---
name: minimal-sop-agent-creator
description: "Use when creating a minimal agent prompt for small models, when user wants to generate a lightweight agent with strict tool/skill limitations, or when asked to '创建 agent', '写一个 agent prompt', '生成 agent 配置', 'sop agent'"
---

# 最小化 SOP Agent 创建器

## 概述

为小模型创建极简 agent prompt 文件。核心原则：**小模型 = 少工具 + 少技能 + 明确步骤**。

小模型上下文窗口有限、指令遵循能力较弱。过多的工具和模糊的指令会导致 agent 行为不可预测。因此，每个生成的 agent 必须严格限制可用工具和技能数量。

## 适用场景

- 用户需要一个专门处理单一任务的轻量级 agent
- 用户明确要求使用小模型（Haiku、小型开源模型等）
- 用户希望 agent 只能访问特定的工具/技能，不能随意调用

## 核心约束（必须遵守）

| 维度 | 限制 |
|------|------|
| 工具数量 | 最多 5 个，推荐 3 个 |
| Prompt 长度 | 最多 200 行（含 frontmatter） |
| SOP 步骤 | 最多 8 步 |
| 输出格式 | OpenCode Agent Markdown（YAML frontmatter + Markdown body） |

**为什么这么严格？** 小模型在面对多个工具选择时容易：
- 选择错误的工具
- 遗漏关键步骤
- 在不相关的工具上浪费 token
- 产生幻觉行为

## 工作流程

### 第一步：需求访谈

向用户提问以下问题（可以合并为一次提问）：

```
1. 这个 agent 的核心任务是什么？（一句话描述）
2. 这个 agent 需要用到哪些工具？（从以下列表选择，最多 5 个）
3. 这个 agent 的模式是什么？
   - primary（主 Agent，用户直接交互）
   - subagent（子 Agent，被其他 Agent 调用或 @mention 调用）
4. 用什么模型？（如 Internal/internal-mimo-v2-flash）
5. agent 的输出应该是什么格式？
6. 有没有需要特别禁止的行为？
```

**可用工具列表**（让用户从中选择）：

| 工具 | 配置名 | 用途 |
|------|--------|------|
| 读取文件 | read | 读取文件内容 |
| 创建/覆盖文件 | write | 创建新文件或覆盖已有文件 |
| 编辑文件 | edit | 编辑已有文件 |
| 执行命令 | bash | 执行 shell 命令 |
| 获取网页 | webfetch | 获取网页内容 |

**注意事项：**
- 如果用户不确定选什么工具，根据任务类型推荐最精简的组合
- 对于"只读"任务（如代码审查），只给 Read + Grep
- 对于"生成"任务（如写代码），给 Read + Write + Edit
- Bash 只在确实需要执行命令时才加入

### 第二步：生成 Agent 文件

根据访谈结果，生成一个 **OpenCode Agent Markdown 格式** 的文件，保存到 `.opencode/agents/` 目录。

**文件名规则：** 文件名即 agent 名称，如 `git-commit.md` → agent 名为 `git-commit`

**文件结构模板：**

```markdown
---
description: "[一句话描述这个 agent 做什么、什么时候用]"
mode: subagent
model: [provider/model-id]
tools:
  read: true
  write: true/false
  edit: true/false
  bash: true/false
  webfetch: true/false
---

# [Agent 名称]

## 角色

[一句话描述 agent 是谁/做什么]

## 任务

[具体任务描述，不超过 3 句话]

## 工作流程

1. [第一步]
2. [第二步]
3. [第三步]
...

## 输出要求

[输出格式和质量要求]

## 禁止行为

- [禁止项1]
- [禁止项2]
```

**YAML frontmatter 必填字段：**

| 字段 | 说明 | 示例 |
|------|------|------|
| `description` | 触发描述，决定何时自动调用 | `"Use when user says 'commit'..."` |
| `mode` | `subagent`（子 Agent）或 `primary`（主 Agent） | `subagent` |
| `model` | 使用的模型（可选，默认用主 Agent 的模型） | `Internal/internal-mimo-v2-flash` |
| `tools` | 工具开关（可选，false = 禁用该工具） | `write: false` |

**可选字段：**

| 字段 | 说明 | 示例 |
|------|------|------|
| `temperature` | 温度参数，0-1 | `0.1` |
| `steps` | 最大迭代步数 | `10` |
| `hidden` | 隐藏 agent（不显示在 @ 菜单） | `true` |
| `permission` | 工具权限控制 | 见下方 |

### 第三步：呈现并迭代

将生成的 agent 文件展示给用户，同时附上质量自检结果：

```
| 检查项 | 结果 |
|--------|------|
| 工具数量 ≤ 5 | ✅/❌ N 个 |
| SOP 步骤 ≤ 8 | ✅/❌ N 步 |
| 每步可执行 | ✅/❌ |
| 工具权限明确 | ✅/❌ |
| 禁止行为具体 | ✅/❌ |
| 输出格式明确 | ✅/❌ |
| description 可触发 | ✅/❌ |
| 总行数 ≤ 200 | ✅/❌ N 行 |
| 约束可执行 | ✅/❌ |
| mode 已指定 | ✅/❌ |
| model 已指定 | ✅/❌ |```

询问用户是否需要调整：

- 太多步骤？精简合并
- 工具太多？删除非必需的
- 步骤不清晰？重写为更具体的指令
- 缺少约束？添加禁止行为

用户确认后，将文件保存到 `.opencode/agents/[agent-name].md`。

## 生成原则

### 1. SOP 必须是可执行的

每一步都应该是具体动作，不是抽象概念。

```
❌ 不好：分析代码质量
✅ 好：读取 src/ 目录下所有 .ts 文件，检查是否有 any 类型，列出文件名和行号
```

### 2. 工具用途要写死（但约束要可执行）

不要让小模型自己判断什么时候用什么工具。在"可用工具"部分明确写出每个工具的用途限制。

```
❌ 不好：- Read: 读取文件
✅ 好：- Read: 只用于读取 src/ 下的 .py 文件，跳过 node_modules/ 和 dist/
```

**重要：约束必须是可执行的。** 不要写 agent 无法在操作前判断的约束。

```
❌ 不好：不要读取非 .json 文件（agent 无法在读取前判断文件类型）
✅ 好：只读取用户明确指定路径的文件（路径约束，可执行）
✅ 好：搜索时排除 node_modules/ 和 dist/ 目录（目录约束，可执行）
```

好的约束类型：
- **路径约束**: 只搜索 `src/` 下的文件，排除 `node_modules/`
- **命令约束**: 只能执行 `git diff` 和 `git status`，禁止 `git commit`
- **工具约束**: 只用 Read 和 Grep，不用 Write/Edit/Bash
- **输出约束**: 只输出 Markdown，不输出命令执行过程

### 3. 每个 SOP 步骤要包含"怎么验证完成"

```
❌ 不好：
3. 生成测试文件

✅ 好：
3. 生成测试文件
   - 文件路径: tests/test_[模块名].py
   - 每个函数至少一个测试用例
   - 验证: 运行 pytest tests/test_[模块名].py 确保通过
```

### 4. 禁止行为要具体

```
❌ 不好：不要做危险的操作
✅ 好：不要使用 rm -rf 命令
✅ 好：不要修改 package.json 中的 dependencies
```

## 示例

### 示例 1：代码风格检查 Agent

**用户需求：** 检查 Python 代码是否符合 PEP 8，只读不改

**生成结果：** 保存到 `.opencode/agents/pep8-checker.md`

```markdown
---
description: "Use when checking Python code style, PEP 8 compliance, or when user asks to review Python formatting"
mode: subagent
model: Internal/internal-mimo-v2-flash
tools:
  read: true
  write: false
  edit: false
  bash: false
  webfetch: false
---

# PEP 8 代码检查器

## 角色

你是一个 Python 代码风格检查工具，只读取和报告问题，不修改任何文件。

## 任务

检查指定目录下的 Python 文件是否符合 PEP 8 规范，输出问题列表。

## 工作流程

1. 使用 Glob 找到目标目录下所有 .py 文件
2. 逐个使用 Read 读取文件内容
3. 检查以下规则：
   - 行长度是否超过 79 字符
   - 函数/类之间是否有两个空行
   - 导入是否按标准库、第三方库、本地模块分组
   - 是否使用了 tab 缩进（应该用 4 个空格）
4. 输出检查结果

## 输出要求

每个文件一个章节，格式：
### [文件路径]
- 第 X 行: [问题描述]

如果没有问题，写"✅ 无问题"。

## 禁止行为

- 不要使用 Write 或 Edit 工具
- 不要执行任何命令（不能用 Bash）
- 不要修改任何文件
- 不要跳过任何 .py 文件（必须全部检查）
- 不要对问题做出修复建议，只报告
```

### 示例 2：Git 提交信息生成 Agent

**用户需求：** 根据 git diff 生成符合 conventional commit 格式的提交信息

**生成结果：** 保存到 `.opencode/agents/commit-msg-gen.md`

```markdown
---
description: "Use when generating git commit messages, analyzing diffs for commit type, or when user asks to create conventional commit messages"
mode: subagent
model: Internal/internal-mimo-v2-flash
tools:
  read: false
  write: false
  edit: false
  bash: true
  webfetch: false
permission:
  bash:
    "*": deny
    "git diff": allow
    "git diff --staged": allow
    "git status": allow
---

# Commit Message 生成器

## 角色

你是一个 git 提交信息生成工具。读取代码变更，输出符合 conventional commit 格式的消息。

## 任务

根据提供的代码 diff，生成一条简洁准确的 commit message。

## 工作流程

1. 使用 Bash 执行 `git diff --staged` 获取暂存区变更
2. 分析变更内容：
   - 新增文件 → feat
   - 修改 bug → fix
   - 重构 → refactor
   - 文档 → docs
   - 测试 → test
   - 配置 → chore
3. 确定影响范围（模块/文件名）
4. 生成 commit message

## 输出格式

```
<type>(<scope>): <description>

[可选的正文]
```

示例：
- feat(auth): add JWT token refresh logic
- fix(api): handle null response in user endpoint
- refactor(utils): extract date formatting helper

## 禁止行为

- 不要执行 git commit 或 git push
- 不要执行除 git diff / git status 以外的任何命令
- 不要读取或修改文件
- 不要添加 emoji
```

## 质量检查清单

生成完成后，自查以下项目：

- [ ] 工具数量 ≤ 5
- [ ] SOP 步骤 ≤ 8
- [ ] 每步都是具体可执行的动作
- [ ] 工具权限在 frontmatter 中明确配置（true/false）
- [ ] 有具体的禁止行为列表
- [ ] 输出格式有明确要求
- [ ] 总行数 ≤ 200
- [ ] 没有模糊的指令（如"适当处理"、"根据情况"）
- [ ] 约束都是可执行的（路径/命令/工具约束，不是类型判断约束）
- [ ] YAML frontmatter 包含 description、mode、model
- [ ] description 字段能触发 agent 调用
- [ ] 文件保存为 `.opencode/agents/[name].md`

## 常见错误

| 错误 | 修正 |
|------|------|
| 给了 bash 但不限制命令 | 在 permission 中配置具体命令白名单 |
| 给了太多工具 | 问自己：去掉这个工具，agent 还能完成任务吗？能就去掉 |
| SOP 步骤太多 | 合并相关步骤，删除可选步骤 |
| 用了"根据情况判断" | 改为 if/else 明确分支 |
| 禁止行为太模糊 | 写出具体命令/操作名 |
| 约束不可执行 | "不要读取非 X 文件" → "只读取用户指定路径的文件" |
| 保存为 SKILL.md | 必须保存为 `.opencode/agents/xxx.md` |
| 缺少 YAML frontmatter | 必须包含 description + mode + model |
| description 太笼统 | 写具体触发词，如 "Use when user says 'commit'" |
