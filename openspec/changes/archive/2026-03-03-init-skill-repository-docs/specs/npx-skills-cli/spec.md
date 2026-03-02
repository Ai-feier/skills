## ADDED Requirements

### Requirement: npx skills 命令基础说明
文档 SHALL 包含 `npx skills` 命令的基本用法说明

#### Scenario: 用户首次使用 npx skills
- **WHEN** 用户执行 `npx skills --help`
- **THEN** 显示帮助信息，包含可用命令列表

### Requirement: skill 安装命令说明
文档 SHALL 说明如何通过 npx skills 安装仓库中的 skill

#### Scenario: 使用 npx 安装 skill
- **WHEN** 用户执行 `npx skills install <skill-name>`
- **THEN** skill 被安装到对应平台的默认路径

### Requirement: skill 列表命令说明
文档 SHALL 说明如何列出可用的 skill

#### Scenario: 查看可用 skills
- **WHEN** 用户执行 `npx skills list`
- **THEN** 显示所有可安装的 skill 及其描述

### Requirement: npx 命令前置条件说明
文档 SHALL 说明使用 npx skills 的前置条件（Node.js 环境等）

#### Scenario: 环境检查
- **WHEN** 用户尝试使用 npx skills 命令
- **THEN** 系统检查 Node.js 是否已安装，如未安装则提示安装
