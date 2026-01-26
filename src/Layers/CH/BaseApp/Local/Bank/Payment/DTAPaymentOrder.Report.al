// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 3010543 "DTA Payment Order"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/DTAPaymentOrder.rdlc';
    Caption = 'DTA Payment Order';

    dataset
    {
        dataitem("DTA Setup"; "DTA Setup")
        {
            DataItemTableView = sorting("Bank Code");
            PrintOnlyIfDetail = true;
            column(DTACurrencyCode_DTASetup; "DTA Currency Code")
            {
            }
            column(BankAccountNo; BankAccountNo)
            {
            }
            column(AdsLine4; AdsLine[4])
            {
            }
            column(AdsLine3; AdsLine[3])
            {
            }
            column(AdsLine2; AdsLine[2])
            {
            }
            column(AdsLine1; AdsLine[1])
            {
            }
            column(DTASenderID_DTASetup; "DTA Sender ID")
            {
            }
            column(DTACustomerID_DTASetup; "DTA Customer ID")
            {
            }
            column(BankCode_DTASetup; "Bank Code")
            {
            }
            column(CompanySetup6; CompanySetup[6])
            {
            }
            column(CompanySetup5; CompanySetup[5])
            {
            }
            column(CompanySetup4; CompanySetup[4])
            {
            }
            column(CompanySetup3; CompanySetup[3])
            {
            }
            column(CompanySetup2; CompanySetup[2])
            {
            }
            column(CompanySetup1; CompanySetup[1])
            {
            }
            column(AmtInGLSetupLCYCode; StrSubstNo(Text003, GLSetup."LCY Code"))
            {
            }
            column(AmtInCurrencyCaption; AmtInCurrencyCaptionLbl)
            {
            }
            column(NoOfInvoicesCaption; NoOfInvoicesCaptionLbl)
            {
            }
            column(TransactionTypeCaption; TransactionTypeCaptionLbl)
            {
            }
            column(PaymentOrderDTACaption; PaymentOrderDTACaptionLbl)
            {
            }
            column(AccountNoCaption; AccountNoCaptionLbl)
            {
            }
            column(AccountInCurrencyCaption; AccountInCurrencyCaptionLbl)
            {
            }
            column(CurrencyCodeCaption; CurrencyCodeCaptionLbl)
            {
            }
            column(DTASenderIDCaption; DTASenderIDCaptionLbl)
            {
            }
            column(DTAOriginatorIDCaption; DTAOriginatorIDCaptionLbl)
            {
            }
            column(BankCodeCaption; BankCodeCaptionLbl)
            {
            }
            dataitem("Gen. Journal Line"; "Gen. Journal Line")
            {
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Posting Date", Clearing, "Debit Bank");

                trigger OnAfterGetRecord()
                begin
                    // Find transaction type
                    TestField("Recipient Bank Account");
                    VendorBankAccount.Get("Account No.", "Recipient Bank Account");

                    xCurr := DtaMgt.GetIsoCurrencyCode("Currency Code");
                    xTA := Format(DtaMgt.GetRecordType(xCurr, Amount, "Account No.", "Recipient Bank Account", 'DTA'));

                    if xTA in ['826', '827'] then begin
                        TotalAmtDomestic := TotalAmtDomestic + Amount;
                        TotalAmtDomesticLCY := TotalAmtDomesticLCY + "Amount (LCY)";
                        TotalNoOfPmtsDomestic := TotalNoOfPmtsDomestic + 1;
                    end;

                    // Prepare total per currency
                    i := 1;

                    while ((iCurrency[i] <> xCurr) or (iTA[i] <> xTA)) and (i < 10) and (iCurrency[i] <> '') do
                        i := i + 1;

                    if i = 10 then
                        Error(Text001);

                    iTA[i] := xTA;
                    iCurrency[i] := xCurr;
                    iNo[i] := iNo[i] + 1;  // No of Records
                    iAmt[i] := iAmt[i] + Amount;
                    iAmtLCY[i] := iAmtLCY[i] + "Amount (LCY)";

                    TotalNoOfPmts := TotalNoOfPmts + 1;
                    TotalAmtLCY := TotalAmtLCY + "Amount (LCY)";
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Account Type", "Account Type"::Vendor);
                    SetRange("Document Type", "Document Type"::Payment);
                    SetRange("Debit Bank", "DTA Setup"."Bank Code");
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 11;
                column(iAmtLCYNumber; iAmtLCY[Number])
                {
                }
                column(iAmtNumber; iAmt[Number])
                {
                }
                column(iNoNumber; iNo[Number])
                {
                }
                column(iTANumber; iTA[Number])
                {
                }
                column(iCurrencyNumber; iCurrency[Number])
                {
                }
                column(Msg; Msg)
                {
                }
                column(TotalNoOfPmtsDomestic; TotalNoOfPmtsDomestic)
                {
                }
                column(TotalNoOfPmts; TotalNoOfPmts)
                {
                }
                column(TodayFormatted; Format(Today))
                {
                }
                column(EmptyString; '')
                {
                }
                column(TotalAmtLCY; TotalAmtLCY)
                {
                }
                column(TotalAmtDomestic; TotalAmtDomestic)
                {
                }
                column(TotalAmtDomesticLCY; TotalAmtDomesticLCY)
                {
                }
                column(TotalTA826By827Caption; TotalTA826By827CaptionLbl)
                {
                }
                column(TotalPaymentOrderCaption; TotalPaymentOrderCaptionLbl)
                {
                }
                column(MsgCaption; MsgCaptionLbl)
                {
                }
                column(DateCaption; DateCaptionLbl)
                {
                }
                column(SignatureCaption; SignatureCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if iCurrency[Number] = '' then
                        CurrReport.Break();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, 10);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Clear(iTA);
                Clear(iCurrency);
                Clear(iNo);
                Clear(iAmt);
                Clear(iAmtLCY);

                BankAccountNo := '';

                TotalNoOfPmts := 0;
                TotalAmtLCY := 0;
                i := 0;

                TotalAmtDomestic := 0;
                TotalAmtDomesticLCY := 0;
                TotalNoOfPmtsDomestic := 0;

                CompanyInfo.Get();
                FormatAdr.Company(CompanySetup, CompanyInfo);

                AdsLine[1] := "DTA Bank Name";
                AdsLine[2] := "DTA Bank Name 2";
                AdsLine[3] := "DTA Bank Address";
                AdsLine[4] := "DTA Bank Post Code" + ' ' + "DTA Setup"."DTA Bank City";
                CompressArray(AdsLine);

                if "DTA Setup"."DTA Currency Code" = '' then begin
                    GLSetup.Get();
                    "DTA Setup"."DTA Currency Code" := GLSetup."LCY Code";
                end;

                if "DTA Setup"."DTA Sender IBAN" <> '' then
                    BankAccountNo := "DTA Setup"."DTA Sender IBAN"
                else
                    BankAccountNo := "DTA Setup"."DTA Debit Acc. No.";
            end;

            trigger OnPreDataItem()
            begin
                SetRange("DTA/EZAG", "DTA/EZAG"::DTA);
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
                    field(Msg; Msg)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Message';
                        MultiLine = true;
                        ToolTip = 'Specifies a message to include on the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DebitDate < Today then
                DebitDate := CalcDate('<3D>', Today);
            if Date2DWY(DebitDate, 1) = 6 then
                DebitDate := CalcDate('<-1D>', DebitDate); // Sat = Fri}
            if Date2DWY(DebitDate, 1) = 7 then
                DebitDate := CalcDate('<1D>', DebitDate); // Sun = Mon}
        end;
    }

    labels
    {
    }

    var
        CompanyInfo: Record "Company Information";
        VendorBankAccount: Record "Vendor Bank Account";
        GLSetup: Record "General Ledger Setup";
        FormatAdr: Codeunit "Format Address";
        DtaMgt: Codeunit DtaMgt;
        CompanySetup: array[8] of Text[100];
        AdsLine: array[4] of Text[32];
        BankAccountNo: Text[35];
        DebitDate: Date;
        xCurr: Code[3];
        i: Integer;
        iCurrency: array[15] of Code[3];
        xTA: Code[3];
        iTA: array[15] of Code[3];
        iNo: array[15] of Integer;
        iAmt: array[15] of Decimal;
        iAmtLCY: array[15] of Decimal;
        TotalNoOfPmts: Integer;
        TotalAmtLCY: Decimal;
        Msg: Text[250];
        TotalAmtDomestic: Decimal;
        TotalAmtDomesticLCY: Decimal;
        TotalNoOfPmtsDomestic: Integer;
        Text001: Label 'Only nine currencies are possible for each DTA payment order. \If necessary, split the order into multiple orders.';
        Text003: Label 'Amount in %1';
        AmtInCurrencyCaptionLbl: Label 'Amount in currency';
        NoOfInvoicesCaptionLbl: Label 'No. of invoices';
        TransactionTypeCaptionLbl: Label 'TransactionType';
        PaymentOrderDTACaptionLbl: Label 'Payment Order DTA';
        AccountNoCaptionLbl: Label 'Account No.';
        AccountInCurrencyCaptionLbl: Label 'Account in currency';
        CurrencyCodeCaptionLbl: Label 'Currency Code';
        DTASenderIDCaptionLbl: Label 'DTA Sender ID';
        DTAOriginatorIDCaptionLbl: Label 'DTA Originator ID';
        BankCodeCaptionLbl: Label 'Bank Code';
        TotalTA826By827CaptionLbl: Label 'Total TA 826/827 (in CHF)';
        TotalPaymentOrderCaptionLbl: Label 'Total payment order';
        MsgCaptionLbl: Label 'Message';
        DateCaptionLbl: Label 'Date';
        SignatureCaptionLbl: Label 'Signature';
}

