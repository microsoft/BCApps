// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8300 "FR Country Data" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        FRExpGLAccount: Codeunit "FR Exp. GL Account";
        FRExpPostingGrp: Codeunit "FR Exp. Posting Grp";
    begin
        BindSubscription(FRExpGLAccount);
        BindSubscription(FRExpPostingGrp);

        W1CountryData.CreateSetupData();
        Codeunit.Run(Codeunit::"FR Upd. Emp. Posting Grp");
        Codeunit.Run(Codeunit::"FR Exp. Posting Grp");

        UnbindSubscription(FRExpPostingGrp);
        UnbindSubscription(FRExpGLAccount);
    end;

    procedure CreateMasterData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateMasterData();
        Codeunit.Run(Codeunit::"FR Exp. Categories");
        Codeunit.Run(Codeunit::"FR Exp. SubCategories");
        Codeunit.Run(Codeunit::"FR Exp. Rule Header");
        Codeunit.Run(Codeunit::"FR Exp. Rule Condition");
    end;

    procedure CreateTransactionalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateTransactionalData();
        Codeunit.Run(Codeunit::"FR Expense");
    end;

    procedure CreateHistoricalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        FRCurrencySwapSub: Codeunit "FR Currency Swap Sub";
        FRPostedExpReport: Codeunit "FR Posted Exp. Report";
    begin
        BindSubscription(FRCurrencySwapSub);
        BindSubscription(FRPostedExpReport);

        W1CountryData.CreateHistoricalData();
        Codeunit.Run(Codeunit::"FR Posted Exp. Report");

        UnbindSubscription(FRPostedExpReport);
        UnbindSubscription(FRCurrencySwapSub);
    end;
}
