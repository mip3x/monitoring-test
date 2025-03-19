# monitoring
Мониторинг процесса

1. ![inf_loop.c](./inf_loop.c)

Сначала был написан бесконечный цикл, который выводит строку и ждёт затем 2 секунды:

```c fold title:inf_loop.c
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
```

2. ![test_monitor.sh](./test_monitor.sh)
   
Затем был написан скрипт, который проверяет, существует ли процесс с именем, совпадающим с первым переданным при запуске скрипта аргументом
