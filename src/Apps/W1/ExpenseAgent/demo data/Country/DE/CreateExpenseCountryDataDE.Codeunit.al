// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8311 "Create Expense Country Data DE" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreateExpGLAccountDE: Codeunit "Create Exp. GL Account DE";
        CreateExpPostingGrpDE: Codeunit "Create Exp. Posting Grp DE";
    begin
        BindSubscription(CreateExpGLAccountDE);
        BindSubscription(CreateExpPostingGrpDE);

        CreateExpenseCountryDataW1.CreateSetupData();
        Codeunit.Run(Codeunit::"Update Emp. Posting Grp DE");
        Codeunit.Run(Codeunit::"Create Exp. Posting Grp DE");

        UnbindSubscription(CreateExpPostingGrpDE);
        UnbindSubscription(CreateExpGLAccountDE);
    end;

    procedure CreateMasterData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateMasterData();
        Codeunit.Run(Codeunit::"Create Exp. Categories DE");
        Codeunit.Run(Codeunit::"Create Exp. SubCategories DE");
        Codeunit.Run(Codeunit::"Create Exp. Rule Header DE");
        Codeunit.Run(Codeunit::"Create Exp. Rule Condition DE");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateTransactionalData();
        Codeunit.Run(Codeunit::"Create Expense DE");
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        ExpDemoDataSubscriberDE: Codeunit "Exp. Demo Data Subscriber DE";
        CreatePostedExpReportDE: Codeunit "Create Posted Exp. Report DE";
    begin
        BindSubscription(ExpDemoDataSubscriberDE);
        BindSubscription(CreatePostedExpReportDE);

        CreateExpenseCountryDataW1.CreateHistoricalData();
        Codeunit.Run(Codeunit::"Create Posted Exp. Report DE");

        UnbindSubscription(CreatePostedExpReportDE);
        UnbindSubscription(ExpDemoDataSubscriberDE);
    end;
}
