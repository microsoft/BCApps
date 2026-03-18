# RoleCenter extensions

Page extensions that embed the `E-Document Activities` cue group into standard BC role centers so users see e-document status without navigating away from their home page.

## How it works

Five page extensions -- Accountant, AP Admin Activities, Business Manager, Inventory Manager, and Ship/Receive/WMS -- each add the `E-Document Activities` CardPart after the approvals section. The activities part (`EDocumentActivities.Page.al` in the parent `Extensions/` directory) shows counts for outgoing and incoming e-documents grouped by status: Processed, In Progress, and Error. Each count is drillable, opening the filtered E-Documents list.

## Things to know

- The activities page uses `RefreshOnActivate = true` so counts update every time the role center is displayed, not just on first load.
- Adding E-Document activities to a new role center only requires a one-line page extension embedding the existing `E-Document Activities` part -- no new codeunit work.
- The AP Admin Activities extension (`EDocAPAdminActivities.PageExt.al`) is separate from the Accountant RC extension because AP Admin has a different page structure for its activity groups.
- All extensions use `ApplicationArea = Basic, Suite`, making them visible in all license tiers that include those areas.
