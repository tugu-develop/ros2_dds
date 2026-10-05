// P1-1 talker: 10Hz で std_msgs/String を送信する。
// data には "<seq>,<送信時刻[ns]>" を入れる(String 型のまま時刻を運ぶため)。
//
// 呼び出し経路(詳細は README.md):
//   rclcpp::Publisher::publish()  -> rcl_publish()  -> rmw_publish()
//   -> Fast DDS: DataWriter::write()  /  Cyclone DDS: dds_write()
#include <chrono>
#include <cstdint>
#include <memory>
#include <string>

#include "rclcpp/rclcpp.hpp"
#include "std_msgs/msg/string.hpp"

using namespace std::chrono_literals;

class Talker : public rclcpp::Node
{
public:
  Talker()
  : Node("p1_1_talker")
  {
    // create_publisher -> rcl_publisher_init -> rmw_create_publisher
    // ここで DDS の Topic と DataWriter が作られる。
    // DDS 上のトピック名は "rt/p1_1/chatter"("rt/" は ROS トピックの接頭辞)、
    // 型名は "std_msgs::msg::dds_::String_" になる(ros2 topic info -v で確認できる)。
    // QoS(10) = KEEP_LAST(10) / RELIABLE / VOLATILE。
    // RELIABLE なので RTPS の HEARTBEAT/ACKNACK による再送が有効になる。
    pub_ = create_publisher<std_msgs::msg::String>("p1_1/chatter", rclcpp::QoS(10));
    timer_ = create_wall_timer(100ms, [this]() {on_timer();});
  }

private:
  void on_timer()
  {
    std_msgs::msg::String msg;
    // listener と同じホスト(同じコンテナ)で動かす前提で system_clock を使う。
    // 別マシン間では時刻同期(PTP/chrony)の誤差がそのまま遅延に乗る点に注意。
    const int64_t send_ns = std::chrono::duration_cast<std::chrono::nanoseconds>(
      std::chrono::system_clock::now().time_since_epoch()).count();
    msg.data = std::to_string(seq_++) + "," + std::to_string(send_ns);

    // publish() は rclcpp -> rcl -> rmw と降りていき、rmw 層で
    // メッセージが CDR にシリアライズされて DDS の DataWriter に渡される。
    pub_->publish(msg);
  }

  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr pub_;
  rclcpp::TimerBase::SharedPtr timer_;
  uint64_t seq_ = 0;
};

int main(int argc, char ** argv)
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<Talker>());
  rclcpp::shutdown();
  return 0;
}
