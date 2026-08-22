// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8255 "NZ Country Data" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        NZExpGLAccount: Codeunit "NZ Exp. GL Account";
        NZExpPostingGrp: Codeunit "NZ Exp. Posting Grp";
    begin
        BindSubscription(NZExpGLAccount);
        BindSubscription(NZExpPostingGrp);

        W1CountryData.CreateSetupData();
        Codeunit.Run(Codeunit::"NZ Upd. Emp. Posting Grp");
        Codeunit.Run(Codeunit::"NZ Exp. Posting Grp");

        UnbindSubscription(NZExpPostingGrp);
        UnbindSubscription(NZExpGLAccount);
    end;

    procedure CreateMasterData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateMasterData();
        Codeunit.Run(Codeunit::"NZ Exp. Categories");
        Codeunit.Run(Codeunit::"NZ Exp. SubCategories");
        Codeunit.Run(Codeunit::"NZ Exp. Rule Header");
        Codeunit.Run(Codeunit::"NZ Exp. Rule Condition");
    end;

    procedure CreateTransactionalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateTransactionalData();
        Codeunit.Run(Codeunit::"NZ Expense");
    end;

    procedure CreateHistoricalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        NZPostedExpReport: Codeunit "NZ Posted Exp. Report";
    begin
        BindSubscription(NZPostedExpReport);

        W1CountryData.CreateHistoricalData();
        Codeunit.Run(Codeunit::"NZ Posted Exp. Report");

        UnbindSubscription(NZPostedExpReport);
    end;
}
