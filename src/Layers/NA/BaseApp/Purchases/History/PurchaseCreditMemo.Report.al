// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Utilities;

report 407 "Purchase - Credit Memo"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/History/PurchaseCreditMemo.rdlc';
    Caption = 'Purchase - Credit Memo';
    PreviewMode = PrintLayout;
    WordMergeDataItem = "Purch. Cr. Memo Hdr.";

    dataset
    {
        dataitem("Purch. Cr. Memo Hdr."; "Purch. Cr. Memo Hdr.")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Buy-from Vendor No.", "No. Printed";
            RequestFilterHeading = 'Posted Purchase Cr. Memo';
            column(No_PurchCrMemoHeader; "No.")
            {
            }
            column(CrMemoNoCaption; CrMemoNoCaptionLbl)
            {
            }
            column(HomePageCaption; HomePageCaptionLbl)
            {
            }
            column(EmailCaption; EmailCaptionLbl)
            {
            }
            column(DocumentDateCaption; DocumentDateCaptionLbl)
            {
            }
            column(BuyFromContactPhoneNoLbl; BuyFromContactPhoneNoLbl)
            {
            }
            column(BuyFromContactMobilePhoneNoLbl; BuyFromContactMobilePhoneNoLbl)
            {
            }
            column(BuyFromContactEmailLbl; BuyFromContactEmailLbl)
            {
            }
            column(PayToContactPhoneNoLbl; PayToContactPhoneNoLbl)
            {
            }
            column(PayToContactMobilePhoneNoLbl; PayToContactMobilePhoneNoLbl)
            {
            }
            column(PayToContactEmailLbl; PayToContactEmailLbl)
            {
            }
            column(BuyFromContactPhoneNo; BuyFromContact."Phone No.")
            {
            }
            column(BuyFromContactMobilePhoneNo; BuyFromContact."Mobile Phone No.")
            {
            }
            column(BuyFromContactEmail; BuyFromContact."E-Mail")
            {
            }
            column(PayToContactPhoneNo; PayToContact."Phone No.")
            {
            }
            column(PayToContactMobilePhoneNo; PayToContact."Mobile Phone No.")
            {
            }
            column(PayToContactEmail; PayToContact."E-Mail")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(DocCaptCopyTxt; StrSubstNo(DocumentCaption(), CopyText))
                    {
                    }
                    column(VendAddr1; VendAddr[1])
                    {
                    }
                    column(CompanyAddr1; CompanyAddr[1])
                    {
                    }
                    column(VendAddr2; VendAddr[2])
                    {
                    }
                    column(CompanyAddr2; CompanyAddr[2])
                    {
                    }
                    column(VendAddr3; VendAddr[3])
                    {
                    }
                    column(CompanyAddr3; CompanyAddr[3])
                    {
                    }
                    column(VendAddr4; VendAddr[4])
                    {
                    }
                    column(CompanyAddr4; CompanyAddr[4])
                    {
                    }
                    column(VendAddr5; VendAddr[5])
                    {
                    }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(VendAddr6; VendAddr[6])
                    {
                    }
                    column(CompanyInfoHomePage; CompanyInfo."Home Page")
                    {
                    }
                    column(CompanyInfoEmail; CompanyInfo."E-Mail")
                    {
                    }
                    column(CompanyPicture; DummyCompanyInfo.Picture)
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
                    column(CompanyInfoBankAccountNo; CompanyInfo."Bank Account No.")
                    {
                    }
                    column(PaytoVendNo_PurchCrMemoHeader; "Purch. Cr. Memo Hdr."."Pay-to Vendor No.")
                    {
                    }
                    column(DocDate04_PurchCrMemoHeader; Format("Purch. Cr. Memo Hdr."."Document Date", 0, 4))
                    {
                    }
                    column(VATNoTxt; VATNoText)
                    {
                    }
                    column(VATRegNo_PurchCrMemoHeader; "Purch. Cr. Memo Hdr."."VAT Registration No.")
                    {
                    }
                    column(No1_PurchCrMemoHeader; "Purch. Cr. Memo Hdr."."No.")
                    {
                    }
                    column(PurchaserTxt; PurchaserText)
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(AppliedToTxt; AppliedToText)
                    {
                    }
                    column(ReferenceTxt; ReferenceText)
                    {
                    }
                    column(YourRef_PurchCrMemoHeader; "Purch. Cr. Memo Hdr."."Your Reference")
                    {
                    }
                    column(VendAddr7; VendAddr[7])
                    {
                    }
                    column(VendAddr8; VendAddr[8])
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
                    column(PostingDate_PurchCrMemoHeader; Format("Purch. Cr. Memo Hdr."."Posting Date"))
                    {
                    }
                    column(PricesIncludingVAT_PurchCrMemoHeader; "Purch. Cr. Memo Hdr."."Prices Including VAT")
                    {
                    }
                    column(BuyfrmVendNo_PurchCrMemoHeader; "Purch. Cr. Memo Hdr."."Buy-from Vendor No.")
                    {
                    }
                    column(ReturnOrderNo_PurchCrMemoHeader; "Purch. Cr. Memo Hdr."."Return Order No.")
                    {
                    }
                    column(ReturnOrderNoTxt; ReturnOrderNoText)
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PricesIncVAT_PurchCrMemoHeader; Format("Purch. Cr. Memo Hdr."."Prices Including VAT"))
                    {
                    }
                    column(VendTaxIdType; Format(Vend."Tax Identification Type"))
                    {
                    }
                    column(PhoneNoCaption; PhoneNoCaptionLbl)
                    {
                    }
                    column(VATRegNoCaption; VATRegNoCaptionLbl)
                    {
                    }
                    column(GiroNoCaption; GiroNoCaptionLbl)
                    {
                    }
                    column(BankCaption; BankCaptionLbl)
                    {
                    }
                    column(BankAccNoCaption; BankAccNoCaptionLbl)
                    {
                    }
                    column(PostingDateCaption; PostingDateCaptionLbl)
                    {
                    }
                    column(TaxIdentTypeCaption; TaxIdentTypeCaptionLbl)
                    {
                    }
                    column(PaytoVendNo_PurchCrMemoHeaderCaption; "Purch. Cr. Memo Hdr.".FieldCaption("Pay-to Vendor No."))
                    {
                    }
                    column(PricesIncludingVAT_PurchCrMemoHeaderCaption; "Purch. Cr. Memo Hdr.".FieldCaption("Prices Including VAT"))
                    {
                    }
                    column(BuyfrmVendNo_PurchCrMemoHeaderCaption; "Purch. Cr. Memo Hdr.".FieldCaption("Buy-from Vendor No."))
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Purch. Cr. Memo Hdr.";
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimTxt; DimText)
                        {
                        }
                        column(HeaderDimCaption; HeaderDimCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not DimSetEntry1.Find('-') then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();

                            Clear(DimText);
                            Continue := false;
                            repeat
                                OldDimText := DimText;
                                if DimText = '' then
                                    DimText := StrSubstNo(
                                        '%1 %2', DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code")
                                else
                                    DimText :=
                                      StrSubstNo(
                                        '%1, %2 %3', DimText,
                                        DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code");
                                if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                    DimText := OldDimText;
                                    Continue := true;
                                    exit;
                                end;
                            until (DimSetEntry1.Next() = 0);
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInternalInfo then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Purch. Cr. Memo Line"; "Purch. Cr. Memo Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Purch. Cr. Memo Hdr.";
                        DataItemTableView = sorting("Document No.", "Line No.");
                        column(ShowIntInfo_PurchCrMemoLine; ShowInternalInfo)
                        {
                        }
                        column(AllowInvDis_PurchCrMemoLine; AllowInvDiscount)
                        {
                        }
                        column(PricesIncVAT_PurchCrMemoLine; PricesIncludingVAT)
                        {
                        }
                        column(Type_PurchCrMemoLine; Format("Purch. Cr. Memo Line".Type, 0, 2))
                        {
                        }
                        column(VATBasDisc_PurchCrMemoLine; "Purch. Cr. Memo Hdr."."VAT Base Discount %")
                        {
                        }
                        column(VATAmtTxt_PurchCrMemoLine; VATAmountText)
                        {
                        }
                        column(AmtLine_PurchCrMemoLine; "Line Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Desc_PurchCrMemoLine; Description)
                        {
                        }
                        column(No_PurchCrMemoLine; "No.")
                        {
                        }
                        column(Qty_PurchCrMemoLine; Quantity)
                        {
                        }
                        column(UOM_PurchCrMemoLine; "Unit of Measure")
                        {
                        }
                        column(DirectUnitCost_PurchCrMemoLine; "Direct Unit Cost")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Line".GetCurrencyCode();
                            AutoFormatType = 2;
                        }
                        column(LineDisc_PurchCrMemoLine; "Line Discount %")
                        {
                        }
                        column(AllowInvDisc_PurchCrMemoLine; "Allow Invoice Disc.")
                        {
                        }
                        column(VATId_PurchCrMemoLine; "VAT Identifier")
                        {
                        }
                        column(InvDisAmt_PurchCrMemoLine; -"Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalTxt_PurchCrMemoLine; TotalText)
                        {
                        }
                        column(Amt_PurchCrMemoLine; Amount)
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalExclVATTxt_PurchCrMemoLine; TotalExclVATText)
                        {
                        }
                        column(TotalInclVATTxt_PurchCrMemoLine; TotalInclVATText)
                        {
                        }
                        column(AmtInclVAT_PurchCrMemoLine; "Amount Including VAT")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AmtInclVATAmt_PurchCrMemoLine; "Amount Including VAT" - Amount)
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineTxt_PurchCrMemoLine; TempVATAmountLine.VATAmountText())
                        {
                        }
                        column(DocNo_PurchCrMemoLine; "Document No.")
                        {
                        }
                        column(LineNo_PurchCrMemoLine; "Line No.")
                        {
                        }
                        column(TotalSubTotal_PurchCrMemoLine; TotalSubTotal)
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalInvDisAmt_PurchCrMemoLine; TotalInvoiceDiscountAmount)
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalAmt_PurchCrMemoLine; TotalAmount)
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalAmtInclVAT_PurchCrMemoLine; TotalAmountInclVAT)
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalAmtVAT_PurchCrMemoLine; TotalAmountVAT)
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalPayDistOnVAT; TotalPaymentDiscountOnVAT)
                        {
                            AutoFormatType = 1;
                        }
                        column(DirectUnitCostCaption; DirectUnitCostCaptionLbl)
                        {
                        }
                        column(DiscPercentageCaption; DiscPercentageCaptionLbl)
                        {
                        }
                        column(AmtCaption; AmtCaptionLbl)
                        {
                        }
                        column(InvDiscAmtCaption; InvDiscAmtCaptionLbl)
                        {
                        }
                        column(SubtotalCaption; SubtotalCaptionLbl)
                        {
                        }
                        column(PaymentDiscVATCaption; PaymentDiscVATCaptionLbl)
                        {
                        }
                        column(AllowInvDiscCaption; AllowInvDiscCaptionLbl)
                        {
                        }
                        column(Desc_PurchCrMemoLineCaption; FieldCaption(Description))
                        {
                        }
                        column(No_PurchCrMemoLineCaption; FieldCaption("No."))
                        {
                        }
                        column(Qty_PurchCrMemoLineCaption; FieldCaption(Quantity))
                        {
                        }
                        column(UOM_PurchCrMemoLineCaption; FieldCaption("Unit of Measure"))
                        {
                        }
                        column(VATId_PurchCrMemoLineCaption; FieldCaption("VAT Identifier"))
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(DimTxtLoop2; DimText)
                            {
                            }
                            column(LineDimCaption; LineDimCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then begin
                                    if not DimSetEntry2.Find('-') then
                                        CurrReport.Break();
                                end else
                                    if not Continue then
                                        CurrReport.Break();

                                Clear(DimText);
                                Continue := false;
                                repeat
                                    OldDimText := DimText;
                                    if DimText = '' then
                                        DimText := StrSubstNo(
                                            '%1 %2', DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code")
                                    else
                                        DimText :=
                                          StrSubstNo(
                                            '%1, %2 %3', DimText,
                                            DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code");
                                    if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                        DimText := OldDimText;
                                        Continue := true;
                                        exit;
                                    end;
                                until (DimSetEntry2.Next() = 0);
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfo then
                                    CurrReport.Break();

                                DimSetEntry2.SetRange("Dimension Set ID", "Purch. Cr. Memo Line"."Dimension Set ID");
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if (Type = Type::"G/L Account") and (not ShowInternalInfo) then
                                "No." := '';

                            TempVATAmountLine.Init();
                            TempVATAmountLine."VAT Identifier" := "Purch. Cr. Memo Line"."VAT Identifier";
                            TempVATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                            TempVATAmountLine."Tax Group Code" := "Tax Group Code";
                            TempVATAmountLine."Tax Area Code" := "Tax Area Code";
                            TempVATAmountLine."Use Tax" := "Use Tax";
                            TempVATAmountLine."VAT %" := "VAT %";
                            TempVATAmountLine."VAT Base" := Amount;
                            TempVATAmountLine."Amount Including VAT" := "Amount Including VAT";
                            TempVATAmountLine."Line Amount" := "Line Amount";
                            if "Allow Invoice Disc." then
                                TempVATAmountLine."Inv. Disc. Base Amount" := "Line Amount";
                            TempVATAmountLine."Invoice Discount Amount" := "Inv. Discount Amount";
                            TempVATAmountLine.InsertLine();

                            AllowInvDiscount := Format("Purch. Cr. Memo Line"."Allow Invoice Disc.");

                            TotalSubTotal += "Line Amount";
                            TotalInvoiceDiscountAmount -= "Inv. Discount Amount";
                            TotalAmount += Amount;
                            TotalAmountVAT += "Amount Including VAT" - Amount;
                            TotalAmountInclVAT += "Amount Including VAT";
                            TotalPaymentDiscountOnVAT += -("Line Amount" - "Inv. Discount Amount" - "Amount Including VAT");

                            if FirstLineHasBeenOutput then
                                Clear(DummyCompanyInfo.Picture);
                            FirstLineHasBeenOutput := true;
                        end;

                        trigger OnPreDataItem()
                        var
                            PurchCrMemoLine: Record "Purch. Cr. Memo Line";
                            VATIdentifier: Code[20];
                        begin
                            TempVATAmountLine.DeleteAll();
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("No." = '') and (Quantity = 0) and (Amount = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SetRange("Line No.", 0, "Line No.");

                            PurchCrMemoLine.SetRange("Document No.", "Purch. Cr. Memo Hdr."."No.");
                            PurchCrMemoLine.SetFilter(Type, '<>%1', 0);
                            VATAmountText := '';
                            if PurchCrMemoLine.Find('-') then begin
                                VATAmountText := StrSubstNo(Text012, PurchCrMemoLine."VAT %");
                                VATIdentifier := PurchCrMemoLine."VAT Identifier";
                                repeat
                                    if (PurchCrMemoLine."VAT Identifier" <> VATIdentifier) and (PurchCrMemoLine.Quantity <> 0) then
                                        VATAmountText := Text013;
                                until PurchCrMemoLine.Next() = 0;
                            end;
                            AllowInvDiscount := Format("Purch. Cr. Memo Line"."Allow Invoice Disc.");
                            FirstLineHasBeenOutput := false;
                            DummyCompanyInfo.Picture := CompanyInfo.Picture;
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(VATBase_PurchCrMemoLine; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmt_VATAmtLine; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(LineAmt_VATAmtLine; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(InvDiscBaseAmt_VATAmtLine; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(InvDisAmt_VATAmtLine; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VAT_VATAmtLine; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATId_VATAmtLine; TempVATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATPercentageCaption; VATPercentageCaptionLbl)
                        {
                        }
                        column(VATBaseCaption; VATBaseCaptionLbl)
                        {
                        }
                        column(VATAmtCaption; VATAmtCaptionLbl)
                        {
                        }
                        column(VATAmtSpecCaption; VATAmtSpecCaptionLbl)
                        {
                        }
                        column(VATIdentifierCaption; VATIdentifierCaptionLbl)
                        {
                        }
                        column(LineAmtCaption; LineAmtCaptionLbl)
                        {
                        }
                        column(InvDiscBaseAmtCaption; InvDiscBaseAmtCaptionLbl)
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
                        column(VALVATAmtLCY; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATBaseLCY; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVATPercent; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmtLineVATId; TempVATAmountLine."VAT Identifier")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempVATAmountLine.GetLine(Number);
                            VALVATBaseLCY :=
                              TempVATAmountLine.GetBaseLCY(
                                "Purch. Cr. Memo Hdr."."Posting Date", "Purch. Cr. Memo Hdr."."Currency Code",
                                "Purch. Cr. Memo Hdr."."Currency Factor");
                            VALVATAmountLCY :=
                              TempVATAmountLine.GetAmountLCY(
                                "Purch. Cr. Memo Hdr."."Posting Date", "Purch. Cr. Memo Hdr."."Currency Code",
                                "Purch. Cr. Memo Hdr."."Currency Factor");
                        end;

                        trigger OnPreDataItem()
                        begin
                            if (not GLSetup."Print VAT specification in LCY") or
                               ("Purch. Cr. Memo Hdr."."Currency Code" = '')
                            then
                                CurrReport.Break();

                            SetRange(Number, 1, TempVATAmountLine.Count);
                            Clear(VALVATBaseLCY);
                            Clear(VALVATAmountLCY);

                            if GLSetup."LCY Code" = '' then
                                VALSpecLCYHeader := Text008 + Text009
                            else
                                VALSpecLCYHeader := Text008 + Format(GLSetup."LCY Code");

                            CurrExchRate.FindCurrency("Purch. Cr. Memo Hdr."."Posting Date", "Purch. Cr. Memo Hdr."."Currency Code", 1);
                            CalculatedExchRate := Round(1 / "Purch. Cr. Memo Hdr."."Currency Factor" * CurrExchRate."Exchange Rate Amount", 0.000001);
                            VALExchRate := StrSubstNo(Text010, CalculatedExchRate, CurrExchRate."Exchange Rate Amount");
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));

                        trigger OnPreDataItem()
                        begin
                            if "Purch. Cr. Memo Hdr."."Buy-from Vendor No." = "Purch. Cr. Memo Hdr."."Pay-to Vendor No." then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(ShipToAddr1; ShipToAddr[1])
                        {
                        }
                        column(ShipToAddr2; ShipToAddr[2])
                        {
                        }
                        column(ShipToAddr3; ShipToAddr[3])
                        {
                        }
                        column(ShipToAddr4; ShipToAddr[4])
                        {
                        }
                        column(ShipToAddr5; ShipToAddr[5])
                        {
                        }
                        column(ShipToAddr6; ShipToAddr[6])
                        {
                        }
                        column(ShipToAddr7; ShipToAddr[7])
                        {
                        }
                        column(ShipToAddr8; ShipToAddr[8])
                        {
                        }
                        column(ShiptoAddressCaption; ShiptoAddressCaptionLbl)
                        {
                        }
                        column(ShipToPhoneNo; "Purch. Cr. Memo Hdr."."Ship-to Phone No.")
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if ShipToAddr[1] = '' then
                                CurrReport.Break();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    FirstLineHasBeenOutput := false;
                    if Number > 1 then begin
                        CopyText := FormatDocument.GetCOPYText();
                        OutputNo += 1;
                    end;

                    TotalSubTotal := 0;
                    TotalInvoiceDiscountAmount := 0;
                    TotalAmount := 0;
                    TotalAmountVAT := 0;
                    TotalAmountInclVAT := 0;
                    TotalPaymentDiscountOnVAT := 0;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode() then
                        CODEUNIT.Run(CODEUNIT::"PurchCrMemo-Printed", "Purch. Cr. Memo Hdr.");
                end;

                trigger OnPreDataItem()
                begin
                    OutputNo := 1;

                    NoOfLoops := Abs(NoOfCopies) + 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FirstLineHasBeenOutput := false;
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");

                FormatAddressFields("Purch. Cr. Memo Hdr.");
                FormatDocumentFields("Purch. Cr. Memo Hdr.");
                if BuyFromContact.Get("Buy-from Contact No.") then;
                if PayToContact.Get("Pay-to Contact No.") then;

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                if not Vend.Get("Buy-from Vendor No.") then
                    Clear(Vend);

                PricesIncludingVAT := Format("Purch. Cr. Memo Hdr."."Prices Including VAT");
            end;

            trigger OnPreDataItem()
            begin
                FirstLineHasBeenOutput := false;
                OnAfterPostDataItem("Purch. Cr. Memo Hdr.");
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
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies the number of copies of each document (in addition to the original) that you want to print.';
                    }
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want the printed report to show information that is only for internal use.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies that interactions with the contact are logged.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            InitLogInteraction();
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        GLSetup.Get();
        CompanyInfo.SetAutoCalcFields(Picture);
        CompanyInfo.Get();

        OnAfterInitReport();
    end;

    trigger OnPostReport()
    begin
        if LogInteraction and not IsReportInPreviewMode() then
            if "Purch. Cr. Memo Hdr.".FindSet() then
                repeat
                    SegManagement.LogDocument(
                      16, "Purch. Cr. Memo Hdr."."No.", 0, 0, DATABASE::Vendor, "Purch. Cr. Memo Hdr."."Buy-from Vendor No.",
                      "Purch. Cr. Memo Hdr."."Purchaser Code", '', "Purch. Cr. Memo Hdr."."Posting Description", '');
                until "Purch. Cr. Memo Hdr.".Next() = 0;
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label '(Applies to %1 %2)';
#pragma warning restore AA0470
        Text005: Label 'Purchase - Credit Memo %1', Comment = '%1 = Document No.';
#pragma warning restore AA0074
        DummyCompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        RespCenter: Record "Responsibility Center";
        CurrExchRate: Record "Currency Exchange Rate";
        BuyFromContact: Record Contact;
        PayToContact: Record Contact;
        Vend: Record Vendor;
        LanguageMgt: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        SegManagement: Codeunit SegManagement;
        VendAddr: array[8] of Text[100];
        ReturnOrderNoText: Text[80];
        PurchaserText: Text[50];
        VATNoText: Text[80];
        ReferenceText: Text[80];
        AppliedToText: Text;
        TotalText: Text[50];
        TotalInclVATText: Text[50];
        TotalExclVATText: Text[50];
        AllowInvDiscount: Text[30];
        PricesIncludingVAT: Text[30];
        VATAmountText: Text[30];
        MoreLines: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        OutputNo: Integer;
        CopyText: Text[30];
        DimText: Text[120];
        OldDimText: Text[75];
        ShowInternalInfo: Boolean;
        Continue: Boolean;
        LogInteraction: Boolean;
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
        VALSpecLCYHeader: Text[80];
        VALExchRate: Text[50];
#pragma warning disable AA0074
        Text008: Label 'VAT Amount Specification in ';
        Text009: Label 'Local Currency';
#pragma warning disable AA0470
        Text010: Label 'Exchange rate: %1/%2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CalculatedExchRate: Decimal;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text011: Label 'Purchase - Prepmt. Credit Memo %1';
        Text012: Label '%1% VAT';
#pragma warning restore AA0470
        Text013: Label 'VAT Amount';
#pragma warning restore AA0074
        LogInteractionEnable: Boolean;
        TotalSubTotal: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalAmountVAT: Decimal;
        TotalInvoiceDiscountAmount: Decimal;
        TotalPaymentDiscountOnVAT: Decimal;
        PhoneNoCaptionLbl: Label 'Phone No.';
        VATRegNoCaptionLbl: Label 'VAT Registration No.';
        GiroNoCaptionLbl: Label 'Giro No.';
        BankCaptionLbl: Label 'Bank';
        BankAccNoCaptionLbl: Label 'Account No.';
        PostingDateCaptionLbl: Label 'Posting Date';
        TaxIdentTypeCaptionLbl: Label 'Tax Ident. Type';
        HeaderDimCaptionLbl: Label 'Header Dimensions';
        DirectUnitCostCaptionLbl: Label 'Direct Unit Cost';
        DiscPercentageCaptionLbl: Label 'Discount %';
        AmtCaptionLbl: Label 'Amount';
        InvDiscAmtCaptionLbl: Label 'Invoice Discount Amount';
        SubtotalCaptionLbl: Label 'Subtotal';
        PaymentDiscVATCaptionLbl: Label 'Payment Discount on VAT';
        AllowInvDiscCaptionLbl: Label 'Allow Invoice Discount';
        LineDimCaptionLbl: Label 'Line Dimensions';
        VATPercentageCaptionLbl: Label 'VAT %';
        VATBaseCaptionLbl: Label 'VAT Base';
        VATAmtCaptionLbl: Label 'VAT Amount';
        VATAmtSpecCaptionLbl: Label 'VAT Amount Specification';
        VATIdentifierCaptionLbl: Label 'VAT Identifier';
        LineAmtCaptionLbl: Label 'Line Amount';
        InvDiscBaseAmtCaptionLbl: Label 'Invoice Discount Base Amount';
        TotalCaptionLbl: Label 'Total';
        ShiptoAddressCaptionLbl: Label 'Ship-to Address';
        CrMemoNoCaptionLbl: Label 'Credit Memo No.';
        HomePageCaptionLbl: Label 'Home Page';
        EmailCaptionLbl: Label 'Email';
        DocumentDateCaptionLbl: Label 'Document Date';
        BuyFromContactPhoneNoLbl: Label 'Buy-from Contact Phone No.';
        BuyFromContactMobilePhoneNoLbl: Label 'Buy-from Contact Mobile Phone No.';
        BuyFromContactEmailLbl: Label 'Buy-from Contact E-Mail';
        PayToContactPhoneNoLbl: Label 'Pay-to Contact Phone No.';
        PayToContactMobilePhoneNoLbl: Label 'Pay-to Contact Mobile Phone No.';
        PayToContactEmailLbl: Label 'Pay-to Contact E-Mail';

    protected var
        CompanyInfo: Record "Company Information";
        FirstLineHasBeenOutput: Boolean;
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];

    procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractionTemplateCode(Enum::"Interaction Log Entry Document Type"::"Purch. Cr. Memo") <> '';
    end;

    local procedure DocumentCaption(): Text[250]
    begin
        if "Purch. Cr. Memo Hdr."."Prepayment Credit Memo" then
            exit(Text011);
        exit(Text005);
    end;

    procedure InitializeRequest(NewNoOfCopies: Integer; NewShowInternalInfo: Boolean; NewLogInteraction: Boolean)
    begin
        NoOfCopies := NewNoOfCopies;
        ShowInternalInfo := NewShowInternalInfo;
        LogInteraction := NewLogInteraction;
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure FormatAddressFields(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        FormatAddr.GetCompanyAddr(PurchCrMemoHdr."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        FormatAddr.PurchCrMemoPayTo(VendAddr, PurchCrMemoHdr);
        FormatAddr.PurchCrMemoShipTo(ShipToAddr, PurchCrMemoHdr);
    end;

    local procedure FormatDocumentFields(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        FormatDocument.SetTotalLabels(PurchCrMemoHdr."Currency Code", TotalText, TotalInclVATText, TotalExclVATText);
        FormatDocument.SetPurchaser(SalesPurchPerson, PurchCrMemoHdr."Purchaser Code", PurchaserText);

        ReturnOrderNoText := FormatDocument.SetText(PurchCrMemoHdr."Return Order No." <> '', PurchCrMemoHdr.FieldCaption("Return Order No."));
        ReferenceText := FormatDocument.SetText(PurchCrMemoHdr."Your Reference" <> '', PurchCrMemoHdr.FieldCaption("Your Reference"));
        VATNoText := FormatDocument.SetText(PurchCrMemoHdr."VAT Registration No." <> '', PurchCrMemoHdr.FieldCaption("VAT Registration No."));
        AppliedToText :=
          FormatDocument.SetText(
            PurchCrMemoHdr."Applies-to Doc. No." <> '', Format(StrSubstNo(Text003, Format(PurchCrMemoHdr."Applies-to Doc. Type"), PurchCrMemoHdr."Applies-to Doc. No.")));
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitReport()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostDataItem(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;
}

