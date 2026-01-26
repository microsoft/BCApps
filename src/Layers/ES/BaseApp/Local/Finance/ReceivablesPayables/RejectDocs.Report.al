// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

report 7000097 "Reject Docs."
{
    Caption = 'Reject Docs.';
    Permissions = TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd,
                  TableData "Cartera Doc." = imd,
                  TableData "Posted Cartera Doc." = imd,
                  TableData "Closed Cartera Doc." = imd,
                  TableData "Posted Bill Group" = imd,
                  TableData "Closed Bill Group" = imd;
    ProcessingOnly = true;

    dataset
    {
        dataitem(CustLedgEntry; "Cust. Ledger Entry")
        {
            DataItemTableView = sorting("Entry No.") where(Open = const(true));

            trigger OnAfterGetRecord()
            var
                FromJnl: Boolean;
            begin
                IsRedrawn := CarteraManagement.CheckFromRedrawnDoc("Bill No.");
                DocCount := DocCount + 1;
                Window.Update(1, DocCount);

                if GLSetup."Unrealized VAT" and
                   (("Document Type" = "Document Type"::Bill) or ("Document Type" = "Document Type"::Invoice))
                then begin
                    FromJnl := false;
                    if PostedDoc."From Journal" then
                        FromJnl := true;
                    OnBeforeCustFindVATSetup(VATPostingSetup, CustLedgEntry, FromJnl);
                    ExistsNoRealVAT := GenJnlPostLine.CustFindVATSetup(VATPostingSetup, CustLedgEntry, FromJnl);
                end;

                if ArePostedDocs then begin
                    PostedDoc.Get(PostedDoc.Type::Receivable, "Entry No.");
                    PostedBillGr.Get(PostedDoc."Bill Gr./Pmt. Order No.");
                    if PostedBillGr."Dealing Type" = PostedBillGr."Dealing Type"::Discount then
                        Discount := true
                    else
                        Discount := false;
                    if PostedBillGr.Factoring = PostedBillGr.Factoring::" " then
                        Factoring := false
                    else
                        Factoring := true;
                    BankAcc.Get(PostedDoc."Bank Account No.");
                    BankAcc.TestField("Bank Acc. Posting Group");
                    BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                    if IncludeExpenses then begin
                        BankAcc.TestField("Operation Fees Code");
                        FeeRange.InitRejExpenses(
                          BankAcc."Operation Fees Code",
                          BankAcc."Currency Code");
                    end;
                end;

                CalcFields("Remaining Amount", "Remaining Amt. (LCY)");

                if "Document Type" = "Document Type"::Bill then begin
                    CurrDescription := StrSubstNo(Text1100004, "Document No.", "Bill No.");
                    CurrDocNo := "Document No.";
                    CurrDocNo2 := "Bill No.";
                    PrepareBillRejPosting("Remaining Amount");
                end else begin
                    CurrDescription := StrSubstNo(Text1100005, "Document No.");
                    CurrDocNo := "Document No.";
                    CurrDocNo2 := "Bill No.";
                    PrepareInvoiceRejPosting("Remaining Amount");
                end;

                if ArePostedDocs then begin
                    PostedDoc.Get(PostedDoc.Type::Receivable, "Entry No.");
                    PostedDoc.Status := PostedDoc.Status::Rejected;
                    PostedDoc."Honored/Rejtd. at Date" := PostingDate;
                    PostedDoc.Modify();
                    "Document Status" := "Document Status"::Rejected;
                    Modify();
                    if IncludeExpenses then
                        FeeRange.CalcRejExpensesAmt(
                          BankAcc."Operation Fees Code",
                          BankAcc."Currency Code",
                          "Remaining Amount",
                          "Entry No.");
                end else begin
                    Doc.Get(Doc.Type::Receivable, "Entry No.");
                    ClosedDoc.TransferFields(Doc);
                    ClosedDoc.Status := ClosedDoc.Status::Rejected;
                    ClosedDoc."Honored/Rejtd. at Date" := PostingDate;
                    ClosedDoc."Bill Gr./Pmt. Order No." := '';
                    ClosedDoc."Remaining Amount" := Doc."Remaining Amount";
                    ClosedDoc."Remaining Amt. (LCY)" := Doc."Remaining Amt. (LCY)";
                    ClosedDoc."Amount for Collection" := 0;
                    ClosedDoc."Amt. for Collection (LCY)" := 0;
                    ClosedDoc.Insert(true);
                    Doc.Delete();
                    "Document Status" := "Document Status"::Rejected;
                    "Document Situation" := "Document Situation"::"Closed Documents";
                    Modify();
                end;

                DocPost.InsertDtldCustLedgEntry(
                  CustLedgEntry,
                  "Remaining Amount",
                  "Remaining Amt. (LCY)",
                  EntryType::Rejection,
                  PostingDate);

                if GLSetup."Unrealized VAT" and
                   ExistsNoRealVAT and
                   (not IsRedrawn)
                then begin
                    CarteraManagement.CustUnrealizedVAT2(
                      CustLedgEntry,
                      "Remaining Amt. (LCY)",
                      GenJnlLine,
                      ExistVATEntry,
                      FirstVATEntryNo,
                      LastVATEntryNo,
                      NoRealVATBuffer,
                      FromJnl,
                      "Document No.");

                    TempCurrCode := "Currency Code";
                    "Currency Code" := '';

                    if NoRealVATBuffer.Find('-') then
                        repeat
                            FindInClosedBills := true;
                            InsertGenJournalLine(
                              GenJnlLine."Account Type"::"G/L Account",
                              NoRealVATBuffer.Account,
                              -NoRealVATBuffer.Amount,
                              "Dimension Set ID");
                            InsertGenJournalLine(
                              GenJnlLine."Account Type"::"G/L Account",
                              NoRealVATBuffer."Balance Account",
                              NoRealVATBuffer.Amount,
                              "Dimension Set ID");
                            FindInClosedBills := false;
                        until NoRealVATBuffer.Next() = 0;

                    "Currency Code" := TempCurrCode;
                end;

                if IncludeExpenses and ArePostedDocs then begin
                    CurrDescription := Text1100006;
                    CurrDocNo := PostedBillGr."No.";
                    CurrDocNo2 := '';
                    if (FeeRange.GetTotalRejExpensesAmt() <> 0) or (UseJournal = UseJournal::AuxJournal) then begin
                        BankAccPostingGr.TestField("Rejection Expenses Acc.");
                        NoRegs := FeeRange.NoRegRejExpenses();
                        for i := 0 to NoRegs - 1 do begin
                            FeeRange.GetRejExpensesAmt(MemIntReg, i);
                            Get(MemIntReg."Entry No.");
                            InsertGenJournalLine(
                              GenJnlLine."Account Type"::"G/L Account",
                              BankAccPostingGr."Rejection Expenses Acc.",
                              MemIntReg.Amount,
                              "Dimension Set ID");
                            InsertGenJournalLine(
                              GenJnlLine."Account Type"::"Bank Account",
                              BankAcc."No.",
                              -MemIntReg.Amount,
                              "Dimension Set ID");
                        end;
                    end;
                end;

                if (FeeRange.GetTotalRejExpensesAmt() <> 0) and ArePostedDocs then begin
                    PostedBillGr."Rejection Expenses Amt." := PostedBillGr."Rejection Expenses Amt." + FeeRange.GetTotalRejExpensesAmt();
                    PostedBillGr.Modify();
                end;
            end;

            trigger OnPostDataItem()
            var
                PostedDoc2: Record "Posted Cartera Doc.";
            begin
                if GenJnlLine.Find('-') then
                    repeat
                        if ArePostedDocs then begin
                            PostedDoc2.SetRange("Document No.", GenJnlLine."Document No.");
                            if PostedDoc2.Find('-') then
                                repeat
                                    PostedBillGr.Get(PostedDoc2."Bill Gr./Pmt. Order No.");
                                    DocPost.CloseBillGroupIfEmpty(PostedBillGr, PostingDate);
                                until PostedDoc2.Next() = 0;
                        end;
                    until GenJnlLine.Next() = 0;

                PostGenJournal();
                if ExistVATEntry then begin
                    GLReg.FindLast();
                    GLReg."From VAT Entry No." := FirstVATEntryNo;
                    GLReg."To VAT Entry No." := LastVATEntryNo;
                    GLReg.Modify();
                end;

                Commit();

                Message(Text1100007, DocCount);
            end;

            trigger OnPreDataItem()
            begin
                DocPost.CheckPostingDate(PostingDate);

                Find('-');
                ArePostedDocs := "Document Situation" = "Document Situation"::"Posted BG/PO";

                if UseJournal = UseJournal::AuxJournal then begin
                    GenJnlBatch.Get(TemplName, BatchName);
                    ReasonCode := GenJnlBatch."Reason Code";
                    GenJnlTemplate.Get(TemplName);
                    SourceCode := GenJnlTemplate."Source Code";
                end else begin
                    ReasonCode := '';
                    SourceCodeSetup.Get();
                    SourceCode := SourceCodeSetup."Cartera Journal"
                end;

                case "Document Type" of
                    "Document Type"::Bill:
                        Window.Open(
                          Text1100001);
                    "Document Type"::Invoice:
                        Window.Open(
                          Text1100002);
                    else
                        Window.Open(
                          Text1100003);
                end;

                DocCount := 0;
                GenJnlLineNextNo := 0;
                ExistVATEntry := false;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        SourceTable = Customer;

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
                        ToolTip = 'Specifies the posting date.';
                    }
                    field(IncludeExpenses; IncludeExpenses)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Expenses';
                        ToolTip = 'Specifies if you want to include the expenses resulting from document rejections. If expenses are included, the amount will be calculated as it was defined under fees for the operation called Rejection Expenses.';
                    }
                    field(UseJournal; UseJournal)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post';
                        OptionCaption = 'Direct,Auxiliary Journal';
                        ToolTip = 'Specifies where to post the ledger entries associated with the document rejection. Direct: Will post directly to the Ledger Entries table. Auxiliary Journal: Will post through a journal that you specify.';

                        trigger OnValidate()
                        begin
                            if UseJournal = UseJournal::Direct then begin
                                BatchName := '';
                                TemplName := '';
                            end;
                        end;
                    }
                    group("Auxiliary Journal")
                    {
                        Caption = 'Auxiliary Journal';
                        field(TemplateName; TemplName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Template Name';
                            TableRelation = "Gen. Journal Template".Name where(Type = const(Cartera),
                                                                                Recurring = const(false));
                            ToolTip = 'Specifies the template that will be used when posting. By default, the CARTERA template is selected.';

                            trigger OnValidate()
                            begin
                                if TemplName = '' then
                                    BatchName := ''
                                else
                                    if UseJournal = UseJournal::Direct then
                                        Error(Text1100008);
                            end;
                        }
                        field(BatchName; BatchName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Batch Name';
                            TableRelation = "Gen. Journal Batch".Name;
                            ToolTip = 'Specifies the name of the journal batch.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                if TemplName = '' then
                                    exit;

                                if GenJnlBatch.Get(TemplName, Text) then;
                                GenJnlBatch.SetRange("Journal Template Name", TemplName);
                                if PAGE.RunModal(PAGE::"General Journal Batches", GenJnlBatch) = ACTION::LookupOK then
                                    BatchName := GenJnlBatch.Name;
                            end;

                            trigger OnValidate()
                            begin
                                if TemplName = '' then
                                    BatchName := '';
                            end;
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PostingDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        OnBeforeOnPreReport(PostingDate, IncludeExpenses, UseJournal, TemplName, BatchName);

        GLSetup.Get();

        if UseJournal = UseJournal::AuxJournal then begin
            if not GenJnlBatch.Get(TemplName, BatchName) then
                Error(Text1100000);
            ReasonCode := GenJnlBatch."Reason Code";
            GenJnlTemplate.Get(TemplName);
            SourceCode := GenJnlTemplate."Source Code";
        end;
    end;

    var
        Text1100000: Label 'Please fill in both the Template Name and the Batch Name of the Auxiliary Journal with correct values.';
        Text1100001: Label 'Rejecting receivable bills              #1######';
        Text1100002: Label 'Rejecting receivable invoices           #1######';
        Text1100003: Label 'Rejecting receivable documents          #1######';
        Text1100004: Label 'Rejected Bill %1/%2';
        Text1100005: Label 'Rejected Document %1';
        Text1100006: Label 'Document Rejection Expenses';
        Text1100007: Label '%1 documents have been rejected.';
        Text1100008: Label 'This field must be blank for Direct Posting.';
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        PostedBillGr: Record "Posted Bill Group";
        GenJnlLine: Record "Gen. Journal Line" temporary;
        BankAcc: Record "Bank Account";
        SourceCodeSetup: Record "Source Code Setup";
        CustPostingGr: Record "Customer Posting Group";
        BankAccPostingGr: Record "Bank Account Posting Group";
        Doc: Record "Cartera Doc.";
        PostedDoc: Record "Posted Cartera Doc.";
        ClosedDoc: Record "Closed Cartera Doc.";
        FeeRange: Record "Fee Range";
        GLSetup: Record "General Ledger Setup";
        GLReg: Record "G/L Register";
        Currency: Record Currency;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DocPost: Codeunit "Document-Post";
        CarteraManagement: Codeunit CarteraManagement;
        GenJnlManagement: Codeunit GenJnlManagement;
        CarteraJnlForm: Page "Cartera Journal";
        Window: Dialog;
        IncludeExpenses: Boolean;
        PostingDate: Date;
        PostingDate2: Date;
        TransactionNo: Integer;
        CurrDescription: Text[250];
        CurrDocNo: Code[20];
        CurrDocNo2: Code[20];
        UseJournal: Option Direct,AuxJournal;
        BatchName: Code[10];
        TemplName: Code[10];
        Discount: Boolean;
        SourceCode: Code[10];
        GenJnlLineNextNo: Integer;
        DocCount: Integer;
        BalanceAccNo: Code[20];
        ArePostedDocs: Boolean;
        ReasonCode: Code[10];
        Factoring: Boolean;
        VATPostingSetup: Record "VAT Posting Setup";
        NoRealVATBuffer: Record "BG/PO Post. Buffer" temporary;
        FirstVATEntryNo: Integer;
        LastVATEntryNo: Integer;
        ExistVATEntry: Boolean;
        IsRedrawn: Boolean;
        GainLossAmt: Decimal;
        TempCurrCode: Code[10];
        NoRegs: Integer;
        i: Integer;
        MemIntReg: Record "BG/PO Post. Buffer";
        EntryType: Option " ","Initial Entry",Application,"Unrealized Loss","Unrealized Gain","Realized Loss","Realized Gain","Payment Discount","Payment Discount (VAT Excl.)","Payment Discount (VAT Adjustment)","Appln. Rounding","Correction of Remaining Amount",,,,,,,,,Settlement,Rejection,Redrawal,Expenses;
        ExistsNoRealVAT: Boolean;
        FindInClosedBills: Boolean;

    local procedure PrepareBillRejPosting(RemainingAmt: Decimal)
    var
        TempCurrencyCode: Code[10];
        Type: Option Receivable,Payable;
    begin
        CustPostingGr.Get(CustLedgEntry."Customer Posting Group");
        CustPostingGr.TestField("Rejected Bills Acc.");
        InsertGenJournalLine(
          GenJnlLine."Account Type"::"G/L Account",
          CustPostingGr."Rejected Bills Acc.",
          RemainingAmt,
          CustLedgEntry."Dimension Set ID");
        if ArePostedDocs then
            if Discount then begin
                CustPostingGr.TestField("Discted. Bills Acc.");
                BalanceAccNo := CustPostingGr."Discted. Bills Acc.";
            end else begin
                CustPostingGr.TestField("Bills on Collection Acc.");
                BalanceAccNo := CustPostingGr."Bills on Collection Acc.";
            end
        else begin
            CustPostingGr.TestField("Bills Account");
            BalanceAccNo := CustPostingGr."Bills Account";
        end;
        OnAfterGetBillsBalanceAccNo(GenJnlLine, CustLedgEntry, BalanceAccNo);

        PostingDate2 := 0D;
        GainLossAmt := 0;
        if CustLedgEntry."Currency Code" <> '' then begin
            Currency.Get(CustLedgEntry."Currency Code");
            if ArePostedDocs then
                PostingDate2 := CarteraManagement.GetLastDate(CustLedgEntry."Currency Code", PostedBillGr."Posting Date", Type::Receivable)
            else
                PostingDate2 := CarteraManagement.GetLastDate(CustLedgEntry."Currency Code", CustLedgEntry."Posting Date", Type::Receivable);

            GainLossAmt := CarteraManagement.GetGainLoss(
                PostingDate2,
                PostingDate,
                RemainingAmt,
                CustLedgEntry."Currency Code");
        end;

        InsertGenJournalLine(
          GenJnlLine."Account Type"::"G/L Account",
          BalanceAccNo,
          -RemainingAmt,
          CustLedgEntry."Dimension Set ID");

        if GainLossAmt <> 0 then begin
            TempCurrencyCode := CustLedgEntry."Currency Code";
            CustLedgEntry."Currency Code" := '';
            if GainLossAmt > 0 then begin
                Currency.TestField("Realized Gains Acc.");
                InsertGenJournalLine(
                  GenJnlLine."Account Type"::"G/L Account",
                  Currency."Realized Gains Acc.",
                  -GainLossAmt,
                  CustLedgEntry."Dimension Set ID");
            end else begin
                Currency.TestField("Realized Losses Acc.");
                InsertGenJournalLine(
                  GenJnlLine."Account Type"::"G/L Account",
                  Currency."Realized Losses Acc.",
                  -GainLossAmt,
                  CustLedgEntry."Dimension Set ID");
            end;
            InsertGenJournalLine(
              GenJnlLine."Account Type"::"G/L Account",
              BalanceAccNo,
              GainLossAmt,
              CustLedgEntry."Dimension Set ID");

            CustLedgEntry."Currency Code" := TempCurrencyCode;
        end;

        if Discount then begin
            BankAccPostingGr.TestField("Liabs. for Disc. Bills Acc.");
            InsertGenJournalLine(
              GenJnlLine."Account Type"::"G/L Account",
              BankAccPostingGr."Liabs. for Disc. Bills Acc.",
              RemainingAmt,
              CustLedgEntry."Dimension Set ID");

            InsertGenJournalLine(
              GenJnlLine."Account Type"::"Bank Account",
              BankAcc."No.",
              -RemainingAmt,
              CustLedgEntry."Dimension Set ID");
        end;
    end;

    local procedure PrepareInvoiceRejPosting(RemainingAmt: Decimal)
    var
        TempCurrencyCode: Code[10];
        Type: Option Receivable,Payable;
    begin
        CustPostingGr.Get(CustLedgEntry."Customer Posting Group");
        CustPostingGr.TestField("Rejected Factoring Acc.");

        PostingDate2 := 0D;
        GainLossAmt := 0;
        if CustLedgEntry."Currency Code" <> '' then begin
            Currency.Get(CustLedgEntry."Currency Code");
            if ArePostedDocs then
                PostingDate2 := CarteraManagement.GetLastDate(CustLedgEntry."Currency Code", PostedBillGr."Posting Date", Type::Receivable)
            else
                PostingDate2 := CarteraManagement.GetLastDate(CustLedgEntry."Currency Code", CustLedgEntry."Posting Date", Type::Receivable);
            GainLossAmt := CarteraManagement.GetGainLoss(
                PostingDate2,
                PostingDate,
                RemainingAmt,
                CustLedgEntry."Currency Code");
        end;

        if ArePostedDocs then begin
            InsertGenJournalLine(
              GenJnlLine."Account Type"::"G/L Account",
              CustPostingGr."Rejected Factoring Acc.",
              RemainingAmt,
              CustLedgEntry."Dimension Set ID");
            if ArePostedDocs then
                if Discount then begin
                    CustPostingGr.TestField("Factoring for Discount Acc.");
                    BalanceAccNo := CustPostingGr."Factoring for Discount Acc.";
                end else begin
                    CustPostingGr.TestField("Factoring for Collection Acc.");
                    BalanceAccNo := CustPostingGr."Factoring for Collection Acc.";
                end;
            InsertGenJournalLine(
              GenJnlLine."Account Type"::"G/L Account",
              BalanceAccNo,
              -RemainingAmt,
              CustLedgEntry."Dimension Set ID");
        end;

        if GainLossAmt <> 0 then begin
            TempCurrencyCode := CustLedgEntry."Currency Code";
            CustLedgEntry."Currency Code" := '';
            if GainLossAmt > 0 then begin
                Currency.TestField("Realized Gains Acc.");
                InsertGenJournalLine(
                  GenJnlLine."Account Type"::"G/L Account",
                  Currency."Realized Gains Acc.",
                  -GainLossAmt,
                  CustLedgEntry."Dimension Set ID");
            end else begin
                Currency.TestField("Realized Losses Acc.");
                InsertGenJournalLine(
                  GenJnlLine."Account Type"::"G/L Account",
                  Currency."Realized Losses Acc.",
                  -GainLossAmt,
                  CustLedgEntry."Dimension Set ID");
            end;
            InsertGenJournalLine(
              GenJnlLine."Account Type"::"G/L Account",
              BalanceAccNo,
              GainLossAmt,
              CustLedgEntry."Dimension Set ID");

            CustLedgEntry."Currency Code" := TempCurrencyCode;
        end;

        if Discount then begin
            BankAccPostingGr.TestField("Liabs. for Factoring Acc.");
            InsertGenJournalLine(
              GenJnlLine."Account Type"::"G/L Account",
              BankAccPostingGr."Liabs. for Factoring Acc.",
              DocPost.FindDisctdAmt(RemainingAmt, CustLedgEntry."Customer No.", BankAcc."No."),
              CustLedgEntry."Dimension Set ID");

            InsertGenJournalLine(
              GenJnlLine."Account Type"::"Bank Account",
              BankAcc."No.",
              -DocPost.FindDisctdAmt(RemainingAmt, CustLedgEntry."Customer No.", BankAcc."No."),
              CustLedgEntry."Dimension Set ID");
        end;
    end;

    local procedure InsertGenJournalLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount2: Decimal; DimSetID: Integer)
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        Clear(GenJnlLine);
        GenJnlLine.Init();
        GenJnlLine."Line No." := GenJnlLineNextNo;
        GenJnlLine."Posting Date" := PostingDate;
        if UseJournal = UseJournal::AuxJournal then begin
            GenJnlLine."Journal Template Name" := TemplName;
            GenJnlLine."Journal Batch Name" := BatchName;
        end;
        GenJnlLine."Document No." := CurrDocNo;
        GenJnlLine."Bill No." := CurrDocNo2;
        GenJnlLine.Validate("Account Type", AccType);
        GenJnlLine.Validate("Account No.", AccNo);
        GenJnlLine.Description := CopyStr(CurrDescription, 1, MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Validate("Currency Code", CustLedgEntry."Currency Code");
        GenJnlLine.Validate(Amount, Amount2);
        if AccType = GenJnlLine."Account Type"::"G/L Account" then begin
            GenJnlLine."Source No." := CustLedgEntry."Customer No.";
            GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
        end;
        GenJnlLine."Source Code" := SourceCode;
        GenJnlLine."Reason Code" := ReasonCode;
        GenJnlLine."Dimension Set ID" :=
          CarteraManagement.GetCombinedDimSetID(GenJnlLine, DimSetID);
        if UseJournal = UseJournal::AuxJournal then
            GenJnlLine."System-Created Entry" := false
        else
            GenJnlLine."System-Created Entry" := true;
        GenJnlLine.Insert();
    end;

    local procedure PostGenJournal()
    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlLine2: Record "Gen. Journal Line";
        LastLineNo: Integer;
    begin
        OnBeforePostGenJournal(GenJnlLine, CustLedgEntry);
        Window.Close();

        if not GenJnlLine.Find('-') then
            exit;

        if UseJournal = UseJournal::AuxJournal then begin
            GenJnlLine2.LockTable();
            GenJnlLine2.SetRange("Journal Template Name", TemplName);
            GenJnlLine2.SetRange("Journal Batch Name", BatchName);
            if GenJnlLine2.FindLast() then begin
                LastLineNo := GenJnlLine2."Line No.";
                TransactionNo := GenJnlLine2."Transaction No." + 1;
            end;
            repeat
                GenJnlLine2 := GenJnlLine;
                GenJnlLine2."Line No." := GenJnlLine2."Line No." + LastLineNo;
                GenJnlLine2."Transaction No." := TransactionNo;
                GenJnlLine2.Insert();
            until GenJnlLine.Next() = 0;
            Commit();
            GenJnlLine2.Reset();
            GenJnlTemplate.Get(TemplName);
            GenJnlLine2.FilterGroup := 2;
            GenJnlLine2.SetRange("Journal Template Name", TemplName);
            GenJnlLine2.FilterGroup := 0;
            GenJnlManagement.SetName(BatchName, GenJnlLine2);
            CarteraJnlForm.SetTableView(GenJnlLine2);
            CarteraJnlForm.SetRecord(GenJnlLine2);
            CarteraJnlForm.AllowClosing(true);
            CarteraJnlForm.RunModal();
        end
        else
            repeat
                GenJnlLine2 := GenJnlLine;
                GenJnlPostLine.RunWithCheck(GenJnlLine2);
            until GenJnlLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustFindVATSetup(var VATPostingSetup: Record "VAT Posting Setup"; CustLedgEntry: Record "Cust. Ledger Entry"; var IsFromJnl: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetBillsBalanceAccNo(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; var BalanceAccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostGenJournal(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreReport(var PostingDate: Date; var IncludeExpenses: Boolean; var UseJournal: Option; var TemplName: Code[10]; var BatchName: Code[10])
    begin
    end;
}

