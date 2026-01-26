// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using System.Environment;

report 15000050 "Remittance - export (Bank)"
{
    Caption = 'Remittance - export (bank)';
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
            MaxIteration = 1;

            trigger OnPreDataItem()
            var
                StoreGenJournalLine: Record "Gen. Journal Line";
                RemPmtOrderExport: Report "Rem. Payment Order  - Export";
                RemittJournalCheckLine: Codeunit "Remitt. journal - Check line";
                InvoiceCounter: Integer;
                MaxPayments: Integer;
                Done: Boolean;
                NextSelection: Boolean;
                LastLine: Boolean;
                NumberOfInvoices: Integer;
                VendBalance: Decimal;
                FirstTransaction: Boolean;
                UnstructuredPaym: Boolean;
                CountUnstPaym: Integer;
                UndefinedValue: Integer;
            begin
                OnBeforeOnPreDataItemGenJournalLine(CurrentGenJournalLine, "Gen. Journal Line");

                RemAgreement.LockTable(); // To ensure the update of sequence numbers

                PurchSetup.Get();

                DateNow := Today; // Present time and date.
                TimeNow := Time;
                ProductionDate := Format(Date2DMY(DateNow, 2), 2) + Format(Date2DMY(DateNow, 1), 2);
                ProductionDate := ConvertStr(ProductionDate, ' ', '0');  // Change, for ex., date '12 1' to '1201'.
                TransactionDate := ProductionDate;
                NextLineNo(true);
                VendBalance := 0; // Make sure vendors' balance is non-negative
                NextSelection := true;  // See the explanation...
                MaxPayments := 999; // Max. number of payments in a transaction
                RemAgreement.Get(RemAgreementCode); // Make sure the specified code is valid

                // Select lines from current journals
                GenJournalLineRec.Reset(); // Make sure primary keys are active and all filters deleted.
                GenJournalLineRec.SetCurrentKey(
                  "Journal Template Name", "Journal Batch Name", "Remittance Agreement Code", "Remittance Type", "Remittance Account Code");
                GenJournalLineRec.SetRange("Journal Template Name", CurrentGenJournalLine."Journal Template Name");
                GenJournalLineRec.SetRange("Journal Batch Name", CurrentGenJournalLine."Journal Batch Name");
                GenJournalLineRec.SetRange("Remittance Agreement Code", RemAgreementCode); // Only one contract at the time is processed.

                if not GenJournalLineRec.FindFirst() then
                    Error(Text001);

                GenJournalLineRec.FindFirst();

                CreatePaymOrderHead();

                // Run through the lines:
                // 1. Start with the first one. Set the filter so that all related lines are selected.
                // 2. Each journal line is deleted after being processed.
                // 3. If there are more then 14 lines, run through more then once.
                // 4. When lines within the filter er processed, the filter is deleted and first of the
                //    remaining journal lines is selected and used now. (starts over at 1.)
                // 5. Stop when all the lines are processed.

                GenJournalLineRec.FindFirst();  // Start with the first one, with new key
                StoreGenJournalLine.Init();
                UndefinedValue := -1;
                StoreGenJournalLine."Remittance Type" := UndefinedValue;
                FirstTransaction := true;
                repeat
                    if NextSelection then begin  // Continue with next selection:
                                                 // Select journal lines for current payment transaction
                        GenJournalLineRec.SetRange("Remittance Type", GenJournalLineRec."Remittance Type");
                        GenJournalLineRec.SetRange("Remittance Account Code", GenJournalLineRec."Remittance Account Code");
                        GenJournalLineRec.SetRange("Posting Date", GenJournalLineRec."Posting Date");
                        GenJournalLineRec.SetRange("Account No.", GenJournalLineRec."Account No.");
                        GenJournalLineRec.SetRange(Urgent, GenJournalLineRec.Urgent);
                        GenJournalLineRec.SetRange("Futures Contract No.", GenJournalLineRec."Futures Contract No.");
                        GenJournalLineRec.SetRange("Futures Contract Exch. Rate", GenJournalLineRec."Futures Contract Exch. Rate");
                        GenJournalLineRec.SetRange("Currency Code", GenJournalLineRec."Currency Code");
                        GenJournalLineRec.SetRange("Currency Factor", GenJournalLineRec."Currency Factor");
                        GenJournalLineRec.SetRange("Agreed Exch. Rate", GenJournalLineRec."Agreed Exch. Rate");
                        GenJournalLineRec.SetRange("Agreed With", GenJournalLineRec."Agreed With");
                        UnstructuredPaym := true;

                        // Unstructured and structured payments must be grouped separately.
                        // Structured payments: those with either KID or External Doc. No. filled out
                        // Unstructured payments: those with recipient ref. 1-3 filled out
                        if not GenJournalLineRec."Structured Payment" then begin
                            if GenJournalLineRec."Remittance Type" = GenJournalLineRec."Remittance Type"::Domestic then begin
                                if GenJournalLineRec."Recipient Ref. 1" = '' then
                                    Error(Text006, GenJournalLineRec."Line No.");
                            end else
                                if GenJournalLineRec."Recipient Ref. Abroad" = '' then
                                    Error(Text009, GenJournalLineRec."Line No.");
                        end else
                            UnstructuredPaym := false;
                        GenJournalLineRec.SetRange("Structured Payment", GenJournalLineRec."Structured Payment");

                        GenJournalLineRec.FindFirst();  // Start with first one among selected ones.

                        // Init data related to the current account/agreement.
                        // All journal lines selected by now are related to the same account
                        StoreRemAccount := RemAccount; // StoreRemAccount is used in ApplHeader.
                        RemAccount.Get(GenJournalLineRec."Remittance Account Code");
                        if FirstTransaction then
                            StoreRemAccount := RemAccount;
                        // Check. This should not happen:
                        if RemAccount."Remittance Agreement Code" <> RemAgreement.Code then
                            Error(Text002);
                        if RemAccount.Type = RemAccount.Type::Foreign then
                            if (GenJournalLineRec."Payment Type Code Abroad" = '') and not SkipPaymentTypeCodeAbroad then
                                SkipPaymentTypeCodeAbroad := ConfirmSkipping(FieldCaption("Payment Type Code Abroad"));
                        RemAccount.TestField("Bank Account No.");
                        if RemAccount.Type = 2 then
                            OwnAccountNo := '00000000000'
                        else
                            OwnAccountNo := RemTools.FormatNumStr(RemAccount."Bank Account No.", 11);
                        NumberOfInvoices := GenJournalLineRec.Count();  // Number of invoices in transaction
                        InvoiceCounter := 0; // Counts number of payments in a payment transaction
                        CountUnstPaym := 0; // Counts number of unstructured payments in a payment transaction - max allowed 8

                        // Check if remittance type is changed. If so, create a new PAYFOR99
                        // for previous payment orders (if any) and a new
                        // PAYFOR00 for following payment orders.
                        if StoreGenJournalLine."Remittance Type" <> GenJournalLineRec."Remittance Type" then begin
                            if not FirstTransaction then begin // Close the last one
                                CountTrans := CountTrans + 1;  // Count payment transactions
                                Betfor99(false);
                            end;

                            // PAYFOR00 for first/next transaction
                            StoreRemAccount := RemAccount;
                            CountTrans := 1;  // Count payment transactions
                            Betfor00();
                            FirstTransaction := false;
                        end;
                    end;

                    GenJournalLineRec.TestField("Account Type", GenJournalLineRec."Account Type"::Vendor);
                    GenJournalLineRec.TestField("Waiting Journal Reference", 0); // Journal line is a settlement. It can not be exported!
                    Vendor.Get(GenJournalLineRec."Account No.");

                    if RemAccount.Type = RemAccount.Type::Domestic then begin
                        CountTrans := CountTrans + 1;
                        Betfor21(GenJournalLineRec)
                    end else begin
                        CountTrans := CountTrans + 3;
                        // Get journal info for the first journal line in vendor transaction
                        // Same values are used for transfer.
                        // This can cause problems, since the following journal lines could have different values.
                        Betfor01(GenJournalLineRec);
                        Betfor02(GenJournalLineRec);
                        Betfor03(GenJournalLineRec);
                    end;

                    repeat
                        if RemAccount.Type = RemAccount.Type::Foreign then
                            if (GenJournalLineRec."Specification (Norges Bank)" = '') and (PurchSetup."Amt. Spec limit to Norges Bank" > 0) then begin
                                if GenJournalLineRec."Amount (LCY)" >= PurchSetup."Amt. Spec limit to Norges Bank" then
                                    Error(
                                      Text008, FieldCaption("Specification (Norges Bank)"), FieldCaption("Amount (LCY)"),
                                      Format(GenJournalLineRec."Line No."), PurchSetup."Amt. Spec limit to Norges Bank");
                                if not SkipSpecification then
                                    SkipSpecification := ConfirmSkipping(FieldCaption("Specification (Norges Bank)"));
                            end;

                        InvoiceCounter := InvoiceCounter + 1;  // Count number of invoices for current vendor.

                        //Count unstructured payments. Max allowed lines for unstructered paym. is 25
                        // Each message consist of 3 lines (recipient ref 1,2,3), so max allowed unstruct. payments in one trans.
                        // is 8.
                        if UnstructuredPaym then
                            CountUnstPaym := CountUnstPaym + 1;

                        RemittJournalCheckLine.CheckUntilFirstError(GenJournalLineRec, RemAccount);
                        VendBalance := VendBalance + GenJournalLineRec."Amount (LCY)";  // Count vendors balance for later checks
                                                                                        // Moved to waiting journal by PAYFor23(), since own ref. is used
                        MoveToWaitingJournal(GenJournalLineRec);  // Move journal line to waiting journal.

                        CountTrans := CountTrans + 1;
                        if RemAccount.Type = RemAccount.Type::Domestic then
                            Betfor23(GenJournalLineRec)
                        else
                            Betfor04(GenJournalLineRec);

                        RemTools.MarkEntry(GenJournalLineRec, 'REM', RemittancePaymentOrder.ID);  // Mark the posts waiting for remitt. settlement.

                        // Delete journal lines that where just processed:
                        StoreGenJournalLine := GenJournalLineRec;
                        GenJournalLineRec.Delete(true);

                        // Find first of the remaining lines in filter. -
                        // - Stop when all vendor lines are exported, or when 999 lines are exported, for structured payments.
                        // In case of unstrucutred payments, max no. of payments within transaction is 8.
                        LastLine := not GenJournalLineRec.FindFirst();
                    until (InvoiceCounter mod MaxPayments = 0) or LastLine or (UnstructuredPaym and ((CountUnstPaym mod 8) = 0));

                    // Are all the selected invoices processed?
                    // If so, the next invoice is selected.
                    // If they are not all processed, then the vendor has more then 14 invoices. Repeat-lopp again -
                    // - until all vendors invoices are exported
                    if InvoiceCounter = NumberOfInvoices then begin
                        // New transaction. Checking amount:
                        // Check balance for processed vendors:
                        if VendBalance < 0 then begin
                            // recognize vendor with and without currency, so the message is formulated correctly
                            if GenJournalLineRec."Currency Code" = '' then
                                Error(Text003,
                                  GenJournalLineRec."Posting Date", GenJournalLineRec."Account No.", VendBalance);
                            Error(Text004, GenJournalLineRec."Posting Date", GenJournalLineRec."Account No.",
                              VendBalance, GenJournalLineRec."Currency Code", GenJournalLineRec."Currency Factor");
                        end;
                        VendBalance := 0;  // Reset for next vendor.
                    end;
                    if InvoiceCounter = NumberOfInvoices then begin
                        // All selected invoices are processed. Continue with the following selection.
                        // Delete limits for vendor.
                        // Continue with the line following the ones just processed:
                        GenJournalLineRec.SetRange("Remittance Type");
                        GenJournalLineRec.SetRange("Remittance Account Code");
                        GenJournalLineRec.SetRange("Posting Date");
                        GenJournalLineRec.SetRange("Account No.");
                        GenJournalLineRec.SetRange(Urgent);
                        GenJournalLineRec.SetRange("Futures Contract No.");
                        GenJournalLineRec.SetRange("Futures Contract Exch. Rate");
                        GenJournalLineRec.SetRange("Currency Code");
                        GenJournalLineRec.SetRange("Currency Factor");
                        GenJournalLineRec.SetRange("Agreed Exch. Rate");
                        GenJournalLineRec.SetRange("Agreed With");
                        GenJournalLineRec.SetRange(KID);
                        GenJournalLineRec.SetRange("External Document No.");
                        GenJournalLineRec.SetRange("Recipient Ref. 1");
                        GenJournalLineRec.SetRange("Structured Payment");
                        Done := not GenJournalLineRec.FindFirst();  // More journal lines?
                        NextSelection := true;  // All selected lines are processed. Select next transaction.
                    end else begin  // Not all invoices are processed.
                        Done := false;  // Don't stop. Continue with the next one from the selection.
                        NextSelection := false;  // Not all selected lines are processed. The next transaction is NOT selected.
                    end;
                until Done;  // If stop=True, all invoices are processed.

                CountTrans := CountTrans + 1;
                Betfor99(true);

                if RemAgreement."Return File Is Not In Use" then
                    RemTools.SettlePaymOrdWithoutReturnFile(RemittancePaymentOrder, GenJournalLineRec);

                // Export  data:
                RemPmtOrderExport.SetPmtOrder(RemittancePaymentOrder);
                RemPmtOrderExport.SetFilename(CurrentFilename);
                PaymentOrderData.Reset();
                PaymentOrderData.SetRange("Payment Order No.", RemittancePaymentOrder.ID);
                RemPmtOrderExport.SetTableView(PaymentOrderData);
                RemPmtOrderExport.RunModal();
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
                    field(RemAgreementCode; RemAgreementCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Remittance agreement code';
                        TableRelation = "Remittance Agreement";
                        ToolTip = 'Specifies the remittance agreement code to use for the payment.';

                        trigger OnValidate()
                        begin
                            RemAgreement.Get(RemAgreementCode);
                            CurrentOperator := RemAgreement."Operator No.";
                            CurrentPassword := RemAgreement.Password;
                            CurrentDivision := RemAgreement.Division;
                            CurrentFilename := RemAgreement.GetPaymentFileName();
                        end;
                    }
                    field(CurrentOperator; CurrentOperator)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Operator';
                        ToolTip = 'Specifies the number of the operator who makes the payment.';
                    }
                    field(CurrentPassword; CurrentPassword)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Password';
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the password that is associated with the payment.';
                    }
                    field(CurrentDivision; CurrentDivision)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Division';
                        ToolTip = 'Specifies the bank division that is making the payment.';
                    }
                    field(CurrentNote; CurrentNote)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Current note';
                        ToolTip = 'Specifies a note for the payment.';
                    }
                    field(CurrentFilename; CurrentFilename)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Filename';
                        ToolTip = 'Specifies the name and directory of the payment.';

                        trigger OnAssistEdit()
                        begin
                            CurrentFilename := '';
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            // Choose the contract specified in the first journal line
            RemAgreement.Get(CurrentGenJournalLine."Remittance Agreement Code");
            RemAgreementCode := RemAgreement.Code;
            CurrentOperator := RemAgreement."Operator No.";
            CurrentPassword := RemAgreement.Password;
            CurrentDivision := RemAgreement.Division;
            CurrentFilename := RemAgreement.GetPaymentFileName();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        FindSetup.Get();
        FindSetup.TestField("LCY Code");
    end;

    var
        GenJournalLineRec: Record "Gen. Journal Line";
        RemAccount: Record "Remittance Account";
        StoreRemAccount: Record "Remittance Account";
        RemAgreement: Record "Remittance Agreement";
        RemittancePaymentOrder: Record "Remittance Payment Order";
        PaymentOrderData: Record "Payment Order Data";
        CurrentGenJournalLine: Record "Gen. Journal Line";
        WaitingJournal: Record "Waiting Journal";
        Vendor: Record Vendor;
        FindSetup: Record "General Ledger Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        RemTools: Codeunit "Remittance Tools";
        ApplicationSystemConstants: Codeunit "Application System Constants";
        DateNow: Date;
        TimeNow: Time;
        ProductionDate: Text[4];
        TransactionDate: Text[4];
        StoreNextno: Integer;
        OwnAccountNo: Code[11];
        CountTrans: Integer;
        CurrentOperator: Text[11];
        CurrentDivision: Text[11];
        CurrentPassword: Text[10];
        CurrentNote: Text[50];
        CurrentFilename: Text[250];
        RemAgreementCode: Code[10];
        Text001: Label 'There are no payments to export.\Export is cancelled.';
        Text002: Label 'Account and remittance agreement are different.';
        Text003: Label 'Payment amount cannot be negative.\Balance for vendor %2 %3 is %1.', Comment = 'Parameter 1 - decimal amount, 2 - account number, 3 - date.';
        Text004: Label 'Payment amount cannot be negative.\Balance for vendor %2 %3 is %1, currency %4 exchange rate %5.', Comment = 'Parameter 1 - decimal amount, 2 - account number, 3 - date, 4 - currency code, 5 - decimal amount.';
        Text006: Label 'You must fill in one of the following fields in journal line %1: KID, External Document No., or Recipient Ref.';
        Text007: Label 'It is not required to fill in %1 on line %2 because the amount is below NOK %3.\\But it is recommended that you fill this field in.\\Do you want to continue?';
        Text008: Label '%1 is missing. This field is required because %2 on line %3 is higher than %4.';
        Text009: Label 'You must fill in one of the following fields in journal line %1: KID, External Document No. or Recipient Ref. Abroad.';
        Text010: Label 'Select invoice currency: %1 invoice entries are selected.';
        Text011: Label 'should follow ISO-standard (3 char)';
        Text012: Label 'Recipient address, city, and post code should be filled in. Do you want to continue?';
        Text013: Label 'Export is cancelled.';
        Text014: Label 'Line %1 is not 80 chars long.\%2';
        SkipSpecification: Boolean;
        SkipPaymentTypeCodeAbroad: Boolean;

    [Scope('OnPrem')]
    procedure CreatePaymOrderHead()
    var
        NextID: Integer;
    begin
        // Create a PaymOrder for import.
        // Select ID. Find next:
        RemittancePaymentOrder.LockTable();
        if RemittancePaymentOrder.FindLast() then
            NextID := RemittancePaymentOrder.ID + 1
        else
            NextID := 1;

        // Insert new PaymOrder. Remaining data are processed later:
        RemittancePaymentOrder.Init();
        RemittancePaymentOrder.ID := NextID;
        RemittancePaymentOrder.Date := DateNow;
        RemittancePaymentOrder.Time := TimeNow;
        RemittancePaymentOrder.Type := RemittancePaymentOrder.Type::Export;
        RemittancePaymentOrder.Comment := CurrentNote;
        RemittancePaymentOrder.Insert();
    end;

    [Scope('OnPrem')]
    procedure ApplHeader(): Text[40]
    var
        Header: Text[40];
        RoutineID: Text[4];
    begin
        // Header of 40 chars. Inserted several places in data. [p8]
        // For use in other blocks.

        // select routine ID - inland or abroad:
        case StoreRemAccount.Type of
            StoreRemAccount.Type::Domestic:
                RoutineID := 'TBII';
            StoreRemAccount.Type::Foreign:
                RoutineID := 'TBIU';
            StoreRemAccount.Type::"Payment Instr.":
                RoutineID := 'TBIO';
        end;

        Header :=
          'AH' + // ID
          '2' + // Version
          '00' + // Return code
          RoutineID + // RoutineID. 4 char
          TransactionDate + // Trans.Date.
          RemTools.NextSeqNo(RemAgreement, 0) + // Trans.Sequence. Daily number.
          Fill(8) + // Trans. Code - Reserved.
          Fill(11) + // UserID - Reserved.
          '04';                      // Number, 80 chars. Fixed.

        exit(Header);
    end;

    [Scope('OnPrem')]
    procedure Betfor00()
    var
        Operator: Text[11];
        Division: Text[11];
    begin
        // Identification transaction [p30]

        // Format operator:
        if RemAgreement."Payment System" = RemAgreement."Payment System"::"DnB Telebank" then
            // Operator is Numeric:
            Operator := RemTools.FormatNumStr(CurrentOperator, 11)
        else
            // Operator is Alfa:
            Operator := PadStr(CurrentOperator, 11, ' ');

        // Format division:
        if RemAgreement."Payment System" = RemAgreement."Payment System"::"Fokus Bank" then
            // Division is Numeric:
            Division := RemTools.FormatNumStr(CurrentDivision, 11)
        else
            // Division is Alfa:
            Division := PadStr(CurrentDivision, 11, ' ');

        // Line 1:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          ApplHeader() + // Application header. 40 char.
          'BETFOR00' + // Transaction code (BETFOR00=identification transaction)
          RemTools.FormatNumStr(RemAgreement."Company/Agreement No.", 11) + // Company no.
          Division + // Division, 11 chars
          RemTools.NextSeqNo(RemAgreement, 1) + // Global sequence no.
          Fill(6);                   // Reserved 6 chars.
        InsertLine(PaymentOrderData);

        // Line 2:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          ProductionDate + // ProductionDate.
          PadStr(RemAgreement.Password, 10, ' ') + // Password.
          'VERSJON002' + // Routine version.
          Fill(10) + // New password. Doesn't use 10 chars.
          Operator + // Operator no.
          ' ' + // Sigill Seal-use.  Not in use.
          RemTools.FormatNum(0, 6, false) + // Sigill Seal-date.  Not in use.
          RemTools.FormatNum(0, 20, false) + // Sigill Part-key.  Not in use.
          ' ' + // Seal how.  Not in use.
          Fill(7);                          // Reserved - 7 of total of 143 chars.
        InsertLine(PaymentOrderData);

        // Line 3. This line is reserved chars only:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data := Fill(80);               // Reserved - 80  of total of 143 chars.
        InsertLine(PaymentOrderData);

        // Line 4:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          Fill(56) + // Reserved - the last 56 and total of 143 chars.
          Fill(15) + // Own ref. batch, 15 chars
          Fill(9);                          // Reserved 9 chars.
        InsertLine(PaymentOrderData);
    end;

    [Scope('OnPrem')]
    procedure Betfor01(JournalRec: Record "Gen. Journal Line")
    var
        InvoiceEntry: Record "Vendor Ledger Entry";
        DueDate: Text[6];
        Y: Text[2];
        M: Text[2];
        D: Text[2];
        PaymentCurrency: Text[3];
        InvoiceCurrency: Text[3];
        ChargesInland: Text[3];
        ChargesAbroad: Text[3];
        Warning: Text[30];
        UrgencyNotice: Text[1];
        AgreedExchRate: Text[8];
        AgreedWith: Text[6];
        Check: Text[1];
        PriceInfo: Text[1];
        ValueDateRecBank: Text[6];
    begin
        // Transfer-transaction abroad. [p22]

        Vendor.Get(GenJournalLineRec."Account No.");
        // Payment date: Format YYMMDD (with leading 0 if possible):
        Y := CopyStr(Format(Date2DMY(GenJournalLineRec."Posting Date", 3), 4), 3, 2);  // Years only (not centuries)
        M := Format(Date2DMY(GenJournalLineRec."Posting Date", 2), 2);
        D := Format(Date2DMY(GenJournalLineRec."Posting Date", 1), 2);
        DueDate := Y + M + D;
        // Endre f.eks. dato '9612 1' til '961201'.
        DueDate := ConvertStr(DueDate, ' ', '0');

        // Payment and invoice currency type:
        // Get invoice currency from the invoice entry:

        // Value date receiving bank: Format YYMMDD (with leading 0 if possible):
        Y := CopyStr(Format(Date2DMY(GenJournalLineRec."Posting Date", 3), 4), 3, 2);  // Years only (not centuries)
        M := Format(Date2DMY(GenJournalLineRec."Posting Date", 2), 2);
        D := Format(Date2DMY(GenJournalLineRec."Posting Date", 1), 2);
        ValueDateRecBank := Y + M + D;
        // Endre f.eks. dato '9612 1' til '961201'.
        ValueDateRecBank := ConvertStr(ValueDateRecBank, ' ', '0');

        // Payment and invoice currency type:
        // Get invoice currency from the invoice entry:

        InvoiceEntry.SetCurrentKey("Document No.");
        InvoiceEntry.SetRange("Document Type", GenJournalLineRec."Applies-to Doc. Type");
        InvoiceEntry.SetRange("Document No.", GenJournalLineRec."Applies-to Doc. No.");
        InvoiceEntry.SetRange("Vendor No.", GenJournalLineRec."Account No.");
        InvoiceEntry.FindFirst();
        if InvoiceEntry.Count <> 1 then // In case the same document no. was used several times.
            Error(Text010, InvoiceEntry.Count);
        if InvoiceEntry."Currency Code" = '' then
            InvoiceCurrency := PadStr(FindSetup."LCY Code", 3)
        else begin
            if StrLen(InvoiceEntry."Currency Code") <> 3 then
                InvoiceEntry.FieldError("Currency Code", Text011);
            InvoiceCurrency := InvoiceEntry."Currency Code";
        end;
        // Payment currency. Specified only if <> Invoice currency type.
        // Attention: Fokus Bank requires that this field is filled in. Payment currency must be specified.
        if GenJournalLineRec."Currency Code" = '' then
            PaymentCurrency := PadStr(FindSetup."LCY Code", 3)
        else begin
            if StrLen(GenJournalLineRec."Currency Code") <> 3 then
                GenJournalLineRec.FieldError("Currency Code", Text011);
            PaymentCurrency := GenJournalLineRec."Currency Code";
        end;

        // Charges
        case Vendor."Charges Domestic" of
            Vendor."Charges Domestic"::"Debit remitter":
                ChargesInland := 'OUR';
            Vendor."Charges Domestic"::"Debit recipient":
                ChargesInland := 'BEN';
            Vendor."Charges Domestic"::Default:
                ChargesInland := '   ';
        end;
        case Vendor."Charges Abroad" of
            Vendor."Charges Abroad"::"Debit remitter":
                ChargesAbroad := 'OUR';
            Vendor."Charges Abroad"::"Debit recipient":
                ChargesAbroad := 'BEN';
            Vendor."Charges Abroad"::Default:
                ChargesAbroad := '   ';
        end;

        // Warning:
        case Vendor."Warning Notice" of
            Vendor."Warning Notice"::None:
                Warning := '';
            Vendor."Warning Notice"::Phone:
                Warning := 'PHONE';
            Vendor."Warning Notice"::Fax:
                Warning := 'TELEX';
            Vendor."Warning Notice"::Other:
                Warning := 'OTHER' + Vendor."Warning Text";
        end;
        Warning := PadStr(Warning, 30, ' ');

        // UrgencyNotice:
        if GenJournalLineRec.Urgent then
            UrgencyNotice := 'Y'
        else
            UrgencyNotice := ' ';

        // Agreed exchg. rate:
        AgreedExchRate := RemTools.FormatNum(GenJournalLineRec."Agreed Exch. Rate", 8, true);
        AgreedWith := PadStr(GenJournalLineRec."Agreed With", 6);

        // Check:
        case GenJournalLineRec.Check of
            GenJournalLineRec.Check::No:
                Check := ' ';
            GenJournalLineRec.Check::"Send to employer":
                Check := '0';
            GenJournalLineRec.Check::"Send to beneficiary":
                Check := '1';
        end;

        PriceInfo := Fill(1);

        // Line 1:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          ApplHeader() + // Application header. 40 chars.
          'BETFOR01' + // Transaction code, 8 chars
          RemTools.FormatNumStr(RemAgreement."Company/Agreement No.", 11) + // Company no.
          OwnAccountNo + // Account no. (own).
          RemTools.NextSeqNo(RemAgreement, 1) + // Global Sequence no. 4 digits.
          Fill(6);                           // Reference no. Blank for new paym orders.
        InsertLine(PaymentOrderData);

        // Line 2:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          DueDate + // DueDate YYMMDD.
          PadStr(GenJournalLineRec."Account No.", 30) + // Own ref. PaymOrder. Users own ID. Not in use!
                                                        // Ownref. PAYFOR04 is used.
          PaymentCurrency + // Payment currency type. Specified only if <> InvoiceCurrencytype.
          InvoiceCurrency + // Invoice currency type. Specified if paym.Currency is not specified.
          ChargesAbroad + // 3 chars
          ChargesInland + // 3 chars
          Warning + // 30 chars
          UrgencyNotice + // ='Y' if urgent. 1 char
          CopyStr(AgreedExchRate, 1, 1);       // First char in this line. The last 7 in next line. 1 char.
        InsertLine(PaymentOrderData);

        // Line 3:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          CopyStr(AgreedExchRate, 2, 7) + // Last 7 chars. 7 chars
          PadStr(GenJournalLineRec."Futures Contract No.", 6) + // 6 chars
          RemTools.FormatNum(GenJournalLineRec."Futures Contract Exch. Rate", 8, true) + // 8 chars
          Check + // Draw a check?. 1 char
          Fill(6) + // Value date receiving bank, 6 chars
          Fill(2) + // Reserved 2 chars.
          '000000000000' + // R2, Real exchange rate. 12 chars
          Fill(12) + // R2, Execution ref. 2, 12 chars
          '0000000000000000' + // R2, Debited amount. 16 chars
          '0000000000';                      // R2, Transfered amount. First 10 chars
        InsertLine(PaymentOrderData);

        // Line 4:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          '000000' + // R2, Transfered amount. Last 6 chars
          Fill(5) + // ClientRef 5 chars
          '000000' + // R2,M Execution ref. 6 chars
          AgreedWith + // 6 chars
          ' ' + // Deleting. Not supported. 1 char
          ' ' + // SBP-kode. DnB field. 1 char
          '000000' + // R2, value date. 6 chars
          '000000000' + // R2, Commision. 9 chars
          '000000000000' + // R2, Exchange rate in LCY. 12 chars
          Fill(1) + // R2, cancellation cause - 1 char - blank
          '0000000000000000' + // 16 chars
          PriceInfo + // R2, 1 char
          Fill(10);                          // Reserved 10 chars

        InsertLine(PaymentOrderData);
    end;

    [Scope('OnPrem')]
    procedure Betfor02(JournalRec: Record "Gen. Journal Line")
    var
        BankAdr1: Text[35];
        SWIFTRemb: Text[11];
        BankCode: Text[15];
        AccNoTBIO: Text[35];
        BankName: Text[35];
    begin
        // Bank-link transaction abroad. [p23]

        Vendor.Get(GenJournalLineRec."Account No.");
        RemAccount.Get(GenJournalLineRec."Remittance Account Code");

        // bank no. for TBIO - used with tbio only
        if RemAccount.Type = 2 then
            AccNoTBIO := PadStr(RemAccount."Bank Account No.", 35)
        else
            AccNoTBIO := Fill(35);

        // Swift address should always be filled out, and must be filled out for payments within EU
        Vendor.TestField(SWIFT);

        // SWIFT remb. Will be devided:
        SWIFTRemb := PadStr(Vendor."SWIFT Remb. Bank", 11);

        // Rec. country/region code must be filled out
        // Bank Code is used only if IBAN not used, and recipient country/region is one of the following countries:
        // 'AU','CA','IE','GB','CH','ZA','DE','US','AT'
        Vendor.TestField("Rcpt. Bank Country/Region Code");
        BankCode := Fill(15);
        if Vendor."Rcpt. Bank Country/Region Code" in ['AU', 'CA', 'IE', 'GB', 'CH', 'ZA', 'DE', 'US', 'AT'] then
            BankCode := PadStr(Vendor."Recipient Bank Account No.", 15);

        // If Bankcode is filled out - then bankname and address MUST be blank.
        BankAdr1 := Fill(35);
        BankName := Fill(35);
        if BankCode = '' then begin
            // Bank address 1. Split:
            BankAdr1 := PadStr(Vendor."Bank Address 1", 35);
            // Bank name
            BankName := PadStr(Vendor."Bank Name", 35);
        end;

        // Note! If swift adr. is filled out then bankname and adr. should be blank, unless
        // the payment is to be forwarded from the swift bank to an underlying non-swift bank.
        // If this is not the case and both swift adr. and bankname/address is filled out -
        // the customer will be charged with the fee.

        // Line 1:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          ApplHeader() + // Application header. 40 chars.
          'BETFOR02' + // Transaction code
          RemTools.FormatNumStr(RemAgreement."Company/Agreement No.", 11) + // Company no.
          OwnAccountNo + // Account no. (own).
          RemTools.NextSeqNo(RemAgreement, 1) + // Global sequence no. 4 digits.
          Fill(6);                           // Reference no. Blank for new PaymOrders.
        InsertLine(PaymentOrderData);

        // Line 2:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          PadStr(Vendor.SWIFT, 11) + // Swift address for recipients bank. 11 chars
          PadStr(BankName, 35) + // Recipients bank. 35 chars
          CopyStr(BankAdr1, 1, 34);           // First 34 chars. 34 chars
        InsertLine(PaymentOrderData);

        // Line 3:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          CopyStr(BankAdr1, 35, 1) + // Last char. 1 char
          PadStr(Vendor."Bank Address 2", 35) + // Recipients bank. 35 chars
          PadStr(Vendor."Bank Address 3", 35) + // Recipients bank. 35 chars
          CopyStr(SWIFTRemb, 1, 9);            // First 9 chars. 9 chars
        InsertLine(PaymentOrderData);

        // Line 4:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          CopyStr(SWIFTRemb, 10, 2) + // Last 2 chars. 2 chars
          PadStr(Vendor."Rcpt. Bank Country/Region Code", 2) + // Country/Region code 2 chars
          BankCode + // 15 chars
          PadStr(AccNoTBIO, 35) + // Account No. (only used with TBIO)
          Fill(26);                          // Reserved 26 chars
        InsertLine(PaymentOrderData);
    end;

    [Scope('OnPrem')]
    procedure Betfor03(JournalRec: Record "Gen. Journal Line")
    var
        Recipient: array[4] of Text[35];
        TelexFax: Text[1];
        RecAdr: Boolean;
    begin
        // Recipients transaction abroad. [p24]

        Vendor.Get(GenJournalLineRec."Account No.");

        // These fields are to be regarded as a unit. If the first position in one
        // of the fields is not filled in (is blank) the rest of the field will be ignored.
        // Line 1 must be filled in before line 2 etc. There must not be any blank lines between the fields.
        Recipient[1] := Vendor.Name;
        Recipient[2] := Vendor.Address;
        Recipient[3] := Vendor."Address 2";
        Recipient[4] := Vendor."Post Code" + ' ' + Vendor.City;
        CompressArray(Recipient);

        // Rec. Adress should be filled out to make sure the recepient receives payment notice, however, it is not required,
        // only recommended
        RecAdr := true;
        if (Recipient[2] = '') or (Recipient[3] = '') or (Vendor."Post Code" = '') or (Vendor.City = '') then
            RecAdr := Confirm(Text012, true);
        if not RecAdr then
            Error(Text013);

        // 35 chars in all fields:
        Recipient[1] := PadStr(Recipient[1], 35);
        Recipient[2] := PadStr(Recipient[2], 35);
        Recipient[3] := PadStr(Recipient[3], 35);
        Recipient[4] := PadStr(Recipient[4], 35);

        // Telex, fax:
        case Vendor."Recipient Confirmation" of
            Vendor."Recipient Confirmation"::None:
                TelexFax := ' ';
            Vendor."Recipient Confirmation"::Telex:
                TelexFax := 'T';
            Vendor."Recipient Confirmation"::Fax:
                TelexFax := 'F';
        end;

        // Rec. country/region code must be filled out
        Vendor.TestField("Country/Region Code");

        // Line 1:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          ApplHeader() + // Application header. 40 chars.
          'BETFOR03' + // transaction code
          RemTools.FormatNumStr(RemAgreement."Company/Agreement No.", 11) + // Company no.
          OwnAccountNo + // Account no. (own). 11 chars
          RemTools.NextSeqNo(RemAgreement, 1) + // Global sequence no. 4 digits.
          Fill(6);                           // Reference no. Blank for new PaymOrders.
        InsertLine(PaymentOrderData);

        // Line 2:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          PadStr(Vendor."Recipient Bank Account No.", 35) + // 35 chars.
          Recipient[1] + // Recipients name. 35 chars
          CopyStr(Recipient[2], 1, 10);         // Recipients address 1. 35 chars
        InsertLine(PaymentOrderData);

        // Line 3:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          CopyStr(Recipient[2], 11, 25) + // Recipients address 1. Last 25 chars
          Recipient[3] + // Recipients address 2. 35 chars
          CopyStr(Recipient[4], 1, 20);         // Recipients address 3. First 20 chars
        InsertLine(PaymentOrderData);

        // Line 4:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          CopyStr(Recipient[4], 21, 15) + // Recipients address 3. Last 15 chars
          PadStr(Vendor."Country/Region Code", 2) + // Recipients country/region code. 2 chars
          TelexFax + // 1 char
          PadStr(Vendor."Telex Country/Region Code", 2) + // Recipients telex country/region code. 2 chars
          PadStr(Vendor."Telex/Fax No.", 18) + // Telex/fax no. 18 chars
          PadStr(Vendor."Recipient Contact", 20) + // Attention: 20 chars
          Fill(22);                           // Reserved 22 chars
        // This shoudln't create problems, regardless of data filled in here.
        InsertLine(PaymentOrderData);
    end;

    [Scope('OnPrem')]
    procedure Betfor04(JournalRec: Record "Gen. Journal Line")
    var
        OwnRef: Text[35];
        InvoiceAmount: Text[15];
        DebitCreditCode: Text[1];
        ToOwnAccount: Text[1];
        KIDForeign: Text[1];
        RecRefAbroad: Code[35];
    begin
        // Invoice transaction abroad. [p25]

        Vendor.Get(GenJournalLineRec."Account No.");

        // Format own ref.:
        // Own ref. comes from Waiting journal it refers to.
        OwnRef := StrSubstNo('%1', WaitingJournal.Reference);
        OwnRef := PadStr(OwnRef, 35);

        // Format invoice amount:
        InvoiceAmount := RemTools.FormatNum(GenJournalLineRec.Amount, 15, true);

        // Create debit/credit code:
        if GenJournalLineRec.Amount < 0 then
            DebitCreditCode := 'K'
        else
            DebitCreditCode := 'D';

        // either KID i "recipient ref. (abroad)" + 'K' in "KID (Foreign)" (if KID specified)
        // or invoice no. i "recipient ref. (abroad)" and blank in "KID (Foreign)" otherwise
        if GenJournalLineRec.KID <> '' then begin
            RecRefAbroad := GenJournalLineRec.KID;
            KIDForeign := 'K';
        end else begin
            if GenJournalLineRec."External Document No." <> '' then
                RecRefAbroad := GenJournalLineRec."External Document No."
            else
                RecRefAbroad := GenJournalLineRec."Recipient Ref. Abroad";
            KIDForeign := ' ';
        end;
        // To own account:
        if Vendor."To Own Account" then
            ToOwnAccount := 'Y'
        else
            ToOwnAccount := ' ';

        // Line 1:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          ApplHeader() + // Application header. 40 chars.
           'BETFOR04' + // transaction code
          RemTools.FormatNumStr(RemAgreement."Company/Agreement No.", 11) + // Company no.
          OwnAccountNo + // Account no (own).
          RemTools.NextSeqNo(RemAgreement, 1) + // Global sequence no. 4 digits.
          Fill(6);                           // Reference no. Blank for new PaymOrders.
        InsertLine(PaymentOrderData);

        // Line 2:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          PadStr(RecRefAbroad, 35) + // Recipient ref.
          OwnRef + // Own reference. Important!: Identification for return. 35 chars
          CopyStr(InvoiceAmount, 1, 10);        // First 10 chars
        InsertLine(PaymentOrderData);

        // Line 3:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          CopyStr(InvoiceAmount, 11, 5) + // Last 5 chars
          DebitCreditCode + // 1 char
          PadStr(GenJournalLineRec."Payment Type Code Abroad", 6) + // 6 chars
          PadStr(GenJournalLineRec."Specification (Norges Bank)", 60) + // Amount concerned. 60 chars
          ToOwnAccount + // To own account. 1 char
          Fill(1) + // R2, Cancelation cause - 1 char - blank
          '000000';                          // reserved 6 chars
        InsertLine(PaymentOrderData);

        // Line 4:
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          ' ' + // Reserved 1 char
          '000000' + // Reserved 6 chars
          Fill(45) + // Reserved 45 chars
          KIDForeign + // 1 char
          '000' + // R1, R2. 3 chars.
          Fill(24);                          // Reserved 24 chars
        InsertLine(PaymentOrderData);
    end;

    [Scope('OnPrem')]
    procedure Betfor21(JournalRec: Record "Gen. Journal Line")
    var
        DueDate: Text[6];
        TextCode: Code[3];
        RecipientAccount: Text[30];
        Y: Text[2];
        M: Text[2];
        D: Text[2];
    begin
        // Transfer transaction. [p31]
        // Header for new creditor. New PAyfor21+payfor23 for shift in:
        // 1. Creditor
        // 2. Date
        // 3. Max. 14 Invoices.
        // 4. Currency

        // Get creditor:
        Vendor.Get(GenJournalLineRec."Account No.");
        // Convert BOLS text code-optionfield to correct code:
        case JournalRec."BOLS Text Code" of
            JournalRec."BOLS Text Code"::"Transfer without advice":
                TextCode := '600';
            JournalRec."BOLS Text Code"::"KID transfer":
                TextCode := '601';
            JournalRec."BOLS Text Code"::"Transfer with advice":
                TextCode := '602';
            JournalRec."BOLS Text Code"::"Money order":
                TextCode := '603';
            JournalRec."BOLS Text Code"::Salary:
                TextCode := '604';
            JournalRec."BOLS Text Code"::"Seaman's pay":
                TextCode := '605';
            JournalRec."BOLS Text Code"::"Agricultural settlement":
                TextCode := '606';
            JournalRec."BOLS Text Code"::"Pension/ Social security":
                TextCode := '607';
            JournalRec."BOLS Text Code"::"Advice sent from institution other than BBS":
                TextCode := '608';
            JournalRec."BOLS Text Code"::Tax:
                TextCode := '609';
            JournalRec."BOLS Text Code"::"Free text mass payment":
                TextCode := '621';
            JournalRec."BOLS Text Code"::"Free text":
                TextCode := '622';
            JournalRec."BOLS Text Code"::"Self-produced money order":
                TextCode := '630';
        end;

        if JournalRec.KID <> '' then
            TextCode := '601'
        else
            if JournalRec."External Document No." <> '' then
                TextCode := '600'
            else
                TextCode := '602';

        // Format YYMMDD (with leading 0, if possible):
        Y := CopyStr(Format(Date2DMY(GenJournalLineRec."Posting Date", 3), 4), 3, 2);  // Years only (not centuries)
        M := Format(Date2DMY(GenJournalLineRec."Posting Date", 2), 2);
        D := Format(Date2DMY(GenJournalLineRec."Posting Date", 1), 2);
        DueDate := Y + M + D;
        // Change, for ex., date '9612 1' to '961201'.
        DueDate := ConvertStr(DueDate, ' ', '0');

        // Format recipients account [p37] (REMEMBER it's an Alfa-field):
        if Vendor."Recipient Bank Account No." = '' then  // Account no. is not specified. Use account 19:
            RecipientAccount := '00000000019'
        else begin // Account is specified. Format account no. deletes all non-numerical char:
            RecipientAccount := '00000000000' + RemTools.FormatAccountNo(Vendor."Recipient Bank Account No.");
            RecipientAccount := CopyStr(RecipientAccount, StrLen(RecipientAccount) - 10);  // 11 last chars.
        end;

        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          ApplHeader() + // Application header. 40 chars.
          'BETFOR21' + // Transaction code (PAYFOR21=Transfer-transaction)
          RemTools.FormatNumStr(RemAgreement."Company/Agreement No.", 11) + // Company no.
          OwnAccountNo + // Account no (own).
          RemTools.NextSeqNo(RemAgreement, 1) + // Global sequence no. 4 digits.
          Fill(6);                           // Referance no. Blank for new PaymOrders.
        InsertLine(PaymentOrderData);

        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          DueDate + // Payment date YYMMDD.
          PadStr(GenJournalLineRec."Account No.", 30) +
          // Own ref. PaymOrder. Users own id. Not in use!
          // - Own ref i PAYFOR23 is used in return.
          ' ' + // Reserved. 1 char.
          RecipientAccount + // Recipients account.
          PadStr(Vendor.Name, 30) + // Recipients name.
          CopyStr(PadStr(Vendor.Address, 30), 1, 2);  // Adress 1. First 2 chars
        InsertLine(PaymentOrderData);

        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          CopyStr(PadStr(Vendor.Address, 30), 3) + // Adress 1. Last 28 chars
          PadStr(Vendor."Address 2", 30) + // Adress 2.
          PadStr(Vendor."Post Code", 4) + // Postal code.
          CopyStr(PadStr(Vendor.City, 26), 1, 18); // City
        InsertLine(PaymentOrderData);

        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          CopyStr(PadStr(Vendor.City, 26), 19) + // city. Remaining 8 chars.
          '000000000000000' + // Amount to own account. 15 chars. NOT SUPPORTED!
          TextCode + // TextCode. BOLS [p40], 3 chars
          'F' + // Trans. type. Only Invoice is supported.
          ' ' + // Deleting. Set ='D' if transaction was previously deleting.
          '000000000000000' + // Total amount. Only settled return R2.
          '00000' + // Reserved. 5 numerical chars.
          Fill(6) + // Value date. Return only (R2).
          Fill(6) + // Value date receiving bank, 6 chars
          Fill(1) + // R2, cancellation cause, 1 char - blanke
          Fill(9) + // Reserved.
          Fill(10);                          // 10 chars
        InsertLine(PaymentOrderData);
    end;

    [Scope('OnPrem')]
    procedure Betfor23(JournalRec: Record "Gen. Journal Line")
    var
        DebitCreditCode: Text[1];
        OwnRef: Text[30];
        InvoiceNo: Text[20];
        CustomerNo: Text[15];
        InvoiceDate: Text[8];
        RecRef1: Text[40];
        RecRef2: Text[40];
        RecRef3: Text[40];
        KID: Text[27];
        Y: Text[4];
        M: Text[2];
        D: Text[2];
    begin
        // Invoice transaction. [p33]

        // Create debit/credit code:
        if GenJournalLineRec."Amount (LCY)" < 0 then
            DebitCreditCode := 'K'
        else
            DebitCreditCode := 'D';

        // Format own ref:
        // Own ref comes from Waiting journal it refers to.
        OwnRef := StrSubstNo('%1', WaitingJournal.Reference);
        OwnRef := PadStr(OwnRef, 30);  // Length is 30 char.

        KID := Fill(27);
        RecRef1 := Fill(40);
        RecRef2 := Fill(40);
        RecRef3 := Fill(40);
        CustomerNo := Fill(15);
        InvoiceNo := Fill(20);
        InvoiceDate := Fill(8);

        // ONLY ONE of the following: KID, External Doc. No., or Recipient ref. 1-3 can be filled out for one payment.
        if GenJournalLineRec.KID = '' then
            if GenJournalLineRec."External Document No." = '' then begin
                GenJournalLineRec.TestField("Recipient Ref. 1");
                RecRef1 := PadStr(GenJournalLineRec."Recipient Ref. 1", 40);
                RecRef2 := PadStr(GenJournalLineRec."Recipient Ref. 2", 40);
                RecRef3 := PadStr(GenJournalLineRec."Recipient Ref. 3", 40);
            end else begin
                InvoiceNo := PadStr(GenJournalLineRec."External Document No.", 20);
                Vendor.Get(GenJournalLineRec."Account No.");
                CustomerNo := PadStr(Vendor."Our Account No.", 15);
                GenJournalLineRec.TestField("Document Date");
                // InvoiceDate: Format YYYYMMDD
                Y := CopyStr(Format(Date2DMY(GenJournalLineRec."Document Date", 3), 4), 1, 4);  // Years incl. centuries
                M := Format(Date2DMY(GenJournalLineRec."Document Date", 2), 2);
                D := Format(Date2DMY(GenJournalLineRec."Document Date", 1), 2);
                InvoiceDate := Y + M + D;
                // Endre f.eks. dato '199612 1' til '19961201'.
                InvoiceDate := ConvertStr(InvoiceDate, ' ', '0');
            end
        else
            KID := PadStr(GenJournalLineRec.KID, 27);
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          ApplHeader() + // Application header. 40 chars.
          'BETFOR23' + // Transaction code (PAYFOR23=Invoice transaction)
          RemTools.FormatNumStr(RemAgreement."Company/Agreement No.", 11) + // Company no.
          OwnAccountNo + // Account no. (own)
          RemTools.NextSeqNo(RemAgreement, 1) + // Global sequence no. 4 digits.
          Fill(6);                           // Reference no. Blank for PaymOrders.
        InsertLine(PaymentOrderData);

        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          RecRef1 + // Recipient ref. invoice. Can not be used with InvoicNo or KID
          RecRef2;                           // Recipient ref. invoice.
        InsertLine(PaymentOrderData);

        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          RecRef3 + // Recipient ref. invoice.
          KID + // KID. Can not be used with InvoiceNo or recipient ref.
          CopyStr(OwnRef, 1, 13);             // Own ref. First 13 chars
        InsertLine(PaymentOrderData);
        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          CopyStr(OwnRef, 14) + // Own ref. Last 17 chars
          RemTools.FormatNum(GenJournalLineRec."Amount (LCY)", 15, true) + // Invoice amount. 15 chars.
          DebitCreditCode + // Debit/credit code.
          InvoiceNo +
          // 20 chars. can not be used with KID or recipient ref., otherwise mandatory together with
          // customer no. and invoice date. = External doc. no - gen. jnl line
          '000' + // Serial no. Specified in return data R1, R2.
          Fill(1) + // R2, cancellation cause - 1 char - blank
          CustomerNo + // 15 chars  = our account no. , vendor tbl
          InvoiceDate;                       // YYYYMMDD = document date = gen. jnl line
        InsertLine(PaymentOrderData);
    end;

    [Scope('OnPrem')]
    procedure Betfor99(LastPayfor99: Boolean)
    var
        AppVersion: Text[11];
    begin
        // Closing transaction. [p34]

        // Application version
        AppVersion := PadStr('Nav ' + ApplicationSystemConstants.ApplicationVersion(), 11);

        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          ApplHeader() + // Application header. 40 chars.
          'BETFOR99' + // Transaction code (PAYFOR99=closing transaction)
          RemTools.FormatNumStr(RemAgreement."Company/Agreement No.", 11) + // Company no.
          Fill(11) + // Reserved 11 char.
          RemTools.NextSeqNo(RemAgreement, 1) + // Global sequence no. 4 digits.
          Fill(6);                           // Reserved 6 chars.
        InsertLine(PaymentOrderData);

        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          ProductionDate + // Production date. 4 chars
          Fill(19) + // Reserved 19 chars.
          RemTools.FormatNum(CountTrans, 5, false) + // Number of transactions - blocks of 320 chars.
          Fill(52);                          // Reserved. First 52 of 163 chars.
        InsertLine(PaymentOrderData);

        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          Fill(80);                           // Reserved. 80 of remaining 111 chars.
        InsertLine(PaymentOrderData);

        InitLine(PaymentOrderData);
        PaymentOrderData.Data :=
          Fill(31) + // Last 31 of 163 characters
          '    ' + // Sigill security. Not in use.
          ' ' + // Sigill language. Not in use.
          ' ' + // Sigill version. Not in use.
          ' ' + // Sigill interface. Not in use.
          '                  ' + // Sigill control field. Not in use.
          AppVersion + // software version, 16 version
          Fill(5) +
          Fill(8);                           // bank version - blank
        InsertLine(PaymentOrderData);

        if LastPayfor99 then  // If DnB Telebank is used, an extra empty line is required.
            if RemAgreement."Payment System" = RemAgreement."Payment System"::"DnB Telebank" then begin
                InitLine(PaymentOrderData);
                PaymentOrderData."Empty Line" := true;
                PaymentOrderData.Data := '';
                InsertLine(PaymentOrderData);
            end;
    end;

    [Scope('OnPrem')]
    procedure MoveToWaitingJournal(JournalLine: Record "Gen. Journal Line")
    var
        WaitingJournal2: Record "Waiting Journal";
    begin
        WaitingJournal.Init();
        WaitingJournal.PerformTransferFieldsFromGenJournalLine(JournalLine);
        WaitingJournal."Payment Order ID - Sent" := RemittancePaymentOrder.ID;
        WaitingJournal."Remittance Status" := WaitingJournal."Remittance Status"::Sent;
        // Own reference, sent to bank:
        WaitingJournal2.LockTable();
        WaitingJournal2.Init();
        if WaitingJournal2.FindLast() then
            WaitingJournal.Reference := WaitingJournal2.Reference + 1
        else
            WaitingJournal.Reference := 1;
        WaitingJournal.Validate("Remittance Account Code", RemAccount.Code);
        WaitingJournal.Insert(true);
        WaitingJournal.CopyLineDimensions(JournalLine);
    end;

    [Scope('OnPrem')]
    procedure Fill(SpaceCount: Integer): Text[250]
    begin
        // Returns a string with number of 'spaceCount' SPACES.
        exit(PadStr('', SpaceCount, ' '));
    end;

    [Scope('OnPrem')]
    procedure NextLineNo(Init: Boolean): Integer
    begin
        // Calculate and return the next line no.
        // PARAMETERS:
        // init=True. Line nos. start with 1, from the next 'False' call.
        // init=False. Returns next line no.
        // RETURNS: Next line no.=0 if init=True.

        if Init then
            StoreNextno := 0 // This number is not used.
        else
            StoreNextno := StoreNextno + 1;
        exit(StoreNextno);
    end;

    [Scope('OnPrem')]
    procedure Control(LineNo: Integer; Data: Text[100])
    begin
        // An extra check. This error must not occur in customers systems.
        // Note that the last line might have length = 0

        if (StrLen(Data) <> 80) and (StrLen(Data) <> 0) then
            Message(Text014, LineNo, Data);
    end;

    [Scope('OnPrem')]
    procedure InitLine(var PaymentOrderData: Record "Payment Order Data")
    begin
        // Prepare data-line for use.
        PaymentOrderData.Init();
        PaymentOrderData."Payment Order No." := RemittancePaymentOrder.ID;
        PaymentOrderData."Line No" := NextLineNo(false);
        PaymentOrderData."Empty Line" := false;
    end;

    [Scope('OnPrem')]
    procedure InsertLine(PaymentOrderData: Record "Payment Order Data")
    begin
        // Insert data-Line in a file.
        Control(PaymentOrderData."Line No", PaymentOrderData.Data);  // My own control, just in case!
        PaymentOrderData.Data := UpperCase(PaymentOrderData.Data);
        PaymentOrderData.Insert();
    end;

    [Scope('OnPrem')]
    procedure SetJournalLine(JournalLine: Record "Gen. Journal Line")
    begin
        // Transfer current lines from journal routine (f.ex. journal window):
        CurrentGenJournalLine := JournalLine;
    end;

    local procedure ConfirmSkipping(FieldCaption: Text): Boolean
    begin
        if not Confirm(StrSubstNo(Text007, FieldCaption,
               Format(GenJournalLineRec."Line No."), PurchSetup."Amt. Spec limit to Norges Bank"))
        then
            Error('');
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreDataItemGenJournalLine(var CurrentGenJournalLine: Record "Gen. Journal Line"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

