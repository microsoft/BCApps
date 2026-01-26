// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.History;
using Microsoft.Sales.Receivables;

report 7000085 "Partial Settl. - Payable"
{
    Caption = 'Partial Settl. - Payable';
    Permissions = TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd,
                  TableData "G/L Register" = m,
                  TableData "Posted Cartera Doc." = imd,
                  TableData "Closed Cartera Doc." = imd,
                  TableData "Posted Payment Order" = imd,
                  TableData "Closed Payment Order" = imd;
    ProcessingOnly = true;

    dataset
    {
        dataitem(PostedDoc; "Posted Cartera Doc.")
        {
            DataItemTableView = sorting("Bill Gr./Pmt. Order No.", Status, "Category Code", Redrawn, "Due Date") where(Status = const(Open));

            trigger OnAfterGetRecord()
            var
                FromJnl: Boolean;
            begin
                IsRedrawn := CarteraManagement.CheckFromRedrawnDoc("No.");
                if PostedPmtOrd."No." = '' then begin
                    PostedPmtOrd.Get("Bill Gr./Pmt. Order No.");
                    BankAcc.Get(PostedPmtOrd."Bank Account No.");
                    Delay := BankAcc."Delay for Notices";
                end;

                RemainingAmt2 := "Remaining Amount" - AppliedAmt;

                DocCount := DocCount + 1;
                Window.Update(1, DocCount);

                case "Document Type" of
                    "Document Type"::Invoice, "Document Type"::"Credit Memo":
                        begin
                            GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                            Clear(GenJnlLine);
                            GenJnlLine.Init();
                            GenJnlLine."Line No." := GenJnlLineNextNo;
                            GenJnlLine."Posting Date" := PostingDate;
                            GenJnlLine."Reason Code" := PostedPmtOrd."Reason Code";
                            GenJnlLine."Document Date" := GenJnlLine."Document Date";
                            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Vendor);
                            VendLedgEntry.Get(PostedDoc."Entry No.");
                            OnBeforeValidateInvoiceAccountNo(PostedDoc, GenJnlLine, VATPostingSetup, VendLedgEntry, FromJnl, ExistsNoRealVAT);
                            GenJnlLine.Validate("Account No.", VendLedgEntry."Vendor No.");
                            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                            GenJnlLine.Description := CopyStr(StrSubstNo(Text1100001, PostedDoc."Document No."), 1, MaxStrLen(GenJnlLine.Description));
                            GenJnlLine."Document No." := PostedPmtOrd."No.";
                            GenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
                            GenJnlLine.Validate(Amount, AppliedAmt);
                            GenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
                            GenJnlLine."Applies-to Doc. No." := VendLedgEntry."Document No.";
                            GenJnlLine."Applies-to Bill No." := VendLedgEntry."Bill No.";
                            GenJnlLine."Source Code" := SourceCode;
                            "Global Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                            GenJnlLine."System-Created Entry" := true;
                            GenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                            GenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                            GenJnlLine.Validate("Recipient Bank Account", VendLedgEntry."Recipient Bank Account");
                            GenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                            OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, VendLedgEntry, PostedPmtOrd);
                            GenJnlLine.Insert();
                            SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";

                            OnAfterInvoiceGenJnlLineInsert(
                              GenJnlLine, VendLedgEntry, PostedDoc, PostedPmtOrd, FromJnl, ExistsNoRealVAT,
                              AppliedAmt, ExistVATEntry, FirstVATEntryNo, LastVATEntryNo, NoRealVATBuffer);
                            if AppliedAmt = RemainingAmt then begin
                                VendLedgEntry."Document Status" := VendLedgEntry."Document Status"::Honored;
                                VendLedgEntry.Modify();
                                RemainingAmt2 := 0;
                            end;
                        end;
                    "Document Type"::Bill:
                        begin
                            GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                            Clear(GenJnlLine);
                            GenJnlLine.Init();
                            GenJnlLine."Line No." := GenJnlLineNextNo;
                            GenJnlLine."Posting Date" := PostingDate;
                            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                            GenJnlLine."Document No." := PostedPmtOrd."No.";
                            GenJnlLine."Reason Code" := PostedPmtOrd."Reason Code";
                            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Vendor);
                            VendLedgEntry.Get(PostedDoc."Entry No.");

                            if GLSetup."Unrealized VAT" then begin
                                FromJnl := false;
                                if PostedDoc."From Journal" then
                                    FromJnl := true;
                                ExistsNoRealVAT := GenJnlPostLine.VendFindVATSetup(VATPostingSetup, VendLedgEntry, FromJnl);
                            end;

                            GenJnlLine.Validate("Account No.", VendLedgEntry."Vendor No.");
                            GenJnlLine.Description := CopyStr(StrSubstNo(Text1100002, PostedDoc."Document No.", PostedDoc."No."), 1, MaxStrLen(GenJnlLine.Description));
                            GenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
                            GenJnlLine.Validate(Amount, AppliedAmt);
                            GenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
                            GenJnlLine."Applies-to Doc. No." := VendLedgEntry."Document No.";
                            GenJnlLine."Applies-to Bill No." := VendLedgEntry."Bill No.";
                            GenJnlLine."Source Code" := SourceCode;
                            GenJnlLine."System-Created Entry" := true;
                            GenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                            GenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                            GenJnlLine.Validate("Recipient Bank Account", VendLedgEntry."Recipient Bank Account");
                            GenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                            OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, VendLedgEntry, PostedPmtOrd);
                            GenJnlLine.Insert();
                            SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                            if GLSetup."Unrealized VAT" and
                               ExistsNoRealVAT and
                               (not IsRedrawn)
                            then begin
                                OnBeforeVendUnrealizedVAT2(PostedDoc, GenJnlLine, VendLedgEntry, PostedPmtOrd, NoRealVATBuffer);
                                CarteraManagement.VendUnrealizedVAT2(
                                  VendLedgEntry,
                                  -AppliedAmt,
                                  GenJnlLine,
                                  ExistVATEntry,
                                  FirstVATEntryNo,
                                  LastVATEntryNo,
                                  NoRealVATBuffer,
                                  FromJnl,
                                  "Document No.");
                                OnAfterVendUnrealizedVAT2(PostedDoc, GenJnlLine, VendLedgEntry, PostedPmtOrd, NoRealVATBuffer);

                                if NoRealVATBuffer.Find('-') then
                                    repeat
                                        InsertGenJournalLine(
                                          GenJnlLine."Account Type"::"G/L Account",
                                          NoRealVATBuffer.Account,
                                          NoRealVATBuffer.Amount);
                                        InsertGenJournalLine(
                                          GenJnlLine."Account Type"::"G/L Account",
                                          NoRealVATBuffer."Balance Account",
                                          -NoRealVATBuffer.Amount);
                                    until NoRealVATBuffer.Next() = 0;
                            end;

                            if AppliedAmt = "Remaining Amount" then begin
                                VendLedgEntry."Document Status" := VendLedgEntry."Document Status"::Honored;
                                VendLedgEntry.Modify();
                            end;
                        end;
                end;

                DimSetID := "Dimension Set ID";
                OnAfterPostedDocOnAfterGetRecord(PostedDoc);
            end;

            trigger OnPostDataItem()
            begin
                if DocCount = 0 then
                    Error(
                      Text1100003 +
                      Text1100004);

                GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                Clear(GenJnlLine);
                GenJnlLine.Init();
                GenJnlLine."Line No." := GenJnlLineNextNo;
                GenJnlLine."Posting Date" := PostingDate;
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                GenJnlLine."Document No." := PostedPmtOrd."No.";
                GenJnlLine."Reason Code" := PostedPmtOrd."Reason Code";
                GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Bank Account");
                GenJnlLine.Validate("Account No.", BankAcc."No.");
                if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
                    GenJnlLine.Description := CopyStr(StrSubstNo(Text1100002, PostedDoc."Document No.", PostedDoc."No."), 1, MaxStrLen(GenJnlLine.Description))
                else
                    GenJnlLine.Description := CopyStr(StrSubstNo(Text1100001, PostedDoc."Document No."), 1, MaxStrLen(GenJnlLine.Description));
                GenJnlLine.Validate("Currency Code", PostedPmtOrd."Currency Code");
                GenJnlLine.Validate(Amount, -AppliedAmt);
                GenJnlLine."Source Code" := SourceCode;
                GenJnlLine."System-Created Entry" := true;
                GenJnlLine."Dimension Set ID" :=
                  CarteraManagement.GetCombinedDimSetID(GenJnlLine, DimSetID);
                OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, VendLedgEntry, PostedPmtOrd);
                GenJnlLine.Insert();
                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";

                if PostedPmtOrd."Currency Code" <> '' then
                    if SumLCYAmt <> 0 then begin
                        Currency.SetFilter(Code, PostedPmtOrd."Currency Code");
                        Currency.FindFirst();
                        if SumLCYAmt > 0 then begin
                            Currency.TestField("Residual Gains Account");
                            Acct := Currency."Residual Gains Account";
                        end else begin
                            Currency.TestField("Residual Losses Account");
                            Acct := Currency."Residual Losses Account";
                        end;
                        GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                        Clear(GenJnlLine);
                        GenJnlLine.Init();
                        GenJnlLine."Line No." := GenJnlLineNextNo;
                        GenJnlLine."Posting Date" := PostingDate;
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                        GenJnlLine."Document No." := PostedPmtOrd."No.";
                        GenJnlLine."Reason Code" := PostedPmtOrd."Reason Code";
                        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
                        GenJnlLine.Validate("Account No.", Acct);
                        GenJnlLine.Description := Text1100005;
                        GenJnlLine.Validate("Currency Code", '');
                        GenJnlLine.Validate(Amount, -SumLCYAmt);
                        GenJnlLine."Source Code" := SourceCode;
                        GenJnlLine."System-Created Entry" := true;
                        GenJnlLine."Dimension Set ID" :=
                          CarteraManagement.GetCombinedDimSetID(GenJnlLine, VendLedgEntry."Dimension Set ID");
                        OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, VendLedgEntry, PostedPmtOrd);
                        GenJnlLine.Insert();
                    end;

                DocPost.PostSettlement(GenJnlLine);

                VendLedgEntry.Get("Entry No.");
                Get(Type, "Entry No.");
                "Honored/Rejtd. at Date" := PostingDate;
                "Remaining Amount" := RemainingAmt2;
                "Remaining Amt. (LCY)" := Round(CurrExchRate.ExchangeAmtFCYToLCY(
                      VendLedgEntry."Posting Date",
                      VendLedgEntry."Currency Code",
                      RemainingAmt2,
                      CurrExchRate.ExchangeRate(VendLedgEntry."Posting Date", VendLedgEntry."Currency Code")),
                    GLSetup."Amount Rounding Precision");
                if RemainingAmt2 = 0 then begin
                    "Remaining Amt. (LCY)" := 0;
                    VendLedgEntry."Document Status" := VendLedgEntry."Document Status"::Honored;
                    Status := Status::Honored;
                    VendLedgEntry.Open := false;
                end else begin
                    VendLedgEntry."Document Status" := VendLedgEntry."Document Status"::Open;
                    Status := Status::Open;
                    VendLedgEntry.Open := true;
                end;

                OnBeforePostedDocModify(PostedDoc, GenJnlLine, VendLedgEntry, PostedPmtOrd);
                VendLedgEntry.Modify();
                Modify();
                PostedPmtOrd.Modify();

                DocPost.ClosePmtOrdIfEmpty(PostedPmtOrd, PostingDate);

                Window.Close();

                if ExistVATEntry then begin
                    GLReg.FindLast();
                    GLReg."From VAT Entry No." := FirstVATEntryNo;
                    GLReg."To VAT Entry No." := LastVATEntryNo;
                    GLReg.Modify();
                end;

                OnAfterPostedDocOnPostDataItem(PostedDoc, GenJnlLine, VendLedgEntry, PostedPmtOrd);
                Commit();

                Message(
                  Text1100006,
                  DocCount, RemainingAmt, PostedPmtOrd."No.", AppliedAmt);
            end;

            trigger OnPreDataItem()
            begin
                DocPost.CheckPostingDate(PostingDate);

                SourceCodeSetup.Get();
                SourceCode := SourceCodeSetup."Cartera Journal";
                DocCount := 0;
                SumLCYAmt := 0;
                GenJnlLineNextNo := 0;
                ExistVATEntry := false;
                Window.Open(
                  Text1100000);
            end;
        }
    }

    requestpage
    {
        SaveValues = false;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the posting date.';

                        trigger OnValidate()
                        var
                            VendLedgEntry2: Record "Vendor Ledger Entry";
                        begin
                            VendLedgEntry2.Get(VendLedgEntryNo);
                            if VendLedgEntry2."Document Type" = VendLedgEntry2."Document Type"::Invoice then begin
                                VendLedgEntry2.CalcFields("Remaining Amount");
                                if PostingDate > VendLedgEntry2."Pmt. Discount Date" then
                                    RemainingAmt := -VendLedgEntry2."Remaining Amount"
                                else
                                    RemainingAmt := -VendLedgEntry2."Remaining Amount" + VendLedgEntry2."Remaining Pmt. Disc. Possible";
                                AppliedAmt := RemainingAmt;
                            end;
                        end;
                    }
                    field(RemainingAmt; RemainingAmt)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = CurrencyCode;
                        AutoFormatType = 1;
                        Caption = 'Remaining Amount';
                        Editable = false;
                        ToolTip = 'Specifies the pending, unpaid amount.';
                    }
                    field(CurrencyCode; CurrencyCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Currency Code';
                        Editable = false;
                        TableRelation = Currency;
                        ToolTip = 'Specifies the currency of the amounts.';
                    }
                    field(AppliedAmt; AppliedAmt)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = CurrencyCode;
                        AutoFormatType = 1;
                        Caption = 'Settled Amount';
                        Editable = true;
                        MinValue = 0;
                        NotBlank = true;
                        ToolTip = 'Specifies the amount that you wish to apply to the total amount due.';

                        trigger OnValidate()
                        begin
                            if AppliedAmt > RemainingAmt then
                                Error(Text1100007, RemainingAmt);
                        end;
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
        PostingDate := WorkDate();
        RemainingAmt := 0;
        AppliedAmt := 0;
        CurrencyCode := '';
    end;

    trigger OnPreReport()
    begin
        GLSetup.Get();
    end;

    var
        Text1100000: Label 'Settling payable documents       #1######';
        Text1100001: Label 'Partial Document settlement %1';
        Text1100002: Label 'Partial Bill settlement %1/%2';
        Text1100003: Label 'No payable documents have been found that can be settled. \';
        Text1100004: Label 'Please check that the selection is not empty and at least one payable document is open.';
        Text1100005: Label 'Residual adjust generated by rounding Amount';
        Text1100006: Label '%1 payable documents totaling %2 have been partially settled in Payment Order %3 by an amount of %4.';
        Text1100007: Label 'The maximum permitted value is %1';
        Text1100008: Label 'Partial payable document settlement %1/%2';
        Text1100009: Label 'Partial payable document settlement %1';
        SourceCodeSetup: Record "Source Code Setup";
        PostedPmtOrd: Record "Posted Payment Order";
        GenJnlLine: Record "Gen. Journal Line" temporary;
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAcc: Record "Bank Account";
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        GLReg: Record "G/L Register";
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        NoRealVATBuffer: Record "BG/PO Post. Buffer" temporary;
        DocPost: Codeunit "Document-Post";
        CarteraManagement: Codeunit CarteraManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Window: Dialog;
        PostingDate: Date;
        Delay: Decimal;
        SourceCode: Code[10];
        Acct: Code[20];
        DocCount: Integer;
        GenJnlLineNextNo: Integer;
        SumLCYAmt: Decimal;
        CurrencyCode: Code[10];
        RemainingAmt: Decimal;
        RemainingAmt2: Decimal;
        AppliedAmt: Decimal;
        ExistVATEntry: Boolean;
        FirstVATEntryNo: Integer;
        LastVATEntryNo: Integer;
        IsRedrawn: Boolean;
        DimSetID: Integer;
        ExistsNoRealVAT: Boolean;
        VendLedgEntryNo: Integer;

    procedure SetInitValue(Amount: Decimal; CurrCode: Code[10]; EntryNo: Integer)
    begin
        CurrencyCode := CurrCode;
        RemainingAmt := Amount;
        AppliedAmt := RemainingAmt;
        VendLedgEntryNo := EntryNo;
    end;

    local procedure InsertGenJournalLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount2: Decimal)
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        Clear(GenJnlLine);
        GenJnlLine.Init();
        GenJnlLine."Line No." := GenJnlLineNextNo;
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Document No." := PostedPmtOrd."No.";
        GenJnlLine."Reason Code" := PostedPmtOrd."Reason Code";
        GenJnlLine."Account Type" := AccType;
        GenJnlLine.Validate("Account No.", AccNo);
        if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
            GenJnlLine.Description := CopyStr(StrSubstNo(Text1100008, PostedDoc."Document No.", PostedDoc."No."), 1, MaxStrLen(GenJnlLine.Description))
        else
            GenJnlLine.Description := CopyStr(StrSubstNo(Text1100009, PostedDoc."Document No."), 1, MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
        GenJnlLine.Validate(Amount, -Amount2);
        GenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
        GenJnlLine."Applies-to Doc. No." := '';
        GenJnlLine."Applies-to Bill No." := VendLedgEntry."Bill No.";
        GenJnlLine."Source Code" := SourceCode;
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Dimension Set ID" :=
          CarteraManagement.GetCombinedDimSetID(GenJnlLine, VendLedgEntry."Dimension Set ID");
        OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, VendLedgEntry, PostedPmtOrd);
        GenJnlLine.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInvoiceGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PostedCarteraDoc: Record "Posted Cartera Doc."; var PostedPaymentOrder: Record "Posted Payment Order"; var FromJnl: Boolean; var ExistsNoRealVAT: Boolean; var AppliedAmt: Decimal; var ExistVATEntry: Boolean; var FirstVATEntryNo: Integer; var LastVATEntryNo: Integer; var BgPoPostBuffer: Record "BG/PO Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedDocOnAfterGetRecord(var PostedCarteraDoc: Record "Posted Cartera Doc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedDocOnPostDataItem(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PostedPaymentOrder: Record "Posted Payment Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVendUnrealizedVAT2(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PostedPaymentOrder: Record "Posted Payment Order"; var BgPoPostBuffer: Record "BG/PO Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJournalLineInsert(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PostedPaymentOrder: Record "Posted Payment Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedDocModify(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PostedPaymentOrder: Record "Posted Payment Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateInvoiceAccountNo(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var FromJnl: Boolean; var ExistsNoRealVAT: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendUnrealizedVAT2(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PostedPaymentOrder: Record "Posted Payment Order"; var BgPoPostBuffer: Record "BG/PO Post. Buffer")
    begin
    end;
}

