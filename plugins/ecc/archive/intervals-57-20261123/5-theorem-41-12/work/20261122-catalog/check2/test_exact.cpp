// Cross-check the exact search against all coordinate permutations on every
// dimension-2 and dimension-3 subspace of F_2^5, including zero/repeated columns.
#define main audit_program_main
#include "audit.cpp"
#undef main
static vector<U> canonical_by_permutations(const Code&c){
 vector<int> p(c.n);iota(p.begin(),p.end(),0);vector<U> best;
 do{vector<U> words;for(U w:c.words){U v=0;for(int j=0;j<c.n;++j)if((w>>j)&1)v|=1ULL<<p[j];words.push_back(v);}sort(words.begin(),words.end());if(best.empty()||words<best)best=move(words);}while(next_permutation(p.begin(),p.end()));return best;
}
int main(){try{
 U pairs=0,equivalent=0,inequivalent=0,perms=0,nodes=0;vector<int> sizes;
 for(int k:{2,3}){
  set<vector<U>> spaces;vector<Code> codes;
  vector<U> rows(k);
  function<void(int,int)> generate=[&](int at,int lo){
   if(at==k){if(rank2(rows,5)!=k)return;Code c;c.n=5;c.k=k;c.q=2;c.rows=rows;analyse(c);auto key=c.words;sort(key.begin(),key.end());if(spaces.insert(key).second)codes.push_back(move(c));return;}
   for(int r=lo;r<32;++r){rows[at]=r;generate(at+1,r+1);}
  };generate(0,1);
  if(codes.size()!=155)throw runtime_error("small domain size is not 155");sizes.push_back(codes.size());
  vector<vector<U>> canon;for(auto&c:codes){canon.push_back(canonical_by_permutations(c));perms+=120;}
  for(size_t i=0;i<codes.size();++i)for(size_t j=i;j<codes.size();++j){bool truth=canon[i]==canon[j];auto r=exact(codes[i],codes[j]);if(truth!=r.equivalent)throw runtime_error("exact differs from brute-force coordinate permutations");if(truth&&codes[i].invariant!=codes[j].invariant)throw runtime_error("invariant differs for equivalent small codes");++pairs;nodes+=r.nodes;if(truth)++equivalent;else ++inequivalent;}
 }
 cout<<"{\"n\":5,\"dimensions\":[2,3],\"distinct_subspaces_per_dimension\":";arr(cout,sizes);cout<<",\"coordinate_permutations_enumerated\":"<<perms<<",\"pairs_including_self\":"<<pairs<<",\"equivalent_pairs\":"<<equivalent<<",\"inequivalent_pairs\":"<<inequivalent<<",\"mismatches\":0,\"exact_search_nodes\":"<<nodes<<"}\n";
 return 0;
}catch(const exception&e){cerr<<e.what()<<'\n';return 1;}}
