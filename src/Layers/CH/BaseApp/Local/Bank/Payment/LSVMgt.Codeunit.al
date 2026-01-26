// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Receivables;
using System.Environment;
using System.IO;

codeunit 3010831 LSVMgt
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "LSV Setup" = m;

    trigger OnRun()
    begin
    end;

    var
        DeleteLSVJournalLineQst: Label 'The payment for customer %1 with amount %2 is planned for LSV collection %3.\Do you want to delete the line?';
        GLEntriesExistErr: Label 'There are already entries in the G/L journal %1. Please post or delete them before you proceed.';
        ConfirmImportQst: Label 'Do you want to import the DebitDirect confirmation file?';
        ImportCancelledErr: Label 'Import was cancelled.';
        CannotBackupMsg: Label 'Backup copy of Debit Direct confirmation file could not be written. Please check LSV setup.';
        ModifyFieldQst: Label 'Do you want to modify the field %1 on all lines from %2 to %3?';
        ImportProgressMsg: Label 'Import Debit Direct confirmation file\No. of payments   #1#########\Total amount     #2#########';
        TransactionErr: Label 'Transaction was not identified. \Import was cancelled.';
        CollectionClosedErr: Label 'Collection is Closed, no change possible.';
        EntryNotFoundErr: Label '%1 entry not found.';
        NoInvoiceErr: Label 'Invoice %1 could not be found. Please check the file.';
        ReopenCollectionQst: Label 'Reopen Collection, are you sure?';
        InvoiceDuplicateErr: Label 'Invoice %1 duplicate. Please check.';
        InvoiceFinishedErr: Label 'Invoice %1 was finished. Please check.';
        LSVSetup: Record "LSV Setup";
        LsvJour: Record "LSV Journal";
        LsvJournalLine: Record "LSV Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        GlLine: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        GlBatchName: Record "Gen. Journal Batch";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        FileMgt: Codeunit "File Management";
        EnvironmentInfo: Codeunit "Environment Information";
        Window: Dialog;
        WrongFileErr: Label 'Wrong file.\Import was cancelled.';
        DDPaymentTxt: Label 'Debit Direct payment ';
        ImportWarningMsg: Label 'Import warning:\\Not all transactions could be imported. \\Credit records imported: %1\Rejected or reversed records: %2\Total amounts credit: %3\Total amounts rejected or reversed: %4\Check the payments carefully in the LSV Journal. Some of the payments could have been rejected.', Comment = 'All 4 parameters are numbers.';
        RecordLengthErr: Label 'The recordlength %1 from file is not known.\Import was cancelled.';
        DDOrderNoErr: Label 'Could not find Debit Direct Order No. %1 from %2.';
        DDPaymentInvTxt: Label 'DD payment, inv ';
        DDCorrectionTxt: Label 'DD correction debit ';
        SuccessMsg: Label '%1 payments for %3 %2 was successfully imported.', Comment = 'Parameter 1 - integer, 2 - decimal, 3 - currency code.';
        GenJournalNotEmptyErr: Label 'Journal "%1" contains entries. Please process these first.';
        TransactionNoErr: Label 'Could not find Transaction No. %1 in Debit Direct Order No. %2.';
        ChooseFileTitleMsg: Label 'Choose the file to upload.';

    [Scope('OnPrem')]
    procedure ReleaseCustLedgEntries(GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer then begin
            CustLedgEntry.Reset();
            CustLedgEntry.SetCurrentKey("Document No.");
            CustLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            CustLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            CustLedgEntry.SetFilter("LSV No.", '<>%1', 0);
            if CustLedgEntry.FindFirst() then begin
                if not Confirm(
                     DeleteLSVJournalLineQst,
                     true, GenJnlLine."Account No.", -GenJnlLine.Amount, CustLedgEntry."LSV No.")
                then
                    Error('');

                LsvJournalLine.SetCurrentKey("Applies-to Doc. No.");
                LsvJournalLine.SetRange("Applies-to Doc. No.", GenJnlLine."Applies-to Doc. No.");
                if not LsvJournalLine.FindFirst() then
                    Error(EntryNotFoundErr, LsvJournalLine.TableCaption());

                LsvJournalLine."LSV Status" := LsvJournalLine."LSV Status"::Open;
                LsvJournalLine.Modify();

                LsvJour.Get(LsvJournalLine."LSV Journal No.");
                LsvJour.Validate("LSV Status");
                LsvJour.Modify();

                // Adjust balance posting in G/L Line if matching Total Amount
                GlLine.Reset();
                GlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                GlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
                if GlLine.FindLast() then
                    if GlLine.Amount = LsvJour.Amount then begin  // Amount before Corr.
                        GlLine.Validate(Amount, LsvJour.Amount);
                        GlLine.Modify();
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ModifyPostingDate(var ActLSVJourLine: Record "LSV Journal Line")
    var
        ModifyPostingDayInput: Page "Modify Posting Day Input";
        NewDate: Date;
    begin
        LsvJour.Get(ActLSVJourLine."LSV Journal No.");
        if LsvJour."LSV Status" >= LsvJour."LSV Status"::Released then
            Error(CollectionClosedErr);
        NewDate := LsvJour."Credit Date";

        ModifyPostingDayInput.SetNewPostingDate(NewDate);
        if ModifyPostingDayInput.RunModal() = ACTION::OK then
            ModifyPostingDayInput.GetNewPostingDate(NewDate)
        else
            exit;

        if not Confirm(ModifyFieldQst, true, LsvJour.FieldCaption("Credit Date"), LsvJour."Credit Date", NewDate) then
            exit;

        LsvJour."Credit Date" := NewDate;
        LsvJour.Modify();
    end;

    [Scope('OnPrem')]
    procedure LSVJournalToGLJournal(GenJournalLine: Record "Gen. Journal Line"; LsvJournal: Record "LSV Journal")
    var
        LsvLine: Record "LSV Journal Line";
        GLSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeries: Codeunit "No. Series";
        LastEntryNo: Integer;
    begin
        LsvLine.SetRange("LSV Journal No.", LsvJournal."No.");
        LsvLine.SetRange("LSV Status", LsvLine."LSV Status"::Open);

        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        if GenJournalLine.FindFirst() then
            Error(GLEntriesExistErr, GenJournalLine."Journal Batch Name");
        if GenJournalLine.FindLast() then
            LastEntryNo := GenJournalLine."Line No.";

        GenJournalBatch.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalBatch.SetRange(Name, GenJournalLine."Journal Batch Name");
        GenJournalBatch.FindFirst();
        GenJournalBatch.TestField("No. Series");

        if LsvLine.Find('-') then
            repeat
                LastEntryNo := LastEntryNo + 10000;
                GenJournalLine.Init();
                GenJournalLine."Journal Template Name" := GenJournalLine."Journal Template Name";
                GenJournalLine."Journal Batch Name" := GenJournalLine."Journal Batch Name";
                GenJournalLine."Line No." := LastEntryNo;
                GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
                GenJournalLine.Validate("Document No.", NoSeries.PeekNextNo(GenJournalBatch."No. Series", LsvJournal."Credit Date"));
                GenJournalLine.Validate("Posting Date", LsvJournal."Credit Date");
                GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Invoice;
                GenJournalLine.Validate("Applies-to Doc. No.", LsvLine."Applies-to Doc. No.");
                GenJournalLine.Validate("Credit Amount", LsvLine."Collection Amount");
                GLSetup.Get();
                if GLSetup."LCY Code" <> LsvLine."Currency Code" then
                    GenJournalLine.Validate("Currency Code", LsvLine."Currency Code");
                OnLSVJournalToGLJournalOnBeforeGenJournalLineInsert(GenJournalLine, LsvLine);
                GenJournalLine.Insert();
                LsvLine."LSV Status" := LsvLine."LSV Status"::"Transferred to Pmt. Journal";
                LsvLine.Modify();
            until LsvLine.Next() = 0;
        LsvJournal.Validate("LSV Status");
        LsvJournal.Modify();
    end;

    [Scope('OnPrem')]
    procedure ClosedByESR(InvoiceNo: Code[20])
    begin
        LsvJournalLine.Reset();
        LsvJournalLine.SetCurrentKey("Applies-to Doc. No.");
        LsvJournalLine.SetRange("Applies-to Doc. No.", InvoiceNo);
        LsvJournalLine.SetRange("LSV Status", LsvJournalLine."LSV Status"::"Closed by Import File",
          LsvJournalLine."LSV Status"::"Transferred to Pmt. Journal");
        if LsvJournalLine.FindFirst() then
            Error(InvoiceFinishedErr, InvoiceNo);
        LsvJournalLine.SetRange("LSV Status");
        if not LsvJournalLine.FindFirst() then
            Error(NoInvoiceErr, InvoiceNo);

        if LsvJournalLine.Count > 1 then begin
            // Rejected entry switch to Closed by ESR
            LsvJournalLine.SetRange("LSV Status", LsvJournalLine."LSV Status"::Rejected);
            if not LsvJournalLine.FindFirst() then
                Error(InvoiceDuplicateErr, InvoiceNo);

            CustLedgEntry.Get(LsvJournalLine."Cust. Ledg. Entry No.");
            CustLedgEntry."On Hold" := 'LSV';
            CustLedgEntry."LSV No." := LsvJournalLine."LSV Journal No.";
            CustLedgEntry.Modify();
            LsvJournalLine."LSV Status" := LsvJournalLine."LSV Status"::"Closed by Import File";
            LsvJournalLine.Modify();

            // Switch the open to rejected
            LsvJournalLine.SetRange("LSV Status", LsvJournalLine."LSV Status"::Open);
            if not LsvJournalLine.FindFirst() then
                Error(InvoiceDuplicateErr, InvoiceNo);
            LsvJournalLine."LSV Status" := LsvJournalLine."LSV Status"::Rejected;
            LsvJournalLine.Modify();
        end else begin
            LsvJournalLine."LSV Status" := LsvJournalLine."LSV Status"::"Closed by Import File";
            LsvJournalLine.Modify();
        end;

        LsvJour.Get(LsvJournalLine."LSV Journal No.");
        LsvJour.Validate("LSV Status");
        LsvJour.Modify();
    end;

    [Scope('OnPrem')]
    procedure ReopenJournal(var ActLSVJour: Record "LSV Journal")
    begin
        if ActLSVJour."LSV Status" >= ActLSVJour."LSV Status"::Finished then
            Error(CollectionClosedErr);

        LsvJournalLine.SetRange("LSV Journal No.", ActLSVJour."No.");
        LsvJournalLine.SetFilter("LSV Status", '<>%1', LsvJournalLine."LSV Status"::Open);
        if LsvJournalLine.FindFirst() then
            Error(CollectionClosedErr);

        if not Confirm(ReopenCollectionQst, false) then
            exit;

        ActLSVJour."LSV Status" := ActLSVJour."LSV Status"::Edit;
        ActLSVJour.Modify();
    end;

    local procedure CheckLSVSetup(ActLSVSetup: Record "LSV Setup")
    begin
        // Check ESR Setup
        ActLSVSetup.TestField("Bal. Account No.");

        // OnPrem - check
        if not EnvironmentInfo.IsSaaS() then
            ActLSVSetup.TestField("DebitDirect Import Filename");

        if ActLSVSetup."Backup Copy" then begin
            ActLSVSetup.TestField("Backup Folder");
            ActLSVSetup.TestField("Last Backup No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure ImportDebitDirectFile(var ActGenJnlLine: Record "Gen. Journal Line")
    var
        f: File;
        TA: Code[2];
        Currency: Code[3];
        InInvoiceNo: Code[10];
        NextDocNo: Code[20];
        DebitDirectOrderNo: Code[2];
        FileName: Text[1024];
        Line: Text[1024];
        InvoiceAmt: Decimal;
        TotalAmt: Decimal;
        CreditAmount: Decimal;
        RejectionAmount: Decimal;
        ReversalAmount: Decimal;
        FeeAmount: Decimal;
        RejectionCode: Integer;
        TotalRecRecords: Integer;
        TotalRecRecordsRev: Integer;
        NoRecords: Integer;
        LastLineNo: Integer;
        DebitDirectRecordNo: Integer;
        Transaction: Option " ",Credit,Cancellation,Correction;
        BalanceAccountType: Enum "Gen. Journal Account Type";
        PrevTransaction: Option " ",Credit,Cancellation,Correction;
        PostDate: Date;
        FirstPostingDate: Date;
        MultiplePostingDates: Boolean;
        IsCancellationExist: Boolean;
    begin
        SelectAndCheckGenJournalLine(GenJournalLine, ActGenJnlLine);

        // One or multiple ESR banks
        if LSVSetup.Count = 1 then begin
            LSVSetup.FindFirst();
            if not Confirm(ConfirmImportQst, false) then
                exit;
        end else
            if PAGE.RunModal(PAGE::"LSV Setup List", LSVSetup) = ACTION::LookupCancel then
                Error(ImportCancelledErr);

        CheckLSVSetup(LSVSetup);

        if LSVSetup."Backup Copy" then
            BackupDDImportFile(LSVSetup);

        // Journal name for no serie
        GlBatchName.Get(ActGenJnlLine."Journal Template Name", ActGenJnlLine."Journal Batch Name");
        NextDocNo := NoSeriesBatch.GetNextNo(GlBatchName."No. Series", PostDate);

        FileName := OpenDDFile(f);
        Window.Open(ImportProgressMsg);

        while ReadDebitDirectLine(f, Line) > 1 do begin
            ValidateLineLength(f, FileName, StrLen(Line));
            ValidateFileID(CopyStr(Line, 1, 3));
            TA := CopyStr(Line, 36, 2);
            if TA = '97' then begin
                AddAmounts(CreditAmount, RejectionAmount, ReversalAmount, FeeAmount, Line);
                AddCounts(TotalRecRecords, TotalRecRecordsRev, Line);
            end else begin
                ReadInvoiceValues(InvoiceAmt, PostDate, DebitDirectOrderNo, DebitDirectRecordNo, RejectionCode, Currency, Line);
                InInvoiceNo := ProcessDebitDirect(LsvJournalLine, PostDate, DebitDirectOrderNo, DebitDirectRecordNo);
                PrevTransaction := Transaction;
                GetAndProcessTransaction(TA, RejectionCode, LsvJournalLine, Transaction, InInvoiceNo);
                if (PrevTransaction <> Transaction) and
                   ((PrevTransaction = Transaction::Cancellation) or (Transaction = Transaction::Cancellation))
                then
                    NextDocNo := NoSeriesBatch.GetNextNo(GlBatchName."No. Series", PostDate);

                if Transaction <> Transaction::Correction then begin
                    PrepareGenJournalLine(GenJournalLine, ActGenJnlLine, PostDate, Transaction, LastLineNo, NextDocNo, Currency);
                    SetValuesDueToTransaction(GenJournalLine, Transaction, InvoiceAmt, InInvoiceNo, IsCancellationExist);
                    GenJournalLine."Source Code" := 'DD';
                    GenJournalLine."Reason Code" := GlBatchName."Reason Code";
                    GenJournalLine.Insert();
                    Commit();

                    // All lines same credit date? (one/multiple balance postings)
                    if FirstPostingDate = 0D then  // Save first
                        FirstPostingDate := PostDate;
                    if FirstPostingDate <> PostDate then  // Compare subsequent
                        MultiplePostingDates := true;

                    NoRecords += 1;
                    TotalAmt := TotalAmt - InvoiceAmt;  // Amount is negative
                    Window.Update(1, NoRecords);
                    Window.Update(2, TotalAmt);
                end;
            end;
        end;
        CloseDDFile(f, FileName);

        GetBalanceAccountType(LSVSetup, BalanceAccountType);
        if MultiplePostingDates or IsCancellationExist then
            SetBalanceAccounts(GenJournalLine, BalanceAccountType, LSVSetup."Bal. Account No.")
        else begin
            PrepareGenJournalLine(GenJournalLine, ActGenJnlLine, PostDate, Transaction, LastLineNo, NextDocNo, Currency);
            InsertBalancingLine(GenJournalLine, BalanceAccountType, LSVSetup, TotalAmt);
        end;

        Window.Close();
        VerifyChecksum(NoRecords, TotalRecRecords, TotalRecRecordsRev, CreditAmount, ReversalAmount, RejectionAmount, TotalAmt, Currency);
    end;

    local procedure ReadDebitDirectLine(var f: File; var Line: Text[1024]): Integer
    var
        BytesRead: Integer;
    begin
        // Reade each ESR line in ESR file
        // Textfile Mode: 130 chars read, to CR/LF. exit(0) means EOF

        Line := '';  // init

        // File with CR/LF
        BytesRead := f.Read(Line);
        if BytesRead = 0 then
            exit(0);

        Line := ConvertStr(Line, ' ', '0');  // Fill Blanks with Zero

        exit(BytesRead);
    end;

    local procedure BackupDDImportFile(var LSVSetup: Record "LSV Setup")
    var
        BackupFilename: Text[300];
    begin
        LSVSetup.LockTable();
        LSVSetup."Last Backup No." := IncStr(LSVSetup."Last Backup No.");
        LSVSetup.Modify();
        BackupFilename := LSVSetup."Backup Folder" + 'DD' + LSVSetup."Last Backup No." + '.BAK';
        if not Exists(BackupFilename) then
            Message(CannotBackupMsg);
    end;

    local procedure ReadPostDate(DateTxt: Text[6]) Result: Date
    var
        ddCR: Integer;
        mmCR: Integer;
        yyCR: Integer;
    begin
        Evaluate(yyCR, CopyStr(DateTxt, 1, 2));
        Evaluate(mmCR, CopyStr(DateTxt, 3, 2));
        Evaluate(ddCR, CopyStr(DateTxt, 5, 2));
        if yyCR > 98 then
            Result := DMY2Date(ddCR, mmCR, 1900 + yyCR)
        else
            Result := DMY2Date(ddCR, mmCR, 2000 + yyCR);
    end;

    local procedure AddAmount(var Amount: Decimal; AddAmountText: Text)
    var
        TempAmount: Decimal;
    begin
        Evaluate(TempAmount, AddAmountText);
        Amount += TempAmount / 100;
    end;

    local procedure AddAmounts(var CreditAmount: Decimal; var RejectionAmount: Decimal; var ReversalAmount: Decimal; var FeeAmount: Decimal; Line: Text)
    begin
        AddAmount(CreditAmount, CopyStr(Line, 60, 13));
        AddAmount(RejectionAmount, CopyStr(Line, 82, 13));
        AddAmount(ReversalAmount, CopyStr(Line, 104, 13));
        AddAmount(FeeAmount, CopyStr(Line, 120, 11));
    end;

    local procedure AddCount(var Counter: Integer; AddValueText: Text)
    var
        TempAddValue: Integer;
    begin
        Evaluate(TempAddValue, AddValueText);
        Counter += TempAddValue;
    end;

    local procedure AddCounts(var TotalRecRecords: Integer; var TotalRecRecordsRev: Integer; Line: Text)
    begin
        // Credit Count
        AddCount(TotalRecRecords, CopyStr(Line, 54, 6));
        // Rejection Count
        AddCount(TotalRecRecordsRev, CopyStr(Line, 76, 6));
        // Reversal Count
        AddCount(TotalRecRecordsRev, CopyStr(Line, 98, 6));
    end;

    local procedure GetAndProcessTransaction(TACode: Code[2]; RejectionCode: Integer; var LSVJournalLine: Record "LSV Journal Line"; var Transaction: Option " ",Credit,Cancellation,Correction; InvoiceNo: Code[10])
    begin
        case TACode of
            '81':  // Credit
                begin
                    Transaction := Transaction::Credit;
                    LSVJournalLine."LSV Status" := LSVJournalLine."LSV Status"::Open;
                    LSVJournalLine."DD Rejection Reason" := LSVJournalLine."DD Rejection Reason"::" ";
                    LSVJournalLine.Modify();

                    if LSVSetup.ReadPermission then
                        ClosedByESR(InvoiceNo);
                end;
            '84':  // Cancellation "Storno"
                begin
                    if RejectionCode <> 2 then
                        Transaction := Transaction::Correction
                    else
                        Transaction := Transaction::Cancellation;

                    LSVJournalLine."LSV Status" := LSVJournalLine."LSV Status"::Rejected;
                    LSVJournalLine."DD Rejection Reason" := RejectionCode;
                    LSVJournalLine.Modify();
                end;
            else
                Error(TransactionErr);
        end;
    end;

    local procedure ProcessDebitDirect(var LSVJournalLine: Record "LSV Journal Line"; PostDate: Date; DebitDirectOrderNo: Code[2]; DebitDirectRecordNo: Integer): Code[10]
    var
        LSVJournal: Record "LSV Journal";
    begin
        LSVJournal.Reset();
        LSVJournal.SetRange("Credit Date", PostDate);
        LSVJournal.SetRange("DebitDirect Orderno.", DebitDirectOrderNo);
        if not LSVJournal.FindLast() then
            Error(DDOrderNoErr, DebitDirectOrderNo, PostDate);

        LSVJournalLine.Reset();
        LSVJournalLine.SetCurrentKey("LSV Journal No.", "Transaction No.");
        LSVJournalLine.SetRange("LSV Journal No.", LSVJournal."No.");
        LSVJournalLine.SetRange("Transaction No.", DebitDirectRecordNo);
        if not LSVJournalLine.FindFirst() then begin
            Window.Close();
            Error(TransactionNoErr, DebitDirectRecordNo, DebitDirectOrderNo);
        end;
        exit(LSVJournalLine."Applies-to Doc. No.");
    end;

    local procedure ValidateLineLength(var f: File; FileName: Text[1024]; LineLength: Integer)
    begin
        if LineLength <> 700 then begin
            CloseDDFile(f, FileName);
            Error(RecordLengthErr, LineLength);
        end;
    end;

    local procedure ValidateFileID(FileID: Code[3])
    begin
        if FileID <> '036' then
            Error(WrongFileErr);
    end;

    local procedure OpenDDFile(var f: File) Result: Text[1024]
    begin
        f.TextMode(true);
        Evaluate(Result, FileMgt.UploadFile(ChooseFileTitleMsg, ''));
        f.Open(Result);
    end;

    local procedure CloseDDFile(var f: File; FileName: Text[1024])
    begin
        f.Close();
        Erase(FileName); // remove server temp file
    end;

    local procedure ReadInvoiceValues(var InvoiceAmount: Decimal; var PostDate: Date; var DebitDirectOrderNo: Code[2]; var DebitDirectRecordNo: Integer; var RejectionCode: Integer; var Currency: Code[3]; Line: Text[1024])
    begin
        Evaluate(InvoiceAmount, CopyStr(Line, 54, 13));
        InvoiceAmount := InvoiceAmount / 100;
        PostDate := ReadPostDate(CopyStr(Line, 4, 6));
        DebitDirectOrderNo := CopyStr(Line, 34, 2);
        Evaluate(DebitDirectRecordNo, CopyStr(Line, 38, 6));
        Evaluate(RejectionCode, CopyStr(Line, 543, 2));
        Currency := CopyStr(Line, 51, 3);
    end;

    local procedure PrepareGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; ActGenJnlLine: Record "Gen. Journal Line"; PostDate: Date; Transaction: Option " ",Credit,Cancellation,Correction; var LastLineNo: Integer; DocumentNo: Code[20]; Currency: Code[3])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GenJournalLine.Init();

        GenJournalLine."Journal Template Name" := ActGenJnlLine."Journal Template Name";
        GenJournalLine."Journal Batch Name" := ActGenJnlLine."Journal Batch Name";

        GenJournalLine."Posting Date" := PostDate;

        LastLineNo := LastLineNo + 10000;
        GenJournalLine."Line No." := LastLineNo;

        if Transaction = Transaction::Cancellation then
            GenJournalLine."Document Type" := GenJournalLine."Document Type"::Refund
        else
            GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Document No." := DocumentNo;

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."LCY Code" <> Currency then
            GenJournalLine."Currency Code" := Currency;
    end;

    local procedure SetCustomerAndCurrencyFromInvoice(var GenJournalLine: Record "Gen. Journal Line"; InvoiceNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        CustLedgerEntry.SetCurrentKey("Document No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", InvoiceNo);
        if CustLedgerEntry.FindFirst() then
            GenJournalLine.Validate("Account No.", CustLedgerEntry."Customer No.");

        if GenJournalLine."Currency Code" <> CustLedgerEntry."Currency Code" then
            GenJournalLine.Validate("Currency Code", CustLedgerEntry."Currency Code");
    end;

    local procedure SetValuesDueToTransaction(var GenJournalLine: Record "Gen. Journal Line"; Transaction: Option " ",Credit,Cancellation,Correction; var InvoiceAmount: Decimal; InvoiceNo: Code[20]; var IsCancellationExist: Boolean)
    begin
        SetCustomerAndCurrencyFromInvoice(GenJournalLine, InvoiceNo);
        case Transaction of
            Transaction::Credit:
                begin
                    ApplyToInvoice(GenJournalLine, InvoiceNo);
                    InvoiceAmount := -InvoiceAmount;
                    GenJournalLine.Description := Format(DDPaymentInvTxt + ' ' + InvoiceNo, -MaxStrLen(GenJournalLine.Description));
                    GenJournalLine.Validate(Amount, InvoiceAmount);
                end;
            Transaction::Cancellation:
                begin
                    IsCancellationExist := true;
                    GenJournalLine.Description := Format(DDCorrectionTxt + ' ' + InvoiceNo, -MaxStrLen(GenJournalLine.Description));
                    GenJournalLine.Validate(Amount, InvoiceAmount);  // positive
                end;
        end;
    end;

    local procedure SetBalanceAccounts(var GenJournalLine: Record "Gen. Journal Line"; BalanceAccountType: Enum "Gen. Journal Account Type"; BalanceAccountNo: Code[20])
    begin
        if GenJournalLine.FindSet() then
            repeat
                GenJournalLine."Bal. Account Type" := BalanceAccountType;
                GenJournalLine.Validate("Bal. Account No.", BalanceAccountNo);
                GenJournalLine.Modify();
            until GenJournalLine.Next() = 0;
    end;

    local procedure GetBalanceAccountType(LSVSetup: Record "LSV Setup"; var BalanceAccountType: Enum "Gen. Journal Account Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if LSVSetup."Bal. Account Type" = LSVSetup."Bal. Account Type"::"Bank Account" then
            BalanceAccountType := GenJournalLine."Bal. Account Type"::"Bank Account"
        else
            BalanceAccountType := GenJournalLine."Bal. Account Type"::"G/L Account";
    end;

    local procedure InsertBalancingLine(var GenJournalLine: Record "Gen. Journal Line"; BalanceAccountType: Enum "Gen. Journal Account Type"; LSVSetup: Record "LSV Setup"; BalancingAmount: Decimal)
    begin
        GenJournalLine."Account Type" := BalanceAccountType;
        GenJournalLine."Source Code" := 'ESR';

        GenJournalLine.Validate("Account No.", LSVSetup."Bal. Account No.");
        GenJournalLine.Description := DDPaymentTxt + ' ' + LSVSetup."Bank Code";
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Validate(Amount, BalancingAmount);
        GenJournalLine.Insert();
    end;

    local procedure ApplyToInvoice(var GenJournalLine: Record "Gen. Journal Line"; InvoiceNo: Code[20])
    begin
        GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Invoice;
        GenJournalLine."Applies-to Doc. No." := InvoiceNo;
    end;

    local procedure VerifyChecksum(NoOfRecords: Integer; TotalRecRecords: Integer; TotalRecRecordsRev: Integer; CreditAmount: Decimal; ReversalAmount: Decimal; RejectionAmount: Decimal; TotalAmount: Decimal; Currency: Code[3])
    var
        TotalRecordsAmt: Decimal;
    begin
        TotalRecordsAmt := -CreditAmount + ReversalAmount - RejectionAmount;
        if (TotalRecRecordsRev <> 0) or (TotalRecordsAmt <> -TotalAmount) then
            Message(
              ImportWarningMsg,
              TotalRecRecords,
              TotalRecRecordsRev,
              Format(-CreditAmount, 0, '<Sign><Integer Thousand><Decimals,3>'),
              Format(ReversalAmount - RejectionAmount, 0, '<Sign><Integer Thousand><Decimals,3>'))
        else
            Message(SuccessMsg, NoOfRecords, TotalAmount, Currency);
    end;

    local procedure SelectAndCheckGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; ActGenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Template Name", ActGenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", ActGenJournalLine."Journal Batch Name");
        GenJournalLine.SetFilter("Account No.", '<>%1', '');
        if GenJournalLine.FindFirst() then
            Error(GenJournalNotEmptyErr, GenJournalLine."Journal Batch Name");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLSVJournalToGLJournalOnBeforeGenJournalLineInsert(var GenJournalLine: Record "Gen. Journal Line"; LsvLine: Record "LSV Journal Line")
    begin
    end;
}

