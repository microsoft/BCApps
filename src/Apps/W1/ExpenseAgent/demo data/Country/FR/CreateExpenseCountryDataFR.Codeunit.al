// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8300 "Create Expense Country Data FR" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreateExpGLAccountFR: Codeunit "Create Exp. GL Account FR";
        CreateExpPostingGrpFR: Codeunit "Create Exp. Posting Grp FR";
    begin
        BindSubscription(CreateExpGLAccountFR);
        BindSubscription(CreateExpPostingGrpFR);

        CreateExpenseCountryDataW1.CreateSetupData();
        Codeunit.Run(Codeunit::"Update Emp. Posting Grp FR");
        Codeunit.Run(Codeunit::"Create Exp. Posting Grp FR");

        UnbindSubscription(CreateExpPostingGrpFR);
        UnbindSubscription(CreateExpGLAccountFR);
    end;

    procedure CreateMasterData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateMasterData();
        Codeunit.Run(Codeunit::"Create Exp. Categories FR");
        Codeunit.Run(Codeunit::"Create Exp. SubCategories FR");
        Codeunit.Run(Codeunit::"Create Exp. Rule Header FR");
        Codeunit.Run(Codeunit::"Create Exp. Rule Condition FR");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateTransactionalData();
        Codeunit.Run(Codeunit::"Create Expense FR");
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        ExpDemoDataSubscriberFR: Codeunit "Exp. Demo Data Subscriber FR";
        CreatePostedExpReportFR: Codeunit "Create Posted Exp. Report FR";
    begin
        BindSubscription(ExpDemoDataSubscriberFR);
        BindSubscription(CreatePostedExpReportFR);

        CreateExpenseCountryDataW1.CreateHistoricalData();
        Codeunit.Run(Codeunit::"Create Posted Exp. Report FR");

        UnbindSubscription(CreatePostedExpReportFR);
        UnbindSubscription(ExpDemoDataSubscriberFR);
    end;
}
