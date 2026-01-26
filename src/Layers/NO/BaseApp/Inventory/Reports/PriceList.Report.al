// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Campaign;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Pricing;
using System.Utilities;

report 715 "Price List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/PriceList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Price List';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Description", "Assembly BOM", "Inventory Posting Group";
            column(CompanyAddr1; CompanyAddr[1])
            {
            }
            column(CompanyAddr2; CompanyAddr[2])
            {
            }
            column(CompanyAddr3; CompanyAddr[3])
            {
            }
            column(CompanyAddr4; CompanyAddr[4])
            {
            }
            column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
            {
            }
            column(CompanyInfoFaxNo; CompanyInfo."Fax No.")
            {
            }
            column(CompanyInfoVATRegNo; CompanyInfo."VAT Registration No.")
            {
            }
            column(CompanyInfoGiroNo; CompanyInfo."Giro No.")
            {
            }
            column(CompanyInfoBankName; CompanyInfo."Bank Name")
            {
            }
            column(CompanyInfoBankAccNo; CompanyInfo."Bank Account No.")
            {
            }
            column(ReqDateFormatted; StrSubstNo(Text003Txt, Format(DateReq, 0, 4)))
            {
            }
            column(CompanyAddr5; CompanyAddr[5])
            {
            }
            column(CompanyAddr6; CompanyAddr[6])
            {
            }
            column(CompanyAddr7; CompanyAddr[7])
            {
            }
            column(CompanyAddr8; CompanyAddr[8])
            {
            }
            column(SalesType; SalesPriceType)
            {
            }
            column(SalesCode; SalesCode)
            {
            }
            column(PageCaption; StrSubstNo(Text002Txt, ''))
            {
            }
            column(SalesDesc; SalesDesc)
            {
            }
            column(UnitPriceFieldCaption; TempSalesPrice.FieldCaption("Unit Price") + CurrencyText)
            {
            }
            column(LineDiscountFieldCaption; TempSalesLineDisc.FieldCaption("Line Discount %") + CurrencyText)
            {
            }
            column(No_Item; "No.")
            {
            }
            column(PriceListCaption; PriceListCaptionLbl)
            {
            }
            column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
            {
            }
            column(CompanyInfoFaxNoCaption; CompanyInfoFaxNoCaptionLbl)
            {
            }
            column(CompanyInfoVATRegNoCaption; CompanyInfoVATRegNoCaptionLbl)
            {
            }
            column(CompanyInfoGiroNoCaption; CompanyInfoGiroNoCaptionLbl)
            {
            }
            column(CompanyInfoBankNameCaption; CompanyInfoBankNameCaptionLbl)
            {
            }
            column(CompanyInfoBankAccNoCaption; CompanyInfoBankAccNoCaptionLbl)
            {
            }
            column(ItemNoCaption; ItemNoCaptionLbl)
            {
            }
            column(ItemDescCaption; ItemDescCaptionLbl)
            {
            }
            column(UnitOfMeasureCaption; UnitOfMeasureCaptionLbl)
            {
            }
            column(MinimumQuantityCaption; MinimumQuantityCaptionLbl)
            {
            }
            column(VATTextCaption; VATTextCaptionLbl)
            {
            }
            column(EnterpriseRegister; CompanyInfo.GetEnterpriseClassification())
            {
            }
            dataitem(SalesPrices; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(VATText_SalesPrices; VATText)
                {
                }
                column(SalesPriceUnitPrice; TempSalesPrice."Unit Price")
                {
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 2;
                }
                column(UOM_SalesPrices; UnitOfMeasure)
                {
                }
                column(ItemNo_SalesPrices; ItemNo)
                {
                }
                column(ItemDesc_SalesPrices; ItemDesc)
                {
                }
                column(MinimumQty_SalesPrices; TempSalesPrice."Minimum Quantity")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    PrintSalesPrice(false);
                end;

                trigger OnPreDataItem()
                begin
                    PreparePrintSalesPrice(false);
                end;
            }
            dataitem(SalesLineDiscs; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(LineDisc_SalesLineDisc; TempSalesLineDisc."Line Discount %")
                {
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 2;
                }
                column(MinimumQty_SalesLineDiscs; TempSalesLineDisc."Minimum Quantity")
                {
                }
                column(UOM_SalesLineDiscs; UnitOfMeasure)
                {
                }
                column(ItemDesc_SalesLineDiscs; ItemDesc)
                {
                }
                column(ItemNo_SalesLineDiscs; ItemNo)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    PrintSalesDisc();
                end;

                trigger OnPreDataItem()
                begin
                    PreparePrintSalesDisc(false);
                end;
            }
            dataitem("Item Variant"; "Item Variant")
            {
                DataItemLink = "Item No." = field("No.");
                dataitem(VariantSalesPrices; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(ItemNo_Variant_SalesPrices; ItemNo)
                    {
                    }
                    column(ItemDesc_Variant_SalesPrices; ItemDesc)
                    {
                    }
                    column(UOM_Variant_SalesPrices; UnitOfMeasure)
                    {
                    }
                    column(MinimumQty_Variant_SalesPrices; TempSalesPrice."Minimum Quantity")
                    {
                    }
                    column(UnitPrince_Variant_SalesPrices; TempSalesPrice."Unit Price")
                    {
                    }
                    column(VATText_Variant_SalesPrices; VATText)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        PrintSalesPrice(true);
                    end;

                    trigger OnPreDataItem()
                    begin
                        PreparePrintSalesPrice(true);
                    end;
                }
                dataitem(VariantSalesLineDiscs; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(ItemNo_Variant_SalesLineDescs; ItemNo)
                    {
                    }
                    column(ItemDesc_Variant_SalesLineDescs; ItemDesc)
                    {
                    }
                    column(UOM_Variant_SalesLineDescs; UnitOfMeasure)
                    {
                    }
                    column(MinimumQty_Variant_SalesLineDescs; TempSalesLineDisc."Minimum Quantity")
                    {
                    }
                    column(LineDisc_Variant_SalesLineDescs; TempSalesLineDisc."Line Discount %")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        PrintSalesDisc();
                    end;

                    trigger OnPreDataItem()
                    begin
                        PreparePrintSalesDisc(true);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    SalesHeader: Record "Sales Header";
                    SalesLine: Record "Sales Line";
                    TempPriceListLine: Record "Price List Line" temporary;
                    CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
                    LineWithPrice: Interface "Line With Price";
                    PriceCalculation: Interface "Price Calculation";
                    PriceType: Enum "Price Type";
                begin
                    ItemNo := Code;
                    ItemDesc := Description;

                    SalesLine.Init();
                    SalesLine.Type := SalesLine.Type::Item;
                    SalesLine."No." := Item."No.";
                    SalesLine."Variant Code" := Code;
                    SalesLine."Posting Date" := DateReq;
                    SetCurrencyFactorInHeader(SalesHeader);
                    SalesLine.GetLineWithPrice(LineWithPrice);
                    LineWithPrice.SetLine(PriceType::Sale, SalesHeader, SalesLine);
                    LineWithPrice.SetSources(PriceSourceList);
                    PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
                    PriceCalculation.FindPrice(TempPriceListLine, false);
                    CopyFromToPriceListLine.CopyTo(TempSalesPrice, TempPriceListLine);
                    PriceCalculation.FindDiscount(TempPriceListLine, false);
                    CopyFromToPriceListLine.CopyTo(TempSalesLineDisc, TempPriceListLine);
                end;
            }

            trigger OnAfterGetRecord()
            var
                SalesHeader: Record "Sales Header";
                SalesLine: Record "Sales Line";
                TempPriceListLine: Record "Price List Line" temporary;
                CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
                LineWithPrice: Interface "Line With Price";
                PriceCalculation: Interface "Price Calculation";
                PriceType: Enum "Price Type";
            begin
                ItemNo := "No.";
                ItemDesc := Description;

                SalesLine.Init();
                SalesLine.Type := SalesLine.Type::Item;
                SalesLine."No." := Item."No.";
                SalesLine."Posting Date" := DateReq;
                SetCurrencyFactorInHeader(SalesHeader);
                SalesLine.GetLineWithPrice(LineWithPrice);
                LineWithPrice.SetLine(PriceType::Sale, SalesHeader, SalesLine);
                LineWithPrice.SetSources(PriceSourceList);
                PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
                PriceCalculation.FindPrice(TempPriceListLine, false);
                CopyFromToPriceListLine.CopyTo(TempSalesPrice, TempPriceListLine);
                PriceCalculation.FindDiscount(TempPriceListLine, false);
                CopyFromToPriceListLine.CopyTo(TempSalesLineDisc, TempPriceListLine);
            end;

            trigger OnPreDataItem()
            begin
                PriceSourceList.Init();
                CustNo := '';
                ContNo := '';
                CustPriceGrCode := '';
                CustDiscGrCode := '';
                SalesDesc := '';

                case SalesPriceType of
                    SalesPriceType::Customer:
                        begin
                            Cust.Get(SalesCode);
                            CustNo := Cust."No.";
                            CustPriceGrCode := Cust."Customer Price Group";
                            CustDiscGrCode := Cust."Customer Disc. Group";
                            PriceSourceList.Add(PriceSourceType::"Customer Disc. Group", CustDiscGrCode);
                            SalesDesc := Cust.Name;
                            PriceSourceList.Add(PriceSourceType::Customer, CustNo);
                            if ContBusRel.FindByRelation(ContBusRel."Link to Table"::Customer, CustNo) then begin
                                ContNo := ContBusRel."Contact No.";
                                PriceSourceList.Add(PriceSourceType::Contact, ContNo);
                            end;
                            PriceSourceList.Add(Enum::"Price Source Type"::"All Customers");
                        end;
                    SalesPriceType::"Customer Price Group":
                        begin
                            CustPriceGr.Get(SalesCode);
                            CustPriceGrCode := CopyStr(SalesCode, 1, MaxStrLen(CustPriceGrCode));
                            PriceSourceList.Add(PriceSourceType::"Customer Price Group", CustPriceGrCode);
                        end;
                    SalesPriceType::Campaign:
                        begin
                            Campaign.Get(SalesCode);
                            CampaignNo := SalesCode;
                            SalesDesc := Campaign.Description;
                            PriceSourceList.Add(PriceSourceType::Campaign, CampaignNo);
                        end;
                    SalesPriceType::"All Customers":
                        PriceSourceList.Add(PriceSourceType::"All Customers");
                end;
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
                    field(Date; DateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date';
                        ToolTip = 'Specifies the period for which the prices apply, such as 10/01/96...12/31/96.';
                    }
                    field(Method; PriceCalcMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Price Calculation method';
                        ToolTip = 'Specifies the price calculation method.';
                    }
                    field(SalesType; SalesPriceType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Type';
                        ToolTip = 'Specifies the sales type for which the price list should be valid.';

                        trigger OnValidate()
                        begin
                            SalesCodeCtrlEnable := SalesPriceType <> SalesPriceType::"All Customers";
                            SalesCode := '';
                        end;
                    }
                    field(SalesCodeCtrl; SalesCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Code';
                        Enabled = SalesCodeCtrlEnable;
                        ToolTip = 'Specifies code for the sales type for which the price list should be valid.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            CustList: Page "Customer List";
                            CustPriceGrList: Page "Customer Price Groups";
                            CampaignList: Page "Campaign List";
                        begin
                            case SalesPriceType of
                                SalesPriceType::Customer:
                                    begin
                                        CustList.LookupMode := true;
                                        CustList.SetRecord(Cust);
                                        if CustList.RunModal() = ACTION::LookupOK then begin
                                            CustList.GetRecord(Cust);
                                            SalesCode := Cust."No.";
                                        end;
                                    end;
                                SalesPriceType::"Customer Price Group":
                                    begin
                                        CustPriceGrList.LookupMode := true;
                                        CustPriceGrList.SetRecord(CustPriceGr);
                                        if CustPriceGrList.RunModal() = ACTION::LookupOK then begin
                                            CustPriceGrList.GetRecord(CustPriceGr);
                                            SalesCode := CustPriceGr.Code;
                                        end;
                                    end;
                                SalesPriceType::Campaign:
                                    begin
                                        CampaignList.LookupMode := true;
                                        CampaignList.SetRecord(Campaign);
                                        if CampaignList.RunModal() = ACTION::LookupOK then begin
                                            CampaignList.GetRecord(Campaign);
                                            SalesCode := Campaign."No.";
                                        end;
                                    end;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            ValidateSalesCode();
                        end;
                    }
                    field("Currency.Code"; Currency.Code)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Currency Code';
                        TableRelation = Currency;
                        ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            SalesCodeCtrlEnable := true;
        end;

        trigger OnOpenPage()
        begin
            VerifyPriceSetup();
            if DateReq = 0D then
                DateReq := WorkDate();

            SalesCodeCtrlEnable := true;
            if SalesPriceType = SalesPriceType::"All Customers" then
                SalesCodeCtrlEnable := false;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ValidateSalesCode();

        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);

        if CustPriceGr.Code <> '' then
            CustPriceGr.Find();

        SetCurrency();
    end;

    var
        CompanyInfo: Record "Company Information";
        CustPriceGr: Record "Customer Price Group";
        Cust: Record Customer;
        Campaign: Record Campaign;
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        TempSalesPrice: Record "Sales Price" temporary;
        TempSalesLineDisc: Record "Sales Line Discount" temporary;
        ContBusRel: Record "Contact Business Relation";
        GLSetup: Record "General Ledger Setup";
        PriceSourceList: Codeunit "Price Source List";
        FormatAddr: Codeunit "Format Address";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        PriceSourceType: Enum "Price Source Type";
        VATText: Text[20];
        DateReq: Date;
        PriceCalcMethod: Enum "Price Calculation Method";
        CompanyAddr: array[8] of Text[100];
        CurrencyText: Text[30];
        UnitOfMeasure: Code[10];
        SalesPriceType: Enum "Sales Price Type";
        SalesCode: Code[20];
        CustNo: Code[20];
        ContNo: Code[20];
        CampaignNo: Code[20];
        ItemNo: Code[20];
        ItemDesc: Text[100];
        SalesDesc: Text[100];
        CustPriceGrCode: Code[10];
        CustDiscGrCode: Code[20];
        IsFirstSalesPrice: Boolean;
        IsFirstSalesLineDisc: Boolean;
        PricesInCurrency: Boolean;
        CurrencyFactor: Decimal;
        SalesCodeCtrlEnable: Boolean;

        Text000Txt: Label 'Incl.';
        Text001Txt: Label 'Excl.';
        Text002Txt: Label 'Page %1', Comment = '%1 - page number';
        Text003Txt: Label 'As of %1', Comment = '%1 - date';
        Text004Err: Label 'You must specify a sales code, if the sales type is different from All Customers.';
        PriceListCaptionLbl: Label 'Price List';
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoFaxNoCaptionLbl: Label 'Fax No.';
        CompanyInfoVATRegNoCaptionLbl: Label 'VAT Reg. No.';
        CompanyInfoGiroNoCaptionLbl: Label 'Giro No.';
        CompanyInfoBankNameCaptionLbl: Label 'Bank';
        CompanyInfoBankAccNoCaptionLbl: Label 'Account No.';
        ItemNoCaptionLbl: Label 'Item No.';
        ItemDescCaptionLbl: Label 'Description';
        UnitOfMeasureCaptionLbl: Label 'Unit of Measure';
        MinimumQuantityCaptionLbl: Label 'Minimum Quantity';
        VATTextCaptionLbl: Label 'VAT';
        NativeCalculationErr: Label 'The Business Central (Version 15.0) must be selected on the Price Calculation Method page.';

    local procedure VerifyPriceSetup()
    var
        PriceCalculationSetup: record "Price Calculation Setup";
    begin
        if PriceCalculationSetup.FindDefault(PriceCalculationSetup.Method::"Lowest Price", PriceCalculationSetup.Type::Sale) then
            if PriceCalculationSetup.Implementation <> PriceCalculationSetup.Implementation::"Business Central (Version 15.0)" then
                Error(NativeCalculationErr);
    end;

    local procedure SetCurrency()
    begin
        PricesInCurrency := Currency.Code <> '';
        if PricesInCurrency then begin
            Currency.Find();
            CurrencyText := ' (' + Currency.Code + ')';
            CurrencyFactor := 0;
        end else
            GLSetup.Get();
    end;

    local procedure ConvertPricetoUoM(var UOMCode: Code[10]; var UnitPrice: Decimal)
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        if UOMCode = '' then begin
            UnitPrice :=
              UnitPrice * UOMMgt.GetQtyPerUnitOfMeasure(Item, Item."Sales Unit of Measure");
            if UOMCode = '' then
                UOMCode := Item."Sales Unit of Measure"
            else
                UOMCode := Item."Base Unit of Measure";
        end;
    end;

    local procedure ConvertPriceLCYToFCY(CurrencyCode: Code[10]; var UnitPrice: Decimal)
    begin
        if PricesInCurrency then begin
            if CurrencyCode = '' then begin
                if CurrencyFactor = 0 then begin
                    Currency.TestField("Unit-Amount Rounding Precision");
                    CurrencyFactor := CurrExchRate.ExchangeRate(DateReq, Currency.Code);
                end;
                UnitPrice := CurrExchRate.ExchangeAmtLCYToFCY(DateReq, Currency.Code, UnitPrice, CurrencyFactor);
            end;
            UnitPrice := Round(UnitPrice, Currency."Unit-Amount Rounding Precision");
        end else
            UnitPrice := Round(UnitPrice, GLSetup."Unit-Amount Rounding Precision");
    end;

    local procedure PreparePrintSalesPrice(IsVariant: Boolean)
    begin
        if PricesInCurrency then begin
            TempSalesPrice.SetRange("Currency Code", Currency.Code);
            if TempSalesPrice.Find('-') then begin
                TempSalesPrice.SetRange("Currency Code", '');
                TempSalesPrice.DeleteAll();
            end;
            TempSalesPrice.SetRange("Currency Code");
        end;

        if IsVariant then begin
            TempSalesPrice.SetRange("Variant Code", '');
            TempSalesPrice.DeleteAll();
            TempSalesPrice.SetRange("Variant Code");
        end;

        IsFirstSalesPrice := true;
    end;

    local procedure PrintSalesPrice(IsVariant: Boolean)
    begin
        if IsFirstSalesPrice then begin
            IsFirstSalesPrice := false;
            if not TempSalesPrice.Find('-') then
                if not IsVariant then begin
                    if SalesPriceType = SalesPriceType::Campaign then
                        CurrReport.Skip();

                    TempSalesPrice."Currency Code" := '';
                    TempSalesPrice."Price Includes VAT" := Item."Price Includes VAT";
                    TempSalesPrice."Unit Price" := Item."Unit Price";
                    TempSalesPrice."Unit of Measure Code" := Item."Base Unit of Measure";
                    TempSalesPrice."Minimum Quantity" := 0;
                end else
                    CurrReport.Skip();
        end else
            if TempSalesPrice.Next() = 0 then
                CurrReport.Break();

        if (SalesPriceType = SalesPriceType::Campaign) and (TempSalesPrice."Sales Type" <> TempSalesPrice."Sales Type"::Campaign) then
            CurrReport.Skip();

        if TempSalesPrice."Price Includes VAT" then
            VATText := Text000Txt
        else
            VATText := Text001Txt;
        UnitOfMeasure := TempSalesPrice."Unit of Measure Code";
        ConvertPricetoUoM(UnitOfMeasure, TempSalesPrice."Unit Price");
        ConvertPriceLCYToFCY(TempSalesPrice."Currency Code", TempSalesPrice."Unit Price");
    end;

    local procedure PreparePrintSalesDisc(IsVariant: Boolean)
    begin
        if PricesInCurrency then begin
            TempSalesLineDisc.SetRange("Currency Code", Currency.Code);
            if TempSalesLineDisc.Find('-') then begin
                TempSalesLineDisc.SetRange("Currency Code", '');
                TempSalesLineDisc.DeleteAll();
            end;
            TempSalesLineDisc.SetRange("Currency Code");
        end;

        if IsVariant then begin
            TempSalesLineDisc.SetRange("Variant Code", '');
            TempSalesLineDisc.DeleteAll();
            TempSalesLineDisc.SetRange("Variant Code");
        end;

        IsFirstSalesLineDisc := true;
    end;

    local procedure PrintSalesDisc()
    begin
        if IsFirstSalesLineDisc then begin
            IsFirstSalesLineDisc := false;
            if not TempSalesLineDisc.Find('-') then
                CurrReport.Break();
        end else
            if TempSalesLineDisc.Next() = 0 then
                CurrReport.Break();

        if (SalesPriceType = SalesPriceType::Campaign) and (TempSalesLineDisc."Sales Type" <> TempSalesLineDisc."Sales Type"::Campaign) then
            CurrReport.Skip();

        if TempSalesLineDisc."Unit of Measure Code" = '' then
            UnitOfMeasure := Item."Base Unit of Measure"
        else
            UnitOfMeasure := TempSalesLineDisc."Unit of Measure Code";
    end;

    local procedure SetCurrencyFactorInHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."Posting Date" := DateReq;
        SalesHeader."Currency Code" := Currency.Code;
        SalesHeader.UpdateCurrencyFactor();
    end;

    procedure InitializeRequest(NewDateReq: Date; NewSalesPriceType: Option; NewSalesCode: Code[20]; NewCurrencyCode: Code[10])
    begin
        DateReq := NewDateReq;
        SalesPriceType := "Sales Price Type".FromInteger(NewSalesPriceType);
        SalesCode := NewSalesCode;
        Currency.Code := NewCurrencyCode;
    end;

    local procedure ValidateSalesCode()
    begin
        if (SalesPriceType <> SalesPriceType::"All Customers") and (SalesCode = '') then
            Error(Text004Err);

        case SalesPriceType of
            SalesPriceType::Customer:
                Cust.Get(SalesCode);
            SalesPriceType::"Customer Price Group":
                CustPriceGr.Get(SalesCode);
            SalesPriceType::Campaign:
                Campaign.Get(SalesCode);
        end;
    end;
}
