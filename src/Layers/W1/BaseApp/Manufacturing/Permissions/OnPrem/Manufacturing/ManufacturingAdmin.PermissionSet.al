namespace System.Security.AccessControl;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Projects.Project.Journal;

permissionset 4855 "Manufacturing - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Setup Manufacturing';

    Permissions = tabledata Family = RIMD,
                  tabledata "Family Line" = RIMD,
                  tabledata Item = R,
                  tabledata "Item Unit of Measure" = R,
                  tabledata "Job Journal Batch" = RIMD,
                  tabledata Location = R,
                  tabledata "Manufacturing Setup" = RIMD,
                  tabledata "No. Series" = RIMD,
                  tabledata "No. Series Line" = RIMD,
                  tabledata "No. Series Relationship" = RIMD,
                  tabledata "Production Forecast Name" = RIMD,
                  tabledata "Reason Code" = R,
                  tabledata "Report Selections" = RIMD,
                  tabledata "Routing Header" = R,
                  tabledata "Source Code" = R,
                  tabledata "Source Code Setup" = R;
}
