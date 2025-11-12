// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Finance.Currency;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Utilities;

report 1191 "Suggest Res. Price Chg. (Res.)"
{
    Caption = 'Suggest Res. Price Chg. (Res.)';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Resource; Resource)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Resource Group No.";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
                ResPriceChg.Type := ResPriceChg.Type::Resource;
                ResPriceChg.Code := Resource."No.";
                ResPriceChg."New Unit Price" :=
                  Round(
                    CurrExchRate.ExchangeAmtLCYToFCY(
                      WorkDate(), ToCurrency.Code,
                      Resource."Unit Price",
                      CurrExchRate.ExchangeRate(
                        WorkDate(), ToCurrency.Code)),
                    ToCurrency."Unit-Amount Rounding Precision");

                if ResPriceChg."New Unit Price" > PriceLowerLimit then
                    ResPriceChg."New Unit Price" := ResPriceChg."New Unit Price" * UnitPriceFactor;
                if RoundingMethod.Code <> '' then begin
                    RoundingMethod."Minimum Amount" := ResPriceChg."New Unit Price";
                    if RoundingMethod.Find('=<') then begin
                        ResPriceChg."New Unit Price" := ResPriceChg."New Unit Price" + RoundingMethod."Amount Added Before";

                        if RoundingMethod.Precision > 0 then
                            ResPriceChg."New Unit Price" :=
                              Round(
                                ResPriceChg."New Unit Price",
                                RoundingMethod.Precision, CopyStr('=><', RoundingMethod.Type + 1, 1));
                        ResPriceChg."New Unit Price" := ResPriceChg."New Unit Price" + RoundingMethod."Amount Added After";
                    end;
                end;

                ResPrice.SetRange(Type, ResPriceChg.Type);
                ResPrice.SetRange(Code, ResPriceChg.Code);
                ResPrice.SetRange("Currency Code", ToCurrency.Code);
                ResPrice.SetRange("Work Type Code", ToWorkType.Code);
                if ResPrice.FindLast() then begin
                    ResPriceChg."Current Unit Price" := ResPrice."Unit Price";
                    PriceAlreadyExists := true
                end else begin
                    ResPriceChg."Current Unit Price" := 0;
                    PriceAlreadyExists := false;
                end;

                if PriceAlreadyExists or CreateNewPrices then begin
                    ResPriceChg2 := ResPriceChg;
                    if ResPriceChg2.Find('=') then
                        ResPriceChg.Modify()
                    else
                        ResPriceChg.Insert();
                end;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text000)
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Copy to Res. Price Change...")
                    {
                        Caption = 'Copy to Res. Price Change...';
                        field("ToCurrency.Code"; ToCurrency.Code)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Currency Code';
                            TableRelation = Currency;
                            ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                        }
                        field("ToWorkType.Code"; ToWorkType.Code)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Work Type';
                            TableRelation = "Work Type";
                            ToolTip = 'Specifies the work types to which the new prices apply. If you want the new price to be calculated for all work types, enter ALL.';
                        }
                    }
                    field(PriceLowerLimit; PriceLowerLimit)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Only Amounts Above';
                        DecimalPlaces = 2 : 5;
                        ToolTip = 'Specifies an amount to determine the lowest unit price that is changed. Only prices that are higher than this are changed. If a price is lower than or equal to this amount, a line for it is created in the Resource Price Changes window, but with the same unit price as on the resource card.';
                    }
                    field(UnitPriceFactor; UnitPriceFactor)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Adjustment Factor';
                        DecimalPlaces = 0 : 5;
                        MinValue = 0;
                        ToolTip = 'Specifies an adjustment factor to multiply the amounts that you want suggested. By entering an adjustment factor, you can increase or decrease the amounts that are suggested.';
                    }
                    field("RoundingMethod.Code"; RoundingMethod.Code)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Rounding Method';
                        TableRelation = "Rounding Method";
                        ToolTip = 'Specifies a code for the rounding method that you want to apply to costs or prices that you adjust.';
                    }
                    field(CreateNewPrices; CreateNewPrices)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Create New Prices';
                        ToolTip = 'Specifies if you want the batch job to create new price suggestions, such as a new combination of currency, project number, or work type. If you only want to adjust existing alternative prices, do not select.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if UnitPriceFactor = 0 then
                UnitPriceFactor := 1;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        RoundingMethod.SetRange(Code, RoundingMethod.Code);

        if ToCurrency.Code = '' then
            ToCurrency.InitRoundingPrecision()
        else begin
            ToCurrency.Find();
            ToCurrency.TestField("Unit-Amount Rounding Precision");
        end;

        ResPriceChg."Currency Code" := ToCurrency.Code;
        ResPriceChg."Work Type Code" := ToWorkType.Code;
    end;

    var
        RoundingMethod: Record "Rounding Method";
        ToCurrency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        ToWorkType: Record "Work Type";
        ResPriceChg2: Record "Resource Price Change";
        ResPriceChg: Record "Resource Price Change";
        ResPrice: Record "Resource Price";
        Window: Dialog;
        PriceAlreadyExists: Boolean;
        CreateNewPrices: Boolean;
        UnitPriceFactor: Decimal;
        PriceLowerLimit: Decimal;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Processing items  #1##########';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure InitializeCopyToResPrice(CurrencyCode: Code[10]; WorkTypeCode: Code[10])
    begin
        ToCurrency.Code := CurrencyCode;
        ToWorkType.Code := WorkTypeCode;
    end;

    procedure InitializeRequest(PriceLowerLimitFrom: Decimal; UnitPriceFactorFrom: Decimal; RoundingMethodCode: Code[10]; CreateNewPricesFrom: Boolean)
    begin
        PriceLowerLimit := PriceLowerLimitFrom;
        UnitPriceFactor := UnitPriceFactorFrom;
        RoundingMethod.Code := RoundingMethodCode;
        CreateNewPrices := CreateNewPricesFrom;
    end;
}
