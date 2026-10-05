# プロジェクト前提
- 環境: Ubuntu 24.04, ROS 2 Jazzy, colcon ワークスペース ~/dds_ws
- 言語: C++17(rclcpp)を基本、解析スクリプトは Python 3
- 対象rmw: rmw_fastrtps_cpp と rmw_cyclonedds_cpp(両方で動くこと)
- 各演習は src/<演習ID>/ にパッケージとして作る
- 必ず README.md に「目的・実行手順・期待される結果・観察ポイント」を書く
- 計測結果は results/<演習ID>/ に CSV で保存する
- 学習目的なので、DDS/RTPSの仕組みに関わる箇所にはコメントで解説を入れる
- 作業前に計画を示し、確認してから実装する