// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using System.Globalization;
using System.Utilities;

report 3010532 "Sales Invoice ESR"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/SalesInvoiceESR.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Invoice ESR';
    Permissions =;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Head; "Sales Invoice Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Sell-to Customer No.", "No. Printed";
            column(No_Head; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(Adr1; Adr[1])
                    {
                    }
                    column(Adr2; Adr[2])
                    {
                    }
                    column(CopyTxt; CopyTxt)
                    {
                    }
                    column(CompanyAdr1; CompanyAdr[1])
                    {
                    }
                    column(CompanyAdr2; CompanyAdr[2])
                    {
                    }
                    column(Adr3; Adr[3])
                    {
                    }
                    column(CompanyAdr3; CompanyAdr[3])
                    {
                    }
                    column(Adr4; Adr[4])
                    {
                    }
                    column(CompanyAdr4; CompanyAdr[4])
                    {
                    }
                    column(Adr5; Adr[5])
                    {
                    }
                    column(CompanyAdr5; CompanyAdr[5])
                    {
                    }
                    column(Adr6; Adr[6])
                    {
                    }
                    column(CompanyAdr6; CompanyAdr[6])
                    {
                    }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(Adr7; Adr[7])
                    {
                    }
                    column(CompanyInfoFaxNo; CompanyInfo."Fax No.")
                    {
                    }
                    column(Adr8; Adr[8])
                    {
                    }
                    column(CompanyInfoVATRegistrationNo; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(HeadBilltoCustomerNo; Head."Bill-to Customer No.")
                    {
                    }
                    column(TitleTxtHeadNo; TitleTxt + ' ' + Head."No.")
                    {
                    }
                    column(HeadDocumentDate; Head."Document Date")
                    {
                    }
                    column(HeaderTxt1; HeaderTxt[1])
                    {
                    }
                    column(HeaderLabel1; HeaderLabel[1])
                    {
                    }
                    column(HeaderTxt2; HeaderTxt[2])
                    {
                    }
                    column(HeaderLabel2; HeaderLabel[2])
                    {
                    }
                    column(HeaderTxt3; HeaderTxt[3])
                    {
                    }
                    column(HeaderLabel3; HeaderLabel[3])
                    {
                    }
                    column(HeaderLabel4; HeaderLabel[4])
                    {
                    }
                    column(HeaderTxt4; HeaderTxt[4])
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PageGroupNo; PageGroupNo)
                    {
                    }
                    column(TelephoneCaption; TelephoneCaptionLbl)
                    {
                    }
                    column(FaxCaption; FaxCaptionLbl)
                    {
                    }
                    column(VATNumberCaption; VATNumberCaptionLbl)
                    {
                    }
                    column(DateCaption; DateCaptionLbl)
                    {
                    }
                    column(CustomerNoCaption; CustomerNoCaptionLbl)
                    {
                    }
                    column(QtyCaption; QtyCaptionLbl)
                    {
                    }
                    column(VATCaption; VATCaptionLbl)
                    {
                    }
                    column(UnitPriceCaption; UnitPriceCaptionLbl)
                    {
                    }
                    column(EmptyStringCaption; EmptyStringCaptionLbl)
                    {
                    }
                    column(AmountCaption; AmountCaptionLbl)
                    {
                    }
                    column(NumberCaption; NumberCaptionLbl)
                    {
                    }
                    column(DescriptionCaption; DescriptionCaptionLbl)
                    {
                    }
                    column(VATRate; ML_VatRate)
                    {
                    }
                    column(VATBase; ML_VatBase)
                    {
                    }
                    column(VATAmt; ML_VatAmt)
                    {
                    }
                    dataitem(Line; "Sales Invoice Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = Head;
                        DataItemTableView = sorting("Document No.", "Line No.");
                        column(No_Line; "No.")
                        {
                        }
                        column(IndentStrDescription; IndentStr + Description)
                        {
                        }
                        column(Quantity_Line; Quantity)
                        {
                        }
                        column(UnitofMeasure_Line; "Unit of Measure")
                        {
                        }
                        column(LineDiscount_Line; "Line Discount %")
                        {
                        }
                        column(VAT_Line; "VAT %")
                        {
                        }
                        column(LineAmount_Line; "Line Amount")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(UnitPrice_Line; "Unit Price")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 2;
                        }
                        column(InvDiscountAmount_Line; "Inv. Discount Amount")
                        {
                        }
                        column(LblTotalInvDisc1; Lbl_TotalInvDisc1)
                        {
                        }
                        column(Type_Line; Type)
                        {
                        }
                        column(Subtotalnet_Line; "Subtotal net")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TransferCaption; TransferCaptionLbl)
                        {
                        }
                        column(LineNo_Line; "Line No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            PageGroupNo := NextPageGroupNo;
                            if Type = Type::"New Page" then
                                NextPageGroupNo := PageGroupNo + 1;

                            IndentStr := PadStr(IndentStr, ("Quote-Level" - 1) * 2);

                            if (Type = Type::"G/L Account") and ("No." = CustPostGrp."Invoice Rounding Account") then
                                Description := ML_RoundingDiff;

                            SumVat();
                        end;

                        trigger OnPreDataItem()
                        begin
                            PageGroupNo := 1;
                            NextPageGroupNo := 1;
                            Clear(VatRate);
                            Clear(VatBase);
                            Clear(VatAmt);
                        end;
                    }
                    dataitem(TotalElement; "Integer")
                    {
                        DataItemTableView = sorting(Number) order(ascending) where(Number = const(1));
                        column(HeadCurrencyCode; Head."Currency Code")
                        {
                        }
                        column(LineAmount; Line.Amount)
                        {
                            AutoFormatExpression = Head."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VatAmt2; VatAmt[2])
                        {
                            AutoFormatExpression = Head."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VatAmt3; VatAmt[3])
                        {
                            AutoFormatExpression = Head."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VatAmt1; VatAmt[1])
                        {
                            AutoFormatExpression = Head."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalInvDisc; -TotalInvDisc)
                        {
                            AutoFormatExpression = Head."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VatBase1; VatBase[1])
                        {
                            AutoFormatExpression = Head."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VatBase2; VatBase[2])
                        {
                            AutoFormatExpression = Head."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VatBase3; VatBase[3])
                        {
                            AutoFormatExpression = Head."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VatRate1; VatRate[1])
                        {
                        }
                        column(VatRate2; VatRate[2])
                        {
                        }
                        column(VatRate3; VatRate[3])
                        {
                        }
                        column(FooterLabel1; FooterLabel[1])
                        {
                        }
                        column(FooterTxt1; FooterTxt[1])
                        {
                        }
                        column(FooterTxt2; FooterTxt[2])
                        {
                        }
                        column(FooterLabel2; FooterLabel[2])
                        {
                        }
                        column(FooterTxt3; FooterTxt[3])
                        {
                        }
                        column(FooterLabel3; FooterLabel[3])
                        {
                        }
                        column(FooterLabel6; FooterLabel[6])
                        {
                        }
                        column(FooterTxt6; FooterTxt[6])
                        {
                        }
                        column(FooterTxt5; FooterTxt[5])
                        {
                        }
                        column(FooterTxt4; FooterTxt[4])
                        {
                        }
                        column(FooterLabel4; FooterLabel[4])
                        {
                        }
                        column(FooterLabel5; FooterLabel[5])
                        {
                        }
                        column(FooterTxt8; FooterTxt[8])
                        {
                        }
                        column(FooterLabel8; FooterLabel[8])
                        {
                        }
                        column(FooterTxt7; FooterTxt[7])
                        {
                        }
                        column(FooterLabel7; FooterLabel[7])
                        {
                        }
                        column(CodingLine; CodingLine)
                        {
                        }
                        column(EsrAdr5; EsrAdr[5])
                        {
                        }
                        column(EsrAdr3; EsrAdr[3])
                        {
                        }
                        column(EsrAdr4; EsrAdr[4])
                        {
                        }
                        column(EsrAdr2; EsrAdr[2])
                        {
                        }
                        column(EsrAdr1; EsrAdr[1])
                        {
                        }
                        column(EsrSetupESRAccountNo; EsrSetup."ESR Account No.")
                        {
                        }
                        column(EsrSetupBeneficiary4; EsrSetup."Beneficiary 4")
                        {
                        }
                        column(DocType; DocType)
                        {
                        }
                        column(CurrencyCode; CurrencyCode)
                        {
                        }
                        column(EsrSetupBeneficiary3; EsrSetup."Beneficiary 3")
                        {
                        }
                        column(RefNo; RefNo)
                        {
                        }
                        column(EsrSetupBeneficiary2; EsrSetup."Beneficiary 2")
                        {
                        }
                        column(EsrSetupBeneficiary; EsrSetup.Beneficiary)
                        {
                        }
                        column(EsrSetupBeneficiaryText; EsrSetup."Beneficiary Text")
                        {
                        }
                        column(EsrSetupESRMemberName3; EsrSetup."ESR Member Name 3")
                        {
                        }
                        column(EsrSetupESRMemberName2; EsrSetup."ESR Member Name 2")
                        {
                        }
                        column(EsrSetupESRMemberName1; EsrSetup."ESR Member Name 1")
                        {
                        }
                        column(AmtTxt21; CopyStr(AmtTxt, 2, 1))
                        {
                        }
                        column(AmtTxt31; CopyStr(AmtTxt, 3, 1))
                        {
                        }
                        column(AmtTxt41; CopyStr(AmtTxt, 4, 1))
                        {
                        }
                        column(AmtTxt51; CopyStr(AmtTxt, 5, 1))
                        {
                        }
                        column(AmtTxt61; CopyStr(AmtTxt, 6, 1))
                        {
                        }
                        column(AmtTxt71; CopyStr(AmtTxt, 7, 1))
                        {
                        }
                        column(AmtTxt81; CopyStr(AmtTxt, 8, 1))
                        {
                        }
                        column(AmtTxt91; CopyStr(AmtTxt, 9, 1))
                        {
                        }
                        column(AmtTxt101; CopyStr(AmtTxt, 10, 1))
                        {
                        }
                        column(AmtTxt11; CopyStr(AmtTxt, 1, 1))
                        {
                        }
                        column(TotalWithoutVATCaption; TotalWithoutVATCaptionLbl)
                        {
                        }
                        column(TotalElementVATCaption; VATCaptionLbl)
                        {
                        }
                        column(TotalWithVATCaption; TotalWithVATCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Lbl_TotalInvDisc := '';

                            // Show footer label
                            if Line."Inv. Discount Amount" <> 0 then
                                Lbl_TotalInvDisc := ML_InvoiceDisc;

                            // Calc Inv. Disc and VAT amounts
                            if Head."Prices Including VAT" then
                                TotalInvDisc := Line."Line Amount" - Line."Amount Including VAT"
                            else
                                TotalInvDisc := Line."Line Amount" - Line.Amount;
                            TotalVat := Line."Amount Including VAT" - Line.Amount;

                            EsrSetup := ESRSetupRequestForm;
                            CHMgt.PrepareEsr(Head, EsrSetup, EsrType, EsrAdr, AmtTxt, CurrencyCode, DocType, RefNo, CodingLine);
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyTxt := ML_Copy;
                        OutputNo += 1;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    if not CurrReport.Preview then
                        CODEUNIT.Run(CODEUNIT::"Sales Inv.-Printed", Head);
                end;

                trigger OnPreDataItem()
                begin
                    OutputNo := 1;
                    CopyTxt := '';
#if not CLEAN27
                    CopiesToPrint := ReqCopies + Cust."Invoice Copies" + 1;
#else
                    CopiesToPrint := ReqCopies + 1;
#endif

                    SetRange(Number, 1, CopiesToPrint);  // Integer table
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := GlobalLanguage.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := GlobalLanguage.GetFormatRegionOrDefault("Format Region");
                // To filter rounding line
                Cust.Get("Bill-to Customer No.");
                CustPostGrp.Get("Customer Posting Group");
                PrepareHeader();
                PrepareFooter();

                // Print LCY Code for foreign cust
                GlSetup.Get();
                if ("Bill-to Country/Region Code" <> '') and ("Currency Code" = '') then
                    "Currency Code" := GlSetup."LCY Code";

                if LogInteraction then
                    if not CurrReport.Preview then
                        if "Bill-to Contact No." <> '' then
                            SegManagement.LogDocument(
                              4, "No.", 0, 0, DATABASE::Contact, "Bill-to Contact No.", "Salesperson Code",
                              "Campaign No.", "Posting Description", '')
                        else
                            SegManagement.LogDocument(
                              4, "No.", 0, 0, DATABASE::Customer, "Bill-to Customer No.", "Salesperson Code",
                              "Campaign No.", "Posting Description", '');
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                FormatAdr.Company(CompanyAdr, CompanyInfo);
                Lbl_TotalInvDisc1 := ML_InvoiceDisc;
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
                    field(ReqCopies; ReqCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field("ESRSetupRequestForm.""Bank Code"""; ESRSetupRequestForm."Bank Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'ESR Bank';
                        TableRelation = "ESR Setup";
                        ToolTip = 'Specifies the code of the ESR bank.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Enabled = LogInteractionEnable;
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

    var
        CompanyInfo: Record "Company Information";
        GlSetup: Record "General Ledger Setup";
        Cust: Record Customer;
        CustPostGrp: Record "Customer Posting Group";
        EsrSetup: Record "ESR Setup";
        ESRSetupRequestForm: Record "ESR Setup";
        GlobalLanguage: Codeunit Language;
        CHMgt: Codeunit CHMgt;
        FormatAdr: Codeunit "Format Address";
        SegManagement: Codeunit SegManagement;
        Adr: array[8] of Text[100];
        CompanyAdr: array[8] of Text[100];
        ReqCopies: Integer;
        CopiesToPrint: Integer;
        VatRate: array[5] of Decimal;
        VatBase: array[5] of Decimal;
        VatAmt: array[5] of Decimal;
        i: Integer;
        IndentStr: Text[30];
        ML_Invoice: Label 'Invoice';
        TitleTxt: Text[50];
        CopyTxt: Text[30];
        HeaderLabel: array[20] of Text[30];
        HeaderTxt: array[20] of Text;
        FooterLabel: array[20] of Text[30];
        FooterTxt: array[20] of Text;
        ML_Copy: Label 'Copy';
        ML_InvoiceDisc: Label 'Invoice Discount';
        ML_RoundingDiff: Label 'Rounding Difference';
        ML_VatRate: Label 'VAT Rate';
        ML_VatBase: Label 'VAT Base';
        ML_VatAmt: Label 'VAT Amount';
        Lbl_TotalInvDisc: Text[30];
        Text001: Label 'You cannot print documents with more than 3 VAT rates.';
        TotalInvDisc: Decimal;
        TotalVat: Decimal;
        EsrAdr: array[8] of Text[100];
        EsrType: Option "Based on ESR Bank",ESR,"ESR+";
        AmtTxt: Text[30];
        CurrencyCode: Code[10];
        DocType: Text[10];
        RefNo: Text[35];
        CodingLine: Text[100];
        LogInteraction: Boolean;
        Lbl_TotalInvDisc1: Text[30];
        OutputNo: Integer;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        LogInteractionEnable: Boolean;
        TelephoneCaptionLbl: Label 'Telephone';
        FaxCaptionLbl: Label 'Fax';
        VATNumberCaptionLbl: Label 'VAT Number';
        DateCaptionLbl: Label 'Date';
        CustomerNoCaptionLbl: Label 'Customer No.';
        QtyCaptionLbl: Label 'Qty.';
        VATCaptionLbl: Label 'VAT';
        UnitPriceCaptionLbl: Label 'Unit Price';
        EmptyStringCaptionLbl: Label '%';
        AmountCaptionLbl: Label 'Amount';
        NumberCaptionLbl: Label 'Number';
        DescriptionCaptionLbl: Label 'Description';
        TransferCaptionLbl: Label 'Transfer';
        TotalWithoutVATCaptionLbl: Label 'Total without VAT';
        TotalWithVATCaptionLbl: Label 'Total with VAT';

    [Scope('OnPrem')]
    procedure PrepareHeader()
    var
        CHReportManagement: Codeunit "CH Report Management";
        RecRef: RecordRef;
    begin
        TitleTxt := ML_Invoice;
        FormatAdr.SalesInvBillTo(Adr, Head);
        RecRef.GetTable(Head);
        CHReportManagement.PrepareHeader(RecRef, REPORT::"Sales Invoice ESR", HeaderLabel, HeaderTxt);
    end;

    [Scope('OnPrem')]
    procedure PrepareFooter()
    var
        CHReportManagement: Codeunit "CH Report Management";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Head);
        CHReportManagement.PrepareFooter(RecRef, REPORT::"Sales Invoice ESR", FooterLabel, FooterTxt);
    end;

    [Scope('OnPrem')]
    procedure SumVat()
    begin
        // Skip lines w/o VAT
        if Line."VAT %" = 0 then
            exit;
        // Find VAT Arrayposition. Empty or same %
        i := 1;
        while (VatRate[i] <> Line."VAT %") and (VatRate[i] <> 0) do
            i := i + 1;
        if i = 4 then
            Error(Text001);

        VatRate[i] := Line."VAT %";
        VatBase[i] := VatBase[i] + Line.Amount;
        VatAmt[i] := VatAmt[i] + (Line."Amount Including VAT" - Line.Amount);
    end;

    [Scope('OnPrem')]
    procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Sales Inv.") <> '';
    end;
}

