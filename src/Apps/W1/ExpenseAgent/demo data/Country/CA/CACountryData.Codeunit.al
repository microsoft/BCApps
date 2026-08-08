// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8245 "CA Country Data" implements "Expense Agent Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateSetupData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        CAExpGLAccount: Codeunit "CA Exp. GL Account";
        CAExpPostingGrp: Codeunit "CA Exp. Posting Grp";
    begin
        BindSubscription(CAExpGLAccount);
        BindSubscription(CAExpPostingGrp);

        W1CountryData.CreateSetupData();
        Codeunit.Run(Codeunit::"CA Upd. Emp. Posting Grp");
        Codeunit.Run(Codeunit::"CA Exp. Posting Grp");

        UnbindSubscription(CAExpPostingGrp);
        UnbindSubscription(CAExpGLAccount);
    end;

    procedure CreateMasterData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateMasterData();
        Codeunit.Run(Codeunit::"CA Exp. Categories");
        Codeunit.Run(Codeunit::"CA Exp. SubCategories");
        Codeunit.Run(Codeunit::"CA Exp. Rule Header");
        Codeunit.Run(Codeunit::"CA Exp. Rule Condition");
    end;

    procedure CreateTransactionalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
    begin
        W1CountryData.CreateTransactionalData();
        Codeunit.Run(Codeunit::"CA Expense");
    end;

    procedure CreateHistoricalData()
    var
        W1CountryData: Codeunit "W1 Country Data";
        CAPostedExpReport: Codeunit "CA Posted Exp. Report";
    begin
        BindSubscription(CAPostedExpReport);

        W1CountryData.CreateHistoricalData();
        Codeunit.Run(Codeunit::"CA Posted Exp. Report");

        UnbindSubscription(CAPostedExpReport);
    end;
}
