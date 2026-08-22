// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8234 "Create Expense Country Data GB" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreateExpGLAccountGB: Codeunit "Create Exp. GL Account GB";
        CreateExpPostingGrpGB: Codeunit "Create Exp. Posting Grp GB";
    begin
        BindSubscription(CreateExpGLAccountGB);
        BindSubscription(CreateExpPostingGrpGB);

        CreateExpenseCountryDataW1.CreateSetupData();
        Codeunit.Run(Codeunit::"Update Emp. Posting Grp GB");
        Codeunit.Run(Codeunit::"Create Exp. Posting Grp GB");

        UnbindSubscription(CreateExpPostingGrpGB);
        UnbindSubscription(CreateExpGLAccountGB);
    end;

    procedure CreateMasterData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateMasterData();
        Codeunit.Run(Codeunit::"Create Exp. Categories GB");
        Codeunit.Run(Codeunit::"Create Exp. SubCategories GB");
        Codeunit.Run(Codeunit::"Create Exp. Rule Header GB");
        Codeunit.Run(Codeunit::"Create Exp. Rule Condition GB");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateTransactionalData();
        Codeunit.Run(Codeunit::"Create Expense GB");
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreatePostedExpReportGB: Codeunit "Create Posted Exp. Report GB";
    begin
        BindSubscription(CreatePostedExpReportGB);

        CreateExpenseCountryDataW1.CreateHistoricalData();
        Codeunit.Run(Codeunit::"Create Posted Exp. Report GB");

        UnbindSubscription(CreatePostedExpReportGB);
    end;
}
