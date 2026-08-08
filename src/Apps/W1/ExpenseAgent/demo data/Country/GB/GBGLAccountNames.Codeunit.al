// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8235 "GB GL Account Names"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        BusinessEntertainingDeductibleTok: Label 'Business Entertaining, deductible', MaxLength = 100;
        OtherIncidentalRevenueTok: Label 'Other Incidental Revenue', MaxLength = 100;
        OtherPrepaidExpensesAndAccruedIncomeTok: Label 'Other prepaid expenses and accrued income', MaxLength = 100;
        PayableInvoiceRoundingTok: Label 'Payable Invoice Rounding', MaxLength = 100;
        MiscExternalExpensesTok: Label 'Misc. external expenses', MaxLength = 100;
        OtherTravelExpensesTok: Label 'Other travel expenses', MaxLength = 100;
        RentalVehiclesTok: Label 'Rental vehicles', MaxLength = 100;
        OtherBankAccountsTok: Label 'Other bank accounts ', MaxLength = 100;
        SaleofResourcesTok: Label 'Sale of Resources', MaxLength = 100;

    procedure BusinessEntertainingDeductibleName(): Text[100]
    begin
        exit(BusinessEntertainingDeductibleTok);
    end;

    procedure OtherIncidentalRevenueName(): Text[100]
    begin
        exit(OtherIncidentalRevenueTok);
    end;

    procedure OtherPrepaidExpensesAndAccruedIncomeName(): Text[100]
    begin
        exit(OtherPrepaidExpensesAndAccruedIncomeTok);
    end;

    procedure PayableInvoiceRoundingName(): Text[100]
    begin
        exit(PayableInvoiceRoundingTok);
    end;

    procedure MiscExternalExpensesName(): Text[100]
    begin
        exit(MiscExternalExpensesTok);
    end;

    procedure OtherTravelExpensesName(): Text[100]
    begin
        exit(OtherTravelExpensesTok);
    end;

    procedure RentalVehiclesName(): Text[100]
    begin
        exit(RentalVehiclesTok);
    end;

    procedure OtherBankAccountsName(): Text[100]
    begin
        exit(OtherBankAccountsTok);
    end;

    procedure SaleofResourcesName(): Text[100]
    begin
        exit(SaleofResourcesTok);
    end;
}
