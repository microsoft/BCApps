# Memory Bank Initialization for Brownfield Codebases

Initialize a compressed memory bank for this large legacy codebase.

## Instructions

1. Read [memory-bank.md](./memory-bank.md) for all specifications
2. Execute the **Initialization Process** section (3 phases)
3. Validate against **Size Validation** and **Evidence-Based Requirements**
4. End with completion summary

All requirements, file specifications, validation criteria, and compression rules are defined in `memory-bank.md`. Follow them exactly.

## Quick Reference

| Phase | Time | Goal |
|-------|------|------|
| Discovery | ~15 min | Map structure, count files, identify critical files |
| Analysis | ~30 min | Read files, extract patterns, verify with grep |
| Compression | ~15 min | Write 3 files, validate size and evidence |

## Completion

End with:

```
? Memory Bank Initialized

Files created:
- README.md (X lines)
- context.md (X lines)  
- patterns.md (X lines)
- current.md (X lines)
- Total: X lines

Target: 530 | Max: 1400 | Actual: X | Status: PASS/FAIL
Evidence: All patterns have file references | Status: PASS/FAIL
```
