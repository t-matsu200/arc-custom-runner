#!/bin/bash

# `dumb-init` を使用して、PID 1 でDockerデーモンとランナープロセスを起動する
dumb-init bash <<'SCRIPT' &

# ログ出力用の関数
log() {
  local instant level msg
  level=$1
  msg=$2
  instant=$(date -u '+%Y-%m-%d %H:%M:%SZ')
  echo "[RUNNER $instant $level entrypoint.sh] $msg"
}

# 指定したプロセスが起動するまで待機する関数
function wait_for_process () {
  local max_time_wait=30
  local process_name="$1"
  local waited_sec=0

  # プロセスが起動するまで、またはmax_time_waitに達するまでループ
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

# DockerグループIDを取得
DOCKER_GID=$(getent group docker | cut -d: -f3)

# Dockerデーモンをバックグラウンドで実行
sudo /usr/bin/dockerd --host=unix:///var/run/docker.sock --group=$DOCKER_GID &

log 'INFO' 'Waiting for processes to be running...'

# 起動を確認するプロセスのリスト
processes=(dockerd)

# プロセスの起動を確認
for process in "${processes[@]}"; do
  if ! wait_for_process "$process"; then
    log 'ERROR' "$process is not running after max time"
    exit 1
  else
    log 'INFO' "$process is running"
  fi
done

# ランナー起動用スクリプトを実行
/bin/bash /home/runner/run.sh
SCRIPT

# 子プロセスのPIDを取得
RUNNER_INIT_PID=$!

# 子プロセスの終了を待機
wait $RUNNER_INIT_PID
