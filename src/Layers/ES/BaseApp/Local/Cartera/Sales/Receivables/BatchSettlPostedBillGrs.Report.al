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

report 7000086 "Batch Settl. Posted Bill Grs."
{
    Caption = 'Batch Settl. Posted Bill Grs.';
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
        dataitem(PostedBillGr; "Posted Bill Group")
        {
            DataItemTableView = sorting("No.") order(ascending);
            dataitem(PostedDoc; "Posted Cartera Doc.")
            {
                DataItemLink = "Bill Gr./Pmt. Order No." = field("No.");
                DataItemTableView = sorting("Bill Gr./Pmt. Order No.", Status, "Category Code", Redrawn, "Due Date") where(Status = const(Open), Type = const(Receivable));

                trigger OnAfterGetRecord()
                var
                    FromJnl: Boolean;
                begin
                    IsRedrawn := CarteraManagement.CheckFromRedrawnDoc("No.");
                    BankAcc.Get(PostedBillGr."Bank Account No.");
                    OnReadPostedBillGroupOnAfterGetBankAcc(BankAcc);
                    Delay := BankAcc."Delay for Notices";
                    OnReadPostedBillGroupOnAfterSetDelay(BankAcc, Delay, PostedBillGr);

                    if DueOnly and (PostingDate < "Due Date" + Delay) then
                        CurrReport.Skip();

                    TotalDocCount := TotalDocCount + 1;
                    DocCount := DocCount + 1;
                    Window.Update(3, Round(DocCount / TotalDoc * 10000, 1));
                    Window.Update(4, StrSubstNo('%1 %2', "Document Type", "Document No."));

                    GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                    Clear(TempGenJnlLine);
                    TempGenJnlLine.Init();
                    TempGenJnlLine."Line No." := GenJnlLineNextNo;
                    TempGenJnlLine."Posting Date" := PostingDate;
                    TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                    TempGenJnlLine."Document No." := PostedBillGr."No.";
                    TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::Customer);
                    CustLedgEntry.Get(PostedDoc."Entry No.");
                    if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then begin
                        TempGenJnlLine.Description := CopyStr(
                            StrSubstNo(Text1100004Lbl, PostedDoc."Document No.", PostedDoc."No."),
                            1, MaxStrLen(TempGenJnlLine.Description));
                        if GLSetup."Unrealized VAT" then begin
                            FromJnl := false;
                            if PostedDoc."From Journal" then
                                FromJnl := true;
                            GenJnlPostLine.CustFindVATSetup(VATPostingSetup, CustLedgEntry, FromJnl);
                        end;
                    end else
                        TempGenJnlLine.Description := CopyStr(
                            StrSubstNo(Text1100005Lbl, PostedDoc."Document No."),
                            1, MaxStrLen(TempGenJnlLine.Description));
                    TempGenJnlLine.Validate("Account No.", CustLedgEntry."Customer No.");
                    TempGenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
                    TempGenJnlLine.Validate(Amount, -PostedDoc."Remaining Amount");
                    TempGenJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
                    TempGenJnlLine."Applies-to Doc. No." := CustLedgEntry."Document No.";
                    TempGenJnlLine."Applies-to Bill No." := CustLedgEntry."Bill No.";
                    TempGenJnlLine."Source Code" := SourceCode;
                    TempGenJnlLine."System-Created Entry" := true;
                    TempGenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
                    TempGenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
                    TempGenJnlLine."Dimension Set ID" := CustLedgEntry."Dimension Set ID";
                    OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry, PostedBillGr);
                    TempGenJnlLine.Insert();
                    SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";

                    if ("Document Type" = "Document Type"::Bill) and
                       GLSetup."Unrealized VAT" and
                       ExistVATEntry and
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
                        OnAfterCustUnrealizedVAT2(PostedDoc, TempGenJnlLine, CustLedgEntry, PostedBillGr, TempNoRealVATBuffer);

                        if TempNoRealVATBuffer.Find('-') then begin
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
                            TempNoRealVATBuffer.DeleteAll();
                        end;
                    end;

                    GroupAmount := GroupAmount + "Remaining Amount";
                    GroupAmountLCY := GroupAmountLCY + "Remaining Amt. (LCY)";
                    CustLedgEntry."Document Status" := CustLedgEntry."Document Status"::Honored;
                    CustLedgEntry.Modify();

                    if TempBGPOPostBuffer.Get('', '', CustLedgEntry."Entry No.") then begin
                        TempBGPOPostBuffer.Amount := TempBGPOPostBuffer.Amount + "Remaining Amount";
                        TempBGPOPostBuffer.Modify();
                    end else begin
                        TempBGPOPostBuffer.Init();
                        TempBGPOPostBuffer."Entry No." := CustLedgEntry."Entry No.";
                        TempBGPOPostBuffer.Amount := TempBGPOPostBuffer.Amount + "Remaining Amount";
                        TempBGPOPostBuffer.Insert();
                    end;

                    if (PostedBillGr."Dealing Type" = PostedBillGr."Dealing Type"::Discount) and
                       (PostedBillGr.Factoring <> PostedBillGr.Factoring::" ")
                    then
                        DiscFactLiabs(PostedDoc);
                end;

                trigger OnPostDataItem()
                var
                    CustLedgEntry2: Record "Cust. Ledger Entry";
                begin
                    if (DocCount = 0) or (GroupAmount = 0) then
                        CurrReport.Skip();

                    if PostedBillGr.Factoring = PostedBillGr.Factoring::" " then begin
                        CustLedgEntry2.Get(TempBGPOPostBuffer."Entry No.");
                        Clear(TempGenJnlLine);
                        TempGenJnlLine.Init();
                        GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                        TempGenJnlLine."Line No." := GenJnlLineNextNo;
                        TempGenJnlLine."Posting Date" := PostingDate;
                        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                        TempGenJnlLine."Document No." := PostedBillGr."No.";
                        if "Dealing Type" = "Dealing Type"::Discount then begin
                            BankAcc.TestField("Bank Acc. Posting Group");
                            BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                            TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"G/L Account");
                            BankAccPostingGr.TestField("Liabs. for Disc. Bills Acc.");
                            TempGenJnlLine.Validate("Account No.", BankAccPostingGr."Liabs. for Disc. Bills Acc.");
                        end else begin
                            TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"Bank Account");
                            TempGenJnlLine.Validate("Account No.", BankAcc."No.");
                        end;
                        TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100009Lbl, PostedBillGr."No."), 1, MaxStrLen(TempGenJnlLine.Description));
                        TempGenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
                        TempGenJnlLine.Validate(Amount, GroupAmount);
                        TempGenJnlLine."Source Code" := SourceCode;
                        TempGenJnlLine."System-Created Entry" := true;
                        TempGenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
                        TempGenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
                        TempGenJnlLine."Dimension Set ID" := CustLedgEntry."Dimension Set ID";
                        OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                        TempGenJnlLine.Insert();
                        SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
                    end else
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
                            TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                            TempGenJnlLine."Document No." := PostedBillGr."No.";
                            TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"G/L Account");
                            TempGenJnlLine.Validate("Account No.", Acct);
                            TempGenJnlLine.Description := Text1100010Lbl;
                            TempGenJnlLine.Validate("Currency Code", '');
                            TempGenJnlLine.Validate(Amount, -SumLCYAmt);
                            TempGenJnlLine."Source Code" := SourceCode;
                            TempGenJnlLine."System-Created Entry" := true;
                            TempGenJnlLine.Validate("Shortcut Dimension 1 Code", BankAcc."Global Dimension 1 Code");
                            TempGenJnlLine.Validate("Shortcut Dimension 2 Code", BankAcc."Global Dimension 2 Code");
                            OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                            TempGenJnlLine.Insert();
                        end;

                    OnPostDataItemPostedDocOnBeforePostSettlement(TempGenJnlLine, PostedBillGr, PostingDate);
                    DocPost.PostSettlement(TempGenJnlLine);
                    TempGenJnlLine.DeleteAll();

                    DocPost.CloseBillGroupIfEmpty(PostedBillGr, PostingDate);

                    if ExistVATEntry then begin
                        GLReg.FindLast();
                        GLReg."From VAT Entry No." := FirstVATEntryNo;
                        GLReg."To VAT Entry No." := LastVATEntryNo;
                        GLReg.Modify();
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SumLCYAmt := 0;
                    GenJnlLineNextNo := 0;
                    TotalDoc := Count;
                    ExistVATEntry := false;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                BillGrCount := BillGrCount + 1;
                Window.Update(1, Round(BillGrCount / TotalBillGr * 10000, 1));
                Window.Update(2, StrSubstNo('%1', "No."));
                Window.Update(3, 0);
                GroupAmount := 0;

                TotalDisctdAmt := 0;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();

                Commit();

                Message(
                  Text1100003Lbl,
                  TotalDocCount, BillGrCount, GroupAmountLCY);
            end;

            trigger OnPreDataItem()
            begin
                DocPost.CheckPostingDate(PostingDate);

                SourceCodeSetup.Get();
                SourceCode := SourceCodeSetup."Cartera Journal";

                GroupAmountLCY := 0;
                BillGrCount := 0;
                DocCount := 0;
                TotalDocCount := 0;
                TotalBillGr := Count;
                Window.Open(
                  Text1100000Lbl +
                  Text1100001Lbl +
                  Text1100002Lbl);
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
        SourceCodeSetup: Record "Source Code Setup";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccPostingGr: Record "Bank Account Posting Group";
        BankAcc: Record "Bank Account";
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        GLReg: Record "G/L Register";
        VATPostingSetup: Record "VAT Posting Setup";
        TempBGPOPostBuffer: Record "BG/PO Post. Buffer" temporary;
        TempNoRealVATBuffer: Record "BG/PO Post. Buffer" temporary;
        DocPost: Codeunit "Document-Post";
        CarteraManagement: Codeunit CarteraManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Text1100000Lbl: Label 'Settling           @1@@@@@@@@@@@@@@@@@@@@@@@\\';
        Text1100001Lbl: Label 'Bill Groups        #2######  @3@@@@@@@@@@@@@\', Comment = '#2 = Bill group number, @3 = Document settlement progress';
        Text1100002Lbl: Label 'Receiv. Documents  #4######', Comment = '#4 = Document type and number';
        Text1100003Lbl: Label '%1 Documents in %2 Bill Groups totaling %3 (LCY) have been settled.', Comment = '%1 = Number of documents settled, %2 = Number of bill groups, %3 = Total amount settled in local currency';
        Text1100004Lbl: Label 'Receivable bill settlement %1/%2', Comment = '%1 = Document number, %2 = Bill number';
        Text1100005Lbl: Label 'Receivable document settlement %1', Comment = '%1 = Document number';
        Text1100009Lbl: Label 'Bill Group settlement %1', Comment = '%1 = Bill group number';
        Text1100010Lbl: Label 'Residual adjust generated by rounding Amount';
        Text1100011Lbl: Label 'Bill Group settlement %1 Customer No. %2', Comment = '%1 = Bill group number, %2 = Customer number';
        Text1100012Lbl: Label 'Receivable document settlement %1/%2', Comment = '%1 = Document number, %2 = Bill number';
        Window: Dialog;
        Delay: Decimal;
        SourceCode: Code[10];
        Acct: Code[20];
        DocCount: Integer;
        TotalDocCount: Integer;
        GroupAmount: Decimal;
        GroupAmountLCY: Decimal;
        GenJnlLineNextNo: Integer;
        SumLCYAmt: Decimal;
        TotalDisctdAmt: Decimal;
        BillGrCount: Integer;
        TotalBillGr: Integer;
        TotalDoc: Integer;
        ExistVATEntry: Boolean;
        LastVATEntryNo: Integer;
        FirstVATEntryNo: Integer;
        IsRedrawn: Boolean;

    protected var
        // Preserve the published protected variable names for report extensions.
#pragma warning disable AA0204
        PostingDate: Date;
        DueOnly: Boolean;
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

        TotalDisctdAmt := TotalDisctdAmt + DisctedAmt;

        Clear(TempGenJnlLine);
        TempGenJnlLine.Init();
        TempGenJnlLine."Line No." := GenJnlLineNextNo;
        TempGenJnlLine."Posting Date" := PostingDate;
        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
        TempGenJnlLine."Document No." := PostedBillGr."No.";
        BankAcc.TestField("Bank Acc. Posting Group");
        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
        TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"G/L Account");
        BankAccPostingGr.TestField("Liabs. for Factoring Acc.");
        TempGenJnlLine.Validate("Account No.", BankAccPostingGr."Liabs. for Factoring Acc.");
        TempGenJnlLine.Description := CopyStr(
            StrSubstNo(Text1100011Lbl,
              PostedBillGr."No.",
              PostedDoc2."Account No."), 1, MaxStrLen(TempGenJnlLine.Description));
        TempGenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
        TempGenJnlLine.Validate(Amount, DisctedAmt);
        TempGenJnlLine."Source Code" := SourceCode;
        TempGenJnlLine."System-Created Entry" := true;
        TempGenJnlLine."Shortcut Dimension 1 Code" := PostedDoc2."Global Dimension 1 Code";
        TempGenJnlLine."Shortcut Dimension 2 Code" := PostedDoc2."Global Dimension 2 Code";
        TempGenJnlLine."Dimension Set ID" := PostedDoc2."Dimension Set ID";
        TempBGPOPostBuffer."Gain - Loss Amount (LCY)" := TempBGPOPostBuffer."Gain - Loss Amount (LCY)" + TempGenJnlLine.Amount;
        TempBGPOPostBuffer.Modify();
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
                begin
                    CustLedgEntry2.Get(TempBGPOPostBuffer."Entry No.");
                    GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                    Clear(TempGenJnlLine);
                    TempGenJnlLine.Init();
                    TempGenJnlLine."Line No." := GenJnlLineNextNo;
                    TempGenJnlLine."Posting Date" := PostingDate;
                    TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                    TempGenJnlLine."Document No." := PostedBillGr."No.";
                    BankAcc.TestField("Bank Acc. Posting Group");
                    BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                    TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"Bank Account");
                    TempGenJnlLine.Validate("Account No.", BankAcc."No.");
                    TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100009Lbl, PostedBillGr."No."), 1, MaxStrLen(TempGenJnlLine.Description));
                    TempGenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
                    TempGenJnlLine.Validate(Amount, GroupAmount - TotalDisctdAmt);
                    TempGenJnlLine."Source Code" := SourceCode;
                    TempGenJnlLine."System-Created Entry" := true;
                    TempGenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry2."Global Dimension 1 Code";
                    TempGenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry2."Global Dimension 2 Code";
                    TempGenJnlLine."Dimension Set ID" := CustLedgEntry2."Dimension Set ID";
                    OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                    TempGenJnlLine.Insert();
                    SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
                end;
            else begin
                CustLedgEntry2.Get(TempBGPOPostBuffer."Entry No.");
                GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                Clear(TempGenJnlLine);
                TempGenJnlLine.Init();
                TempGenJnlLine."Line No." := GenJnlLineNextNo;
                TempGenJnlLine."Posting Date" := PostingDate;
                TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                TempGenJnlLine."Document No." := PostedBillGr."No.";
                BankAcc.TestField("Bank Acc. Posting Group");
                BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"Bank Account");
                TempGenJnlLine.Validate("Account No.", BankAcc."No.");
                TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100009Lbl, PostedBillGr."No."), 1, MaxStrLen(TempGenJnlLine.Description));
                TempGenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
                TempGenJnlLine.Validate(Amount, GroupAmount);
                TempGenJnlLine."Source Code" := SourceCode;
                TempGenJnlLine."System-Created Entry" := true;
                TempGenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry2."Global Dimension 1 Code";
                TempGenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry2."Global Dimension 2 Code";
                TempGenJnlLine."Dimension Set ID" := CustLedgEntry2."Dimension Set ID";
                OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                TempGenJnlLine.Insert();
                SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
            end;
        end;
    end;

    local procedure InsertGenJournalLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount2: Decimal)
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        Clear(TempGenJnlLine);
        TempGenJnlLine.Init();
        TempGenJnlLine."Line No." := GenJnlLineNextNo;
        TempGenJnlLine."Posting Date" := PostingDate;
        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
        TempGenJnlLine."Document No." := PostedBillGr."No.";
        TempGenJnlLine."Account Type" := AccType;
        TempGenJnlLine."Account No." := AccNo;
        TempGenJnlLine.Description := CopyStr(
            StrSubstNo(Text1100012Lbl, PostedDoc."Document No.", PostedDoc."No."),
            1, MaxStrLen(TempGenJnlLine.Description));
        TempGenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
        TempGenJnlLine.Validate(Amount, -Amount2);
        TempGenJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
        TempGenJnlLine."Applies-to Doc. No." := '';
        TempGenJnlLine."Applies-to Bill No." := CustLedgEntry."Bill No.";
        TempGenJnlLine."Source Code" := SourceCode;
        TempGenJnlLine."System-Created Entry" := true;
        TempGenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
        TempGenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
        TempGenJnlLine."Dimension Set ID" := CustLedgEntry."Dimension Set ID";
        OnBeforeGenJournalLineInsert(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry, PostedBillGr);
        TempGenJnlLine.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCustUnrealizedVAT2(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var PostedBillGroup: Record "Posted Bill Group"; var BgPoPostBuffer: Record "BG/PO Post. Buffer")
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
    local procedure OnReadPostedBillGroupOnAfterGetBankAcc(BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReadPostedBillGroupOnAfterSetDelay(var BankAccount: Record "Bank Account"; var Delay: Decimal; PostedBillGr: Record "Posted Bill Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDataItemPostedDocOnBeforePostSettlement(var GenJournalLine: Record "Gen. Journal Line"; PostedBillGroup: Record "Posted Bill Group"; PostingDate: Date);
    begin
    end;
}

