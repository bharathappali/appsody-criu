#!/bin/bash

DOCKER_CAPABILITIES="--cap-add AUDIT_CONTROL \
                     --cap-add DAC_READ_SEARCH \
                     --cap-add NET_ADMIN \
                     --cap-add SYS_ADMIN \
                     --cap-add SYS_PTRACE \
                     --cap-add SYS_RESOURCE \
                     --security-opt apparmor=unconfined \
                     --security-opt seccomp=unconfined"

LOG_MESSAGE="checkpoint successfull"

check_for_checkpoint() {
    echo "[  INFO  ] LOG_MESSAGE : ${LOG_MESSAGE}"
    echo "[  INFO  ] Container ID : $1"
    for i in $(seq 1 100)
    do
        docker logs "$1" 2>&1 | grep "${LOG_MESSAGE}" &> /dev/null
        local init_x=$?
		if [ ${init_x} -eq 0 ]; then
            break
        else
            if [ $i -eq 100 ]; then
                exit 1
            fi
            sleep 1
        fi
    done
}

echo "[  INFO  ] Building app image with criu"
docker build -t petclinic-springboot:to-be-checkpointed -f Dockerfile_criu .
# docker images 2>&1 | grep "to-be-checkpointed"
if [ $? -eq 0 ]; then
    echo "[  INFO  ] Image petclinic-springboot:to-be-checkpointed successfully built"
else
    echo "[  ERR   ] Docker build failed"
    exit 1
fi

echo "[  INFO  ] Running the app for checkpointing"
cp_cont_id=$(docker run ${DOCKER_CAPABILITIES} -d petclinic-springboot:to-be-checkpointed)
echo "[  INFO  ] Container created ${cp_cont_id}"

echo "[  INFO  ] Checking if checkpoint happened"
check_for_checkpoint $cp_cont_id
if [ $? -eq 0 ]; then
	docker commit ${cp_cont_id} petclinic-springboot:with-criu
	docker stop ${cp_cont_id}
fi

echo "[  INFO  ] Checking if image is created"
docker images | grep "petclinic-springboot" 2>&1 | grep "with-criu" 
if [ $? -eq 0 ]; then
	echo "[  INFO  ] petclinic-springboot:with-criu ready to use"
else
	echo "[  ERR   ] image build failed"
fi

