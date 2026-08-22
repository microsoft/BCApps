// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8456 "Create Expense Country Data FI" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreateExpGLAccountFI: Codeunit "Create Exp. GL Account FI";
        CreateExpPostingGrpFI: Codeunit "Create Exp. Posting Grp FI";
    begin
        BindSubscription(CreateExpGLAccountFI);
        BindSubscription(CreateExpPostingGrpFI);

        CreateExpenseCountryDataW1.CreateSetupData();
        Codeunit.Run(Codeunit::"Update Emp. Posting Grp FI");
        Codeunit.Run(Codeunit::"Create Exp. Posting Grp FI");

        UnbindSubscription(CreateExpPostingGrpFI);
        UnbindSubscription(CreateExpGLAccountFI);
    end;

    procedure CreateMasterData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateMasterData();
        Codeunit.Run(Codeunit::"Create Exp. Categories FI");
        Codeunit.Run(Codeunit::"Create Exp. SubCategories FI");
        Codeunit.Run(Codeunit::"Create Exp. Rule Header FI");
        Codeunit.Run(Codeunit::"Create Exp. Rule Condition FI");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        ExpDemoDataSubscriberFI: Codeunit "Exp. Demo Data Subscriber FI";
    begin
        BindSubscription(ExpDemoDataSubscriberFI);

        CreateExpenseCountryDataW1.CreateTransactionalData();
        Codeunit.Run(Codeunit::"Create Expense FI");

        UnbindSubscription(ExpDemoDataSubscriberFI);
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        ExpDemoDataSubscriberFI: Codeunit "Exp. Demo Data Subscriber FI";
        CreatePostedExpReportFI: Codeunit "Create Posted Exp. Report FI";
    begin
        BindSubscription(ExpDemoDataSubscriberFI);
        BindSubscription(CreatePostedExpReportFI);

        CreateExpenseCountryDataW1.CreateHistoricalData();
        Codeunit.Run(Codeunit::"Create Posted Exp. Report FI");

        UnbindSubscription(CreatePostedExpReportFI);
        UnbindSubscription(ExpDemoDataSubscriberFI);
    end;
}
