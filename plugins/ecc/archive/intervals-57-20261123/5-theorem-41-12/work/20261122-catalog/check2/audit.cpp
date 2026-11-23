// Independent binary linear code catalogue audit, C++17, standard library only.
// No external graph/canonicalisation library or prior audit is used.
#include <algorithm>
#include <array>
#include <chrono>
#include <cstdint>
#include <fstream>
#include <functional>
#include <iomanip>
#include <iostream>
#include <map>
#include <numeric>
#include <random>
#include <regex>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>
using namespace std;
using U=uint64_t;
struct Code {
 int idx=0,k=0,n=0,q=0,decl_hull=-1,rank=0,d=0,hull=0;
 vector<U> rows, words;
 vector<int> columns,mult,unique_cols,colcolor,spectrum,zero_cols;
 bool even=false,repeated=false;
 array<U,2> invariant{};
 int refinement_rounds=0;
};
static string quote(const string&s){ostringstream o;o<<'"';for(unsigned char c:s){if(c=='"'||c=='\\')o<<'\\'<<c;else if(c=='\n')o<<"\\n";else if(c<32)o<<"\\u"<<hex<<setw(4)<<setfill('0')<<int(c)<<dec;else o<<c;}o<<'"';return o.str();}
template<class T> static void arr(ostream&o,const vector<T>&v){o<<'[';for(size_t i=0;i<v.size();++i){if(i)o<<',';o<<v[i];}o<<']';}
static int rank2(vector<U> a,int width){int r=0;for(int b=width-1;b>=0;--b){int p=r;while(p<(int)a.size()&&!((a[p]>>b)&1))++p;if(p==(int)a.size())continue;swap(a[p],a[r]);for(int j=r+1;j<(int)a.size();++j)if((a[j]>>b)&1)a[j]^=a[r];++r;}return r;}
struct Digest{
 U a=1469598103934665603ULL,b=0x6a09e667f3bcc909ULL;
 void add(U x){ // Fixed deterministic digest; collisions only enlarge exact-search buckets.
  for(int j=0;j<8;++j){U c=(x>>(8*j))&255;a=(a^c)*1099511628211ULL;b=(b^c)*0x9e3779b185ebca87ULL;b=(b<<13)|(b>>51);}
 }
};
static void analyse(Code&c){
 c.rank=rank2(c.rows,c.n);int N=1<<c.k;
 c.words.assign(N,0);c.spectrum.assign(c.n+1,0);c.spectrum[0]=1;c.d=c.n+1;
 for(int m=1;m<N;++m){int i=__builtin_ctz((unsigned)m);c.words[m]=c.words[m^(1<<i)]^c.rows[i];int w=__builtin_popcountll(c.words[m]);++c.spectrum[w];c.d=min(c.d,w);}
 c.even=true;for(int w=1;w<=c.n;w+=2)if(c.spectrum[w])c.even=false;
 vector<U> gram(c.k);for(int i=0;i<c.k;++i)for(int j=0;j<c.k;++j)if(__builtin_parityll(c.rows[i]&c.rows[j]))gram[i]|=1ULL<<j;
 c.hull=c.k-rank2(gram,c.k);c.columns.assign(c.n,0);c.mult.assign(N,0);c.zero_cols.clear();c.unique_cols.clear();c.repeated=false;
 for(int j=0;j<c.n;++j){for(int i=0;i<c.k;++i)if((c.rows[i]>>j)&1)c.columns[j]|=1<<i;++c.mult[c.columns[j]];if(!c.columns[j])c.zero_cols.push_back(j);}
 for(int v=0;v<N;++v){if(c.mult[v])c.unique_cols.push_back(v);if(c.mult[v]>1)c.repeated=true;}
 // Intrinsic bipartite graph: one vertex per distinct generator column, coloured
 // by multiplicity; one vertex for EVERY codeword, coloured by Hamming weight.
 // Incidence is parity(message & column). Under row changes messages/columns
 // are relabelled contragrediently; under coordinate permutations columns are
 // permuted. Thus the coloured graph, and every refinement digest, is invariant.
 int t=c.unique_cols.size(),V=t+N;vector<vector<int>> adj(V);vector<int> color(V);
 for(int j=0;j<t;++j){int v=c.unique_cols[j];color[j]=c.mult[v];for(int m=0;m<N;++m)if(__builtin_parity((unsigned)(v&m))){adj[j].push_back(t+m);adj[t+m].push_back(j);}}
 for(int m=0;m<N;++m)color[t+m]=c.n+1+__builtin_popcountll(c.words[m]);
 Digest dig;dig.add(c.n);dig.add(c.k);dig.add(c.rank);dig.add(c.hull);dig.add(t);for(int x:c.spectrum)dig.add(x);
 int old_count=set<int>(color.begin(),color.end()).size();c.refinement_rounds=0;
 for(;;){
  vector<vector<int>> sig(V);vector<int> order(V);iota(order.begin(),order.end(),0);
  for(int v=0;v<V;++v){sig[v].reserve(adj[v].size()+1);sig[v].push_back(color[v]);for(int u:adj[v])sig[v].push_back(color[u]);sort(sig[v].begin()+1,sig[v].end());}
  sort(order.begin(),order.end(),[&](int a,int b){return sig[a]<sig[b];});
  vector<int> next(V);int cnt=0;dig.add(V);
  for(int i=0;i<V;++i){int v=order[i];if(i==0||sig[v]!=sig[order[i-1]])++cnt;next[v]=cnt-1;dig.add(sig[v].size());for(int x:sig[v])dig.add(x);}
  ++c.refinement_rounds;dig.add(cnt);color.swap(next);
  if(cnt==old_count)break;
  old_count=cnt;
  if(c.refinement_rounds>V)throw runtime_error("refinement failed to stabilise");
 }
 c.colcolor.assign(N,-1);for(int j=0;j<t;++j)c.colcolor[c.unique_cols[j]]=color[j];c.invariant={dig.a,dig.b};
}
struct ExactResult{bool equivalent=false;vector<int> permutation;U nodes=0,candidates=0;};
static ExactResult exact(const Code&a,const Code&b){
 ExactResult res;if(a.k!=b.k||a.n!=b.n||a.rank!=a.k||b.rank!=b.k)return res;
 int N=1<<a.k;vector<int> image(N,-1),span{0};image[0]=0;
 // A coordinate equivalence exists iff an invertible linear map on F2^k
 // carries the generator-column MULTISET to the other multiset. At each node
 // the map is known on a subspace. An independent source column is mapped to
 // EVERY independent target column satisfying necessary invariants. Extending
 // checks every new point of the subspace, including absent column vectors.
 // A full-rank input's columns span, so each level increases dimension and
 // after k levels EVERY possible admissible linear map has been considered.
 auto compatible=[&](int x,int y){return a.mult[x]==b.mult[y]&&(!a.mult[x]||a.colcolor[x]==b.colcolor[y]);};
 if(!compatible(0,0))return res;
 function<bool()> dfs;
 // Define actual DFS separately to keep all branches fully reversible.
 dfs=[&](){
  ++res.nodes;
  if((int)span.size()==N){
   vector<vector<int>> positions(N);for(int j=0;j<b.n;++j)positions[b.columns[j]].push_back(j);
   vector<int> taken(N),p(a.n);for(int j=0;j<a.n;++j){int y=image[a.columns[j]];if(taken[y]>=(int)positions[y].size())throw runtime_error("bad full map");p[j]=positions[y][taken[y]++];}
   // Independent final verification on actual codeword sets, coordinate 0 is
   // the leftmost source character. p[j] is the TARGET position of source j.
   vector<U> transported;for(U w:a.words){U v=0;for(int j=0;j<a.n;++j)if((w>>j)&1)v|=1ULL<<p[j];transported.push_back(v);}
   vector<U> target=b.words;sort(target.begin(),target.end());sort(transported.begin(),transported.end());if(target!=transported)throw runtime_error("explicit permutation verification failed");
   res.permutation=move(p);res.equivalent=true;return true;
  }
  vector<char> in_image(N);for(int x:span)in_image[image[x]]=1;
  int chosen=-1;vector<int> options;
  for(int x:a.unique_cols)if(image[x]<0){
   vector<int> poss;
   for(int y:b.unique_cols)if(!in_image[y]&&compatible(x,y)){
    bool ok=true;for(int s:span)if(!compatible(s^x,image[s]^y)){ok=false;break;}if(ok)poss.push_back(y);
   }
   if(poss.empty())return false;
   if(chosen<0||poss.size()<options.size()){chosen=x;options=move(poss);if(options.size()==1)break;}
  }
  if(chosen<0)throw runtime_error("full rank columns failed to span");
  size_t old=span.size();
  for(int y:options){
   ++res.candidates;
   for(size_t j=0;j<old;++j){int x=span[j]^chosen;image[x]=image[span[j]]^y;span.push_back(x);}
   if(dfs())return true;
   for(size_t j=old;j<span.size();++j)image[span[j]]=-1;
   span.resize(old);
  }
  return false;
 };
 dfs();return res;
}
static vector<Code> parse(const string&path,int n,int k,vector<string>&errors){
 ifstream in(path);if(!in)throw runtime_error("cannot open "+path);vector<string> lines;string s;while(getline(in,s)){if(!s.empty()&&s.back()=='\r')s.pop_back();lines.push_back(s);}
 regex header(R"(^\s*\?(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(.*)$)"), hull(R"(HULL\s*=\s*(\d+))"), binary(R"(^[01]+$)");
 vector<Code> out;smatch m;
 for(size_t l=0;l<lines.size();){
  if(!regex_match(lines[l],m,header)){if(!lines[l].empty()&&lines[l][0]=='?')errors.push_back("malformed header at line "+to_string(l+1));++l;continue;}
  Code c;c.k=stoi(m[1]);c.n=stoi(m[2]);c.q=stoi(m[3]);c.idx=stoi(m[4]);smatch h;string tail=m[5];if(regex_search(tail,h,hull))c.decl_hull=stoi(h[1]);size_t start=l++;
  if(c.n!=n||c.k!=k||c.q!=2)throw runtime_error("unexpected dimensions at line "+to_string(start+1));
  for(int i=0;i<k;++i){if(l>=lines.size()||!regex_match(lines[l],binary)||(int)lines[l].size()!=n)throw runtime_error("invalid/missing matrix row at line "+to_string(l+1));U row=0;for(int j=0;j<n;++j)if(lines[l][j]=='1')row|=1ULL<<j;c.rows.push_back(row);++l;}
  // A further n-character binary line would be an extra matrix row. Integer
  // metadata is otherwise allowed; known files use short decimal statistics.
  if(l<lines.size()&&regex_match(lines[l],binary)&&(int)lines[l].size()==n)errors.push_back("extra binary matrix row after idx "+to_string(c.idx));
  out.push_back(move(c));
 }
 return out;
}
static string hexkey(array<U,2>x){ostringstream o;o<<hex<<setfill('0')<<setw(16)<<x[0]<<setw(16)<<x[1];return o.str();}
static void histogram(ostream&o,const map<int,int>&h){o<<'{';bool first=true;for(auto [x,y]:h){if(!first)o<<',';first=false;o<<quote(to_string(x))<<':'<<y;}o<<'}';}
static Code transform(const Code&a,mt19937_64&rng,vector<int>&p){Code b=a;iota(p.begin(),p.end(),0);shuffle(p.begin(),p.end(),rng);b.rows.assign(a.k,0);for(int i=0;i<a.k;++i)for(int j=0;j<a.n;++j)if((a.rows[i]>>j)&1)b.rows[i]|=1ULL<<p[j];for(int t=0;t<12*a.k;++t){int i=rng()%a.k,j=rng()%a.k;if(i!=j)b.rows[i]^=b.rows[j];}analyse(b);return b;}
static void selftest(const vector<Code>&codes,ostream&o){
 mt19937_64 rng(0x20261122ac02ULL);int tests=min<int>(100,codes.size()),passed=0;U nodes=0;
 for(int t=0;t<tests;++t){int ix=(U(t)*codes.size())/tests;const Code&a=codes[ix];vector<int>p(a.n);Code b=transform(a,rng,p);if(a.invariant!=b.invariant)throw runtime_error("random invariance selftest failed");auto e=exact(a,b);if(!e.equivalent)throw runtime_error("random exact equivalence selftest failed");++passed;nodes+=e.nodes;}
 o<<"{\"seed\":\"0x20261122ac02\",\"random_transform_tests\":"<<passed<<",\"invariant_failures\":0,\"exact_false_negatives\":0,\"verified_explicit_permutations\":"<<passed<<",\"search_nodes\":"<<nodes<<'}';
}
static void audit(const string&input,int n,int k,int expected,const string&prefix){
 auto start=chrono::steady_clock::now();vector<string> errors;auto codes=parse(input,n,k,errors);map<int,int> hull,evenh,dist,ranks;vector<int> even,zero,repeat,bad_hull;map<array<U,2>,vector<int>> buckets;set<int> ids;int even_nr=0;U total_messages=0;
 for(int i=0;i<(int)codes.size();++i){auto&c=codes[i];analyse(c);++hull[c.hull];++dist[c.d];++ranks[c.rank];if(!ids.insert(c.idx).second)errors.push_back("duplicate idx "+to_string(c.idx));if(c.even){even.push_back(c.idx);++evenh[c.hull];if(!c.repeated)++even_nr;}if(!c.zero_cols.empty())zero.push_back(c.idx);if(c.repeated)repeat.push_back(c.idx);if(c.decl_hull>=0&&c.decl_hull!=c.hull)bad_hull.push_back(c.idx);buckets[c.invariant].push_back(i);total_messages+=(1<<k)-1;if(i%2000==0)cerr<<n<<","<<k<<": analysed "<<i<<"/"<<codes.size()<<'\n';}
 if((int)codes.size()!=expected)errors.push_back("block count differs from expected");
 for(int i=1;i<=expected;++i)if(!ids.count(i))errors.push_back("missing idx "+to_string(i));
 for(int x:ids)if(x<1||x>expected)errors.push_back("out of range idx "+to_string(x));
 sort(even.begin(),even.end());ofstream ei(prefix+".even_idx.txt");for(int x:even)ei<<x<<'\n';ei.close();
 U pairs=0;int maxbucket=0;for(auto&[key,v]:buckets){pairs+=U(v.size())*(v.size()-1)/2;maxbucket=max(maxbucket,(int)v.size());}cerr<<n<<","<<k<<": buckets="<<buckets.size()<<" candidate pairs="<<pairs<<" max bucket="<<maxbucket<<'\n';
 ofstream o(prefix+".audit.json");o<<"{\n\"input\":"<<quote(input)<<",\"n\":"<<n<<",\"k\":"<<k<<",\"expected_count\":"<<expected<<",\n\"summary\":{\"count\":"<<codes.size()<<",\"count_even\":"<<even.size()<<",\"count_even_no_repeated_columns\":"<<even_nr<<",\"hull_histogram\":";histogram(o,hull);o<<",\"even_hull_histogram\":";histogram(o,evenh);o<<",\"minimum_distance_histogram\":";histogram(o,dist);o<<",\"rank_histogram\":";histogram(o,ranks);o<<",\"zero_column_failures\":";arr(o,zero);o<<",\"repeated_columns_idx\":";arr(o,repeat);o<<",\"header_hull_mismatches\":";arr(o,bad_hull);o<<",\"invariant_bucket_count\":"<<buckets.size()<<",\"largest_invariant_bucket\":"<<maxbucket<<",\"pairs_requiring_exact\":"<<pairs<<",\"pairs_excluded_by_invariant\":"<<U(codes.size())*(codes.size()-1)/2-pairs<<",\"nonzero_messages_enumerated\":"<<total_messages<<"},\n\"format_errors\":[";for(size_t i=0;i<errors.size();++i){if(i)o<<',';o<<quote(errors[i]);}o<<"],\n\"selftest\":";selftest(codes,o);o<<",\n\"exact_pairs\":[\n";
 bool first=true;U done=0,totalnodes=0,equivalent=0;
 for(auto&[key,v]:buckets)for(size_t i=0;i<v.size();++i)for(size_t j=i+1;j<v.size();++j){auto&a=codes[v[i]];auto&b=codes[v[j]];auto r=exact(a,b);if(!first)o<<",\n";first=false;o<<"{\"idx_a\":"<<a.idx<<",\"idx_b\":"<<b.idx<<",\"equivalent\":"<<(r.equivalent?"true":"false")<<",\"exhaustive\":true,\"search_nodes\":"<<r.nodes<<",\"candidate_extensions\":"<<r.candidates;if(r.equivalent){++equivalent;o<<",\"permutation_source_to_target_zero_based\":";arr(o,r.permutation);cerr<<"EQUIVALENT "<<a.idx<<' '<<b.idx<<'\n';}o<<'}';++done;totalnodes+=r.nodes;if(done%1000==0){o.flush();cerr<<n<<","<<k<<": exact pairs "<<done<<'/'<<pairs<<'\n';}}
 o<<"\n],\"exact_pairs_completed\":"<<done<<",\"equivalent_pair_count\":"<<equivalent<<",\"unresolved_pairs\":[],\"all_pairwise_decisions_strict\":true,\"all_pairwise_inequivalent_proved\":"<<(equivalent==0?"true":"false")<<",\"exact_search_total_nodes\":"<<totalnodes<<",\n\"codes\":[\n";
 for(size_t i=0;i<codes.size();++i){if(i)o<<",\n";auto&c=codes[i];o<<"{\"idx\":"<<c.idx<<",\"row_count\":"<<c.rows.size()<<",\"row_lengths\":";arr(o,vector<int>(c.k,c.n));o<<",\"rank\":"<<c.rank<<",\"minimum_distance\":"<<c.d<<",\"weight_spectrum_including_zero\":";arr(o,c.spectrum);o<<",\"zero_columns_zero_based\":";arr(o,c.zero_cols);o<<",\"even\":"<<(c.even?"true":"false")<<",\"repeated_columns\":"<<(c.repeated?"true":"false")<<",\"column_multiplicity_histogram\":";map<int,int> mh;for(int v:c.unique_cols)++mh[c.mult[v]];histogram(o,mh);o<<",\"hull_dimension\":"<<c.hull<<",\"declared_hull\":";if(c.decl_hull<0)o<<"null";else o<<c.decl_hull;o<<",\"invariant\":"<<quote(hexkey(c.invariant))<<",\"refinement_rounds\":"<<c.refinement_rounds<<'}';}
 o<<"\n],\"elapsed_seconds\":"<<chrono::duration<double>(chrono::steady_clock::now()-start).count()<<"}\n";
 cerr<<n<<","<<k<<": COMPLETE in "<<chrono::duration<double>(chrono::steady_clock::now()-start).count()<<" seconds\n";
}
int main(int argc,char**argv){try{if(argc!=6){cerr<<"usage: audit INPUT N K EXPECTED OUTPUT_PREFIX\n";return 2;}audit(argv[1],stoi(argv[2]),stoi(argv[3]),stoi(argv[4]),argv[5]);return 0;}catch(const exception&e){cerr<<"ERROR: "<<e.what()<<'\n';return 1;}}
