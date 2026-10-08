// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using Microsoft.Finance.SalesTax;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using System.Globalization;
using System.Utilities;

report 10120 "Purchase Credit Memo NA"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Document/PurchaseCreditMemoNA.rdlc';
    Caption = 'Purchase Credit Memo';

    dataset
    {
        dataitem("Purch. Cr. Memo Hdr."; "Purch. Cr. Memo Hdr.")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Buy-from Vendor No.", "Pay-to Vendor No.", "No. Printed";
            column(No_PurchCrMemoHdr; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyAddress1; CompanyAddress[1])
                    {
                    }
                    column(CompanyAddress2; CompanyAddress[2])
                    {
                    }
                    column(CompanyAddress3; CompanyAddress[3])
                    {
                    }
                    column(CompanyAddress4; CompanyAddress[4])
                    {
                    }
                    column(CompanyAddress5; CompanyAddress[5])
                    {
                    }
                    column(CompanyAddress6; CompanyAddress[6])
                    {
                    }
                    column(CopyTxt; CopyTxt)
                    {
                    }
                    column(BuyFromAddress1; BuyFromAddress[1])
                    {
                    }
                    column(BuyFromAddress2; BuyFromAddress[2])
                    {
                    }
                    column(BuyFromAddress3; BuyFromAddress[3])
                    {
                    }
                    column(BuyFromAddress4; BuyFromAddress[4])
                    {
                    }
                    column(BuyFromAddress5; BuyFromAddress[5])
                    {
                    }
                    column(BuyFromAddress6; BuyFromAddress[6])
                    {
                    }
                    column(BuyFromAddress7; BuyFromAddress[7])
                    {
                    }
                    column(AppDocType_PurchCrMemoHdr; "Purch. Cr. Memo Hdr."."Applies-to Doc. Type")
                    {
                    }
                    column(ShipToAddress1; ShipToAddress[1])
                    {
                    }
                    column(ShipToAddress2; ShipToAddress[2])
                    {
                    }
                    column(ShipToAddress3; ShipToAddress[3])
                    {
                    }
                    column(ShipToAddress4; ShipToAddress[4])
                    {
                    }
                    column(ShipToAddress5; ShipToAddress[5])
                    {
                    }
                    column(ShipToAddress6; ShipToAddress[6])
                    {
                    }
                    column(ShipToAddress7; ShipToAddress[7])
                    {
                    }
                    column(PaytoVendNo_PurchCrMemoHdr; "Purch. Cr. Memo Hdr."."Pay-to Vendor No.")
                    {
                    }
                    column(YourRef_PurchCrMemoHdr; "Purch. Cr. Memo Hdr."."Your Reference")
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(VendCrMemoNo_PurchCrMemoHdr; "Purch. Cr. Memo Hdr."."Vendor Cr. Memo No.")
                    {
                    }
                    column(DocDate_PurchCrMemoHdr; "Purch. Cr. Memo Hdr."."Document Date")
                    {
                    }
                    column(CompanyAddress7; CompanyAddress[7])
                    {
                    }
                    column(CompanyAddress8; CompanyAddress[8])
                    {
                    }
                    column(BuyFromAddress8; BuyFromAddress[8])
                    {
                    }
                    column(ShipToAddress8; ShipToAddress[8])
                    {
                    }
                    column(AppDocNo_PurchCrMemoHdr; "Purch. Cr. Memo Hdr."."Applies-to Doc. No.")
                    {
                    }
                    column(CopyNo; CopyNo)
                    {
                    }
                    column(VendTaxIdentificationType; Format(Vend."Tax Identification Type"))
                    {
                    }
                    column(ToCaption; ToCaptionLbl)
                    {
                    }
                    column(ApplytoTypeCaption; ApplytoTypeCaptionLbl)
                    {
                    }
                    column(VendorIDCaption; VendorIDCaptionLbl)
                    {
                    }
                    column(ConfirmToCaption; ConfirmToCaptionLbl)
                    {
                    }
                    column(BuyerCaption; BuyerCaptionLbl)
                    {
                    }
                    column(ShipCaption; ShipCaptionLbl)
                    {
                    }
                    column(PurchCreditMemoCaption; PurchCreditMemoCaptionLbl)
                    {
                    }
                    column(PurchaseCreditMemoNumberCaption; PurchaseCreditMemoNumberCaptionLbl)
                    {
                    }
                    column(PurchaseCreditMemoDateCaption; PurchaseCreditMemoDateCaptionLbl)
                    {
                    }
                    column(PageCaption; PageCaptionLbl)
                    {
                    }
                    column(ApplytoNumberCaption; ApplytoNumberCaptionLbl)
                    {
                    }
                    column(PayCaption; PayCaptionLbl)
                    {
                    }
                    column(TaxIdentTypeCaption; TaxIdentTypeCaptionLbl)
                    {
                    }
                    dataitem("Purch. Cr. Memo Line"; "Purch. Cr. Memo Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Purch. Cr. Memo Hdr.";
                        DataItemTableView = sorting("Document No.", "Line No.");
                        column(AmountExclInvDisc; AmountExclInvDisc)
                        {
                        }
                        column(ItemNumberToPrint; ItemNumberToPrint)
                        {
                        }
                        column(UOM_PurchCrMemoLine; "Unit of Measure")
                        {
                        }
                        column(Quantity_PurchCrMemoLine; Quantity)
                        {
                        }
                        column(UnitPriceToPrint; UnitPriceToPrint)
                        {
                            DecimalPlaces = 2 : 5;
                        }
                        column(Desc_PurchCrMemoLine; Description)
                        {
                        }
                        column(AmountExclInvDisc1; Amount - AmountExclInvDisc)
                        {
                        }
                        column(AmountIncludingVATAmount; "Amount Including VAT" - Amount)
                        {
                        }
                        column(AmtIncluVAT_PurchCrMemoLine; "Amount Including VAT")
                        {
                        }
                        column(BreakdownLabel1; BreakdownLabel[1])
                        {
                        }
                        column(BreakdownTitle; BreakdownTitle)
                        {
                        }
                        column(BreakdownLabel2; BreakdownLabel[2])
                        {
                        }
                        column(BreakdownLabel3; BreakdownLabel[3])
                        {
                        }
                        column(BreakdownAmt1; BreakdownAmt[1])
                        {
                        }
                        column(BreakdownAmt2; BreakdownAmt[2])
                        {
                        }
                        column(BreakdownAmt3; BreakdownAmt[3])
                        {
                        }
                        column(BreakdownAmt4; BreakdownAmt[4])
                        {
                        }
                        column(BreakdownLabel4; BreakdownLabel[4])
                        {
                        }
                        column(TotalTaxLabel; TotalTaxLabel)
                        {
                        }
                        column(PrintFooter; PrintFooter)
                        {
                        }
                        column(LineNo_PurchCrMemoLine; "Line No.")
                        {
                        }
                        column(ItemNoCaption; ItemNoCaptionLbl)
                        {
                        }
                        column(UnitCaption; UnitCaptionLbl)
                        {
                        }
                        column(DescriptionCaption; DescriptionCaptionLbl)
                        {
                        }
                        column(QuantityCaption; QuantityCaptionLbl)
                        {
                        }
                        column(UnitPriceCaption; UnitPriceCaptionLbl)
                        {
                        }
                        column(TotalPriceCaption; TotalPriceCaptionLbl)
                        {
                        }
                        column(SubtotalCaption; SubtotalCaptionLbl)
                        {
                        }
                        column(InvoiceDiscountCaption; InvoiceDiscountCaptionLbl)
                        {
                        }
                        column(TotalCaption; TotalCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            OnLineNumber := OnLineNumber + 1;

                            if Type = Type::" " then begin
                                ItemNumberToPrint := '';
                                "Unit of Measure" := '';
                                Amount := 0;
                                "Amount Including VAT" := 0;
                                "Inv. Discount Amount" := 0;
                                Quantity := 0;
                            end else
                                if Type = Type::"G/L Account" then
                                    ItemNumberToPrint := "Vendor Item No."
                                else
                                    ItemNumberToPrint := "No.";

                            AmountExclInvDisc := Amount + "Inv. Discount Amount";

                            if Quantity = 0 then
                                UnitPriceToPrint := 0 // so it won't print
                            else
                                UnitPriceToPrint := Round(AmountExclInvDisc / Quantity, 0.00001);
                            if OnLineNumber = NumberOfLines then
                                PrintFooter := true;
                        end;

                        trigger OnPreDataItem()
                        begin
                            Clear(AmountExclInvDisc);
                            NumberOfLines := Count;
                            OnLineNumber := 0;
                            PrintFooter := false;
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if CopyNo = NoLoops then begin
                        if not CurrReport.Preview then
                            PurchaseCrMemoPrinted.Run("Purch. Cr. Memo Hdr.");
                        CurrReport.Break();
                    end;
                    CopyNo := CopyNo + 1;
                    if CopyNo = 1 then // Original
                        Clear(CopyTxt)
                    else
                        CopyTxt := Text000;
                end;

                trigger OnPreDataItem()
                begin
                    NoLoops := 1 + Abs(NoCopies);
                    if NoLoops <= 0 then
                        NoLoops := 1;
                    CopyNo := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if PrintCompany then
                    if RespCenter.Get("Responsibility Center") then begin
                        FormatAddress.RespCenter(CompanyAddress, RespCenter);
                        CompanyInformation."Phone No." := RespCenter."Phone No.";
                        CompanyInformation."Fax No." := RespCenter."Fax No.";
                    end;
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");

                if "Purchaser Code" = '' then
                    Clear(SalesPurchPerson)
                else
                    SalesPurchPerson.Get("Purchaser Code");

                if "Pay-to Vendor No." = '' then begin
                    "Buy-from Vendor Name" := Text009;
                    "Ship-to Name" := Text009;
                end;

                FormatAddress.PurchCrMemoPayTo(BuyFromAddress, "Purch. Cr. Memo Hdr.");
                FormatAddress.PurchCrMemoShipTo(ShipToAddress, "Purch. Cr. Memo Hdr.");

                if LogInteraction then
                    if not CurrReport.Preview then
                        SegManagement.LogDocument(
                          16, "No.", 0, 0, DATABASE::Vendor, "Buy-from Vendor No.", "Purchaser Code", '', "Posting Description", '');

                Clear(BreakdownTitle);
                Clear(BreakdownLabel);
                Clear(BreakdownAmt);
                TotalTaxLabel := Text008;
                if "Tax Area Code" <> '' then begin
                    TaxArea.Get("Tax Area Code");
                    case TaxArea."Country/Region" of
                        TaxArea."Country/Region"::US:
                            TotalTaxLabel := Text005;
                        TaxArea."Country/Region"::CA:
                            TotalTaxLabel := Text007;
                    end;
                    SalesTaxCalc.StartSalesTaxCalculation();
                    if TaxArea."Use External Tax Engine" then
                        SalesTaxCalc.CallExternalTaxEngineForDoc(DATABASE::"Purch. Cr. Memo Hdr.", 0, "No.")
                    else begin
                        SalesTaxCalc.AddPurchCrMemoLines("No.");
                        SalesTaxCalc.EndSalesTaxCalculation("Posting Date");
                    end;
                    SalesTaxCalc.GetSummarizedSalesTaxTable(TempSalesTaxAmtLine);
                    BrkIdx := 0;
                    PrevPrintOrder := 0;
                    PrevTaxPercent := 0;
                    TempSalesTaxAmtLine.Reset();
                    TempSalesTaxAmtLine.SetCurrentKey("Print Order", "Tax Area Code for Key", "Tax Jurisdiction Code");
                    if TempSalesTaxAmtLine.Find('-') then
                        repeat
                            if (TempSalesTaxAmtLine."Print Order" = 0) or
                               (TempSalesTaxAmtLine."Print Order" <> PrevPrintOrder) or
                               (TempSalesTaxAmtLine."Tax %" <> PrevTaxPercent)
                            then begin
                                BrkIdx := BrkIdx + 1;
                                if BrkIdx > 1 then
                                    if TaxArea."Country/Region" = TaxArea."Country/Region"::CA then
                                        BreakdownTitle := Text006
                                    else
                                        BreakdownTitle := Text003;
                                if BrkIdx > ArrayLen(BreakdownAmt) then begin
                                    BrkIdx := BrkIdx - 1;
                                    BreakdownLabel[BrkIdx] := Text004;
                                end else
                                    BreakdownLabel[BrkIdx] := StrSubstNo(TempSalesTaxAmtLine."Print Description", TempSalesTaxAmtLine."Tax %");
                            end;
                            BreakdownAmt[BrkIdx] := BreakdownAmt[BrkIdx] + TempSalesTaxAmtLine."Tax Amount";
                        until TempSalesTaxAmtLine.Next() = 0;
                    if BrkIdx = 1 then begin
                        Clear(BreakdownLabel);
                        Clear(BreakdownAmt);
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                if PrintCompany then
                    FormatAddress.Company(CompanyAddress, CompanyInformation)
                else
                    Clear(CompanyAddress);
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
                    field(NumberOfCopies; NoCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Number of Copies';
                        ToolTip = 'Specifies the number of copies of each document (in addition to the original) that you want to print.';
                    }
                    field(PrintCompanyAddress; PrintCompany)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Company Address';
                        ToolTip = 'Specifies if your company address is printed at the top of the sheet, because you do not use pre-printed paper. Leave this check box blank to omit your company''s address.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want to record the related interactions with the involved contact person in the Interaction Log Entry table.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            LogInteractionEnable := true;
        end;

        trigger OnOpenPage()
        begin
            LogInteraction := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Purch. Cr. Memo") <> '';
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get('');
    end;

    var
        UnitPriceToPrint: Decimal;
        AmountExclInvDisc: Decimal;
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyInformation: Record "Company Information";
        RespCenter: Record "Responsibility Center";
        TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary;
        TaxArea: Record "Tax Area";
        Vend: Record Vendor;
        LanguageMgt: Codeunit Language;
        CompanyAddress: array[8] of Text[100];
        BuyFromAddress: array[8] of Text[100];
        ShipToAddress: array[8] of Text[100];
        CopyTxt: Text[10];
        ItemNumberToPrint: Text[50];
        PrintCompany: Boolean;
        PrintFooter: Boolean;
        NoCopies: Integer;
        NoLoops: Integer;
        CopyNo: Integer;
        NumberOfLines: Integer;
        OnLineNumber: Integer;
        PurchaseCrMemoPrinted: Codeunit "PurchCrMemo-Printed";
        FormatAddress: Codeunit "Format Address";
        SalesTaxCalc: Codeunit "Sales Tax Calculate";
        SegManagement: Codeunit SegManagement;
        LogInteraction: Boolean;
        TotalTaxLabel: Text[30];
        BreakdownTitle: Text[30];
        BreakdownLabel: array[4] of Text[30];
        BreakdownAmt: array[4] of Decimal;
        BrkIdx: Integer;
        PrevPrintOrder: Integer;
        PrevTaxPercent: Decimal;
        Text000: Label 'COPY';
        Text003: Label 'Sales Tax Breakdown:';
        Text004: Label 'Other Taxes';
        Text005: Label 'Total Sales Tax:';
        Text006: Label 'Tax Breakdown:';
        Text007: Label 'Total Tax:';
        Text008: Label 'Tax:';
        Text009: Label 'VOID CREDIT MEMO';
        LogInteractionEnable: Boolean;
        ToCaptionLbl: Label 'To:';
        ApplytoTypeCaptionLbl: Label 'Apply to Type';
        VendorIDCaptionLbl: Label 'Vendor ID';
        ConfirmToCaptionLbl: Label 'Confirm To';
        BuyerCaptionLbl: Label 'Buyer';
        ShipCaptionLbl: Label 'Ship';
        PurchCreditMemoCaptionLbl: Label 'Purchase Credit Memo';
        PurchaseCreditMemoNumberCaptionLbl: Label 'Purchase Credit Memo Number:';
        PurchaseCreditMemoDateCaptionLbl: Label 'Purchase Credit Memo Date:';
        PageCaptionLbl: Label 'Page';
        ApplytoNumberCaptionLbl: Label 'Apply to Number';
        PayCaptionLbl: Label 'Pay';
        TaxIdentTypeCaptionLbl: Label 'Tax Ident. Type';
        ItemNoCaptionLbl: Label 'Item No.';
        UnitCaptionLbl: Label 'Unit';
        DescriptionCaptionLbl: Label 'Description';
        QuantityCaptionLbl: Label 'Quantity';
        UnitPriceCaptionLbl: Label 'Unit Price';
        TotalPriceCaptionLbl: Label 'Total Price';
        SubtotalCaptionLbl: Label 'Subtotal';
        InvoiceDiscountCaptionLbl: Label 'Invoice Discount:';
        TotalCaptionLbl: Label 'Total';
}

