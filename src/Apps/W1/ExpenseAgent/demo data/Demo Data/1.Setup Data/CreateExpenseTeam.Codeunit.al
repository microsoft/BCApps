// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8210 "Create Expense Team"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseTeam(Default(), DefaultTeamLbl);
    end;

    var
        DefaultTok: Label 'DEFAULT', MaxLength = 20, Locked = true;
        DefaultTeamLbl: Label 'Default Team', MaxLength = 100;

    procedure Default(): Code[20]
    begin
        exit(DefaultTok);
    end;
}