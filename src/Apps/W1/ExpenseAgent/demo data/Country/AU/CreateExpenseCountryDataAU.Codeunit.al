// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8265 "Create Expense Country Data AU" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreateExpGLAccountAU: Codeunit "Create Exp. GL Account AU";
        CreateExpPostingGrpAU: Codeunit "Create Exp. Posting Grp AU";
    begin
        BindSubscription(CreateExpGLAccountAU);
        BindSubscription(CreateExpPostingGrpAU);

        CreateExpenseCountryDataW1.CreateSetupData();
        Codeunit.Run(Codeunit::"Update Emp. Posting Grp AU");
        Codeunit.Run(Codeunit::"Create Exp. Posting Grp AU");

        UnbindSubscription(CreateExpPostingGrpAU);
        UnbindSubscription(CreateExpGLAccountAU);
    end;

    procedure CreateMasterData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateMasterData();
        Codeunit.Run(Codeunit::"Create Exp. Categories AU");
        Codeunit.Run(Codeunit::"Create Exp. SubCategories AU");
        Codeunit.Run(Codeunit::"Create Exp. Rule Header AU");
        Codeunit.Run(Codeunit::"Create Exp. Rule Condition AU");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateTransactionalData();
        Codeunit.Run(Codeunit::"Create Expense AU");
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreatePostedExpReportAU: Codeunit "Create Posted Exp. Report AU";
    begin
        BindSubscription(CreatePostedExpReportAU);

        CreateExpenseCountryDataW1.CreateHistoricalData();
        Codeunit.Run(Codeunit::"Create Posted Exp. Report AU");

        UnbindSubscription(CreatePostedExpReportAU);
    end;
}
