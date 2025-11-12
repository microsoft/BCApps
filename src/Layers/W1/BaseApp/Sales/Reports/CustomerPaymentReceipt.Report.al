// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 211 "Customer - Payment Receipt"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/CustomerPaymentReceipt.rdlc';
    Caption = 'Customer - Payment Receipt';
    WordMergeDataItem = "Cust. Ledger Entry";

    dataset
    {
        dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
        {
            DataItemTableView = sorting("Document Type", "Customer No.", "Posting Date", "Currency Code") where("Document Type" = filter(Payment | Refund));
            RequestFilterFields = "Customer No.", "Posting Date", "Document No.";
            column(EntryNo_CustLedgEntry; "Entry No.")
            {
            }
            dataitem(PageLoop; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(CustAddr6; CustAddr[6])
                {
                }
                column(CustAddr7; CustAddr[7])
                {
                }
                column(CustAddr8; CustAddr[8])
                {
                }
                column(CustAddr4; CustAddr[4])
                {
                }
                column(CustAddr5; CustAddr[5])
                {
                }
                column(CustAddr3; CustAddr[3])
                {
                }
                column(CustAddr1; CustAddr[1])
                {
                }
                column(CustAddr2; CustAddr[2])
                {
                }
                column(CustomerNo_CustLedgEntry; "Cust. Ledger Entry"."Customer No.")
                {
                    IncludeCaption = true;
                }
                column(DocDate_CustLedgEntry; Format("Cust. Ledger Entry"."Document Date", 0, 4))
                {
                }
                column(CompanyAddr1; CompanyAddr[1])
                {
                }
                column(CompanyAddr2; CompanyAddr[2])
                {
                }
                column(CompanyAddr3; CompanyAddr[3])
                {
                }
                column(CompanyAddr4; CompanyAddr[4])
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
                column(CompanyInfoEMail; CompanyInfo."E-Mail")
                {
                }
                column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                {
                }
                column(CompanyInfoHomePage; CompanyInfo."Home Page")
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
                column(ReportTitle; ReportTitle)
                {
                }
                column(DocumentNo_CustLedgEntry; "Cust. Ledger Entry"."Document No.")
                {
                }
                column(PaymentDiscountTitle; PaymentDiscountTitle)
                {
                }
                column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
                {
                }
                column(CompanyInfoGiroNoCaption; CompanyInfoGiroNoCaptionLbl)
                {
                }
                column(CompanyInfoBankNameCptn; CompanyInfoBankNameCptnLbl)
                {
                }
                column(CompanyInfoBankAccNoCptn; CompanyInfoBankAccNoCptnLbl)
                {
                }
                column(ReceiptNoCaption; ReceiptNoCaptionLbl)
                {
                }
                column(CompanyInfoVATRegNoCptn; CompanyInfoVATRegNoCptnLbl)
                {
                }
                column(CustLedgEntry1PostDtCptn; CustLedgEntry1PostDtCptnLbl)
                {
                }
                column(AmountCaption; AmountCaptionLbl)
                {
                }
                column(PaymAmtSpecificationCptn; PaymAmtSpecificationCptnLbl)
                {
                }
                column(PmtTolInvCurrCaption; PmtTolInvCurrCaptionLbl)
                {
                }
                column(DocumentDateCaption; DocumentDateCaptionLbl)
                {
                }
                column(CompanyInfoEMailCaption; CompanyInfoEMailCaptionLbl)
                {
                }
                column(CompanyInfoHomePageCptn; CompanyInfoHomePageCptnLbl)
                {
                }
                dataitem(DetailedCustLedgEntry1; "Detailed Cust. Ledg. Entry")
                {
                    DataItemLink = "Applied Cust. Ledger Entry No." = field("Entry No.");
                    DataItemLinkReference = "Cust. Ledger Entry";
                    DataItemTableView = sorting("Applied Cust. Ledger Entry No.", "Entry Type") where(Unapplied = const(false));
                    dataitem(CustLedgEntry1; "Cust. Ledger Entry")
                    {
                        DataItemLink = "Entry No." = field("Cust. Ledger Entry No.");
                        DataItemLinkReference = DetailedCustLedgEntry1;
                        DataItemTableView = sorting("Entry No.");
                        column(PostDate_CustLedgEntry1; Format("Posting Date"))
                        {
                        }
                        column(DocType_CustLedgEntry1; "Document Type")
                        {
                            IncludeCaption = true;
                        }
                        column(DocumentNo_CustLedgEntry1; "Document No.")
                        {
                            IncludeCaption = true;
                        }
                        column(Desc_CustLedgEntry1; Description)
                        {
                            IncludeCaption = true;
                        }
                        column(CurrCode_CustLedgEntry1; CurrencyCode("Currency Code"))
                        {
                        }
                        column(ShowAmount; ShowAmount)
                        {
                        }
                        column(PmtDiscInvCurr; PmtDiscInvCurr)
                        {
                        }
                        column(PmtTolInvCurr; PmtTolInvCurr)
                        {
                        }
                        column(CurrencyCodeCaption; FieldCaption("Currency Code"))
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if "Entry No." = "Cust. Ledger Entry"."Entry No." then
                                CurrReport.Skip();

                            PmtDiscInvCurr := 0;
                            PmtTolInvCurr := 0;
                            PmtDiscPmtCurr := 0;
                            PmtTolPmtCurr := 0;

                            ShowAmount := -DetailedCustLedgEntry1.Amount;

                            if "Cust. Ledger Entry"."Currency Code" <> "Currency Code" then begin
                                PmtDiscInvCurr := Round("Pmt. Disc. Given (LCY)" * "Original Currency Factor");
                                PmtTolInvCurr := Round("Pmt. Tolerance (LCY)" * "Original Currency Factor");
                                AppliedAmount :=
                                  Round(
                                    -DetailedCustLedgEntry1.Amount / "Original Currency Factor" *
                                    "Cust. Ledger Entry"."Original Currency Factor", Currency."Amount Rounding Precision");
                            end else begin
                                PmtDiscInvCurr := Round("Pmt. Disc. Given (LCY)" * "Cust. Ledger Entry"."Original Currency Factor");
                                PmtTolInvCurr := Round("Pmt. Tolerance (LCY)" * "Cust. Ledger Entry"."Original Currency Factor");
                                AppliedAmount := -DetailedCustLedgEntry1.Amount;
                            end;

                            PmtDiscPmtCurr := Round("Pmt. Disc. Given (LCY)" * "Cust. Ledger Entry"."Original Currency Factor");
                            PmtTolPmtCurr := Round("Pmt. Tolerance (LCY)" * "Cust. Ledger Entry"."Original Currency Factor");

                            RemainingAmount := (RemainingAmount - AppliedAmount) + PmtDiscPmtCurr + PmtTolPmtCurr;
                        end;
                    }
                }
                dataitem(DetailedCustLedgEntry2; "Detailed Cust. Ledg. Entry")
                {
                    DataItemLink = "Cust. Ledger Entry No." = field("Entry No.");
                    DataItemLinkReference = "Cust. Ledger Entry";
                    DataItemTableView = sorting("Cust. Ledger Entry No.", "Entry Type", "Posting Date") where(Unapplied = const(false));
                    dataitem(CustLedgEntry2; "Cust. Ledger Entry")
                    {
                        DataItemLink = "Entry No." = field("Applied Cust. Ledger Entry No.");
                        DataItemLinkReference = DetailedCustLedgEntry2;
                        DataItemTableView = sorting("Entry No.");
                        column(AppliedAmount; AppliedAmount)
                        {
                        }
                        column(Desc_CustLedgEntry2; Description)
                        {
                        }
                        column(DocumentNo_CustLedgEntry2; "Document No.")
                        {
                        }
                        column(DocType_CustLedgEntry2; "Document Type")
                        {
                        }
                        column(PostDate_CustLedgEntry2; Format("Posting Date"))
                        {
                        }
                        column(PmtDiscInvCurr1; PmtDiscInvCurr)
                        {
                        }
                        column(PmtTolInvCurr1; PmtTolInvCurr)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if "Entry No." = "Cust. Ledger Entry"."Entry No." then
                                CurrReport.Skip();

                            PmtDiscInvCurr := 0;
                            PmtTolInvCurr := 0;
                            PmtDiscPmtCurr := 0;
                            PmtTolPmtCurr := 0;

                            ShowAmount := DetailedCustLedgEntry2.Amount;

                            if "Cust. Ledger Entry"."Currency Code" <> "Currency Code" then begin
                                PmtDiscInvCurr := Round("Pmt. Disc. Given (LCY)" * "Original Currency Factor");
                                PmtTolInvCurr := Round("Pmt. Tolerance (LCY)" * "Original Currency Factor");
                            end else begin
                                PmtDiscInvCurr := Round("Pmt. Disc. Given (LCY)" * "Cust. Ledger Entry"."Original Currency Factor");
                                PmtTolInvCurr := Round("Pmt. Tolerance (LCY)" * "Cust. Ledger Entry"."Original Currency Factor");
                            end;

                            PmtDiscPmtCurr := Round("Pmt. Disc. Given (LCY)" * "Cust. Ledger Entry"."Original Currency Factor");
                            PmtTolPmtCurr := Round("Pmt. Tolerance (LCY)" * "Cust. Ledger Entry"."Original Currency Factor");

                            AppliedAmount := DetailedCustLedgEntry2.Amount;
                            RemainingAmount := (RemainingAmount - AppliedAmount) + PmtDiscPmtCurr + PmtTolPmtCurr;
                        end;
                    }
                }
                dataitem(Total; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(RemainingAmount; RemainingAmount)
                    {
                    }
                    column(CurrCode_CustLedgEntry; CurrencyCode("Cust. Ledger Entry"."Currency Code"))
                    {
                    }
                    column(OriginalAmt_CustLedgEntry; "Cust. Ledger Entry"."Original Amount")
                    {
                    }
                    column(ExtDocNo_CustLedgEntry; "Cust. Ledger Entry"."External Document No.")
                    {
                    }
                    column(PaymAmtNotAllocatedCptn; PaymAmtNotAllocatedCptnLbl)
                    {
                    }
                    column(CustLedgEntryOrgAmtCptn; CustLedgEntryOrgAmtCptnLbl)
                    {
                    }
                    column(ExternalDocumentNoCaption; ExternalDocumentNoCaptionLbl)
                    {
                    }
                }
            }

            trigger OnAfterGetRecord()
            begin
                Cust.Get("Customer No.");
                FormatAddr.Customer(CustAddr, Cust);

                if not Currency.Get("Currency Code") then
                    Currency.InitRoundingPrecision();

                if "Document Type" = "Document Type"::Payment then begin
                    ReportTitle := Text003;
                    PaymentDiscountTitle := Text006;
                end else begin
                    ReportTitle := Text004;
                    PaymentDiscountTitle := Text007;
                end;

                CalcFields("Original Amount");
                RemainingAmount := -"Original Amount";
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                FormatAddr.Company(CompanyAddr, CompanyInfo);
                GLSetup.Get();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Customer - Payment Receipt';
        AboutText = 'Send a report to customers who want documentation for receipt of payment.';

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        GLSetup: Record "General Ledger Setup";
        Cust: Record Customer;
        Currency: Record Currency;
        FormatAddr: Codeunit "Format Address";
        ReportTitle: Text[30];
        PaymentDiscountTitle: Text[30];
        CompanyAddr: array[8] of Text[100];
        CustAddr: array[8] of Text[100];
        RemainingAmount: Decimal;
        AppliedAmount: Decimal;
        PmtDiscInvCurr: Decimal;
        PmtTolInvCurr: Decimal;
        PmtDiscPmtCurr: Decimal;
#pragma warning disable AA0074
        Text003: Label 'Payment Receipt';
        Text004: Label 'Payment Voucher';
        Text006: Label 'Pmt. Disc. Given';
        Text007: Label 'Pmt. Disc. Rcvd.';
#pragma warning restore AA0074
        PmtTolPmtCurr: Decimal;
        ShowAmount: Decimal;
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoGiroNoCaptionLbl: Label 'Giro No.';
        CompanyInfoBankNameCptnLbl: Label 'Bank';
        CompanyInfoBankAccNoCptnLbl: Label 'Account No.';
        ReceiptNoCaptionLbl: Label 'Receipt No.';
        CompanyInfoVATRegNoCptnLbl: Label 'GST Reg. No.';
        CustLedgEntry1PostDtCptnLbl: Label 'Posting Date';
        AmountCaptionLbl: Label 'Amount';
        PaymAmtSpecificationCptnLbl: Label 'Payment Amount Specification';
        PmtTolInvCurrCaptionLbl: Label 'Pmt Tol.';
        DocumentDateCaptionLbl: Label 'Document Date';
        CompanyInfoEMailCaptionLbl: Label 'Email';
        CompanyInfoHomePageCptnLbl: Label 'Home Page';
        PaymAmtNotAllocatedCptnLbl: Label 'Payment Amount Not Allocated';
        CustLedgEntryOrgAmtCptnLbl: Label 'Payment Amount';
        ExternalDocumentNoCaptionLbl: Label 'External Document No.';

    protected var
        CompanyInfo: Record "Company Information";

    local procedure CurrencyCode(SrcCurrCode: Code[10]): Code[10]
    begin
        if SrcCurrCode = '' then
            exit(GLSetup."LCY Code");
        exit(SrcCurrCode);
    end;
}

