import { ConfigRequirement, SkillConfig, ValidationResult } from '../../lib/config-types';

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
