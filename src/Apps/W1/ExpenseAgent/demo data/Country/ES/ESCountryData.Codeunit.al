// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8275 "ES Country Data" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        ESExpGLAccount: Codeunit "ES Exp. GL Account";
        ESExpPostingGrp: Codeunit "ES Exp. Posting Grp";
    begin
        BindSubscription(ESExpGLAccount);
        BindSubscription(ESExpPostingGrp);

        W1CountryData.CreateSetupData();
        Codeunit.Run(Codeunit::"ES Upd. Employee");
        Codeunit.Run(Codeunit::"ES Upd. Emp. Posting Grp");
        Codeunit.Run(Codeunit::"ES Exp. Posting Grp");

        UnbindSubscription(ESExpPostingGrp);
        UnbindSubscription(ESExpGLAccount);
    end;

    procedure CreateMasterData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateMasterData();
        Codeunit.Run(Codeunit::"ES Exp. Categories");
        Codeunit.Run(Codeunit::"ES Exp. SubCategories");
        Codeunit.Run(Codeunit::"ES Exp. Rule Header");
        Codeunit.Run(Codeunit::"ES Exp. Rule Condition");
    end;

    procedure CreateTransactionalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        ESCurrencySwapSub: Codeunit "ES Currency Swap Sub";
    begin
        BindSubscription(ESCurrencySwapSub);

        W1CountryData.CreateTransactionalData();
        Codeunit.Run(Codeunit::"ES Expense");

        UnbindSubscription(ESCurrencySwapSub);
    end;

    procedure CreateHistoricalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        ESCurrencySwapSub: Codeunit "ES Currency Swap Sub";
        ESPostedExpReport: Codeunit "ES Posted Exp. Report";
    begin
        BindSubscription(ESCurrencySwapSub);
        BindSubscription(ESPostedExpReport);

        W1CountryData.CreateHistoricalData();
        Codeunit.Run(Codeunit::"ES Posted Exp. Report");

        UnbindSubscription(ESPostedExpReport);
        UnbindSubscription(ESCurrencySwapSub);
    end;
}
