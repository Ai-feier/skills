# Lesson Skill 安装指南

本文件包含自动安装脚本和使用说明。

## 快速安装

### 自动安装（推荐）

```bash
# 如果项目没有 MEMORY.md，会自动创建并配置 lesson skill
curl -sL https://raw.githubusercontent.com/Ai-feier/skills/main/docs/INSTALL.sh | bash
```

### 手动安装

如果没有 MEMORY.md，先创建：

```bash
# 创建 MEMORY.md
cat > MEMORY.md << 'EOF'
# MEMORY.md — 项目铁律

本文件记录了项目开发过程中总结的重要经验和规则。

---

## 开发规范

- (铁律将记录于此)

## 调试经验

- (调试经验将记录于此)

## 工具配置

- (工具配置经验将记录于此)

## 代码风格

- (代码风格相关规则将记录于此)

---

> 本文件由 lesson skill 自动管理
EOF
```

然后配置 skill。

---

## 各平台配置

### OpenCode

OpenCode 需要将 skill 链接到项目本地配置：

```bash
# 项目级安装（推荐）
mkdir -p .opencode/skills
ln -s skills/lesson .opencode/skills/lesson
```

**注意**：OpenCode 会优先使用项目级配置 `.opencode/skills/*/SKILL.md`。

### Claude Code

Claude Code 自动发现 skills：

```bash
# 项目级
mkdir -p .claude/skills
ln -s ../skills/lesson .claude/skills/lesson

# 或全局
mkdir -p ~/.claude/skills
ln -s /path/to/skills/lesson ~/.claude/skills/lesson
```

### Codex

```bash
# 项目级
mkdir -p .agents/skills
ln -s ../skills/lesson .agents/skills/lesson

# 或全局
mkdir -p ~/.agents/skills
ln -s /path/to/skills/lesson ~/.agents/skills/lesson
```

---

## 验证安装

安装后，在项目中尝试：

```
记录经验：this is a test lesson
```

应该会自动写入 MEMORY.md。

---

## 卸载

删除对应的符号链接即可：

```bash
# OpenCode
rm .opencode/skills/lesson

# Claude Code
rm .claude/skills/lesson

# Codex
rm .agents/skills/lesson
```
