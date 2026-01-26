// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.CRM.Team;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using System.Globalization;
using System.Utilities;

report 10474 "Service Invoice-Sales Tax"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Local/History/ServiceInvoiceSalesTax.rdlc';
    Caption = 'Service - Invoice';

    dataset
    {
        dataitem("Service Invoice Header"; "Service Invoice Header")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Customer No.", "No. Printed";
            RequestFilterHeading = 'Service Invoice';
            column(No_ServiceInvoiceHeader; "No.")
            {
            }
            column(DisplayAdditionalFeeNote; DisplayAdditionalFeeNote)
            {
            }
            dataitem("Service Invoice Line"; "Service Invoice Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    TempServInvoiceLine := "Service Invoice Line";
                    TempServInvoiceLine.Insert();
                end;

                trigger OnPreDataItem()
                begin
                    TempServInvoiceLine.Reset();
                    TempServInvoiceLine.DeleteAll();
                end;
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyInfo3Picture; CompanyInfo3.Picture)
                    {
                    }
                    column(CompanyInfo2Picture; CompanyInfo2.Picture)
                    {
                    }
                    column(CompanyInfo1Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(CompanyInformationPicture; CompanyInformation.Picture)
                    {
                    }
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
                    column(BillToAddress1; BillToAddress[1])
                    {
                    }
                    column(BillToAddress2; BillToAddress[2])
                    {
                    }
                    column(BillToAddress3; BillToAddress[3])
                    {
                    }
                    column(BillToAddress4; BillToAddress[4])
                    {
                    }
                    column(BillToAddress5; BillToAddress[5])
                    {
                    }
                    column(BillToAddress6; BillToAddress[6])
                    {
                    }
                    column(BillToAddress7; BillToAddress[7])
                    {
                    }
                    column(DueDate_ServInvHeader; "Service Invoice Header"."Due Date")
                    {
                    }
                    column(PaymentTermsDescription; PaymentTerms.Description)
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
                    column(BilltoCustNo_ServInvHdr; "Service Invoice Header"."Bill-to Customer No.")
                    {
                    }
                    column(YourReference_ServInvHdr; "Service Invoice Header"."Your Reference")
                    {
                    }
                    column(OrderDate_ServInvHdr; "Service Invoice Header"."Order Date")
                    {
                    }
                    column(OrderNo_ServInvHdr; "Service Invoice Header"."Order No.")
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(DocDate_ServInvHdr; "Service Invoice Header"."Document Date")
                    {
                    }
                    column(CompanyAddress7; CompanyAddress[7])
                    {
                    }
                    column(CompanyAddress8; CompanyAddress[8])
                    {
                    }
                    column(BillToAddress8; BillToAddress[8])
                    {
                    }
                    column(ShipToAddress8; ShipToAddress[8])
                    {
                    }
                    column(TaxRegNo; TaxRegNo)
                    {
                    }
                    column(TaxRegLabel; TaxRegLabel)
                    {
                    }
                    column(PrintFooter; PrintFooter)
                    {
                    }
                    column(CopyNo; CopyNo)
                    {
                    }
                    column(BillCaption; BillCaptionLbl)
                    {
                    }
                    column(ToCaption; ToCaptionLbl)
                    {
                    }
                    column(DueDateCaption; DueDateCaptionLbl)
                    {
                    }
                    column(TermsCaption; TermsCaptionLbl)
                    {
                    }
                    column(CustomerIDCaption; CustomerIDCaptionLbl)
                    {
                    }
                    column(PONumberCaption; PONumberCaptionLbl)
                    {
                    }
                    column(PODateCaption; PODateCaptionLbl)
                    {
                    }
                    column(OurOrderNoCaption; OurOrderNoCaptionLbl)
                    {
                    }
                    column(SalesPersonCaption; SalesPersonCaptionLbl)
                    {
                    }
                    column(ShipCaption; ShipCaptionLbl)
                    {
                    }
                    column(InvoiceCaption; InvoiceCaptionLbl)
                    {
                    }
                    column(InvoiceNumberCaption; InvoiceNumberCaptionLbl)
                    {
                    }
                    column(InvoiceDateCaption; InvoiceDateCaptionLbl)
                    {
                    }
                    column(PageCaption; PageCaptionLbl)
                    {
                    }
                    dataitem(ServInvLine; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ServInvLineNumber; Number)
                        {
                        }
                        column(AmountExclInvDisc; AmountExclInvDisc)
                        {
                        }
                        column(TempServInvoiceLineNo; TempServInvoiceLine."No.")
                        {
                        }
                        column(TempServInvLineUOM; TempServInvoiceLine."Unit of Measure")
                        {
                        }
                        column(OrderedQuantity; OrderedQuantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(TempServInvoiceLineQty; TempServInvoiceLine.Quantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(UnitPriceToPrint; UnitPriceToPrint)
                        {
                            DecimalPlaces = 2 : 5;
                        }
                        column(TempServInvLineDescription; TempServInvoiceLine.Description)
                        {
                        }
                        column(TaxLiable; TaxLiable)
                        {
                        }
                        column(TempServInvLineAmtTaxLiable; TempServInvoiceLine.Amount - TaxLiable)
                        {
                        }
                        column(BreakdownLabel1; BreakdownLabel[1])
                        {
                        }
                        column(BreakdownLabel2; BreakdownLabel[2])
                        {
                        }
                        column(BreakdownTitle; BreakdownTitle)
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
                        column(BreakdownLabel3; BreakdownLabel[3])
                        {
                        }
                        column(TotalTaxLabel; TotalTaxLabel)
                        {
                        }
                        column(BreakdownAmt4; BreakdownAmt[4])
                        {
                        }
                        column(BreakdownLabel4; BreakdownLabel[4])
                        {
                        }
                        column(TempServInvLineAmtExclInvDisc; TempServInvoiceLine.Amount - AmountExclInvDisc)
                        {
                        }
                        column(TempServInvLineAmtInclVATAmt; TempServInvoiceLine."Amount Including VAT" - TempServInvoiceLine.Amount)
                        {
                        }
                        column(TempServInvLineAmtInclVAT; TempServInvoiceLine."Amount Including VAT")
                        {
                        }
                        column(ItemDescriptionCaption; ItemDescriptionCaptionLbl)
                        {
                        }
                        column(UnitCaption; UnitCaptionLbl)
                        {
                        }
                        column(OrderQtyCaption; OrderQtyCaptionLbl)
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
                        column(AmtSubjectToSalesTaxCaption; AmtSubjectToSalesTaxCaptionLbl)
                        {
                        }
                        column(AmtExemptFromSalesTaxCaption; AmtExemptFromSalesTaxCaptionLbl)
                        {
                        }
                        column(InvoiceDiscountCaption; InvoiceDiscountCaptionLbl)
                        {
                        }
                        column(SubtotalCaption; SubtotalCaptionLbl)
                        {
                        }
                        column(TotalCaption; TotalCaptionLbl)
                        {
                        }
                        dataitem("Service Shipment Buffer"; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(ServShpBufferPostingDate; ServiceShipmentBuffer."Posting Date")
                            {
                            }
                            column(ServShpBufferQuantity; ServiceShipmentBuffer.Quantity)
                            {
                                DecimalPlaces = 0 : 5;
                            }
                            column(ServShpBufferNumber; Number)
                            {
                            }
                            column(ShipmentCaption; ShipmentCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then
                                    ServiceShipmentBuffer.Find('-')
                                else
                                    ServiceShipmentBuffer.Next();

                                if Number > 1 then begin
                                    TaxLiable := 0;
                                    AmountExclInvDisc := 0;
                                    TempServInvoiceLine.Amount := 0;
                                    TempServInvoiceLine."Amount Including VAT" := 0;
                                end
                            end;

                            trigger OnPreDataItem()
                            begin
                                ServiceShipmentBuffer.SetRange("Document No.", "Service Invoice Line"."Document No.");
                                ServiceShipmentBuffer.SetRange("Line No.", "Service Invoice Line"."Line No.");

                                SetRange(Number, 1, ServiceShipmentBuffer.Count);
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            OnLineNumber := OnLineNumber + 1;

                            if OnLineNumber = 1 then
                                TempServInvoiceLine.Find('-')
                            else
                                TempServInvoiceLine.Next();

                            OrderedQuantity := 0;
                            if "Service Invoice Header"."Order No." = '' then
                                OrderedQuantity := TempServInvoiceLine.Quantity
                            else
                                if OrderLine.Get(1, "Service Invoice Header"."Order No.", TempServInvoiceLine."Line No.") then
                                    OrderedQuantity := OrderLine.Quantity
                                else begin
                                    ShipmentLine.SetRange("Order No.", "Service Invoice Header"."Order No.");
                                    ShipmentLine.SetRange("Order Line No.", TempServInvoiceLine."Line No.");
                                    if ShipmentLine.Find('-') then
                                        repeat
                                            OrderedQuantity := OrderedQuantity + ShipmentLine.Quantity;
                                        until 0 = ShipmentLine.Next();
                                end;

                            DescriptionToPrint := TempServInvoiceLine.Description + ' ' + TempServInvoiceLine."Description 2";
                            if TempServInvoiceLine.Type = TempServInvoiceLine.Type::" " then begin
                                TempServInvoiceLine."No." := '';
                                TempServInvoiceLine."Unit of Measure" := '';
                                TempServInvoiceLine.Amount := 0;
                                TempServInvoiceLine."Amount Including VAT" := 0;
                                TempServInvoiceLine."Inv. Discount Amount" := 0;
                                TempServInvoiceLine.Quantity := 0;
                            end else
                                if TempServInvoiceLine.Type = TempServInvoiceLine.Type::"G/L Account" then
                                    TempServInvoiceLine."No." := '';

                            if TempServInvoiceLine.Amount <> TempServInvoiceLine."Amount Including VAT" then
                                TaxLiable := TempServInvoiceLine.Amount
                            else
                                TaxLiable := 0;

                            AmountExclInvDisc := TempServInvoiceLine.Amount + TempServInvoiceLine."Inv. Discount Amount";

                            if TempServInvoiceLine.Quantity = 0 then
                                UnitPriceToPrint := 0
                            // so it won't print
                            else
                                UnitPriceToPrint := Round(AmountExclInvDisc / TempServInvoiceLine.Quantity, 0.00001);

                            if OnLineNumber = NumberOfLines then
                                PrintFooter := true;
                        end;

                        trigger OnPreDataItem()
                        begin
                            Clear(TaxLiable);
                            Clear(AmountExclInvDisc);
                            NumberOfLines := TempServInvoiceLine.Count();
                            SetRange(Number, 1, NumberOfLines);
                            OnLineNumber := 0;
                            PrintFooter := false;
                        end;
                    }
                    dataitem(LineFee; "Integer")
                    {
                        DataItemTableView = sorting(Number) order(ascending) where(Number = filter(1 ..));
                        column(LineFeeCaptionLbl; TempLineFeeNoteOnReportHist.ReportText)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if not DisplayAdditionalFeeNote then
                                CurrReport.Break();
                            if Number = 1 then begin
                                if not TempLineFeeNoteOnReportHist.FindSet() then
                                    CurrReport.Break()
                            end else
                                if TempLineFeeNoteOnReportHist.Next() = 0 then
                                    CurrReport.Break();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if CopyNo = NoLoops then begin
                        if not CurrReport.Preview then
                            ServiceInvCountPrinted.Run("Service Invoice Header");
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
#if not CLEAN27
                    NoLoops := 1 + Abs(NoCopies) + Customer."Invoice Copies";
#else
                    NoLoops := 1 + Abs(NoCopies);
#endif
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
                /*?????
                IF "Order No." = '' THEN
                  OrderNoText := ''
                else
                  OrderNoText := FIELDCAPTION("Order No."); */
                if "Salesperson Code" = '' then
                    Clear(SalesPurchPerson)
                else
                    SalesPurchPerson.Get("Salesperson Code");

                if not Customer.Get("Bill-to Customer No.") then begin
                    Clear(Customer);
                    "Bill-to Name" := Text009;
                    "Ship-to Name" := Text009;
                end;

                GetLineFeeNoteOnReportHist("No.");

                ServiceFormatAddress.ServiceInvBillTo(BillToAddress, "Service Invoice Header");
                ServiceFormatAddress.ServiceInvShipTo(ShipToAddress, ShipToAddress, "Service Invoice Header");

                if "Payment Terms Code" = '' then
                    Clear(PaymentTerms)
                else
                    PaymentTerms.Get("Payment Terms Code");

                Clear(BreakdownTitle);
                Clear(BreakdownLabel);
                Clear(BreakdownAmt);
                TotalTaxLabel := Text008;
                TaxRegNo := '';
                TaxRegLabel := '';
                if "Tax Area Code" <> '' then begin
                    TaxArea.Get("Tax Area Code");
                    case TaxArea."Country/Region" of
                        TaxArea."Country/Region"::US:
                            TotalTaxLabel := Text005;
                        TaxArea."Country/Region"::CA:
                            begin
                                TotalTaxLabel := Text007;
                                TaxRegNo := CompanyInformation."VAT Registration No.";
                                TaxRegLabel := CompanyInformation.FieldCaption("VAT Registration No.");
                            end;
                    end;
                    ServSalesTaxCalc.StartSalesTaxCalculation();
                    if TaxArea."Use External Tax Engine" then
                        ServSalesTaxCalc.CallExternalTaxEngineForDoc(DATABASE::"Service Invoice Header", 0, "No.")
                    else begin
                        ServSalesTaxCalc.AddServInvoiceLines("No.");
                        ServSalesTaxCalc.EndSalesTaxCalculation("Posting Date");
                    end;
                    ServSalesTaxCalc.GetSummarizedSalesTaxTable(TempSalesTaxAmtLine);
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
                        ApplicationArea = Service;
                        Caption = 'Number of Copies';
                        ToolTip = 'Specifies the number of copies to print of the document.';
                    }
                    field(PrintCompanyAddress; PrintCompany)
                    {
                        ApplicationArea = Service;
                        Caption = 'Print Company Address';
                        ToolTip = 'Specifies if your company address is printed at the top of the sheet, because you do not use pre-printed paper. Leave this check box blank to omit your company''s address.';
                    }
                    field(DisplayAdditionalFeeNote; DisplayAdditionalFeeNote)
                    {
                        ApplicationArea = Service;
                        Caption = 'Show Additional Fee Note';
                        ToolTip = 'Specifies if you want notes about additional fees to be shown on the document.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        // ShipmentLine.SETCURRENTKEY("Order No.","Order Line No.");

        GLSetup.Get();
        CompanyInformation.Get();
        ServiceSetup.Get();

        case ServiceSetup."Logo Position on Documents" of
            ServiceSetup."Logo Position on Documents"::"No Logo":
                ;
            ServiceSetup."Logo Position on Documents"::Left:
                begin
                    CompanyInfo3.Get();
                    CompanyInfo3.CalcFields(Picture);
                end;
            ServiceSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            ServiceSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
        end;

        if PrintCompany then
            FormatAddress.Company(CompanyAddress, CompanyInformation)
        else
            Clear(CompanyAddress);
    end;

    var
        TaxLiable: Decimal;
        OrderedQuantity: Decimal;
        UnitPriceToPrint: Decimal;
        AmountExclInvDisc: Decimal;
        PaymentTerms: Record "Payment Terms";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        GLSetup: Record "General Ledger Setup";
        ServiceSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        OrderLine: Record "Service Line";
        ShipmentLine: Record "Service Shipment Line";
        TempServInvoiceLine: Record "Service Invoice Line" temporary;
        RespCenter: Record "Responsibility Center";
        TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary;
        TempLineFeeNoteOnReportHist: Record "Line Fee Note on Report Hist." temporary;
        TaxArea: Record "Tax Area";
        LanguageMgt: Codeunit Language;
        CompanyAddress: array[8] of Text[100];
        BillToAddress: array[8] of Text[100];
        ShipToAddress: array[8] of Text[100];
        CopyTxt: Text[10];
        DescriptionToPrint: Text[210];
        PrintCompany: Boolean;
        PrintFooter: Boolean;
        NoCopies: Integer;
        NoLoops: Integer;
        CopyNo: Integer;
        NumberOfLines: Integer;
        OnLineNumber: Integer;
        ServiceShipmentBuffer: Record "Service Shipment Buffer" temporary;
        ServiceInvCountPrinted: Codeunit "Service Inv.-Printed";
        FormatAddress: Codeunit "Format Address";
        ServiceFormatAddress: Codeunit "Service Format Address";
        ServSalesTaxCalc: Codeunit "Serv. Sales Tax Calculate";
        NextEntryNo: Integer;
        FirstValueEntryNo: Integer;
        Text000: Label 'COPY';
        TaxRegNo: Text[30];
        TaxRegLabel: Text;
        TotalTaxLabel: Text;
        BreakdownTitle: Text;
        BreakdownLabel: array[4] of Text[30];
        BreakdownAmt: array[4] of Decimal;
        Text003: Label 'Sales Tax Breakdown:';
        Text004: Label 'Other Taxes';
        BrkIdx: Integer;
        PrevPrintOrder: Integer;
        PrevTaxPercent: Decimal;
        Text005: Label 'Total Sales Tax:';
        Text006: Label 'Tax Breakdown:';
        Text007: Label 'Total Tax:';
        Text008: Label 'Tax:';
        Text009: Label 'Void Invoice';
        BillCaptionLbl: Label 'Bill';
        ToCaptionLbl: Label 'To:';
        DueDateCaptionLbl: Label 'Due Date';
        TermsCaptionLbl: Label 'Terms';
        CustomerIDCaptionLbl: Label 'Customer ID';
        PONumberCaptionLbl: Label 'P.O. Number';
        PODateCaptionLbl: Label 'P.O. Date';
        OurOrderNoCaptionLbl: Label 'Our Order No.';
        SalesPersonCaptionLbl: Label 'SalesPerson';
        ShipCaptionLbl: Label 'Ship';
        InvoiceCaptionLbl: Label 'Invoice';
        InvoiceNumberCaptionLbl: Label 'Invoice Number:';
        InvoiceDateCaptionLbl: Label 'Invoice Date:';
        PageCaptionLbl: Label 'Page:';
        ItemDescriptionCaptionLbl: Label 'Item/Description';
        UnitCaptionLbl: Label 'Unit';
        OrderQtyCaptionLbl: Label 'Order Qty';
        QuantityCaptionLbl: Label 'Quantity';
        UnitPriceCaptionLbl: Label 'Unit Price';
        TotalPriceCaptionLbl: Label 'Total Price';
        AmtSubjectToSalesTaxCaptionLbl: Label 'Amount Subject to Sales Tax';
        AmtExemptFromSalesTaxCaptionLbl: Label 'Amount Exempt from Sales Tax';
        InvoiceDiscountCaptionLbl: Label 'Invoice Discount:';
        SubtotalCaptionLbl: Label 'Subtotal:';
        TotalCaptionLbl: Label 'Total:';
        ShipmentCaptionLbl: Label 'Shipment';
        DisplayAdditionalFeeNote: Boolean;

    protected var
        CompanyInformation: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CompanyInfo3: Record "Company Information";

    procedure FindPostedShipmentDate(): Date
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentBuffer2: Record "Service Shipment Buffer" temporary;
    begin
        NextEntryNo := 1;
        if "Service Invoice Line"."Shipment No." <> '' then
            if ServiceShipmentHeader.Get("Service Invoice Line"."Shipment No.") then
                exit(ServiceShipmentHeader."Posting Date");

        if "Service Invoice Header"."Order No." = '' then
            exit("Service Invoice Header"."Posting Date");

        case "Service Invoice Line".Type of
            "Service Invoice Line".Type::Item:
                GenerateBufferFromValueEntry("Service Invoice Line");
            "Service Invoice Line".Type::"G/L Account", "Service Invoice Line".Type::Resource,
          "Service Invoice Line".Type::Cost:
                GenerateBufferFromShipment("Service Invoice Line");
            "Service Invoice Line".Type::" ":
                exit(0D);
        end;

        ServiceShipmentBuffer.Reset();
        ServiceShipmentBuffer.SetRange("Document No.", "Service Invoice Line"."Document No.");
        ServiceShipmentBuffer.SetRange("Line No.", "Service Invoice Line"."Line No.");
        if ServiceShipmentBuffer.Find('-') then begin
            ServiceShipmentBuffer2 := ServiceShipmentBuffer;
            if ServiceShipmentBuffer.Next() = 0 then begin
                ServiceShipmentBuffer.Get(
                  ServiceShipmentBuffer2."Document No.", ServiceShipmentBuffer2."Line No.", ServiceShipmentBuffer2."Entry No.");
                ServiceShipmentBuffer.Delete();
                exit(ServiceShipmentBuffer2."Posting Date");
            end;
            ServiceShipmentBuffer.CalcSums(Quantity);
            if ServiceShipmentBuffer.Quantity <> "Service Invoice Line".Quantity then begin
                ServiceShipmentBuffer.DeleteAll();
                exit("Service Invoice Header"."Posting Date");
            end;
        end else
            exit("Service Invoice Header"."Posting Date");
    end;

    procedure GenerateBufferFromValueEntry(ServiceInvoiceLine2: Record "Service Invoice Line")
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TotalQuantity: Decimal;
        Quantity: Decimal;
    begin
        TotalQuantity := ServiceInvoiceLine2."Quantity (Base)";
        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", ServiceInvoiceLine2."Document No.");
        ValueEntry.SetRange("Posting Date", "Service Invoice Header"."Posting Date");
        ValueEntry.SetRange("Item Charge No.", '');
        ValueEntry.SetFilter("Entry No.", '%1..', FirstValueEntryNo);
        if ValueEntry.Find('-') then
            repeat
                if ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then begin
                    if ServiceInvoiceLine2."Qty. per Unit of Measure" <> 0 then
                        Quantity := ValueEntry."Invoiced Quantity" / ServiceInvoiceLine2."Qty. per Unit of Measure"
                    else
                        Quantity := ValueEntry."Invoiced Quantity";
                    AddBufferEntry(
                      ServiceInvoiceLine2,
                      -Quantity,
                      ItemLedgerEntry."Posting Date");
                    TotalQuantity := TotalQuantity + ValueEntry."Invoiced Quantity";
                end;
                FirstValueEntryNo := ValueEntry."Entry No." + 1;
            until (ValueEntry.Next() = 0) or (TotalQuantity = 0);
    end;

    procedure GenerateBufferFromShipment(ServiceInvoiceLine: Record "Service Invoice Line")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine2: Record "Service Invoice Line";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        TotalQuantity: Decimal;
        Quantity: Decimal;
    begin
        TotalQuantity := 0;
        ServiceInvoiceHeader.SetCurrentKey("Order No.");
        ServiceInvoiceHeader.SetFilter("No.", '..%1', "Service Invoice Header"."No.");
        ServiceInvoiceHeader.SetRange("Order No.", "Service Invoice Header"."Order No.");
        if ServiceInvoiceHeader.Find('-') then
            repeat
                ServiceInvoiceLine2.SetRange("Document No.", ServiceInvoiceHeader."No.");
                ServiceInvoiceLine2.SetRange("Line No.", ServiceInvoiceLine."Line No.");
                ServiceInvoiceLine2.SetRange(Type, ServiceInvoiceLine.Type);
                ServiceInvoiceLine2.SetRange("No.", ServiceInvoiceLine."No.");
                ServiceInvoiceLine2.SetRange("Unit of Measure Code", ServiceInvoiceLine."Unit of Measure Code");
                if ServiceInvoiceLine2.Find('-') then
                    repeat
                        TotalQuantity := TotalQuantity + ServiceInvoiceLine2.Quantity;
                    until ServiceInvoiceLine2.Next() = 0;
            until ServiceInvoiceHeader.Next() = 0;

        ServiceShipmentLine.SetCurrentKey("Order No.", "Order Line No.");
        ServiceShipmentLine.SetRange("Order No.", "Service Invoice Header"."Order No.");
        ServiceShipmentLine.SetRange("Order Line No.", ServiceInvoiceLine."Line No.");
        ServiceShipmentLine.SetRange("Line No.", ServiceInvoiceLine."Line No.");
        ServiceShipmentLine.SetRange(Type, ServiceInvoiceLine.Type);
        ServiceShipmentLine.SetRange("No.", ServiceInvoiceLine."No.");
        ServiceShipmentLine.SetRange("Unit of Measure Code", ServiceInvoiceLine."Unit of Measure Code");
        ServiceShipmentLine.SetFilter(Quantity, '<>%1', 0);

        if ServiceShipmentLine.Find('-') then
            repeat
                if Abs(ServiceShipmentLine.Quantity) <= Abs(TotalQuantity - ServiceInvoiceLine.Quantity) then
                    TotalQuantity := TotalQuantity - ServiceShipmentLine.Quantity
                else begin
                    if Abs(ServiceShipmentLine.Quantity) > Abs(TotalQuantity) then
                        ServiceShipmentLine.Quantity := TotalQuantity;
                    Quantity :=
                      ServiceShipmentLine.Quantity - (TotalQuantity - ServiceInvoiceLine.Quantity);

                    TotalQuantity := TotalQuantity - ServiceShipmentLine.Quantity;
                    ServiceInvoiceLine.Quantity := ServiceInvoiceLine.Quantity - Quantity;

                    if ServiceShipmentHeader.Get(ServiceShipmentLine."Document No.") then
                        AddBufferEntry(
                          ServiceInvoiceLine,
                          Quantity,
                          ServiceShipmentHeader."Posting Date");
                end;
            until (ServiceShipmentLine.Next() = 0) or (TotalQuantity = 0);
    end;

    procedure AddBufferEntry(ServiceInvoiceLine: Record "Service Invoice Line"; QtyOnShipment: Decimal; PostingDate: Date)
    begin
        ServiceShipmentBuffer.SetRange("Document No.", ServiceInvoiceLine."Document No.");
        ServiceShipmentBuffer.SetRange("Line No.", ServiceInvoiceLine."Line No.");
        ServiceShipmentBuffer.SetRange("Posting Date", PostingDate);
        if ServiceShipmentBuffer.Find('-') then begin
            ServiceShipmentBuffer.Quantity := ServiceShipmentBuffer.Quantity + QtyOnShipment;
            ServiceShipmentBuffer.Modify();
            exit;
        end;

        ServiceShipmentBuffer."Document No." := ServiceInvoiceLine."Document No.";
        ServiceShipmentBuffer."Line No." := ServiceInvoiceLine."Line No.";
        ServiceShipmentBuffer."Entry No." := NextEntryNo;
        ServiceShipmentBuffer.Type := ServiceInvoiceLine.Type;
        ServiceShipmentBuffer."No." := ServiceInvoiceLine."No.";
        ServiceShipmentBuffer.Quantity := QtyOnShipment;
        ServiceShipmentBuffer."Posting Date" := PostingDate;
        ServiceShipmentBuffer.Insert();
        NextEntryNo := NextEntryNo + 1
    end;

    local procedure GetLineFeeNoteOnReportHist(SalesInvoiceHeaderNo: Code[20])
    var
        LineFeeNoteOnReportHist: Record "Line Fee Note on Report Hist.";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
    begin
        TempLineFeeNoteOnReportHist.DeleteAll();
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeaderNo);
        if not CustLedgerEntry.FindFirst() then
            exit;

        if not Customer.Get("Service Invoice Header"."Bill-to Customer No.") then
            exit;

        LineFeeNoteOnReportHist.SetRange("Cust. Ledger Entry No", CustLedgerEntry."Entry No.");
        LineFeeNoteOnReportHist.SetRange("Language Code", Customer."Language Code");
        if LineFeeNoteOnReportHist.FindSet() then
            repeat
                TempLineFeeNoteOnReportHist.Init();
                TempLineFeeNoteOnReportHist.Copy(LineFeeNoteOnReportHist);
                TempLineFeeNoteOnReportHist.Insert();
            until LineFeeNoteOnReportHist.Next() = 0
        else begin
            LineFeeNoteOnReportHist.SetRange("Language Code", LanguageMgt.GetUserLanguageCode());
            if LineFeeNoteOnReportHist.FindSet() then
                repeat
                    TempLineFeeNoteOnReportHist.Init();
                    TempLineFeeNoteOnReportHist.Copy(LineFeeNoteOnReportHist);
                    TempLineFeeNoteOnReportHist.Insert();
                until LineFeeNoteOnReportHist.Next() = 0;
        end;
    end;
}

