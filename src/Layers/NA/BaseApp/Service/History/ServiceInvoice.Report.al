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
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Service.Item;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Utilities;

report 5911 "Service - Invoice"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/History/ServiceInvoice.rdlc';
    Caption = 'Service - Invoice';
    Permissions = TableData "Sales Shipment Buffer" = rimd;
    WordMergeDataItem = "Service Invoice Header";

    dataset
    {
        dataitem("Service Invoice Header"; "Service Invoice Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Customer No.", "No. Printed";
            RequestFilterHeading = 'Posted Service Invoice';
            column(No_ServiceInvHeader; "No.")
            {
            }
            column(DisplayAdditionalFeeNote; DisplayAdditionalFeeNote)
            {
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
                    column(CompanyInfo1Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(CompanyInfoPicture; CompanyInfo.Picture)
                    {
                    }
                    column(CompanyInfo3Picture; CompanyInfo3.Picture)
                    {
                    }
                    column(ReportTitleCopyText; StrSubstNo(DocumentCaption(), CopyText))
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
                    column(CompanyInfoVATRegistrationNo; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(CompanyInfoGiroNo; CompanyInfo."Giro No.")
                    {
                    }
                    column(CompanyInfoBankName; CompanyBankAccount.Name)
                    {
                    }
                    column(CompanyInfoBankAccountNo; CompanyBankAccount."Bank Account No.")
                    {
                    }
                    column(BilltoCustNo_ServiceInvHdr; "Service Invoice Header"."Bill-to Customer No.")
                    {
                    }
                    column(PostingDate_ServiceInvHdr; Format("Service Invoice Header"."Posting Date"))
                    {
                    }
                    column(VATNoText; VATNoText)
                    {
                    }
                    column(VATRegNo_ServiceInvHdr; "Service Invoice Header"."VAT Registration No.")
                    {
                    }
                    column(DueDate_ServiceInvHdr; Format("Service Invoice Header"."Due Date"))
                    {
                    }
                    column(SalesPersonText; SalesPersonText)
                    {
                    }
                    column(Name_SalesPurchPerson; SalesPurchPerson.Name)
                    {
                    }
                    column(ReferenceText; ReferenceText)
                    {
                    }
                    column(YourReference_ServiceInvHdr; "Service Invoice Header"."Your Reference")
                    {
                    }
                    column(OrderNoText; OrderNoText)
                    {
                    }
                    column(OrderNo_ServiceInvHdr; "Service Invoice Header"."Order No.")
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
                    column(DocDate_ServiceInvHdr; Format("Service Invoice Header"."Document Date", 0, 4))
                    {
                    }
                    column(PricesIncVAT_ServiceInvHdr; "Service Invoice Header"."Prices Including VAT")
                    {
                    }
                    column(PageCaption; StrSubstNo(Text005, ''))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PricesIncVATFormat_ServInvHdr; Format("Service Invoice Header"."Prices Including VAT"))
                    {
                    }
                    column(TaxIdentificationType_Cust; Format(Cust."Tax Identification Type"))
                    {
                    }
                    column(CompanyInfoPhoneNoCaption; Text007)
                    {
                    }
                    column(CompanyInfoFaxNoCaption; Text008)
                    {
                    }
                    column(CompanyInfoVATRegNoCaption; Text009)
                    {
                    }
                    column(CompanyInfoGiroNoCaption; Text010)
                    {
                    }
                    column(CompanyInfoBankNameCaption; Text011)
                    {
                    }
                    column(CompanyInfoBankAccNoCaption; Text012)
                    {
                    }
                    column(ServiceInvHdrDueDtCaption; Text013)
                    {
                    }
                    column(InvoiceNoCaption; Text014)
                    {
                    }
                    column(ServiceInvHdrPostDtCaption; Text015)
                    {
                    }
                    column(TaxIdentTypeCaption; Text016)
                    {
                    }
                    column(UnitPriceCaption; Text018)
                    {
                    }
                    column(PostedShipmentDateCaption; Text021)
                    {
                    }
                    column(SerInvLineLineDisCaption; Text019)
                    {
                    }
                    column(AmountCaption; Text020)
                    {
                    }
                    column(BilltoCustNo_ServiceInvHdrCaption; "Service Invoice Header".FieldCaption("Bill-to Customer No."))
                    {
                    }
                    column(PricesIncVAT_ServiceInvHdrCaption; "Service Invoice Header".FieldCaption("Prices Including VAT"))
                    {
                    }
                    column(CompanyBankBranchNo; CompanyBankAccount."Bank Branch No.")
                    {
                    }
                    column(CompanyBankBranchNo_Lbl; CompanyBankAccount.FieldCaption("Bank Branch No."))
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Service Invoice Header";
                        DataItemTableView = sorting(Number);
                        column(DimText; DimText)
                        {
                        }
                        column(DimensionLoop1Number; Number)
                        {
                        }
                        column(HeaderDimensionsCaption; Text017)
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
                            FindDimTxt("Service Invoice Header"."Dimension Set ID");
                            SetRange(Number, 1, DimTxtArrLength);
                        end;
                    }
                    dataitem("Service Invoice Line"; "Service Invoice Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Service Invoice Header";
                        DataItemTableView = sorting("Document No.", "Service Item Line No.");
                        column(TypeInt; TypeInt)
                        {
                        }
                        column(VATBaseDisc_ServInvHdr; "Service Invoice Header"."VAT Base Discount %")
                        {
                        }
                        column(TotalLineAmount; TotalLineAmount)
                        {
                        }
                        column(TotalAmount; TotalAmount)
                        {
                        }
                        column(TotalAmountInclVAT; TotalAmountInclVAT)
                        {
                        }
                        column(TotalInvDiscAmount; TotalInvDiscAmount)
                        {
                        }
                        column(LineNo_ServInvLine; "Line No.")
                        {
                        }
                        column(ServiceInvoiceLineLineAmount; "Line Amount")
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Description_ServiceInvLine; Description)
                        {
                        }
                        column(No_ServiceInvLine; "No.")
                        {
                        }
                        column(SerialNo_ServiceItem; ServiceItemSerialNo)
                        {
                        }
                        column(Quantity_ServiceInvLine; Quantity)
                        {
                        }
                        column(UnitofMeasure_ServiceInvLine; "Unit of Measure")
                        {
                        }
                        column(UnitPrice_ServiceInvLine; "Unit Price")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 2;
                        }
                        column(LineDiscount_ServiceInvLine; "Line Discount %")
                        {
                        }
                        column(VATIdentifier_ServiceInvLine; "VAT Identifier")
                        {
                        }
                        column(PostedShipmentDate; Format(PostedShipmentDate))
                        {
                        }
                        column(InvDiscountAmount; -"Inv. Discount Amount")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(LineAmt_ServInvLine; Amount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AmtInclVATAmount; "Amount Including VAT" - Amount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AmtInclVAT_ServInvLine; "Amount Including VAT")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(ServiceInvLineNoCaption; FieldCaption("No."))
                        {
                        }
                        column(VATAmountLineVATAmountText; TempVATAmountLine.VATAmountText())
                        {
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(PaymentDiscVAT_ServiceInvLine; -("Line Amount" - "Inv. Discount Amount" - "Amount Including VAT"))
                        {
                            AutoFormatExpression = "Service Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(InvDiscountAmountCaption; Text022)
                        {
                        }
                        column(SubtotalCaption; Text023)
                        {
                        }
                        column(PaymentDiscVATCaption; Text024)
                        {
                        }
                        column(SerialNo_ServiceItemCaption; SerialNoCaptionLbl)
                        {
                        }
                        column(Description_ServiceInvLineCaption; FieldCaption(Description))
                        {
                        }
                        column(Quantity_ServiceInvLineCaption; QuantityCaptionLbl)
                        {
                        }
                        column(UnitofMeasure_ServiceInvLineCaption; FieldCaption("Unit of Measure"))
                        {
                        }
                        column(VATIdentifier_ServiceInvLineCaption; FieldCaption("VAT Identifier"))
                        {
                        }
                        dataitem("Service Shipment Buffer"; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(PostingDate_ServiceShiptBuffer; Format(TempServiceShipmentBuffer."Posting Date"))
                            {
                            }
                            column(Quantity_ServiceShiptBuffer; TempServiceShipmentBuffer.Quantity)
                            {
                                DecimalPlaces = 0 : 5;
                            }
                            column(ShipmentCaption; Text025)
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
                                TempServiceShipmentBuffer.SetRange("Document No.", "Service Invoice Line"."Document No.");
                                TempServiceShipmentBuffer.SetRange("Line No.", "Service Invoice Line"."Line No.");

                                SetRange(Number, 1, TempServiceShipmentBuffer.Count);
                            end;
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(DimText1; DimText)
                            {
                            }
                            column(LineDimensionsCaption; Text026)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number <= DimTxtArrLength then
                                    DimText := DimTxtArr[Number]
                                else
                                    DimText := Format("Service Invoice Line".Type) + ' ' + AccNo;
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfo then
                                    CurrReport.Break();

                                FindDimTxt("Service Invoice Line"."Dimension Set ID");
                                if IsServiceContractLine then
                                    SetRange(Number, 1, DimTxtArrLength + 1)
                                else
                                    SetRange(Number, 1, DimTxtArrLength);
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            PostedShipmentDate := 0D;
                            AccNo := '';
                            ServiceItemSerialNo := '';

                            if Quantity <> 0 then
                                PostedShipmentDate := FindPostedShipmentDate();

                            IsServiceContractLine := (Type = Type::"G/L Account") and ("Service Item No." <> '') and ("Contract No." <> '');
                            if IsServiceContractLine then begin
                                AccNo := "No.";
                                "No." := "Service Item No.";
                                ServiceItemSerialNo := GetServiceItemSerialNo("Service Item No.");
                            end else
                                ServiceItemSerialNo := "Service Item Serial No.";

                            TempVATAmountLine.Init();
                            TempVATAmountLine."VAT Identifier" := "VAT Identifier";
                            TempVATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                            TempVATAmountLine."Tax Group Code" := "Tax Group Code";
                            TempVATAmountLine."VAT %" := "VAT %";
                            TempVATAmountLine."VAT Base" := Amount;
                            TempVATAmountLine."Amount Including VAT" := "Amount Including VAT";
                            TempVATAmountLine."Line Amount" := "Line Amount";
                            if "Allow Invoice Disc." then
                                TempVATAmountLine."Inv. Disc. Base Amount" := "Line Amount";
                            TempVATAmountLine."Invoice Discount Amount" := "Inv. Discount Amount";
                            TempVATAmountLine.InsertLine();

                            TotalLineAmount += "Line Amount";
                            TotalAmount += Amount;
                            TotalAmountInclVAT += "Amount Including VAT";
                            TotalInvDiscAmount += "Inv. Discount Amount";
                            TypeInt := Type.AsInteger();
                        end;

                        trigger OnPreDataItem()
                        begin
                            TempVATAmountLine.DeleteAll();
                            TempServiceShipmentBuffer.Reset();
                            TempServiceShipmentBuffer.DeleteAll();
                            FirstValueEntryNo := 0;
                            if not FindLastMeaningfulLine("Service Invoice Line") then
                                CurrReport.Break();
                            SetRange("Line No.", 0, "Line No.");

                            TotalLineAmount := 0;
                            TotalAmount := 0;
                            TotalAmountInclVAT := 0;
                            TotalInvDiscAmount := 0;
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(VATBase_VATAmountLine; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATAmount_VATAmountLine; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(LineAmount_VATAmountLine; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Service Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(InvDiscBaseAmount_VATAmountLine; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Service Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(InvoiceDisAmt_VATAmountLine; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Service Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VAT_VATAmountLine; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATIdentifier_VATAmountLine; TempVATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATAmountLineVATCaption; Text027)
                        {
                        }
                        column(VATAmountLineVATBaseCaption; Text028)
                        {
                        }
                        column(VATAmountLineVATAmtCaption; Text029)
                        {
                        }
                        column(VATAmountSpecCaption; Text030)
                        {
                        }
                        column(VATAmtLineVATIdentCaption; Text031)
                        {
                        }
                        column(InvDiscBaseAmtCaption; Text032)
                        {
                        }
                        column(VATAmtLineLineAmtCaption; Text033)
                        {
                        }
                        column(VATAmtLineInvDisAmtCaption; Text034)
                        {
                        }
                        column(VATAmtLineVATBaseCaption; Text035)
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
                        column(Description_PaymentTerms; PaymentTerms.Description)
                        {
                        }
                        column(PaymentTermsDescCaption; Text036)
                        {
                        }
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(CustomerNo_ServiceInvHdr; "Service Invoice Header"."Customer No.")
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
                        column(ShiptoAddressCaption; Text037)
                        {
                        }
                        column(CustomerNo_ServiceInvHdrCaption; "Service Invoice Header".FieldCaption("Customer No."))
                        {
                        }
                        column(ShipToPhoneNo; "Service Invoice Header"."Ship-to Phone")
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if not ShowShippingAddr then
                                CurrReport.Break();
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
                    if Number > 1 then begin
                        CopyText := FormatDocument.GetCOPYText();
                        OutputNo += 1;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode() then
                        CODEUNIT.Run(CODEUNIT::"Service Inv.-Printed", "Service Invoice Header");
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
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");

                FormatAddressFields("Service Invoice Header");
                FormatDocumentFields("Service Invoice Header");

                if not CompanyBankAccount.Get("Service Invoice Header"."Company Bank Account Code") then
                    CompanyBankAccount.CopyBankFieldsFromCompanyInfo(CompanyInfo);

                if not Cust.Get("Bill-to Customer No.") then
                    Clear(Cust);

                GetLineFeeNoteOnReportHist("No.");
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service - Invoice';
        AboutText = 'Generate a service invoice that you can send to your customer.';
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

    trigger OnInitReport()
    begin
        GLSetup.Get();
        CompanyInfo.Get();
        ServiceSetup.Get();
        FormatDocument.SetLogoPosition(ServiceSetup."Logo Position on Documents", CompanyInfo1, CompanyInfo2, CompanyInfo3);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        PaymentTerms: Record "Payment Terms";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyBankAccount: Record "Bank Account";
        ServiceSetup: Record "Service Mgt. Setup";
        Cust: Record Customer;
        DimSetEntry: Record "Dimension Set Entry";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        RespCenter: Record "Responsibility Center";
        TempServiceShipmentBuffer: Record "Service Shipment Buffer" temporary;
        TempLineFeeNoteOnReportHist: Record "Line Fee Note on Report Hist." temporary;
        LanguageMgt: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        PostedShipmentDate: Date;
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        OrderNoText: Text[80];
        SalesPersonText: Text[50];
        VATNoText: Text[80];
        ReferenceText: Text[80];
        TotalText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        CopyText: Text[30];
        ShowShippingAddr: Boolean;
        NextEntryNo: Integer;
        FirstValueEntryNo: Integer;
        OutputNo: Integer;
        TypeInt: Integer;
        DimText: Text[120];
        ShowInternalInfo: Boolean;
        TotalLineAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalInvDiscAmount: Decimal;
        DimTxtArrLength: Integer;
        DimTxtArr: array[500] of Text[50];
        IsServiceContractLine: Boolean;
        AccNo: Code[20];
        ServiceItemSerialNo: Code[50];
        DisplayAdditionalFeeNote: Boolean;

#pragma warning disable AA0074
        Text004: Label 'Service - Invoice %1', Comment = '%1 = Document No.';
#pragma warning disable AA0470
        Text005: Label 'Page %1';
        Text007: Label 'Phone No.';
        Text008: Label 'Fax No.';
        Text009: Label 'VAT Reg. No.';
        Text010: Label 'Giro No.';
        Text011: Label 'Bank';
        Text012: Label 'Account No.';
        Text013: Label 'Due Date';
        Text014: Label 'Invoice No.';
        Text015: Label 'Posting Date';
        Text016: Label 'Tax Ident. Type';
        Text017: Label 'Header Dimensions';
        Text018: Label 'Unit Price';
        Text019: Label 'Disc. %';
        Text020: Label 'Amount';
        Text021: Label 'Posted Shipment Date';
        Text022: Label 'Inv. Discount Amount';
        Text023: Label 'Subtotal';
        Text024: Label 'Payment Discount on VAT';
        Text025: Label 'Shipment';
        Text026: Label 'Line Dimensions';
        Text027: Label 'VAT %';
        Text028: Label 'VAT Base';
        Text029: Label 'VAT Amount';
        Text030: Label 'VAT Amount Specification';
        Text031: Label 'VAT Identifier';
        Text032: Label 'Inv. Disc. Base Amount';
        Text033: Label 'Line Amount';
        Text034: Label 'Invoice Discount Amount';
        Text035: Label 'Total';
        Text036: Label 'Payment Terms';
        Text037: Label 'Ship-to Address';
#pragma warning restore AA0470
#pragma warning restore AA0074  
        QuantityCaptionLbl: Label 'Qty';
        SerialNoCaptionLbl: Label 'Serial No.';

    protected var
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CompanyInfo3: Record "Company Information";

    procedure FindPostedShipmentDate(): Date
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        TempServiceShipmentBuffer2: Record "Service Shipment Buffer" temporary;
    begin
        NextEntryNo := 1;
        if "Service Invoice Line"."Shipment No." <> '' then
            if ServiceShipmentHeader.Get("Service Invoice Line"."Shipment No.") then
                exit(ServiceShipmentHeader."Posting Date");

        if "Service Invoice Header"."Order No." = '' then
            exit("Service Invoice Header"."Posting Date");

        if "Service Invoice Line".Type = "Service Invoice Line".Type::" " then
            exit(0D);

        GenerateBufferFromShipment("Service Invoice Line");

        TempServiceShipmentBuffer.Reset();
        TempServiceShipmentBuffer.SetRange("Document No.", "Service Invoice Line"."Document No.");
        TempServiceShipmentBuffer.SetRange("Line No.", "Service Invoice Line"."Line No.");
        if TempServiceShipmentBuffer.Find('-') then begin
            TempServiceShipmentBuffer2 := TempServiceShipmentBuffer;
            if TempServiceShipmentBuffer.Next() = 0 then begin
                TempServiceShipmentBuffer.Get(
                  TempServiceShipmentBuffer2."Document No.", TempServiceShipmentBuffer2."Line No.", TempServiceShipmentBuffer2."Entry No.");
                TempServiceShipmentBuffer.Delete();
                exit(TempServiceShipmentBuffer2."Posting Date");
            end;
            TempServiceShipmentBuffer.CalcSums(Quantity);
            if TempServiceShipmentBuffer.Quantity <> "Service Invoice Line".Quantity then begin
                TempServiceShipmentBuffer.DeleteAll();
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
        TempServiceShipmentBuffer.SetRange("Document No.", ServiceInvoiceLine."Document No.");
        TempServiceShipmentBuffer.SetRange("Line No.", ServiceInvoiceLine."Line No.");
        TempServiceShipmentBuffer.SetRange("Posting Date", PostingDate);
        if TempServiceShipmentBuffer.Find('-') then begin
            TempServiceShipmentBuffer.Quantity := TempServiceShipmentBuffer.Quantity + QtyOnShipment;
            TempServiceShipmentBuffer.Modify();
            exit;
        end;

        TempServiceShipmentBuffer."Document No." := ServiceInvoiceLine."Document No.";
        TempServiceShipmentBuffer."Line No." := ServiceInvoiceLine."Line No.";
        TempServiceShipmentBuffer."Entry No." := NextEntryNo;
        TempServiceShipmentBuffer.Type := ServiceInvoiceLine.Type;
        TempServiceShipmentBuffer."No." := ServiceInvoiceLine."No.";
        TempServiceShipmentBuffer.Quantity := QtyOnShipment;
        TempServiceShipmentBuffer."Posting Date" := PostingDate;
        TempServiceShipmentBuffer.Insert();
        NextEntryNo := NextEntryNo + 1
    end;

    local procedure DocumentCaption(): Text[250]
    var
        DocCaption: Text;
    begin
        OnBeforeGetDocumentCaption("Service Invoice Header", DocCaption);
        if DocCaption <> '' then
            exit(DocCaption);
        exit(Text004);
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

    local procedure GetServiceItemSerialNo(ServiceItemNo: Code[20]): Code[50]
    var
        ServiceItem: Record "Service Item";
    begin
        if ServiceItem.Get(ServiceItemNo) then
            exit(ServiceItem."Serial No.");
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure FormatAddressFields(var ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        ServiceFormatAddress: Codeunit "Service Format Address";
    begin
        FormatAddr.GetCompanyAddr(ServiceInvoiceHeader."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        ServiceFormatAddress.ServiceInvBillTo(CustAddr, ServiceInvoiceHeader);
        ShowShippingAddr := ServiceFormatAddress.ServiceInvShipTo(ShipToAddr, CustAddr, ServiceInvoiceHeader);
    end;

    local procedure FormatDocumentFields(ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        FormatDocument.SetTotalLabels(ServiceInvoiceHeader."Currency Code", TotalText, TotalInclVATText, TotalExclVATText);
        FormatDocument.SetSalesPerson(SalesPurchPerson, ServiceInvoiceHeader."Salesperson Code", SalesPersonText);
        FormatDocument.SetPaymentTerms(PaymentTerms, ServiceInvoiceHeader."Payment Terms Code", ServiceInvoiceHeader."Language Code");

        OrderNoText := FormatDocument.SetText(ServiceInvoiceHeader."Order No." <> '', ServiceInvoiceHeader.FieldCaption("Order No."));
        ReferenceText := FormatDocument.SetText(ServiceInvoiceHeader."Your Reference" <> '', ServiceInvoiceHeader.FieldCaption("Your Reference"));
        VATNoText := FormatDocument.SetText(ServiceInvoiceHeader."VAT Registration No." <> '', ServiceInvoiceHeader.FieldCaption("VAT Registration No."));
    end;

    local procedure FindLastMeaningfulLine(var ServiceInvoiceLine: Record "Service Invoice Line") MoreLines: Boolean
    var
        ServiceInvLine: Record "Service Invoice Line";
    begin
        ServiceInvLine.Copy(ServiceInvoiceLine);
        ServiceInvLine.SetCurrentKey("Document No.", "Line No.");
        MoreLines := ServiceInvLine.Find('+');
        while MoreLines and
            (ServiceInvLine.Description = '') and (ServiceInvLine."No." = '') and
            (ServiceInvLine.Quantity = 0) and (ServiceInvLine.Amount = 0)
        do
            MoreLines := ServiceInvLine.Next(-1) <> 0;
        if MoreLines then
            ServiceInvoiceLine := ServiceInvLine;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDocumentCaption(ServiceInvoiceHeader: Record "Service Invoice Header"; var DocCaption: Text)
    begin
    end;
}

