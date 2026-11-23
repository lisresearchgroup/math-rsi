// layers3: exact syndrome-ball layering over V=F2^r, 10<=r<=41, n<=4096, tmax<=250.
// Derived from layers2.c (PT3). Adds: multithreading (pthreads), per-block three-state marks,
// deterministic OUT.json, segmented checkpoints with a time policy, resume, PROGRESS heartbeat, STATS.
// Contract: ../SPEC_TOOLS.md section 2.
//
// L_0={0}; L_t = L_{t-1} U (U_j (L_{t-1} xor c_j)); stop at t=tmax or when L_t = V.
// Bit convention: syndrome v is bit (v&63) of word (v>>6). Column integer: bit i = row i of H.
//
// Exit codes: 0 ok (OUT written) | 2 bad arguments/input/checkpoint fingerprint mismatch | 3 allocation failure
//             4 I/O error | 5 thread creation failed (nothing published; checkpoint stays consistent).
//
// Block marks: every block has a u32 popcount (kept for both bitmaps). 0 = empty, BLKBITS = full,
// otherwise mixed.  This is the three-state mark, and it also yields |L_t| and the free reps without
// rescanning the bitmap.
//
// Locking: everything checkpoint related (queues, buffer segment states, meta) is guarded by `mu`.
// Compute workers only touch bitmaps, block counters and a few atomics.
//
// Checkpoint commit order (a kill -9 at any point must leave a usable checkpoint):
//   segment: write tmp, fsync, rename, fsync(layer dir), fsync(ckpt dir)  -> only then state=2 (eligible for meta)
//   meta:    write tmp, fsync, rename, fsync(ckpt dir)                    -> only then old layers may be deleted
//   resume with a fully restored layer D+1: commit the new meta FIRST, then delete layer D.
//   finish:  OUT rename, then meta finished=true, then delete segments.
// Segments carry a 64-bit content hash (seeded with layer and segment index) in the meta.
//
// Policy note: the trigger for writing segments is min(--ckpt-start, --ckpt-throttle).  If --ckpt-throttle is smaller than
// --ckpt-start the throttle value wins, so even a run shorter than --ckpt-start may write segments.  Intended (kept as is).
//
// cols file: whitespace-separated decimal numbers only; any other byte is exit 2, a read error exit 4, no columns exit 2.
// Memory besides the two bitmaps (block counters + J thread buffers + segment tables) must stay below 1 GiB, else exit 2.
//
// Test-only environment variables (never set in production):
//   LAYERS3_TEST_WRITE_DELAY_US  sleep after every 4 MiB segment write() call
//   LAYERS3_TEST_LAG_LOG=file    append "t lag throttled layer durable_layer" every 0.25 s
//   LAYERS3_TEST_FAIL_THREAD=N   the N-th pthread_create call fails with EAGAIN
//   LAYERS3_TEST_ABORT_AT=name[:k]  _exit(99) at the k-th (default 1st) pass through the named point:
//       seg_before_rename seg_renamed meta_before_rename meta_after_rename meta_committed janitor_rm
//       promote_before_meta promote_after_meta resume_before_meta resume_after_meta
//       out_before_rename out_after_rename finish_meta_done
//   LAYERS3_TEST_HOLD_LAYER=K    the meta is never advanced to layer K; after layer K is computed the process waits
//       until all its segments are listed in the meta (state "D=K-1, layer K fully on disk") and then _exit(99)
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdarg.h>
#include <stdatomic.h>
#include <time.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <dirent.h>
#include <getopt.h>
#include <pthread.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/resource.h>

typedef uint64_t u64;
typedef uint32_t u32;
typedef uint8_t u8;

static const u64 MK[6] = {0x5555555555555555ULL, 0x3333333333333333ULL, 0x0f0f0f0f0f0f0f0fULL,
                          0x00ff00ff00ff00ffULL, 0x0000ffff0000ffffULL, 0x00000000ffffffffULL};

#define MAXN 4096
#define MAXT 250
#define MAXNSEG (1ULL << 16)
#define MAXCNTBYTES (512ULL << 20)
#define MAXEXTRABYTES (1ULL << 30)
#define CHUNK (4u << 20)
static double PROG_INT = 10.0;   // test hook LAYERS3_TEST_PROG_INT
#define TICK_NS 50000000L

// ------------------------------------------------------------------ parameters / geometry
static int R, N, TMAX, BWLOG, SEGLOG, FREE_FROM, FREE_MAX, J, NWRITERS;
static double CK_START = 120, CK_THROTTLE = 360, META_INT = 30;
static const char *COLS_PATH, *OUT_PATH, *CK_DIR, *PROG_PATH, *STATS_PATH;
static u64 cols[MAXN];
static u64 NWORDS, BW, NBLOCKS, SEGW, NSEG, BPS, UB, UPS, NUNITS, FULLV;
static u32 BLKBITS;
static char HOST[256];
static pid_t PID;
static long TEST_DELAY_US = 0;
static const char *LAG_LOG = NULL;
static u64 COLS_FNV;
// unique nonzero columns, ascending (same closure as the full list)
static int NUC;
static u64 HB[MAXN], WLO[MAXN];
static int LC[MAXN];

// test hooks
static int TEST_FAIL_THREAD = 0, HOLD_LAYER = 0;
static char ABORT_NAME[64]; static long ABORT_NTH = 1; static int ABORT_SET = 0;
static _Atomic long abort_cnt = 0;
static _Atomic int thr_create_count = 0;
static void testpt(const char *name) {
  if (!ABORT_SET || !name || strcmp(name, ABORT_NAME)) return;
  if (atomic_fetch_add(&abort_cnt, 1) + 1 == ABORT_NTH) { fprintf(stderr, "layers3: TEST abort at %s\n", name); _exit(99); }
}

// ------------------------------------------------------------------ time / logging / helpers
static double T0, T0_UNIX;
static double mono(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec + 1e-9 * t.tv_nsec; }
static double now(void) { return mono() - T0; }
static void logf_(const char *fmt, ...) {
  char b[1024]; va_list ap; va_start(ap, fmt); vsnprintf(b, sizeof b, fmt, ap); va_end(ap);
  fprintf(stderr, "[%9.1f] %s\n", now(), b);
}
static void die(int code, const char *fmt, ...) {
  char b[1024]; va_list ap; va_start(ap, fmt); vsnprintf(b, sizeof b, fmt, ap); va_end(ap);
  fprintf(stderr, "layers3: %s\n", b); exit(code);
}
// Every thread creation goes through here: a failure terminates the process at once (exit 5) so that OUT is never
// published from a partially executed layer and nobody waits for a thread that does not exist.
static void spawn(pthread_t *t, void *(*fn)(void *), void *arg, const char *what) {
  int n = atomic_fetch_add(&thr_create_count, 1) + 1;
  int rc = (TEST_FAIL_THREAD && n == TEST_FAIL_THREAD) ? EAGAIN : pthread_create(t, NULL, fn, arg);
  if (rc) { fprintf(stderr, "layers3: pthread_create failed (%s, call #%d): %s\n", what, n, strerror(rc)); _exit(5); }
}

typedef struct { char *p; size_t n, cap; } SB;
static void sb_init(SB *s) { s->cap = 4096; s->n = 0; s->p = malloc(s->cap); if (!s->p) die(3, "oom"); s->p[0] = 0; }
static void sb_printf(SB *s, const char *fmt, ...) {
  for (;;) {
    va_list ap; va_start(ap, fmt);
    int k = vsnprintf(s->p + s->n, s->cap - s->n, fmt, ap); va_end(ap);
    if (k < 0) die(3, "sb");
    if ((size_t)k < s->cap - s->n) { s->n += (size_t)k; return; }
    s->cap = s->cap * 2 + (size_t)k; s->p = realloc(s->p, s->cap); if (!s->p) die(3, "oom");
  }
}

static int mkdir_p(const char *path) {
  char b[4096]; snprintf(b, sizeof b, "%s", path);
  for (char *q = b + 1; *q; q++) if (*q == '/') { *q = 0; if (mkdir(b, 0777) && errno != EEXIST) return -1; *q = '/'; }
  if (mkdir(b, 0777) && errno != EEXIST) return -1;
  return 0;
}
// 0 ok; -1 error (errno set). EINVAL/ENOTSUP/EOPNOTSUPP mean "directory fsync not supported by this filesystem":
// counted, not an error.
static _Atomic u64 dir_fsync_unsupported = 0;
static int fsync_dir(const char *path) {
  int fd = open(path, O_RDONLY | O_DIRECTORY);
  if (fd < 0) return -1;
  int rc = fsync(fd), e = errno; close(fd);
  if (rc == 0) return 0;
  if (e == EINVAL || e == ENOTSUP || e == EOPNOTSUPP) { atomic_fetch_add(&dir_fsync_unsupported, 1); return 0; }
  errno = e; return -1;
}
static int write_all(int fd, const void *buf, size_t n) {
  const char *p = buf;
  while (n) { ssize_t w = write(fd, p, n); if (w < 0) { if (errno == EINTR) continue; return -1; } p += w; n -= (size_t)w; }
  return 0;
}
// write text atomically: tmp.<host>.<pid>, fsync, rename. durable!=0 also fsyncs the directory (error => -1).
static int atomic_write_file(const char *path, const char *data, size_t n, int durable, const char *pt_before, const char *pt_after) {
  char tmp[4400]; snprintf(tmp, sizeof tmp, "%s.tmp.%s.%d", path, HOST, (int)PID);
  int fd = open(tmp, O_WRONLY | O_CREAT | O_TRUNC, 0644);
  if (fd < 0) return -1;
  if (write_all(fd, data, n) || fsync(fd)) { int e = errno; close(fd); unlink(tmp); errno = e; return -1; }
  close(fd);
  testpt(pt_before);
  if (rename(tmp, path)) { int e = errno; unlink(tmp); errno = e; return -1; }
  testpt(pt_after);
  if (durable) {
    char d[4400]; snprintf(d, sizeof d, "%s", path);
    char *sl = strrchr(d, '/'); int rc;
    if (sl) { *sl = 0; rc = fsync_dir(d[0] ? d : "/"); } else rc = fsync_dir(".");
    if (rc) return -1;
  }
  return 0;
}
static int rm_rf(const char *path) {
  DIR *d = opendir(path);
  if (!d) { return unlink(path); }
  struct dirent *e;
  while ((e = readdir(d))) {
    if (!strcmp(e->d_name, ".") || !strcmp(e->d_name, "..")) continue;
    char c[4400]; snprintf(c, sizeof c, "%s/%s", path, e->d_name);
    struct stat st;
    if (lstat(c, &st) == 0 && S_ISDIR(st.st_mode)) rm_rf(c); else unlink(c);
  }
  closedir(d);
  return rmdir(path);
}

// ------------------------------------------------------------------ minimal JSON parser (for meta)
typedef struct JN { char ty; u64 num; char *str; size_t cnt; struct JN **kids; char **keys; } JN; // ty: n s b a o z
static void jws(const char **p) { while (**p == ' ' || **p == '\n' || **p == '\t' || **p == '\r') (*p)++; }
static JN *jparse(const char **p) {
  jws(p);
  JN *n = calloc(1, sizeof(JN));
  if (!n) die(3, "oom");
  char c = **p;
  if (c == '{' || c == '[') {
    n->ty = c == '{' ? 'o' : 'a'; (*p)++; jws(p);
    size_t cap = 0;
    while (**p && **p != '}' && **p != ']') {
      char *key = NULL;
      if (n->ty == 'o') {
        JN *k = jparse(p); if (!k || k->ty != 's') return NULL;
        key = k->str; jws(p); if (**p != ':') return NULL; (*p)++;
      }
      JN *v = jparse(p); if (!v) return NULL;
      if (n->cnt == cap) {
        cap = cap ? cap * 2 : 8;
        n->kids = realloc(n->kids, cap * sizeof(JN *)); n->keys = realloc(n->keys, cap * sizeof(char *));
        if (!n->kids || !n->keys) die(3, "oom");
      }
      n->kids[n->cnt] = v; n->keys[n->cnt] = key; n->cnt++;
      jws(p); if (**p == ',') { (*p)++; jws(p); }
    }
    if (**p != '}' && **p != ']') return NULL;
    (*p)++; return n;
  }
  if (c == '"') {
    const char *s = ++(*p); while (**p && **p != '"') (*p)++;
    if (**p != '"') return NULL;
    n->ty = 's'; n->str = strndup(s, (size_t)(*p - s)); (*p)++; return n;
  }
  if (!strncmp(*p, "true", 4)) { n->ty = 'b'; n->num = 1; *p += 4; return n; }
  if (!strncmp(*p, "false", 5)) { n->ty = 'b'; n->num = 0; *p += 5; return n; }
  if (!strncmp(*p, "null", 4)) { n->ty = 'z'; *p += 4; return n; }
  if (c >= '0' && c <= '9') { char *e; n->ty = 'n'; n->num = strtoull(*p, &e, 10); *p = e; return n; }
  return NULL;
}
static JN *jget(JN *o, const char *key) {
  if (!o || o->ty != 'o') return NULL;
  for (size_t i = 0; i < o->cnt; i++) if (o->keys[i] && !strcmp(o->keys[i], key)) return o->kids[i];
  return NULL;
}

// ------------------------------------------------------------------ segment hash (64 bit, 4 independent lanes)
#define HK1 0x9E3779B97F4A7C15ULL
#define HK2 0xC2B2AE3D27D4EB4FULL
static void hash_init(u64 h[4], int layer, u64 seg) {
  u64 s = (HK1 * ((u64)layer + 1)) ^ (HK2 * (seg + 1));
  for (int l = 0; l < 4; l++) h[l] = s + (u64)l * 0x165667B19E3779F9ULL;
}
// nw must be a multiple of 4; the lane of a word is its index mod 4 within the segment
static inline void hash_acc(u64 h[4], const u64 *w, size_t nw) {
  u64 a = h[0], b = h[1], c = h[2], d = h[3];
  for (size_t i = 0; i < nw; i += 4) {
    a = (a ^ w[i]) * HK1;     a ^= a >> 29;
    b = (b ^ w[i + 1]) * HK1; b ^= b >> 29;
    c = (c ^ w[i + 2]) * HK1; c ^= c >> 29;
    d = (d ^ w[i + 3]) * HK1; d ^= d >> 29;
  }
  h[0] = a; h[1] = b; h[2] = c; h[3] = d;
}
static u64 hash_fin(const u64 h[4]) {
  u64 f = h[0];
  for (int l = 1; l < 4; l++) { f = (f ^ h[l]) * HK2; f ^= f >> 31; }
  return f;
}

// ------------------------------------------------------------------ buffers and shared state
typedef struct { u64 pop, hash; } SI;   // per-segment popcount and content hash (hash 0 when pop == 0)
typedef struct {
  u64 *bm; u32 *cnt;
  int layer;                // layer stored/being built, -1 unused
  u8 *state;                // per segment: 0 none, 1 queued/in flight, 2 written (renamed)
  SI *si;                   // per segment info, pop valid once queued, hash once written
  _Atomic u64 *done_ns;     // per segment completion time (ns since start)+1, 0 = not complete
  _Atomic u64 *claim_ns;    // per segment: earliest wall time (stamp_ns) at which one of its units was claimed by a worker; 0 = none/restored
  int inflight;             // queued + running write jobs referencing this buffer
} Buf;
static Buf bufs[2];
static int prev_i = 0;

typedef struct { int have; u64 count; u64 *reps; int nreps; } FreeItem;

static pthread_mutex_t mu = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t cv = PTHREAD_COND_INITIALIZER;   // job done / state change (main waits)
static pthread_cond_t qcv = PTHREAD_COND_INITIALIZER;  // job queued (writers wait)

static int ncomp = 0;                 // completed layers L_0..L_{ncomp-1}
static u64 Lsize[MAXT + 2];
static double ctime_[MAXT + 2];       // completion time of layer (0 for layers restored)
static double lsec[MAXT + 2];         // seconds spent computing layer this run (-1 if not computed)
static FreeItem fitem[MAXT + 2];
static int computing = 0, cur_layer = 0, waiting_write = 0, finalizing = 0;
static int resume_keep = 0;           // first layer after resume: output buffer already holds loaded segments

static int ck_enabled = 0, ck_touched = 0;
static int meta_D = 0;                // layer D in the persisted meta (0 = virtual: L_0 needs no segment files)
static SI *meta_Dsi, *meta_list_si;
static u8 *meta_listed;               // segments of layer meta_D+1 listed in persisted meta
static double last_meta = -1e9;
static u64 resume_count = 0, resume_rejected = 0;
static int resumed_from = -1;
static double resume_load_sec = 0;
static int del_below = 0, jan_done = 1;

typedef struct { int b; u64 seg; } Job;
static Job *jq; static size_t jq_h, jq_t, jq_cap;
static int wstop = 0;                       // under mu
static _Atomic int abort_writes = 0, mgr_stop = 0;
static int active_writers = 0; static double active_start = 0;
static double write_wall = 0, write_thread_sec = 0, write_job_max = 0; static u64 write_bytes = 0, segs_written = 0, segs_sparse = 0;
static u64 jobs_done = 0;
static double thr_layer[MAXT + 2];   // seconds the compute threads were throttled while a layer was running
static double segq[MAXT + 2][5]; static size_t segq_n[MAXT + 2]; static double *segtmp;   // segment completion-time quantiles per layer
static int cmp_dbl(const void *a, const void *b) { double x = *(const double *)a, y = *(const double *)b; return x < y ? -1 : x > y; }
static double throttle_sec = 0; static u64 throttle_events = 0;
static double cur_lag = 0; static int cur_throttled = 0;
static int cand_layer = -1; static SI *cand_si;  // fully written layer whose buffer was recycled before the meta recorded it
static _Atomic int g_metaD = 0;      // mirror of meta_D for lock-free checks in writers
// Rule 1/2 state.  X(now) = now - min claim over segments of layers > D that are not listed in the meta (see at_risk_min_claim).
static u64 rec_claim[MAXT + 2];                 // layers whose buffer was recycled: min claim over their at-risk segments (~0 = none)
static pthread_mutex_t disp = PTHREAD_MUTEX_INITIALIZER;   // serialises unit hand-out (units are handed out in index order)
static _Atomic int g_waiting = 0, g_release = 0;           // a worker holds the dispenser waiting at a segment start / watchdog release token
static double max_claim_X = 0, max_wall_X = 0, max_seg_sec = 0;   // under mu (max_seg_sec: main thread)
static long META_DELAY_US = 0;                  // test hook: delay every meta commit
static u64 meta_commits = 0, wd_snap = 0, watchdog_releases = 0; static double thr_since = -1;
// per-layer compute state
static u64 *g_prevbm, *g_nextbm; static u32 *g_pcnt, *g_ncnt; static Buf *g_nextbuf;
static _Atomic u64 g_next_unit, g_units_done;
static u8 *g_skip; static _Atomic u64 *g_segunits;
static u64 *tmpbuf[1024];

static u64 stamp_ns(void) { return (u64)(now() * 1e9) + 1; }

// ------------------------------------------------------------------ free reps
static void compute_free(Buf *B, int t, u64 cnt) {
  if (t < FREE_FROM || cnt == FULLV) return;
  u64 count = FULLV - cnt, need = count < (u64)FREE_MAX ? count : (u64)FREE_MAX;
  FreeItem *f = &fitem[t]; f->have = 1; f->count = count; f->nreps = (int)need;
  f->reps = malloc((need ? need : 1) * 8);
  u64 got = 0;
  for (u64 b = 0; b < NBLOCKS && got < need; b++) {
    if (B->cnt[b] == BLKBITS) continue;
    const u64 *w = B->bm + b * BW; int empty = B->cnt[b] == 0;
    for (u64 i = 0; i < BW && got < need; i++) {
      u64 m = empty ? ~0ULL : ~w[i];
      while (m && got < need) { f->reps[got++] = ((b * BW + i) << 6) + (u64)__builtin_ctzll(m); m &= m - 1; }
    }
  }
  if (got != need) die(2, "internal: free reps mismatch t=%d got=%llu need=%llu", t, (unsigned long long)got, (unsigned long long)need);
}
static void emit_free(SB *s, int upto, const char *indent) {
  int first = 1;
  for (int t = FREE_FROM < 0 ? 0 : FREE_FROM; t <= upto; t++) {
    FreeItem *f = &fitem[t]; if (!f->have) continue;
    sb_printf(s, "%s%s{\"t\": %d, \"count\": %llu, \"reps\": [", first ? "" : ",\n", indent, t, (unsigned long long)f->count);
    for (int i = 0; i < f->nreps; i++) sb_printf(s, "%s%llu", i ? "," : "", (unsigned long long)f->reps[i]);
    sb_printf(s, "]}"); first = 0;
  }
}

// ------------------------------------------------------------------ compute kernel
static inline u64 or_acc(u64 *restrict out, const u64 *restrict src) {
  u64 acc = ~0ULL;
  for (u64 w = 0; w < BW; w++) { u64 y = out[w] | src[w]; out[w] = y; acc &= y; }
  return acc;
}
static void do_block(u64 o, u64 *tmp) {
  u64 *out = g_nextbm + o * BW; const u64 *pb = g_prevbm + o * BW;
  u32 pc = g_pcnt[o];
  if (pc == BLKBITS) { memset(out, 0xff, BW * 8); g_ncnt[o] = BLKBITS; return; }
  if (pc == 0) memset(out, 0, BW * 8); else memcpy(out, pb, BW * 8);
  int mod = 0, full = 0;
  for (int j = 0; j < NUC; j++) {
    u64 ib = o ^ HB[j]; u32 sc = g_pcnt[ib];
    if (!sc) continue;
    if (sc == BLKBITS) { memset(out, 0xff, BW * 8); full = 1; break; }
    const u64 *src = g_prevbm + ib * BW; u64 wl = WLO[j]; int l = LC[j];
    u64 acc;
    if (wl == 0 && l == 0) acc = or_acc(out, src);
    else {
      u64 wh = wl & ~7ULL; int sl = (int)(wl & 7);
      if (sl == 0) { for (u64 w = 0; w < BW; w += 8) memcpy(tmp + w, src + (w ^ wh), 64); }
      else { for (u64 w = 0; w < BW; w += 8) { const u64 *s = src + (w ^ wh); for (int i = 0; i < 8; i++) tmp[w + i] = s[i ^ sl]; } }
      for (int k = 0; k < 6; k++) if (l >> k & 1) {
        int s = 1 << k; u64 m = MK[k];
        for (u64 w = 0; w < BW; w++) { u64 y = tmp[w]; tmp[w] = ((y & m) << s) | ((y >> s) & m); }
      }
      acc = or_acc(out, tmp);
    }
    mod = 1;
    if (acc == ~0ULL) { full = 1; break; }
  }
  u32 c;
  if (full) c = BLKBITS;
  else if (!mod) c = pc;
  else { u64 s = 0; for (u64 w = 0; w < BW; w++) s += (u64)__builtin_popcountll(out[w]); c = (u32)s; }
  g_ncnt[o] = c;
}
// ---- unit dispenser: rule 1.  Units are handed out in index order by one thread at a time (disp).  A unit that is the first of
// a not-restored segment opens a new segment: it is handed out only when X <= ckpt-throttle (or the watchdog released the gate).
// All other units belong to an already opened segment and are handed out freely, so started segments always finish.
static u64 at_risk_min_claim(void);   // caller holds mu
static int claim_unit(u64 *uo) {
  pthread_mutex_lock(&disp);
  for (;;) {
    u64 u = atomic_load(&g_next_unit);
    if (u >= NUNITS) { pthread_mutex_unlock(&disp); return 0; }
    u64 seg = u / UPS;
    int opens = (u % UPS == 0) && !g_skip[seg];
    if (opens && ck_enabled) {
      pthread_mutex_lock(&mu);
      u64 mc = at_risk_min_claim(), nw = stamp_ns();
      double X = mc == ~0ULL ? 0.0 : (double)(nw - mc) * 1e-9;
      int rel = X > CK_THROTTLE ? atomic_exchange(&g_release, 0) : 0;
      if (X > CK_THROTTLE && !rel) { pthread_mutex_unlock(&mu); atomic_store(&g_waiting, 1); usleep(5000); continue; }
      if (X > max_claim_X) max_claim_X = X;
      pthread_mutex_unlock(&mu);
      atomic_store(&g_waiting, 0);
    }
    atomic_store(&g_next_unit, u + 1);
    if (!g_skip[seg]) {   // record the claim time of the segment (atomic min over all its units)
      _Atomic u64 *c = &g_nextbuf->claim_ns[seg]; u64 nw = stamp_ns(), old = atomic_load(c);
      while ((old == 0 || old > nw) && !atomic_compare_exchange_weak(c, &old, nw)) {}
    }
    pthread_mutex_unlock(&disp);
    *uo = u; return 1;
  }
}
static void *worker(void *arg) {
  u64 *tmp = tmpbuf[(int)(intptr_t)arg];
  u64 u;
  while (claim_unit(&u)) {
    u64 seg = u / UPS;
    if (g_skip[seg]) { atomic_fetch_add(&g_units_done, 1); continue; }
    u64 b0 = u * UB;
    for (u64 b = b0; b < b0 + UB; b++) do_block(b, tmp);
    atomic_fetch_add(&g_units_done, 1);
    if (atomic_fetch_add(&g_segunits[seg], 1) + 1 == UPS) atomic_store(&g_nextbuf->done_ns[seg], stamp_ns());
  }
  return NULL;
}

// ------------------------------------------------------------------ checkpoint IO
static void seg_path(char *b, size_t n, int layer, u64 k) { snprintf(b, n, "%s/L%d/seg%llu.bin", CK_DIR, layer, (unsigned long long)k); }

// returns 0 ok, 1 aborted, -1 error (errno set)
static int write_seg(int layer, u64 k, const u64 *mem, u64 pop, u64 *bytes_out, u64 *hash_out) {
  char dir[4400], fin[4400], tmp[4500];
  snprintf(dir, sizeof dir, "%s/L%d", CK_DIR, layer);
  if (mkdir_p(dir)) return -1;
  seg_path(fin, sizeof fin, layer, k);
  snprintf(tmp, sizeof tmp, "%s.tmp.%s.%d", fin, HOST, (int)PID);
  int fd = open(tmp, O_WRONLY | O_CREAT | O_TRUNC, 0644);
  if (fd < 0) return -1;
  size_t total = SEGW * 8, off = 0; u64 bytes = 0, hash = 0;
  if (pop == 0) { if (ftruncate(fd, (off_t)total)) { int e = errno; close(fd); unlink(tmp); errno = e; return -1; } }
  else {
    u64 h[4]; hash_init(h, layer, k);
    while (off < total) {
      if (atomic_load(&abort_writes) || layer < atomic_load(&g_metaD)) { close(fd); unlink(tmp); return 1; }
      size_t c = total - off < CHUNK ? total - off : CHUNK;
      hash_acc(h, (const u64 *)((const char *)mem + off), c / 8);
      if (write_all(fd, (const char *)mem + off, c)) { int e = errno; close(fd); unlink(tmp); errno = e; return -1; }
      off += c; bytes += c;
      if (TEST_DELAY_US) usleep((useconds_t)TEST_DELAY_US);
    }
    hash = hash_fin(h);
  }
  if (fsync(fd)) { int e = errno; close(fd); unlink(tmp); errno = e; return -1; }
  posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
  close(fd);
  testpt("seg_before_rename");
  if (rename(tmp, fin)) { int e = errno; unlink(tmp); errno = e; return -1; }
  if (fsync_dir(dir) || fsync_dir(CK_DIR)) return -1;
  testpt("seg_renamed");
  *bytes_out = bytes; *hash_out = hash;
  return 0;
}

// caller holds mu
static void enqueue(int b, u64 k) {
  Buf *B = &bufs[b];
  u64 pop = 0; const u32 *c = B->cnt + k * BPS;
  for (u64 i = 0; i < BPS; i++) pop += c[i];
  B->si[k].pop = pop; B->si[k].hash = 0; B->state[k] = 1; B->inflight++;
  ck_touched = 1;
  if (jq_t - jq_h >= jq_cap) die(2, "internal: job queue overflow");
  jq[jq_t % jq_cap] = (Job){b, k}; jq_t++;
  pthread_cond_signal(&qcv);
}

static void *writer_main(void *arg) {
  (void)arg;
  pthread_mutex_lock(&mu);
  for (;;) {
    while (jq_h == jq_t && !wstop) pthread_cond_wait(&qcv, &mu);
    if (jq_h == jq_t && wstop) break;
    Job j = jq[jq_h % jq_cap]; jq_h++;
    Buf *B = &bufs[j.b];
    if (atomic_load(&abort_writes) || B->layer < meta_D) { B->state[j.seg] = 0; B->inflight--; pthread_cond_broadcast(&cv); continue; }
    u64 pop = B->si[j.seg].pop; int layer = B->layer;
    if (active_writers++ == 0) active_start = now();
    double ts = now();
    pthread_mutex_unlock(&mu);
    u64 bytes = 0, hash = 0;
    int rc = write_seg(layer, j.seg, B->bm + j.seg * SEGW, pop, &bytes, &hash);
    int e = errno;
    pthread_mutex_lock(&mu);
    double te = now();
    write_thread_sec += te - ts; if (te - ts > write_job_max) write_job_max = te - ts;
    if (--active_writers == 0) write_wall += te - active_start;
    if (rc < 0) { fprintf(stderr, "layers3: checkpoint segment write failed (layer %d seg %llu): %s\n", layer, (unsigned long long)j.seg, strerror(e)); _exit(4); }
    if (rc == 0) { B->si[j.seg].hash = hash; B->state[j.seg] = 2; write_bytes += bytes; segs_written++; if (pop == 0) segs_sparse++; }
    else B->state[j.seg] = 0;
    B->inflight--; jobs_done++;
    pthread_cond_broadcast(&cv);
  }
  pthread_mutex_unlock(&mu);
  return NULL;
}

static void build_meta(SB *s, int D, const SI *dsi, const u8 *listed, const SI *lsi, int finished) {
  sb_printf(s, "{\n \"format\": \"layers3-meta-v2\",\n \"host\": \"%s\", \"pid\": %d, \"updated_unix\": %.0f,\n", HOST, (int)PID, T0_UNIX + now());
  sb_printf(s, " \"r\": %d, \"tmax\": %d, \"n\": %d, \"cols_fnv\": %llu, \"seglog\": %d, \"free_from\": %d, \"free_max\": %d,\n",
            R, TMAX, N, (unsigned long long)COLS_FNV, SEGLOG, FREE_FROM, FREE_MAX);
  sb_printf(s, " \"finished\": %s,\n \"resume_count\": %llu,\n", finished ? "true" : "false", (unsigned long long)resume_count);
  if (finished) { sb_printf(s, " \"durable_layer\": 0,\n \"L_sizes\": [],\n \"free\": [],\n \"durable_seg_pop\": [],\n \"durable_seg_hash\": [],\n \"next_layer\": 1,\n \"next_segs\": []\n}\n"); return; }
  sb_printf(s, " \"durable_layer\": %d,\n \"L_sizes\": [", D);
  for (int t = 0; t <= D; t++) sb_printf(s, "%s%llu", t ? "," : "", (unsigned long long)Lsize[t]);
  sb_printf(s, "],\n \"free\": [\n"); emit_free(s, D, "  "); sb_printf(s, "\n ],\n");
  sb_printf(s, " \"durable_seg_pop\": [");
  for (u64 k = 0; k < NSEG; k++) sb_printf(s, "%s%llu", k ? "," : "", (unsigned long long)dsi[k].pop);
  sb_printf(s, "],\n \"durable_seg_hash\": [");
  for (u64 k = 0; k < NSEG; k++) sb_printf(s, "%s%llu", k ? "," : "", (unsigned long long)dsi[k].hash);
  sb_printf(s, "],\n \"next_layer\": %d,\n \"next_segs\": [", D + 1);
  int first = 1;
  for (u64 k = 0; k < NSEG; k++) if (listed[k]) { sb_printf(s, "%s[%llu,%llu,%llu]", first ? "" : ",", (unsigned long long)k, (unsigned long long)lsi[k].pop, (unsigned long long)lsi[k].hash); first = 0; }
  sb_printf(s, "]\n}\n");
}
static int write_meta_text(const SB *s) {
  if (mkdir_p(CK_DIR)) return -1;
  char p[4400]; snprintf(p, sizeof p, "%s/meta.json", CK_DIR);
  return atomic_write_file(p, s->p, s->n, 1, "meta_before_rename", "meta_after_rename");
}

// ------------------------------------------------------------------ progress
static void write_progress(int force_state /*0 auto,1 done*/) {
  if (!PROG_PATH) return;
  SB s; sb_init(&s);
  pthread_mutex_lock(&mu);
  double t = now();
  u64 done = atomic_load(&g_units_done);
  double frac = computing ? (double)done / (double)NUNITS : 0.0; if (frac > 1) frac = 1;
  const char *st = force_state ? "done" : (waiting_write || finalizing) ? "writing" : "running";
  sb_printf(&s, "{\"host\":\"%s\", \"pid\":%d, \"r\":%d, \"n\":%d, \"tmax\":%d, \"threads\":%d, \"start_unix\":%.0f, \"now_unix\":%.0f,\n", HOST, (int)PID, R, N, TMAX, J, T0_UNIX, T0_UNIX + t);
  if (resumed_from >= 0) sb_printf(&s, " \"resumed_from_layer\": %d,", resumed_from); else sb_printf(&s, " \"resumed_from_layer\": null,");
  sb_printf(&s, " \"layer\": %d, \"layer_frac\": %.4f, \"L_sizes\":[", force_state ? ncomp - 1 : cur_layer, force_state ? 1.0 : frac);
  for (int i = 0; i < ncomp; i++) sb_printf(&s, "%s%llu", i ? "," : "", (unsigned long long)Lsize[i]);
  sb_printf(&s, "],\n \"durable_layer\": %d, \"durable_lag_sec\": %.1f, \"throttled\": %s, \"state\":\"%s\"}\n",
            ck_enabled ? meta_D : -1, cur_lag, cur_throttled ? "true" : "false", st);
  pthread_mutex_unlock(&mu);
  if (atomic_write_file(PROG_PATH, s.p, s.n, 0, NULL, NULL)) logf_("warning: cannot write progress %s: %s", PROG_PATH, strerror(errno));
  free(s.p);
}

// ------------------------------------------------------------------ manager (meta, policy, throttle, progress)
static Buf *find_layer_buf(int layer) {
  for (int i = 0; i < 2; i++) if (bufs[i].layer == layer) return &bufs[i];
  return NULL;
}
static u8 *sc_listed; static SI *sc_si, *sc_list_si;
static double mgr_last_tick = 0, mgr_last_prog = -100, mgr_last_laglog = -1;
static FILE *lag_fp = NULL;

// X(now) = now - min{ claim_ns[k] : segment k of a layer > D, not listed in the meta (the listed segments of layer D+1 are loaded
// from disk on restart and cost nothing) }.  Layers whose buffer was recycled are summarised in rec_claim.  Caller holds mu.
static u64 at_risk_min_claim(void) {
  u64 m = ~0ULL;
  for (int l = meta_D + 1; l <= MAXT + 1; l++) if (rec_claim[l] < m) m = rec_claim[l];
  for (int bi = 0; bi < 2; bi++) {
    Buf *B = &bufs[bi];
    if (B->layer <= meta_D) continue;
    int lst = B->layer == meta_D + 1;
    for (u64 k = 0; k < NSEG; k++) { u64 c = atomic_load(&B->claim_ns[k]); if (c && c < m && !(lst && meta_listed[k])) m = c; }
  }
  return m;
}

static void mgr_tick(void) {
  pthread_mutex_lock(&mu);
  double t = now();
  int tp = ncomp - 1;
  double lag = 0, X = 0; int thr = 0;
  if (ck_enabled) {
    Buf *P = &bufs[prev_i];
    int Dn = meta_D;
    const SI *dn_si = NULL;
    if (cand_layer > Dn) { Dn = cand_layer; dn_si = cand_si; }
    // Promote to the highest completed layer that is completely on disk.  Candidates are the layers still held in the two
    // buffers (the older one may be tp-1 while tp is already computed) -- intermediate layers that were never written and
    // have already been recycled are irrelevant: a durable layer D only needs L_D itself (L_0 is virtual), so jumping
    // over them is correct.  (A version that only promoted Dn+1 stalled forever when Dn+1 was no longer in a buffer.)
    for (int bi = 0; bi < 2; bi++) {
      Buf *Q = &bufs[bi];
      if (Q->layer < 1 || Q->layer > tp || Q->layer <= Dn || (HOLD_LAYER > 0 && Q->layer >= HOLD_LAYER)) continue;
      int all2 = 1; for (u64 k = 0; k < NSEG; k++) if (Q->state[k] != 2) { all2 = 0; break; }
      if (all2) { Dn = Q->layer; dn_si = Q->si; }
    }
    if (HOLD_LAYER > 0 && Dn >= HOLD_LAYER) { Dn = meta_D; dn_si = NULL; }   // test hook: never promote to the hold layer
    Buf *Nb = find_layer_buf(Dn + 1);
    int changed = Dn > meta_D;
    if (!changed && Nb) for (u64 k = 0; k < NSEG; k++) if ((Nb->state[k] == 2) != (meta_listed[k] != 0)) { changed = 1; break; }
    // A pending meta update is also due immediately while the compute threads are throttled: the meta commit is what
    // lets the lag shrink again (otherwise ckpt-throttle < meta-interval would stall the computation between commits).
    if (Dn > meta_D || (changed && (t - last_meta >= META_INT || cur_throttled))) {
      const SI *dsi = meta_Dsi;
      if (Dn > meta_D) { memcpy(sc_si, dn_si, NSEG * sizeof(SI)); dsi = sc_si; }
      for (u64 k = 0; k < NSEG; k++) {
        sc_listed[k] = (Nb && Nb->state[k] == 2) ? 1 : 0;
        if (sc_listed[k]) sc_list_si[k] = Nb->si[k]; else sc_list_si[k] = (SI){0, 0};
      }
      SB s; sb_init(&s); build_meta(&s, Dn, dsi, sc_listed, sc_list_si, 0);
      pthread_mutex_unlock(&mu);
      if (META_DELAY_US) usleep((useconds_t)META_DELAY_US);
      int rc = write_meta_text(&s);
      int e = errno;
      free(s.p);
      if (rc) { fprintf(stderr, "layers3: meta write failed: %s\n", strerror(e)); _exit(4); }
      if (Dn > meta_D) testpt("meta_committed");
      pthread_mutex_lock(&mu);
      if (Dn > meta_D) { memcpy(meta_Dsi, sc_si, NSEG * sizeof(SI)); meta_D = Dn; if (cand_layer <= meta_D) cand_layer = -1; atomic_store(&g_metaD, Dn); del_below = Dn; }
      memcpy(meta_listed, sc_listed, NSEG); memcpy(meta_list_si, sc_list_si, NSEG * sizeof(SI));
      last_meta = now(); meta_commits++;
      t = last_meta;
      tp = ncomp - 1; P = &bufs[prev_i];
    }
    // ---- rules 1 and 2 (see the proof in QUAL_REPORT.md)
    double trig = CK_START < CK_THROTTLE ? CK_START : CK_THROTTLE;
    u64 mc = at_risk_min_claim();
    X = mc == ~0ULL ? 0.0 : (double)(stamp_ns() - mc) * 1e-9;
    lag = X;
    // Rule 2: X reached the trigger and a complete layer beyond D exists -> write the newest complete layer (D jumps to it).
    if (tp >= 1 && tp > meta_D && X >= trig)
      for (u64 k = 0; k < NSEG; k++) if (P->state[k] == 0) enqueue(prev_i, k);
    // Rule 2, second part: once D == tp, segments of the layer being computed are queued as soon as they are complete
    // (and, once written, listed in the meta -- immediately while the gate is closed).  D=0: L_0 is virtual, same rule.
    if (computing && meta_D == tp && X >= trig) {
      Buf *Nx = &bufs[prev_i ^ 1];
      for (u64 k = 0; k < NSEG; k++) if (atomic_load(&Nx->done_ns[k]) && Nx->state[k] == 0) enqueue(prev_i ^ 1, k);
    }
    thr = atomic_load(&g_waiting);   // rule 1 is enforced in claim_unit(); here only observed
    // Watchdog (defence in depth; the tests assert it never fires): gate closed for 60 s with no write finished, no meta
    // commit, nothing queued or in flight -> hand the dispenser one release token.
    { u64 snap = jobs_done * 1000003ULL + meta_commits * 7919ULL + (u64)meta_D;
      if (!thr || snap != wd_snap) { thr_since = thr ? t : -1; wd_snap = snap; }
      else if (thr_since < 0) thr_since = t;
      if (thr && thr_since >= 0 && t - thr_since > 60.0 && jq_t == jq_h && active_writers == 0) {
        watchdog_releases++; thr_since = -1; atomic_store(&g_release, 1);
        fprintf(stderr, "[%9.1f] WARNING: throttle watchdog released a stuck gate (X=%.1f, D=%d, tp=%d); exposure bound not guaranteed\n", t, X, meta_D, tp); } }
  } else lag = t;
  double dt = t - mgr_last_tick; if (dt < 0 || dt > 5) dt = 0; mgr_last_tick = t;
  if (thr && !cur_throttled) throttle_events++;
  if (thr) { throttle_sec += dt; if (computing && cur_layer <= MAXT) thr_layer[cur_layer] += dt; }
  if (ck_enabled && lag > max_wall_X) max_wall_X = lag;
  cur_lag = lag; cur_throttled = thr;
  int lg = ck_enabled && lag_fp && t - mgr_last_laglog >= 0.25;
  if (lg) { fprintf(lag_fp, "%.2f %.2f %d %d %d\n", t, lag, thr, cur_layer, meta_D); fflush(lag_fp); mgr_last_laglog = t; }
  int doprog = PROG_PATH && t - mgr_last_prog >= PROG_INT;
  if (doprog) mgr_last_prog = t;
  pthread_mutex_unlock(&mu);
  if (doprog) write_progress(0);
}
static void *mgr_main(void *arg) {
  (void)arg;
  while (!atomic_load(&mgr_stop)) {
    mgr_tick();
    struct timespec ts = {0, TICK_NS}; nanosleep(&ts, NULL);
  }
  return NULL;
}
static void *janitor_main(void *arg) {
  (void)arg;
  while (!atomic_load(&mgr_stop)) {
    pthread_mutex_lock(&mu);
    int lo = jan_done, hi = del_below;
    pthread_mutex_unlock(&mu);
    int done_to = lo;
    for (int u = lo; u < hi; u++) {
      pthread_mutex_lock(&mu);
      int busy = 0; for (int i = 0; i < 2; i++) if (bufs[i].layer == u && bufs[i].inflight > 0) busy = 1;
      pthread_mutex_unlock(&mu);
      if (busy) break;
      testpt("janitor_rm");
      char p[4400]; snprintf(p, sizeof p, "%s/L%d", CK_DIR, u); rm_rf(p); done_to = u + 1;
    }
    if (done_to > lo) { pthread_mutex_lock(&mu); if (jan_done < done_to) jan_done = done_to; pthread_mutex_unlock(&mu); }
    struct timespec ts = {0, 200000000L}; nanosleep(&ts, NULL);
  }
  return NULL;
}

// ------------------------------------------------------------------ resume
typedef struct { int b; u64 seg; u64 want_pop, want_hash; int layer; int ok; } LoadTask;
static LoadTask *ltasks; static size_t nlt; static _Atomic size_t lt_next;
static int load_seg(LoadTask *T) {
  char p[4400]; seg_path(p, sizeof p, T->layer, T->seg);
  int fd = open(p, O_RDONLY); if (fd < 0) return 0;
  struct stat st; size_t total = SEGW * 8;
  if (fstat(fd, &st) || (u64)st.st_size != total) { close(fd); return 0; }
  Buf *B = &bufs[T->b]; char *dst = (char *)(B->bm + T->seg * SEGW); size_t off = 0, hashed = 0;
  u64 h[4]; hash_init(h, T->layer, T->seg);
  while (off < total) {
    size_t c = total - off < CHUNK ? total - off : CHUNK;
    ssize_t r = pread(fd, dst + off, c, (off_t)off);
    if (r < 0 && errno == EINTR) continue;
    if (r <= 0) { close(fd); return 0; }
    off += (size_t)r;
    size_t upto = off & ~(size_t)31;                       // hash only whole 4-word groups; keeps lane alignment on short reads
    if (upto > hashed) { hash_acc(h, (const u64 *)(dst + hashed), (upto - hashed) / 8); hashed = upto; }
  }
  posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
  close(fd);
  u64 pop = 0;
  for (u64 i = 0; i < BPS; i++) {
    const u64 *w = B->bm + (T->seg * BPS + i) * BW; u64 s = 0;
    for (u64 x = 0; x < BW; x++) s += (u64)__builtin_popcountll(w[x]);
    B->cnt[T->seg * BPS + i] = (u32)s; pop += s;
  }
  if (pop != T->want_pop) return 0;
  if (pop != 0 && hash_fin(h) != T->want_hash) return 0;
  return 1;
}
static void *loader(void *arg) {
  (void)arg;
  for (;;) { size_t i = atomic_fetch_add(&lt_next, 1); if (i >= nlt) break; ltasks[i].ok = load_seg(&ltasks[i]); }
  return NULL;
}
static void run_loaders(void) {
  atomic_store(&lt_next, 0);
  size_t nt = (size_t)J < nlt ? (size_t)J : nlt; if (nt < 1) nt = 1;
  pthread_t th[1024];
  for (size_t i = 0; i < nt; i++) spawn(&th[i], loader, NULL, "loader");
  for (size_t i = 0; i < nt; i++) pthread_join(th[i], NULL);
}

static void wipe_ckdir_layers(int keep_a, int keep_b) {
  DIR *d = opendir(CK_DIR); if (!d) return;
  struct dirent *e;
  while ((e = readdir(d))) {
    char p[4400]; snprintf(p, sizeof p, "%s/%s", CK_DIR, e->d_name);
    if (e->d_name[0] == 'L' && e->d_name[1] >= '0' && e->d_name[1] <= '9') {
      int u = atoi(e->d_name + 1);
      if (u == keep_a || u == keep_b) {
        DIR *d2 = opendir(p);
        if (d2) { struct dirent *f; while ((f = readdir(d2))) if (strstr(f->d_name, ".tmp.")) { char q[4500]; snprintf(q, sizeof q, "%s/%s", p, f->d_name); unlink(q); } closedir(d2); }
      } else rm_rf(p);
    } else if (strstr(e->d_name, ".tmp.")) unlink(p);
  }
  closedir(d);
}

static void fresh_state(void) {
  // bitmaps are fresh anonymous memory; blocks with cnt==0 are semantically all-zero whatever the bytes are
  memset(bufs[0].cnt, 0, NBLOCKS * 4); memset(bufs[1].cnt, 0, NBLOCKS * 4);
  memset(bufs[0].bm, 0, BW * 8); bufs[0].bm[0] = 1; bufs[0].cnt[0] = 1;
  bufs[0].layer = 0; bufs[1].layer = -1;
  memset(bufs[0].si, 0, NSEG * sizeof(SI)); bufs[0].si[0].pop = 1;
  memset(meta_Dsi, 0, NSEG * sizeof(SI)); meta_Dsi[0].pop = 1;
  for (u64 k = 0; k < NSEG; k++) bufs[0].state[k] = 2;
  prev_i = 0; ncomp = 1; Lsize[0] = 1; ctime_[0] = 0;
  meta_D = 0; atomic_store(&g_metaD, 0);
}

// give up on the checkpoint: forget it and start from scratch (the caller then runs fresh_state)
static int scratch(const char *why) {
  logf_("ERROR: %s; starting from scratch", why);
  wipe_ckdir_layers(-1, -1);
  char mp[4400]; snprintf(mp, sizeof mp, "%s/meta.json", CK_DIR); unlink(mp);
  for (int t = 0; t <= MAXT + 1; t++) { fitem[t].have = 0; fitem[t].nreps = 0; free(fitem[t].reps); fitem[t].reps = NULL; }
  return 0;
}

// returns 1 if resumed
static int try_resume(void) {
  char mp[4400]; snprintf(mp, sizeof mp, "%s/meta.json", CK_DIR);
  FILE *f = fopen(mp, "r");
  if (!f) { if (access(CK_DIR, F_OK) == 0) wipe_ckdir_layers(-1, -1); return 0; }
  fseek(f, 0, SEEK_END); long sz = ftell(f); fseek(f, 0, SEEK_SET);
  char *txt = malloc((size_t)sz + 1); if (!txt) die(3, "oom");
  if (fread(txt, 1, (size_t)sz, f) != (size_t)sz) die(4, "cannot read %s", mp);
  txt[sz] = 0; fclose(f);
  const char *p = txt; JN *m = jparse(&p);
  if (!m || m->ty != 'o') return scratch("checkpoint meta is unparsable");
  JN *fm = jget(m, "format");
  if (!fm || fm->ty != 's' || strcmp(fm->str, "layers3-meta-v2"))
    die(2, "checkpoint meta %s has format '%s', expected layers3-meta-v2 (treated as fingerprint mismatch); refusing to overwrite", mp, fm && fm->ty == 's' ? fm->str : "?");
  JN *x;
#define MGET(var, key) do { x = jget(m, key); if (!x || (x->ty != 'n' && x->ty != 'b')) return scratch("meta lacks " key); var = x->num; } while (0)
  u64 mr, mtmax, mn, mfnv, mseg, mff, mfm, mfin, mrc, mD;
  MGET(mr, "r"); MGET(mtmax, "tmax"); MGET(mn, "n"); MGET(mfnv, "cols_fnv"); MGET(mseg, "seglog");
  MGET(mff, "free_from"); MGET(mfm, "free_max"); MGET(mfin, "finished"); MGET(mrc, "resume_count");
  if (mr != (u64)R || mtmax != (u64)TMAX || mn != (u64)N || mfnv != COLS_FNV || mseg != (u64)SEGLOG || mff != (u64)FREE_FROM || mfm != (u64)FREE_MAX)
    die(2, "checkpoint fingerprint mismatch in %s (meta r=%llu tmax=%llu n=%llu seglog=%llu free_from=%llu free_max=%llu); refusing to overwrite",
        mp, (unsigned long long)mr, (unsigned long long)mtmax, (unsigned long long)mn, (unsigned long long)mseg, (unsigned long long)mff, (unsigned long long)mfm);
  resume_count = mrc;
  if (mfin) { logf_("checkpoint meta says finished; recomputing from scratch"); wipe_ckdir_layers(-1, -1); return 0; }
  MGET(mD, "durable_layer");
  JN *ls = jget(m, "L_sizes"), *fr = jget(m, "free"), *dp = jget(m, "durable_seg_pop"), *dh = jget(m, "durable_seg_hash"), *ns = jget(m, "next_segs");
  if (mD > (u64)TMAX || !ls || ls->ty != 'a' || ls->cnt != mD + 1 || !fr || fr->ty != 'a' || !dp || dp->ty != 'a' || dp->cnt != NSEG ||
      !dh || dh->ty != 'a' || dh->cnt != NSEG || !ns || ns->ty != 'a')
    return scratch("meta structure invalid");
  int D = (int)mD;
  for (size_t k = 0; k < NSEG; k++) if (dp->kids[k]->ty != 'n' || dh->kids[k]->ty != 'n') return scratch("meta segment arrays invalid");
  for (int t = 0; t <= D; t++) if (ls->kids[t]->ty != 'n') return scratch("meta L_sizes invalid");
  u64 sumpop = 0; for (size_t k = 0; k < NSEG; k++) sumpop += dp->kids[k]->num;
  if (sumpop != ls->kids[D]->num) return scratch("meta popcounts inconsistent with L_sizes");
  double tl = now();
  size_t base = D >= 1 ? NSEG : 0;     // L_0 is virtual: nothing to load for D=0
  if (D == 0) fresh_state();           // before loading: sets up L_0 and clears block counts of both buffers
  ltasks = calloc(base + ns->cnt + 1, sizeof(LoadTask)); if (!ltasks) die(3, "oom");
  if (D >= 1) for (size_t k = 0; k < NSEG; k++) ltasks[k] = (LoadTask){0, k, dp->kids[k]->num, dh->kids[k]->num, D, 0};
  size_t nn = 0;
  u8 *seen = calloc(NSEG, 1); if (!seen) die(3, "oom");
  for (size_t i = 0; i < ns->cnt; i++) {
    JN *e = ns->kids[i];
    // any malformed, out-of-range or duplicated entry means the meta is corrupt: forget the checkpoint and start over
    if (e->ty != 'a' || e->cnt != 3 || e->kids[0]->ty != 'n' || e->kids[1]->ty != 'n' || e->kids[2]->ty != 'n') { free(seen); return scratch("meta next_segs entry malformed"); }
    if (e->kids[0]->num >= NSEG) { free(seen); return scratch("meta next_segs segment index out of range"); }
    if (seen[e->kids[0]->num]) { free(seen); return scratch("meta next_segs lists a segment twice"); }
    seen[e->kids[0]->num] = 1;
    ltasks[base + nn++] = (LoadTask){1, e->kids[0]->num, e->kids[1]->num, e->kids[2]->num, D + 1, 0};
  }
  free(seen);
  nlt = base + nn;
  run_loaders();
  for (size_t k = 0; k < base; k++) if (!ltasks[k].ok) {
    resume_rejected++;
    char why[200]; snprintf(why, sizeof why, "checkpoint layer %d segment %llu invalid (size/popcount/hash); layer D unusable", D, (unsigned long long)k);
    return scratch(why);
  }
  // restore state
  for (int t = 0; t <= D; t++) { Lsize[t] = ls->kids[t]->num; ctime_[t] = 0; }
  if (D == 0) compute_free(&bufs[0], 0, 1);
  else for (size_t i = 0; i < fr->cnt; i++) {
    JN *e = fr->kids[i]; JN *tt = jget(e, "t"), *cc = jget(e, "count"), *rr = jget(e, "reps");
    if (!tt || !cc || !rr || rr->ty != 'a' || tt->num > (u64)D) return scratch("meta free item invalid");
    FreeItem *fi = &fitem[tt->num]; fi->have = 1; fi->count = cc->num; fi->nreps = (int)rr->cnt; fi->reps = malloc((rr->cnt ? rr->cnt : 1) * 8);
    for (size_t q = 0; q < rr->cnt; q++) fi->reps[q] = rr->kids[q]->num;
  }
  prev_i = 0; ncomp = D + 1; meta_D = D; atomic_store(&g_metaD, D);
  bufs[0].layer = D;
  for (u64 k = 0; k < NSEG; k++) { bufs[0].state[k] = 2; bufs[0].si[k] = (SI){dp->kids[k]->num, dh->kids[k]->num}; meta_Dsi[k] = bufs[0].si[k]; }
  bufs[1].layer = D + 1;
  u64 nload = 0;
  for (size_t i = 0; i < nn; i++) {
    LoadTask *T = &ltasks[base + i];
    if (!T->ok) { resume_rejected++; logf_("note: checkpoint layer %d segment %llu invalid (size/popcount/hash); will recompute", D + 1, (unsigned long long)T->seg); continue; }
    bufs[1].state[T->seg] = 2; bufs[1].si[T->seg] = (SI){T->want_pop, T->want_hash}; atomic_store(&bufs[1].done_ns[T->seg], 1);
    meta_listed[T->seg] = 1; meta_list_si[T->seg] = bufs[1].si[T->seg]; nload++;
  }
  resumed_from = D; resume_count++;
  resume_load_sec = now() - tl;
  logf_("RESUMED from checkpoint: durable layer %d (|L|=%llu), %llu/%llu segments of layer %d restored, load %.1fs",
        D, (unsigned long long)Lsize[D], (unsigned long long)nload, (unsigned long long)NSEG, D + 1, resume_load_sec);
  int promoted = 0;
  if (nload == NSEG) { // layer D+1 complete: promote
    u64 s = 0; for (u64 k = 0; k < NSEG; k++) s += bufs[1].si[k].pop;
    Lsize[D + 1] = s; ctime_[D + 1] = 0; compute_free(&bufs[1], D + 1, s);
    prev_i = 1; ncomp = D + 2; meta_D = D + 1; atomic_store(&g_metaD, D + 1);
    memcpy(meta_Dsi, bufs[1].si, NSEG * sizeof(SI)); memset(meta_listed, 0, NSEG); memset(meta_list_si, 0, NSEG * sizeof(SI));
    bufs[0].layer = -1; for (u64 k = 0; k < NSEG; k++) { bufs[0].state[k] = 0; atomic_store(&bufs[0].done_ns[k], 0); atomic_store(&bufs[0].claim_ns[k], 0); }
    logf_("layer %d fully restored; promoted to durable layer", D + 1);
    promoted = 1;
  } else resume_keep = 1;
  // Commit the validated state (drops invalid segments, records the promotion) BEFORE deleting anything the old meta
  // still refers to: a kill between the two steps then leaves either the old meta with all its files, or the new one.
  testpt(promoted ? "promote_before_meta" : "resume_before_meta");
  { SB s; sb_init(&s); build_meta(&s, meta_D, meta_Dsi, meta_listed, meta_list_si, 0);
    if (write_meta_text(&s)) die(4, "cannot write meta: %s", strerror(errno));
    free(s.p); last_meta = now(); ck_touched = 1; }
  testpt(promoted ? "promote_after_meta" : "resume_after_meta");
  wipe_ckdir_layers(meta_D, meta_D + 1);
  jan_done = meta_D;
  free(txt);
  return 1;
}

// ------------------------------------------------------------------ output
static int write_out(int T) {
  SB s; sb_init(&s);
  int full = Lsize[T] == FULLV;
  sb_printf(&s, "{\n \"format\": \"layers3-v1\",\n \"r\": %d, \"n\": %d, \"tmax\": %d,\n \"cols\": [", R, N, TMAX);
  for (int i = 0; i < N; i++) sb_printf(&s, "%s%llu", i ? "," : "", (unsigned long long)cols[i]);
  sb_printf(&s, "],\n \"L_sizes\": [");
  for (int t = 0; t <= T; t++) sb_printf(&s, "%s%llu", t ? "," : "", (unsigned long long)Lsize[t]);
  sb_printf(&s, "],\n \"layers_computed\": %d,\n \"full\": %s,\n", T, full ? "true" : "false");
  if (full) sb_printf(&s, " \"covering_radius\": %d,\n", T); else sb_printf(&s, " \"covering_radius\": null,\n");
  sb_printf(&s, " \"complement_size_last\": %llu,\n \"free_from\": %d, \"free_max\": %d,\n \"free\": [", (unsigned long long)(FULLV - Lsize[T]), FREE_FROM, FREE_MAX);
  int any = 0; for (int t = FREE_FROM < 0 ? 0 : FREE_FROM; t <= T; t++) if (fitem[t].have) any = 1;
  if (any) { sb_printf(&s, "\n"); emit_free(&s, T, " "); sb_printf(&s, "\n ]\n}\n"); } else sb_printf(&s, "]\n}\n");
  int rc = atomic_write_file(OUT_PATH, s.p, s.n, 1, "out_before_rename", "out_after_rename");
  free(s.p);
  return rc;
}
static void write_stats(int T, double wall) {
  if (!STATS_PATH) return;
  struct rusage ru; getrusage(RUSAGE_SELF, &ru);
  SB s; sb_init(&s);
  sb_printf(&s, "{\"host\":\"%s\", \"pid\":%d, \"r\":%d, \"n\":%d, \"tmax\":%d, \"layers_computed\":%d, \"threads\":%d, \"ckpt_writers\":%d,\n", HOST, (int)PID, R, N, TMAX, T, J, NWRITERS);
  sb_printf(&s, " \"start_unix\":%.0f, \"end_unix\":%.0f, \"wall_sec\":%.2f, \"peak_rss_kb\":%ld,\n", T0_UNIX, T0_UNIX + wall, wall, ru.ru_maxrss);
  sb_printf(&s, " \"layer_seconds\":[");
  for (int t = 0; t <= T; t++) { if (t) sb_printf(&s, ","); if (lsec[t] < 0) sb_printf(&s, "null"); else sb_printf(&s, "%.2f", lsec[t]); }
  sb_printf(&s, "],\n \"layer_compute_seconds\":[");
  for (int t = 0; t <= T; t++) { if (t) sb_printf(&s, ","); if (lsec[t] < 0) sb_printf(&s, "null"); else sb_printf(&s, "%.2f", lsec[t] - thr_layer[t] > 0 ? lsec[t] - thr_layer[t] : 0.0); }
  sb_printf(&s, "],\n \"seg_done_sec\":[");   // per computed layer: [min,p10,p50,p90,max] completion time of its segments, seconds since layer start
  for (int t = 0; t <= T; t++) { if (t) sb_printf(&s, ",");
    if (lsec[t] < 0 || !segq_n[t]) sb_printf(&s, "null");
    else sb_printf(&s, "[%.2f,%.2f,%.2f,%.2f,%.2f]", segq[t][0], segq[t][1], segq[t][2], segq[t][3], segq[t][4]); }
  sb_printf(&s, "],\n \"bwlog\":%d, \"seglog\":%d, \"unit_blocks\":%llu, \"nseg\":%llu,\n", BWLOG, SEGLOG, (unsigned long long)UB, (unsigned long long)NSEG);
  sb_printf(&s, " \"ckpt_enabled\":%s, \"ckpt_start_sec\":%.1f, \"ckpt_throttle_sec\":%.1f, \"meta_interval_sec\":%.1f,\n", ck_enabled ? "true" : "false", CK_START, CK_THROTTLE, META_INT);
  sb_printf(&s, " \"ckpt_write_bytes\":%llu, \"ckpt_write_thread_sec\":%.2f, \"ckpt_write_wall_sec\":%.2f, \"ckpt_seg_write_max_sec\":%.2f, \"ckpt_segments_written\":%llu, \"ckpt_segments_sparse\":%llu,\n",
            (unsigned long long)write_bytes, write_thread_sec, write_wall, write_job_max, (unsigned long long)segs_written, (unsigned long long)segs_sparse);
  sb_printf(&s, " \"watchdog_releases\":%llu, \"dir_fsync_unsupported\":%llu, \"resume_segments_rejected\":%llu,\n", (unsigned long long)watchdog_releases, (unsigned long long)atomic_load(&dir_fsync_unsupported), (unsigned long long)resume_rejected);
  sb_printf(&s, " \"resumes\":%llu, \"resumed_this_run\":%s, ", (unsigned long long)resume_count, resumed_from >= 0 ? "true" : "false");
  if (resumed_from >= 0) sb_printf(&s, "\"resumed_from_layer\":%d, ", resumed_from); else sb_printf(&s, "\"resumed_from_layer\":null, ");
  sb_printf(&s, "\"resume_load_sec\":%.2f,\n \"max_durable_lag_sec\":%.2f, \"max_wall_exposure_sec\":%.2f, \"max_exposure_at_claim_sec\":%.2f, \"max_seg_compute_sec\":%.2f, \"throttle_sec\":%.2f, \"throttle_events\":%llu, \"test_write_delay_us\":%ld}\n",
            resume_load_sec, max_wall_X, max_wall_X, max_claim_X, max_seg_sec, throttle_sec, (unsigned long long)throttle_events, TEST_DELAY_US);
  if (atomic_write_file(STATS_PATH, s.p, s.n, 0, NULL, NULL)) logf_("warning: cannot write stats %s: %s", STATS_PATH, strerror(errno));
  free(s.p);
}

// ------------------------------------------------------------------ main
static void usage(void) {
  fprintf(stderr, "usage: layers3 -r R -t TMAX -c COLS -o OUT.json [-j THREADS] [-k CKPTDIR] [-p PROGRESS.json] [-s STATS.json]\n"
                  "               [-f FREE_FROM] [-m FREE_MAX] [-b BWLOG] [-g SEGLOG] [--ckpt-start SEC] [--ckpt-throttle SEC]\n"
                  "               [--meta-interval SEC] [--ckpt-writers N]\n");
}
static int cmp_u64(const void *a, const void *b) { u64 x = *(const u64 *)a, y = *(const u64 *)b; return x < y ? -1 : x > y; }
static u64 *map_bitmap(u64 words) {
  void *p = mmap(NULL, words * 8, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (p == MAP_FAILED) return NULL;
  madvise(p, words * 8, MADV_HUGEPAGE);
  return p;
}
static int parse_int(const char *s, long lo, long hi, const char *name) {
  char *e; long v = strtol(s, &e, 10);
  if (*s == 0 || *e || v < lo || v > hi) { fprintf(stderr, "layers3: bad value for %s: %s (range %ld..%ld)\n", name, s, lo, hi); exit(2); }
  return (int)v;
}
static double parse_dbl(const char *s, const char *name) {
  char *e; double v = strtod(s, &e);
  if (*s == 0 || *e || v < 0) { fprintf(stderr, "layers3: bad value for %s: %s\n", name, s); exit(2); }
  return v;
}
static void hold_and_die(int t) {   // test hook, see header
  double t0 = now();
  for (;;) {
    pthread_mutex_lock(&mu);
    int ok = meta_D == t - 1;
    for (u64 k = 0; ok && k < NSEG; k++) if (!meta_listed[k]) ok = 0;
    pthread_mutex_unlock(&mu);
    if (ok) { fprintf(stderr, "layers3: TEST hold: layer %d fully listed in meta (D=%d); aborting\n", t, t - 1); _exit(99); }
    if (now() - t0 > 120) { fprintf(stderr, "layers3: TEST hold timed out\n"); _exit(98); }
    usleep(10000);
  }
}

int main(int argc, char **argv) {
  T0 = mono(); { struct timespec tt; clock_gettime(CLOCK_REALTIME, &tt); T0_UNIX = tt.tv_sec + 1e-9 * tt.tv_nsec; }
  gethostname(HOST, sizeof HOST); HOST[sizeof HOST - 1] = 0; PID = getpid();
  R = -1; TMAX = -1; J = (int)sysconf(_SC_NPROCESSORS_ONLN); if (J < 1) J = 1; if (J > 1024) J = 1024;
  FREE_FROM = -1; FREE_MAX = 1024; BWLOG = 10; SEGLOG = 27; NWRITERS = 4;
  static struct option lo[] = {{"ckpt-start", 1, 0, 1000}, {"ckpt-throttle", 1, 0, 1001}, {"meta-interval", 1, 0, 1002}, {"ckpt-writers", 1, 0, 1003}, {0, 0, 0, 0}};
  int c;
  while ((c = getopt_long(argc, argv, "r:t:c:o:j:k:p:s:f:m:b:g:", lo, NULL)) != -1) {
    switch (c) {
      case 'r': R = parse_int(optarg, -1000, 1000, "-r"); break;
      case 't': TMAX = parse_int(optarg, -1000, 100000, "-t"); break;
      case 'c': COLS_PATH = optarg; break;
      case 'o': OUT_PATH = optarg; break;
      case 'j': J = parse_int(optarg, 1, 1024, "-j"); break;
      case 'k': CK_DIR = optarg; break;
      case 'p': PROG_PATH = optarg; break;
      case 's': STATS_PATH = optarg; break;
      case 'f': FREE_FROM = parse_int(optarg, 0, 100000, "-f"); break;
      case 'm': FREE_MAX = parse_int(optarg, 0, 10000000, "-m"); break;
      case 'b': BWLOG = parse_int(optarg, 0, 40, "-b"); break;
      case 'g': SEGLOG = parse_int(optarg, 0, 60, "-g"); break;
      case 1000: CK_START = parse_dbl(optarg, "--ckpt-start"); break;
      case 1001: CK_THROTTLE = parse_dbl(optarg, "--ckpt-throttle"); break;
      case 1002: META_INT = parse_dbl(optarg, "--meta-interval"); break;
      case 1003: NWRITERS = parse_int(optarg, 1, 256, "--ckpt-writers"); break;
      default: usage(); return 2;
    }
  }
  if (R < 0 || TMAX < 0 || !COLS_PATH || !OUT_PATH) { usage(); return 2; }
  if (R < 10 || R > 41) die(2, "r=%d out of range 10..41", R);
  if (TMAX > MAXT) die(2, "tmax=%d out of range 0..%d", TMAX, MAXT);
  if (FREE_FROM < 0) FREE_FROM = TMAX + 1;
  { const char *e = getenv("LAYERS3_TEST_WRITE_DELAY_US"); if (e) TEST_DELAY_US = atol(e); }
  { const char *e = getenv("LAYERS3_TEST_META_DELAY_US"); if (e) META_DELAY_US = atol(e); }
  { const char *e = getenv("LAYERS3_TEST_PROG_INT"); if (e && *e) PROG_INT = atof(e); }
  { const char *e = getenv("LAYERS3_TEST_LAG_LOG"); if (e && *e) LAG_LOG = e; }
  { const char *e = getenv("LAYERS3_TEST_FAIL_THREAD"); if (e && *e) TEST_FAIL_THREAD = atoi(e); }
  { const char *e = getenv("LAYERS3_TEST_HOLD_LAYER"); if (e && *e) HOLD_LAYER = atoi(e); }
  { const char *e = getenv("LAYERS3_TEST_ABORT_AT");
    if (e && *e) { snprintf(ABORT_NAME, sizeof ABORT_NAME, "%s", e); char *colon = strchr(ABORT_NAME, ':'); if (colon) { *colon = 0; ABORT_NTH = atol(colon + 1); } ABORT_SET = 1; } }
  // columns: whitespace-separated decimal integers, nothing else. Any other byte -> exit 2, read error -> exit 4.
  int n = 0;
  { FILE *f = fopen(COLS_PATH, "r"); if (!f) die(2, "cannot open cols %s: %s", COLS_PATH, strerror(errno));
    int ch, in = 0; u64 v = 0;
    while ((ch = fgetc(f)) != EOF) {
      if (ch >= '0' && ch <= '9') {
        u64 dg = (u64)(ch - '0');
        if (v > (UINT64_MAX - dg) / 10) die(2, "column value in %s does not fit in 64 bits", COLS_PATH);
        v = v * 10 + dg; in = 1;
      } else if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' || ch == '\v' || ch == '\f') {
        if (in) { if (n >= MAXN) die(2, "more than %d columns", MAXN); cols[n++] = v; in = 0; v = 0; }
      } else die(2, "unexpected byte 0x%02x in cols file %s (after %d columns)", ch, COLS_PATH, n);
    }
    if (ferror(f)) die(4, "read error on cols file %s: %s", COLS_PATH, strerror(errno));
    if (!feof(f)) die(4, "cols file %s: reading stopped before end of file", COLS_PATH);
    if (in) { if (n >= MAXN) die(2, "more than %d columns", MAXN); cols[n++] = v; }
    fclose(f); }
  N = n;
  if (N < 1) die(2, "no columns");
  for (int i = 0; i < N; i++) if (cols[i] >> R) die(2, "column %d (%llu) does not fit in r=%d bits", i, (unsigned long long)cols[i], R);
  COLS_FNV = 1469598103934665603ULL;
  for (int i = 0; i < N; i++) for (int b = 0; b < 8; b++) { COLS_FNV ^= (cols[i] >> (8 * b)) & 0xff; COLS_FNV *= 1099511628211ULL; }
  // geometry
  NWORDS = 1ULL << (R - 6);
  if (BWLOG > R - 6) BWLOG = R - 6;
  if (BWLOG < 3 || BWLOG > 20) die(2, "bwlog out of range 3..20");
  if (SEGLOG > R - 6) SEGLOG = R - 6;
  if (SEGLOG < BWLOG) die(2, "seglog (%d) must be >= bwlog (%d)", SEGLOG, BWLOG);
  BW = 1ULL << BWLOG; NBLOCKS = NWORDS / BW; BLKBITS = (u32)(BW * 64);
  SEGW = 1ULL << SEGLOG; NSEG = NWORDS / SEGW; BPS = SEGW / BW; FULLV = 1ULL << R;
  if (NSEG > MAXNSEG) die(2, "geometry rejected: %llu segments (> %llu); raise -g", (unsigned long long)NSEG, (unsigned long long)MAXNSEG);
  if (2 * NBLOCKS * 4 > MAXCNTBYTES) die(2, "geometry rejected: block counters would take %llu MiB (> %llu MiB); raise -b",
                                         (unsigned long long)(2 * NBLOCKS * 4 >> 20), (unsigned long long)(MAXCNTBYTES >> 20));
  { // everything except the two bitmaps, from the actual allocations: block counters, per-thread buffers, per-segment tables
    // (state, si, done_ns, claim_ns x2 buffers; cand/meta/sc tables; g_skip, g_segunits; job queue; segtmp; resume parse: ~1 KiB per segment
    // is a generous upper bound), segment meta text, free-rep lists (one list per layer >= FREE_FROM, FREE_MAX x 8 B each) and a fixed 16 MiB.
    u64 nfree = (TMAX >= FREE_FROM) ? (u64)(TMAX - FREE_FROM + 1) : 0;
    u64 extra = 2 * NBLOCKS * 4 + (u64)J * BW * 8 + NSEG * 1024 + nfree * (u64)FREE_MAX * 8 + (16ULL << 20);
    if (extra > MAXEXTRABYTES) die(2, "geometry rejected: memory besides the bitmaps would be %llu MiB (counters %llu MiB, %d thread buffers x %llu KiB, %llu segments, free lists %llu MiB) > %llu MiB; lower -j/-m or raise -b/-g",
                                   (unsigned long long)(extra >> 20), (unsigned long long)(2 * NBLOCKS * 4 >> 20), J, (unsigned long long)(BW * 8 >> 10), (unsigned long long)NSEG,
                                   (unsigned long long)(nfree * (u64)FREE_MAX * 8 >> 20), (unsigned long long)(MAXEXTRABYTES >> 20)); }
  UB = BPS < 64 ? BPS : 64;
  while (UB > 1 && NBLOCKS / UB < (u64)(8 * J)) UB >>= 1;
  UPS = BPS / UB; NUNITS = NBLOCKS / UB;
  ck_enabled = CK_DIR != NULL;
  // unique nonzero columns, ascending
  { u64 tmpc[MAXN]; memcpy(tmpc, cols, N * 8); qsort(tmpc, N, 8, cmp_u64);
    NUC = 0;
    u64 last = 0; int have = 0;
    for (int i = 0; i < N; i++) { u64 v = tmpc[i]; if (!v || (have && v == last)) continue; last = v; have = 1;
      u64 w = v >> 6; HB[NUC] = w >> BWLOG; WLO[NUC] = w & (BW - 1); LC[NUC] = (int)(v & 63); NUC++; } }
  logf_("r=%d n=%d (unique nonzero %d) tmax=%d J=%d bwlog=%d seglog=%d nseg=%llu unit_blocks=%llu ckpt=%s", R, N, NUC, TMAX, J, BWLOG, SEGLOG, (unsigned long long)NSEG, (unsigned long long)UB, ck_enabled ? CK_DIR : "off");
  // memory
  for (int i = 0; i < 2; i++) {
    bufs[i].bm = map_bitmap(NWORDS);
    if (!bufs[i].bm) die(3, "cannot allocate bitmap %d (%llu bytes)", i, (unsigned long long)(NWORDS * 8));
    bufs[i].cnt = calloc(NBLOCKS, 4); bufs[i].state = calloc(NSEG, 1); bufs[i].si = calloc(NSEG, sizeof(SI));
    bufs[i].done_ns = calloc(NSEG, 8); bufs[i].claim_ns = calloc(NSEG, 8);
    if (!bufs[i].cnt || !bufs[i].state || !bufs[i].si || !bufs[i].done_ns || !bufs[i].claim_ns) die(3, "cannot allocate block marks");
    bufs[i].layer = -1;
  }
  cand_si = calloc(NSEG, sizeof(SI)); meta_Dsi = calloc(NSEG, sizeof(SI)); meta_list_si = calloc(NSEG, sizeof(SI)); meta_listed = calloc(NSEG, 1);
  sc_listed = calloc(NSEG, 1); sc_si = calloc(NSEG, sizeof(SI)); sc_list_si = calloc(NSEG, sizeof(SI));
  g_skip = calloc(NSEG, 1); g_segunits = calloc(NSEG, 8);
  jq_cap = 2 * NSEG + 16; jq = calloc(jq_cap, sizeof(Job));
  segtmp = malloc(NSEG * sizeof(double));
  if (!cand_si || !meta_Dsi || !meta_list_si || !meta_listed || !sc_listed || !sc_si || !sc_list_si || !g_skip || !g_segunits || !jq || !segtmp) die(3, "oom");
  for (int i = 0; i < J && i < 1024; i++) { tmpbuf[i] = aligned_alloc(64, BW * 8); if (!tmpbuf[i]) die(3, "oom"); }
  for (int t = 0; t <= MAXT + 1; t++) { lsec[t] = -1; rec_claim[t] = ~0ULL; }
  // start state
  int resumed = 0;
  if (ck_enabled) resumed = try_resume();
  if (!resumed) {
    fresh_state();
    compute_free(&bufs[0], 0, 1);
  }
  if (LAG_LOG) lag_fp = fopen(LAG_LOG, "a");
  pthread_t wth[256], mth, jth;
  if (ck_enabled) for (int i = 0; i < NWRITERS; i++) spawn(&wth[i], writer_main, NULL, "checkpoint writer");
  spawn(&mth, mgr_main, NULL, "manager");
  if (ck_enabled) spawn(&jth, janitor_main, NULL, "janitor");

  // ---------------------------------------------------------------- layer loop
  for (int t = ncomp; t <= TMAX; t++) {
    if (Lsize[t - 1] == FULLV) break;
    double ts = now();
    pthread_mutex_lock(&mu);
    Buf *Nb = &bufs[prev_i ^ 1];
    if (!resume_keep) {
      while (Nb->inflight > 0) { waiting_write = 1; pthread_cond_wait(&cv, &mu); }
      waiting_write = 0;
      if (ck_enabled && Nb->layer >= 1 && Nb->layer > meta_D && Nb->layer > cand_layer) {
        int all2 = 1; for (u64 k = 0; k < NSEG; k++) if (Nb->state[k] != 2) { all2 = 0; break; }
        if (all2) { cand_layer = Nb->layer; memcpy(cand_si, Nb->si, NSEG * sizeof(SI)); }
      }
      if (ck_enabled && Nb->layer >= 1 && Nb->layer > meta_D) {   // the buffer is about to lose layer Nb->layer: remember its at-risk claim
        u64 m = ~0ULL;
        for (u64 k = 0; k < NSEG; k++) { u64 c = atomic_load(&Nb->claim_ns[k]); if (c && c < m && !(Nb->layer == meta_D + 1 && meta_listed[k])) m = c; }
        rec_claim[Nb->layer] = m;
      }
      Nb->layer = t;
      memset(Nb->state, 0, NSEG); memset(Nb->si, 0, NSEG * sizeof(SI));
      for (u64 k = 0; k < NSEG; k++) { atomic_store(&Nb->done_ns[k], 0); atomic_store(&Nb->claim_ns[k], 0); }
    }
    for (u64 k = 0; k < NSEG; k++) { g_skip[k] = (Nb->state[k] == 2); atomic_store(&g_segunits[k], 0); }
    resume_keep = 0;
    g_prevbm = bufs[prev_i].bm; g_pcnt = bufs[prev_i].cnt; g_nextbm = Nb->bm; g_ncnt = Nb->cnt; g_nextbuf = Nb;
    atomic_store(&g_next_unit, 0); atomic_store(&g_units_done, 0);
    cur_layer = t; computing = 1;
    pthread_mutex_unlock(&mu);
    ts = now();
    pthread_t th[1024];
    for (int i = 0; i < J; i++) spawn(&th[i], worker, (void *)(intptr_t)i, "compute worker");
    for (int i = 0; i < J; i++) pthread_join(th[i], NULL);
    u64 cnt = 0; for (u64 b = 0; b < NBLOCKS; b++) cnt += Nb->cnt[b];
    if (segtmp) { // completion-time distribution of the segments computed in this layer (seconds since layer start)
      size_t m = 0;
      for (u64 k = 0; k < NSEG; k++) { u64 d = atomic_load(&Nb->done_ns[k]); if (!g_skip[k] && d) segtmp[m++] = (double)(d - 1) * 1e-9 - ts; }
      if (m) {
        static const double qs[5] = {0, 0.1, 0.5, 0.9, 1};
        qsort(segtmp, m, sizeof(double), cmp_dbl);
        for (int q = 0; q < 5; q++) segq[t][q] = segtmp[(size_t)(qs[q] * (double)(m - 1) + 0.5)];
        segq_n[t] = m;
      }
    }
    for (u64 k = 0; k < NSEG; k++) {   // longest segment (first unit claimed -> last unit done) computed in this layer
      u64 d = atomic_load(&Nb->done_ns[k]), c = atomic_load(&Nb->claim_ns[k]);
      if (!g_skip[k] && d && c && d > c && (double)(d - c) * 1e-9 > max_seg_sec) max_seg_sec = (double)(d - c) * 1e-9;
    }
    double te = now();
    pthread_mutex_lock(&mu);
    Lsize[t] = cnt; lsec[t] = te - ts; ctime_[t] = te;
    compute_free(Nb, t, cnt);
    prev_i ^= 1; ncomp = t + 1; computing = 0;
    pthread_mutex_unlock(&mu);
    logf_("layer %d |L_t|=%llu N_t=%llu layer_sec=%.1f", t, (unsigned long long)cnt, (unsigned long long)(cnt - Lsize[t - 1]), te - ts);
    if (PROG_PATH) { pthread_mutex_lock(&mu); mgr_last_prog = -100; pthread_mutex_unlock(&mu); }
    if (ck_enabled && HOLD_LAYER == t) hold_and_die(t);
  }
  int T = ncomp - 1;
  double wall = now();
  // ---------------------------------------------------------------- shutdown checkpoint machinery, write OUT
  pthread_mutex_lock(&mu);
  finalizing = 1; computing = 0; atomic_store(&abort_writes, 1); wstop = 1;
  pthread_cond_broadcast(&qcv); pthread_cond_broadcast(&cv);
  pthread_mutex_unlock(&mu);
  if (ck_enabled) for (int i = 0; i < NWRITERS; i++) pthread_join(wth[i], NULL);
  atomic_store(&mgr_stop, 1); pthread_join(mth, NULL); if (ck_enabled) pthread_join(jth, NULL);
  if (lag_fp) fclose(lag_fp);
  if (write_out(T)) die(4, "cannot write %s: %s", OUT_PATH, strerror(errno));
  if (ck_enabled && (ck_touched || resumed_from >= 0)) {
    // OUT is published; mark the checkpoint finished first, only then delete the segments
    SB s; sb_init(&s); build_meta(&s, 0, NULL, NULL, NULL, 1);
    if (write_meta_text(&s)) die(4, "cannot write final meta: %s", strerror(errno));
    free(s.p);
    testpt("finish_meta_done");
    DIR *d = opendir(CK_DIR);
    if (d) { struct dirent *e; while ((e = readdir(d))) {
      if (e->d_name[0] == 'L' && e->d_name[1] >= '0' && e->d_name[1] <= '9') { char p[4400]; snprintf(p, sizeof p, "%s/%s", CK_DIR, e->d_name); rm_rf(p); } }
      closedir(d); }
  }
  wall = now();
  write_stats(T, wall);
  write_progress(1);
  logf_("done: T=%d |L_T|=%llu full=%d wall=%.1fs", T, (unsigned long long)Lsize[T], Lsize[T] == FULLV, wall);
  return 0;
}
