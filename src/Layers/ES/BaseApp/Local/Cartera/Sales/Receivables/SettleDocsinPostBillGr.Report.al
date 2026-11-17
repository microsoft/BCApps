// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;

report 7000098 "Settle Docs. in Post. Bill Gr."
{
    Caption = 'Settle Docs. in Post. Bill Gr.';
    Permissions = TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd,
                  TableData "G/L Register" = m,
                  TableData "Posted Cartera Doc." = imd,
                  TableData "Closed Cartera Doc." = imd,
                  TableData "Posted Bill Group" = imd,
                  TableData "Closed Bill Group" = imd;
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

                PostedBillGr.Get("Bill Gr./Pmt. Order No.");
                BankAcc.Get(PostedBillGr."Bank Account No.");
                Delay := BankAcc."Delay for Notices";

                if OnlyDueDocuments and (PostingDate < "Due Date" + Delay) then
                    CurrReport.Skip();

                DocCount := DocCount + 1;
                Window.Update(1, DocCount);

                GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                Clear(TempGenJnlLine);
                TempGenJnlLine.Init();
                TempGenJnlLine."Line No." := GenJnlLineNextNo;
                TempGenJnlLine."Posting Date" := PostingDate;
                TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                TempGenJnlLine."Document No." := PostedBillGr."No.";
                TempGenJnlLine."Reason Code" := PostedBillGr."Reason Code";
                TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::Customer);
                CustLedgEntry.Get(PostedDoc."Entry No.");

                if GLSetup."Unrealized VAT" and (PostedDoc."Document Type" = PostedDoc."Document Type"::Bill) then begin
                    FromJnl := false;
                    if PostedDoc."From Journal" then
                        FromJnl := true;
                    ExistsNoRealVAT := GenJnlPostLine.CustFindVATSetup(VATPostingSetup, CustLedgEntry, FromJnl)
                end;

                OnAfterGetPostedDocOnBeforeValidateAccountNo(
                  TempGenJnlLine, PostedDoc, VATPostingSetup, CustLedgEntry, FromJnl, ExistsNoRealVAT);
                TempGenJnlLine.Validate("Account No.", CustLedgEntry."Customer No.");
                TempGenJnlLine.Validate("Salespers./Purch. Code", CustLedgEntry."Salesperson Code");
                TempGenJnlLine.Validate("Posting Group", CustLedgEntry."Customer Posting Group");
                if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
                    TempGenJnlLine.Description := CopyStr(
                        StrSubstNo(Text1100001Lbl, PostedDoc."Document No.", PostedDoc."No."),
                        1, MaxStrLen(TempGenJnlLine.Description))
                else
                    TempGenJnlLine.Description := CopyStr(
                        StrSubstNo(Text1100002Lbl, PostedDoc."Document No."),
                        1, MaxStrLen(TempGenJnlLine.Description));
                TempGenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
                if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlCust(TempGenJnlLine, CustLedgEntry, 0, false) then
                    TempGenJnlLine.Validate(Amount, -PostedDoc."Remaining Amount" + CustLedgEntry."Remaining Pmt. Disc. Possible")
                else
                    TempGenJnlLine.Validate(Amount, -PostedDoc."Remaining Amount");
                TempGenJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
                TempGenJnlLine."Applies-to Doc. No." := CustLedgEntry."Document No.";
                TempGenJnlLine."Applies-to Bill No." := CustLedgEntry."Bill No.";
                TempGenJnlLine."Source Code" := SourceCode;
                TempGenJnlLine."System-Created Entry" := true;
                TempGenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
                TempGenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
                TempGenJnlLine."Dimension Set ID" :=
                  CarteraManagement.GetDimSetIDFromCustLedgEntry(TempGenJnlLine, CustLedgEntry, true);
                OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry, PostedBillGr);
                TempGenJnlLine.Insert();
                SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";

                if ("Document Type" = "Document Type"::Bill) and
                   GLSetup."Unrealized VAT" and
                   ExistsNoRealVAT and
                   (not IsRedrawn)
                then begin
                    CustLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                    OnBeforeCustUnrealizedVAT2(PostedDoc, TempGenJnlLine, CustLedgEntry, PostedBillGr, TempNoRealVATBuffer);
                    CarteraManagement.CustUnrealizedVAT2(
                      CustLedgEntry,
                      CustLedgEntry."Remaining Amt. (LCY)",
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
                              "Global Dimension 1 Code",
                              "Global Dimension 2 Code",
                              "Dimension Set ID");
                            InsertGenJournalLine(
                              TempGenJnlLine."Account Type"::"G/L Account",
                              TempNoRealVATBuffer."Balance Account",
                              -TempNoRealVATBuffer.Amount,
                              "Global Dimension 1 Code",
                              "Global Dimension 2 Code",
                              "Dimension Set ID");
                        until TempNoRealVATBuffer.Next() = 0;
                        TempNoRealVATBuffer.DeleteAll();
                    end;
                    "Currency Code" := TempCurrCode;
                end;

                if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlCust(TempGenJnlLine, CustLedgEntry, 0, false) then
                    CalcBankAccount("No.", "Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible", CustLedgEntry."Entry No.")
                else
                    CalcBankAccount("No.", "Remaining Amount", CustLedgEntry."Entry No.");

                GroupAmount := GroupAmount + "Remaining Amount";
                CustLedgEntry."Document Status" := CustLedgEntry."Document Status"::Honored;
                CustLedgEntry.Modify();

                if (PostedBillGr."Dealing Type" = PostedBillGr."Dealing Type"::Discount) and
                   (PostedBillGr.Factoring <> PostedBillGr.Factoring::" ")
                then
                    DiscFactLiabs(PostedDoc);
            end;

            trigger OnPostDataItem()
            var
                CustLedgEntry2: Record "Cust. Ledger Entry";
                PostedDoc2: Record "Posted Cartera Doc.";
                IsHandled: Boolean;
            begin
                if (DocCount = 0) or (GroupAmount = 0) then begin
                    if OnlyDueDocuments then
                        Error(NoDueReceivableDocumentsErr);

                    Error(NoReceivableDocumentsErr);
                end;
                IsHandled := false;
                OnPostDataItemOnBeforeBankAccPostBufferLoop(TempBankAccPostBuffer, PostedDoc, PostedBillGr, TempGenJnlLine, GenJnlLineNextNo, SumLCYAmt, PostingDate, SourceCode, IsHandled);
                if not IsHandled and TempBankAccPostBuffer.Find('-') then
                    repeat
                        CustLedgEntry2.Get(TempBankAccPostBuffer."Entry No.");
                        PostedDoc2.Get(0, CustLedgEntry2."Entry No.");
                        PostedBillGr.Get(PostedDoc2."Bill Gr./Pmt. Order No.");
                        BankAcc.Get(PostedBillGr."Bank Account No.");
                        if PostedBillGr.Factoring = PostedBillGr.Factoring::" " then begin
                            GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                            Clear(TempGenJnlLine);
                            TempGenJnlLine.Init();
                            TempGenJnlLine."Line No." := GenJnlLineNextNo;
                            TempGenJnlLine."Posting Date" := PostingDate;
                            TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                            TempGenJnlLine."Document No." := PostedBillGr."No.";
                            TempGenJnlLine."Reason Code" := PostedBillGr."Reason Code";
                            if PostedBillGr."Dealing Type" = PostedBillGr."Dealing Type"::Discount then begin
                                BankAcc.TestField("Bank Acc. Posting Group");
                                BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                                TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"G/L Account");
                                BankAccPostingGr.TestField("Liabs. for Disc. Bills Acc.");
                                TempGenJnlLine.Validate("Account No.", BankAccPostingGr."Liabs. for Disc. Bills Acc.");
                                TempGenJnlLine.Validate("Source Type", TempGenJnlLine."Source Type"::"Bank Account");
                                TempGenJnlLine.Validate("Source No.", BankAcc."No.");
                            end else begin
                                TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"Bank Account");
                                TempGenJnlLine.Validate("Account No.", BankAcc."No.");
                            end;
                            TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100006Lbl, PostedBillGr."No."), 1, MaxStrLen(TempGenJnlLine.Description));
                            TempGenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
                            TempGenJnlLine.Validate(Amount, TempBankAccPostBuffer.Amount);
                            TempGenJnlLine."Source Code" := SourceCode;
                            TempGenJnlLine."System-Created Entry" := true;
                            TempGenJnlLine."Shortcut Dimension 1 Code" := TempBankAccPostBuffer."Global Dimension 1 Code";
                            TempGenJnlLine."Shortcut Dimension 2 Code" := TempBankAccPostBuffer."Global Dimension 2 Code";
                            TempGenJnlLine."Dimension Set ID" :=
                              CarteraManagement.GetDimSetIDFromCustLedgEntry(TempGenJnlLine, CustLedgEntry2, true);
                            OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                            TempGenJnlLine.Insert();
                            SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
                        end; // else
                             // FactBankAccounting;
                    until TempBankAccPostBuffer.Next() = 0;

                if PostedBillGr.Factoring <> PostedBillGr.Factoring::" " then
                    FactBankAccounting();

                if PostedBillGr."Currency Code" <> '' then
                    if SumLCYAmt <> 0 then begin
                        Currency.SetFilter(Code, PostedBillGr."Currency Code");
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
                        TempGenJnlLine."Posting Date" := PostingDate;
                        TempGenJnlLine."Document No." := PostedBillGr."No.";
                        TempGenJnlLine."Reason Code" := PostedBillGr."Reason Code";
                        TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"G/L Account");
                        TempGenJnlLine.Validate("Account No.", Acct);
                        TempGenJnlLine.Description := Text1100007Lbl;
                        TempGenJnlLine.Validate("Currency Code", '');
                        TempGenJnlLine.Validate(Amount, -SumLCYAmt);
                        TempGenJnlLine."Source Code" := SourceCode;
                        TempGenJnlLine."System-Created Entry" := true;
                        TempGenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry2."Global Dimension 1 Code";
                        TempGenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry2."Global Dimension 2 Code";
                        TempGenJnlLine."Dimension Set ID" :=
                          CarteraManagement.GetDimSetIDFromCustLedgEntry(TempGenJnlLine, CustLedgEntry2, true);
                        OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                        TempGenJnlLine.Insert();
                    end;

                PostedBillGr.Modify();
                OnBeforePostSettlementForPostedBillGroup(TempGenJnlLine, PostedBillGr, PostingDate);
                DocPost.PostSettlementForPostedBillGroup(TempGenJnlLine, PostingDate);
                OnAfterPostSettlementForPostedBillGroup(TempGenJnlLine, PostedBillGr, PostingDate);

                Window.Close();

                if ExistVATEntry then begin
                    GLReg.FindLast();
                    GLReg."From VAT Entry No." := FirstVATEntryNo;
                    GLReg."To VAT Entry No." := LastVATEntryNo;
                    GLReg.Modify();
                end;

                Commit();

                if not HidePrintDialog then
                    Message(Text1100008Lbl, DocCount, GroupAmount);
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
                  Text1100000Lbl);
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
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the posting date.';
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
        PostingDate := WorkDate();
    end;

    trigger OnPreReport()
    begin
        GLSetup.Get();
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        PostedBillGr: Record "Posted Bill Group";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccPostingGr: Record "Bank Account Posting Group";
        BankAcc: Record "Bank Account";
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        GLReg: Record "G/L Register";
        VATPostingSetup: Record "VAT Posting Setup";
        TempBankAccPostBuffer: Record "BG/PO Post. Buffer" temporary;
        TempNoRealVATBuffer: Record "BG/PO Post. Buffer" temporary;
        DocPost: Codeunit "Document-Post";
        CarteraManagement: Codeunit CarteraManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        Text1100000Lbl: Label 'Settling receivable documents         #1######', Comment = '#1 = Number of documents settled';
        Text1100001Lbl: Label 'Bill settlement %1/%2', Comment = '%1 = Document number, %2 = Bill number';
        Text1100002Lbl: Label 'Document settlement %1', Comment = '%1 = Document number';
        NoDueReceivableDocumentsErr: Label 'No receivable documents have been found that can be settled. Please check that the selection is not empty and at least one receivable document is open and due.';
        NoReceivableDocumentsErr: Label 'No receivable documents have been found that can be settled. Please check that the selection is not empty and at least one receivable document is open.';
        Text1100006Lbl: Label 'Bill Group settlement %1', Comment = '%1 = Bill group number';
        Text1100007Lbl: Label 'Residual adjust generated by rounding Amount';
        Text1100008Lbl: Label '%1 receivable documents totaling %2 have been settled.', Comment = '%1 = Number of documents settled, %2 = Total amount settled';
        Text1100009Lbl: Label 'Bill Group settlement %1 Customer No. %2', Comment = '%1 = Bill group number, %2 = Customer number';
        Text1100010Lbl: Label 'Receivable document settlement %1/%2', Comment = '%1 = Document number, %2 = Bill number';
        Window: Dialog;
        OnlyDueDocuments: Boolean;
        Delay: Decimal;
        SourceCode: Code[10];
        Acct: Code[20];
        DocCount: Integer;
        GroupAmount: Decimal;
        GenJnlLineNextNo: Integer;
        SumLCYAmt: Decimal;
        TotalDisctdAmt: Decimal;
        ExistVATEntry: Boolean;
        IsRedrawn: Boolean;
        FirstVATEntryNo: Integer;
        LastVATEntryNo: Integer;
        TempCurrCode: Code[10];
        ExistsNoRealVAT: Boolean;
        HidePrintDialog: Boolean;

    protected var
        // Preserve the published protected variable name for report extensions.
#pragma warning disable AA0204
        PostingDate: Date;
#pragma warning restore AA0204

    [Scope('OnPrem')]
    procedure DiscFactLiabs(PostedDoc2: Record "Posted Cartera Doc.")
    var
        Currency2: Record Currency;
        DisctedAmt: Decimal;
        RoundingPrec: Decimal;
    begin
        DisctedAmt := 0;
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        if PostedDoc2."Currency Code" <> '' then begin
            Currency2.Get(PostedDoc2."Currency Code");
            RoundingPrec := Currency2."Amount Rounding Precision";
        end else
            RoundingPrec := GLSetup."Amount Rounding Precision";

        DisctedAmt := Round(DocPost.FindDisctdAmt(
              PostedDoc2."Remaining Amount",
              PostedDoc2."Account No.",
              PostedDoc2."Bank Account No."), RoundingPrec);

        CalcBankAccount(PostedDoc2."No.", -DisctedAmt, CustLedgEntry."Entry No.");
        TotalDisctdAmt := TotalDisctdAmt + DisctedAmt;

        Clear(TempGenJnlLine);
        TempGenJnlLine.Init();
        TempGenJnlLine."Line No." := GenJnlLineNextNo;
        TempGenJnlLine."Posting Date" := PostingDate;
        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
        TempGenJnlLine."Document No." := PostedBillGr."No.";
        TempGenJnlLine."Reason Code" := PostedBillGr."Reason Code";
        BankAcc.TestField("Bank Acc. Posting Group");
        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
        TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"G/L Account");
        BankAccPostingGr.TestField("Liabs. for Factoring Acc.");
        TempGenJnlLine.Validate("Account No.", BankAccPostingGr."Liabs. for Factoring Acc.");
        TempGenJnlLine.Description := CopyStr(
            StrSubstNo(Text1100009Lbl,
              PostedBillGr."No.",
              PostedDoc2."Account No."), 1, MaxStrLen(TempGenJnlLine.Description));
        TempGenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
        TempGenJnlLine.Validate(Amount, DisctedAmt);
        TempGenJnlLine."Source Code" := SourceCode;
        TempGenJnlLine."System-Created Entry" := true;
        TempGenJnlLine."Shortcut Dimension 1 Code" := PostedDoc2."Global Dimension 1 Code";
        TempGenJnlLine."Shortcut Dimension 2 Code" := PostedDoc2."Global Dimension 2 Code";
        TempGenJnlLine."Dimension Set ID" := PostedDoc2."Dimension Set ID";
        OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry, PostedBillGr);
        TempGenJnlLine.Insert();
        SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
    end;

    [Scope('OnPrem')]
    procedure FactBankAccounting()
    var
        CustLedgEntry2: Record "Cust. Ledger Entry";
    begin
        case true of
            PostedDoc."Dealing Type" = PostedDoc."Dealing Type"::Discount:
                if TempBankAccPostBuffer.Find('-') then
                    repeat
                        GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                        CustLedgEntry2.Get(TempBankAccPostBuffer."Entry No.");
                        Clear(TempGenJnlLine);
                        TempGenJnlLine.Init();
                        TempGenJnlLine."Line No." := GenJnlLineNextNo;
                        TempGenJnlLine."Posting Date" := PostingDate;
                        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                        TempGenJnlLine."Document No." := PostedBillGr."No.";
                        TempGenJnlLine."Reason Code" := PostedBillGr."Reason Code";
                        BankAcc.TestField("Bank Acc. Posting Group");
                        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                        TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"Bank Account");
                        TempGenJnlLine.Validate("Account No.", BankAcc."No.");
                        TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100006Lbl, PostedBillGr."No."), 1, MaxStrLen(TempGenJnlLine.Description));
                        TempGenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
                        // VALIDATE(Amount,GroupAmount - TotalDisctdAmt);
                        TempGenJnlLine.Validate(Amount, TempBankAccPostBuffer.Amount);
                        TempGenJnlLine."Source Code" := SourceCode;
                        TempGenJnlLine."System-Created Entry" := true;
                        TempGenJnlLine."Shortcut Dimension 1 Code" := TempBankAccPostBuffer."Global Dimension 1 Code";
                        TempGenJnlLine."Shortcut Dimension 2 Code" := TempBankAccPostBuffer."Global Dimension 2 Code";
                        TempGenJnlLine."Dimension Set ID" := TempBankAccPostBuffer."Dimension Set ID";
                        OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                        TempGenJnlLine.Insert();
                        SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
                    until TempBankAccPostBuffer.Next() = 0;
            else
                if TempBankAccPostBuffer.Find('-') then
                    repeat
                        GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                        CustLedgEntry2.Get(TempBankAccPostBuffer."Entry No.");
                        Clear(TempGenJnlLine);
                        TempGenJnlLine.Init();
                        TempGenJnlLine."Line No." := GenJnlLineNextNo;
                        TempGenJnlLine."Posting Date" := PostingDate;
                        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                        TempGenJnlLine."Document No." := PostedBillGr."No.";
                        TempGenJnlLine."Reason Code" := PostedBillGr."Reason Code";
                        BankAcc.TestField("Bank Acc. Posting Group");
                        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                        TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"Bank Account");
                        TempGenJnlLine.Validate("Account No.", BankAcc."No.");
                        TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100006Lbl, PostedBillGr."No."), 1, MaxStrLen(TempGenJnlLine.Description));
                        TempGenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
                        TempGenJnlLine.Validate(Amount, TempBankAccPostBuffer.Amount);
                        TempGenJnlLine."Source Code" := SourceCode;
                        TempGenJnlLine."System-Created Entry" := true;
                        TempGenJnlLine."Shortcut Dimension 1 Code" := TempBankAccPostBuffer."Global Dimension 1 Code";
                        TempGenJnlLine."Shortcut Dimension 2 Code" := TempBankAccPostBuffer."Global Dimension 2 Code";
                        TempGenJnlLine."Dimension Set ID" := TempBankAccPostBuffer."Dimension Set ID";
                        OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                        TempGenJnlLine.Insert();
                        SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
                    until TempBankAccPostBuffer.Next() = 0;
        end;
    end;

    local procedure InsertGenJournalLine(AccType: enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount2: Decimal; Dep: Code[20]; Proj: Code[20]; DimSetID: Integer)
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        Clear(TempGenJnlLine);
        TempGenJnlLine.Init();
        TempGenJnlLine."Line No." := GenJnlLineNextNo;
        TempGenJnlLine."Posting Date" := PostingDate;
        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
        TempGenJnlLine."Document No." := PostedBillGr."No.";
        TempGenJnlLine."Reason Code" := PostedBillGr."Reason Code";
        TempGenJnlLine."Account Type" := AccType;
        TempGenJnlLine."Account No." := AccNo;
        TempGenJnlLine.Description := CopyStr(
            StrSubstNo(Text1100010Lbl, PostedDoc."Document No.", PostedDoc."No."),
            1, MaxStrLen(TempGenJnlLine.Description));
        TempGenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
        TempGenJnlLine.Validate(Amount, -Amount2);
        TempGenJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
        TempGenJnlLine."Applies-to Doc. No." := '';
        TempGenJnlLine."Applies-to Bill No." := CustLedgEntry."Bill No.";
        TempGenJnlLine."Source Code" := SourceCode;
        TempGenJnlLine."System-Created Entry" := true;
        TempGenJnlLine."Shortcut Dimension 1 Code" := Dep;
        TempGenJnlLine."Shortcut Dimension 2 Code" := Proj;
        TempGenJnlLine."Dimension Set ID" := DimSetID;
        SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
        OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry, PostedBillGr);
        TempGenJnlLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure CalcBankAccount(BankAcc2: Code[20]; Amount2: Decimal; EntryNo: Integer)
    var
        IsHandled: Boolean;
    begin
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
            TempBankAccPostBuffer."Global Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
            TempBankAccPostBuffer."Global Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
            TempBankAccPostBuffer.Insert();
        end;
    end;

    procedure SetHidePrintDialog(NewHidePrintDialog: Boolean)
    begin
        HidePrintDialog := NewHidePrintDialog;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPostedDocOnBeforeValidateAccountNo(var GenJournalLine: Record "Gen. Journal Line"; var PostedCarteraDoc: Record "Posted Cartera Doc."; var VATPostingSetup: Record "VAT Posting Setup"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var FromJnl: Boolean; var ExistsNoRealVAT: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSettlementForPostedBillGroup(var GenJournalLine: Record "Gen. Journal Line"; PostedBillGroup: Record "Posted Bill Group"; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBankAccount(BankAcc2: Code[20]; Amount2: Decimal; EntryNo: Integer; var BgPoPostBuffer: Record "BG/PO Post. Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustUnrealizedVAT2(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var PostedBillGroup: Record "Posted Bill Group"; var BgPoPostBuffer: Record "BG/PO Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJournalLineInsert(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var CustLedgerEntry2: Record "Cust. Ledger Entry"; var PostedBillGroup: Record "Posted Bill Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSettlementForPostedBillGroup(var GenJournalLine: Record "Gen. Journal Line"; PostedBillGroup: Record "Posted Bill Group"; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDataItemOnBeforeBankAccPostBufferLoop(var BankAccPostBuffer: Record "BG/PO Post. Buffer" temporary; PostedDoc: Record "Posted Cartera Doc."; PostedBillGr: Record "Posted Bill Group"; var GenJnlLine: Record "Gen. Journal Line"; var GenJnlLineNextNo: Integer; var SumLCYAmt: Decimal; PostingDate: Date; SourceCode: Code[10]; var IsHandled: Boolean)
    begin
    end;
}

