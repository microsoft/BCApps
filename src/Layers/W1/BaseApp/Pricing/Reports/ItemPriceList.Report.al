// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Reports;

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

report 7050 "Item Price List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Pricing/Reports/ItemPriceList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Item Price List';
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
            column(ReqDateFormatted; StrSubstNo(AsOfTok, Format(DateReq, 0, 4)))
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
            column(SourceType; PriceSource."Source Type")
            {
            }
            column(SourceNo; PriceSource."Source No.")
            {
            }
            column(PageCaption; StrSubstNo(PageTok, ''))
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
                RequestFilterFields = Code;
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
                begin
                    ItemNo := Code;
                    ItemDesc := Description;

                    FindPriceDiscount(Code);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ItemNo := "No.";
                ItemDesc := Description;

                FindPriceDiscount('');
            end;

            trigger OnPreDataItem()
            begin
                PriceSourceList.Init();
                CustNo := '';
                ContNo := '';
                CustPriceGrCode := '';
                CustDiscGrCode := '';
                SalesDesc := '';

                case PriceSource."Source Type" of
                    PriceSource."Source Type"::Customer:
                        begin
                            Cust.Get(PriceSource."Source No.");
                            CustNo := Cust."No.";
                            CustPriceGrCode := Cust."Customer Price Group";
                            CustDiscGrCode := Cust."Customer Disc. Group";
                            PriceSourceList.Add("Price Source Type"::"Customer Disc. Group", CustDiscGrCode);
                            SalesDesc := Cust.Name;
                            PriceSourceList.Add("Price Source Type"::Customer, CustNo);
                            if ContBusRel.FindByRelation(ContBusRel."Link to Table"::Customer, CustNo) then begin
                                ContNo := ContBusRel."Contact No.";
                                PriceSourceList.Add("Price Source Type"::Contact, ContNo);
                            end;
                            PriceSourceList.Add("Price Source Type"::"All Customers");
                        end;
                    PriceSource."Source Type"::"Customer Price Group":
                        begin
                            CustPriceGr.Get(PriceSource."Source No.");
                            CustPriceGrCode := CopyStr(PriceSource."Source No.", 1, MaxStrLen(CustPriceGrCode));
                            PriceSourceList.Add("Price Source Type"::"Customer Price Group", CustPriceGrCode);
                        end;
                    PriceSource."Source Type"::Campaign:
                        begin
                            Campaign.Get(PriceSource."Source No.");
                            CampaignNo := PriceSource."Source No.";
                            SalesDesc := Campaign.Description;
                            PriceSourceList.Add("Price Source Type"::Campaign, CampaignNo);
                        end;
                    PriceSource."Source Type"::"All Customers":
                        PriceSourceList.Add("Price Source Type"::"All Customers");
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
                        ToolTip = 'Specifies the period for which the prices apply, such as 10/01/20...12/31/20.';
                    }
                    field(Method; PriceCalcMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Price Calculation Method';
                        ToolTip = 'Specifies the price calculation method.';

                        trigger OnValidate()
                        begin
                            ValidateMethod();
                        end;
                    }
                    field(Handler; format(PriceCalculationHandler))
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Price Calculation Handler';
                        ToolTip = 'Specifies the price calculation handler that is defined for the calculation of sales prices for the selected method.';

                        trigger OnAssistEdit()
                        begin
                            Page.RunModal(Page::"Price Calculation Methods");
                        end;
                    }
                    field(SourceType; SalesSourceType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Assign-to Type';
                        ToolTip = 'Specifies the type of entity to which the price list is assigned. The options are relevant to the entity you are currently viewing.';

                        trigger OnValidate()
                        begin
                            SourceNoCtrlEnable := SalesSourceType <> SalesSourceType::"All Customers";
                            PriceSource.Validate("Source Type", SalesSourceType.AsInteger());
                            SalesSourceNo := PriceSource."Source No.";
                        end;
                    }
                    field(SourceNoCtrl; SalesSourceNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Assign-to';
                        Enabled = SourceNoCtrlEnable;
                        ToolTip = 'Specifies the entity to which the prices are assigned. The options depend on the selection in the Assign-to Type field. If you choose an entity, the price list will be used only for that entity.';

                        trigger OnLookup(var Text: Text) Result: Boolean
                        begin
                            PriceSource.Validate("Source Type", SalesSourceType.AsInteger());
                            Result := PriceSource.LookupNo();
                            if Result then begin
                                SalesSourceNo := PriceSource."Source No.";
                                LookupIsComplete := true;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            if LookupIsComplete then
                                SalesSourceNo := PriceSource."Source No.";
                            if (SalesSourceNo = '') and (SalesSourceType <> SalesSourceType::"All Customers") then
                                Error(MissSourceNoErr);

                            PriceSource.Validate("Source No.", SalesSourceNo);
                            LookupIsComplete := false;

                            Currency.Code := PriceSource."Currency Code";
                            SalesSourceNo := PriceSource."Source No.";
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

        trigger OnOpenPage()
        begin
            if SalesSourceType.AsInteger() = 0 then
                SalesSourceType := SalesSourceType::"All Customers";
            if DateReq = 0D then
                DateReq := WorkDate();

            SourceNoCtrlEnable := SalesSourceType <> SalesSourceType::"All Customers";
        end;

        trigger OnAfterGetCurrRecord()
        begin
            ValidateMethod();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if (SalesSourceNo = '') and (SalesSourceType <> SalesSourceType::"All Customers") then
            Error(MissSourceNoErr);

        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);

        if CustPriceGr.Code <> '' then
            CustPriceGr.Find();

        PriceSource.Validate("Source Type", SalesSourceType.AsInteger());
        PriceSource.Validate("Source No.", SalesSourceNo);
        PriceSource."Currency Code" := Currency.Code;
        SetCurrency();
    end;

    protected var
        Currency: Record Currency;
        PriceSource: Record "Price Source";
        TempSalesPrice: Record "Price List Line" temporary;
        TempSalesLineDisc: Record "Price List Line" temporary;
        PriceSourceList: Codeunit "Price Source List";

    var
        CompanyInfo: Record "Company Information";
        CustPriceGr: Record "Customer Price Group";
        Cust: Record Customer;
        Campaign: Record Campaign;
        CurrExchRate: Record "Currency Exchange Rate";
        ContBusRel: Record "Contact Business Relation";
        GLSetup: Record "General Ledger Setup";
        FormatAddr: Codeunit "Format Address";
        PriceCalcMethod: Enum "Price Calculation Method";
        PriceCalculationHandler: Enum "Price Calculation Handler";
        SalesSourceType: Enum "Sales Price Source Type";
        LookupIsComplete: Boolean;
        SalesSourceNo: Code[20];
        VATText: Text[20];
        DateReq: Date;
        CompanyAddr: array[8] of Text[100];
        CurrencyText: Text[30];
        UnitOfMeasure: Code[10];
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
        SourceNoCtrlEnable: Boolean;
        InclTok: Label 'Incl.';
        ExclTok: Label 'Excl.';
        PageTok: Label 'Page %1', Comment = '%1 - a page number';
        AsOfTok: Label 'As of %1', Comment = '%1 - a date';
        MissSourceNoErr: Label 'You must specify an Assign-to, if the Assign-to Type is different from All Customers.';
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

    local procedure FindPriceDiscount(VariantCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        PriceCalculation: Interface "Price Calculation";
    begin
        SalesLine.Init();
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine."Variant Code" := VariantCode;
        SalesLine."Posting Date" := DateReq;
        SetCurrencyFactorInHeader(SalesHeader);
        SalesLine.GetLineWithPrice(LineWithPrice);
        LineWithPrice.SetLine(Enum::"Price Type"::Sale, SalesHeader, SalesLine);
        LineWithPrice.SetSources(PriceSourceList);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
        PriceCalculation.FindPrice(TempSalesPrice, false);
        PriceCalculation.FindDiscount(TempSalesLineDisc, false);
    end;

    local procedure GetPriceHandler(Method: Enum "Price Calculation Method"): Enum "Price Calculation Handler";
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        if PriceCalculationSetup.FindDefault(Method, PriceCalculationSetup.Type::Sale) then
            exit(PriceCalculationSetup.Implementation);
    end;

    local procedure ValidateMethod()
    begin
        if PriceCalcMethod = PriceCalcMethod::" " then
            PriceCalcMethod := PriceCalcMethod::"Lowest Price";
        PriceCalculationHandler := GetPriceHandler(PriceCalcMethod);
    end;

    local procedure SetCurrency()
    begin
        PricesInCurrency := PriceSource."Currency Code" <> '';
        if PricesInCurrency then begin
            Currency.Get(PriceSource."Currency Code");
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

        TempSalesPrice.SetRange("Source Type", PriceSource."Source Type");
        TempSalesPrice.SetRange("Source No.", PriceSource."Source No.");

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
            if not TempSalesPrice.FindSet() then
                if not IsVariant then begin
                    if PriceSource."Source Type" = PriceSource."Source Type"::Campaign then
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

        if (PriceSource."Source Type" = PriceSource."Source Type"::Campaign) and (TempSalesPrice."Source Type" <> TempSalesPrice."Source Type"::Campaign) then
            CurrReport.Skip();

        if TempSalesPrice."Price Includes VAT" then
            VATText := InclTok
        else
            VATText := ExclTok;
        UnitOfMeasure := TempSalesPrice."Unit of Measure Code";
        ConvertPricetoUoM(UnitOfMeasure, TempSalesPrice."Unit Price");
        ConvertPriceLCYToFCY(TempSalesPrice."Currency Code", TempSalesPrice."Unit Price");
    end;

    local procedure PreparePrintSalesDisc(IsVariant: Boolean)
    begin
        if PricesInCurrency then begin
            TempSalesLineDisc.SetRange("Currency Code", Currency.Code);
            if TempSalesLineDisc.FindSet() then begin
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
            if not TempSalesLineDisc.FindSet() then
                CurrReport.Break();
        end else
            if TempSalesLineDisc.Next() = 0 then
                CurrReport.Break();

        if (PriceSource."Source Type" = PriceSource."Source Type"::Campaign) and (TempSalesLineDisc."Source Type" <> TempSalesLineDisc."Source Type"::Campaign) then
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

    procedure InitializeRequest(NewDateReq: Date; NewSourceType: Enum "Sales Price Source Type"; NewSourceNo: Code[20]; NewCurrencyCode: Code[10])
    begin
        DateReq := NewDateReq;
        SalesSourceType := NewSourceType;
        SalesSourceNo := NewSourceNo;
        Currency.Code := NewCurrencyCode;

        PriceSource.Validate("Source Type", SalesSourceType.AsInteger());
        PriceSource.Validate("Source No.", SalesSourceNo);
        PriceSource."Currency Code" := Currency.Code;
    end;
}

