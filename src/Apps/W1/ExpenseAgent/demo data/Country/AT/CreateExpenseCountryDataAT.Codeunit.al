// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8323 "Create Expense Country Data AT" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreateExpGLAccountAT: Codeunit "Create Exp. GL Account AT";
        CreateExpPostingGrpAT: Codeunit "Create Exp. Posting Grp AT";
    begin
        BindSubscription(CreateExpGLAccountAT);
        BindSubscription(CreateExpPostingGrpAT);

        CreateExpenseCountryDataW1.CreateSetupData();
        Codeunit.Run(Codeunit::"Update Emp. Posting Grp AT");
        Codeunit.Run(Codeunit::"Create Exp. Posting Grp AT");

        UnbindSubscription(CreateExpPostingGrpAT);
        UnbindSubscription(CreateExpGLAccountAT);
    end;

    procedure CreateMasterData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateMasterData();
        Codeunit.Run(Codeunit::"Create Exp. Categories AT");
        Codeunit.Run(Codeunit::"Create Exp. SubCategories AT");
        Codeunit.Run(Codeunit::"Create Exp. Rule Header AT");
        Codeunit.Run(Codeunit::"Create Exp. Rule Condition AT");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateTransactionalData();
        Codeunit.Run(Codeunit::"Create Expense AT");
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        ExpDemoDataSubscriberAT: Codeunit "Exp. Demo Data Subscriber AT";
        CreatePostedExpReportAT: Codeunit "Create Posted Exp. Report AT";
    begin
        BindSubscription(ExpDemoDataSubscriberAT);
        BindSubscription(CreatePostedExpReportAT);

        CreateExpenseCountryDataW1.CreateHistoricalData();
        Codeunit.Run(Codeunit::"Create Posted Exp. Report AT");

        UnbindSubscription(CreatePostedExpReportAT);
        UnbindSubscription(ExpDemoDataSubscriberAT);
    end;
}
