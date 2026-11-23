#include <array>
#include <atomic>
#include <cstdint>
#include <cstdio>
#include <fstream>
#include <iostream>
#include <limits>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <string>
#include <thread>
#include <unistd.h>
#include <vector>
#include <algorithm>

using U64 = uint64_t;

constexpr int MAX_N = 260;
constexpr int WORDS = (MAX_N + 63) / 64;
constexpr U64 EMPTY_KEY = std::numeric_limits<U64>::max();

struct Bits {
    std::array<U64, WORDS> x{};
};

static inline bool bit_get(const Bits& b, int p) {
    return (b.x[p >> 6] >> (p & 63)) & 1ULL;
}

static inline void bit_toggle(Bits& b, int p) {
    b.x[p >> 6] ^= 1ULL << (p & 63);
}

static inline void bits_xor(Bits& a, const Bits& b) {
    for (int i = 0; i < WORDS; ++i)
        a.x[i] ^= b.x[i];
}

static inline bool bits_equal(const Bits& a, const Bits& b) {
    for (int i = 0; i < WORDS; ++i)
        if (a.x[i] != b.x[i]) return false;
    return true;
}

static inline int bits_weight(const Bits& b, int n) {
    int ans = 0;
    int words = (n + 63) / 64;

    for (int i = 0; i < words; ++i)
        ans += __builtin_popcountll(b.x[i]);

    return ans;
}

static inline U64 mix64(U64 x) {
    x += 0x9e3779b97f4a7c15ULL;
    x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ULL;
    x = (x ^ (x >> 27)) * 0x94d049bb133111ebULL;
    return x ^ (x >> 31);
}

static U64 choose_u64(int n, int k) {
    if (k < 0 || k > n) return 0;
    k = std::min(k, n - k);

    __int128 v = 1;

    for (int i = 1; i <= k; ++i) {
        v = v * (n - i + 1) / i;

        if (v > std::numeric_limits<U64>::max())
            throw std::runtime_error("计数超过 64 位范围，所需内存不可行");
    }

    return (U64)v;
}

static U64 sat_add(U64 a, U64 b) {
    if (a > std::numeric_limits<U64>::max() - b)
        throw std::runtime_error("计数超过 64 位范围，所需内存不可行");

    return a + b;
}

static U64 physical_memory() {
    long pages = sysconf(_SC_PHYS_PAGES);
    long page_size = sysconf(_SC_PAGE_SIZE);

    if (pages <= 0 || page_size <= 0)
        return 0;

    __int128 x = (__int128)pages * page_size;

    if (x > std::numeric_limits<U64>::max())
        return std::numeric_limits<U64>::max();

    return (U64)x;
}

enum class InsertResult {
    Inserted,
    Existing,
    Full
};

class SyndromeSet {
public:
    enum class Mode {
        Hash,
        Bitmap
    };

private:
    Mode mode_ = Mode::Hash;
    int rho_ = 0;

    U64 capacity_ = 0;
    U64 mask_ = 0;
    std::unique_ptr<std::atomic<U64>[]> slots_;

    U64 bitmap_words_ = 0;
    std::unique_ptr<std::atomic<U64>[]> bitmap_;

    std::atomic<U64> used_{0};

    static U64 next_power_two(U64 x) {
        U64 p = 1;

        while (p < x) {
            if (p > (std::numeric_limits<U64>::max() >> 1))
                throw std::runtime_error("哈希表容量溢出");

            p <<= 1;
        }

        return p;
    }

    void init_hash(U64 expected, U64 available) {
        if (expected == 0)
            expected = 1;

        __int128 t = ((__int128)expected * 10 + 6) / 7;

        if (t > std::numeric_limits<U64>::max())
            throw std::runtime_error("哈希表容量溢出");

        U64 need = std::max<U64>(16, (U64)t);
        U64 cap = next_power_two(need);

        __int128 bytes = (__int128)cap * sizeof(std::atomic<U64>);

        if (bytes > available)
            throw std::runtime_error("内存不足：综合哈希表");

        mode_ = Mode::Hash;
        capacity_ = cap;
        mask_ = cap - 1;

        slots_.reset(new std::atomic<U64>[cap]);

        for (U64 i = 0; i < cap; ++i)
            slots_[i].store(EMPTY_KEY, std::memory_order_relaxed);

        bitmap_.reset();
        bitmap_words_ = 0;
        used_.store(0, std::memory_order_relaxed);
    }

    void move_from(SyndromeSet&& other) noexcept {
        mode_ = other.mode_;
        rho_ = other.rho_;
        capacity_ = other.capacity_;
        mask_ = other.mask_;
        slots_ = std::move(other.slots_);
        bitmap_words_ = other.bitmap_words_;
        bitmap_ = std::move(other.bitmap_);
        used_.store(other.used_.load(std::memory_order_relaxed),
                     std::memory_order_relaxed);

        other.capacity_ = 0;
        other.mask_ = 0;
        other.bitmap_words_ = 0;
        other.used_.store(0, std::memory_order_relaxed);
    }

public:
    SyndromeSet() = default;

    SyndromeSet(const SyndromeSet&) = delete;
    SyndromeSet& operator=(const SyndromeSet&) = delete;

    SyndromeSet(SyndromeSet&& other) noexcept {
        move_from(std::move(other));
    }

    SyndromeSet& operator=(SyndromeSet&& other) noexcept {
        if (this != &other) {
            clear();
            move_from(std::move(other));
        }

        return *this;
    }

    void clear() {
        slots_.reset();
        bitmap_.reset();

        capacity_ = 0;
        mask_ = 0;
        bitmap_words_ = 0;

        used_.store(0, std::memory_order_relaxed);
    }

    void init(int rho, U64 expected, U64 available, bool allow_bitmap) {
        clear();
        rho_ = rho;

        if (allow_bitmap) {
            U64 words = rho <= 6 ? 1ULL : (1ULL << (rho - 6));
            __int128 bytes = (__int128)words * sizeof(std::atomic<U64>);

            if (bytes <= available) {
                mode_ = Mode::Bitmap;
                bitmap_words_ = words;
                bitmap_.reset(new std::atomic<U64>[words]);

                for (U64 i = 0; i < words; ++i)
                    bitmap_[i].store(0, std::memory_order_relaxed);

                used_.store(0, std::memory_order_relaxed);
                return;
            }
        }

        init_hash(expected, available);
    }

    Mode mode() const {
        return mode_;
    }

    U64 bytes() const {
        if (mode_ == Mode::Bitmap)
            return bitmap_words_ * sizeof(std::atomic<U64>);

        return capacity_ * sizeof(std::atomic<U64>);
    }

    U64 size() const {
        return used_.load(std::memory_order_relaxed);
    }

    bool can_hold(U64 additional) const {
        if (mode_ == Mode::Bitmap)
            return true;

        U64 now = size();

        if (additional > std::numeric_limits<U64>::max() - now)
            return false;

        U64 total = now + additional;

        return (__int128)total * 10 <= (__int128)capacity_ * 7;
    }

    bool contains(U64 key) const {
        if (mode_ == Mode::Bitmap) {
            U64 word = key >> 6;
            U64 bit = 1ULL << (key & 63);

            return (bitmap_[word].load(std::memory_order_relaxed) & bit) != 0;
        }

        U64 start = mix64(key) & mask_;
        U64 p = start;

        while (true) {
            U64 v = slots_[p].load(std::memory_order_acquire);

            if (v == EMPTY_KEY)
                return false;

            if (v == key)
                return true;

            p = (p + 1) & mask_;

            if (p == start)
                return false;
        }
    }

    InsertResult insert_or_existing(U64 key) {
        if (mode_ == Mode::Bitmap) {
            U64 word = key >> 6;
            U64 bit = 1ULL << (key & 63);
            U64 old = bitmap_[word].fetch_or(bit, std::memory_order_acq_rel);

            if (old & bit)
                return InsertResult::Existing;

            used_.fetch_add(1, std::memory_order_relaxed);
            return InsertResult::Inserted;
        }

        U64 start = mix64(key) & mask_;
        U64 p = start;

        while (true) {
            U64 v = slots_[p].load(std::memory_order_acquire);

            if (v == key)
                return InsertResult::Existing;

            if (v == EMPTY_KEY) {
                U64 expected = EMPTY_KEY;

                if (slots_[p].compare_exchange_weak(
                        expected, key,
                        std::memory_order_acq_rel,
                        std::memory_order_acquire)) {
                    used_.fetch_add(1, std::memory_order_relaxed);
                    return InsertResult::Inserted;
                }

                continue;
            }

            p = (p + 1) & mask_;

            if (p == start)
                return InsertResult::Full;
        }
    }

    template<class F>
    void for_each_hash_key(F&& f) const {
        if (mode_ != Mode::Hash)
            throw std::runtime_error("内部错误：试图遍历位图");

        for (U64 i = 0; i < capacity_; ++i) {
            U64 v = slots_[i].load(std::memory_order_relaxed);

            if (v != EMPTY_KEY)
                f(v);
        }
    }

    const char* mode_name() const {
        return mode_ == Mode::Bitmap ? "bitmap" : "exact-hash";
    }

    void rebuild_hash_from(const SyndromeSet& old,
                           const SyndromeSet& extra,
                           int rho,
                           U64 available) {
        U64 total = sat_add(old.size(), extra.size());

        SyndromeSet fresh;
        fresh.init(rho, total, available, false);

        old.for_each_hash_key([&](U64 s) {
            if (fresh.insert_or_existing(s) == InsertResult::Full)
                throw std::runtime_error("内部错误：重建综合表溢出");
        });

        extra.for_each_hash_key([&](U64 s) {
            if (fresh.insert_or_existing(s) == InsertResult::Full)
                throw std::runtime_error("内部错误：合并综合表溢出");
        });

        *this = std::move(fresh);
    }
};

struct WorkEntry {
    int weight = 0;
    U64 expected = 0;
    U64 visits = 0;
    bool complete = false;
    std::string operation;
};

struct SearchResult {
    bool found = false;
    Bits codeword{};
    int weight = 0;
};

class Solver {
    int n_;
    int rho_;
    int D_;
    int limit_;
    int threads_;
    U64 memory_budget_;

    const std::vector<U64>& column_syndrome_;

    SyndromeSet* active_set_ = nullptr;
    std::atomic<U64>* active_count_ = nullptr;
    std::atomic<bool>* active_full_ = nullptr;

    enum class ActiveMode {
        InsertCurrent,
        QueryGlobal
    } active_mode_ = ActiveMode::QueryGlobal;

    int active_weight_ = 0;
    int active_recovery_max_ = 0;

    std::atomic<bool> stop_{false};
    std::atomic<bool> internal_error_{false};

    std::mutex result_mutex_;
    std::mutex progress_mutex_;
    SearchResult result_;

    void progress(U64 x, const char* label) {
        if (x && x % 20000000ULL == 0) {
            std::lock_guard<std::mutex> lock(progress_mutex_);
            std::cerr << label << ": " << x << "\n";
        }
    }

    bool recover_rec(int start,
                     int need,
                     U64 syndrome,
                     U64 target,
                     const Bits& current,
                     Bits& bits,
                     Bits& answer) {
        if (need == 0) {
            if (syndrome == target && !bits_equal(bits, current)) {
                answer = bits;
                return true;
            }

            return false;
        }

        for (int i = start; i <= n_ - need; ++i) {
            bit_toggle(bits, i);

            if (recover_rec(i + 1,
                            need - 1,
                            syndrome ^ column_syndrome_[i],
                            target,
                            current,
                            bits,
                            answer)) {
                bit_toggle(bits, i);
                return true;
            }

            bit_toggle(bits, i);
        }

        return false;
    }

    bool recover_other(int max_weight,
                       U64 target,
                       const Bits& current,
                       Bits& answer) {
        for (int weight = 0; weight <= max_weight; ++weight) {
            Bits bits;

            if (weight == 0) {
                if (target == 0 && !bits_equal(bits, current)) {
                    answer = bits;
                    return true;
                }

                continue;
            }

            if (recover_rec(0,
                            weight,
                            0,
                            target,
                            current,
                            bits,
                            answer)) {
                return true;
            }
        }

        return false;
    }

    void claim_candidate(U64 syndrome,
                         const Bits& current,
                         int recovery_max) {
        bool expected = false;

        if (!stop_.compare_exchange_strong(expected, true))
            return;

        Bits other;

        if (!recover_other(recovery_max, syndrome, current, other)) {
            internal_error_.store(true, std::memory_order_relaxed);
            return;
        }

        Bits word = current;
        bits_xor(word, other);

        int weight = bits_weight(word, n_);

        if (weight <= 0 || weight >= D_) {
            internal_error_.store(true, std::memory_order_relaxed);
            return;
        }

        std::lock_guard<std::mutex> lock(result_mutex_);

        result_.found = true;
        result_.codeword = word;
        result_.weight = weight;
    }

    void leaf(U64 syndrome, Bits& bits) {
        if (stop_.load(std::memory_order_relaxed) ||
            internal_error_.load(std::memory_order_relaxed)) {
            return;
        }

        U64 count =
            active_count_->fetch_add(1, std::memory_order_relaxed) + 1;

        progress(count, "subsets");

        if (active_mode_ == ActiveMode::QueryGlobal) {
            if (active_set_->contains(syndrome))
                claim_candidate(syndrome, bits, active_recovery_max_);

            return;
        }

        if (active_set_->contains(syndrome)) {
            claim_candidate(syndrome, bits, active_weight_ - 1);
            return;
        }

        InsertResult r = active_set_->insert_or_existing(syndrome);

        if (r == InsertResult::Existing) {
            claim_candidate(syndrome, bits, active_weight_);
        } else if (r == InsertResult::Full) {
            active_full_->store(true, std::memory_order_relaxed);
        }
    }

    void enumerate_tail(int pos,
                        int need,
                        U64 syndrome,
                        Bits& bits) {
        if (stop_.load(std::memory_order_relaxed) ||
            internal_error_.load(std::memory_order_relaxed) ||
            active_full_->load(std::memory_order_relaxed)) {
            return;
        }

        if (need == 0) {
            leaf(syndrome, bits);
            return;
        }

        for (int i = pos; i <= n_ - need; ++i) {
            bit_toggle(bits, i);

            enumerate_tail(i + 1,
                           need - 1,
                           syndrome ^ column_syndrome_[i],
                           bits);

            bit_toggle(bits, i);

            if (stop_.load(std::memory_order_relaxed) ||
                internal_error_.load(std::memory_order_relaxed) ||
                active_full_->load(std::memory_order_relaxed)) {
                return;
            }
        }
    }

    U64 enumerate_weight(int weight,
                         SyndromeSet& set,
                         std::atomic<U64>& count,
                         std::atomic<bool>& full,
                         ActiveMode mode,
                         int recovery_max) {
        active_set_ = &set;
        active_count_ = &count;
        active_full_ = &full;
        active_mode_ = mode;
        active_weight_ = weight;
        active_recovery_max_ = recovery_max;

        if (weight == 0) {
            Bits bits;
            leaf(0, bits);
            return count.load(std::memory_order_relaxed);
        }

        int tasks = n_ - weight + 1;
        int workers = std::max(1, std::min(threads_, tasks));
        std::atomic<int> next_task{0};
        std::vector<std::thread> pool;
        pool.reserve(workers);

        auto worker = [&]() {
            while (!stop_.load(std::memory_order_relaxed) &&
                   !internal_error_.load(std::memory_order_relaxed) &&
                   !full.load(std::memory_order_relaxed)) {
                int first = next_task.fetch_add(1, std::memory_order_relaxed);

                if (first >= tasks)
                    break;

                Bits bits;
                bit_toggle(bits, first);

                if (weight == 1) {
                    leaf(column_syndrome_[first], bits);
                } else {
                    enumerate_tail(first + 1,
                                   weight - 1,
                                   column_syndrome_[first],
                                   bits);
                }
            }
        };

        try {
            for (int i = 0; i < workers; ++i)
                pool.emplace_back(worker);
        } catch (...) {
            for (auto& t : pool)
                t.join();

            throw;
        }

        for (auto& t : pool)
            t.join();

        return count.load(std::memory_order_relaxed);
    }

    void merge_current(SyndromeSet& global,
                       const SyndromeSet& current) {
        if (global.mode() == SyndromeSet::Mode::Bitmap) {
            current.for_each_hash_key([&](U64 s) {
                if (global.insert_or_existing(s) == InsertResult::Full)
                    throw std::runtime_error("内部错误：位图插入失败");
            });

            return;
        }

        if (global.can_hold(current.size())) {
            current.for_each_hash_key([&](U64 s) {
                if (global.insert_or_existing(s) == InsertResult::Full)
                    throw std::runtime_error("内部错误：综合表插入失败");
            });

            return;
        }

        U64 old_bytes = global.bytes();
        U64 current_bytes = current.bytes();

        if (old_bytes > memory_budget_ - current_bytes)
            throw std::runtime_error("内存不足：合并综合表");

        U64 available =
            memory_budget_ - old_bytes - current_bytes;

        SyndromeSet fresh;
        fresh.rebuild_hash_from(global, current, rho_, available);
        global = std::move(fresh);
    }

public:
    Solver(int n,
           int rho,
           int D,
           int threads,
           U64 memory_budget,
           const std::vector<U64>& column_syndrome)
        : n_(n),
          rho_(rho),
          D_(D),
          limit_(D - 1),
          threads_(threads),
          memory_budget_(memory_budget),
          column_syndrome_(column_syndrome) {}

    SearchResult run(std::vector<WorkEntry>& work,
                     std::string& set_mode) {
        int h = (limit_ + 1) / 2;
        int stored_max = (limit_ % 2 == 0) ? h : h - 1;

        SyndromeSet global;
        global.init(rho_, 1, memory_budget_, true);
        set_mode = global.mode_name();

        std::cerr << "rho=" << rho_
                  << " h=" << h
                  << " stored_max=" << stored_max
                  << "\n";

        for (int weight = 0; weight <= h; ++weight) {
            WorkEntry entry;
            entry.weight = weight;
            entry.expected = choose_u64(n_, weight);

            bool odd_final_lookup =
                (limit_ % 2 == 1 && weight == h);

            entry.operation = odd_final_lookup
                ? "lookup"
                : "insert_and_collision_check";

            if (odd_final_lookup) {
                std::atomic<U64> count{0};
                std::atomic<bool> full{false};

                enumerate_weight(weight,
                                 global,
                                 count,
                                 full,
                                 ActiveMode::QueryGlobal,
                                 stored_max);

                entry.visits =
                    count.load(std::memory_order_relaxed);

                if (!stop_.load(std::memory_order_relaxed) &&
                    !internal_error_.load(std::memory_order_relaxed) &&
                    entry.visits != entry.expected) {
                    throw std::runtime_error(
                        "内部错误：重量层未完整枚举");
                }

                entry.complete =
                    !stop_.load(std::memory_order_relaxed) &&
                    !internal_error_.load(std::memory_order_relaxed) &&
                    entry.visits == entry.expected;

                work.push_back(entry);

                if (stop_.load(std::memory_order_relaxed) ||
                    internal_error_.load(std::memory_order_relaxed)) {
                    break;
                }

                continue;
            }

            U64 hint = std::min<U64>(entry.expected, 1ULL << 20);

            if (hint == 0)
                hint = 1;

            bool finished = false;

            while (!finished) {
                if (stop_.load(std::memory_order_relaxed) ||
                    internal_error_.load(std::memory_order_relaxed)) {
                    break;
                }

                if (global.bytes() > memory_budget_)
                    throw std::runtime_error("内存不足：综合表");

                U64 available = memory_budget_ - global.bytes();

                SyndromeSet current;
                current.init(rho_, hint, available, false);

                std::atomic<U64> count{0};
                std::atomic<bool> full{false};

                enumerate_weight(weight,
                                 current,
                                 count,
                                 full,
                                 ActiveMode::InsertCurrent,
                                 weight - 1);

                U64 pass_visits =
                    count.load(std::memory_order_relaxed);

                entry.visits = sat_add(entry.visits, pass_visits);

                if (stop_.load(std::memory_order_relaxed) ||
                    internal_error_.load(std::memory_order_relaxed)) {
                    break;
                }

                if (full.load(std::memory_order_relaxed)) {
                    if (hint > (std::numeric_limits<U64>::max() >> 1))
                        throw std::runtime_error("综合表扩容溢出");

                    hint <<= 1;
                    continue;
                }

                if (pass_visits != entry.expected)
                    throw std::runtime_error(
                        "内部错误：重量层未完整枚举");

                merge_current(global, current);

                entry.complete = true;
                finished = true;
            }

            work.push_back(entry);

            if (stop_.load(std::memory_order_relaxed) ||
                internal_error_.load(std::memory_order_relaxed)) {
                break;
            }
        }

        if (internal_error_.load(std::memory_order_relaxed))
            throw std::runtime_error("搜索内部错误");

        return result_;
    }
};

static long long parse_i64(const std::string& s, const char* name) {
    size_t p = 0;
    long long v;

    try {
        v = std::stoll(s, &p);
    } catch (...) {
        throw std::runtime_error(std::string("非法") + name);
    }

    if (p != s.size())
        throw std::runtime_error(std::string("非法") + name);

    return v;
}

static unsigned parse_threads(const std::string& s) {
    size_t p = 0;
    unsigned long long v;

    try {
        v = std::stoull(s, &p);
    } catch (...) {
        throw std::runtime_error("非法 threads");
    }

    if (p != s.size() || v == 0 || v > 1000000ULL)
        throw std::runtime_error("非法 threads");

    return (unsigned)v;
}

static std::string bits_string(const Bits& b, int n) {
    std::string s(n, '0');

    for (int i = 0; i < n; ++i)
        if (bit_get(b, i))
            s[i] = '1';

    return s;
}

static bool in_row_span(const std::vector<Bits>& rref,
                        const std::vector<int>& pivots,
                        int rank,
                        int n,
                        const Bits& target) {
    Bits x = target;

    for (int i = 0; i < rank; ++i) {
        if (bit_get(x, pivots[i]))
            bits_xor(x, rref[i]);
    }

    return bits_weight(x, n) == 0;
}

int main(int argc, char** argv) {
    std::string output_path;
    std::string temporary_path;

    try {
        if (argc != 4 && argc != 5)
            throw std::runtime_error(
                "用法：verify_b G.txt D out.json [threads]");

        long long Dll = parse_i64(argv[2], "D");

        if (Dll > 40)
            throw std::runtime_error("D 必须不大于 40");

        int D = (int)Dll;
        output_path = argv[3];

        unsigned threads;

        if (argc == 5) {
            threads = parse_threads(argv[4]);
        } else {
            threads = std::thread::hardware_concurrency();

            if (threads == 0)
                threads = 1;
        }

        std::ifstream fin(argv[1]);

        if (!fin)
            throw std::runtime_error("无法打开 G.txt");

        std::vector<std::string> lines;
        std::string line;

        while (std::getline(fin, line)) {
            if (!line.empty() && line.back() == '\r')
                line.pop_back();

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
                if (s[j] == '1')
                    bit_toggle(b, j);
                else if (s[j] != '0')
                    throw std::runtime_error("G.txt 含非 0/1 字符");
            }

            rows.push_back(b);
        }

        std::vector<Bits> rref = rows;
        std::vector<int> pivots;
        int rank = 0;

        for (int col = 0;
             col < n && rank < (int)rref.size();
             ++col) {
            int selected = -1;

            for (int i = rank; i < (int)rref.size(); ++i) {
                if (bit_get(rref[i], col)) {
                    selected = i;
                    break;
                }
            }

            if (selected < 0)
                continue;

            std::swap(rref[rank], rref[selected]);

            for (int i = 0; i < (int)rref.size(); ++i) {
                if (i != rank && bit_get(rref[i], col))
                    bits_xor(rref[i], rref[rank]);
            }

            pivots.push_back(col);
            ++rank;
        }

        int rho = n - rank;

        if (rho > 41)
            throw std::runtime_error("N-K 超出题目规定范围");

        std::vector<bool> is_pivot(n, false);

        for (int p : pivots)
            is_pivot[p] = true;

        std::vector<Bits> parity_rows;
        parity_rows.reserve(rho);

        for (int free_col = 0; free_col < n; ++free_col) {
            if (is_pivot[free_col])
                continue;

            Bits v;
            bit_toggle(v, free_col);

            for (int i = 0; i < rank; ++i) {
                if (bit_get(rref[i], free_col))
                    bit_toggle(v, pivots[i]);
            }

            parity_rows.push_back(v);
        }

        std::vector<U64> column_syndrome(n, 0);

        for (int c = 0; c < n; ++c) {
            U64 syndrome = 0;

            for (int i = 0; i < rho; ++i) {
                if (bit_get(parity_rows[i], c))
                    syndrome |= 1ULL << i;
            }

            column_syndrome[c] = syndrome;
        }

        bool d_ge_D = true;
        SearchResult result;
        std::vector<WorkEntry> work;
        std::string set_mode = "none";

        if (rank != 0 && D > 1) {
            U64 phys = physical_memory();
            U64 budget = phys ? (phys * 80 / 100)
                              : (400ULL << 30);

            std::cerr << "n=" << n
                      << " k=" << rank
                      << " rho=" << rho
                      << " D=" << D
                      << " threads=" << threads
                      << "\n";

            Solver solver(n,
                          rho,
                          D,
                          (int)threads,
                          budget,
                          column_syndrome);

            result = solver.run(work, set_mode);

            if (result.found) {
                d_ge_D = false;

                if (result.weight <= 0 || result.weight >= D)
                    throw std::runtime_error("witness 重量错误");

                if (bits_weight(result.codeword, n) != result.weight)
                    throw std::runtime_error("witness 重量自检失败");

                if (!in_row_span(rref,
                                 pivots,
                                 rank,
                                 n,
                                 result.codeword)) {
                    throw std::runtime_error(
                        "witness 不属于生成矩阵张成空间");
                }
            }
        }

        temporary_path = output_path + ".tmp";

        std::ofstream fout(temporary_path);

        if (!fout)
            throw std::runtime_error("无法创建输出临时文件");

        int stored_max = 0;

        if (D > 1) {
            int limit = D - 1;
            int h = (limit + 1) / 2;
            stored_max = (limit % 2 == 0) ? h : h - 1;
        }

        fout << "{\"n\":" << n
             << ",\"k\":" << rank
             << ",\"rows\":" << lines.size()
             << ",\"D\":" << D
             << ",\"d_ge_D\":"
             << (d_ge_D ? "true" : "false")
             << ",\"method\":\"按重量逐层枚举全部至多 ceil((D-1)/2) 列子集，以精确综合碰撞判定低重量码字；哈希键为完整综合，无概率步骤\""
             << ",\"work\":{"
             << "\"rho\":" << rho
             << ",\"stored_max_weight\":" << stored_max
             << ",\"set_mode\":\"" << set_mode << "\""
             << ",\"weights\":[";

        for (size_t i = 0; i < work.size(); ++i) {
            if (i)
                fout << ",";

            const WorkEntry& e = work[i];

            fout << "{\"w\":" << e.weight
                 << ",\"expected\":" << e.expected
                 << ",\"enumeration_visits\":" << e.visits
                 << ",\"complete\":"
                 << (e.complete ? "true" : "false")
                 << ",\"operation\":\"" << e.operation << "\"}";
        }

        fout << "]}";

        if (d_ge_D) {
            fout << ",\"witness\":null}\n";
        } else {
            fout << ",\"witness\":{\"codeword\":\""
                 << bits_string(result.codeword, n)
                 << "\",\"weight\":" << result.weight
                 << "}}\n";
        }

        fout.close();

        if (!fout)
            throw std::runtime_error("写出 JSON 失败");

        if (std::rename(temporary_path.c_str(),
                        output_path.c_str()) != 0) {
            std::remove(temporary_path.c_str());
            throw std::runtime_error("替换输出文件失败");
        }

        std::cerr << "done\n";
        return 0;
    } catch (const std::bad_alloc&) {
        if (!temporary_path.empty())
            std::remove(temporary_path.c_str());

        std::cerr << "error: 内存不足\n";
        return 2;
    } catch (const std::exception& e) {
        if (!temporary_path.empty())
            std::remove(temporary_path.c_str());

        std::cerr << "error: " << e.what() << "\n";
        return 2;
    }
}
