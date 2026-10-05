# dds-lab:ROS 2 DDS 学習用の検証環境(Phase 1)

ROS 2 Jazzy のコンテナを使い、Phase 1 の演習(rmw切り替え、ドメイン分離、QoS不一致、TransientLocal、層の確認)を再現します。

## 準備

```bash
docker compose build
```

コンテナは `dds-net`(bridge)に接続され、DDSのDiscoveryはこのネットワーク内のマルチキャストで行われます。
Fast DDS の共有メモリはコンテナ間で使えないため、`FASTDDS_BUILTIN_TRANSPORTS=UDPv4` で無効にしています。

## シナリオ

| シナリオ | 起動コマンド | 期待される結果 |
| --- | --- | --- |
| rmw切り替え | `docker compose --profile basic up` | `listener-fastrtps` と `listener-cyclone` の両方が `I heard: [Hello World: N]` を表示する(別ベンダー間の通信) |
| ドメイン分離 | `docker compose --profile domain up` | `listener-fastrtps`(ドメイン0)は受信し、`listener-domain1` は何も受信しない |
| QoS不一致 | `docker compose --profile qos up` | Pub=best_effort × Sub=reliable なので、両ノードに「非互換QoS: 原因=RELIABILITY」が出て、受信は0件のまま |
| QoS互換 | `PUB_RELIABILITY=reliable docker compose --profile qos up` | 接続され、`受信: msg N` が表示される |
| TransientLocal | `docker compose --profile transient up` | `late-sub` が5秒遅れて参加しても、過去の5件を受信する |
| Volatile(対照) | `SUB_DURABILITY=volatile docker compose --profile transient up` | `late-sub` は何も受信しない |
| Depthの影響 | `PUB_DEPTH=2 docker compose --profile transient up` | `late-sub` が受け取るのは直近2件だけになる |
| 層の確認 | `docker compose run --rm layers` | rmw ごとに、`librclcpp` `librcl` `librmw` は共通で、`libfastrtps` と `libddsc` のどちらかが現れる |
| 対話シェル | `docker compose run --rm shell` | `ros2 topic info -v` や `ros2 doctor --report` を試せる。tcpdump用に NET_ADMIN / NET_RAW を付与済み |

終了は `Ctrl+C` のあと `docker compose --profile <名前> down` を実行します。

## QoS検証ノードの環境変数

| 変数 | 既定値 | 意味 |
| --- | --- | --- |
| `RMW` | `rmw_fastrtps_cpp` | qos / transient シナリオで使うrmw(`rmw_cyclonedds_cpp` に変えて比較できる) |
| `PUB_RELIABILITY` / `SUB_RELIABILITY` | `best_effort` / `reliable` | qos シナリオの Reliability |
| `PUB_DURABILITY` / `SUB_DURABILITY` | `volatile` / `volatile`(transientでは `transient_local`) | Durability |
| `PUB_DEPTH` | `10` | transient シナリオの Publisher の Depth |

例:Cyclone DDS で同じ不一致を再現する

```bash
RMW=rmw_cyclonedds_cpp docker compose --profile qos up
```

## 実践編(P1-x)との対応

- P1-1(rmw切り替え):basic シナリオと layers
- P1-2(ドメインID):domain シナリオと shell 内の `ros2 topic info -v`
- P1-3(QoS不一致):qos シナリオ(`scripts/qos_node.py` が incompatible_qos イベントを登録済み)
- P1-4(QoS総当たり):環境変数を変えてシナリオを繰り返す。自動化は Claude Code に任せる想定

## 注意

- Linux の Docker Engine を想定しています。Docker Desktop(Mac / Windows)ではマルチキャストの挙動が異なる場合があります。
- 作成時点では Docker の実行環境がなく、構文チェック(YAML、Python、シェル)までしか行っていません。初回の `docker compose build` と各シナリオの結果を確認してください。
- `scripts/` は読み取り専用でマウントされるため、編集はホスト側で行えば再ビルドなしで反映されます。
