// Independent implementation from O6_SPEC.md only. No syndrome-column BFS.
#include <algorithm>
#include <array>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>
#include <immintrin.h>
using namespace std;
using U=uint32_t; using L=uint64_t;
static double now(){return chrono::duration<double>(chrono::steady_clock::now().time_since_epoch()).count();}
// Standalone SHA-256, bytes supplied in canonical decimal/newline format.
struct SHA {
 U h[8]={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
 vector<unsigned char> b; L bytes=0;
 static U ro(U x,int n){return (x>>n)|(x<<(32-n));}
 void block(const unsigned char*p){
 static const U k[64]={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
 U w[64];for(int i=0;i<16;i++)w[i]=(U(p[4*i])<<24)|(U(p[4*i+1])<<16)|(U(p[4*i+2])<<8)|p[4*i+3];
 for(int i=16;i<64;i++){U x=w[i-15],y=w[i-2];w[i]=w[i-16]+(ro(x,7)^ro(x,18)^(x>>3))+w[i-7]+(ro(y,17)^ro(y,19)^(y>>10));}
 U a=h[0],c=h[2],d=h[3],e=h[4],f=h[5],g=h[6],z=h[7],bb=h[1];
 for(int i=0;i<64;i++){U t=z+(ro(e,6)^ro(e,11)^ro(e,25))+((e&f)^(~e&g))+k[i]+w[i];U t2=(ro(a,2)^ro(a,13)^ro(a,22))+((a&bb)^(a&c)^(bb&c));z=g;g=f;f=e;e=d+t;d=c;c=bb;bb=a;a=t+t2;}
 U v[8]={a,bb,c,d,e,f,g,z};for(int i=0;i<8;i++)h[i]+=v[i]; }
 void add(const string&s){bytes+=s.size();for(unsigned char c:s){b.push_back(c);if(b.size()==64){block(b.data());b.clear();}}}
 string finish(){L bits=bytes*8;b.push_back(128);while(b.size()%64!=56)b.push_back(0);for(int i=7;i>=0;i--)b.push_back(bits>>(8*i));for(size_t i=0;i<b.size();i+=64)block(b.data()+i);ostringstream o;o<<hex<<setfill('0');for(U x:h)o<<setw(8)<<x;return o.str();}
};
int main(int argc,char**argv){try{
 double start=now();if(argc!=5&&argc!=7)throw runtime_error("usage: ext2 matrix w D out.json [--dump-F path]");
 int w=stoi(argv[2]),D=stoi(argv[3]),m=w-1;if(w<2||w>6||D<2||(D&1))throw runtime_error("invalid w/D");
 if(argc==7&&string(argv[5])!="--dump-F")throw runtime_error("invalid option");
 ifstream in(argv[1]);if(!in)throw runtime_error("matrix open");string line;vector<L> r;int N=-1;
 while(getline(in,line)){if(!line.empty()&&line.back()=='\r')line.pop_back();if(line.empty())continue; if(line.find_first_not_of("01")!=string::npos)throw runtime_error("matrix must contain binary rows only");if(N<0)N=line.size();if(int(line.size())!=N||N>63)throw runtime_error("bad row length");L x=0;for(int j=0;j<N;j++)if(line[j]=='1')x|=1ULL<<j;if(__builtin_parityll(x))throw runtime_error("odd row");r.push_back(x);}
 int k=r.size();if(N<1||k<1||k>24)throw runtime_error("unsupported matrix");vector<int> piv,freec;int rank=0;
 for(int j=0;j<N;j++){int t=rank;while(t<k&&!((r[t]>>j)&1))t++;if(t==k){freec.push_back(j);continue;}swap(r[t],r[rank]);for(int i=0;i<k;i++)if(i!=rank&&((r[i]>>j)&1))r[i]^=r[rank];piv.push_back(j);rank++;}
 if(rank!=k)throw runtime_error("rank deficient");
 int rho=freec.size();if(rho<1||rho>29)throw runtime_error("rho must be 1..29");size_t S=1ULL<<rho;vector<uint8_t> dep(S,63);int dk=N+1;
 // For c in K, seed f(c_Q)=wt(c_P). For all s, direct definition is
 // min_c [wt(c_P)+sum_t |s_t-c_Q,t|] = min_c wt(x_s+c).
 // Coordinate tensor transforms (a,b)->(min(a,b+1),min(b,a+1))
 // successively minimize each free coordinate. After t coordinates the
 // table is the minimum over ALL seeds, allowing changes only on those
 // t coordinates. Induction proves the final table equals the formula.
 // No distances are layered; no parity-check columns are traversed.
 L cw=0;for(U u=0;u<(1U<<k);u++){if(u)cw^=r[__builtin_ctz(u)];int wt=__builtin_popcountll(cw);if(u)dk=min(dk,wt);U q=0;for(int t=0;t<rho;t++)q|=U((cw>>freec[t])&1)<<t;int wp=0;for(int p:piv)wp+=(cw>>p)&1;dep[q]=min<int>(dep[q],wp);}
 double tinit=now();
 for(size_t h=1;h<S;h*=2){for(size_t base=0;base<S;base+=2*h){size_t j=0;
#ifdef __AVX2__
 const __m256i one=_mm256_set1_epi8(1);
 for(;j+32<=h;j+=32){auto a=_mm256_loadu_si256((__m256i*)&dep[base+j]);auto b=_mm256_loadu_si256((__m256i*)&dep[base+h+j]);auto aa=_mm256_min_epu8(a,_mm256_add_epi8(b,one));auto bb=_mm256_min_epu8(b,_mm256_add_epi8(a,one));_mm256_storeu_si256((__m256i*)&dep[base+j],aa);_mm256_storeu_si256((__m256i*)&dep[base+h+j],bb);}
#endif
 for(;j<h;j++){uint8_t a=dep[base+j],b=dep[base+h+j];dep[base+j]=min<int>(a,b+1);dep[base+h+j]=min<int>(b,a+1);}}}
 double tdepth=now();vector<U> F;array<L,64> hist{};U mask=(1U<<(rho-1))-1;vector<U> member(((1ULL<<(rho-1))+31)/32,0);SHA sha;ofstream dump;if(argc==7){dump.open(argv[6]);if(!dump)throw runtime_error("F dump open");}
 for(U s=0;s<S;s++)if(!__builtin_parity(s)){hist[dep[s]]++;if(s&&dep[s]>=D-2){F.push_back(s);U x=s&mask;member[x>>5]|=1U<<(x&31);string st=to_string(s)+"\n";sha.add(st);if(dump.is_open())dump<<st;}
 // In-place exact even-parity compression: s&mask <= s, so no unread
 // even entry is overwritten. The removed high bit is parity(low bits).
 dep[s&mask]=dep[s];}
 dep.resize(S/2);dep.shrink_to_fit();
 string digest=sha.finish();double tF=now();
 vector<vector<U>> adj(F.size());L counts[6]={0, L(F.size()),0,0,0,0};
 // Each i<j is tested once. Compression to low rho-1 bits is injective
 // on even syndromes (the omitted high bit is fixed by even parity),
 // and all tested XORs are even. Thus this bit test is exact.
 if(m>=2)for(size_t i=0;i<F.size();i++){U a=F[i]&mask;auto&v=adj[i];for(size_t j=i+1;j<F.size();j++){U x=a^(F[j]&mask);if((member[x>>5]>>(x&31))&1U)v.push_back(j);}counts[2]+=v.size();}
 double tedges=now();vector<vector<U>> sols;vector<U> chosen;
 auto record=[&](){if(sols.size()<100000){vector<U> z;for(U i:chosen)z.push_back(F[i]);sols.push_back(move(z));}};
 // Increasing indices remove permutations ONLY: every unordered set has
 // exactly one increasing enumeration. Candidate intersection enforces
 // exactly all pair conditions. On insertion, every subset containing
 // the new head is checked; subsets without it held at the parent.
 // Therefore no passing set is pruned and every statistic is exhaustive.
 function<void(const vector<U>&)> dfs=[&](const vector<U>&cand){
 for(size_t z=0;z<cand.size();z++){U v=cand[z];int old=chosen.size();bool ok=true;
 for(U b=1;b<(1U<<old)&&ok;b++){int sz=1+__builtin_popcount(b);if(sz<=2)continue;U x=F[v];for(int t=0;t<old;t++)if((b>>t)&1)x^=F[chosen[t]];int threshold=D-2*(sz/2+(sz&1)); // sz3,4 => D-4; sz5 => D-6
 if(dep[x&mask]<threshold)ok=false;}
 if(!ok)continue;
 chosen.push_back(v);int n=chosen.size();counts[n]++;if(n==m)record();else {vector<U> next;set_intersection(cand.begin()+z+1,cand.end(),adj[v].begin(),adj[v].end(),back_inserter(next));dfs(next);}chosen.pop_back();}};
 if(m==1){for(U i=0;i<F.size();i++){chosen={i};record();}}else if(m==2){for(U i=0;i<F.size();i++)for(U j:adj[i]){chosen={i,j};record();}}else{for(U i=0;i<F.size();i++){chosen={i}; // edge counts already recorded; insert the second head explicitly
 for(size_t z=0;z<adj[i].size();z++){U j=adj[i][z];chosen.push_back(j);vector<U> cand;set_intersection(adj[i].begin()+z+1,adj[i].end(),adj[j].begin(),adj[j].end(),back_inserter(cand));dfs(cand);chosen.pop_back();}}}
 double tend=now();ofstream out(argv[4]);if(!out)throw runtime_error("output open");
 auto ints=[&](const auto&v){out<<'[';bool first=true;for(auto a:v){if(!first)out<<',';first=false;out<<a;}out<<']';};
 out<<"{\"N\":"<<N<<",\"kappa\":"<<k<<",\"rho\":"<<rho<<",\"w\":"<<w<<",\"D\":"<<D<<",\"pivots\":";ints(piv);out<<",\"free\":";ints(freec);out<<",\"min_distance_K\":"<<dk<<",\"F_size\":"<<F.size()<<",\"F_sha256\":\""<<digest<<"\",\"depth_hist_even\":{";bool first=true;for(int d=0;d<64;d+=2){if(d>N)break;if(!first)out<<',';first=false;out<<'"'<<d<<"\":"<<hist[d];}out<<'}';
 if(m>=2)out<<",\"edges\":"<<counts[2];
 for(int j=3;j<=m;j++)out<<",\"c"<<j<<"\":"<<counts[j];
 out<<",\"solutions\":"<<counts[m]<<",\"solution_list\":[";for(size_t i=0;i<sols.size();i++){if(i)out<<',';ints(sols[i]);}out<<']';if(counts[m]>100000)out<<",\"solution_list_truncated\":true";
 out<<setprecision(9)<<",\"seconds\":"<<tend-start<<",\"stage_seconds\":{\"init\":"<<tinit-start<<",\"depth_transform\":"<<tdepth-tinit<<",\"F_extract\":"<<tF-tdepth<<",\"F_total\":"<<tF-start<<",\"edges\":"<<tedges-tF<<",\"higher_search\":"<<tend-tedges<<"},\"impl\":\"sol-direct\"}\n";
 if(!out)throw runtime_error("output write");
 cerr<<"F="<<F.size()<<" edges="<<counts[2]<<" solutions="<<counts[m]<<" seconds="<<tend-start<<"\n";return 0;
 }catch(const exception&e){cerr<<"ext2: "<<e.what()<<"\n";return 1;}}
