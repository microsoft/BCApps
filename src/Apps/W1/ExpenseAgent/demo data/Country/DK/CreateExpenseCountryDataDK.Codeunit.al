// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8288 "Create Expense Country Data DK" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreateExpGLAccountDK: Codeunit "Create Exp. GL Account DK";
        CreateExpPostingGrpDK: Codeunit "Create Exp. Posting Grp DK";
    begin
        BindSubscription(CreateExpGLAccountDK);
        BindSubscription(CreateExpPostingGrpDK);

        CreateExpenseCountryDataW1.CreateSetupData();
        Codeunit.Run(Codeunit::"Update Emp. Posting Grp DK");
        Codeunit.Run(Codeunit::"Create Exp. Posting Grp DK");

        UnbindSubscription(CreateExpPostingGrpDK);
        UnbindSubscription(CreateExpGLAccountDK);
    end;

    procedure CreateMasterData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateMasterData();
        Codeunit.Run(Codeunit::"Create Exp. Categories DK");
        Codeunit.Run(Codeunit::"Create Exp. SubCategories DK");
        Codeunit.Run(Codeunit::"Create Exp. Rule Header DK");
        Codeunit.Run(Codeunit::"Create Exp. Rule Condition DK");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        ExpDemoDataSubscriberDK: Codeunit "Exp. Demo Data Subscriber DK";
    begin
        BindSubscription(ExpDemoDataSubscriberDK);

        CreateExpenseCountryDataW1.CreateTransactionalData();
        Codeunit.Run(Codeunit::"Create Expense DK");

        UnbindSubscription(ExpDemoDataSubscriberDK);
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        ExpDemoDataSubscriberDK: Codeunit "Exp. Demo Data Subscriber DK";
        CreatePostedExpReportDK: Codeunit "Create Posted Exp. Report DK";
    begin
        BindSubscription(ExpDemoDataSubscriberDK);
        BindSubscription(CreatePostedExpReportDK);

        CreateExpenseCountryDataW1.CreateHistoricalData();
        Codeunit.Run(Codeunit::"Create Posted Exp. Report DK");

        UnbindSubscription(CreatePostedExpReportDK);
        UnbindSubscription(ExpDemoDataSubscriberDK);
    end;
}
