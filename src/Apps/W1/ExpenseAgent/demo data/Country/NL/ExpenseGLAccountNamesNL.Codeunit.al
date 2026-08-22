// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8478 "Expense GL Account Names NL"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CurrentReceivableFromEmployeesTok: Label 'Current Receivable from Employees', MaxLength = 100;
        CurrentLiabilitiesToEmployeesTok: Label 'Current Liabilities to Employees', MaxLength = 100;
        BoardAndLodgingTok: Label 'Board and lodging', MaxLength = 100;
        OtherTravelExpensesTok: Label 'Other travel expenses', MaxLength = 100;
        PayableInvoiceRoundingTok: Label 'Payable Invoice Rounding', MaxLength = 100;
        SaleofResourcesTok: Label 'Sale of Resources', MaxLength = 100;
        RentalVehiclesTok: Label 'Rental vehicles', MaxLength = 100;

    procedure CurrentReceivableFromEmployeesName(): Text[100]
    begin
        exit(CurrentReceivableFromEmployeesTok);
    end;

    procedure CurrentLiabilitiesToEmployeesName(): Text[100]
    begin
        exit(CurrentLiabilitiesToEmployeesTok);
    end;

    procedure BoardAndLodgingName(): Text[100]
    begin
        exit(BoardAndLodgingTok);
    end;

    procedure OtherTravelExpensesName(): Text[100]
    begin
        exit(OtherTravelExpensesTok);
    end;

    procedure PayableInvoiceRoundingName(): Text[100]
    begin
        exit(PayableInvoiceRoundingTok);
    end;

    procedure SaleofResourcesName(): Text[100]
    begin
        exit(SaleofResourcesTok);
    end;

    procedure RentalVehiclesName(): Text[100]
    begin
        exit(RentalVehiclesTok);
    end;
}
