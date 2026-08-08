// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8323 "AT Country Data" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        ATExpGLAccount: Codeunit "AT Exp. GL Account";
        ATExpPostingGrp: Codeunit "AT Exp. Posting Grp";
    begin
        BindSubscription(ATExpGLAccount);
        BindSubscription(ATExpPostingGrp);

        W1CountryData.CreateSetupData();
        Codeunit.Run(Codeunit::"AT Upd. Emp. Posting Grp");
        Codeunit.Run(Codeunit::"AT Exp. Posting Grp");

        UnbindSubscription(ATExpPostingGrp);
        UnbindSubscription(ATExpGLAccount);
    end;

    procedure CreateMasterData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateMasterData();
        Codeunit.Run(Codeunit::"AT Exp. Categories");
        Codeunit.Run(Codeunit::"AT Exp. SubCategories");
        Codeunit.Run(Codeunit::"AT Exp. Rule Header");
        Codeunit.Run(Codeunit::"AT Exp. Rule Condition");
    end;

    procedure CreateTransactionalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateTransactionalData();
        Codeunit.Run(Codeunit::"AT Expense");
    end;

    procedure CreateHistoricalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        ATCurrencySwapSub: Codeunit "AT Currency Swap Sub";
        ATPostedExpReport: Codeunit "AT Posted Exp. Report";
    begin
        BindSubscription(ATCurrencySwapSub);
        BindSubscription(ATPostedExpReport);

        W1CountryData.CreateHistoricalData();
        Codeunit.Run(Codeunit::"AT Posted Exp. Report");

        UnbindSubscription(ATPostedExpReport);
        UnbindSubscription(ATCurrencySwapSub);
    end;
}
