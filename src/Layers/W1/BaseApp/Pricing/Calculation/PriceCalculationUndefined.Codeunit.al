// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

using Microsoft.Pricing.PriceList;

codeunit 7005 "Price Calculation - Undefined" implements "Price Calculation"
{
    var
        CurrPriceCalculationSetup: Record "Price Calculation Setup";
        CurrLineWithPrice: Interface "Line With Price";
        MissingPriceSetupErr: Label 'There is no active price calculation setup (default ones: %1) matching the line: Price Type = %2, TableNo = %3, Record content = %4',
            Comment = '%1 -  list of default setup records, %2 - price type value, %3 - table id, %4 - content of the line';

    local procedure ShowError()
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        SetupList: Text;
        Line: Variant;
    begin
        CurrLineWithPrice.GetLine(Line);
        PriceCalculationSetup.SetRange(Default);
        if PriceCalculationSetup.FindSet() then
            repeat
                SetupList += PriceCalculationSetup.Code + ';';
            until PriceCalculationSetup.Next() = 0;
        Error(MissingPriceSetupErr, SetupList, CurrLineWithPrice.GetPriceType(), CurrLineWithPrice.GetTableNo(), Format(Line));
    end;

    procedure GetLine(var Line: Variant)
    begin
        CurrLineWithPrice.GetLine(Line);
    end;

    procedure Init(LineWithPrice: Interface "Line With Price"; PriceCalculationSetup: Record "Price Calculation Setup")
    begin
        CurrLineWithPrice := LineWithPrice;
        CurrPriceCalculationSetup := PriceCalculationSetup;
    end;

    procedure ApplyDiscount()
    begin
        ShowError();
    end;

    procedure ApplyPrice(CalledByFieldNo: Integer)
    begin
        ShowError();
    end;

    procedure CountDiscount(ShowAll: Boolean) Result: Integer;
    begin
        ShowError();
    end;

    procedure CountPrice(ShowAll: Boolean) Result: Integer;
    begin
        ShowError();
    end;

    procedure FindDiscount(var TempPriceListLine: Record "Price List Line"; ShowAll: Boolean) Found: Boolean;
    begin
        ShowError();
    end;

    procedure FindPrice(var TempPriceListLine: Record "Price List Line"; ShowAll: Boolean) Found: Boolean;
    begin
        ShowError();
    end;

    procedure IsDiscountExists(ShowAll: Boolean) Result: Boolean;
    begin
        ShowError();
    end;

    procedure IsPriceExists(ShowAll: Boolean) Result: Boolean;
    begin
        ShowError();
    end;

    procedure PickDiscount()
    begin
        ShowError();
    end;

    procedure PickPrice()
    begin
        ShowError();
    end;

    procedure ShowPrices(var TempPriceListLine: Record "Price List Line")
    begin
        ShowError();
    end;
}