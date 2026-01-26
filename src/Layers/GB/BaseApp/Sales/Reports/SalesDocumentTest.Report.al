// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.Security.User;
using System.Utilities;

report 202 "Sales Document - Test"
{
    DefaultLayout = RDLC;
#if not CLEAN27
    RDLCLayout = './Sales/Reports/SalesDocumentTestGB.rdlc';
#else
    RDLCLayout = './Sales/Reports/SalesDocumentTest.rdlc';
#endif
    Caption = 'Sales Document - Test';
    WordMergeDataItem = "Sales Header";

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = where("Document Type" = filter(<> Quote));
            RequestFilterFields = "Document Type", "No.";
            RequestFilterHeading = 'Sales Document';
            column(Sales_Header_Document_Type; "Document Type")
            {
            }
            column(Sales_Header_No_; "No.")
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(USERID; UserId)
                {
                }
                column(STRSUBSTNO_Text014_SalesHeaderFilter_; StrSubstNo(Text014, SalesHeaderFilter))
                {
                }
                column(SalesHeaderFilter; SalesHeaderFilter)
                {
                }
                column(ShipInvText; ShipInvText)
                {
                }
                column(ReceiveInvText; ReceiveInvText)
                {
                }
                column(Sales_Header___Sell_to_Customer_No__; "Sales Header"."Sell-to Customer No.")
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
                column(SellToAddr_8_; SellToAddr[8])
                {
                }
                column(SellToAddr_7_; SellToAddr[7])
                {
                }
                column(SellToAddr_6_; SellToAddr[6])
                {
                }
                column(SellToAddr_5_; SellToAddr[5])
                {
                }
                column(SellToAddr_4_; SellToAddr[4])
                {
                }
                column(SellToAddr_3_; SellToAddr[3])
                {
                }
                column(SellToAddr_2_; SellToAddr[2])
                {
                }
                column(SellToAddr_1_; SellToAddr[1])
                {
                }
                column(Sales_Header___Ship_to_Code_; "Sales Header"."Ship-to Code")
                {
                }
                column(FORMAT__Sales_Header___Document_Type____________Sales_Header___No__; Format("Sales Header"."Document Type") + ' ' + "Sales Header"."No.")
                {
                }
                column(ShipReceiveOnNextPostReq; ShipReceiveOnNextPostReq)
                {
                }
                column(ShowCostAssignment; ShowCostAssignment)
                {
                }
                column(InvOnNextPostReq; InvOnNextPostReq)
                {
                }
                column(Sales_Header___VAT_Base_Discount___; "Sales Header"."VAT Base Discount %")
                {
                }
                column(SalesDocumentType; Format("Sales Header"."Document Type", 0, 2))
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
                column(Sales_Header___Bill_to_Customer_No__; "Sales Header"."Bill-to Customer No.")
                {
                }
                column(Sales_Header___Salesperson_Code_; "Sales Header"."Salesperson Code")
                {
                }
                column(Sales_Header___Your_Reference_; "Sales Header"."Your Reference")
                {
                }
                column(Sales_Header___Customer_Posting_Group_; "Sales Header"."Customer Posting Group")
                {
                }
                column(Sales_Header___Posting_Date_; Format("Sales Header"."Posting Date"))
                {
                }
                column(Sales_Header___Document_Date_; Format("Sales Header"."Document Date"))
                {
                }
                column(Sales_Header___Prices_Including_VAT_; "Sales Header"."Prices Including VAT")
                {
                }
                column(SalesHdrPricesIncludingVATFmt; Format("Sales Header"."Prices Including VAT"))
                {
                }
                column(Sales_Header___Payment_Terms_Code_; "Sales Header"."Payment Terms Code")
                {
                }
                column(Sales_Header___Payment_Discount___; "Sales Header"."Payment Discount %")
                {
                }
                column(Sales_Header___Due_Date_; Format("Sales Header"."Due Date"))
                {
                }
                column(Sales_Header___Customer_Disc__Group_; "Sales Header"."Customer Disc. Group")
                {
                }
                column(Sales_Header___Pmt__Discount_Date_; Format("Sales Header"."Pmt. Discount Date"))
                {
                }
                column(Sales_Header___Invoice_Disc__Code_; "Sales Header"."Invoice Disc. Code")
                {
                }
                column(Sales_Header___Shipment_Method_Code_; "Sales Header"."Shipment Method Code")
                {
                }
                column(Sales_Header___Payment_Method_Code_; "Sales Header"."Payment Method Code")
                {
                }
                column(Sales_Header___Customer_Posting_Group__Control104; "Sales Header"."Customer Posting Group")
                {
                }
                column(Sales_Header___Posting_Date__Control105; Format("Sales Header"."Posting Date"))
                {
                }
                column(Sales_Header___Document_Date__Control106; Format("Sales Header"."Document Date"))
                {
                }
                column(Sales_Header___Order_Date_; Format("Sales Header"."Order Date"))
                {
                }
                column(Sales_Header___Shipment_Date_; Format("Sales Header"."Shipment Date"))
                {
                }
                column(Sales_Header___Prices_Including_VAT__Control194; "Sales Header"."Prices Including VAT")
                {
                }
#if not CLEAN27
                column(SalesHeader__VAT_Base_Discount___; SalesHeader."VAT Base Discount %")
                {
                }
#endif
                column(Sales_Header___Payment_Terms_Code__Control18; "Sales Header"."Payment Terms Code")
                {
                }
                column(Sales_Header___Due_Date__Control19; Format("Sales Header"."Due Date"))
                {
                }
                column(Sales_Header___Pmt__Discount_Date__Control22; Format("Sales Header"."Pmt. Discount Date"))
                {
                }
                column(Sales_Header___Payment_Discount____Control23; "Sales Header"."Payment Discount %")
                {
                }
                column(Sales_Header___Payment_Method_Code__Control26; "Sales Header"."Payment Method Code")
                {
                }
                column(Sales_Header___Shipment_Method_Code__Control37; "Sales Header"."Shipment Method Code")
                {
                }
                column(Sales_Header___Customer_Disc__Group__Control100; "Sales Header"."Customer Disc. Group")
                {
                }
                column(Sales_Header___Invoice_Disc__Code__Control102; "Sales Header"."Invoice Disc. Code")
                {
                }
                column(Sales_Header___Customer_Posting_Group__Control130; "Sales Header"."Customer Posting Group")
                {
                }
                column(Sales_Header___Posting_Date__Control131; Format("Sales Header"."Posting Date"))
                {
                }
                column(Sales_Header___Document_Date__Control132; Format("Sales Header"."Document Date"))
                {
                }
                column(Sales_Header___Prices_Including_VAT__Control196; "Sales Header"."Prices Including VAT")
                {
                }
#if not CLEAN27
                column(DisplayPaymentDiscount; DisplayPaymentDiscount)
                {
                }
                column(DiscountTextCptn; DiscountText)
                {
                }
                column(SalesHeader__VAT_Base_Discount____Control1040003; SalesHeader."VAT Base Discount %")
                {
                }
#endif
                column(Sales_Header___Applies_to_Doc__Type_; "Sales Header"."Applies-to Doc. Type")
                {
                }
                column(Sales_Header___Applies_to_Doc__No__; "Sales Header"."Applies-to Doc. No.")
                {
                }
                column(Sales_Header___Customer_Posting_Group__Control136; "Sales Header"."Customer Posting Group")
                {
                }
                column(Sales_Header___Posting_Date__Control137; Format("Sales Header"."Posting Date"))
                {
                }
                column(Sales_Header___Document_Date__Control138; Format("Sales Header"."Document Date"))
                {
                }
                column(Sales_Header___Prices_Including_VAT__Control198; "Sales Header"."Prices Including VAT")
                {
                }
#if not CLEAN27
                column(SalesHeader__VAT_Base_Discount____Control1040005; SalesHeader."VAT Base Discount %")
                {
                }
#endif
                column(PageCounter_Number; Number)
                {
                }
                column(Sales_Document___TestCaption; Sales_Document___TestCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Sales_Header___Sell_to_Customer_No__Caption; "Sales Header".FieldCaption("Sell-to Customer No."))
                {
                }
                column(Ship_toCaption; Ship_toCaptionLbl)
                {
                }
                column(Sell_toCaption; Sell_toCaptionLbl)
                {
                }
                column(Sales_Header___Ship_to_Code_Caption; "Sales Header".FieldCaption("Ship-to Code"))
                {
                }
                column(Bill_toCaption; Bill_toCaptionLbl)
                {
                }
                column(Sales_Header___Bill_to_Customer_No__Caption; "Sales Header".FieldCaption("Bill-to Customer No."))
                {
                }
                column(Sales_Header___Salesperson_Code_Caption; "Sales Header".FieldCaption("Salesperson Code"))
                {
                }
                column(Sales_Header___Your_Reference_Caption; "Sales Header".FieldCaption("Your Reference"))
                {
                }
                column(Sales_Header___Customer_Posting_Group_Caption; "Sales Header".FieldCaption("Customer Posting Group"))
                {
                }
                column(Sales_Header___Posting_Date_Caption; Sales_Header___Posting_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Document_Date_Caption; Sales_Header___Document_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Prices_Including_VAT_Caption; "Sales Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(Sales_Header___Payment_Terms_Code_Caption; "Sales Header".FieldCaption("Payment Terms Code"))
                {
                }
                column(Sales_Header___Payment_Discount___Caption; "Sales Header".FieldCaption("Payment Discount %"))
                {
                }
                column(Sales_Header___Due_Date_Caption; Sales_Header___Due_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Customer_Disc__Group_Caption; "Sales Header".FieldCaption("Customer Disc. Group"))
                {
                }
                column(Sales_Header___Pmt__Discount_Date_Caption; Sales_Header___Pmt__Discount_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Invoice_Disc__Code_Caption; "Sales Header".FieldCaption("Invoice Disc. Code"))
                {
                }
                column(Sales_Header___Shipment_Method_Code_Caption; "Sales Header".FieldCaption("Shipment Method Code"))
                {
                }
                column(Sales_Header___Payment_Method_Code_Caption; "Sales Header".FieldCaption("Payment Method Code"))
                {
                }
                column(Sales_Header___Customer_Posting_Group__Control104Caption; "Sales Header".FieldCaption("Customer Posting Group"))
                {
                }
                column(Sales_Header___Posting_Date__Control105Caption; Sales_Header___Posting_Date__Control105CaptionLbl)
                {
                }
                column(Sales_Header___Document_Date__Control106Caption; Sales_Header___Document_Date__Control106CaptionLbl)
                {
                }
                column(Sales_Header___Order_Date_Caption; Sales_Header___Order_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Shipment_Date_Caption; Sales_Header___Shipment_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Prices_Including_VAT__Control194Caption; "Sales Header".FieldCaption("Prices Including VAT"))
                {
                }
#if not CLEAN27
                column(SalesHeader__VAT_Base_Discount___Caption; SalesHeader__VAT_Base_Discount___CaptionLbl)
                {
                }
#endif
                column(Sales_Header___Payment_Terms_Code__Control18Caption; "Sales Header".FieldCaption("Payment Terms Code"))
                {
                }
                column(Sales_Header___Payment_Discount____Control23Caption; "Sales Header".FieldCaption("Payment Discount %"))
                {
                }
                column(Sales_Header___Due_Date__Control19Caption; Sales_Header___Due_Date__Control19CaptionLbl)
                {
                }
                column(Sales_Header___Pmt__Discount_Date__Control22Caption; Sales_Header___Pmt__Discount_Date__Control22CaptionLbl)
                {
                }
                column(Sales_Header___Shipment_Method_Code__Control37Caption; "Sales Header".FieldCaption("Shipment Method Code"))
                {
                }
                column(Sales_Header___Payment_Method_Code__Control26Caption; "Sales Header".FieldCaption("Payment Method Code"))
                {
                }
                column(Sales_Header___Customer_Disc__Group__Control100Caption; "Sales Header".FieldCaption("Customer Disc. Group"))
                {
                }
                column(Sales_Header___Invoice_Disc__Code__Control102Caption; "Sales Header".FieldCaption("Invoice Disc. Code"))
                {
                }
                column(Sales_Header___Customer_Posting_Group__Control130Caption; "Sales Header".FieldCaption("Customer Posting Group"))
                {
                }
                column(Sales_Header___Posting_Date__Control131Caption; Sales_Header___Posting_Date__Control131CaptionLbl)
                {
                }
                column(Sales_Header___Document_Date__Control132Caption; Sales_Header___Document_Date__Control132CaptionLbl)
                {
                }
                column(Sales_Header___Prices_Including_VAT__Control196Caption; "Sales Header".FieldCaption("Prices Including VAT"))
                {
                }
#if not CLEAN27
                column(SalesHeader__VAT_Base_Discount____Control1040003Caption; SalesHeader__VAT_Base_Discount____Control1040003CaptionLbl)
                {
                }
#endif
                column(Sales_Header___Applies_to_Doc__Type_Caption; "Sales Header".FieldCaption("Applies-to Doc. Type"))
                {
                }
                column(Sales_Header___Applies_to_Doc__No__Caption; "Sales Header".FieldCaption("Applies-to Doc. No."))
                {
                }
                column(Sales_Header___Customer_Posting_Group__Control136Caption; "Sales Header".FieldCaption("Customer Posting Group"))
                {
                }
                column(Sales_Header___Posting_Date__Control137Caption; Sales_Header___Posting_Date__Control137CaptionLbl)
                {
                }
                column(Sales_Header___Document_Date__Control138Caption; Sales_Header___Document_Date__Control138CaptionLbl)
                {
                }
                column(Sales_Header___Prices_Including_VAT__Control198Caption; "Sales Header".FieldCaption("Prices Including VAT"))
                {
                }
#if not CLEAN27
                column(SalesHeader__VAT_Base_Discount____Control1040005Caption; SalesHeader__VAT_Base_Discount____Control1040005CaptionLbl)
                {
                }
#endif
                dataitem(DimensionLoop1; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(DimensionLoop1_Number; Number)
                    {
                    }
                    column(DimText_Control162; DimText)
                    {
                    }
                    column(Header_DimensionsCaption; Header_DimensionsCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not DimSetEntry1.FindSet() then
                                CurrReport.Break();
                        end else
                            if not Continue then
                                CurrReport.Break();

                        DimText := '';
                        Continue := false;
                        repeat
                            OldDimText := DimText;
                            if DimText = '' then
                                DimText := StrSubstNo('%1 - %2', DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code")
                            else
                                DimText :=
                                  StrSubstNo(
                                    '%1; %2 - %3', DimText, DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code");
                            if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                DimText := OldDimText;
                                Continue := true;
                                exit;
                            end;
                        until DimSetEntry1.Next() = 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ShowDim then
                            CurrReport.Break();
                    end;
                }
                dataitem(HeaderErrorCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(ErrorText_Number_; ErrorText[Number])
                    {
                    }
                    column(HeaderErrorCounter_Number; Number)
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
                    dataitem("Sales Line"; "Sales Line")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemLinkReference = "Sales Header";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
                        column(Sales_Line_Document_Type; "Document Type")
                        {
                        }
                        column(Sales_Line_Document_No_; "Document No.")
                        {
                        }
                        column(Sales_Line_Line_No_; "Line No.")
                        {
                        }

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
                        column(QtyToHandleCaption; QtyToHandleCaption)
                        {
                        }
                        column(Sales_Line__Type; Format("Sales Line".Type))
                        {
                        }
                        column(Sales_Line___No__; "Sales Line"."No.")
                        {
                        }
                        column(Sales_Line__Description; "Sales Line".Description)
                        {
                        }
                        column(Sales_Line__Quantity; "Sales Line".Quantity)
                        {
                        }
                        column(QtyToHandle; QtyToHandle)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(Sales_Line___Qty__to_Invoice_; "Sales Line"."Qty. to Invoice")
                        {
                        }
                        column(Sales_Line___Unit_Price_; "Sales Line"."Unit Price")
                        {
                            AutoFormatExpression = "Sales Line"."Currency Code";
                            AutoFormatType = 2;
                        }
                        column(Sales_Line___Line_Discount___; "Sales Line"."Line Discount %")
                        {
                        }
                        column(Sales_Line___Line_Amount_; "Sales Line"."Line Amount")
                        {
                            AutoFormatExpression = "Sales Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(Sales_Line___Allow_Invoice_Disc__; "Sales Line"."Allow Invoice Disc.")
                        {
                        }
                        column(Sales_Line___VAT_Identifier_; "Sales Line"."VAT Identifier")
                        {
                        }
                        column(SalesLineAllowInvoiceDiscFmt; Format("Sales Line"."Allow Invoice Disc."))
                        {
                        }
                        column(RoundLoop_RoundLoop_Number; Number)
                        {
                        }
                        column(Sales_Line___Inv__Discount_Amount_; "Sales Line"."Inv. Discount Amount")
                        {
                        }
#if not CLEAN27
                        column(SalesLine__Reverse_Charge_; SalesLine."Reverse Charge")
                        {
                        }
                        column(SalesSetup__Invoice_Wording_; SalesSetup."Invoice Wording")
                        {
                        }
#endif
                        column(TempSalesLine__Inv__Discount_Amount_; -TempSalesLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TempSalesLine__Line_Amount_; TempSalesLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SumLineAmount; SumLineAmount)
                        {
                        }
                        column(SumInvDiscountAmount; SumInvDiscountAmount)
                        {
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(TempSalesLine__Line_Amount_____Sales_Line___Inv__Discount_Amount_; TempSalesLine."Line Amount" - TempSalesLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(VATAmountLine_VATAmountText; TempVATAmountLine.VATAmountText())
                        {
                        }
                        column(TempSalesLine__Line_Amount____TempSalesLine__Inv__Discount_Amount_; TempSalesLine."Line Amount" - TempSalesLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmount; VATAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TempSalesLine__Line_Amount____TempSalesLine__Inv__Discount_Amount____VATAmount; TempSalesLine."Line Amount" - TempSalesLine."Inv. Discount Amount" + VATAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(VATDiscountAmount; -VATDiscountAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalInclVATText_Control191; TotalInclVATText)
                        {
                        }
                        column(VATAmountLine_VATAmountText_Control189; TempVATAmountLine.VATAmountText())
                        {
                        }
                        column(VATBaseAmount___VATAmount; VATBaseAmount + VATAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmount_Control188; VATAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalExclVATText_Control186; TotalExclVATText)
                        {
                        }
                        column(VATBaseAmount; VATBaseAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
#if not CLEAN27
                        column(SalesLine__Reverse_Charge__Control10410094; SalesLine."Reverse Charge")
                        {
                        }
                        column(TotalReverseCharge; TotalReverseCharge)
                        {
                        }
#endif
                        column(Sales_Line___No__Caption; "Sales Line".FieldCaption("No."))
                        {
                        }
                        column(Sales_Line__DescriptionCaption; "Sales Line".FieldCaption(Description))
                        {
                        }
                        column(Sales_Line___Qty__to_Invoice_Caption; "Sales Line".FieldCaption("Qty. to Invoice"))
                        {
                        }
                        column(Unit_PriceCaption; Unit_PriceCaptionLbl)
                        {
                        }
                        column(Sales_Line___Line_Discount___Caption; Sales_Line___Line_Discount___CaptionLbl)
                        {
                        }
                        column(Sales_Line___Allow_Invoice_Disc__Caption; "Sales Line".FieldCaption("Allow Invoice Disc."))
                        {
                        }
                        column(Sales_Line___VAT_Identifier_Caption; "Sales Line".FieldCaption("VAT Identifier"))
                        {
                        }
                        column(AmountCaption; AmountCaptionLbl)
                        {
                        }
                        column(Sales_Line__TypeCaption; "Sales Line".FieldCaption(Type))
                        {
                        }
                        column(Sales_Line__QuantityCaption; "Sales Line".FieldCaption(Quantity))
                        {
                        }
#if not CLEAN27
                        column(Reverse_ChargeCaption; Reverse_ChargeCaptionLbl)
                        {
                        }
#endif
                        column(TempSalesLine__Inv__Discount_Amount_Caption; TempSalesLine__Inv__Discount_Amount_CaptionLbl)
                        {
                        }
                        column(SubtotalCaption; SubtotalCaptionLbl)
                        {
                        }
                        column(VATDiscountAmountCaption; VATDiscountAmountCaptionLbl)
                        {
                        }
#if not CLEAN27
                        column(Reverse_ChargeCaption_Control1040093; Reverse_ChargeCaption_Control1040093Lbl)
                        {
                        }
#endif
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(DimText_Control159; DimText)
                            {
                            }
                            column(DimensionLoop2_Number; Number)
                            {
                            }
                            column(DimText_Control161; DimText)
                            {
                            }
                            column(Line_DimensionsCaption; Line_DimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then begin
                                    if not DimSetEntry2.FindSet() then
                                        CurrReport.Break();
                                end else
                                    if not Continue then
                                        CurrReport.Break();

                                DimText := '';
                                Continue := false;
                                repeat
                                    OldDimText := DimText;
                                    if DimText = '' then
                                        DimText := StrSubstNo('%1 - %2', DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code")
                                    else
                                        DimText :=
                                          StrSubstNo(
                                            '%1; %2 - %3', DimText, DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code");
                                    if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                        DimText := OldDimText;
                                        Continue := true;
                                        exit;
                                    end;
                                until DimSetEntry2.Next() = 0;
                            end;

                            trigger OnPostDataItem()
                            begin
                                SumLineAmount := SumLineAmount + TempSalesLine."Line Amount";
                                SumInvDiscountAmount := SumInvDiscountAmount + TempSalesLine."Inv. Discount Amount";
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowDim then
                                    CurrReport.Break();
                            end;
                        }
                        dataitem(LineErrorCounter; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(ErrorText_Number__Control97; ErrorText[Number])
                            {
                            }
                            column(LineErrorCounter_Number; Number)
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
                            TableID: array[10] of Integer;
                            No: array[10] of Code[20];
                            Fraction: Decimal;
                            IsHandled: Boolean;
                        begin
                            if Number = 1 then
                                TempSalesLine.Find('-')
                            else
                                TempSalesLine.Next();
                            "Sales Line" := TempSalesLine;

                            if not "Sales Header"."Prices Including VAT" and
                               ("Sales Line"."VAT Calculation Type" = "Sales Line"."VAT Calculation Type"::"Full VAT")
                            then
                                TempSalesLine."Line Amount" := 0;

                            DimSetEntry2.SetRange("Dimension Set ID", "Sales Line"."Dimension Set ID");
                            DimMgt.GetDimensionSet(TempDimSetEntry, "Sales Line"."Dimension Set ID");

                            if "Sales Line"."Document Type" in ["Sales Line"."Document Type"::"Return Order", "Sales Line"."Document Type"::"Credit Memo"]
                            then begin
                                if "Sales Line"."Document Type" = "Sales Line"."Document Type"::"Credit Memo" then begin
                                    if ("Sales Line"."Return Qty. to Receive" <> "Sales Line".Quantity) and ("Sales Line"."Return Receipt No." = '') then
                                        AddError(StrSubstNo(Text015, "Sales Line".FieldCaption("Return Qty. to Receive"), "Sales Line".Quantity));
                                    if "Sales Line"."Qty. to Invoice" <> "Sales Line".Quantity then
                                        AddError(StrSubstNo(Text015, "Sales Line".FieldCaption("Qty. to Invoice"), "Sales Line".Quantity));
                                end;
                                if "Sales Line"."Qty. to Ship" <> 0 then
                                    AddError(StrSubstNo(Text043, "Sales Line".FieldCaption("Qty. to Ship")));
                            end else begin
                                if "Sales Line"."Document Type" = "Sales Line"."Document Type"::Invoice then begin
                                    if ("Sales Line"."Qty. to Ship" <> "Sales Line".Quantity) and ("Sales Line"."Shipment No." = '') then
                                        AddError(StrSubstNo(Text015, "Sales Line".FieldCaption("Qty. to Ship"), "Sales Line".Quantity));
                                    if "Sales Line"."Qty. to Invoice" <> "Sales Line".Quantity then
                                        AddError(StrSubstNo(Text015, "Sales Line".FieldCaption("Qty. to Invoice"), "Sales Line".Quantity));
                                end;
                                if "Sales Line"."Return Qty. to Receive" <> 0 then
                                    AddError(StrSubstNo(Text043, "Sales Line".FieldCaption("Return Qty. to Receive")));
                            end;

                            if not "Sales Header".Ship then
                                "Sales Line"."Qty. to Ship" := 0;
                            if not "Sales Header".Receive then
                                "Sales Line"."Return Qty. to Receive" := 0;

                            if ("Sales Line"."Document Type" = "Sales Line"."Document Type"::Invoice) and ("Sales Line"."Shipment No." <> '') then begin
                                "Sales Line"."Quantity Shipped" := "Sales Line".Quantity;
                                "Sales Line"."Qty. to Ship" := 0;
                            end;

                            if ("Sales Line"."Document Type" = "Sales Line"."Document Type"::"Credit Memo") and ("Sales Line"."Return Receipt No." <> '') then begin
                                "Sales Line"."Return Qty. Received" := "Sales Line".Quantity;
                                "Sales Line"."Return Qty. to Receive" := 0;
                            end;

                            if "Sales Header".Invoice then begin
                                if "Sales Line"."Document Type" in ["Sales Line"."Document Type"::"Return Order", "Sales Line"."Document Type"::"Credit Memo"] then
                                    MaxQtyToBeInvoiced := "Sales Line"."Return Qty. to Receive" + "Sales Line"."Return Qty. Received" - "Sales Line"."Quantity Invoiced"
                                else
                                    MaxQtyToBeInvoiced := "Sales Line"."Qty. to Ship" + "Sales Line"."Quantity Shipped" - "Sales Line"."Quantity Invoiced";
                                if Abs("Sales Line"."Qty. to Invoice") > Abs(MaxQtyToBeInvoiced) then
                                    "Sales Line"."Qty. to Invoice" := MaxQtyToBeInvoiced;
                            end else
                                "Sales Line"."Qty. to Invoice" := 0;

                            if "Sales Line"."Gen. Prod. Posting Group" <> '' then begin
                                if ("Sales Header"."Document Type" in
                                    ["Sales Header"."Document Type"::"Return Order",
                                     "Sales Header"."Document Type"::"Credit Memo"]) and
                                   ("Sales Header"."Applies-to Doc. Type" = "Sales Header"."Applies-to Doc. Type"::Invoice) and
                                   ("Sales Header"."Applies-to Doc. No." <> '')
                                then begin
                                    CustLedgEntry.SetCurrentKey("Document No.");
                                    CustLedgEntry.SetRange("Customer No.", "Sales Header"."Bill-to Customer No.");
                                    CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
                                    CustLedgEntry.SetRange("Document No.", "Sales Header"."Applies-to Doc. No.");
                                    if (not CustLedgEntry.FindLast()) and (not ApplNoError) then begin
                                        ApplNoError := true;
                                        AddError(
                                          StrSubstNo(
                                            Text016,
                                            "Sales Header".FieldCaption("Applies-to Doc. No."), "Sales Header"."Applies-to Doc. No."));
                                    end;
                                end;

                                if not VATPostingSetup.Get("Sales Line"."VAT Bus. Posting Group", "Sales Line"."VAT Prod. Posting Group") then
                                    AddError(
                                      StrSubstNo(
                                        Text017,
                                        VATPostingSetup.TableCaption(), "Sales Line"."VAT Bus. Posting Group", "Sales Line"."VAT Prod. Posting Group"));
                                if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
                                    if ("Sales Header"."VAT Registration No." = '') and (not VATNoError) then begin
                                        VATNoError := true;
                                        AddError(
                                          StrSubstNo(
                                            Text035, "Sales Header".FieldCaption("VAT Registration No.")));
                                    end;
                            end;

                            if "Sales Line".Quantity <> 0 then begin
                                if "Sales Line"."No." = '' then
                                    AddError(StrSubstNo(Text019, "Sales Line".Type, "Sales Line".FieldCaption("No.")));
                                if "Sales Line".Type = "Sales Line".Type::" " then
                                    AddError(StrSubstNo(Text006, "Sales Line".FieldCaption(Type)));
                            end else
                                if "Sales Line".Amount <> 0 then
                                    AddError(
                                      StrSubstNo(Text020, "Sales Line".FieldCaption(Amount), "Sales Line".FieldCaption(Quantity)));

                            if "Sales Line"."Drop Shipment" then begin
                                if "Sales Line".Type <> "Sales Line".Type::Item then
                                    AddError(Text021);
                                if ("Sales Line"."Qty. to Ship" <> 0) and ("Sales Line"."Purch. Order Line No." = 0) then begin
                                    AddError(StrSubstNo(Text022, "Sales Line"."Line No."));
                                    AddError(Text023);
                                end;
                            end;

                            SalesLine := "Sales Line";
                            if not ("Sales Line"."Document Type" in
                                    ["Sales Line"."Document Type"::"Return Order", "Sales Line"."Document Type"::"Credit Memo"])
                            then begin
                                SalesLine."Qty. to Ship" := -SalesLine."Qty. to Ship";
                                SalesLine."Qty. to Invoice" := -SalesLine."Qty. to Invoice";
                            end;

                            RemQtyToBeInvoiced := SalesLine."Qty. to Invoice";

                            case "Sales Line"."Document Type" of
                                "Sales Line"."Document Type"::"Return Order", "Sales Line"."Document Type"::"Credit Memo":
                                    CheckRcptLines("Sales Line");
                                "Sales Line"."Document Type"::Order, "Sales Line"."Document Type"::Invoice:
                                    CheckShptLines("Sales Line");
                            end;

                            if ("Sales Line".Type <> "Sales Line".Type::" ") and ("Sales Line"."Qty. to Invoice" <> 0) then begin
                                if not ApplicationAreaMgmt.IsSalesTaxEnabled() then
                                    if not GenPostingSetup.Get("Sales Line"."Gen. Bus. Posting Group", "Sales Line"."Gen. Prod. Posting Group") then
                                        AddError(
                                          StrSubstNo(
                                            Text017,
                                            GenPostingSetup.TableCaption(), "Sales Line"."Gen. Bus. Posting Group", "Sales Line"."Gen. Prod. Posting Group"));
                                if not VATPostingSetup.Get("Sales Line"."VAT Bus. Posting Group", "Sales Line"."VAT Prod. Posting Group") then
                                    AddError(
                                      StrSubstNo(
                                        Text017,
                                        VATPostingSetup.TableCaption(), "Sales Line"."VAT Bus. Posting Group", "Sales Line"."VAT Prod. Posting Group"));
                            end;

                            if "Sales Line"."Prepayment %" > 0 then
                                if not "Sales Line"."Prepayment Line" and ("Sales Line".Quantity > 0) then begin
                                    Fraction := ("Sales Line"."Qty. to Invoice" + "Sales Line"."Quantity Invoiced") / "Sales Line".Quantity;
                                    if Fraction > 1 then
                                        Fraction := 1;

                                    case true of
                                        (Fraction * "Sales Line"."Line Amount" < "Sales Line"."Prepmt Amt to Deduct") and
                                      ("Sales Line"."Prepmt Amt to Deduct" <> 0):
                                            AddError(
                                              StrSubstNo(
                                                Text053,
                                                "Sales Line".FieldCaption("Prepmt Amt to Deduct"),
                                                Round(Fraction * "Sales Line"."Line Amount", GLSetup."Amount Rounding Precision")));
                                        (1 - Fraction) * "Sales Line"."Line Amount" <
                                      "Sales Line"."Prepmt. Amt. Inv." - "Sales Line"."Prepmt Amt Deducted" - "Sales Line"."Prepmt Amt to Deduct":
                                            AddError(
                                              StrSubstNo(
                                                Text054,
                                                "Sales Line".FieldCaption("Prepmt Amt to Deduct"),
                                                Round(
                                                  "Sales Line"."Prepmt. Amt. Inv." - "Sales Line"."Prepmt Amt Deducted" - (1 - Fraction) * "Sales Line"."Line Amount",
                                                  GLSetup."Amount Rounding Precision")));
                                    end;
                                end;
                            if not "Sales Line"."Prepayment Line" and ("Sales Line"."Prepmt. Line Amount" > 0) then
                                if "Sales Line"."Prepmt. Line Amount" > "Sales Line"."Prepmt. Amt. Inv." then
                                    AddError(StrSubstNo(Text046, "Sales Line".FieldCaption("Prepmt. Line Amount")));

                            CheckSalesLine("Sales Line");

                            IsHandled := false;
                            OnAfterGetRecordSalesLineOnBeforeCheckDim("Sales Line", GLAcc, OrigMaxLineNo, IsHandled);
                            if not IsHandled then
                                if "Sales Line"."Line No." > OrigMaxLineNo then begin
                                    AddDimToTempLine("Sales Line");
                                    if not DimMgt.CheckDimIDComb("Sales Line"."Dimension Set ID") then
                                        AddError(DimMgt.GetDimCombErr());
                                    if not DimMgt.CheckDimValuePosting(TableID, No, "Sales Line"."Dimension Set ID") then
                                        AddError(DimMgt.GetDimValuePostingErr());
                                end else begin
                                    if not DimMgt.CheckDimIDComb("Sales Line"."Dimension Set ID") then
                                        AddError(DimMgt.GetDimCombErr());

                                    TableID[1] := DimMgt.SalesLineTypeToTableID("Sales Line".Type);
                                    No[1] := "Sales Line"."No.";
                                    TableID[2] := Database::Job;
                                    No[2] := "Sales Line"."Job No.";
                                    OnBeforeCheckDimValuePostingLine("Sales Line", TableID, No);
                                    if not DimMgt.CheckDimValuePosting(TableID, No, "Sales Line"."Dimension Set ID") then
                                        AddError(DimMgt.GetDimValuePostingErr());
                                end;

#if not CLEAN27
                            TotalReverseCharge := TotalReverseCharge + SalesLine."Reverse Charge";
#endif
                            OnAfterCheckSalesDocLine("Sales Line", ErrorText, ErrorCounter);
                        end;

                        trigger OnPreDataItem()
                        begin
                            VATNoError := false;
                            ApplNoError := false;

                            MoreLines := TempSalesLine.Find('+');
                            while MoreLines and (TempSalesLine.Description = '') and (TempSalesLine."Description 2" = '') and
                                  (TempSalesLine."No." = '') and (TempSalesLine.Quantity = 0) and
                                  (TempSalesLine.Amount = 0)
                            do
                                MoreLines := TempSalesLine.Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            TempSalesLine.SetRange("Line No.", 0, TempSalesLine."Line No.");
                            SetRange(Number, 1, TempSalesLine.Count);

                            SumLineAmount := 0;
                            SumInvDiscountAmount := 0;
#if not CLEAN27
                            TotalReverseCharge := 0;
#endif
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(VATAmountLine__VAT_Amount_; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base_; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Sales Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount_; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount_; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount_; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control150; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base__Control151; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Sales Line"."Currency Code";
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
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control171; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount__Control169; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control175; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base__Control176; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Sales Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control177; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control178; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount__Control179; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control181; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base__Control182; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Sales Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control183; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control184; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount__Control185; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATCounter_Number; Number)
                        {
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
                        column(ContinuedCaption; ContinuedCaptionLbl)
                        {
                        }
                        column(ContinuedCaption_Control155; ContinuedCaption_Control155Lbl)
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
                            SetRange(Number, 1, TempVATAmountLine.Count);
                        end;
                    }
                    dataitem(VATCounterLCY; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(VALExchRate; VALExchRate)
                        {
                        }
                        column(VALSpecLCYHeader; VALSpecLCYHeader)
                        {
                        }
                        column(VALVATAmountLCY; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATBaseLCY; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATAmountLCY_Control88; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATBaseLCY_Control165; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT____Control167; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmountLine__VAT_Identifier__Control241; TempVATAmountLine."VAT Identifier")
                        {
                        }
                        column(VALVATAmountLCY_Control242; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATBaseLCY_Control243; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATAmountLCY_Control245; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATBaseLCY_Control246; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VATCounterLCY_Number; Number)
                        {
                        }
                        column(VALVATAmountLCY_Control88Caption; VALVATAmountLCY_Control88CaptionLbl)
                        {
                        }
                        column(VALVATBaseLCY_Control165Caption; VALVATBaseLCY_Control165CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT____Control167Caption; VATAmountLine__VAT____Control167CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Identifier__Control241Caption; VATAmountLine__VAT_Identifier__Control241CaptionLbl)
                        {
                        }
                        column(ContinuedCaption_Control87; ContinuedCaption_Control87Lbl)
                        {
                        }
                        column(ContinuedCaption_Control244; ContinuedCaption_Control244Lbl)
                        {
                        }
                        column(TotalCaption_Control247; TotalCaption_Control247Lbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempVATAmountLine.GetLine(Number);
                            VALVATBaseLCY :=
                              TempVATAmountLine.GetBaseLCY(
                                "Sales Header"."Posting Date", "Sales Header"."Currency Code", "Sales Header"."Currency Factor");
                            VALVATAmountLCY :=
                              TempVATAmountLine.GetAmountLCY(
                                "Sales Header"."Posting Date", "Sales Header"."Currency Code", "Sales Header"."Currency Factor");
                        end;

                        trigger OnPreDataItem()
                        var
                            CurrExchRate: Record "Currency Exchange Rate";
                        begin
                            if (not GLSetup."Print VAT specification in LCY") or
                               ("Sales Header"."Currency Code" = '')
                            then
                                CurrReport.Break();

                            SetRange(Number, 1, TempVATAmountLine.Count);
                            Clear(VALVATBaseLCY);
                            Clear(VALVATAmountLCY);

                            if GLSetup."LCY Code" = '' then
                                VALSpecLCYHeader := Text050 + Text051
                            else
                                VALSpecLCYHeader := Text050 + Format(GLSetup."LCY Code");

                            CurrExchRate.FindCurrency("Sales Header"."Posting Date", "Sales Header"."Currency Code", 1);
                            CurrExchRate."Relational Exch. Rate Amount" := CurrExchRate."Exchange Rate Amount" / "Sales Header"."Currency Factor";
                            VALExchRate := StrSubstNo(Text052, CurrExchRate."Relational Exch. Rate Amount", CurrExchRate."Exchange Rate Amount");
                        end;
                    }
                    dataitem("Item Charge Assignment (Sales)"; "Item Charge Assignment (Sales)")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemLinkReference = "Sales Header";
                        DataItemTableView = sorting("Document Type", "Document No.", "Document Line No.", "Line No.");
                        column(Item_Charge_Assignment__Sales___Qty__to_Assign_; "Qty. to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Amount_to_Assign_; "Amount to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Item_Charge_No__; "Item Charge No.")
                        {
                        }
                        column(SalesLine2_Description; SalesLine2.Description)
                        {
                        }
                        column(SalesLine2_Quantity; SalesLine2.Quantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(Item_Charge_Assignment__Sales___Item_No__; "Item No.")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Qty__to_Assign__Control209; "Qty. to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Unit_Cost_; "Unit Cost")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Amount_to_Assign__Control216; "Amount to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Qty__to_Assign__Control221; "Qty. to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Amount_to_Assign__Control222; "Amount to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Qty__to_Assign__Control224; "Qty. to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Amount_to_Assign__Control225; "Amount to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Sales__Document_Type; "Document Type")
                        {
                        }
                        column(Item_Charge_Assignment__Sales__Document_No_; "Document No.")
                        {
                        }
                        column(Item_Charge_Assignment__Sales__Document_Line_No_; "Document Line No.")
                        {
                        }
                        column(Item_Charge_Assignment__Sales__Line_No_; "Line No.")
                        {
                        }
                        column(Item_Charge_SpecificationCaption; Item_Charge_SpecificationCaptionLbl)
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Item_Charge_No__Caption; FieldCaption("Item Charge No."))
                        {
                        }
                        column(SalesLine2_DescriptionCaption; SalesLine2_DescriptionCaptionLbl)
                        {
                        }
                        column(SalesLine2_QuantityCaption; SalesLine2_QuantityCaptionLbl)
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Item_No__Caption; FieldCaption("Item No."))
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Qty__to_Assign__Control209Caption; FieldCaption("Qty. to Assign"))
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Unit_Cost_Caption; FieldCaption("Unit Cost"))
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Amount_to_Assign__Control216Caption; FieldCaption("Amount to Assign"))
                        {
                        }
                        column(ContinuedCaption_Control210; ContinuedCaption_Control210Lbl)
                        {
                        }
                        column(TotalCaption_Control220; TotalCaption_Control220Lbl)
                        {
                        }
                        column(ContinuedCaption_Control223; ContinuedCaption_Control223Lbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if SalesLine2.Get("Document Type", "Document No.", "Document Line No.") then;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowCostAssignment then
                                CurrReport.Break();
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Clear(TempSalesLine);
                        Clear(SalesPost);
                        TempVATAmountLine.DeleteAll();
                        TempSalesLine.DeleteAll();
                        SalesPost.GetSalesLines("Sales Header", TempSalesLine, 1);
#if not CLEAN27
                        if ReverseChargeApplies then
                            TempSalesLine.SetReverseChargeApplies();
#endif
                        OnAfterSalesPostGetSalesLines("Sales Header", TempSalesLine);
                        TempSalesLine.CalcVATAmountLines(0, "Sales Header", TempSalesLine, TempVATAmountLine);
                        TempSalesLine.UpdateVATOnLines(0, "Sales Header", TempSalesLine, TempVATAmountLine);
                        VATAmount := TempVATAmountLine.GetTotalVATAmount();
                        VATBaseAmount := TempVATAmountLine.GetTotalVATBase();
                        VATDiscountAmount :=
                          TempVATAmountLine.GetTotalVATDiscount("Sales Header"."Currency Code", "Sales Header"."Prices Including VAT");
                    end;
                }
            }

            trigger OnAfterGetRecord()
            var
                TableID: array[10] of Integer;
                No: array[10] of Code[20];
            begin
                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                FormatAddr.SalesHeaderSellTo(SellToAddr, "Sales Header");
                FormatAddr.SalesHeaderBillTo(BillToAddr, "Sales Header");
                FormatAddr.SalesHeaderShipTo(ShipToAddr, ShipToAddr, "Sales Header");
                if "Currency Code" = '' then begin
                    GLSetup.TestField("LCY Code");
                    TotalText := StrSubstNo(Text004, GLSetup."LCY Code");
                    TotalExclVATText := StrSubstNo(Text033, GLSetup."LCY Code");
                    TotalInclVATText := StrSubstNo(Text005, GLSetup."LCY Code");
                end else begin
                    TotalText := StrSubstNo(Text004, "Currency Code");
                    TotalExclVATText := StrSubstNo(Text033, "Currency Code");
                    TotalInclVATText := StrSubstNo(Text005, "Currency Code");
                end;

                Invoice := InvOnNextPostReq;
                Ship := ShipReceiveOnNextPostReq;
                Receive := ShipReceiveOnNextPostReq;

                OnSalesHeaderOnAfterGetRecordOnBeforeVerifySellToCust("Sales Header", ErrorText, ErrorCounter);

                VerifySellToCust("Sales Header");
                VerifyBillToCust("Sales Header");

                SalesSetup.Get();

                VerifyPostingDate("Sales Header");

                if SalesSetup."Posting Date Check on Posting" then
                    if "Posting Date" <> WorkDate() then
                        AddError(
                          StrSubstNo(DifferentPostingDateToWorkDateTxt, FieldCaption("Posting Date"), "Posting Date", WorkDate()));

                if "Document Date" <> 0D then
                    if "Document Date" <> NormalDate("Document Date") then
                        AddError(StrSubstNo(Text009, FieldCaption("Document Date")));

                case "Document Type" of
                    "Document Type"::Order:
                        Receive := false;
                    "Document Type"::Invoice:
                        begin
                            Ship := true;
                            Invoice := true;
                            Receive := false;
                        end;
                    "Document Type"::"Return Order":
                        Ship := false;
                    "Document Type"::"Credit Memo":
                        begin
                            Ship := false;
                            Invoice := true;
                            Receive := true;
                        end;
                end;

                if not (Ship or Invoice or Receive) then
                    AddError(
                      StrSubstNo(
                        Text034,
                        FieldCaption(Ship), FieldCaption(Invoice), FieldCaption(Receive)));

                if Invoice then begin
                    SalesLine.Reset();
                    SalesLine.SetRange("Document Type", "Document Type");
                    SalesLine.SetRange("Document No.", "No.");
                    SalesLine.SetFilter(Quantity, '<>0');
                    if "Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"] then
                        SalesLine.SetFilter("Qty. to Invoice", '<>0');
                    Invoice := SalesLine.Find('-');
                    if Invoice and (not Ship) and ("Document Type" = "Document Type"::Order) then begin
                        Invoice := false;
                        repeat
                            Invoice := (SalesLine."Quantity Shipped" - SalesLine."Quantity Invoiced") <> 0;
                        until Invoice or (SalesLine.Next() = 0);
                    end else
                        if Invoice and (not Receive) and ("Document Type" = "Document Type"::"Return Order") then begin
                            Invoice := false;
                            repeat
                                Invoice := (SalesLine."Return Qty. Received" - SalesLine."Quantity Invoiced") <> 0;
                            until Invoice or (SalesLine.Next() = 0);
                        end;
                end;

                if Ship then begin
                    SalesLine.Reset();
                    SalesLine.SetRange("Document Type", "Document Type");
                    SalesLine.SetRange("Document No.", "No.");
                    SalesLine.SetFilter(Quantity, '<>0');
                    if "Document Type" = "Document Type"::Order then
                        SalesLine.SetFilter("Qty. to Ship", '<>0');
                    SalesLine.SetRange("Shipment No.", '');
                    Ship := SalesLine.Find('-');
                end;
                if Receive then begin
                    SalesLine.Reset();
                    SalesLine.SetRange("Document Type", "Document Type");
                    SalesLine.SetRange("Document No.", "No.");
                    SalesLine.SetFilter(Quantity, '<>0');
                    if "Document Type" = "Document Type"::"Return Order" then
                        SalesLine.SetFilter("Return Qty. to Receive", '<>0');
                    SalesLine.SetRange("Return Receipt No.", '');
                    Receive := SalesLine.Find('-');
                end;

                if not (Ship or Invoice or Receive) then
                    AddError(DocumentErrorsMgt.GetNothingToPostErrorMsg());

                if Invoice then
                    if not ("Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]) then
                        if "Due Date" = 0D then
                            AddError(StrSubstNo(Text006, FieldCaption("Due Date")));

                if Ship and ("Shipping No." = '') then // Order,Invoice
                    if ("Document Type" = "Document Type"::Order) or
                       (("Document Type" = "Document Type"::Invoice) and SalesSetup."Shipment on Invoice")
                    then
                        if "Shipping No. Series" = '' then
                            AddError(
                              StrSubstNo(
                                Text006,
                                FieldCaption("Shipping No. Series")));

                if Receive and ("Return Receipt No." = '') then // Return Order,Credit Memo
                    if ("Document Type" = "Document Type"::"Return Order") or
                       (("Document Type" = "Document Type"::"Credit Memo") and SalesSetup."Return Receipt on Credit Memo")
                    then
                        if "Return Receipt No. Series" = '' then
                            AddError(
                              StrSubstNo(
                                Text006,
                                FieldCaption("Return Receipt No. Series")));

                if Invoice and ("Posting No." = '') then
                    if "Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"] then
                        if "Posting No. Series" = '' then
                            AddError(
                              StrSubstNo(
                                Text006,
                                FieldCaption("Posting No. Series")));

                SalesLine.Reset();
                SalesLine.SetRange("Document Type", "Document Type");
                SalesLine.SetRange("Document No.", "No.");
                SalesLine.SetFilter("Purch. Order Line No.", '<>0');
                if Ship then
                    if SalesLine.Find('-') then
                        repeat
                            if PurchOrderHeader."No." <> SalesLine."Purchase Order No." then begin
                                PurchOrderHeader.Get(PurchOrderHeader."Document Type"::Order, SalesLine."Purchase Order No.");
                                if PurchOrderHeader."Pay-to Vendor No." = '' then
                                    AddError(
                                      StrSubstNo(
                                        Text013,
                                        PurchOrderHeader.FieldCaption("Pay-to Vendor No.")));
                                if PurchOrderHeader."Receiving No." = '' then
                                    if PurchOrderHeader."Receiving No. Series" = '' then
                                        AddError(
                                          StrSubstNo(
                                            Text013,
                                            PurchOrderHeader.FieldCaption("Receiving No. Series")));
                            end;
                        until SalesLine.Next() = 0;

                if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then
                    if SalesSetup."Ext. Doc. No. Mandatory" and ("External Document No." = '') then
                        AddError(StrSubstNo(Text006, FieldCaption("External Document No.")));

                if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                    AddError(DimMgt.GetDimCombErr());

                TableID[1] := Database::Customer;
                No[1] := "Bill-to Customer No.";
                TableID[3] := Database::"Salesperson/Purchaser";
                No[3] := "Salesperson Code";
                TableID[4] := Database::Campaign;
                No[4] := "Campaign No.";
                TableID[5] := Database::"Responsibility Center";
                No[5] := "Responsibility Center";
                OnBeforeCheckDimValuePostingHeader("Sales Header", TableID, No);
                if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                    AddError(DimMgt.GetDimValuePostingErr());

                OnAfterCheckSalesDoc("Sales Header", ErrorText, ErrorCounter);

#if not CLEAN27
                if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then
                    ReverseChargeApplies := SalesPost.CheckIfReverseChargeApplies("Sales Header");
                DisplayPaymentDiscount := "Payment Discount %" <> 0;
                DiscountText := StrSubstNo(DiscountLbl, "Payment Discount %", "Pmt. Discount Date");
#endif
            end;

            trigger OnPreDataItem()
            begin
                SalesHeader.Copy("Sales Header");
                SalesHeader.FilterGroup := 2;
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                if SalesHeader.FindFirst() then begin
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
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
                if SalesHeader.FindFirst() then begin
                    case true of
                        ShipReceiveOnNextPostReq and InvOnNextPostReq:
                            ReceiveInvText := Text018;
                        ShipReceiveOnNextPostReq:
                            ReceiveInvText := Text031;
                        InvOnNextPostReq:
                            ReceiveInvText := Text002;
                    end;
                    ReceiveInvText := StrSubstNo(Text032, ReceiveInvText);
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
                    group("Order/Return Order Posting")
                    {
                        Caption = 'Order/Return Order Posting';
                        field(ShipReceiveOnNextPostReq; ShipReceiveOnNextPostReq)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ship/Receive';
                            ToolTip = 'Specifies whether you want to post the documents that are being tested as shipped/received, as invoiced or as shipped/received and invoiced. Select the check box next to each option that you want to select.';

                            trigger OnValidate()
                            begin
                                if not ShipReceiveOnNextPostReq then
                                    InvOnNextPostReq := true;
                            end;
                        }
                        field(InvOnNextPostReq; InvOnNextPostReq)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Invoice';
                            ToolTip = 'Specifies invoices to test before you post them, to check whether there are any posting dates missing, etc.';

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
                    field(ShowItemChargeAssignment; ShowCostAssignment)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Item Charge Assgnt.';
                        ToolTip = 'Specifies if you want the test report to show the item charges that have been assigned to the sales document.';
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
        SalesHeaderFilter := "Sales Header".GetFilters();
    end;

    var
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
        Text010: Label '%1 is not within your allowed range of posting dates.';
        Text013: Label '%1 must be entered on the purchase order header.';
        Text014: Label 'Sales Document: %1';
        Text015: Label '%1 must be %2.';
        Text016: Label '%1 %2 does not exist on customer entries.';
        Text017: Label '%1 %2 %3 does not exist.';
#pragma warning restore AA0470
        Text018: Label 'Receive and Credit Memo';
#pragma warning disable AA0470
        Text019: Label '%1 %2 must be specified.';
        Text020: Label '%1 must be 0 when %2 is 0.';
#pragma warning restore AA0470
        Text021: Label 'Drop shipments are only possible for items.';
#pragma warning disable AA0470
        Text022: Label 'You cannot ship sales order line %1 because the line is marked';
#pragma warning restore AA0470
        Text023: Label 'as a drop shipment and is not yet associated with a purchase order.';
#pragma warning disable AA0470
        Text024: Label 'The %1 on the shipment is not the same as the %1 on the sales header.';
        Text025: Label 'Line %1 of the return receipt %2, which you are attempting to invoice, has already been invoiced.';
        Text026: Label 'Line %1 of the shipment %2, which you are attempting to invoice, has already been invoiced.';
        Text027: Label '%1 must have the same sign as the shipments.';
#pragma warning restore AA0470
        Text031: Label 'Receive';
#pragma warning disable AA0470
        Text032: Label 'Return Order Posting: %1';
        Text033: Label 'Total %1 Excl. VAT';
        Text034: Label 'Enter "Yes" in %1 and/or %2 and/or %3.';
        Text035: Label 'You must enter the customer''s %1.';
        Text036: Label 'The quantity you are attempting to invoice is greater than the quantity in shipment %1.';
        Text037: Label 'The quantity you are attempting to invoice is greater than the quantity in return receipt %1.';
        Text038: Label 'The %1 on the return receipt is not the same as the %1 on the sales header.';
        Text039: Label '%1 must have the same sign as the return receipt.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        SalesSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        GLAcc: Record "G/L Account";
        Item: Record Item;
        Res: Record Resource;
        SaleShptLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
        PurchOrderHeader: Record "Purchase Header";
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        FA: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        InvtPeriod: Record "Inventory Period";
        FormatAddr: Codeunit "Format Address";
        DimMgt: Codeunit DimensionManagement;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        SalesPost: Codeunit "Sales-Post";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        SalesHeaderFilter: Text;
        SellToAddr: array[8] of Text[100];
        BillToAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        TotalText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
        ShipInvText: Text[50];
        ReceiveInvText: Text[50];
        DimText: Text[120];
        OldDimText: Text[75];
        ErrorText: array[99] of Text[250];
        QtyToHandleCaption: Text[30];
        MaxQtyToBeInvoiced: Decimal;
        RemQtyToBeInvoiced: Decimal;
        QtyToBeInvoiced: Decimal;
        VATAmount: Decimal;
        VATBaseAmount: Decimal;
        VATDiscountAmount: Decimal;
        QtyToHandle: Decimal;
        ErrorCounter: Integer;
        OrigMaxLineNo: Integer;
        InvOnNextPostReq: Boolean;
        ShipReceiveOnNextPostReq: Boolean;
        VATNoError: Boolean;
        ApplNoError: Boolean;
        Continue: Boolean;
        ShowCostAssignment: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text043: Label '%1 must be zero.';
        Text045: Label '%1 must not be %2 for %3 %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        MoreLines: Boolean;
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
        VALSpecLCYHeader: Text[80];
        VALExchRate: Text[50];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text046: Label '%1 must be completely preinvoiced before you can ship or invoice the line.';
#pragma warning restore AA0470
        Text050: Label 'VAT Amount Specification in ';
        Text051: Label 'Local Currency';
#pragma warning disable AA0470
        Text052: Label 'Exchange rate: %1/%2';
        Text053: Label '%1 can at most be %2.';
        Text054: Label '%1 must be at least %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        SumLineAmount: Decimal;
        SumInvDiscountAmount: Decimal;
        DifferentPostingDateToWorkDateTxt: Label '%1 %2 is different to Work Date %3.', Comment = '%1 = Posting Date Field Caption %2=Posting Date Field Value %3=WorkDate value';
#if not CLEAN27
        ReverseChargeApplies: Boolean;
        TotalReverseCharge: Decimal;
#endif
        Sales_Document___TestCaptionLbl: Label 'Sales Document - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Ship_toCaptionLbl: Label 'Ship-to';
        Sell_toCaptionLbl: Label 'Sell-to';
        Bill_toCaptionLbl: Label 'Bill-to';
        Sales_Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        Sales_Header___Document_Date_CaptionLbl: Label 'Document Date';
        Sales_Header___Due_Date_CaptionLbl: Label 'Due Date';
        Sales_Header___Pmt__Discount_Date_CaptionLbl: Label 'Pmt. Discount Date';
        Sales_Header___Posting_Date__Control105CaptionLbl: Label 'Posting Date';
        Sales_Header___Document_Date__Control106CaptionLbl: Label 'Document Date';
        Sales_Header___Order_Date_CaptionLbl: Label 'Order Date';
        Sales_Header___Shipment_Date_CaptionLbl: Label 'Shipment Date';
#if not CLEAN27
        SalesHeader__VAT_Base_Discount___CaptionLbl: Label 'VAT Base Discount %';
#endif
        Sales_Header___Due_Date__Control19CaptionLbl: Label 'Due Date';
        Sales_Header___Pmt__Discount_Date__Control22CaptionLbl: Label 'Pmt. Discount Date';
        Sales_Header___Posting_Date__Control131CaptionLbl: Label 'Posting Date';
        Sales_Header___Document_Date__Control132CaptionLbl: Label 'Document Date';
#if not CLEAN27
        SalesHeader__VAT_Base_Discount____Control1040003CaptionLbl: Label 'VAT Base Discount %';
#endif
        Sales_Header___Posting_Date__Control137CaptionLbl: Label 'Posting Date';
        Sales_Header___Document_Date__Control138CaptionLbl: Label 'Document Date';
#if not CLEAN27
        SalesHeader__VAT_Base_Discount____Control1040005CaptionLbl: Label 'VAT Base Discount %';
#endif
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        Unit_PriceCaptionLbl: Label 'Unit Price';
        Sales_Line___Line_Discount___CaptionLbl: Label 'Line Disc. %';
        AmountCaptionLbl: Label 'Amount';
#if not CLEAN27
        Reverse_ChargeCaptionLbl: Label 'Reverse Charge';
#endif
        TempSalesLine__Inv__Discount_Amount_CaptionLbl: Label 'Inv. Discount Amount';
        SubtotalCaptionLbl: Label 'Subtotal';
        VATDiscountAmountCaptionLbl: Label 'Payment Discount on VAT';
#if not CLEAN27
        Reverse_ChargeCaption_Control1040093Lbl: Label 'Reverse Charge';
#endif
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
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption_Control155Lbl: Label 'Continued';
        TotalCaptionLbl: Label 'Total';
        VALVATAmountLCY_Control88CaptionLbl: Label 'VAT Amount';
        VALVATBaseLCY_Control165CaptionLbl: Label 'VAT Base';
        VATAmountLine__VAT____Control167CaptionLbl: Label 'VAT %';
        VATAmountLine__VAT_Identifier__Control241CaptionLbl: Label 'VAT Identifier';
        ContinuedCaption_Control87Lbl: Label 'Continued';
        ContinuedCaption_Control244Lbl: Label 'Continued';
        TotalCaption_Control247Lbl: Label 'Total';
        Item_Charge_SpecificationCaptionLbl: Label 'Item Charge Specification';
        SalesLine2_DescriptionCaptionLbl: Label 'Description';
        SalesLine2_QuantityCaptionLbl: Label 'Assignable Qty';
        ContinuedCaption_Control210Lbl: Label 'Continued';
        TotalCaption_Control220Lbl: Label 'Total';
        ContinuedCaption_Control223Lbl: Label 'Continued';
#if not CLEAN27
        DiscountText: Text[500];
        DisplayPaymentDiscount: Boolean;
        DiscountLbl: Label 'A discount of %1% of the full price applies if payment is made on or before %2. No credit memo will be issued after you have made the payment. Therefore, you must make sure that you only recover the VAT actually paid.';
#endif

    protected var
        ShowDim: Boolean;

    local procedure AddError(Text: Text)
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := CopyStr(Text, 1, MaxStrLen(ErrorText[ErrorCounter]));
    end;

    local procedure CheckShptLines(SalesLine2: Record "Sales Line")
    var
        TempPostedDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        if Abs(RemQtyToBeInvoiced) > Abs(SalesLine2."Qty. to Ship") then begin
            SaleShptLine.Reset();
            case SalesLine2."Document Type" of
                SalesLine2."Document Type"::Order:
                    begin
                        SaleShptLine.SetCurrentKey("Order No.", "Order Line No.");
                        SaleShptLine.SetRange("Order No.", SalesLine2."Document No.");
                        SaleShptLine.SetRange("Order Line No.", SalesLine2."Line No.");
                    end;
                SalesLine2."Document Type"::Invoice:
                    begin
                        SaleShptLine.SetRange("Document No.", SalesLine2."Shipment No.");
                        SaleShptLine.SetRange("Line No.", SalesLine2."Shipment Line No.");
                    end;
            end;

            SaleShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
            if SaleShptLine.Find('-') then
                repeat
                    DimMgt.GetDimensionSet(TempPostedDimSetEntry, SaleShptLine."Dimension Set ID");
                    if not DimMgt.CheckDimIDConsistency(
                         TempDimSetEntry, TempPostedDimSetEntry, Database::"Sales Line", Database::"Sales Shipment Line")
                    then
                        AddError(DimMgt.GetDocDimConsistencyErr());
                    if SaleShptLine."Sell-to Customer No." <> SalesLine2."Sell-to Customer No." then
                        AddError(
                          StrSubstNo(
                            Text024,
                            SalesLine2.FieldCaption("Sell-to Customer No.")));
                    if SaleShptLine.Type <> SalesLine2.Type then
                        AddError(
                          StrSubstNo(
                            Text024,
                            SalesLine2.FieldCaption(Type)));
                    if SaleShptLine."No." <> SalesLine2."No." then
                        AddError(
                          StrSubstNo(
                            Text024,
                            SalesLine2.FieldCaption("No.")));
                    if SaleShptLine."Gen. Bus. Posting Group" <> SalesLine2."Gen. Bus. Posting Group" then
                        AddError(
                          StrSubstNo(
                            Text024,
                            SalesLine2.FieldCaption("Gen. Bus. Posting Group")));
                    if SaleShptLine."Gen. Prod. Posting Group" <> SalesLine2."Gen. Prod. Posting Group" then
                        AddError(
                          StrSubstNo(
                            Text024,
                            SalesLine2.FieldCaption("Gen. Prod. Posting Group")));
                    if SaleShptLine."Location Code" <> SalesLine2."Location Code" then
                        AddError(
                          StrSubstNo(
                            Text024,
                            SalesLine2.FieldCaption("Location Code")));
                    if SaleShptLine."Job No." <> SalesLine2."Job No." then
                        AddError(
                          StrSubstNo(
                            Text024,
                            SalesLine2.FieldCaption("Job No.")));

                    if -SalesLine."Qty. to Invoice" * SaleShptLine.Quantity < 0 then
                        AddError(
                          StrSubstNo(
                            Text027, SalesLine2.FieldCaption("Qty. to Invoice")));

                    QtyToBeInvoiced := RemQtyToBeInvoiced - SalesLine."Qty. to Ship";
                    if Abs(QtyToBeInvoiced) > Abs(SaleShptLine.Quantity - SaleShptLine."Quantity Invoiced") then
                        QtyToBeInvoiced := -(SaleShptLine.Quantity - SaleShptLine."Quantity Invoiced");
                    RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                    SaleShptLine."Quantity Invoiced" := SaleShptLine."Quantity Invoiced" - QtyToBeInvoiced;
                    SaleShptLine."Qty. Shipped Not Invoiced" :=
                      SaleShptLine.Quantity - SaleShptLine."Quantity Invoiced"
                until (SaleShptLine.Next() = 0) or (Abs(RemQtyToBeInvoiced) <= Abs(SalesLine2."Qty. to Ship"))
            else
                AddError(
                  StrSubstNo(
                    Text026,
                    SalesLine2."Shipment Line No.",
                    SalesLine2."Shipment No."));
        end;

        if Abs(RemQtyToBeInvoiced) > Abs(SalesLine2."Qty. to Ship") then
            if SalesLine2."Document Type" = SalesLine2."Document Type"::Invoice then
                AddError(
                  StrSubstNo(
                    Text036,
                    SalesLine2."Shipment No."));
    end;

    local procedure CheckRcptLines(SalesLine2: Record "Sales Line")
    var
        TempPostedDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        if Abs(RemQtyToBeInvoiced) > Abs(SalesLine2."Return Qty. to Receive") then begin
            ReturnRcptLine.Reset();
            case SalesLine2."Document Type" of
                SalesLine2."Document Type"::"Return Order":
                    begin
                        ReturnRcptLine.SetCurrentKey("Return Order No.", "Return Order Line No.");
                        ReturnRcptLine.SetRange("Return Order No.", SalesLine2."Document No.");
                        ReturnRcptLine.SetRange("Return Order Line No.", SalesLine2."Line No.");
                    end;
                SalesLine2."Document Type"::"Credit Memo":
                    begin
                        ReturnRcptLine.SetRange("Document No.", SalesLine2."Return Receipt No.");
                        ReturnRcptLine.SetRange("Line No.", SalesLine2."Return Receipt Line No.");
                    end;
            end;

            ReturnRcptLine.SetFilter("Return Qty. Rcd. Not Invd.", '<>0');
            if ReturnRcptLine.Find('-') then
                repeat
                    DimMgt.GetDimensionSet(TempPostedDimSetEntry, ReturnRcptLine."Dimension Set ID");
                    if not DimMgt.CheckDimIDConsistency(
                         TempDimSetEntry, TempPostedDimSetEntry, Database::"Sales Line", Database::"Return Receipt Line")
                    then
                        AddError(DimMgt.GetDocDimConsistencyErr());
                    if ReturnRcptLine."Sell-to Customer No." <> SalesLine2."Sell-to Customer No." then
                        AddError(
                          StrSubstNo(
                            Text038,
                            SalesLine2.FieldCaption("Sell-to Customer No.")));
                    if ReturnRcptLine.Type <> SalesLine2.Type then
                        AddError(
                          StrSubstNo(
                            Text038,
                            SalesLine2.FieldCaption(Type)));
                    if ReturnRcptLine."No." <> SalesLine2."No." then
                        AddError(
                          StrSubstNo(
                            Text038,
                            SalesLine2.FieldCaption("No.")));
                    if ReturnRcptLine."Gen. Bus. Posting Group" <> SalesLine2."Gen. Bus. Posting Group" then
                        AddError(
                          StrSubstNo(
                            Text038,
                            SalesLine2.FieldCaption("Gen. Bus. Posting Group")));
                    if ReturnRcptLine."Gen. Prod. Posting Group" <> SalesLine2."Gen. Prod. Posting Group" then
                        AddError(
                          StrSubstNo(
                            Text038,
                            SalesLine2.FieldCaption("Gen. Prod. Posting Group")));
                    if ReturnRcptLine."Location Code" <> SalesLine2."Location Code" then
                        AddError(
                          StrSubstNo(
                            Text038,
                            SalesLine2.FieldCaption("Location Code")));
                    if ReturnRcptLine."Job No." <> SalesLine2."Job No." then
                        AddError(
                          StrSubstNo(
                            Text038,
                            SalesLine2.FieldCaption("Job No.")));

                    if SalesLine."Qty. to Invoice" * ReturnRcptLine.Quantity < 0 then
                        AddError(
                          StrSubstNo(
                            Text039, SalesLine2.FieldCaption("Qty. to Invoice")));
                    QtyToBeInvoiced := RemQtyToBeInvoiced - SalesLine."Return Qty. to Receive";
                    if Abs(QtyToBeInvoiced) > Abs(ReturnRcptLine.Quantity - ReturnRcptLine."Quantity Invoiced") then
                        QtyToBeInvoiced := ReturnRcptLine.Quantity - ReturnRcptLine."Quantity Invoiced";
                    RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                    ReturnRcptLine."Quantity Invoiced" := ReturnRcptLine."Quantity Invoiced" + QtyToBeInvoiced;
                    ReturnRcptLine."Return Qty. Rcd. Not Invd." :=
                      ReturnRcptLine.Quantity - ReturnRcptLine."Quantity Invoiced";
                until (ReturnRcptLine.Next() = 0) or (Abs(RemQtyToBeInvoiced) <= Abs(SalesLine2."Return Qty. to Receive"))
            else
                AddError(
                  StrSubstNo(
                    Text025,
                    SalesLine2."Return Receipt Line No.",
                    SalesLine2."Return Receipt No."));
        end;

        if Abs(RemQtyToBeInvoiced) > Abs(SalesLine2."Return Qty. to Receive") then
            if SalesLine2."Document Type" = SalesLine2."Document Type"::"Credit Memo" then
                AddError(
                  StrSubstNo(
                    Text037,
                    SalesLine2."Return Receipt No."));
    end;

    local procedure IsInvtPosting(): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", "Sales Header"."Document Type");
        SalesLine.SetRange("Document No.", "Sales Header"."No.");
        SalesLine.SetFilter(Type, '%1|%2', SalesLine.Type::Item, SalesLine.Type::"Charge (Item)");
        if SalesLine.IsEmpty() then
            exit(false);
        if "Sales Header".Ship then begin
            SalesLine.SetFilter("Qty. to Ship", '<>%1', 0);
            if not SalesLine.IsEmpty() then
                exit(true);
        end;
        if "Sales Header".Receive then begin
            SalesLine.SetFilter("Return Qty. to Receive", '<>%1', 0);
            if not SalesLine.IsEmpty() then
                exit(true);
        end;
        if "Sales Header".Invoice then begin
            SalesLine.SetFilter("Qty. to Invoice", '<>%1', 0);
            if not SalesLine.IsEmpty() then
                exit(true);
        end;
    end;

    procedure AddDimToTempLine(SalesLine: Record "Sales Line")
    var
        SourceCodeSetup: Record "Source Code Setup";
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        SourceCodeSetup.Get();

        SalesLine.CreateDimFromDefaultDim(0);
        SalesLine."Shortcut Dimension 1 Code" := '';
        SalesLine."Shortcut Dimension 2 Code" := '';
        SalesLine."Dimension Set ID" :=
          DimMgt.GetDefaultDimID(DefaultDimSource, SourceCodeSetup.Sales, SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code",
            SalesLine."Dimension Set ID", Database::Customer);

        OnAfterAddDimToTempLine(SalesLine);
    end;

    procedure InitializeRequest(NewShipReceiveOnNextPostReq: Boolean; NewInvOnNextPostReq: Boolean; NewShowDim: Boolean; NewShowCostAssignment: Boolean)
    begin
        ShipReceiveOnNextPostReq := NewShipReceiveOnNextPostReq;
        InvOnNextPostReq := NewInvOnNextPostReq;
        ShowDim := NewShowDim;
        ShowCostAssignment := NewShowCostAssignment;
    end;

    local procedure CheckSalesLine(SalesLine2: Record "Sales Line")
    var
        ItemVariant: Record "Item Variant";
        ErrorTextLocal: Text[250];
        IsHandled: Boolean;
        ItemItemVariantLbl: Label '%1 %2', Comment = '%1 - Item No., %2 - Variant Code';
    begin
        IsHandled := false;
        OnBeforeCheckSalesLine(SalesLine2, IsHandled, ErrorCounter, ErrorText);
        if IsHandled then
            exit;

        case SalesLine2.Type of
            SalesLine2.Type::"G/L Account":
                begin
                    if (SalesLine2."No." = '') and (SalesLine2.Amount = 0) then
                        exit;

                    if SalesLine2."No." <> '' then
                        if GLAcc.Get(SalesLine2."No.") then begin
                            if GLAcc.Blocked then
                                AddError(
                                  StrSubstNo(
                                    MustBeForErr,
                                    GLAcc.FieldCaption(Blocked), false, GLAcc.TableCaption(), SalesLine2."No."));
                            if (not GLAcc."Direct Posting") and (not SalesLine2."System-Created Entry") and (SalesLine2."Line No." <= OrigMaxLineNo) then
                                AddError(
                                  StrSubstNo(
                                    MustBeForErr,
                                    GLAcc.FieldCaption("Direct Posting"), true, GLAcc.TableCaption(), SalesLine2."No."));
                        end else
                            AddError(
                              StrSubstNo(
                                Text008,
                                GLAcc.TableCaption(), SalesLine2."No."));
                end;
            SalesLine2.Type::Item:
                begin
                    if (SalesLine2."No." = '') and (SalesLine2.Quantity = 0) then
                        exit;

                    if SalesLine2."No." <> '' then
                        if Item.Get(SalesLine2."No.") then begin
                            if Item.Blocked then
                                AddError(StrSubstNo(MustBeForErr, Item.FieldCaption(Blocked), false, Item.TableCaption(), SalesLine2."No."));

                            if SalesLine2."Variant Code" <> '' then begin
                                ItemVariant.SetLoadFields(Blocked);
                                if ItemVariant.Get(SalesLine2."No.", SalesLine2."Variant Code") then begin
                                    if ItemVariant.Blocked then
                                        AddError(StrSubstNo(MustBeForErr, ItemVariant.FieldCaption(Blocked), false, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, SalesLine2."No.", SalesLine2."Variant Code")));
                                end else
                                    AddError(StrSubstNo(Text008, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, SalesLine2."No.", SalesLine2."Variant Code")));
                            end;

                            if Item.Reserve = Item.Reserve::Always then begin
                                SalesLine2.CalcFields("Reserved Quantity");
                                if SalesLine2."Document Type" in [SalesLine2."Document Type"::"Return Order", SalesLine2."Document Type"::"Credit Memo"] then begin
                                    if (SalesLine2.SignedXX(SalesLine2.Quantity) < 0) and (Abs(SalesLine2."Reserved Quantity") < Abs(SalesLine2."Return Qty. to Receive")) then
                                        AddError(
                                          StrSubstNo(
                                            Text015,
                                            SalesLine2.FieldCaption("Reserved Quantity"), SalesLine2.SignedXX(SalesLine2."Return Qty. to Receive")));
                                end else
                                    if (SalesLine2.SignedXX(SalesLine2.Quantity) < 0) and (Abs(SalesLine2."Reserved Quantity") < Abs(SalesLine2."Qty. to Ship")) then
                                        AddError(
                                          StrSubstNo(
                                            Text015,
                                            SalesLine2.FieldCaption("Reserved Quantity"), SalesLine2.SignedXX(SalesLine2."Qty. to Ship")));
                            end
                        end else
                            AddError(
                              StrSubstNo(
                                Text008,
                                Item.TableCaption(), SalesLine2."No."));
                end;
            SalesLine2.Type::Resource:
                begin
                    if (SalesLine2."No." = '') and (SalesLine2.Quantity = 0) then
                        exit;

                    if Res.Get(SalesLine2."No.") then begin
                        if Res."Privacy Blocked" then
                            AddError(
                              StrSubstNo(
                                MustBeForErr,
                                Res.FieldCaption("Privacy Blocked"), false, Res.TableCaption(), SalesLine2."No."));
                        if Res.Blocked then
                            AddError(
                              StrSubstNo(
                                MustBeForErr,
                                Res.FieldCaption(Blocked), false, Res.TableCaption(), SalesLine2."No."));
                    end else
                        AddError(
                          StrSubstNo(
                            Text008,
                            Res.TableCaption(), SalesLine2."No."));
                end;
            SalesLine2.Type::"Fixed Asset":
                begin
                    if (SalesLine2."No." = '') and (SalesLine2.Quantity = 0) then
                        exit;
                    if SalesLine2."No." <> '' then
                        if FA.Get(SalesLine2."No.") then begin
                            if FA.Blocked then
                                AddError(
                                  StrSubstNo(
                                    MustBeForErr,
                                    FA.FieldCaption(Blocked), false, FA.TableCaption(), SalesLine2."No."));
                            if FA.Inactive then
                                AddError(
                                  StrSubstNo(
                                    MustBeForErr,
                                    FA.FieldCaption(Inactive), false, FA.TableCaption(), SalesLine2."No."));
                            if SalesLine2."Depreciation Book Code" = '' then
                                AddError(StrSubstNo(Text006, SalesLine2.FieldCaption("Depreciation Book Code")))
                            else
                                if not FADeprBook.Get(SalesLine2."No.", SalesLine2."Depreciation Book Code") then
                                    AddError(
                                      StrSubstNo(
                                        Text017,
                                        FADeprBook.TableCaption(), SalesLine2."No.", SalesLine2."Depreciation Book Code"));
                        end else
                            AddError(
                              StrSubstNo(
                                Text008,
                                FA.TableCaption(), SalesLine2."No."));
                end;
            else begin
                OnCheckSalesLineCaseTypeElse(SalesLine2.Type.AsInteger(), SalesLine2."No.", ErrorTextLocal);
                if ErrorTextLocal <> '' then
                    AddError(ErrorTextLocal);
            end;
        end;
    end;

    local procedure VerifySellToCust(SalesHeader: Record "Sales Header")
    var
        ShipQtyExist: Boolean;
    begin
        if SalesHeader."Sell-to Customer No." = '' then
            AddError(StrSubstNo(Text006, SalesHeader.FieldCaption("Sell-to Customer No.")))
        else
            if Cust.Get(SalesHeader."Sell-to Customer No.") then begin
                if (Cust.Blocked = Cust.Blocked::Ship) and SalesHeader.Ship then begin
                    SalesLine2.SetRange("Document Type", SalesHeader."Document Type");
                    SalesLine2.SetRange("Document No.", SalesHeader."No.");
                    SalesLine2.SetFilter("Qty. to Ship", '>0');
                    if SalesLine2.FindFirst() then
                        ShipQtyExist := true;
                end;
                if Cust."Privacy Blocked" then
                    AddError(Cust.GetPrivacyBlockedGenericErrorText(Cust));
                if (Cust.Blocked = Cust.Blocked::All) or
                   ((Cust.Blocked = Cust.Blocked::Invoice) and
                    (not (SalesHeader."Document Type" in
                          [SalesHeader."Document Type"::"Credit Memo", SalesHeader."Document Type"::"Return Order"]))) or
                   ShipQtyExist
                then
                    AddError(
                      StrSubstNo(
                        Text045,
                        Cust.FieldCaption(Blocked), Cust.Blocked, Cust.TableCaption(), SalesHeader."Sell-to Customer No."))
            end else
                AddError(
                  StrSubstNo(
                    Text008,
                    Cust.TableCaption(), SalesHeader."Sell-to Customer No."));
    end;

    local procedure VerifyBillToCust(SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."Bill-to Customer No." = '' then
            AddError(StrSubstNo(Text006, SalesHeader.FieldCaption("Bill-to Customer No.")))
        else
            if SalesHeader."Bill-to Customer No." <> SalesHeader."Sell-to Customer No." then
                if Cust.Get(SalesHeader."Bill-to Customer No.") then begin
                    if Cust."Privacy Blocked" then
                        AddError(Cust.GetPrivacyBlockedGenericErrorText(Cust));
                    if (Cust.Blocked = Cust.Blocked::All) or
                       ((Cust.Blocked = Cust.Blocked::Invoice) and
                        (SalesHeader."Document Type" in
                         [SalesHeader."Document Type"::"Credit Memo", SalesHeader."Document Type"::"Return Order"]))
                    then
                        AddError(
                          StrSubstNo(
                            Text045,
                            Cust.FieldCaption(Blocked), false, Cust.TableCaption(), SalesHeader."Bill-to Customer No."));
                end else
                    AddError(
                      StrSubstNo(
                        Text008,
                        Cust.TableCaption(), SalesHeader."Bill-to Customer No."));
    end;

    local procedure VerifyPostingDate(SalesHeader: Record "Sales Header")
    var
        UserSetupManagement: Codeunit "User Setup Management";
        InvtPeriodEndDate: Date;
        TempErrorText: Text[250];
    begin
        if SalesHeader."Posting Date" = 0D then
            AddError(StrSubstNo(Text006, SalesHeader.FieldCaption("Posting Date")))
        else
            if SalesHeader."Posting Date" <> NormalDate(SalesHeader."Posting Date") then
                AddError(StrSubstNo(Text009, SalesHeader.FieldCaption("Posting Date")))
            else begin
                if not UserSetupManagement.TestAllowedPostingDate(SalesHeader."Posting Date", TempErrorText) then
                    AddError(TempErrorText);
                if IsInvtPosting() then begin
                    InvtPeriodEndDate := SalesHeader."Posting Date";
                    if not InvtPeriod.IsValidDate(InvtPeriodEndDate) then
                        AddError(
                          StrSubstNo(Text010, Format(SalesHeader."Posting Date")))
                end;
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSalesDoc(SalesHeader: Record "Sales Header"; var ErrorText: array[99] of Text[250]; var ErrorCounter: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSalesDocLine(SalesLine: Record "Sales Line"; var ErrorText: array[99] of Text[250]; var ErrorCounter: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddDimToTempLine(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesPostGetSalesLines(var SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValuePostingHeader(var SalesHeader: Record "Sales Header"; var TableID: array[10] of Integer; var No: array[10] of Code[20]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValuePostingLine(var SalesLine: Record "Sales Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesLine(SalesLine: Record "Sales Line"; var IsHandled: Boolean; var ErrorCounter: Integer; var ErrorText: array[99] of Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesLineCaseTypeElse(LineType: Option; "No.": Code[20]; var ErrorText: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordSalesLineOnBeforeCheckDim(SalesLine: Record "Sales Line"; var GLAcc: Record "G/L Account"; OrigMaxLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesHeaderOnAfterGetRecordOnBeforeVerifySellToCust(SalesHeader: Record "Sales Header"; var ErrorText: array[99] of Text[250]; var ErrorCounter: Integer)
    begin
    end;
}

