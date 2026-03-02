## ADDED Requirements

### Requirement: OpenCode 平台安装指南
文档 SHALL 包含 OpenCode 平台的 skill 安装步骤，包括：
- 全局安装方式（复制到 ~/.config/opencode/skills/）
- 项目级安装方式（复制到 .opencode/skills/）
- 使用 symlink 的替代方式

#### Scenario: 全局安装 OpenCode skill
- **WHEN** 用户执行全局安装命令
- **THEN** skill 被安装到 ~/.config/opencode/skills/ 目录，可在所有项目中使用

#### Scenario: 项目级安装 OpenCode skill
- **WHEN** 用户在项目目录执行项目级安装命令
- **THEN** skill 被安装到 .opencode/skills/ 目录，仅当前项目可用

### Requirement: Claude Code 平台安装指南
文档 SHALL 包含 Claude Code 平台的 skill 安装步骤：
- 全局安装方式（复制到 ~/.claude/skills/）
- 目录结构和文件要求说明

#### Scenario: 全局安装 Claude Code skill
- **WHEN** 用户执行 Claude Code 全局安装命令
- **THEN** skill 被安装到 ~/.claude/skills/ 目录

### Requirement: Codex 平台安装指南
文档 SHALL 包含 Codex 平台的 skill 安装步骤和注意事项

#### Scenario: 安装 Codex skill
- **WHEN** 用户需要在 Codex 中使用 skill
- **THEN** 文档提供正确的安装路径和方式

### Requirement: 安装命令示例完整
文档 SHALL 提供可直接复制执行的命令行示例

#### Scenario: 用户跟随示例安装
- **WHEN** 用户复制文档中的命令执行
- **THEN** skill 成功安装且可正常使用
