#!/usr/bin/env bash
set -euo pipefail

### ←—— 可自定义变量 ——→
WORKDIR="$HOME/nockchain"       # 安装目录
REPO_URL="https://github.com/zorp-corp/nockchain.git"
RPC_PORT=30333                  # JSON-RPC 端口
P2P_PORT=30334                  # P2P 端口
SCREEN_PREFIX="nock"            # screen 会话名前缀
### ←———————————————→

echo "🛠️ 开始部署 Nockchain 节点..."

# 1. 安装系统依赖
echo "1) 更新系统 & 安装依赖..."
sudo apt-get update -y
sudo apt-get install -y build-essential curl git jq screen docker.io

sudo systemctl enable --now docker

# 2. 安装 Rust
if ! command -v rustc &>/dev/null; then
  echo "2) 安装 Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
else
  echo "Rust 已安装，版本：$(rustc --version)"
fi

# 3. 克隆或更新仓库
echo "3) 获取源码到 $WORKDIR ..."
if [ -d "$WORKDIR/.git" ]; then
  cd "$WORKDIR" && git pull
else
  git clone "$REPO_URL" "$WORKDIR"
  cd "$WORKDIR"
fi

# 4. 编译 Choo & 节点驱动
echo "4) 编译 Choo 编译器..."
make install-choo

echo "5) 构建节点 & 驱动..."
make build-hoon-all
make build

# 5. 生成钱包密钥对
echo "6) 生成钱包密钥对..."
if [ ! -f "$WORKDIR/wallet.json" ]; then
  ./target/release/wallet keygen --out "$WORKDIR/wallet.json" --format json
  echo "钱包文件保存在：$WORKDIR/wallet.json"
else
  echo "检测到已存在 wallet.json，跳过生成。"
fi

# 6. 配置 Makefile
echo "7) 配置 Makefile..."
PUBKEY=$(jq -r '.pubkey' wallet.json)
sed -i -E "s|^MINING_PUBKEY ?= .*|MINING_PUBKEY = $PUBKEY|" Makefile
sed -i -E "s|^RPC_PORT ?= .*|RPC_PORT = $RPC_PORT|" Makefile
sed -i -E "s|^P2P_PORT ?= .*|P2P_PORT = $P2P_PORT|" Makefile

# 7. 设置 PATH 和默认目录到 shell 启动文件
echo "8) 写入环境变量配置到 bash/zsh..."
SHELL_FILE="$HOME/.bashrc"
if [[ "$SHELL" == */zsh ]]; then
  SHELL_FILE="$HOME/.zshrc"
fi

{
  echo ""
  echo "# [nockchain] 自动添加的钱包环境变量"
  echo "cd $WORKDIR"
  echo "export PATH=\"\$PATH:$WORKDIR/target/release\""
} >> "$SHELL_FILE"

echo "→ 已写入环境变量至 $SHELL_FILE"

# 8. 启动 Leader 和 Follower
echo "9) 启动节点进程（使用 screen）..."
screen -dmS "${SCREEN_PREFIX}_leader" make run-nockchain-leader
screen -dmS "${SCREEN_PREFIX}_follower" make run-nockchain-follower

echo "✅ 部署完成！"
echo "➡️ 使用 wallet 命令前请先执行："
echo "   cd $WORKDIR"
echo "   export PATH=\"\$PATH:$WORKDIR/target/release\""
echo "   （此操作已自动写入你的 $SHELL_FILE）"
echo ""
echo "📺 查看节点日志： screen -r ${SCREEN_PREFIX}_leader / ${SCREEN_PREFIX}_follower"
