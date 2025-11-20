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

report 7052 "Suggest Sales Price on Wksh."
{
    Caption = 'Suggest Sales Price on Wksh.';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Price"; "Sales Price")
        {
            DataItemTableView = sorting("Item No.");
            RequestFilterFields = "Sales Type", "Sales Code", "Item No.", "Currency Code", "Starting Date";

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
                SkipRecord: Boolean;
            begin
                if Item."No." <> "Item No." then begin
                    Item.Get("Item No.");
                    Window.Update(1, "Item No.");
                end;

                ReplaceSalesCode := not (("Sales Type" = ToSalesType) and ("Sales Code" = ToSalesCode));

                if (ToSalesCode = '') and (ToSalesType <> ToSalesType::"All Customers") then
                    Error(Text002, "Sales Type");

                SkipRecord := false;
                OnSalesPriceOnAfterGetRecordOnAfterCheck("Sales Price", Item, SkipRecord);
                if SkipRecord then
                    CurrReport.Skip();

                Clear(SalesPriceWksh);

                SalesPriceWksh.Validate("Sales Type", ToSalesType);
                if not ReplaceSalesCode then
                    SalesPriceWksh.Validate("Sales Code", "Sales Code")
                else
                    SalesPriceWksh.Validate("Sales Code", ToSalesCode);

                SalesPriceWksh.Validate("Item No.", "Item No.");
                SalesPriceWksh."New Unit Price" := "Unit Price";
                SalesPriceWksh."Minimum Quantity" := "Minimum Quantity";

                if not ReplaceUnitOfMeasure then
                    SalesPriceWksh."Unit of Measure Code" := "Unit of Measure Code"
                else begin
                    SalesPriceWksh."Unit of Measure Code" := ToUnitOfMeasure.Code;
                    if not (SalesPriceWksh."Unit of Measure Code" in ['', Item."Base Unit of Measure"]) then
                        if not ItemUnitOfMeasure.Get("Item No.", SalesPriceWksh."Unit of Measure Code") then
                            CurrReport.Skip();
                    SalesPriceWksh."New Unit Price" :=
                      SalesPriceWksh."New Unit Price" *
                      UOMMgt.GetQtyPerUnitOfMeasure(Item, SalesPriceWksh."Unit of Measure Code") /
                      UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                end;
                SalesPriceWksh.Validate("Unit of Measure Code");
                SalesPriceWksh.Validate("Variant Code", "Variant Code");

                if not ReplaceCurrency then
                    SalesPriceWksh."Currency Code" := "Currency Code"
                else
                    SalesPriceWksh."Currency Code" := ToCurrency.Code;

                if not ReplaceStartingDate then begin
                    if not ReplaceEndingDate then
                        SalesPriceWksh.Validate("Starting Date", "Starting Date")
                end else
                    SalesPriceWksh.Validate("Starting Date", ToStartDate);

                if not ReplaceEndingDate then begin
                    if not ReplaceStartingDate then
                        SalesPriceWksh.Validate("Ending Date", "Ending Date")
                end else
                    SalesPriceWksh.Validate("Ending Date", ToEndDate);

                if "Currency Code" <> SalesPriceWksh."Currency Code" then begin
                    if "Currency Code" <> '' then begin
                        FromCurrency.Get("Currency Code");
                        FromCurrency.TestField(Code);
                        SalesPriceWksh."New Unit Price" :=
                          CurrExchRate.ExchangeAmtFCYToLCY(
                            WorkDate(), "Currency Code", SalesPriceWksh."New Unit Price",
                            CurrExchRate.ExchangeRate(
                              WorkDate(), "Currency Code"));
                    end;
                    if SalesPriceWksh."Currency Code" <> '' then
                        SalesPriceWksh."New Unit Price" :=
                          CurrExchRate.ExchangeAmtLCYToFCY(
                            WorkDate(), SalesPriceWksh."Currency Code",
                            SalesPriceWksh."New Unit Price", CurrExchRate.ExchangeRate(
                              WorkDate(), SalesPriceWksh."Currency Code"));
                end;

                if SalesPriceWksh."Currency Code" = '' then
                    Currency2.InitRoundingPrecision()
                else begin
                    Currency2.Get(SalesPriceWksh."Currency Code");
                    Currency2.TestField("Unit-Amount Rounding Precision");
                end;
                SalesPriceWksh."New Unit Price" :=
                  Round(SalesPriceWksh."New Unit Price", Currency2."Unit-Amount Rounding Precision");

                IsHandled := false;
                OnBeforeSetNewUnitPriceAbovePriceLimit(SalesPriceWksh, PriceLowerLimit, IsHandled);
                if not IsHandled then
                    if SalesPriceWksh."New Unit Price" > PriceLowerLimit then
                        SalesPriceWksh."New Unit Price" := SalesPriceWksh."New Unit Price" * UnitPriceFactor;

                if RoundingMethod.Code <> '' then begin
                    RoundingMethod."Minimum Amount" := SalesPriceWksh."New Unit Price";
                    if RoundingMethod.Find('=<') then begin
                        SalesPriceWksh."New Unit Price" :=
                          SalesPriceWksh."New Unit Price" + RoundingMethod."Amount Added Before";
                        if RoundingMethod.Precision > 0 then
                            SalesPriceWksh."New Unit Price" :=
                              Round(
                                SalesPriceWksh."New Unit Price",
                                RoundingMethod.Precision, CopyStr('=><', RoundingMethod.Type + 1, 1));
                        SalesPriceWksh."New Unit Price" := SalesPriceWksh."New Unit Price" +
                          RoundingMethod."Amount Added After";
                    end;
                end;

                if ToSalesType = ToSalesType::"Customer Price Group" then begin
                    SalesPriceWksh."Price Includes VAT" := ToCustPriceGr."Price Includes VAT";
                    SalesPriceWksh."VAT Bus. Posting Gr. (Price)" := ToCustPriceGr."VAT Bus. Posting Gr. (Price)";
                    SalesPriceWksh."Allow Invoice Disc." := ToCustPriceGr."Allow Invoice Disc.";
                    SalesPriceWksh."Allow Line Disc." := ToCustPriceGr."Allow Line Disc.";
                end else begin
                    SalesPriceWksh."Price Includes VAT" := "Price Includes VAT";
                    SalesPriceWksh."VAT Bus. Posting Gr. (Price)" := "VAT Bus. Posting Gr. (Price)";
                    SalesPriceWksh."Allow Invoice Disc." := "Allow Invoice Disc.";
                    SalesPriceWksh."Allow Line Disc." := "Allow Line Disc.";
                end;
                SalesPriceWksh.CalcCurrentPrice(PriceAlreadyExists);

                OnBeforeModifyOrInsertSalesPriceWksh(
                    SalesPriceWksh, "Sales Price", UnitPriceFactor, PriceLowerLimit, RoundingMethod, CreateNewPrices);

                if PriceAlreadyExists or CreateNewPrices then begin
                    TempSalesPriceWksh := SalesPriceWksh;
                    if not TempSalesPriceWksh.Insert() then
                        Error(SalesPriceWkshLineExistsErr, TempSalesPriceWksh.RecordId);

                    SalesPriceWksh2 := SalesPriceWksh;
                    if SalesPriceWksh2.Find('=') then
                        SalesPriceWksh.Modify(true)
                    else
                        SalesPriceWksh.Insert(true);
                end;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text001);
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
                        field(SalesType; ToSalesType)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Sales Type';
                            ToolTip = 'Specifies the sales type that the sales price agreement will be copied to. To see the existing sales types, click the field.';

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
                            ToolTip = 'Specifies the code for the sales type that the sales prices will be copied to. To see the existing sales codes, click the field.';

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
                            var
                                Customer: Record Customer;
                                CustomerPriceGroup: Record "Customer Price Group";
                                Campaign: Record Campaign;
                            begin
                                if ToSalesType = ToSalesType::"All Customers" then
                                    exit;

                                case ToSalesType of
                                    ToSalesType::Customer:
                                        Customer.Get(ToSalesCode);
                                    ToSalesType::"Customer Price Group":
                                        CustomerPriceGroup.Get(ToSalesCode);
                                    ToSalesType::Campaign:
                                        begin
                                            Campaign.Get(ToSalesCode);
                                            ToStartDate := Campaign."Starting Date";
                                            ToEndDate := Campaign."Ending Date";
                                        end;
                                end;
                            end;
                        }
                        field(UnitOfMeasureCode; ToUnitOfMeasure.Code)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Unit of Measure Code';
                            TableRelation = "Unit of Measure";
                            ToolTip = 'Specifies the unit of measure that the item is shown in.';

                            trigger OnValidate()
                            begin
                                if ToUnitOfMeasure.Code <> '' then
                                    ToUnitOfMeasure.Find();
                            end;
                        }
                        field(CurrencyCode; ToCurrency.Code)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Currency Code';
                            TableRelation = Currency;
                            ToolTip = 'Specifies the code for the currency that amounts are shown in.';

                            trigger OnValidate()
                            begin
                                if ToCurrency.Code <> '' then
                                    ToCurrency.Find();
                            end;
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
                    field(OnlyPricesAbove; PriceLowerLimit)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only Prices Above';
                        DecimalPlaces = 2 : 5;
                        ToolTip = 'Specifies the code for the sales type that the sales prices will be copied to. To see the existing sales codes, click the field.';
                    }
                    field(AdjustmentFactor; UnitPriceFactor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjustment Factor';
                        DecimalPlaces = 0 : 5;
                        MinValue = 0;
                        ToolTip = 'Specifies an adjustment factor to multiply the sales price that you want suggested. By entering an adjustment factor, you can increase or decrease the amounts that are suggested.';
                    }
                    field(RoundingMethodCtrl; RoundingMethod.Code)
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
            if UnitPriceFactor = 0 then begin
                UnitPriceFactor := 1;
                ToCustPriceGr.Code := '';
                ToUnitOfMeasure.Code := '';
                ToCurrency.Code := '';
            end;

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
        case ToSalesType of
            ToSalesType::Customer:
                begin
                    ToCust."No." := ToSalesCode;
                    if ToCust."No." <> '' then
                        ToCust.Find()
                    else begin
                        if not ToCust.Find() then
                            ToCust.Init();
                        ToSalesCode := ToCust."No.";
                    end;
                end;
            ToSalesType::"Customer Price Group":
                begin
                    ToCustPriceGr.Code := ToSalesCode;
                    if ToCustPriceGr.Code <> '' then
                        ToCustPriceGr.Find()
                    else begin
                        if not ToCustPriceGr.Find() then
                            ToCustPriceGr.Init();
                        ToSalesCode := ToCustPriceGr.Code;
                    end;
                end;
            ToSalesType::Campaign:
                begin
                    ToCampaign."No." := ToSalesCode;
                    if ToCampaign."No." <> '' then
                        ToCampaign.Find()
                    else begin
                        if not ToCampaign.Find() then
                            ToCampaign.Init();
                        ToSalesCode := ToCampaign."No.";
                    end;
                    ToStartDate := ToCampaign."Starting Date";
                    ToEndDate := ToCampaign."Ending Date";
                end;
        end;

        ReplaceUnitOfMeasure := ToUnitOfMeasure.Code <> '';
        ReplaceCurrency := ToCurrency.Code <> '';
        ReplaceStartingDate := ToStartDate <> 0D;
        ReplaceEndingDate := ToEndDate <> 0D;

        if ReplaceUnitOfMeasure and (ToUnitOfMeasure.Code <> '') then
            ToUnitOfMeasure.Find();

        RoundingMethod.SetRange(Code, RoundingMethod.Code);
    end;

    trigger OnPostReport()
    begin
        OnAfterPostReport();
    end;

    var
        SalesPriceWksh2: Record "Sales Price Worksheet";
        SalesPriceWksh: Record "Sales Price Worksheet";
        TempSalesPriceWksh: Record "Sales Price Worksheet" temporary;
        ToCust: Record Customer;
        ToCustPriceGr: Record "Customer Price Group";
        ToCampaign: Record Campaign;
        ToUnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ToCurrency: Record Currency;
        FromCurrency: Record Currency;
        Currency2: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        RoundingMethod: Record "Rounding Method";
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        PriceAlreadyExists: Boolean;
        CreateNewPrices: Boolean;
        UnitPriceFactor: Decimal;
        PriceLowerLimit: Decimal;
        ToSalesType: Enum "Sales Price Type";
        ToSalesCode: Code[20];
        ToStartDate: Date;
        ToEndDate: Date;
        ReplaceSalesCode: Boolean;
        ReplaceUnitOfMeasure: Boolean;
        ReplaceCurrency: Boolean;
        ReplaceStartingDate: Boolean;
        ReplaceEndingDate: Boolean;
        SalesCodeCtrlEnable: Boolean;
        ToStartDateCtrlEnable: Boolean;
        ToEndDateCtrlEnable: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Processing items  #1##########';
        Text002: Label 'Sales Code must be specified when copying from %1 to All Customers.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        SalesPriceWkshLineExistsErr: Label 'There are multiple source lines for the record: %1.', Comment = '%1 = RecordId';

    procedure InitializeRequest(NewToSalesType: Option Customer,"Customer Price Group",Campaign,"All CUstomers"; NewToSalesCode: Code[20]; NewToStartDate: Date; NewToEndDate: Date; NewToCurrCode: Code[10]; NewToUOMCode: Code[10]; NewCreateNewPrices: Boolean)
    begin
        ToSalesType := "Sales Price Type".FromInteger(NewToSalesType);
        ToSalesCode := NewToSalesCode;
        ToStartDate := NewToStartDate;
        ToEndDate := NewToEndDate;
        ToCurrency.Code := NewToCurrCode;
        ToUnitOfMeasure.Code := NewToUOMCode;
        CreateNewPrices := NewCreateNewPrices;
    end;

    procedure InitializeRequest2(NewToSalesType: Option Customer,"Customer Price Group",Campaign,"All CUstomers"; NewToSalesCode: Code[20]; NewToStartDate: Date; NewToEndDate: Date; NewToCurrCode: Code[10]; NewToUOMCode: Code[10]; NewCreateNewPrices: Boolean; NewPriceLowerLimit: Decimal; NewUnitPriceFactor: Decimal; NewRoundingMethodCode: Code[10])
    begin
        InitializeRequest(NewToSalesType, NewToSalesCode, NewToStartDate, NewToEndDate, NewToCurrCode, NewToUOMCode, NewCreateNewPrices);
        PriceLowerLimit := NewPriceLowerLimit;
        UnitPriceFactor := NewUnitPriceFactor;
        RoundingMethod.Code := NewRoundingMethodCode;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyOrInsertSalesPriceWksh(var SalesPriceWorksheet: Record "Sales Price Worksheet"; var SalesPrice: Record "Sales Price"; UnitPriceFactor: Decimal; PriceLowerLimit: Decimal; RoundingMethod: Record "Rounding Method"; CreateNewPrices: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetNewUnitPriceAbovePriceLimit(var SalesPriceWorksheet: Record "Sales Price Worksheet"; PriceLowerLimit: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesPriceOnAfterGetRecordOnAfterCheck(SalesPrice: Record "Sales Price"; Item: Record Item; var SkipRecord: Boolean)
    begin
    end;
}
