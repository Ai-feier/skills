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
