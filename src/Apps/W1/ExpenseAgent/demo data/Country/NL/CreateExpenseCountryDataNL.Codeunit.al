// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8401 "Create Expense Country Data NL" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreateExpGLAccountNL: Codeunit "Create Exp. GL Account NL";
        CreateExpPostingGrpNL: Codeunit "Create Exp. Posting Grp NL";
    begin
        BindSubscription(CreateExpGLAccountNL);
        BindSubscription(CreateExpPostingGrpNL);

        CreateExpenseCountryDataW1.CreateSetupData();
        Codeunit.Run(Codeunit::"Update Emp. Posting Grp NL");
        Codeunit.Run(Codeunit::"Create Exp. Posting Grp NL");

        UnbindSubscription(CreateExpPostingGrpNL);
        UnbindSubscription(CreateExpGLAccountNL);
    end;

    procedure CreateMasterData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateMasterData();
        Codeunit.Run(Codeunit::"Create Exp. Categories NL");
        Codeunit.Run(Codeunit::"Create Exp. SubCategories NL");
        Codeunit.Run(Codeunit::"Create Exp. Rule Header NL");
        Codeunit.Run(Codeunit::"Create Exp. Rule Condition NL");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        ExpDemoDataSubscriberNL: Codeunit "Exp. Demo Data Subscriber NL";
    begin
        BindSubscription(ExpDemoDataSubscriberNL);

        CreateExpenseCountryDataW1.CreateTransactionalData();
        Codeunit.Run(Codeunit::"Create Expense NL");

        UnbindSubscription(ExpDemoDataSubscriberNL);
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        ExpDemoDataSubscriberNL: Codeunit "Exp. Demo Data Subscriber NL";
        CreatePostedExpReportNL: Codeunit "Create Posted Exp. Report NL";
    begin
        BindSubscription(ExpDemoDataSubscriberNL);
        BindSubscription(CreatePostedExpReportNL);

        CreateExpenseCountryDataW1.CreateHistoricalData();
        Codeunit.Run(Codeunit::"Create Posted Exp. Report NL");

        UnbindSubscription(CreatePostedExpReportNL);
        UnbindSubscription(ExpDemoDataSubscriberNL);
    end;
}
