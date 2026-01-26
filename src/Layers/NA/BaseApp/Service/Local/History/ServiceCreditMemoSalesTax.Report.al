// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.CRM.Team;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using Microsoft.Service.History;
using System.Globalization;
using System.Utilities;

report 10473 "Service Credit Memo-Sales Tax"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Local/History/ServiceCreditMemoSalesTax.rdlc';
    Caption = 'Service Credit Memo';
    Permissions = TableData "Sales Shipment Buffer" = rimd;

    dataset
    {
        dataitem("Service Cr.Memo Header"; "Service Cr.Memo Header")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Customer No.", "No. Printed";
            RequestFilterHeading = 'Service Credit Memo';
            dataitem("Service Cr.Memo Line"; "Service Cr.Memo Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    TempServCrMemoLine := "Service Cr.Memo Line";
                    TempServCrMemoLine.Insert();
                end;

                trigger OnPreDataItem()
                begin
                    TempServCrMemoLine.Reset();
                    TempServCrMemoLine.DeleteAll();
                end;
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyInfo2Picture; CompanyInfo2.Picture)
                    {
                    }
                    column(CompanyInfo3Picture; CompanyInfo3.Picture)
                    {
                    }
                    column(CompanyInfo1Picture; CompanyInfo1.Picture)
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
                    column(AppltoDocType_ServCrMemoHeader; "Service Cr.Memo Header"."Applies-to Doc. Type")
                    {
                    }
                    column(AppltoDocNo_ServCrMemoHeader; "Service Cr.Memo Header"."Applies-to Doc. No.")
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
                    column(BilltoCustNo_ServCrMemoHeader; "Service Cr.Memo Header"."Bill-to Customer No.")
                    {
                    }
                    column(YourRef_ServCrMemoHeader; "Service Cr.Memo Header"."Your Reference")
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(No_ServCrMemoHeader; "Service Cr.Memo Header"."No.")
                    {
                    }
                    column(DocDate_ServCrMemoHeader; "Service Cr.Memo Header"."Document Date")
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
                    column(TaxRegLabel; TaxRegLabel)
                    {
                    }
                    column(TaxRegNo; TaxRegNo)
                    {
                    }
                    column(PrintFooter; PrintFooter)
                    {
                    }
                    column(CopyNo; CopyNo)
                    {
                    }
                    column(CustTaxIdentificationType; Format(Cust."Tax Identification Type"))
                    {
                    }
                    column(CreditCaption; Text010)
                    {
                    }
                    column(ToCaption; Text011)
                    {
                    }
                    column(ApplytoTypeCaption; Text012)
                    {
                    }
                    column(ApplytoNumberCaption; Text013)
                    {
                    }
                    column(CustomerIDCaption; Text014)
                    {
                    }
                    column(PONumberCaption; Text015)
                    {
                    }
                    column(SalesPersonCaption; Text016)
                    {
                    }
                    column(ShipCaption; Text017)
                    {
                    }
                    column(CreditMemoCaption; Text018)
                    {
                    }
                    column(CreditMemoNumberCaption; Text019)
                    {
                    }
                    column(CreditMemoDateCaption; Text020)
                    {
                    }
                    column(PageCaption; Text021)
                    {
                    }
                    column(TaxIdentTypeCaption; Text022)
                    {
                    }
                    dataitem(ServCrMemoLine; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(Number_IntegerLine; Number)
                        {
                        }
                        column(AmountExclInvDisc; AmountExclInvDisc)
                        {
                        }
                        column(TempServCrMemoLineNo; TempServCrMemoLine."No.")
                        {
                        }
                        column(TempServCrMemoLineUOM; TempServCrMemoLine."Unit of Measure")
                        {
                        }
                        column(TempServCrMemoLineQty; TempServCrMemoLine.Quantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(UnitPriceToPrint; UnitPriceToPrint)
                        {
                            DecimalPlaces = 2 : 5;
                        }
                        column(TempServCrMemoLineDesc; TempServCrMemoLine.Description + ' ' + TempServCrMemoLine."Description 2")
                        {
                        }
                        column(BreakdownLabel1; BreakdownLabel[1])
                        {
                        }
                        column(BreakdownTitle; BreakdownTitle)
                        {
                        }
                        column(BreakdownAmt1; BreakdownAmt[1])
                        {
                        }
                        column(TaxLiable; TaxLiable)
                        {
                        }
                        column(TempServCrMemoLineAmtTaxLiable; TempServCrMemoLine.Amount - TaxLiable)
                        {
                        }
                        column(BreakdownLabel2; BreakdownLabel[2])
                        {
                        }
                        column(BreakdownAmt2; BreakdownAmt[2])
                        {
                        }
                        column(TotalTaxLabel; TotalTaxLabel)
                        {
                        }
                        column(BreakdownAmt3; BreakdownAmt[3])
                        {
                        }
                        column(BreakdownLabel3; BreakdownLabel[3])
                        {
                        }
                        column(BreakdownAmt4; BreakdownAmt[4])
                        {
                        }
                        column(BreakdownLabel4; BreakdownLabel[4])
                        {
                        }
                        column(TempServCrMemoLineAmtAmtExclInvDisc; TempServCrMemoLine.Amount - AmountExclInvDisc)
                        {
                        }
                        column(TempServCrMemoLineAmtInclVATAmount; TempServCrMemoLine."Amount Including VAT" - TempServCrMemoLine.Amount)
                        {
                        }
                        column(TempServCrMemoLineAmtInclVAT; TempServCrMemoLine."Amount Including VAT")
                        {
                        }
                        column(ItemNoCaption; Text023)
                        {
                        }
                        column(UnitCaption; Text024)
                        {
                        }
                        column(DescriptionCaption; Text025)
                        {
                        }
                        column(QuantityCaption; Text026)
                        {
                        }
                        column(UnitPriceCaption; Text027)
                        {
                        }
                        column(TotalPriceCaption; Text028)
                        {
                        }
                        column(AmountSubjecttoSalesTaxCaption; Text029)
                        {
                        }
                        column(AmountExemptfromSalesTaxCaption; Text030)
                        {
                        }
                        column(InvoiceDiscountCaption; Text031)
                        {
                        }
                        column(SubtotalCaption; Text032)
                        {
                        }
                        column(TotalCaption; Text033)
                        {
                        }
                        dataitem("Service Shipment Buffer"; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(ServiceShptBufferPostDate; ServiceShipmentBuffer."Posting Date")
                            {
                            }
                            column(ServiceShptBufferQty; ServiceShipmentBuffer.Quantity)
                            {
                                DecimalPlaces = 0 : 5;
                            }
                            column(ReturnReceiptCaption; Text034)
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
                                    TempServCrMemoLine.Amount := 0;
                                    TempServCrMemoLine."Amount Including VAT" := 0;
                                end
                            end;

                            trigger OnPreDataItem()
                            begin
                                SetRange(Number, 1, ServiceShipmentBuffer.Count);
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            OnLineNumber := OnLineNumber + 1;
                            if OnLineNumber = 1 then
                                TempServCrMemoLine.Find('-')
                            else
                                TempServCrMemoLine.Next();

                            if TempServCrMemoLine.Type = TempServCrMemoLine.Type::" " then begin
                                TempServCrMemoLine."No." := '';
                                TempServCrMemoLine."Unit of Measure" := '';
                                TempServCrMemoLine.Amount := 0;
                                TempServCrMemoLine."Amount Including VAT" := 0;
                                TempServCrMemoLine."Inv. Discount Amount" := 0;
                                TempServCrMemoLine.Quantity := 0;
                            end else
                                if TempServCrMemoLine.Type = TempServCrMemoLine.Type::"G/L Account" then
                                    TempServCrMemoLine."No." := '';

                            if TempServCrMemoLine.Amount <> TempServCrMemoLine."Amount Including VAT" then
                                TaxLiable := TempServCrMemoLine.Amount
                            else
                                TaxLiable := 0;

                            AmountExclInvDisc := TempServCrMemoLine.Amount + TempServCrMemoLine."Inv. Discount Amount";

                            if TempServCrMemoLine.Quantity = 0 then
                                UnitPriceToPrint := 0
                            // so it won't print
                            else
                                UnitPriceToPrint := Round(AmountExclInvDisc / TempServCrMemoLine.Quantity, 0.00001);

                            if OnLineNumber = NumberOfLines then
                                PrintFooter := true;
                        end;

                        trigger OnPreDataItem()
                        begin
                            Clear(TaxLiable);
                            Clear(AmountExclInvDisc);
                            NumberOfLines := TempServCrMemoLine.Count();
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
                            ServiceCrMemoPrinted.Run("Service Cr.Memo Header");
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
                if "Salesperson Code" = '' then
                    Clear(SalesPurchPerson)
                else
                    SalesPurchPerson.Get("Salesperson Code");

                if "Bill-to Customer No." = '' then begin
                    "Bill-to Name" := Text009;
                    "Ship-to Name" := Text009;
                end;

                ServiceFormatAddress.ServiceCrMemoBillTo(BillToAddress, "Service Cr.Memo Header");
                ServiceFormatAddress.ServiceCrMemoShipTo(ShipToAddress, ShipToAddress, "Service Cr.Memo Header");

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
                        ServSalesTaxCalc.CallExternalTaxEngineForDoc(DATABASE::"Service Cr.Memo Header", 0, "No.")
                    else begin
                        ServSalesTaxCalc.AddServCrMemoLines("No.");
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
        CompanyInformation.Get();
        SalesSetup.Get();

        case SalesSetup."Logo Position on Documents" of
            SalesSetup."Logo Position on Documents"::"No Logo":
                ;
            SalesSetup."Logo Position on Documents"::Left:
                begin
                    CompanyInfo3.Get();
                    CompanyInfo3.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Right:
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
        UnitPriceToPrint: Decimal;
        AmountExclInvDisc: Decimal;
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyInformation: Record "Company Information";
        SalesSetup: Record "Sales & Receivables Setup";
        TempServCrMemoLine: Record "Service Cr.Memo Line" temporary;
        ServiceShipmentBuffer: Record "Service Shipment Buffer" temporary;
        RespCenter: Record "Responsibility Center";
        TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary;
        TaxArea: Record "Tax Area";
        Cust: Record Customer;
        LanguageMgt: Codeunit Language;
        CompanyAddress: array[8] of Text[100];
        BillToAddress: array[8] of Text[100];
        ShipToAddress: array[8] of Text[100];
        CopyTxt: Text[10];
        PrintCompany: Boolean;
        PrintFooter: Boolean;
        NoCopies: Integer;
        NoLoops: Integer;
        CopyNo: Integer;
        NumberOfLines: Integer;
        OnLineNumber: Integer;
        ServiceCrMemoPrinted: Codeunit "Service Cr. Memo-Printed";
        FormatAddress: Codeunit "Format Address";
        ServiceFormatAddress: Codeunit "Service Format Address";
        ServSalesTaxCalc: Codeunit "Serv. Sales Tax Calculate";
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
        NextEntryNo: Integer;
        FirstValueEntryNo: Integer;
        Text003: Label 'Sales Tax Breakdown:';
        Text004: Label 'Other Taxes';
        Text005: Label 'Total Sales Tax:';
        Text006: Label 'Tax Breakdown:';
        Text007: Label 'Total Tax:';
        Text008: Label 'Tax:';
        Text009: Label 'VOID CREDIT MEMO';
        Text010: Label 'Credit';
        Text011: Label 'To:';
        Text012: Label 'Apply to Type';
        Text013: Label 'Apply to Number';
        Text014: Label 'Customer ID';
        Text015: Label 'P.O. Number';
        Text016: Label 'SalesPerson';
        Text017: Label 'Ship';
        Text018: Label 'Credit Memo';
        Text019: Label 'Credit Memo Number:';
        Text020: Label 'Credit Memo Date:';
        Text021: Label 'Page';
        Text022: Label 'Tax Ident. Type';
        Text023: Label 'Item No.';
        Text024: Label 'Unit';
        Text025: Label 'Description';
        Text026: Label 'Quantity';
        Text027: Label 'Unit Price';
        Text028: Label 'Total Price';
        Text029: Label 'Amount Subject to Sales Tax';
        Text030: Label 'Amount Exempt from Sales Tax';
        Text031: Label 'Invoice Discount:';
        Text032: Label 'Subtotal:';
        Text033: Label 'Total:';
        Text034: Label 'Return Receipt';

    protected var
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CompanyInfo3: Record "Company Information";

    procedure FindPostedShipmentDate(): Date
    var
        ServiceShipmentBuffer2: Record "Service Shipment Buffer" temporary;
    begin
        NextEntryNo := 1;

        case "Service Cr.Memo Line".Type of
            "Service Cr.Memo Line".Type::Item:
                GenerateBufferFromValueEntry("Service Cr.Memo Line");
            "Service Cr.Memo Line".Type::" ":
                exit(0D);
        end;

        ServiceShipmentBuffer.Reset();
        ServiceShipmentBuffer.SetRange("Document No.", "Service Cr.Memo Line"."Document No.");
        ServiceShipmentBuffer.SetRange("Line No.", "Service Cr.Memo Line"."Line No.");

        if ServiceShipmentBuffer.Find('-') then begin
            ServiceShipmentBuffer2 := ServiceShipmentBuffer;
            if ServiceShipmentBuffer.Next() = 0 then begin
                ServiceShipmentBuffer.Get(ServiceShipmentBuffer2."Document No.", ServiceShipmentBuffer2."Line No.", ServiceShipmentBuffer2.
                  "Entry No.");
                ServiceShipmentBuffer.Delete();
                exit(ServiceShipmentBuffer2."Posting Date");
            end;
            ServiceShipmentBuffer.CalcSums(Quantity);
            if ServiceShipmentBuffer.Quantity <> "Service Cr.Memo Line".Quantity then begin
                ServiceShipmentBuffer.DeleteAll();
                exit("Service Cr.Memo Header"."Posting Date");
            end;
        end else
            exit("Service Cr.Memo Header"."Posting Date");
    end;

    procedure GenerateBufferFromValueEntry(ServiceCrMemoLine2: Record "Service Cr.Memo Line")
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TotalQuantity: Decimal;
        Quantity: Decimal;
    begin
        TotalQuantity := ServiceCrMemoLine2."Quantity (Base)";
        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", ServiceCrMemoLine2."Document No.");
        ValueEntry.SetRange("Posting Date", "Service Cr.Memo Header"."Posting Date");
        ValueEntry.SetRange("Item Charge No.", '');
        ValueEntry.SetFilter("Entry No.", '%1..', FirstValueEntryNo);
        if ValueEntry.Find('-') then
            repeat
                if ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then begin
                    if ServiceCrMemoLine2."Qty. per Unit of Measure" <> 0 then
                        Quantity := ValueEntry."Invoiced Quantity" / ServiceCrMemoLine2."Qty. per Unit of Measure"
                    else
                        Quantity := ValueEntry."Invoiced Quantity";
                    AddBufferEntry(
                      ServiceCrMemoLine2,
                      -Quantity,
                      ItemLedgerEntry."Posting Date");
                    TotalQuantity := TotalQuantity - ValueEntry."Invoiced Quantity";
                end;
                FirstValueEntryNo := ValueEntry."Entry No." + 1;
            until (ValueEntry.Next() = 0) or (TotalQuantity = 0);
    end;

    procedure AddBufferEntry(ServiceCrMemoLine: Record "Service Cr.Memo Line"; QtyOnShipment: Decimal; PostingDate: Date)
    begin
        ServiceShipmentBuffer.SetRange("Document No.", ServiceCrMemoLine."Document No.");
        ServiceShipmentBuffer.SetRange("Line No.", ServiceCrMemoLine."Line No.");
        ServiceShipmentBuffer.SetRange("Posting Date", PostingDate);
        if ServiceShipmentBuffer.Find('-') then begin
            ServiceShipmentBuffer.Quantity := ServiceShipmentBuffer.Quantity - QtyOnShipment;
            ServiceShipmentBuffer.Modify();
            exit;
        end;

        ServiceShipmentBuffer.Init();
        ServiceShipmentBuffer."Document No." := ServiceCrMemoLine."Document No.";
        ServiceShipmentBuffer."Line No." := ServiceCrMemoLine."Line No.";
        ServiceShipmentBuffer."Entry No." := NextEntryNo;
        ServiceShipmentBuffer.Type := ServiceCrMemoLine.Type;
        ServiceShipmentBuffer."No." := ServiceCrMemoLine."No.";
        ServiceShipmentBuffer.Quantity := -QtyOnShipment;
        ServiceShipmentBuffer."Posting Date" := PostingDate;
        ServiceShipmentBuffer.Insert();
        NextEntryNo := NextEntryNo + 1
    end;
}

