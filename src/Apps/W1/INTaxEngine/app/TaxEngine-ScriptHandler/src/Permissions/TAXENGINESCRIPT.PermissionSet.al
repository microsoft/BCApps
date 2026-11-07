// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TaxEngine.ScriptHandler;

permissionset 20156 "TAX ENGINE SCRIPT"
{
    Access = Public;
    Assignable = true;
    Caption = 'Tax Engine Script Handler';

    Permissions = tabledata "Tax Test Condition" = RIMD,
                  tabledata "Tax Test Condition Item" = RIMD,
                  tabledata "Action Comment" = RIMD,
                  tabledata "Action Concatenate" = RIMD,
                  tabledata "Action Concatenate Line" = RIMD,
                  tabledata "Action Container" = RIMD,
                  tabledata "Action Convert Case" = RIMD,
                  tabledata "Action Date Calculation" = RIMD,
                  tabledata "Action Date To DateTime" = RIMD,
                  tabledata "Action Extract Date Part" = RIMD,
                  tabledata "Action Extract DateTime Part" = RIMD,
                  tabledata "Action Ext. Substr. From Index" = RIMD,
                  tabledata "Action Ext. Substr. From Pos." = RIMD,
                  tabledata "Action Find Date Interval" = RIMD,
                  tabledata "Action Find Substring" = RIMD,
                  tabledata "Action If Statement" = RIMD,
                  tabledata "Action Length Of String" = RIMD,
                  tabledata "Action Loop N Times" = RIMD,
                  tabledata "Action Loop Through Rec. Field" = RIMD,
                  tabledata "Action Loop Through Records" = RIMD,
                  tabledata "Action Loop With Condition" = RIMD,
                  tabledata "Action Message" = RIMD,
                  tabledata "Action Number Calculation" = RIMD,
                  tabledata "Action Number Expression" = RIMD,
                  tabledata "Action Number Expr. Token" = RIMD,
                  tabledata "Action Replace Substring" = RIMD,
                  tabledata "Action Round Number" = RIMD,
                  tabledata "Action Set Variable" = RIMD,
                  tabledata "Action String Expression" = RIMD,
                  tabledata "Action String Expr. Token" = RIMD,
                  tabledata "Script Action" = RIMD,
                  tabledata "Script Context" = RIMD,
                  tabledata "Script Editor Line" = RIMD,
                  tabledata "Script Record Variable" = RIMD,
                  tabledata "Script Variable" = RIMD;
}
