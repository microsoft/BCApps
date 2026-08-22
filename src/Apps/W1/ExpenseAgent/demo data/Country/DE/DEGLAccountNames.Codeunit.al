// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8312 "DE GL Account Names"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        BusinessaccountOperatingDomesticTok: Label 'Business account, Operating, Domestic', MaxLength = 100;
        SaleofResourcesTok: Label 'Sale of Resource', MaxLength = 100;
        AssetsintheformofprepaidexpensesTok: Label 'Assets in the form of prepaid expenses', MaxLength = 100;
        SalesInvoiceRoundingTok: Label 'Sales Invoice Rounding', MaxLength = 100;
        BoardandlodgingTok: Label 'Board and lodging', MaxLength = 100;
        MiscexternalexpensesTok: Label 'Misc. external expenses', MaxLength = 100;
        OthertravelexpensesTok: Label 'Other travel expenses', MaxLength = 100;
        RentalvehiclesTok: Label 'Rental vehicles', MaxLength = 100;
        BusinessEntertainingdeductibleTok: Label 'Business Entertaining, deductible', MaxLength = 100;

    procedure BusinessaccountOperatingDomesticName(): Text[100]
    begin
        exit(BusinessaccountOperatingDomesticTok);
    end;

    procedure SaleofResourcesName(): Text[100]
    begin
        exit(SaleofResourcesTok);
    end;

    procedure AssetsintheformofprepaidexpensesName(): Text[100]
    begin
        exit(AssetsintheformofprepaidexpensesTok);
    end;

    procedure SalesInvoiceRoundingName(): Text[100]
    begin
        exit(SalesInvoiceRoundingTok);
    end;

    procedure BoardandlodgingName(): Text[100]
    begin
        exit(BoardandlodgingTok);
    end;

    procedure MiscexternalexpensesName(): Text[100]
    begin
        exit(MiscexternalexpensesTok);
    end;

    procedure OthertravelexpensesName(): Text[100]
    begin
        exit(OthertravelexpensesTok);
    end;

    procedure RentalvehiclesName(): Text[100]
    begin
        exit(RentalvehiclesTok);
    end;

    procedure BusinessEntertainingdeductibleName(): Text[100]
    begin
        exit(BusinessEntertainingdeductibleTok);
    end;
}
