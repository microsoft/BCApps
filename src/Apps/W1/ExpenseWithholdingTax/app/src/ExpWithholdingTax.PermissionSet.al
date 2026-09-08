// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseTaxIntegration;

permissionset 7058 "Exp. Withholding Tax"
{
    Assignable = true;
    Caption = 'Expense Withholding Tax';

    Permissions =
        tabledata "WHT Exp. Report Buffer" = RIMD,
        table "WHT Exp. Report Buffer" = X,
        codeunit "WHT Expense Category Mgt." = X,
        codeunit "WHT Exp. Report Post Handler" = X;
}
