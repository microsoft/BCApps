// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

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
using Microsoft.Service.History;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Globalization;
using System.Utilities;

report 3010534 "Service - Invoice ESR"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Local/Bank/Payment/ServiceInvoiceESR.rdlc';
    Caption = 'Service - Invoice ESR';
    Permissions = TableData "Sales Shipment Buffer" = rimd;
    UsageCategory = Documents;

    dataset
    {
        dataitem("Service Invoice Header"; "Service Invoice Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Customer No.", "No. Printed";
            RequestFilterHeading = 'Posted Service Invoice';
            column(No_ServiceInvHdr; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyInfoPicture; CompanyInfo1.Picture)
                    {
                    }
                    column(ServiceInvCopyText; StrSubstNo(Text004, CopyText))
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
                    column(CompanyInfoPhNo; CompanyInfo."Phone No.")
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
                    column(CompanyInfoBankName; CompanyBankAccount.Name)
                    {
                    }
                    column(CompanyInfoBankAccNo; CompanyBankAccount."Bank Account No.")
                    {
                    }
                    column(ServiceInvHdrBilltoCustNo; "Service Invoice Header"."Bill-to Customer No.")
                    {
                    }
                    column(ServiceInvHdrPostingDate; "Service Invoice Header"."Posting Date")
                    {
                    }
                    column(VATNoText; VATNoText)
                    {
                    }
                    column(ServiceInvHdrVATRegNo; "Service Invoice Header"."VAT Registration No.")
                    {
                    }
                    column(ServiceInvHdrDueDate; "Service Invoice Header"."Due Date")
                    {
                    }
                    column(SalesPersonText; SalesPersonText)
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(ServiceInvHdrNo; "Service Invoice Header"."No.")
                    {
                    }
                    column(ReferenceText; ReferenceText)
                    {
                    }
                    column(ServiceInvHdrYourReference; "Service Invoice Header"."Your Reference")
                    {
                    }
                    column(OrderNoText; OrderNoText)
                    {
                    }
                    column(ServiceInvHdrOrderNo; "Service Invoice Header"."Order No.")
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
                    column(DocumentDateFormatted; Format("Service Invoice Header"."Document Date", 0, 4))
                    {
                    }
                    column(ServiceInvHdrPricesIncludingVAT; "Service Invoice Header"."Prices Including VAT")
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PhNoCaption; PhNoCaptionLbl)
                    {
                    }
                    column(FaxNoCaption; FaxNoCaptionLbl)
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
                    column(AccNoCaption; AccNoCaptionLbl)
                    {
                    }
                    column(ServiceInvHdrBilltoCustNoCaption; "Service Invoice Header".FieldCaption("Bill-to Customer No."))
                    {
                    }
                    column(ServiceInvHdrDueDateCaption; "Service Invoice Header".FieldCaption("Due Date"))
                    {
                    }
                    column(InvNoCaption; InvNoCaptionLbl)
                    {
                    }
                    column(ServiceInvHdrPostingDateCaption; "Service Invoice Header".FieldCaption("Posting Date"))
                    {
                    }
                    column(ServiceInvHdrPricesIncludingVATCaption; "Service Invoice Header".FieldCaption("Prices Including VAT"))
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Service Invoice Header";
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(HdrDimensionsCaption; HdrDimensionsCaptionLbl)
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
                    dataitem("Service Invoice Line"; "Service Invoice Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Service Invoice Header";
                        DataItemTableView = sorting("Document No.", "Line No.");
                        column(LineAmt_ServiceInvLine; "Line Amount")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Description_ServiceInvLine; Description)
                        {
                        }
                        column(No_ServiceInvLine; "No.")
                        {
                        }
                        column(Qty_ServiceInvLine; Quantity)
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
                        column(LineDisc_ServiceInvLine; "Line Discount %")
                        {
                        }
                        column(VATIdentifier_ServiceInvLine; "VAT Identifier")
                        {
                        }
                        column(PostedShipmentDate; PostedShipmentDate)
                        {
                        }
                        column(NegOfInvDiscAmt; -"Inv. Discount Amount")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(Amt_ServiceInvLine; Amount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AmtIncludingVATExclAmount; "Amount Including VAT" - Amount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AmtIncludingVAT_ServiceInvLine; "Amount Including VAT")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVATAmtText; VATAmountLine.VATAmountText())
                        {
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(NegofLineAmtExclInvDiscAmtExclAmtIncludingVAT; -("Line Amount" - "Inv. Discount Amount" - "Amount Including VAT"))
                        {
                            AutoFormatExpression = "Service Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(NoCaption_ServiceInvLine; FieldCaption("No."))
                        {
                        }
                        column(DescCaption_ServiceInvLine; FieldCaption(Description))
                        {
                        }
                        column(QtyCaption_ServiceInvLine; FieldCaption(Quantity))
                        {
                        }
                        column(UOMCaption_ServiceInvLine; FieldCaption("Unit of Measure"))
                        {
                        }
                        column(UnitPriceCaption; UnitPriceCaptionLbl)
                        {
                        }
                        column(DiscCaption; DiscCaptionLbl)
                        {
                        }
                        column(AmtCaption; AmtCaptionLbl)
                        {
                        }
                        column(VATIdentifierCaption_ServiceInvLine; FieldCaption("VAT Identifier"))
                        {
                        }
                        column(PostedShipmentDateCaption; PostedShipmentDateCaptionLbl)
                        {
                        }
                        column(ContinuedCaption; ContinuedCaptionLbl)
                        {
                        }
                        column(InvDiscAmtCaption; InvDiscAmtCaptionLbl)
                        {
                        }
                        column(SubtotCaption; SubtotCaptionLbl)
                        {
                        }
                        column(PmtDiscOnVATCaption; PmtDiscOnVATCaptionLbl)
                        {
                        }
                        column(LineNo_ServiceInvLine; "Line No.")
                        {
                        }
                        dataitem("Service Shipment Buffer"; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(ServiceShipmentBufferPostingDate; ServiceShipmentBuffer."Posting Date")
                            {
                            }
                            column(ServiceShipmentBufferQty; ServiceShipmentBuffer.Quantity)
                            {
                                DecimalPlaces = 0 : 5;
                            }
                            column(ShipmentCaption; ShipmentCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then
                                    ServiceShipmentBuffer.Find('-')
                                else
                                    ServiceShipmentBuffer.Next();
                            end;

                            trigger OnPreDataItem()
                            begin
                                ServiceShipmentBuffer.SetRange("Document No.", "Service Invoice Line"."Document No.");
                                ServiceShipmentBuffer.SetRange("Line No.", "Service Invoice Line"."Line No.");

                                SetRange(Number, 1, ServiceShipmentBuffer.Count);
                            end;
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(DimText1; DimText)
                            {
                            }
                            column(LineDimensionsCaption; LineDimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then begin
                                    if not DimSetEntry2.FindFirst() then
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

                                DimSetEntry2.SetRange("Dimension Set ID", "Service Invoice Line"."Dimension Set ID");
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            PostedShipmentDate := 0D;
                            if Quantity <> 0 then
                                PostedShipmentDate := FindPostedShipmentDate();

                            if (Type = Type::"G/L Account") and not ShowInternalInfo then
                                "No." := '';

                            VATAmountLine.Init();
                            VATAmountLine."VAT Identifier" := "VAT Identifier";
                            VATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                            VATAmountLine."Tax Group Code" := "Tax Group Code";
                            VATAmountLine."VAT %" := "VAT %";
                            VATAmountLine."VAT Base" := Amount;
                            VATAmountLine."Amount Including VAT" := "Amount Including VAT";
                            VATAmountLine."Line Amount" := "Line Amount";
                            if "Allow Invoice Disc." then
                                VATAmountLine."Inv. Disc. Base Amount" := "Line Amount";
                            VATAmountLine."Invoice Discount Amount" := "Inv. Discount Amount";
                            VATAmountLine.InsertLine();
                        end;

                        trigger OnPreDataItem()
                        begin
                            VATAmountLine.DeleteAll();
                            ServiceShipmentBuffer.Reset();
                            ServiceShipmentBuffer.DeleteAll();
                            FirstValueEntryNo := 0;
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("No." = '') and (Quantity = 0) and (Amount = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SetRange("Line No.", 0, "Line No.");
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(VATAmtLineVATBase; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVATAmount; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineLineAmt; VATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Service Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscBaseAmt; VATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Service Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscAmt; VATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Service Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVAT; VATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmtLineVATIdentifier; VATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATCaption; VATCaptionLbl)
                        {
                        }
                        column(VATAmtCaption; VATAmtCaptionLbl)
                        {
                        }
                        column(VATAmtSpecificationCaption; VATAmtSpecificationCaptionLbl)
                        {
                        }
                        column(VATIdentifierCaption; VATIdentifierCaptionLbl)
                        {
                        }
                        column(InvDiscBaseAmtCaption; InvDiscBaseAmtCaptionLbl)
                        {
                        }
                        column(LineAmtCaption; LineAmtCaptionLbl)
                        {
                        }
                        column(InvDiscAmountCaption; InvDiscAmountCaptionLbl)
                        {
                        }
                        column(VATBaseCaption; VATBaseCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            VATAmountLine.GetLine(Number);
                        end;

                        trigger OnPreDataItem()
                        begin
                            if VATAmountLine.GetTotalVATAmount() = 0 then
                                CurrReport.Break();
                            SetRange(Number, 1, VATAmountLine.Count);
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(PaymentTermsDescription; PaymentTerms.Description)
                        {
                        }
                        column(PaymentTermsCaption; PaymentTermsCaptionLbl)
                        {
                        }
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(ServiceInvHdrCustNo; "Service Invoice Header"."Customer No.")
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
                        column(ShiptoAddrCaption; ShiptoAddrCaptionLbl)
                        {
                        }
                        column(ServiceInvHdrCustNoCaption; "Service Invoice Header".FieldCaption("Customer No."))
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if not ShowShippingAddr then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(ESR; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(CodingLine; CodingLine)
                        {
                        }
                        column(EsrAdr5; EsrAdr[5])
                        {
                        }
                        column(EsrAdr4; EsrAdr[4])
                        {
                        }
                        column(EsrAdr3; EsrAdr[3])
                        {
                        }
                        column(EsrAdr2; EsrAdr[2])
                        {
                        }
                        column(EsrAdr1; EsrAdr[1])
                        {
                        }
                        column(AmtTxt91; CopyStr(AmtTxt, 9, 1))
                        {
                        }
                        column(EsrSetupESRAccNo; EsrSetup."ESR Account No.")
                        {
                        }
                        column(AmtTxt81; CopyStr(AmtTxt, 8, 1))
                        {
                        }
                        column(AmtTxt71; CopyStr(AmtTxt, 7, 1))
                        {
                        }
                        column(EsrSetupBeneficiary4; EsrSetup."Beneficiary 4")
                        {
                        }
                        column(AmtTxt61; CopyStr(AmtTxt, 6, 1))
                        {
                        }
                        column(EsrSetupBeneficiary3; EsrSetup."Beneficiary 3")
                        {
                        }
                        column(DocType; DocType)
                        {
                        }
                        column(RefNo; RefNo)
                        {
                        }
                        column(AmtTxt51; CopyStr(AmtTxt, 5, 1))
                        {
                        }
                        column(EsrSetupBeneficiary2; EsrSetup."Beneficiary 2")
                        {
                        }
                        column(AmtTxt41; CopyStr(AmtTxt, 4, 1))
                        {
                        }
                        column(CurrencyCode; CurrencyCode)
                        {
                        }
                        column(AmtTxt31; CopyStr(AmtTxt, 3, 1))
                        {
                        }
                        column(AmtTxt21; CopyStr(AmtTxt, 2, 1))
                        {
                        }
                        column(EsrSetupBeneficiary; EsrSetup.Beneficiary)
                        {
                        }
                        column(AmtTxt11; CopyStr(AmtTxt, 1, 1))
                        {
                        }
                        column(EsrSetupBeneficiaryText; EsrSetup."Beneficiary Text")
                        {
                        }
                        column(EsrSetupESRMemberName3; EsrSetup."ESR Member Name 3")
                        {
                        }
                        column(AmtTxt1011; CopyStr(AmtTxt, 10, 1))
                        {
                        }
                        column(EsrSetupESRMemberName2; EsrSetup."ESR Member Name 2")
                        {
                        }
                        column(EsrSetupESRMemberName1; EsrSetup."ESR Member Name 1")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            ServBankPaymentMgt.PrepareEsrService("Service Invoice Header", EsrSetup, EsrType, EsrAdr, AmtTxt, CurrencyCode, DocType, RefNo, CodingLine);
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
                    if not CurrReport.Preview then
                        ServiceInvPrinted.Run("Service Invoice Header");
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
                CurrReport.Language := GlobalLanguage.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := GlobalLanguage.GetFormatRegionOrDefault("Format Region");

                FormatAddressFields("Service Invoice Header");
                FormatDocumentFields("Service Invoice Header");

                if not CompanyBankAccount.Get("Service Invoice Header"."Company Bank Account Code") then
                    CompanyBankAccount.CopyBankFieldsFromCompanyInfo(CompanyInfo);

                if not Cust.Get("Bill-to Customer No.") then
                    Clear(Cust);
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
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want the printed report to show information that is only for internal use.';
                    }
                    field("EsrSetup.""Bank Code"""; EsrSetup."Bank Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'ESR Bank';
                        TableRelation = "ESR Setup";
                        ToolTip = 'Specifies the code of the ESR bank.';
                    }
                    field(EsrType; EsrType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'ESR System';
                        OptionCaption = 'Based on ESR Bank,ESR,ESR+';
                        ToolTip = 'Specifies which ESR system to apply to the transaction. ESR systems include Based on ESR Bank, ESR, and ESR+.';
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
        Text004: Label 'Service - Invoice %1';
        GLSetup: Record "General Ledger Setup";
        PaymentTerms: Record "Payment Terms";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyBankAccount: Record "Bank Account";
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        ServiceSetup: Record "Service Mgt. Setup";
        Cust: Record Customer;
        VATAmountLine: Record "VAT Amount Line" temporary;
        RespCenter: Record "Responsibility Center";
        ServiceShipmentBuffer: Record "Service Shipment Buffer" temporary;
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        EsrSetup: Record "ESR Setup";
        GlobalLanguage: Codeunit Language;
        ServBankPaymentMgt: Codeunit "Serv. Bank Payment Mgt.";
        ServiceInvPrinted: Codeunit "Service Inv.-Printed";
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        PostedShipmentDate: Date;
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        OrderNoText: Text[80];
        SalesPersonText: Text[30];
        VATNoText: Text[80];
        ReferenceText: Text[80];
        TotalText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
        MoreLines: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        CopyText: Text[30];
        ShowShippingAddr: Boolean;
        NextEntryNo: Integer;
        FirstValueEntryNo: Integer;
        OutputNo: Integer;
        DimText: Text[120];
        OldDimText: Text[75];
        ShowInternalInfo: Boolean;
        Continue: Boolean;
        EsrAdr: array[8] of Text[100];
        EsrType: Option "Based on ESR Bank",ESR,"ESR+";
        AmtTxt: Text[30];
        CurrencyCode: Code[10];
        DocType: Text[10];
        RefNo: Text[35];
        CodingLine: Text[100];
        PhNoCaptionLbl: Label 'Phone No.';
        FaxNoCaptionLbl: Label 'Fax No.';
        VATRegNoCaptionLbl: Label 'VAT Reg. No.';
        GiroNoCaptionLbl: Label 'Giro No.';
        BankCaptionLbl: Label 'Bank';
        AccNoCaptionLbl: Label 'Account No.';
        InvNoCaptionLbl: Label 'Invoice No.';
        HdrDimensionsCaptionLbl: Label 'Header Dimensions';
        UnitPriceCaptionLbl: Label 'Unit Price';
        DiscCaptionLbl: Label 'Disc. %';
        AmtCaptionLbl: Label 'Amount';
        PostedShipmentDateCaptionLbl: Label 'Posted Shipment Date';
        ContinuedCaptionLbl: Label 'Continued';
        InvDiscAmtCaptionLbl: Label 'Inv. Discount Amount';
        SubtotCaptionLbl: Label 'Subtotal';
        PmtDiscOnVATCaptionLbl: Label 'Payment Discount on VAT';
        ShipmentCaptionLbl: Label 'Shipment';
        LineDimensionsCaptionLbl: Label 'Line Dimensions';
        VATCaptionLbl: Label 'VAT %';
        VATBaseCaptionLbl: Label 'VAT Base';
        VATAmtCaptionLbl: Label 'VAT Amount';
        VATAmtSpecificationCaptionLbl: Label 'VAT Amount Specification';
        VATIdentifierCaptionLbl: Label 'VAT Identifier';
        InvDiscBaseAmtCaptionLbl: Label 'Inv. Disc. Base Amount';
        LineAmtCaptionLbl: Label 'Line Amount';
        InvDiscAmountCaptionLbl: Label 'Invoice Discount Amount';
        PaymentTermsCaptionLbl: Label 'Payment Terms';
        ShiptoAddrCaptionLbl: Label 'Ship-to Address';

    [Scope('OnPrem')]
    procedure FindPostedShipmentDate(): Date
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentBuffer2: Record "Service Shipment Buffer" temporary;
    begin
        NextEntryNo := 1;
        if "Service Invoice Line"."Shipment No." <> '' then
            if ServiceShipmentHeader.Get("Service Invoice Line"."Shipment No.") then
                exit(ServiceShipmentHeader."Posting Date");

        if "Service Invoice Header"."Order No." = '' then
            exit("Service Invoice Header"."Posting Date");

        case "Service Invoice Line".Type of
            "Service Invoice Line".Type::Item:
                GenerateBufferFromValueEntry("Service Invoice Line");
            "Service Invoice Line".Type::"G/L Account", "Service Invoice Line".Type::Resource,
          "Service Invoice Line".Type::Cost:
                GenerateBufferFromShipment("Service Invoice Line");
            "Service Invoice Line".Type::" ":
                exit(0D);
        end;

        ServiceShipmentBuffer.Reset();
        ServiceShipmentBuffer.SetRange("Document No.", "Service Invoice Line"."Document No.");
        ServiceShipmentBuffer.SetRange("Line No.", "Service Invoice Line"."Line No.");
        if ServiceShipmentBuffer.Find('-') then begin
            ServiceShipmentBuffer2 := ServiceShipmentBuffer;
            if ServiceShipmentBuffer.Next() = 0 then begin
                ServiceShipmentBuffer.Get(
                  ServiceShipmentBuffer2."Document No.", ServiceShipmentBuffer2."Line No.", ServiceShipmentBuffer2."Entry No.");
                ServiceShipmentBuffer.Delete();
                exit(ServiceShipmentBuffer2."Posting Date");
            end;
            ServiceShipmentBuffer.CalcSums(Quantity);
            if ServiceShipmentBuffer.Quantity <> "Service Invoice Line".Quantity then begin
                ServiceShipmentBuffer.DeleteAll();
                exit("Service Invoice Header"."Posting Date");
            end;
        end else
            exit("Service Invoice Header"."Posting Date");
    end;

    [Scope('OnPrem')]
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

    [Scope('OnPrem')]
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

    [Scope('OnPrem')]
    procedure AddBufferEntry(ServiceInvoiceLine: Record "Service Invoice Line"; QtyOnShipment: Decimal; PostingDate: Date)
    begin
        ServiceShipmentBuffer.SetRange("Document No.", ServiceInvoiceLine."Document No.");
        ServiceShipmentBuffer.SetRange("Line No.", ServiceInvoiceLine."Line No.");
        ServiceShipmentBuffer.SetRange("Posting Date", PostingDate);
        if ServiceShipmentBuffer.Find('-') then begin
            ServiceShipmentBuffer.Quantity := ServiceShipmentBuffer.Quantity + QtyOnShipment;
            ServiceShipmentBuffer.Modify();
            exit;
        end;

        ServiceShipmentBuffer."Document No." := ServiceInvoiceLine."Document No.";
        ServiceShipmentBuffer."Line No." := ServiceInvoiceLine."Line No.";
        ServiceShipmentBuffer."Entry No." := NextEntryNo;
        ServiceShipmentBuffer.Type := ServiceInvoiceLine.Type;
        ServiceShipmentBuffer."No." := ServiceInvoiceLine."No.";
        ServiceShipmentBuffer.Quantity := QtyOnShipment;
        ServiceShipmentBuffer."Posting Date" := PostingDate;
        ServiceShipmentBuffer.Insert();
        NextEntryNo := NextEntryNo + 1
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
}

