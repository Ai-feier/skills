# Agent Skills

个人 Agent Skills 仓库 — 用于 [Claude Code](https://docs.anthropic.com/en/docs/build-with-claude/computer-use)、[OpenCode](https://opencode.ai) 和 [Codex](https://codexrc.com) 的可复用技能集合。

Skills 是包含指令、脚本和资源的文件夹，Agent 按需动态加载以提升特定任务的执行质量。

## 目录结构

```
├── skills/           # 所有 skill 存放于此
│   ├── lesson/       # 铁律捕获：自动识别踩坑点并写入 MEMORY.md
│   └── .../          # 更多 skill
├── template/         # 新建 skill 的模板
├── docs/             # 详细文档
│   ├── opencode-install.md
│   ├── claude-code-install.md
│   └── codex-install.md
├── MEMORY.md         # 项目铁律（可选）
├── RECOMMENDED.md    # 推荐的第三方 skill 列表
└── README.md         # 本文件
```

## Skill 目录

| Skill | 描述 | 触发方式 | 依赖 |
|-------|------|----------|------|
| [lesson](skills/lesson/) | 将踩坑经验和关键教训提炼为铁律，写入项目 `MEMORY.md` | `/lesson`、`记录经验`、Agent 自动检测 | 需要项目根目录有 `MEMORY.md` |

> **注意**：部分 skill 需要项目满足特定条件才能正常工作（如 lesson 需要 MEMORY.md）。详见各 skill 文档。

## 安装使用

本仓库支持三种平台的 skill 安装方式。请选择适合你的平台进行安装：

### 快速开始

```bash
# 克隆仓库
git clone https://github.com/Ai-feier/skills.git
cd skills

# 查看可用 skills
ls skills/
```

### OpenCode 安装

将 skill 目录拷贝（或 symlink）到 OpenCode 的 skill 发现路径之一：

```bash
# 全局安装（所有项目可用）
cp -r skills/lesson ~/.config/opencode/skills/lesson

# 或通过 symlink（推荐，方便更新）
ln -s $(pwd)/skills/lesson ~/.config/opencode/skills/lesson

# 项目级安装（仅当前项目可用）
mkdir -p .opencode/skills
ln -s $(pwd)/skills/lesson .opencode/skills/lesson
```

**OpenCode skill 发现路径优先级：**
1. 项目级: `.opencode/skills/*/SKILL.md`
2. 全局级: `~/.config/opencode/skills/*/SKILL.md`
3. Claude 兼容: `~/.claude/skills/*/SKILL.md`

### Claude Code 安装

Claude Code 自动发现 skills，只需创建包含 `SKILL.md` 的目录即可：

```bash
# 全局安装（所有项目可用）
mkdir -p ~/.claude/skills/lesson
ln -s $(pwd)/skills/lesson/SKILL.md ~/.claude/skills/lesson/SKILL.md

# 项目级安装（仅当前项目可用）
mkdir -p .claude/skills/lesson
ln -s $(pwd)/skills/lesson/SKILL.md .claude/skills/lesson/SKILL.md
```

**Claude Code skill 发现路径：**
- 项目级: `.claude/skills/<skill-name>/SKILL.md`
- 用户级: `~/.claude/skills/<skill-name>/SKILL.md`
- 企业级: 通过 managed settings 配置

**特点：**
- 支持嵌套目录发现（monorepo 友好）
- 支持 `.claude/skills/` 内目录的动态加载
- 支持 `disable-model-invocation` 控制自动触发

### Codex 安装

Codex 使用 `.agents/skills` 目录作为 skill 发现路径：

```bash
# 全局安装
mkdir -p ~/.agents/skills
ln -s $(pwd)/skills/lesson ~/.agents/skills/lesson

# 项目级安装
mkdir -p .agents/skills
ln -s $(pwd)/skills/lesson .agents/skills/lesson
```

**Codex skill 发现路径：**
- 项目级: `.agents/skills/`
- 用户级: `~/.agents/skills/`
- 系统级: `/etc/codex/skills/`

**Codex 内置命令：**
```
$skill-installer install <skill-name>  # 从内置库安装
$skill-creator  # 创建新 skill
```

### 使用 npx skills 命令安装

如果你安装了 `skills` CLI 工具，可以使用以下命令：

```bash
# 全局安装 skills CLI
npm install -g @skills/cli

# 查看可用 skills
npx skills list

# 安装指定 skill 到当前平台
npx skills install lesson

# 安装到指定平台
npx skills install lesson --platform opencode
npx skills install lesson --platform claude-code
npx skills install lesson --platform codex
```

## 使用 npx skills CLI

`npx skills` 是一个方便的 CLI 工具，用于管理和安装 skills：

| 命令 | 说明 |
|------|------|
| `npx skills list` | 列出所有可用的 skills |
| `npx skills install <name>` | 安装指定 skill |
| `npx skills uninstall <name>` | 卸载指定 skill |
| `npx skills search <keyword>` | 搜索 skills |
| `npx skills init` | 初始化项目所需的 skill 环境 |

**前置条件：**
- Node.js 18+
- npm 或 yarn

## 创建新 Skill

1. 复制模板：`cp -r template skills/your-skill-name`
2. 编辑 `skills/your-skill-name/SKILL.md`
3. 填写 YAML frontmatter（`name` + `description`）
4. 编写指令内容

**关键原则：**
- 每个 skill 一个目录，必须包含 `SKILL.md`
- `description` 要写得具体且 "pushy"，覆盖所有触发场景
- YAML frontmatter 的 `name` 和 `description` 是必填字段

```yaml
---
name: your-skill-name
description: "具体描述 skill 做什么、什么时候触发。宁可多触发，不可漏触发。"
---
```

详见 [template/SKILL.md](template/SKILL.md)。

## 参考

- [Anthropic 官方 Skills 仓库](https://github.com/anthropics/skills)
- [Agent Skills 规范](https://agentskills.io)
- [Oh My OpenCode](https://github.com/code-yeongyu/oh-my-opencode) — OpenCode 增强插件

## License

MIT © [Ai-feier](https://github.com/Ai-feier)
