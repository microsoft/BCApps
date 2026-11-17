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
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.History;
using Microsoft.Sales.Receivables;

report 7000082 "Settle Docs. in Posted PO"
{
    Caption = 'Settle Docs. in Posted PO';
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
                IsHandled: Boolean;
            begin
                IsRedrawn := CarteraManagement.CheckFromRedrawnDoc("No.");
                if "Document Type" = "Document Type"::Invoice then
                    ExistInvoice := true;

                IsHandled := false;
                OnAfterGetPostedDocOnBeforePostedPmtOrdGet(PostedDoc, PostedPmtOrd, BankAcc, Delay, IsHandled);
                if not IsHandled then begin
                    PostedPmtOrd.Get("Bill Gr./Pmt. Order No.");
                    BankAcc.Get(PostedPmtOrd."Bank Account No.");
                    Delay := BankAcc."Delay for Notices";
                end;

                if OnlyDueDocuments and (DocumentPostingDate < "Due Date" + Delay) then
                    CurrReport.Skip();

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
                            OnBeforeValidateInvoiceAccountNo(
                              PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, FromJnl, ExistsNoRealVAT, PostedPmtOrd);
                            TempGenJnlLine.Validate("Account No.", VendLedgEntry."Vendor No.");
                            TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                            TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100001Lbl, PostedDoc."Document No."), 1, MaxStrLen(TempGenJnlLine.Description));
                            TempGenJnlLine."Document No." := PostedPmtOrd."No.";
                            TempGenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
                            TempGenJnlLine."Posting Group" := VendLedgEntry."Vendor Posting Group";
                            if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlVend(TempGenJnlLine, VendLedgEntry, 0, false) then
                                TempGenJnlLine.Validate(Amount, PostedDoc."Remaining Amount" + VendLedgEntry."Remaining Pmt. Disc. Possible")
                            else
                                TempGenJnlLine.Validate(Amount, PostedDoc."Remaining Amount");
                            TempGenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
                            TempGenJnlLine."Applies-to Doc. No." := VendLedgEntry."Document No.";
                            TempGenJnlLine."Applies-to Bill No." := VendLedgEntry."Bill No.";
                            TempGenJnlLine."Source Code" := SourceCode;
                            TempGenJnlLine."System-Created Entry" := true;
                            TempGenJnlLine.Validate("Recipient Bank Account", VendLedgEntry."Recipient Bank Account");
                            TempGenJnlLine.Validate("Dimension Set ID", VendLedgEntry."Dimension Set ID");
                            OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, PostedPmtOrd, BankAcc);
                            TempGenJnlLine.Insert();
                            SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
                            GroupAmount := GroupAmount + "Remaining Amount";
                            if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlVend(TempGenJnlLine, VendLedgEntry, 0, false) then
                                CalcBankAccount("No.", "Remaining Amount" + VendLedgEntry."Remaining Pmt. Disc. Possible", VendLedgEntry."Entry No.")
                            else
                                CalcBankAccount("No.", "Remaining Amount", VendLedgEntry."Entry No.");
                            VendLedgEntry."Document Status" := VendLedgEntry."Document Status"::Honored;
                            VendLedgEntry.Modify();
                            OnAfterCreateInvoiceGenJnlLine(
                              TempGenJnlLine, VendLedgEntry, PostedDoc, PostedPmtOrd, FromJnl, ExistsNoRealVAT, ExistVATEntry,
                              IsRedrawn, FirstVATEntryNo, LastVATEntryNo, TempNoRealVATBuffer, TempBankAccPostBuffer);
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
                            TempGenJnlLine.Validate(Amount, PostedDoc."Remaining Amount");
                            TempGenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
                            TempGenJnlLine."Applies-to Doc. No." := VendLedgEntry."Document No.";
                            TempGenJnlLine."Applies-to Bill No." := VendLedgEntry."Bill No.";
                            TempGenJnlLine."Source Code" := SourceCode;
                            TempGenJnlLine."System-Created Entry" := true;
                            TempGenJnlLine.Validate("Recipient Bank Account", VendLedgEntry."Recipient Bank Account");
                            TempGenJnlLine.Validate("Dimension Set ID", VendLedgEntry."Dimension Set ID");
                            OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, PostedPmtOrd, BankAcc);
                            TempGenJnlLine.Insert();
                            SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
                            if GLSetup."Unrealized VAT" and ExistsNoRealVAT and (not IsRedrawn) then begin
                                VendLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");

                                OnBeforeVendUnrealizedVAT2(PostedDoc, TempGenJnlLine, VendLedgEntry, PostedPmtOrd, TempNoRealVATBuffer);
                                CarteraManagement.VendUnrealizedVAT2(
                                  VendLedgEntry,
                                  VendLedgEntry."Remaining Amt. (LCY)",
                                  TempGenJnlLine,
                                  ExistVATEntry,
                                  FirstVATEntryNo,
                                  LastVATEntryNo,
                                  TempNoRealVATBuffer,
                                  FromJnl,
                                  "Document No.");

                                TempCurrCode := "Currency Code";
                                "Currency Code" := '';

                                if TempNoRealVATBuffer.Find('-') then begin
                                    repeat
                                        InsertGenJournalLine(
                                          TempGenJnlLine."Account Type"::"G/L Account",
                                          TempNoRealVATBuffer.Account,
                                          TempNoRealVATBuffer.Amount,
                                          "Dimension Set ID");
                                        InsertGenJournalLine(
                                          TempGenJnlLine."Account Type"::"G/L Account",
                                          TempNoRealVATBuffer."Balance Account",
                                          -TempNoRealVATBuffer.Amount,
                                          "Dimension Set ID");
                                    until TempNoRealVATBuffer.Next() = 0;
                                    TempNoRealVATBuffer.DeleteAll();
                                end;

                                "Currency Code" := TempCurrCode;
                            end;
                            GroupAmount := GroupAmount + "Remaining Amount";
                            CalcBankAccount("No.", "Remaining Amount", VendLedgEntry."Entry No.");
                            VendLedgEntry."Document Status" := VendLedgEntry."Document Status"::Honored;
                            VendLedgEntry.Modify();
                            OnAfterCreateBillGenJnlLine(
                              TempGenJnlLine, VendLedgEntry, PostedDoc, PostedPmtOrd, FromJnl, ExistsNoRealVAT, ExistVATEntry,
                              IsRedrawn, FirstVATEntryNo, LastVATEntryNo, TempNoRealVATBuffer, TempBankAccPostBuffer);
                        end;
                end;
            end;

            trigger OnPostDataItem()
            var
                VendLedgEntry2: Record "Vendor Ledger Entry";
                PostedDoc2: Record "Posted Cartera Doc.";
                IsHandled: Boolean;
            begin
                if (DocCount = 0) or (GroupAmount = 0) then begin
                    if OnlyDueDocuments then
                        Error(NoDuePayableDocumentsErr);

                    Error(NoPayableDocumentsErr);
                end;

                IsHandled := false;
                OnBeforePostedDocOnPostDataItem(PostedDoc, PostedPmtOrd, TempBankAccPostBuffer, IsHandled, TempGenJnlLine, GenJnlLineNextNo, SumLCYAmt, DocumentPostingDate, SourceCode);
                if not IsHandled then
                    if TempBankAccPostBuffer.Find('-') then
                        repeat
                            VendLedgEntry2.Get(TempBankAccPostBuffer."Entry No.");
                            PostedDoc2.Get(1, VendLedgEntry2."Entry No.");
                            PostedPmtOrd.Get(PostedDoc2."Bill Gr./Pmt. Order No.");
                            BankAcc.Get(PostedPmtOrd."Bank Account No.");
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
                            TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100006Lbl, PostedPmtOrd."No."), 1, MaxStrLen(TempGenJnlLine.Description));
                            TempGenJnlLine.Validate("Currency Code", PostedPmtOrd."Currency Code");
                            TempGenJnlLine.Validate(Amount, -TempBankAccPostBuffer.Amount);
                            TempGenJnlLine."Source Code" := SourceCode;
                            TempGenJnlLine.Validate("Dimension Set ID", CarteraManagement.GetCombinedDimSetID(TempGenJnlLine, TempBankAccPostBuffer."Dimension Set ID"));
                            TempGenJnlLine."System-Created Entry" := true;
                            OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, PostedPmtOrd, BankAcc);
                            TempGenJnlLine.Insert();

                            SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
                        until TempBankAccPostBuffer.Next() = 0;

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
                        TempGenJnlLine.Description := Text1100007Lbl;
                        TempGenJnlLine.Validate("Currency Code", '');
                        TempGenJnlLine.Validate(Amount, -SumLCYAmt);
                        TempGenJnlLine."Source Code" := SourceCode;
                        TempGenJnlLine."System-Created Entry" := true;
                        OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, PostedPmtOrd, BankAcc);
                        TempGenJnlLine.Insert();
                    end;

                PostedPmtOrd.Modify();
                DocPost.PostSettlementForPostedPmtOrder(TempGenJnlLine, DocumentPostingDate);
                OnAfterPostSettlementForPostedPmtOrder(PostedDoc, PostedPmtOrd);

                Window.Close();

                if (Counter > 1) and GLSetup."Unrealized VAT" and ExistVATEntry and ExistInvoice then begin
                    if VATEntry.FindLast() then
                        ToVATEntryNo := VATEntry."Entry No.";
                    GLReg.FindLast();
                    GLReg."From VAT Entry No." := FromVATEntryNo;
                    GLReg."To VAT Entry No." := ToVATEntryNo;
                    GLReg.Modify();
                end else
                    if ExistVATEntry then begin
                        GLReg.FindLast();
                        GLReg."From VAT Entry No." := FirstVATEntryNo;
                        GLReg."To VAT Entry No." := LastVATEntryNo;
                        GLReg.Modify();
                    end;

                IsHandled := false;
                OnBeforeCommit(PostedDoc, PostedPmtOrd, TempGenJnlLine, HidePrintDialog, IsHandled);
                if IsHandled then
                    exit;

                Commit();

                if not HidePrintDialog then
                    Message(Text1100008Lbl, DocCount, GroupAmount);
            end;

            trigger OnPreDataItem()
            begin
                OnBeforePostedDocOnPreDataItem(PostedDoc, DocumentPostingDate);
                DocPost.CheckPostingDate(DocumentPostingDate);

                SourceCodeSetup.Get();
                SourceCode := SourceCodeSetup."Cartera Journal";
                DocCount := 0;
                SumLCYAmt := 0;
                GenJnlLineNextNo := 0;
                ExistInvoice := false;
                ExistVATEntry := false;
                Window.Open(
                  Text1100000Lbl);
                Counter := Count;
                if (Counter > 1) and GLSetup."Unrealized VAT" then begin
                    VATEntry.LockTable();
                    if VATEntry.FindLast() then
                        FromVATEntryNo := VATEntry."Entry No." + 1;
                end;
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
                    field(PostingDate; DocumentPostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the posting date for the document.';
                    }
                    field(DueOnly; OnlyDueDocuments)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Due bills only';
                        ToolTip = 'Specifies if you want to only include documents that have become overdue. If it does not matter if a document is overdue at the time of settlement, leave this field blank.';
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
        Currency: Record Currency;
        GLReg: Record "G/L Register";
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        TempBankAccPostBuffer: Record "BG/PO Post. Buffer" temporary;
        TempNoRealVATBuffer: Record "BG/PO Post. Buffer" temporary;
        DocPost: Codeunit "Document-Post";
        CarteraManagement: Codeunit CarteraManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        Text1100000Lbl: Label 'Settling payable documents     #1######', Comment = '#1 = Number of documents settled';
        Text1100001Lbl: Label 'Payable document settlement %1', Comment = '%1 = Document number';
        Text1100002Lbl: Label 'Payable bill settlement %1/%2', Comment = '%1 = Document number, %2 = Bill number';
        NoDuePayableDocumentsErr: Label 'No payable documents have been found that can be settled. Please check that the selection is not empty and at least one payable document is open and due.';
        NoPayableDocumentsErr: Label 'No payable documents have been found that can be settled. Please check that the selection is not empty and at least one payable document is open.';
        Text1100006Lbl: Label 'Payment Order settlement %1', Comment = '%1 = Payment order number';
        Text1100007Lbl: Label 'Residual adjust generated by rounding Amount';
        Text1100008Lbl: Label '%1 documents totaling %2 have been settled.', Comment = '%1 = Number of documents settled, %2 = Total amount settled';
        Text1100009Lbl: Label 'Document settlement %1/%2', Comment = '%1 = Document number, %2 = Bill number';
        Window: Dialog;
        DocumentPostingDate: Date;
        OnlyDueDocuments: Boolean;
        Delay: Decimal;
        SourceCode: Code[10];
        Acct: Code[20];
        DocCount: Integer;
        GroupAmount: Decimal;
        GenJnlLineNextNo: Integer;
        SumLCYAmt: Decimal;
        ExistVATEntry: Boolean;
        FirstVATEntryNo: Integer;
        LastVATEntryNo: Integer;
        IsRedrawn: Boolean;
        ExistInvoice: Boolean;
        FromVATEntryNo: Integer;
        ToVATEntryNo: Integer;
        Counter: Integer;
        TempCurrCode: Code[10];
        ExistsNoRealVAT: Boolean;
        HidePrintDialog: Boolean;

    local procedure InsertGenJournalLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount2: Decimal; DimSetID: Integer)
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        Clear(TempGenJnlLine);
        TempGenJnlLine.Init();
        TempGenJnlLine."Line No." := GenJnlLineNextNo;
        TempGenJnlLine."Posting Date" := DocumentPostingDate;
        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
        TempGenJnlLine."Document No." := PostedPmtOrd."No.";
        TempGenJnlLine."Reason Code" := PostedPmtOrd."Reason Code";
        TempGenJnlLine."Account Type" := AccType;
        TempGenJnlLine."Account No." := AccNo;
        if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
            TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100009Lbl, PostedDoc."Document No.", PostedDoc."No."), 1, MaxStrLen(TempGenJnlLine.Description))
        else
            TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100009Lbl, PostedDoc."Document No.", PostedDoc."No."), 1, MaxStrLen(TempGenJnlLine.Description));
        TempGenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
        TempGenJnlLine.Validate(Amount, -Amount2);
        TempGenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
        TempGenJnlLine."Applies-to Doc. No." := '';
        TempGenJnlLine."Applies-to Bill No." := VendLedgEntry."Bill No.";
        TempGenJnlLine."Source Code" := SourceCode;
        TempGenJnlLine."System-Created Entry" := true;
        TempGenJnlLine.Validate("Dimension Set ID", DimSetID);
        SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
        OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, VendLedgEntry, PostedPmtOrd, BankAcc);
        TempGenJnlLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure CalcBankAccount(BankAcc2: Code[20]; Amount2: Decimal; EntryNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcBankAccount(BankAcc2, Amount2, EntryNo, TempBankAccPostBuffer, IsHandled);
        if IsHandled then
            exit;

        if TempBankAccPostBuffer.Get(BankAcc2, '', EntryNo) then begin
            TempBankAccPostBuffer.Amount := TempBankAccPostBuffer.Amount + Amount2;
            TempBankAccPostBuffer.Modify();
        end else begin
            TempBankAccPostBuffer.Init();
            TempBankAccPostBuffer.Account := BankAcc2;
            TempBankAccPostBuffer.Amount := Amount2;
            TempBankAccPostBuffer."Entry No." := EntryNo;
            TempBankAccPostBuffer."Global Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
            TempBankAccPostBuffer."Global Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
            TempBankAccPostBuffer."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
            TempBankAccPostBuffer.Insert();
        end;
    end;

    procedure SetHidePrintDialog(NewHidePrintDialog: Boolean)
    begin
        HidePrintDialog := NewHidePrintDialog;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateBillGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PostedCarteraDoc: Record "Posted Cartera Doc."; var PostedPaymentOrder: Record "Posted Payment Order"; var FromJnl: Boolean; var ExistsNoRealVAT: Boolean; var ExistVATEntry: Boolean; var IsRedrawn: Boolean; var FirstVATEntryNo: Integer; var LastVATEntryNo: Integer; var BgPoPostBuffer: Record "BG/PO Post. Buffer"; var BankBgPoPostBuffer: Record "BG/PO Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInvoiceGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PostedCarteraDoc: Record "Posted Cartera Doc."; var PostedPaymentOrder: Record "Posted Payment Order"; var FromJnl: Boolean; var ExistsNoRealVAT: Boolean; var ExistVATEntry: Boolean; var IsRedrawn: Boolean; var FirstVATEntryNo: Integer; var LastVATEntryNo: Integer; var BgPoPostBuffer: Record "BG/PO Post. Buffer"; var BankBgPoPostBuffer: Record "BG/PO Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPostedDocOnBeforePostedPmtOrdGet(var PostedCarteraDoc: Record "Posted Cartera Doc."; var PostedPaymentOrder: Record "Posted Payment Order"; var BankAccount: Record "Bank Account"; var Delay: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSettlementForPostedPmtOrder(var PostedCarteraDoc: Record "Posted Cartera Doc."; var PostedPaymentOrder: Record "Posted Payment Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCommit(var PostedCarteraDoc: Record "Posted Cartera Doc."; var PostedPaymentOrder: Record "Posted Payment Order"; var GenJournalLine: Record "Gen. Journal Line"; var HidePrintDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBankAccount(BankAcc2: Code[20]; Amount2: Decimal; EntryNo: Integer; var BgPoPostBuffer: Record "BG/PO Post. Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJournalLineInsert(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PostedPaymentOrder: Record "Posted Payment Order"; var BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedDocOnPostDataItem(var PostedCarteraDoc: Record "Posted Cartera Doc."; var PostedPaymentOrder: Record "Posted Payment Order"; var BgPoPostBuffer: Record "BG/PO Post. Buffer"; var IsHandled: Boolean; var GenJnlLine: Record "Gen. Journal Line"; var GenJnlLineNextNo: Integer; var SumLCYAmt: Decimal; PostingDate: Date; SourceCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedDocOnPreDataItem(var PostedCarteraDoc: Record "Posted Cartera Doc."; var PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateInvoiceAccountNo(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var FromJnl: Boolean; var ExistsNoRealVAT: Boolean; var PostedPaymentOrder: Record "Posted Payment Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendUnrealizedVAT2(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PostedPaymentOrder: Record "Posted Payment Order"; var BgPoPostBuffer: Record "BG/PO Post. Buffer")
    begin
    end;
}

