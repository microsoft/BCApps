// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8484 "Expense GL Account Names CZ"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        BankAccountKBTok: Label 'Bank Account - KB', MaxLength = 100;
        PayablesToEmployeesTok: Label 'Payables to employees', MaxLength = 100;
        TravelExpensesTok: Label 'Travel expenses', MaxLength = 100;
        RepresentationCostsTok: Label 'Representation costs', MaxLength = 100;
        OtherOperatingExpensesTok: Label 'Other operating expenses', MaxLength = 100;
        SalesGoodsDomesticTok: Label 'Sales goods - domestic', MaxLength = 100;

    procedure BankAccountKBName(): Text[100]
    begin
        exit(BankAccountKBTok);
    end;

    procedure PayablesToEmployeesName(): Text[100]
    begin
        exit(PayablesToEmployeesTok);
    end;

    procedure TravelExpensesName(): Text[100]
    begin
        exit(TravelExpensesTok);
    end;

    procedure RepresentationCostsName(): Text[100]
    begin
        exit(RepresentationCostsTok);
    end;

    procedure OtherOperatingExpensesName(): Text[100]
    begin
        exit(OtherOperatingExpensesTok);
    end;

    procedure SalesGoodsDomesticName(): Text[100]
    begin
        exit(SalesGoodsDomesticTok);
    end;
}
