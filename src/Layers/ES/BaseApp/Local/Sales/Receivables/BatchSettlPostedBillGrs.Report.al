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
                    Clear(GenJnlLine);
                    GenJnlLine.Init();
                    GenJnlLine."Line No." := GenJnlLineNextNo;
                    GenJnlLine."Posting Date" := PostingDate;
                    GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                    GenJnlLine."Document No." := PostedBillGr."No.";
                    GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
                    CustLedgEntry.Get(PostedDoc."Entry No.");
                    if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then begin
                        GenJnlLine.Description := CopyStr(
                            StrSubstNo(Text1100004, PostedDoc."Document No.", PostedDoc."No."),
                            1, MaxStrLen(GenJnlLine.Description));
                        if GLSetup."Unrealized VAT" then begin
                            FromJnl := false;
                            if PostedDoc."From Journal" then
                                FromJnl := true;
                            ExistsNoRealVAT := GenJnlPostLine.CustFindVATSetup(VATPostingSetup, CustLedgEntry, FromJnl);
                        end;
                    end else
                        GenJnlLine.Description := CopyStr(
                            StrSubstNo(Text1100005, PostedDoc."Document No."),
                            1, MaxStrLen(GenJnlLine.Description));
                    GenJnlLine.Validate("Account No.", CustLedgEntry."Customer No.");
                    GenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
                    GenJnlLine.Validate(Amount, -PostedDoc."Remaining Amount");
                    GenJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
                    GenJnlLine."Applies-to Doc. No." := CustLedgEntry."Document No.";
                    GenJnlLine."Applies-to Bill No." := CustLedgEntry."Bill No.";
                    GenJnlLine."Source Code" := SourceCode;
                    GenJnlLine."System-Created Entry" := true;
                    GenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
                    GenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
                    GenJnlLine."Dimension Set ID" := CustLedgEntry."Dimension Set ID";
                    OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry, PostedBillGr);
                    GenJnlLine.Insert();
                    SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";

                    if ("Document Type" = "Document Type"::Bill) and
                       GLSetup."Unrealized VAT" and
                       ExistVATEntry and
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
                        OnAfterCustUnrealizedVAT2(PostedDoc, GenJnlLine, CustLedgEntry, PostedBillGr, NoRealVATBuffer);

                        if NoRealVATBuffer.Find('-') then begin
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
                            NoRealVATBuffer.DeleteAll();
                        end;
                    end;

                    GroupAmount := GroupAmount + "Remaining Amount";
                    GroupAmountLCY := GroupAmountLCY + "Remaining Amt. (LCY)";
                    CustLedgEntry."Document Status" := CustLedgEntry."Document Status"::Honored;
                    CustLedgEntry.Modify();

                    if BGPOPostBuffer.Get('', '', CustLedgEntry."Entry No.") then begin
                        BGPOPostBuffer.Amount := BGPOPostBuffer.Amount + "Remaining Amount";
                        BGPOPostBuffer.Modify();
                    end else begin
                        BGPOPostBuffer.Init();
                        BGPOPostBuffer."Entry No." := CustLedgEntry."Entry No.";
                        BGPOPostBuffer.Amount := BGPOPostBuffer.Amount + "Remaining Amount";
                        BGPOPostBuffer.Insert();
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
                        CustLedgEntry2.Get(BGPOPostBuffer."Entry No.");
                        Clear(GenJnlLine);
                        GenJnlLine.Init();
                        GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                        GenJnlLine."Line No." := GenJnlLineNextNo;
                        GenJnlLine."Posting Date" := PostingDate;
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                        GenJnlLine."Document No." := PostedBillGr."No.";
                        if "Dealing Type" = "Dealing Type"::Discount then begin
                            BankAcc.TestField("Bank Acc. Posting Group");
                            BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
                            BankAccPostingGr.TestField("Liabs. for Disc. Bills Acc.");
                            GenJnlLine.Validate("Account No.", BankAccPostingGr."Liabs. for Disc. Bills Acc.");
                        end else begin
                            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Bank Account");
                            GenJnlLine.Validate("Account No.", BankAcc."No.");
                        end;
                        GenJnlLine.Description := CopyStr(StrSubstNo(Text1100009, PostedBillGr."No."), 1, MaxStrLen(GenJnlLine.Description));
                        GenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
                        GenJnlLine.Validate(Amount, GroupAmount);
                        GenJnlLine."Source Code" := SourceCode;
                        GenJnlLine."System-Created Entry" := true;
                        GenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
                        GenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
                        GenJnlLine."Dimension Set ID" := CustLedgEntry."Dimension Set ID";
                        OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                        GenJnlLine.Insert();
                        SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
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
                            Clear(GenJnlLine);
                            GenJnlLine.Init();
                            GenJnlLine."Line No." := GenJnlLineNextNo;
                            GenJnlLine."Posting Date" := PostingDate;
                            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                            GenJnlLine."Document No." := PostedBillGr."No.";
                            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
                            GenJnlLine.Validate("Account No.", Acct);
                            GenJnlLine.Description := Text1100010;
                            GenJnlLine.Validate("Currency Code", '');
                            GenJnlLine.Validate(Amount, -SumLCYAmt);
                            GenJnlLine."Source Code" := SourceCode;
                            GenJnlLine."System-Created Entry" := true;
                            GenJnlLine.Validate("Shortcut Dimension 1 Code", BankAcc."Global Dimension 1 Code");
                            GenJnlLine.Validate("Shortcut Dimension 2 Code", BankAcc."Global Dimension 2 Code");
                            OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                            GenJnlLine.Insert();
                        end;

                    OnPostDataItemPostedDocOnBeforePostSettlement(GenJnlLine, PostedBillGr, PostingDate);
                    DocPost.PostSettlement(GenJnlLine);
                    GenJnlLine.DeleteAll();

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
                  Text1100003,
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
                  Text1100000 +
                  Text1100001 +
                  Text1100002);
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
        Text1100000: Label 'Settling           @1@@@@@@@@@@@@@@@@@@@@@@@\\';
        Text1100001: Label 'Bill Groups        #2######  @3@@@@@@@@@@@@@\';
        Text1100002: Label 'Receiv. Documents  #4######';
        Text1100003: Label '%1 Documents in %2 Bill Groups totaling %3 (LCY) have been settled.';
        Text1100004: Label 'Receivable bill settlement %1/%2';
        Text1100005: Label 'Receivable document settlement %1';
        Text1100009: Label 'Bill Group settlement %1';
        Text1100010: Label 'Residual adjust generated by rounding Amount';
        Text1100011: Label 'Bill Group settlement %1 Customer No. %2';
        Text1100012: Label 'Receivable document settlement %1/%2';
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line" temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccPostingGr: Record "Bank Account Posting Group";
        BankAcc: Record "Bank Account";
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        GLReg: Record "G/L Register";
        VATPostingSetup: Record "VAT Posting Setup";
        DocPost: Codeunit "Document-Post";
        CarteraManagement: Codeunit CarteraManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Window: Dialog;
        PostingDate: Date;
        DueOnly: Boolean;
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
        BGPOPostBuffer: Record "BG/PO Post. Buffer" temporary;
        NoRealVATBuffer: Record "BG/PO Post. Buffer" temporary;
        ExistsNoRealVAT: Boolean;

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

        Clear(GenJnlLine);
        GenJnlLine.Init();
        GenJnlLine."Line No." := GenJnlLineNextNo;
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := PostedBillGr."No.";
        BankAcc.TestField("Bank Acc. Posting Group");
        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
        BankAccPostingGr.TestField("Liabs. for Factoring Acc.");
        GenJnlLine.Validate("Account No.", BankAccPostingGr."Liabs. for Factoring Acc.");
        GenJnlLine.Description := CopyStr(
            StrSubstNo(Text1100011,
              PostedBillGr."No.",
              PostedDoc2."Account No."), 1, MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
        GenJnlLine.Validate(Amount, DisctedAmt);
        GenJnlLine."Source Code" := SourceCode;
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Shortcut Dimension 1 Code" := PostedDoc2."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := PostedDoc2."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := PostedDoc2."Dimension Set ID";
        BGPOPostBuffer."Gain - Loss Amount (LCY)" := BGPOPostBuffer."Gain - Loss Amount (LCY)" + GenJnlLine.Amount;
        BGPOPostBuffer.Modify();
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
                begin
                    CustLedgEntry2.Get(BGPOPostBuffer."Entry No.");
                    GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                    Clear(GenJnlLine);
                    GenJnlLine.Init();
                    GenJnlLine."Line No." := GenJnlLineNextNo;
                    GenJnlLine."Posting Date" := PostingDate;
                    GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                    GenJnlLine."Document No." := PostedBillGr."No.";
                    BankAcc.TestField("Bank Acc. Posting Group");
                    BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                    GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Bank Account");
                    GenJnlLine.Validate("Account No.", BankAcc."No.");
                    GenJnlLine.Description := CopyStr(StrSubstNo(Text1100009, PostedBillGr."No."), 1, MaxStrLen(GenJnlLine.Description));
                    GenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
                    GenJnlLine.Validate(Amount, GroupAmount - TotalDisctdAmt);
                    GenJnlLine."Source Code" := SourceCode;
                    GenJnlLine."System-Created Entry" := true;
                    GenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry2."Global Dimension 1 Code";
                    GenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry2."Global Dimension 2 Code";
                    GenJnlLine."Dimension Set ID" := CustLedgEntry2."Dimension Set ID";
                    OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                    GenJnlLine.Insert();
                    SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
                end;
            else begin
                CustLedgEntry2.Get(BGPOPostBuffer."Entry No.");
                GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                Clear(GenJnlLine);
                GenJnlLine.Init();
                GenJnlLine."Line No." := GenJnlLineNextNo;
                GenJnlLine."Posting Date" := PostingDate;
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                GenJnlLine."Document No." := PostedBillGr."No.";
                BankAcc.TestField("Bank Acc. Posting Group");
                BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Bank Account");
                GenJnlLine.Validate("Account No.", BankAcc."No.");
                GenJnlLine.Description := CopyStr(StrSubstNo(Text1100009, PostedBillGr."No."), 1, MaxStrLen(GenJnlLine.Description));
                GenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
                GenJnlLine.Validate(Amount, GroupAmount);
                GenJnlLine."Source Code" := SourceCode;
                GenJnlLine."System-Created Entry" := true;
                GenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry2."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry2."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := CustLedgEntry2."Dimension Set ID";
                OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                GenJnlLine.Insert();
                SumLCYAmt := SumLCYAmt + GenJnlLine."Amount (LCY)";
            end;
        end;
    end;

    local procedure InsertGenJournalLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount2: Decimal)
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        Clear(GenJnlLine);
        GenJnlLine.Init();
        GenJnlLine."Line No." := GenJnlLineNextNo;
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := PostedBillGr."No.";
        GenJnlLine."Account Type" := AccType;
        GenJnlLine."Account No." := AccNo;
        GenJnlLine.Description := CopyStr(
            StrSubstNo(Text1100012, PostedDoc."Document No.", PostedDoc."No."),
            1, MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
        GenJnlLine.Validate(Amount, -Amount2);
        GenJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
        GenJnlLine."Applies-to Doc. No." := '';
        GenJnlLine."Applies-to Bill No." := CustLedgEntry."Bill No.";
        GenJnlLine."Source Code" := SourceCode;
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := CustLedgEntry."Dimension Set ID";
        OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry, PostedBillGr);
        GenJnlLine.Insert();
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

