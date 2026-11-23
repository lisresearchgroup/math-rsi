/*
 * verify_a: exact, complete decision of d(C) >= D for a binary linear code C
 * given by a generator matrix G (rows x N).  See METHOD.md for the proof of the criterion.
 *
 *   verify_a G.txt D out.json [threads]
 *
 * Criterion (H' = parity-check matrix of C with rho' = N-rank(G) rows, columns h_0..h_{N-1} in F_2^rho'):
 *   d >= D  <=>  every set of <= D-1 columns of H' is linearly independent.
 *   a = floor((D-1)/2).
 *   (i)  all subsets of size <= a have pairwise distinct sums       (covers dependent sets of size <= 2a)
 *   (ii) D even: no subset of size a+1 has a sum equal to the sum of a subset of size <= a
 *                                                                   (covers dependent sets of size 2a+1)
 * Both are tested exactly with a 2^rho' bit bitmap (atomic test-and-set in phase (i), read-only probes in phase (ii)).
 *
 * Exit codes: 0 decision made (true or false), 2 bad input/arguments, 3 not enough memory, 4 I/O error,
 *             5 internal self-check failure.
 */
#define _GNU_SOURCE
#include <errno.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

typedef uint64_t u64;
#define MAXN 1024
#define MAXK 64

static int N, ROWS, K, RHO, NT;
static u64 col[MAXN];            /* columns of H' as rho'-bit integers */
static u64 *bm;                  /* bitmap over F_2^rho' */
static u64 bm_words;
static size_t bm_bytes;

/* ---------------- small helpers ---------------- */
static double now_sec(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec * 1e-9;
}
static double T0;
#define LOG(...) do { fprintf(stderr, "[%8.2fs] ", now_sec() - T0); fprintf(stderr, __VA_ARGS__); fputc('\n', stderr); } while (0)
static void die(int code, const char *msg) {
    fprintf(stderr, "verify_a: error: %s\n", msg);
    exit(code);
}

/* ---------------- enumeration state ---------------- */
enum { M_INSERT = 0, M_PROBE = 1, M_FIND = 2 };
static int g_mode, g_k;                   /* current phase mode and exact subset size */
static u64 g_target;                      /* M_FIND: required sum */
static int g_exk, g_ex[MAXK];             /* M_FIND: subset to exclude (size g_exk, -1 = none) */

static volatile int g_stop;
static int g_zero_only;                   /* a == 0, D even: only the empty subset (sum 0) is in the set */
static pthread_mutex_t g_mu = PTHREAD_MUTEX_INITIALIZER;
static int g_found, g_fk, g_fidx[MAXK];
static u64 g_fsum;

typedef struct { int idx[MAXK]; u64 count; } Tctx;

static int nunits;
static int (*units)[2];
static volatile long g_next;

static void record(Tctx *t, int lastj, u64 sum) {
    pthread_mutex_lock(&g_mu);
    if (!g_found) {
        g_found = 1;
        g_fk = g_k;
        for (int i = 0; i + 1 < g_k; i++) g_fidx[i] = t->idx[i];
        g_fidx[g_k - 1] = lastj;
        g_fsum = sum;
        __atomic_store_n(&g_stop, 1, __ATOMIC_RELAXED);
    }
    pthread_mutex_unlock(&g_mu);
}

static inline int leaf_hit(int j, u64 s, Tctx *t) {
    /* returns 1 if this subset (prefix in t->idx, last element j) is a "hit" for the current mode */
    u64 w = s >> 6, b = 1ULL << (s & 63);
    switch (g_mode) {
    case M_INSERT: {
        u64 old = __atomic_fetch_or(&bm[w], b, __ATOMIC_RELAXED);
        return (old & b) != 0;
    }
    case M_PROBE:
        if (g_zero_only) return s == 0;
        return (bm[w] & b) != 0;
    default:
        if (s != g_target) return 0;
        if (g_exk == g_k) {  /* same size as excluded: compare */
            int same = 1;
            for (int i = 0; i + 1 < g_k; i++) if (t->idx[i] != g_ex[i]) { same = 0; break; }
            if (same && g_ex[g_k - 1] == j) return 0;
        }
        return 1;
    }
}

static void rec(Tctx *t, int depth, int start, u64 sum) {
    int rem = g_k - depth;
    if (rem == 1) {
        if (__atomic_load_n(&g_stop, __ATOMIC_RELAXED)) return;
        const int PF = 12;
        int j;
        for (j = start; j < N; j++) {
            if (j + PF < N && g_mode != M_FIND) {
                u64 pw = (sum ^ col[j + PF]) >> 6;
                __builtin_prefetch(&bm[pw], 1, 0);
            }
            u64 s = sum ^ col[j];
            if (leaf_hit(j, s, t)) {
                record(t, j, s);
                j++;
                break;
            }
        }
        t->count += (u64)(j - start);
        return;
    }
    for (int j = start; j <= N - rem; j++) {
        if (__atomic_load_n(&g_stop, __ATOMIC_RELAXED)) return;
        t->idx[depth] = j;
        rec(t, depth + 1, j + 1, sum ^ col[j]);
    }
}

static void *worker(void *arg) {
    Tctx *t = arg;
    for (;;) {
        long u = __atomic_fetch_add(&g_next, 1, __ATOMIC_RELAXED);
        if (u >= nunits || __atomic_load_n(&g_stop, __ATOMIC_RELAXED)) break;
        if (g_k == 1) {
            /* unit = single first element, which is the leaf itself */
            int j = units[u][0];
            u64 s = col[j];
            t->count++;
            if (leaf_hit(j, s, t)) record(t, j, s);
        } else {
            int i1 = units[u][0], i2 = units[u][1];
            t->idx[0] = i1;
            if (g_k == 2) {
                u64 s = col[i1] ^ col[i2];
                t->count++;
                t->idx[0] = i1;
                if (leaf_hit(i2, s, t)) record(t, i2, s);
            } else {
                t->idx[1] = i2;
                rec(t, 2, i2 + 1, col[i1] ^ col[i2]);
            }
        }
    }
    return NULL;
}

/* run one enumeration pass over all subsets of exact size k; returns total leaves visited */
static u64 run_pass(int mode, int k, int nthreads, const char *label) {
    g_mode = mode;
    g_k = k;
    g_next = 0;
    /* units: single elements for k=1, ordered pairs (i1<i2) with enough elements left for k>=2 */
    int cap = (k == 1) ? N : N * (N - 1) / 2;
    units = realloc(units, sizeof(int[2]) * (size_t)(cap > 0 ? cap : 1));
    nunits = 0;
    if (k == 1) {
        for (int i = 0; i < N; i++) { units[nunits][0] = i; units[nunits][1] = -1; nunits++; }
    } else {
        for (int i = 0; i < N; i++)
            for (int j = i + 1; j < N; j++)
                if (N - j - 1 >= k - 2) { units[nunits][0] = i; units[nunits][1] = j; nunits++; }
    }
    Tctx *ctx = calloc(nthreads, sizeof(Tctx));
    pthread_t *th = malloc(sizeof(pthread_t) * nthreads);
    if (!ctx || !th) die(3, "out of memory (thread contexts)");
    int started = 0;
    for (int i = 0; i < nthreads; i++) {
        if (pthread_create(&th[i], NULL, worker, &ctx[i]) != 0) break;
        started++;
    }
    if (started == 0) die(3, "cannot start threads");
    /* progress monitor: main thread polls the unit counter while workers run */
    double tl = now_sec();
    for (;;) {
        struct timespec ts = {0, 10 * 1000 * 1000};
        nanosleep(&ts, NULL);
        long nx = __atomic_load_n(&g_next, __ATOMIC_RELAXED);
        if (nx >= nunits + started || __atomic_load_n(&g_stop, __ATOMIC_RELAXED)) break;
        if (now_sec() - tl > 60) {
            LOG("%s size %d: units %ld/%d", label, k, nx > nunits ? (long)nunits : nx, nunits);
            tl = now_sec();
        }
    }
    u64 total = 0;
    for (int i = 0; i < started; i++) { pthread_join(th[i], NULL); total += ctx[i].count; }
    free(ctx);
    free(th);
    return total;
}

/* ---------------- G reading and linear algebra ---------------- */
static int W;                       /* words per row */
static u64 *Gw;                     /* original rows, ROWS x W */
static u64 *R;                      /* RREF rows, ROWS x W */
static int piv[MAXN], is_piv[MAXN];

static inline int getb(const u64 *r, int j) { return (r[j >> 6] >> (j & 63)) & 1; }
static inline void setb(u64 *r, int j) { r[j >> 6] |= 1ULL << (j & 63); }

static char *read_all(const char *path, size_t *len) {
    FILE *f = fopen(path, "rb");
    if (!f) { fprintf(stderr, "verify_a: cannot open %s: %s\n", path, strerror(errno)); exit(2); }
    size_t cap = 1 << 16, n = 0;
    char *buf = malloc(cap);
    for (;;) {
        if (n + 1 >= cap) { cap *= 2; buf = realloc(buf, cap); }
        size_t r = fread(buf + n, 1, cap - n - 1, f);
        if (r == 0) break;
        n += r;
    }
    fclose(f);
    buf[n] = 0;
    *len = n;
    return buf;
}

static void read_G(const char *path) {
    size_t len;
    char *buf = read_all(path, &len);
    /* split lines; strip CR and trailing blanks; ignore trailing empty lines only */
    int nl = 0, linecap = 4096;
    char **lines = malloc(sizeof(char *) * linecap);
    int *llen = malloc(sizeof(int) * linecap);
    size_t p = 0;
    while (p < len) {
        size_t q = p;
        while (q < len && buf[q] != '\n') q++;
        size_t e = q;
        while (e > p && (buf[e - 1] == '\r' || buf[e - 1] == ' ' || buf[e - 1] == '\t')) e--;
        if (nl >= linecap) { linecap *= 2; lines = realloc(lines, sizeof(char *) * linecap); llen = realloc(llen, sizeof(int) * linecap); }
        lines[nl] = buf + p;
        llen[nl] = (int)(e - p);
        nl++;
        p = q + 1;
    }
    while (nl > 0 && llen[nl - 1] == 0) nl--;
    if (nl == 0) die(2, "G.txt has no rows");
    N = llen[0];
    ROWS = nl;
    if (N < 1 || N > MAXN) die(2, "row length out of range (1..1024)");
    W = (N + 63) / 64;
    Gw = calloc((size_t)ROWS * W, sizeof(u64));
    for (int i = 0; i < ROWS; i++) {
        if (llen[i] != N) { fprintf(stderr, "verify_a: row %d has length %d, expected %d\n", i, llen[i], N); exit(2); }
        for (int j = 0; j < N; j++) {
            char c = lines[i][j];
            if (c == '1') setb(Gw + (size_t)i * W, j);
            else if (c != '0') { fprintf(stderr, "verify_a: row %d col %d: bad character\n", i, j); exit(2); }
        }
    }
    free(lines); free(llen); free(buf);
}

/* RREF of G; fills piv[0..K-1] (pivot column of RREF row i), is_piv[] */
static void rref(void) {
    R = malloc((size_t)ROWS * W * sizeof(u64));
    memcpy(R, Gw, (size_t)ROWS * W * sizeof(u64));
    int r = 0;
    for (int c = 0; c < N && r < ROWS; c++) {
        int p = -1;
        for (int i = r; i < ROWS; i++) if (getb(R + (size_t)i * W, c)) { p = i; break; }
        if (p < 0) continue;
        if (p != r) for (int w = 0; w < W; w++) { u64 tmp = R[(size_t)p * W + w]; R[(size_t)p * W + w] = R[(size_t)r * W + w]; R[(size_t)r * W + w] = tmp; }
        for (int i = 0; i < ROWS; i++)
            if (i != r && getb(R + (size_t)i * W, c))
                for (int w = 0; w < W; w++) R[(size_t)i * W + w] ^= R[(size_t)r * W + w];
        piv[r] = c;
        is_piv[c] = 1;
        r++;
    }
    K = r;
}

/* rank of rows of G plus extra vector c (given as word array) : returns 1 if c in rowspace(G) (via RREF) */
static int in_rowspace(const u64 *c) {
    u64 *t = malloc(W * sizeof(u64));
    memcpy(t, c, W * sizeof(u64));
    for (int i = 0; i < K; i++)
        if (getb(t, piv[i]))
            for (int w = 0; w < W; w++) t[w] ^= R[(size_t)i * W + w];
    int zero = 1;
    for (int w = 0; w < W; w++) if (t[w]) zero = 0;
    free(t);
    return zero;
}

static void build_H(void) {
    RHO = N - K;
    if (RHO > 62) { fprintf(stderr, "verify_a: N-rank = %d > 62 not supported\n", RHO); exit(2); }
    int fm[MAXN], nf = 0;
    for (int j = 0; j < N; j++) if (!is_piv[j]) fm[nf++] = j;
    memset(col, 0, sizeof col);
    for (int m = 0; m < nf; m++) col[fm[m]] = 1ULL << m;
    for (int i = 0; i < K; i++)
        for (int m = 0; m < nf; m++)
            if (getb(R + (size_t)i * W, fm[m])) col[piv[i]] |= 1ULL << m;
    /* self-check: every original row of G is orthogonal to every row of H' (xor of columns over support = 0) */
    for (int i = 0; i < ROWS; i++) {
        u64 s = 0;
        for (int j = 0; j < N; j++) if (getb(Gw + (size_t)i * W, j)) s ^= col[j];
        if (s) die(5, "internal: G row not in kernel of H'");
    }
}

/* ---------------- memory ---------------- */
static double avail_gib(void) {
    double best = -1;
    FILE *f = fopen("/proc/meminfo", "r");
    if (f) {
        char line[256];
        while (fgets(line, sizeof line, f)) {
            unsigned long long kb;
            if (sscanf(line, "MemAvailable: %llu kB", &kb) == 1) best = kb / 1048576.0;
        }
        fclose(f);
    }
    const char *cg[] = {"/sys/fs/cgroup/memory.max", "/sys/fs/cgroup/memory/memory.limit_in_bytes"};
    const char *cu[] = {"/sys/fs/cgroup/memory.current", "/sys/fs/cgroup/memory/memory.usage_in_bytes"};
    for (int k = 0; k < 2; k++) {
        FILE *g = fopen(cg[k], "r");
        if (!g) continue;
        unsigned long long lim;
        if (fscanf(g, "%llu", &lim) == 1 && lim < (1ULL << 60)) {
            double l = lim / 1073741824.0, used = 0;
            FILE *u = fopen(cu[k], "r");
            unsigned long long uu;
            if (u) { if (fscanf(u, "%llu", &uu) == 1) used = uu / 1073741824.0; fclose(u); }
            if (best < 0 || l - used < best) best = l - used;
        }
        fclose(g);
    }
    return best;
}

/* ---------------- output ---------------- */
static void write_json(const char *out, int d_ge_D, int D, const char *method, const char *work, const char *witness, int wweight) {
    char tmp[4096];
    snprintf(tmp, sizeof tmp, "%s.tmp.%d", out, (int)getpid());
    FILE *f = fopen(tmp, "w");
    if (!f) { fprintf(stderr, "verify_a: cannot write %s: %s\n", tmp, strerror(errno)); exit(4); }
    fprintf(f, "{\"n\":%d,\"k\":%d,\"rows\":%d,\"D\":%d,\"d_ge_D\":%s,\n \"method\":\"%s\",\n \"work\":%s,\n \"witness\":",
            N, K, ROWS, D, d_ge_D ? "true" : "false", method, work);
    if (witness) fprintf(f, "{\"codeword\":\"%s\",\"weight\":%d}}\n", witness, wweight);
    else fprintf(f, "null}\n");
    fflush(f);
    fsync(fileno(f));
    if (fclose(f) != 0) { fprintf(stderr, "verify_a: write error\n"); exit(4); }
    if (rename(tmp, out) != 0) { fprintf(stderr, "verify_a: rename failed: %s\n", strerror(errno)); exit(4); }
}

int main(int argc, char **argv) {
    if (argc < 4 || argc > 5) {
        fprintf(stderr, "usage: verify_a G.txt D out.json [threads]\n");
        return 2;
    }
    T0 = now_sec();
    char *endp;
    long Dl = strtol(argv[2], &endp, 10);
    if (*endp || Dl < 1 || Dl > 4096) die(2, "D must be an integer in 1..4096");
    int D = (int)Dl;
    NT = (int)sysconf(_SC_NPROCESSORS_ONLN);
    if (argc == 5) {
        long t = strtol(argv[4], &endp, 10);
        if (*endp || t < 1 || t > 1024) die(2, "threads must be 1..1024");
        NT = (int)t;
    }
    if (NT < 1) NT = 1;

    read_G(argv[1]);
    rref();
    build_H();
    int a = (D - 1) / 2;
    int even = (D % 2 == 0);
    int amax = a < N ? a : N;
    if (a + 1 > MAXK - 1) die(2, "D too large for subset stack (a+1 >= 63)");
    LOG("N=%d rows=%d rank=%d rho'=%d D=%d a=%d phases=%s threads=%d", N, ROWS, K, RHO, D, a, even ? "(i)+(ii)" : "(i)", NT);

    const char *method = even
        ? "H' columns: (i) all subsets of <=a columns have distinct sums, (ii) no (a+1)-subset sum equals a <=a-subset sum; complete, a=(D-2)/2"
        : "H' columns: all subsets of <=a columns have pairwise distinct sums (a=(D-1)/2); complete";
    char work[1024];
    u64 n1 = 0, n2 = 0;
    int fail = 0;
    int witness_phase = 0;

    int need_bitmap = (a >= 1);
    g_zero_only = (a == 0);
    if (need_bitmap) {
        bm_words = RHO >= 6 ? (1ULL << (RHO - 6)) : 1;
        bm_bytes = (size_t)bm_words * 8;
        double need = bm_bytes / 1073741824.0, av = avail_gib();
        const char *capenv = getenv("VERIFY_A_MAX_GIB");
        double cap = capenv ? atof(capenv) : 0;
        if ((cap > 0 && need > cap) || (av >= 0 && need > av * 0.95)) {
            fprintf(stderr, "verify_a: error: bitmap 2^%d bits needs %.3f GiB, available %.3f GiB%s; refusing (no approximation)\n",
                    RHO, need, av, cap > 0 ? " / cap set by VERIFY_A_MAX_GIB" : "");
            return 3;
        }
        bm = mmap(NULL, bm_bytes, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0);
        if (bm == MAP_FAILED) die(3, "mmap of bitmap failed");
#ifdef MADV_HUGEPAGE
        madvise(bm, bm_bytes, MADV_HUGEPAGE);
#endif
        bm[0] |= 1;  /* empty subset has sum 0 */
        LOG("bitmap %.3f GiB", need);
    }

    double t1 = now_sec();
    /* phase (i): insert all subsets of size 1..a */
    for (int k = 1; k <= amax && !fail; k++) {
        n1 += run_pass(M_INSERT, k, NT, "phase(i)");
        if (g_found) fail = 1;
        else LOG("phase(i) size %d done, total subsets %llu", k, (unsigned long long)n1);
    }
    double t2 = now_sec();
    if (fail) witness_phase = 1;
    /* phase (ii): D even, probe all (a+1)-subsets */
    if (!fail && even && a + 1 <= N) {
        n2 += run_pass(M_PROBE, a + 1, NT, "phase(ii)");
        if (g_found) { fail = 1; witness_phase = 2; }
        else LOG("phase(ii) done, %llu subsets", (unsigned long long)n2);
    }
    double t3 = now_sec();

    char *wstr = NULL;
    int wweight = 0;
    if (fail) {
        /* B = recorded subset, target sum v; find a different subset A (size <= a) with the same sum */
        int bk = g_fk, bidx[MAXK];
        memcpy(bidx, g_fidx, sizeof(int) * bk);
        u64 v = g_fsum;
        LOG("phase(%s) hit: |B|=%d sum=%llu; searching partner", witness_phase == 1 ? "i" : "ii", bk, (unsigned long long)v);
        int ak = -1, aidx[MAXK];
        if (v == 0 && bk > 0) ak = 0;      /* empty subset */
        g_exk = bk;
        memcpy(g_ex, bidx, sizeof(int) * bk);
        g_target = v;
        for (int k = 1; ak < 0 && k <= amax; k++) {
            g_found = 0; g_stop = 0;
            run_pass(M_FIND, k, NT, "partner");
            if (g_found) { ak = g_fk; memcpy(aidx, g_fidx, sizeof(int) * ak); }
        }
        if (ak < 0) die(5, "internal: partner subset not found");
        u64 *c = calloc(W, sizeof(u64));
        for (int i = 0; i < bk; i++) c[bidx[i] >> 6] ^= 1ULL << (bidx[i] & 63);
        for (int i = 0; i < ak; i++) c[aidx[i] >> 6] ^= 1ULL << (aidx[i] & 63);
        /* self-check the witness: nonzero, weight < D, H' c = 0, c in rowspace(G) */
        int w = 0;
        u64 s = 0;
        for (int j = 0; j < N; j++) if (getb(c, j)) { w++; s ^= col[j]; }
        if (w < 1) die(5, "internal: witness is zero");
        if (w >= D) die(5, "internal: witness weight >= D");
        if (s != 0) die(5, "internal: witness fails H' c = 0");
        if (!in_rowspace(c)) die(5, "internal: witness not in row space of G");
        wstr = malloc(N + 1);
        for (int j = 0; j < N; j++) wstr[j] = getb(c, j) ? '1' : '0';
        wstr[N] = 0;
        wweight = w;
        LOG("witness weight %d (checked: H'c=0, in rowspace(G), weight<D)", w);
        free(c);
    }
    double tend = now_sec();
    snprintf(work, sizeof work,
             "{\"rho_prime\":%d,\"a\":%d,\"phase1_subsets\":%llu,\"phase2_subsets\":%llu,\"bitmap_bytes\":%llu,\"threads\":%d,"
             "\"phase1_sec\":%.3f,\"phase2_sec\":%.3f,\"elapsed_sec\":%.3f,\"early_abort\":%s,\"witness_phase\":%d}",
             RHO, a, (unsigned long long)n1, (unsigned long long)n2, (unsigned long long)(need_bitmap ? bm_bytes : 0), NT,
             t2 - t1, t3 - t2, tend - T0, fail ? "true" : "false", witness_phase);
    write_json(argv[3], !fail, D, method, work, wstr, wweight);
    LOG("d >= %d: %s", D, fail ? "false" : "true");
    return 0;
}
