# monitoring
Мониторинг процесса, переданного через аргумент командной строки

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
   
Затем был написан скрипт, который проверяет, существует ли процесс с именем, совпадающим с первым переданным при запуске скрипта аргументом: с помощью `pgrep` происходит поиск по имени процесса. Если `pid` не найден, то это пишется в файл лога, если найден, сравнивается с `pid` процесса из файла `stored_pid`: если они НЕ равны, то это означает, что процесс был перезапущен, и сообщение об этом также добавляется в файл лога. Затем `current_pid` сохраняется в файл `stored_pid`.

Затем, в течение 5 секунд происходит попытка получить ответ от сервиса по `MONITOR_URL` с помощью `curl`. Если не удалось, то это пишется также в файл лога. Если удалось, то просто выводится в консоль.

```bash
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <process_name>"
    exit 1
fi

PROCESS_NAME="$1"
LOG_FILE="/var/log/monitoring.log"

MONITOR_URL="https://test.com/monitoring/test/api"
# MONITOR_URL="localhost:8081/health" # test URL

PID_FILE="/tmp/test_monitor_${PROCESS_NAME}.pid"

current_pid=$(pgrep -x "$PROCESS_NAME")

if [ -z "$current_pid" ]; then
    echo "$(date): Process '$PROCESS_NAME' is not running"
    exit 0
fi

if [ -f "$PID_FILE" ]; then
    stored_pid=$(cat "$PID_FILE")
    if [ "$stored_pid" != "$current_pid" ]; then
        echo "$(date): Process '$PROCESS_NAME' restarted. New PID: $current_pid" >> "$LOG_FILE"
    fi
fi
echo "$current_pid" > "$PID_FILE"

curl --max-time 5 --silent --fail "$MONITOR_URL" > /dev/null
if [ $? -ne 0 ]; then
    echo "$(date): Monitoring server $MONITOR_URL is not available" >> "$LOG_FILE"
else
    echo "$(date): Success sending request to $MONITOR_URL"
fi

echo "Exiting..."

exit 0
```

3. ![test_monitor.service](./test_monitor.service)

Были написаны `systemd` unit:

```service
[Unit]
Description=Monitoring test process

[Service]
Type=oneshot
ExecStart=/usr/local/bin/test_monitor.sh
```

и `timer`:
```service
[Unit]
Description=Run test_monitor.service each minute

[Timer]
Unit=test_monitor.service
OnCalendar=*-*-* *:*:00
Persistent=true

[Install]
WantedBy=timers.target
```

Для запуска `systemd` unit:
1. Необходимо прочитать новые `systemd` файлы (их нужно записать по путям `/etc/systemd/system/test_monitor.service` и `/etc/systemd/system/test_monitor.timer` соответственно):
```bash
systemctl daemon-reload
```
3. Включить таймер на автозапуск при старте системы:
```bash
systemctl enable test_monitor.timer
```
5. Запустить таймер (работа сервиса начнётся после запуска команды):
```bash
systemctl start test_monitor.timer
```
