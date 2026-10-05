FROM ros:jazzy-ros-base

ENV DEBIAN_FRONTEND=noninteractive

# デモノード、両ベンダーのrmw、ネットワーク調査用ツール
RUN apt-get update && apt-get install -y --no-install-recommends \
      ros-jazzy-demo-nodes-cpp \
      ros-jazzy-demo-nodes-py \
      ros-jazzy-rmw-fastrtps-cpp \
      ros-jazzy-rmw-cyclonedds-cpp \
      iproute2 iputils-ping tcpdump tshark procps less \
    && rm -rf /var/lib/apt/lists/*

# ros:jazzy の ENTRYPOINT (/ros_entrypoint.sh) が setup.bash を読み込む
WORKDIR /scripts
