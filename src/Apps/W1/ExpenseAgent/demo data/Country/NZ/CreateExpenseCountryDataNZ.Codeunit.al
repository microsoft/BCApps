// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8255 "Create Expense Country Data NZ" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreateExpGLAccountNZ: Codeunit "Create Exp. GL Account NZ";
        CreateExpPostingGrpNZ: Codeunit "Create Exp. Posting Grp NZ";
    begin
        BindSubscription(CreateExpGLAccountNZ);
        BindSubscription(CreateExpPostingGrpNZ);

        CreateExpenseCountryDataW1.CreateSetupData();
        Codeunit.Run(Codeunit::"Update Emp. Posting Grp NZ");
        Codeunit.Run(Codeunit::"Create Exp. Posting Grp NZ");

        UnbindSubscription(CreateExpPostingGrpNZ);
        UnbindSubscription(CreateExpGLAccountNZ);
    end;

    procedure CreateMasterData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateMasterData();
        Codeunit.Run(Codeunit::"Create Exp. Categories NZ");
        Codeunit.Run(Codeunit::"Create Exp. SubCategories NZ");
        Codeunit.Run(Codeunit::"Create Exp. Rule Header NZ");
        Codeunit.Run(Codeunit::"Create Exp. Rule Condition NZ");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateTransactionalData();
        Codeunit.Run(Codeunit::"Create Expense NZ");
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreatePostedExpReportNZ: Codeunit "Create Posted Exp. Report NZ";
    begin
        BindSubscription(CreatePostedExpReportNZ);

        CreateExpenseCountryDataW1.CreateHistoricalData();
        Codeunit.Run(Codeunit::"Create Posted Exp. Report NZ");

        UnbindSubscription(CreatePostedExpReportNZ);
    end;
}
