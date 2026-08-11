// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8275 "Create Expense Country Data ES" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreateExpGLAccountES: Codeunit "Create Exp. GL Account ES";
        CreateExpPostingGrpES: Codeunit "Create Exp. Posting Grp ES";
    begin
        BindSubscription(CreateExpGLAccountES);
        BindSubscription(CreateExpPostingGrpES);

        CreateExpenseCountryDataW1.CreateSetupData();
        Codeunit.Run(Codeunit::"Update Employee ES");
        Codeunit.Run(Codeunit::"Update Emp. Posting Grp ES");
        Codeunit.Run(Codeunit::"Create Exp. Posting Grp ES");

        UnbindSubscription(CreateExpPostingGrpES);
        UnbindSubscription(CreateExpGLAccountES);
    end;

    procedure CreateMasterData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateMasterData();
        Codeunit.Run(Codeunit::"Create Exp. Categories ES");
        Codeunit.Run(Codeunit::"Create Exp. SubCategories ES");
        Codeunit.Run(Codeunit::"Create Exp. Rule Header ES");
        Codeunit.Run(Codeunit::"Create Exp. Rule Condition ES");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        ExpDemoDataSubscriberES: Codeunit "Exp. Demo Data Subscriber ES";
    begin
        BindSubscription(ExpDemoDataSubscriberES);

        CreateExpenseCountryDataW1.CreateTransactionalData();
        Codeunit.Run(Codeunit::"Create Expense ES");

        UnbindSubscription(ExpDemoDataSubscriberES);
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        ExpDemoDataSubscriberES: Codeunit "Exp. Demo Data Subscriber ES";
        CreatePostedExpReportES: Codeunit "Create Posted Exp. Report ES";
    begin
        BindSubscription(ExpDemoDataSubscriberES);
        BindSubscription(CreatePostedExpReportES);

        CreateExpenseCountryDataW1.CreateHistoricalData();
        Codeunit.Run(Codeunit::"Create Posted Exp. Report ES");

        UnbindSubscription(CreatePostedExpReportES);
        UnbindSubscription(ExpDemoDataSubscriberES);
    end;
}
