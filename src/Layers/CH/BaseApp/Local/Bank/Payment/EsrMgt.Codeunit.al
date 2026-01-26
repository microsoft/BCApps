// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Receivables;
using System.IO;

codeunit 3010531 EsrMgt
{
    Permissions = TableData "ESR Setup" = m;

    trigger OnRun()
    begin
    end;

    var
        Text008: Label 'Do you want to import the ESR file?';
        Text011: Label 'Import cancelled.';
        Text015: Label 'Journal "%1" contains entries. Please process these first.';
        Text017: Label 'Import ESR file\No. of payments   #1############\Total amount     #2############';
        Text020: Label 'ESR payment, inv ';
        Text021: Label 'ESR correction debit ';
        Text022: Label 'ESR correction ';
        Text025: Label 'ESR payment ';
        Text026: Label 'Checksum error on import.\\The number of payments or the sum of amounts does not match the checksum record.\\Total records read    : %1\Total of checksum     : %2\Total amounts read    : %3\Total of checksum     : %4.', Comment = 'All parameters are numbers.';
        Text036: Label '%1 payments of %2 for currency %3 were successfully imported.', Comment = 'Parameters 1 and 2 - numbers. 3 - currency code.';
        Text039: Label 'The record length from the file is not known.\Import was cancelled.';
        Text040: Label 'Transaction was not identified. \Import was cancelled.';
        ESRSetup: Record "ESR Setup";
        LsvSetup: Record "LSV Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GlBatchName: Record "Gen. Journal Batch";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        LsvMgt: Codeunit LSVMgt;
        FileMgt: Codeunit "File Management";
        Window: Dialog;
        TA: Code[3];
        RefNo: Code[27];
        InvoiceAmt: Decimal;
        MicroFilmNo: Code[9];
        PaymentCharges: Code[6];
        ddVA: Code[2];
        mmVA: Code[2];
        yyVA: Code[4];
        ddCR: Integer;
        mmCR: Integer;
        yyCR: Integer;
        PostDate: Date;
        FirstPostingDate: Date;
        MultiplePostingDates: Boolean;
        TotalRecAmt: Decimal;
        TotalRecCents: Integer;
        TotalRecRecords: Integer;
        TotalRecCharges: Decimal;
        NoRecords: Integer;
        TotalAmt: Decimal;
        LastLineNo: Integer;
        NextDocNo: Code[20];
        InInvoiceNo: Code[10];
        Currency: Code[3];
        Transaction: Option " ",Credit,Cancellation,Correction;
        TotalRecord: Boolean;
        Text041: Label 'The ESR Account No. %1 defined in the ESR Setup table cannot be detected at the expected position in the file. %2 is not able to determine the ESR record length.', Comment = '%2 - product name';
        Text042: Label 'More than one open invoice were found for the Reference No. %1.';
        ChooseFileTitleMsg: Label 'Choose the file to upload.';

    [Scope('OnPrem')]
    procedure CheckSetup(ActESRSetup: Record "ESR Setup")
    begin
        // Check ESR Setup
        ActESRSetup.TestField("Bal. Account No.");
        ActESRSetup.TestField("ESR Filename");
        ActESRSetup.TestField("BESR Customer ID");
        ActESRSetup.TestField("ESR Account No.");
        if ActESRSetup."Backup Copy" then begin
            ActESRSetup.TestField("Backup Folder");
            ActESRSetup.TestField("Last Backup No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure ImportEsrFile(var ActGenJnlLine: Record "Gen. Journal Line")
    var
        NoSeries: Codeunit "No. Series";
        BankMgt: Codeunit BankMgt;
        f: File;
        OcrAccNo: Code[20];
        Txt: Text[250];
        RecordLength: Integer;
        CRLFTerminated: Boolean;
        CR: Char;
        TempFileName: Text[1024];
    begin
        //@TODO: Update file handling.

        // ImportESRFile from source to GLL

        // *** Select GL journal. Check if empty
        GenJournalLine.SetRange("Journal Template Name", ActGenJnlLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", ActGenJnlLine."Journal Batch Name");
        GenJournalLine.SetFilter("Account No.", '<>%1', '');
        if GenJournalLine.FindFirst() then
            Error(Text015, GenJournalLine."Journal Batch Name");

        // One or multiple ESR banks
        if ESRSetup.Count = 1 then begin
            ESRSetup.FindFirst();
            if not Confirm(Text008, false) then
                exit;
        end else
            if PAGE.RunModal(PAGE::"ESR Setup List", ESRSetup) = ACTION::LookupCancel then
                Error(Text011);

        CheckSetup(ESRSetup);

        // Save sourcefile
        SaveSourceFile();

        LastLineNo := 0;
        NoRecords := 0;
        TotalAmt := 0;

        // Journal name for no serie
        GlBatchName.Get(ActGenJnlLine."Journal Template Name", ActGenJnlLine."Journal Batch Name");
        NextDocNo := NoSeries.PeekNextNo(GlBatchName."No. Series", PostDate);

        CRLFTerminated := false;
        TempFileName := Copystr(FileMgt.UploadFile(ChooseFileTitleMsg, ''), 1, 1024);
        f.Open(TempFileName);
        f.Seek(98);
        while (f.Pos < 202) and (f.Read(CR) <> 0) and (not CRLFTerminated) do
            if CR = 13 then
                CRLFTerminated := true;

        if not CRLFTerminated then begin
            f.Seek(3);           // Recordtype 3 must have ESR Account at this Position
            ReadEsrLine(f, Txt, CRLFTerminated, 9);

            // *** E S R   A C C O U N T   N O  - Expand and remove dashes
            OcrAccNo := BankMgt.CheckPostAccountNo(ESRSetup."ESR Account No.");
            OcrAccNo := DelChr(OcrAccNo, '=', '-');

            if Txt = OcrAccNo then
                RecordLength := 128 // Recordtype 3
            else begin
                f.Seek(6); // Recordtype 4 must have ESR Account at this Position
                ReadEsrLine(f, Txt, CRLFTerminated, 9);

                if Txt = OcrAccNo then
                    RecordLength := 200 // Recordtype 4
                else
                    Error(Text041, ESRSetup."Bank Code", PRODUCTNAME.Full());
            end;
        end;

        f.Close();
        if CRLFTerminated then
            f.TextMode(true)
        else
            f.TextMode(false);
        f.Open(TempFileName);
        Window.Open(Text017);

        while ReadEsrLine(f, Txt, CRLFTerminated, RecordLength) > 1 do begin
            case StrLen(Txt) of
                100 .. 128:
                    RecordType03(Txt);
                198 .. 202:
                    RecordType04(Txt);
                else
                    Error(Text039);
            end;

            if not TotalRecord then begin
                // Insert GL line
                GenJournalLine.Init();
                GenJournalLine."Journal Template Name" := ActGenJnlLine."Journal Template Name";
                GenJournalLine."Journal Batch Name" := ActGenJnlLine."Journal Batch Name";
                LastLineNo := LastLineNo + 10000;
                GenJournalLine."Line No." := LastLineNo;
                GenJournalLine."Document No." := NextDocNo;
                GenJournalLine."Posting Date" := PostDate;
                GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
                GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;

                GeneralLedgerSetup.Get();
                if GeneralLedgerSetup."LCY Code" <> Currency then
                    GenJournalLine."Currency Code" := Currency;

                // Fetch customer based on invoice no.
                CustLedgerEntry.SetCurrentKey("Document No.");
                CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
                CustLedgerEntry.SetRange("Document No.", InInvoiceNo);
                if CustLedgerEntry.FindFirst() then begin
                    GenJournalLine.Validate("Account No.", CustLedgerEntry."Customer No.");
                    if GenJournalLine."Currency Code" <> CustLedgerEntry."Currency Code" then
                        GenJournalLine.Validate("Currency Code", CustLedgerEntry."Currency Code");
                end else
                    GenJournalLine.Validate("Currency Code");

                GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Invoice;
                GenJournalLine."Applies-to Doc. No." := InInvoiceNo;

                // Process transaction of credit record
                case Transaction of
                    Transaction::Credit:
                        begin
                            GenJournalLine.Description := Text020 + ' ' + InInvoiceNo;
                            GenJournalLine.Amount := -InvoiceAmt / 100;
                        end;
                    Transaction::Cancellation:
                        begin
                            GenJournalLine."Document Type" := GenJournalLine."Document Type"::Invoice;
                            GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::" ";
                            GenJournalLine."Applies-to Doc. No." := '';
                            GenJournalLine.Description := Format(Text021 + ' ' + InInvoiceNo, -MaxStrLen(GenJournalLine.Description));
                            GenJournalLine.Amount := InvoiceAmt / 100;
                        end;
                    Transaction::Correction:
                        begin
                            GenJournalLine.Description := Text022 + ' ' + InInvoiceNo;
                            GenJournalLine.Amount := -InvoiceAmt / 100;
                        end;
                end;

                GenJournalLine."Source Code" := 'ESR';
                GenJournalLine."Reason Code" := GlBatchName."Reason Code";
                GenJournalLine."External Document No." := MicroFilmNo;
                GenJournalLine."ESR Information" := 'ESR ' + RefNo + '/' + PaymentCharges + '/' + ddVA + '.' + mmVA + '.' + yyVA + '/' + TA;
                GenJournalLine.Insert();

                // All lines same credit date? (one/multiple balance postings)
                if FirstPostingDate = 0D then  // Save first
                    FirstPostingDate := PostDate;
                if FirstPostingDate <> PostDate then  // Compare subsequent
                    MultiplePostingDates := true;

                // Add total
                NoRecords := NoRecords + 1;
                TotalAmt := TotalAmt - GenJournalLine.Amount;  // Amount is negative
                Window.Update(1, NoRecords);
                Window.Update(2, TotalAmt);
            end; // Totalrecord
        end;  // End Read File
        f.Close();
        Erase(TempFileName);

        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", ActGenJnlLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", ActGenJnlLine."Journal Batch Name");
        GenJournalLine.SetRange("Source Code", 'ESR');
        if GenJournalLine.FindSet() then
            repeat
                GenJournalLine.Validate(Amount, GenJournalLine.Amount);
                GenJournalLine.Modify();
            until GenJournalLine.Next() = 0;

        // *** Bal account per line or as combined entry
        if MultiplePostingDates then begin
            // Bal Account per line
            if GenJournalLine.Find('-') then
                repeat
                    if ESRSetup."Bal. Account Type" = ESRSetup."Bal. Account Type"::"Bank Account" then
                        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account"
                    else
                        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"G/L Account";

                    GenJournalLine.Validate("Bal. Account No.", ESRSetup."Bal. Account No.");
                    GenJournalLine.Modify();
                until GenJournalLine.Next() = 0;
        end else begin
            // Add bal. acc. line at end
            GenJournalLine.Init();
            GenJournalLine."Journal Template Name" := ActGenJnlLine."Journal Template Name";
            GenJournalLine."Journal Batch Name" := ActGenJnlLine."Journal Batch Name";
            LastLineNo := LastLineNo + 10000;
            GenJournalLine."Line No." := LastLineNo;
            GenJournalLine."Document No." := NextDocNo;
            GenJournalLine."Account Type" := "Gen. Journal Account Type".FromInteger(ESRSetup."Bal. Account Type");

            GeneralLedgerSetup.Get();
            if GeneralLedgerSetup."LCY Code" <> Currency then
                GenJournalLine."Currency Code" := Currency;

            if ESRSetup."Bal. Account Type" = ESRSetup."Bal. Account Type"::"Bank Account" then
                GenJournalLine."Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account"
            else
                GenJournalLine."Account Type" := GenJournalLine."Bal. Account Type"::"G/L Account";

            GenJournalLine."Posting Date" := PostDate;
            GenJournalLine."Source Code" := 'ESR';

            GenJournalLine.Validate("Account No.", ESRSetup."Bal. Account No.");
            GenJournalLine.Description := Text025 + ' ' + ESRSetup."Bank Code";
            GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
            GenJournalLine.Validate(Amount, TotalAmt);
            GenJournalLine.Insert();
        end;

        Window.Close();

        // Compare total record
        TotalRecAmt := TotalRecAmt + (TotalRecCents / 100);

        // CHecksum error
        if (TotalRecRecords <> NoRecords) or (TotalRecAmt <> TotalAmt) then
            Message(
              Text026,
              NoRecords,
              TotalRecRecords,
              Format(TotalAmt, 0, '<Sign><Integer Thousand><Decimals,3>'),
              Format(TotalRecAmt, 0, '<Sign><Integer Thousand><Decimals,3>'))
        else
            Message(Text036, NoRecords, TotalAmt, Currency);
    end;

    [Scope('OnPrem')]
    procedure ReadEsrLine(var f: File; var Line: Text[250]; TextFile: Boolean; RecordLength: Integer): Integer
    var
        BytesRead: Integer;
        ch: Char;
    begin
        // Reade each ESR line in ESR file
        // Textfile Mode: 130 chars read, to CR/LF. exit(0) means EOF

        Line := '';  // init

        // File with CR/LF
        if TextFile then begin
            BytesRead := f.Read(Line);
            if BytesRead = 0 then
                exit(0);
        end;

        if not TextFile then
            for BytesRead := 1 to RecordLength do begin
                if f.Read(ch) < 1 then
                    exit(BytesRead);

                Line[BytesRead] := ch;
            end;

        Line := ConvertStr(Line, ' ', '0');  // Fill Blanks with Zero
        exit(BytesRead);
    end;

    [Scope('OnPrem')]
    procedure RecordType03(Line: Text[250])
    begin
        TA := CopyStr(Line, 1, 3);
        if not (CopyStr(TA, 1, 2) in ['99']) then begin
            TotalRecord := false;
            RefNo := CopyStr(Line, 13, 27);
            Currency := 'CHF';
            Evaluate(InvoiceAmt, CopyStr(Line, 40, 10));
            yyVA := CopyStr(Line, 66, 2);
            mmVA := CopyStr(Line, 68, 2);
            ddVA := CopyStr(Line, 70, 2);
            Evaluate(yyCR, CopyStr(Line, 72, 2));
            Evaluate(mmCR, CopyStr(Line, 74, 2));
            Evaluate(ddCR, CopyStr(Line, 76, 2));
            MicroFilmNo := CopyStr(Line, 78, 9);
            PaymentCharges := CopyStr(Line, 97, 4);

            InInvoiceNo := CopyStr(RefNo, 19, 8);
            TrimInvoiceNo(InInvoiceNo);

            if yyCR > 98 then
                PostDate := DMY2Date(ddCR, mmCR, 1900 + yyCR)
            else
                PostDate := DMY2Date(ddCR, mmCR, 2000 + yyCR);
            Transaction := Transaction::" ";

            // Process transaction of credit record
            case CopyStr(TA, 3, 1) of
                '2':  // Credit
                    begin
                        Transaction := Transaction::Credit;
                        if CopyStr(TA, 1, 1) = '2' then
                            if LsvSetup.ReadPermission then
                                LsvMgt.ClosedByESR(InInvoiceNo);
                    end;
                '5':  // Cancellation "Storno"
                    begin
                        Transaction := Transaction::Cancellation;
                        if CopyStr(TA, 1, 1) = '2' then
                            if LsvSetup.ReadPermission then
                                LsvMgt.ClosedByESR(InInvoiceNo);
                    end;
                '8': // Correction
                    begin
                        Transaction := Transaction::Correction;
                        if CopyStr(TA, 1, 1) = '2' then
                            if LsvSetup.ReadPermission then
                                LsvMgt.ClosedByESR(InInvoiceNo);
                    end;
                else
                    Error(Text040);
            end;
        end else begin
            TotalRecord := true;
            Evaluate(TotalRecAmt, CopyStr(Line, 40, 10));
            Evaluate(TotalRecCents, CopyStr(Line, 50, 2));
            Evaluate(TotalRecRecords, CopyStr(Line, 52, 12));
            Evaluate(TotalRecCharges, CopyStr(Line, 70, 9));

            case CopyStr(TA, 3, 3) of
                '5':  // Debit - Negative
                    begin
                        TotalRecAmt := -TotalRecAmt;
                        TotalRecCents := -TotalRecCents;
                    end;
                '9':  // Credit - Positive
                    begin
                        TotalRecAmt := TotalRecAmt;
                        TotalRecCents := TotalRecCents;
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure RecordType04(Line: Text[250])
    begin
        TA := CopyStr(Line, 1, 3);
        if not (CopyStr(TA, 1, 2) in ['98', '99']) then begin
            TotalRecord := false;
            RefNo := CopyStr(Line, 16, 27);
            Currency := CopyStr(Line, 43, 3);
            Evaluate(InvoiceAmt, CopyStr(Line, 46, 12));
            yyVA := CopyStr(Line, 101, 4);
            mmVA := CopyStr(Line, 105, 2);
            ddVA := CopyStr(Line, 107, 2);
            Evaluate(yyCR, CopyStr(Line, 109, 4));
            Evaluate(mmCR, CopyStr(Line, 113, 2));
            Evaluate(ddCR, CopyStr(Line, 115, 2));

            PaymentCharges := CopyStr(Line, 121, 6);
            MicroFilmNo := '';

            InInvoiceNo := CopyStr(RefNo, 19, 8);
            TrimInvoiceNo(InInvoiceNo);

            PostDate := DMY2Date(ddCR, mmCR, yyCR);

            Transaction := Transaction::" ";

            // Process transaction of credit record
            case CopyStr(TA, 3, 3) of
                '1':  // Credit
                    Transaction := Transaction::Credit;
                '2':  // Cancellation "Storno"
                    Transaction := Transaction::Cancellation;
                '3': // Correction
                    Transaction := Transaction::Correction;
                else
                    Error(Text040);
            end;
        end else begin
            TotalRecord := true;
            Currency := CopyStr(Line, 43, 3);
            Evaluate(TotalRecAmt, CopyStr(Line, 46, 10));
            Evaluate(TotalRecCents, CopyStr(Line, 56, 2));
            Evaluate(TotalRecRecords, CopyStr(Line, 58, 12));
            Evaluate(TotalRecCharges, CopyStr(Line, 81, 11));

            case CopyStr(TA, 3, 1) of
                '1':  // Credit - Positive
                    begin
                        TotalRecAmt := TotalRecAmt;
                        TotalRecCents := TotalRecCents;
                    end;
                '2':  // Debit - Negative
                    begin
                        TotalRecAmt := -TotalRecAmt;
                        TotalRecCents := -TotalRecCents;
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure TrimInvoiceNo(InvoiceNo: Code[10])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        InvCount: Integer;
        TmpInvNo: Code[10];
        ReferenceNo: Code[10];
    begin
        ReferenceNo := InvoiceNo;
        TmpInvNo := InvoiceNo;
        CustLedgEntry.SetCurrentKey("Document No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange(Open, true);
        while TmpInvNo[1] = '0' do begin
            CustLedgEntry.SetRange("Document No.", TmpInvNo);
            if CustLedgEntry.FindFirst() then begin
                InvCount := InvCount + 1;
                if InvCount > 1 then
                    Error(Text042, ReferenceNo);
                InInvoiceNo := TmpInvNo;
            end;
            TmpInvNo := CopyStr(TmpInvNo, 2);
        end;
        if InvCount = 0 then
            InInvoiceNo := TmpInvNo;

        if (TmpInvNo[1] <> '0') and (InvCount = 1) then begin
            CustLedgEntry2.SetCurrentKey("Document No.");
            CustLedgEntry2.SetRange("Document Type", CustLedgEntry2."Document Type"::Invoice);
            CustLedgEntry2.SetRange(Open, true);
            CustLedgEntry2.SetRange("Document No.", TmpInvNo);
            if CustLedgEntry2.FindFirst() then
                Error(Text042, ReferenceNo);
        end;
    end;

    local procedure SaveSourceFile()
    begin
        if ESRSetup."Backup Copy" then begin
            ESRSetup.LockTable();
            ESRSetup."Last Backup No." := IncStr(ESRSetup."Last Backup No.");
            ESRSetup.Modify();
        end;
    end;
}

