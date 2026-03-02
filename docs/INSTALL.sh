#!/bin/bash
#
# Lesson Skill Auto-Installer
# 用法: curl -sL https://raw.githubusercontent.com/Ai-feier/skills/main/docs/INSTALL.sh | bash
#

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Lesson Skill 安装器${NC}"
echo "======================"

# 检查是否在 git 仓库中
if [ ! -d ".git" ]; then
    echo -e "${RED}错误: 请在项目根目录运行此脚本${NC}"
    exit 1
fi

# 检查是否有 skills 目录
if [ ! -d "skills/lesson" ]; then
    echo -e "${RED}错误: 未找到 skills/lesson 目录${NC}"
    echo "请先克隆 skills 仓库: git clone https://github.com/Ai-feier/skills.git"
    exit 1
fi

# 检查是否有 MEMORY.md
if [ ! -f "MEMORY.md" ]; then
    echo -e "${YELLOW}未找到 MEMORY.md，正在创建...${NC}"
    
    cat > MEMORY.md << 'EOF'
# MEMORY.md — 项目铁律

本文件记录了项目开发过程中总结的重要经验和规则。

请使用 `/lesson`、`记录经验` 或 `铁律` 命令添加新规则。

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
    echo -e "${GREEN}✓ MEMORY.md 已创建${NC}"
else
    echo -e "${GREEN}✓ MEMORY.md 已存在${NC}"
fi

# 检测当前平台并安装 skill
PLATFORM="unknown"

# 检查 OpenCode
if [ -d ".opencode" ] || [ -f "opencode.json" ]; then
    PLATFORM="opencode"
    echo -e "${YELLOW}检测到 OpenCode${NC}"
    
    mkdir -p .opencode/skills
    if [ -L ".opencode/skills/lesson" ]; then
        echo -e "${GREEN}✓ lesson skill 已链接${NC}"
    else
        ln -sf ../skills/lesson .opencode/skills/lesson
        echo -e "${GREEN}✓ lesson skill 已安装 (OpenCode)${NC}"
    fi
fi

# 检查 Claude Code
if [ -d ".claude" ]; then
    PLATFORM="claude-code"
    echo -e "${YELLOW}检测到 Claude Code${NC}"
    
    mkdir -p .claude/skills
    if [ -L ".claude/skills/lesson" ]; then
        echo -e "${GREEN}✓ lesson skill 已链接${NC}"
    else
        ln -sf ../skills/lesson .claude/skills/lesson
        echo -e "${GREEN}✓ lesson skill 已安装 (Claude Code)${NC}"
    fi
fi

# 检查 Codex
if [ -d ".agents" ]; then
    PLATFORM="codex"
    echo -e "${YELLOW}检测到 Codex${NC}"
    
    mkdir -p .agents/skills
    if [ -L ".agents/skills/lesson" ]; then
        echo -e "${GREEN}✓ lesson skill 已链接${NC}"
    else
        ln -sf ../skills/lesson .agents/skills/lesson
        echo -e "${GREEN}✓ lesson skill 已安装 (Codex)${NC}"
    fi
fi

if [ "$PLATFORM" = "unknown" ]; then
    echo -e "${YELLOW}未检测到支持的平台，手动安装:${NC}"
    echo ""
    echo "OpenCode:"
    echo "  mkdir -p .opencode/skills"
    echo "  ln -s skills/lesson .opencode/skills/lesson"
    echo ""
    echo "Claude Code:"
    echo "  mkdir -p .claude/skills"
    echo "  ln -s skills/lesson .claude/skills/lesson"
    echo ""
    echo "Codex:"
    echo "  mkdir -p .agents/skills"
    echo "  ln -s skills/lesson .agents/skills/lesson"
fi

echo ""
echo -e "${GREEN}安装完成!${NC}"
echo "使用 /lesson 或 '记录经验' 来捕获铁律"
