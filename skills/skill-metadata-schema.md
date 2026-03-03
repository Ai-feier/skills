# Skill Metadata Schema

## Configuration Requirements

Skills can declare configuration requirements in their SKILL.md frontmatter:

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

      ## 开发规范

      ## 调试经验

      ## 工具配置

      ## 代码风格

      ---
```

## Field Definitions

- `file`: Path to configuration file (relative to project root)
- `required_fields`: JSON fields that must be present
- `type`: File type (`template`, `json`, `yaml`)
- `content`: Template content for file creation
