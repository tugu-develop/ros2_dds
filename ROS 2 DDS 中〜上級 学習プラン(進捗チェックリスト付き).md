# ROS 2 DDS 中〜上級 学習プラン(進捗チェックリスト付き)

Sep 30, 2026 · @kito

## 使い方と全体スケジュール

約36週(9ヶ月)で、ROS 2のDDS層を「設定して使える」から「仕様レベルで説明・チューニング・解析できる」まで引き上げます。各項目のチェックボックスを完了時にチェックし、詰まった箇所にはコメントでメモを残してください。

1. Phase 1 基礎:第1〜8週
2. Phase 2 中級:第9〜20週
3. Phase 3 上級:第21〜36週
4. ネットワークレイヤー並行トラック:第1〜36週、各Phaseと同時に進める

**前提環境**:Ubuntu 24.04 + ROS 2 Jazzy(LTS)を推奨します。PC 2台(または1台+Raspberry Pi)を同一LANに置けると、Discoveryやマルチキャストの演習が本物の条件で試せます。Wireshark、Docker、`iproute2`(`ip`、`tc`)も用意してください。

**実践編の使い方**:各週の「演習」は、実践編のClaude Codeプロンプト番号(P1-1など)に対応しています。プロンプトはそのままClaude Codeに貼り付けられる形にしてあります。生成されたコードは必ず自分で読み、動かし、結果を記録してから次に進んでください。

**達成の目安**

- 中級到達(Phase 2修了):QoS不一致やDiscovery不全を、ログとパケットキャプチャから原因特定できる
- 上級到達(Phase 3修了):RTPSメッセージの流れを説明でき、レイテンシのボトルネックを計測データに基づいて改善できる

## Phase 1 基礎(第1〜8週)

ゴールは、ROS 2のレイヤー構造とDDSの基本エンティティ、QoSの互換性ルールを自分の言葉で説明できることです。

**第1〜2週:ROS 2のアーキテクチャ**

- [ ] rclcpp/rclpy → rcl → rmw → DDS実装 の層構造を図に描いて説明できる
- [ ] design.ros2.org「ROS on DDS」を読了
- [ ] `RMW_IMPLEMENTATION` を切り替えて、Fast DDSとCyclone DDSの両方でtalker/listenerを動かす
- [ ] 演習 P1-1:最小のpub/subノードとrmw切り替えスクリプトを作る

**第3〜4週:DDSの基本エンティティ**

- [ ] DomainParticipant、Publisher、Subscriber、DataWriter、DataReader、Topic、Typeの関係を説明できる
- [ ] ROS 2のノード、トピックとDDSエンティティの対応(Foxy以降は原則1コンテキスト1 Participant)を理解する
- [ ] `ROS_DOMAIN_ID` を変えると通信が分離されることを確認する
- [ ] 演習 P1-2:ドメインIDとエンティティ構成を可視化するスクリプトを作る

**第5〜6週:QoSポリシー**

- [ ] Reliability、Durability、History/Depth、Deadline、Liveliness、Lifespanの意味を説明できる
- [ ] Request vs Offered の互換性ルール(例:Reliable要求 × BestEffort提供は不可)を表にまとめる
- [ ] センサー用のプリセット(`SensorDataQoS`)とデフォルトQoSの違いを把握する
- [ ] 演習 P1-3:QoS不一致を意図的に起こし、イベントコールバックで検出する

**第7〜8週:Phase 1 のまとめ**

- [ ] TransientLocal で後から参加したSubscriberが過去メッセージを受け取ることを確認する
- [ ] `ros2 topic info -v`、`ros2 doctor` の出力を読める
- [ ] 演習 P1-4:QoS組み合わせの自動テストマトリクスを作る
- [ ] Phase 1 で学んだことを1ページにまとめ、このドキュメントにリンクする

## Phase 2 中級(第9〜20週)

ゴールは、Discoveryの仕組みを理解し、ベンダー設定・共有メモリ・計測ツールを使って実システムの通信問題を解決できることです。

**第9〜11週:Discovery**

- [ ] SPDP(Participant発見)とSEDP(Endpoint発見)の流れを説明できる
- [ ] ノード数に対してDiscoveryトラフィックがどう増えるかを理解する
- [ ] Fast DDS Discovery Server を立てて、マルチキャストなしで通信させる
- [ ] `ROS_AUTOMATIC_DISCOVERY_RANGE` と `ROS_STATIC_PEERS`(Iron以降)を試す
- [ ] 演習 P2-1:Discovery Server構成をDocker Composeで再現する

**第12〜14週:ベンダー設定XML**

- [ ] Fast DDSのXMLプロファイル(transport、participant、data writer/reader)を読み書きできる
- [ ] Cyclone DDSの設定(`CYCLONEDDS_URI`)でインターフェース指定とピア指定ができる
- [ ] 大容量メッセージ向けにソケットバッファとフラグメントサイズを調整する
- [ ] 演習 P2-2:両ベンダーの設定を生成・切り替えるツールを作る

**第15〜17週:共有メモリとゼロコピー**

- [ ] Fast DDSの共有メモリトランスポートとData Sharingの違いを説明できる
- [ ] Cyclone DDS + iceoryx、またはFast DDSでloaned messageを使うゼロコピー通信を動かす
- [ ] 同一ホスト内のUDPとSHMでレイテンシを比較する
- [ ] 演習 P2-3:メッセージサイズ別のレイテンシ・スループット計測ベンチを作る

**第18〜20週:計測と可視化**

- [ ] Wiresharkの`rtps`フィルタでDATA、HEARTBEAT、ACKNACKを見分けられる
- [ ] ros2\_tracing(LTTng)でコールバックの実行時間を取得する
- [ ] CARETでエンドツーエンドのパスレイテンシを計測する
- [ ] 演習 P2-4:pcapからRTPSの統計を出す解析スクリプトを作る

## Phase 3 上級(第21〜36週)

ゴールは、RTPS仕様・リアルタイム性・セキュリティを踏まえて、性能要件を満たす通信設計を自分で決められることです。

**第21〜24週:DDSI-RTPS仕様**

- [ ] DDSI-RTPS 2.5 仕様の第8章(振る舞いモジュール)と第9章(PSM:UDP/IP)を読了
- [ ] Reliable通信でのHEARTBEAT → ACKNACK → 再送 の流れを、実パケットで追跡できる
- [ ] GAP、DATA\_FRAG、INFO\_TS サブメッセージの役割を説明できる
- [ ] 演習 P3-1:パケットロス注入下でのReliable/BestEffort比較実験を自動化する

**第25〜28週:Executorとレイテンシ解析**

- [ ] SingleThreaded / MultiThreaded / EventsExecutor の違いを説明できる
- [ ] Callback Group(MutuallyExclusive / Reentrant)でのスケジューリングの違いを実測する
- [ ] Casini et al.(ECRTS 2019)の応答時間分析モデルを自分の構成に当てはめる
- [ ] 演習 P3-2:処理チェーンのレイテンシをExecutor別に比較する

**第29〜31週:リアルタイム化**

- [ ] PREEMPT\_RTカーネルを導入し、`cyclictest` でジッタを測る
- [ ] スレッド優先度(SCHED\_FIFO)、CPUアフィニティ、`mlockall` を設定する
- [ ] DDSの内部スレッド(受信スレッドなど)の優先度を設定XMLで調整する
- [ ] 演習 P3-3:リアルタイム設定付き制御ループノードを作る

**第32〜34週:セキュリティ**

- [ ] DDS Security の3プラグイン(Authentication、Access Control、Cryptographic)を説明できる
- [ ] SROS2でキーストアを作り、暗号化通信を有効にする
- [ ] セキュリティ有効時のレイテンシとDiscovery時間の増加を計測する
- [ ] 演習 P3-4:SROS2のセットアップと性能比較を自動化する

**第35〜36週:代替ミドルウェアと総仕上げ**

- [ ] rmw\_zenoh の設計(ルーター経由、マルチキャスト非依存)をDDSと比較できる
- [ ] 同じ構成をrmw\_zenohで動かし、Discovery時間と帯域を比較する
- [ ] 演習 P3-5:rmw別の総合ベンチマークレポートを作る
- [ ] 学習成果をブログ記事または社内発表資料にまとめる

## ネットワークレイヤー並行トラック(第1〜36週)

DDSの不具合の多くはネットワーク層に原因があるため、各Phaseと並行して週2〜3時間をこのトラックに充てます。

**N1 L2/L3基礎(第1〜6週、Phase 1と並行)**

- [ ] Ethernetフレーム、MTU(通常1500バイト)、IPフラグメンテーションを説明できる
- [ ] ARP、VLAN、サブネットの基本を理解する
- [ ] 点群や画像など64KB超のメッセージがUDPでどう分割されるかを理解する
- [ ] 演習 N-1:network namespaceで仮想ネットワークを作り、MTUを変えて実験する

**N2 UDPとマルチキャスト(第7〜12週)**

- [ ] ユニキャスト、マルチキャスト、ブロードキャストの違いを説明できる
- [ ] IGMP、TTL、マルチキャストアドレス(DDSの既定は239.255.0.1)を理解する
- [ ] IGMP snoopingとWi-Fiでマルチキャストが不安定になる理由を説明できる
- [ ] 演習 N-2:マルチキャスト送受信テストツールを作り、Wi-Fiと有線で比較する

**N3 RTPSのポート設計(第13〜16週)**

- [ ] 既定ポートの計算式を暗記する:PB=7400、DG=250、PG=2 として、Discoveryマルチキャスト=PB+DG×domainId、ユーザーマルチキャスト=+1、Discoveryユニキャスト=+10+PG×participantId、ユーザーユニキャスト=+11+PG×participantId
- [ ] ファイアウォール(ufw/nftables)でDDS通信を許可するルールを書ける
- [ ] 演習 N-3:ドメインIDとParticipant数から必要ポートとファイアウォール設定を出力するツールを作る

**N4 Linuxカーネルのネットワーク設定(第17〜22週)**

- [ ] `net.core.rmem_max`、`net.core.wmem_max`、`net.ipv4.ipfrag_*` の意味を説明できる
- [ ] `ss -u -a -m`、`ip -s link`、`ethtool -S`、`netstat -su` でドロップを確認できる
- [ ] `tc netem` で遅延・ロス・帯域制限を注入できる
- [ ] 演習 N-4:UDP受信ドロップを監視するスクリプトを作る

**N5 仮想化と越境(第23〜28週)**

- [ ] Dockerのbridge / host ネットワークでDDSがどう振る舞うかを確認する
- [ ] VPN(WireGuardなど)越しにマルチキャストなしで通信させる
- [ ] 演習 N-5:Docker bridge越しにROS 2を通すための設定を作る

**N6 時刻同期とリアルタイム通信(第29〜36週)**

- [ ] chrony(NTP)とPTP(IEEE 1588、`linuxptp`)の精度の違いを理解する
- [ ] 複数ホスト間のレイテンシ計測で時刻同期が必要な理由を説明できる
- [ ] TSN(IEEE 802.1Qbvなど)とDSCPマーキングの概要を理解する
- [ ] 演習 N-6:PTPで同期した2ホスト間のワンウェイレイテンシ計測を行う

## 実践編:Claude Code プロンプト集

各プロンプトは、ワークスペース直下で Claude Code に貼り付けて使います。最初に下の共通前提を `CLAUDE.md` として保存しておくと、全演習で同じ環境・方針が守られます。

### 共通前提(CLAUDE.md)

```text
# プロジェクト前提
- 環境: Ubuntu 24.04, ROS 2 Jazzy, colcon ワークスペース ~/dds_ws
- 言語: C++17(rclcpp)を基本、解析スクリプトは Python 3
- 対象rmw: rmw_fastrtps_cpp と rmw_cyclonedds_cpp(両方で動くこと)
- 各演習は src/<演習ID>/ にパッケージとして作る
- 必ず README.md に「目的・実行手順・期待される結果・観察ポイント」を書く
- 計測結果は results/<演習ID>/ に CSV で保存する
- 学習目的なので、DDS/RTPSの仕組みに関わる箇所にはコメントで解説を入れる
- 作業前に計画を示し、確認してから実装する
```

### Phase 1

**P1-1 最小pub/subとrmw切り替え**

```text
src/p1_1_basic_pubsub/ に rclcpp の talker/listener パッケージを作ってください。
- talker は 10Hz で std_msgs/String を送信し、送信時刻をメッセージに含める
- listener は受信時に遅延(ms)をログ出力する
- scripts/run_all_rmw.sh を作り、RMW_IMPLEMENTATION を fastrtps と cyclonedds で切り替えて
  それぞれ30秒動かし、遅延の平均・最大を results/p1_1/ に CSV で保存する
- README に rclcpp → rcl → rmw → DDS の呼び出し経路を、コード上のどこに対応するか含めて説明する
```

**P1-2 ドメインIDとエンティティの可視化**

```text
src/p1_2_entity_inspector/ に Python スクリプトを作ってください。
- 指定した ROS_DOMAIN_ID 上のノード、トピック、Publisher/Subscriber 数と各エンドポイントのQoSを
  rclpy の graph API(get_publishers_info_by_topic など)で取得し、表形式で出力する
- 異なるドメインIDで2つのtalkerを起動し、互いに見えないことを確認するデモ launch ファイルを付ける
- README に DDSエンティティ(DomainParticipant/DataWriter/DataReader)と ROS 2 の概念の対応表を書く
```

**P1-3 QoS不一致の検出**

```text
src/p1_3_qos_mismatch/ に rclcpp パッケージを作ってください。
- パラメータで Reliability / Durability / Deadline / Liveliness を指定できる Publisher と Subscriber
- QoS event コールバック(incompatible QoS、deadline missed、liveliness changed)をすべて登録し、
  発生時にどのポリシーが原因かをログ出力する
- 「Reliable要求 × BestEffort提供」など代表的な不一致5パターンを再現する launch ファイル
- README に Request vs Offered の互換性ルール表を書く
```

**P1-4 QoS組み合わせのテストマトリクス**

```text
src/p1_4_qos_matrix/ に、QoS組み合わせを総当たりで検証するテストを作ってください。
- Reliability(2) × Durability(2) × History/Depth(KeepLast1, KeepLast10, KeepAll) を
  Publisher側・Subscriber側の全組み合わせで試す
- 各組み合わせで「接続可否」「100件送信時の受信数」「後から参加したSubscriberの受信数」を記録
- 結果を results/p1_4/matrix.csv と、見やすいMarkdown表に出力する
- fastrtps と cyclonedds の両方で実行し、差分があれば README で考察する
```

### Phase 2

**P2-1 Discovery Server構成**

```text
src/p2_1_discovery_server/ に Docker Compose 構成を作ってください。
- コンテナ: discovery server 1台、talker 3台、listener 3台(ROS 2 Jazzy公式イメージ)
- 構成A: 通常のマルチキャストDiscovery、構成B: Fast DDS Discovery Server(ROS_DISCOVERY_SERVER)
- 両構成で Discovery 完了までの時間と、起動後60秒のDiscoveryパケット数を tcpdump で計測する
- 計測を自動化する scripts/compare.sh と、結果の CSV 出力
- README に SPDP/SEDP の流れと、Discovery Server でトラフィックが減る理由を図解(Mermaid)する
```

**P2-2 ベンダー設定ジェネレーター**

```text
src/p2_2_dds_config_gen/ に Python CLI を作ってください。
- YAML の共通設定(使用NIC、ピアIPリスト、マルチキャスト有無、共有メモリ有無、ソケットバッファサイズ)
  から、Fast DDS XML プロファイルと Cyclone DDS XML を生成する
- 生成した設定を適用して talker/listener を起動する env ファイルも出力する
- 各設定項目が DDS のどの概念に対応するかをコメントで出力ファイル内に書く
- 生成物を xmllint でスキーマ検証するテストを付ける
```

**P2-3 メッセージサイズ別ベンチマーク**

```text
src/p2_3_size_bench/ にレイテンシ・スループット計測ベンチを作ってください。
- メッセージサイズ: 64B, 1KB, 64KB, 1MB, 4MB(uint8 配列)
- 通信方式: 同一ホストUDP、共有メモリ、loaned message によるゼロコピー(対応rmwのみ)
- ping-pong 方式でRTTを1000回計測し、p50/p99/max と、ロス数を CSV に保存
- 結果を matplotlib でグラフ化するスクリプト
- README に「どのサイズから差が開くか」とその理由(フラグメンテーション、コピー回数)を考察する欄を用意
```

**P2-4 pcapからRTPS統計**

```text
src/p2_4_rtps_analyzer/ に Python スクリプトを作ってください。
- tshark(pyshark)で pcap を読み、RTPS サブメッセージ種別(DATA, DATA_FRAG, HEARTBEAT,
  ACKNACK, GAP, INFO_TS)ごとの件数とバイト数を集計する
- GUID prefix ごとに Participant を識別し、トピック名(SEDPから抽出)と対応づける
- 再送(同一シーケンス番号のDATAの重複)を検出して件数を出す
- テスト用に、P2-3 実行中にキャプチャした pcap を使う手順を README に書く
```

### Phase 3

**P3-1 パケットロス注入実験**

```text
src/p3_1_loss_experiment/ に実験自動化を作ってください。
- 2つの network namespace を veth で接続し、片方に talker、もう片方に listener を置く
- tc netem でロス率 0%, 1%, 5%, 10%, 20% と遅延 0ms, 20ms を組み合わせる
- Reliable / BestEffort それぞれで、受信率・レイテンシp99・HEARTBEAT/ACKNACK数(P2-4の解析器を再利用)を計測
- sudo が必要な箇所は明示し、実験後に namespace を必ず片付ける trap を入れる
- README に HEARTBEAT → ACKNACK → 再送 のシーケンス図(Mermaid)を書く
```

**P3-2 Executor別レイテンシ比較**

```text
src/p3_2_executor_chain/ に処理チェーンの評価系を作ってください。
- sensor(100Hz) → filter → fusion → planner の4ノードチェーン。各ノードに疑似処理時間(パラメータ)を設定可能
- SingleThreadedExecutor, MultiThreadedExecutor, EventsExecutor と、
  Callback Group(MutuallyExclusive / Reentrant)の組み合わせで実行
- ros2_tracing でトレースを取り、エンドツーエンドレイテンシを算出する解析スクリプト
- CARET でも同じチェーンを計測する手順を README に書く
```

**P3-3 リアルタイム制御ループ**

```text
src/p3_3_rt_control/ に 1kHz の制御ループノードを作ってください。
- 起動時に mlockall、SCHED_FIFO 優先度、CPUアフィニティを設定(パラメータで変更可)
- ループ内で動的メモリ確保をしない設計にし、その理由をコメントで説明
- 周期ジッタのヒストグラムを CSV 出力
- 通常カーネルと PREEMPT_RT で比較する手順、cyclictest での事前確認手順を README に書く
- Fast DDS / Cyclone DDS の受信スレッド優先度を設定するXML例も添える
```

**P3-4 SROS2セットアップと性能比較**

```text
src/p3_4_sros2/ に SROS2 の自動セットアップを作ってください。
- ros2 security コマンドでキーストア作成、talker/listener 用の鍵とパーミッションを生成するスクリプト
- アクセス制御ポリシー(policy.xml)で、特定トピックのみ publish 許可する例
- セキュリティ無効/有効(認証のみ、暗号化あり)で Discovery 時間とレイテンシを比較し CSV 保存
- 鍵を誤って使った場合に接続拒否されることを確認するテスト
- README に DDS Security の3プラグインの役割を書く
```

**P3-5 rmw総合ベンチマーク**

```text
src/p3_5_rmw_report/ に総合ベンチマークを作ってください。
- 対象: rmw_fastrtps_cpp, rmw_cyclonedds_cpp, rmw_zenoh_cpp
- 測定項目: ノード50個起動時のDiscovery完了時間、P2-3のサイズ別レイテンシ、アイドル時の帯域
- rmw_zenoh では zenohd ルーターの起動も自動化する
- 全結果をまとめた Markdown レポート(表とグラフ)を自動生成する
- 公平な比較のための注意点(ウォームアップ、CPU周波数固定、試行回数)を README に書く
```

### ネットワークトラック

**N-1 network namespaceとMTU実験**

```text
src/n1_netns_mtu/ にシェルスクリプト群を作ってください。
- 2つの network namespace を veth ペアで接続する setup.sh と、片付け用 teardown.sh
- MTU を 1500 / 9000 / 576 に変えながら、ping -s と iperf3(UDP)で大きなパケットを送る
- tcpdump でIPフラグメントの発生を確認し、件数を CSV に保存
- 同じ namespace 上で ROS 2 talker/listener を動かし、64KB超メッセージのフラグメントを観察する手順
- README に MTU・IPフラグメント・RTPSのDATA_FRAGの関係を説明する
```

**N-2 マルチキャスト送受信テスト**

```text
src/n2_mcast_tool/ に Python 製のマルチキャストテストツールを作ってください。
- sender: 指定グループ(既定 239.255.0.1)・ポート・TTL・NICで、連番付きパケットを一定レートで送信
- receiver: IGMP join して受信し、ロス率・順序入れ替え・ジッタを1秒ごとに表示
- 有線とWi-Fiで比較した結果を CSV に保存するオプション
- `ip maddr` と `tcpdump igmp` で join 状態を確認する手順を README に書く
```

**N-3 RTPSポート計算とファイアウォール設定**

```text
src/n3_rtps_ports/ に Python CLI を作ってください。
- 入力: domain_id、participant 数、使用NIC
- RTPS 仕様の既定値(PB=7400, DG=250, PG=2, d0=0, d1=10, d2=1, d3=11)で
  Discovery/ユーザー × マルチキャスト/ユニキャストの全ポートを計算して表示
- ufw と nftables のルールを出力
- 計算結果が実際の通信と一致するか、ss -ulpn の出力と照合するチェックモード
- 単体テスト(pytest)で計算式を検証する
```

**N-4 UDP受信ドロップ監視**

```text
src/n4_udp_drop_monitor/ に監視スクリプトを作ってください。
- /proc/net/snmp の Udp: RcvbufErrors, InErrors と、ss -u -a -m のソケットごとの drops を1秒ごとに取得
- ROS 2 プロセス(ros2 / rclcpp ノード)のソケットだけを抽出して表示
- 現在の net.core.rmem_max / rmem_default を表示し、推奨値の sysctl 設定ファイルを出力
- P2-3 のベンチを 4MB メッセージで動かしながらドロップが出る様子を観察する手順を README に書く
```

**N-5 Docker bridge越しのROS 2通信**

```text
src/n5_docker_bridge/ に Docker Compose 構成を作ってください。
- 構成A: network_mode: host、構成B: bridge ネットワーク、構成C: bridge + ユニキャストピア指定
- 各構成で、ホスト上のノードとコンテナ内ノードが通信できるかを自動判定するスクリプト
- 構成Cでは Fast DDS と Cyclone DDS の両方の設定ファイルを用意
- README に、bridge でマルチキャストDiscoveryが届かない理由と、共有メモリが誤検出される問題の対処を書く
```

**N-6 PTP同期とワンウェイレイテンシ**

```text
src/n6_ptp_latency/ に2ホスト間の計測系を作ってください。
- linuxptp(ptp4l, phc2sys)の設定ファイルと起動スクリプト。ハードウェアタイムスタンプ非対応NIC向けの設定も用意
- chrony のみの場合と PTP の場合で、時刻オフセットを pmc / chronyc で記録
- 送信時刻を埋め込んだ ROS 2 メッセージでワンウェイレイテンシを計測し、同期方式ごとに比較
- README に、時刻同期精度がレイテンシ計測の誤差にどう効くかを説明する
```

## 参考文献(読了チェックリスト)

書誌情報は記憶に基づくため、版や発行年は各出版社・論文誌のページで確認してください。括弧内は読むのに適した時期です。

**仕様・一次資料**

- [ ] OMG DDS 1.4(Phase 1)
- [ ] OMG DDSI-RTPS 2.5(Phase 3)
- [ ] OMG DDS Security 1.1(Phase 3)
- [ ] OMG DDS-XTypes 1.3(Phase 2〜3、型の互換性を扱う場合)
- [ ] design.ros2.org「ROS on DDS」(Phase 1)
- [ ] docs.ros.org:About Quality of Service Settings、Discovery Server、DDS tuning(Phase 1〜2)
- [ ] eProsima Fast DDS / Eclipse Cyclone DDS 公式ドキュメント(Phase 2)

**論文**

- [ ] Maruyama, Kato, Azumi, "Exploring the Performance of ROS2" (EMSOFT 2016)(Phase 1)
- [ ] Macenski et al., "Robot Operating System 2: Design, Architecture, and Uses in the Wild" (Science Robotics, 2022)(Phase 1)
- [ ] Kronauer et al., "Latency Analysis of ROS2 Multi-Node Systems" (MFI 2021)(Phase 2)
- [ ] Bédard et al., "ros2\_tracing: Multipurpose Low-Overhead Framework for Real-Time Tracing of ROS 2" (RA-L 2022)(Phase 2)
- [ ] Kuboichi et al., "CARET: Chain-Aware ROS 2 Evaluation Tool"(2022)(Phase 2)
- [ ] Casini et al., "Response-Time Analysis of ROS 2 Processing Chains Under Reservation-Based Scheduling" (ECRTS 2019)(Phase 3)
- [ ] Blass et al., "A ROS 2 Response-Time Analysis Exploiting Starvation Freedom and Execution-Time Variance" (RTSS 2021)(Phase 3)
- [ ] Kim et al., "Security and Performance Considerations in ROS 2: A Balancing Act"(2018)(Phase 3)
- [ ] Mayoral-Vilches et al., "SROS2: Usable Cyber Security Tools for ROS 2" (IROS 2022)(Phase 3)

**日本語書籍:ROS 2**

- [ ] 近藤豊『ROS2ではじめよう 次世代ロボットプログラミング』技術評論社(Phase 1)
- [ ] 出村公成ほか『ROS 2とPythonで作って学ぶAIロボット入門』講談社(Phase 1、補助)

**日本語書籍:ネットワーク・Linux**

- [ ] 戸根勤『ネットワークはなぜつながるのか』日経BP(N1)
- [ ] 井上直也ほか『マスタリングTCP/IP 入門編』オーム社(N1〜N2)
- [ ] もよよ『Linuxで動かしながら学ぶTCP/IPネットワーク入門』(N1、演習N-1と相性が良い)
- [ ] みやたひろし『パケットキャプチャの教科書』SBクリエイティブ(N2〜N3、P2-4と並行)
- [ ] 武内覚『\[試して理解\]Linuxのしくみ』技術評論社(Phase 3 リアルタイム化の前)
- [ ] W.R.スティーヴンス『UNIXネットワークプログラミング』翻訳版(N2〜N4、必要な章のみ)

**コミュニティ・日本語情報源**

- [ ] ROS Japan UG の勉強会資料(随時)
- [ ] TIER IV の CARET ドキュメント(日本語あり、Phase 2)
- [ ] ROS Discourse の Middleware WG の議論(Phase 3、rmw\_zenoh などの最新動向)
