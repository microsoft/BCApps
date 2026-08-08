// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8223 "US Country Data" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        USExpGLAccount: Codeunit "US Exp. GL Account";
        USExpPostingGrp: Codeunit "US Exp. Posting Grp";
    begin
        BindSubscription(USExpGLAccount);
        BindSubscription(USExpPostingGrp);

        W1CountryData.CreateSetupData();
        Codeunit.Run(Codeunit::"US Upd. Emp. Posting Grp");
        Codeunit.Run(Codeunit::"US Exp. Posting Grp");

        UnbindSubscription(USExpPostingGrp);
        UnbindSubscription(USExpGLAccount);
    end;

    procedure CreateMasterData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateMasterData();
        Codeunit.Run(Codeunit::"US Exp. Categories");
        Codeunit.Run(Codeunit::"US Exp. SubCategories");
        Codeunit.Run(Codeunit::"US Exp. Rule Header");
        Codeunit.Run(Codeunit::"US Exp. Rule Condition");
    end;

    procedure CreateTransactionalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateTransactionalData();
        Codeunit.Run(Codeunit::"US Expense");
    end;

    procedure CreateHistoricalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        USPostedExpReport: Codeunit "US Posted Exp. Report";
    begin
        BindSubscription(USPostedExpReport);

        W1CountryData.CreateHistoricalData();
        Codeunit.Run(Codeunit::"US Posted Exp. Report");

        UnbindSubscription(USPostedExpReport);
    end;
}
