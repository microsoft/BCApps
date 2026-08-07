// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8311 "DE Country Data" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        DEExpGLAccount: Codeunit "DE Exp. GL Account";
        DEExpPostingGrp: Codeunit "DE Exp. Posting Grp";
    begin
        BindSubscription(DEExpGLAccount);
        BindSubscription(DEExpPostingGrp);

        W1CountryData.CreateSetupData();
        Codeunit.Run(Codeunit::"DE Upd. Emp. Posting Grp");
        Codeunit.Run(Codeunit::"DE Exp. Posting Grp");

        UnbindSubscription(DEExpPostingGrp);
        UnbindSubscription(DEExpGLAccount);
    end;

    procedure CreateMasterData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateMasterData();
        Codeunit.Run(Codeunit::"DE Exp. Categories");
        Codeunit.Run(Codeunit::"DE Exp. SubCategories");
        Codeunit.Run(Codeunit::"DE Exp. Rule Header");
        Codeunit.Run(Codeunit::"DE Exp. Rule Condition");
    end;

    procedure CreateTransactionalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateTransactionalData();
        Codeunit.Run(Codeunit::"DE Expense");
    end;

    procedure CreateHistoricalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        DECurrencySwapSub: Codeunit "DE Currency Swap Sub";
        DEPostedExpReport: Codeunit "DE Posted Exp. Report";
    begin
        BindSubscription(DECurrencySwapSub);
        BindSubscription(DEPostedExpReport);

        W1CountryData.CreateHistoricalData();
        Codeunit.Run(Codeunit::"DE Posted Exp. Report");

        UnbindSubscription(DEPostedExpReport);
        UnbindSubscription(DECurrencySwapSub);
    end;
}
