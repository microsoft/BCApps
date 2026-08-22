// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8467 "Create Expense Country Data CZ" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreateExpGLAccountCZ: Codeunit "Create Exp. GL Account CZ";
        CreateExpPostingGrpCZ: Codeunit "Create Exp. Posting Grp CZ";
    begin
        BindSubscription(CreateExpGLAccountCZ);
        BindSubscription(CreateExpPostingGrpCZ);

        CreateExpenseCountryDataW1.CreateSetupData();
        Codeunit.Run(Codeunit::"Update Emp. Posting Grp CZ");
        Codeunit.Run(Codeunit::"Create Exp. Posting Grp CZ");

        UnbindSubscription(CreateExpPostingGrpCZ);
        UnbindSubscription(CreateExpGLAccountCZ);
    end;

    procedure CreateMasterData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateMasterData();
        Codeunit.Run(Codeunit::"Create Exp. Categories CZ");
        Codeunit.Run(Codeunit::"Create Exp. SubCategories CZ");
        Codeunit.Run(Codeunit::"Create Exp. Rule Header CZ");
        Codeunit.Run(Codeunit::"Create Exp. Rule Condition CZ");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateTransactionalData();
        Codeunit.Run(Codeunit::"Create Expense CZ");
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreatePostedExpReportCZ: Codeunit "Create Posted Exp. Report CZ";
    begin
        BindSubscription(CreatePostedExpReportCZ);

        CreateExpenseCountryDataW1.CreateHistoricalData();
        Codeunit.Run(Codeunit::"Create Posted Exp. Report CZ");

        UnbindSubscription(CreatePostedExpReportCZ);
    end;
}
