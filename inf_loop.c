#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <unistd.h>

int main() {
    uint64_t iterator = 0;
    while (true) {
        printf("hello: %" PRIu64 "\n", ++iterator);
        sleep(2);
    }
    return 0;
}
