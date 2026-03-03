import { ConfigValidator } from '../../lib/config-validator';
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
