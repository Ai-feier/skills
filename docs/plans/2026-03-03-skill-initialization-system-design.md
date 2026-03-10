# Skill Initialization System Design

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a standardized skill initialization system that automatically handles configuration requirements for all skills, preventing initialization failures like the `lesson` skill's missing `instructions` configuration.

**Architecture:** Configuration metadata in skill frontmatter + validation/generation system + automatic initialization on skill use.

**Tech Stack:** TypeScript, OpenCode skill system, JSON/YAML parsing

---

## Problem Statement

The `lesson` skill requires specific configuration in `.opencode/opencode.json` with an `instructions` array, but this configuration is not being properly inherited or set up when skills are initialized. Other agents initialize correctly, but the `lesson` skill fails due to missing configuration.

### Root Cause Analysis

1. **`lesson` skill requires**: `.opencode/opencode.json` with `"instructions": ["MEMORY.md"]`
2. **Current state**: Global opencode config exists at `~/.config/opencode/opencode.json` but lacks the `instructions` field
3. **Issue**: Skills expect project-level configuration but don't have a standardized way to ensure it's present

---

## Task 1: Extend SKILL.md Frontmatter Schema

**Files:**
- Create: `skills/skill-metadata-schema.md`
- Modify: `skills/template/SKILL.md`

**Step 1: Create skill metadata schema document**

```markdown
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
```

**Step 2: Update template SKILL.md**

```yaml
---
name: your-skill-name
description: "具体描述 skill 做什么、什么时候触发。宁可多触发，不可漏触发。"
config_requirements:
  # Add configuration requirements here
  # - file: ".opencode/opencode.json"
  #   required_fields:
  #     instructions: ["MEMORY.md"]
```

**Step 3: Verify schema is valid**

Run: `cat skills/skill-metadata-schema.md`

---

## Task 2: Implement Configuration Validation

**Files:**
- Create: `skills/lib/config-validator.ts`
- Create: `skills/lib/config-types.ts`

**Step 1: Create configuration types**

```typescript
// config-types.ts
export interface ConfigRequirement {
  file: string;
  required_fields?: Record<string, any>;
  type?: "template" | "json" | "yaml";
  content?: string;
}

export interface SkillConfig {
  name: string;
  config_requirements?: ConfigRequirement[];
}

export interface ValidationResult {
  valid: boolean;
  missing: string[];
  errors: string[];
}
```

**Step 2: Implement validation logic**

```typescript
// config-validator.ts
import * as fs from 'fs';
import * as path from 'path';
import { ConfigRequirement, ValidationResult } from './config-types';

export class ConfigValidator {
  async validateSkillConfig(
    skillName: string,
    requirements: ConfigRequirement[],
    projectRoot: string
  ): Promise<ValidationResult> {
    const result: ValidationResult = {
      valid: true,
      missing: [],
      errors: []
    };

    for (const req of requirements) {
      const filePath = path.join(projectRoot, req.file);
      
      if (!fs.existsSync(filePath)) {
        result.valid = false;
        result.missing.push(req.file);
        continue;
      }

      if (req.required_fields) {
        const content = fs.readFileSync(filePath, 'utf8');
        const config = JSON.parse(content);
        
        for (const [key, value] of Object.entries(req.required_fields)) {
          if (!(key in config) || JSON.stringify(config[key]) !== JSON.stringify(value)) {
            result.valid = false;
            result.errors.push(`Field '${key}' in ${req.file} does not match required value`);
          }
        }
      }
    }

    return result;
  }
}
```

**Step 3: Test validation**

Run: `npm test -- --testPathPattern=config-validator`

---

## Task 3: Implement Configuration Generation

**Files:**
- Modify: `skills/lib/config-validator.ts` (add generation methods)

**Step 1: Add generation methods to ConfigValidator**

```typescript
// Add to config-validator.ts
export class ConfigValidator {
  // ... existing validation methods ...

  async generateMissingConfig(
    requirements: ConfigRequirement[],
    projectRoot: string
  ): Promise<void> {
    for (const req of requirements) {
      const filePath = path.join(projectRoot, req.file);
      
      if (!fs.existsSync(filePath)) {
        // Create file based on type
        if (req.type === "template" && req.content) {
          fs.mkdirSync(path.dirname(filePath), { recursive: true });
          fs.writeFileSync(filePath, req.content);
        } else if (req.type === "json") {
          fs.mkdirSync(path.dirname(filePath), { recursive: true });
          fs.writeFileSync(filePath, JSON.stringify(req.required_fields || {}, null, 2));
        }
      } else if (req.required_fields) {
        // Update existing file
        const content = fs.readFileSync(filePath, 'utf8');
        const config = JSON.parse(content);
        
        for (const [key, value] of Object.entries(req.required_fields)) {
          if (!(key in config)) {
            config[key] = value;
          }
        }
        
        fs.writeFileSync(filePath, JSON.stringify(config, null, 2));
      }
    }
  }
}
```

**Step 2: Test generation**

Run: `npm test -- --testPathPattern=config-validator`

---

## Task 4: Integrate with Skill Discovery

**Files:**
- Modify: `skills/lib/skills-core.ts` (add initialization hook)

**Step 1: Add initialization check to skill loading**

```typescript
// In skills-core.ts, add to skill loading logic
export async function loadSkill(skillPath: string, projectRoot: string): Promise<Skill> {
  const skill = await parseSkill(skillPath);
  
  // Check configuration requirements
  if (skill.config_requirements) {
    const validator = new ConfigValidator();
    const result = await validator.validateSkillConfig(
      skill.name,
      skill.config_requirements,
      projectRoot
    );
    
    if (!result.valid) {
      // Generate missing configuration
      await validator.generateMissingConfig(
        skill.config_requirements,
        projectRoot
      );
      
      // Re-validate
      const revalidated = await validator.validateSkillConfig(
        skill.name,
        skill.config_requirements,
        projectRoot
      );
      
      if (!revalidated.valid) {
        throw new Error(`Failed to initialize skill ${skill.name}: ${revalidated.errors.join(', ')}`);
      }
    }
  }
  
  return skill;
}
```

**Step 2: Test integration**

Run: `npm test -- --testPathPattern=skills-core`

---

## Task 5: Update Existing Skills

**Files:**
- Modify: `skills/skills/lesson/SKILL.md`

**Step 1: Add config_requirements to lesson skill**

```yaml
---
name: lesson
description: "Use when user mentions '/lesson', '记录经验', '铁律', or wants to capture lessons learned..."
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

**Step 2: Verify lesson skill loads correctly**

Run: `npm test -- --testPathPattern=lesson-skill`

---

## Task 6: Documentation and Testing

**Files:**
- Create: `skills/docs/skill-initialization-guide.md`
- Create: `skills/tests/config-validator.test.ts`

**Step 1: Create user guide**

```markdown
# Skill Initialization Guide

## Automatic Configuration

Skills can now declare configuration requirements in their SKILL.md frontmatter. When a skill is loaded, the system will:

1. Check if required configuration files exist
2. Validate required fields are present
3. Generate missing files or update existing ones
4. Re-validate and load the skill

## Example: lesson Skill

The lesson skill now automatically:
- Creates `.opencode/opencode.json` with `instructions: ["MEMORY.md"]`
- Creates `MEMORY.md` with template content
- Validates configuration before loading

## Adding Configuration to Your Skill

Add `config_requirements` to your SKILL.md frontmatter:

```yaml
config_requirements:
  - file: ".opencode/opencode.json"
    required_fields:
      your_field: "value"
```
```

**Step 2: Create comprehensive tests**

```typescript
// config-validator.test.ts
describe('ConfigValidator', () => {
  test('validates missing configuration files', async () => {
    // Test implementation
  });
  
  test('generates missing configuration files', async () => {
    // Test implementation
  });
  
  test('updates existing configuration files', async () => {
    // Test implementation
  });
});
```

**Step 3: Run full test suite**

Run: `npm test`

---

## Success Criteria

- [ ] Configuration validation works correctly
- [ ] Missing files are generated automatically
- [ ] Existing skills remain compatible
- [ ] Clear error messages when configuration fails
- [ ] Documentation is complete and accurate
