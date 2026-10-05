#!/usr/bin/env python3
"""QoS検証用の最小 pub/sub ノード。

  qos_node.py pub --reliability best_effort
  qos_node.py sub --reliability reliable

QoS が非互換のとき、incompatible_qos イベントで原因ポリシーを表示する。
"""
import argparse
import time

import rclpy
from rclpy.node import Node
from rclpy.qos import DurabilityPolicy, HistoryPolicy, QoSProfile, ReliabilityPolicy
from std_msgs.msg import String

try:
    from rclpy.event_handler import PublisherEventCallbacks, SubscriptionEventCallbacks
except ImportError:  # Humble 以前
    from rclpy.qos_event import PublisherEventCallbacks, SubscriptionEventCallbacks

# rmw_qos_policy_kind_t のビット値(rmw の定義に基づく。未知の値はそのまま表示する)
POLICY_BITS = {
    1 << 1: 'DURABILITY',
    1 << 2: 'DEADLINE',
    1 << 3: 'LIVELINESS',
    1 << 4: 'RELIABILITY',
    1 << 5: 'HISTORY',
    1 << 6: 'LIFESPAN',
    1 << 7: 'DEPTH',
    1 << 8: 'LIVELINESS_LEASE_DURATION',
}


def policy_name(kind):
    return POLICY_BITS.get(int(kind), f'UNKNOWN({int(kind)})')


def build_qos(a):
    return QoSProfile(
        history=HistoryPolicy.KEEP_LAST,
        depth=a.depth,
        reliability=(ReliabilityPolicy.RELIABLE if a.reliability == 'reliable'
                     else ReliabilityPolicy.BEST_EFFORT),
        durability=(DurabilityPolicy.TRANSIENT_LOCAL if a.durability == 'transient_local'
                    else DurabilityPolicy.VOLATILE),
    )


class QosPub(Node):
    def __init__(self, a):
        super().__init__('qos_pub')
        self.n = 0
        callbacks = PublisherEventCallbacks(incompatible_qos=self.on_incompatible)
        self.pub = self.create_publisher(String, a.topic, build_qos(a), event_callbacks=callbacks)
        self.get_logger().info(
            f'PUB topic=/{a.topic} reliability={a.reliability} '
            f'durability={a.durability} depth={a.depth}')
        if a.count > 0:
            # 起動直後に count 件だけ送って待機する(TransientLocal の確認用)
            for _ in range(a.count):
                self.publish_one()
            self.get_logger().info(f'{a.count} 件を送信して待機します')
        else:
            self.create_timer(1.0 / a.rate, self.publish_one)

    def publish_one(self):
        self.pub.publish(String(data=f'msg {self.n}'))
        self.n += 1

    def on_incompatible(self, info):
        self.get_logger().warning(
            f'非互換QoS: 原因={policy_name(info.last_policy_kind)} 累計={info.total_count}')


class QosSub(Node):
    def __init__(self, a):
        super().__init__('qos_sub')
        self.received = 0
        callbacks = SubscriptionEventCallbacks(incompatible_qos=self.on_incompatible)
        self.create_subscription(String, a.topic, self.on_msg, build_qos(a),
                                 event_callbacks=callbacks)
        self.get_logger().info(
            f'SUB topic=/{a.topic} reliability={a.reliability} '
            f'durability={a.durability} depth={a.depth}')
        self.create_timer(5.0, self.report)

    def on_msg(self, msg):
        self.received += 1
        self.get_logger().info(f'受信: {msg.data}')

    def report(self):
        self.get_logger().info(f'[状況] 累計受信 {self.received} 件')

    def on_incompatible(self, info):
        self.get_logger().warning(
            f'非互換QoS: 原因={policy_name(info.last_policy_kind)} 累計={info.total_count}')


def main():
    p = argparse.ArgumentParser()
    p.add_argument('mode', choices=['pub', 'sub'])
    p.add_argument('--topic', default='chatter_qos')
    p.add_argument('--reliability', choices=['reliable', 'best_effort'], default='reliable')
    p.add_argument('--durability', choices=['volatile', 'transient_local'], default='volatile')
    p.add_argument('--depth', type=int, default=10)
    p.add_argument('--rate', type=float, default=2.0, help='pub の送信周期 [Hz]')
    p.add_argument('--count', type=int, default=0, help='pub: 0=周期送信、N>0=起動時にN件だけ送信')
    p.add_argument('--delay', type=float, default=0.0, help='sub: 起動を遅らせる秒数')
    a = p.parse_args()

    rclpy.init()
    if a.delay > 0:
        print(f'{a.delay} 秒待ってから購読を開始します', flush=True)
        time.sleep(a.delay)
    node = QosPub(a) if a.mode == 'pub' else QosSub(a)
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        if rclpy.ok():
            rclpy.shutdown()


if __name__ == '__main__':
    main()
