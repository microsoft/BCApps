namespace System.Security.AccessControl;

using Microsoft.Inventory.Analysis;

permissionset 1698 "Inventory Analysis - View"
{
    Access = Public;
    Assignable = false;

    Caption = 'Read S&R/P&P/Inv. Analys. Rep.';
    Permissions = tabledata "Analysis Column" = R,
                  tabledata "Analysis Column Template" = R,
                  tabledata "Analysis Dim. Selection Buffer" = rimd,
                  tabledata "Analysis Field Value" = Rimd,
                  tabledata "Analysis Line" = R,
                  tabledata "Analysis Line Template" = R,
                  tabledata "Analysis Report Name" = R,
                  tabledata "Analysis Selected Dimension" = rimd,
                  tabledata "Analysis Type" = R,
                  tabledata "Item Analysis View" = R,
                  tabledata "Item Analysis View Budg. Entry" = Rimd,
                  tabledata "Item Analysis View Entry" = Rimd,
                  tabledata "Item Analysis View Filter" = R;
}
