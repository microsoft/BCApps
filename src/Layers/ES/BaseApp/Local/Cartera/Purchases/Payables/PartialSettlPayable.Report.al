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
                end;

                RemainingAmt2 := "Remaining Amount" - AppliedDocumentAmount;

                DocCount := DocCount + 1;
                Window.Update(1, DocCount);

                case "Document Type" of
                    "Document Type"::Invoice, "Document Type"::"Credit Memo":
                        begin
                            GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                            Clear(TempGenJnlLine);
                            TempGenJnlLine.Init();
                            TempGenJnlLine."Line No." := GenJnlLineNextNo;
                            TempGenJnlLine."Posting Date" := DocumentPostingDate;
                            TempGenJnlLine."Reason Code" := PostedPmtOrd."Reason Code";
                            TempGenJnlLine."Document Date" := TempGenJnlLine."Document Date";
                            TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::Vendor);
                            VendLedgEntry.Get(PostedDoc."Entry No.");
                            OnBeforeValidateInvoiceAccountNo(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, FromJnl, ExistsNoRealVAT);
                            TempGenJnlLine.Validate("Account No.", VendLedgEntry."Vendor No.");
                            TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                            TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100001Lbl, PostedDoc."Document No."), 1, MaxStrLen(TempGenJnlLine.Description));
                            TempGenJnlLine."Document No." := PostedPmtOrd."No.";
                            TempGenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
                            TempGenJnlLine.Validate(Amount, AppliedDocumentAmount);
                            TempGenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
                            TempGenJnlLine."Applies-to Doc. No." := VendLedgEntry."Document No.";
                            TempGenJnlLine."Applies-to Bill No." := VendLedgEntry."Bill No.";
                            TempGenJnlLine."Source Code" := SourceCode;
                            "Global Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                            TempGenJnlLine."System-Created Entry" := true;
                            TempGenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                            TempGenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                            TempGenJnlLine.Validate("Recipient Bank Account", VendLedgEntry."Recipient Bank Account");
                            TempGenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                            OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, PostedPmtOrd);
                            TempGenJnlLine.Insert();
                            SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";

                            OnAfterInvoiceGenJnlLineInsert(
                              TempGenJnlLine, VendLedgEntry, PostedDoc, PostedPmtOrd, FromJnl, ExistsNoRealVAT,
                              AppliedDocumentAmount, ExistVATEntry, FirstVATEntryNo, LastVATEntryNo, TempNoRealVATBuffer);
                            if AppliedDocumentAmount = RemainingDocumentAmount then begin
                                VendLedgEntry."Document Status" := VendLedgEntry."Document Status"::Honored;
                                VendLedgEntry.Modify();
                                RemainingAmt2 := 0;
                            end;
                        end;
                    "Document Type"::Bill:
                        begin
                            GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                            Clear(TempGenJnlLine);
                            TempGenJnlLine.Init();
                            TempGenJnlLine."Line No." := GenJnlLineNextNo;
                            TempGenJnlLine."Posting Date" := DocumentPostingDate;
                            TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                            TempGenJnlLine."Document No." := PostedPmtOrd."No.";
                            TempGenJnlLine."Reason Code" := PostedPmtOrd."Reason Code";
                            TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::Vendor);
                            VendLedgEntry.Get(PostedDoc."Entry No.");

                            if GLSetup."Unrealized VAT" then begin
                                FromJnl := false;
                                if PostedDoc."From Journal" then
                                    FromJnl := true;
                                ExistsNoRealVAT := GenJnlPostLine.VendFindVATSetup(VATPostingSetup, VendLedgEntry, FromJnl);
                            end;

                            TempGenJnlLine.Validate("Account No.", VendLedgEntry."Vendor No.");
                            TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100002Lbl, PostedDoc."Document No.", PostedDoc."No."), 1, MaxStrLen(TempGenJnlLine.Description));
                            TempGenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
                            TempGenJnlLine.Validate(Amount, AppliedDocumentAmount);
                            TempGenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
                            TempGenJnlLine."Applies-to Doc. No." := VendLedgEntry."Document No.";
                            TempGenJnlLine."Applies-to Bill No." := VendLedgEntry."Bill No.";
                            TempGenJnlLine."Source Code" := SourceCode;
                            TempGenJnlLine."System-Created Entry" := true;
                            TempGenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                            TempGenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                            TempGenJnlLine.Validate("Recipient Bank Account", VendLedgEntry."Recipient Bank Account");
                            TempGenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                            OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, PostedPmtOrd);
                            TempGenJnlLine.Insert();
                            SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
                            if GLSetup."Unrealized VAT" and
                               ExistsNoRealVAT and
                               (not IsRedrawn)
                            then begin
                                OnBeforeVendUnrealizedVAT2(PostedDoc, TempGenJnlLine, VendLedgEntry, PostedPmtOrd, TempNoRealVATBuffer);
                                CarteraManagement.VendUnrealizedVAT2(
                                  VendLedgEntry,
                                  -AppliedDocumentAmount,
                                  TempGenJnlLine,
                                  ExistVATEntry,
                                  FirstVATEntryNo,
                                  LastVATEntryNo,
                                  TempNoRealVATBuffer,
                                  FromJnl,
                                  "Document No.");
                                OnAfterVendUnrealizedVAT2(PostedDoc, TempGenJnlLine, VendLedgEntry, PostedPmtOrd, TempNoRealVATBuffer);

                                if TempNoRealVATBuffer.Find('-') then
                                    repeat
                                        InsertGenJournalLine(
                                          TempGenJnlLine."Account Type"::"G/L Account",
                                          TempNoRealVATBuffer.Account,
                                          TempNoRealVATBuffer.Amount);
                                        InsertGenJournalLine(
                                          TempGenJnlLine."Account Type"::"G/L Account",
                                          TempNoRealVATBuffer."Balance Account",
                                          -TempNoRealVATBuffer.Amount);
                                    until TempNoRealVATBuffer.Next() = 0;
                            end;

                            if AppliedDocumentAmount = "Remaining Amount" then begin
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
                    Error(NoPayableDocumentsToSettleErr);

                GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                Clear(TempGenJnlLine);
                TempGenJnlLine.Init();
                TempGenJnlLine."Line No." := GenJnlLineNextNo;
                TempGenJnlLine."Posting Date" := DocumentPostingDate;
                TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                TempGenJnlLine."Document No." := PostedPmtOrd."No.";
                TempGenJnlLine."Reason Code" := PostedPmtOrd."Reason Code";
                TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"Bank Account");
                TempGenJnlLine.Validate("Account No.", BankAcc."No.");
                if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
                    TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100002Lbl, PostedDoc."Document No.", PostedDoc."No."), 1, MaxStrLen(TempGenJnlLine.Description))
                else
                    TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100001Lbl, PostedDoc."Document No."), 1, MaxStrLen(TempGenJnlLine.Description));
                TempGenJnlLine.Validate("Currency Code", PostedPmtOrd."Currency Code");
                TempGenJnlLine.Validate(Amount, -AppliedDocumentAmount);
                TempGenJnlLine."Source Code" := SourceCode;
                TempGenJnlLine."System-Created Entry" := true;
                TempGenJnlLine."Dimension Set ID" :=
                  CarteraManagement.GetCombinedDimSetID(TempGenJnlLine, DimSetID);
                OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, PostedPmtOrd);
                TempGenJnlLine.Insert();
                SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";

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
                        Clear(TempGenJnlLine);
                        TempGenJnlLine.Init();
                        TempGenJnlLine."Line No." := GenJnlLineNextNo;
                        TempGenJnlLine."Posting Date" := DocumentPostingDate;
                        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                        TempGenJnlLine."Document No." := PostedPmtOrd."No.";
                        TempGenJnlLine."Reason Code" := PostedPmtOrd."Reason Code";
                        TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"G/L Account");
                        TempGenJnlLine.Validate("Account No.", Acct);
                        TempGenJnlLine.Description := Text1100005Lbl;
                        TempGenJnlLine.Validate("Currency Code", '');
                        TempGenJnlLine.Validate(Amount, -SumLCYAmt);
                        TempGenJnlLine."Source Code" := SourceCode;
                        TempGenJnlLine."System-Created Entry" := true;
                        TempGenJnlLine."Dimension Set ID" :=
                          CarteraManagement.GetCombinedDimSetID(TempGenJnlLine, VendLedgEntry."Dimension Set ID");
                        OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, PostedPmtOrd);
                        TempGenJnlLine.Insert();
                    end;

                DocPost.PostSettlement(TempGenJnlLine);

                VendLedgEntry.Get("Entry No.");
                Get(Type, "Entry No.");
                "Honored/Rejtd. at Date" := DocumentPostingDate;
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

                OnBeforePostedDocModify(PostedDoc, TempGenJnlLine, VendLedgEntry, PostedPmtOrd);
                VendLedgEntry.Modify();
                Modify();
                PostedPmtOrd.Modify();

                DocPost.ClosePmtOrdIfEmpty(PostedPmtOrd, DocumentPostingDate);

                Window.Close();

                if ExistVATEntry then begin
                    GLReg.FindLast();
                    GLReg."From VAT Entry No." := FirstVATEntryNo;
                    GLReg."To VAT Entry No." := LastVATEntryNo;
                    GLReg.Modify();
                end;

                OnAfterPostedDocOnPostDataItem(PostedDoc, TempGenJnlLine, VendLedgEntry, PostedPmtOrd);
                Commit();

                Message(
                  Text1100006Lbl,
                  DocCount, RemainingDocumentAmount, PostedPmtOrd."No.", AppliedDocumentAmount);
            end;

            trigger OnPreDataItem()
            begin
                DocPost.CheckPostingDate(DocumentPostingDate);

                SourceCodeSetup.Get();
                SourceCode := SourceCodeSetup."Cartera Journal";
                DocCount := 0;
                SumLCYAmt := 0;
                GenJnlLineNextNo := 0;
                ExistVATEntry := false;
                Window.Open(
                  Text1100000Lbl);
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
                    field(PostingDate; DocumentPostingDate)
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
                                if DocumentPostingDate > VendLedgEntry2."Pmt. Discount Date" then
                                    RemainingDocumentAmount := -VendLedgEntry2."Remaining Amount"
                                else
                                    RemainingDocumentAmount := -VendLedgEntry2."Remaining Amount" + VendLedgEntry2."Remaining Pmt. Disc. Possible";
                                AppliedDocumentAmount := RemainingDocumentAmount;
                            end;
                        end;
                    }
                    field(RemainingAmt; RemainingDocumentAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = DocumentCurrencyCode;
                        AutoFormatType = 1;
                        Caption = 'Remaining Amount';
                        Editable = false;
                        ToolTip = 'Specifies the pending, unpaid amount.';
                    }
                    field(CurrencyCode; DocumentCurrencyCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Currency Code';
                        Editable = false;
                        TableRelation = Currency;
                        ToolTip = 'Specifies the currency of the amounts.';
                    }
                    field(AppliedAmt; AppliedDocumentAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = DocumentCurrencyCode;
                        AutoFormatType = 1;
                        Caption = 'Settled Amount';
                        Editable = true;
                        MinValue = 0;
                        NotBlank = true;
                        ToolTip = 'Specifies the amount that you wish to apply to the total amount due.';

                        trigger OnValidate()
                        begin
                            if AppliedDocumentAmount > RemainingDocumentAmount then
                                Error(Text1100007Lbl, RemainingDocumentAmount);
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
        DocumentPostingDate := WorkDate();
        RemainingDocumentAmount := 0;
        AppliedDocumentAmount := 0;
        DocumentCurrencyCode := '';
    end;

    trigger OnPreReport()
    begin
        GLSetup.Get();
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        PostedPmtOrd: Record "Posted Payment Order";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAcc: Record "Bank Account";
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        GLReg: Record "G/L Register";
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        TempNoRealVATBuffer: Record "BG/PO Post. Buffer" temporary;
        DocPost: Codeunit "Document-Post";
        CarteraManagement: Codeunit CarteraManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Text1100000Lbl: Label 'Settling payable documents       #1######', Comment = '#1 = Number of documents settled';
        Text1100001Lbl: Label 'Partial Document settlement %1', Comment = '%1 = Document number';
        Text1100002Lbl: Label 'Partial Bill settlement %1/%2', Comment = '%1 = Document number, %2 = Bill number';
        NoPayableDocumentsToSettleErr: Label 'No payable documents have been found that can be settled. \Please check that the selection is not empty and at least one payable document is open.';
        Text1100005Lbl: Label 'Residual adjust generated by rounding Amount';
        Text1100006Lbl: Label '%1 payable documents totaling %2 have been partially settled in Payment Order %3 by an amount of %4.', Comment = '%1 = Number of documents partially settled, %2 = Remaining amount, %3 = Payment order number, %4 = Applied amount';
        Text1100007Lbl: Label 'The maximum permitted value is %1', Comment = '%1 = Remaining amount available for settlement';
        Text1100008Lbl: Label 'Partial payable document settlement %1/%2', Comment = '%1 = Document number, %2 = Bill number';
        Text1100009Lbl: Label 'Partial payable document settlement %1', Comment = '%1 = Document number';
        Window: Dialog;
        DocumentPostingDate: Date;
        SourceCode: Code[10];
        Acct: Code[20];
        DocCount: Integer;
        GenJnlLineNextNo: Integer;
        SumLCYAmt: Decimal;
        DocumentCurrencyCode: Code[10];
        RemainingDocumentAmount: Decimal;
        RemainingAmt2: Decimal;
        AppliedDocumentAmount: Decimal;
        ExistVATEntry: Boolean;
        FirstVATEntryNo: Integer;
        LastVATEntryNo: Integer;
        IsRedrawn: Boolean;
        DimSetID: Integer;
        ExistsNoRealVAT: Boolean;
        VendLedgEntryNo: Integer;

    procedure SetInitValue(Amount: Decimal; CurrCode: Code[10]; EntryNo: Integer)
    begin
        DocumentCurrencyCode := CurrCode;
        RemainingDocumentAmount := Amount;
        AppliedDocumentAmount := RemainingDocumentAmount;
        VendLedgEntryNo := EntryNo;
    end;

    local procedure InsertGenJournalLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount2: Decimal)
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        Clear(TempGenJnlLine);
        TempGenJnlLine.Init();
        TempGenJnlLine."Line No." := GenJnlLineNextNo;
        TempGenJnlLine."Posting Date" := DocumentPostingDate;
        TempGenJnlLine."Document No." := PostedPmtOrd."No.";
        TempGenJnlLine."Reason Code" := PostedPmtOrd."Reason Code";
        TempGenJnlLine."Account Type" := AccType;
        TempGenJnlLine.Validate("Account No.", AccNo);
        if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
            TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100008Lbl, PostedDoc."Document No.", PostedDoc."No."), 1, MaxStrLen(TempGenJnlLine.Description))
        else
            TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100009Lbl, PostedDoc."Document No."), 1, MaxStrLen(TempGenJnlLine.Description));
        TempGenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
        TempGenJnlLine.Validate(Amount, -Amount2);
        TempGenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
        TempGenJnlLine."Applies-to Doc. No." := '';
        TempGenJnlLine."Applies-to Bill No." := VendLedgEntry."Bill No.";
        TempGenJnlLine."Source Code" := SourceCode;
        TempGenJnlLine."System-Created Entry" := true;
        TempGenJnlLine."Dimension Set ID" :=
          CarteraManagement.GetCombinedDimSetID(TempGenJnlLine, VendLedgEntry."Dimension Set ID");
        OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, PostedPmtOrd);
        TempGenJnlLine.Insert();
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

