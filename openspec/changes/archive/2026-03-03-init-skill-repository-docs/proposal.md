## Why

个人开发者需要一个统一的 skill 集成仓库，用于管理和分发自己开发的各类 AI 助手 skill。同时需要提供清晰的安装说明，让用户能够通过 `npx skills` 命令快速安装所需的 skill，覆盖 OpenCode、Codex 和 Claude Code 三个平台。

## What Changes

- 创建 skill 集成仓库的基础项目结构
- 编写 OpenCode、Codex、Claude Code 三个平台的 skill 安装指南
- 提供 `npx skills` 命令的使用说明和示例
- 整理并规范化个人开发的 skill 集合

## Capabilities

### New Capabilities

- `skill-installation-guide`: 提供跨平台的 skill 安装指南文档，包括 OpenCode、Codex、Claude Code 的安装方式和命令
- `skill-repository-structure`: 定义 skill 仓库的目录结构和组织方式
- `npx-skills-cli`: 说明如何使用 npx skills 命令行工具管理和安装 skill

### Modified Capabilities

(无 - 新项目)

## Impact

- 新增文档文件：安装指南、使用说明
- 仓库结构：skills/ 目录用于存放各类 skill
- 用户可以通过 README 快速了解如何安装和使用 skill
