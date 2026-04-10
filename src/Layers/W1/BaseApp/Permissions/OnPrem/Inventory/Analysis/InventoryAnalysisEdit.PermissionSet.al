namespace System.Security.AccessControl;

using Microsoft.Inventory.Analysis;

permissionset 949 "Inventory Analysis - Edit"
{
    Access = Public;
    Assignable = false;

    Caption = 'Edit S&R/P&P/Inv. Analys. Rep.';
    Permissions = tabledata "Analysis Column" = RIMD,
                  tabledata "Analysis Column Template" = RIMD,
                  tabledata "Analysis Dim. Selection Buffer" = rimd,
                  tabledata "Analysis Field Value" = Rimd,
                  tabledata "Analysis Line" = RIMD,
                  tabledata "Analysis Line Template" = RIMD,
                  tabledata "Analysis Report Name" = RIMD,
                  tabledata "Analysis Selected Dimension" = rimd,
                  tabledata "Analysis Type" = RIMD,
                  tabledata "Item Analysis View" = RIMD,
                  tabledata "Item Analysis View Budg. Entry" = Rimd,
                  tabledata "Item Analysis View Entry" = Rimd,
                  tabledata "Item Analysis View Filter" = RIMD;
}
