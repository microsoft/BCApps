// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.CRM.Campaign;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;

report 7051 "Suggest Item Price on Wksh."
{
    Caption = 'Suggest Item Price on Wksh.';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Vendor No.", "Inventory Posting Group";

            trigger OnAfterGetRecord()
            var
                CurrentUnitPrice: Decimal;
            begin
                Window.Update(1, "No.");
                SalesPriceWksh.Init();
                SalesPriceWksh.Validate("Item No.", Item."No.");

                if not (SalesPriceWksh."Unit of Measure Code" in [Item."Base Unit of Measure", '']) then
                    if not ItemUnitOfMeasure.Get(SalesPriceWksh."Item No.", SalesPriceWksh."Unit of Measure Code") then
                        CurrReport.Skip();

                SalesPriceWksh.Validate("Unit of Measure Code", ToUnitofMeasure.Code);
                CurrentUnitPrice :=
                  Round(
                    CurrExchRate.ExchangeAmtLCYToFCY(
                      WorkDate(), ToCurrency.Code,
                      Item."Unit Price",
                      CurrExchRate.ExchangeRate(
                        WorkDate(), ToCurrency.Code)) *
                    UOMMgt.GetQtyPerUnitOfMeasure(Item, SalesPriceWksh."Unit of Measure Code"),
                    ToCurrency."Unit-Amount Rounding Precision");

                if CurrentUnitPrice > PriceLowerLimit then
                    SalesPriceWksh."New Unit Price" := CurrentUnitPrice * UnitPriceFactor;

                OnBeforeRoundMethod(SalesPriceWksh, Item, ToCurrency, UnitPriceFactor, PriceLowerLimit, CurrentUnitPrice);

                if RoundingMethod.Code <> '' then begin
                    RoundingMethod."Minimum Amount" := SalesPriceWksh."New Unit Price";
                    if RoundingMethod.Find('=<') then begin
                        SalesPriceWksh."New Unit Price" := SalesPriceWksh."New Unit Price" + RoundingMethod."Amount Added Before";
                        if RoundingMethod.Precision > 0 then
                            SalesPriceWksh."New Unit Price" :=
                              Round(
                                SalesPriceWksh."New Unit Price",
                                RoundingMethod.Precision, CopyStr('=><', RoundingMethod.Type + 1, 1));
                        SalesPriceWksh."New Unit Price" := SalesPriceWksh."New Unit Price" + RoundingMethod."Amount Added After";
                    end;
                end;

                SalesPriceWksh.CalcCurrentPrice(PriceAlreadyExists);

                if not PriceAlreadyExists then begin
                    SalesPriceWksh."Current Unit Price" := CurrentUnitPrice;
                    SalesPriceWksh."VAT Bus. Posting Gr. (Price)" := Item."VAT Bus. Posting Gr. (Price)";
                end;

                OnBeforeModifyOrInsertSalesPriceWksh(SalesPriceWksh);

                if PriceAlreadyExists or CreateNewPrices then begin
                    SalesPriceWksh2 := SalesPriceWksh;
                    if SalesPriceWksh2.Find('=') then
                        SalesPriceWksh.Modify()
                    else
                        SalesPriceWksh.Insert();
                end;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text000);
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
                    group("Copy to Sales Price Worksheet...")
                    {
                        Caption = 'Copy to Sales Price Worksheet...';
                        field(ToSalesType; ToSalesType)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Sales Type';
                            ToolTip = 'Specifies the sales type for the sales price agreement. To see the existing sales types, click the field.';

                            trigger OnValidate()
                            begin
                                SalesCodeCtrlEnable := ToSalesType <> ToSalesType::"All Customers";
                                ToStartDateCtrlEnable := ToSalesType <> ToSalesType::Campaign;
                                ToEndDateCtrlEnable := ToSalesType <> ToSalesType::Campaign;

                                ToSalesCode := '';
                                ToStartDate := 0D;
                                ToEndDate := 0D;
                            end;
                        }
                        field(SalesCodeCtrl; ToSalesCode)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Sales Code';
                            Enabled = SalesCodeCtrlEnable;
                            ToolTip = 'Specifies the code for the sales type that the sales price agreement will update. To see the existing sales codes, click the field.';

                            trigger OnLookup(var Text: Text): Boolean
                            var
                                CustList: Page "Customer List";
                                CustPriceGrList: Page "Customer Price Groups";
                                CampaignList: Page "Campaign List";
                            begin
                                case ToSalesType of
                                    ToSalesType::Customer:
                                        begin
                                            CustList.LookupMode := true;
                                            CustList.SetRecord(ToCust);
                                            if CustList.RunModal() = ACTION::LookupOK then begin
                                                CustList.GetRecord(ToCust);
                                                ToSalesCode := ToCust."No.";
                                            end;
                                        end;
                                    ToSalesType::"Customer Price Group":
                                        begin
                                            CustPriceGrList.LookupMode := true;
                                            CustPriceGrList.SetRecord(ToCustPriceGr);
                                            if CustPriceGrList.RunModal() = ACTION::LookupOK then begin
                                                CustPriceGrList.GetRecord(ToCustPriceGr);
                                                ToSalesCode := ToCustPriceGr.Code;
                                            end;
                                        end;
                                    ToSalesType::Campaign:
                                        begin
                                            CampaignList.LookupMode := true;
                                            CampaignList.SetRecord(ToCampaign);
                                            if CampaignList.RunModal() = ACTION::LookupOK then begin
                                                CampaignList.GetRecord(ToCampaign);
                                                ToSalesCode := ToCampaign."No.";
                                                ToStartDate := ToCampaign."Starting Date";
                                                ToEndDate := ToCampaign."Ending Date";
                                            end;
                                        end;
                                end;
                            end;

                            trigger OnValidate()
                            begin
                                ToSalesCodeOnAfterValidate();
                            end;
                        }
                        field("ToUnitofMeasure.Code"; ToUnitofMeasure.Code)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Unit of Measure Code';
                            TableRelation = "Unit of Measure";
                            ToolTip = 'Specifies the unit of measure that the item is shown in.';
                        }
                        field("ToCurrency.Code"; ToCurrency.Code)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Currency Code';
                            TableRelation = Currency;
                            ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                        }
                        field(ToStartDateCtrl; ToStartDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Date';
                            Enabled = ToStartDateCtrlEnable;
                            ToolTip = 'Specifies the date when the price changes will take effect.';
                        }
                        field(ToEndDateCtrl; ToEndDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            Enabled = ToEndDateCtrlEnable;
                            ToolTip = 'Specifies the date to which the price changes are valid.';
                        }
                    }
                    field(PriceLowerLimit; PriceLowerLimit)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only Amounts Above';
                        DecimalPlaces = 2 : 5;
                        ToolTip = 'Specifies the lowest unit price that will be changed. Only prices that are higher than this price will be changed.';
                    }
                    field(UnitPriceFactor; UnitPriceFactor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjustment Factor';
                        DecimalPlaces = 0 : 5;
                        MinValue = 0;
                        ToolTip = 'Specifies an adjustment factor to multiply the item price that you want suggested. By entering an adjustment factor, you can increase or decrease the amounts that are suggested.';
                    }
                    field("RoundingMethod.Code"; RoundingMethod.Code)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Rounding Method';
                        TableRelation = "Rounding Method";
                        ToolTip = 'Specifies a code for the rounding method that you want applied to prices.';
                    }
                    field(CreateNewPrices; CreateNewPrices)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create New Prices';
                        ToolTip = 'Specifies if you want the batch job to create new price suggestions (for example, a new combination of currency, sales code and time). Don''t insert a check mark if you only want to adjust existing sales prices.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            ToEndDateCtrlEnable := true;
            ToStartDateCtrlEnable := true;
            SalesCodeCtrlEnable := true;
        end;

        trigger OnOpenPage()
        begin
            if UnitPriceFactor = 0 then
                UnitPriceFactor := 1;

            SalesCodeCtrlEnable := true;
            if ToSalesType = ToSalesType::"All Customers" then
                SalesCodeCtrlEnable := false;

            SalesCodeCtrlEnable := ToSalesType <> ToSalesType::"All Customers";
            ToStartDateCtrlEnable := ToSalesType <> ToSalesType::Campaign;
            ToEndDateCtrlEnable := ToSalesType <> ToSalesType::Campaign;
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

        if (ToSalesCode = '') and (ToSalesType <> ToSalesType::"All Customers") then
            Error(Text002, SalesPrice.FieldCaption("Sales Code"));

        if ToUnitofMeasure.Code <> '' then
            ToUnitofMeasure.Find();
        SalesPriceWksh.Validate("Sales Type", ToSalesType);
        SalesPriceWksh.Validate("Sales Code", ToSalesCode);
        SalesPriceWksh.Validate("Currency Code", ToCurrency.Code);
        SalesPriceWksh.Validate("Starting Date", ToStartDate);
        SalesPriceWksh.Validate("Ending Date", ToEndDate);
        SalesPriceWksh."Unit of Measure Code" := ToUnitofMeasure.Code;

        case ToSalesType of
            ToSalesType::Customer:
                begin
                    ToCust."No." := ToSalesCode;
                    ToCust.Find();
                    SalesPriceWksh."Price Includes VAT" := ToCust."Prices Including VAT";
                    SalesPriceWksh."Allow Line Disc." := ToCust."Allow Line Disc.";
                end;
            ToSalesType::"Customer Price Group":
                begin
                    ToCustPriceGr.Code := ToSalesCode;
                    ToCustPriceGr.Find();
                    SalesPriceWksh."Price Includes VAT" := ToCustPriceGr."Price Includes VAT";
                    SalesPriceWksh."Allow Line Disc." := ToCustPriceGr."Allow Line Disc.";
                    SalesPriceWksh."Allow Invoice Disc." := ToCustPriceGr."Allow Invoice Disc.";
                end;
        end;
    end;

    var
        RoundingMethod: Record "Rounding Method";
        SalesPrice: Record "Sales Price";
        SalesPriceWksh2: Record "Sales Price Worksheet";
        SalesPriceWksh: Record "Sales Price Worksheet";
        ToCust: Record Customer;
        ToCustPriceGr: Record "Customer Price Group";
        ToCampaign: Record Campaign;
        ToCurrency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        ToUnitofMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        PriceAlreadyExists: Boolean;
        CreateNewPrices: Boolean;
        UnitPriceFactor: Decimal;
        PriceLowerLimit: Decimal;
        SalesCodeCtrlEnable: Boolean;
        ToStartDateCtrlEnable: Boolean;
        ToEndDateCtrlEnable: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Processing items  #1##########';
        Text002: Label '%1 must be specified.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        ToSalesType: Enum "Sales Price Type";
        ToSalesCode: Code[20];
        ToStartDate: Date;
        ToEndDate: Date;

    procedure InitializeRequest(NewToSalesType: Option; NewToSalesCode: Code[20]; NewToStartDateText: Date; NewToEndDateText: Date; NewToCurrCode: Code[10]; NewToUOMCode: Code[10])
    begin
        ToSalesType := "Sales Price Type".FromInteger(NewToSalesType);
        ToSalesCode := NewToSalesCode;
        ToStartDate := NewToStartDateText;
        ToEndDate := NewToEndDateText;
        ToCurrency.Code := NewToCurrCode;
        ToUnitofMeasure.Code := NewToUOMCode;
    end;

    local procedure ToSalesCodeOnAfterValidate()
    begin
        if ToSalesType = ToSalesType::Campaign then
            if ToCampaign.Get(ToSalesCode) then begin
                ToStartDate := ToCampaign."Starting Date";
                ToEndDate := ToCampaign."Ending Date";
            end else begin
                ToStartDate := 0D;
                ToEndDate := 0D;
            end;
    end;

    procedure InitializeRequest2(NewToSalesType: Option; NewToSalesCode: Code[20]; NewToStartDateText: Date; NewToEndDateText: Date; NewToCurrCode: Code[10]; NewToUOMCode: Code[10]; NewPriceLowerLimit: Decimal; NewUnitPriceFactor: Decimal; NewRoundingMethodCode: Code[10]; NewCreateNewPrices: Boolean)
    begin
        InitializeRequest(NewToSalesType, NewToSalesCode, NewToStartDateText, NewToEndDateText, NewToCurrCode, NewToUOMCode);
        PriceLowerLimit := NewPriceLowerLimit;
        UnitPriceFactor := NewUnitPriceFactor;
        RoundingMethod.Code := NewRoundingMethodCode;
        CreateNewPrices := NewCreateNewPrices;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundMethod(var SalesPriceWorksheet: Record "Sales Price Worksheet"; Item: Record Item; ToCurrency: Record Currency; UnitPriceFactor: Decimal; PriceLowerLimit: Decimal; var CurrentUnitPrice: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyOrInsertSalesPriceWksh(var SalesPriceWorksheet: Record "Sales Price Worksheet")
    begin
    end;
}
