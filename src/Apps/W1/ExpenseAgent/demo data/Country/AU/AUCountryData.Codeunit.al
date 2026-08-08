// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8265 "AU Country Data" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        AUExpGLAccount: Codeunit "AU Exp. GL Account";
        AUExpPostingGrp: Codeunit "AU Exp. Posting Grp";
    begin
        BindSubscription(AUExpGLAccount);
        BindSubscription(AUExpPostingGrp);

        W1CountryData.CreateSetupData();
        Codeunit.Run(Codeunit::"AU Upd. Emp. Posting Grp");
        Codeunit.Run(Codeunit::"AU Exp. Posting Grp");

        UnbindSubscription(AUExpPostingGrp);
        UnbindSubscription(AUExpGLAccount);
    end;

    procedure CreateMasterData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateMasterData();
        Codeunit.Run(Codeunit::"AU Exp. Categories");
        Codeunit.Run(Codeunit::"AU Exp. SubCategories");
        Codeunit.Run(Codeunit::"AU Exp. Rule Header");
        Codeunit.Run(Codeunit::"AU Exp. Rule Condition");
    end;

    procedure CreateTransactionalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateTransactionalData();
        Codeunit.Run(Codeunit::"AU Expense");
    end;

    procedure CreateHistoricalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        AUPostedExpReport: Codeunit "AU Posted Exp. Report";
    begin
        BindSubscription(AUPostedExpReport);

        W1CountryData.CreateHistoricalData();
        Codeunit.Run(Codeunit::"AU Posted Exp. Report");

        UnbindSubscription(AUPostedExpReport);
    end;
}
