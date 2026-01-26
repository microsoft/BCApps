// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Sales.History;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Utilities;

report 5912 "Service - Credit Memo"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/History/ServiceCreditMemo.rdlc';
    Caption = 'Service - Credit Memo';
    Permissions = TableData "Sales Shipment Buffer" = rimd;
    WordMergeDataItem = "Service Cr.Memo Header";

    dataset
    {
        dataitem("Service Cr.Memo Header"; "Service Cr.Memo Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Customer No.", "No. Printed";
            RequestFilterHeading = 'Posted Service Credit Memo';
            column(DocumentDateCaption; DocumentDateCaptionLbl)
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyInfo1Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(SalesCorrectInvCopyText; StrSubstNo(Text1100001, CopyText))
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
                    column(CompanyAddr4; CompanyAddr[4])
                    {
                    }
                    column(CustAddr5; CustAddr[5])
                    {
                    }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(CustAddr6; CustAddr[6])
                    {
                    }
                    column(CompanyInfoFaxNo; CompanyInfo."Fax No.")
                    {
                    }
                    column(CompanyInfoVATRegNo; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(CompanyInfoGiroNo; CompanyInfo."Giro No.")
                    {
                    }
                    column(UnitPriceCaption; UnitPriceCaptionLbl)
                    {
                    }
                    column(ServiceCrMemoLineLineDiscountCaption; ServiceCrMemoLineLineDiscountCaptionLbl)
                    {
                    }
                    column(AmountCaption; AmountCaptionLbl)
                    {
                    }
                    column(PostedReceiptDateCaption; PostedReceiptDateCaptionLbl)
                    {
                    }
                    column(InvDiscountAmountCaption; InvDiscountAmountCaptionLbl)
                    {
                    }
                    column(SubtotalCaption; SubtotalCaptionLbl)
                    {
                    }
                    column(TotalText; TotalTextLbl)
                    {
                    }
                    column(LineAmountInvDiscountAmountAmountIncludingVATCaption; LineAmountInvDiscountAmountAmountIncludingVATCaptionLbl)
                    {
                    }
                    column(CompanyInfoBankName; CompanyBankAccount.Name)
                    {
                    }
                    column(CompanyInfoBankAccNo; CompanyBankAccount."Bank Account No.")
                    {
                    }
                    column(BilltoCustNo_ServCrMemoHdr; "Service Cr.Memo Header"."Bill-to Customer No.")
                    {
                    }
                    column(PostingDate_ServCrMemoHdr; Format("Service Cr.Memo Header"."Posting Date"))
                    {
                    }
                    column(VATNoText; VATNoText)
                    {
                    }
                    column(VATRegNo_ServCrMemoHdr; "Service Cr.Memo Header"."VAT Registration No.")
                    {
                    }
                    column(No1_ServCrMemoHdr; "Service Cr.Memo Header"."No.")
                    {
                    }
                    column(SalesPersonText; SalesPersonText)
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(AppliedToText; AppliedToText)
                    {
                    }
                    column(ReferenceText; ReferenceText)
                    {
                    }
                    column(YourRef_ServCrMemoHdr; "Service Cr.Memo Header"."Your Reference")
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
                    column(CompanyAddr7; CompanyAddr[7])
                    {
                    }
                    column(CompanyAddr8; CompanyAddr[8])
                    {
                    }
                    column(DocDate_ServCrMemoHdr; Format("Service Cr.Memo Header"."Document Date"))
                    {
                    }
                    column(PricesInclVAT_ServCrMemoHdr; "Service Cr.Memo Header"."Prices Including VAT")
                    {
                    }
                    column(PageCaption; StrSubstNo(Text006, ''))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PricInclVATFmt_ServCrMemoHdr; Format("Service Cr.Memo Header"."Prices Including VAT"))
                    {
                    }
                    column(CorrectInvNo_ServCrMemoHdr; "Service Cr.Memo Header"."Corrected Invoice No.")
                    {
                    }
                    column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoFaxNoCaption; CompanyInfoFaxNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoVATRegistrationNoCaption; CompanyInfoVATRegistrationNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoGiroNoCaption; CompanyInfoGiroNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoBankNameCaption; CompanyInfoBankNameCaptionLbl)
                    {
                    }
                    column(CompanyInfoBankAccountNoCaption; CompanyInfoBankAccountNoCaptionLbl)
                    {
                    }
                    column(ServiceCrMemoHeaderNoCaption; ServiceCrMemoHeaderNoCaptionLbl)
                    {
                    }
                    column(ServiceCrMemoHeaderPostingDateCaption; ServiceCrMemoHeaderPostingDateCaptionLbl)
                    {
                    }
                    column(CorrectedInvoiceNoCaption; CorrectedInvoiceNoCaptionLbl)
                    {
                    }
                    column(BilltoCustNo_ServCrMemoHdrCaption; "Service Cr.Memo Header".FieldCaption("Bill-to Customer No."))
                    {
                    }
                    column(PricesInclVAT_ServCrMemoHdrCaption; "Service Cr.Memo Header".FieldCaption("Prices Including VAT"))
                    {
                    }
                    column(CACCaption; CACCaptionLbl)
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Service Cr.Memo Header";
                        DataItemTableView = sorting(Number);
                        column(DimText; DimText)
                        {
                        }
                        column(Number_Integer; Number)
                        {
                        }
                        column(HeaderDimensionsCaption; HeaderDimensionsCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            DimText := DimTxtArr[Number];
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInternalInfo then
                                CurrReport.Break();
                            FindDimTxt("Service Cr.Memo Header"."Dimension Set ID");
                            SetRange(Number, 1, DimTxtArrLength);
                        end;
                    }
                    dataitem("Service Cr.Memo Line"; "Service Cr.Memo Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Service Cr.Memo Header";
                        DataItemTableView = sorting("Document No.", "Line No.");
                        column(TypeInt; TypeInt)
                        {
                        }
                        column(TotalAmt; TotalAmount)
                        {
                        }
                        column(TotalAmtInclVAT; TotalAmountInclVAT)
                        {
                        }
                        column(TotalInvDiscAmt; TotalInvDiscAmount)
                        {
                        }
                        column(LineNo_ServCrMemoLine; "Service Cr.Memo Line"."Line No.")
                        {
                        }
                        column(VATBaseDisc_ServCrMemoHdr; "Service Cr.Memo Header"."VAT Base Discount %")
                        {
                        }
                        column(TotalLineAmt; TotalLineAmount)
                        {
                        }
                        column(TypeNo; TypeNo)
                        {
                        }
                        column(TotalPmt; TotalPmtDiscAmount)
                        {
                        }
                        column(LineAmt_ServCrMemoLine; "Line Amount")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Desc_ServCrMemoLine; Description)
                        {
                        }
                        column(No_ServCrMemoLine; "No.")
                        {
                        }
                        column(No_ServCrMemoLineCaption; FieldCaption("No."))
                        {
                        }
                        column(Quantity_ServCrMemoLine; Quantity)
                        {
                        }
                        column(UnitofMeasure_ServCrMemoLine; "Unit of Measure")
                        {
                        }
                        column(UnitPrice_ServCrMemoLine; "Unit Price")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 2;
                        }
                        column(LineDisc_ServCrMemoLine; "Line Discount %")
                        {
                        }
                        column(VATIdentifier_ServCrMemoLine; "VAT Identifier")
                        {
                        }
                        column(PostedRcptDate; Format(PostedReceiptDate))
                        {
                        }
                        column(InvDiscountAmount; -"Inv. Discount Amount")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Amount_ServCrMemoLine; -"Pmt. Discount Amount")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(AmtInclVAT_ServCrMemoLine; "Amount Including VAT")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AmtIncludingVATAmt; "Amount Including VAT" - Amount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATAmtText_VATAmtLine; TempVATAmountLine.VATAmountText())
                        {
                        }
                        column(Amt_ServCrMemoLine; Amount)
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(LineAmntInvDiscAmtAmtInclVAT; -("Line Amount" - "Inv. Discount Amount" - "Pmt. Discount Amount" - "Amount Including VAT"))
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(Desc_ServCrMemoLineCaption; FieldCaption(Description))
                        {
                        }
                        column(Quantity_ServCrMemoLineCaption; FieldCaption(Quantity))
                        {
                        }
                        column(UnitofMeasure_ServCrMemoLineCaption; FieldCaption("Unit of Measure"))
                        {
                        }
                        column(VATIdentifier_ServCrMemoLineCaption; FieldCaption("VAT Identifier"))
                        {
                        }
                        dataitem("Service Shipment Buffer"; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(ServShipBufferPostingDate; Format(TempServiceShipmentBuffer."Posting Date"))
                            {
                            }
                            column(ServiceShipmentBufferQuantity; TempServiceShipmentBuffer.Quantity)
                            {
                                DecimalPlaces = 0 : 5;
                            }
                            column(ReturnReceiptCaption; ReturnReceiptCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then
                                    TempServiceShipmentBuffer.Find('-')
                                else
                                    TempServiceShipmentBuffer.Next();
                            end;

                            trigger OnPreDataItem()
                            begin
                                SetRange(Number, 1, TempServiceShipmentBuffer.Count);
                            end;
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(DimText1; DimText)
                            {
                            }
                            column(LineDimensionsCaption; LineDimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                DimText := DimTxtArr[Number];
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfo then
                                    CurrReport.Break();

                                FindDimTxt("Service Cr.Memo Line"."Dimension Set ID");
                                SetRange(Number, 1, DimTxtArrLength);
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempServiceShipmentBuffer.DeleteAll();
                            PostedReceiptDate := 0D;
                            if Quantity <> 0 then
                                PostedReceiptDate := FindPostedShipmentDate();

                            if (Type = Type::"G/L Account") and not ShowInternalInfo then
                                "No." := '';

                            if VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then begin
                                TempVATAmountLine.Init();
                                TempVATAmountLine."VAT Identifier" := "VAT Identifier";
                                TempVATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                                TempVATAmountLine."Tax Group Code" := "Tax Group Code";
                                TempVATAmountLine."VAT %" := VATPostingSetup."VAT %";
                                TempVATAmountLine."EC %" := VATPostingSetup."EC %";
                                TempVATAmountLine."VAT Base" := Amount;
                                TempVATAmountLine."Amount Including VAT" := "Amount Including VAT";
                                TempVATAmountLine."Line Amount" := "Line Amount";
                                TempVATAmountLine."Pmt. Discount Amount" := "Pmt. Discount Amount";
                                TempVATAmountLine.SetCurrencyCode("Service Cr.Memo Header"."Currency Code");
                                if "Allow Invoice Disc." then
                                    TempVATAmountLine."Inv. Disc. Base Amount" := "Line Amount";
                                TempVATAmountLine."Invoice Discount Amount" := "Inv. Discount Amount";
                                TempVATAmountLine."VAT Difference" := "VAT Difference";
                                TempVATAmountLine."EC Difference" := "EC Difference";
                                if "Service Cr.Memo Header"."Prices Including VAT" then
                                    TempVATAmountLine."Prices Including VAT" := true;
                                TempVATAmountLine."VAT Clause Code" := "VAT Clause Code";
                                TempVATAmountLine.InsertLine();

                                TotalAmount += Amount;
                                TotalAmountInclVAT += "Amount Including VAT";
                                TotalInvDiscAmount += "Inv. Discount Amount";
                                TotalLineAmount += "Line Amount";
                                TypeInt := Type.AsInteger();
                                TypeNo := TempVATAmountLine."VAT Calculation Type".AsInteger();
                                TotalPmtDiscAmount += "Pmt. Discount Amount";
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            TempVATAmountLine.DeleteAll();
                            TempServiceShipmentBuffer.Reset();
                            TempServiceShipmentBuffer.DeleteAll();
                            FirstValueEntryNo := 0;
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("No." = '') and (Quantity = 0) and (Amount = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SetRange("Line No.", 0, "Line No.");

                            TotalAmount := 0;
                            TotalAmountInclVAT := 0;
                            TotalInvDiscAmount := 0;
                            TotalLineAmount := 0;
                            TotalPmtDiscAmount := 0;
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(VATAmtLineVATBase; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVATAmt; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineLineAmt; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscBaseAmt; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscAmt; TempVATAmountLine."Invoice Discount Amount" + TempVATAmountLine."Pmt. Discount Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineECAmt; TempVATAmountLine."EC Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVAT; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmtLineInvDisAmt1; TempVATAmountLine."Invoice Discount Amount" + TempVATAmountLine."Pmt. Discount Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVATIdentifier; TempVATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATAmtLineEC; TempVATAmountLine."EC %")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineVATCaption; VATAmountLineVATCaptionLbl)
                        {
                        }
                        column(VATAmountLineVATBaseCaption; VATAmountLineVATBaseCaptionLbl)
                        {
                        }
                        column(VATAmountLineVATAmountCaption; VATAmountLineVATAmountCaptionLbl)
                        {
                        }
                        column(VATAmountSpecificationCaption; VATAmountSpecificationCaptionLbl)
                        {
                        }
                        column(VATAmountLineVATIdentifierCaption; VATAmountLineVATIdentifierCaptionLbl)
                        {
                        }
                        column(VATAmountLineInvDiscBaseCaption; VATAmountLineInvDiscBaseCaptionLbl)
                        {
                        }
                        column(VATAmountLineLineAmountCaption; VATAmountLineLineAmountCaptionLbl)
                        {
                        }
                        column(VATAmountLineInvoiceDiscountAmountCaption; VATAmountLineInvoiceDiscountAmountCaptionLbl)
                        {
                        }
                        column(ECAmountCaption; ECAmountCaptionLbl)
                        {
                        }
                        column(ECCaption; ECCaptionLbl)
                        {
                        }
                        column(VATAmountLineVATBase1Caption; VATAmountLineVATBase1CaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempVATAmountLine.GetLine(Number);

                            if TempVATAmountLine."VAT Amount" = 0 then
                                TempVATAmountLine."VAT %" := 0;
                            if TempVATAmountLine."EC Amount" = 0 then
                                TempVATAmountLine."EC %" := 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if TempVATAmountLine.GetTotalVATAmount() = 0 then
                                CurrReport.Break();
                            SetRange(Number, 1, TempVATAmountLine.Count);
                        end;
                    }
                    dataitem(VATClauseEntryCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(VATClauseVATIdentifier; TempVATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATClauseCode; TempVATAmountLine."VAT Clause Code")
                        {
                        }
                        column(VATClauseDescription; VATClauseText)
                        {
                        }
                        column(VATClauseDescription2; VATClause."Description 2")
                        {
                        }
                        column(VATClauseAmount; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATClausesCaption; VATClausesCap)
                        {
                        }
                        column(VATClauseVATIdentifierCaption; VATAmountLineVATIdentifierCaptionLbl)
                        {
                        }
                        column(VATClauseVATAmtCaption; VATAmountLineVATAmountCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempVATAmountLine.GetLine(Number);
                            if not VATClause.Get(TempVATAmountLine."VAT Clause Code") then
                                CurrReport.Skip();
                            VATClauseText := VATClause.GetDescriptionText("Service Cr.Memo Header");
                        end;

                        trigger OnPreDataItem()
                        begin
                            Clear(VATClause);
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
                        column(CustNo_ServCrMemoHdr; "Service Cr.Memo Header"."Customer No.")
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
                        column(CustNo_ServCrMemoHdrCaption; "Service Cr.Memo Header".FieldCaption("Customer No."))
                        {
                        }
                        column(ShipToPhoneNo; "Service Cr.Memo Header"."Ship-to Phone")
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
                    if Number > 1 then begin
                        CopyText := Text004;
                        OutputNo += 1;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode() then
                        CODEUNIT.Run(CODEUNIT::"Service Cr. Memo-Printed", "Service Cr.Memo Header");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");

                FormatAddressFields("Service Cr.Memo Header");
                FormatDocumentFields("Service Cr.Memo Header");

                if not CompanyBankAccount.Get("Service Cr.Memo Header"."Company Bank Account Code") then
                    CompanyBankAccount.CopyBankFieldsFromCompanyInfo(CompanyInfo);

                ShowCashAccountingCriteria("Service Cr.Memo Header");
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service - Credit Memo';
        AboutText = 'Generate a service credit memo that you can send to your customer.';
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
                        ApplicationArea = Service;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = Service;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want the printed report to show information that is only for internal use.';
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

    trigger OnInitReport()
    begin
        GLSetup.Get();
        CompanyInfo.Get();
        ServiceSetup.Get();

        case ServiceSetup."Logo Position on Documents" of
            ServiceSetup."Logo Position on Documents"::"No Logo":
                ;
            ServiceSetup."Logo Position on Documents"::Left:
                CompanyInfo.CalcFields(Picture);
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
    end;

    var
        GLSetup: Record "General Ledger Setup";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyBankAccount: Record "Bank Account";
        ServiceSetup: Record "Service Mgt. Setup";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        VATClause: Record "VAT Clause";
        DimSetEntry: Record "Dimension Set Entry";
        TempServiceShipmentBuffer: Record "Service Shipment Buffer" temporary;
        RespCenter: Record "Responsibility Center";
        VATPostingSetup: Record "VAT Posting Setup";
        LanguageMgt: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        SalesPersonText: Text[50];
        VATNoText: Text[80];
        ReferenceText: Text[80];
        AppliedToText: Text;
        TotalText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
        VATClauseText: Text;
        MoreLines: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        OutputNo: Integer;
        TypeInt: Integer;
        CopyText: Text[30];
        ShowShippingAddr: Boolean;
        DimText: Text[120];
        ShowInternalInfo: Boolean;
        FirstValueEntryNo: Integer;
        PostedReceiptDate: Date;
        NextEntryNo: Integer;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalInvDiscAmount: Decimal;
        TotalLineAmount: Decimal;
        DimTxtArrLength: Integer;
        DimTxtArr: array[500] of Text[50];
        SubtotalCaptionLbl: Label 'Subtotal';
        TypeNo: Integer;
        TotalPmtDiscAmount: Decimal;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label '(Applies to %1 %2)';
#pragma warning restore AA0470
        Text004: Label 'COPY';
#pragma warning disable AA0470
        Text006: Label 'Page %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        UnitPriceCaptionLbl: Label 'Unit Price';
        AmountCaptionLbl: Label 'Amount';
        PostedReceiptDateCaptionLbl: Label 'Posted Return Receipt Date';
        ServiceCrMemoLineLineDiscountCaptionLbl: Label 'Disc. %';
        Text1100001: Label 'Sales - Corrective invoice %1';
        InvDiscountAmountCaptionLbl: Label 'Invoice Discount Amount';
        TotalTextLbl: Label 'Payment Discount Received Amount';
        LineAmountInvDiscountAmountAmountIncludingVATCaptionLbl: Label 'Payment Discount on VAT';
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoFaxNoCaptionLbl: Label 'Fax No.';
        CompanyInfoVATRegistrationNoCaptionLbl: Label 'VAT Reg. No.';
        CompanyInfoGiroNoCaptionLbl: Label 'Giro No.';
        CompanyInfoBankNameCaptionLbl: Label 'Bank';
        CompanyInfoBankAccountNoCaptionLbl: Label 'Account No.';
        ServiceCrMemoHeaderNoCaptionLbl: Label 'Credit Memo No.';
        ServiceCrMemoHeaderPostingDateCaptionLbl: Label 'Posting Date';
        CorrectedInvoiceNoCaptionLbl: Label 'Corrected Invoice No.';
        HeaderDimensionsCaptionLbl: Label 'Header Dimensions';
        ReturnReceiptCaptionLbl: Label 'Return Receipt';
        LineDimensionsCaptionLbl: Label 'Line Dimensions';
#pragma warning disable AA0074
        VATClausesCap: Label 'VAT Clause';
#pragma warning restore AA0074
        VATAmountLineVATCaptionLbl: Label 'VAT %';
        VATAmountLineVATBaseCaptionLbl: Label 'VAT Base';
        VATAmountLineVATAmountCaptionLbl: Label 'VAT Amount';
        VATAmountSpecificationCaptionLbl: Label 'VAT Amount Specification';
        VATAmountLineVATIdentifierCaptionLbl: Label 'VAT Identifier';
        VATAmountLineInvDiscBaseCaptionLbl: Label 'Invoice Discount Base Amount';
        VATAmountLineLineAmountCaptionLbl: Label 'Line Amount';
        VATAmountLineInvoiceDiscountAmountCaptionLbl: Label 'Invoice and Payment Discounts';
        ECAmountCaptionLbl: Label 'EC Amount';
        ECCaptionLbl: Label 'EC %';
        VATAmountLineVATBase1CaptionLbl: Label 'Total';
        ShiptoAddressCaptionLbl: Label 'Ship-to Address';
        DocumentDateCaptionLbl: Label 'Document Date';
        CACCaptionLbl: Text;
        CACTxt: Label 'Régimen especial del criterio de caja', Locked = true;

    protected var
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";

    procedure FindPostedShipmentDate(): Date
    var
        TempServiceShipmentBuffer2: Record "Service Shipment Buffer" temporary;
    begin
        NextEntryNo := 1;

        case "Service Cr.Memo Line".Type of
            "Service Cr.Memo Line".Type::Item:
                GenerateBufferFromValueEntry("Service Cr.Memo Line");
            "Service Cr.Memo Line".Type::" ":
                exit(0D);
        end;

        TempServiceShipmentBuffer.Reset();
        TempServiceShipmentBuffer.SetRange("Document No.", "Service Cr.Memo Line"."Document No.");
        TempServiceShipmentBuffer.SetRange("Line No.", "Service Cr.Memo Line"."Line No.");

        if TempServiceShipmentBuffer.Find('-') then begin
            TempServiceShipmentBuffer2 := TempServiceShipmentBuffer;
            if TempServiceShipmentBuffer.Next() = 0 then begin
                TempServiceShipmentBuffer.Get(
                    TempServiceShipmentBuffer2."Document No.", TempServiceShipmentBuffer2."Line No.", TempServiceShipmentBuffer2."Entry No.");
                TempServiceShipmentBuffer.Delete();
                exit(TempServiceShipmentBuffer2."Posting Date");
            end;
            TempServiceShipmentBuffer.CalcSums(Quantity);
            if TempServiceShipmentBuffer.Quantity <> "Service Cr.Memo Line".Quantity then begin
                TempServiceShipmentBuffer.DeleteAll();
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
        TempServiceShipmentBuffer.SetRange("Document No.", ServiceCrMemoLine."Document No.");
        TempServiceShipmentBuffer.SetRange("Line No.", ServiceCrMemoLine."Line No.");
        TempServiceShipmentBuffer.SetRange("Posting Date", PostingDate);
        if TempServiceShipmentBuffer.Find('-') then begin
            TempServiceShipmentBuffer.Quantity := TempServiceShipmentBuffer.Quantity - QtyOnShipment;
            TempServiceShipmentBuffer.Modify();
            exit;
        end;

        TempServiceShipmentBuffer.Init();
        TempServiceShipmentBuffer."Document No." := ServiceCrMemoLine."Document No.";
        TempServiceShipmentBuffer."Line No." := ServiceCrMemoLine."Line No.";
        TempServiceShipmentBuffer."Entry No." := NextEntryNo;
        TempServiceShipmentBuffer.Type := ServiceCrMemoLine.Type;
        TempServiceShipmentBuffer."No." := ServiceCrMemoLine."No.";
        TempServiceShipmentBuffer.Quantity := -QtyOnShipment;
        TempServiceShipmentBuffer."Posting Date" := PostingDate;
        TempServiceShipmentBuffer.Insert();
        NextEntryNo := NextEntryNo + 1
    end;

    procedure FindDimTxt(DimSetID: Integer)
    var
        Separation: Text[5];
        i: Integer;
        TxtToAdd: Text[120];
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

    [Scope('OnPrem')]
    procedure ShowCashAccountingCriteria(ServiceCrMemoHeader: Record "Service Cr.Memo Header"): Text
    var
        VATEntry: Record "VAT Entry";
    begin
        GLSetup.Get();
        if not GLSetup."Unrealized VAT" then
            exit;
        CACCaptionLbl := '';
        VATEntry.SetRange("Document No.", ServiceCrMemoHeader."No.");
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::"Credit Memo");
        if VATEntry.FindSet() then
            repeat
                if VATEntry."VAT Cash Regime" then
                    CACCaptionLbl := CACTxt;
            until (VATEntry.Next() = 0) or (CACCaptionLbl <> '');
        exit(CACCaptionLbl);
    end;

    procedure InitializeRequest(NewShowInternalInfo: Boolean)
    begin
        ShowInternalInfo := NewShowInternalInfo;
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure FormatAddressFields(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        ServiceFormatAddress: Codeunit "Service Format Address";
    begin
        FormatAddr.GetCompanyAddr(ServiceCrMemoHeader."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        ServiceFormatAddress.ServiceCrMemoBillTo(CustAddr, ServiceCrMemoHeader);
        ShowShippingAddr := ServiceFormatAddress.ServiceCrMemoShipTo(ShipToAddr, CustAddr, ServiceCrMemoHeader);
    end;

    local procedure FormatDocumentFields(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        FormatDocument.SetTotalLabels(ServiceCrMemoHeader."Currency Code", TotalText, TotalInclVATText, TotalExclVATText);
        FormatDocument.SetSalesPerson(SalesPurchPerson, ServiceCrMemoHeader."Salesperson Code", SalesPersonText);

        ReferenceText := FormatDocument.SetText(ServiceCrMemoHeader."Your Reference" <> '', ServiceCrMemoHeader.FieldCaption("Your Reference"));
        VATNoText := FormatDocument.SetText(ServiceCrMemoHeader."VAT Registration No." <> '', ServiceCrMemoHeader.FieldCaption("VAT Registration No."));
        AppliedToText :=
          FormatDocument.SetText(
            ServiceCrMemoHeader."Applies-to Doc. No." <> '', Format(StrSubstNo(Text003, Format(ServiceCrMemoHeader."Applies-to Doc. Type"), ServiceCrMemoHeader."Applies-to Doc. No.")));
    end;
}

