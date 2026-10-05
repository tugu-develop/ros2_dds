#!/usr/bin/env bash
# talker が実際に読み込んでいるライブラリを rmw ごとに表示する。
# rclcpp / rcl / rmw は共通で、DDS実装(libfastrtps / libddsc)だけが入れ替わることを確認する。
set -u

TALKER=/opt/ros/jazzy/lib/demo_nodes_cpp/talker

for rmw in rmw_fastrtps_cpp rmw_cyclonedds_cpp; do
  RMW_IMPLEMENTATION=$rmw "$TALKER" > /dev/null 2>&1 &
  pid=$!
  sleep 2
  echo "== $rmw =="
  grep -oE '[^ ]*(librclcpp|librcl\.|librmw|libfastrtps|libddsc)[^ ]*' "/proc/$pid/maps" \
    | xargs -r -n1 basename | sort -u
  kill "$pid" 2>/dev/null
  wait "$pid" 2>/dev/null
  echo
done
