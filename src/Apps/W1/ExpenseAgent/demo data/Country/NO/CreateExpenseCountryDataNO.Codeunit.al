// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8445 "Create Expense Country Data NO" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreateExpGLAccountNO: Codeunit "Create Exp. GL Account NO";
        CreateExpPostingGrpNO: Codeunit "Create Exp. Posting Grp NO";
    begin
        BindSubscription(CreateExpGLAccountNO);
        BindSubscription(CreateExpPostingGrpNO);

        CreateExpenseCountryDataW1.CreateSetupData();
        Codeunit.Run(Codeunit::"Update Emp. Posting Grp NO");
        Codeunit.Run(Codeunit::"Create Exp. Posting Grp NO");

        UnbindSubscription(CreateExpPostingGrpNO);
        UnbindSubscription(CreateExpGLAccountNO);
    end;

    procedure CreateMasterData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateMasterData();
        Codeunit.Run(Codeunit::"Create Exp. Categories NO");
        Codeunit.Run(Codeunit::"Create Exp. SubCategories NO");
        Codeunit.Run(Codeunit::"Create Exp. Rule Header NO");
        Codeunit.Run(Codeunit::"Create Exp. Rule Condition NO");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateTransactionalData();
        Codeunit.Run(Codeunit::"Create Expense NO");
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreatePostedExpReportNO: Codeunit "Create Posted Exp. Report NO";
    begin
        BindSubscription(CreatePostedExpReportNO);

        CreateExpenseCountryDataW1.CreateHistoricalData();
        Codeunit.Run(Codeunit::"Create Posted Exp. Report NO");

        UnbindSubscription(CreatePostedExpReportNO);
    end;
}
