namespace System.Security.AccessControl;

using Microsoft.Bank.Payment;
using Microsoft.Finance.WithholdingTax;

permissionsetextension 12125 "WHTLocalReadIT" extends "LOCAL READ"
{
    Permissions =
                  tabledata "Computed Contribution" = R,
                  tabledata "Contribution Bracket" = R,
                  tabledata "Contribution Bracket Line" = R,
                  tabledata "Contribution Code" = R,
                  tabledata "Contribution Code Line" = R,
                  tabledata "Contribution Payment" = R,
                  tabledata Contributions = R,
                  tabledata "Computed Withholding Tax" = R,
                  tabledata "Purch. Withh. Contribution" = R,
                  tabledata "Tmp Withholding Contribution" = R,
                  tabledata "Withhold Code" = R,
                  tabledata "Withhold Code Line" = R,
                  tabledata "Withholding Tax" = R,
                  tabledata "Withholding Tax Line" = R,
                  tabledata "Withholding Tax Payment" = R,
                  tabledata "Withholding Exceptional Event" = R;
}
