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
