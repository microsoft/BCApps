// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8223 "Create Expense Country Data US" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreateExpGLAccountUS: Codeunit "Create Exp. GL Account US";
        CreateExpPostingGrpUS: Codeunit "Create Exp. Posting Grp US";
    begin
        BindSubscription(CreateExpGLAccountUS);
        BindSubscription(CreateExpPostingGrpUS);

        CreateExpenseCountryDataW1.CreateSetupData();
        Codeunit.Run(Codeunit::"Update Emp. Posting Grp US");
        Codeunit.Run(Codeunit::"Create Exp. Posting Grp US");

        UnbindSubscription(CreateExpPostingGrpUS);
        UnbindSubscription(CreateExpGLAccountUS);
    end;

    procedure CreateMasterData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateMasterData();
        Codeunit.Run(Codeunit::"Create Exp. Categories US");
        Codeunit.Run(Codeunit::"Create Exp. SubCategories US");
        Codeunit.Run(Codeunit::"Create Exp. Rule Header US");
        Codeunit.Run(Codeunit::"Create Exp. Rule Condition US");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
    begin
        CreateExpenseCountryDataW1.CreateTransactionalData();
        Codeunit.Run(Codeunit::"Create Expense US");
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryDataW1: Codeunit "Create Expense Country Data W1";
        CreatePostedExpReportUS: Codeunit "Create Posted Exp. Report US";
    begin
        BindSubscription(CreatePostedExpReportUS);

        CreateExpenseCountryDataW1.CreateHistoricalData();
        Codeunit.Run(Codeunit::"Create Posted Exp. Report US");

        UnbindSubscription(CreatePostedExpReportUS);
    end;
}
