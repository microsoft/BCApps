// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8234 "GB Country Data" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        GBExpGLAccount: Codeunit "GB Exp. GL Account";
        GBExpPostingGrp: Codeunit "GB Exp. Posting Grp";
    begin
        BindSubscription(GBExpGLAccount);
        BindSubscription(GBExpPostingGrp);

        W1CountryData.CreateSetupData();
        Codeunit.Run(Codeunit::"GB Upd. Emp. Posting Grp");
        Codeunit.Run(Codeunit::"GB Exp. Posting Grp");

        UnbindSubscription(GBExpPostingGrp);
        UnbindSubscription(GBExpGLAccount);
    end;

    procedure CreateMasterData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateMasterData();
        Codeunit.Run(Codeunit::"GB Exp. Categories");
        Codeunit.Run(Codeunit::"GB Exp. SubCategories");
        Codeunit.Run(Codeunit::"GB Exp. Rule Header");
        Codeunit.Run(Codeunit::"GB Exp. Rule Condition");
    end;

    procedure CreateTransactionalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateTransactionalData();
        Codeunit.Run(Codeunit::"GB Expense");
    end;

    procedure CreateHistoricalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        GBPostedExpReport: Codeunit "GB Posted Exp. Report";
    begin
        BindSubscription(GBPostedExpReport);

        W1CountryData.CreateHistoricalData();
        Codeunit.Run(Codeunit::"GB Posted Exp. Report");

        UnbindSubscription(GBPostedExpReport);
    end;
}
