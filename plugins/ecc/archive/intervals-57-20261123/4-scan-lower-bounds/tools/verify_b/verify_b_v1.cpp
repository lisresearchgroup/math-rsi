#include <algorithm>
#include <array>
#include <atomic>
#include <cerrno>
#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <limits>
#include <mutex>
#include <stdexcept>
#include <string>
#include <thread>
#include <unistd.h>
#include <unordered_map>
#include <vector>

using U64 = uint64_t;
constexpr int MAX_N = 260;
constexpr int NW = (MAX_N + 63) / 64;

struct Bits {
    std::array<U64, NW> a{};
};

static inline bool getbit(const Bits& b, int p) {
    return (b.a[p >> 6] >> (p & 63)) & 1ULL;
}

static inline void togglebit(Bits& b, int p) {
    b.a[p >> 6] ^= 1ULL << (p & 63);
}

static inline void xorbits(Bits& a, const Bits& b) {
    for (int i = 0; i < NW; ++i) a.a[i] ^= b.a[i];
}

static inline bool anybit(const Bits& b, int n) {
    int full = n >> 6;
    for (int i = 0; i < full; ++i) {
        if (b.a[i]) return true;
    }
    if (n & 63) {
        if (b.a[full] & ((1ULL << (n & 63)) - 1)) return true;
    }
    return false;
}

static inline int popcount_bits(const Bits& b, int n) {
    int ans = 0;
    int words = (n + 63) / 64;
    for (int i = 0; i < words; ++i) ans += __builtin_popcountll(b.a[i]);
    if ((n & 63) && words) {
        ans -= __builtin_popcountll(b.a[words - 1] & ~((1ULL << (n & 63)) - 1));
    }
    return ans;
}

static inline U64 splitmix64(U64 x) {
    x += 0x9e3779b97f4a7c15ULL;
    x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ULL;
    x = (x ^ (x >> 27)) * 0x94d049bb133111ebULL;
    return x ^ (x >> 31);
}

struct FlatMinTable {
    struct Cell {
        U64 key = 0;
        uint8_t value = 255;
        uint8_t pad[7]{};
    };

    std::vector<Cell> tab;
    U64 mask = 0;
    U64 used = 0;
    uint8_t zero_nonempty = 255;

    static U64 sat_add(U64 a, U64 b) {
        if (a > std::numeric_limits<U64>::max() - b)
            return std::numeric_limits<U64>::max();
        return a + b;
    }

    static U64 comb_sat(int n, int k, U64 cap) {
        if (k < 0 || k > n) return 0;
        k = std::min(k, n - k);
        __int128 x = 1;
        for (int i = 1; i <= k; ++i) {
            x = x * (n - i + 1) / i;
            if (x > cap) return cap;
        }
        return (U64)x;
    }

    static U64 estimate_subsets(int n, int q, U64 cap) {
        U64 s = 0;
        for (int i = 0; i <= q; ++i) {
            U64 c = comb_sat(n, i, cap);
            s = sat_add(s, c);
            if (s >= cap) return cap;
        }
        return s;
    }

    void init(int n, int q, U64 memory_budget) {
        U64 cell_limit = memory_budget / sizeof(Cell);
        if (cell_limit < 16) throw std::runtime_error("内存不足：无法建立综合表");

        U64 estimate = estimate_subsets(n, q, cell_limit);
        if (estimate >= cell_limit)
            throw std::runtime_error("内存不足：重量有界综合表过大");

        __int128 need128 = ((__int128)estimate * 10 + 6) / 7;
        if (need128 > cell_limit)
            throw std::runtime_error("内存不足：重量有界综合表过大");

        U64 need = (U64)need128;
        U64 cap = 1;
        while (cap < need) {
            if (cap > (std::numeric_limits<U64>::max() >> 1))
                throw std::runtime_error("综合表容量溢出");
            cap <<= 1;
        }

        if ((__int128)cap * sizeof(Cell) > memory_budget)
            throw std::runtime_error("内存不足：无法分配综合表");

        tab.assign((size_t)cap, Cell{});
        mask = cap - 1;
        used = 0;
        zero_nonempty = 255;
    }

    void put_min(U64 key, uint8_t value, bool nonempty) {
        if (key == 0 && nonempty && value < zero_nonempty)
            zero_nonempty = value;

        U64 p = splitmix64(key) & mask;
        while (true) {
            Cell& c = tab[(size_t)p];
            if (c.value == 255) {
                c.key = key;
                c.value = value;
                ++used;
                return;
            }
            if (c.key == key) {
                if (value < c.value) c.value = value;
                return;
            }
            p = (p + 1) & mask;
        }
    }

    uint8_t get(U64 key) const {
        U64 p = splitmix64(key) & mask;
        while (true) {
            const Cell& c = tab[(size_t)p];
            if (c.value == 255) return 255;
            if (c.key == key) return c.value;
            p = (p + 1) & mask;
        }
    }

    size_t entries() const {
        return (size_t)used;
    }
};

struct SearchResult {
    bool found = false;
    Bits word{};
    int weight = 0;
};

struct SearchEngine {
    int n;
    int D;
    int limit;
    int threads;
    const std::vector<U64>& column_syndrome;
    U64 memory_budget;

    std::atomic<bool> stop{false};
    std::atomic<bool> internal_error{false};
    std::atomic<U64> high_checked{0};
    std::atomic<U64> low_generated{0};
    std::mutex result_mutex;
    std::mutex progress_mutex;
    SearchResult result;

    SearchEngine(int n_, int D_, int threads_,
                 const std::vector<U64>& cs,
                 U64 budget)
        : n(n_), D(D_), limit(D_ - 1), threads(threads_),
          column_syndrome(cs), memory_budget(budget) {}

    void progress(U64 x, const char* phase) {
        if (x && x % 20000000ULL == 0) {
            std::lock_guard<std::mutex> lk(progress_mutex);
            std::cerr << phase << ": " << x << "\n";
        }
    }

    void build_low_rec(const std::vector<int>& side,
                       int start, int depth, int q,
                       U64 syndrome, Bits& bits,
                       FlatMinTable& table) {
        if (internal_error.load(std::memory_order_relaxed)) return;

        table.put_min(syndrome, (uint8_t)depth, depth != 0);
        U64 cnt = low_generated.fetch_add(1, std::memory_order_relaxed) + 1;
        progress(cnt, "low subsets");

        if (depth == q) return;

        for (int i = start; i < (int)side.size(); ++i) {
            int c = side[i];
            togglebit(bits, c);
            build_low_rec(side, i + 1, depth + 1, q,
                          syndrome ^ column_syndrome[c], bits, table);
            togglebit(bits, c);
        }
    }

    bool recover_low_rec(const std::vector<int>& side,
                         int start, int depth, int max_depth,
                         U64 syndrome, U64 target,
                         int high_weight, Bits& bits, Bits& answer) {
        if (syndrome == target) {
            if (!(high_weight == 0 && depth == 0 && target == 0)) {
                answer = bits;
                return true;
            }
        }

        if (depth == max_depth) return false;

        for (int i = start; i < (int)side.size(); ++i) {
            int c = side[i];
            togglebit(bits, c);
            if (recover_low_rec(side, i + 1, depth + 1,
                                max_depth,
                                syndrome ^ column_syndrome[c],
                                target, high_weight,
                                bits, answer)) {
                togglebit(bits, c);
                return true;
            }
            togglebit(bits, c);
        }
        return false;
    }

    void claim_candidate(const std::vector<int>& low_side,
                         const FlatMinTable& table,
                         U64 high_syndrome,
                         int high_weight,
                         const Bits& high_bits) {
        if (stop.load(std::memory_order_relaxed)) return;

        uint8_t low_weight = table.get(high_syndrome);
        if (high_weight == 0 && high_syndrome == 0)
            low_weight = table.zero_nonempty;

        if (low_weight == 255) return;

        int total = high_weight + (int)low_weight;
        if (total <= 0 || total >= D) return;

        bool expected = false;
        if (!stop.compare_exchange_strong(expected, true))
            return;

        Bits low_bits;
        Bits tmp;
        int max_low = std::min((int)low_weight, limit - high_weight);
        if (!recover_low_rec(low_side, 0, 0, max_low,
                             0, high_syndrome, high_weight,
                             tmp, low_bits)) {
            internal_error.store(true);
            return;
        }

        Bits word = high_bits;
        for (int i = 0; i < NW; ++i) word.a[i] |= low_bits.a[i];

        std::lock_guard<std::mutex> lk(result_mutex);
        result.found = true;
        result.word = word;
        result.weight = total;
    }

    void high_tail(const std::vector<int>& side,
                   int pos, int need,
                   U64 syndrome, Bits& bits,
                   const std::vector<int>& low_side,
                   const FlatMinTable& table) {
        if (stop.load(std::memory_order_relaxed) ||
            internal_error.load(std::memory_order_relaxed))
            return;

        if (need == 0) {
            U64 checked = high_checked.fetch_add(1, std::memory_order_relaxed) + 1;
            progress(checked, "high subsets");
            claim_candidate(low_side, table, syndrome,
                            popcount_bits(bits, n), bits);
            return;
        }

        int m = (int)side.size();
        for (int i = pos; i <= m - need; ++i) {
            int c = side[i];
            togglebit(bits, c);
            high_tail(side, i + 1, need - 1,
                      syndrome ^ column_syndrome[c],
                      bits, low_side, table);
            togglebit(bits, c);

            if (stop.load(std::memory_order_relaxed) ||
                internal_error.load(std::memory_order_relaxed))
                return;
        }
    }

    void search_weight(const std::vector<int>& low_side,
                       const std::vector<int>& high_side,
                       const FlatMinTable& table,
                       int weight) {
        if (stop.load() || internal_error.load()) return;

        if (weight == 0) {
            Bits empty;
            claim_candidate(low_side, table, 0, 0, empty);
            return;
        }

        if (weight > (int)high_side.size()) return;

        int tasks = (int)high_side.size() - weight + 1;
        int worker_count = std::max(1, std::min(threads, tasks));
        std::atomic<int> next_task{0};
        std::vector<std::thread> workers;
        workers.reserve(worker_count);

        auto worker = [&]() {
            while (!stop.load() && !internal_error.load()) {
                int first = next_task.fetch_add(1);
                if (first >= tasks) break;

                Bits bits;
                int c = high_side[first];
                togglebit(bits, c);

                if (weight == 1) {
                    U64 checked =
                        high_checked.fetch_add(1, std::memory_order_relaxed) + 1;
                    progress(checked, "high subsets");
                    claim_candidate(low_side, table,
                                    column_syndrome[c], 1, bits);
                } else {
                    high_tail(high_side, first + 1, weight - 1,
                              column_syndrome[c], bits,
                              low_side, table);
                }
            }
        };

        try {
            for (int i = 0; i < worker_count; ++i)
                workers.emplace_back(worker);
        } catch (...) {
            for (auto& t : workers) t.join();
            throw;
        }

        for (auto& t : workers) t.join();
    }

    void run_orientation(const std::vector<int>& low_side,
                         const std::vector<int>& high_side) {
        int q = std::min(limit / 2, (int)low_side.size());

        FlatMinTable table;
        table.init((int)low_side.size(), q, memory_budget);

        Bits bits;
        build_low_rec(low_side, 0, 0, q, 0, bits, table);

        {
            std::lock_guard<std::mutex> lk(progress_mutex);
            std::cerr << "table entries: " << table.entries() << "\n";
        }

        int max_high = std::min(limit, (int)high_side.size());
        for (int w = 0; w <= max_high; ++w) {
            if (stop.load() || internal_error.load()) break;
            search_weight(low_side, high_side, table, w);
        }
    }
};

static U64 physical_memory_bytes() {
    long pages = sysconf(_SC_PHYS_PAGES);
    long page_size = sysconf(_SC_PAGE_SIZE);
    if (pages <= 0 || page_size <= 0) return 0;
    __int128 x = (__int128)pages * page_size;
    if (x > std::numeric_limits<U64>::max())
        return std::numeric_limits<U64>::max();
    return (U64)x;
}

static bool in_row_span(const std::vector<Bits>& rref,
                        const std::vector<int>& pivots,
                        int rank, int n,
                        const Bits& target) {
    Bits residual = target;
    for (int i = 0; i < rank; ++i) {
        if (getbit(residual, pivots[i]))
            xorbits(residual, rref[i]);
    }
    return !anybit(residual, n);
}

static std::string bits_to_string(const Bits& b, int n) {
    std::string s;
    s.resize(n);
    for (int i = 0; i < n; ++i)
        s[i] = getbit(b, i) ? '1' : '0';
    return s;
}

static long long parse_i64(const std::string& s, const char* what) {
    size_t p = 0;
    long long v = 0;
    try {
        v = std::stoll(s, &p);
    } catch (...) {
        throw std::runtime_error(std::string("非法") + what);
    }
    if (p != s.size())
        throw std::runtime_error(std::string("非法") + what);
    return v;
}

static unsigned parse_u32(const std::string& s, const char* what) {
    size_t p = 0;
    unsigned long long v = 0;
    try {
        v = std::stoull(s, &p);
    } catch (...) {
        throw std::runtime_error(std::string("非法") + what);
    }
    if (p != s.size() || v == 0 || v > 1000000ULL)
        throw std::runtime_error(std::string("非法") + what);
    return (unsigned)v;
}

int main(int argc, char** argv) {
    std::string out_path;

    try {
        if (argc != 4 && argc != 5)
            throw std::runtime_error(
                "用法：verify_b G.txt D out.json [threads]");

        const char* g_path = argv[1];
        long long Dll = parse_i64(argv[2], "D");
        if (Dll > 40)
            throw std::runtime_error("D 必须不大于 40");
        int D = (int)Dll;

        out_path = argv[3];

        unsigned threads;
        if (argc == 5)
            threads = parse_u32(argv[4], "threads");
        else {
            threads = std::thread::hardware_concurrency();
            if (threads == 0) threads = 1;
        }

        std::ifstream fin(g_path);
        if (!fin)
            throw std::runtime_error("无法打开 G.txt");

        std::vector<std::string> lines;
        std::string line;
        while (std::getline(fin, line)) {
            if (!line.empty() && line.back() == '\r') line.pop_back();
            if (line.empty())
                throw std::runtime_error("G.txt 含空行");
            lines.push_back(line);
        }

        if (lines.empty())
            throw std::runtime_error("G.txt 为空");

        int n = (int)lines[0].size();
        if (n <= 0 || n > MAX_N)
            throw std::runtime_error("N 超出范围");

        std::vector<Bits> rows;
        rows.reserve(lines.size());

        for (const std::string& s : lines) {
            if ((int)s.size() != n)
                throw std::runtime_error("各行长度不一致");

            Bits b;
            for (int j = 0; j < n; ++j) {
                if (s[j] == '1') togglebit(b, j);
                else if (s[j] != '0')
                    throw std::runtime_error("G.txt 含非 0/1 字符");
            }
            rows.push_back(b);
        }

        std::vector<Bits> rref = rows;
        std::vector<int> pivots;
        int rank = 0;

        for (int col = 0; col < n && rank < (int)rref.size(); ++col) {
            int sel = -1;
            for (int i = rank; i < (int)rref.size(); ++i) {
                if (getbit(rref[i], col)) {
                    sel = i;
                    break;
                }
            }
            if (sel < 0) continue;

            std::swap(rref[rank], rref[sel]);

            for (int i = 0; i < (int)rref.size(); ++i) {
                if (i != rank && getbit(rref[i], col))
                    xorbits(rref[i], rref[rank]);
            }

            pivots.push_back(col);
            ++rank;
        }

        int redundancy = n - rank;
        if (redundancy > 41)
            throw std::runtime_error("N-K 超出题目规定范围");

        std::vector<bool> is_pivot(n, false);
        for (int p : pivots) is_pivot[p] = true;

        std::vector<Bits> parity_rows;
        parity_rows.reserve(redundancy);

        for (int free_col = 0; free_col < n; ++free_col) {
            if (is_pivot[free_col]) continue;

            Bits v;
            togglebit(v, free_col);

            for (int i = 0; i < rank; ++i) {
                if (getbit(rref[i], free_col))
                    togglebit(v, pivots[i]);
            }

            parity_rows.push_back(v);
        }

        std::vector<U64> column_syndrome(n, 0);
        for (int c = 0; c < n; ++c) {
            U64 s = 0;
            for (int i = 0; i < redundancy; ++i) {
                if (getbit(parity_rows[i], c))
                    s |= 1ULL << i;
            }
            column_syndrome[c] = s;
        }

        bool answer = true;
        SearchResult found;
        U64 low_generated = 0;
        U64 high_checked = 0;
        int orientations = 0;

        if (rank != 0 && D > 1) {
            U64 phys = physical_memory_bytes();
            U64 budget = phys ? (phys * 80 / 100)
                              : (400ULL << 30);

            int t = D - 1;
            int mid = n / 2;

            std::vector<int> left, right;
            for (int i = 0; i < mid; ++i) left.push_back(i);
            for (int i = mid; i < n; ++i) right.push_back(i);

            SearchEngine engine(n, D, (int)threads,
                                column_syndrome, budget);

            std::cerr << "rank=" << rank
                      << " redundancy=" << redundancy
                      << " D=" << D << "\n";

            engine.run_orientation(left, right);
            ++orientations;

            if (!engine.stop.load() &&
                !engine.internal_error.load()) {
                engine.run_orientation(right, left);
                ++orientations;
            }

            if (engine.internal_error.load())
                throw std::runtime_error("搜索内部错误");

            low_generated = engine.low_generated.load();
            high_checked = engine.high_checked.load();

            if (engine.result.found) {
                answer = false;
                found = engine.result;

                if (found.weight <= 0 || found.weight >= D)
                    throw std::runtime_error("witness 重量错误");

                if (popcount_bits(found.word, n) != found.weight)
                    throw std::runtime_error("witness 重量自检失败");

                if (!in_row_span(rref, pivots, rank, n, found.word))
                    throw std::runtime_error("witness 不属于生成矩阵张成空间");
            }
        }

        std::ofstream fout(out_path + ".tmp");
        if (!fout)
            throw std::runtime_error("无法创建输出临时文件");

        fout << "{\"n\":" << n
             << ",\"k\":" << rank
             << ",\"rows\":" << rows.size()
             << ",\"D\":" << D
             << ",\"d_ge_D\":" << (answer ? "true" : "false")
             << ",\"method\":\"按综合做两半坐标的完整重量有界 meet-in-the-middle 枚举，每个综合保留最小重量并穷举另一半\""
             << ",\"work\":{"
             << "\"orientations\":" << orientations
             << ",\"low_subsets_generated\":" << low_generated
             << ",\"high_subsets_checked\":" << high_checked
             << "}";

        if (answer) {
            fout << ",\"witness\":null}\n";
        } else {
            fout << ",\"witness\":{\"codeword\":\""
                 << bits_to_string(found.word, n)
                 << "\",\"weight\":" << found.weight
                 << "}}\n";
        }

        fout.close();
        if (!fout)
            throw std::runtime_error("写出 JSON 失败");

        std::string tmp = out_path + ".tmp";
        if (std::rename(tmp.c_str(), out_path.c_str()) != 0) {
            std::remove(tmp.c_str());
            throw std::runtime_error("替换输出文件失败");
        }

        std::cerr << "done\n";
        return 0;
    } catch (const std::bad_alloc&) {
        std::cerr << "error: 内存不足\n";
        return 2;
    } catch (const std::exception& e) {
        std::cerr << "error: " << e.what() << "\n";
        return 2;
    }
}
