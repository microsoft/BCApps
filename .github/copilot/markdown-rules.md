# Markdown Formatting Rules

## Critical Rules

### 1. No Em Dashes
**Never use em dashes (—) in markdown files.**

- ❌ **Wrong:** `This is great — it works perfectly`
- ✅ **Correct:** `This is great - it works perfectly`
- ✅ **Alternative:** `This is great -- it works perfectly`

**Reason:** Em dashes can cause encoding issues and inconsistent rendering across different platforms and tools.

---

### 2. Blank Lines Before Lists
**CRITICAL:** Always add a blank line before bullet lists or numbered lists.

**Why:** When converting to Word (docx), lists without a preceding blank line will merge with the previous paragraph, creating formatting issues.

**❌ Bad:**
```markdown
**Possible With Ideal Conditions:** 2-3x productivity
- Solo developers on greenfield projects
- Highly experienced AI-first practitioners
```

**✅ Good:**
```markdown
**Possible With Ideal Conditions:** 2-3x productivity

- Solo developers on greenfield projects
- Highly experienced AI-first practitioners
```

**Applies to:**

- Bullet lists (using `-`, `*`, or `+`)
- Numbered lists (using `1.`, `2.`, etc.)
- Any list following bold text, headings, or regular paragraphs
- Nested lists

---

## Best Practices

### Headers
- Use ATX-style headers (`#` through `######`)
- Add blank line before and after headers
- Use sentence case for headers (not TITLE CASE)

### Links
- Use descriptive link text (not "click here")
- Prefer reference-style links for repeated URLs
- Keep URLs under 80 characters when possible

### Code Blocks
- Specify language for syntax highlighting
- Use triple backticks (```) not indentation
- Add blank line before and after code blocks

### Emphasis
- Use `*italic*` or `_italic_` consistently
- Use `**bold**` or `__bold__` consistently
- Don't mix styles in same document

### Tables
- Align columns for readability in source
- Include header row separator
- Keep tables under 80 characters wide when possible

---

## Document Structure

### Required Elements
- Clear title (H1) at top
- Brief description or overview
- Logical section hierarchy
- Table of contents for docs >300 lines

### Recommended Elements
- Examples for complex concepts
- Cross-references to related docs
- Last updated date
- Name of the person that updated it (use the Windows username if you haven't been told something better)
- Version or document ID

---

## Conversion Considerations

### For DOCX Conversion
When using `scripts/md-to-docx.ps1`:

- Ensure blank lines before lists
- Use standard markdown (avoid HTML)
- Test complex tables before converting
- Keep line length reasonable (<120 chars)
- Avoid fancy Unicode characters

### For GitHub Rendering
- Use GitHub-flavored markdown features
- Test alerts/callouts if using
- Verify emoji support if needed
- Check task list rendering

---

## Common Mistakes

### ❌ Avoid These:
```markdown
**Bold text without blank line:**
- List item 1
- List item 2

Using em dashes — like this

Header without blank lines:
### Next Section
Some content

Inconsistent list markers:
- First item
* Second item
+ Third item
```

### ✅ Do This Instead:
```markdown
**Bold text with blank line:**

- List item 1
- List item 2

Using hyphens - like this

Header with blank lines:

### Next Section

Some content

Consistent list markers:

- First item
- Second item
- Third item
```

---

## Quick Reference

| Element | Correct | Incorrect |
|---------|---------|-----------|
| Em dash | `--` or `-` | `—` |
| List spacing | Blank line before | No blank line |
| Header case | Sentence case | TITLE CASE |
| Code blocks | ` ```language ` | Indented |
| Emphasis | Consistent style | Mixed styles |

---

## Enforcement

These rules are enforced to ensure:

- ✅ Clean conversion to DOCX/PDF
- ✅ Consistent rendering across platforms
- ✅ Maintainable documentation
- ✅ Accessible content
- ✅ Professional appearance

**When in doubt, prioritize clarity and consistency over style.**


---

**Last Updated:** December 3, 2025 by gregrata
