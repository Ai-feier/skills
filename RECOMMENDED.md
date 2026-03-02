# 推荐 Skills

个人使用过并推荐的 Agent Skills，按用途分类。

> ⭐ = 强烈推荐，日常高频使用

---

## 开发流程 (Oh My OpenCode Superpowers)

来源: [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) 插件内置

| Skill | 用途 | 推荐度 |
|-------|------|--------|
| `using-superpowers` | 启动时加载，确保所有 skill 被正确发现和使用 | ⭐ |
| `brainstorming` | 实现前先头脑风暴，避免盲目编码 | ⭐ |
| `writing-plans` | 将需求转化为可执行的实施计划 | ⭐ |
| `executing-plans` | 按计划分步执行，带检查点 | ⭐ |
| `systematic-debugging` | 系统化调试，杜绝乱猜式修 bug | ⭐ |
| `test-driven-development` | TDD 流程：先写测试再写实现 | |
| `verification-before-completion` | 完成前强制验证，防止"自以为好了" | ⭐ |
| `subagent-driven-development` | 多 Agent 并行开发独立任务 | |
| `dispatching-parallel-agents` | 编排并行 Agent 执行 | |
| `using-git-worktrees` | Git worktree 隔离开发 | |
| `writing-skills` | 创建和维护 skill 本身 | |
| `requesting-code-review` | 完成后请求代码审查 | |
| `receiving-code-review` | 接收并处理代码审查反馈 | |
| `finishing-a-development-branch` | 分支完成后的集成决策 | |

## Skill 开发

| Skill | 来源 | 用途 | 推荐度 |
|-------|------|------|--------|
| `skill-creator` | [anthropics/skills](https://github.com/anthropics/skills) | 创建、测试、优化 skill 的完整工作流 | ⭐ |
| `find-skills` | 内置 | 搜索和发现可安装的 skill | |

## 项目特定

| Skill | 来源 | 用途 |
|-------|------|------|
| `docker-image-migration` | 自建 | Docker 镜像从 GitLab 迁移到私有仓库 |
| `gitlab-docker-migrator` | 自建 (项目级) | GitLab Helm Charts 镜像迁移专用 |

## 经验积累

| Skill | 来源 | 用途 | 推荐度 |
|-------|------|------|--------|
| `lesson` | 本仓库 | 自动捕获踩坑经验，写入 MEMORY.md 铁律 | ⭐ |

## 官方文档/设计类 (Anthropic)

来源: [anthropics/skills](https://github.com/anthropics/skills)

| Skill | 用途 |
|-------|------|
| `frontend-design` | 前端 UI/UX 设计与实现 |
| `mcp-builder` | MCP Server 快速搭建 |
| `webapp-testing` | Web 应用自动化测试 |
| `canvas-design` | Canvas 画布设计 |
| `docx` / `pdf` / `pptx` / `xlsx` | 文档创建与编辑 |

---

## 安装方式

### 从 Anthropic 官方安装 (Claude Code)

```bash
/plugin marketplace add anthropics/skills
/plugin install example-skills@anthropic-agent-skills
```

### 手动安装

```bash
# 克隆官方仓库
git clone https://github.com/anthropics/skills /tmp/anthropic-skills

# 挑选需要的 skill
cp -r /tmp/anthropic-skills/skills/frontend-design ~/.claude/skills/frontend-design
```

### Oh My OpenCode Superpowers

随 `oh-my-opencode` 插件自动安装，无需手动配置。
