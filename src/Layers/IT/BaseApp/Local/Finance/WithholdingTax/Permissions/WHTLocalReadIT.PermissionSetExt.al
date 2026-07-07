namespace System.Security.AccessControl;

using Microsoft.Finance.WithholdingTax;

permissionsetextension 12125 "WHTLocalReadIT" extends "LOCAL READ"
{
    Permissions = tabledata "Computed Withholding Tax" = R,
                  tabledata "Purch. Withh. Contribution" = R,
                  tabledata "Tmp Withholding Contribution" = R,
                  tabledata "Withhold Code" = R,
                  tabledata "Withhold Code Line" = R,
                  tabledata "Withholding Tax" = R,
                  tabledata "Withholding Tax Line" = R,
                  tabledata "Withholding Tax Payment" = R,
                  tabledata "Withholding Exceptional Event" = R;
}
