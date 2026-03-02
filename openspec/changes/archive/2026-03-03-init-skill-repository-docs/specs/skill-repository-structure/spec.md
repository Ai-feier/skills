## ADDED Requirements

### Requirement: 仓库根目录结构规范
仓库 SHALL 包含以下顶层目录和文件：
- skills/ 目录：存放所有可用的 skill
- template/ 目录：新建 skill 的模板
- README.md：项目主文档
- RECOMMENDED.md：推荐的第三方 skill 列表

#### Scenario: 用户查看仓库结构
- **WHEN** 用户克隆仓库后查看根目录
- **THEN** 看到清晰的目录结构，知道各目录用途

### Requirement: Skill 目录规范
每个 skill SHALL 是独立的目录，包含：
- SKILL.md：skill 的主文件（必需）
- README.md：skill 的说明文档（可选）
- 相关资源文件

#### Scenario: 用户进入 skill 目录
- **WHEN** 用户打开 skills/xxx/ 目录
- **THEN** 看到规范的目录结构和必需的文件

### Requirement: Skill 元数据格式
SKILL.md SHALL 包含 YAML frontmatter，包含：
- name：skill 名称
- description：skill 描述

#### Scenario: 解析 skill 元数据
- **WHEN** Agent 或工具解析 SKILL.md 文件
- **THEN** 能正确读取 name 和 description 字段

### Requirement: Skill 分类体系
仓库 SHALL 按照功能领域对 skill 进行分类组织

#### Scenario: 用户按分类查找 skill
- **WHEN** 用户需要特定功能的 skill
- **THEN** 可以通过目录结构快速定位相关 skill
