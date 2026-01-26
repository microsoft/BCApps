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

                if DueOnly and (PostingDate < "Due Date" + Delay) then
                    CurrReport.Skip();

                DocCount := DocCount + 1;
                Window.Update(1, DocCount);

                GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                Clear(GenJnlLine);
                GenJnlLine.Init();
                GenJnlLine."Line No." := GenJnlLineNextNo;
                GenJnlLine."Posting Date" := PostingDate;
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                GenJnlLine."Document No." := PostedBillGr."No.";
                GenJnlLine."Reason Code" := PostedBillGr."Reason Code";
                GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
                CustLedgEntry.Get(PostedDoc."Entry No.");

                if GLSetup."Unrealized VAT" and (PostedDoc."Document Type" = PostedDoc."Document Type"::Bill) then begin
                    FromJnl := false;
                    if PostedDoc."From Journal" then
                        FromJnl := true;
                    ExistsNoRealVAT := GenJnlPostLine.CustFindVATSetup(VATPostingSetup, CustLedgEntry, FromJnl)
                end;

                OnAfterGetPostedDocOnBeforeValidateAccountNo(
                  GenJnlLine, PostedDoc, VATPostingSetup, CustLedgEntry, FromJnl, ExistsNoRealVAT);
                GenJnlLine.Validate("Account No.", CustLedgEntry."Customer No.");
                GenJnlLine.Validate("Salespers./Purch. Code", CustLedgEntry."Salesperson Code");
                GenJnlLine.Validate("Posting Group", CustLedgEntry."Customer Posting Group");
                if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
                    GenJnlLine.Description := CopyStr(
                        StrSubstNo(Text1100001, PostedDoc."Document No.", PostedDoc."No."),
                        1, MaxStrLen(GenJnlLine.Description))
                else
                    GenJnlLine.Description := CopyStr(
                        StrSubstNo(Text1100002, PostedDoc."Document No."),
                        1, MaxStrLen(GenJnlLine.Description));
                GenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
                if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlCust(GenJnlLine, CustLedgEntry, 0, false) then
                    GenJnlLine.Validate(Amount, -PostedDoc."Remaining Amount" + CustLedgEntry."Remaining Pmt. Disc. Possible")
                else
                    GenJnlLine.Validate(Amount, -PostedDoc."Remaining Amount");
                GenJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
                GenJnlLine."Applies-to Doc. No." := CustLedgEntry."Document No.";
                GenJnlLine."Applies-to Bill No." := CustLedgEntry."Bill No.";
                GenJnlLine."Source Code" := SourceCode;
                GenJnlLine."System-Created Entry" := true;
                GenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" :=
                  CarteraManagement.GetDimSetIDFromCustLedgEntry(GenJnlLine, CustLedgEntry, true);
                OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry, PostedBillGr);
                GenJnlLine.Insert();
                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";

                if ("Document Type" = "Document Type"::Bill) and
                   GLSetup."Unrealized VAT" and
                   ExistsNoRealVAT and
                   (not IsRedrawn)
                then begin
                    CustLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                    OnBeforeCustUnrealizedVAT2(PostedDoc, GenJnlLine, CustLedgEntry, PostedBillGr, NoRealVATBuffer);
                    CarteraManagement.CustUnrealizedVAT2(
                      CustLedgEntry,
                      CustLedgEntry."Remaining Amt. (LCY)",
                      GenJnlLine,
                      ExistVATEntry,
                      FirstVATEntryNo,
                      LastVATEntryNo,
                      NoRealVATBuffer,
                      FromJnl,
                      "Document No.");

                    TempCurrCode := "Currency Code";
                    "Currency Code" := '';

                    if NoRealVATBuffer.Find('-') then begin
                        repeat
                            InsertGenJournalLine(
                              GenJnlLine."Account Type"::"G/L Account",
                              NoRealVATBuffer.Account,
                              NoRealVATBuffer.Amount,
                              "Global Dimension 1 Code",
                              "Global Dimension 2 Code",
                              "Dimension Set ID");
                            InsertGenJournalLine(
                              GenJnlLine."Account Type"::"G/L Account",
                              NoRealVATBuffer."Balance Account",
                              -NoRealVATBuffer.Amount,
                              "Global Dimension 1 Code",
                              "Global Dimension 2 Code",
                              "Dimension Set ID");
                        until NoRealVATBuffer.Next() = 0;
                        NoRealVATBuffer.DeleteAll();
                    end;
                    "Currency Code" := TempCurrCode;
                end;

                if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlCust(GenJnlLine, CustLedgEntry, 0, false) then
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
                    if DueOnly then
                        Error(
                          Text1100003 +
                          Text1100004);

                    Error(
                      Text1100003 +
                      Text1100005);
                end;
                IsHandled := false;
                OnPostDataItemOnBeforeBankAccPostBufferLoop(BankAccPostBuffer, PostedDoc, PostedBillGr, GenJnlLine, GenJnlLineNextNo, SumLCYAmt, PostingDate, SourceCode, IsHandled);
                if not IsHandled and BankAccPostBuffer.Find('-') then
                    repeat
                        CustLedgEntry2.Get(BankAccPostBuffer."Entry No.");
                        PostedDoc2.Get(0, CustLedgEntry2."Entry No.");
                        PostedBillGr.Get(PostedDoc2."Bill Gr./Pmt. Order No.");
                        BankAcc.Get(PostedBillGr."Bank Account No.");
                        if PostedBillGr.Factoring = PostedBillGr.Factoring::" " then begin
                            GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                            Clear(GenJnlLine);
                            GenJnlLine.Init();
                            GenJnlLine."Line No." := GenJnlLineNextNo;
                            GenJnlLine."Posting Date" := PostingDate;
                            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                            GenJnlLine."Document No." := PostedBillGr."No.";
                            GenJnlLine."Reason Code" := PostedBillGr."Reason Code";
                            if PostedBillGr."Dealing Type" = PostedBillGr."Dealing Type"::Discount then begin
                                BankAcc.TestField("Bank Acc. Posting Group");
                                BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                                GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
                                BankAccPostingGr.TestField("Liabs. for Disc. Bills Acc.");
                                GenJnlLine.Validate("Account No.", BankAccPostingGr."Liabs. for Disc. Bills Acc.");
                                GenJnlLine.Validate("Source Type", GenJnlLine."Source Type"::"Bank Account");
                                GenJnlLine.Validate("Source No.", BankAcc."No.");
                            end else begin
                                GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Bank Account");
                                GenJnlLine.Validate("Account No.", BankAcc."No.");
                            end;
                            GenJnlLine.Description := CopyStr(StrSubstNo(Text1100006, PostedBillGr."No."), 1, MaxStrLen(GenJnlLine.Description));
                            GenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
                            GenJnlLine.Validate(Amount, BankAccPostBuffer.Amount);
                            GenJnlLine."Source Code" := SourceCode;
                            GenJnlLine."System-Created Entry" := true;
                            GenJnlLine."Shortcut Dimension 1 Code" := BankAccPostBuffer."Global Dimension 1 Code";
                            GenJnlLine."Shortcut Dimension 2 Code" := BankAccPostBuffer."Global Dimension 2 Code";
                            GenJnlLine."Dimension Set ID" :=
                              CarteraManagement.GetDimSetIDFromCustLedgEntry(GenJnlLine, CustLedgEntry2, true);
                            OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                            GenJnlLine.Insert();
                            SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                        end; // else
                             // FactBankAccounting;
                    until BankAccPostBuffer.Next() = 0;

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
                        Clear(GenJnlLine);
                        GenJnlLine.Init();
                        GenJnlLine."Line No." := GenJnlLineNextNo;
                        GenJnlLine."Posting Date" := PostingDate;
                        GenJnlLine."Document No." := PostedBillGr."No.";
                        GenJnlLine."Reason Code" := PostedBillGr."Reason Code";
                        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
                        GenJnlLine.Validate("Account No.", Acct);
                        GenJnlLine.Description := Text1100007;
                        GenJnlLine.Validate("Currency Code", '');
                        GenJnlLine.Validate(Amount, -SumLCYAmt);
                        GenJnlLine."Source Code" := SourceCode;
                        GenJnlLine."System-Created Entry" := true;
                        GenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry2."Global Dimension 1 Code";
                        GenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry2."Global Dimension 2 Code";
                        GenJnlLine."Dimension Set ID" :=
                          CarteraManagement.GetDimSetIDFromCustLedgEntry(GenJnlLine, CustLedgEntry2, true);
                        OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                        GenJnlLine.Insert();
                    end;

                PostedBillGr.Modify();
                OnBeforePostSettlementForPostedBillGroup(GenJnlLine, PostedBillGr, PostingDate);
                DocPost.PostSettlementForPostedBillGroup(GenJnlLine, PostingDate);
                OnAfterPostSettlementForPostedBillGroup(GenJnlLine, PostedBillGr, PostingDate);

                Window.Close();

                if ExistVATEntry then begin
                    GLReg.FindLast();
                    GLReg."From VAT Entry No." := FirstVATEntryNo;
                    GLReg."To VAT Entry No." := LastVATEntryNo;
                    GLReg.Modify();
                end;

                Commit();

                if not HidePrintDialog then
                    Message(Text1100008, DocCount, GroupAmount);
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
                    field(DueOnly; DueOnly)
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
        Text1100000: Label 'Settling receivable documents         #1######';
        Text1100001: Label 'Bill settlement %1/%2';
        Text1100002: Label 'Document settlement %1';
        Text1100003: Label 'No receivable documents have been found that can be settled.';
        Text1100004: Label 'Please check that the selection is not empty and at least one receivable documents is open and due.';
        Text1100005: Label 'Please check that the selection is not empty and at least one receivable documents is open.';
        Text1100006: Label 'Bill Group settlement %1';
        Text1100007: Label 'Residual adjust generated by rounding Amount';
        Text1100008: Label '%1 receivable documents totaling %2 have been settled.';
        Text1100009: Label 'Bill Group settlement %1 Customer No. %2';
        Text1100010: Label 'Receivable document settlement %1/%2';
        SourceCodeSetup: Record "Source Code Setup";
        PostedBillGr: Record "Posted Bill Group";
        GenJnlLine: Record "Gen. Journal Line" temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccPostingGr: Record "Bank Account Posting Group";
        BankAcc: Record "Bank Account";
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        GLReg: Record "G/L Register";
        VATPostingSetup: Record "VAT Posting Setup";
        BankAccPostBuffer: Record "BG/PO Post. Buffer" temporary;
        NoRealVATBuffer: Record "BG/PO Post. Buffer" temporary;
        DocPost: Codeunit "Document-Post";
        CarteraManagement: Codeunit CarteraManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        Window: Dialog;
        DueOnly: Boolean;
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
        PostingDate: Date;

    [Scope('OnPrem')]
    procedure DiscFactLiabs(PostedDoc2: Record "Posted Cartera Doc.")
    var
        DisctedAmt: Decimal;
        Currency2: Record Currency;
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

        Clear(GenJnlLine);
        GenJnlLine.Init();
        GenJnlLine."Line No." := GenJnlLineNextNo;
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := PostedBillGr."No.";
        GenJnlLine."Reason Code" := PostedBillGr."Reason Code";
        BankAcc.TestField("Bank Acc. Posting Group");
        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
        BankAccPostingGr.TestField("Liabs. for Factoring Acc.");
        GenJnlLine.Validate("Account No.", BankAccPostingGr."Liabs. for Factoring Acc.");
        GenJnlLine.Description := CopyStr(
            StrSubstNo(Text1100009,
              PostedBillGr."No.",
              PostedDoc2."Account No."), 1, MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
        GenJnlLine.Validate(Amount, DisctedAmt);
        GenJnlLine."Source Code" := SourceCode;
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Shortcut Dimension 1 Code" := PostedDoc2."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := PostedDoc2."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := PostedDoc2."Dimension Set ID";
        OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry, PostedBillGr);
        GenJnlLine.Insert();
        SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
    end;

    [Scope('OnPrem')]
    procedure FactBankAccounting()
    var
        CustLedgEntry2: Record "Cust. Ledger Entry";
    begin
        case true of
            PostedDoc."Dealing Type" = PostedDoc."Dealing Type"::Discount:
                if BankAccPostBuffer.Find('-') then
                    repeat
                        GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                        CustLedgEntry2.Get(BankAccPostBuffer."Entry No.");
                        Clear(GenJnlLine);
                        GenJnlLine.Init();
                        GenJnlLine."Line No." := GenJnlLineNextNo;
                        GenJnlLine."Posting Date" := PostingDate;
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                        GenJnlLine."Document No." := PostedBillGr."No.";
                        GenJnlLine."Reason Code" := PostedBillGr."Reason Code";
                        BankAcc.TestField("Bank Acc. Posting Group");
                        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Bank Account");
                        GenJnlLine.Validate("Account No.", BankAcc."No.");
                        GenJnlLine.Description := CopyStr(StrSubstNo(Text1100006, PostedBillGr."No."), 1, MaxStrLen(GenJnlLine.Description));
                        GenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
                        // VALIDATE(Amount,GroupAmount - TotalDisctdAmt);
                        GenJnlLine.Validate(Amount, BankAccPostBuffer.Amount);
                        GenJnlLine."Source Code" := SourceCode;
                        GenJnlLine."System-Created Entry" := true;
                        GenJnlLine."Shortcut Dimension 1 Code" := BankAccPostBuffer."Global Dimension 1 Code";
                        GenJnlLine."Shortcut Dimension 2 Code" := BankAccPostBuffer."Global Dimension 2 Code";
                        GenJnlLine."Dimension Set ID" := BankAccPostBuffer."Dimension Set ID";
                        OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                        GenJnlLine.Insert();
                        SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                    until BankAccPostBuffer.Next() = 0;
            else
                if BankAccPostBuffer.Find('-') then
                    repeat
                        GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                        CustLedgEntry2.Get(BankAccPostBuffer."Entry No.");
                        Clear(GenJnlLine);
                        GenJnlLine.Init();
                        GenJnlLine."Line No." := GenJnlLineNextNo;
                        GenJnlLine."Posting Date" := PostingDate;
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                        GenJnlLine."Document No." := PostedBillGr."No.";
                        GenJnlLine."Reason Code" := PostedBillGr."Reason Code";
                        BankAcc.TestField("Bank Acc. Posting Group");
                        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Bank Account");
                        GenJnlLine.Validate("Account No.", BankAcc."No.");
                        GenJnlLine.Description := CopyStr(StrSubstNo(Text1100006, PostedBillGr."No."), 1, MaxStrLen(GenJnlLine.Description));
                        GenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
                        GenJnlLine.Validate(Amount, BankAccPostBuffer.Amount);
                        GenJnlLine."Source Code" := SourceCode;
                        GenJnlLine."System-Created Entry" := true;
                        GenJnlLine."Shortcut Dimension 1 Code" := BankAccPostBuffer."Global Dimension 1 Code";
                        GenJnlLine."Shortcut Dimension 2 Code" := BankAccPostBuffer."Global Dimension 2 Code";
                        GenJnlLine."Dimension Set ID" := BankAccPostBuffer."Dimension Set ID";
                        OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                        GenJnlLine.Insert();
                        SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                    until BankAccPostBuffer.Next() = 0;
        end;
    end;

    local procedure InsertGenJournalLine(AccType: enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount2: Decimal; Dep: Code[20]; Proj: Code[20]; DimSetID: Integer)
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        Clear(GenJnlLine);
        GenJnlLine.Init();
        GenJnlLine."Line No." := GenJnlLineNextNo;
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := PostedBillGr."No.";
        GenJnlLine."Reason Code" := PostedBillGr."Reason Code";
        GenJnlLine."Account Type" := AccType;
        GenJnlLine."Account No." := AccNo;
        GenJnlLine.Description := CopyStr(
            StrSubstNo(Text1100010, PostedDoc."Document No.", PostedDoc."No."),
            1, MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
        GenJnlLine.Validate(Amount, -Amount2);
        GenJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
        GenJnlLine."Applies-to Doc. No." := '';
        GenJnlLine."Applies-to Bill No." := CustLedgEntry."Bill No.";
        GenJnlLine."Source Code" := SourceCode;
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Shortcut Dimension 1 Code" := Dep;
        GenJnlLine."Shortcut Dimension 2 Code" := Proj;
        GenJnlLine."Dimension Set ID" := DimSetID;
        SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
        OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry, PostedBillGr);
        GenJnlLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure CalcBankAccount(BankAcc2: Code[20]; Amount2: Decimal; EntryNo: Integer)
    var
        IsHandled: Boolean;
    begin
        OnBeforeCalcBankAccount(BankAcc2, Amount2, EntryNo, BankAccPostBuffer, IsHandled);
        if IsHandled then
            exit;

        if BankAccPostBuffer.Get(BankAcc2, '', EntryNo) then begin
            BankAccPostBuffer.Amount := BankAccPostBuffer.Amount + Amount2;
            BankAccPostBuffer.Modify();
        end else begin
            BankAccPostBuffer.Init();
            BankAccPostBuffer.Account := BankAcc2;
            BankAccPostBuffer.Amount := Amount2;
            BankAccPostBuffer."Entry No." := EntryNo;
            BankAccPostBuffer."Global Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
            BankAccPostBuffer."Global Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
            BankAccPostBuffer.Insert();
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

