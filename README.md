# 🧱 Nockchain 一键部署脚本

这是一个用于在 Linux / VPS 上一键部署 [Nockchain](https://github.com/0xmoei/nockchain) zkPoW 节点的自动化脚本（`deploy_nock.sh`）。适用于主网/测试网挖矿环境。

---

## 🚀 项目功能

- 自动安装依赖：Rust、Docker、build-essential 等
- 自动克隆、编译 Nockchain 节点代码
- 自动生成钱包密钥、配置挖矿公钥
- 自动构建 Leader 与 Follower 节点
- 自动设置 wallet 命令路径（终端重启后仍可用）

---

## 📦 使用方法

```bash
# 下载脚本
curl -o deploy_nock.sh https://raw.githubusercontent.com/gao1996916/Nock/main/deploy_nock.sh

# 赋予执行权限
chmod +x deploy_nock.sh

# 执行部署
./deploy_nock.sh
