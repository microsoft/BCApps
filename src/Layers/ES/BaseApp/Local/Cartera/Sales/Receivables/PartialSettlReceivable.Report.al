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

report 7000084 "Partial Settl.- Receivable"
{
    Caption = 'Partial Settl.- Receivable';
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
                if PostedBillGr."No." = '' then begin
                    PostedBillGr.Get("Bill Gr./Pmt. Order No.");
                    BankAcc.Get(PostedBillGr."Bank Account No.");
                    BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                end;

                RemainingAmt2 := "Remaining Amount" - AppliedAmt;

                DocCount := DocCount + 1;
                Window.Update(1, DocCount);

                GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                Clear(TempGenJnlLine);
                TempGenJnlLine.Init();
                TempGenJnlLine."Line No." := GenJnlLineNextNo;
                TempGenJnlLine."Posting Date" := DocumentPostingDate;
                TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                TempGenJnlLine."Document No." := PostedBillGr."No.";
                TempGenJnlLine."Reason Code" := PostedBillGr."Reason Code";
                TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::Customer);
                CustLedgEntry.Get(PostedDoc."Entry No.");

                if GLSetup."Unrealized VAT" and (PostedDoc."Document Type" = PostedDoc."Document Type"::Bill) then begin
                    FromJnl := false;
                    if PostedDoc."From Journal" then
                        FromJnl := true;
                    ExistsNoRealVAT := GenJnlPostLine.CustFindVATSetup(VATPostingSetup, CustLedgEntry, FromJnl);
                end;

                OnBeforeValidateAccountNo(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, FromJnl, ExistsNoRealVAT);
                TempGenJnlLine.Validate("Account No.", CustLedgEntry."Customer No.");
                if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
                    TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100001Lbl, PostedDoc."Document No.", PostedDoc."No."), 1, MaxStrLen(TempGenJnlLine.Description))
                else
                    TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100002Lbl, PostedDoc."Document No."), 1, MaxStrLen(TempGenJnlLine.Description));
                TempGenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
                TempGenJnlLine.Validate(Amount, -AppliedAmt);
                TempGenJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
                TempGenJnlLine."Applies-to Doc. No." := CustLedgEntry."Document No.";
                TempGenJnlLine."Applies-to Bill No." := CustLedgEntry."Bill No.";
                TempGenJnlLine."Source Code" := SourceCode;
                TempGenJnlLine."System-Created Entry" := true;
                TempGenJnlLine."Dimension Set ID" :=
                  CarteraManagement.GetCombinedDimSetID(TempGenJnlLine, CustLedgEntry."Dimension Set ID");
                OnBeforeInsertGenJournalLine(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, PostedBillGr);
                TempGenJnlLine.Insert();
                SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";

                if ("Document Type" = "Document Type"::Bill) and
                   GLSetup."Unrealized VAT" and
                   ExistsNoRealVAT and
                   (not IsRedrawn)
                then begin
                    OnBeforeCustUnrealizedVAT2(PostedDoc, TempGenJnlLine, CustLedgEntry, PostedBillGr, TempNoRealVATBuffer);
                    CarteraManagement.CustUnrealizedVAT2(
                      CustLedgEntry,
                      AppliedAmt,
                      TempGenJnlLine,
                      ExistVATEntry,
                      FirstVATEntryNo,
                      LastVATEntryNo,
                      TempNoRealVATBuffer,
                      FromJnl,
                      "Document No.");
                    OnAfterCustUnrealizedVAT2(PostedDoc, TempGenJnlLine, CustLedgEntry, PostedBillGr, TempNoRealVATBuffer);

                    if TempNoRealVATBuffer.Find('-') then
                        repeat
                            InsertGenJournalLine(
                              TempGenJnlLine."Account Type"::"G/L Account",
                              TempNoRealVATBuffer.Account,
                              -TempNoRealVATBuffer.Amount);
                            InsertGenJournalLine(
                              TempGenJnlLine."Account Type"::"G/L Account",
                              TempNoRealVATBuffer."Balance Account",
                              TempNoRealVATBuffer.Amount);
                        until TempNoRealVATBuffer.Next() = 0;
                end;

                if AppliedAmt = RemainingAmt then begin
                    CustLedgEntry."Document Status" := CustLedgEntry."Document Status"::Honored;
                    CustLedgEntry.Modify();
                    RemainingAmt2 := 0;
                end;

                if (PostedBillGr."Dealing Type" = PostedBillGr."Dealing Type"::Discount) and
                   (PostedBillGr.Factoring <> PostedBillGr.Factoring::" ")
                then
                    RiskDiscFactLiabs(PostedDoc);

                DimSetID := "Dimension Set ID";

                OnAfterPostedDocDataItem(PostedDoc);
            end;

            trigger OnPostDataItem()
            begin
                if DocCount = 0 then
                    Error(NoReceivableDocumentsToSettleErr);

                if PostedBillGr.Factoring = PostedBillGr.Factoring::" " then begin
                    if "Dealing Type" = "Dealing Type"::Discount then begin
                        GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                        Clear(TempGenJnlLine);
                        TempGenJnlLine.Init();
                        TempGenJnlLine."Line No." := GenJnlLineNextNo;
                        TempGenJnlLine."Posting Date" := DocumentPostingDate;
                        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                        TempGenJnlLine."Document No." := PostedBillGr."No.";
                        TempGenJnlLine."Reason Code" := PostedBillGr."Reason Code";
                        BankAcc.TestField("Bank Acc. Posting Group");
                        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                        TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"G/L Account");
                        BankAccPostingGr.TestField("Liabs. for Disc. Bills Acc.");
                        TempGenJnlLine.Validate("Account No.", BankAccPostingGr."Liabs. for Disc. Bills Acc.");
                        if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
                            TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100001Lbl, PostedDoc."Document No.", PostedDoc."No."), 1, MaxStrLen(TempGenJnlLine.Description))
                        else
                            TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100002Lbl, PostedDoc."Document No."), 1, MaxStrLen(TempGenJnlLine.Description));
                        TempGenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
                        TempGenJnlLine.Validate(Amount, AppliedAmt);
                        TempGenJnlLine."Source Code" := SourceCode;
                        TempGenJnlLine."System-Created Entry" := true;
                        TempGenJnlLine."Dimension Set ID" :=
                          CarteraManagement.GetCombinedDimSetID(TempGenJnlLine, DimSetID);
                        OnBeforeInsertGenJournalLine(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, PostedBillGr);
                        TempGenJnlLine.Insert();
                        SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
                    end else
                        BankAmtBuffer := BankAmtBuffer + AppliedAmt;
                end else
                    FactBankAccounting();

                if BankAmtBuffer <> 0 then
                    BankAccounting(BankAmtBuffer);

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
                        TempGenJnlLine."Posting Date" := DocumentPostingDate;
                        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                        TempGenJnlLine."Document No." := PostedBillGr."No.";
                        TempGenJnlLine."Reason Code" := PostedBillGr."Reason Code";
                        TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"G/L Account");
                        TempGenJnlLine.Validate("Account No.", Acct);
                        TempGenJnlLine.Description := Text1100005Lbl;
                        TempGenJnlLine.Validate("Currency Code", '');
                        TempGenJnlLine.Validate(Amount, -SumLCYAmt);
                        TempGenJnlLine."Source Code" := SourceCode;
                        TempGenJnlLine."System-Created Entry" := true;
                        TempGenJnlLine."Dimension Set ID" :=
                          CarteraManagement.GetCombinedDimSetID(TempGenJnlLine, CustLedgEntry."Dimension Set ID");
                        OnBeforeInsertGenJournalLine(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, PostedBillGr);
                        TempGenJnlLine.Insert();
                    end;

                DocPost.PostSettlement(TempGenJnlLine);

                CustLedgEntry.Get("Entry No.");
                Get(Type, "Entry No.");
                "Honored/Rejtd. at Date" := DocumentPostingDate;
                "Remaining Amount" := RemainingAmt2;
                "Remaining Amt. (LCY)" := Round(CurrExchRate.ExchangeAmtFCYToLCY(
                      CustLedgEntry."Posting Date",
                      CustLedgEntry."Currency Code",
                      RemainingAmt2,
                      CurrExchRate.ExchangeRate(CustLedgEntry."Posting Date", CustLedgEntry."Currency Code")),
                    GLSetup."Amount Rounding Precision");
                if RemainingAmt2 = 0 then begin
                    "Remaining Amt. (LCY)" := 0;
                    CustLedgEntry."Document Status" := CustLedgEntry."Document Status"::Honored;
                    Status := Status::Honored;
                    CustLedgEntry.Open := false;
                end else begin
                    CustLedgEntry."Document Status" := CustLedgEntry."Document Status"::Open;
                    Status := Status::Open;
                    CustLedgEntry.Open := true;
                end;
                OnBeforeModifyPostedDoc(PostedDoc, TempGenJnlLine, CustLedgEntry, PostedBillGr);
                CustLedgEntry.Modify();
                Modify();
                PostedBillGr.Modify();

                DocPost.CloseBillGroupIfEmpty(PostedBillGr, DocumentPostingDate);

                Window.Close();

                if ExistVATEntry then begin
                    GLReg.FindLast();
                    GLReg."From VAT Entry No." := FirstVATEntryNo;
                    GLReg."To VAT Entry No." := LastVATEntryNo;
                    GLReg.Modify();
                end;

                OnAfterPostedDocOnPostDataItem(PostedDoc, TempGenJnlLine, CustLedgEntry, PostedBillGr);

                Commit();
                Message(
                  Text1100006Lbl,
                  DocCount, RemainingAmt, PostedBillGr."No.", AppliedAmt);
            end;

            trigger OnPreDataItem()
            begin
                DocPost.CheckPostingDate(DocumentPostingDate);

                SourceCodeSetup.Get();
                SourceCode := SourceCodeSetup."Cartera Journal";
                DocCount := 0;
                TotalDisctdAmt := 0;
                BankAmtBuffer := 0;
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
                            CustLedgEntry2: Record "Cust. Ledger Entry";
                        begin
                            CustLedgEntry2.Get(CustLedgEntryNo);
                            if CustLedgEntry2."Document Type" = CustLedgEntry2."Document Type"::Invoice then begin
                                CustLedgEntry2.CalcFields("Remaining Amount");
                                if DocumentPostingDate > CustLedgEntry2."Pmt. Discount Date" then
                                    RemainingAmt := CustLedgEntry2."Remaining Amount"
                                else
                                    RemainingAmt := CustLedgEntry2."Remaining Amount" - CustLedgEntry2."Remaining Pmt. Disc. Possible";
                                AppliedAmt := RemainingAmt;
                            end;
                        end;
                    }
                    field(RemainingAmount; RemainingAmt)
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
                    field(SettledAmount; AppliedAmt)
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
                            if AppliedAmt > RemainingAmt then
                                Error(Text1100007Lbl, RemainingAmt);
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
        RemainingAmt := 0;
        AppliedAmt := 0;
        DocumentCurrencyCode := '';
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
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        GLReg: Record "G/L Register";
        VATPostingSetup: Record "VAT Posting Setup";
        TempNoRealVATBuffer: Record "BG/PO Post. Buffer" temporary;
        DocPost: Codeunit "Document-Post";
        CarteraManagement: Codeunit CarteraManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Text1100000Lbl: Label ' Partially settling receivable documents      #1######', Comment = '#1 = Number of documents partially settled';
        Text1100001Lbl: Label 'Partial Bill settlement %1/%2', Comment = '%1 = Document number, %2 = Bill number';
        Text1100002Lbl: Label 'Partial Document settlement %1', Comment = '%1 = Document number';
        NoReceivableDocumentsToSettleErr: Label 'No receivable documents have been found that can be settled. \Please check that the selection is not empty and at least one receivable document is open.';
        Text1100005Lbl: Label 'Residual adjust generated by rounding Amount';
        Text1100006Lbl: Label '%1 receivable documents totaling %2 have been partially settled in Bill Group %3 by an amount of %4.', Comment = '%1 = Number of documents partially settled, %2 = Remaining amount, %3 = Bill group number, %4 = Applied amount';
        Text1100007Lbl: Label 'The maximum permitted value is %1', Comment = '%1 = Remaining amount available for settlement';
        Text1100008Lbl: Label 'Partial Document settlement %1 Customer No. %2', Comment = '%1 = Document number, %2 = Customer number';
        Text1100009Lbl: Label 'Partial receivable document settlement %1/%2', Comment = '%1 = Document number, %2 = Bill number';
        Text1100010Lbl: Label 'Partial receivable document settlement %1', Comment = '%1 = Document number';
        Window: Dialog;
        DocumentPostingDate: Date;
        SourceCode: Code[10];
        Acct: Code[20];
        DocCount: Integer;
        GenJnlLineNextNo: Integer;
        TotalDisctdAmt: Decimal;
        RemainingAmt: Decimal;
        DocumentCurrencyCode: Code[10];
        AppliedAmt: Decimal;
        RemainingAmt2: Decimal;
        BankAmtBuffer: Decimal;
        SumLCYAmt: Decimal;
        ExistVATEntry: Boolean;
        FirstVATEntryNo: Integer;
        LastVATEntryNo: Integer;
        IsRedrawn: Boolean;
        DimSetID: Integer;
        ExistsNoRealVAT: Boolean;
        CustLedgEntryNo: Integer;

    local procedure RiskDiscFactLiabs(PostedDoc2: Record "Posted Cartera Doc.")
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
              AppliedAmt,
              PostedDoc2."Account No.",
              PostedDoc2."Bank Account No."), RoundingPrec);

        TotalDisctdAmt := TotalDisctdAmt + DisctedAmt;

        Clear(TempGenJnlLine);
        TempGenJnlLine.Init();
        TempGenJnlLine."Line No." := GenJnlLineNextNo;
        TempGenJnlLine."Posting Date" := DocumentPostingDate;
        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
        TempGenJnlLine."Document No." := PostedBillGr."No.";
        TempGenJnlLine."Reason Code" := PostedBillGr."Reason Code";
        BankAcc.TestField("Bank Acc. Posting Group");
        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
        TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"G/L Account");
        BankAccPostingGr.TestField("Liabs. for Factoring Acc.");
        TempGenJnlLine.Validate("Account No.", BankAccPostingGr."Liabs. for Factoring Acc.");
        TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100008Lbl, PostedDoc2."Document No.", PostedDoc2."Account No."), 1, MaxStrLen(TempGenJnlLine.Description));
        TempGenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
        TempGenJnlLine.Validate(Amount, DisctedAmt);
        TempGenJnlLine."Source Code" := SourceCode;
        TempGenJnlLine."System-Created Entry" := true;
        TempGenJnlLine."Dimension Set ID" :=
          CarteraManagement.GetCombinedDimSetID(TempGenJnlLine, PostedDoc2."Dimension Set ID");
        OnBeforeInsertGenJournalLine(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, PostedBillGr);
        TempGenJnlLine.Insert();
        SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
    end;

    local procedure FactBankAccounting()
    begin
        if PostedDoc."Dealing Type" = PostedDoc."Dealing Type"::Discount then
            BankAmtBuffer := BankAmtBuffer + (AppliedAmt - TotalDisctdAmt)
        else
            BankAmtBuffer := BankAmtBuffer + AppliedAmt;
    end;

    procedure SetInitValue(Amount: Decimal; CurrCode: Code[10]; EntryNo: Integer)
    begin
        DocumentCurrencyCode := CurrCode;
        RemainingAmt := Amount;
        AppliedAmt := RemainingAmt;
        CustLedgEntryNo := EntryNo;
    end;

    local procedure BankAccounting(BankAmt: Decimal)
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;
        Clear(TempGenJnlLine);
        TempGenJnlLine.Init();
        TempGenJnlLine."Line No." := GenJnlLineNextNo;
        TempGenJnlLine."Posting Date" := DocumentPostingDate;
        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
        TempGenJnlLine."Document No." := PostedBillGr."No.";
        TempGenJnlLine."Reason Code" := PostedBillGr."Reason Code";
        BankAcc.TestField("Bank Acc. Posting Group");
        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
        TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"Bank Account");
        TempGenJnlLine.Validate("Account No.", BankAcc."No.");
        if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
            TempGenJnlLine.Description := CopyStr(StrSubstNo(
                  Text1100001Lbl, PostedDoc."Document No.", PostedDoc."No."), 1, MaxStrLen(TempGenJnlLine.Description))
        else
            TempGenJnlLine.Description := CopyStr(StrSubstNo(
                  Text1100002Lbl, PostedDoc."Document No."), 1, MaxStrLen(TempGenJnlLine.Description));
        TempGenJnlLine.Validate("Currency Code", PostedBillGr."Currency Code");
        TempGenJnlLine.Validate(Amount, BankAmt);
        TempGenJnlLine."Source Code" := SourceCode;
        TempGenJnlLine."System-Created Entry" := true;
        TempGenJnlLine."Dimension Set ID" :=
          CarteraManagement.GetCombinedDimSetID(TempGenJnlLine, DimSetID);
        OnBeforeInsertGenJournalLine(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, PostedBillGr);
        TempGenJnlLine.Insert();
        SumLCYAmt := SumLCYAmt + TempGenJnlLine."Amount (LCY)";
    end;

    local procedure InsertGenJournalLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount2: Decimal)
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        Clear(TempGenJnlLine);
        TempGenJnlLine.Init();
        TempGenJnlLine."Line No." := GenJnlLineNextNo;
        TempGenJnlLine."Posting Date" := DocumentPostingDate;
        TempGenJnlLine."Document No." := PostedBillGr."No.";
        TempGenJnlLine."Reason Code" := PostedBillGr."Reason Code";
        TempGenJnlLine."Account Type" := AccType;
        TempGenJnlLine.Validate("Account No.", AccNo);
        if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
            TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100009Lbl, PostedDoc."Document No.", PostedDoc."No."), 1, MaxStrLen(TempGenJnlLine.Description))
        else
            TempGenJnlLine.Description := CopyStr(StrSubstNo(Text1100010Lbl, PostedDoc."Document No."), 1, MaxStrLen(TempGenJnlLine.Description));
        TempGenJnlLine.Validate("Currency Code", PostedDoc."Currency Code");
        TempGenJnlLine.Validate(Amount, Amount2);
        TempGenJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
        TempGenJnlLine."Applies-to Doc. No." := '';
        TempGenJnlLine."Applies-to Bill No." := CustLedgEntry."Bill No.";
        TempGenJnlLine."Source Code" := SourceCode;
        TempGenJnlLine."System-Created Entry" := true;
        TempGenJnlLine."Dimension Set ID" :=
          CarteraManagement.GetCombinedDimSetID(TempGenJnlLine, CustLedgEntry."Dimension Set ID");
        OnBeforeInsertGenJournalLine(PostedDoc, TempGenJnlLine, VATPostingSetup, CustLedgEntry, PostedBillGr);
        TempGenJnlLine.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCustUnrealizedVAT2(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var PostedBillGroup: Record "Posted Bill Group"; var BgPoPostBuffer: Record "BG/PO Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedDocDataItem(var PostedCarteraDoc: Record "Posted Cartera Doc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedDocOnPostDataItem(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var PostedBillGroup: Record "Posted Bill Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustUnrealizedVAT2(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var PostedBillGroup: Record "Posted Bill Group"; var BgPoPostBuffer: Record "BG/PO Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGenJournalLine(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var PostedBillGroup: Record "Posted Bill Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPostedDoc(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var PostedBillGroup: Record "Posted Bill Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAccountNo(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var FromJnl: Boolean; var ExistsNoRealVAT: Boolean)
    begin
    end;
}

