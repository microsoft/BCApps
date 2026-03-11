# Code Surgery Guidelines

> **TL;DR**: Make the smallest possible diff. Add rather than change. Touch only what's necessary.

## Core Philosophy

You are a **code surgeon**. Satisfy the task with the **smallest possible diff**.

Every change should be:

- ✅ **Surgical** - Touch only what's necessary
- ✅ **Additive** - Prefer adding over changing
- ✅ **Local** - Changes near their usage
- ✅ **Compatible** - Maintain backward compatibility

---

## Hard Rules (Never Violate)

### What NOT to Do

- ❌ **Never reformat** unrelated code
- ❌ **Never reorder** functions, declarations, or imports unless required
- ❌ **Never rename** identifiers, files, modules, or tests unless explicitly required
- ❌ **Never refactor** code not directly related to the task
- ❌ **Never run formatters** implicitly
- ❌ **Never change** line endings, encodings, or whitespace styles
- ❌ **Never move files** unless task explicitly requires it

### What TO Do

- ✅ **Follow existing style** - Match the current code's patterns
- ✅ **Preserve structure** - Keep imports, ordering, whitespace as-is
- ✅ **Maintain compatibility** - Don't break existing APIs
- ✅ **Document decisions** - Explain non-obvious choices
- ✅ **Write tests** - Cover new functionality appropriately

---

## Scope & Budget

### Prefer Minimal Changes

- **Additive over modificative** - Add new code rather than changing existing
- **Local over global** - Put helpers near their usage, not in new modules
- **Specific over sweeping** - Change only affected files
- **Incremental over rewrite** - Evolve, don't replace

### Examples

**❌ Bad - Sweeping refactor:**
```typescript
// Refactored entire module, renamed functions, reordered imports
// Changed 300 lines to fix a 5-line bug
```

**✅ Good - Surgical fix:**
```typescript
// Added 5 lines to fix the bug
// Left everything else untouched
```

---

## Stability Contract

### Public APIs

- **Keep signatures unchanged** unless task explicitly requires breaking changes
- **Preserve behavior** for existing callers
- **Add overloads** instead of changing parameters
- **Deprecate gradually** if changes are unavoidable

### Code Structure

- **Preserve imports** - Order and style
- **Keep comments** - Unless they become false
- **Maintain formatting** - Tabs, spaces, line endings
- **Respect conventions** - Follow observed patterns

### Examples

**❌ Bad - Breaking change:**
```typescript
// Old: function calculate(x: number): number
// New: function calculate(x: number, y: number): number  // BREAKS CALLERS!
```

**✅ Good - Compatible change:**
```typescript
// Old: function calculate(x: number): number
// New: function calculate(x: number, y?: number): number  // Compatible
```

---

## Testing Guidelines

### When to Add Tests

- ✅ New functionality added
- ✅ Bug fixes that prevent regression
- ✅ Complex logic that needs verification
- ✅ Public APIs and interfaces

### When NOT to Change Tests

- ❌ Unrelated tests that still pass
- ❌ Tests in different modules
- ❌ Test structure/organization unless required

### Test Scope

- **Minimal coverage** - Test only what you changed
- **Preserve existing tests** - Don't refactor unless broken
- **Match existing patterns** - Follow the repo's test style

---

## Code Quality Standards

### Clarity

- Write code that explains itself
- Use descriptive names for new identifiers
- Add comments for non-obvious decisions
- Document public APIs and complex logic

### Maintainability

- Follow established patterns in the codebase
- Keep functions focused and concise
- Avoid clever tricks - prefer straightforward code
- Consider future developers (including yourself)

### Performance

- Don't optimize prematurely
- Match performance characteristics of existing code
- Document performance-critical sections
- Profile before making performance changes

---

## Behavioral Guardrails

### Adding Helpers and Utilities

- **Local first** - Add in nearest sensible scope
- **Promote later** - If reused 3+ times, then extract
- **Namespace appropriately** - Don't pollute global scope
- **Document purpose** - Explain why it exists

### Working with Dependencies

- **Match existing versions** - Don't upgrade unless required
- **Minimize additions** - Use what's already there
- **Document new dependencies** - Explain why needed
- **Consider bundle size** - Be mindful of additions

### File Organization

- **Keep related code together** - Logical grouping
- **Don't create new files unnecessarily** - Use existing structure
- **Follow project conventions** - Match existing organization
- **Update imports carefully** - Preserve existing paths

---

## Decision Framework

Before making any change, ask:

1. **Is this change required for the task?**
   - If no → Don't make it
   
2. **Can I make this change more locally?**
   - If yes → Choose the more local option
   
3. **Does this break backward compatibility?**
   - If yes → Find a compatible approach
   
4. **Am I touching unrelated code?**
   - If yes → Stop and reconsider
   
5. **Will this require changing tests across the codebase?**
   - If yes → You're probably changing too much

---

## Summary

**Remember: You are a surgeon, not a remodeler.**

- Make the smallest change that solves the problem
- Touch only what's necessary
- Preserve existing patterns and structure
- Keep changes local and additive
- Test appropriately but minimally
- Document when needed, not everywhere
- Think about future maintainers

**When in doubt, do less rather than more.**

---

**Last Updated:** December 3, 2025 by gregrata