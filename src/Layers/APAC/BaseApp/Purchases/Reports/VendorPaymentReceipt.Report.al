// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 411 "Vendor - Payment Receipt"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/VendorPaymentReceipt.rdlc';
    Caption = 'Vendor - Payment Receipt';
    ApplicationArea = Suite;
    UsageCategory = Documents;
    WordMergeDataItem = "Vendor Ledger Entry";

    dataset
    {
        dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
        {
            DataItemTableView = sorting("Document Type", "Vendor No.", "Posting Date", "Currency Code") where("Document Type" = filter(Payment | Refund));
            RequestFilterFields = "Vendor No.", "Posting Date", "Document No.";
            dataitem(PageLoop; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(VendAddr6; VendAddr[6])
                {
                }
                column(VendAddr7; VendAddr[7])
                {
                }
                column(VendAddr8; VendAddr[8])
                {
                }
                column(VendAddr4; VendAddr[4])
                {
                }
                column(VendAddr5; VendAddr[5])
                {
                }
                column(VendAddr3; VendAddr[3])
                {
                }
                column(VendAddr1; VendAddr[1])
                {
                }
                column(VendAddr2; VendAddr[2])
                {
                }
                column(VendorNo_VendLedgEntry; "Vendor Ledger Entry"."Vendor No.")
                {
                    IncludeCaption = true;
                }
                column(DocDate_VendLedgEntry; Format("Vendor Ledger Entry"."Document Date", 0, 4))
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
                column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                {
                }
                column(CompanyInfoEmail; CompanyInfo."E-Mail")
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
                column(DocNo_VendLedgEntry; "Vendor Ledger Entry"."Document No.")
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
                column(CompanyInfoBankNameCaption; CompanyInfoBankNameCaptionLbl)
                {
                }
                column(CompanyInfoBankAccountNoCaption; CompanyInfoBankAccountNoCaptionLbl)
                {
                }
                column(ReceiptNoCaption; ReceiptNoCaptionLbl)
                {
                }
                column(CompanyInfoVATRegistrationNoCaption; CompanyInfoVATRegistrationNoCaptionLbl)
                {
                }
                column(VendLedgEntry1PostingDateCaption; VendLedgEntry1PostingDateCaptionLbl)
                {
                }
                column(AmountCaption; AmountCaptionLbl)
                {
                }
                column(PmtTolInvCurrCaption; PmtTolInvCurrCaptionLbl)
                {
                }
                dataitem(DetailedVendorLedgEntry1; "Detailed Vendor Ledg. Entry")
                {
                    DataItemLink = "Applied Vend. Ledger Entry No." = field("Entry No.");
                    DataItemLinkReference = "Vendor Ledger Entry";
                    DataItemTableView = sorting("Applied Vend. Ledger Entry No.", "Entry Type") where(Unapplied = const(false));
                    PrintOnlyIfDetail = true;  
                    column(AppEntryNo_DetailVendLedgEntry; "Applied Vend. Ledger Entry No.")
                    {
                    }
                    dataitem(VendLedgEntry1; "Vendor Ledger Entry")
                    {
                        DataItemLink = "Entry No." = field("Vendor Ledger Entry No.");
                        DataItemLinkReference = DetailedVendorLedgEntry1;
                        DataItemTableView = sorting("Entry No.");
                        column(PostingDate_VendLedgEntry; Format("Posting Date"))
                        {
                        }
                        column(DocumentType_VendLedgEntry; "Document Type")
                        {
                            IncludeCaption = true;
                        }
                        column(DocNo_VendLedgEntry1; "Document No.")
                        {
                            IncludeCaption = true;
                        }
                        column(Description_VendLedgEntry; Description)
                        {
                            IncludeCaption = true;
                        }
                        column(ShowAmount; -ShowAmount)
                        {
                        }
                        column(CurrencyCodeCurrencyCode; CurrencyCode("Currency Code"))
                        {
                        }
                        column(NegPmtDiscInvCurrVendLedgEntry1; -PmtDiscInvCurr)
                        {
                        }
                        column(NegPmtTolInvCurrVendLedgEntry1; -PmtTolInvCurr)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if VendLedgEntry1."Entry No." = "Vendor Ledger Entry"."Entry No." then
                                CurrReport.Skip();

                            PmtDiscInvCurr := 0;
                            PmtTolInvCurr := 0;
                            PmtDiscPmtCurr := 0;
                            PmtTolPmtCurr := 0;

                            "Vendor Ledger Entry".CalcFields("WHT Amount");
                            WHTAmount := "Vendor Ledger Entry"."WHT Amount";
                            ShowAmount := -DetailedVendorLedgEntry1.Amount + "Vendor Ledger Entry"."WHT Amount";

                            if "Vendor Ledger Entry"."Currency Code" <> "Currency Code" then begin
                                PmtDiscInvCurr := Round("Pmt. Disc. Rcd.(LCY)" * "Vendor Ledger Entry"."Original Currency Factor");
                                PmtTolInvCurr := Round("Pmt. Tolerance (LCY)" * "Vendor Ledger Entry"."Original Currency Factor");
                                AppliedAmount :=
                                  Round(
                                    -DetailedVendorLedgEntry1.Amount / "Original Currency Factor" * "Vendor Ledger Entry"."Original Currency Factor",
                                    Currency."Amount Rounding Precision");
                            end else begin
                                PmtDiscInvCurr := Round("Pmt. Disc. Rcd.(LCY)" * "Vendor Ledger Entry"."Original Currency Factor");
                                PmtTolInvCurr := Round("Pmt. Tolerance (LCY)" * "Vendor Ledger Entry"."Original Currency Factor");
                                AppliedAmount := -DetailedVendorLedgEntry1.Amount;
                            end;

                            PmtDiscPmtCurr := Round("Pmt. Disc. Rcd.(LCY)" * "Vendor Ledger Entry"."Original Currency Factor");

                            PmtTolPmtCurr := Round("Pmt. Tolerance (LCY)" * "Vendor Ledger Entry"."Original Currency Factor");

                            RemainingAmount := (RemainingAmount - AppliedAmount) + PmtDiscPmtCurr + PmtTolPmtCurr;
                        end;
                    }
                }
                dataitem(DetailedVendorLedgEntry2; "Detailed Vendor Ledg. Entry")
                {
                    DataItemLink = "Vendor Ledger Entry No." = field("Entry No.");
                    DataItemLinkReference = "Vendor Ledger Entry";
                    DataItemTableView = sorting("Vendor Ledger Entry No.", "Entry Type", "Posting Date") where(Unapplied = const(false));
                    column(EntryNo_DetailVendLedgEntry; "Vendor Ledger Entry No.")
                    {
                    }
                    dataitem(VendLedgEntry2; "Vendor Ledger Entry")
                    {
                        DataItemLink = "Entry No." = field("Applied Vend. Ledger Entry No.");
                        DataItemLinkReference = DetailedVendorLedgEntry2;
                        DataItemTableView = sorting("Entry No.");
                        column(AppliedAmount; -AppliedAmount)
                        {
                        }
                        column(Desc1_VendLedgEntry; Description)
                        {
                        }
                        column(DocNo1_VendLedgEntry; "Document No.")
                        {
                        }
                        column(DocType_VendLedgEntry; "Document Type")
                        {
                        }
                        column(PostDate1_VendLedgEntry; Format("Posting Date"))
                        {
                        }
                        column(CurrCode_VendLedgEntry; CurrencyCode("Currency Code"))
                        {
                        }
                        column(PmtTolInvCurr1; -PmtTolInvCurr)
                        {
                        }

                        trigger OnAfterGetRecord()
                        var
                        begin
                            if VendLedgEntry2."Entry No." = "Vendor Ledger Entry"."Entry No." then
                                CurrReport.Skip();

                            PmtDiscInvCurr := 0;
                            PmtTolInvCurr := 0;
                            PmtDiscPmtCurr := 0;
                            PmtTolPmtCurr := 0;

                            ShowAmount := DetailedVendorLedgEntry2.Amount;

                            if "Vendor Ledger Entry"."Currency Code" <> "Currency Code" then begin
                                PmtDiscInvCurr := Round("Pmt. Disc. Rcd.(LCY)" * "Original Currency Factor");
                                PmtTolInvCurr := Round("Pmt. Tolerance (LCY)" * "Original Currency Factor");
                            end else begin
                                PmtDiscInvCurr := Round("Pmt. Disc. Rcd.(LCY)" * "Vendor Ledger Entry"."Original Currency Factor");
                                PmtTolInvCurr := Round("Pmt. Tolerance (LCY)" * "Vendor Ledger Entry"."Original Currency Factor");
                            end;

                            PmtDiscPmtCurr := Round("Pmt. Disc. Rcd.(LCY)" * "Vendor Ledger Entry"."Original Currency Factor");

                            PmtTolPmtCurr := Round("Pmt. Tolerance (LCY)" * "Vendor Ledger Entry"."Original Currency Factor");

                            AppliedAmount := DetailedVendorLedgEntry2.Amount;
                            RemainingAmount := (RemainingAmount - AppliedAmount) + PmtDiscPmtCurr + PmtTolPmtCurr;
                        end;
                    }
                }
                dataitem(Total; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(NegRemainingAmt; -RemainingAmount)
                    {
                    }
                    column(CurrCode1_VendLedgEntry; CurrencyCode("Vendor Ledger Entry"."Currency Code"))
                    {
                    }
                    column(NegOriginalAmt_VendLedgEntry; -"Vendor Ledger Entry"."Original Amount" + WHTAmount)
                    {
                    }
                    column(EmptyString; '')
                    {
                    }
                    column(ExtDocNo_VendLedgEntry; "Vendor Ledger Entry"."External Document No.")
                    {
                    }
                    column(PaymentAmountNotAllocatedCaption; PaymentAmountNotAllocatedCaptionLbl)
                    {
                    }
                    column(VendorLedgerEntryOriginalAmountCaption; VendorLedgerEntryOriginalAmountCaptionLbl)
                    {
                    }
                    column(ExternalDocumentNoCaption; ExternalDocumentNoCaptionLbl)
                    {
                    }
                }
            }

            trigger OnAfterGetRecord()
            begin
                Vend.Get("Vendor No.");
                FormatAddr.Vendor(VendAddr, Vend);
                if not Currency.Get("Currency Code") then
                    Currency.InitRoundingPrecision();

                if "Document Type" = "Document Type"::Payment then begin
                    ReportTitle := Text004;
                    PaymentDiscountTitle := Text007;
                end else begin
                    ReportTitle := Text003;
                    PaymentDiscountTitle := Text006;
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

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
        HomePageCaption = 'Home Page';
        EmailCaption = 'Email';
        DocumentDateCaption = 'Document Date';
        PageCaption = 'Page';
    }

    var
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        Vend: Record Vendor;
        Currency: Record Currency;
        FormatAddr: Codeunit "Format Address";
        ReportTitle: Text[30];
        PaymentDiscountTitle: Text[30];
        CompanyAddr: array[8] of Text[100];
        VendAddr: array[8] of Text[100];
        RemainingAmount: Decimal;
        AppliedAmount: Decimal;
        PmtDiscInvCurr: Decimal;
        PmtTolInvCurr: Decimal;
        PmtDiscPmtCurr: Decimal;
#pragma warning disable AA0074
        Text003: Label 'Payment Receipt';
        Text004: Label 'Payment Voucher';
        Text006: Label 'Payment Discount Given';
        Text007: Label 'Payment Discount Received';
#pragma warning restore AA0074
        PmtTolPmtCurr: Decimal;
        ShowAmount: Decimal;
        WHTAmount: Decimal;
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoGiroNoCaptionLbl: Label 'Giro No.';
        CompanyInfoBankNameCaptionLbl: Label 'Bank';
        CompanyInfoBankAccountNoCaptionLbl: Label 'Account No.';
        ReceiptNoCaptionLbl: Label 'Receipt No.';
        CompanyInfoVATRegistrationNoCaptionLbl: Label 'GST Registration No.';
        VendLedgEntry1PostingDateCaptionLbl: Label 'Posting Date';
        AmountCaptionLbl: Label 'Amount';
        PmtTolInvCurrCaptionLbl: Label 'Payment Tolerance';
        PaymentAmountNotAllocatedCaptionLbl: Label 'Payment Amount Not Allocated';
        VendorLedgerEntryOriginalAmountCaptionLbl: Label 'Payment Amount';
        ExternalDocumentNoCaptionLbl: Label 'External Document No.';

    local procedure CurrencyCode(SrcCurrCode: Code[10]): Code[10]
    begin
        if SrcCurrCode = '' then
            exit(GLSetup."LCY Code")
        else
            exit(SrcCurrCode);
    end;
}

