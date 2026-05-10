// author: tko
#ifndef COMMON_H
#define COMMON_H

#include <iostream>
#include <string>
#include <vector>
#include <memory>
#include <stdexcept>
#include <ctime>
using namespace std;

void print_hex(const char *label, const uint8_t *v, size_t len) {
    size_t i;

    printf("%s: ", label);
    for (i = 0; i < len; ++i) {
        printf("%02x", v[i]);
    }
    printf("\n");
}

#endif