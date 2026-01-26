// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

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
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using System.Globalization;
using System.Utilities;

report 28072 "Sales - Tax Invoice"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/WithholdingTax/SalesTaxInvoice.rdlc';
    Caption = 'Sales - Tax Invoice';

    dataset
    {
        dataitem("Sales Tax Invoice Header"; "Sales Tax Invoice Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Sell-to Customer No.", "No. Printed";
            RequestFilterHeading = 'Sales Tax Invoice Header';
            column(No_SalesTaxInvHdr; "No.")
            {
            }
            column(CompanyInfoEmailCaption; CompanyInfoEmailCaptionLbl)
            {
            }
            column(CompanyInfoHomePageCaption; CompanyInfoHomePageCaptionLbl)
            {
            }
            column(DocumentDateCaption; DocumentDateCaptionLbl)
            {
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
                    column(Homepage; CompanyInfo."Home Page")
                    {
                    }
                    column(Email; CompanyInfo."E-Mail")
                    {
                    }
                    column(PaymentTermsDescription; PaymentTerms.Description)
                    {
                    }
                    column(ShipmentMethodDescription; ShipmentMethod.Description)
                    {
                    }
                    column(PaymentTermsDescCaption; PaymentTermsDescCaptionLbl)
                    {
                    }
                    column(ShipmentMethodDescCaption; ShipmentMethodDescCaptionLbl)
                    {
                    }
                    column(AllowInvDiscCaption; AllowInvDiscCaptionLbl)
                    {
                    }
                    column(CopyText; StrSubstNo(Text004, CopyText))
                    {
                    }
                    column(CustAddr1; CustAddr[1])
                    {
                    }
                    column(CompanyAddr1; CompanyAddr[1])
                    {
                    }
                    column(CustAddr2; CustAddr[2])
                    {
                    }
                    column(CompanyAddr2; CompanyAddr[2])
                    {
                    }
                    column(CustAddr3; CustAddr[3])
                    {
                    }
                    column(CompanyAddr3; CompanyAddr[3])
                    {
                    }
                    column(CustAddr4; CustAddr[4])
                    {
                    }
                    column(CustAddr5; CustAddr[5])
                    {
                    }
                    column(CompanyAddr4; CompanyAddr[4])
                    {
                    }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(CustAddr6; CustAddr[6])
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
                    column(BilltoCustNo_SalesTaxInvHdr; "Sales Tax Invoice Header"."Bill-to Customer No.")
                    {
                    }
                    column(FormatedPostingDate; Format("Sales Tax Invoice Header"."Posting Date"))
                    {
                    }
                    column(VATNoText; VATNoText)
                    {
                    }
                    column(VATRegNo_SalesTaxInvHdr; "Sales Tax Invoice Header"."VAT Registration No.")
                    {
                    }
                    column(FormatedDueDate; Format("Sales Tax Invoice Header"."Due Date"))
                    {
                    }
                    column(SalesPersonText; SalesPersonText)
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(No_PageLoop; "Sales Tax Invoice Header"."No.")
                    {
                    }
                    column(ReferenceText; ReferenceText)
                    {
                    }
                    column(YourReference_SalesTaxInvHdr; "Sales Tax Invoice Header"."Your Reference")
                    {
                    }
                    column(OrderNoText; OrderNoText)
                    {
                    }
                    column(OrderNo_SalesTaxInvHdr; "Sales Tax Invoice Header"."Order No.")
                    {
                    }
                    column(CustAddr7; CustAddr[7])
                    {
                    }
                    column(CustAddr8; CustAddr[8])
                    {
                    }
                    column(CompanyAddr5; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr6; CompanyAddr[6])
                    {
                    }
                    column(FormatedDocumentDate; Format("Sales Tax Invoice Header"."Document Date", 0, 4))
                    {
                    }
                    column(PricesIncluVAT_SalesTaxInvHdr; "Sales Tax Invoice Header"."Prices Including VAT")
                    {
                    }
                    column(NoOfLoops; OutputNO)
                    {
                    }
                    column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
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
                    column(DueDateCaption; DueDateCaptionLbl)
                    {
                    }
                    column(InvoiceNoCaption; InvoiceNoCaptionLbl)
                    {
                    }
                    column(PostingDateCaption; PostingDateCaptionLbl)
                    {
                    }
                    column(BilltoCustNo_SalesTaxInvHdrCaption; "Sales Tax Invoice Header".FieldCaption("Bill-to Customer No."))
                    {
                    }
                    column(PricesIncluVAT_SalesTaxInvHdrCaption; "Sales Tax Invoice Header".FieldCaption("Prices Including VAT"))
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Sales Tax Invoice Header";
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(Number_DimensionLoop1; Number)
                        {
                        }
                        column(HeaderDimensionsCaption; HeaderDimensionsCaptionLbl)
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
                    dataitem("Sales Tax Invoice Line"; "Sales Tax Invoice Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Sales Tax Invoice Header";
                        DataItemTableView = sorting("Document No.", "Line No.");
                        column(LineAmount_SalesTaxInvLine; "Line Amount")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Description_SalesTaxInvoiceLine; Description)
                        {
                        }
                        column(Description_SalesTaxInvoiceLineCaption; FieldCaption(Description))
                        {
                        }
                        column(TypeNO; TypeNO)
                        {
                        }
                        column(Quantity_SalesTaxInvLine; Quantity)
                        {
                        }
                        column(Quantity_SalesTaxInvLineCaption; FieldCaption(Quantity))
                        {
                        }
                        column(UOM_SalesTaxInvLine; "Unit of Measure")
                        {
                        }
                        column(UOM_SalesTaxInvLineCaption; FieldCaption("Unit of Measure"))
                        {
                        }
                        column(UnitPrice_SalesTaxInvLine; "Unit Price")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 2;
                        }
                        column(LineDiscount_SalesTaxInvLine; "Line Discount %")
                        {
                        }
                        column(AllowInvDisc_SalesTaxInvLine; "Allow Invoice Disc.")
                        {
                        }
                        column(VATIdentifier_SalesTaxInvLine; "VAT Identifier")
                        {
                        }
                        column(VATIdentifier_SalesTaxInvLineCaption; FieldCaption("VAT Identifier"))
                        {
                        }
                        column(ExternalDocNo_SalesTaxInvLine; "External Document No.")
                        {
                        }
                        column(InvDiscountAmount; -"Inv. Discount Amount")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(InvDiscountAmount0; TotalInvAmt <> 0)
                        {
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(Amount_SalesTaxInvLine; Amount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalAmt; TotalAmt)
                        {
                        }
                        column(SalesTaxInvLine_AmtInclVATAmt; "Amount Including VAT" - Amount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AmtIncluVAT_SalesTaxInvLine; "Amount Including VAT")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATAmountText_SalesTaxInvoiceLine; TempVATAmountLine.VATAmountText())
                        {
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(TotalVATAmt; TotalVATAmt)
                        {
                        }
                        column(LineAmtInvDisAmtAmtIncluVAT; -("Line Amount" - "Inv. Discount Amount" - "Amount Including VAT"))
                        {
                            AutoFormatExpression = "Sales Tax Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SalesTaxInvHdrVATBaseDis0; "Sales Tax Invoice Header"."VAT Base Discount %" <> 0)
                        {
                        }
                        column(TotalExclVATTextLCY; TotalExclVATTextLCY)
                        {
                        }
                        column(TotalInclVATTextLCY; TotalInclVATTextLCY)
                        {
                        }
                        column(AmountIncLCYAmountLCY; AmountIncLCY - AmountLCY)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AmountLCY; AmountLCY)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AmountIncLCY; AmountIncLCY)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(CurrFactor_SalesTaxInvHdr; "Sales Tax Invoice Header"."Currency Factor")
                        {
                        }
                        column(CurrCode_SalesTaxInvHdr; "Sales Tax Invoice Header"."Currency Code")
                        {
                        }
                        column(CurrencyLCY; CurrencyLCY)
                        {
                        }
                        column(AmountLangB1AmountLangB2; AmountLangB[1] + ' ' + AmountLangB[2])
                        {
                            AutoFormatType = 1;
                        }
                        column(AmountLangA1AmountLangA2; AmountLangA[1] + ' ' + AmountLangA[2])
                        {
                            AutoFormatType = 1;
                        }
                        column(AmountInWords; AmountInWords)
                        {
                        }
                        column(LineNo_SalesTaxInvLine; "Line No.")
                        {
                        }
                        column(TotalLineAmt; TotalLineAmt)
                        {
                        }
                        column(TotalInvAmt; TotalInvAmt)
                        {
                        }
                        column(UnitPriceCaption; UnitPriceCaptionLbl)
                        {
                        }
                        column(SalesTaxInvLineLineDisCaption; SalesTaxInvLineLineDisCaptionLbl)
                        {
                        }
                        column(AmountCaption; AmountCaptionLbl)
                        {
                        }
                        column(InvoiceRefCaption; InvoiceRefCaptionLbl)
                        {
                        }
                        column(ContinuedCaption; ContinuedCaptionLbl)
                        {
                        }
                        column(InvDiscountAmountCaption; InvDiscountAmountCaptionLbl)
                        {
                        }
                        column(SubtotalCaption; SubtotalCaptionLbl)
                        {
                        }
                        column(LineAmtInvDisAmtAmtIncluVATCaption; LineAmtInvDisAmtAmtIncluVATCaptionLbl)
                        {
                        }
                        column(ExchangeRateCaption; ExchangeRateCaptionLbl)
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(DimText_DimensionLoop2; DimText)
                            {
                            }
                            column(LineDimensionsCaption; LineDimensionsCaptionLbl)
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

                                DimSetEntry2.SetRange("Dimension Set ID", "Sales Tax Invoice Line"."Dimension Set ID");
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if (Type = Type::"G/L Account") and (not ShowInternalInfo) then
                                "No." := '';

                            TempVATAmountLine.Init();
                            TempVATAmountLine."VAT Identifier" := "VAT Identifier";
                            TempVATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                            TempVATAmountLine."Tax Group Code" := "Tax Group Code";
                            TempVATAmountLine."VAT %" := "VAT %";
                            TempVATAmountLine."VAT Base" := Amount;
                            TempVATAmountLine."Amount Including VAT" := "Amount Including VAT";
                            TempVATAmountLine."Line Amount" := "Line Amount";
                            TempVATAmountLine."VAT Realized" := "Paid VAT";
                            TempVATAmountLine."Amount Paid" := "Paid Amount Incl. VAT";
                            if "Allow Invoice Disc." then
                                TempVATAmountLine."Inv. Disc. Base Amount" := "Line Amount";
                            TempVATAmountLine."Invoice Discount Amount" := "Inv. Discount Amount";
                            TempVATAmountLine."VAT Amount" := TempVATAmountLine."Amount Including VAT" - TempVATAmountLine."VAT Base";
                            TempVATAmountLine.InsertLine();

                            TypeNO := Type;
                            TotalLineAmt += "Line Amount";
                            TotalInvAmt += "Inv. Discount Amount";
                            TotalAmt += Amount;
                            TotalVATAmt += "Amount Including VAT";
                        end;

                        trigger OnPreDataItem()
                        begin
                            TempVATAmountLine.DeleteAll();
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("No." = '') and (Quantity = 0) and (Amount = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SetRange("Line No.", 0, "Line No.");
                            TotalLineAmt := 0;
                            TotalInvAmt := 0;
                            TotalAmt := 0;
                            TotalVATAmt := 0;
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(VATAmountLineVATBase; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Sales Tax Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineVATAmount; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Sales Tax Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineLineAmount; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Tax Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscBaseAmount; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Sales Tax Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineInvDisAmount; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Sales Tax Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineAmountPaid; TempVATAmountLine."Amount Paid")
                        {
                            AutoFormatExpression = "Sales Tax Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineVATRealized; TempVATAmountLine."VAT Realized")
                        {
                            AutoFormatExpression = "Sales Tax Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineVAT; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmountLineVATIdentifier; TempVATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATAmountLineVATCaption; VATAmountLineVATCaptionLbl)
                        {
                        }
                        column(VATAmountLineVATBaseCaption; VATAmountLineVATBaseCaptionLbl)
                        {
                        }
                        column(VATAmountLineVATAmtCaption; VATAmountLineVATAmtCaptionLbl)
                        {
                        }
                        column(VATAmountSpecificationCaption; VATAmountSpecificationCaptionLbl)
                        {
                        }
                        column(VATAmountLineVATIdentCaption; VATAmountLineVATIdentCaptionLbl)
                        {
                        }
                        column(VATAmtLineInvDiscBaseAmtCaption; VATAmtLineInvDiscBaseAmtCaptionLbl)
                        {
                        }
                        column(VATAmountLineLineAmtCaption; VATAmountLineLineAmtCaptionLbl)
                        {
                        }
                        column(VATAmountLineInvDisAmtCaption; VATAmountLineInvDisAmtCaptionLbl)
                        {
                        }
                        column(AmountPaidCaption; AmountPaidCaptionLbl)
                        {
                        }
                        column(VATRealizedCaption; VATRealizedCaptionLbl)
                        {
                        }
                        column(VATBaseCaption; VATBaseCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempVATAmountLine.GetLine(Number);
                        end;

                        trigger OnPreDataItem()
                        begin
                            if TempVATAmountLine.GetTotalVATAmount() = 0 then
                                CurrReport.Break();
                            SetRange(Number, 1, TempVATAmountLine.Count);
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(SelltoCustNo_SalesTaxInvHdr; "Sales Tax Invoice Header"."Sell-to Customer No.")
                        {
                        }
                        column(SelltoCustNoBilltoCustNo_SalesTaxInvHdr; "Sales Tax Invoice Header"."Sell-to Customer No." <> "Sales Tax Invoice Header"."Bill-to Customer No.")
                        {
                        }
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
                        column(SelltoCustNo_SalesTaxInvHdrCaption; "Sales Tax Invoice Header".FieldCaption("Sell-to Customer No."))
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if not ShowShippingAddr then
                                CurrReport.Break();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then
                        CopyText := Text003;
                    OutputNO += 1;
                end;

                trigger OnPostDataItem()
                begin
                    if not CurrReport.Preview then
                        SalesTaxInvCountPrinted.Run("Sales Tax Invoice Header");
                end;

                trigger OnPreDataItem()
                begin
#if not CLEAN27
                    NoOfLoops := Abs(NoOfCopies) + Cust."Invoice Copies" + 1;
#else
                    NoOfLoops := Abs(NoOfCopies) + 1;
#endif
                    if NoOfLoops <= 0 then
                        NoOfLoops := 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);

                    OutputNO := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");

                if RespCenter.Get("Responsibility Center") then begin
                    FormatAddr.RespCenter(CompanyAddr, RespCenter);
                    CompanyInfo."Phone No." := RespCenter."Phone No.";
                    CompanyInfo."Fax No." := RespCenter."Fax No.";
                end else
                    FormatAddr.Company(CompanyAddr, CompanyInfo);

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                if "Order No." = '' then
                    OrderNoText := ''
                else
                    OrderNoText := FieldCaption("Order No.");
                if "Salesperson Code" = '' then begin
                    SalesPurchPerson.Init();
                    SalesPersonText := '';
                end else begin
                    SalesPurchPerson.Get("Salesperson Code");
                    SalesPersonText := Text000;
                end;
                if "Your Reference" = '' then
                    ReferenceText := ''
                else
                    ReferenceText := FieldCaption("Your Reference");
                if "VAT Registration No." = '' then
                    VATNoText := ''
                else
                    VATNoText := FieldCaption("VAT Registration No.");
                if "Currency Code" = '' then begin
                    GLSetup.TestField("LCY Code");
                    TotalText := StrSubstNo(Text001, GLSetup."LCY Code");
                    TotalInclVATText := StrSubstNo(Text002, GLSetup."LCY Code");
                    TotalExclVATText := StrSubstNo(Text006, GLSetup."LCY Code");
                end else begin
                    TotalText := StrSubstNo(Text001, "Currency Code");
                    TotalInclVATText := StrSubstNo(Text002, "Currency Code");
                    TotalExclVATText := StrSubstNo(Text006, "Currency Code");
                    TotalInclVATTextLCY := StrSubstNo(Text002, GLSetup."LCY Code");
                    TotalExclVATTextLCY := StrSubstNo(Text006, GLSetup."LCY Code");
                end;
                FormatAddr.SalesTaxInvBillTo(CustAddr, "Sales Tax Invoice Header");
                Cust.Get("Bill-to Customer No.");

                if "Payment Terms Code" = '' then
                    PaymentTerms.Init()
                else
                    PaymentTerms.Get("Payment Terms Code");
                if "Shipment Method Code" = '' then
                    ShipmentMethod.Init()
                else
                    ShipmentMethod.Get("Shipment Method Code");

                FormatAddr.SalesTaxInvShipTo(ShipToAddr, "Sales Tax Invoice Header");
                ShowShippingAddr := "Sell-to Customer No." <> "Bill-to Customer No.";
                for i := 1 to ArrayLen(ShipToAddr) do
                    if ShipToAddr[i] <> CustAddr[i] then
                        ShowShippingAddr := true;

                CalcFields(Amount);
                CalcFields("Amount Including VAT");

                AmountLCY :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      WorkDate(), "Currency Code", Amount, "Currency Factor"));
                AmountIncLCY :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      WorkDate(), "Currency Code", "Amount Including VAT", "Currency Factor"));
                SalesLine.InitTextVariable();
                SalesLine.FormatNoText(AmountLangA, "Amount Including VAT", "Currency Code");
                if ShowTHFormatting then begin
                    SalesLine.InitTextVariableTH();
                    SalesLine.FormatNoTextTH(AmountLangB, "Amount Including VAT", "Currency Code");
                end else begin
                    AmountLangB[1] := '';
                    AmountLangB[2] := '';
                end;

                if LogInteraction then
                    if not CurrReport.Preview then
                        if "Bill-to Contact No." <> '' then
                            SegManagement.LogDocument(
                              4, "No.", 0, 0, DATABASE::Contact, "Bill-to Contact No.", "Salesperson Code", '', "Posting Description", '')
                        else
                            SegManagement.LogDocument(
                              4, "No.", 0, 0, DATABASE::Customer, "Bill-to Customer No.", "Salesperson Code", '', "Posting Description", '');
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
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field(ShowInternalInformation; ShowInternalInfo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if the document shows internal information.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want the program to log this interaction.';
                    }
                    field(AmountInWords; AmountInWords)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Total In Words';
                        ToolTip = 'Specifies that you want to print total amounts as words.';
                    }
                    field(CurrencyLCY; CurrencyLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show LCY for FCY';
                        ToolTip = 'Specifies if you want to use your own currency instead of the currency of your customers or vendors.';
                    }
                    field(ShowTHAmountInWords; ShowTHFormatting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show TH Amount In Words';
                        ToolTip = 'Specifies that you want to print Thai amounts as words.';
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

    trigger OnInitReport()
    begin
        GLSetup.Get();
        CompanyInfo.Get();
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
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
        end;
    end;

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            InitLogInteraction();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        CompanyInfo1: Record "Company Information";
        CompanyInfo3: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        ShipmentMethod: Record "Shipment Method";
        PaymentTerms: Record "Payment Terms";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyInfo: Record "Company Information";
        Cust: Record Customer;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        RespCenter: Record "Responsibility Center";
        CurrExchRate: Record "Currency Exchange Rate";
        LanguageMgt: Codeunit Language;
        SalesTaxInvCountPrinted: Codeunit "Sales Tax Inv.-Printed";
        FormatAddr: Codeunit "Format Address";
        SegManagement: Codeunit SegManagement;
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        OrderNoText: Text[30];
        SalesPersonText: Text[30];
        VATNoText: Text[30];
        ReferenceText: Text[35];
        TotalText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
        TotalExclVATTextLCY: Text[50];
        TotalInclVATTextLCY: Text[50];
        AmountLangA: array[2] of Text[80];
        AmountLangB: array[2] of Text[80];
        AmountLCY: Decimal;
        AmountIncLCY: Decimal;
        MoreLines: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        CopyText: Text[30];
        ShowShippingAddr: Boolean;
        i: Integer;
        DimText: Text[120];
        OldDimText: Text[75];
        ShowInternalInfo: Boolean;
        Continue: Boolean;
        LogInteraction: Boolean;
        AmountInWords: Boolean;
        CurrencyLCY: Boolean;
        Text000: Label 'Salesperson';
        Text001: Label 'Total %1';
        Text002: Label 'Total %1 Incl. VAT';
        Text003: Label 'COPY';
        Text004: Label 'Sales - Tax Invoice %1';
        Text006: Label 'Total %1 Excl. VAT';
        SalesLine: Record "Sales Line";
        ShowTHFormatting: Boolean;
        TypeNO: Integer;
        OutputNO: Integer;
        TotalLineAmt: Decimal;
        TotalInvAmt: Decimal;
        TotalAmt: Decimal;
        TotalVATAmt: Decimal;
        LogInteractionEnable: Boolean;
        PaymentTermsDescCaptionLbl: Label 'Payment Terms';
        ShipmentMethodDescCaptionLbl: Label 'Shipment Method';
        AllowInvDiscCaptionLbl: Label 'Allow Invoice Discount';
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoVATRegNoCaptionLbl: Label 'VAT Registration No.';
        CompanyInfoGiroNoCaptionLbl: Label 'Giro No.';
        CompanyInfoBankNameCaptionLbl: Label 'Bank';
        CompanyInfoBankAccNoCaptionLbl: Label 'Account No.';
        DueDateCaptionLbl: Label 'Due Date';
        InvoiceNoCaptionLbl: Label 'Invoice No.';
        PostingDateCaptionLbl: Label 'Posting Date';
        HeaderDimensionsCaptionLbl: Label 'Header Dimensions';
        UnitPriceCaptionLbl: Label 'Unit Price';
        SalesTaxInvLineLineDisCaptionLbl: Label 'Discount %';
        AmountCaptionLbl: Label 'Amount';
        InvoiceRefCaptionLbl: Label 'Invoice Reference';
        ContinuedCaptionLbl: Label 'Continued';
        InvDiscountAmountCaptionLbl: Label 'Inv. Discount Amount';
        SubtotalCaptionLbl: Label 'Subtotal';
        LineAmtInvDisAmtAmtIncluVATCaptionLbl: Label 'Payment Discount on VAT';
        ExchangeRateCaptionLbl: Label 'Exchange Rate';
        LineDimensionsCaptionLbl: Label 'Line Dimensions';
        VATAmountLineVATCaptionLbl: Label 'VAT %';
        VATAmountLineVATBaseCaptionLbl: Label 'VAT Base';
        VATAmountLineVATAmtCaptionLbl: Label 'VAT Amount';
        VATAmountSpecificationCaptionLbl: Label 'VAT Amount Specification';
        VATAmountLineVATIdentCaptionLbl: Label 'VAT Identifier';
        VATAmtLineInvDiscBaseAmtCaptionLbl: Label 'Inv. Disc. Base Amount';
        VATAmountLineLineAmtCaptionLbl: Label 'Line Amount';
        VATAmountLineInvDisAmtCaptionLbl: Label 'Invoice Discount Amount';
        AmountPaidCaptionLbl: Label 'Amount Paid';
        VATRealizedCaptionLbl: Label 'VAT Realized';
        VATBaseCaptionLbl: Label 'Total';
        ShiptoAddressCaptionLbl: Label 'Ship-to Address';
        CompanyInfoEmailCaptionLbl: Label 'E-Mail';
        CompanyInfoHomePageCaptionLbl: Label 'Home Page';
        DocumentDateCaptionLbl: Label 'Document Date';

    [Scope('OnPrem')]
    procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Sales Inv.") <> '';
    end;
}

