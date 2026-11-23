#include <algorithm>
#include <array>
#include <cstdint>
#include <ctime>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <numeric>
#include <vector>
using U=uint64_t;
int pc(U x){return __builtin_popcountll(x);}
double cpu(){return double(std::clock())/CLOCKS_PER_SEC;}
struct CheckedBlock{U index,high;std::array<U,129>masks{};};
int main(int argc,char**argv){
  if(argc!=5&&argc!=7)return 2;
  const double start=cpu(),limit=std::stod(argv[4]);
  std::ifstream in(argv[1]);std::ofstream out(argv[2]),fout(argv[3]);
  int n,k,d,parity;in>>n>>k>>d>>parity;
  if(n!=40||k!=7||d!=16||parity!=0)return 2;
  std::array<U,7>rows{},P{};std::vector<int>free(33);
  for(auto&r:rows)in>>r;for(auto&j:free)in>>j;
  for(int i=0;i<7;i++)for(int j=0;j<33;j++)P[i]|=((rows[i]>>free[j])&1)<<j;
  std::array<U,128>centers{};std::array<int,128>order{};
  for(int u=1;u<128;u++){int b=__builtin_ctz(unsigned(u));centers[u]=centers[u^(1<<b)]^P[b];}
  std::iota(order.begin(),order.end(),0);
  std::stable_sort(order.begin(),order.end(),[](int u,int v){return pc(u)<pc(v);});
  std::array<U,128>hc{};std::array<int,128>lc{},rhs{};
  for(int i=0;i<128;i++){hc[i]=centers[order[i]]>>6;lc[i]=centers[order[i]]&63;rhs[i]=16-pc(order[i]);}
  U table[64][7]{},parity_mask[2]{};
  for(int low=0;low<64;low++){
    parity_mask[pc(low)%2]|=U(1)<<low;
    for(int c=0;c<64;c++)for(int t=0;t<=6;t++)if(pc(low^c)>=t)table[c][t]|=U(1)<<low;
  }
  const U modulus=U(1)<<27,multiplier=0x11bbcdcbULL,offset=0x0e7b9d15ULL;
  const bool sample=argc==7;const U count=sample?std::stoull(argv[6]):modulus;
  if(sample&&(std::string(argv[5])!="--sample"||count>modulus||count<64))return 2;
  std::array<U,129>blocks{},candidates{};std::vector<CheckedBlock>checked;
  U processed=0,comparisons=0,accepted=0;const double filter_start=cpu();
  for(U index=0;index<count;index++){
    if(index%4096==0&&cpu()-start>=limit-0.25)break;
    U high=(multiplier*index+offset)&(modulus-1);
    U active=parity_mask[pc(high)%2];
    bool capture=index%(count/64)==0;CheckedBlock capture_data{};
    if(capture){capture_data.index=index;capture_data.high=high;capture_data.masks[0]=active;}
    blocks[0]++;candidates[0]+=pc(active);
    for(int i=0;i<128;i++){
      comparisons++;int t=rhs[i]-pc(high^hc[i]);
      if(t>6)active=0;else if(t>0)active&=table[lc[i]][t];
      if(capture)capture_data.masks[i+1]=active;
      if(!active)break;
      blocks[i+1]++;candidates[i+1]+=pc(active);
    }
    if(capture)checked.push_back(capture_data);
    while(active){
      int low=__builtin_ctzll(active);U packed=(high<<6)|U(low);
      fout<<packed<<"\n";accepted++;active&=active-1;
    }
    processed++;
    if(!sample&&processed%(U(1)<<25)==0)std::cerr<<"completed "<<processed<<"/"<<count<<" CPU="<<cpu()-start<<" F="<<accepted<<"\n";
  }
  const double seconds=cpu()-filter_start;fout.flush();
  out<<std::setprecision(12)<<"{\"n\":40,\"k\":7,\"required_distance\":16,\"required_parity\":0"
     <<",\"sample\":"<<(sample?"true":"false")<<",\"requested_blocks\":"<<count<<",\"processed_blocks\":"<<processed
     <<",\"eligible_representatives\":"<<candidates[0]<<",\"coverage_index_begin\":0,\"coverage_index_end_exclusive\":"<<processed
     <<",\"affine_multiplier\":"<<multiplier<<",\"affine_offset\":"<<offset<<",\"affine_modulus\":"<<modulus
     <<",\"cpu_limit_seconds\":"<<limit<<",\"filter_cpu_seconds\":"<<seconds<<",\"block_constraint_evaluations\":"<<comparisons
     <<",\"average_constraints_per_block\":"<<double(comparisons)/processed<<",\"processed_complete\":"<<(processed==count?"true":"false")
     <<",\"accepted_count\":"<<accepted<<",\"saved_count\":"<<accepted<<",\"saved_cap\":"<<accepted<<",\"rows\":[";
  for(int j=0;j<7;j++){if(j)out<<",";out<<rows[j];}out<<"],\"free\":[";
  for(int j=0;j<33;j++){if(j)out<<",";out<<free[j];}out<<"],\"message_order\":[";
  for(int j=0;j<128;j++){if(j)out<<",";out<<order[j];}out<<"],\"blocks_after_prefix\":[";
  for(int j=0;j<129;j++){if(j)out<<",";out<<blocks[j];}out<<"],\"candidates_after_prefix\":[";
  for(int j=0;j<129;j++){if(j)out<<",";out<<candidates[j];}out<<"],\"selected_blocks\":[";
  for(int j=0;j<int(checked.size());j++){if(j)out<<",";auto&b=checked[j];out<<"{\"index\":"<<b.index<<",\"high\":"<<b.high<<",\"masks\":[";
    for(int t=0;t<129;t++){if(t)out<<",";out<<b.masks[t];}out<<"]}";}
  out<<"]}\n";std::cerr<<"terminal complete="<<(processed==count)<<" CPU="<<seconds<<" F="<<accepted<<"\n";
  return processed==count?0:3;
}
