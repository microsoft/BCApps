// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8412 "Create Expense Country Data BE" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreateExpGLAccountBE: Codeunit "Create Exp. GL Account BE";
        CreateExpPostingGrpBE: Codeunit "Create Exp. Posting Grp BE";
    begin
        BindSubscription(CreateExpGLAccountBE);
        BindSubscription(CreateExpPostingGrpBE);

        CreateExpenseCountryDataW1.CreateSetupData();
        Codeunit.Run(Codeunit::"Update Emp. Posting Grp BE");
        Codeunit.Run(Codeunit::"Create Exp. Posting Grp BE");

        UnbindSubscription(CreateExpPostingGrpBE);
        UnbindSubscription(CreateExpGLAccountBE);
    end;

    procedure CreateMasterData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateMasterData();
        Codeunit.Run(Codeunit::"Create Exp. Categories BE");
        Codeunit.Run(Codeunit::"Create Exp. SubCategories BE");
        Codeunit.Run(Codeunit::"Create Exp. Rule Header BE");
        Codeunit.Run(Codeunit::"Create Exp. Rule Condition BE");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        ExpDemoDataSubscriberBE: Codeunit "Exp. Demo Data Subscriber BE";
    begin
        BindSubscription(ExpDemoDataSubscriberBE);

        CreateExpenseCountryDataW1.CreateTransactionalData();
        Codeunit.Run(Codeunit::"Create Expense BE");

        UnbindSubscription(ExpDemoDataSubscriberBE);
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        ExpDemoDataSubscriberBE: Codeunit "Exp. Demo Data Subscriber BE";
        CreatePostedExpReportBE: Codeunit "Create Posted Exp. Report BE";
    begin
        BindSubscription(ExpDemoDataSubscriberBE);
        BindSubscription(CreatePostedExpReportBE);

        CreateExpenseCountryDataW1.CreateHistoricalData();
        Codeunit.Run(Codeunit::"Create Posted Exp. Report BE");

        UnbindSubscription(CreatePostedExpReportBE);
        UnbindSubscription(ExpDemoDataSubscriberBE);
    end;
}
