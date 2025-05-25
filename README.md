# CleanMyDeepin

> 🧹 专为 deepin 操作系统设计的系统垃圾清理工具

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Qt Version](https://img.shields.io/badge/Qt-6.x-green.svg)](https://qt.io/)
[![C++](https://img.shields.io/badge/C++-17-orange.svg)](https://isocpp.org/)

## 📖 项目简介

CleanMyDeepin 是一款简洁高效的系统清理工具，专门为 deepin 操作系统用户量身定制。通过直观的图形界面，帮助用户快速识别和清理系统中的垃圾文件，释放磁盘空间，提升系统性能。

## ✨ 主要特性

### 🎯 核心功能
- **智能扫描**: 自动识别系统临时文件、日志文件、缓存文件等垃圾内容
- **树形展示**: 清晰的层级结构展示扫描结果，支持展开/折叠查看
- **选择性清理**: 支持单个文件选择、全选/反选，用户完全控制清理内容
- **实时进度**: 扫描和清理过程实时显示进度和统计信息
- **安全保护**: 二次确认机制，避免误删重要文件

### 🔧 扫描范围
- `/tmp` - 系统临时文件
- `/var/tmp` - 系统临时目录
- `/var/log` - 系统日志文件
- `~/.thumbnails` - 缩略图缓存

### 💡 技术特色
- **现代架构**: 采用 QML + C++ 前后端分离设计
- **高性能**: 异步多线程扫描，延迟加载大型目录
- **高分屏支持**: 适配各种分辨率显示设备
- **国际化**: 支持多语言界面（源语言英文）
- **deepin 原生**: 遵循 deepin 设计语言和用户体验规范

## 🚀 快速开始

### 环境要求
- deepin 20.0+ 或其他基于 Debian 的 Linux 发行版
- Qt 6.x
- CMake 3.14+
- C++17 编译器

### 编译安装

```bash
# 克隆仓库
git clone https://github.com/deepin-community/cleanmydeepin.git
cd cleanmydeepin

# 创建构建目录
mkdir build && cd build

# 配置和编译
cmake ..
make -j$(nproc)

# 运行
./cleanmydeepin
```

### 依赖包安装（以 Debian/Ubuntu 为例）

```bash
sudo apt update
sudo apt install qt6-base-dev qt6-declarative-dev cmake build-essential
```

## 📊 开发状态

| 模块 | 状态 | 说明 |
|-----|------|------|
| 扫描功能 | ✅ 完成 | 支持多路径并发扫描 |
| 树形展示 | ✅ 完成 | 延迟加载、状态管理 |
| 选择管理 | ✅ 完成 | 递归选择、统计计算 |
| 清理功能 | 🚧 开发中 | 基础框架已完成 |
| 设置模块 | 🚧 开发中 | 配置管理器已实现 |
| 国际化 | 🚧 开发中 | 框架已搭建 |
| 单元测试 | ⏳ 计划中 | 待添加测试覆盖 |

## 🤝 贡献指南

我们欢迎各种形式的贡献！

### 代码贡献
1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

### 其他贡献方式
- 🐛 提交 Bug 报告
- 💡 建议新功能
- 📝 改进文档
- 🌍 协助翻译

### 开发规范
- 遵循项目的架构设计原则（详见 [DESIGN.md](docs/DESIGN.md)）
- C++ 代码注释使用中文，日志输出使用英文
- QML 代码遵循既定的组件设计模式
- 提交前运行代码格式化和基础测试

## 📄 许可证

本项目采用 [Apache License 2.0](LICENSE) 许可证。

## 🙏 致谢

- deepin 社区提供的设计指导和技术支持
- Qt 框架为跨平台开发提供的强大基础
- 所有为项目贡献代码和建议的开发者

## 📞 联系我们

- 问题反馈: [GitHub Issues](https://github.com/deepin-community/cleanmydeepin/issues)
- 功能建议: [GitHub Discussions](https://github.com/deepin-community/cleanmydeepin/discussions)

---

⭐ 如果这个项目对你有帮助，请给我们一个 Star！
