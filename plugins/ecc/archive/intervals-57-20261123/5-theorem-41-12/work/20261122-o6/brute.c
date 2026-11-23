// brute.c -- independent brute-force oracle for O6 (small parents only). No layering, no clique logic.
// usage: brute gen.txt w D out.json [--depth-only]   (depth-only: out is a binary file of one depth byte per syndrome)
// For j=1..m (m=w-1): enumerate EVERY j-subset s_1<..<s_j of the nonzero syndromes 1..2^rho-1 (odd ones included),
//   (matrix mode) build the real (kappa+j) x (N+j+1) generator matrix [K|0 ; x_{s_i}| e_i+e_{j+1}], enumerate all
//   2^(kappa+j)-1 nonzero codewords, accept iff min weight >= D AND every codeword weight is even;
//   (literal mode) accept iff for every nonempty T the XOR-sum syndrome is even-popcount and brute depth >= tau(|T|).
// Brute depth(s) = min over all 2^kappa c in K of wt(x_s + c).
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
typedef uint64_t u64; typedef uint32_t u32;
static void die(const char*m){fprintf(stderr,"brute: %s\n",m);exit(2);}
int main(int argc,char**argv){
  if(argc<5) die("usage: brute gen.txt w D out.json");
  int w=atoi(argv[2]),D=atoi(argv[3]); int m=w-1; if(m<1||m>5) die("w in 2..6");
  int G[16][64]; int kappa=0,N=0; char line[512];
  FILE*f=fopen(argv[1],"r"); if(!f) die("open");
  while(fgets(line,sizeof line,f)){
    int L=(int)strlen(line); while(L>0&&(line[L-1]=='\n'||line[L-1]=='\r'||line[L-1]==' '))L--;
    if(!L) continue; if(!N)N=L; else if(L!=N) die("ragged");
    if(kappa>=16) die("kappa>16"); for(int c=0;c<N;c++) G[kappa][c]=line[c]=='1';
    kappa++;
  }
  fclose(f);
  if(N+m+1>64) die("N+w>64");
  /* Gauss-Jordan to leftmost-pivot RREF on int matrix */
  int piv[16],rank=0;
  for(int c=0;c<N&&rank<kappa;c++){
    int r=-1; for(int i=rank;i<kappa;i++) if(G[i][c]){r=i;break;}
    if(r<0) continue;
    if(r!=rank) for(int x=0;x<N;x++){int t=G[r][x];G[r][x]=G[rank][x];G[rank][x]=t;}
    for(int i=0;i<kappa;i++) if(i!=rank&&G[i][c]) for(int x=0;x<N;x++) G[i][x]^=G[rank][x];
    piv[rank++]=c;
  }
  if(rank!=kappa) die("rank deficient");
  int isp[64]={0}; for(int i=0;i<kappa;i++) isp[piv[i]]=1;
  int fre[64],rho=0; for(int c=0;c<N;c++) if(!isp[c]) fre[rho++]=c;
  u64 Krow[16]; for(int i=0;i<kappa;i++){Krow[i]=0;for(int c=0;c<N;c++) if(G[i][c]) Krow[i]|=1ULL<<c;}
  /* K codewords table, d(K) */
  u64 nK=1ULL<<kappa; u64*Kc=malloc(nK*8);
  for(u64 g=0;g<nK;g++){u64 v=0;for(int i=0;i<kappa;i++) if(g>>i&1) v^=Krow[i];Kc[g]=v;}
  int dK=N+1; for(u64 g=1;g<nK;g++){int wt=__builtin_popcountll(Kc[g]); if(wt<dK)dK=wt;}
  u64 S=1ULL<<rho;
  u64*xs=malloc(S*8); unsigned char*dep=malloc(S);
  for(u64 s=0;s<S;s++){ u64 v=0; for(int t=0;t<rho;t++) if(s>>t&1) v|=1ULL<<fre[t]; xs[s]=v;
    int best=N+1; for(u64 g=0;g<nK;g++){int wt=__builtin_popcountll(v^Kc[g]); if(wt<best)best=wt;} dep[s]=(unsigned char)best; }
  if(argc>5&&!strcmp(argv[5],"--depth-only")){ FILE*o=fopen(argv[4],"wb"); if(!o)die("write"); fwrite(dep,1,S,o); fclose(o); return 0; }
  int tau[6]={0,D-2,D-2,D-4,D-4,D-6};
  u64 cm[6]={0},cl[6]={0}; u64 cap=3000000; u32*solM=malloc(cap*5*4),*solL=malloc(cap*5*4); u64 nsM=0,nsL=0;
  for(int j=1;j<=m;j++){
    u32 idx[6]; for(int i=0;i<j;i++) idx[i]=(u32)(i+1);   /* s_1<..<s_j in [1,S-1] */
    if((u64)j>S-1) continue;
    for(;;){
      /* literal mode */
      int okL=1; u32 sm=0;
      for(u32 T=1;T<(1u<<j)&&okL;T++){ u32 v=0; for(int i=0;i<j;i++) if(T>>i&1) v^=idx[i]; int sz=__builtin_popcount(T);
        if(__builtin_popcount(v)&1 || (int)dep[v]<tau[sz]) okL=0; (void)sm; }
      if(okL){ cl[j]++; if(j==m&&nsL<cap){for(int i=0;i<j;i++)solL[nsL*5+i]=idx[i];nsL++;} }
      /* matrix mode: rows = head rows first, then K rows */
      u64 rows[16]; int nr=0; int tw=N+j; /* last tail coordinate index N+j */
      for(int i=0;i<j;i++) rows[nr++]=xs[idx[i]] | (1ULL<<(N+i)) | (1ULL<<tw);
      for(int i=0;i<kappa;i++) rows[nr++]=Krow[i];
      u64 cur=0,tot=1ULL<<nr; int okM=1;
      for(u64 g=1;g<tot;g++){ cur^=rows[__builtin_ctzll(g)]; int wt=__builtin_popcountll(cur); if(wt<D||(wt&1)){okM=0;break;} }
      if(okM){ cm[j]++; if(j==m&&nsM<cap){for(int i=0;i<j;i++)solM[nsM*5+i]=idx[i];nsM++;} }
      /* next combination */
      int p=j-1; while(p>=0 && idx[p]==S-(u32)(j-p)) p--;
      if(p<0) break; idx[p]++; for(int q=p+1;q<j;q++) idx[q]=idx[q-1]+1;
    }
  }
  FILE*o=fopen(argv[4],"w"); if(!o) die("write");
  fprintf(o,"{\"N\":%d,\"kappa\":%d,\"rho\":%d,\"w\":%d,\"D\":%d,\"min_distance_K\":%d,\"pivots\":[",N,kappa,rho,w,D,dK);
  for(int i=0;i<kappa;i++)fprintf(o,"%s%d",i?",":"",piv[i]);
  fprintf(o,"],\"free\":["); for(int i=0;i<rho;i++)fprintf(o,"%s%d",i?",":"",fre[i]);
  fprintf(o,"],\n\"depth\":["); for(u64 s=0;s<S;s++)fprintf(o,"%s%d",s?",":"",dep[s]);
  fprintf(o,"],\n\"c_matrix\":["); for(int j=1;j<=m;j++)fprintf(o,"%s%llu",j>1?",":"",(unsigned long long)cm[j]);
  fprintf(o,"],\"c_literal\":["); for(int j=1;j<=m;j++)fprintf(o,"%s%llu",j>1?",":"",(unsigned long long)cl[j]);
  fprintf(o,"],\n\"solutions_matrix\":["); for(u64 i=0;i<nsM;i++){fprintf(o,"%s[",i?",":"");for(int t=0;t<m;t++)fprintf(o,"%s%u",t?",":"",solM[i*5+t]);fprintf(o,"]");}
  fprintf(o,"],\n\"solutions_literal\":["); for(u64 i=0;i<nsL;i++){fprintf(o,"%s[",i?",":"");for(int t=0;t<m;t++)fprintf(o,"%s%u",t?",":"",solL[i*5+t]);fprintf(o,"]");}
  fprintf(o,"],\"impl\":\"brute.c\"}\n"); fclose(o);
  return 0;
}
