---
name: hf-model-download
description: |
  Download Hugging Face models with automatic failover and resume support. Use this skill whenever the user wants to download model files from Hugging Face, mentions HF/HuggingFace model repos, GGUF files, safetensors, or asks to pull/download models. Triggers on phrases like "download model from HF", "pull model", "get model from huggingface", "download GGUF", etc. The skill ensures reliable downloads by trying multiple sources and methods.
---

# HF Model Download

Reliably download model files from Hugging Face with automatic source switching, resume support, and format verification.

## When to Use

- User wants to download any model from Hugging Face
- User mentions a Hugging Face repo ID (e.g., `username/model-name`)
- User asks for GGUF, safetensors, bin, or other model files
- User has network issues accessing Hugging Face directly

## Download Strategy

The skill follows this priority order to ensure successful downloads:

1. **Official Hugging Face** (`huggingface.co`) - Try first
2. **China Mirror** (`hf-mirror.com`) - Fallback if official fails
3. **Alternative methods** - Try huggingface_hub CLI if curl fails

## Workflow

### Step 1: Parse Request

Extract from user input:
- **repo_id**: Hugging Face repo ID (e.g., `Tesslate/OmniCoder-9B-GGUF`)
- **filename**: Specific file to download (optional, will list files if not provided)
- **local_dir**: Destination directory (default: `./models/<repo_name>`)

### Step 2: Check File Availability

If no specific filename provided, list available files:

```bash
curl -s "https://huggingface.co/api/models/<repo_id>" | python3 -c "import sys,json; d=json.load(sys.stdin); print('\n'.join(sorted(d.get('siblings',[]), key=lambda x: x.get('rfilename',''))[i].get('rfilename') for i in range(len(d.get('siblings',[])))))"
```

Or via mirror:
```bash
curl -s "https://hf-mirror.com/api/models/<repo_id>"
```

### Step 3: Download with Fallback

**Method A: curl (preferred for large files)**

```bash
# Create directory
mkdir -p <local_dir>

# Try official source first
curl -L -C - "https://huggingface.co/<repo_id>/resolve/main/<filename>" \
  -o <local_dir>/<filename>

# If fails (SSL, timeout, connection refused), try mirror
curl -L -C - "https://hf-mirror.com/<repo_id>/resolve/main/<filename>" \
  -o <local_dir>/<filename>
```

**Method B: huggingface_hub CLI (if curl fails)**

```bash
# Without mirror
HF_HUB_ENABLE_HF_TRANSFER=1 hf download <repo_id> <filename> --local-dir <local_dir>

# With mirror if needed
HF_ENDPOINT=https://hf-mirror.com HF_HUB_ENABLE_HF_TRANSFER=1 \
  hf download <repo_id> <filename> --local-dir <local_dir>
```

### Step 4: Verify Download

Check file integrity based on type:

**GGUF files:**
```bash
file <filepath> && head -c 100 <filepath> | xxd | head -5
# Should show "GGUF" magic bytes
```

**Safetensors files:**
```bash
file <filepath>
# Should show data or JSON header
```

**General verification:**
- Check file size matches expected (from API or HF webpage)
- Check file is not empty: `ls -lh <filepath>`

## Error Handling

### SSL Errors
```
[SSL: UNEXPECTED_EOF_WHILE_READING]
```
→ Switch to mirror immediately

### Connection Refused
```
Failed to connect to huggingface.co port 443
```
→ Use mirror

### Resume Interrupted Download
```bash
# Same curl command with -C flag resumes automatically
curl -L -C - "https://hf-mirror.com/<repo_id>/resolve/main/<filename>" -o <filepath>
```

### huggingface_hub Client Closed Error
```
RuntimeError: Cannot send a request, as the client has been closed
```
→ Use curl instead of hf CLI

## Quick Reference

| Scenario | Command |
|----------|---------|
| Download GGUF | `curl -L -C - "https://hf-mirror.com/<repo>/resolve/main/<file>.gguf" -o <local>` |
| List repo files | `curl -s "https://hf-mirror.com/api/models/<repo>" \| jq '.siblings[].rfilename'` |
| Resume download | Same curl command ( `-C` flag handles resume) |
| Specific revision | Add `?ref=<branch/tag>` to URL |

## Examples

**Example 1: Download specific GGUF file**
```
User: Download omnicoder-9b-q4_k_m.gguf from Tesslate/OmniCoder-9B-GGUF

→ mkdir -p ./models/OmniCoder-9B-GGUF
→ curl -L -C - "https://huggingface.co/Tesslate/OmniCoder-9B-GGUF/resolve/main/omnicoder-9b-q4_k_m.gguf" -o ./models/OmniCoder-9B-GGUF/omnicoder-9b-q4_k_m.gguf
→ (if fails, use hf-mirror.com)
→ Verify: file ./models/OmniCoder-9B-GGUF/omnicoder-9b-q4_k_m.gguf
```

**Example 2: Download entire model repo**
```
User: Download Qwen/Qwen2.5-7B-Instruct

→ Use hf download command:
→ hf download Qwen/Qwen2.5-7B-Instruct --local-dir ./models/Qwen2.5-7B-Instruct
```

**Example 3: List available files**
```
User: What files are in microsoft/Phi-3-mini-4k-instruct-gguf?

→ curl -s "https://hf-mirror.com/api/models/microsoft/Phi-3-mini-4k-instruct-gguf" | python3 -c "..."
→ Show list of *.gguf files
```

## Tips

1. **Large files (>1GB)**: Use curl with `-C` for resume support
2. **Network issues in China**: Use hf-mirror.com directly
3. **Rate limiting**: Wait and retry, or use HF token: `-H "Authorization: Bearer <token>"`
4. **Private repos**: Add `-H "Authorization: Bearer <HF_TOKEN>"` to curl
