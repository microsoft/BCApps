// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8482 "Expense GL Account Names NO"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TravelTok: Label 'Travel', MaxLength = 100;
        EntertainmentDeductibleTok: Label 'Entertainment, Deductible', MaxLength = 100;
        CarAllowanceTok: Label 'Car Allowance', MaxLength = 100;
        AdministrativeExpensesTok: Label 'Administrative Expenses', MaxLength = 100;
        SubsistenceTok: Label 'Subsitence', MaxLength = 100;
        SalesOtherJobExpensesTok: Label 'Sales, Other Job Expenses', MaxLength = 100;

    procedure TravelName(): Text[100]
    begin
        exit(TravelTok);
    end;

    procedure EntertainmentDeductibleName(): Text[100]
    begin
        exit(EntertainmentDeductibleTok);
    end;

    procedure CarAllowanceName(): Text[100]
    begin
        exit(CarAllowanceTok);
    end;

    procedure AdministrativeExpensesName(): Text[100]
    begin
        exit(AdministrativeExpensesTok);
    end;

    procedure SubsistenceName(): Text[100]
    begin
        exit(SubsistenceTok);
    end;

    procedure SalesOtherJobExpensesName(): Text[100]
    begin
        exit(SalesOtherJobExpensesTok);
    end;
}
