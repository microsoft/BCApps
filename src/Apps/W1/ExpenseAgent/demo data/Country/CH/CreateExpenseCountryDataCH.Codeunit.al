// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8434 "Create Expense Country Data CH" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreateExpGLAccountCH: Codeunit "Create Exp. GL Account CH";
        CreateExpPostingGrpCH: Codeunit "Create Exp. Posting Grp CH";
    begin
        BindSubscription(CreateExpGLAccountCH);
        BindSubscription(CreateExpPostingGrpCH);

        CreateExpenseCountryDataW1.CreateSetupData();
        Codeunit.Run(Codeunit::"Update Emp. Posting Grp CH");
        Codeunit.Run(Codeunit::"Create Exp. Posting Grp CH");

        UnbindSubscription(CreateExpPostingGrpCH);
        UnbindSubscription(CreateExpGLAccountCH);
    end;

    procedure CreateMasterData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateMasterData();
        Codeunit.Run(Codeunit::"Create Exp. Categories CH");
        Codeunit.Run(Codeunit::"Create Exp. SubCategories CH");
        Codeunit.Run(Codeunit::"Create Exp. Rule Header CH");
        Codeunit.Run(Codeunit::"Create Exp. Rule Condition CH");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateTransactionalData();
        Codeunit.Run(Codeunit::"Create Expense CH");
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreatePostedExpReportCH: Codeunit "Create Posted Exp. Report CH";
    begin
        BindSubscription(CreatePostedExpReportCH);

        CreateExpenseCountryDataW1.CreateHistoricalData();
        Codeunit.Run(Codeunit::"Create Posted Exp. Report CH");

        UnbindSubscription(CreatePostedExpReportCH);
    end;
}
