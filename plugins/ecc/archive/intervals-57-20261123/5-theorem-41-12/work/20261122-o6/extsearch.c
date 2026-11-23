// extsearch.c -- O6 coset-compatibility computation (see work/O6_SPEC.md).
// usage: extsearch gen.txt w D out.json [--dump-F path] [--dump-depth path] [--pbits B] [--sol-cap N]
//   gen.txt: kappa lines of N chars 0/1 (leftmost char = coordinate 0).
//   --dump-depth: (rho<=24) binary file, one byte per syndrome s in [0,2^rho): depth(s) (255 = not reached)
// Build: gcc -O3 -march=native -std=c11 -o extsearch extsearch.c
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
typedef uint64_t u64; typedef uint32_t u32;
static double now(void){struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return t.tv_sec+1e-9*t.tv_nsec;}
static void die(const char*m){fprintf(stderr,"extsearch: %s\n",m);exit(2);}

/* ---------------- SHA-256 ---------------- */
typedef struct{u32 h[8];unsigned char buf[64];size_t blen;u64 total;}sha_t;
static const u32 K256[64]={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
#define ROR(x,n) (((x)>>(n))|((x)<<(32-(n))))
static void sha_block(sha_t*s,const unsigned char*p){
  u32 w[64]; for(int i=0;i<16;i++) w[i]=(u32)p[4*i]<<24|(u32)p[4*i+1]<<16|(u32)p[4*i+2]<<8|p[4*i+3];
  for(int i=16;i<64;i++){u32 s0=ROR(w[i-15],7)^ROR(w[i-15],18)^(w[i-15]>>3),s1=ROR(w[i-2],17)^ROR(w[i-2],19)^(w[i-2]>>10);w[i]=w[i-16]+s0+w[i-7]+s1;}
  u32 a=s->h[0],b=s->h[1],c=s->h[2],d=s->h[3],e=s->h[4],f=s->h[5],g=s->h[6],h=s->h[7];
  for(int i=0;i<64;i++){u32 S1=ROR(e,6)^ROR(e,11)^ROR(e,25),ch=(e&f)^(~e&g),t1=h+S1+ch+K256[i]+w[i],S0=ROR(a,2)^ROR(a,13)^ROR(a,22),mj=(a&b)^(a&c)^(b&c),t2=S0+mj;h=g;g=f;f=e;e=d+t1;d=c;c=b;b=a;a=t1+t2;}
  s->h[0]+=a;s->h[1]+=b;s->h[2]+=c;s->h[3]+=d;s->h[4]+=e;s->h[5]+=f;s->h[6]+=g;s->h[7]+=h;
}
static void sha_init(sha_t*s){static const u32 iv[8]={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};memcpy(s->h,iv,32);s->blen=0;s->total=0;}
static void sha_upd(sha_t*s,const unsigned char*p,size_t n){s->total+=n;while(n){size_t c=64-s->blen;if(c>n)c=n;memcpy(s->buf+s->blen,p,c);s->blen+=c;p+=c;n-=c;if(s->blen==64){sha_block(s,s->buf);s->blen=0;}}}
static void sha_fin(sha_t*s,char*hex){u64 bits=s->total*8;unsigned char pad=0x80;sha_upd(s,&pad,1);unsigned char z=0;while(s->blen!=56)sha_upd(s,&z,1);unsigned char L[8];for(int i=0;i<8;i++)L[i]=(unsigned char)(bits>>(56-8*i));sha_upd(s,L,8);for(int i=0;i<8;i++)sprintf(hex+8*i,"%08x",s->h[i]);}

/* ---------------- globals for the search ---------------- */
static int m_heads, rho;
static u64 *SB[3];       /* SB[0]: depth>=D-2 (sizes 1,2); SB[1]: depth>=D-4 (sizes 3,4); SB[2]: depth>=D-6 (size 5); even popcount, s<2^rho */
static u64 *PB; static u32 PM;
static u64 cnt[8];
static u32 chosen[8], sums[64];
static u32 *candbuf[8];
static u64 SOLCAP=100000;
static u32 *sol; static u64 nsol_stored;
static inline int inset(int sz,u32 v){int si=sz<=2?0:(sz<=4?1:2);return (int)((SB[si][v>>6]>>(v&63))&1);}
static inline int pairok(u32 x){return (int)(((PB[(x&PM)>>6]>>(x&63))&1)&((SB[0][x>>6]>>(x&63))&1));}
static void rec(int k,const u32*cand,size_t nc){
  for(size_t i=0;i<nc;i++){
    u32 e=cand[i]; chosen[k]=e; cnt[k+1]++;
    if(k+1==m_heads){
      if(nsol_stored<SOLCAP){for(int t=0;t<k;t++)sol[nsol_stored*m_heads+t]=chosen[t];sol[nsol_stored*m_heads+k]=e;nsol_stored++;}
      continue;
    }
    int nm=1<<k; for(int mk=0;mk<nm;mk++) sums[nm|mk]=sums[mk]^e;
    u32*nx=candbuf[k+1]; size_t n=0;
    for(size_t j=i+1;j<nc;j++){ u32 c=cand[j]; u32 x=e^c; nx[n]=c; n+=(size_t)((PB[(x&PM)>>6]>>(x&63))&1); }
    size_t n2=0;
    for(size_t t=0;t<n;t++){
      u32 c=nx[t];
      if(!((SB[0][(e^c)>>6]>>((e^c)&63))&1)) continue;
      int ok=1;
      for(int mk=1;mk<nm;mk++){ if(!inset(__builtin_popcount(mk)+2,sums[nm|mk]^c)){ok=0;break;} }
      if(ok) nx[n2++]=c;
    }
    n=n2;
    rec(k+1,nx,n);
  }
}

static const u64 MK[6]={0x5555555555555555ULL,0x3333333333333333ULL,0x0f0f0f0f0f0f0f0fULL,0x00ff00ff00ff00ffULL,0x0000ffff0000ffffULL,0x00000000ffffffffULL};
#define ODDPAT 0x6996966996696996ULL  /* bit b set iff popcount(b) odd */
static inline u64 evpat(u64 w){return __builtin_parityll(w)?ODDPAT:~ODDPAT;}

int main(int argc,char**argv){
  double T0=now();
  if(argc<5) die("usage: extsearch gen.txt w D out.json [--dump-F p] [--dump-depth p] [--pbits B] [--sol-cap N]");
  const char*genf=argv[1]; int w=atoi(argv[2]); int D=atoi(argv[3]); const char*outf=argv[4];
  const char*dumpF=NULL,*dumpD=NULL; int pbits=22; u64 firstN=0; /* --first N: BENCHMARK ONLY, restricts the outer loop to the first N elements of F (partial counts) */
  for(int i=5;i<argc;i++){
    if(!strcmp(argv[i],"--dump-F")&&i+1<argc) dumpF=argv[++i];
    else if(!strcmp(argv[i],"--dump-depth")&&i+1<argc) dumpD=argv[++i];
    else if(!strcmp(argv[i],"--pbits")&&i+1<argc) pbits=atoi(argv[++i]);
    else if(!strcmp(argv[i],"--first")&&i+1<argc) firstN=strtoull(argv[++i],NULL,10);
    else if(!strcmp(argv[i],"--sol-cap")&&i+1<argc) SOLCAP=strtoull(argv[++i],NULL,10);
    else die("bad option");
  }
  if(w<2||w>6) die("w must be in 2..6"); if(D<4||(D&1)) die("D must be even >=4");
  m_heads=w-1;
  /* ---- read generator ---- */
  u64 rows[64]; int kappa=0,N=0; char line[512];
  FILE*f=fopen(genf,"r"); if(!f) die("cannot open generator file");
  while(fgets(line,sizeof line,f)){
    int L=(int)strlen(line); while(L>0&&(line[L-1]=='\n'||line[L-1]=='\r'||line[L-1]==' '))L--;
    if(L==0) continue;
    if(N==0) N=L; else if(L!=N) die("ragged generator");
    if(N>64) die("N>64"); if(kappa>=64) die("too many rows");
    u64 r=0; for(int c=0;c<N;c++){ if(line[c]=='1') r|=1ULL<<c; else if(line[c]!='0') die("bad char"); }
    rows[kappa++]=r;
  }
  fclose(f);
  if(kappa<1) die("empty generator");
  for(int i=0;i<kappa;i++) if(__builtin_popcountll(rows[i])&1) die("odd-weight generator row");
  /* ---- leftmost-pivot RREF ---- */
  int piv[64],rank=0;
  for(int c=0;c<N&&rank<kappa;c++){
    int r=-1; for(int i=rank;i<kappa;i++) if(rows[i]>>c&1){r=i;break;}
    if(r<0) continue;
    u64 t=rows[r];rows[r]=rows[rank];rows[rank]=t;
    for(int i=0;i<kappa;i++) if(i!=rank&&(rows[i]>>c&1)) rows[i]^=rows[rank];
    piv[rank++]=c;
  }
  if(rank!=kappa) die("generator rows not linearly independent");
  rho=N-kappa;
  if(rho<6||rho>30) die("rho must be in 6..30");
  int fre[64],nf=0; { u64 pm=0; for(int i=0;i<kappa;i++) pm|=1ULL<<piv[i]; for(int c=0;c<N;c++) if(!(pm>>c&1)) fre[nf++]=c; }
  /* ---- min distance of K (full enumeration, Gray code) ---- */
  int dK=N+1; if(kappa<=40){ u64 cur=0; u64 tot=1ULL<<kappa; for(u64 g=1;g<tot;g++){ cur^=rows[__builtin_ctzll(g)]; int wt=__builtin_popcountll(cur); if(wt<dK)dK=wt; } }
  /* ---- parity-check columns in canonical labelling ---- */
  u32 col[64];
  for(int c=0;c<N;c++){
    int ip=-1; for(int i=0;i<kappa;i++) if(piv[i]==c){ip=i;break;}
    u32 v=0;
    if(ip<0){ for(int t=0;t<rho;t++) if(fre[t]==c){v=1u<<t;break;} }
    else { for(int t=0;t<rho;t++) if(rows[ip]>>fre[t]&1) v|=1u<<t; }
    col[c]=v;
  }
  /* ---- layering ---- */
  int R=rho<12?12:rho;
  u64 nwords=1ULL<<(R-6), nvw=1ULL<<(rho-6);
  int bwlog=R-6<10?R-6:10; u64 BW=1ULL<<bwlog, nblocks=nwords/BW;
  u64 *A=aligned_alloc(4096,nwords*8),*B=aligned_alloc(4096,nwords*8),*tmp=aligned_alloc(64,BW*8);
  unsigned char*nzA=calloc(nblocks,1),*nzB=calloc(nblocks,1);
  if(!A||!B||!nzA||!nzB||!tmp) die("alloc");
  int ethr[3]={D-3,D-5,D-7}; /* S_i = even s with s not in L_ethr[i]  (ethr<0: all even s) */
  for(int i=0;i<3;i++){SB[i]=aligned_alloc(4096,nvw*8);if(!SB[i])die("alloc");}
  int snap[3]={0,0,0};
  unsigned char*depth=NULL; u64 fullcnt=1ULL<<rho;
  if(dumpD){ if(rho>24) die("--dump-depth needs rho<=24"); depth=malloc(fullcnt); memset(depth,255,fullcnt); depth[0]=0; }
  u64 hb[64],wlo[64]; int lc[64];
  for(int j=0;j<N;j++){u64 ww=col[j]>>6;hb[j]=ww>>bwlog;wlo[j]=ww&(BW-1);lc[j]=(int)(col[j]&63);}
  #define SNAPSHOT(BM,I) do{ for(u64 q=0;q<nvw;q++){ u64 ev=evpat(q); SB[I][q]=(~(BM)[q])&ev; } snap[I]=1; }while(0)
  memset(A,0,nwords*8); A[0]=1; nzA[0]=1;
  u64 *prev=A,*next=B; unsigned char*nzp=nzA,*nzn=nzB;
  u64 even_hist[80]; memset(even_hist,0,sizeof even_hist);
  even_hist[0]=1; /* syndrome 0 is even, depth 0 */
  u64 total_prev=1, even_prev=1; int T=0;
  double tl0=now();
  for(int i=0;i<3;i++) if(ethr[i]==0) SNAPSHOT(prev,i);
  for(int t=1;t<=70 && total_prev<fullcnt;t++){
    u64 cntall=0,cnteven=0;
    for(u64 o=0;o<nblocks;o++){
      u64*out=next+o*BW,*pb=prev+o*BW; int any=nzp[o];
      memcpy(out,pb,BW*8);
      for(int j=0;j<N;j++){
        u64 ib=o^hb[j]; if(!nzp[ib]) continue;
        const u64*src=prev+ib*BW; u64 wl=wlo[j];
        if(wl==0&&lc[j]==0){for(u64 x=0;x<BW;x++)out[x]|=src[x];any=1;continue;}
        u64 wh=wl&~7ULL; int sl=(int)(wl&7);
        if(sl==0){for(u64 x=0;x<BW;x+=8)memcpy(tmp+x,src+(x^wh),64);}
        else{for(u64 x=0;x<BW;x+=8){const u64*s=src+(x^wh);for(int i=0;i<8;i++)tmp[x+i]=s[i^sl];}}
        for(int k=0;k<6;k++)if(lc[j]>>k&1){int s=1<<k;u64 mk=MK[k];for(u64 x=0;x<BW;x++){u64 y=tmp[x];tmp[x]=((y&mk)<<s)|((y>>s)&mk);}}
        for(u64 x=0;x<BW;x++)out[x]|=tmp[x];
        any=1;
      }
      nzn[o]=0;
      if(any){ u64 c=0,ce=0; for(u64 x=0;x<BW;x++){u64 v=out[x];c+=(u64)__builtin_popcountll(v);ce+=(u64)__builtin_popcountll(v&evpat(o*BW+x));} nzn[o]=c!=0; cntall+=c; cnteven+=ce; }
    }
    if(depth){ for(u64 q=0;q<nvw;q++){ u64 d=next[q]&~prev[q]; while(d){int b=__builtin_ctzll(d);d&=d-1;depth[q*64+(u64)b]=(unsigned char)t;} } }
    even_hist[t]=cnteven-even_prev; total_prev=cntall; even_prev=cnteven; T=t;
    u64*tp=prev;prev=next;next=tp; unsigned char*tz=nzp;nzp=nzn;nzn=tz;
    for(int i=0;i<3;i++) if(ethr[i]==t) SNAPSHOT(prev,i);
  }
  if(total_prev!=fullcnt) die("layering did not reach full space");
  for(int i=0;i<3;i++) if(!snap[i]){
    if(ethr[i]<0){ for(u64 q=0;q<nvw;q++) SB[i][q]=evpat(q); }
    else { memset(SB[i],0,nvw*8); } /* L_e is the whole space */
  }
  free(A);free(B);free(tmp);free(nzA);free(nzB);
  double sec_layer=now()-tl0;
  if(dumpD){ FILE*d=fopen(dumpD,"wb"); fwrite(depth,1,fullcnt,d); fclose(d); }
  /* ---- F list ---- */
  double tf0=now();
  u64 nF=0; for(u64 q=0;q<nvw;q++) nF+=(u64)__builtin_popcountll(SB[0][q]);
  u32*F=malloc((nF+64)*4); { u64 n=0; for(u64 q=0;q<nvw;q++){u64 x=SB[0][q];while(x){int b=__builtin_ctzll(x);x&=x-1;F[n++]=(u32)(q*64+(u64)b);}} }
  char shahex[65]; { sha_t s; sha_init(&s); char buf[16384]; size_t bl=0; for(u64 i=0;i<nF;i++){ if(bl>sizeof buf-16){sha_upd(&s,(unsigned char*)buf,bl);bl=0;} bl+=(size_t)sprintf(buf+bl,"%u\n",F[i]); } sha_upd(&s,(unsigned char*)buf,bl); sha_fin(&s,shahex); }
  if(dumpF){ FILE*d=fopen(dumpF,"w"); for(u64 i=0;i<nF;i++) fprintf(d,"%u\n",F[i]); fclose(d); }
  /* ---- prefilter ---- */
  int pb=pbits<rho?pbits:rho; if(pb<6)pb=6;
  PM=(u32)((1ULL<<pb)-1); u64 pw=1ULL<<(pb-6); PB=calloc(pw,8);
  for(u64 i=0;i<nF;i++){u32 x=F[i]&PM;PB[x>>6]|=1ULL<<(x&63);}
  double sec_F=now()-tf0;
  /* ---- search ---- */
  sol=malloc((size_t)SOLCAP*m_heads*4);
  for(int k=0;k<8;k++) candbuf[k]=malloc((nF+64)*4);
  memset(cnt,0,sizeof cnt); nsol_stored=0; sums[0]=0;
  double sec_pair=0,sec_deep=0; double tlast=now();
  cnt[1]=nF;
  if(m_heads>=2){
    u32*c0=candbuf[1];
    u64 iend=(firstN&&firstN<nF)?firstN:nF;
    for(u64 i=0;i<iend;i++){
      u32 a=F[i]; double ta=now();
      size_t n=0; const u32*Fp=F; u64 ne=nF;
      for(u64 j=i+1;j<ne;j++){ u32 x=a^Fp[j]; c0[n]=Fp[j]; n+=(size_t)((PB[(x&PM)>>6]>>(x&63))&1); }
      size_t n2=0; for(size_t t=0;t<n;t++){ u32 c=c0[t]; u32 x=a^c; if((SB[0][x>>6]>>(x&63))&1) c0[n2++]=c; }
      double tb=now(); sec_pair+=tb-ta;
      if(m_heads==2) cnt[2]+=n2;
      if(m_heads>=3 && n2){ chosen[0]=a; sums[1]=a; rec(1,c0,n2); }
      else if(m_heads==2){ for(size_t t=0;t<n2;t++){ if(nsol_stored<SOLCAP){sol[nsol_stored*2]=a;sol[nsol_stored*2+1]=c0[t];nsol_stored++;} } }
      double tc=now(); sec_deep+=tc-tb;
      if(tc-tlast>30){ tlast=tc; fprintf(stderr,"[extsearch] %llu/%llu edges=%llu c3=%llu c4=%llu c5=%llu t=%.1f\n",(unsigned long long)i,(unsigned long long)nF,(unsigned long long)cnt[2],(unsigned long long)cnt[3],(unsigned long long)cnt[4],(unsigned long long)cnt[5],tc-T0); }
    }
  } else { for(u64 i=0;i<nF&&i<SOLCAP;i++){sol[i]=F[i];nsol_stored++;} }
  u64 nsol=cnt[m_heads];
  double sec_total=now()-T0;
  /* ---- JSON ---- */
  FILE*o=fopen(outf,"w"); if(!o) die("cannot write output");
  fprintf(o,"{\"N\":%d,\"kappa\":%d,\"rho\":%d,\"w\":%d,\"D\":%d,\n \"pivots\":[",N,kappa,rho,w,D);
  for(int i=0;i<kappa;i++)fprintf(o,"%s%d",i?",":"",piv[i]);
  fprintf(o,"],\"free\":["); for(int i=0;i<nf;i++)fprintf(o,"%s%d",i?",":"",fre[i]);
  fprintf(o,"],\n \"min_distance_K\":%d,\n \"F_size\":%llu,\n \"F_sha256\":\"%s\",\n \"depth_hist_even\":{",dK,(unsigned long long)nF,shahex);
  { int first=1; for(int t=0;t<=T;t++) if(even_hist[t]){ fprintf(o,"%s\"%d\":%llu",first?"":",",t,(unsigned long long)even_hist[t]); first=0; } }
  fprintf(o,"},\n \"edges\":%llu",(unsigned long long)(m_heads>=2?cnt[2]:0));
  for(int j=3;j<=m_heads;j++) fprintf(o,", \"c%d\":%llu",j,(unsigned long long)cnt[j]);
  fprintf(o,",\n \"solutions\":%llu,\n \"solution_list\":[",(unsigned long long)nsol);
  for(u64 i=0;i<nsol_stored;i++){ fprintf(o,"%s[",i?",":""); for(int t=0;t<m_heads;t++)fprintf(o,"%s%u",t?",":"",sol[i*m_heads+t]); fprintf(o,"]"); }
  fprintf(o,"]");
  if(nsol>nsol_stored) fprintf(o,",\n \"solution_list_truncated\":true");
  fprintf(o,",\n \"seconds\":%.3f,\"seconds_layering\":%.3f,\"seconds_Flist\":%.3f,\"seconds_pairs\":%.3f,\"seconds_deeper\":%.3f,\"pbits\":%d,\"partial_first\":%llu,\"impl\":\"extsearch.c\"}\n",sec_total,sec_layer,sec_F,sec_pair,sec_deep,pb,(unsigned long long)firstN);
  fclose(o);
  return 0;
}
