// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using System.IO;
using System.Utilities;

report 15000062 "Remittance - Import (Bank)"
{
    Caption = 'Remittance - Import (Bank)';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    PaymentOrderData2.FindSet()
                else
                    PaymentOrderData2.Next();

                // Import line to a variable and process it later:
                NoOfLines := NoOfLines + 1;
                LineData[NoOfLines] := PaymentOrderData2.Data;
                if NoOfLines = 4 then begin // All 4 lines in transaction are read:
                    NoOfLines := 0; // From the begining
                    TransCode := CopyStr(LineData[1], 41, 8); // Transaction code
                    case TransCode of
                        'BETFOR00':
                            ReadBETFOR00();
                        'BETFOR01':
                            ReadBETFOR01();
                        'BETFOR02':
                            ReadBETFOR02();
                        'BETFOR03':
                            ReadBETFOR03();
                        'BETFOR04':
                            ReadBETFOR04();
                        'BETFOR21':
                            ReadBETFOR21();
                        'BETFOR22':
                            ReadBETFOR22();
                        'BETFOR23':
                            ReadBETFOR23();
                        'BETFOR99':
                            ReadBETFOR99();
                        else
                            Error(Text15000007, FileImp, TransCode);
                    end;
                end;
                PaymentOrderData := PaymentOrderData2;
                PaymentOrderData.Insert();
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, PaymentOrderData2.Count);
            end;
        }
    }

    requestpage
    {

        layout
        {
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
        GenLedgSetup.Get();
        GenLedgSetup.TestField("LCY Code");
        DateNow := Today;
        TimeNow := Time;
        NoOfLines := 0;
        Betfor99IsRead := false;
        PaymentCurrency := '';
        AccountCurrency := '';
        CreateNewDocumentNo := true;
        Betfor03IsRead := false;
        MoreReturnJournals := false;
        FileImp := StrSubstNo(Text15000006, CurrentFileName);
    end;

    trigger OnPostReport()
    begin
        TxtFile.Close();
        // BETFOR99 should be read by the end of the import:
        if not Betfor99IsRead then
            Error(Text15000008, FileImp);

        if not Confirm(StrSubstNo(
               Text15000000,
               FileMgt.GetFileName(CurrentFileName), NumberApproved, NumberRejected, NumberSettled),
             true)
        then
            Error(Text15000005);

        PaymentOrderData2.DeleteAll();
    end;

    trigger OnPreReport()
    begin
        ServerTempFile := CopyStr(FileMgt.UploadFile(ChooseFileTitleMsg, ''), 1, 1024);
        // Create work file.
        // No changes are made directly to the OriginalFilename, since it is renamed
        // at the end (the file can't be renamed while it's open).
        TxtFile.TextMode := true;
        TxtFile.Open(ServerTempFile);

        CreatePaymOrder();
        while TxtFile.Len <> TxtFile.Pos do begin
            TxtFile.Read(FileData);
            PaymentOrderData2.Init();
            PaymentOrderData2."Payment Order No." := PaymOrder.ID;
            PaymentOrderData2."Line No" += 1;
            PaymentOrderData2.Data := PadStr(FileData, 80, ' '); // Make sure the line is 80 chars long.;
            PaymentOrderData2.Insert();
        end
    end;

    var
        RemAccount: Record "Remittance Account";
        LatestRemAccount: Record "Remittance Account";
        PaymOrder: Record "Remittance Payment Order";
        RemAgreement: Record "Remittance Agreement";
        LatestRemAgreement: Record "Remittance Agreement";
        WaitingJournal: Record "Waiting Journal";
        CurrentJournal: Record "Gen. Journal Line";
        GenLedgSetup: Record "General Ledger Setup";
        PaymentOrderData: Record "Payment Order Data";
        PaymentOrderData2: Record "Payment Order Data" temporary;
        RemTools: Codeunit "Remittance Tools";
        FileMgt: Codeunit "File Management";
        TxtFile: File;
        JournalNextLineNo: Integer;
        NoOfLines: Integer;
        NumberApproved: Integer;
        NumberSettled: Integer;
        NumberRejected: Integer;
        OwnRef: Integer;
        ErrorLevel: Integer;
        CancellationCause: Integer;
        PriceInfo: Integer;
        BalanceEntryAmount: Decimal;
        BalanceEntryAmountLCY: Decimal;
        Commission: Decimal;
        TransCommission: Decimal;
        RealExchangeRate: Decimal;
        ReturnCode: Code[2];
        TransDocumentNo: Code[10];
        PaymentCurrency: Code[3];
        LatestVend: Code[20];
        LatestCurrencyCode: Code[3];
        AccountCurrency: Code[10];
        TransCode: Code[8];
        LineData: array[4] of Text[80];
        CurrentFileName: Text[250];
        CurrentNote: Text[50];
        EffRef: Text[6];
        FileImp: Text[250];
        ErrorMessage: array[5] of Text[250];
        ExecRef2: Text[12];
        FileData: Text[80];
        ServerTempFile: Text[1024];
        First: Boolean;
        Betfor99IsRead: Boolean;
        Betfor03IsRead: Boolean;
        CreateNewDocumentNo: Boolean;
        MoreReturnJournals: Boolean;
        ValueDate: Date;
        LatestDate: Date;
        DateNow: Date;
        TimeNow: Time;
        Text15000000: Label 'Return data for the file "%1" are imported correctly:\Approved: %2.\Rejected: %3.\Settled: %4.\\%4 settled payments are transferred to payment journal.', Comment = 'Parameter 1 - file name, 2, 3, 4 - integer numbers.';
        Text15000005: Label 'Import is cancelled.';
        Text15000006: Label 'Return file "%1":';
        Text15000007: Label '%1\Error: Transaction code is not valid"%2".';
        Text15000008: Label '%1\Return file is not complete. System cannot find closing transaction (PAYFOR99) in return file.\Import is cancelled.';
        Text15000010: Label '%1\Error: Transaction type PAYFOR22 (batch transfer) is not valid.';
        Text15000012: Label 'cannot be %1 when settling';
        Text15000013: Label 'cannot be %1. Receipt return must be imported before settling';
        Text15000014: Label 'Due date changed from %1 to %2.';
        Text15000015: Label 'Internal error in remittance module:\Payment currency code in journal (%1) does not match paym. curr. code in return file (%2).';
        Text15000016: Label '%1\Real exchange rate is missing from return file.';
        Text15000017: Label 'Internal error in remittance module:\Unknown return code (%1).';
        Text15000018: Label 'Currency codes should be identical:\Bank account %1: currency code is identical to ''%2''.\Remittance account %3: currency code is identical to ''%4''.', Comment = 'Parameter 1 - bank account number, 2 and 4 - currency code, 3 - account number.';
        Text15000021: Label 'Remittance: Commission';
        Text15000022: Label 'Remittance: Vendors %1';
        Text15000023: Label 'Remittance: Vendors %1';
        Text15000024: Label 'Remittance: Round off/Divergence';
        Text15000025: Label 'Round off/Divergence is too large.\Max. round off/divergence is %1 (LCY).';
        Text15000026: Label 'must be specified';
        Text15000027: Label '%1\The Remittance Status must not be %2 for waiting journal line with Reference %3.';
        Text15000028: Label 'cannot be settled when payment is rejected';
        ChooseFileTitleMsg: Label 'Choose the file to upload.';

    local procedure ReadBETFOR00()
    begin
        // Identification.
        NewTransaction();
        if not ReturnErrorCheck(5, 'BETFOR00') then
            exit;
    end;

    local procedure ReadBETFOR01()
    var
        RealExchRateText: Text[9];
        RealExchRateDecFact: Decimal;
    begin
        // Transfer transaction.
        if not ReturnErrorCheck(4, 'BETFOR01') then
            exit;
        if ReturnCode = '02' then begin
            PaymentCurrency := CopyStr(LineData[2], 37, 3);
            if PaymentCurrency = '' then // No payment currency. Read invoice currency:
                PaymentCurrency := CopyStr(LineData[2], 40, 3);
            if PaymentCurrency = GenLedgSetup."LCY Code" then
                PaymentCurrency := ''; // Payment currency is LCY

            // Real exchange rate is copied and used later if the account
            // is charged in LCY and payment is made in currency
            RealExchRateText := CopyStr(LineData[3], 31, 8);
            // Chekc if the fifth decimal is specified
            if StrPos('0123456789', CopyStr(LineData[3], 39, 1)) > 0 then begin
                RealExchRateText := RealExchRateText + CopyStr(LineData[3], 39, 1);
                RealExchRateDecFact := 100000; // RealExchangeRate has 5 decimals
            end else
                RealExchRateDecFact := 10000; // RealExchangeRate has 4 decimals
            if Evaluate(RealExchangeRate, RealExchRateText) then
                RealExchangeRate := RealExchangeRate / RealExchRateDecFact
            else
                RealExchangeRate := 0;
            // importing execution ref. 2
            Evaluate(ExecRef2, CopyStr(LineData[3], 43, 12));

            // importing cancel. cause
            SetCancellationCause(CopyStr(LineData[4], 53, 1));

            Evaluate(Commission, CopyStr(LineData[4], 32, 9));
            Commission := Commission / 100;

            ValueDate := DateFromText(CopyStr(LineData[4], 26, 6));

            EffRef := CopyStr(LineData[4], 12, 6); // Handling ref. is saved in waiting journal.
            Evaluate(PriceInfo, CopyStr(LineData[4], 30, 1));
        end;
    end;

    local procedure ReadBETFOR02()
    begin
        // Bank link transaction
        if not ReturnErrorCheck(3, 'BETFOR02') then
            exit;
    end;

    local procedure ReadBETFOR03()
    begin
        // Recipient transaction
        Betfor03IsRead := true;
        if not ReturnErrorCheck(2, 'BETFOR03') then
            exit;
    end;

    local procedure ReadBETFOR04()
    begin
        // Invoice transaction.
        Evaluate(OwnRef, CopyStr(LineData[2], 36, 35));
        SetCancellationCause(CopyStr(LineData[3], 74, 1));

        if not ReturnErrorCheck(1, 'BETFOR04') then
            exit;
        ProcessBETFOR23and04();
    end;

    local procedure ReadBETFOR21()
    var
        ValDateStr: Text[6];
    begin
        // Transfer transaction
        if not ReturnErrorCheck(2, 'BETFOR21') then
            exit;
        if ReturnCode = '02' then begin
            ValDateStr := CopyStr(LineData[4], 49, 6);
            ValueDate := DateFromText(ValDateStr);
            // import cancel. cause
            SetCancellationCause(CopyStr(LineData[4], 60, 1));
        end;
    end;

    local procedure ReadBETFOR22()
    begin
        // Batch transfer (for inst. payroll) is not implemented.
        Error(Text15000010, FileImp)
    end;

    [Scope('OnPrem')]
    procedure ReadBETFOR23()
    begin
        // Invoice transaction.
        Evaluate(OwnRef, CopyStr(LineData[3], 68, 13) + CopyStr(LineData[4], 1, 17));
        SetCancellationCause(CopyStr(LineData[4], 57, 1));
        if not ReturnErrorCheck(1, 'BETFOR23') then
            exit;
        ProcessBETFOR23and04();
    end;

    local procedure ProcessBETFOR23and04()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
    begin
        // Process invoice transaction - BETFOR04 and BETFOR23.
        // Own referance is read by the time this function is called.
        if false then;
        // Update waiting journal:
        WaitingJournal.Get(OwnRef);
        WaitingJournal."Return Code" := ReturnCode;
        WaitingJournal."Handling Ref." := EffRef;
        WaitingJournal."Execution Ref. 2" := ExecRef2;
        WaitingJournal."Price Info" := PriceInfo;

        RemAccount.Get(WaitingJournal."Remittance Account Code");
        RemAgreement.Get(RemAccount."Remittance Agreement Code");

        AccountCurrency := RemAccount."Currency Code";

        // If PostBanken is used, read the return code from invoice, since an invoice can be rejected:
        if RemAgreement."Payment System" = RemAgreement."Payment System"::Postbanken then
            ReturnCode := CopyStr(LineData[1], 4, 2);  // AH-Return Code.

        if ReturnCode = '01' then begin
            NumberApproved := NumberApproved + 1;  // Count imported

            // 1. Postbanken: Receipt return is now received, after settlement/error return
            // Do NOT set the status to Approved since settlement/error return is received.
            // This is ok for PostBanken, but not the others!
            // 2. Check whether Waiting Journal already has status sent. If not, an error occured:
            // Set status to Approved (for Postbanken too).
            // 3. Error. Status had different value then expected.
            if RemAgreement."Receipt Return Required" or
               (WaitingJournal."Remittance Status" <= WaitingJournal."Remittance Status"::Sent)
            then
                if WaitingJournal."Remittance Status" = WaitingJournal."Remittance Status"::Sent then
                    WaitingJournal.Validate("Remittance Status", WaitingJournal."Remittance Status"::Approved)
                else
                    WaitingJournal.FieldError("Remittance Status");
            WaitingJournal.Validate("Payment Order ID - Approved", PaymOrder.ID);
            WaitingJournal.Modify();
        end else
            if ReturnCode = '02' then begin
                // Chek whether balance entry is created by the time the next transaction is read:
                // ValueDate is already read in BETFOR21, and is valid for all the payments
                // until the next BETFOR21.
                // ValueDate: Settlement date for payments processed at the time.
                // WaitingJournal."Accountnr.": VendNo. for next Payment.

                if Betfor03IsRead then
                    CurrencyCheck();
                Betfor03IsRead := false;

                // Check whether a balance entry should be created now:
                CreateBalanceEntry(ValueDate, AccountCurrency, WaitingJournal."Account No.", RemAccount, RemAgreement);

                NumberSettled := NumberSettled + 1;
                FindDocumentNo(ValueDate);

                // If the status is not sent or approved, it will not be changed to settled.
                if (WaitingJournal."Remittance Status" <> WaitingJournal."Remittance Status"::Sent) and
                   (WaitingJournal."Remittance Status" <> WaitingJournal."Remittance Status"::Approved)
                then
                    WaitingJournal.FieldError(
                      "Remittance Status", StrSubstNo(Text15000012, WaitingJournal."Remittance Status"));
                // If "Receipt return required"=Yes, the status has to be Approved first, to be changed to Settled.
                if RemAgreement."Receipt Return Required" and
                   (WaitingJournal."Remittance Status" <> WaitingJournal."Remittance Status"::Approved)
                then begin
                    if WaitingJournal."Remittance Status" = WaitingJournal."Remittance Status"::Sent then
                        WaitingJournal.FieldError(
                          "Remittance Status", StrSubstNo(Text15000013,
                            WaitingJournal."Remittance Status"));

                    WaitingJournal.FieldError(
                      "Remittance Status", StrSubstNo(Text15000012, WaitingJournal."Remittance Status"));
                end;
                // Prepare and insert the journal:
                GenJournalLine.Init();
                GenJournalLine.TransferFields(WaitingJournal);
                InitJournalLine(GenJournalLine, RemAccount);
                if GenJournalLine."Posting Date" <> ValueDate then
                    RemTools.InsertWarning(
                      GenJournalLine, StrSubstNo(Text15000014,
                        GenJournalLine."Posting Date", ValueDate));
                GenJournalLine.Validate("Posting Date", ValueDate); // Read in BETFOR21.
                GenJournalLine.Validate("Document No.", TransDocumentNo);
                // Calculate currency exchange rate if Account is in LCY, and payments in other currency
                if (AccountCurrency = '') and (PaymentCurrency <> '') then begin
                    Currency.Get(PaymentCurrency);
                    Currency.TestField("Units to NOK");
                    if GenJournalLine."Currency Code" <> PaymentCurrency then
                        Error(
                          Text15000015,
                          GenJournalLine."Currency Code", PaymentCurrency);
                    if RealExchangeRate = 0 then
                        Error(Text15000016, FileImp);
                    GenJournalLine.Validate("Currency Factor", 1 / RealExchangeRate * Currency."Units to NOK");
                end;
                GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
                GenJournalLine.Validate("Bal. Account No.", '');
                GenJournalLine.Insert(true);
                WaitingJournal.RecreateLineDimensions(GenJournalLine);

                // Update balance entry amount
                BalanceEntryAmountLCY := BalanceEntryAmountLCY + GenJournalLine."Amount (LCY)";
                TransCommission := TransCommission + Commission;
                // Commission for this transaction is reseted. I.e. it's not recalculated if there are more payments.
                Commission := 0;

                WaitingJournal.Validate("Cancellation Cause", CancellationCause);

                // Update Waiting journal
                WaitingJournal.Validate("Payment Order ID - Settled", PaymOrder.ID);
                WaitingJournal.Validate("Journal, Settlement Template", GenJournalLine."Journal Template Name");
                WaitingJournal.Validate("Journal - Settlement", GenJournalLine."Journal Batch Name");
                WaitingJournal.Modify(true);

                // Update round off
            end else // This error should not occur.
                Error(Text15000017, ReturnCode);

        OnAfterProcessBETFOR23and04(GenJournalLine, WaitingJournal, ReturnCode, BalanceEntryAmountLCY);
    end;

    [Scope('OnPrem')]
    procedure ReadBETFOR99()
    begin
        // Closing transaction.
        if NumberSettled > 0 then  // Check whether payments are created
                                   // Create balance entry for the last vendor transaction.
                                   // All the parameters are dummies. This is only to make sure that the balance entry is created:
            CreateBalanceEntry(20010101D, AccountCurrency, '', RemAccount, RemAgreement);
        Betfor99IsRead := true; // Check. En error occurs if this is not TRUE when the import is finished.
    end;

    local procedure CurrencyCheck()
    var
        BankAccount: Record "Bank Account";
    begin
        // Check if the setup is correct. Rem. account currency code should be the same as bank account curr. code
        if RemAccount."Account Type" = RemAccount."Account Type"::"Bank account" then begin
            BankAccount.Get(RemAccount."Account No.");
            if BankAccount."Currency Code" <> RemAccount."Currency Code" then
                Error(
                  Text15000018,
                  BankAccount."No.", BankAccount."Currency Code",
                  RemAccount.Code, RemAccount."Currency Code");
        end;
    end;

    local procedure CreatePaymOrder()
    var
        NextPaymOrderId: Integer;
    begin
        // Create import PaymOrder.
        // Select ID. Find the next one:
        PaymOrder.LockTable();
        if PaymOrder.FindLast() then
            NextPaymOrderId := PaymOrder.ID + 1
        else
            NextPaymOrderId := 1;

        // Insert new PaymOrder. Remaining data are set later:
        PaymOrder.Init();
        PaymOrder.Validate(ID, NextPaymOrderId);
        PaymOrder.Validate(Date, DateNow);
        PaymOrder.Validate(Time, TimeNow);
        PaymOrder.Validate(Type, PaymOrder.Type::Return);
        PaymOrder.Validate(Comment, CurrentNote);
        PaymOrder.Insert(true);
    end;

    local procedure FindDocumentNo(PostDate: Date)
    var
        NoSeries: Codeunit "No. Series";
    begin
        if CreateNewDocumentNo then begin
            TransDocumentNo := '';
                TransDocumentNo := NoSeries.GetNextNo(RemAccount."Document No. Series", PostDate);
            CreateNewDocumentNo := false;
        end;
        // Trans. document no. is now the current document no.
    end;

    local procedure CreateBalanceEntry(CurrentDate: Date; CurrentCurrencyCode: Code[3]; CurrentVend: Code[20]; CurrentRemAccount: Record "Remittance Account"; CurrentRemAgreement: Record "Remittance Agreement")
    var
        GenJournalLine: Record "Gen. Journal Line";
        NewBalanceEntry: Boolean;
        DivergenceLCY: Decimal;
    begin
        // Create balance entries for each vendor transaction.
        // General rules:
        // - variables Current... used for the payment processed at the moment
        // - variables Latest... used for payments that were just created.
        // - check if Current... and Latest... are different. If so, the new balance entry must be created.
        // - The balance entry is created with data from the payments that were just created (variables Latest...).

        // First chance to create balance entry. Don't create the entry yet, instead store date and vendor for later...
        if First then begin
            First := false;
            LatestDate := CurrentDate;
            LatestVend := CurrentVend;
            LatestCurrencyCode := CurrentCurrencyCode;
            LatestRemAgreement := CurrentRemAgreement;
            LatestRemAccount := CurrentRemAccount;
        end;

        if BalanceEntryAmountLCY = 0 then // The balance entry will not be created after all:
            exit;

        // Create balance entry? If the user setup is defined with balance entry per vendor
        // then a balance entry is created each time the vendor is changed. A balance entry is created each
        // time a date is changed, regardless of setup.
        if LatestRemAgreement."New Document Per." = LatestRemAgreement."New Document Per."::"Specified for account" then begin
            if CurrentRemAccount."New Document Per." = CurrentRemAccount."New Document Per."::Vendor then
                NewBalanceEntry := (CurrentVend <> LatestVend);
        end else
            if LatestRemAgreement."New Document Per." = LatestRemAgreement."New Document Per."::Vendor then
                NewBalanceEntry := (CurrentVend <> LatestVend);
        if CurrentDate <> LatestDate then // A change in date allways means creating new balance entry:
            NewBalanceEntry := true;
        if LatestCurrencyCode <> CurrentCurrencyCode then
            NewBalanceEntry := true;
        if LatestRemAccount.Code <> CurrentRemAccount.Code then
            NewBalanceEntry := true;
        if not NewBalanceEntry then // If not 'create new balance entry' - then exit
            exit;

        // Post commission:
        if TransCommission <> 0 then begin
            LatestRemAccount.TestField("Charge Account No.");
            GenJournalLine.Init();
            InitJournalLine(GenJournalLine, LatestRemAccount);
            GenJournalLine.Validate("Posting Date", LatestDate);
            GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
            GenJournalLine.Validate("Account No.", LatestRemAccount."Charge Account No.");
            GenJournalLine.Validate("Currency Code", LatestCurrencyCode);
            GenJournalLine.Validate(Amount, TransCommission);
            BalanceEntryAmountLCY := BalanceEntryAmountLCY + GenJournalLine."Amount (LCY)";

            GenJournalLine.Validate("Document No.", TransDocumentNo);
            GenJournalLine.Validate(Description, Text15000021);
            GenJournalLine.Insert(true);
        end;

        // Create balance entry:
        GenJournalLine.Init();
        InitJournalLine(GenJournalLine, LatestRemAccount);
        GenJournalLine.Validate("Posting Date", LatestDate);
        GenJournalLine.Validate("Account Type", LatestRemAccount."Account Type");
        GenJournalLine.Validate("Account No.", LatestRemAccount."Account No.");
        GenJournalLine.Validate("Currency Code", LatestCurrencyCode);
        if GenJournalLine."Currency Code" = '' then
            BalanceEntryAmount := BalanceEntryAmountLCY
        else
            BalanceEntryAmount := Round(BalanceEntryAmountLCY * GenJournalLine."Currency Factor");
        GenJournalLine.Validate(Amount, -BalanceEntryAmount);
        GenJournalLine.Validate("Document No.", TransDocumentNo);
        case LatestRemAgreement."New Document Per." of
            LatestRemAgreement."New Document Per."::Date:
                GenJournalLine.Validate(
                  Description, StrSubstNo(Text15000022, LatestDate));
            LatestRemAgreement."New Document Per."::Vendor:
                GenJournalLine.Validate(
                  Description, StrSubstNo(Text15000023, LatestVend));
        end;
        OnBeforeGenJournalLineInsertBalanceEntry(GenJournalLine, BalanceEntryAmountLCY);
        GenJournalLine.Insert(true);

        // Post round off/divergence:
        // Divergence is calculated as a differance betweens "Amount (NOK)" in the balance entry line and the sum of
        // "Amount (LCY)" in the current transaction lines
        DivergenceLCY := -(GenJournalLine."Amount (LCY)" + BalanceEntryAmountLCY);
        if DivergenceLCY <> 0 then begin
            LatestRemAccount.TestField("Round off/Divergence Acc. No.");
            GenJournalLine.Init();
            InitJournalLine(GenJournalLine, LatestRemAccount);
            GenJournalLine.Validate("Posting Date", LatestDate);
            GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
            GenJournalLine.Validate("Account No.", LatestRemAccount."Round off/Divergence Acc. No.");
            GenJournalLine.Validate(Amount, DivergenceLCY);
            GenJournalLine.Validate("Document No.", TransDocumentNo);
            GenJournalLine.Validate(Description, Text15000024);
            if Abs(DivergenceLCY) > LatestRemAccount."Max. Round off/Diverg. (LCY)" then
                RemTools.InsertWarning(
                  GenJournalLine,
                  StrSubstNo(Text15000025,
                    LatestRemAccount."Max. Round off/Diverg. (LCY)"));
            GenJournalLine.Insert(true);
        end;

        // prepare for the next balance entry:
        CreateNewDocumentNo := true;
        BalanceEntryAmount := 0;  // From the begining, with the balance entry amount
        BalanceEntryAmountLCY := 0;
        TransCommission := 0;
        LatestDate := CurrentDate; // Store current date, vend. etc.
        LatestVend := CurrentVend;
        LatestCurrencyCode := CurrentCurrencyCode;
        LatestRemAccount := CurrentRemAccount;
        LatestRemAgreement := CurrentRemAgreement;
    end;

    local procedure NewTransaction()
    begin
        // Initialize transaction import.
        // Called before import starts, after a transaction from a file is closed (BETFOR99)
        // and before the next transaction from that file begins.
        First := true; // Balance entry control:
        BalanceEntryAmount := 0;
        BalanceEntryAmountLCY := 0;
        TransCommission := 0;
        LatestDate := 0D;
        LatestVend := '';
        LatestCurrencyCode := '';
        Clear(LatestRemAccount);
        PaymentCurrency := '';
        AccountCurrency := '';
        RealExchangeRate := 0;
    end;

    [Scope('OnPrem')]
    procedure InitJournalLine(var GenJournalLine: Record "Gen. Journal Line"; RemAccount: Record "Remittance Account")
    var
        RegisterJournal: Record "Gen. Journal Batch";
        CheckGenJnlLine: Record "Gen. Journal Line";
    begin
        // Initialize JournalLine
        if RemAccount."Return Journal Name" = '' then begin
            // Def journal name is used (the journal user reads from)
            // Make sure the user imports in a journal.
            // Read from main meny if the journal is specified for the account:
            if CurrentJournal."Journal Batch Name" = '' then
                RemAccount.FieldError("Return Journal Name", Text15000026);
            GenJournalLine.Validate("Journal Template Name", CurrentJournal."Journal Template Name");
            GenJournalLine.Validate("Journal Batch Name", CurrentJournal."Journal Batch Name");
        end else begin
            // The journal specified for the account is used:
            RemAccount.TestField("Return Journal Name");
            GenJournalLine.Validate("Journal Template Name", RemAccount."Return Journal Template Name");
            GenJournalLine.Validate("Journal Batch Name", RemAccount."Return Journal Name");
            MoreReturnJournals := true; // If TRUE, settlement status is last shown.
        end;

        // Find the next line no. for the journal in use
        CheckGenJnlLine := GenJournalLine;
        CheckGenJnlLine.SetRange("Journal Template Name", CheckGenJnlLine."Journal Template Name");
        CheckGenJnlLine.SetRange("Journal Batch Name", CheckGenJnlLine."Journal Batch Name");
        if CheckGenJnlLine.FindLast() then
            JournalNextLineNo := CheckGenJnlLine."Line No." + 10000
        else
            JournalNextLineNo := 10000;

        GenJournalLine.Validate("Line No.", JournalNextLineNo);
        RegisterJournal.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        GenJournalLine."Posting No. Series" := RegisterJournal."Posting No. Series";
    end;

    [Scope('OnPrem')]
    procedure SetJournal(GenJournalLine: Record "Gen. Journal Line")
    begin
        // Specifies journal for import (current).
        // Called from external function, which imports upon return.
        CurrentJournal := GenJournalLine;
    end;

    [Scope('OnPrem')]
    procedure Initialize(GenJournalLine: Record "Gen. Journal Line"; FileName: Text[250]; Note: Text[50])
    begin
        // Specifies variables used for import (current).
        // Called from external function, which imports upon return.
        CurrentJournal := GenJournalLine;
        CurrentFileName := FileName;
        CurrentNote := Note;
    end;

    [Scope('OnPrem')]
    procedure ReadStatus(var Approved: Integer; var Rejected: Integer; var Settled: Integer; var ReturnMoreReturnJournals: Boolean; var ReturnPaymOrder: Record "Remittance Payment Order")
    begin
        // Returns info on the current (terminated) import.
        // Counts parameters with new values.
        Approved := Approved + NumberApproved;
        Rejected := Rejected + NumberRejected;
        Settled := Settled + NumberSettled;
        ReturnMoreReturnJournals := MoreReturnJournals;
        ReturnPaymOrder := PaymOrder;
    end;

    [Scope('OnPrem')]
    procedure StatusError(CurrentWaitingJournal: Record "Waiting Journal")
    begin
        Error(
          Text15000027,
          FileImp, CurrentWaitingJournal."Remittance Status", CurrentWaitingJournal.Reference);
    end;

    [Scope('OnPrem')]
    procedure ReturnErrorCheck(BetForLevel: Integer; BetForName: Text[8]): Boolean
    var
        ReturnError: Record "Return Error";
        GenJournalLine: Record "Gen. Journal Line";
        i: Integer;
    begin
        // Check return code.
        // Return value = False: Error. I.e. transaction is reseted. There is an error at this or higher level.
        // Return value = True: transaction will be completed.

        // Previous errors (if any) are reseted:
        if BetForLevel >= ErrorLevel then
            ErrorLevel := 0;

        // Check for Error at this Level:
        ReturnCode := CopyStr(LineData[1], 4, 2);
        ErrorMessage[BetForLevel] := RemTools.ReturnError(ReturnCode);
        if (ErrorLevel = 0) and (ErrorMessage[BetForLevel] <> '') then
            ErrorLevel := BetForLevel; // Error at this level (since there is no error at a higher level)

        if (BetForLevel = 1) and (ErrorLevel > 0) then begin
            // Write error messages to database:
            NumberRejected := NumberRejected + 1;
            ReturnError.Validate("Transaction Name", BetForName);
            ReturnError.Validate(Date, Today);
            ReturnError.Validate(Time, Time);
            ReturnError.Validate("Waiting Journal Reference", OwnRef);
            ReturnError.Validate("Payment Order ID", PaymOrder.ID);
            for i := 1 to 5 do
                if ErrorMessage[i] <> '' then begin
                    ReturnError.Validate("Serial Number", 0); // Finally specified in 'OnInsert'
                    ReturnError.Validate("Message Text", ErrorMessage[i]);
                    ReturnError.Insert(true);
                end;

            WaitingJournal.Get(OwnRef);
            RemAccount.Get(WaitingJournal."Remittance Account Code");
            RemAgreement.Get(RemAccount."Remittance Agreement Code");

            if WaitingJournal."Remittance Status" = WaitingJournal."Remittance Status"::Settled then
                WaitingJournal.FieldError(
                  "Remittance Status", StrSubstNo(Text15000028));

            // Release customer entry
            GenJournalLine.Init(); // A journal line with data is used to mark entry.
            GenJournalLine.TransferFields(WaitingJournal); // Copy Waiting journal to gen. journal.
            RemTools.MarkEntry(GenJournalLine, RemAgreement."On Hold Rejection Code", 0);

            WaitingJournal.Validate("Remittance Status", WaitingJournal."Remittance Status"::Rejected);
            WaitingJournal.Validate("Payment Order ID - Rejected", PaymOrder.ID);
            WaitingJournal.Modify(true);
        end;

        exit(ErrorLevel = 0);
    end;

    [Scope('OnPrem')]
    procedure SetCancellationCause(CancelCode: Text[1])
    var
        TempCancCode: Text[1];
    begin
        Evaluate(TempCancCode, CancelCode);
        case TempCancCode of
            '':
                CancellationCause := 0;
            'B':
                CancellationCause := 1;
            'D':
                CancellationCause := 2;
            'F':
                CancellationCause := 3;
            'K':
                CancellationCause := 4;
            'O':
                CancellationCause := 5;
            'S':
                CancellationCause := 6;
        end;
    end;

    local procedure DateFromText(DateValue: Text): Date
    var
        Day: Integer;
        Month: Integer;
        Year: Integer;
        WorkDateYear: Integer;
        WorkDateYearMin: Integer;
        WorkDateCentury: Integer;
        WorkDateCenturyMin: Integer;
    begin
        Evaluate(Day, CopyStr(DateValue, 5, 2));
        Evaluate(Month, CopyStr(DateValue, 3, 2));
        Evaluate(Year, CopyStr(DateValue, 1, 2));

        // Use WorkDate() +-50 to determing correct century

        WorkDateYear := Date2DMY(WorkDate(), 3);
        WorkDateYearMin := WorkDateYear - 50;

        WorkDateCentury := Round(WorkDateYear / 100, 1, '<') * 100;
        WorkDateCenturyMin := Round(WorkDateYearMin / 100, 1, '<') * 100;

        if WorkDateCenturyMin + Year < WorkDateYearMin then
            Year := WorkDateCentury + Year
        else
            Year := WorkDateCenturyMin + Year;

        exit(DMY2Date(Day, Month, Year));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessBETFOR23and04(var GenJournalLine: Record "Gen. Journal Line"; var WaitingJournal: Record "Waiting Journal"; ReturnCode: Code[2]; var BalanceEntryAmountLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJournalLineInsertBalanceEntry(var GenJournalLine: Record "Gen. Journal Line"; var BalanceEntryAmountLCY: Decimal);
    begin
    end;
}