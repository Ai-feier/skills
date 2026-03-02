# Agent Skills

个人 Agent Skills 仓库 — 用于 [Claude Code](https://docs.anthropic.com/en/docs/build-with-claude/computer-use) 和 [OpenCode](https://opencode.ai) 的可复用技能集合。

Skills 是包含指令、脚本和资源的文件夹，Agent 按需动态加载以提升特定任务的执行质量。

## 目录结构

```
skills/           ← 所有 skill 存放于此
├── lesson/       ← 铁律捕获：自动识别踩坑点并写入 MEMORY.md
└── .../          ← 更多 skill
template/         ← 新建 skill 的模板
RECOMMENDED.md    ← 推荐的第三方 skill 列表
```

## Skill 目录

| Skill | 描述 | 触发方式 |
|-------|------|----------|
| [lesson](skills/lesson/) | 将踩坑经验和关键教训提炼为铁律，写入项目 `MEMORY.md` | `/lesson`、`记录经验`、Agent 自动检测 |

## 安装使用

### OpenCode

将 skill 目录拷贝（或 symlink）到 OpenCode 的 skill 发现路径之一：

```bash
# 全局安装（所有项目可用）
cp -r skills/lesson ~/.config/opencode/skills/lesson

# 或通过 symlink
ln -s $(pwd)/skills/lesson ~/.config/opencode/skills/lesson
```

OpenCode skill 发现路径：
- 项目级: `.opencode/skills/*/SKILL.md`
- 全局级: `~/.config/opencode/skills/*/SKILL.md`
- Claude 兼容: `~/.claude/skills/*/SKILL.md`

### Claude Code

```bash
# 全局安装
cp -r skills/lesson ~/.claude/skills/lesson
```

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
