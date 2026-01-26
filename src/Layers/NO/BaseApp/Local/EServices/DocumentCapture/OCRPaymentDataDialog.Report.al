// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Setup;
using System.IO;

report 15000065 "OCR Payment - Data Dialog"
{
    Caption = 'OCR Payment - Data Dialog';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(FileNameTextBox; OCRPaymentFileName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'File Name';
                        ToolTip = 'Specifies the file name for the payment.';

                        trigger OnAssistEdit()
                        begin
                            FileName := FileMgt.UploadFile(Text10623, FileName);
                            if FileName <> '' then
                                OCRPaymentFileName := FileMgt.GetFileName(FileName);
                        end;

                        trigger OnValidate()
                        begin
                            FileName := CopyStr(OCRPaymentFileName, 1, MaxStrLen(FileName));
                            OCRPaymentFileName := FileMgt.GetFileName(FileName);
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
        OCRSetup.Get();
        SalesSetup.Get();
        FileName := OCRSetup.FileName;
        BalAccType := OCRSetup."Bal. Account Type";
        BalAccNo := OCRSetup."Bal. Account No.";
    end;

    trigger OnPostReport()
    begin
        if BalEntrySum <> 0 then
            CreateBalEntry();

        TxtFile.Close();
        MessageText := StrSubstNo(text160806, NumberOfEntries);
        if NumberOfWarnings > 0 then
            Message(text160807, MessageText, NumberOfWarnings)
        else
            Message(MessageText);
    end;

    trigger OnPreReport()
    begin
        if FileName = '' then
            Error(Text160815);

        ServerTempFile := FileName;

        if ((OCRSetup."Journal Template Name" <> '') or (OCRSetup."Journal Name" <> '')) and
           ((OCRSetup."Journal Template Name" <> JournalSelection."Journal Template Name") or
            (OCRSetup."Journal Name" <> JournalSelection."Journal Batch Name"))
        then
            Error(
              text160802,
              OCRSetup."Journal Template Name",
              OCRSetup."Journal Name");

        GenJnlLine.SetRange("Journal Template Name", JournalSelection."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", JournalSelection."Journal Batch Name");
        if GenJnlLine.FindLast() then begin
            if not Confirm(text160803, false) then
                Error('');
            NextLineNo := GenJnlLine."Line No." + 10000;
        end else
            NextLineNo := 10000;

        RegisterJournal.Get(JournalSelection."Journal Template Name", JournalSelection."Journal Batch Name");
        RegisterJournal.TestField("Bal. Account No.", '');
        RegisterJournal.TestField("No. Series");

        TxtFile.TextMode := true;
        TxtFile.Open(ServerTempFile);

        BalEntrySum := 0;
        NumberOfWarnings := 0;
        NumberOfEntries := 0;
        NewDocumentNo := false;
        Commit();
        LatestOCRDate := 0D;

        while TxtFile.Len <> TxtFile.Pos do begin
            TxtFile.Read(RecordContent);
            RecordType := CopyStr(RecordContent, 7, 2);
            case RecordType of
                '10':
                    RecordType10();
                '20':
                    RecordType20();
                '21':
                    begin
                        RecordType21();
                        CreatePayment();
                    end;
                '22':
                    RecordType22();
                '40':
                    RecordType40();
                '41':
                    RecordType41();
            end;
        end;
    end;

    var
        CustEntry: Record "Cust. Ledger Entry";
        JournalSelection: Record "Gen. Journal Line";
        PrevGenJnlLine: Record "Gen. Journal Line";
        RegisterJournal: Record "Gen. Journal Batch";
        OCRSetup: Record "OCR Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        Reminder: Record "Issued Reminder Header";
        GenJnlLine: Record "Gen. Journal Line";
        FileMgt: Codeunit "File Management";
        TxtFile: File;
        OCRDate: Date;
        LatestOCRDate: Date;
        BalAccType: Option "Gen. Ledg. Account",,,"Bank account";
        BalAccNo: Code[20];
        ApplyToDocumentNo: Code[20];
        ApplyToDocumentType: Code[1];
        FileName: Text[250];
        RecordContent: Text[250];
        RecordType: Text[2];
        KID: Text[25];
        ServerTempFile: Text[1024];
        MessageText: Text[250];
        OCRPaymentFileName: Text;
        OCRAmount: Decimal;
        BalEntrySum: Decimal;
        DivergenceAmount: Decimal;
        RemainingAmount: Decimal;
        NumberOfEntries: Integer;
        NumberOfWarnings: Integer;
        NextLineNo: Integer;
        text160801: Label 'OCR-Payment';
        text160813: Label 'OCR-Payment, %1';
        text160804: Label 'Divergence, OCR-Payment (%1 %2)', Comment = 'Parameter 1 - document type, 2 - document number.';
        text160802: Label 'OCR payments can only be imported into journal Journal Template Name %1, Journal Name %2.';
        text160803: Label 'The journal already contains lines.\Import?';
        text160806: Label '%1 payments are imported.';
        text160807: Label '%1\Number of warnings for import: %2.';
        text160808: Label '%1\Following warning nos.: %2';
        text160809: Label 'Amount paid in does not correspond to the remaining amount %1.';
        text160810: Label 'Error in KID "%1".';
        text160811: Label 'Customer entry is closed (entry serial no. %1).';
        text160812: Label 'Payment, reminder no. %1.\Apply-to must be specified manually.';
        Text160815: Label 'Specify file name.';
        text160816: Label 'Error unknown';
        text160817: Label 'Warning no. %1: %2', Comment = 'Parameter 1 - integer, 2 - text.';
        text160818: Label 'Divergence created.\Amount paid in does not correspond with the remaining amount %1.';
        text160819: Label 'Document no. "%1" does not exist.\KID="%2".';
        text160820: Label 'Reminder no. "%1" does not exist.\KID="%2".';
        Text10623: Label 'Import from OCR Payment File.';
        NewDocumentNo: Boolean;

    local procedure CreatePayment()
    begin
        if LatestOCRDate <> OCRDate then begin
            if BalEntrySum <> 0 then
                CreateBalEntry();
            LatestOCRDate := OCRDate;
        end;

        BalEntrySum := BalEntrySum + OCRAmount;
        Clear(GenJnlLine);
        GenJnlLine.Validate("Journal Template Name", JournalSelection."Journal Template Name");
        GenJnlLine.Validate("Journal Batch Name", JournalSelection."Journal Batch Name");
        if NewDocumentNo then
            GenJnlLine.SetUpNewLine(PrevGenJnlLine, PrevGenJnlLine."Balance (LCY)", true)
        else
            GenJnlLine.SetUpNewLine(PrevGenJnlLine, 1, true);
        GenJnlLine.Validate("Line No.", NextLineNo);
        NextLineNo := NextLineNo + 10000;
        GenJnlLine.Validate("Posting Date", OCRDate);
        GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Payment);
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::Invoice);

        if KID[25] = '''' then begin    // Wrong KID
            KID := CopyStr(KID, 1, 24);  // Delete error markings ''''.
            GenJnlLine.Validate(Amount, OCRAmount);
            SetWarning(2); // Wrong KID
        end else begin
            ApplyToDocumentNo := DeleteZeros(ApplyToDocumentNo);
            if ApplyToDocumentType = '3' then begin
                // Find the reminder. Then, the customer no is known:
                if Reminder.Get(ApplyToDocumentNo) then begin
                    GenJnlLine.Validate("Account No.", Reminder."Customer No.");
                    SetWarning(4);
                end else
                    SetWarning(7); // Reminder does not exist
                GenJnlLine.Validate(Amount, OCRAmount);
                SetWarning(4);
            end else begin
                // Find invoice/credit memo. Then, the customer no. is known:
                CustEntry.SetCurrentKey("Document No.", "Document Type");
                case ApplyToDocumentType of
                    '0', '1':
                        CustEntry.SetRange("Document Type", CustEntry."Document Type"::Invoice);
                    '2':
                        CustEntry.SetRange("Document Type", CustEntry."Document Type"::"Finance Charge Memo");
                end;
                CustEntry.SetRange("Document No.", ApplyToDocumentNo);

                if not CustEntry.FindFirst() then begin
                    SetWarning(6); // Document no. does not exist
                                   // Create temporary customer entry and info used in following:
                    CustEntry."Customer No." := '';
                    CustEntry.Open := true;
                    RemainingAmount := -OCRAmount;
                    ApplyToDocumentNo := '';
                end else begin
                    CustEntry.CalcFields("Remaining Amount");
                    RemainingAmount := CustEntry."Remaining Amount";
                end;
                GenJnlLine.Validate("Account No.", CustEntry."Customer No.");
                GenJnlLine.Validate(Amount, OCRAmount);
                case true of
                    not CustEntry.Open:
                        SetWarning(3); // Customer entry is closed
                    (GenJnlLine.Amount <> -RemainingAmount) and
                    (Abs(GenJnlLine.Amount + RemainingAmount) <= OCRSetup."Max. Divergence"):
                        begin
                            SetWarning(5); // Wrong amount - automatic divergence entry
                            DivergenceAmount := GenJnlLine.Amount + RemainingAmount;
                            // Apply to ledger
                            GenJnlLine.Validate(Amount, -RemainingAmount);
                        end;
                    GenJnlLine.Amount <> -RemainingAmount:
                        SetWarning(1); // Wrong amount
                end;

                GenJnlLine.Validate("Applies-to Doc. No.", ApplyToDocumentNo);
            end;
        end;
        GenJnlLine.Validate(Description, text160801);
        GenJnlLine.Insert(true);
        PrevGenJnlLine := GenJnlLine;

        if DivergenceAmount <> 0 then
            CreateDivergence(DivergenceAmount);

        NumberOfEntries := NumberOfEntries + 1;
        NewDocumentNo := false;
    end;

    local procedure CreateBalEntry()
    begin
        Clear(GenJnlLine);
        GenJnlLine.Validate("Journal Template Name", JournalSelection."Journal Template Name");
        GenJnlLine.Validate("Journal Batch Name", JournalSelection."Journal Batch Name");
        GenJnlLine.SetUpNewLine(PrevGenJnlLine, 1, true);
        GenJnlLine.Validate("Line No.", NextLineNo);
        NextLineNo := NextLineNo + 10000;
        GenJnlLine.Validate("Posting Date", LatestOCRDate);
        GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Payment);
        GenJnlLine.Validate("Account Type", BalAccType);
        GenJnlLine.Validate("Account No.", BalAccNo);
        GenJnlLine.Validate(Description,
          CopyStr(StrSubstNo(text160813, LatestOCRDate), 1, MaxStrLen(GenJnlLine.Description)));
        GenJnlLine.Validate(Amount, -BalEntrySum);
        GenJnlLine.Insert(true);
        PrevGenJnlLine := GenJnlLine;

        BalEntrySum := 0;
        NewDocumentNo := true;
    end;

    [Scope('OnPrem')]
    procedure CreateDivergence(DivergenceAmount: Decimal)
    begin
        if OCRSetup."Max. Divergence" = 0 then
            exit;
        OCRSetup.TestField("Divergence Account No.");

        Clear(GenJnlLine);
        GenJnlLine.Validate("Journal Template Name", JournalSelection."Journal Template Name");
        GenJnlLine.Validate("Journal Batch Name", JournalSelection."Journal Batch Name");
        GenJnlLine.SetUpNewLine(GenJnlLine, 0, false);
        GenJnlLine.Validate("Line No.", NextLineNo);
        NextLineNo := NextLineNo + 10000;
        GenJnlLine.Validate("Posting Date", LatestOCRDate);
        GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::" ");
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
        GenJnlLine.Validate("Account No.", OCRSetup."Divergence Account No.");
        GenJnlLine.Validate(
          Description, StrSubstNo(text160804, CustEntry."Document Type", CustEntry."Document No."));
        GenJnlLine.Validate(Amount, DivergenceAmount);
        GenJnlLine.Insert();
        PrevGenJnlLine := GenJnlLine;
    end;

    [Scope('OnPrem')]
    procedure RecordType10()
    begin
        // No data is used
    end;

    local procedure RecordType20()
    begin
        Evaluate(OCRDate, CopyStr(RecordContent, 59, 8));
        Evaluate(OCRAmount, CopyStr(RecordContent, 75, 14));
        OCRAmount := -OCRAmount / 100;
    end;

    local procedure RecordType21()
    begin
        KID := CopyStr(RecordContent, 5, 25);

        // Read info on KID:
        ApplyToDocumentType := '';
        case SalesSetup."KID Setup" of
            SalesSetup."KID Setup"::"Document No.":
                ApplyToDocumentNo := CopyStr(KID, 25 - SalesSetup."Document No. length", SalesSetup."Document No. length");
            SalesSetup."KID Setup"::"Document No.+Customer No.":
                ApplyToDocumentNo :=
                  CopyStr(KID, 25 - SalesSetup."Document No. length" - SalesSetup."Customer No. length",
                    SalesSetup."Document No. length");
            SalesSetup."KID Setup"::"Customer No.+Document No.":
                ApplyToDocumentNo := CopyStr(KID, 25 - SalesSetup."Document No. length", SalesSetup."Document No. length");
            SalesSetup."KID Setup"::"Document Type+Document No.":
                begin
                    ApplyToDocumentNo := CopyStr(KID, 25 - SalesSetup."Document No. length", SalesSetup."Document No. length");
                    ApplyToDocumentType := Format(KID[24 - SalesSetup."Document No. length"]);
                end;
            else
                SalesSetup.FieldError("KID Setup");
        end;
    end;

    local procedure RecordType22()
    begin
    end;

    local procedure RecordType40()
    begin
    end;

    local procedure RecordType41()
    begin
    end;

    local procedure DeleteZeros(No: Code[20]): Code[20]
    var
        continue: Boolean;
    begin
        continue := true;
        while continue and (No <> '') do begin
            continue := (No[1] = '0');
            if continue then
                No := CopyStr(No, 2);
        end;
        exit(No);
    end;

    [Scope('OnPrem')]
    procedure SetJournal(JournalLine: Record "Gen. Journal Line")
    begin
        JournalSelection."Journal Template Name" := JournalLine."Journal Template Name";
        JournalSelection."Journal Batch Name" := JournalLine."Journal Batch Name";
    end;

    local procedure SetWarning(WarningNo: Integer)
    var
        Text: Text[250];
    begin
        NumberOfWarnings := NumberOfWarnings + 1;
        if GenJnlLine.Warning then
            // An error is already registered. Specify error no. for following errors only
            if StrPos(GenJnlLine."Warning text", text160810) = 0 then
                Text := StrSubstNo(text160808, GenJnlLine."Warning text", WarningNo)
            else
                Text := StrSubstNo('%1, %2', GenJnlLine."Warning text", WarningNo)
        else begin
            GenJnlLine.Validate(Warning, true);
            case WarningNo of
                1:
                    Text := StrSubstNo(text160809, RemainingAmount);
                2:
                    Text := StrSubstNo(text160811, KID);
                3:
                    Text := StrSubstNo(text160812, CustEntry."Entry No.");
                4:
                    Text := StrSubstNo(text160818, ApplyToDocumentNo);
                5:
                    Text := StrSubstNo(text160819, RemainingAmount);
                6:
                    Text := StrSubstNo(text160820, ApplyToDocumentNo, KID);
                else
                    Text := text160816;
            end;
            Text := StrSubstNo(text160817, WarningNo, Text);
        end;
        if StrLen(Text) > MaxStrLen(GenJnlLine."Warning text") then
            Text := CopyStr(Text, 1, MaxStrLen(GenJnlLine."Warning text") - 3) + '...';
        GenJnlLine.Validate("Warning text", Text);
    end;
}

