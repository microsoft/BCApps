// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Utilities;

report 412 "Purchase Prepmt. Doc. - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/PurchasePrepmtDocTest.rdlc';
    Caption = 'Purchase Prepmt. Doc. - Test';

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = where("Document Type" = const(Order));
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Purchase Prepayment Document';
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
                column(STRSUBSTNO_Text001_PurchHeaderFilter_; StrSubstNo(Text001, PurchHeaderFilter))
                {
                }
                column(PurchHeaderFilter; PurchHeaderFilter)
                {
                }
                column(PrepmtDocText; PrepmtDocText)
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
                column(ShipToAddr_1_; ShipToAddr[1])
                {
                }
                column(BuyFromAddr_1_; BuyFromAddr[1])
                {
                }
                column(Purchase_Header___Sell_to_Customer_No__; "Purchase Header"."Sell-to Customer No.")
                {
                }
                column(Purchase_Header___Buy_from_Vendor_No__; "Purchase Header"."Buy-from Vendor No.")
                {
                }
                column(FORMAT__Purchase_Header___Document_Type____________Purchase_Header___No__; Format("Purchase Header"."Document Type") + ' ' + "Purchase Header"."No.")
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
                column(PayToAddr_4_; PayToAddr[4])
                {
                }
                column(PayToAddr_3_; PayToAddr[3])
                {
                }
                column(PayToAddr_2_; PayToAddr[2])
                {
                }
                column(PayToAddr_1_; PayToAddr[1])
                {
                }
                column(Purchase_Header___Pay_to_Vendor_No__; "Purchase Header"."Pay-to Vendor No.")
                {
                }
                column(ShowPgCounter5; not ("Purchase Header"."Pay-to Vendor No." in ['', "Purchase Header"."Buy-from Vendor No."]))
                {
                }
                column(Purchase_Header___Purchaser_Code_; "Purchase Header"."Purchaser Code")
                {
                }
                column(Purchase_Header___Your_Reference_; "Purchase Header"."Your Reference")
                {
                }
                column(Purchase_Header___Prices_Including_VAT_; "Purchase Header"."Prices Including VAT")
                {
                }
                column(Purchase_Header___Vendor_Invoice_No__; "Purchase Header"."Vendor Invoice No.")
                {
                }
                column(Purchase_Header___Shipment_Method_Code_; "Purchase Header"."Shipment Method Code")
                {
                }
                column(Purchase_Header___Payment_Method_Code_; "Purchase Header"."Payment Method Code")
                {
                }
                column(Purchase_Header___Vendor_Shipment_No__; "Purchase Header"."Vendor Shipment No.")
                {
                }
                column(Purchase_Header___Vendor_Order_No__; "Purchase Header"."Vendor Order No.")
                {
                }
                column(Purchase_Header___Prepayment_Due_Date_; Format("Purchase Header"."Prepayment Due Date"))
                {
                }
                column(Purchase_Header___Posting_Date_; Format("Purchase Header"."Posting Date"))
                {
                }
                column(Purchase_Header___Prepmt__Payment_Terms_Code_; "Purchase Header"."Prepmt. Payment Terms Code")
                {
                }
                column(Purchase_Header___Document_Date_; Format("Purchase Header"."Document Date"))
                {
                }
                column(Purchase_Header___Expected_Receipt_Date_; Format("Purchase Header"."Expected Receipt Date"))
                {
                }
                column(Purchase_Header___Vendor_Posting_Group_; "Purchase Header"."Vendor Posting Group")
                {
                }
                column(Purchase_Header___Order_Date_; Format("Purchase Header"."Order Date"))
                {
                }
                column(Purchase_Header___Prepmt__Pmt__Discount_Date_; Format("Purchase Header"."Prepmt. Pmt. Discount Date"))
                {
                }
                column(Purchase_Header___Prepmt__Payment_Discount___; "Purchase Header"."Prepmt. Payment Discount %")
                {
                }
                column(FORMAT__Purchase_Header___Prepmt__Include_Tax__; Format("Purchase Header"."Prepmt. Include Tax"))
                {
                }
                column(ShowPgCounter7; DocumentType = DocumentType::Invoice)
                {
                }
                column(PricesIncludingVAT1; Format("Purchase Header"."Prices Including VAT"))
                {
                }
                column(Purchase_Header___Vendor_Cr__Memo_No__; "Purchase Header"."Vendor Cr. Memo No.")
                {
                }
                column(Purchase_Header___Prices_Including_VAT__Control78; "Purchase Header"."Prices Including VAT")
                {
                }
                column(Purchase_Header___Posting_Date__Control81; Format("Purchase Header"."Posting Date"))
                {
                }
                column(Purchase_Header___Document_Date__Control83; Format("Purchase Header"."Document Date"))
                {
                }
                column(Purchase_Header___Vendor_Posting_Group__Control87; "Purchase Header"."Vendor Posting Group")
                {
                }
                column(FORMAT__Purchase_Header___Prepmt__Include_Tax___Control1021003; Format("Purchase Header"."Prepmt. Include Tax"))
                {
                }
                column(ShowPgCounter8; DocumentType = DocumentType::"Credit Memo")
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Purchase_Prepyament_Document___TestCaption; Purchase_Prepyament_Document___TestCaptionLbl)
                {
                }
                column(Ship_toCaption; Ship_toCaptionLbl)
                {
                }
                column(Buy_fromCaption; Buy_fromCaptionLbl)
                {
                }
                column(Purchase_Header___Sell_to_Customer_No__Caption; "Purchase Header".FieldCaption("Sell-to Customer No."))
                {
                }
                column(Purchase_Header___Buy_from_Vendor_No__Caption; "Purchase Header".FieldCaption("Buy-from Vendor No."))
                {
                }
                column(Purchase_Header___Pay_to_Vendor_No__Caption; "Purchase Header".FieldCaption("Pay-to Vendor No."))
                {
                }
                column(Pay_toCaption; Pay_toCaptionLbl)
                {
                }
                column(Purchase_Header___Purchaser_Code_Caption; "Purchase Header".FieldCaption("Purchaser Code"))
                {
                }
                column(Purchase_Header___Your_Reference_Caption; "Purchase Header".FieldCaption("Your Reference"))
                {
                }
                column(Purchase_Header___Prices_Including_VAT_Caption; "Purchase Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(Purchase_Header___Vendor_Invoice_No__Caption; "Purchase Header".FieldCaption("Vendor Invoice No."))
                {
                }
                column(Purchase_Header___Vendor_Shipment_No__Caption; "Purchase Header".FieldCaption("Vendor Shipment No."))
                {
                }
                column(Purchase_Header___Vendor_Order_No__Caption; "Purchase Header".FieldCaption("Vendor Order No."))
                {
                }
                column(Purchase_Header___Shipment_Method_Code_Caption; "Purchase Header".FieldCaption("Shipment Method Code"))
                {
                }
                column(Purchase_Header___Payment_Method_Code_Caption; "Purchase Header".FieldCaption("Payment Method Code"))
                {
                }
                column(Purchase_Header___Prepayment_Due_Date_Caption; Purchase_Header___Prepayment_Due_Date_CaptionLbl)
                {
                }
                column(Purchase_Header___Posting_Date_Caption; Purchase_Header___Posting_Date_CaptionLbl)
                {
                }
                column(Purchase_Header___Prepmt__Payment_Terms_Code_Caption; "Purchase Header".FieldCaption("Prepmt. Payment Terms Code"))
                {
                }
                column(Purchase_Header___Document_Date_Caption; Purchase_Header___Document_Date_CaptionLbl)
                {
                }
                column(Purchase_Header___Expected_Receipt_Date_Caption; Purchase_Header___Expected_Receipt_Date_CaptionLbl)
                {
                }
                column(Purchase_Header___Vendor_Posting_Group_Caption; "Purchase Header".FieldCaption("Vendor Posting Group"))
                {
                }
                column(Purchase_Header___Order_Date_Caption; Purchase_Header___Order_Date_CaptionLbl)
                {
                }
                column(Purchase_Header___Prepmt__Pmt__Discount_Date_Caption; Purchase_Header___Prepmt__Pmt__Discount_Date_CaptionLbl)
                {
                }
                column(Purchase_Header___Prepmt__Payment_Discount___Caption; "Purchase Header".FieldCaption("Prepmt. Payment Discount %"))
                {
                }
                column(FORMAT__Purchase_Header___Prepmt__Include_Tax__Caption; FORMAT__Purchase_Header___Prepmt__Include_Tax__CaptionLbl)
                {
                }
                column(Purchase_Header___Vendor_Cr__Memo_No__Caption; "Purchase Header".FieldCaption("Vendor Cr. Memo No."))
                {
                }
                column(Purchase_Header___Prices_Including_VAT__Control78Caption; "Purchase Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(Purchase_Header___Posting_Date__Control81Caption; Purchase_Header___Posting_Date__Control81CaptionLbl)
                {
                }
                column(Purchase_Header___Document_Date__Control83Caption; Purchase_Header___Document_Date__Control83CaptionLbl)
                {
                }
                column(Purchase_Header___Vendor_Posting_Group__Control87Caption; "Purchase Header".FieldCaption("Vendor Posting Group"))
                {
                }
                column(FORMAT__Purchase_Header___Prepmt__Include_Tax___Control1021003Caption; FORMAT__Purchase_Header___Prepmt__Include_Tax___Control1021003CaptionLbl)
                {
                }
                dataitem(HeaderDimLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(HeaderDimLoop_Number; Number)
                    {
                    }
                    column(Header_DimensionsCaption; Header_DimensionsCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not DimSetEntry.FindSet() then
                                CurrReport.Break();
                        end else
                            if not Continue then
                                CurrReport.Break();

                        DimText := '';
                        Continue := false;
                        repeat
                            Continue := MergeText(DimSetEntry);
                            if Continue then
                                exit;
                        until DimSetEntry.Next() = 0;
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
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    dataitem("Purchase Line"; "Purchase Line")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemLinkReference = "Purchase Header";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                        trigger OnPreDataItem()
                        begin
                            CurrReport.Break();
                        end;
                    }
                    dataitem(PurchLineLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(Purchase_Line___Prepmt__Amt__Inv__; "Purchase Line"."Prepmt. Amt. Inv.")
                        {
                        }
                        column(Purchase_Line___Prepmt__Line_Amount_; "Purchase Line"."Prepmt. Line Amount")
                        {
                        }
                        column(Purchase_Line___Prepayment___; "Purchase Line"."Prepayment %")
                        {
                        }
                        column(Purchase_Line___Line_Amount_; "Purchase Line"."Line Amount")
                        {
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
                        column(Purchase_Line__Type; Format("Purchase Line".Type))
                        {
                        }
                        column(Purchase_Line___Line_No__; "Purchase Line"."Line No.")
                        {
                        }
                        column(Purchase_Line___Prepmt__Amt__Inv__Caption; "Purchase Line".FieldCaption("Prepmt. Amt. Inv."))
                        {
                        }
                        column(Purchase_Line___Prepmt__Line_Amount_Caption; "Purchase Line".FieldCaption("Prepmt. Line Amount"))
                        {
                        }
                        column(Purchase_Line___Prepayment___Caption; "Purchase Line".FieldCaption("Prepayment %"))
                        {
                        }
                        column(Purchase_Line___Line_Amount_Caption; "Purchase Line".FieldCaption("Line Amount"))
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
                        dataitem(LineErrorCounter; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(ErrorText_Number__Control104; ErrorText[Number])
                            {
                            }
                            column(ErrorText_Number__Control104Caption; ErrorText_Number__Control104CaptionLbl)
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
                            GLAcc: Record "G/L Account";
                            CurrentErrorCount: Integer;
                        begin
                            if Number = 1 then begin
                                if not TempPurchLine.Find('-') then
                                    CurrReport.Break();
                            end else
                                if TempPurchLine.Next() = 0 then
                                    CurrReport.Break();
                            "Purchase Line" := TempPurchLine;
                            CurrentErrorCount := ErrorCounter;
                            if ("Purchase Line"."Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") or
                               ("Purchase Line"."Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
                            then
                                if not GenPostingSetup.Get(
                                     "Purchase Line"."Gen. Bus. Posting Group", "Purchase Line"."Gen. Prod. Posting Group")
                                then
                                    AddError(
                                      StrSubstNo(
                                        Text016,
                                        GenPostingSetup.TableCaption(),
                                        "Purchase Line"."Gen. Bus. Posting Group", "Purchase Line"."Gen. Prod. Posting Group"));

                            if GenPostingSetup."Purch. Prepayments Account" = '' then
                                AddError(StrSubstNo(Text006, GenPostingSetup.FieldCaption("Purch. Prepayments Account")))
                            else
                                if GLAcc.Get(GenPostingSetup."Purch. Prepayments Account") then begin
                                    if GLAcc.Blocked then
                                        AddError(
                                          StrSubstNo(
                                            Text008, GLAcc.FieldCaption(Blocked), false, GLAcc.TableCaption(), "Purchase Line"."No."));
                                end else
                                    AddError(StrSubstNo(Text007, GLAcc.TableCaption(), GenPostingSetup."Purch. Prepayments Account"));

                            if ErrorCounter = CurrentErrorCount then
                                if PurchPostPrepmt.PrepmtAmount("Purchase Line", DocumentType, "Purchase Header"."Prepmt. Include Tax") <> 0 then begin
                                    PurchPostPrepmt.FillInvLineBuffer("Purchase Header", "Purchase Line", TempPrepmtInvLineBuf2);
                                    TempPrepmtInvLineBuf.InsertInvLineBuffer(TempPrepmtInvLineBuf2);
                                end;

                            TempPrepmtInvLineBuf2.Reset();
                            TempPrepmtInvLineBuf2.DeleteAll();
                        end;
                    }

                    trigger OnPreDataItem()
                    var
                        TempPurchLineToDeduct: Record "Purchase Line" temporary;
                    begin
                        TempPurchLine.Reset();
                        TempPurchLine.DeleteAll();

                        Clear(PurchPostPrepmt);
                        TempVATAmountLine.DeleteAll();
                        if "Purchase Header"."Tax Area Code" = '' then begin  // VAT
                            PurchPostPrepmt.GetPurchLines("Purchase Header", DocumentType, TempPurchLine);
                            if DocumentType = DocumentType::Invoice then begin
                                PurchPostPrepmt.GetPurchLinesToDeduct("Purchase Header", TempPurchLineToDeduct);
                                if not TempPurchLineToDeduct.IsEmpty() then
                                    PurchPostPrepmt.CalcVATAmountLines(
                                      "Purchase Header", TempPurchLineToDeduct, TempVATAmountLineDeduct, DocumentType::"Credit Memo");
                            end;
                            PurchPostPrepmt.CalcVATAmountLines("Purchase Header", TempPurchLine, TempVATAmountLine, DocumentType);
                            TempVATAmountLine.DeductVATAmountLine(TempVATAmountLineDeduct);
                            PurchPostPrepmt.UpdateVATOnLines("Purchase Header", TempPurchLine, TempVATAmountLine, DocumentType);
                            VATAmount := TempVATAmountLine.GetTotalVATAmount();
                            VATBaseAmount := TempVATAmountLine.GetTotalVATBase();
                        end else begin
                            PurchLine.SetPurchHeader("Purchase Header");
                            PurchLine.CalcSalesTaxLines("Purchase Header", PurchLine);
                            PurchPostPrepmt.UpdateSalesTaxOnLines(PurchLine, "Purchase Header"."Prepmt. Include Tax", "Purchase Header", DocumentType);
                            if PurchLine.FindSet() then
                                repeat
                                    TempPurchLine := PurchLine;
                                    if DocumentType = DocumentType::"Credit Memo" then
                                        TempPurchLine."Prepmt. Amt. Inv." := TempPurchLine."Prepmt. Line Amount";
                                    TempPurchLine.Insert();
                                until PurchLine.Next() = 0;
                        end;
                    end;
                }
                dataitem(Blank; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                }
                dataitem(PrepmtLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(Prepayment_Inv__Line_Buffer___VAT_Identifier_; "Prepayment Inv. Line Buffer"."VAT Identifier")
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer___VAT___; "Prepayment Inv. Line Buffer"."VAT %")
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer___VAT_Amount_; "Prepayment Inv. Line Buffer"."VAT Amount")
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer__Description; "Prepayment Inv. Line Buffer".Description)
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer__Amount; "Prepayment Inv. Line Buffer".Amount)
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer___G_L_Account_No__; "Prepayment Inv. Line Buffer"."G/L Account No.")
                    {
                    }
                    column(PrepmtLoop_PrepmtLoop_Number; Number)
                    {
                    }
                    column(TotalText; TotalText)
                    {
                    }
                    column(VATAmount___0; VATAmount = 0)
                    {
                    }
                    column(TotalExclVATText; TotalExclVATText)
                    {
                    }
                    column(VATAmountLine_VATAmountText; TempVATAmountLine.VATAmountText())
                    {
                    }
                    column(TotalInclVATText; TotalInclVATText)
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer__Amount_Control160; "Prepayment Inv. Line Buffer".Amount)
                    {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmount; VATAmount)
                    {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Prepayment_Inv__Line_Buffer__Amount___VATAmount; "Prepayment Inv. Line Buffer".Amount + VATAmount)
                    {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(NOT__Purchase_Header___Prices_Including_VAT__AND__VATAmount____0_; not "Purchase Header"."Prices Including VAT" and (VATAmount <> 0))
                    {
                    }
                    column(SumPrepaymInvLineBufferAmount; SumPrepaymInvLineBufferAmount)
                    {
                    }
                    column(VATBaseAmount___VATAmount; VATBaseAmount + VATAmount)
                    {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Purchase_Header___Prices_Including_VAT__AND__VATAmount____0_; "Purchase Header"."Prices Including VAT" and (VATAmount <> 0))
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer___VAT_Identifier_Caption; "Prepayment Inv. Line Buffer".FieldCaption("VAT Identifier"))
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer___VAT___Caption; "Prepayment Inv. Line Buffer".FieldCaption("VAT %"))
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer___VAT_Amount_Caption; "Prepayment Inv. Line Buffer".FieldCaption("VAT Amount"))
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer__DescriptionCaption; "Prepayment Inv. Line Buffer".FieldCaption(Description))
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer__AmountCaption; "Prepayment Inv. Line Buffer".FieldCaption(Amount))
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer___G_L_Account_No__Caption; "Prepayment Inv. Line Buffer".FieldCaption("G/L Account No."))
                    {
                    }
                    dataitem("Prepayment Inv. Line Buffer"; "Prepayment Inv. Line Buffer")
                    {
                        DataItemTableView = sorting("G/L Account No.", "Dimension Set ID", "Job No.", "Tax Area Code", "Tax Liable", "Tax Group Code", "Invoice Rounding", Adjustment, "Line No.");

                        trigger OnPreDataItem()
                        begin
                            CurrReport.Break();
                        end;
                    }
                    dataitem(LineDimLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText_Control118; DimText)
                        {
                        }
                        column(LineDimLoop_Number; Number)
                        {
                        }
                        column(LineDocDim_LineNo; LineDimSetEntry."Dimension Set ID")
                        {
                        }
                        column(Header_DimensionsCaption_Control119; Header_DimensionsCaption_Control119Lbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not LineDimSetEntry.FindSet() then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();
                            DimText := '';
                            Continue := false;

                            repeat
                                Continue := MergeText(LineDimSetEntry);
                                if Continue then
                                    exit;
                            until LineDimSetEntry.Next() = 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowDim then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(PrepmtErrorCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ErrorText_Number__Control121; ErrorText[Number])
                        {
                        }
                        column(ErrorText_Number__Control121Caption; ErrorText_Number__Control121CaptionLbl)
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
                    begin
                        if Number = 1 then begin
                            if not TempPrepmtInvLineBuf.Find('-') then
                                CurrReport.Break();
                        end else
                            if TempPrepmtInvLineBuf.Next() = 0 then
                                CurrReport.Break();

                        LineDimSetEntry.SetRange("Dimension Set ID", TempPrepmtInvLineBuf."Dimension Set ID");

                        "Prepayment Inv. Line Buffer" := TempPrepmtInvLineBuf;

                        if not DimMgt.CheckDimIDComb(TempPrepmtInvLineBuf."Dimension Set ID") then
                            AddError(DimMgt.GetDimCombErr());
                        TableID[1] := DimMgt.PurchLineTypeToTableID("Purchase Line".Type::"G/L Account");
                        No[1] := "Prepayment Inv. Line Buffer"."G/L Account No.";
                        TableID[2] := Database::Job;
                        No[2] := "Prepayment Inv. Line Buffer"."Job No.";
                        if not DimMgt.CheckDimValuePosting(TableID, No, TempPrepmtInvLineBuf."Dimension Set ID") then
                            AddError(DimMgt.GetDimValuePostingErr());

                        SumPrepaymInvLineBufferAmount := SumPrepaymInvLineBufferAmount + "Prepayment Inv. Line Buffer".Amount;
                    end;

                    trigger OnPostDataItem()
                    begin
                        TempPrepmtInvLineBuf.Reset();
                        TempPrepmtInvLineBuf.DeleteAll();
                    end;

                    trigger OnPreDataItem()
                    begin
                        SumPrepaymInvLineBufferAmount := 0;
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
                        AutoFormatExpression = "Purchase Line"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__Line_Amount_; TempVATAmountLine."Line Amount")
                    {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Amount__Control128; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Base__Control129; TempVATAmountLine."VAT Base")
                    {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__Line_Amount__Control130; TempVATAmountLine."Line Amount")
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
                    column(VATAmountLine__VAT_Amount__Control151; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Base__Control152; TempVATAmountLine."VAT Base")
                    {
                        AutoFormatExpression = "Purchase Line"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__Line_Amount__Control153; TempVATAmountLine."Line Amount")
                    {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Amount__Control128Caption; VATAmountLine__VAT_Amount__Control128CaptionLbl)
                    {
                    }
                    column(VATAmountLine__VAT_Base__Control129Caption; VATAmountLine__VAT_Base__Control129CaptionLbl)
                    {
                    }
                    column(VATAmountLine__Line_Amount__Control130Caption; VATAmountLine__Line_Amount__Control130CaptionLbl)
                    {
                    }
                    column(VATAmountLine__VAT___Caption; VATAmountLine__VAT___CaptionLbl)
                    {
                    }
                    column(VATAmountLine__VAT_Identifier_Caption; VATAmountLine__VAT_Identifier_CaptionLbl)
                    {
                    }
                    column(VAT_Amount_SpecificationCaption; VAT_Amount_SpecificationCaptionLbl)
                    {
                    }
                    column(ContinuedCaption; ContinuedCaptionLbl)
                    {
                    }
                    column(ContinuedCaption_Control150; ContinuedCaption_Control150Lbl)
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
                        if VATAmount = 0 then
                            CurrReport.Break();
                        SetRange(Number, 1, TempVATAmountLine.Count);
                    end;
                }
            }

            trigger OnAfterGetRecord()
            var
                VendLedgEntry: Record "Vendor Ledger Entry";
                FormatAddr: Codeunit "Format Address";
                VendorMgt: Codeunit "Vendor Mgt.";
                TableID: array[10] of Integer;
                No: array[10] of Code[20];
            begin
                FormatAddr.PurchHeaderPayTo(PayToAddr, "Purchase Header");
                FormatAddr.PurchHeaderBuyFrom(BuyFromAddr, "Purchase Header");
                FormatAddr.PurchHeaderShipTo(ShipToAddr, "Purchase Header");
                if "Currency Code" = '' then begin
                    GLSetup.TestField("LCY Code");
                    TotalText := StrSubstNo(Text002, GLSetup."LCY Code");
                    TotalInclVATText := StrSubstNo(Text003, GLSetup."LCY Code");
                    TotalExclVATText := StrSubstNo(Text004, GLSetup."LCY Code");
                end else begin
                    TotalText := StrSubstNo(Text002, "Currency Code");
                    TotalInclVATText := StrSubstNo(Text003, "Currency Code");
                    TotalExclVATText := StrSubstNo(Text004, "Currency Code");
                end;

                if "Document Type" <> "Document Type"::Order then
                    AddError(StrSubstNo(Text000, FieldCaption("Document Type")));

                if not PurchPostPrepmt.CheckOpenPrepaymentLines("Purchase Header", DocumentType) then
                    AddError(DocumentErrorsMgt.GetNothingToPostErrorMsg());

                if (DocumentType = DocumentType::Invoice) and ("Prepayment Due Date" = 0D) then
                    AddError(StrSubstNo(Text006, FieldCaption("Prepayment Due Date")));

                CheckVend("Buy-from Vendor No.", FieldCaption("Buy-from Vendor No."));
                CheckVend("Pay-to Vendor No.", FieldCaption("Pay-to Vendor No."));

                CheckPostingDate("Purchase Header");

                PurchSetup.Get();

                case DocumentType of
                    DocumentType::Invoice:
                        begin
                            if PurchSetup."Ext. Doc. No. Mandatory" and ("Vendor Invoice No." = '') then
                                AddError(StrSubstNo(Text006, FieldCaption("Vendor Invoice No.")));
                            if ("Prepayment No." = '') and ("Prepayment No. Series" = '') then
                                AddError(StrSubstNo(Text012, FieldCaption("Prepayment No. Series")));
                            if "Vendor Invoice No." <> '' then
                                VendorMgt.SetFilterForExternalDocNo(
                                  VendLedgEntry, VendLedgEntry."Document Type"::Invoice, "Vendor Invoice No.", "Pay-to Vendor No.", "Document Date");
                        end;
                    DocumentType::"Credit Memo":
                        begin
                            if PurchSetup."Ext. Doc. No. Mandatory" and ("Vendor Cr. Memo No." = '') then
                                AddError(StrSubstNo(Text006, FieldCaption("Vendor Cr. Memo No.")));
                            if ("Prepmt. Cr. Memo No." = '') and ("Prepmt. Cr. Memo No. Series" = '') then
                                AddError(StrSubstNo(Text012, FieldCaption("Prepmt. Cr. Memo No.")));
                            if "Vendor Cr. Memo No." <> '' then
                                VendorMgt.SetFilterForExternalDocNo(
                                  VendLedgEntry, VendLedgEntry."Document Type"::"Credit Memo", "Vendor Cr. Memo No.", "Pay-to Vendor No.", "Document Date");
                        end;
                end;

                if VendLedgEntry.HasFilter then begin
                    VendLedgEntry.SetCurrentKey("Vendor No.");
                    VendLedgEntry.SetRange("Vendor No.", "Pay-to Vendor No.");
                    if VendLedgEntry.FindFirst() then
                        AddError(StrSubstNo(Text011, VendLedgEntry."Document Type", VendLedgEntry."External Document No."));
                end;

                DimSetEntry.SetRange("Dimension Set ID", "Dimension Set ID");
                if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                    AddError(DimMgt.GetDimCombErr());

                TableID[1] := Database::Vendor;
                No[1] := "Pay-to Vendor No.";
                TableID[2] := Database::Job;
                // No[2] := "Job No.";
                TableID[3] := Database::"Salesperson/Purchaser";
                No[3] := "Purchaser Code";
                TableID[4] := Database::Campaign;
                No[4] := "Campaign No.";
                TableID[5] := Database::"Responsibility Center";
                No[5] := "Responsibility Center";
                CheckDimValuePosting(TableID, No, "Purchase Header");
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrepaymentDocumentType; DocumentType)
                    {
                        ApplicationArea = Prepayments;
                        Caption = 'Prepayment Document Type';
                        OptionCaption = 'Invoice,Credit Memo';
                        ToolTip = 'Specifies the type of prepayment document: invoice or credit memo.';
                    }
                    field(ShowDimensions; ShowDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies if you want dimensions information for the journal lines to be included in the report.';
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
        PurchHeaderFilter := "Purchase Header".GetFilters();

        if DocumentType = DocumentType::Invoice then
            PrepmtDocText := Text014
        else
            PrepmtDocText := Text015;

        GLSetup.Get();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        GenPostingSetup: Record "General Posting Setup";
        TempPurchLine: Record "Purchase Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineDeduct: Record "VAT Amount Line" temporary;
        TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary;
        TempPrepmtInvLineBuf2: Record "Prepayment Inv. Line Buffer" temporary;
        PurchLine: Record "Purchase Line";
        DimSetEntry: Record "Dimension Set Entry";
        LineDimSetEntry: Record "Dimension Set Entry";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        PurchPostPrepmt: Codeunit "Purchase-Post Prepayments";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        DimMgt: Codeunit DimensionManagement;
        DocumentType: Option Invoice,"Credit Memo",Statistic;
        VATAmount: Decimal;
        VATBaseAmount: Decimal;
        ErrorCounter: Integer;
        ErrorText: array[99] of Text[250];
        PurchHeaderFilter: Text;
        DimText: Text[120];
        PayToAddr: array[8] of Text[100];
        BuyFromAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        PrepmtDocText: Text[50];
        TotalText: Text[50];
        TotalInclVATText: Text[50];
        TotalExclVATText: Text[50];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must be Order.';
        Text001: Label 'Purchase Document: %1';
        Text002: Label 'Total %1';
        Text003: Label 'Total %1 Incl. VAT';
        Text004: Label 'Total %1 Excl. VAT';
        Text006: Label '%1 must be specified.';
        Text007: Label '%1 %2 does not exist.';
        Text008: Label '%1 must not be %2 for %3 %4.';
        Text009: Label '%1 must not be a closing date.';
        Text010: Label '%1 is not within your allowed range of posting dates.';
        Text011: Label 'Purchase %1 %2 already exists for this vendor.';
        Text012: Label '%1 must be entered.';
#pragma warning restore AA0470
        Text014: Label 'Prepayment Invoice';
        Text015: Label 'Prepayment Credit Memo';
#pragma warning restore AA0074
        ShowDim: Boolean;
        Continue: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text016: Label '%1 %2 %3 does not exist.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        SumPrepaymInvLineBufferAmount: Decimal;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Purchase_Prepyament_Document___TestCaptionLbl: Label 'Purchase Prepayment Document - Test';
        Ship_toCaptionLbl: Label 'Ship-to';
        Buy_fromCaptionLbl: Label 'Buy-from';
        Pay_toCaptionLbl: Label 'Pay-to';
        Purchase_Header___Prepayment_Due_Date_CaptionLbl: Label 'Prepayment Due Date';
        Purchase_Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        Purchase_Header___Document_Date_CaptionLbl: Label 'Document Date';
        Purchase_Header___Expected_Receipt_Date_CaptionLbl: Label 'Expected Receipt Date';
        Purchase_Header___Order_Date_CaptionLbl: Label 'Order Date';
        Purchase_Header___Prepmt__Pmt__Discount_Date_CaptionLbl: Label 'Prepmt. Pmt. Discount Date';
        FORMAT__Purchase_Header___Prepmt__Include_Tax__CaptionLbl: Label 'Prepmt. Include Tax';
        Purchase_Header___Posting_Date__Control81CaptionLbl: Label 'Posting Date';
        Purchase_Header___Document_Date__Control83CaptionLbl: Label 'Document Date';
        FORMAT__Purchase_Header___Prepmt__Include_Tax___Control1021003CaptionLbl: Label 'Prepmt. Include Tax';
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        ErrorText_Number__Control104CaptionLbl: Label 'Warning!';
        Header_DimensionsCaption_Control119Lbl: Label 'Header Dimensions';
        ErrorText_Number__Control121CaptionLbl: Label 'Warning!';
        VATAmountLine__VAT_Amount__Control128CaptionLbl: Label 'VAT Amount';
        VATAmountLine__VAT_Base__Control129CaptionLbl: Label 'VAT Base';
        VATAmountLine__Line_Amount__Control130CaptionLbl: Label 'Line Amount';
        VATAmountLine__VAT___CaptionLbl: Label 'VAT %';
        VATAmountLine__VAT_Identifier_CaptionLbl: Label 'VAT Identifier';
        VAT_Amount_SpecificationCaptionLbl: Label 'VAT Amount Specification';
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption_Control150Lbl: Label 'Continued';
        TotalCaptionLbl: Label 'Total';

    local procedure AddError(Text: Text)
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := CopyStr(Text, 1, MaxStrLen(ErrorText[ErrorCounter]));
    end;

    local procedure CheckVend(VendNo: Code[20]; FieldCaption: Text[30])
    var
        Vend: Record Vendor;
    begin
        if VendNo = '' then begin
            AddError(StrSubstNo(Text006, FieldCaption));
            exit;
        end;
        if not Vend.Get(VendNo) then begin
            AddError(StrSubstNo(Text007, Vend.TableCaption(), VendNo));
            exit;
        end;
        if Vend."Privacy Blocked" then
            AddError(Vend.GetPrivacyBlockedGenericErrorText(Vend));

        if Vend.Blocked in [Vend.Blocked::All, Vend.Blocked::Payment] then
            AddError(
              StrSubstNo(Text008, Vend.FieldCaption(Blocked), Vend.Blocked, Vend.TableCaption(), VendNo));
    end;

    local procedure CheckPostingDate(PurchaseHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
        PostingDateError: Text[250];
    begin
        IsHandled := false;
        OnBeforeCheckPostingDate(PurchaseHeader, PostingDateError, IsHandled);
        if IsHandled then begin
            AddError(PostingDateError);
            exit;
        end;

        case true of
            PurchaseHeader."Posting Date" = 0D:
                AddError(StrSubstNo(Text006, PurchaseHeader.FieldCaption("Posting Date")));
            PurchaseHeader."Posting Date" <> NormalDate(PurchaseHeader."Posting Date"):
                AddError(StrSubstNo(Text009, PurchaseHeader.FieldCaption("Posting Date")));
            GenJnlCheckLine.DateNotAllowed(PurchaseHeader."Posting Date", PurchaseHeader."Journal Templ. Name"):
                AddError(StrSubstNo(Text010, PurchaseHeader.FieldCaption("Posting Date")));
        end;
    end;

    local procedure CheckDimValuePosting(var TableID: array[10] of Integer; var No: array[10] of Code[20]; PurchaseHeader: Record "Purchase Header")
    begin
        OnBeforeCheckDimValuePosting(TableID, No, PurchaseHeader);
        if not DimMgt.CheckDimValuePosting(TableID, No, PurchaseHeader."Dimension Set ID") then
            AddError(DimMgt.GetDimValuePostingErr());
    end;

    local procedure MergeText(DimSetEntry: Record "Dimension Set Entry"): Boolean
    begin
        if (StrLen(DimText) + StrLen(StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")) + 2) >
           MaxStrLen(DimText)
        then
            exit(true);

        if DimText = '' then
            DimText := StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
        else
            DimText :=
              StrSubstNo('%1; %2', DimText, StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code"));
        exit(false);
    end;

    procedure InitializeRequest(NewDocumentType: Option; NewShowDim: Boolean)
    begin
        DocumentType := NewDocumentType;
        ShowDim := NewShowDim;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValuePosting(var TableID: array[10] of Integer; var No: array[10] of Code[20]; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPostingDate(var PurchaseHeader: Record "Purchase Header"; var PostingDateError: Text[250]; var IsHandled: Boolean)
    begin
    end;
}

