
#include "vendor/fluxsort.h"

#include <chrono>
#include <cstdint>
#include <iostream>
#include <vector>

const size_t LIMIT = 1000000;

using RandSeed = std::pair<uint64_t, uint64_t>;

RandSeed init_rand = {0x69B4C98CB8530805, 0xFED1DD3004688D68};

std::pair<RandSeed, int64_t> next_rand_i64(RandSeed r) {
  auto [s0, s1] = r;
  uint64_t ns1 = s0 ^ s1;
  uint64_t nr0 = (((s0 << 55) | (s0 >> 9)) ^ ns1) ^ (ns1 << 14);
  uint64_t nr1 = (ns1 << 36) | (ns1 >> 28);
  return {{nr0, nr1}, static_cast<int64_t>(s0 + s1)};
}

std::vector<int64_t> build_list(size_t size) {
  std::vector<int64_t> list(size, 0);

  RandSeed r = init_rand;
  for (size_t i = 0; i < size; ++i) {
    auto [nr, rv] = next_rand_i64(r);
    r = nr;
    list[i] = rv;
  }
  return list;
}

bool test_sort(std::vector<int64_t> list) {
    for(size_t i = 1; i < list.size(); ++i) {
    if(list[i] < list[i-1]) {
      return false;
    }
  }
  return true;
}

int main() {
  auto list = build_list(LIMIT);

  // Use prim with inline compare. LLVM tends to inline the compare for roc.
  auto start = std::chrono::high_resolution_clock::now();
  fluxsort_prim(list.data(), list.size(), sizeof(int64_t));
  auto end = std::chrono::high_resolution_clock::now();
  auto elapsed_ms = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();
  
  std::string out;
  if(test_sort(list)) {
      out = "List sorted correctly!";
  } else {
      out = "Failure in sorting list!!!";
  }
  std::cout << out << std::endl;
  std::cout << "Sorted "<<LIMIT<<" integers in "<< elapsed_ms <<" milliseconds." << std::endl;

  return 0;
}
