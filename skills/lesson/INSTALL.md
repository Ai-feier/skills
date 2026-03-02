# 安装

## 1. 配置权限

在 `opencode.json` 中添加 skill 权限：

```json
{
  "permission": {
    "skill": "allow"
  }
}
```

## 2. 链接 Skill

### OpenCode
```bash
mkdir -p .opencode/skills
ln -s ../skills/lesson .opencode/skills/lesson
```

### Claude Code
```bash
mkdir -p .claude/skills
ln -s ../skills/lesson .claude/skills/lesson
```

### Codex
```bash
mkdir -p .agents/skills
ln -s ../skills/lesson .agents/skills/lesson
```

## 3. 创建 MEMORY.md（如果没有）

Skill 会把经验写入项目根目录的 `MEMORY.md`：

```bash
cat > MEMORY.md << 'EOF'
# MEMORY.md — 项目铁律

---

## 开发规范

## 调试经验

## 工具配置

## 代码风格

---
EOF
```

## 使用

```
/lesson 或 记录经验
```
