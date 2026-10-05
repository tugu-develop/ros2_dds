# P1-1 最小 pub/sub と rmw 切り替え

## 目的

- rclcpp の最小 talker/listener を自分で書き、`RMW_IMPLEMENTATION` を変えるだけで DDS 実装(Fast DDS / Cyclone DDS)が入れ替わることを確認する。
- `publish()` から DDS の `write` まで、受信から callback まで、どの層をどう通るかをコードと対応づけて理解する。
- 同一ホスト内の遅延(平均・最大)を rmw ごとに計測し、比較の土台を作る。

## 構成

| ファイル | 内容 |
| --- | --- |
| `src/talker.cpp` | 10Hz(`create_wall_timer(100ms)`)で `/p1_1/chatter` に `std_msgs/String` を送る。`data` は `"<seq>,<送信時刻ns>"` |
| `src/listener.cpp` | 受信時に `seq=N latency=X ms` をログ出力。パラメータ `csv_path` で1メッセージ1行の CSV も書く |
| `../../scripts/run_all_rmw.sh` | ビルドし、rmw ごとに30秒ずつ動かして `results/p1_1/` に CSV を保存する |

QoS は両側とも `rclcpp::QoS(10)` = KEEP_LAST(10) / RELIABLE / VOLATILE。

## 実行手順

ホストに ROS 2 がなくても、リポジトリ直下の Docker 環境で動きます(`./src` は `/src` に読み取り専用でマウントされ、ビルドはコンテナ内の `/tmp/p1_1_ws` で行います)。

```bash
cd ~/workspace/ros2_dds
docker compose build                                    # 初回のみ
docker compose run --rm shell bash /scripts/run_all_rmw.sh
```

| 環境変数 | 既定値 | 意味 |
| --- | --- | --- |
| `DURATION` | `30` | rmw ごとの talker 送信時間[秒] |
| `WARMUP_SEC` | `1` | 集計から除く、最初の受信からの秒数(Discovery 直後の立ち上がりを除く) |
| `P1_1_DOMAIN_ID` | `11` | 使う ROS_DOMAIN_ID。他シナリオ(ドメイン0)のノードと混ざらないよう分けている |

例:`docker compose run --rm -e DURATION=60 shell bash /scripts/run_all_rmw.sh`

手で動かす場合(コンテナ内、スクリプトを一度実行してビルド済みのとき):

```bash
source /tmp/p1_1_ws/install/setup.bash
RMW_IMPLEMENTATION=rmw_cyclonedds_cpp ros2 run p1_1_basic_pubsub listener &
RMW_IMPLEMENTATION=rmw_fastrtps_cpp   ros2 run p1_1_basic_pubsub talker      # 別ベンダー同士でも通信できる
```

### 出力(`results/p1_1/`)

| ファイル | 内容 |
| --- | --- |
| `summary.csv` | `rmw,samples,lost,mean_ms,max_ms,min_ms,p50_ms,p99_ms` |
| `raw_<rmw>.csv` | `seq,send_ns,recv_ns,latency_ms`(全メッセージ) |
| `listener_<rmw>.log` / `talker_<rmw>.log` | 各ノードのログ |

## 期待される結果

- 両 rmw とも約300件を受信し、`lost=0` になる(RELIABLE かつ同一ホストのため)。
- 遅延は両方ともサブミリ秒から1ms程度。初回の計測(2026-10-03、Docker 内、ドメイン11、UDPv4 ループバック)では次のとおり。

| rmw | samples | mean [ms] | max [ms] | p99 [ms] |
| --- | --- | --- | --- | --- |
| rmw_fastrtps_cpp | 287 | 0.79 | 1.49 | 1.06 |
| rmw_cyclonedds_cpp | 288 | 0.63 | 0.83 | 0.81 |

この程度の差は実行ごとに入れ替わることもあります。**1回の計測で「どちらが速い」と結論しない**でください。

## 観察ポイント

1. **何を測っているか**:遅延は「talker の `publish()` 直前」から「listener の callback 冒頭」まで。DDS の転送だけでなく、シリアライズ、rmw の待機解除、Executor のディスパッチ、デシリアライズも含む。
2. **トランスポート**:compose で `FASTDDS_BUILTIN_TRANSPORTS=UDPv4` が設定されているため、Fast DDS の共有メモリ(SHM)は無効で、両 rmw とも UDP ループバックで比べている。外して(`-e FASTDDS_BUILTIN_TRANSPORTS=DEFAULT`)Fast DDS だけ SHM にすると、どう変わるかを試す。
3. **最初の数件**:`raw_*.csv` の先頭は他より遅かったり、seq が 0 から始まらないことがある。Discovery(SPDP/SEDP)でマッチングが済む前に送ったメッセージは VOLATILE なので届かない。
4. **max と p99 の差**:max は OS スケジューリングの影響を受ける外れ値1件で決まる。比べるなら p99 も見る。
5. **ライブラリの入れ替わり**:`docker compose run --rm layers` で、rmw を変えても `librclcpp` / `librcl` / `librmw` は共通で、`libfastrtps` と `libddsc` だけが入れ替わることを確認する。
6. **DDS 上の名前**:`ros2 topic info -v /p1_1/chatter` で型名 `std_msgs::msg::dds_::String_`、ノードの GID、QoS を見る。DDS 上のトピック名は `rt/p1_1/chatter` になる。

## rclcpp → rcl → rmw → DDS の呼び出し経路

関数名は ROS 2 Jazzy のソースに基づいています。行番号は版によって変わるので、GitHub(ros2/rclcpp、ros2/rcl、ros2/rmw_fastrtps、ros2/rmw_cyclonedds)で関数名を検索して読んでください。

### 層の役割

| 層 | ライブラリ | 役割 |
| --- | --- | --- |
| rclcpp | `librclcpp.so` | C++ API(Node、Publisher、Executor、テンプレートによる型付け) |
| rcl | `librcl.so` | 言語に依存しない C の共通処理(トピック名の展開とリマップ、引数、ロギング、検証) |
| rmw | `librmw.so` + `librmw_implementation.so` | DDS を抽象化した C インタフェース。`librmw_implementation` が `RMW_IMPLEMENTATION` を見て、実装ライブラリを実行時に `dlopen` する |
| rmw 実装 | `librmw_fastrtps_cpp.so` / `librmw_cyclonedds_cpp.so` | rmw の関数を各 DDS の API に変換する。CDR シリアライズもここで行う |
| DDS | `libfastrtps.so`(Jazzy は Fast DDS 2.14) / `libddsc.so` | DCPS(DomainParticipant / DataWriter / DataReader)と RTPS プロトコル、UDP/SHM トランスポート |

ポイントは、**talker/listener のバイナリは rmw 実装をリンクしていない**ことです。rcl までは同じコードで、rmw の関数呼び出しが `librmw_implementation` を経由して、実行時に選んだ実装へ振り分けられます。そのため再ビルドなしで rmw を切り替えられます。

### 初期化(ノードとエンティティの作成)

| コード上の場所 | rclcpp | rcl | rmw | Fast DDS | Cyclone DDS |
| --- | --- | --- | --- | --- | --- |
| `rclcpp::init()`(各 `main`) | `rclcpp::init` → `Context::init` | `rcl_init` | `rmw_init` | 実装側の context を用意 | 同左 |
| `Node("p1_1_talker")`(各コンストラクタ) | `NodeBase` | `rcl_node_init` | `rmw_create_node` | context ごとに1つの `DomainParticipant` を作る(初回のみ) | `dds_create_participant`(context ごとに1つ) |
| `create_publisher(...)`(`talker.cpp`) | `rclcpp::create_publisher` → `Publisher` コンストラクタ | `rcl_publisher_init`(トピック名を `/p1_1/chatter` に展開) | `rmw_create_publisher` | `create_topic("rt/p1_1/chatter")` → `Publisher` → `create_datawriter` | `dds_create_topic` → `dds_create_writer` |
| `create_subscription(...)`(`listener.cpp`) | `Subscription` コンストラクタ | `rcl_subscription_init` | `rmw_create_subscription` | `create_datareader` | `dds_create_reader` |

Foxy 以降、DomainParticipant はノードごとではなく **context(プロセス)ごとに1つ**です。ノードの情報は `ros_discovery_info` トピックで別途配られます。

DataWriter と DataReader ができると、DDS の Discovery が動きます。SPDP で participant を見つけ、SEDP でトピック名、型名、QoS を照合してマッチングします。

### 送信経路(`talker.cpp` の `pub_->publish(msg)`)

```
Talker::on_timer()                               talker.cpp
 └ rclcpp::Publisher<String>::publish(const T&)  rclcpp/publisher.hpp
    │  (intra-process 無効なので inter-process 経路へ)
    └ Publisher::do_inter_process_publish(msg)
       └ rcl_publish(publisher_handle, &msg, nullptr)              rcl/src/rcl/publisher.c
          └ rmw_publish(rmw_handle, ros_message, allocation)        rmw/rmw.h(librmw_implementation が転送)
             ├ [Fast DDS] rmw_fastrtps_shared_cpp::__rmw_publish
             │    └ eprosima::fastdds::dds::DataWriter::write(&data)
             │       (シリアライズは rosidl_typesupport_fastrtps_cpp が生成した CDR コード)
             │       └ RTPS Writer → History に格納 → UDPv4 送信
             └ [Cyclone DDS] rmw_cyclonedds_cpp の rmw_publish
                  └ dds_write(writer, ros_message)
                     (独自の sertype が rosidl_typesupport_introspection_cpp で CDR に変換)
                     └ RTPS DATA サブメッセージ → UDP 送信
```

### 受信経路(`listener.cpp` の `on_message()` が呼ばれるまで)

```
rclcpp::spin(node)                                    listener.cpp の main
 └ SingleThreadedExecutor::spin()
    └ Executor::wait_for_work()
       └ rcl_wait(wait_set)                            rcl/src/rcl/wait.c
          └ rmw_wait(subscriptions, guards, ..., timeout)
             ├ [Fast DDS] DataReader のリスナー(on_data_available)が条件変数を起こす
             └ [Cyclone DDS] dds_waitset_wait で reader の data available を待つ
    └ Executor::execute_any_executable → execute_subscription
       └ SubscriptionBase::take_type_erased
          └ rcl_take(subscription, msg, &info)          rcl/src/rcl/subscription.c
             └ rmw_take_with_info(...)
                ├ [Fast DDS] DataReader::take_next_sample → CDR デシリアライズ
                └ [Cyclone DDS] dds_takecdr / dds_take → デシリアライズ
       └ Subscription::handle_message → AnySubscriptionCallback::dispatch
          └ Listener::on_message(msg)                   listener.cpp
```

listener が計測している遅延は、この図の最後の行で取った時刻と、送信経路の最初の行の時刻の差です。つまり **両方の経路をすべて含んだ値**です。

### 自分で確かめる方法

- `docker compose run --rm layers`:読み込まれた `.so` を rmw ごとに表示する。
- `ltrace`/`gdb`(イメージには未導入。`apt install gdb` で入る):`break rmw_publish` で止めて `bt` を取ると、上の送信経路のスタックがそのまま見える。
- `tcpdump -i any udp portrange 10150-10399 -w p1_1.pcap`(shell コンテナで実行し、Wireshark の RTPS ディセクタで開く):DATA / HEARTBEAT / ACKNACK を観察する。ドメイン11のポートは `7400 + 250×11 = 10150` から始まる。
