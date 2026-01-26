// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Security.AccessControl;
using System.Utilities;

report 11561 "SR Vendor Payment Advice"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/SRVendorPaymentAdvice.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Payment Advice';
    UsageCategory = ReportsAndAnalysis;
    AllowScheduling = false;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Vendor Posting Group", "Country/Region Code";
            column(CompanyInfoCityTodayFormatted; CompanyInformation.City + ', ' + Format(Today, 0, 4))
            {
            }
            column(VendorAdr1; VendorAdr[1])
            {
            }
            column(CompanyAdr1; CompanyAdr[1])
            {
            }
            column(VendorAdr2; VendorAdr[2])
            {
            }
            column(CompanyAdr2; CompanyAdr[2])
            {
            }
            column(VendorAdr3; VendorAdr[3])
            {
            }
            column(CompanyAdr3; CompanyAdr[3])
            {
            }
            column(VendorAdr4; VendorAdr[4])
            {
            }
            column(CompanyAdr4; CompanyAdr[4])
            {
            }
            column(VendorAdr5; VendorAdr[5])
            {
            }
            column(CompanyAdr5; CompanyAdr[5])
            {
            }
            column(VendorAdr6; VendorAdr[6])
            {
            }
            column(CompanyAdr6; CompanyAdr[6])
            {
            }
            column(VendorAdr7; VendorAdr[7])
            {
            }
            column(VendorAdr8; VendorAdr[8])
            {
            }
            column(MsgTxt; MsgTxt)
            {
            }
            column(PaymentCaption; PaymentCaptionLbl)
            {
            }
            column(PaymentAdviceCaption; PaymentAdviceCaptionLbl)
            {
            }
            column(PosCaption; PosCaptionLbl)
            {
            }
            column(DescCaption_GenJnlLine; "Gen. Journal Line".FieldCaption(Description))
            {
            }
            column(OurDocNoCaption; OurDocNoCaptionLbl)
            {
            }
            column(YrDocNoCaption; YrDocNoCaptionLbl)
            {
            }
            column(InvoiceCaption; InvoiceCaptionLbl)
            {
            }
            column(InvDateCaption; InvDateCaptionLbl)
            {
            }
            column(CurrCaption; CurrCaptionLbl)
            {
            }
            column(PmtDiscPmtTolCaption; PmtDiscPmtTolCaptionLbl)
            {
            }
            column(No_Vendor; "No.")
            {
            }
            dataitem("Gen. Journal Line"; "Gen. Journal Line")
            {
                DataItemTableView = sorting("Account Type", "Account No.", "Applies-to Doc. Type", "Applies-to Doc. No.");
                column(Amount_GenJnlLine; Amount)
                {
                }
                column(Desc_GenJnlLine; Description)
                {
                }
                column(VendEntryExternalDocNo; VendEntry."External Document No.")
                {
                }
                column(VendEntryDocDate; Format(VendEntry."Document Date"))
                {
                }
                column(VendEntryDocNo; VendEntry."Document No.")
                {
                }
                column(VendEntryAmount; -VendEntry.Amount)
                {
                }
                column(Pos; Pos)
                {
                }
                column(CurrencyCode_GenJnlLine; "Currency Code")
                {
                }
                column(PmtDiscAmtPmtTolerance; PmtDiscAmt + PmtTolerance)
                {
                }
                column(iCurr1; iCurr[1])
                {
                }
                column(iCurr2; iCurr[2])
                {
                }
                column(iCurr3; iCurr[3])
                {
                }
                column(iAmt3; iAmt[3])
                {
                }
                column(iAmt2; iAmt[2])
                {
                }
                column(iCurr4; iCurr[4])
                {
                }
                column(iAmt4; iAmt[4])
                {
                }
                column(iAmt1; iAmt[1])
                {
                }
                column(CompanyInfName; CompanyInformation.Name)
                {
                }
                column(RespPerson; RespPerson)
                {
                }
                column(TransferCaption; TransferCaptionLbl)
                {
                }
                column(TotalpaymentCaption; TotalpaymentCaptionLbl)
                {
                }
                column(YourssincerelyCaption; YourssincerelyCaptionLbl)
                {
                }
                column(TempName_GenJnlLine; "Journal Template Name")
                {
                }
                column(JnlBatchName_GenJnlLine; "Journal Batch Name")
                {
                }
                column(LineNo_GenJnlLine; "Line No.")
                {
                }
                dataitem(PmtVendEntryLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(PostingDate_PartPmtVendorEntry; Format(TempVendLedgEntry."Posting Date"))
                    {
                    }
                    column(DocType_PartPmtVendorEntry; TempVendLedgEntry."Document Type")
                    {
                    }
                    column(DocNo_PartPmtVendorEntry; TempVendLedgEntry."Document No.")
                    {
                    }
                    column(CurrCode_PartPmtVendorEntry; TempVendLedgEntry."Currency Code")
                    {
                    }
                    column(Amount; -TempVendLedgEntry.Amount)
                    {
                    }
                    column(ExternalDocNo_PartPmtVendorEntry; TempVendLedgEntry."External Document No.")
                    {
                    }
                    column(EntryNo_PartPmtVendorEntry; TempVendLedgEntry."Entry No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number > 1 then
                            if TempVendLedgEntry.Next() = 0 then
                                CurrReport.Break();

                        if TempVendLedgEntry."Currency Code" = '' then
                            TempVendLedgEntry."Currency Code" := GlSetup."LCY Code";

                        TempVendLedgEntry.CalcFields(Amount);
                    end;

                    trigger OnPreDataItem()
                    begin
                        TempVendLedgEntry.Reset();
                        if not TempVendLedgEntry.FindSet() then
                            CurrReport.Break();
                    end;
                }
                dataitem(RelatedPmtVendEntryLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DocNo_PartPmtVendorEntry2; TempRelatedVendLedgEntry."Document No.")
                    {
                    }
                    column(CurrCode_PartPmtVendorEntry2; TempRelatedVendLedgEntry."Currency Code")
                    {
                    }
                    column(Amount_PartPmtVendorEntry2; -TempRelatedVendLedgEntry.Amount)
                    {
                    }
                    column(ExternalDocNo_PartPmtVendorEntry2; TempRelatedVendLedgEntry."External Document No.")
                    {
                    }
                    column(PostingDate_PartPmtVendorEntry2; Format(TempRelatedVendLedgEntry."Posting Date"))
                    {
                    }
                    column(DocType_PartPmtVendorEntry2; TempRelatedVendLedgEntry."Document Type")
                    {
                    }
                    column(EntryNo_PartPmtVendorEntry2; TempRelatedVendLedgEntry."Entry No.")
                    {
                    }
                    column(ClosedbyEntryNo_PartPmtVendorEntry2; TempRelatedVendLedgEntry."Closed by Entry No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number > 1 then
                            if TempRelatedVendLedgEntry.Next() = 0 then
                                CurrReport.Break();

                        if TempRelatedVendLedgEntry."Currency Code" = '' then
                            TempRelatedVendLedgEntry."Currency Code" := GlSetup."LCY Code";

                        TempRelatedVendLedgEntry.CalcFields(Amount);
                    end;

                    trigger OnPreDataItem()
                    begin
                        TempRelatedVendLedgEntry.Reset();
                        if not TempRelatedVendLedgEntry.FindSet() then
                            CurrReport.Break();
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    OpenRemAmtFC: Decimal;
                begin
                    // ESR Zlg nicht avisieren
                    if not ShowEsrPayments then begin
                        if not VendBank.Get("Account No.", "Recipient Bank Account") then  // Bankverbindung

                        Error(Text002, "Recipient Bank Account", "Account No.");

                        if VendBank."Payment Form" in [VendBank."Payment Form"::ESR, VendBank."Payment Form"::"ESR+"] then
                            CurrReport.Skip();
                    end;

                    // Rechnungsposten für Rech. Betrag

                    PmtDiscAmt := 0;
                    PmtTolerance := 0;

                    VendEntry.SetCurrentKey("Document No.");
                    if "Applies-to Doc. No." <> '' then begin
                        VendEntry.SetRange("Document Type", VendEntry."Document Type"::Invoice);
                        VendEntry.SetRange("Document No.", "Applies-to Doc. No.");
                        VendEntry.SetRange("Vendor No.", "Account No.");
                        if not VendEntry.Find('-') then
                            VendEntry.Init();

                        VendEntry.CalcFields(Amount, "Remaining Amount");

                        if (VendEntry."Pmt. Discount Date" >= "Posting Date") or
                           ((VendEntry."Pmt. Disc. Tolerance Date" >= "Posting Date") and
                            VendEntry."Accepted Pmt. Disc. Tolerance")
                        then
                            PmtDiscAmt := VendEntry."Remaining Pmt. Disc. Possible";

                        PmtTolerance := VendEntry."Accepted Payment Tolerance";
                        OpenRemAmtFC := -VendEntry."Remaining Amount";

                        // Open entry and remaining for multicurrency. Convert to pmt currency
                        if VendEntry."Currency Code" <> "Currency Code" then
                            OpenRemAmtFC :=
                              ExchRate.ExchangeAmtFCYToFCY(
                                "Posting Date", VendEntry."Currency Code", "Currency Code", -VendEntry."Remaining Amount");

                        // Applied entry is not closed
                        if (OpenRemAmtFC - Amount + PmtDiscAmt + PmtTolerance) > 0 then
                            PmtDiscAmt := 0;
                        if Amount > OpenRemAmtFC then
                            PmtDiscAmt := 0;
                    end else begin
                        VendEntry."Entry No." := 0;
                        VendEntry."Document No." := '';
                        VendEntry.CalcFields(Amount, "Remaining Amount");
                    end;
                    BuildPmtVendLedgEntryBuffer(VendEntry."Entry No.");

                    Pos := Pos + 1;
                    NoOfPayments := NoOfPayments + 1;

                    // Total pro Währung summieren
                    i := 1;
                    if "Currency Code" = '' then
                        "Currency Code" := GlSetup."LCY Code";

                    while (iCurr[i] <> "Currency Code") and (iCurr[i] <> '') do
                        i := i + 1;

                    if i = 6 then
                        Error(Text003, i - 1);

                    iCurr[i] := "Currency Code";
                    iAmt[i] := iAmt[i] + Amount;
                    iAmtLCY[i] := iAmtLCY[i] + "Amount (LCY)";
                end;

                trigger OnPostDataItem()
                begin
                    if Pos > 0 then
                        NoOfVendors := NoOfVendors + 1;
                end;

                trigger OnPreDataItem()
                begin
                    // Nur Zeilen vom Typ Kreditor/Zahlungen vom ausgewählten Journal für den aktuellen Kreditor
                    SetCurrentKey("Account Type", "Account No.");
                    SetRange("Document Type", "Document Type"::Payment);
                    SetRange("Account Type", "Account Type"::Vendor);
                    SetRange("Account No.", Vendor."No.");
                    SetRange("Journal Template Name", JourBatchName);
                    SetRange("Journal Batch Name", JourBatch);

                    Pos := 0;
                    Clear(iCurr);
                    Clear(iAmt);
                    Clear(iAmtLCY);

                    // Nur drucken, falls bestimmte Anzahl Zlg pro Kred.

                    Clear(TempGenJourLine);
                    TempGenJourLine.CopyFilters("Gen. Journal Line");

                    if not ShowEsrPayments then
                        SetEsrFilter(TempGenJourLine);
                    if TempGenJourLine.Count < PrintFromNoOfVendorInvoices then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FormatAdr.Vendor(VendorAdr, Vendor);
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
                    field(PrintFromNoOfVendorInvoices; PrintFromNoOfVendorInvoices)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print from Payments/Vendor';
                        ToolTip = 'Specifies the number of payments.';
                    }
                    field(ShowEsrPayments; ShowEsrPayments)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Advice ESR Payments';
                        ToolTip = 'Specifies if you want to advice ESR payments. Typically this option is not used because ESR payments are not combined into collective payments.';
                    }
                    field(RespPerson; RespPerson)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Responsible Person';
                        ToolTip = 'Specifies the person responsible.';
                    }
                    field(MsgTxt; MsgTxt)
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
        var
            User: Record User;
        begin
            if MsgTxt = '' then
                MsgTxt := Text004;

            if PrintFromNoOfVendorInvoices = 0 then
                PrintFromNoOfVendorInvoices := 1;

            if (RespPerson = '') and (UserId <> '') then begin
                User.SetRange("User Name", UserId);
                if User.FindFirst() then
                    RespPerson := User."Full Name";
            end;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Message(
          Text001,
          NoOfVendors, NoOfPayments, "Gen. Journal Line".GetFilter("Journal Batch Name"));
    end;

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        FormatAdr.Company(CompanyAdr, CompanyInformation);

        GlSetup.Get();
        if GlSetup."LCY Code" = '' then
            GlSetup."LCY Code" := Text000;
    end;

    var
        Text000: Label 'CHF';
        Text001: Label 'Payment advice processed for %1 vendors. %2 payments processed from journal %3.';
        Text002: Label 'Bank %1 does not exist for vendor %2.';
        Text003: Label 'More than %1 currencies cannot be processed.';
        Text004: Label 'We have advices our bank to remit the following amount to your account in the next few days.';
        CompanyInformation: Record "Company Information";
        GlSetup: Record "General Ledger Setup";
        VendEntry: Record "Vendor Ledger Entry";
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        TempRelatedVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        VendBank: Record "Vendor Bank Account";
        ExchRate: Record "Currency Exchange Rate";
        TempGenJourLine: Record "Gen. Journal Line";
        FormatAdr: Codeunit "Format Address";
        JourBatch: Code[20];
        JourBatchName: Code[20];
        ShowEsrPayments: Boolean;
        PrintFromNoOfVendorInvoices: Integer;
        RespPerson: Text[50];
        MsgTxt: Text[250];
        CompanyAdr: array[8] of Text[100];
        VendorAdr: array[8] of Text[100];
        Pos: Integer;
        NoOfVendors: Integer;
        NoOfPayments: Integer;
        i: Integer;
        iCurr: array[20] of Code[10];
        iAmt: array[20] of Decimal;
        iAmtLCY: array[20] of Decimal;
        PmtDiscAmt: Decimal;
        PmtTolerance: Decimal;
        PaymentCaptionLbl: Label 'Payment';
        PaymentAdviceCaptionLbl: Label 'Payment Advice';
        PosCaptionLbl: Label 'Pos.';
        OurDocNoCaptionLbl: Label 'Our. Doc. No';
        YrDocNoCaptionLbl: Label 'Yr. Doc. No.';
        InvoiceCaptionLbl: Label 'Invoice';
        InvDateCaptionLbl: Label 'Inv. Date';
        CurrCaptionLbl: Label 'Curr.';
        PmtDiscPmtTolCaptionLbl: Label 'Pmt.Disc./ Pmt.Tol. ';
        TransferCaptionLbl: Label 'Transfer';
        TotalpaymentCaptionLbl: Label 'Total payment';
        YourssincerelyCaptionLbl: Label 'Yours sincerely';

    [Scope('OnPrem')]
    procedure DefineJourBatch(_GnlJourLine: Record "Gen. Journal Line")
    begin
        JourBatch := _GnlJourLine."Journal Batch Name";
        JourBatchName := _GnlJourLine."Journal Template Name";
    end;

    [Scope('OnPrem')]
    procedure SetEsrFilter(var TempGenJourLine: Record "Gen. Journal Line")
    var
        VendBank: Record "Vendor Bank Account";
    begin
        if TempGenJourLine.Find('-') then
            repeat
                if not VendBank.Get(TempGenJourLine."Account No.", TempGenJourLine."Recipient Bank Account") then
                    Error(Text002, TempGenJourLine."Recipient Bank Account", TempGenJourLine."Account No.");
                if not (VendBank."Payment Form" in [VendBank."Payment Form"::ESR, VendBank."Payment Form"::"ESR+"]) then
                    TempGenJourLine.Mark(true)
                else
                    TempGenJourLine.Mark(false);
            until TempGenJourLine.Next() = 0;

        TempGenJourLine.MarkedOnly(true);
    end;

    local procedure BuildPmtVendLedgEntryBuffer(EntryNo: Integer)
    begin
        if EntryNo = 0 then
            exit;

        TempVendLedgEntry.Reset();
        TempVendLedgEntry.DeleteAll();
        TempRelatedVendLedgEntry.Reset();
        TempRelatedVendLedgEntry.DeleteAll();

        UpdateVendLedgEntryBufferRecursively(TempVendLedgEntry, TempRelatedVendLedgEntry, EntryNo);
    end;

    local procedure UpdateVendLedgEntryBufferRecursively(var VendLedgEntryBuffer: Record "Vendor Ledger Entry"; var RelatedVendLedgEntryBuffer: Record "Vendor Ledger Entry"; EntryNo: Integer)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Closed by Entry No.", EntryNo);
        if VendLedgEntry.FindSet() then
            repeat
                VendLedgEntryBuffer := VendLedgEntry;
                if VendLedgEntryBuffer.Insert() then;
                UpdateVendLedgEntryBufferRecursively(
                  RelatedVendLedgEntryBuffer, RelatedVendLedgEntryBuffer, VendLedgEntry."Entry No.");
            until VendLedgEntry.Next() = 0;
    end;
}

