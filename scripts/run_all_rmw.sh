#!/usr/bin/env bash
# P1-1: rmw を Fast DDS / Cyclone DDS で切り替えて talker/listener を動かし、遅延を計測する。
#
#   docker compose run --rm shell bash /scripts/run_all_rmw.sh
#
# 出力(RESULTS_DIR、既定は /results/p1_1):
#   raw_<rmw>.csv   1メッセージ1行(seq,send_ns,recv_ns,latency_ms)
#   summary.csv     rmw ごとの件数・平均・最大など
#
# 環境変数: DURATION(既定30秒)、WARMUP_SEC(集計から除く先頭秒数、既定1)、
#           P1_1_DOMAIN_ID(既定11。compose の ROS_DOMAIN_ID=0 で動く他シナリオと混ざらないよう分ける)
set -eo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SRC_DIR=${SRC_DIR:-$([ -d /src ] && echo /src || echo "$SCRIPT_DIR/../src")}
RESULTS_DIR=${RESULTS_DIR:-$([ -d /results ] && echo /results/p1_1 || echo "$SCRIPT_DIR/../results/p1_1")}
WS_DIR=${WS_DIR:-/tmp/p1_1_ws}
DURATION=${DURATION:-30}
WARMUP_SEC=${WARMUP_SEC:-1}
export ROS_DOMAIN_ID=${P1_1_DOMAIN_ID:-11}
RMWS=(rmw_fastrtps_cpp rmw_cyclonedds_cpp)

# setup.bash は未定義変数を参照するので、set -u より前に読み込む
source "/opt/ros/${ROS_DISTRO:-jazzy}/setup.bash"
set -u

echo "== build (src: $SRC_DIR -> $WS_DIR) =="
mkdir -p "$WS_DIR" "$RESULTS_DIR"
(cd "$WS_DIR" && colcon build \
  --base-paths "$SRC_DIR/p1_1_basic_pubsub" \
  --build-base "$WS_DIR/build" --install-base "$WS_DIR/install" \
  --event-handlers console_direct- )
set +u; source "$WS_DIR/install/setup.bash"; set -u
BIN="$WS_DIR/install/p1_1_basic_pubsub/lib/p1_1_basic_pubsub"

for rmw in "${RMWS[@]}"; do
  echo "== $rmw: ${DURATION}s (ROS_DOMAIN_ID=$ROS_DOMAIN_ID) =="
  export RMW_IMPLEMENTATION=$rmw
  raw="$RESULTS_DIR/raw_${rmw}.csv"

  # listener を先に起動し、DataReader が準備できてから talker を起動する
  "$BIN/listener" --ros-args -p csv_path:="$raw" > "$RESULTS_DIR/listener_${rmw}.log" 2>&1 &
  listener_pid=$!
  sleep 2

  # timeout は DURATION 秒後に SIGINT を送る(rclcpp が正常終了する)
  timeout -s INT "$DURATION" "$BIN/talker" > "$RESULTS_DIR/talker_${rmw}.log" 2>&1 || true

  sleep 1  # 送信途中のメッセージを受け取りきる
  kill -INT "$listener_pid" 2>/dev/null || true
  wait "$listener_pid" 2>/dev/null || true
  echo "received: $(($(wc -l < "$raw") - 1)) messages -> $raw"
done

echo "== summary =="
python3 - "$RESULTS_DIR" "$WARMUP_SEC" "${RMWS[@]}" <<'EOF'
import csv
import statistics
import sys

results_dir, warmup_sec, rmws = sys.argv[1], float(sys.argv[2]), sys.argv[3:]


def percentile(sorted_vals, p):
    # 最近傍法(サンプル数が少ないので補間はしない)
    idx = min(len(sorted_vals) - 1, max(0, round(p / 100 * len(sorted_vals)) - 1))
    return sorted_vals[idx]


rows = []
for rmw in rmws:
    with open(f'{results_dir}/raw_{rmw}.csv') as f:
        data = list(csv.DictReader(f))
    if not data:
        print(f'{rmw}: no samples', file=sys.stderr)
        continue
    # Discovery 直後の立ち上がりを除くため、最初の受信から warmup_sec 秒は集計しない
    t0 = int(data[0]['recv_ns'])
    lat = sorted(float(r['latency_ms']) for r in data
                 if int(r['recv_ns']) - t0 >= warmup_sec * 1e9)
    seqs = [int(r['seq']) for r in data]
    # 欠落数は「受信した seq の範囲」と受信数の差。最初に届く前の取りこぼしは含まない
    lost = (max(seqs) - min(seqs) + 1) - len(set(seqs))
    rows.append({
        'rmw': rmw,
        'samples': len(lat),
        'lost': lost,
        'mean_ms': round(statistics.fmean(lat), 4),
        'max_ms': round(lat[-1], 4),
        'min_ms': round(lat[0], 4),
        'p50_ms': round(percentile(lat, 50), 4),
        'p99_ms': round(percentile(lat, 99), 4),
    })

with open(f'{results_dir}/summary.csv', 'w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
    w.writeheader()
    w.writerows(rows)

for r in rows:
    print(', '.join(f'{k}={v}' for k, v in r.items()))
print(f'-> {results_dir}/summary.csv')
EOF

# コンテナは root で動くので、結果ファイルの所有者をホスト側の results/ に合わせる
chown -R --reference="$RESULTS_DIR/.." "$RESULTS_DIR" 2>/dev/null || true
