// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8213 "Create Expense Rule Condition"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        Codeunit.Run(Codeunit::"Create Expense Rule Conditions"); // in the expense app
    end;
}