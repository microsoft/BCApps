// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.Security.User;
using System.Utilities;

report 402 "Purchase Document - Test"
{
    DefaultLayout = RDLC;
#if not CLEAN27
    RDLCLayout = './Purchases/Reports/PurchaseDocumentTestGB.rdlc';
#else
    RDLCLayout = './Purchases/Reports/PurchaseDocumentTest.rdlc';
#endif
    Caption = 'Purchase Document - Test';
    WordMergeDataItem = "Purchase Header";

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = where("Document Type" = filter(<> Quote));
            RequestFilterFields = "Document Type", "No.";
            RequestFilterHeading = 'Purchase Document';
            column(Purchase_Header_Document_Type; "Document Type")
            {
            }
            column(Purchase_Header_No_; "No.")
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
                column(STRSUBSTNO_Text018_PurchHeaderFilter_; StrSubstNo(Text018, PurchHeaderFilter))
                {
                }
                column(PurchHeaderFilter; PurchHeaderFilter)
                {
                }
                column(ReceiveInvoiceText; ReceiveInvoiceText)
                {
                }
                column(ShipInvoiceText; ShipInvoiceText)
                {
                }
                column(Purchase_Header___Sell_to_Customer_No__; "Purchase Header"."Sell-to Customer No.")
                {
                }
                column(ShipToAddr_1_; ShipToAddr[1])
                {
                }
                column(ShipToAddr_2_; ShipToAddr[2])
                {
                }
                column(ShipToAddr_3_; ShipToAddr[3])
                {
                }
                column(ShipToAddr_4_; ShipToAddr[4])
                {
                }
                column(ShipToAddr_5_; ShipToAddr[5])
                {
                }
                column(ShipToAddr_6_; ShipToAddr[6])
                {
                }
                column(ShipToAddr_7_; ShipToAddr[7])
                {
                }
                column(ShipToAddr_8_; ShipToAddr[8])
                {
                }
                column(FORMAT__Purchase_Header___Document_Type____________Purchase_Header___No__; Format("Purchase Header"."Document Type") + ' ' + "Purchase Header"."No.")
                {
                }
                column(BuyFromAddr_8_; BuyFromAddr[8])
                {
                }
                column(BuyFromAddr_7_; BuyFromAddr[7])
                {
                }
                column(BuyFromAddr_6_; BuyFromAddr[6])
                {
                }
                column(BuyFromAddr_5_; BuyFromAddr[5])
                {
                }
                column(BuyFromAddr_4_; BuyFromAddr[4])
                {
                }
                column(BuyFromAddr_3_; BuyFromAddr[3])
                {
                }
                column(BuyFromAddr_2_; BuyFromAddr[2])
                {
                }
                column(BuyFromAddr_1_; BuyFromAddr[1])
                {
                }
                column(Purchase_Header___Buy_from_Vendor_No__; "Purchase Header"."Buy-from Vendor No.")
                {
                }
                column(Purchase_Header___Document_Type_; Format("Purchase Header"."Document Type", 0, 2))
                {
                }
                column(Purchase_Header___VAT_Base_Discount___; "Purchase Header"."VAT Base Discount %")
                {
                }
                column(PricesInclVATtxt; PricesInclVATtxt)
                {
                }
                column(ShowItemChargeAssgnt; ShowItemChargeAssgnt)
                {
                }
                column(PayToAddr_1_; PayToAddr[1])
                {
                }
                column(PayToAddr_2_; PayToAddr[2])
                {
                }
                column(PayToAddr_3_; PayToAddr[3])
                {
                }
                column(PayToAddr_4_; PayToAddr[4])
                {
                }
                column(PayToAddr_5_; PayToAddr[5])
                {
                }
                column(PayToAddr_6_; PayToAddr[6])
                {
                }
                column(PayToAddr_7_; PayToAddr[7])
                {
                }
                column(PayToAddr_8_; PayToAddr[8])
                {
                }
                column(Purchase_Header___Pay_to_Vendor_No__; "Purchase Header"."Pay-to Vendor No.")
                {
                }
                column(Purchase_Header___Purchaser_Code_; "Purchase Header"."Purchaser Code")
                {
                }
                column(Purchase_Header___Your_Reference_; "Purchase Header"."Your Reference")
                {
                }
                column(Purchase_Header___Vendor_Posting_Group_; "Purchase Header"."Vendor Posting Group")
                {
                }
                column(Purchase_Header___Posting_Date_; Format("Purchase Header"."Posting Date"))
                {
                }
                column(Purchase_Header___Document_Date_; Format("Purchase Header"."Document Date"))
                {
                }
                column(Purchase_Header___Prices_Including_VAT_; "Purchase Header"."Prices Including VAT")
                {
                }
                column(Purchase_Header___Payment_Terms_Code_; "Purchase Header"."Payment Terms Code")
                {
                }
                column(Purchase_Header___Payment_Discount___; "Purchase Header"."Payment Discount %")
                {
                }
                column(Purchase_Header___Due_Date_; Format("Purchase Header"."Due Date"))
                {
                }
                column(Purchase_Header___Pmt__Discount_Date_; Format("Purchase Header"."Pmt. Discount Date"))
                {
                }
                column(Purchase_Header___Shipment_Method_Code_; "Purchase Header"."Shipment Method Code")
                {
                }
                column(Purchase_Header___Payment_Method_Code_; "Purchase Header"."Payment Method Code")
                {
                }
                column(Purchase_Header___Vendor_Order_No__; "Purchase Header"."Vendor Order No.")
                {
                }
                column(Purchase_Header___Vendor_Shipment_No__; "Purchase Header"."Vendor Shipment No.")
                {
                }
                column(Purchase_Header___Vendor_Invoice_No__; "Purchase Header"."Vendor Invoice No.")
                {
                }
                column(Purchase_Header___Vendor_Posting_Group__Control104; "Purchase Header"."Vendor Posting Group")
                {
                }
                column(Purchase_Header___Posting_Date__Control106; Format("Purchase Header"."Posting Date"))
                {
                }
                column(Purchase_Header___Document_Date__Control107; Format("Purchase Header"."Document Date"))
                {
                }
                column(Purchase_Header___Order_Date_; Format("Purchase Header"."Order Date"))
                {
                }
                column(Purchase_Header___Expected_Receipt_Date_; Format("Purchase Header"."Expected Receipt Date"))
                {
                }
                column(Purchase_Header___Prices_Including_VAT__Control212; "Purchase Header"."Prices Including VAT")
                {
                }
#if not CLEAN27
                column(Purchase_Header___VAT_Base_Discount____Control1040000; "Purchase Header"."VAT Base Discount %")
                {
                }
#endif
                column(Purchase_Header___Payment_Discount____Control14; "Purchase Header"."Payment Discount %")
                {
                }
                column(Purchase_Header___Payment_Terms_Code__Control18; "Purchase Header"."Payment Terms Code")
                {
                }
                column(Purchase_Header___Due_Date__Control19; Format("Purchase Header"."Due Date"))
                {
                }
                column(Purchase_Header___Pmt__Discount_Date__Control22; Format("Purchase Header"."Pmt. Discount Date"))
                {
                }
                column(Purchase_Header___Payment_Method_Code__Control30; "Purchase Header"."Payment Method Code")
                {
                }
                column(Purchase_Header___Shipment_Method_Code__Control33; "Purchase Header"."Shipment Method Code")
                {
                }
                column(Purchase_Header___Vendor_Shipment_No___Control34; "Purchase Header"."Vendor Shipment No.")
                {
                }
                column(Purchase_Header___Vendor_Invoice_No___Control35; "Purchase Header"."Vendor Invoice No.")
                {
                }
                column(Purchase_Header___Vendor_Posting_Group__Control110; "Purchase Header"."Vendor Posting Group")
                {
                }
                column(Purchase_Header___Posting_Date__Control112; Format("Purchase Header"."Posting Date"))
                {
                }
                column(Purchase_Header___Document_Date__Control113; Format("Purchase Header"."Document Date"))
                {
                }
                column(Purchase_Header___Prices_Including_VAT__Control214; "Purchase Header"."Prices Including VAT")
                {
                }
#if not CLEAN27
                column(Purchase_Header___VAT_Base_Discount____Control1040002; "Purchase Header"."VAT Base Discount %")
                {
                }
#endif
                column(Purchase_Header___Vendor_Cr__Memo_No__; "Purchase Header"."Vendor Cr. Memo No.")
                {
                }
                column(Purchase_Header___Applies_to_Doc__Type_; "Purchase Header"."Applies-to Doc. Type")
                {
                }
                column(Purchase_Header___Applies_to_Doc__No__; "Purchase Header"."Applies-to Doc. No.")
                {
                }
                column(Purchase_Header___Vendor_Posting_Group__Control128; "Purchase Header"."Vendor Posting Group")
                {
                }
                column(Purchase_Header___Posting_Date__Control130; Format("Purchase Header"."Posting Date"))
                {
                }
                column(Purchase_Header___Document_Date__Control131; Format("Purchase Header"."Document Date"))
                {
                }
                column(Purchase_Header___Prices_Including_VAT__Control216; "Purchase Header"."Prices Including VAT")
                {
                }
#if not CLEAN27
                column(Purchase_Header___VAT_Base_Discount____Control1040004; "Purchase Header"."VAT Base Discount %")
                {
                }
#endif
                column(PageCounter_Number; Number)
                {
                }
                column(Purchase_Document___TestCaption; Purchase_Document___TestCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Purchase_Header___Sell_to_Customer_No__Caption; "Purchase Header".FieldCaption("Sell-to Customer No."))
                {
                }
                column(Ship_toCaption; Ship_toCaptionLbl)
                {
                }
                column(Buy_fromCaption; Buy_fromCaptionLbl)
                {
                }
                column(Purchase_Header___Buy_from_Vendor_No__Caption; "Purchase Header".FieldCaption("Buy-from Vendor No."))
                {
                }
                column(Pay_toCaption; Pay_toCaptionLbl)
                {
                }
                column(Purchase_Header___Pay_to_Vendor_No__Caption; "Purchase Header".FieldCaption("Pay-to Vendor No."))
                {
                }
                column(Purchase_Header___Purchaser_Code_Caption; "Purchase Header".FieldCaption("Purchaser Code"))
                {
                }
                column(Purchase_Header___Your_Reference_Caption; "Purchase Header".FieldCaption("Your Reference"))
                {
                }
                column(Purchase_Header___Vendor_Posting_Group_Caption; "Purchase Header".FieldCaption("Vendor Posting Group"))
                {
                }
                column(Purchase_Header___Posting_Date_Caption; Purchase_Header___Posting_Date_CaptionLbl)
                {
                }
                column(Purchase_Header___Document_Date_Caption; Purchase_Header___Document_Date_CaptionLbl)
                {
                }
                column(Purchase_Header___Prices_Including_VAT_Caption; "Purchase Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(Purchase_Header___Payment_Terms_Code_Caption; "Purchase Header".FieldCaption("Payment Terms Code"))
                {
                }
                column(Purchase_Header___Payment_Discount___Caption; "Purchase Header".FieldCaption("Payment Discount %"))
                {
                }
                column(Purchase_Header___Due_Date_Caption; Purchase_Header___Due_Date_CaptionLbl)
                {
                }
                column(Purchase_Header___Pmt__Discount_Date_Caption; Purchase_Header___Pmt__Discount_Date_CaptionLbl)
                {
                }
                column(Purchase_Header___Shipment_Method_Code_Caption; "Purchase Header".FieldCaption("Shipment Method Code"))
                {
                }
                column(Purchase_Header___Payment_Method_Code_Caption; "Purchase Header".FieldCaption("Payment Method Code"))
                {
                }
                column(Purchase_Header___Vendor_Order_No__Caption; "Purchase Header".FieldCaption("Vendor Order No."))
                {
                }
                column(Purchase_Header___Vendor_Shipment_No__Caption; "Purchase Header".FieldCaption("Vendor Shipment No."))
                {
                }
                column(Purchase_Header___Vendor_Invoice_No__Caption; "Purchase Header".FieldCaption("Vendor Invoice No."))
                {
                }
                column(Purchase_Header___Vendor_Posting_Group__Control104Caption; "Purchase Header".FieldCaption("Vendor Posting Group"))
                {
                }
                column(Purchase_Header___Posting_Date__Control106Caption; Purchase_Header___Posting_Date__Control106CaptionLbl)
                {
                }
                column(Purchase_Header___Document_Date__Control107Caption; Purchase_Header___Document_Date__Control107CaptionLbl)
                {
                }
                column(Purchase_Header___Order_Date_Caption; Purchase_Header___Order_Date_CaptionLbl)
                {
                }
                column(Purchase_Header___Expected_Receipt_Date_Caption; Purchase_Header___Expected_Receipt_Date_CaptionLbl)
                {
                }
                column(Purchase_Header___Prices_Including_VAT__Control212Caption; "Purchase Header".FieldCaption("Prices Including VAT"))
                {
                }
#if not CLEAN27
                column(Purchase_Header___VAT_Base_Discount____Control1040000Caption; Purchase_Header___VAT_Base_Discount____Control1040000CaptionLbl)
                {
                }
#endif
                column(Purchase_Header___Payment_Discount____Control14Caption; "Purchase Header".FieldCaption("Payment Discount %"))
                {
                }
                column(Purchase_Header___Payment_Terms_Code__Control18Caption; "Purchase Header".FieldCaption("Payment Terms Code"))
                {
                }
                column(Purchase_Header___Due_Date__Control19Caption; Purchase_Header___Due_Date__Control19CaptionLbl)
                {
                }
                column(Purchase_Header___Pmt__Discount_Date__Control22Caption; Purchase_Header___Pmt__Discount_Date__Control22CaptionLbl)
                {
                }
                column(Purchase_Header___Payment_Method_Code__Control30Caption; "Purchase Header".FieldCaption("Payment Method Code"))
                {
                }
                column(Purchase_Header___Shipment_Method_Code__Control33Caption; "Purchase Header".FieldCaption("Shipment Method Code"))
                {
                }
                column(Purchase_Header___Vendor_Shipment_No___Control34Caption; "Purchase Header".FieldCaption("Vendor Shipment No."))
                {
                }
                column(Purchase_Header___Vendor_Invoice_No___Control35Caption; "Purchase Header".FieldCaption("Vendor Invoice No."))
                {
                }
                column(Purchase_Header___Vendor_Posting_Group__Control110Caption; "Purchase Header".FieldCaption("Vendor Posting Group"))
                {
                }
                column(Purchase_Header___Posting_Date__Control112Caption; Purchase_Header___Posting_Date__Control112CaptionLbl)
                {
                }
                column(Purchase_Header___Document_Date__Control113Caption; Purchase_Header___Document_Date__Control113CaptionLbl)
                {
                }
                column(Purchase_Header___Prices_Including_VAT__Control214Caption; "Purchase Header".FieldCaption("Prices Including VAT"))
                {
                }
#if not CLEAN27
                column(Purchase_Header___VAT_Base_Discount____Control1040002Caption; Purchase_Header___VAT_Base_Discount____Control1040002CaptionLbl)
                {
                }
#endif
                column(Purchase_Header___Vendor_Cr__Memo_No__Caption; "Purchase Header".FieldCaption("Vendor Cr. Memo No."))
                {
                }
                column(Purchase_Header___Applies_to_Doc__Type_Caption; "Purchase Header".FieldCaption("Applies-to Doc. Type"))
                {
                }
                column(Purchase_Header___Applies_to_Doc__No__Caption; "Purchase Header".FieldCaption("Applies-to Doc. No."))
                {
                }
                column(Purchase_Header___Vendor_Posting_Group__Control128Caption; "Purchase Header".FieldCaption("Vendor Posting Group"))
                {
                }
                column(Purchase_Header___Posting_Date__Control130Caption; Purchase_Header___Posting_Date__Control130CaptionLbl)
                {
                }
                column(Purchase_Header___Document_Date__Control131Caption; Purchase_Header___Document_Date__Control131CaptionLbl)
                {
                }
                column(Purchase_Header___Prices_Including_VAT__Control216Caption; "Purchase Header".FieldCaption("Prices Including VAT"))
                {
                }
#if not CLEAN27
                column(Purchase_Header___VAT_Base_Discount____Control1040004Caption; Purchase_Header___VAT_Base_Discount____Control1040004CaptionLbl)
                {
                }
#endif
                column(RemitToAddressCaption; Remit_toCaptionLbl)
                {
                }
                column(RemitToAddress_Name; RemitAddressBuffer.Name)
                {
                }
                column(RemitToAddress_Name2; RemitAddressBuffer.Address)
                {
                }
                column(RemitToAddress_Contact; RemitAddressBuffer."Address 2")
                {
                }
                column(RemitToAddress_Address; RemitAddressBuffer.City)
                {
                }
                column(RemitToAddress_Address2; RemitAddressBuffer.County)
                {
                }
                column(RemitToAddress_City; RemitAddressBuffer."Post Code")
                {
                }
                column(RemitToAddress_PostCode; RemitAddressBuffer."Country/Region Code")
                {
                }
                column(RemitToAddress_County; RemitAddressBuffer.Contact)
                {
                }
                dataitem(DimensionLoop1; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(DimensionLoop1_Number; Number)
                    {
                    }
                    column(DimText_Control163; DimText)
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
                    dataitem("Purchase Line"; "Purchase Line")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemLinkReference = "Purchase Header";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
                        column(Purchase_Line_Document_Type; "Document Type")
                        {
                        }
                        column(Purchase_Line_Document_No_; "Document No.")
                        {
                        }
                        column(Purchase_Line_Line_No_; "Line No.")
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
                        column(Purchase_Line__Type; Format("Purchase Line".Type))
                        {
                        }
                        column(Purchase_Line___Line_Amount_; "Purchase Line"."Line Amount")
                        {
                            AutoFormatExpression = "Purchase Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(Purchase_Line___VAT_Identifier_; "Purchase Line"."VAT Identifier")
                        {
                        }
                        column(Purchase_Line___Allow_Invoice_Disc__; "Purchase Line"."Allow Invoice Disc.")
                        {
                        }
                        column(Purchase_Line___Line_Discount___; "Purchase Line"."Line Discount %")
                        {
                        }
                        column(Purchase_Line___Direct_Unit_Cost_; "Purchase Line"."Direct Unit Cost")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 2;
                        }
                        column(Purchase_Line___Qty__to_Invoice_; "Purchase Line"."Qty. to Invoice")
                        {
                        }
                        column(QtyToHandle; QtyToHandle)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(Purchase_Line__Quantity; "Purchase Line".Quantity)
                        {
                        }
                        column(Purchase_Line__Description; "Purchase Line".Description)
                        {
                        }
                        column(Purchase_Line___No__; "Purchase Line"."No.")
                        {
                        }
                        column(Purchase_Line___Line_No__; "Purchase Line"."Line No.")
                        {
                        }
                        column(Purchase_Line___Inv__Discount_Amount_; "Purchase Line"."Inv. Discount Amount")
                        {
                        }
                        column(AllowInvDisctxt; AllowInvDisctxt)
                        {
                        }
                        column(TempPurchLine__Inv__Discount_Amount_; -TempPurchaseLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TempPurchLine__Line_Amount_; TempPurchaseLine."Line Amount")
                        {
                            AutoFormatExpression = "Purchase Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(TempPurchLine__Line_Amount____TempPurchLine__Inv__Discount_Amount_; TempPurchaseLine."Line Amount" - TempPurchaseLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(VATAmountLine_VATAmountText; TempVATAmountLine.VATAmountText())
                        {
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(TempPurchLine__Line_Amount____TempPurchLine__Inv__Discount_Amount____VATAmount; TempPurchaseLine."Line Amount" - TempPurchaseLine."Inv. Discount Amount" + VATAmount)
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmount; VATAmount)
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TempPurchLine__Line_Amount____TempPurchLine__Inv__Discount_Amount__Control224; TempPurchaseLine."Line Amount" - TempPurchaseLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SumInvDiscountAmount; SumInvDiscountAmount)
                        {
                        }
                        column(SumLineAmount; SumLineAmount)
                        {
                        }
                        column(VATDiscountAmount; -VATDiscountAmount)
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalInclVATText_Control155; TotalInclVATText)
                        {
                        }
                        column(VATAmountLine_VATAmountText_Control151; TempVATAmountLine.VATAmountText())
                        {
                        }
                        column(TotalExclVATText_Control153; TotalExclVATText)
                        {
                        }
                        column(VATBaseAmount; VATBaseAmount)
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATBaseAmount___VATAmount; VATBaseAmount + VATAmount)
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmount_Control150; VATAmount)
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
#if not CLEAN27
                        column(TotalReverseCharge; TotalReverseCharge)
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
#endif
                        column(RoundLoop_Number; Number)
                        {
                        }
                        column(AmountCaption; AmountCaptionLbl)
                        {
                        }
                        column(Purchase_Line___VAT_Identifier_Caption; "Purchase Line".FieldCaption("VAT Identifier"))
                        {
                        }
                        column(Purchase_Line___Allow_Invoice_Disc__Caption; "Purchase Line".FieldCaption("Allow Invoice Disc."))
                        {
                        }
                        column(Purchase_Line___Line_Discount___Caption; Purchase_Line___Line_Discount___CaptionLbl)
                        {
                        }
                        column(Direct_Unit_CostCaption; Direct_Unit_CostCaptionLbl)
                        {
                        }
                        column(Purchase_Line___Qty__to_Invoice_Caption; "Purchase Line".FieldCaption("Qty. to Invoice"))
                        {
                        }
                        column(Purchase_Line__QuantityCaption; "Purchase Line".FieldCaption(Quantity))
                        {
                        }
                        column(Purchase_Line__DescriptionCaption; "Purchase Line".FieldCaption(Description))
                        {
                        }
                        column(Purchase_Line___No__Caption; "Purchase Line".FieldCaption("No."))
                        {
                        }
                        column(Purchase_Line__TypeCaption; "Purchase Line".FieldCaption(Type))
                        {
                        }
                        column(TempPurchLine__Inv__Discount_Amount_Caption; TempPurchLine__Inv__Discount_Amount_CaptionLbl)
                        {
                        }
                        column(SubtotalCaption; SubtotalCaptionLbl)
                        {
                        }
                        column(VATDiscountAmountCaption; VATDiscountAmountCaptionLbl)
                        {
                        }
#if not CLEAN27
                        column(Reverse_ChargeCaption_Control1040006; Reverse_ChargeCaption_Control1040006Lbl)
                        {
                        }
#endif
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(DimText_Control165; DimText)
                            {
                            }
                            column(DimensionLoop2_Number; Number)
                            {
                            }
                            column(DimText_Control167; DimText)
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
                                SumLineAmount := SumLineAmount + TempPurchaseLine."Line Amount";
                                SumInvDiscountAmount := SumInvDiscountAmount + TempPurchaseLine."Inv. Discount Amount";
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
                            column(ErrorText_Number__Control103; ErrorText[Number])
                            {
                            }
                            column(LineErrorCounter_Number; Number)
                            {
                            }
                            column(ErrorText_Number__Control103Caption; ErrorText_Number__Control103CaptionLbl)
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
                        begin
                            if Number = 1 then
                                TempPurchaseLine.Find('-')
                            else
                                TempPurchaseLine.Next();
                            "Purchase Line" := TempPurchaseLine;

                            OnRoundLoopOnBeforeAfterGetRecord("Purchase Line", ErrorCounter, ErrorText);

                            if not "Purchase Header"."Prices Including VAT" and
                               ("Purchase Line"."VAT Calculation Type" = "Purchase Line"."VAT Calculation Type"::"Full VAT")
                            then
                                TempPurchaseLine."Line Amount" := 0;
                            DimSetEntry2.SetRange("Dimension Set ID", "Purchase Line"."Dimension Set ID");
                            DimMgt.GetDimensionSet(TempDimSetEntry, "Purchase Line"."Dimension Set ID");

                            if "Purchase Line"."Document Type" in ["Purchase Line"."Document Type"::"Return Order", "Purchase Line"."Document Type"::"Credit Memo"]
                            then begin
                                if "Purchase Line"."Document Type" = "Purchase Line"."Document Type"::"Credit Memo" then begin
                                    if ("Purchase Line"."Return Qty. to Ship" <> "Purchase Line".Quantity) and ("Purchase Line"."Return Shipment No." = '') then
                                        AddError(StrSubstNo(Text019, "Purchase Line".FieldCaption("Return Qty. to Ship"), "Purchase Line".Quantity));
                                    if "Purchase Line"."Qty. to Invoice" <> "Purchase Line".Quantity then
                                        AddError(StrSubstNo(Text019, "Purchase Line".FieldCaption("Qty. to Invoice"), "Purchase Line".Quantity));
                                end;
                                if "Purchase Line"."Qty. to Receive" <> 0 then
                                    AddError(StrSubstNo(Text040, "Purchase Line".FieldCaption("Qty. to Receive")));
                            end else begin
                                if "Purchase Line"."Document Type" = "Purchase Line"."Document Type"::Invoice then begin
                                    if ("Purchase Line"."Qty. to Receive" <> "Purchase Line".Quantity) and ("Purchase Line"."Receipt No." = '') then
                                        AddError(StrSubstNo(Text019, "Purchase Line".FieldCaption("Qty. to Receive"), "Purchase Line".Quantity));
                                    if "Purchase Line"."Qty. to Invoice" <> "Purchase Line".Quantity then
                                        AddError(StrSubstNo(Text019, "Purchase Line".FieldCaption("Qty. to Invoice"), "Purchase Line".Quantity));
                                end;
                                if "Purchase Line"."Return Qty. to Ship" <> 0 then
                                    AddError(StrSubstNo(Text040, "Purchase Line".FieldCaption("Return Qty. to Ship")));
                            end;

                            if not "Purchase Header".Receive then
                                "Purchase Line"."Qty. to Receive" := 0;
                            if not "Purchase Header".Ship then
                                "Purchase Line"."Return Qty. to Ship" := 0;

                            if ("Purchase Line"."Document Type" = "Purchase Line"."Document Type"::Invoice) and ("Purchase Line"."Receipt No." <> '') then begin
                                "Purchase Line"."Quantity Received" := "Purchase Line".Quantity;
                                "Purchase Line"."Qty. to Receive" := 0;
                            end;

                            if ("Purchase Line"."Document Type" = "Purchase Line"."Document Type"::"Credit Memo") and ("Purchase Line"."Return Shipment No." <> '') then begin
                                "Purchase Line"."Return Qty. Shipped" := "Purchase Line".Quantity;
                                "Purchase Line"."Return Qty. to Ship" := 0;
                            end;

                            if "Purchase Header".Invoice then begin
                                if "Purchase Line"."Document Type" = "Purchase Line"."Document Type"::"Credit Memo" then
                                    MaxQtyToBeInvoiced := "Purchase Line"."Return Qty. to Ship" + "Purchase Line"."Return Qty. Shipped" - "Purchase Line"."Quantity Invoiced"
                                else
                                    MaxQtyToBeInvoiced := "Purchase Line"."Qty. to Receive" + "Purchase Line"."Quantity Received" - "Purchase Line"."Quantity Invoiced";
                                if Abs("Purchase Line"."Qty. to Invoice") > Abs(MaxQtyToBeInvoiced) then
                                    "Purchase Line"."Qty. to Invoice" := MaxQtyToBeInvoiced;
                            end else
                                "Purchase Line"."Qty. to Invoice" := 0;

                            if "Purchase Header".Receive then begin
                                QtyToHandle := "Purchase Line"."Qty. to Receive";
                                QtyToHandleCaption := "Purchase Line".FieldCaption("Qty. to Receive");
                            end;

                            if "Purchase Header".Ship then begin
                                QtyToHandle := "Purchase Line"."Return Qty. to Ship";
                                QtyToHandleCaption := "Purchase Line".FieldCaption("Return Qty. to Ship");
                            end;

                            if "Purchase Line"."Gen. Prod. Posting Group" <> '' then begin
                                Clear(GenPostingSetup);
                                GenPostingSetup.Reset();
                                GenPostingSetup.SetRange("Gen. Bus. Posting Group", "Purchase Line"."Gen. Bus. Posting Group");
                                GenPostingSetup.SetRange("Gen. Prod. Posting Group", "Purchase Line"."Gen. Prod. Posting Group");
                                if not GenPostingSetup.FindLast() then
                                    AddError(
                                      StrSubstNo(
                                        Text020,
                                        GenPostingSetup.TableCaption(), "Purchase Line"."Gen. Bus. Posting Group", "Purchase Line"."Gen. Prod. Posting Group"));
                            end;

                            if "Purchase Line".Quantity <> 0 then begin
                                if "Purchase Line"."No." = '' then
                                    AddError(StrSubstNo(Text006, "Purchase Line".FieldCaption("No.")));
                                if "Purchase Line".Type = "Purchase Line".Type::" " then
                                    AddError(StrSubstNo(Text006, "Purchase Line".FieldCaption(Type)));
                            end else
                                if "Purchase Line".Amount <> 0 then
                                    AddError(StrSubstNo(Text021, "Purchase Line".FieldCaption(Amount), "Purchase Line".FieldCaption(Quantity)));

                            PurchLine := "Purchase Line";
                            TestJobFields(PurchLine);
                            if "Purchase Line"."Document Type" in ["Purchase Line"."Document Type"::"Return Order", "Purchase Line"."Document Type"::"Credit Memo"]
                            then begin
                                PurchLine."Return Qty. to Ship" := -PurchLine."Return Qty. to Ship";
                                PurchLine."Qty. to Invoice" := -PurchLine."Qty. to Invoice";
                            end;

                            RemQtyToBeInvoiced := PurchLine."Qty. to Invoice";

                            case "Purchase Line"."Document Type" of
                                "Purchase Line"."Document Type"::"Return Order", "Purchase Line"."Document Type"::"Credit Memo":
                                    CheckShptLines("Purchase Line");
                                "Purchase Line"."Document Type"::Order, "Purchase Line"."Document Type"::Invoice:
                                    CheckRcptLines("Purchase Line");
                            end;

                            if ("Purchase Line".Type <> "Purchase Line".Type::" ") and ("Purchase Line"."Qty. to Invoice" <> 0) then
                                if not ApplicationAreaMgmt.IsSalesTaxEnabled() then
                                    if not GenPostingSetup.Get("Purchase Line"."Gen. Bus. Posting Group", "Purchase Line"."Gen. Prod. Posting Group") then
                                        AddError(
                                          StrSubstNo(
                                            Text020,
                                            GenPostingSetup.TableCaption(), "Purchase Line"."Gen. Bus. Posting Group", "Purchase Line"."Gen. Prod. Posting Group"));

                            if "Purchase Line"."Prepayment %" > 0 then
                                if not "Purchase Line"."Prepayment Line" and ("Purchase Line".Quantity > 0) then begin
                                    Fraction := ("Purchase Line"."Qty. to Invoice" + "Purchase Line"."Quantity Invoiced") / "Purchase Line".Quantity;
                                    if Fraction > 1 then
                                        Fraction := 1;

                                    case true of
                                        (Fraction * "Purchase Line"."Line Amount" < "Purchase Line"."Prepmt Amt to Deduct") and
                                      ("Purchase Line"."Prepmt Amt to Deduct" <> 0):
                                            AddError(
                                              StrSubstNo(
                                                Text053,
                                                "Purchase Line".FieldCaption("Prepmt Amt to Deduct"),
                                                Round(Fraction * "Purchase Line"."Line Amount", GLSetup."Amount Rounding Precision")));
                                        (1 - Fraction) * "Purchase Line"."Line Amount" <
                                      "Purchase Line"."Prepmt. Amt. Inv." - "Purchase Line"."Prepmt Amt Deducted" - "Purchase Line"."Prepmt Amt to Deduct":
                                            AddError(
                                              StrSubstNo(
                                                Text054,
                                                "Purchase Line".FieldCaption("Prepmt Amt to Deduct"),
                                                Round(
                                                  "Purchase Line"."Prepmt. Amt. Inv." - "Purchase Line"."Prepmt Amt Deducted" - (1 - Fraction) * "Purchase Line"."Line Amount",
                                                  GLSetup."Amount Rounding Precision")));
                                    end;
                                end;
                            if not "Purchase Line"."Prepayment Line" and ("Purchase Line"."Prepmt. Line Amount" > 0) then
                                if "Purchase Line"."Prepmt. Line Amount" > "Purchase Line"."Prepmt. Amt. Inv." then
                                    AddError(StrSubstNo(Text042, "Purchase Line".FieldCaption("Prepmt. Line Amount")));

                            CheckPurchLine("Purchase Line");

                            if "Purchase Line"."Line No." > OrigMaxLineNo then begin
                                AddDimToTempLine("Purchase Line");
                                if not DimMgt.CheckDimIDComb("Purchase Line"."Dimension Set ID") then
                                    AddError(DimMgt.GetDimCombErr());
                                if not DimMgt.CheckDimValuePosting(TableID, No, "Purchase Line"."Dimension Set ID") then
                                    AddError(DimMgt.GetDimValuePostingErr());
                            end else begin
                                if not DimMgt.CheckDimIDComb("Purchase Line"."Dimension Set ID") then
                                    AddError(DimMgt.GetDimCombErr());

                                TableID[1] := DimMgt.PurchLineTypeToTableID("Purchase Line".Type);
                                No[1] := "Purchase Line"."No.";
                                TableID[2] := Database::Job;
                                No[2] := "Purchase Line"."Job No.";
                                OnBeforeCheckDimValuePostingLine("Purchase Line", TableID, No);
                                if not DimMgt.CheckDimValuePosting(TableID, No, "Purchase Line"."Dimension Set ID") then
                                    AddError(DimMgt.GetDimValuePostingErr());
                            end;

                            AllowInvDisctxt := Format("Purchase Line"."Allow Invoice Disc.");
                            OnRoundLoopOnAfterGetRecord("Purchase Line", ErrorText, ErrorCounter);
                        end;

                        trigger OnPreDataItem()
                        var
                            MoreLines: Boolean;
                        begin
                            MoreLines := TempPurchaseLine.Find('+');
                            while MoreLines and (TempPurchaseLine.Description = '') and (TempPurchaseLine."Description 2" = '') and
                                  (TempPurchaseLine."No." = '') and (TempPurchaseLine.Quantity = 0) and
                                  (TempPurchaseLine.Amount = 0)
                            do
                                MoreLines := TempPurchaseLine.Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            TempPurchaseLine.SetRange("Line No.", 0, TempPurchaseLine."Line No.");
                            SetRange(Number, 1, TempPurchaseLine.Count);

                            SumLineAmount := 0;
                            SumInvDiscountAmount := 0;
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(VATAmountLine__VAT_Amount_; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base_; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount_; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount_; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount_; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control98; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base__Control138; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT___; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmountLine__VAT_Identifier_; TempVATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATAmountLine__Line_Amount__Control175; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control176; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control177; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control95; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base__Control139; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control181; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control182; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount__Control183; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control85; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base__Control137; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control187; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control188; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount__Control189; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Purchase Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATCounter_Number; Number)
                        {
                        }
                        column(VAT_Amount_SpecificationCaption; VAT_Amount_SpecificationCaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Amount__Control98Caption; VATAmountLine__VAT_Amount__Control98CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Base__Control138Caption; VATAmountLine__VAT_Base__Control138CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT___Caption; VATAmountLine__VAT___CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Identifier_Caption; VATAmountLine__VAT_Identifier_CaptionLbl)
                        {
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control176Caption; VATAmountLine__Inv__Disc__Base_Amount__Control176CaptionLbl)
                        {
                        }
                        column(VATAmountLine__Line_Amount__Control175Caption; VATAmountLine__Line_Amount__Control175CaptionLbl)
                        {
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control177Caption; VATAmountLine__Invoice_Discount_Amount__Control177CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Base_Caption; VATAmountLine__VAT_Base_CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Base__Control139Caption; VATAmountLine__VAT_Base__Control139CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Base__Control137Caption; VATAmountLine__VAT_Base__Control137CaptionLbl)
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
                        column(VALVATAmountLCY_Control242; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATBaseLCY_Control243; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT____Control244; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmountLine__VAT_Identifier__Control245; TempVATAmountLine."VAT Identifier")
                        {
                        }
                        column(VALVATAmountLCY_Control246; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATBaseLCY_Control247; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATAmountLCY_Control249; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATBaseLCY_Control250; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VATCounterLCY_Number; Number)
                        {
                        }
                        column(VALVATAmountLCY_Control242Caption; VALVATAmountLCY_Control242CaptionLbl)
                        {
                        }
                        column(VALVATBaseLCY_Control243Caption; VALVATBaseLCY_Control243CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT____Control244Caption; VATAmountLine__VAT____Control244CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Identifier__Control245Caption; VATAmountLine__VAT_Identifier__Control245CaptionLbl)
                        {
                        }
                        column(ContinuedCaption; ContinuedCaptionLbl)
                        {
                        }
                        column(ContinuedCaption_Control248; ContinuedCaption_Control248Lbl)
                        {
                        }
                        column(TotalCaption; TotalCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempVATAmountLine.GetLine(Number);
                            VALVATBaseLCY :=
                              TempVATAmountLine.GetBaseLCY(
                                "Purchase Header"."Posting Date", "Purchase Header"."Currency Code", "Purchase Header"."Currency Factor");
                            VALVATAmountLCY :=
                              TempVATAmountLine.GetAmountLCY(
                                "Purchase Header"."Posting Date", "Purchase Header"."Currency Code", "Purchase Header"."Currency Factor");
                        end;

                        trigger OnPreDataItem()
                        var
                            CurrExchRate: Record "Currency Exchange Rate";
                        begin
                            if (not GLSetup."Print VAT specification in LCY") or
                               ("Purchase Header"."Currency Code" = '')
                            then
                                CurrReport.Break();

                            SetRange(Number, 1, TempVATAmountLine.Count);
                            Clear(VALVATBaseLCY);
                            Clear(VALVATAmountLCY);

                            if GLSetup."LCY Code" = '' then
                                VALSpecLCYHeader := Text050 + Text051
                            else
                                VALSpecLCYHeader := Text050 + Format(GLSetup."LCY Code");

                            CurrExchRate.FindCurrency("Purchase Header"."Posting Date", "Purchase Header"."Currency Code", 1);
                            CurrExchRate."Relational Exch. Rate Amount" := CurrExchRate."Exchange Rate Amount" / "Purchase Header"."Currency Factor";
                            VALExchRate := StrSubstNo(Text052, CurrExchRate."Relational Exch. Rate Amount", CurrExchRate."Exchange Rate Amount");
                        end;
                    }
                    dataitem("Item Charge Assignment (Purch)"; "Item Charge Assignment (Purch)")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemLinkReference = "Purchase Header";
                        DataItemTableView = sorting("Document Type", "Document No.", "Document Line No.", "Line No.");
                        column(Item_Charge_Assignment__Purch___Qty__to_Assign_; "Qty. to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Purch___Amount_to_Assign_; "Amount to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Purch___Item_Charge_No__; "Item Charge No.")
                        {
                        }
                        column(PurchLine2_Description; PurchLine2.Description)
                        {
                        }
                        column(PurchLine2_Quantity; PurchLine2.Quantity)
                        {
                        }
                        column(Item_Charge_Assignment__Purch___Item_No__; "Item No.")
                        {
                        }
                        column(Item_Charge_Assignment__Purch___Qty__to_Assign__Control204; "Qty. to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Purch___Unit_Cost_; "Unit Cost")
                        {
                        }
                        column(Item_Charge_Assignment__Purch___Amount_to_Assign__Control210; "Amount to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Purch___Qty__to_Assign__Control195; "Qty. to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Purch___Amount_to_Assign__Control196; "Amount to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Purch___Qty__to_Assign__Control191; "Qty. to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Purch___Amount_to_Assign__Control193; "Amount to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Purch__Document_Type; "Document Type")
                        {
                        }
                        column(Item_Charge_Assignment__Purch__Document_No_; "Document No.")
                        {
                        }
                        column(Item_Charge_Assignment__Purch__Document_Line_No_; "Document Line No.")
                        {
                        }
                        column(Item_Charge_Assignment__Purch__Line_No_; "Line No.")
                        {
                        }
                        column(Item_Charge_SpecificationCaption; Item_Charge_SpecificationCaptionLbl)
                        {
                        }
                        column(Item_Charge_Assignment__Purch___Item_Charge_No__Caption; FieldCaption("Item Charge No."))
                        {
                        }
                        column(Item_Charge_Assignment__Purch___Item_No__Caption; FieldCaption("Item No."))
                        {
                        }
                        column(Item_Charge_Assignment__Purch___Qty__to_Assign__Control204Caption; FieldCaption("Qty. to Assign"))
                        {
                        }
                        column(Item_Charge_Assignment__Purch___Unit_Cost_Caption; FieldCaption("Unit Cost"))
                        {
                        }
                        column(Item_Charge_Assignment__Purch___Amount_to_Assign__Control210Caption; FieldCaption("Amount to Assign"))
                        {
                        }
                        column(DescriptionCaption; DescriptionCaptionLbl)
                        {
                        }
                        column(PurchLine2_QuantityCaption; PurchLine2_QuantityCaptionLbl)
                        {
                        }
                        column(ContinuedCaption_Control197; ContinuedCaption_Control197Lbl)
                        {
                        }
                        column(TotalCaption_Control194; TotalCaption_Control194Lbl)
                        {
                        }
                        column(ContinuedCaption_Control192; ContinuedCaption_Control192Lbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if PurchLine2.Get("Document Type", "Document No.", "Document Line No.") then;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowItemChargeAssgnt then
                                CurrReport.Break();
                        end;
                    }

                    trigger OnAfterGetRecord()
                    var
                        PurchPost: Codeunit "Purch.-Post";
                    begin
                        Clear(TempPurchaseLine);
                        Clear(PurchPost);
                        TempPurchaseLine.DeleteAll();
                        TempVATAmountLine.DeleteAll();
                        PurchPost.GetPurchLines("Purchase Header", TempPurchaseLine, 1);
                        TempPurchaseLine.CalcVATAmountLines(0, "Purchase Header", TempPurchaseLine, TempVATAmountLine);
                        TempPurchaseLine.UpdateVATOnLines(0, "Purchase Header", TempPurchaseLine, TempVATAmountLine);
                        VATAmount := TempVATAmountLine.GetTotalVATAmount();
                        VATBaseAmount := TempVATAmountLine.GetTotalVATBase();
                        VATDiscountAmount :=
                          TempVATAmountLine.GetTotalVATDiscount("Purchase Header"."Currency Code", "Purchase Header"."Prices Including VAT");
                    end;
                }
            }

            trigger OnAfterGetRecord()
            var
                VendorMgt: Codeunit "Vendor Mgt.";
                TableID: array[10] of Integer;
                No: array[10] of Code[20];
            begin
                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                FormatAddr.PurchHeaderPayTo(PayToAddr, "Purchase Header");
                FormatAddr.PurchHeaderBuyFrom(BuyFromAddr, "Purchase Header");
                FormatAddr.PurchHeaderShipTo(ShipToAddr, "Purchase Header");
                FormatAddr.PurchHeaderRemitTo(RemitAddressBuffer, "Purchase Header");
                if "Currency Code" = '' then begin
                    GLSetup.TestField("LCY Code");
                    TotalText := StrSubstNo(Text004, GLSetup."LCY Code");
                    TotalInclVATText := StrSubstNo(Text005, GLSetup."LCY Code");
                    TotalExclVATText := StrSubstNo(Text031, GLSetup."LCY Code");
                end else begin
                    TotalText := StrSubstNo(Text004, "Currency Code");
                    TotalInclVATText := StrSubstNo(Text005, "Currency Code");
                    TotalExclVATText := StrSubstNo(Text031, "Currency Code");
                end;

                Invoice := InvOnNextPostReq;
                Receive := ReceiveShipOnNextPostReq;
                Ship := ReceiveShipOnNextPostReq;

                VerifyBuyFromVend("Purchase Header");
                VerifyPayToVend("Purchase Header");

                PurchSetup.Get();

                VerifyPostingDate("Purchase Header");

                if PurchSetup."Posting Date Check on Posting" then
                    if "Posting Date" <> WorkDate() then
                        AddError(
                          StrSubstNo(
                            DifferentPostingDateToWorkDateTxt, FieldCaption("Posting Date"), "Posting Date", WorkDate()));

                if "Document Date" <> 0D then
                    if "Document Date" <> NormalDate("Document Date") then
                        AddError(StrSubstNo(Text009, FieldCaption("Document Date")));

                case "Document Type" of
                    "Document Type"::Order:
                        Ship := false;
                    "Document Type"::Invoice:
                        begin
                            Receive := true;
                            Invoice := true;
                            Ship := false;
                        end;
                    "Document Type"::"Return Order":
                        Receive := false;
                    "Document Type"::"Credit Memo":
                        begin
                            Receive := false;
                            Invoice := true;
                            Ship := true;
                        end;
                end;

                if not (Receive or Invoice or Ship) then
                    AddError(
                      StrSubstNo(
                        Text032,
                        FieldCaption(Receive), FieldCaption(Invoice), FieldCaption(Ship)));

                if Invoice then begin
                    PurchLine.Reset();
                    PurchLine.SetRange("Document Type", "Document Type");
                    PurchLine.SetRange("Document No.", "No.");
                    PurchLine.SetFilter(Quantity, '<>0');
                    if "Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"] then
                        PurchLine.SetFilter("Qty. to Invoice", '<>0');
                    Invoice := PurchLine.Find('-');
                    if Invoice and (not Receive) and ("Document Type" = "Document Type"::Order) then begin
                        Invoice := false;
                        repeat
                            Invoice := PurchLine."Quantity Received" - PurchLine."Quantity Invoiced" <> 0;
                        until Invoice or (PurchLine.Next() = 0);
                    end else
                        if Invoice and (not Ship) and ("Document Type" = "Document Type"::"Return Order") then begin
                            Invoice := false;
                            repeat
                                Invoice := PurchLine."Return Qty. Shipped" - PurchLine."Quantity Invoiced" <> 0;
                            until Invoice or (PurchLine.Next() = 0);
                        end;
                end;

                if Receive then begin
                    PurchLine.Reset();
                    PurchLine.SetRange("Document Type", "Document Type");
                    PurchLine.SetRange("Document No.", "No.");
                    PurchLine.SetFilter(Quantity, '<>0');
                    if "Document Type" = "Document Type"::Order then
                        PurchLine.SetFilter("Qty. to Receive", '<>0');
                    PurchLine.SetRange("Receipt No.", '');
                    Receive := PurchLine.Find('-');
                end;
                if Ship then begin
                    PurchLine.Reset();
                    PurchLine.SetRange("Document Type", "Document Type");
                    PurchLine.SetRange("Document No.", "No.");
                    PurchLine.SetFilter(Quantity, '<>0');
                    if "Document Type" = "Document Type"::"Return Order" then
                        PurchLine.SetFilter("Return Qty. to Ship", '<>0');
                    PurchLine.SetRange("Return Shipment No.", '');
                    Ship := PurchLine.Find('-');
                end;

                if not (Receive or Invoice or Ship) then
                    AddError(DocumentErrorsMgt.GetNothingToPostErrorMsg());

                if Invoice then begin
                    PurchLine.Reset();
                    PurchLine.SetRange("Document Type", "Document Type");
                    PurchLine.SetRange("Document No.", "No.");
                    PurchLine.SetFilter("Sales Order Line No.", '<>0');
                    if PurchLine.Find('-') then
                        repeat
                            SalesLine.Get(SalesLine."Document Type"::Order, PurchLine."Sales Order No.", PurchLine."Sales Order Line No.");
                            if Receive and
                               Invoice and
                               (PurchLine."Qty. to Invoice" <> 0) and
                               (PurchLine."Qty. to Receive" <> 0)
                            then
                                AddError(Text013);
                            if Abs(PurchLine."Quantity Received" - PurchLine."Quantity Invoiced") <
                               Abs(PurchLine."Qty. to Invoice")
                            then
                                PurchLine."Qty. to Invoice" := PurchLine."Quantity Received" - PurchLine."Quantity Invoiced";
                            if Abs(PurchLine.Quantity - (PurchLine."Qty. to Invoice" + PurchLine."Quantity Invoiced")) <
                               Abs(SalesLine.Quantity - SalesLine."Quantity Invoiced")
                            then
                                AddError(
                                  StrSubstNo(
                                    Text014,
                                    PurchLine."Sales Order No."));
                        until PurchLine.Next() = 0;
                end;

                if Invoice then
                    if not ("Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]) then
                        if "Due Date" = 0D then
                            AddError(StrSubstNo(Text006, FieldCaption("Due Date")));

                if Receive and ("Receiving No." = '') then
                    if ("Document Type" = "Document Type"::Order) or
                       (("Document Type" = "Document Type"::Invoice) and PurchSetup."Receipt on Invoice")
                    then
                        if "Receiving No. Series" = '' then
                            AddError(
                              StrSubstNo(
                                Text015,
                                FieldCaption("Receiving No. Series")));

                if Ship and ("Return Shipment No." = '') then
                    if ("Document Type" = "Document Type"::"Return Order") or
                       (("Document Type" = "Document Type"::"Credit Memo") and PurchSetup."Return Shipment on Credit Memo")
                    then
                        if "Return Shipment No. Series" = '' then
                            AddError(
                              StrSubstNo(
                                Text015,
                                FieldCaption("Return Shipment No. Series")));

                if Invoice and ("Posting No." = '') then
                    if "Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"] then
                        if "Posting No. Series" = '' then
                            AddError(
                              StrSubstNo(
                                Text015,
                                FieldCaption("Posting No. Series")));

                PurchLine.Reset();
                PurchLine.SetRange("Document Type", "Document Type");
                PurchLine.SetRange("Document No.", "No.");
                PurchLine.SetFilter("Sales Order Line No.", '<>0');
                if Receive then
                    if PurchLine.FindSet() then
                        repeat
                            if SalesHeader."No." <> PurchLine."Sales Order No." then begin
                                SalesHeader.Get(1, PurchLine."Sales Order No.");
                                if SalesHeader."Bill-to Customer No." = '' then
                                    AddError(
                                      StrSubstNo(
                                        Text016,
                                        SalesHeader.FieldCaption("Bill-to Customer No.")));
                                if SalesHeader."Shipping No." = '' then
                                    if SalesHeader."Shipping No. Series" = '' then
                                        AddError(
                                          StrSubstNo(
                                            Text016,
                                            SalesHeader.FieldCaption("Shipping No. Series")));
                            end;
                        until PurchLine.Next() = 0;

                if Invoice then
                    if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then begin
                        if PurchSetup."Ext. Doc. No. Mandatory" and ("Vendor Invoice No." = '') then
                            AddError(StrSubstNo(Text006, FieldCaption("Vendor Invoice No.")));
                    end else
                        if PurchSetup."Ext. Doc. No. Mandatory" and ("Vendor Cr. Memo No." = '') then
                            AddError(StrSubstNo(Text006, FieldCaption("Vendor Cr. Memo No.")));

                if "Vendor Invoice No." <> '' then begin
                    VendLedgEntry.SetCurrentKey("External Document No.");
                    VendorMgt.SetFilterForExternalDocNo(
                      VendLedgEntry, "Document Type", "Vendor Invoice No.", "Pay-to Vendor No.", "Document Date");
                    if VendLedgEntry.FindFirst() then
                        AddError(
                          StrSubstNo(
                            Text017,
                            "Document Type", "Vendor Invoice No."));
                end;

                if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                    AddError(DimMgt.GetDimCombErr());

                TableID[1] := Database::Vendor;
                No[1] := "Pay-to Vendor No.";
                TableID[3] := Database::"Salesperson/Purchaser";
                No[3] := "Purchaser Code";
                TableID[4] := Database::Campaign;
                No[4] := "Campaign No.";
                TableID[5] := Database::"Responsibility Center";
                No[5] := "Responsibility Center";
                OnBeforeCheckDimValuePostingHeader("Purchase Header", TableID, No);
                if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                    AddError(DimMgt.GetDimValuePostingErr());

                PricesInclVATtxt := Format("Prices Including VAT");

                OnAfterCheckPurchaseDoc("Purchase Header", ErrorText, ErrorCounter);

#if not CLEAN27
                ReverseCharge := 0;
                TotalReverseCharge := 0;
#endif
            end;

            trigger OnPreDataItem()
            begin
                PurchHeader.Copy("Purchase Header");
                PurchHeader.FilterGroup := 2;
                PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
                if PurchHeader.FindFirst() then begin
                    case true of
                        ReceiveShipOnNextPostReq and InvOnNextPostReq:
                            ReceiveInvoiceText := Text000;
                        ReceiveShipOnNextPostReq:
                            ReceiveInvoiceText := Text001;
                        InvOnNextPostReq:
                            ReceiveInvoiceText := Text002;
                    end;
                    ReceiveInvoiceText := StrSubstNo(Text003, ReceiveInvoiceText);
                end;
                PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::"Return Order");
                if PurchHeader.FindFirst() then begin
                    case true of
                        ReceiveShipOnNextPostReq and InvOnNextPostReq:
                            ShipInvoiceText := Text028;
                        ReceiveShipOnNextPostReq:
                            ShipInvoiceText := Text029;
                        InvOnNextPostReq:
                            ShipInvoiceText := Text002;
                    end;
                    ShipInvoiceText := StrSubstNo(Text030, ShipInvoiceText);
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
                    group("Order/Credit Memo Posting")
                    {
                        Caption = 'Order/Credit Memo Posting';
                        field(ReceiveShip; ReceiveShipOnNextPostReq)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Receive/Ship';
                            ToolTip = 'Specifies whether you want to post the documents that are being tested as received/shipped, as invoiced or as received/shipped and invoiced. Select the check box next to each option that you want to select.';

                            trigger OnValidate()
                            begin
                                if not ReceiveShipOnNextPostReq then
                                    InvOnNextPostReq := true;
                            end;
                        }
                        field(Invoice; InvOnNextPostReq)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Invoice';
                            ToolTip = 'Specifies invoices to test before you post them, to check whether there are any posting dates missing, etc.';

                            trigger OnValidate()
                            begin
                                if not InvOnNextPostReq then
                                    ReceiveShipOnNextPostReq := true;
                            end;
                        }
                    }
                    field(ShowDim; ShowDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies if you want dimensions information for the journal lines to be included in the report.';
                    }
                    field(ShowItemChargeAssignment; ShowItemChargeAssgnt)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Item Charge Assgnt.';
                        ToolTip = 'Specifies if you want the test report to show the item charge that has been assigned to the purchase document.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if not ReceiveShipOnNextPostReq and not InvOnNextPostReq then begin
                ReceiveShipOnNextPostReq := true;
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
        PurchHeaderFilter := "Purchase Header".GetFilters();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Receive and Invoice';
        Text001: Label 'Receive';
        Text002: Label 'Invoice';
#pragma warning disable AA0470
        Text003: Label 'Order Posting: %1';
        Text004: Label 'Total %1';
        Text005: Label 'Total %1 Incl. VAT';
        Text006: Label '%1 must be specified.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        MustBeForErr: Label '%1 must be %2 for %3 %4.', Comment = '%1 = field caption, %2 = value, %3 = table caption, %4 = No.)';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text008: Label '%1 %2 does not exist.';
        Text009: Label '%1 must not be a closing date.';
        Text010: Label '%1 is not within your allowed range of posting dates.';
#pragma warning restore AA0470
        Text013: Label 'A drop shipment from a purchase order cannot be received and invoiced at the same time.';
#pragma warning disable AA0470
        Text014: Label 'Invoice sales order %1 before invoicing this purchase order.';
        Text015: Label '%1 must be entered.';
        Text016: Label '%1 must be entered on the sales order header.';
        Text017: Label 'Purchase %1 %2 already exists for this vendor.';
        Text018: Label 'Purchase Document: %1';
        Text019: Label '%1 must be %2.';
        Text020: Label '%1 %2 %3 does not exist.';
        Text021: Label '%1 must be 0 when %2 is 0.';
        Text022: Label 'The %1 on the receipt is not the same as the %1 on the purchase header.';
        Text023: Label '%1 must have the same sign as the receipt.';
        Text025: Label '%1 must have the same sign as the return shipment.';
#pragma warning restore AA0470
        Text028: Label 'Ship and Invoice';
        Text029: Label 'Ship';
#pragma warning disable AA0470
        Text030: Label 'Return Order Posting: %1';
        Text031: Label 'Total %1 Excl. VAT';
        Text032: Label 'Enter "Yes" in %1 and/or %2 and/or %3.';
        Text033: Label 'Line %1 of the receipt %2, which you are attempting to invoice, has already been invoiced.';
        Text034: Label 'Line %1 of the return shipment %2, which you are attempting to invoice, has already been invoiced.';
        Text036: Label 'The %1 on the return shipment is not the same as the %1 on the purchase header.';
        Text037: Label 'The quantity you are attempting to invoice is greater than the quantity in receipt %1.';
        Text038: Label 'The quantity you are attempting to invoice is greater than the quantity in return shipment %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PurchSetup: Record "Purchases & Payables Setup";
        GLSetup: Record "General Ledger Setup";
        Vend: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        GLAcc: Record "G/L Account";
        Item: Record Item;
        FA: Record "Fixed Asset";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnShptLine: Record "Return Shipment Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        InvtPeriod: Record "Inventory Period";
        RemitAddressBuffer: Record "Remit Address Buffer";
        FormatAddr: Codeunit "Format Address";
        DimMgt: Codeunit DimensionManagement;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        PayToAddr: array[8] of Text[100];
        BuyFromAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        PurchHeaderFilter: Text;
        ErrorText: array[99] of Text[250];
        DimText: Text[120];
        OldDimText: Text[75];
        ReceiveInvoiceText: Text[50];
        ShipInvoiceText: Text[50];
        TotalText: Text[50];
        TotalInclVATText: Text[50];
        TotalExclVATText: Text[50];
        QtyToHandleCaption: Text[80];
        MaxQtyToBeInvoiced: Decimal;
        RemQtyToBeInvoiced: Decimal;
        QtyToBeInvoiced: Decimal;
        QtyToHandle: Decimal;
        VATAmount: Decimal;
        VATBaseAmount: Decimal;
        VATDiscountAmount: Decimal;
        ErrorCounter: Integer;
        OrigMaxLineNo: Integer;
        InvOnNextPostReq: Boolean;
        ReceiveShipOnNextPostReq: Boolean;
        Continue: Boolean;
        ShowItemChargeAssgnt: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text040: Label '%1 must be zero.';
        Text041: Label '%1 must not be %2 for %3 %4.';
        Text042: Label '%1 must be completely preinvoiced before you can ship or invoice the line.';
#pragma warning restore AA0470
        Text050: Label 'VAT Amount Specification in ';
        Text051: Label 'Local Currency';
#pragma warning disable AA0470
        Text052: Label 'Exchange rate: %1/%2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
        VALSpecLCYHeader: Text[80];
        VALExchRate: Text[50];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text053: Label '%1 can at most be %2.';
        Text054: Label '%1 must be at least %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PricesInclVATtxt: Text[30];
        AllowInvDisctxt: Text[30];
        SumLineAmount: Decimal;
        SumInvDiscountAmount: Decimal;
        DifferentPostingDateToWorkDateTxt: Label '%1 %2 is different to Work Date %3.', Comment = '%1 = Posting Date Field Caption %2=Posting Date Field Value %3=WorkDate value';
#if not CLEAN27
        Text10500: Label 'Reverse charge item - please check correct VAT rate is entered. Reverse Charge %1';
        TempPurchLine2: Record "Purchase Line";
        ReverseCharge: Decimal;
        TotalReverseCharge: Decimal;
#endif
        Purchase_Document___TestCaptionLbl: Label 'Purchase Document - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Ship_toCaptionLbl: Label 'Ship-to';
        Buy_fromCaptionLbl: Label 'Buy-from';
        Pay_toCaptionLbl: Label 'Pay-to';
        Remit_toCaptionLbl: Label 'Remit-to';
        Purchase_Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        Purchase_Header___Document_Date_CaptionLbl: Label 'Document Date';
        Purchase_Header___Due_Date_CaptionLbl: Label 'Due Date';
        Purchase_Header___Pmt__Discount_Date_CaptionLbl: Label 'Pmt. Discount Date';
        Purchase_Header___Posting_Date__Control106CaptionLbl: Label 'Posting Date';
        Purchase_Header___Document_Date__Control107CaptionLbl: Label 'Document Date';
        Purchase_Header___Order_Date_CaptionLbl: Label 'Order Date';
        Purchase_Header___Expected_Receipt_Date_CaptionLbl: Label 'Expected Receipt Date';
#if not CLEAN27
        Purchase_Header___VAT_Base_Discount____Control1040000CaptionLbl: Label 'VAT Base Discount %';
#endif
        Purchase_Header___Due_Date__Control19CaptionLbl: Label 'Due Date';
        Purchase_Header___Pmt__Discount_Date__Control22CaptionLbl: Label 'Pmt. Discount Date';
        Purchase_Header___Posting_Date__Control112CaptionLbl: Label 'Posting Date';
        Purchase_Header___Document_Date__Control113CaptionLbl: Label 'Document Date';
#if not CLEAN27
        Purchase_Header___VAT_Base_Discount____Control1040002CaptionLbl: Label 'VAT Base Discount %';
#endif
        Purchase_Header___Posting_Date__Control130CaptionLbl: Label 'Posting Date';
        Purchase_Header___Document_Date__Control131CaptionLbl: Label 'Document Date';
#if not CLEAN27
        Purchase_Header___VAT_Base_Discount____Control1040004CaptionLbl: Label 'VAT Base Discount %';
#endif
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        AmountCaptionLbl: Label 'Amount';
        Purchase_Line___Line_Discount___CaptionLbl: Label 'Line Disc. %';
        Direct_Unit_CostCaptionLbl: Label 'Direct Unit Cost';
        TempPurchLine__Inv__Discount_Amount_CaptionLbl: Label 'Inv. Discount Amount';
        SubtotalCaptionLbl: Label 'Subtotal';
        VATDiscountAmountCaptionLbl: Label 'Payment Discount on VAT';
#if not CLEAN27
        Reverse_ChargeCaption_Control1040006Lbl: Label 'Reverse Charge';
#endif
        Line_DimensionsCaptionLbl: Label 'Line Dimensions';
        ErrorText_Number__Control103CaptionLbl: Label 'Warning!';
        VAT_Amount_SpecificationCaptionLbl: Label 'VAT Amount Specification';
        VATAmountLine__VAT_Amount__Control98CaptionLbl: Label 'VAT Amount';
        VATAmountLine__VAT_Base__Control138CaptionLbl: Label 'VAT Base';
        VATAmountLine__VAT___CaptionLbl: Label 'VAT %';
        VATAmountLine__VAT_Identifier_CaptionLbl: Label 'VAT Identifier';
        VATAmountLine__Inv__Disc__Base_Amount__Control176CaptionLbl: Label 'Invoice Discount Base Amount';
        VATAmountLine__Line_Amount__Control175CaptionLbl: Label 'Line Amount';
        VATAmountLine__Invoice_Discount_Amount__Control177CaptionLbl: Label 'Invoice Discount Amount';
        VATAmountLine__VAT_Base_CaptionLbl: Label 'Continued';
        VATAmountLine__VAT_Base__Control139CaptionLbl: Label 'Continued';
        VATAmountLine__VAT_Base__Control137CaptionLbl: Label 'Total';
        VALVATAmountLCY_Control242CaptionLbl: Label 'VAT Amount';
        VALVATBaseLCY_Control243CaptionLbl: Label 'VAT Base';
        VATAmountLine__VAT____Control244CaptionLbl: Label 'VAT %';
        VATAmountLine__VAT_Identifier__Control245CaptionLbl: Label 'VAT Identifier';
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption_Control248Lbl: Label 'Continued';
        TotalCaptionLbl: Label 'Total';
        Item_Charge_SpecificationCaptionLbl: Label 'Item Charge Specification';
        DescriptionCaptionLbl: Label 'Description';
        PurchLine2_QuantityCaptionLbl: Label 'Assignable Qty';
        ContinuedCaption_Control197Lbl: Label 'Continued';
        TotalCaption_Control194Lbl: Label 'Total';
        ContinuedCaption_Control192Lbl: Label 'Continued';

    protected var
        ShowDim: Boolean;

    local procedure AddError(Text: Text)
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := CopyStr(Text, 1, MaxStrLen(ErrorText[ErrorCounter]));
    end;

    local procedure CheckPurchLine(PurchaseLine: Record "Purchase Line")
    var
        ItemVariant: Record "Item Variant";
        Resource: Record Resource;
        ErrorText: Text[250];
        ItemItemVariantLbl: Label '%1 %2', Comment = '%1 - Item No., %2 - Variant Code';
    begin
        case PurchaseLine.Type of
            PurchaseLine.Type::"G/L Account":
                begin
                    if (PurchaseLine."No." = '') and (PurchaseLine.Amount = 0) then
                        exit;

                    if PurchaseLine."No." <> '' then
                        if GLAcc.Get(PurchaseLine."No.") then begin
                            if GLAcc.Blocked then
                                AddError(
                                  StrSubstNo(
                                    MustBeForErr,
                                    GLAcc.FieldCaption(Blocked), false, GLAcc.TableCaption(), PurchaseLine."No."));
                            if (not GLAcc."Direct Posting") and (not PurchaseLine."System-Created Entry") and (PurchaseLine."Line No." <= OrigMaxLineNo) then
                                AddError(
                                  StrSubstNo(
                                    MustBeForErr,
                                    GLAcc.FieldCaption("Direct Posting"), true, GLAcc.TableCaption(), PurchaseLine."No."));
                        end else
                            AddError(
                              StrSubstNo(
                                Text008,
                                GLAcc.TableCaption(), PurchaseLine."No."));
                end;
            PurchaseLine.Type::Item:
                begin
                    if (PurchaseLine."No." = '') and (PurchaseLine.Quantity = 0) then
                        exit;

                    if PurchaseLine."No." <> '' then
                        if Item.Get(PurchaseLine."No.") then begin
                            if Item.Blocked then
                                AddError(StrSubstNo(MustBeForErr, Item.FieldCaption(Blocked), false, Item.TableCaption(), PurchaseLine."No."));

                            if PurchaseLine."Variant Code" <> '' then begin
                                ItemVariant.SetLoadFields(Blocked);
                                if ItemVariant.Get(PurchaseLine."No.", PurchaseLine."Variant Code") then begin
                                    if ItemVariant.Blocked then
                                        AddError(StrSubstNo(MustBeForErr, ItemVariant.FieldCaption(Blocked), false, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, PurchaseLine."No.", PurchaseLine."Variant Code")));
                                end else
                                    AddError(StrSubstNo(Text008, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, PurchaseLine."No.", PurchaseLine."Variant Code")));
                            end;

                            if Item."Costing Method" = Item."Costing Method"::Specific then
                                if Item.Reserve = Item.Reserve::Always then begin
                                    PurchaseLine.CalcFields("Reserved Quantity");
                                    if (PurchaseLine.Signed(PurchaseLine.Quantity) < 0) and (Abs(PurchaseLine."Reserved Quantity") < Abs(PurchaseLine."Qty. to Receive")) then
                                        AddError(StrSubstNo(Text019, PurchaseLine.FieldCaption("Reserved Quantity"), PurchaseLine.Signed(PurchaseLine."Qty. to Receive")));
                                end;

#if not CLEAN27
                            ReverseCharge := 0;
                            if "Purchase Line"."Reverse Charge Item" and
                               ("Purchase Header"."VAT Bus. Posting Group" = PurchSetup."Domestic Vendors") and
                               ("Purchase Header"."VAT Registration No." <> '')
                            then
                                if PurchSetup."Reverse Charge VAT Posting Gr." = "Purchase Line"."VAT Bus. Posting Group" then begin
                                    TempPurchLine2 := "Purchase Line";
                                    TempPurchLine2.SuspendStatusCheck(true);
                                    TempPurchLine2.Validate("VAT Bus. Posting Group", PurchSetup."Domestic Vendors");
                                    TempPurchLine2.Validate(Amount);
                                    ReverseCharge :=
                                      Round(
                                        (TempPurchLine2."Amount Including VAT" - TempPurchLine2.Amount) *
                                        TempPurchLine2."Qty. to Invoice" / TempPurchLine2.Quantity);
                                    AddError(StrSubstNo(Text10500, ReverseCharge));
                                    TotalReverseCharge := TotalReverseCharge + ReverseCharge;
                                end else
                                    AddError(StrSubstNo(Text10500, Round(0)));
#endif
                        end else
                            AddError(StrSubstNo(Text008, Item.TableCaption(), PurchaseLine."No."));
                end;
            PurchaseLine.Type::"Fixed Asset":
                begin
                    if (PurchaseLine."No." = '') and (PurchaseLine.Quantity = 0) then
                        exit;

                    if PurchaseLine."No." <> '' then
                        if FA.Get(PurchaseLine."No.") then begin
                            if FA.Blocked then
                                AddError(
                                  StrSubstNo(
                                    MustBeForErr,
                                    FA.FieldCaption(Blocked), false, FA.TableCaption(), PurchaseLine."No."));
                            if FA.Inactive then
                                AddError(
                                  StrSubstNo(
                                    MustBeForErr,
                                    FA.FieldCaption(Inactive), false, FA.TableCaption(), PurchaseLine."No."));
                        end else
                            AddError(
                              StrSubstNo(
                                Text008,
                                FA.TableCaption(), PurchaseLine."No."));
                end;
            PurchaseLine.Type::Resource:
                begin
                    if (PurchaseLine."No." = '') and (PurchaseLine.Quantity = 0) then
                        exit;

                    if Resource.Get(PurchaseLine."No.") then begin
                        if Resource."Privacy Blocked" then
                            AddError(StrSubstNo(MustBeForErr, Resource.FieldCaption("Privacy Blocked"), false, Resource.TableCaption(), PurchaseLine."No."));
                        if Resource.Blocked then
                            AddError(StrSubstNo(MustBeForErr, Resource.FieldCaption(Blocked), false, Resource.TableCaption(), PurchaseLine."No."));
                    end else
                        AddError(StrSubstNo(Text008, Resource.TableCaption(), PurchaseLine."No."));
                end
            else begin
                OnCheckPurchLineCaseTypeElse(PurchaseLine.Type.AsInteger(), PurchaseLine."No.", ErrorText);
                if ErrorText <> '' then
                    AddError(ErrorText);
            end;
        end;
        OnAfterCheckPurchLine(PurchaseLine, "Purchase Header", ErrorCounter, ErrorText);
    end;

    local procedure CheckRcptLines(PurchLine2: Record "Purchase Line")
    var
        TempPostedDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        if Abs(RemQtyToBeInvoiced) > Abs(PurchLine2."Qty. to Receive") then begin
            PurchRcptLine.Reset();
            case PurchLine2."Document Type" of
                PurchLine2."Document Type"::Order:
                    begin
                        PurchRcptLine.SetCurrentKey("Order No.", "Order Line No.");
                        PurchRcptLine.SetRange("Order No.", PurchLine2."Document No.");
                        PurchRcptLine.SetRange("Order Line No.", PurchLine2."Line No.");
                    end;
                PurchLine2."Document Type"::Invoice:
                    begin
                        PurchRcptLine.SetRange("Document No.", PurchLine2."Receipt No.");
                        PurchRcptLine.SetRange("Line No.", PurchLine2."Receipt Line No.");
                    end;
            end;

            PurchRcptLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
            if PurchRcptLine.Find('-') then
                repeat
                    DimMgt.GetDimensionSet(TempPostedDimSetEntry, PurchRcptLine."Dimension Set ID");
                    if not DimMgt.CheckDimIDConsistency(
                         TempDimSetEntry, TempPostedDimSetEntry, Database::"Purchase Line", Database::"Purch. Rcpt. Line")
                    then
                        AddError(DimMgt.GetDocDimConsistencyErr());
                    if PurchRcptLine."Buy-from Vendor No." <> PurchLine2."Buy-from Vendor No." then
                        AddError(
                          StrSubstNo(
                            Text022,
                            PurchLine2.FieldCaption("Buy-from Vendor No.")));
                    if PurchRcptLine.Type <> PurchLine2.Type then
                        AddError(
                          StrSubstNo(
                            Text022,
                            PurchLine2.FieldCaption(Type)));
                    if PurchRcptLine."No." <> PurchLine2."No." then
                        AddError(
                          StrSubstNo(
                            Text022,
                            PurchLine2.FieldCaption("No.")));
                    if PurchRcptLine."Gen. Bus. Posting Group" <> PurchLine2."Gen. Bus. Posting Group" then
                        AddError(
                          StrSubstNo(
                            Text022,
                            PurchLine2.FieldCaption("Gen. Bus. Posting Group")));
                    if PurchRcptLine."Gen. Prod. Posting Group" <> PurchLine2."Gen. Prod. Posting Group" then
                        AddError(
                          StrSubstNo(
                            Text022,
                            PurchLine2.FieldCaption("Gen. Prod. Posting Group")));
                    if PurchRcptLine."Location Code" <> PurchLine2."Location Code" then
                        AddError(
                          StrSubstNo(
                            Text022,
                            PurchLine2.FieldCaption("Location Code")));
                    if PurchRcptLine."Job No." <> PurchLine2."Job No." then
                        AddError(
                          StrSubstNo(
                            Text022,
                            PurchLine2.FieldCaption("Job No.")));

                    if PurchLine."Qty. to Invoice" * PurchRcptLine.Quantity < 0 then
                        AddError(StrSubstNo(Text023, PurchLine2.FieldCaption("Qty. to Invoice")));

                    QtyToBeInvoiced := RemQtyToBeInvoiced - PurchLine."Qty. to Receive";
                    if Abs(QtyToBeInvoiced) > Abs(PurchRcptLine.Quantity - PurchRcptLine."Quantity Invoiced") then
                        QtyToBeInvoiced := PurchRcptLine.Quantity - PurchRcptLine."Quantity Invoiced";
                    RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                    PurchRcptLine."Quantity Invoiced" := PurchRcptLine."Quantity Invoiced" + QtyToBeInvoiced;
                until (PurchRcptLine.Next() = 0) or (Abs(RemQtyToBeInvoiced) <= Abs(PurchLine2."Qty. to Receive"))
            else
                AddError(
                  StrSubstNo(
                    Text033,
                    PurchLine2."Receipt Line No.",
                    PurchLine2."Receipt No."));
        end;

        if Abs(RemQtyToBeInvoiced) > Abs(PurchLine2."Qty. to Receive") then
            if PurchLine2."Document Type" = PurchLine2."Document Type"::Invoice then
                AddError(
                  StrSubstNo(
                    Text037,
                    PurchLine2."Receipt No."))
    end;

    local procedure CheckShptLines(PurchLine2: Record "Purchase Line")
    var
        TempPostedDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        if Abs(RemQtyToBeInvoiced) > Abs(PurchLine2."Return Qty. to Ship") then begin
            ReturnShptLine.Reset();
            case PurchLine2."Document Type" of
                PurchLine2."Document Type"::"Return Order":
                    begin
                        ReturnShptLine.SetCurrentKey("Return Order No.", "Return Order Line No.");
                        ReturnShptLine.SetRange("Return Order No.", PurchLine2."Document No.");
                        ReturnShptLine.SetRange("Return Order Line No.", PurchLine2."Line No.");
                    end;
                PurchLine2."Document Type"::"Credit Memo":
                    begin
                        ReturnShptLine.SetRange("Document No.", PurchLine2."Return Shipment No.");
                        ReturnShptLine.SetRange("Line No.", PurchLine2."Return Shipment Line No.");
                    end;
            end;

            ReturnShptLine.SetFilter("Return Qty. Shipped Not Invd.", '<>0');
            if ReturnShptLine.Find('-') then
                repeat
                    DimMgt.GetDimensionSet(TempPostedDimSetEntry, ReturnShptLine."Dimension Set ID");
                    if not DimMgt.CheckDimIDConsistency(
                         TempDimSetEntry, TempPostedDimSetEntry, Database::"Purchase Line", Database::"Return Shipment Line")
                    then
                        AddError(DimMgt.GetDocDimConsistencyErr());

                    if ReturnShptLine."Buy-from Vendor No." <> PurchLine2."Buy-from Vendor No." then
                        AddError(
                          StrSubstNo(
                            Text036,
                            PurchLine2.FieldCaption("Buy-from Vendor No.")));
                    if ReturnShptLine.Type <> PurchLine2.Type then
                        AddError(
                          StrSubstNo(
                            Text036,
                            PurchLine2.FieldCaption(Type)));
                    if ReturnShptLine."No." <> PurchLine2."No." then
                        AddError(
                          StrSubstNo(
                            Text036,
                            PurchLine2.FieldCaption("No.")));
                    if ReturnShptLine."Gen. Bus. Posting Group" <> PurchLine2."Gen. Bus. Posting Group" then
                        AddError(
                          StrSubstNo(
                            Text036,
                            PurchLine2.FieldCaption("Gen. Bus. Posting Group")));
                    if ReturnShptLine."Gen. Prod. Posting Group" <> PurchLine2."Gen. Prod. Posting Group" then
                        AddError(
                          StrSubstNo(
                            Text036,
                            PurchLine2.FieldCaption("Gen. Prod. Posting Group")));
                    if ReturnShptLine."Location Code" <> PurchLine2."Location Code" then
                        AddError(
                          StrSubstNo(
                            Text036,
                            PurchLine2.FieldCaption("Location Code")));
                    if ReturnShptLine."Job No." <> PurchLine2."Job No." then
                        AddError(
                          StrSubstNo(
                            Text036,
                            PurchLine2.FieldCaption("Job No.")));

                    if -PurchLine."Qty. to Invoice" * ReturnShptLine.Quantity < 0 then
                        AddError(StrSubstNo(Text025, PurchLine2.FieldCaption("Qty. to Invoice")));
                    QtyToBeInvoiced := RemQtyToBeInvoiced - PurchLine."Return Qty. to Ship";
                    if Abs(QtyToBeInvoiced) > Abs(ReturnShptLine.Quantity - ReturnShptLine."Quantity Invoiced") then
                        QtyToBeInvoiced := ReturnShptLine.Quantity - ReturnShptLine."Quantity Invoiced";
                    RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                    ReturnShptLine."Quantity Invoiced" := ReturnShptLine."Quantity Invoiced" + QtyToBeInvoiced;
                until (ReturnShptLine.Next() = 0) or (Abs(RemQtyToBeInvoiced) <= Abs(PurchLine2."Return Qty. to Ship"))
            else
                AddError(
                  StrSubstNo(
                    Text034,
                    PurchLine2."Return Shipment Line No.",
                    PurchLine2."Return Shipment No."));
        end;

        if Abs(RemQtyToBeInvoiced) > Abs(PurchLine2."Return Qty. to Ship") then
            if PurchLine2."Document Type" = PurchLine2."Document Type"::"Credit Memo" then
                AddError(
                  StrSubstNo(
                    Text038,
                    PurchLine2."Return Shipment No."));
    end;

    procedure TestJobFields(var PurchLine: Record "Purchase Line")
    var
        Job: Record Job;
        JT: Record "Job Task";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestJobFields(PurchLine, ErrorCounter, ErrorText, IsHandled);
        if IsHandled then
            exit;

        if PurchLine."Job No." = '' then
            exit;
        if (PurchLine.Type <> PurchLine.Type::"G/L Account") and (PurchLine.Type <> PurchLine.Type::Item) then
            exit;
        if (PurchLine."Document Type" <> PurchLine."Document Type"::Invoice) and
           (PurchLine."Document Type" <> PurchLine."Document Type"::"Credit Memo")
        then
            exit;
        if not Job.Get(PurchLine."Job No.") then
            AddError(StrSubstNo(Text053, Job.TableCaption(), PurchLine."Job No."))
        else
            if Job.Blocked <> Job.Blocked::" " then
                AddError(
                  StrSubstNo(
                    Text041, Job.FieldCaption(Blocked), Job.Blocked, Job.TableCaption(), PurchLine."Job No."));

        if PurchLine."Job Task No." = '' then
            AddError(StrSubstNo(Text006, PurchLine.FieldCaption("Job Task No.")))
        else
            if not JT.Get(PurchLine."Job No.", PurchLine."Job Task No.") then
                AddError(StrSubstNo(Text053, JT.TableCaption(), PurchLine."Job Task No."))
    end;

    local procedure IsInvtPosting(): Boolean
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", "Purchase Header"."Document Type");
        PurchLine.SetRange("Document No.", "Purchase Header"."No.");
        PurchLine.SetFilter(Type, '%1|%2', PurchLine.Type::Item, PurchLine.Type::"Charge (Item)");
        if PurchLine.IsEmpty() then
            exit(false);
        if "Purchase Header".Receive then begin
            PurchLine.SetFilter("Qty. to Receive", '<>%1', 0);
            if not PurchLine.IsEmpty() then
                exit(true);
        end;
        if "Purchase Header".Ship then begin
            PurchLine.SetFilter("Return Qty. to Ship", '<>%1', 0);
            if not PurchLine.IsEmpty() then
                exit(true);
        end;
        if "Purchase Header".Invoice then begin
            PurchLine.SetFilter("Qty. to Invoice", '<>%1', 0);
            if not PurchLine.IsEmpty() then
                exit(true);
        end;
    end;

    procedure AddDimToTempLine(PurchLine: Record "Purchase Line")
    var
        SourceCodesetup: Record "Source Code Setup";
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        SourceCodesetup.Get();

        DimMgt.AddDimSource(DefaultDimSource, DimMgt.PurchLineTypeToTableID(PurchLine.Type), PurchLine."No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, PurchLine."Job No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::"Responsibility Center", PurchLine."Responsibility Center");

        PurchLine."Shortcut Dimension 1 Code" := '';
        PurchLine."Shortcut Dimension 2 Code" := '';

        PurchLine."Dimension Set ID" :=
          DimMgt.GetDefaultDimID(DefaultDimSource, SourceCodesetup.Purchases, PurchLine."Shortcut Dimension 1 Code", PurchLine."Shortcut Dimension 2 Code",
            PurchLine."Dimension Set ID", Database::Vendor);

        OnAfterAddDimToTempLine(PurchLine);
    end;

    procedure InitializeRequest(NewReceiveShipOnNextPostReq: Boolean; NewInvOnNextPostReq: Boolean; NewShowDim: Boolean; NewShowItemChargeAssgnt: Boolean)
    begin
        ReceiveShipOnNextPostReq := NewReceiveShipOnNextPostReq;
        InvOnNextPostReq := NewInvOnNextPostReq;
        ShowDim := NewShowDim;
        ShowItemChargeAssgnt := NewShowItemChargeAssgnt;
    end;

    local procedure VerifyBuyFromVend(PurchaseHeader: Record "Purchase Header")
    begin
        if PurchaseHeader."Buy-from Vendor No." = '' then
            AddError(StrSubstNo(Text006, PurchaseHeader.FieldCaption("Buy-from Vendor No.")))
        else
            if Vend.Get(PurchaseHeader."Buy-from Vendor No.") then begin
                if Vend."Privacy Blocked" then
                    AddError(Vend.GetPrivacyBlockedGenericErrorText(Vend));

                if Vend.Blocked = Vend.Blocked::All then
                    AddError(
                      StrSubstNo(
                        Text041,
                        Vend.FieldCaption(Blocked), Vend.Blocked, Vend.TableCaption(), PurchaseHeader."Buy-from Vendor No."));
            end else
                AddError(
                  StrSubstNo(
                    Text008,
                    Vend.TableCaption(), PurchaseHeader."Buy-from Vendor No."));
    end;

    local procedure VerifyPayToVend(PurchaseHeader: Record "Purchase Header")
    begin
        if PurchaseHeader."Pay-to Vendor No." = '' then
            AddError(StrSubstNo(Text006, PurchaseHeader.FieldCaption("Pay-to Vendor No.")))
        else
            if PurchaseHeader."Pay-to Vendor No." <> PurchaseHeader."Buy-from Vendor No." then
                if Vend.Get(PurchaseHeader."Pay-to Vendor No.") then begin
                    if Vend."Privacy Blocked" then
                        AddError(Vend.GetPrivacyBlockedGenericErrorText(Vend));
                    if Vend.Blocked = Vend.Blocked::All then
                        AddError(
                          StrSubstNo(
                            Text041,
                            Vend.FieldCaption(Blocked), Vend.Blocked::All, Vend.TableCaption(), PurchaseHeader."Pay-to Vendor No."));
                end else
                    AddError(
                      StrSubstNo(
                        Text008,
                        Vend.TableCaption(), PurchaseHeader."Pay-to Vendor No."));
    end;

    local procedure VerifyPostingDate(PurchaseHeader: Record "Purchase Header")
    var
        UserSetupManagement: Codeunit "User Setup Management";
        InvtPeriodEndDate: Date;
        TempErrorText: Text[250];
    begin
        if PurchaseHeader."Posting Date" = 0D then
            AddError(StrSubstNo(Text006, PurchaseHeader.FieldCaption("Posting Date")))
        else
            if PurchaseHeader."Posting Date" <> NormalDate(PurchaseHeader."Posting Date") then
                AddError(StrSubstNo(Text009, PurchaseHeader.FieldCaption("Posting Date")))
            else begin
                if not UserSetupManagement.TestAllowedPostingDate(PurchaseHeader."Posting Date", TempErrorText) then
                    AddError(TempErrorText);
                if IsInvtPosting() then begin
                    InvtPeriodEndDate := PurchaseHeader."Posting Date";
                    if not InvtPeriod.IsValidDate(InvtPeriodEndDate) then
                        AddError(
                          StrSubstNo(Text010, Format(PurchaseHeader."Posting Date")))
                end;
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddDimToTempLine(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPurchaseDoc(PurchaseHeader: Record "Purchase Header"; var ErrorText: array[99] of Text[250]; var ErrorCounter: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValuePostingHeader(var PurchaseHeader: Record "Purchase Header"; var TableID: array[10] of Integer; var No: array[10] of Code[20]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValuePostingLine(var PurchaseLine: Record "Purchase Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestJobFields(var PurchaseLine: Record "Purchase Line"; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250]; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPurchLineCaseTypeElse(LineType: Option; "No.": Code[20]; var ErrorText: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRoundLoopOnAfterGetRecord(var PurchaseLine: Record "Purchase Line"; var ErrorText: array[99] of Text[250]; var ErrorCounter: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRoundLoopOnBeforeAfterGetRecord(var PurchaseLine: Record "Purchase Line"; var ErrorCounter: Integer; var ErrorText: array[99] of Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPurchLine(PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var ErrorCounter: Integer; var ErrorText: Text[250])
    begin
    end;
}

