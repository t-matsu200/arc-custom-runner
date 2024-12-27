#!/bin/bash

dumb-init bash <<'SCRIPT' &

log() {
  local instant level msg
  level=$1
  msg=$2
  instant=$(date '+%F %T.%-3N' 2>/dev/null || :)
  echo "[$instant] [$level] --- $msg"
}

function wait_for_process () {
  local max_time_wait=30
  local process_name="$1"
  local waited_sec=0

  while ! pgrep "$process_name" >/dev/null && ((waited_sec < max_time_wait)); do
    log 'INFO' "Process $process_name is not running yet. Retrying in 1 seconds"
    log 'INFO' "Waited $waited_sec seconds of $max_time_wait seconds"
    sleep 1
    ((waited_sec=waited_sec+1))
    if ((waited_sec >= max_time_wait)); then
      return 1
    fi
  done
  return 0
}

log 'INFO' 'Starting Docker daemon'
DOCKER_GID=$(getent group docker | cut -d: -f3)
sudo /usr/bin/dockerd --host=unix:///var/run/docker.sock --group=$DOCKER_GID &

log 'INFO' 'Waiting for processes to be running...'
processes=(dockerd)

for process in "${processes[@]}"; do
  if ! wait_for_process "$process"; then
    log 'ERROR' "$process is not running after max time"
    exit 1
  else
    log 'INFO' "$process is running"
  fi
done

/bin/bash /home/runner/run.sh
SCRIPT

RUNNER_INIT_PID=$!
wait $RUNNER_INIT_PID
