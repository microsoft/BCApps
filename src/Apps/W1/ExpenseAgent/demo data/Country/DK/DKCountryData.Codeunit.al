// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8288 "DK Country Data" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        DKExpGLAccount: Codeunit "DK Exp. GL Account";
        DKExpPostingGrp: Codeunit "DK Exp. Posting Grp";
    begin
        BindSubscription(DKExpGLAccount);
        BindSubscription(DKExpPostingGrp);

        W1CountryData.CreateSetupData();
        Codeunit.Run(Codeunit::"DK Upd. Emp. Posting Grp");
        Codeunit.Run(Codeunit::"DK Exp. Posting Grp");

        UnbindSubscription(DKExpPostingGrp);
        UnbindSubscription(DKExpGLAccount);
    end;

    procedure CreateMasterData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateMasterData();
        Codeunit.Run(Codeunit::"DK Exp. Categories");
        Codeunit.Run(Codeunit::"DK Exp. SubCategories");
        Codeunit.Run(Codeunit::"DK Exp. Rule Header");
        Codeunit.Run(Codeunit::"DK Exp. Rule Condition");
    end;

    procedure CreateTransactionalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateTransactionalData();
        Codeunit.Run(Codeunit::"DK Expense");
    end;

    procedure CreateHistoricalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        DKCurrencySwapSub: Codeunit "DK Currency Swap Sub";
        DKPostedExpReport: Codeunit "DK Posted Exp. Report";
    begin
        BindSubscription(DKCurrencySwapSub);
        BindSubscription(DKPostedExpReport);

        W1CountryData.CreateHistoricalData();
        Codeunit.Run(Codeunit::"DK Posted Exp. Report");

        UnbindSubscription(DKPostedExpReport);
        UnbindSubscription(DKCurrencySwapSub);
    end;
}
