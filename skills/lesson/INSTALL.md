# 安装

## 1. 创建 MEMORY.md（如果没有）

```bash
cat > MEMORY.md << 'EOF'
# MEMORY.md — 项目铁律

本文件记录了项目开发过程中总结的重要经验和规则。

---

## 开发规范

## 调试经验

## 工具配置

## 代码风格

---
EOF
```

## 2. 链接 Skill

### OpenCode
```bash
mkdir -p .opencode/skills
ln -s skills/lesson .opencode/skills/lesson
```

### Claude Code
```bash
mkdir -p .claude/skills
ln -s skills/lesson .claude/skills/lesson
```

### Codex
```bash
mkdir -p .agents/skills
ln -s skills/lesson .agents/skills/lesson
```

## 使用

```
/lesson 或 记录经验
```
