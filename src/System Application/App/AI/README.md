# AI SDK

The **Troubleshooting Sessions** list and card show saved troubleshooting reports from the platform's read-only virtual table. The list shows the newest reports first. Both pages show the owner name if the viewer can read the user record. The list loads readable names together on first use rather than looking up each session owner separately. The card shows the saved report as JSON.

The list defaults to `InProgress` or `AwaitingUser`. The platform currently saves reports only as `Concluded`, so choose **Show all sessions** to see them. `Concluded` means the AI returned an answer, not that the user closed the case.

Both pages have inherent execute access and are read-only. No app permission set is required to open the pages. The virtual table enforces owner and company access, including the separate permission for seeing other users' reports. The pages do not grant that permission or access to the User table.