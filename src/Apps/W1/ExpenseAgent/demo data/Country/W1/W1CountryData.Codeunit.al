// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8222 "W1 Country Data" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    begin
        Codeunit.Run(Codeunit::"Create Expense Payment Method");
        Codeunit.Run(Codeunit::"Create Expense No. Series DM");
        Codeunit.Run(Codeunit::"Create Expense Group");
        Codeunit.Run(Codeunit::"Create Expense G/L Account");
        Codeunit.Run(Codeunit::"Create Expense Posting Group");
        Codeunit.Run(Codeunit::"Create Expense Team");
        Codeunit.Run(Codeunit::"Create Exp. Agent Setup");
    end;

    procedure CreateMasterData()
    begin
        Codeunit.Run(Codeunit::"Create Expense Location");
        Codeunit.Run(Codeunit::"Create Expense Categories DM");
        Codeunit.Run(Codeunit::"Create Expense Subcategories");
        Codeunit.Run(Codeunit::"Create Expense Rule Header");
        Codeunit.Run(Codeunit::"Create Expense Rule Condition");
        Codeunit.Run(Codeunit::"Create Expense User");
    end;

    procedure CreateTransactionalData()
    begin
        Codeunit.Run(Codeunit::"Create Expense");
        Codeunit.Run(Codeunit::"Create Exp. Report");
    end;

    procedure CreateHistoricalData()
    begin
        Codeunit.Run(Codeunit::"Create Posted Expense Report");
    end;
}
