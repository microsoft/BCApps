// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Posting;
using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Security.User;
using System.Utilities;

report 10485 "Service Document - Test NA"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Local/Reports/ServiceDocumentTestNA.rdlc';
    Caption = 'Service Document - Test';
    WordMergeDataItem = "Service Header";

    dataset
    {
        dataitem("Service Header"; "Service Header")
        {
            DataItemTableView = where("Document Type" = filter(<> Quote));
            RequestFilterFields = "Document Type", "No.";
            RequestFilterHeading = 'Service Document';
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(Service_Document___TestCaption; Service_Document___TestCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(STRSUBSTNO_Text014_ServiceHeaderFilter_; StrSubstNo(Text014, ServiceHeaderFilter))
                {
                }
                column(ShowServiceHeaderFilter; ServiceHeaderFilter)
                {
                }
                column(ShipInvText; ShipInvText)
                {
                }
                column(ReceiveInvText; ReceiveInvText)
                {
                }
                column(Service_Header___Customer_No__; "Service Header"."Customer No.")
                {
                }
                column(ShipToAddr_8_; ShipToAddr[8])
                {
                }
                column(ShipToAddr_7_; ShipToAddr[7])
                {
                }
                column(ShipToAddr_6_; ShipToAddr[6])
                {
                }
                column(ShipToAddr_5_; ShipToAddr[5])
                {
                }
                column(ShipToAddr_4_; ShipToAddr[4])
                {
                }
                column(ShipToAddr_3_; ShipToAddr[3])
                {
                }
                column(ShipToAddr_2_; ShipToAddr[2])
                {
                }
                column(ShipToAddr_1_; ShipToAddr[1])
                {
                }
                column(Service_Header___Ship_to_Code_; "Service Header"."Ship-to Code")
                {
                }
                column(FORMAT__Service_Header___Document_Type____________Service_Header___No__; Format("Service Header"."Document Type") + ' ' + "Service Header"."No.")
                {
                }
                column(FORMAT__Service_Header___Prices_Including_VAT__; Format("Service Header"."Prices Including VAT"))
                {
                }
                column(BillToAddr_8_; BillToAddr[8])
                {
                }
                column(BillToAddr_7_; BillToAddr[7])
                {
                }
                column(BillToAddr_6_; BillToAddr[6])
                {
                }
                column(BillToAddr_5_; BillToAddr[5])
                {
                }
                column(BillToAddr_4_; BillToAddr[4])
                {
                }
                column(BillToAddr_3_; BillToAddr[3])
                {
                }
                column(BillToAddr_2_; BillToAddr[2])
                {
                }
                column(BillToAddr_1_; BillToAddr[1])
                {
                }
                column(Service_Header___Bill_to_Customer_No__; "Service Header"."Bill-to Customer No.")
                {
                }
                column(ShowBillAddrInfo; "Service Header"."Bill-to Customer No." <> "Service Header"."Customer No.")
                {
                }
                column(Service_Header___Salesperson_Code_; "Service Header"."Salesperson Code")
                {
                }
                column(Service_Header___Your_Reference_; "Service Header"."Your Reference")
                {
                }
                column(Service_Header___Customer_Posting_Group_; "Service Header"."Customer Posting Group")
                {
                }
                column(Service_Header___Posting_Date_; Format("Service Header"."Posting Date"))
                {
                }
                column(Service_Header___Document_Date_; Format("Service Header"."Document Date"))
                {
                }
                column(Service_Header___Prices_Including_VAT_; "Service Header"."Prices Including VAT")
                {
                }
                column(ShowQuote; "Service Header"."Document Type" = "Service Header"."Document Type"::Quote)
                {
                }
                column(Service_Header___Payment_Terms_Code_; "Service Header"."Payment Terms Code")
                {
                }
                column(Service_Header___Payment_Discount___; "Service Header"."Payment Discount %")
                {
                }
                column(Service_Header___Due_Date_; Format("Service Header"."Due Date"))
                {
                }
                column(Service_Header___Customer_Disc__Group_; "Service Header"."Customer Disc. Group")
                {
                }
                column(Service_Header___Pmt__Discount_Date_; Format("Service Header"."Pmt. Discount Date"))
                {
                }
                column(Service_Header___Invoice_Disc__Code_; "Service Header"."Invoice Disc. Code")
                {
                }
                column(Service_Header___Payment_Method_Code_; "Service Header"."Payment Method Code")
                {
                }
                column(Service_Header___Posting_Date__Control105; Format("Service Header"."Posting Date"))
                {
                }
                column(Service_Header___Document_Date__Control106; Format("Service Header"."Document Date"))
                {
                }
                column(Service_Header___Order_Date_; Format("Service Header"."Order Date"))
                {
                }
                column(Service_Header___Prices_Including_VAT__Control194; "Service Header"."Prices Including VAT")
                {
                }
                column(ShowOrder; "Service Header"."Document Type" = "Service Header"."Document Type"::Order)
                {
                }
                column(Service_Header___Payment_Terms_Code__Control18; "Service Header"."Payment Terms Code")
                {
                }
                column(Service_Header___Due_Date__Control19; Format("Service Header"."Due Date"))
                {
                }
                column(Service_Header___Pmt__Discount_Date__Control22; Format("Service Header"."Pmt. Discount Date"))
                {
                }
                column(Service_Header___Payment_Discount____Control23; "Service Header"."Payment Discount %")
                {
                }
                column(Service_Header___Payment_Method_Code__Control26; "Service Header"."Payment Method Code")
                {
                }
                column(Service_Header___Customer_Disc__Group__Control100; "Service Header"."Customer Disc. Group")
                {
                }
                column(Service_Header___Invoice_Disc__Code__Control102; "Service Header"."Invoice Disc. Code")
                {
                }
                column(Service_Header___Customer_Posting_Group__Control130; "Service Header"."Customer Posting Group")
                {
                }
                column(Service_Header___Posting_Date__Control131; Format("Service Header"."Posting Date"))
                {
                }
                column(Service_Header___Document_Date__Control132; Format("Service Header"."Document Date"))
                {
                }
                column(Service_Header___Prices_Including_VAT__Control196; "Service Header"."Prices Including VAT")
                {
                }
                column(ShowInvoice; "Service Header"."Document Type" = "Service Header"."Document Type"::Invoice)
                {
                }
                column(Service_Header___Applies_to_Doc__Type_; "Service Header"."Applies-to Doc. Type")
                {
                }
                column(Service_Header___Applies_to_Doc__No__; "Service Header"."Applies-to Doc. No.")
                {
                }
                column(Service_Header___Customer_Posting_Group__Control136; "Service Header"."Customer Posting Group")
                {
                }
                column(Service_Header___Posting_Date__Control137; Format("Service Header"."Posting Date"))
                {
                }
                column(Service_Header___Document_Date__Control138; Format("Service Header"."Document Date"))
                {
                }
                column(Service_Header___Prices_Including_VAT__Control198; "Service Header"."Prices Including VAT")
                {
                }
                column(ShowCreditMemo; "Service Header"."Document Type" = "Service Header"."Document Type"::"Credit Memo")
                {
                }
                column(Service_Header___Customer_No__Caption; "Service Header".FieldCaption("Customer No."))
                {
                }
                column(Ship_toCaption; Ship_toCaptionLbl)
                {
                }
                column(CustomerCaption; CustomerCaptionLbl)
                {
                }
                column(Service_Header___Ship_to_Code_Caption; "Service Header".FieldCaption("Ship-to Code"))
                {
                }
                column(Bill_toCaption; Bill_toCaptionLbl)
                {
                }
                column(Service_Header___Bill_to_Customer_No__Caption; "Service Header".FieldCaption("Bill-to Customer No."))
                {
                }
                column(Service_Header___Salesperson_Code_Caption; "Service Header".FieldCaption("Salesperson Code"))
                {
                }
                column(Service_Header___Your_Reference_Caption; "Service Header".FieldCaption("Your Reference"))
                {
                }
                column(Service_Header___Customer_Posting_Group_Caption; "Service Header".FieldCaption("Customer Posting Group"))
                {
                }
                column(Service_Header___Posting_Date_Caption; Service_Header___Posting_Date_CaptionLbl)
                {
                }
                column(Service_Header___Document_Date_Caption; Service_Header___Document_Date_CaptionLbl)
                {
                }
                column(Service_Header___Prices_Including_VAT_Caption; "Service Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(Service_Header___Payment_Terms_Code_Caption; "Service Header".FieldCaption("Payment Terms Code"))
                {
                }
                column(Service_Header___Payment_Discount___Caption; "Service Header".FieldCaption("Payment Discount %"))
                {
                }
                column(Service_Header___Due_Date_Caption; Service_Header___Due_Date_CaptionLbl)
                {
                }
                column(Service_Header___Customer_Disc__Group_Caption; "Service Header".FieldCaption("Customer Disc. Group"))
                {
                }
                column(Service_Header___Pmt__Discount_Date_Caption; Service_Header___Pmt__Discount_Date_CaptionLbl)
                {
                }
                column(Service_Header___Invoice_Disc__Code_Caption; "Service Header".FieldCaption("Invoice Disc. Code"))
                {
                }
                column(Service_Header___Payment_Method_Code_Caption; "Service Header".FieldCaption("Payment Method Code"))
                {
                }
                column(Service_Header___Posting_Date__Control105Caption; Service_Header___Posting_Date__Control105CaptionLbl)
                {
                }
                column(Service_Header___Document_Date__Control106Caption; Service_Header___Document_Date__Control106CaptionLbl)
                {
                }
                column(Service_Header___Order_Date_Caption; Service_Header___Order_Date_CaptionLbl)
                {
                }
                column(Service_Header___Prices_Including_VAT__Control194Caption; "Service Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(Service_Header___Payment_Terms_Code__Control18Caption; "Service Header".FieldCaption("Payment Terms Code"))
                {
                }
                column(Service_Header___Payment_Discount____Control23Caption; "Service Header".FieldCaption("Payment Discount %"))
                {
                }
                column(Service_Header___Due_Date__Control19Caption; Service_Header___Due_Date__Control19CaptionLbl)
                {
                }
                column(Service_Header___Pmt__Discount_Date__Control22Caption; Service_Header___Pmt__Discount_Date__Control22CaptionLbl)
                {
                }
                column(Service_Header___Payment_Method_Code__Control26Caption; "Service Header".FieldCaption("Payment Method Code"))
                {
                }
                column(Service_Header___Customer_Disc__Group__Control100Caption; "Service Header".FieldCaption("Customer Disc. Group"))
                {
                }
                column(Service_Header___Invoice_Disc__Code__Control102Caption; "Service Header".FieldCaption("Invoice Disc. Code"))
                {
                }
                column(Service_Header___Customer_Posting_Group__Control130Caption; "Service Header".FieldCaption("Customer Posting Group"))
                {
                }
                column(Service_Header___Posting_Date__Control131Caption; Service_Header___Posting_Date__Control131CaptionLbl)
                {
                }
                column(Service_Header___Document_Date__Control132Caption; Service_Header___Document_Date__Control132CaptionLbl)
                {
                }
                column(Service_Header___Prices_Including_VAT__Control196Caption; "Service Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(Service_Header___Applies_to_Doc__Type_Caption; "Service Header".FieldCaption("Applies-to Doc. Type"))
                {
                }
                column(Service_Header___Applies_to_Doc__No__Caption; "Service Header".FieldCaption("Applies-to Doc. No."))
                {
                }
                column(Service_Header___Customer_Posting_Group__Control136Caption; "Service Header".FieldCaption("Customer Posting Group"))
                {
                }
                column(Service_Header___Posting_Date__Control137Caption; Service_Header___Posting_Date__Control137CaptionLbl)
                {
                }
                column(Service_Header___Document_Date__Control138Caption; Service_Header___Document_Date__Control138CaptionLbl)
                {
                }
                column(Service_Header___Prices_Including_VAT__Control198Caption; "Service Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(SellToAddr_1_; SellToAddr[1])
                {
                }
                column(SellToAddr_2_; SellToAddr[2])
                {
                }
                column(SellToAddr_3_; SellToAddr[3])
                {
                }
                column(SellToAddr_4_; SellToAddr[4])
                {
                }
                column(SellToAddr_5_; SellToAddr[5])
                {
                }
                column(SellToAddr_6_; SellToAddr[6])
                {
                }
                column(SellToAddr_7_; SellToAddr[7])
                {
                }
                column(SellToAddr_8_; SellToAddr[8])
                {
                }
                dataitem(DimensionLoop1; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(DimText; DimText)
                    {
                    }
                    column(Header_DimensionsCaption; Header_DimensionsCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        DimText := DimTxtArr[Number];
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ShowDim then
                            CurrReport.Break();
                        FindDimTxt("Service Header"."Dimension Set ID");
                        SetRange(Number, 1, DimTxtArrLength);
                    end;
                }
                dataitem(HeaderErrorCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(ErrorText_Number_; ErrorText[Number])
                    {
                    }
                    column(ErrorText_Number_Caption; ErrorText_Number_CaptionLbl)
                    {
                    }

                    trigger OnPostDataItem()
                    begin
                        ErrorCounter := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, ErrorCounter);
                    end;
                }
                dataitem(CopyLoop; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 1;
                    dataitem("Service Line"; "Service Line")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemLinkReference = "Service Header";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                        trigger OnPreDataItem()
                        begin
                            if Find('+') then
                                OrigMaxLineNo := "Line No.";
                            CurrReport.Break();
                        end;
                    }
                    dataitem(RoundLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(Service_Line__Type; "Service Line".Type)
                        {
                        }
                        column(Service_Line___No__; "Service Line"."No.")
                        {
                        }
                        column(Service_Line__Description; "Service Line".Description)
                        {
                        }
                        column(Service_Line__Quantity; "Service Line".Quantity)
                        {
                        }
                        column(QtyToHandle; QtyToHandle)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(Service_Line___Qty__to_Invoice_; "Service Line"."Qty. to Invoice")
                        {
                        }
                        column(Service_Line___Unit_Price_; "Service Line"."Unit Price")
                        {
                            AutoFormatExpression = "Service Line"."Currency Code";
                            AutoFormatType = 2;
                        }
                        column(Service_Line___Line_Discount___; "Service Line"."Line Discount %")
                        {
                        }
                        column(Service_Line___Line_Amount_; "Service Line"."Line Amount")
                        {
                            AutoFormatExpression = "Service Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(Service_Line___Allow_Invoice_Disc__; "Service Line"."Allow Invoice Disc.")
                        {
                        }
                        column(Service_Line___VAT_Identifier_; "Service Line"."VAT Identifier")
                        {
                        }
                        column(FORMAT__Service_Line___Allow_Invoice_Disc___; Format("Service Line"."Allow Invoice Disc."))
                        {
                        }
                        column(ServiceLineLineNo; ServiceLine."Line No.")
                        {
                        }
                        column(SumLineAmount; SumLineAmount)
                        {
                        }
                        column(SumInvDiscountAmount; SumInvDiscountAmount)
                        {
                        }
                        column(TempServiceLine__Inv__Discount_Amount_; -TempServiceLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TempServiceLine__Line_Amount_; TempServiceLine."Line Amount")
                        {
                            AutoFormatExpression = "Service Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(TempServiceLine__Line_Amount_____Service_Line___Inv__Discount_Amount_; TempServiceLine."Line Amount" - TempServiceLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(ShowRoundLoop5; VATAmount = 0)
                        {
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(VATAmountLine_VATAmountText; TempVATAmountLine.VATAmountText())
                        {
                        }
                        column(TempServiceLine__Line_Amount____TempServiceLine__Inv__Discount_Amount_; TempServiceLine."Line Amount" - TempServiceLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmount; VATAmount)
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TempServiceLine__Line_Amount____TempServiceLine__Inv__Discount_Amount____VATAmount; TempServiceLine."Line Amount" - TempServiceLine."Inv. Discount Amount" + VATAmount)
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(ShowRoundLoop6; not "Service Header"."Prices Including VAT" and (VATAmount <> 0))
                        {
                        }
                        column(VATDiscountAmount; -VATDiscountAmount)
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(ShowRoundLoop7; "Service Header"."Prices Including VAT" and (VATAmount <> 0) and ("Service Header"."VAT Base Discount %" <> 0))
                        {
                        }
                        column(VATBaseAmount___VATAmount; VATBaseAmount + VATAmount)
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATBaseAmount; VATBaseAmount)
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(ShowRoundLoop8; "Service Header"."Prices Including VAT" and (VATAmount <> 0))
                        {
                        }
                        column(Service_Line___No__Caption; "Service Line".FieldCaption("No."))
                        {
                        }
                        column(Service_Line__DescriptionCaption; "Service Line".FieldCaption(Description))
                        {
                        }
                        column(Service_Line___Qty__to_Invoice_Caption; "Service Line".FieldCaption("Qty. to Invoice"))
                        {
                        }
                        column(Unit_PriceCaption; Unit_PriceCaptionLbl)
                        {
                        }
                        column(Service_Line___Line_Discount___Caption; Service_Line___Line_Discount___CaptionLbl)
                        {
                        }
                        column(Service_Line___Allow_Invoice_Disc__Caption; "Service Line".FieldCaption("Allow Invoice Disc."))
                        {
                        }
                        column(Service_Line___VAT_Identifier_Caption; "Service Line".FieldCaption("VAT Identifier"))
                        {
                        }
                        column(AmountCaption; AmountCaptionLbl)
                        {
                        }
                        column(Service_Line__TypeCaption; "Service Line".FieldCaption(Type))
                        {
                        }
                        column(Service_Line__QuantityCaption; Service_Line__QuantityCaptionLbl)
                        {
                        }
                        column(QtyToHandleCaption; QtyToHandleCaptionLbl)
                        {
                        }
                        column(TempServiceLine__Inv__Discount_Amount_Caption; TempServiceLine__Inv__Discount_Amount_CaptionLbl)
                        {
                        }
                        column(SubtotalCaption; SubtotalCaptionLbl)
                        {
                        }
                        column(VATDiscountAmountCaption; VATDiscountAmountCaptionLbl)
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(DimText_Control159; DimText)
                            {
                            }
                            column(Line_DimensionsCaption; Line_DimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                DimText := DimTxtArr[Number];
                            end;

                            trigger OnPostDataItem()
                            begin
                                SumLineAmount := SumLineAmount + TempServiceLine."Line Amount";
                                SumInvDiscountAmount := SumInvDiscountAmount + TempServiceLine."Inv. Discount Amount";
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowDim then
                                    CurrReport.Break();
                                FindDimTxt("Service Line"."Dimension Set ID");
                                SetRange(Number, 1, DimTxtArrLength);
                            end;
                        }
                        dataitem(LineErrorCounter; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(ErrorText_Number__Control97; ErrorText[Number])
                            {
                            }
                            column(ErrorText_Number__Control97Caption; ErrorText_Number__Control97CaptionLbl)
                            {
                            }

                            trigger OnPostDataItem()
                            begin
                                ErrorCounter := 0;
                            end;

                            trigger OnPreDataItem()
                            begin
                                SetRange(Number, 1, ErrorCounter);
                            end;
                        }

                        trigger OnAfterGetRecord()
                        var
                            ServCost: Record "Service Cost";
                            TableID: array[10] of Integer;
                            No: array[10] of Code[20];
                        begin
                            if Number = 1 then
                                TempServiceLine.Find('-')
                            else
                                TempServiceLine.Next();
                            "Service Line" := TempServiceLine;

                            if SalesTax and not HeaderTaxArea."Use External Tax Engine" then
                                ServSalesTaxCalculate.AddServiceLine("Service Line");

                            if not "Service Header"."Prices Including VAT" and
                                   ("Service Line"."VAT Calculation Type" = "Service Line"."VAT Calculation Type"::"Full VAT")
                            then
                                TempServiceLine."Line Amount" := 0;

                            TempDimSetEntry.SetRange("Dimension Set ID", "Service Line"."Dimension Set ID");
                            if "Service Line"."Document Type" = "Service Line"."Document Type"::"Credit Memo" then begin
                                if "Service Line"."Document Type" = "Service Line"."Document Type"::"Credit Memo" then
                                    if "Service Line"."Qty. to Invoice" <> "Service Line".Quantity then
                                        AddError(StrSubstNo(Text015, "Service Line".FieldCaption("Qty. to Invoice"), "Service Line".Quantity));
                                if "Service Line"."Qty. to Ship" <> 0 then
                                    AddError(StrSubstNo(Text043, "Service Line".FieldCaption("Qty. to Ship")));
                            end else
                                if "Service Line"."Document Type" = "Service Line"."Document Type"::Invoice then begin
                                    if ("Service Line"."Qty. to Ship" <> "Service Line".Quantity) and ("Service Line"."Shipment No." = '') then
                                        AddError(StrSubstNo(Text015, "Service Line".FieldCaption("Qty. to Ship"), "Service Line".Quantity));
                                    if "Service Line"."Qty. to Invoice" <> "Service Line".Quantity then
                                        AddError(StrSubstNo(Text015, "Service Line".FieldCaption("Qty. to Invoice"), "Service Line".Quantity));
                                end;

                            if not Ship then
                                "Service Line"."Qty. to Ship" := 0;

                            if ("Service Line"."Document Type" = "Service Line"."Document Type"::Invoice) and ("Service Line"."Shipment No." <> '') then begin
                                "Service Line"."Quantity Shipped" := "Service Line".Quantity;
                                "Service Line"."Qty. to Ship" := 0;
                            end;

                            if Invoice then begin
                                if "Service Line"."Document Type" = "Service Line"."Document Type"::"Credit Memo" then
                                    MaxQtyToBeInvoiced := "Service Line".Quantity
                                else
                                    MaxQtyToBeInvoiced := "Service Line"."Qty. to Ship" + "Service Line"."Quantity Shipped" - "Service Line"."Quantity Invoiced";
                                if Abs("Service Line"."Qty. to Invoice") > Abs(MaxQtyToBeInvoiced) then
                                    "Service Line"."Qty. to Invoice" := MaxQtyToBeInvoiced;
                            end else
                                "Service Line"."Qty. to Invoice" := 0;

                            if "Service Line"."Gen. Prod. Posting Group" <> '' then begin
                                if ("Service Header"."Document Type" = "Service Header"."Document Type"::"Credit Memo") and
                                   ("Service Header"."Applies-to Doc. Type" = "Service Header"."Applies-to Doc. Type"::Invoice) and
                                   ("Service Header"."Applies-to Doc. No." <> '')
                                then begin
                                    CustLedgEntry.SetCurrentKey("Document No.");
                                    CustLedgEntry.SetRange("Customer No.", "Service Header"."Bill-to Customer No.");
                                    CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
                                    CustLedgEntry.SetRange("Document No.", "Service Header"."Applies-to Doc. No.");
                                    if not CustLedgEntry.FindLast() and not ApplNoError then begin
                                        ApplNoError := true;
                                        AddError(
                                          StrSubstNo(
                                            Text016,
                                            "Service Header".FieldCaption("Applies-to Doc. No."), "Service Header"."Applies-to Doc. No."));
                                    end;
                                end;

                                if not VATPostingSetup.Get("Service Line"."VAT Bus. Posting Group", "Service Line"."VAT Prod. Posting Group") then
                                    AddError(
                                      StrSubstNo(
                                        Text017,
                                        VATPostingSetup.TableCaption(), "Service Line"."VAT Bus. Posting Group", "Service Line"."VAT Prod. Posting Group"));
                                if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
                                    if ("Service Header"."VAT Registration No." = '') and not VATNoError then begin
                                        VATNoError := true;
                                        AddError(
                                          StrSubstNo(
                                            Text035, "Service Header".FieldCaption("VAT Registration No.")));
                                    end;
                            end;

                            CheckQuantity("Service Line");

                            ServiceLine := "Service Line";
                            if not ("Service Line"."Document Type" = "Service Line"."Document Type"::"Credit Memo") then begin
                                ServiceLine."Qty. to Ship" := -ServiceLine."Qty. to Ship";
                                ServiceLine."Qty. to Invoice" := -ServiceLine."Qty. to Invoice";
                            end;

                            RemQtyToBeInvoiced := ServiceLine."Qty. to Invoice";

                            case "Service Line"."Document Type" of
                                "Service Line"."Document Type"::Order, "Service Line"."Document Type"::Invoice:
                                    CheckShptLines("Service Line");
                            end;

                            if ("Service Line".Type.AsInteger() >= "Service Line".Type::"G/L Account".AsInteger()) and ("Service Line"."Qty. to Invoice" <> 0) then begin
                                if not GenPostingSetup.Get("Service Line"."Gen. Bus. Posting Group", "Service Line"."Gen. Prod. Posting Group") then
                                    AddError(
                                      StrSubstNo(
                                        Text017,
                                        GenPostingSetup.TableCaption(), "Service Line"."Gen. Bus. Posting Group", "Service Line"."Gen. Prod. Posting Group"));
                                if not VATPostingSetup.Get("Service Line"."VAT Bus. Posting Group", "Service Line"."VAT Prod. Posting Group") then
                                    AddError(
                                      StrSubstNo(
                                        Text017,
                                        VATPostingSetup.TableCaption(), "Service Line"."VAT Bus. Posting Group", "Service Line"."VAT Prod. Posting Group"));
                            end;

                            CheckType("Service Line");

                            if not DimMgt.CheckDimIDComb("Service Line"."Dimension Set ID") then
                                AddError(DimMgt.GetDimCombErr());

                            if "Service Line".Type = "Service Line".Type::Cost then begin
                                TableID[1] := Database::"G/L Account";
                                if ServCost.Get("Service Line"."No.") then
                                    No[1] := ServCost."Account No.";
                            end else begin
                                TableID[1] := ServDimMgt.ServiceLineTypeToTableID("Service Line".Type);
                                No[1] := "Service Line"."No.";
                            end;
                            TableID[2] := Database::Job;
                            No[2] := "Service Line"."Job No.";
                            if not DimMgt.CheckDimValuePosting(TableID, No, "Service Line"."Dimension Set ID") then
                                AddError(DimMgt.GetDimValuePostingErr());
                            if "Service Line"."Line No." > OrigMaxLineNo then begin
                                "Service Line"."No." := '';
                                "Service Line".Type := "Service Line".Type::" ";
                            end;
                            if "Service Line"."Line No." = OrigMaxLineNo then
                                if SalesTax then begin
                                    if not SalesTaxCalculationOverridden then begin
                                        if HeaderTaxArea."Use External Tax Engine" then
                                            ServSalesTaxCalculate.CallExternalTaxEngineForServ("Service Header", true)
                                        else
                                            ServSalesTaxCalculate.EndSalesTaxCalculation("Service Header"."Posting Date");
                                        ServSalesTaxCalculate.GetSalesTaxAmountLineTable(SalesTaxAmountLine);
                                    end;
                                    VATAmount := SalesTaxAmountLine.GetTotalTaxAmountFCY();
                                    VATBaseAmount := SalesTaxAmountLine.GetTotalTaxBase();
                                    TaxText := SalesTaxAmountLine.TaxAmountText();
                                end else
                                    TaxText := TempVATAmountLine.VATAmountText();
                        end;

                        trigger OnPreDataItem()
                        begin
                            VATNoError := false;
                            ApplNoError := false;

                            MoreLines := TempServiceLine.Find('+');
                            while MoreLines and (TempServiceLine.Description = '') and (TempServiceLine."Description 2" = '') and
                                  (TempServiceLine."No." = '') and (TempServiceLine.Quantity = 0) and
                                  (TempServiceLine.Amount = 0)
                            do
                                MoreLines := TempServiceLine.Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            TempServiceLine.SetRange("Line No.", 0, TempServiceLine."Line No.");
                            SetRange(Number, 1, TempServiceLine.Count);

                            SumLineAmount := 0;
                            SumInvDiscountAmount := 0;
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(VATAmountLine__VAT_Amount_; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base_; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Service Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount_; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount_; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount_; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control150; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base__Control151; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Service Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT___; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmountLine__VAT_Identifier_; TempVATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control173; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control171; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount__Control169; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control181; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base__Control182; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Service Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control183; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control184; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control150Caption; VATAmountLine__VAT_Amount__Control150CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Base__Control151Caption; VATAmountLine__VAT_Base__Control151CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT___Caption; VATAmountLine__VAT___CaptionLbl)
                        {
                        }
                        column(VAT_Amount_SpecificationCaption; VAT_Amount_SpecificationCaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Identifier_Caption; VATAmountLine__VAT_Identifier_CaptionLbl)
                        {
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control173Caption; VATAmountLine__Invoice_Discount_Amount__Control173CaptionLbl)
                        {
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control171Caption; VATAmountLine__Inv__Disc__Base_Amount__Control171CaptionLbl)
                        {
                        }
                        column(VATAmountLine__Line_Amount__Control169Caption; VATAmountLine__Line_Amount__Control169CaptionLbl)
                        {
                        }
                        column(TotalCaption; TotalCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempVATAmountLine.GetLine(Number);
                        end;

                        trigger OnPreDataItem()
                        begin
                            if SalesTax then
                                CurrReport.Break();
                            if VATAmount = 0 then
                                CurrReport.Break();
                            SetRange(Number, 1, TempVATAmountLine.Count);
                        end;
                    }
                    dataitem(SalesTaxCounter; "Integer")
                    {
                        column(SalesTaxAmountLine__Tax_Amount_; SalesTaxAmountLine."Tax Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SalesTaxAmountLine__Tax_Area_Code_for_Key_; SalesTaxAmountLine."Tax Area Code for Key")
                        {
                        }
                        column(SalesTaxAmountLine__Tax___; SalesTaxAmountLine."Tax %")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SalesTaxAmountLine__Inv__Disc__Base_Amount_; SalesTaxAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SalesTaxAmountLine__Invoice_Discount_Amount_; SalesTaxAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SalesTaxAmountLine__Tax_Base_Amount_; SalesTaxAmountLine."Tax Base Amount")
                        {
                            AutoFormatExpression = "Service Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SalesTaxAmountLine__Tax_Amount__Control1020016; SalesTaxAmountLine."Tax Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SalesTax_; SalesTax)
                        {
                        }
                        column(SalesTaxAmountLine__Tax_Amount__Control1020010; SalesTaxAmountLine."Tax Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SumtotalVAT_; SumtotalVAT)
                        {
                        }
                        column(SumtotalExchFactor_; ExchangeFactor)
                        {
                        }
                        column(SalesTaxAmountLine__Tax_Amount__Control1020018; SalesTaxAmountLine."Tax Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(ServiceHeader_CurrCode_; "Service Header"."Currency Code")
                        {
                        }
                        column(SalesTaxAmountLine__Tax_Amount__Control1020020; SalesTaxAmountLine."Tax Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(Total______Service_Header___Currency_Code_; 'Total ' + "Service Header"."Currency Code")
                        {
                        }
                        column(SalesTaxAmountLine__Tax_Amount____ExchangeFactor; SalesTaxAmountLine.GetTotalTaxAmountFCY())
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SalesTaxCounter_Number; Number)
                        {
                        }
                        column(Sales_Tax_AmountsCaption; Sales_Tax_AmountsCaptionLbl)
                        {
                        }
                        column(Tax_Area_CodeCaption; Tax_Area_CodeCaptionLbl)
                        {
                        }
                        column(Tax__Caption; Tax__CaptionLbl)
                        {
                        }
                        column(Inv__Disc__Base_AmountCaption; Inv__Disc__Base_AmountCaptionLbl)
                        {
                        }
                        column(Invoice_Discount_AmountCaption; Invoice_Discount_AmountCaptionLbl)
                        {
                        }
                        column(Tax_Base_AmountCaption; Tax_Base_AmountCaptionLbl)
                        {
                        }
                        column(Tax_AmountCaption; Tax_AmountCaptionLbl)
                        {
                        }
                        column(ContinuedCaption_Control1020007; ContinuedCaption_Control1020007Lbl)
                        {
                        }
                        column(ContinuedCaption_Control1020009; ContinuedCaption_Control1020009Lbl)
                        {
                        }
                        column(TotalCaption_Control1020017; TotalCaption_Control1020017Lbl)
                        {
                        }
                        column(TotalCaption_Control1020019; TotalCaption_Control1020019Lbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then
                                SalesTaxAmountLine.FindFirst()
                            else
                                SalesTaxAmountLine.Next();

                            if SalesTax and (SalesTaxAmountLine."Tax Amount" <> 0) then
                                SumtotalVAT := SumtotalVAT + SalesTaxAmountLine."Tax Amount";

                            SumtotalExchFactor := SalesTaxAmountLine.GetTotalTaxAmountFCY();
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not SalesTax then
                                CurrReport.Break();
                            SetRange(Number, 1, SalesTaxAmountLine.Count);
                            SalesTaxAmountLine.Reset();

                            SumtotalVAT := 0;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Clear(TempServiceLine);
                        Clear(ServAmountsMgt);
                        TempVATAmountLine.DeleteAll();
                        TempServiceLine.DeleteAll();

                        ServAmountsMgt.GetServiceLines("Service Header", TempServiceLine, 1);

                        // Ship prm added
                        TempServiceLine.CalcVATAmountLines(0, "Service Header", TempServiceLine, TempVATAmountLine, Ship);
                        TempServiceLine.UpdateVATOnLines(0, "Service Header", TempServiceLine, TempVATAmountLine);
                        VATAmount := TempVATAmountLine.GetTotalVATAmount();
                        VATBaseAmount := TempVATAmountLine.GetTotalVATBase();
                        VATDiscountAmount :=
                          TempVATAmountLine.GetTotalVATDiscount("Service Header"."Currency Code", "Service Header"."Prices Including VAT");
                        if SalesTax then begin
                            SalesTaxAmountLine.DeleteAll();
                            OnBeforeCalculateSalesTax("Service Header", SalesTaxAmountLine, SalesTaxCalculationOverridden);
#if not CLEAN28
                            ServiceDocumentTest.RunOnBeforeCalculateSalesTax("Service Header", SalesTaxAmountLine, SalesTaxCalculationOverridden);
#endif
                            ServSalesTaxCalculate.StartSalesTaxCalculation();
                        end;
                    end;
                }
            }

            trigger OnAfterGetRecord()
            var
                ServiceFormatAddress: Codeunit "Service Format Address";
                TableID: array[10] of Integer;
                No: array[10] of Code[20];
            begin
                ServiceFormatAddress.ServiceHeaderSellTo(SellToAddr, "Service Header");
                ServiceFormatAddress.ServiceHeaderBillTo(BillToAddr, "Service Header");
                ServiceFormatAddress.ServiceHeaderShipTo(ShipToAddr, "Service Header");
                if "Currency Code" = '' then begin
                    GLSetup.TestField("LCY Code");
                    TotalText := StrSubstNo(Text004, GLSetup."LCY Code");
                    TotalExclVATText := StrSubstNo(Text033, GLSetup."LCY Code");
                    TotalInclVATText := StrSubstNo(Text005, GLSetup."LCY Code");
                    ExchangeFactor := 1;
                end else begin
                    TotalText := StrSubstNo(Text004, "Currency Code");
                    TotalExclVATText := StrSubstNo(Text033, "Currency Code");
                    TotalInclVATText := StrSubstNo(Text005, "Currency Code");
                    ExchangeFactor := "Currency Factor";
                end;

                Invoice := InvOnNextPostReq;
                Ship := ShipReceiveOnNextPostReq;

                SalesTax := "Tax Area Code" <> '';
                if SalesTax then
                    HeaderTaxArea.Get("Tax Area Code");

                VerifyCustomerNo("Service Header");
                VerifyBilltoCustomerNo("Service Header");

                ServiceSetup.Get();

                VerifyPostingDate("Service Header");

                if "Document Date" <> 0D then
                    if "Document Date" <> NormalDate("Document Date") then
                        AddError(StrSubstNo(Text009, FieldCaption("Document Date")));

                case "Document Type" of
                    "Document Type"::Invoice:
                        begin
                            Ship := true;
                            Invoice := true;
                        end;
                    "Document Type"::"Credit Memo":
                        begin
                            Ship := false;
                            Invoice := true;
                        end;
                end;

                if not (Ship or Invoice) then
                    AddError(
                      StrSubstNo(
                        Text034,
                        Text001, Text002));

                if Invoice then begin
                    ServiceLine.Reset();
                    ServiceLine.SetRange("Document Type", "Document Type");
                    ServiceLine.SetRange("Document No.", "No.");
                    ServiceLine.SetFilter(Quantity, '<>0');
                    if "Document Type" = "Document Type"::Order then
                        ServiceLine.SetFilter("Qty. to Invoice", '<>0');
                    Invoice := ServiceLine.Find('-');
                    if Invoice and not Ship and ("Document Type" = "Document Type"::Order) then begin
                        Invoice := false;
                        repeat
                            Invoice := (ServiceLine."Quantity Shipped" - ServiceLine."Quantity Invoiced") <> 0;
                        until Invoice or (ServiceLine.Next() = 0);
                    end;
                end;

                if Ship then begin
                    ServiceLine.Reset();
                    ServiceLine.SetRange("Document Type", "Document Type");
                    ServiceLine.SetRange("Document No.", "No.");
                    ServiceLine.SetFilter(Quantity, '<>0');
                    if "Document Type" = "Document Type"::Order then
                        ServiceLine.SetFilter("Qty. to Ship", '<>0');
                    ServiceLine.SetRange("Shipment No.", '');
                    Ship := ServiceLine.Find('-');
                end;

                if not (Ship or Invoice) then
                    AddError(DocumentErrorsMgt.GetNothingToPostErrorMsg());

                if Invoice then
                    if not ("Document Type" = "Document Type"::"Credit Memo") then
                        if "Due Date" = 0D then
                            AddError(StrSubstNo(Text006, FieldCaption("Due Date")));

                if Ship and ("Shipping No." = '') then // Order,Invoice
                    if ("Document Type" = "Document Type"::Order) or
                       (("Document Type" = "Document Type"::Invoice) and ServiceSetup."Shipment on Invoice")
                    then
                        if "Shipping No. Series" = '' then
                            AddError(
                              StrSubstNo(
                                Text006,
                                FieldCaption("Shipping No. Series")));

                if Invoice and ("Posting No." = '') then
                    if "Document Type" = "Document Type"::Order then
                        if "Posting No. Series" = '' then
                            AddError(
                              StrSubstNo(
                                Text006,
                                FieldCaption("Posting No. Series")));

                ServiceLine.Reset();
                ServiceLine.SetRange("Document Type", "Document Type");
                ServiceLine.SetRange("Document No.", "No.");
                if ServiceLine.FindFirst() then;

                if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                    AddError(DimMgt.GetDimCombErr());

                TableID[1] := Database::Customer;
                No[1] := "Bill-to Customer No.";
                TableID[3] := Database::"Salesperson/Purchaser";
                No[3] := "Salesperson Code";
                TableID[4] := Database::"Responsibility Center";
                No[4] := "Responsibility Center";

                if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                    AddError(DimMgt.GetDimValuePostingErr());

                OnAfterCheckServiceDoc("Service Header", ErrorText, ErrorCounter);
#if not CLEAN28
                ServiceDocumentTest.RunOnAfterCheckServiceDoc("Service Header", ErrorText, ErrorCounter);
#endif
            end;

            trigger OnPreDataItem()
            begin
                ServiceHeader.Copy("Service Header");
                ServiceHeader.FilterGroup := 2;
                ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
                if ServiceHeader.FindFirst() then begin
                    case true of
                        ShipReceiveOnNextPostReq and InvOnNextPostReq:
                            ShipInvText := Text000;
                        ShipReceiveOnNextPostReq:
                            ShipInvText := Text001;
                        InvOnNextPostReq:
                            ShipInvText := Text002;
                    end;
                    ShipInvText := StrSubstNo(Text003, ShipInvText);
                end;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'Service Document - Test';
        AboutText = 'Verify whether service orders, invoices, or credit memos are correct before you post them.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Order Posting")
                    {
                        Caption = 'Order Posting';
                        field(ShipReceiveOnNextPostReq; ShipReceiveOnNextPostReq)
                        {
                            ApplicationArea = Service;
                            Caption = 'Ship';
                            ToolTip = 'Specifies if you want to post the documents that are being tested as shipped, or as shipped and invoiced.';

                            trigger OnValidate()
                            begin
                                if not ShipReceiveOnNextPostReq then
                                    InvOnNextPostReq := true;
                            end;
                        }
                        field(InvOnNextPostReq; InvOnNextPostReq)
                        {
                            ApplicationArea = Service;
                            Caption = 'Invoice';
                            ToolTip = 'Specifies whether you want to post the documents that are being tested as invoiced, or as shipped and invoiced.';

                            trigger OnValidate()
                            begin
                                if not InvOnNextPostReq then
                                    ShipReceiveOnNextPostReq := true;
                            end;
                        }
                    }
                    field(ShowDim; ShowDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies if you want dimensions information for the journal lines that you want to include in the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if not ShipReceiveOnNextPostReq and not InvOnNextPostReq then begin
                ShipReceiveOnNextPostReq := true;
                InvOnNextPostReq := true;
            end;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        GLSetup.Get();
    end;

    trigger OnPreReport()
    begin
        ServiceHeaderFilter := "Service Header".GetFilters();
    end;

    var
        ServiceSetup: Record "Service Mgt. Setup";
        GLSetup: Record "General Ledger Setup";
        Cust: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLine2: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        GLAcc: Record "G/L Account";
        Item: Record Item;
        Res: Record Resource;
        ServiceShptLine: Record "Service Shipment Line";
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
#if not CLEAN28
        ServiceDocumentTest: Report "Service Document - Test";
#endif
        DimMgt: Codeunit DimensionManagement;
        ServDimMgt: Codeunit "Serv. Dimension Management";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        ServAmountsMgt: Codeunit "Serv-Amounts Mgt.";
        ServiceHeaderFilter: Text;
        SellToAddr: array[8] of Text[100];
        BillToAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        TotalText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
        ShipInvText: Text[50];
        ReceiveInvText: Text[50];
        DimText: Text;
        ErrorText: array[99] of Text[250];
        MaxQtyToBeInvoiced: Decimal;
        RemQtyToBeInvoiced: Decimal;
        QtyToBeInvoiced: Decimal;
        VATAmount: Decimal;
        VATBaseAmount: Decimal;
        VATDiscountAmount: Decimal;
        QtyToHandle: Decimal;
        SumLineAmount: Decimal;
        SumInvDiscountAmount: Decimal;
        ErrorCounter: Integer;
        OrigMaxLineNo: Integer;
        InvOnNextPostReq: Boolean;
        ShipReceiveOnNextPostReq: Boolean;
        VATNoError: Boolean;
        ApplNoError: Boolean;
        ShowDim: Boolean;
        MoreLines: Boolean;
        Ship: Boolean;
        Invoice: Boolean;
        DimTxtArrLength: Integer;
        DimTxtArr: array[500] of Text;
        ExchangeFactor: Decimal;
        SalesTax: Boolean;
        HeaderTaxArea: Record "Tax Area";
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
        ServSalesTaxCalculate: Codeunit "Serv. Sales Tax Calculate";
        TaxText: Text[30];
        SumtotalVAT: Decimal;
        SumtotalExchFactor: Decimal;

#pragma warning disable AA0074
        Text000: Label 'Ship and Invoice';
        Text001: Label 'Ship';
        Text002: Label 'Invoice';
#pragma warning disable AA0470
        Text003: Label 'Order Posting: %1';
        Text004: Label 'Total %1';
        Text005: Label 'Total %1 Incl. VAT';
        Text006: Label '%1 must be specified.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        MustBeForErr: Label '%1 must be %2 for %3 %4.';
#pragma warning restore AA0470
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text008: Label '%1 %2 does not exist.';
        Text009: Label '%1 must not be a closing date.';
        Text014: Label 'Service Document: %1';
        Text015: Label '%1 must be %2.';
        Text016: Label '%1 %2 does not exist on customer entries.';
        Text017: Label '%1 %2 %3 does not exist.';
        Text019: Label '%1 %2 must be specified.';
        Text020: Label '%1 must be 0 when %2 is 0.';
        Text024: Label 'The %1 on the shipment is not the same as the %1 on the Service Header.';
        Text026: Label 'Line %1 of the shipment %2, which you are attempting to invoice, has already been invoiced.';
        Text027: Label '%1 must have the same sign as the shipments.';
        Text033: Label 'Total %1 Excl. VAT';
        Text034: Label 'Enter "Yes" in %1 and/or %2.';
        Text035: Label 'You must enter the customer''s %1.';
        Text036: Label 'The quantity you are attempting to invoice is greater than the quantity in shipment %1.';
        Text043: Label '%1 must be zero.';
        Text045: Label '%1 must not be %2 for %3 %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Service_Document___TestCaptionLbl: Label 'Service Document - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Ship_toCaptionLbl: Label 'Ship-to';
        CustomerCaptionLbl: Label 'Customer';
        Bill_toCaptionLbl: Label 'Bill-to';
        Service_Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        Service_Header___Document_Date_CaptionLbl: Label 'Document Date';
        Service_Header___Due_Date_CaptionLbl: Label 'Due Date';
        Service_Header___Pmt__Discount_Date_CaptionLbl: Label 'Pmt. Discount Date';
        Service_Header___Posting_Date__Control105CaptionLbl: Label 'Posting Date';
        Service_Header___Document_Date__Control106CaptionLbl: Label 'Document Date';
        Service_Header___Order_Date_CaptionLbl: Label 'Order Date';
        Service_Header___Due_Date__Control19CaptionLbl: Label 'Due Date';
        Service_Header___Pmt__Discount_Date__Control22CaptionLbl: Label 'Pmt. Discount Date';
        Service_Header___Posting_Date__Control131CaptionLbl: Label 'Posting Date';
        Service_Header___Document_Date__Control132CaptionLbl: Label 'Document Date';
        Service_Header___Posting_Date__Control137CaptionLbl: Label 'Posting Date';
        Service_Header___Document_Date__Control138CaptionLbl: Label 'Document Date';
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        Unit_PriceCaptionLbl: Label 'Unit Price';
        Service_Line___Line_Discount___CaptionLbl: Label 'Line Disc. %';
        AmountCaptionLbl: Label 'Amount';
        Service_Line__QuantityCaptionLbl: Label 'Quantity';
        QtyToHandleCaptionLbl: Label 'Qty. to Handle';
        TempServiceLine__Inv__Discount_Amount_CaptionLbl: Label 'Inv. Discount Amount';
        SubtotalCaptionLbl: Label 'Subtotal';
        VATDiscountAmountCaptionLbl: Label 'Payment Discount on VAT';
        Line_DimensionsCaptionLbl: Label 'Line Dimensions';
        ErrorText_Number__Control97CaptionLbl: Label 'Warning!';
        VATAmountLine__VAT_Amount__Control150CaptionLbl: Label 'VAT Amount';
        VATAmountLine__VAT_Base__Control151CaptionLbl: Label 'VAT Base';
        VATAmountLine__VAT___CaptionLbl: Label 'VAT %';
        VAT_Amount_SpecificationCaptionLbl: Label 'VAT Amount Specification';
        VATAmountLine__VAT_Identifier_CaptionLbl: Label 'VAT Identifier';
        VATAmountLine__Invoice_Discount_Amount__Control173CaptionLbl: Label 'Invoice Discount Amount';
        VATAmountLine__Inv__Disc__Base_Amount__Control171CaptionLbl: Label 'Inv. Disc. Base Amount';
        VATAmountLine__Line_Amount__Control169CaptionLbl: Label 'Line Amount';
        TotalCaptionLbl: Label 'Total';
        Sales_Tax_AmountsCaptionLbl: Label 'Sales Tax Amounts';
        Tax_Area_CodeCaptionLbl: Label 'Tax Area Code';
        Tax__CaptionLbl: Label 'Tax %';
        Inv__Disc__Base_AmountCaptionLbl: Label 'Inv. Disc. Base Amount';
        Invoice_Discount_AmountCaptionLbl: Label 'Invoice Discount Amount';
        Tax_Base_AmountCaptionLbl: Label 'Tax Base Amount';
        Tax_AmountCaptionLbl: Label 'Tax Amount';
        ContinuedCaption_Control1020007Lbl: Label 'Continued';
        ContinuedCaption_Control1020009Lbl: Label 'Continued';
        TotalCaption_Control1020017Lbl: Label 'Total';
        TotalCaption_Control1020019Lbl: Label 'Total';
        SalesTaxCalculationOverridden: Boolean;

    local procedure AddError(Text: Text)
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := CopyStr(Text, 1, MaxStrLen(ErrorText[ErrorCounter]));
    end;

    local procedure CheckShptLines(ServiceLine2: Record "Service Line")
    var
        TempPostedDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        if Abs(RemQtyToBeInvoiced) > Abs(ServiceLine2."Qty. to Ship") then begin
            ServiceShptLine.Reset();
            case ServiceLine2."Document Type" of
                ServiceLine2."Document Type"::Order:
                    begin
                        ServiceShptLine.SetCurrentKey("Order No.", "Order Line No.");
                        ServiceShptLine.SetRange("Order No.", ServiceLine2."Document No.");
                        ServiceShptLine.SetRange("Order Line No.", ServiceLine2."Line No.");
                    end;
                ServiceLine2."Document Type"::Invoice:
                    begin
                        ServiceShptLine.SetRange("Document No.", ServiceLine2."Shipment No.");
                        ServiceShptLine.SetRange("Line No.", ServiceLine2."Shipment Line No.");
                    end;
            end;

            ServiceShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');

            if ServiceShptLine.Find('-') then
                repeat
                    DimMgt.GetDimensionSet(TempPostedDimSetEntry, ServiceShptLine."Dimension Set ID");
                    if not DimMgt.CheckDimIDConsistency(
                         TempDimSetEntry, TempPostedDimSetEntry, Database::"Service Line", Database::"Service Shipment Line")
                    then
                        AddError(DimMgt.GetDocDimConsistencyErr());

                    if ServiceShptLine."Customer No." <> ServiceLine2."Customer No." then
                        AddError(
                          StrSubstNo(
                            Text024,
                            ServiceLine2.FieldCaption("Customer No.")));
                    if ServiceShptLine.Type <> ServiceLine2.Type then
                        AddError(
                          StrSubstNo(
                            Text024,
                            ServiceLine2.FieldCaption(Type)));
                    if ServiceShptLine."No." <> ServiceLine2."No." then
                        AddError(
                          StrSubstNo(
                            Text024,
                            ServiceLine2.FieldCaption("No.")));
                    if ServiceShptLine."Gen. Bus. Posting Group" <> ServiceLine2."Gen. Bus. Posting Group" then
                        AddError(
                          StrSubstNo(
                            Text024,
                            ServiceLine2.FieldCaption("Gen. Bus. Posting Group")));
                    if ServiceShptLine."Gen. Prod. Posting Group" <> ServiceLine2."Gen. Prod. Posting Group" then
                        AddError(
                          StrSubstNo(
                            Text024,
                            ServiceLine2.FieldCaption("Gen. Prod. Posting Group")));
                    if ServiceShptLine."Location Code" <> ServiceLine2."Location Code" then
                        AddError(
                          StrSubstNo(
                            Text024,
                            ServiceLine2.FieldCaption("Location Code")));

                    if -ServiceLine."Qty. to Invoice" * ServiceShptLine.Quantity < 0 then
                        AddError(
                          StrSubstNo(
                            Text027, ServiceLine2.FieldCaption("Qty. to Invoice")));

                    QtyToBeInvoiced := RemQtyToBeInvoiced - ServiceLine."Qty. to Ship";
                    if Abs(QtyToBeInvoiced) > Abs(ServiceShptLine.Quantity - ServiceShptLine."Quantity Invoiced") then
                        QtyToBeInvoiced := -(ServiceShptLine.Quantity - ServiceShptLine."Quantity Invoiced");
                    RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                    ServiceShptLine."Quantity Invoiced" := ServiceShptLine."Quantity Invoiced" - QtyToBeInvoiced;
                    ServiceShptLine."Qty. Shipped Not Invoiced" :=
                      ServiceShptLine.Quantity - ServiceShptLine."Quantity Invoiced"
                until (ServiceShptLine.Next() = 0) or (Abs(RemQtyToBeInvoiced) <= Abs(ServiceLine2."Qty. to Ship"))
            else
                AddError(
                  StrSubstNo(
                    Text026,
                    ServiceLine2."Shipment Line No.",
                    ServiceLine2."Shipment No."));
        end;

        if Abs(RemQtyToBeInvoiced) > Abs(ServiceLine2."Qty. to Ship") then
            if ServiceLine2."Document Type" = ServiceLine2."Document Type"::Invoice then
                AddError(
                  StrSubstNo(
                    Text036,
                    ServiceLine2."Shipment No."));
    end;

    procedure FindDimTxt(DimSetID: Integer)
    var
        i: Integer;
        TxtToAdd: Text[120];
        Separation: Text[5];
        StartNewLine: Boolean;
    begin
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        DimTxtArrLength := 0;
        for i := 1 to ArrayLen(DimTxtArr) do
            DimTxtArr[i] := '';
        if not DimSetEntry.FindSet() then
            exit;
        Separation := '; ';
        repeat
            TxtToAdd := DimSetEntry."Dimension Code" + ' - ' + DimSetEntry."Dimension Value Code";
            if DimTxtArrLength = 0 then
                StartNewLine := true
            else
                StartNewLine := StrLen(DimTxtArr[DimTxtArrLength]) + StrLen(Separation) + StrLen(TxtToAdd) > MaxStrLen(DimTxtArr[1]);
            if StartNewLine then begin
                DimTxtArrLength += 1;
                DimTxtArr[DimTxtArrLength] := TxtToAdd
            end else
                DimTxtArr[DimTxtArrLength] := DimTxtArr[DimTxtArrLength] + Separation + TxtToAdd;
        until DimSetEntry.Next() = 0;
    end;

    procedure CheckQuantity(var ServiceLine: Record "Service Line")
    begin
        if ServiceLine.Quantity <> 0 then begin
            if ServiceLine."No." = '' then
                AddError(StrSubstNo(Text019, ServiceLine.Type, ServiceLine.FieldCaption("No.")));
            if ServiceLine.Type = ServiceLine.Type::" " then
                AddError(StrSubstNo(Text006, ServiceLine.FieldCaption(Type)));
        end else
            if ServiceLine.Amount <> 0 then
                AddError(
                  StrSubstNo(Text020, ServiceLine.FieldCaption(Amount), ServiceLine.FieldCaption(Quantity)));
    end;

    procedure InitializeRequest(ShipReceiveOnNextPostReqFrom: Boolean; InvOnNextPostReqFrom: Boolean; ShowDimFrom: Boolean)
    begin
        ShipReceiveOnNextPostReq := ShipReceiveOnNextPostReqFrom;
        if not ShipReceiveOnNextPostReq then
            InvOnNextPostReq := true;
        InvOnNextPostReq := InvOnNextPostReqFrom;
        if not InvOnNextPostReq then
            ShipReceiveOnNextPostReq := true;
        ShowDim := ShowDimFrom;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesTax(var ServiceHeader: Record "Service Header"; var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var SalesTaxCalculationOverridden: Boolean)
    begin
    end;

    local procedure CheckType(ServiceLine2: Record "Service Line")
    var
        ItemVariant: Record "Item Variant";
        ItemItemVariantLbl: Label '%1 %2', Comment = '%1 - Item No., %2 - Variant Code';
    begin
        OnBeforeCheckType(ServiceLine2, ErrorCounter, ErrorText);
#if not CLEAN28
        ServiceDocumentTest.RunOnBeforeCheckType(ServiceLine2, ErrorCounter, ErrorText);
#endif
        case ServiceLine2.Type of
            ServiceLine2.Type::"G/L Account":
                begin
                    if (ServiceLine2."No." = '') and (ServiceLine2.Amount = 0) then
                        exit;

                    if ServiceLine2."No." <> '' then
                        if GLAcc.Get(ServiceLine2."No.") then begin
                            if GLAcc.Blocked then
                                AddError(StrSubstNo(MustBeForErr, GLAcc.FieldCaption(Blocked), false, GLAcc.TableCaption(), ServiceLine2."No."));
                            if not GLAcc."Direct Posting" and (ServiceLine2."Line No." <= OrigMaxLineNo) then
                                AddError(StrSubstNo(MustBeForErr, GLAcc.FieldCaption("Direct Posting"), true, GLAcc.TableCaption(), ServiceLine2."No."));
                        end else
                            AddError(StrSubstNo(Text008, GLAcc.TableCaption(), ServiceLine2."No."));
                end;
            ServiceLine2.Type::Item:
                begin
                    if (ServiceLine2."No." = '') and (ServiceLine2.Quantity = 0) then
                        exit;

                    if ServiceLine2."No." <> '' then
                        if Item.Get(ServiceLine2."No.") then begin
                            if Item.Blocked then
                                AddError(StrSubstNo(MustBeForErr, Item.FieldCaption(Blocked), false, Item.TableCaption(), ServiceLine2."No."));

                            if ServiceLine2."Variant Code" <> '' then begin
                                ItemVariant.SetLoadFields(Blocked);
                                if ItemVariant.Get(ServiceLine2."No.", ServiceLine2."Variant Code") then begin
                                    if ItemVariant.Blocked then
                                        AddError(StrSubstNo(MustBeForErr, ItemVariant.FieldCaption(Blocked), false, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, ServiceLine2."No.", ServiceLine2."Variant Code")));
                                end else
                                    AddError(StrSubstNo(Text008, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, ServiceLine2."No.", ServiceLine2."Variant Code")));
                            end;


                            if Item.Reserve = Item.Reserve::Always then begin
                                ServiceLine2.CalcFields(ServiceLine2."Reserved Quantity");
                                if ServiceLine2."Document Type" = ServiceLine2."Document Type"::"Credit Memo" then begin
                                    if (ServiceLine2.SignedXX(ServiceLine2.Quantity) < 0) and (Abs(ServiceLine2."Reserved Quantity") < Abs(ServiceLine2.Quantity)) then
                                        AddError(StrSubstNo(Text015, ServiceLine2.FieldCaption("Reserved Quantity"), ServiceLine2.SignedXX(ServiceLine2.Quantity)));
                                end else
                                    if (ServiceLine2.SignedXX(ServiceLine2.Quantity) < 0) and (Abs(ServiceLine2."Reserved Quantity") < Abs(ServiceLine2."Qty. to Ship")) then
                                        AddError(StrSubstNo(Text015, ServiceLine2.FieldCaption("Reserved Quantity"), ServiceLine2.SignedXX(ServiceLine2."Qty. to Ship")));
                            end
                        end else
                            AddError(StrSubstNo(Text008, Item.TableCaption(), ServiceLine2."No."));
                end;
            ServiceLine2.Type::Resource:
                begin
                    if (ServiceLine2."No." = '') and (ServiceLine2.Quantity = 0) then
                        exit;

                    if ServiceLine2."No." <> '' then
                        if Res.Get(ServiceLine2."No.") then begin
                            if Res."Privacy Blocked" then
                                AddError(StrSubstNo(MustBeForErr, Res.FieldCaption("Privacy Blocked"), false, Res.TableCaption(), ServiceLine2."No."));
                            if Res.Blocked then
                                AddError(StrSubstNo(MustBeForErr, Res.FieldCaption(Blocked), false, Res.TableCaption(), ServiceLine2."No."));
                        end else
                            AddError(StrSubstNo(Text008, Res.TableCaption(), ServiceLine2."No."));
                end;
        end;
    end;

    local procedure VerifyCustomerNo(ServiceHeader: Record "Service Header")
    var
        ShipQtyExist: Boolean;
    begin
        if ServiceHeader."Customer No." = '' then
            AddError(StrSubstNo(Text006, ServiceHeader.FieldCaption("Customer No.")))
        else
            if Cust.Get(ServiceHeader."Customer No.") then begin
                if (Cust.Blocked = Cust.Blocked::Ship) and Ship then begin
                    ServiceLine2.SetRange("Document Type", ServiceHeader."Document Type");
                    ServiceLine2.SetRange("Document No.", ServiceHeader."No.");
                    ServiceLine2.SetFilter("Qty. to Ship", '>0');
                    if ServiceLine2.FindFirst() then
                        ShipQtyExist := true;
                end;
                if Cust."Privacy Blocked" then
                    AddError(
                      StrSubstNo(
                        Text045,
                        Cust.FieldCaption("Privacy Blocked"), Cust."Privacy Blocked", Cust.TableCaption(), ServiceHeader."Customer No."));
                if (Cust.Blocked = Cust.Blocked::All) or
                   ((Cust.Blocked = Cust.Blocked::Invoice) and
                    (not (ServiceHeader."Document Type" = ServiceHeader."Document Type"::"Credit Memo"))) or
                   ShipQtyExist
                then
                    AddError(
                      StrSubstNo(
                        Text045,
                        Cust.FieldCaption(Blocked), Cust.Blocked, Cust.TableCaption(), ServiceHeader."Customer No."));
            end else
                AddError(
                  StrSubstNo(
                    Text008,
                    Cust.TableCaption(), ServiceHeader."Customer No."));
    end;

    local procedure VerifyBilltoCustomerNo(ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Bill-to Customer No." = '' then
            AddError(StrSubstNo(Text006, ServiceHeader.FieldCaption("Bill-to Customer No.")))
        else
            if ServiceHeader."Bill-to Customer No." <> ServiceHeader."Customer No." then
                if Cust.Get(ServiceHeader."Bill-to Customer No.") then begin
                    if Cust."Privacy Blocked" then
                        AddError(
                          StrSubstNo(
                            Text045,
                            Cust.FieldCaption("Privacy Blocked"), Cust."Privacy Blocked", Cust.TableCaption(), ServiceHeader."Bill-to Customer No."));
                    if (Cust.Blocked = Cust.Blocked::All) or
                       ((Cust.Blocked = Cust.Blocked::Invoice) and
                        (ServiceHeader."Document Type" = ServiceHeader."Document Type"::"Credit Memo"))
                    then
                        AddError(
                          StrSubstNo(
                            Text045,
                            Cust.FieldCaption(Blocked), false, Cust.TableCaption(), ServiceHeader."Bill-to Customer No."));
                end else
                    AddError(
                      StrSubstNo(
                        Text008,
                        Cust.TableCaption(), ServiceHeader."Bill-to Customer No."));
    end;

    local procedure VerifyPostingDate(ServiceHeader: Record "Service Header")
    var
        UserSetupManagement: Codeunit "User Setup Management";
        TempErrorText: Text[250];
    begin
        if ServiceHeader."Posting Date" = 0D then
            AddError(StrSubstNo(Text006, ServiceHeader.FieldCaption("Posting Date")))
        else
            if ServiceHeader."Posting Date" <> NormalDate(ServiceHeader."Posting Date") then
                AddError(StrSubstNo(Text009, ServiceHeader.FieldCaption("Posting Date")))
            else
                if not UserSetupManagement.TestAllowedPostingDate(ServiceHeader."Posting Date", TempErrorText) then
                    AddError(TempErrorText);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckServiceDoc(ServiceHeader: Record "Service Header"; var ErrorText: array[99] of Text[250]; var ErrorCounter: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckType(ServiceLine: Record "Service Line"; var ErrorCounter: Integer; var ErrorText: array[99] of Text[250])
    begin
    end;
}
