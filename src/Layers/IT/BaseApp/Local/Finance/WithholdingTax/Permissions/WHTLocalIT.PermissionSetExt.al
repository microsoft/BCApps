namespace System.Security.AccessControl;

using Microsoft.Finance.WithholdingTax;

permissionsetextension 12124 "WHTLocalIT" extends "LOCAL"
{
    Permissions = tabledata "Computed Withholding Tax" = RIMD,
                  tabledata "Purch. Withh. Contribution" = RIMD,
                  tabledata "Tmp Withholding Contribution" = RIMD,
                  tabledata "Withhold Code" = RIMD,
                  tabledata "Withhold Code Line" = RIMD,
                  tabledata "Withholding Tax" = RIMD,
                  tabledata "Withholding Tax Line" = RIMD,
                  tabledata "Withholding Tax Payment" = RIMD,
                  tabledata "Withholding Exceptional Event" = RIMD;
}
