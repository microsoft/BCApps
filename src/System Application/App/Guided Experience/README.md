# Guided Experience

## Early Access Preview feature catalog

Edit [`EarlyAccessPreviewFeatures.json`](../Resources/Files/EarlyAccessPreviewFeatures.json)
in the System Application resource folder. The similarly named file in this module's
`Resources` folder is a sample, not the shipped catalog.

Each entry describes one user-testable capability. Group related implementation
changes into one entry and preserve existing help and video links when updating it.

| Property | Type | Limit / convention |
| --- | --- | --- |
| `FeatureName` | String | Required, nonblank and unique; at most 2048 UTF-16 code units. |
| `Description` | String | Required and nonblank; at most 1024 UTF-16 code units. |
| `Category` | String | Required and nonblank; at most 250 UTF-16 code units. |
| `HelpURL` | String | At most 250 UTF-16 code units; use an empty string when no verified link is available. |
| `VideoURL` | String | At most 250 UTF-16 code units; use an empty string when no verified link is available. |
| `ADOSliceIds` | Array of integers, optional | Nonempty, unique positive Azure DevOps **Slice** IDs for the capability. |

Property names are case-sensitive. For `ADOSliceIds`, verify the actual work-item
type in the repository's Azure DevOps project. Follow a bug, task or deliverable's
actual parent hierarchy to a relevant slice; do not substitute a bug, epic, owner
record or an unrelated broader parent. Include multiple slices when they deliver
the capability together, and omit the property when no slice is verified. Missing
slice metadata must not exclude an otherwise suitable feature.

Publish only the numeric slice IDs, not internal work-item URLs, titles,
descriptions, ownership or readiness notes. These references do not close work
items; listing PRs should not copy closing directives from implementation PRs.

The AL loader reads only the five display properties and ignores `ADOSliceIds`.
Existing entries without metadata continue to work. The metadata creates no
runtime Azure DevOps dependency and is not shown in the cockpit.
