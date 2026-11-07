// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using Microsoft.Finance.SalesTax;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Globalization;
using System.Utilities;

report 10070 "Sales Invoice (Pre-Printed)"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/History/SalesInvoicePrePrinted.rdlc';
    Caption = 'Sales - Invoice';

    dataset
    {
        dataitem("Sales Invoice Header"; "Sales Invoice Header")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Sell-to Customer No.", "Bill-to Customer No.", "Ship-to Code", "No. Printed";
            RequestFilterHeading = 'Sales Invoice';
            column(Sales_Invoice_Header_No_; "No.")
            {
            }
            dataitem("Sales Invoice Line"; "Sales Invoice Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.");
                dataitem(SalesLineComments; "Sales Comment Line")
                {
                    DataItemLink = "No." = field("Document No."), "Document Line No." = field("Line No.");
                    DataItemTableView = sorting("Document Type", "No.", "Document Line No.", "Line No.") where("Document Type" = const("Posted Invoice"), "Print On Invoice" = const(true));

                    trigger OnAfterGetRecord()
                    begin
                        InsertTempLine(Comment, 10);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TempSalesInvoiceLine := "Sales Invoice Line";
                    TempSalesInvoiceLine.Insert();
                    HighestLineNo := "Line No.";
                end;

                trigger OnPreDataItem()
                begin
                    TempSalesInvoiceLine.Reset();
                    TempSalesInvoiceLine.DeleteAll();
                end;
            }
            dataitem("Sales Comment Line"; "Sales Comment Line")
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting("Document Type", "No.", "Document Line No.", "Line No.") where("Document Type" = const("Posted Invoice"), "Print On Invoice" = const(true), "Document Line No." = const(0));

                trigger OnAfterGetRecord()
                begin
                    InsertTempLine(Comment, 1000);
                end;

                trigger OnPreDataItem()
                begin
                    TempSalesInvoiceLine.Init();
                    TempSalesInvoiceLine."Document No." := "Sales Invoice Header"."No.";
                    TempSalesInvoiceLine."Line No." := HighestLineNo + 1000;
                    HighestLineNo := TempSalesInvoiceLine."Line No.";
                    TempSalesInvoiceLine.Insert();
                end;
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyAddress_1_; CompanyAddress[1])
                    {
                    }
                    column(CompanyAddress_2_; CompanyAddress[2])
                    {
                    }
                    column(CompanyAddress_3_; CompanyAddress[3])
                    {
                    }
                    column(CompanyAddress_4_; CompanyAddress[4])
                    {
                    }
                    column(CompanyAddress_5_; CompanyAddress[5])
                    {
                    }
                    column(CompanyAddress_6_; CompanyAddress[6])
                    {
                    }
                    column(CopyTxt; CopyTxt)
                    {
                    }
                    column(BillToAddress_1_; BillToAddress[1])
                    {
                    }
                    column(BillToAddress_2_; BillToAddress[2])
                    {
                    }
                    column(BillToAddress_3_; BillToAddress[3])
                    {
                    }
                    column(BillToAddress_4_; BillToAddress[4])
                    {
                    }
                    column(BillToAddress_5_; BillToAddress[5])
                    {
                    }
                    column(BillToAddress_6_; BillToAddress[6])
                    {
                    }
                    column(BillToAddress_7_; BillToAddress[7])
                    {
                    }
                    column(ShipmentMethod_Description; ShipmentMethod.Description)
                    {
                    }
                    column(Sales_Invoice_Header___Shipment_Date_; "Sales Invoice Header"."Shipment Date")
                    {
                    }
                    column(Sales_Invoice_Header___Due_Date_; "Sales Invoice Header"."Due Date")
                    {
                    }
                    column(PaymentTerms_Description; PaymentTerms.Description)
                    {
                    }
                    column(ShipToAddress_1_; ShipToAddress[1])
                    {
                    }
                    column(ShipToAddress_2_; ShipToAddress[2])
                    {
                    }
                    column(ShipToAddress_3_; ShipToAddress[3])
                    {
                    }
                    column(ShipToAddress_4_; ShipToAddress[4])
                    {
                    }
                    column(ShipToAddress_5_; ShipToAddress[5])
                    {
                    }
                    column(ShipToAddress_6_; ShipToAddress[6])
                    {
                    }
                    column(ShipToAddress_7_; ShipToAddress[7])
                    {
                    }
                    column(Sales_Invoice_Header___Bill_to_Customer_No__; "Sales Invoice Header"."Bill-to Customer No.")
                    {
                    }
                    column(Sales_Invoice_Header___Your_Reference_; "Sales Invoice Header"."Your Reference")
                    {
                    }
                    column(Sales_Invoice_Header___Order_Date_; "Sales Invoice Header"."Order Date")
                    {
                    }
                    column(Sales_Invoice_Header___Order_No__; "Sales Invoice Header"."Order No.")
                    {
                    }
                    column(SalesPurchPerson_Name; SalesPurchPerson.Name)
                    {
                    }
                    column(Sales_Invoice_Header___No__; "Sales Invoice Header"."No.")
                    {
                    }
                    column(Sales_Invoice_Header___Document_Date_; "Sales Invoice Header"."Document Date")
                    {
                    }
                    column(CompanyAddress_7_; CompanyAddress[7])
                    {
                    }
                    column(CompanyAddress_8_; CompanyAddress[8])
                    {
                    }
                    column(BillToAddress_8_; BillToAddress[8])
                    {
                    }
                    column(ShipToAddress_8_; ShipToAddress[8])
                    {
                    }
                    column(TaxRegLabel; TaxRegLabel)
                    {
                    }
                    column(TaxRegNo; TaxRegNo)
                    {
                    }
                    column(CopyNo; CopyNo)
                    {
                    }
                    column(SalesInvLine_Number; SalesInvLine.Number)
                    {
                    }
                    column(PageLoop_Number; Number)
                    {
                    }
                    dataitem(SalesInvLine; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(AmountExclInvDisc; AmountExclInvDisc)
                        {
                        }
                        column(TempSalesInvoiceLine__No__; TempSalesInvoiceLine."No.")
                        {
                        }
                        column(TempSalesInvoiceLine__Unit_of_Measure_; TempSalesInvoiceLine."Unit of Measure")
                        {
                        }
                        column(OrderedQuantity; OrderedQuantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(TempSalesInvoiceLine_Quantity; TempSalesInvoiceLine.Quantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(UnitPriceToPrint; UnitPriceToPrint)
                        {
                            DecimalPlaces = 2 : 5;
                        }
                        column(AmountExclInvDisc_Control53; AmountExclInvDisc)
                        {
                        }
                        column(LowDescription; LowDescriptionToPrint)
                        {
                        }
                        column(HighDescription; HighDescriptionToPrint)
                        {
                        }
                        column(PrintFooter; PrintFooter)
                        {
                        }
                        column(AmountExclInvDisc_Control40; AmountExclInvDisc)
                        {
                        }
                        column(TaxLiable; TaxLiable)
                        {
                        }
                        column(TempSalesInvoiceLine_Amount___TaxLiable; TempSalesInvoiceLine.Amount - TaxLiable)
                        {
                        }
                        column(AmountExclInvDisc_Control79; AmountExclInvDisc)
                        {
                        }
                        column(TempSalesInvoiceLine_Amount___AmountExclInvDisc; TempSalesInvoiceLine.Amount - AmountExclInvDisc)
                        {
                        }
                        column(TempSalesInvoiceLine__Amount_Including_VAT____TempSalesInvoiceLine_Amount; TempSalesInvoiceLine."Amount Including VAT" - TempSalesInvoiceLine.Amount)
                        {
                        }
                        column(TempSalesInvoiceLine__Amount_Including_VAT_; TempSalesInvoiceLine."Amount Including VAT")
                        {
                        }
                        column(BreakdownTitle; BreakdownTitle)
                        {
                        }
                        column(BreakdownLabel_1_; BreakdownLabel[1])
                        {
                        }
                        column(BreakdownLabel_2_; BreakdownLabel[2])
                        {
                        }
                        column(BreakdownAmt_1_; BreakdownAmt[1])
                        {
                        }
                        column(BreakdownAmt_2_; BreakdownAmt[2])
                        {
                        }
                        column(BreakdownAmt_3_; BreakdownAmt[3])
                        {
                        }
                        column(BreakdownLabel_3_; BreakdownLabel[3])
                        {
                        }
                        column(BreakdownAmt_4_; BreakdownAmt[4])
                        {
                        }
                        column(BreakdownLabel_4_; BreakdownLabel[4])
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            OnLineNumber := OnLineNumber + 1;

                            if OnLineNumber = 1 then
                                TempSalesInvoiceLine.Find('-')
                            else
                                TempSalesInvoiceLine.Next();

                            OrderedQuantity := 0;
                            if "Sales Invoice Header"."Order No." = '' then
                                OrderedQuantity := TempSalesInvoiceLine.Quantity
                            else
                                if OrderLine.Get(1, "Sales Invoice Header"."Order No.", TempSalesInvoiceLine."Line No.") then
                                    OrderedQuantity := OrderLine.Quantity
                                else begin
                                    ShipmentLine.SetRange("Order No.", "Sales Invoice Header"."Order No.");
                                    ShipmentLine.SetRange("Order Line No.", TempSalesInvoiceLine."Line No.");
                                    if ShipmentLine.Find('-') then
                                        repeat
                                            OrderedQuantity := OrderedQuantity + ShipmentLine.Quantity;
                                        until 0 = ShipmentLine.Next();
                                end;

                            DescriptionToPrint := TempSalesInvoiceLine.Description + ' ' + TempSalesInvoiceLine."Description 2";
                            if TempSalesInvoiceLine.Type = TempSalesInvoiceLine.Type::" " then begin
                                if OnLineNumber < NumberOfLines then begin
                                    TempSalesInvoiceLine.Next();
                                    if TempSalesInvoiceLine.Type = TempSalesInvoiceLine.Type::" " then begin
                                        DescriptionToPrint :=
                                          CopyStr(DescriptionToPrint + ' ' + TempSalesInvoiceLine.Description + ' ' + TempSalesInvoiceLine."Description 2", 1, MaxStrLen(DescriptionToPrint));
                                        OnLineNumber := OnLineNumber + 1;
                                        SalesInvLine.Next();
                                    end else
                                        TempSalesInvoiceLine.Next(-1);
                                end;
                                TempSalesInvoiceLine."No." := '';
                                TempSalesInvoiceLine."Unit of Measure" := '';
                                TempSalesInvoiceLine.Amount := 0;
                                TempSalesInvoiceLine."Amount Including VAT" := 0;
                                TempSalesInvoiceLine."Inv. Discount Amount" := 0;
                                TempSalesInvoiceLine.Quantity := 0;
                            end else
                                if TempSalesInvoiceLine.Type = TempSalesInvoiceLine.Type::"G/L Account" then
                                    TempSalesInvoiceLine."No." := '';

                            if TempSalesInvoiceLine."No." = '' then begin
                                HighDescriptionToPrint := DescriptionToPrint;
                                LowDescriptionToPrint := '';
                            end else begin
                                HighDescriptionToPrint := '';
                                LowDescriptionToPrint := DescriptionToPrint;
                            end;

                            if TempSalesInvoiceLine.Amount <> TempSalesInvoiceLine."Amount Including VAT" then
                                TaxLiable := TempSalesInvoiceLine.Amount
                            else
                                TaxLiable := 0;

                            AmountExclInvDisc := TempSalesInvoiceLine.Amount + TempSalesInvoiceLine."Inv. Discount Amount";

                            if TempSalesInvoiceLine.Quantity = 0 then
                                UnitPriceToPrint := 0
                            // so it won't print
                            else
                                UnitPriceToPrint := Round(AmountExclInvDisc / TempSalesInvoiceLine.Quantity, 0.00001);
                            if OnLineNumber = NumberOfLines then
                                PrintFooter := true;
                        end;

                        trigger OnPreDataItem()
                        begin
                            Clear(TaxLiable);
                            Clear(AmountExclInvDisc);
                            NumberOfLines := TempSalesInvoiceLine.Count();
                            SetRange(Number, 1, NumberOfLines);
                            OnLineNumber := 0;
                            PrintFooter := false;
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if CopyNo = NoLoops then begin
                        if not CurrReport.Preview then
                            SalesInvPrinted.Run("Sales Invoice Header");
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
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");

                if PrintCompany then
                    if RespCenter.Get("Responsibility Center") then begin
                        FormatAddress.RespCenter(CompanyAddress, RespCenter);
                        CompanyInformation."Phone No." := RespCenter."Phone No.";
                        CompanyInformation."Fax No." := RespCenter."Fax No.";
                    end;

                if not Customer.Get("Bill-to Customer No.") then begin
                    Clear(Customer);
                    "Bill-to Name" := Text009;
                    "Ship-to Name" := Text009;
                end;

                FormatAddress.SalesInvBillTo(BillToAddress, "Sales Invoice Header");
                FormatAddress.SalesInvShipTo(ShipToAddress, ShipToAddress, "Sales Invoice Header");

                FormatDocumentFields("Sales Invoice Header");

                if LogInteraction then
                    if not CurrReport.Preview then
                        if "Bill-to Contact No." <> '' then
                            SegManagement.LogDocument(
                              4, "No.", 0, 0, DATABASE::Contact, "Bill-to Contact No.", "Salesperson Code",
                              "Campaign No.", "Posting Description", '')
                        else
                            SegManagement.LogDocument(
                              4, "No.", 0, 0, DATABASE::Customer, "Bill-to Customer No.", "Salesperson Code",
                              "Campaign No.", "Posting Description", '');

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
                    SalesTaxCalc.StartSalesTaxCalculation();
                    if TaxArea."Use External Tax Engine" then
                        SalesTaxCalc.CallExternalTaxEngineForDoc(DATABASE::"Sales Invoice Header", 0, "No.")
                    else begin
                        SalesTaxCalc.AddSalesInvoiceLines("No.");
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
                    field(NoCopies; NoCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Number of Copies';
                        ToolTip = 'Specifies the number of copies of each document (in addition to the original) that you want to print.';
                    }
                    field(PrintCompany; PrintCompany)
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
            InitLogInteraction();
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ShipmentLine.SetCurrentKey("Order No.", "Order Line No.");
        if not CurrReport.UseRequestPage then
            InitLogInteraction();

        CompanyInformation.Get();
        SalesSetup.Get();

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
        ShipmentMethod: Record "Shipment Method";
        PaymentTerms: Record "Payment Terms";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyInformation: Record "Company Information";
        SalesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        OrderLine: Record "Sales Line";
        ShipmentLine: Record "Sales Shipment Line";
        TempSalesInvoiceLine: Record "Sales Invoice Line" temporary;
        RespCenter: Record "Responsibility Center";
        TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary;
        TaxArea: Record "Tax Area";
        LanguageMgt: Codeunit Language;
        SalesInvPrinted: Codeunit "Sales Inv.-Printed";
        FormatAddress: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        SalesTaxCalc: Codeunit "Sales Tax Calculate";
        SegManagement: Codeunit SegManagement;
        CompanyAddress: array[8] of Text[100];
        BillToAddress: array[8] of Text[100];
        ShipToAddress: array[8] of Text[100];
        CopyTxt: Text[10];
        SalespersonText: Text[50];
        DescriptionToPrint: Text[210];
        HighDescriptionToPrint: Text[210];
        LowDescriptionToPrint: Text[210];
        PrintCompany: Boolean;
        PrintFooter: Boolean;
        NoCopies: Integer;
        NoLoops: Integer;
        CopyNo: Integer;
        NumberOfLines: Integer;
        OnLineNumber: Integer;
        HighestLineNo: Integer;
        LogInteraction: Boolean;
        Text000: Label 'COPY';
        TaxRegNo: Text[30];
        TaxRegLabel: Text;
        TotalTaxLabel: Text;
        BreakdownTitle: Text;
        BreakdownLabel: array[4] of Text[30];
        BreakdownAmt: array[4] of Decimal;
        BrkIdx: Integer;
        PrevPrintOrder: Integer;
        PrevTaxPercent: Decimal;
        Text003: Label 'Sales Tax Breakdown:';
        Text004: Label 'Other Taxes';
        Text005: Label 'Total Sales Tax:';
        Text006: Label 'Tax Breakdown:';
        Text007: Label 'Total Tax:';
        Text008: Label 'Tax:';
        Text009: Label 'VOID INVOICE';
        LogInteractionEnable: Boolean;

    procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Sales Inv.") <> '';
    end;

    local procedure FormatDocumentFields(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        FormatDocument.SetSalesPerson(SalesPurchPerson, SalesInvoiceHeader."Salesperson Code", SalespersonText);
        FormatDocument.SetPaymentTerms(PaymentTerms, SalesInvoiceHeader."Payment Terms Code", SalesInvoiceHeader."Language Code");
        FormatDocument.SetShipmentMethod(ShipmentMethod, SalesInvoiceHeader."Shipment Method Code", SalesInvoiceHeader."Language Code");
    end;

    local procedure InsertTempLine(Comment: Text[80]; IncrNo: Integer)
    begin
        TempSalesInvoiceLine.Init();
        TempSalesInvoiceLine."Document No." := "Sales Invoice Header"."No.";
        TempSalesInvoiceLine."Line No." := HighestLineNo + IncrNo;
        HighestLineNo := TempSalesInvoiceLine."Line No.";
        FormatDocument.ParseComment(Comment, TempSalesInvoiceLine.Description, TempSalesInvoiceLine."Description 2");
        TempSalesInvoiceLine.Insert();
    end;
}

