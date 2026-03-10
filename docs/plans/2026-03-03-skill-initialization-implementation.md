# Skill Initialization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement a standardized skill initialization system that automatically handles configuration requirements for all skills, preventing initialization failures like the `lesson` skill's missing `instructions` configuration.

**Architecture:** Configuration metadata in skill frontmatter + validation/generation system + automatic initialization on skill use.

**Tech Stack:** TypeScript, OpenCode skill system, JSON/YAML parsing

---

## Task 1: Create Configuration Types

**Files:**
- Create: `skills/lib/config-types.ts`

**Step 1: Write the failing test**

```typescript
// tests/lib/config-types.test.ts
import { ConfigRequirement, SkillConfig, ValidationResult } from '../lib/config-types';

describe('ConfigRequirement', () => {
  test('has required fields', () => {
    const req: ConfigRequirement = {
      file: '.opencode/opencode.json',
      required_fields: { instructions: ['MEMORY.md'] }
    };
    expect(req.file).toBe('.opencode/opencode.json');
    expect(req.required_fields).toEqual({ instructions: ['MEMORY.md'] });
  });
});
```

**Step 2: Run test to verify it fails**

Run: `npm test -- --testPathPattern=config-types`
Expected: FAIL with "Cannot find module '../lib/config-types'"

**Step 3: Write minimal implementation**

```typescript
// skills/lib/config-types.ts
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

**Step 4: Run test to verify it passes**

Run: `npm test -- --testPathPattern=config-types`
Expected: PASS

**Step 5: Commit**

```bash
git add skills/lib/config-types.ts tests/lib/config-types.test.ts
git commit -m "feat: add configuration types for skill initialization"
```

---

## Task 2: Implement Configuration Validator

**Files:**
- Create: `skills/lib/config-validator.ts`
- Create: `tests/lib/config-validator.test.ts`

**Step 1: Write the failing test**

```typescript
// tests/lib/config-validator.test.ts
import { ConfigValidator } from '../lib/config-validator';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

describe('ConfigValidator', () => {
  let tempDir: string;
  
  beforeEach(() => {
    tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'skill-test-'));
  });
  
  afterEach(() => {
    fs.rmSync(tempDir, { recursive: true, force: true });
  });
  
  test('validates missing configuration files', async () => {
    const validator = new ConfigValidator();
    const result = await validator.validateSkillConfig(
      'test-skill',
      [{ file: '.opencode/opencode.json', required_fields: { instructions: ['MEMORY.md'] } }],
      tempDir
    );
    
    expect(result.valid).toBe(false);
    expect(result.missing).toContain('.opencode/opencode.json');
  });
});
```

**Step 2: Run test to verify it fails**

Run: `npm test -- --testPathPattern=config-validator`
Expected: FAIL with "Cannot find module '../lib/config-validator'"

**Step 3: Write minimal implementation**

```typescript
// skills/lib/config-validator.ts
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

  async generateMissingConfig(
    requirements: ConfigRequirement[],
    projectRoot: string
  ): Promise<void> {
    for (const req of requirements) {
      const filePath = path.join(projectRoot, req.file);
      
      if (!fs.existsSync(filePath)) {
        if (req.type === "template" && req.content) {
          fs.mkdirSync(path.dirname(filePath), { recursive: true });
          fs.writeFileSync(filePath, req.content);
        } else if (req.type === "json") {
          fs.mkdirSync(path.dirname(filePath), { recursive: true });
          fs.writeFileSync(filePath, JSON.stringify(req.required_fields || {}, null, 2));
        }
      } else if (req.required_fields) {
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

**Step 4: Run test to verify it passes**

Run: `npm test -- --testPathPattern=config-validator`
Expected: PASS

**Step 5: Commit**

```bash
git add skills/lib/config-validator.ts tests/lib/config-validator.test.ts
git commit -m "feat: implement configuration validator for skill initialization"
```

---

## Task 3: Update Skill Metadata Schema

**Files:**
- Create: `skills/skill-metadata-schema.md`
- Modify: `skills/template/SKILL.md`

**Step 1: Write the failing test**

```bash
# Test that schema file exists
test -f skills/skill-metadata-schema.md || exit 1
```

Run: `test -f skills/skill-metadata-schema.md`
Expected: FAIL (file doesn't exist)

**Step 2: Write minimal implementation**

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

**Step 3: Run test to verify it passes**

Run: `test -f skills/skill-metadata-schema.md`
Expected: PASS

**Step 4: Update template SKILL.md**

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

**Step 5: Commit**

```bash
git add skills/skill-metadata-schema.md skills/template/SKILL.md
git commit -m "docs: add skill metadata schema for configuration requirements"
```

---

## Task 4: Integrate with Skill Discovery

**Files:**
- Modify: `skills/lib/skills-core.ts`

**Step 1: Write the failing test**

```typescript
// tests/lib/skills-core.test.ts
import { loadSkill } from '../lib/skills-core';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

describe('loadSkill', () => {
  let tempDir: string;
  
  beforeEach(() => {
    tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'skill-test-'));
  });
  
  afterEach(() => {
    fs.rmSync(tempDir, { recursive: true, force: true });
  });
  
  test('validates configuration requirements on load', async () => {
    // Create a skill with config requirements
    const skillDir = path.join(tempDir, 'test-skill');
    fs.mkdirSync(skillDir, { recursive: true });
    
    const skillContent = `---
name: test-skill
description: "Test skill"
config_requirements:
  - file: ".opencode/opencode.json"
    required_fields:
      instructions: ["MEMORY.md"]
---
# Test Skill
`;
    fs.writeFileSync(path.join(skillDir, 'SKILL.md'), skillContent);
    
    // This should fail because config doesn't exist
    await expect(loadSkill(skillDir, tempDir)).rejects.toThrow();
  });
});
```

**Step 2: Run test to verify it fails**

Run: `npm test -- --testPathPattern=skills-core`
Expected: FAIL (loadSkill doesn't validate config)

**Step 3: Write minimal implementation**

```typescript
// In skills-core.ts, add to skill loading logic
import { ConfigValidator } from './config-validator';

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

**Step 4: Run test to verify it passes**

Run: `npm test -- --testPathPattern=skills-core`
Expected: PASS

**Step 5: Commit**

```bash
git add skills/lib/skills-core.ts tests/lib/skills-core.test.ts
git commit -m "feat: integrate configuration validation with skill loading"
```

---

## Task 5: Update Existing Skills

**Files:**
- Modify: `skills/skills/lesson/SKILL.md`

**Step 1: Write the failing test**

```bash
# Test that lesson skill has config_requirements
grep -q "config_requirements:" skills/skills/lesson/SKILL.md || exit 1
```

Run: `grep -q "config_requirements:" skills/skills/lesson/SKILL.md`
Expected: FAIL (config_requirements not found)

**Step 2: Write minimal implementation**

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

**Step 3: Run test to verify it passes**

Run: `grep -q "config_requirements:" skills/skills/lesson/SKILL.md`
Expected: PASS

**Step 4: Commit**

```bash
git add skills/skills/lesson/SKILL.md
git commit -m "feat: add configuration requirements to lesson skill"
```

---

## Task 6: Documentation and Final Testing

**Files:**
- Create: `skills/docs/skill-initialization-guide.md`

**Step 1: Write the failing test**

```bash
# Test that guide exists
test -f skills/docs/skill-initialization-guide.md || exit 1
```

Run: `test -f skills/docs/skill-initialization-guide.md`
Expected: FAIL (file doesn't exist)

**Step 2: Write minimal implementation**

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

**Step 3: Run test to verify it passes**

Run: `test -f skills/docs/skill-initialization-guide.md`
Expected: PASS

**Step 4: Run full test suite**

Run: `npm test`
Expected: All tests pass

**Step 5: Commit**

```bash
git add skills/docs/skill-initialization-guide.md
git commit -m "docs: add skill initialization guide"
```

---

## Success Criteria

- [ ] Configuration validation works correctly
- [ ] Missing files are generated automatically
- [ ] Existing skills remain compatible
- [ ] Clear error messages when configuration fails
- [ ] Documentation is complete and accurate
