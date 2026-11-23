// Standalone literal40-bit verifier for saved pair-rejection certificates.
// No search implementation, no legacy Python audit helper, no F-domain scan.
#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdio>
#include <ctime>
#include <fstream>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>
using U=uint64_t;
void need(bool condition,const std::string&message){if(!condition)throw std::runtime_error(message);}
double cpu(){return double(std::clock())/CLOCKS_PER_SEC;}
int wt(U x){return __builtin_popcountll(x);}

struct Reader{
  FILE*f;std::array<unsigned char,1<<16>buffer{};size_t pos=0,len=0;U bytes=0;
  explicit Reader(const std::string&path):f(std::fopen(path.c_str(),"rb")){need(f!=nullptr,"cannot open "+path);}
  ~Reader(){std::fclose(f);}
  int get(){if(pos==len){len=std::fread(buffer.data(),1,buffer.size(),f);pos=0;if(!len){need(!std::ferror(f),"read error");return EOF;}}
    ++bytes;return buffer[pos++];}
  U number(int delimiter,U maximum){
    int c=get();need(c>='0'&&c<='9',"missing unsigned decimal field");U value=0;
    do{unsigned digit=unsigned(c-'0');need(value<=maximum/10 && (value<maximum/10||digit<=maximum%10),"numeric field out of range");
      value=value*10+digit;c=get();}while(c>='0'&&c<='9');
    need(c==delimiter,"wrong field delimiter or truncated record");return value;
  }
  void literal(const std::string&text){for(unsigned char c:text)need(get()==c,"wrong TSV header");}
};

template<class T,size_t N>std::array<T,N>line_array(std::istream&in){
  std::string line;need(bool(std::getline(in,line)),"missing metadata row");std::istringstream s(line);std::array<T,N>a{};
  for(T&v:a)need(bool(s>>v),"short metadata row");s>>std::ws;need(s.eof(),"extra metadata fields");return a;
}
std::string line(std::istream&in){std::string s;need(bool(std::getline(in,s)),"missing metadata string");return s;}
std::array<U,128>words(const std::array<U,7>&rows){
  std::array<U,128>C{};for(unsigned u=0;u<128;u++)for(unsigned i=0;i<7;i++)if((u>>i)&1)C[u]^=rows[i];return C;
}

int main(int argc,char**argv){
  if(argc!=5)return 2;
  const double start=cpu(),limit=std::stod(argv[4]);
  int finished=0,binary_cases=0,tsv_cases=0;U totalF=0,totalPairs=0,totalDistances=0,totalBytes=0;
  std::array<U,41>globalWeights{};
  std::ofstream trace(argv[2]);
  try{
    std::ifstream plan(argv[1]);need(bool(plan),"cannot open literal plan");
    need(line(plan)=="LITERAL_PAIR_REPLAY_V1","wrong plan format");
    auto totals=line_array<U,3>(plan);need(totals[0]==172,"expected172 cases");
    for(U case_number=0;case_number<totals[0];case_number++){
      const double case_start=cpu();auto meta=line_array<U,4>(plan);
      const U id=meta[0],expectedF=meta[1],expectedPairs=meta[2],format=meta[3];
      need(id==case_number,"nonsequential snapshot172 index");need(format<2,"unknown witness format");
      need(expectedPairs==expectedF*(expectedF-1)/2,"declared pair cardinality mismatch");
      std::string name=line(plan);
      auto original=line_array<U,7>(plan),rows=line_array<U,7>(plan);
      auto free=line_array<int,33>(plan);auto pivots=line_array<int,7>(plan);
      auto permutation=line_array<int,40>(plan);
      std::string F_path=line(plan),witness_path=line(plan);
      auto perm_sorted=permutation;std::sort(perm_sorted.begin(),perm_sorted.end());
      std::vector<int>coordinates(free.begin(),free.end());coordinates.insert(coordinates.end(),pivots.begin(),pivots.end());std::sort(coordinates.begin(),coordinates.end());
      for(int j=0;j<40;j++)need(perm_sorted[j]==j&&coordinates[j]==j,"invalid coordinate partition/permutation");
      for(int i=0;i<7;i++){
        need(original[i]<(U(1)<<40)&&rows[i]<(U(1)<<40),"row exceeds40 bits");
        for(int j=0;j<7;j++)need(((rows[i]>>pivots[j])&1)==U(i==j),"scan rows not systematic at supplied pivots");
      }
      auto C=words(rows),actual=words(original),mapped=actual;
      for(int u=0;u<128;u++){
        U x=0;for(int j=0;j<40;j++)x|=((actual[u]>>j)&1)<<permutation[j];mapped[u]=x;
        if(u)need(wt(C[u])>=18 && !(wt(C[u])&1),"base not even distance18 or greater");
      }
      auto sortedC=C;std::sort(sortedC.begin(),sortedC.end());std::sort(mapped.begin(),mapped.end());
      need(sortedC==mapped,"actual172 matrix does not bind to scan under permutation");
      need(std::adjacent_find(sortedC.begin(),sortedC.end())==sortedC.end(),"base rank is not7");
      std::vector<U>F;F.reserve(expectedF);std::vector<U>packed;packed.reserve(expectedF);
      Reader fr(F_path);
      for(U j=0;j<expectedF;j++){
        U z=fr.number('\n',(U(1)<<33)-1),a=0;packed.push_back(z);
        for(int k=0;k<33;k++)a|=((z>>k)&1)<<free[k];
        need(!(wt(a)&1),"odd F representative");
        for(U c:C){need(wt(a^c)>=16,"saved F has a distance below16");totalDistances++;}
        F.push_back(a);
      }
      need(fr.get()==EOF,"extra F data after expected count");
      std::sort(packed.begin(),packed.end());need(std::adjacent_find(packed.begin(),packed.end())==packed.end(),"duplicate packed F representative");
      Reader certificate(witness_path);
      if(format==1){certificate.literal("F_i\tF_j\tbase_message\tactual_weight\n");tsv_cases++;}else binary_cases++;
      U pairs=0;std::array<U,41>weights{};
      for(U i=0;i<expectedF;i++){
        if((i&63U)==0)need(cpu()-start<limit,"CPU budget reached before full replay");
        for(U j=i+1;j<expectedF;j++){
          U u,saved_weight=0;
          if(format==0){int byte=certificate.get();need(byte>=0&&byte<128,"binary EOF, sentinel255, or invalid message");u=U(byte);}
          else{
            need(certificate.number('\t',expectedF)==i,"TSV i differs from exact lex pair");
            need(certificate.number('\t',expectedF)==j,"TSV j differs from exact lex pair");
            u=certificate.number('\t',127);saved_weight=certificate.number('\n',40);
          }
          int actual_weight=wt(F[i]^F[j]^C[u]);
          need(actual_weight<16,"pair witness is not a rejection");
          if(format==1)need(saved_weight==U(actual_weight),"TSV stated weight disagrees with literal weight");
          weights[actual_weight]++;pairs++;
        }
      }
      need(pairs==expectedPairs,"actual pair count differs");need(certificate.get()==EOF,"extra witness bytes/records after final pair");
      totalF+=expectedF;totalPairs+=pairs;totalBytes+=certificate.bytes;finished++;
      for(int w=0;w<=40;w++)globalWeights[w]+=weights[w];
      trace.precision(12);trace<<"{\"snapshot172_index\":"<<id<<",\"case\":\""<<name<<"\",\"status\":\"PASS\",\"F_count\":"<<expectedF
        <<",\"all_F_distances_checked\":"<<expectedF*128<<",\"pairs_replayed\":"<<pairs<<",\"witness_format\":\""<<(format?"TSV":"uint8")
        <<"\",\"witness_bytes_read\":"<<certificate.bytes<<",\"literal_matrix_binding\":true,\"strict_EOF\":true,\"weight_histogram\":{";
      bool first=true;for(int w=0;w<=40;w++)if(weights[w]){if(!first)trace<<',';first=false;trace<<'"'<<w<<"\":"<<weights[w];}
      trace<<"},\"CPU_seconds\":"<<cpu()-case_start<<"}\n";trace.flush();
    }
    need(line(plan)=="END","missing plan end marker");need(plan.peek()==EOF,"extra metadata after end marker");
    need(totalF==totals[1]&&totalPairs==totals[2],"final totals disagree with manifest");
    std::ofstream result(argv[3]);result.precision(12);
    result<<"{\"status\":\"PASS\",\"cases_completed\":"<<finished<<",\"binary_cases\":"<<binary_cases<<",\"TSV_cases\":"<<tsv_cases
      <<",\"F_count\":"<<totalF<<",\"all_F_actual_distances_checked\":"<<totalDistances<<",\"pairs_replayed\":"<<totalPairs
      <<",\"witness_bytes_read\":"<<totalBytes<<",\"all172_literal_matrix_bindings_checked\":true,\"all_streams_exact_EOF\":true"
      <<",\"sentinels_or_invalid_messages\":0,\"nonrejecting_witnesses\":0,\"F_domains_rerun\":0,\"CPU_seconds\":"<<cpu()-start<<",\"weight_histogram\":{";
    bool first=true;for(int w=0;w<=40;w++)if(globalWeights[w]){if(!first)result<<',';first=false;result<<'"'<<w<<"\":"<<globalWeights[w];}
    result<<"}}\n";
    std::cout<<"PASS cases="<<finished<<" F="<<totalF<<" pairs="<<totalPairs<<" CPU="<<cpu()-start<<'\n';return 0;
  }catch(const std::exception&e){
    std::cerr<<"FAIL after "<<finished<<" cases: "<<e.what()<<'\n';
    std::ofstream result(argv[3]);result<<"{\"status\":\"FAIL\",\"cases_completed\":"<<finished<<",\"CPU_seconds\":"<<cpu()-start<<"}\n";return 1;
  }
}
