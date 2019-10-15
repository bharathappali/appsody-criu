#!/bin/bash

create_dump_folder() {
    mkdir -p /home/criu-dump-location
    touch /home/criu-dump-location/dump.log /home/criu-dump-location/restore.log
}
run_app() {
    java -jar /app.jar > out.log 2>&1 &
}

get_app_pid() {
    echo `ps -ef | grep java | grep -v grep | awk '{ print $2 }'`
}

check_server_started() {
    for i in $(seq 1 100)
    do
        cat /out.log | grep "Tomcat started on port" &> /dev/null
        local init=$?
        if [ ${init} -eq 0 ]; then
            break
        else
            if [ $i -eq 100 ]; then
                exit 1
            fi
            sleep 1
        fi
    done
}

initiate_dump() {
    mkdir -p /home/criu-dump-location/dump-image-store
    cd /home/criu-dump-location/dump-image-store
    check_server_started
    if [ $? -eq 0 ]; then
        criu dump -t "$1" --tcp-established -j -v4 -o "$2"
    fi    
}

create_dump_folder
run_app
app_pid=$(get_app_pid)
initiate_dump $app_pid "/home/criu-dump-location/dump.log"
