// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8212 "Create Expense Rule Header"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        Codeunit.Run(Codeunit::"Create Expense Rule Headers"); // in the expense app
    end;
}