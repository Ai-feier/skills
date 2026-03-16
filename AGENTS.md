# AGENTS.md

> 此文件是 AI 在本仓库工作的入口地图。保持精简（<100 行）。
> 原则：地图，不是百科全书。

## 文档治理

### 铁律
- **禁止自主创建**：AI 不得自行创建任何文档（README、CHANGELOG、设计文档等），必须先请求人工批准
- **禁止自主修改**：AI 修改文档前必须说明修改内容和原因，获得人工同意
- **简洁优先**：文档用最少的字表达必要信息，冗余即错误

### 渐进式文档策略
- 项目初期只维护此文件，不创建额外文档
- 需要新文档时，AI 提出请求 → 人工审批 → AI 执行
- 文档随项目复杂度增长而增长，不超前创建

## 仓库结构

```
/home/yzl/aidev/skills/
├── README.md, RECOMMENDED.md          # Main documentation
├── template/                          # Skill templates
├── skills/                            # Skill implementations
│   ├── lesson/                        # Example skill
│   ├── init-agents-md/                # Agent documentation skill
│   ├── lib/                           # TypeScript libraries
│   └── tests/                         # Test files
├── docs/                              # Documentation
│   └── plans/                         # Implementation plans
├── openspec/                          # OpenSpec configuration
└── .opencode/                         # OpenCode configuration
```

**Key Directories:**
- `skills/` - Main directory containing all agent skills
- `.opencode/` - OpenCode platform configuration and skills
- `template/` - Template for creating new skills
- `docs/plans/` - Project planning and design documents

## 编码规范

**Technology Stack:**
- TypeScript 5.0+ for skill system implementation
- Node.js 18+ runtime environment
- Jest testing framework with TypeScript support
- OpenCode, Claude Code, and Codex platform support

**Skill Structure:**
- Each skill is a directory containing `SKILL.md` (required)
- YAML frontmatter with `name` and `description` fields (required)
- Optional `config_requirements` for automatic configuration validation
- Skills use kebab-case naming convention

**Configuration Schema:**
```yaml
---
name: skill-name
description: "Use when [condition] - [what it does]"
config_requirements:
  - file: ".opencode/opencode.json"
    required_fields:
      instructions: ["MEMORY.md"]
  - file: "MEMORY.md"
    type: "template"
    content: |
      # MEMORY.md — 项目铁律
---
```

## 渐进式披露索引

当项目逐步成长时，按需添加以下文档并在此索引：
- `docs/ARCHITECTURE.md` — 系统架构和模块边界
- `docs/DESIGN.md` — 设计决策和核心信念
- `docs/QUALITY.md` — 质量标准和评分

> 空索引是正常的。文档应在真正需要时才创建，且必须经人工批准。
