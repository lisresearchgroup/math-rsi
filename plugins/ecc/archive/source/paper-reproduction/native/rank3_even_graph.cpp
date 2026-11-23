#include <algorithm>
#include <ctime>
#include <fstream>
#include <iostream>
#include <set>
#include <vector>
using U=unsigned long long;
std::vector<U>C,F;
bool at_least(U a,int threshold){for(U c:C)if(__builtin_popcountll(a^c)<threshold)return false;return true;}
int delta(U a){int d=40;for(U c:C)d=std::min(d,__builtin_popcountll(a^c));return d;}
struct Edge{int i,j,d;};struct Triangle{int i,j,k,d;};
int main(int argc,char**argv){
  if(argc!=3)return 2;
  const auto start=std::clock();
  std::ifstream in(argv[1]),ff(argv[2]);int n,k,threshold,parity;in>>n>>k>>threshold>>parity;
  if(n!=40||k!=7||threshold!=16||parity!=0)return 3;
  std::vector<U>G(7);for(U&r:G)in>>r;
  std::vector<int>free(33);for(int&j:free)in>>j;
  for(int u=0;u<128;++u){U w=0;for(int i=0;i<7;++i)if((u>>i)&1)w^=G[i];C.push_back(w);}
  U z;while(ff>>z){U a=0;for(int i=0;i<33;++i)a|=((z>>i)&1ULL)<<free[i];if((__builtin_popcountll(a)&1)||!at_least(a,16))return 4;F.push_back(a);}
  if(F.size()>5000)return 5;
  std::vector<std::set<int>>adj(F.size());std::vector<Edge>edges;
  long long pairs=0;
  for(size_t i=0;i<F.size();++i){
    for(size_t j=i+1;j<F.size();++j){++pairs;U x=F[i]^F[j];if(at_least(x,16)){adj[i].insert(int(j));adj[j].insert(int(i));edges.push_back({int(i),int(j),delta(x)});}}
    if(double(std::clock()-start)/CLOCKS_PER_SEC>52.0)return 6;
  }
  std::vector<Triangle>triangles;std::vector<int>target;
  for(size_t i=0;i<F.size();++i){
    for(int j:adj[i])if(j>int(i))for(int t:adj[i])if(t>j&&adj[j].count(t)){
      int d=delta(F[i]^F[j]^F[t]);triangles.push_back({int(i),j,t,d});
      if(d>=14){target={int(i),j,t};break;}
    }
    if(!target.empty())break;
    if(double(std::clock()-start)/CLOCKS_PER_SEC>52.0)return 7;
  }
  std::cout<<"{\"F_count\":"<<F.size()<<",\"all_F_verified\":true,\"pair_count\":"<<pairs<<",\"pair_graph_complete\":true,\"edges\":[";
  for(size_t i=0;i<edges.size();++i){if(i)std::cout<<',';auto e=edges[i];std::cout<<'['<<e.i<<','<<e.j<<','<<e.d<<']';}
  std::cout<<"],\"triangles\":[";
  for(size_t i=0;i<triangles.size();++i){if(i)std::cout<<',';auto t=triangles[i];std::cout<<'['<<t.i<<','<<t.j<<','<<t.k<<','<<t.d<<']';}
  std::cout<<"],\"target_indices\":[";
  for(size_t i=0;i<target.size();++i){if(i)std::cout<<',';std::cout<<target[i];}
  std::cout<<"],\"all_triangles_exhausted\":"<<(target.empty()?"true":"false")<<",\"cpu_seconds\":"<<double(std::clock()-start)/CLOCKS_PER_SEC<<"}\n";
}
