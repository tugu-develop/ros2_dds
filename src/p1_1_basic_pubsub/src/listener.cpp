// P1-1 listener: 受信時に「受信時刻 - 送信時刻」を遅延[ms]としてログ出力する。
// パラメータ csv_path を指定すると、1メッセージ1行で CSV にも記録する。
//
// 呼び出し経路(詳細は README.md):
//   DDS が受信 -> rmw の待機(rmw_wait)が起きる -> Executor がサブスクリプションを選ぶ
//   -> rcl_take() -> rmw_take_with_info() -> DataReader::take() / dds_take()
//   -> rclcpp がこのクラスの on_message() を呼ぶ
#include <chrono>
#include <cstdint>
#include <fstream>
#include <memory>
#include <stdexcept>
#include <string>

#include "rclcpp/rclcpp.hpp"
#include "std_msgs/msg/string.hpp"

class Listener : public rclcpp::Node
{
public:
  Listener()
  : Node("p1_1_listener")
  {
    const auto csv_path = declare_parameter<std::string>("csv_path", "");
    if (!csv_path.empty()) {
      csv_.open(csv_path, std::ios::out | std::ios::trunc);
      if (!csv_) {
        throw std::runtime_error("cannot open csv_path: " + csv_path);
      }
      csv_ << "seq,send_ns,recv_ns,latency_ms\n";
    }

    // create_subscription -> rcl_subscription_init -> rmw_create_subscription
    // ここで DDS の DataReader が作られる。talker の DataWriter と
    // トピック名・型名・QoS が一致すると、Discovery(SEDP)でマッチングされる。
    sub_ = create_subscription<std_msgs::msg::String>(
      "p1_1/chatter", rclcpp::QoS(10),
      [this](const std_msgs::msg::String & msg) {on_message(msg);});
  }

private:
  void on_message(const std_msgs::msg::String & msg)
  {
    // 計測の誤差を減らすため、最初に受信時刻を取る。
    // この時点で DDS 受信 -> rmw_take -> デシリアライズ -> Executor のディスパッチ
    // まで済んでいるので、遅延には「DDS の転送」と「ROS 2 層のオーバーヘッド」の両方が含まれる。
    const int64_t recv_ns = std::chrono::duration_cast<std::chrono::nanoseconds>(
      std::chrono::system_clock::now().time_since_epoch()).count();

    const auto comma = msg.data.find(',');
    if (comma == std::string::npos) {
      RCLCPP_WARN(get_logger(), "unexpected payload: '%s'", msg.data.c_str());
      return;
    }
    const uint64_t seq = std::stoull(msg.data.substr(0, comma));
    const int64_t send_ns = std::stoll(msg.data.substr(comma + 1));
    const double latency_ms = static_cast<double>(recv_ns - send_ns) / 1e6;

    RCLCPP_INFO(get_logger(), "seq=%lu latency=%.3f ms", seq, latency_ms);

    if (csv_.is_open()) {
      csv_ << seq << ',' << send_ns << ',' << recv_ns << ',' << latency_ms << '\n';
      csv_.flush();  // 10Hz なので毎回 flush しても負荷は無視できる
    }
  }

  rclcpp::Subscription<std_msgs::msg::String>::SharedPtr sub_;
  std::ofstream csv_;
};

int main(int argc, char ** argv)
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<Listener>());
  rclcpp::shutdown();
  return 0;
}
