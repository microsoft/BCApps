// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8423 "Create Expense Country Data IT" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreateExpGLAccountIT: Codeunit "Create Exp. GL Account IT";
        CreateExpPostingGrpIT: Codeunit "Create Exp. Posting Grp IT";
    begin
        BindSubscription(CreateExpGLAccountIT);
        BindSubscription(CreateExpPostingGrpIT);

        CreateExpenseCountryDataW1.CreateSetupData();
        Codeunit.Run(Codeunit::"Update Emp. Posting Grp IT");
        Codeunit.Run(Codeunit::"Create Exp. Posting Grp IT");

        UnbindSubscription(CreateExpPostingGrpIT);
        UnbindSubscription(CreateExpGLAccountIT);
    end;

    procedure CreateMasterData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateMasterData();
        Codeunit.Run(Codeunit::"Create Exp. Categories IT");
        Codeunit.Run(Codeunit::"Create Exp. SubCategories IT");
        Codeunit.Run(Codeunit::"Create Exp. Rule Header IT");
        Codeunit.Run(Codeunit::"Create Exp. Rule Condition IT");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        ExpDemoDataSubscriberIT: Codeunit "Exp. Demo Data Subscriber IT";
    begin
        BindSubscription(ExpDemoDataSubscriberIT);

        CreateExpenseCountryDataW1.CreateTransactionalData();
        Codeunit.Run(Codeunit::"Create Expense IT");

        UnbindSubscription(ExpDemoDataSubscriberIT);
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        ExpDemoDataSubscriberIT: Codeunit "Exp. Demo Data Subscriber IT";
        CreatePostedExpReportIT: Codeunit "Create Posted Exp. Report IT";
    begin
        BindSubscription(ExpDemoDataSubscriberIT);
        BindSubscription(CreatePostedExpReportIT);

        CreateExpenseCountryDataW1.CreateHistoricalData();
        Codeunit.Run(Codeunit::"Create Posted Exp. Report IT");

        UnbindSubscription(CreatePostedExpReportIT);
        UnbindSubscription(ExpDemoDataSubscriberIT);
    end;
}
