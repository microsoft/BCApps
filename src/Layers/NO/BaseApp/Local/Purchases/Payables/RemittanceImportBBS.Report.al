// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.NoSeries;
using System.IO;
using System.Utilities;

report 15000063 "Remittance - Import (BBS)"
{
    Caption = 'Remittance - Import (BBS)';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);

            trigger OnAfterGetRecord()
            var
                Recordtype: Code[2];
            begin
                if Number = 1 then
                    PaymentOrderData2.FindSet()
                else
                    PaymentOrderData2.Next();

                // import line to a variable, handle it later:
                LineData := PaymentOrderData2.Data;

                Recordtype := CopyStr(LineData, 7, 2);
                case Recordtype of
                    '10':
                        Recordtype10();
                    '20':
                        Recordtype20();
                    '30':
                        Recordtype30();
                    '31':
                        Recordtype31();
                    '88':
                        Recordtype88();
                    '89':
                        Recordtype89();
                    else
                        Error(Text15000005, FileImp, Recordtype);
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
        DateNow := Today;
        TimeNow := Time;
        Recordtype89IsRead := false;
        CreateNewDocumentNo := true;
        MoreReturnJournals := false;
        FileImp := StrSubstNo(Text15000004, CurrentFilename);
    end;

    trigger OnPostReport()
    begin
        TxtFile.Close();

        // Recordtype89 must be read by the end of import:
        if not Recordtype89IsRead then
            Error(Text15000006, FileImp);

        if not Confirm(StrSubstNo(
               Text15000000,
               FileMgt.GetFileName(CurrentFilename), NumberSettled), true)
        then
            Error(Text15000003);

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
        PaymentOrderData: Record "Payment Order Data";
        PaymentOrderData2: Record "Payment Order Data" temporary;
        RemTools: Codeunit "Remittance Tools";
        FileMgt: Codeunit "File Management";
        TxtFile: File;
        JournalNextLineNo: Integer;
        NumberSettled: Integer;
        PaymOrderNo: Integer;
        TransNo: Integer;
        TransOwnref: Integer;
        ShipmentNo: Integer;
        BalanceEntryAmountLCY: Decimal;
        TransAmount: Decimal;
        LatestVend: Code[20];
        DataRecipient: Code[8];
        TransDocumentNo: Code[10];
        CurrentFilename: Text[250];
        LineData: Text[80];
        CurrentNote: Text[50];
        FileData: Text[80];
        FileImp: Text[250];
        ServerTempFile: Text[1024];
        First: Boolean;
        Recordtype89IsRead: Boolean;
        CreateNewDocumentNo: Boolean;
        MoreReturnJournals: Boolean;
        LatestDate: Date;
        TransBBSDate: Date;
        Text15000000: Label 'Return data was imported correctly from the file "%1":\Settled: %2.\\%2 settled payments are transferred to the payment journal.', Comment = 'Parameter 1 - file name, 2 - integer number.';
        Text15000003: Label 'Import is cancelled.';
        Text15000004: Label 'Return file "%1":';
        Text15000005: Label '%1\Error: Record type is not valid "%2".';
        Text15000006: Label '%1\Return file is not complete. Cannot find closing record for shipment (Recordtype 89) in the return file.\Import is cancelled.';
        Text15000008: Label 'The file does not correspond to this BBS contract.\The BBS Customer Unit ID %1 is registered in the agreement, while %2 is registered in the file.\Import is cancelled.';
        Text15000010: Label 'can not be %1 in settlement';
        Text15000011: Label 'Due date is changed from %1 to %2.';
        Text15000012: Label 'Remittance: Vendor %1';
        Text15000013: Label 'Remittance: Vendor %1';
        Text15000014: Label 'must be specified';
        Text15000015: Label '%1\The Remittance Status cannot be %2 for waiting journal line with Reference %3.';
        DateNow: Date;
        TimeNow: Time;
        ChooseFileTitleMsg: Label 'Choose the file to upload.';

    local procedure Recordtype10()
    begin
        // Start record shipment
        Evaluate(ShipmentNo, CopyStr(LineData, 17, 7));
        DataRecipient := CopyStr(LineData, 24, 8);
    end;

    local procedure Recordtype20()
    begin
        // Start record payment order
        Evaluate(PaymOrderNo, CopyStr(LineData, 18, 7));
    end;

    local procedure Recordtype30()
    begin
        // Transaction record, amount entry 1
        NewTransaction();
        Evaluate(TransNo, CopyStr(LineData, 9, 7));
        Evaluate(TransBBSDate, CopyStr(LineData, 16, 6));
        Evaluate(TransAmount, CopyStr(LineData, 33, 17));
    end;

    local procedure Recordtype31()
    begin
        // Transaction record, amount entry 2
        Evaluate(TransOwnref, CopyStr(LineData, 26, 25));
        ProcessTransaction();
    end;

    local procedure Recordtype88()
    begin
        // End record PaymOrder
    end;

    local procedure Recordtype89()
    begin
        // End record shipment
        Recordtype89IsRead := true;
    end;

    local procedure ProcessTransaction()
    var
        GenJnlLine: Record "Gen. Journal Line";
        TransAmountCheck: Decimal;
    begin
        // Process transaction - i.e. Recordtype 31 is now read and the OwnRef is known.

        // Update Waiting journal:
        WaitingJournal.SetCurrentKey("BBS Referance");
        WaitingJournal.SetRange("BBS Referance", TransOwnref);
        WaitingJournal.Find('-');

        RemAccount.Get(WaitingJournal."Remittance Account Code");
        RemAgreement.Get(RemAccount."Remittance Agreement Code");
        // make sure the return file belongs to the user:
        if RemAgreement."BBS Customer Unit ID" <> DataRecipient then
            Error(
              Text15000008,
              RemAgreement."BBS Customer Unit ID", DataRecipient);

        TransAmountCheck := 0;
        repeat
            NumberSettled := NumberSettled + 1;
            FindDocumentNo(TransBBSDate);

            // If the status is not sent or approved, it will not be changed to settled.
            // Note: Waiting journal can never have status approved for BBS.
            if (WaitingJournal."Remittance Status" <> WaitingJournal."Remittance Status"::Sent) and
               (WaitingJournal."Remittance Status" <> WaitingJournal."Remittance Status"::Approved)
            then
                WaitingJournal.FieldError(
                  "Remittance Status", StrSubstNo(Text15000010, WaitingJournal."Remittance Status"));

            // Prepare and insert into journal:
            GenJnlLine.Init();
            GenJnlLine.TransferFields(WaitingJournal);
            InitJournalLine(GenJnlLine, RemAccount);
            if GenJnlLine."Posting Date" <> TransBBSDate then
                RemTools.InsertWarning(
                  GenJnlLine, StrSubstNo(Text15000011,
                    GenJnlLine."Posting Date", TransBBSDate));
            GenJnlLine.Validate("Posting Date", TransBBSDate);
            GenJnlLine.Validate("Document No.", TransDocumentNo);
            GenJnlLine.Insert(true);
            WaitingJournal.RecreateLineDimensions(GenJnlLine);

            // Update amount to balance entry etc.
            BalanceEntryAmountLCY := BalanceEntryAmountLCY + GenJnlLine."Amount (LCY)";
            TransAmountCheck := TransAmountCheck + GenJnlLine."Amount (LCY)";

            // Update waiting journal
            WaitingJournal.Validate("Payment Order ID - Settled", PaymOrder.ID);
            WaitingJournal.Validate("BBS Shipment No.", ShipmentNo);
            WaitingJournal.Validate("BBS Payment Order No.", PaymOrderNo);
            WaitingJournal.Validate("BBS Transaction No.", TransNo);
            WaitingJournal.Validate("Journal, Settlement Template", GenJnlLine."Journal Template Name");
            WaitingJournal.Validate("Journal - Settlement", GenJnlLine."Journal Batch Name");
            WaitingJournal.Modify(true);
        until WaitingJournal.Next() = 0;

        CreateBalanceEntry(
          TransBBSDate, WaitingJournal."Account No.", RemAccount, RemAgreement,
          GenJnlLine."Document Type" = GenJnlLine."Document Type"::Payment);
    end;

    local procedure CreatePaymOrder()
    var
        NextPaymOrderID: Integer;
    begin
        // Create import of PaymOrder.
        // Find ID. Find Next:
        PaymOrder.LockTable();
        if PaymOrder.FindLast() then
            NextPaymOrderID := PaymOrder.ID + 1
        else
            NextPaymOrderID := 1;

        // Insert new PaymOrder. Set the remaining data later:
        PaymOrder.Init();
        PaymOrder.Validate(ID, NextPaymOrderID);
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
        // TransDocumentNo is now current Document no.
    end;

    local procedure CreateBalanceEntry(CurrentDate: Date; CurrentVend: Code[20]; CurrentRemAccount: Record "Remittance Account"; CurrentRemAgreement: Record "Remittance Agreement"; IsPayment: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // Create balance entries for each vendor transaction.
        // In general:
        // - Variabels Current... store values for current processes.
        // - Variabels Latest... store values for newly created payments.
        // - Check if Current... and Latest... are different. If so, create a new balance entry.
        // - Balance entries are created with info from the newly created payments (variabels Latest...).

        // First chance to create balance entry. Don't create. Instead, store date and vendor for later:
        if First then begin
            First := false; // not the first any more.
            LatestDate := CurrentDate;
            LatestVend := CurrentVend;
            LatestRemAgreement := CurrentRemAgreement;
            LatestRemAccount := CurrentRemAccount;
        end;

        if BalanceEntryAmountLCY = 0 then // Balance entry won't be created anyway:
            exit;

        // Create balance entry:
        GenJnlLine.Init();
        InitJournalLine(GenJnlLine, LatestRemAccount);
        GenJnlLine.Validate("Posting Date", LatestDate);
        GenJnlLine.Validate("Account Type", LatestRemAccount."Account Type");
        GenJnlLine.Validate("Account No.", LatestRemAccount."Account No.");
        GenJnlLine.Validate(Amount, -BalanceEntryAmountLCY);
        if IsPayment then
            GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Payment);
        GenJnlLine.Validate("Document No.", TransDocumentNo);
        case LatestRemAgreement."New Document Per." of
            LatestRemAgreement."New Document Per."::Date:
                GenJnlLine.Validate(
                  Description, StrSubstNo(Text15000012, LatestDate));
            LatestRemAgreement."New Document Per."::Vendor:
                GenJnlLine.Validate(
                  Description, StrSubstNo(Text15000013, LatestVend));
        end;
        GenJnlLine.Insert(true);

        // Prepare for the next balance entry:
        CreateNewDocumentNo := true;
        BalanceEntryAmountLCY := 0;
        LatestDate := CurrentDate; // Store Current Date, vendor etc..
        LatestVend := CurrentVend;
        LatestRemAccount := CurrentRemAccount;
        LatestRemAgreement := CurrentRemAgreement;
    end;

    local procedure NewTransaction()
    begin
        // Initialize transaction import.
        // Called before import is started, after a transaction in the file is closed (BETFOR99)
        // and before the next transaction from the same file starts.
        First := true; // Control of balance entry;
        BalanceEntryAmountLCY := 0;
        LatestDate := 0D;
        LatestVend := '';
        Clear(LatestRemAccount);
    end;

    [Scope('OnPrem')]
    procedure InitJournalLine(var GenJnlLine: Record "Gen. Journal Line"; RemAccount: Record "Remittance Account")
    var
        RegisterJournal: Record "Gen. Journal Batch";
        CHeckGenJnlLine: Record "Gen. Journal Line";
    begin
        // Initialize journal line
        if RemAccount."Return Journal Name" = '' then begin
            // Def. Journal name is used (journal user imports from)
            // Make sure the user imports into journal. Read from the main meny if
            // the journal is specified for the account:
            if CurrentJournal."Journal Batch Name" = '' then
                RemAccount.FieldError("Return Journal Name", Text15000014);
            GenJnlLine.Validate("Journal Template Name", CurrentJournal."Journal Template Name");
            GenJnlLine.Validate("Journal Batch Name", CurrentJournal."Journal Batch Name");
        end else begin
            // Journal name specified for the Account is used
            RemAccount.TestField("Return Journal Name");
            GenJnlLine.Validate("Journal Template Name", RemAccount."Return Journal Template Name");
            GenJnlLine.Validate("Journal Batch Name", RemAccount."Return Journal Name");
            MoreReturnJournals := true; // If True, the settlement status is shown last.
        end;

        // Find next LineNo for the current journal
        CHeckGenJnlLine := GenJnlLine;
        CHeckGenJnlLine.SetRange("Journal Template Name", CHeckGenJnlLine."Journal Template Name");
        CHeckGenJnlLine.SetRange("Journal Batch Name", CHeckGenJnlLine."Journal Batch Name");
        if CHeckGenJnlLine.FindLast() then
            JournalNextLineNo := CHeckGenJnlLine."Line No." + 10000
        else
            JournalNextLineNo := 10000;

        GenJnlLine.Validate("Line No.", JournalNextLineNo);
        RegisterJournal.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        GenJnlLine."Posting No. Series" := RegisterJournal."Posting No. Series";
    end;

    [Scope('OnPrem')]
    procedure SetJournal(GenJnlLine: Record "Gen. Journal Line")
    begin
        // Specify import journal.
        // Called from external function, which imports upon return.
        CurrentJournal := GenJnlLine;
    end;

    [Scope('OnPrem')]
    procedure Initialize(GenJnlLine: Record "Gen. Journal Line"; FileName: Text[250]; Note: Text[50])
    begin
        // Specify import variabels.
        // Called from external function, which imports upon return.
        CurrentJournal := GenJnlLine;
        CurrentFilename := FileName;
        CurrentNote := Note;
    end;

    [Scope('OnPrem')]
    procedure ReadStatus(var Approved: Integer; var Rejected: Integer; var Settled: Integer; var ReturnMoreReturnJournals: Boolean; var ReturnPaymOrder: Record "Remittance Payment Order")
    begin
        // Return info on the newly performed import.
        // Count parameters with new values.
        Approved := 0;
        Rejected := 0;
        Settled := Settled + NumberSettled;
        ReturnMoreReturnJournals := MoreReturnJournals;
        ReturnPaymOrder := PaymOrder;
    end;

    [Scope('OnPrem')]
    procedure StatusError(CurrentWaitingJournal: Record "Waiting Journal")
    begin
        Error(
          Text15000015,
          FileImp,
          CurrentWaitingJournal."Remittance Status",
          CurrentWaitingJournal.Reference);
    end;
}
