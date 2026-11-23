// Independent scalar 40-bit coset traversal. No packed 27/6 distance table.
#include <algorithm>
#include <array>
#include <cstdint>
#include <ctime>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>
using U = uint64_t;
int wt(U x) { return __builtin_popcountll(x); }
double cpu() { return double(std::clock()) / CLOCKS_PER_SEC; }
struct Range { U begin, end; };

int main(int argc, char** argv) {
  if (argc != 7) return 2;
  const double start = cpu(), limit = std::stod(argv[5]);
  const bool full = std::string(argv[4]) == "full";
  if (!full && std::string(argv[4]) != "profile") return 2;
  const U control_index = std::stoull(argv[6]);
  std::ifstream in(argv[1]);
  int n, k; in >> n >> k;
  if (n != 40 || k != 7) return 2;
  std::array<U, 7> original{}, reduced{}, old_rows{};
  std::array<int, 7> reverse_pivots{}, old_pivots{};
  std::array<int, 33> free{}, old_free{};
  for (auto& r : original) in >> r;
  for (auto& r : old_rows) in >> r;
  for (auto& p : old_pivots) in >> p;
  for (auto& p : old_free) in >> p;
  if (!in) return 2;
  reduced = original;
  int rank = 0;
  for (int p = 39; p >= 0; --p) {
    int found = rank;
    while (found < 7 && !(reduced[found] & (U(1) << p))) ++found;
    if (found == 7) continue;
    std::swap(reduced[rank], reduced[found]);
    for (int j = 0; j < 7; ++j)
      if (j != rank && (reduced[j] & (U(1) << p))) reduced[j] ^= reduced[rank];
    reverse_pivots[rank++] = p;
  }
  if (rank != 7) return 3;
  int f = 0;
  for (int p = 0; p < 40; ++p)
    if (std::find(reverse_pivots.begin(), reverse_pivots.end(), p) == reverse_pivots.end()) free[f++] = p;
  if (f != 33) return 3;
  std::array<U, 32> basis{};
  for (int j = 0; j < 32; ++j) basis[j] = (U(1) << free[j]) | (U(1) << free[32]);
  std::array<U, 128> code{};
  for (unsigned u = 0; u < 128; ++u)
    for (unsigned j = 0; j < 7; ++j) if ((u >> j) & 1) code[u] ^= original[j];
  for (unsigned u = 1; u < 128; ++u)
    if (wt(code[u]) < 18 || (wt(code[u]) & 1) || code[u] >= (U(1) << 40)) return 3;
  std::sort(code.begin(), code.end(), [](U a, U b) {
    return wt(a) != wt(b) ? wt(a) < wt(b) : a < b;
  });
  for (int j = 1; j < 128; ++j) if (code[j] == code[j-1]) return 3;
  std::vector<Range> ranges;
  if (full) ranges.push_back({0, U(1) << 32});
  else {
    // Exactly one 2^16 block in each 2^26-wide stratum. The offset varies
    // across all middle phases, avoiding low-support prefix timing bias.
    for (U s = 0; s < 64; ++s) {
      U begin = (s << 26) | (((s * 0x279U + 0x137U) & 1023U) << 16);
      if ((control_index >> 26) == s) begin = control_index & ~U(65535);
      ranges.push_back({begin, begin + 65536});
    }
  }
  std::ofstream accepted_file(argv[3]);
  U processed = 0, comparisons = 0, accepted = 0;
  int last_bad = 0; bool interrupted = false;
  for (const auto& range : ranges) {
    U gray = range.begin ^ (range.begin >> 1), x = 0;
    for (int j = 0; j < 32; ++j) if ((gray >> j) & 1) x ^= basis[j];
    for (U i = range.begin; i < range.end; ++i) {
      if ((processed & 65535U) == 0 && cpu() - start >= limit) { interrupted = true; break; }
      if (i != range.begin) x ^= basis[__builtin_ctzll(i)];
      // Reusing the preceding rejection witness only changes constraint order.
      // Every rejection still computes an actual 40-bit weight below16.
      bool valid = true; ++comparisons;
      if (wt(x ^ code[last_bad]) < 16) valid = false;
      else {
        for (int j = 0; j < 128; ++j) if (j != last_bad) {
          ++comparisons;
          if (wt(x ^ code[j]) < 16) { valid = false; last_bad = j; break; }
        }
      }
      if (valid) {
        U old_normal = x;
        for (int j = 0; j < 7; ++j)
          if ((old_normal >> old_pivots[j]) & 1) old_normal ^= old_rows[j];
        U old_packed = 0;
        for (int j = 0; j < 33; ++j) old_packed |= ((old_normal >> old_free[j]) & 1) << j;
        accepted_file << i << ' ' << x << ' ' << old_packed << '\n';
        ++accepted;
      }
      ++processed;
    }
    if (interrupted) break;
  }
  accepted_file.flush();
  const U requested = full ? (U(1) << 32) : (U(1) << 22);
  const bool complete = processed == requested;
  std::ofstream out(argv[2]);
  out.precision(12);
  out << "{\"mode\":\"" << (full ? "full" : "profile") << "\",\"n\":40,\"k\":7"
      << ",\"requested_representatives\":" << requested << ",\"processed_representatives\":" << processed
      << ",\"requested_traversal_complete\":" << (complete ? "true" : "false")
      << ",\"full_domain_complete\":" << ((full && complete) ? "true" : "false")
      << ",\"accepted_count\":" << accepted << ",\"actual_40bit_distance_evaluations\":" << comparisons
      << ",\"cpu_limit_seconds\":" << limit << ",\"cpu_seconds\":" << cpu()-start
      << ",\"reverse_pivots\":[";
  for (int j = 0; j < 7; ++j) { if (j) out << ','; out << reverse_pivots[j]; }
  out << "],\"reverse_reduced_rows\":[";
  for (int j = 0; j < 7; ++j) { if (j) out << ','; out << reduced[j]; }
  out << "],\"independent_free\":[";
  for (int j = 0; j < 33; ++j) { if (j) out << ','; out << free[j]; }
  out << "],\"gray_basis_40bit\":[";
  for (int j = 0; j < 32; ++j) { if (j) out << ','; out << basis[j]; }
  out << "],\"requested_ranges\":[";
  for (size_t j = 0; j < ranges.size(); ++j) { if (j) out << ','; out << '[' << ranges[j].begin << ',' << ranges[j].end << ']'; }
  out << "]}\n";
  return complete ? 0 : 4;
}
