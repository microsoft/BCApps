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
using System.Reflection;
using System.Telemetry;

report 15000064 "OCR Payment - BBS"
{
    Caption = 'OCR Payment - BBS';
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
                            FileName := FileMgt.UploadFile(Text10613, FileName);
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

        trigger OnOpenPage()
        begin
            FileName := OCRSetup.FileName;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        OCRSetup.Get();
        SalesSetup.GetRecordOnce();
        BalAccType := OCRSetup."Bal. Account Type";
        BalAccNo := OCRSetup."Bal. Account No.";
    end;

    trigger OnPostReport()
    begin
        FeatureTelemetry.LogUptake('1000HU7', NOOCRReportTok, Enum::"Feature Uptake Status"::"Used");
        if BalEntrySum <> 0 then
            CreateBalEntry();

        TxtFile.Close();
        MessageText := StrSubstNo(Text10618, NumberOfEntries);
        if NumberOfWarnings > 0 then
            Message(Text10619, MessageText, NumberOfWarnings)
        else
            Message(MessageText);
        FeatureTelemetry.LogUsage('1000HU8', NOOCRReportTok, 'NO OCR Set Up Payments Completed');
    end;

    trigger OnPreReport()
    begin
        if FileName = '' then
            Error(Text10632);
        ServerTempFile := FileName;

        if ((OCRSetup."Journal Template Name" <> '') or (OCRSetup."Journal Name" <> '')) and
           ((OCRSetup."Journal Template Name" <> SelectedGenJnlLine."Journal Template Name") or
            (OCRSetup."Journal Name" <> SelectedGenJnlLine."Journal Batch Name"))
        then
            Error(
              Text10616,
              OCRSetup."Journal Template Name",
              OCRSetup."Journal Name");

        GenJnlLine.SetRange("Journal Template Name", SelectedGenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", SelectedGenJnlLine."Journal Batch Name");
        if GenJnlLine.FindLast() then begin
            if not Confirm(Text10617, false) then
                Error('');
            NextLineNo := GenJnlLine."Line No." + 10000;
        end else
            NextLineNo := 10000;

        // Test journal
        GenJournalBatch.Get(SelectedGenJnlLine."Journal Template Name", SelectedGenJnlLine."Journal Batch Name");
        GenJournalBatch.TestField("Bal. Account No.", '');
        GenJournalBatch.TestField("No. Series");
        // Create work file
        TxtFile.TextMode := true;
        TxtFile.Open(ServerTempFile);

        BalEntrySum := 0;
        NumberOfWarnings := 0;
        NumberOfEntries := 0;
        NewDocumentNo := false;
        Commit();
        LatestBBSDate := 0D;
        LatestPaymentRef := '';

        while TxtFile.Len <> TxtFile.Pos do begin
            TxtFile.Read(RecordContent);
            Recordtype := CopyStr(RecordContent, 7, 2);
            case Recordtype of
                '30':
                    RecordType30();
                '31':
                    begin
                        RecordType31();
                        CreatePayment();
                    end;
            end;
        end;
    end;

    var
        SelectedGenJnlLine: Record "Gen. Journal Line";
        PrevGenJnlLine: Record "Gen. Journal Line";
        OCRSetup: Record "OCR Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IssuedReminderHeader: Record "Issued Reminder Header";
        GenJnlLine: Record "Gen. Journal Line";
        FileMgt: Codeunit "File Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NOOCRReportTok: Label 'NO OCR Set Up Payments', Locked = true;
        TxtFile: File;
        Bbsdate: Date;
        LatestBBSDate: Date;
        BalAccNo: Code[20];
        Recordtype: Code[2];
        LatestPaymentRef: Code[10];
        PaymentRef: Code[10];
        ApplyToDocumentNo: Code[20];
        ApplyToDocumentType: Code[1];
        TransType: Code[2];
        FileName: Text[250];
        RecordContent: Text[80];
        MessageText: Text[250];
        KID: Text[30];
        TransTypeText: Text[30];
        ServerTempFile: Text[1024];
        OCRPaymentFileName: Text;
        OCRAmount: Decimal;
        BalEntrySum: Decimal;
        DivergenceAmount: Decimal;
        RemainingAmount: Decimal;
        NextLineNo: Integer;
        BalAccType: Integer;
        CentralID: Integer;
        DayCode: Integer;
        PartialSettlementNo: Integer;
        NumberOfWarnings: Integer;
        NumberOfEntries: Integer;
        NewDocumentNo: Boolean;
        Text10600: Label ' OCR Payment';
        Text10601: Label ' (Giro)';
        Text10602: Label ' (Fixed payment orders)';
        Text10603: Label ' (Direct remittance)';
        Text10604: Label ' (BTG)';
        Text10605: Label ' (CounterGiro)';
        Text10606: Label ' (AgreementGiro)';
        Text10607: Label ' (Telegiro)';
        Text10608: Label ' (Giro paid in cash)';
        Text10611: Label 'Divergence, OCR-Payment (%1 %2)', Comment = 'Parameter 1 - document type, 2 - document number.';
        Text10612: Label 'OCR-Payment. Paymentref. %1';
        Text10613: Label 'Import from OCR Payment File.';
        Text10616: Label 'OCR payments can only be imported into journal Journal Template Name %1, Journal Name %2.';
        Text10617: Label 'Journal already contains lines.\Import?';
        Text10618: Label '%1 payments are imported.';
        Text10619: Label '%1\Number of warnings for import: %2.';
        Text10620: Label 'Following error no.';
        Text10621: Label '%1\Following warning nos.: %2';
        Text10622: Label 'Amount paid-in does not correspond to the remaining amount %1.';
        Text10623: Label 'Error in KID "%1".';
        Text10624: Label 'Customer entry is closed (entry serial no. %1).';
        Text10625: Label 'Payment, reminder no. %1.\Apply to must be specified manually.';
        Text10626: Label 'Divergence occured.\Amount paid-in does not correspond with remaining amount %1.';
        Text10627: Label 'Document no. "%1" does not exist.\KID="%2".';
        Text10628: Label 'Reminder no. "%1" does not exist.\KID="%2".';
        Text10629: Label 'Error unknown.';
        Text10630: Label 'Warning %1: %2', Comment = 'Parameter 1 - integer, 2 - text.';
        Text10632: Label 'Specify file name.';

    local procedure CreatePayment()
    begin
        DivergenceAmount := 0;

        // Check new bal.entry
        if LatestPaymentRef <> PaymentRef then begin
            if BalEntrySum <> 0 then
                CreateBalEntry();
            LatestBBSDate := Bbsdate;
            LatestPaymentRef := PaymentRef;
        end;

        BalEntrySum := BalEntrySum + OCRAmount;
        Clear(GenJnlLine);
        GenJnlLine.Validate("Journal Template Name", SelectedGenJnlLine."Journal Template Name");
        GenJnlLine.Validate("Journal Batch Name", SelectedGenJnlLine."Journal Batch Name");
        if NewDocumentNo then
            GenJnlLine.SetUpNewLine(PrevGenJnlLine, PrevGenJnlLine."Balance (LCY)", true)
        else
            GenJnlLine.SetUpNewLine(PrevGenJnlLine, 1, true);
        GenJnlLine.Validate("Line No.", NextLineNo);
        NextLineNo := NextLineNo + 10000;
        GenJnlLine.Validate("Posting Date", Bbsdate);
        GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Payment);
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::Invoice);

        if KID[25] = '''' then begin  // If 25. char  = ' then the KID is wrong.
                                      // Cust.No. and ApplyToDocumentNo can not be set:
            KID := CopyStr(KID, 1, 24);  // Delete ' in KID.
            GenJnlLine.Validate(Amount, OCRAmount);
            SetWarning(2); // Wrong KID
        end else begin
            ApplyToDocumentNo := DeleteZeroes(ApplyToDocumentNo);
            if ApplyToDocumentType = '3' then begin
                // Find reminder, then the cust.no. is known:
                if IssuedReminderHeader.Get(ApplyToDocumentNo) then begin
                    GenJnlLine.Validate("Account No.", IssuedReminderHeader."Customer No.");
                    SetWarning(4);
                end else
                    SetWarning(7); // reminder does not exist
                GenJnlLine.Validate(Amount, OCRAmount);
            end else begin
                // Find invoice/credit memo. Then the cust. no. is known:
                CustLedgerEntry.SetCurrentKey("Document Type");
                case ApplyToDocumentType of
                    '0', '1':
                        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
                    '2':
                        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Finance Charge Memo");
                end;
                CustLedgerEntry.SetRange("Document No.", ApplyToDocumentNo);
                if not CustLedgerEntry.FindFirst() then begin
                    SetWarning(6); // Document No. does not exist
                                   // Create a temporary CustEntry and the info used in following:
                    CustLedgerEntry."Customer No." := '';
                    CustLedgerEntry.Open := true;
                    RemainingAmount := -OCRAmount;
                    ApplyToDocumentNo := '';
                end else begin
                    CustLedgerEntry.CalcFields("Remaining Amount");
                    RemainingAmount := CustLedgerEntry."Remaining Amount";
                end;
                GenJnlLine.Validate("Account No.", CustLedgerEntry."Customer No.");
                GenJnlLine.Validate(Amount, OCRAmount);
                case true of
                    not CustLedgerEntry.Open:
                        SetWarning(3); // CustEntry is closed
                    (GenJnlLine.Amount <> -RemainingAmount) and
                    (Abs(GenJnlLine.Amount + RemainingAmount) <= OCRSetup."Max. Divergence"):
                        begin
                            SetWarning(5); // Wrong Amount - automatic divergence post
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

        OnCreatePaymentOnBeforeSetTransTypeText(GenJnlLine, SalesSetup, KID);

        case TransType of
            '10':
                TransTypeText := Text10601;
            '11':
                TransTypeText := Text10602;
            '12':
                TransTypeText := Text10603;
            '13':
                TransTypeText := Text10604;
            '14':
                TransTypeText := Text10605;
            '15':
                TransTypeText := Text10606;
            '16':
                TransTypeText := Text10607;
            '17':
                TransTypeText := Text10608;
            else
                TransTypeText := '';
        end;
        GenJnlLine.Validate(Description, Text10600 + TransTypeText);
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
        GenJnlLine.Validate("Journal Template Name", SelectedGenJnlLine."Journal Template Name");
        GenJnlLine.Validate("Journal Batch Name", SelectedGenJnlLine."Journal Batch Name");
        GenJnlLine.SetUpNewLine(PrevGenJnlLine, 1, true);
        GenJnlLine.Validate("Line No.", NextLineNo);
        NextLineNo := NextLineNo + 10000;
        GenJnlLine.Validate("Posting Date", LatestBBSDate);
        GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Payment);
        GenJnlLine.Validate("Account Type", BalAccType);
        GenJnlLine.Validate("Account No.", BalAccNo);
        GenJnlLine.Validate(Description, StrSubstNo(Text10612, LatestPaymentRef));
        GenJnlLine.Validate(Amount, -BalEntrySum);
        GenJnlLine.Insert(true);
        PrevGenJnlLine := GenJnlLine;

        BalEntrySum := 0;
        NewDocumentNo := true;
    end;

    local procedure CreateDivergence(DivergenceAmount: Decimal): Boolean
    begin
        if OCRSetup."Max. Divergence" = 0 then
            exit;
        OCRSetup.TestField("Divergence Account No.");

        Clear(GenJnlLine);
        GenJnlLine.Validate("Journal Template Name", SelectedGenJnlLine."Journal Template Name");
        GenJnlLine.Validate("Journal Batch Name", SelectedGenJnlLine."Journal Batch Name");
        GenJnlLine.SetUpNewLine(PrevGenJnlLine, 1, true);
        GenJnlLine.Validate("Line No.", NextLineNo);
        NextLineNo := NextLineNo + 10000;
        GenJnlLine.Validate("Posting Date", LatestBBSDate);
        GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::" ");
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
        GenJnlLine.Validate("Account No.", OCRSetup."Divergence Account No.");
        GenJnlLine.Validate(Description, StrSubstNo(Text10611, CustLedgerEntry."Document Type", CustLedgerEntry."Document No."));
        GenJnlLine.Validate(Amount, DivergenceAmount);
        GenJnlLine.Insert(true);
        PrevGenJnlLine := GenJnlLine;
    end;

    local procedure RecordType30()
    var
        OCRDateString: Text[6];
    begin
        // OCR Date string is always specified as DDMMYY
        OCRDateString := CopyStr(RecordContent, 16, 6);
        ParseBbsDate(Bbsdate, OCRDateString);

        Evaluate(CentralID, CopyStr(RecordContent, 22, 2));
        Evaluate(DayCode, CopyStr(RecordContent, 24, 2));
        Evaluate(PartialSettlementNo, CopyStr(RecordContent, 26, 1));
        PaymentRef := CopyStr(RecordContent, 22, 10);
        // Read the whole KID for later check:
        KID := CopyStr(RecordContent, 50, 25);
        // Amount in LCY/100 to negativ Amount in LCY.
        Evaluate(OCRAmount, CopyStr(RecordContent, 33, 17));
        OCRAmount := -(OCRAmount / 100);

        // Customer No. is not read. Only the document no. and maybe document type are read
        FindApplyToDocument(KID, ApplyToDocumentType, ApplyToDocumentNo);
    end;

    procedure FindApplyToDocument(KID: Text[30]; var ApplyToDocumentType: Code[1]; var ApplyToDocumentNo: Code[20])
    begin
        SalesSetup.GetRecordOnce();
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
            SalesSetup."KID Setup"::"Document No.+Document Type":
                begin
                    ApplyToDocumentNo := CopyStr(KID, 24 - SalesSetup."Document No. length", SalesSetup."Document No. length");
                    ApplyToDocumentType := Format(KID[25]);
                end;
            else
                SalesSetup.FieldError("KID Setup");
        end;
    end;

    local procedure RecordType31()
    begin
        TransType := CopyStr(RecordContent, 5, 2);
    end;

    local procedure DeleteZeroes(No: Code[20]): Code[20]
    var
        Continue: Boolean;
    begin
        // Delete leadnig zeros:
        Continue := true;
        while Continue and (No <> '') do begin
            Continue := (No[1] = '0');
            if Continue then
                No := CopyStr(No, 2);
        end;
        exit(No);
    end;

    procedure SetJournal(JournalLine: Record "Gen. Journal Line")
    begin
        SelectedGenJnlLine."Journal Template Name" := JournalLine."Journal Template Name";
        SelectedGenJnlLine."Journal Batch Name" := JournalLine."Journal Batch Name";
    end;

    local procedure SetWarning(WarningNo: Integer)
    var
        Text: Text[250];
    begin
        NumberOfWarnings := NumberOfWarnings + 1;
        if GenJnlLine.Warning then
            // An error is already registered. Specify error no. on further errors only
            if StrPos(GenJnlLine."Warning text", Text10620) = 0 then
                Text := StrSubstNo(Text10621, GenJnlLine."Warning text", WarningNo)
            else
                Text := StrSubstNo('%1, %2', GenJnlLine."Warning text", WarningNo)
        else begin
            GenJnlLine.Validate(Warning, true);
            case WarningNo of
                1:
                    Text := StrSubstNo(Text10622, RemainingAmount);
                2:
                    Text := StrSubstNo(Text10623, KID);
                3:
                    Text := StrSubstNo(Text10624, CustLedgerEntry."Entry No.");
                4:
                    Text := StrSubstNo(Text10625, ApplyToDocumentNo);
                5:
                    Text := StrSubstNo(Text10626, RemainingAmount);
                6:
                    Text := StrSubstNo(Text10627, ApplyToDocumentNo, KID);
                7:
                    Text := StrSubstNo(Text10628, ApplyToDocumentNo, KID);
                else
                    Text := Text10629;
            end;
            Text := StrSubstNo(Text10630, WarningNo, Text);
        end;
        if StrLen(Text) > MaxStrLen(GenJnlLine."Warning text") then
            Text := CopyStr(Text, 1, MaxStrLen(GenJnlLine."Warning text") - 3) + '...';
        GenJnlLine.Validate("Warning text", Text);
    end;

    local procedure ParseBbsDate(var BbsDate: Date; OCRDateString: Text[6])
    var
        TypeHelper: Codeunit "Type Helper";
        DateVariant: Variant;
    begin
        DateVariant := BbsDate;
        TypeHelper.Evaluate(DateVariant, OCRDateString, 'ddMMyy', 'no');
        BbsDate := DateVariant;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePaymentOnBeforeSetTransTypeText(var GenJnlLine: Record "Gen. Journal Line"; SalesSetup: Record "Sales & Receivables Setup"; KID: Text[30])
    begin
    end;
}

