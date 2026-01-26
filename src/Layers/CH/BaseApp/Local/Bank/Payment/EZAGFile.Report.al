// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.IO;
using System.Telemetry;

report 3010542 "EZAG File"
{
    Caption = 'EZAG File';
    Permissions = TableData "Vendor Ledger Entry" = m,
                  TableData "DTA Setup" = m;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Posting Date", Clearing, "Debit Bank");

            trigger OnAfterGetRecord()
            begin
                if not VendBank.Get("Account No.", "Recipient Bank Account") then  // Bank connection
                    Error(Text011, "Recipient Bank Account", "Account No.");

                TotalLCY := TotalLCY + "Amount (LCY)";  // For message

                // Combine pmt, if not ESR/ESR+, same account, bank, currency
                SummaryPmtAmt := SummaryPmtAmt + Amount;
                NoOfGlLines := NoOfGlLines + 1;
                PrepareSummaryPmt();

                // Write EZAG rec or add amount for combined pmt
                NextGlLine.Copy("Gen. Journal Line");
                if (NextGlLine.Next() = 0) or
                   (SummaryPerVendor = false) or
                   (NextGlLine."Account No." <> "Account No.") or
                   (NextGlLine."Recipient Bank Account" <> "Recipient Bank Account") or
                   (NextGlLine."Currency Code" <> "Currency Code") or
                   (VendBank."Payment Form" in [VendBank."Payment Form"::ESR, VendBank."Payment Form"::"ESR+"])
                then begin
                    AdjustSummaryPmtText();

                    WriteEzagRecord(
                      "Account No.", "Recipient Bank Account", "Currency Code", SummaryPmtAmt,
                      "Posting Date", "Document No.", "Applies-to Doc. No.", Description, CopyStr(SummaryPmtTxt, 1, 70));

                    "Exported to Payment File" := true;
                    SummaryPmtAmt := 0;
                    SummaryPmtTxt := '';
                end;
            end;

            trigger OnPostDataItem()
            begin
                WriteTotalRecord();
            end;

            trigger OnPreDataItem()
            begin
                // Key: Posting Date, Clearing
                SetRange("Account Type", "Account Type"::Vendor);
                SetRange("Document Type", "Document Type"::Payment);
                SetFilter("Account No.", '<>%1', '');
                SetFilter(Amount, '<>%1', 0);

                // Prepare debit date
                if not FindFirst() then
                    Error(Text007);

                if Date2DWY("Posting Date", 1) >= 6 then
                    Error(Text008, "Posting Date");

                if "Posting Date" < Today then
                    Error(Text009, "Posting Date");

                xValuta := Format("Posting Date", 6, '<year><month,2><day,2>');

                PrepareFile();
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
                    field("DtaSetup.""Bank Code"""; DtaSetup."Bank Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Debit to bank';
                        Lookup = true;
                        TableRelation = "DTA Setup" where("DTA/EZAG" = const(EZAG));
                        ToolTip = 'Specifies the bank to which the payments are charged.';
                    }
                    field(SummaryPerVendor; SummaryPerVendor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Combined payment for vendor';
                        ToolTip = 'Specifies if you want the payment lines to be combined for the same vendor, currency, bank, and debit bank.';
                    }
                    field(DiscTransfer; DiscTransfer)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Shipment with disk';
                        ToolTip = 'Specifies if you want to transfer the EZAG file to the bank by disk.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            // Suggest main bank
            DtaSetup.SetRange("DTA/EZAG", DtaSetup."DTA/EZAG"::EZAG);

            DiscTransfer := true;
            if DtaSetup.FindFirst() then
                if DtaSetup."Yellownet Home Page" <> '' then
                    DiscTransfer := false;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUsage('0000KEG', 'DTA Local CH Functionality', 'EZAG File report');
        Filename.Close();

        if DtaSetup."File Format" = DtaSetup."File Format"::"Without CR/LF" then
            GeneralMgt.RemoveCrLf(DtaSetup."EZAG File Folder" + DtaSetup."EZAG Filename", ServerTempFileName, false);
        FileMgt.DownloadHandler(ServerTempFilename, '', '', '', DtaSetup."EZAG File Folder" + DtaSetup."EZAG Filename");

        // Backup file
        if DtaSetup."Backup Copy" then begin
            DtaSetup.LockTable();
            DtaSetup."Last Backup No." := IncStr(DtaSetup."Last Backup No.");
            DtaSetup.Modify();
            BackupFilename := DtaSetup."Backup Folder" + 'EZA' + DtaSetup."Last Backup No." + '.BAK';
            FileMgt.DownloadHandler(ServerTempFilename, '', '', '', BackupFilename);
        end;

        Message(Text006,
          NoOfGlLines, GlSetup."LCY Code", Format(TotalLCY, 0, '<integer thousand><decimals,3>'), TotalNoOfRecs);

        // Save last EZAG no.
        if TotalNoOfRecs > 0 then
            DtaSetup.Modify();
    end;

    var
        Text006: Label 'Total of %1 records for %2 %3 have been processed. %4 payment records were created.', Comment = 'Parameters 1, 3 and 4 - numbers, 2 - currency code.';
        Text007: Label 'No vendor payments exist in this journal.';
        Text009: Label 'The posting date %1 must not be in the past.';
        Text008: Label 'The posting date %1 is invalide. Please chose a postal working day (Mon - Fri).';
        Text011: Label 'No bank connection found with bank code %1 for vendor %2.';
        Text012: Label 'Processing line:        #1###########\';
        Text013: Label 'Vendor number:          #2###########';
        Text014: Label 'EZAG account "%1" not found in the DTA setup.';
        Text015: Label 'The debit bank "%1" is not set up for EZAG.';
        Text016: Label 'etc.';
        Text017: Label ' etc.';
        Text018: Label 'The payments have different posting dates (%1 and %2). If necessary, generate multiple files for your payments.', Comment = 'Parameters 1 and 2 - dates.';
        Text020: Label 'Vendor %1 is not defined in the vendor table.';
        Text029: Label 'ESR and ESR+ must have an application doc. no.\It is missing for document %1, vendor %2.', Comment = 'Parameter 1 - document number, 2 - vendor number.';
        Text031: Label 'Vendor entry for invoice %1 of vendor %2 not found.';
        Text032: Label 'The amount in the vendor entry and in the journal must match for payment type ESR 5/15.\G/L journal: %1, vendor entry: %2.', Comment = 'Parameters 1 and 2 - amounts.';
        Text035: Label 'Reference no. for invoice %1 of vendor %2 must have %3 digits according to the vendor bank definition.';
        Text040: Label 'Country  "%1" for vendor %2 is not defined in the country table.';
        Text041: Label 'The EU country/region code "%1" for vendor %2 must be defined in the country table with 2 characters.';
        Text044: Label 'Only 15 currencies are possible on an EZAG payment order. If necessary split into multiple orders.';
        Text047: Label 'This batch job creates an EZAG Testfile to verify the account numbers.\For each bank of a vendor (except ESR 5/15) a record with 1.00 is generated in the currency of the vendor.\Do you want to continue?';
        Text050: Label 'DTA Testfile\';
        Text051: Label 'Vendor     #1########\';
        Text052: Label 'Records    #2########';
        Text055: Label 'Vendor %1 for bank %2 not found.';
        Text056: Label 'EZAG account verficication ';
        Text057: Label 'File "%1" for the account verification has been created successfully. It is now saved in the folder "%2".\\%3 records with CHF 1.00 each have been processed.', Comment = 'Parameter 1 - file name, 2 - folder name, 3 - number.';
        DtaSetup: Record "DTA Setup";
        GlSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        VendEntry: Record "Vendor Ledger Entry";
        Country: Record "Country/Region";
        NextGlLine: Record "Gen. Journal Line";
        VendBank: Record "Vendor Bank Account";
        DTAMgt: Codeunit DtaMgt;
        GeneralMgt: Codeunit GeneralMgt;
        FileMgt: Codeunit "File Management";
        Filename: File;
        Window: Dialog;
        TestFile: Boolean;
        SummaryPerVendor: Boolean;
        BackupFilename: Text;
        FirstPostingDate: Date;
        TaLineno: Code[6];
        SummaryPmtAmt: Decimal;
        SummaryPmtTxt: Text[80];
        AmtWoComma: Code[16];
        xValuta: Text[10];
        xEsrAcc: Code[9];
        xRefNo: Code[27];
        xChkDig: Code[2];
        xISO: Code[3];
        xPostAcc: Code[10];
        xBankAcc: Code[70];
        xClearing: Text[15];
        xRecName: Text[35];
        xRecName2: Text[35];
        xRecStreet: Text[35];
        xRecCity: Text[35];
        xRecPostCode: Text[10];
        xBeneName: Text[35];
        xBeneName2: Text[35];
        xBeneStreet: Text[35];
        xBenePostCode: Text[35];
        xBeneCity: Text[35];
        NoOfGlLines: Integer;
        TotalNoOfRecs: Integer;
        TotalLCY: Decimal;
        ControlArea: Text[65];
        AmtPart: Text[82];
        ReceiverPart: Text[150];
        BenePart: Text[150];
        MessagePart: Text[150];
        OriginatorPart: Text[168];
        i: Integer;
        iCurrCode: array[15] of Code[5];
        iNo: array[15] of Integer;
        iAmt: array[15] of Decimal;
        CurrencyElement: array[15] of Code[25];
        Text060: Label 'The IBAN of vendor %1 must originate from CH/LI.';
        Text061: Label 'The IBAN of vendor %1 must not originate from CH/LI.';
        Text062: Label 'Account No. is empty for vendor %1, bank account code %2.', Comment = 'Parameter 1 - vendor number, 2 - bank account code.';
        RecType: Integer;
        DiscTransfer: Boolean;
        Text070: Label 'The Entry %1 generates a wrong DTA Line, please check.';
        ServerTempFileName: Text[1024];

    [Scope('OnPrem')]
    procedure PrepareFile()
    begin
        // Create file
        GlSetup.Get();

        Filename.TextMode := true;
        Filename.WriteMode := true;
        ServerTempFileName := FileMgt.ServerTempFileName('');
        Filename.Create(ServerTempFileName, TEXTENCODING::Windows);

        Window.Open(
          Text012 +
          Text013);

        // CHeck setup
        if not DtaSetup.Get(DtaSetup."Bank Code") then
            Error(Text014, DtaSetup."Bank Code");

        if DtaSetup."DTA/EZAG" <> DtaSetup."DTA/EZAG"::EZAG then
            Error(Text015, DtaSetup."Bank Code");

        DtaSetup.TestField("EZAG File Folder");
        DtaSetup.TestField("EZAG Filename");
        DtaSetup.TestField("EZAG Debit Account No.");
        DtaSetup.TestField("EZAG Charges Account No.");
        DtaSetup.TestField("Last EZAG Order No.");

        // Increment order no.
        if (DtaSetup."Last EZAG Order No." = '99') or (DtaSetup."Last EZAG Order No." = '') then
            DtaSetup."Last EZAG Order No." := '00';
        DtaSetup."Last EZAG Order No." := IncStr(DtaSetup."Last EZAG Order No.");
        DtaSetup.Modify();

        TaLineno := '000000';

        // *** Write header, 50 + 650 blank + CR/LF
        PrepareControlArea('00');
        Filename.Write(CheckLine(ControlArea + PadStr(' ', 650), 700));
    end;

    [Scope('OnPrem')]
    procedure PrepareSummaryPmt()
    begin
        // Text and summary pmt text prepare
        VendEntry.SetCurrentKey("Document No.");
        VendEntry.SetRange("Document Type", VendEntry."Document Type"::Invoice);
        VendEntry.SetRange("Document No.", "Gen. Journal Line"."Applies-to Doc. No.");
        VendEntry.SetRange("Vendor No.", "Gen. Journal Line"."Account No.");
        if VendEntry.FindFirst() then begin
            if SummaryPmtTxt = '' then
                SummaryPmtTxt := VendEntry."External Document No."
            // 1. Line: Ext. No.
            else
                if StrLen(SummaryPmtTxt) < 60 then
                    // Additional lines with free space: + Ext. No.
                    SummaryPmtTxt := SummaryPmtTxt + ', ' + VendEntry."External Document No."
                else
                    if StrPos(SummaryPmtTxt, Text016) = 0 then
                        // etc. not yet added
                        SummaryPmtTxt := CopyStr(SummaryPmtTxt, 1, 61) + Text017;
            if VendEntry."On Hold" = '' then begin
                VendEntry."On Hold" := 'DTA';
                VendEntry.Modify();
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure AdjustSummaryPmtText()
    begin
        // Adjust text and summary text before DTA record is written
        if SummaryPmtTxt = VendEntry."External Document No." then
            // Only one pmt.
            SummaryPmtTxt := ''
        else
            if StrPos("Gen. Journal Line".Description, VendEntry."External Document No.") > 0 then
                // Remove Ext. No in text
                "Gen. Journal Line".Description := CopyStr("Gen. Journal Line".Description, 1, StrPos("Gen. Journal Line".Description, VendEntry."External Document No.") - 3);
    end;

    [Scope('OnPrem')]
    procedure WriteEzagRecord(_Vendor: Code[20]; _VendBank: Code[20]; _Curr: Code[10]; _Amt: Decimal; _PostDate: Date; _DocNo: Code[20]; _AppDocNo: Code[20]; _PostTxt: Text[100]; _PostTxt2: Text[70])
    begin
        TotalNoOfRecs := TotalNoOfRecs + 1;
        Window.Update(1, TotalNoOfRecs);
        Window.Update(2, _Vendor);

        // All lines same posting date?
        if FirstPostingDate = 0D then  // Save first
            FirstPostingDate := _PostDate;
        if FirstPostingDate <> _PostDate then
            Error(Text018, FirstPostingDate, _PostDate);

        if not Vendor.Get(_Vendor) then  // for Address
            Error(Text020, _Vendor);

        Vendor.TestField(Name);
        Vendor.TestField(City);

        if not VendBank.Get(_Vendor, _VendBank) then  // Bank connection
            Error(Text011, _VendBank, _Vendor);

        xISO := DTAMgt.GetIsoCurrencyCode(_Curr);
        RecType := DTAMgt.GetRecordType(xISO, _Amt, _Vendor, _VendBank, 'EZAG');

        // Amt 13 digits. No thousand and decimal separator. Preceding zeros.
        AmtWoComma := Format(_Amt, 0, '<Integer><Decimals,3>');
        AmtWoComma := DelChr(AmtWoComma, '=', '.,');  // Remove decimal
        AmtWoComma := CopyStr('0000000000000', 1, 13 - StrLen(AmtWoComma)) + AmtWoComma;

        case RecType of
            22: // TA22, Post domestic
                begin
                    // Define receiver and beneficiary
                    VendBank.TestField("Giro Account No.");
                    xPostAcc := DelChr(VendBank."Giro Account No.", '=', '-');  // - remove
                    if VendBank."Bank Account No." = '' then begin  // Account of receiver
                        Vendor.TestField(Name);
                        xRecName := CopyStr(Vendor.Name, 1, 35);
                        xRecName2 := CopyStr(Vendor."Name 2", 1, 35);
                        xRecStreet := CopyStr(Vendor.Address, 1, 35);
                        xRecCity := CopyStr(Vendor.City, 1, 25);
                        xRecPostCode := CopyStr(Vendor."Post Code", 1, 4);
                        xBeneName := '';
                        xBeneName2 := '';
                        xBeneStreet := '';
                        xBeneCity := '';
                        xBenePostCode := '';
                    end else begin  // Post account at bank
                        VendBank.TestField(Name);
                        xRecName := CopyStr(VendBank.Name, 1, 35);
                        xRecName2 := CopyStr(VendBank.Address, 1, 35);
                        xRecStreet := CopyStr(VendBank."Address 2", 1, 35);
                        xRecCity := CopyStr(VendBank.City, 1, 25);
                        xRecPostCode := CopyStr(VendBank."Post Code", 1, 4);
                        xBeneName := CopyStr(Vendor.Name, 1, 35);
                        xBeneName2 := CopyStr(Vendor."Name 2", 1, 35);
                        xBeneStreet := CopyStr(Vendor.Address, 1, 35);
                        xBeneCity := CopyStr(Vendor.City, 1, 25);
                        xBenePostCode := CopyStr(Vendor."Post Code", 1, 4);
                    end;

                    PrepareControlArea('22'); // TA 22
                    if VendBank.IBAN <> '' then
                        xBankAcc := DTAMgt.IBANDELCHR(VendBank.IBAN)
                    else
                        xBankAcc := VendBank."Bank Account No.";

                    // Amount part: Pos 51 - 122, 72 chars
                    // AWä Aufgabebetrag   VWä La PC Konto  blank  Bankkonto Endbegünstigter
                    // 123 4567890123456 7 890 12 345678901 234567 89012345678901234567890123456789012
                    AmtPart := StrSubstNo(
                        '#1#×#2###########× ×#3#×CH×#4#######×      ×#5#################################',
                        xISO,
                        AmtWoComma,
                        xISO,
                        xPostAcc,
                        xBankAcc);

                    // Receiver part, 4 x 35, Pos 123 - 262, 140 Chars
                    ReceiverPart := StrSubstNo(
                        '#1#################################×#2#################################×' +
                        '#3#################################×#4########×#5#######################',
                        xRecName,
                        xRecName2,
                        xRecStreet,
                        xRecPostCode,
                        xRecCity);

                    // Beneficiary: 4 x 35, Pos 263 - 402, 140 Chars
                    BenePart := StrSubstNo(
                        '#1#################################×#2#################################×' +
                        '#3#################################×#4########×#5#######################',
                        xBeneName,
                        xBeneName2,
                        xBeneStreet,
                        xBenePostCode,
                        xBeneCity);

                    // Message, 4 x 35Z, Pos 403 - 542, 140 Chars
                    PrepareMessage(_PostTxt, _PostTxt2);

                    // Originator, blank, Pos 543 - 700, 158
                    OriginatorPart := PadStr(' ', 158);
                    // TA22 write record 50 + 72 + 140 + 140 + 140 + 158 = 700 chars
                    Filename.Write(CheckLine(ControlArea + AmtPart + ReceiverPart + BenePart + MessagePart + OriginatorPart, 700));
                end;  // TA22, EZ Post
            24: // TA24, Payment order domestic
                begin
                    // Prepare fields
                    Vendor.TestField(Name);
                    Vendor.TestField("Post Code");
                    Vendor.TestField(City);

                    PrepareControlArea('24'); // TA

                    // Amount part: Pos 51 - 122, 72 chars
                    // AWä Aufgabebetrag   VWä La blank15         blank34                            b
                    // 123 4567890123456 7 890 12 345678901234567 8901234567890123456789012345678901 2
                    AmtPart := StrSubstNo(
                        '#1#×#2###########× ×#3#×CH×               ×                                  × ',
                        xISO,
                        AmtWoComma,
                        xISO);

                    // Receiver part, 4 x 35, Pos 123 - 262, 140 Chars
                    ReceiverPart := StrSubstNo(
                        '#1#################################×#2#################################×' +
                        '#3#################################×#4########×#5#######################',
                        CopyStr(Vendor.Name, 1, 35),
                        CopyStr(Vendor."Name 2", 1, 35),
                        CopyStr(Vendor.Address, 1, 35),
                        CopyStr(Vendor."Post Code", 1, 4),
                        CopyStr(Vendor.City, 1, 25));

                    // Bene, blank, Pos 263 - 402, 140 Chars
                    BenePart := PadStr(' ', 140);

                    // Message, 4 x 35Z, Pos 403 - 542, 140 Chars
                    PrepareMessage(_PostTxt, _PostTxt2);

                    // Originator, leer, Pos 543 - 700, 158 Char
                    OriginatorPart := PadStr(' ', 158);
                    Filename.Write(CheckLine(ControlArea + AmtPart + ReceiverPart + BenePart + MessagePart + OriginatorPart, 700));
                end;  // TA24, EZ Post
            27:  // TA27, Clearing payment domestic
                begin
                    // Prepare fields
                    Vendor.TestField(Name);
                    Vendor.TestField("Post Code");
                    Vendor.TestField(City);

                    CheckVendBankAccount(VendBank);
                    VendBank.TestField("Clearing No.");
                    xClearing := '  ' + VendBank."Clearing No." + CopyStr('000000', 1, 6 - StrLen(VendBank."Clearing No."));

                    if VendBank.IBAN <> '' then begin
                        if not (CopyStr(DTAMgt.IBANDELCHR(VendBank.IBAN), 1, 2) in ['CH', 'LI']) then
                            Error(Text060, Vendor."No.");
                        xBankAcc := DTAMgt.IBANDELCHR(VendBank.IBAN);
                        if xISO <> 'CHF' then
                            xClearing := VendBank."SWIFT Code"
                        else
                            xClearing := ''; // Clearing should be Empty on CHF IBAN
                    end else
                        xBankAcc := VendBank."Bank Account No.";

                    PrepareControlArea('27'); // TA

                    // Amount part: Pos 51 - 122, 72 chars
                    // AWä Aufgabebetrag   VWä La Clearing        Bankkonto Endbegünstigter
                    // 123 4567890123456 7 890 12 345678901234567 89012345678901234567890123456789012
                    AmtPart := StrSubstNo(
                        '#1#×#2###########× ×#3#×CH×#4#############×#5#################################',
                        xISO,
                        AmtWoComma,
                        xISO,
                        xClearing,
                        xBankAcc);

                    // Receiver part, 4 x 35, Pos 123 - 262, 140 Chars
                    ReceiverPart := PadStr(' ', 140);

                    // Beneficiary: 4 x 35, Pos 263 - 402, 140 Chars
                    BenePart := StrSubstNo(
                        '#1#################################×#2#################################×' +
                        '#3#################################×#4########×#5#######################',
                        CopyStr(Vendor.Name, 1, 35),
                        CopyStr(Vendor."Name 2", 1, 35),
                        CopyStr(Vendor.Address, 1, 35),
                        CopyStr(Vendor."Post Code", 1, 4),
                        CopyStr(Vendor.City, 1, 25));

                    // Message, 4 x 35Z, Pos 403 - 542, 140 Chars
                    PrepareMessage(_PostTxt, _PostTxt2);

                    // Originator, blank, Pos 543 - 700, 158
                    OriginatorPart := PadStr(' ', 158);
                    Filename.Write(CheckLine(ControlArea + AmtPart + ReceiverPart + BenePart + MessagePart + OriginatorPart, 700));
                end;  // TA27, EZ Bank
            28: // TA28, ESR payment
                begin
                    // Prepare fields
                    if not TestFile then begin
                        if _AppDocNo = '' then
                            Error(Text029, _DocNo, _Vendor);

                        VendEntry.SetCurrentKey("Document No.");
                        VendEntry.SetRange("Document Type", VendEntry."Document Type"::Invoice);
                        VendEntry.SetRange("Document No.", _AppDocNo);
                        VendEntry.SetRange("Vendor No.", _Vendor);
                        if not VendEntry.FindFirst() then
                            Error(Text031, _AppDocNo, _Vendor);

                        VendBank.TestField("ESR Account No.");
                        VendBank.TestField("ESR Type");  // Option not blank

                        VendEntry.CalcFields("Amount (LCY)");
                        if (VendBank."Payment Form" = VendBank."Payment Form"::ESR) and
                           (VendBank."ESR Type" = VendBank."ESR Type"::"5/15") and
                           (_Amt <> -VendEntry."Amount (LCY)")
                        then
                            Error(Text032, _Amt, -VendEntry."Amount (LCY)");
                    end;

                    // Reference number 5/15
                    if VendBank."ESR Type" = VendBank."ESR Type"::"5/15" then begin
                        xEsrAcc := '0000' + VendBank."ESR Account No.";
                        xRefNo := CopyStr(VendEntry."Reference No.", 1, 15);
                        if StrLen(xRefNo) <> 15 then
                            Error(Text035, _AppDocNo, _Vendor, 15);

                        xRefNo := '000000000000' + xRefNo;
                        xChkDig := CopyStr(VendEntry."Reference No.", 17, 2);
                    end;

                    // 9/27
                    if VendBank."ESR Type" = VendBank."ESR Type"::"9/27" then begin
                        xEsrAcc := DelChr(VendBank."ESR Account No.", '=', '-');  // remove '-'
                        xRefNo := VendEntry."Reference No.";
                        xChkDig := '';

                        if StrLen(VendEntry."Reference No.") <> 27 then
                            Error(Text035, _AppDocNo, _Vendor, 27);
                    end;

                    // 9/16
                    if VendBank."ESR Type" = VendBank."ESR Type"::"9/16" then begin
                        xEsrAcc := DelChr(VendBank."ESR Account No.", '=', '-');  // remove '-'
                        xRefNo := '00000000000' + VendEntry."Reference No.";
                        xChkDig := '';

                        if StrLen(VendEntry."Reference No.") <> 16 then
                            Error(Text035, _AppDocNo, _Vendor, 16);
                    end;

                    PrepareControlArea('28'); // TA

                    // Amount part: Pos 51 - 110, 60 Char
                    // AWä Aufgabebetrag   VWä La PZ ESR Kto   Referenznr (27)
                    // 123 4567890123456 7 890 12 34 567890123 456789012345678901234567890
                    AmtPart := StrSubstNo(
                        '#1#×#2###########× ×#3#×CH×#4×#5#######×#6#########################',
                        xISO,
                        AmtWoComma,
                        xISO,
                        xChkDig,
                        xEsrAcc,
                        xRefNo);

                    // TA28 write record 50 + 60 + 590 = 700 Char
                    Filename.Write(CheckLine(ControlArea + AmtPart + PadStr(' ', 590), 700));
                end;  // TA28, ESR/ESR+
            32: // TA32, Postgiro Foreign
                begin
                    // Prepare fields
                    Vendor.TestField(Name);
                    Vendor.TestField("Post Code");
                    Vendor.TestField(City);
                    CheckVendBankAccount(VendBank);

                    CheckCountryCode();

                    if VendBank.IBAN <> '' then begin
                        if CopyStr(DTAMgt.IBANDELCHR(VendBank.IBAN), 1, 2) in ['CH', 'LI'] then
                            Error(Text061, Vendor."No.");
                        xBankAcc := DTAMgt.IBANDELCHR(VendBank.IBAN);
                    end else
                        xBankAcc := VendBank."Bank Account No.";

                    PrepareControlArea('32'); // TA

                    // Amount part: Pos 51 - 122, 72 chars
                    // AWä Aufgabebetrag   VWä La Res             Postkonto
                    // 123 4567890123456 7 890 12 345678901234567 89012345678901234567890123456789012
                    AmtPart := StrSubstNo(
                        '#1#×#2###########× ×#3#×#4×#5#############×#6#################################',
                        xISO,
                        AmtWoComma,
                        xISO,
                        Country."EU Country/Region Code",
                        PadStr(' ', 15),
                        xBankAcc);

                    // Receiver part, 4 x 35, Pos 123 - 262, 140 Chars
                    ReceiverPart := StrSubstNo(
                        '#1#################################×#2#################################×' +
                        '#3#################################×#4########×#5#######################',
                        CopyStr(Vendor.Name, 1, 35),
                        CopyStr(Vendor."Name 2", 1, 35),
                        CopyStr(Vendor.Address, 1, 35),
                        CopyStr(Vendor."Post Code", 1, 10),
                        CopyStr(Vendor.City, 1, 25));

                    // Beneficiary: 4 x 35, Pos 263 - 402, 140 Chars
                    BenePart := PadStr(' ', 140);

                    // Message, 4 x 35Z, Pos 403 - 542, 140 Chars
                    PrepareMessage(_PostTxt, _PostTxt2);

                    // Originator, blank, Pos 543 - 700, 158
                    OriginatorPart := 'BEN' + PadStr(' ', 155);  // BEN = Charge paid by receiver
                    Filename.Write(CheckLine(ControlArea + AmtPart + ReceiverPart + BenePart + MessagePart + OriginatorPart, 700));
                end;  // TA32, Postgiro foreign
            34: // TA34, Post remittance foreign
                begin
                    // Prepare fields
                    Vendor.TestField(Name);
                    Vendor.TestField("Post Code");
                    Vendor.TestField(City);

                    CheckCountryCode();

                    PrepareControlArea('34'); // TA

                    // Amount part: Pos 51 - 122, 72 chars
                    // AWä Aufgabebetrag   VWä La Res (leer)      Res (leer)
                    // 123 4567890123456 7 890 12 345678901234567 89012345678901234567890123456789012
                    AmtPart := StrSubstNo(
                        '#1#×#2###########× ×#3#×#4×#5#############×#6#################################',
                        xISO,
                        AmtWoComma,
                        xISO,
                        Country."EU Country/Region Code",
                        PadStr(' ', 15),
                        PadStr(' ', 35));

                    // Receiver part, 4 x 35, Pos 123 - 262, 140 Chars
                    ReceiverPart := StrSubstNo(
                        '#1#################################×#2#################################×' +
                        '#3#################################×#4########×#5#######################',
                        CopyStr(Vendor.Name, 1, 35),
                        CopyStr(Vendor."Name 2", 1, 35),
                        CopyStr(Vendor.Address, 1, 35),
                        CopyStr(Vendor."Post Code", 1, 10),
                        CopyStr(Vendor.City, 1, 25));

                    // Beneficiary: 4 x 35, Pos 263 - 402, 140 Chars
                    BenePart := PadStr(' ', 140);

                    // Message, 4 x 35Z, Pos 403 - 542, 140 Chars
                    PrepareMessage(_PostTxt, _PostTxt2);

                    // Originator, blank, Pos 543 - 700, 158
                    OriginatorPart := 'BEN' + PadStr(' ', 155);  // BEN = Charge paid by receiver
                    Filename.Write(CheckLine(ControlArea + AmtPart + ReceiverPart + BenePart + MessagePart + OriginatorPart, 700));
                end;  // TA34, Postgiro foreign
            37: // TA37, Bank paiment foreign
                begin
                    // Prepare fields
                    Vendor.TestField(Name);
                    Vendor.TestField("Post Code");
                    Vendor.TestField(City);
                    CheckVendBankAccount(VendBank);

                    CheckCountryCode();

                    if VendBank."SWIFT Code" <> '' then begin
                        VendBank.TestField(Name);
                        xClearing := VendBank."SWIFT Code"
                    end else
                        xClearing := VendBank."Bank Identifier Code";

                    if VendBank.IBAN <> '' then begin
                        if CopyStr(DTAMgt.IBANDELCHR(VendBank.IBAN), 1, 2) in ['CH', 'LI'] then
                            Error(Text061, Vendor."No.");
                        xBankAcc := DTAMgt.IBANDELCHR(VendBank.IBAN);
                    end else
                        xBankAcc := VendBank."Bank Account No.";

                    PrepareControlArea('37'); // TA

                    // Amount part: Pos 51 - 122, 72 chars
                    // AWä Aufgabebetrag   VWä La BLZ/Swift       Kontonummer
                    // 123 4567890123456 7 890 12 345678901234567 89012345678901234567890123456789012
                    AmtPart := StrSubstNo(
                        '#1#×#2###########× ×#3#×#4×#5#############×#6#################################',
                        xISO,
                        AmtWoComma,
                        xISO,
                        Country."EU Country/Region Code",
                        xClearing,
                        xBankAcc);

                    // Receiver part, 4 x 35, Pos 123 - 262, 140 Chars
                    ReceiverPart := StrSubstNo(
                        '#1#################################×#2#################################×' +
                        '#3#################################×#4########×#5#######################',
                        CopyStr(VendBank.Name, 1, 35),
                        CopyStr(VendBank.Address, 1, 35),
                        CopyStr(VendBank."Address 2", 1, 35),
                        CopyStr(VendBank."Post Code", 1, 10),
                        CopyStr(VendBank.City, 1, 25));

                    // Beneficiary: 4 x 35, Pos 263 - 402, 140 Chars
                    BenePart := StrSubstNo(
                        '#1#################################×#2#################################×' +
                        '#3#################################×#4########×#5#######################',
                        CopyStr(Vendor.Name, 1, 35),
                        CopyStr(Vendor."Name 2", 1, 35),
                        CopyStr(Vendor.Address, 1, 35),
                        CopyStr(Vendor."Post Code", 1, 10),
                        CopyStr(Vendor.City, 1, 25));

                    // Message, 4 x 35Z, Pos 403 - 542, 140 Chars
                    PrepareMessage(_PostTxt, _PostTxt2);

                    // Originator, blank, Pos 543 - 700, 158
                    OriginatorPart := 'BEN' + PadStr(' ', 155);  // BEN = Charge paid by receiver
                    Filename.Write(CheckLine(ControlArea + AmtPart + ReceiverPart + BenePart + MessagePart + OriginatorPart, 700));
                end;  // TA32, Postgiro foreign
        end;

        // *** Add total amt and recs per currency
        i := 1;
        while (iCurrCode[i] <> xISO) and (i < 16) and (iCurrCode[i] <> '') do
            i := i + 1;

        if i = 16 then
            Error(Text044);

        iCurrCode[i] := xISO;
        iNo[i] := iNo[i] + 1;  // No of Records
        iAmt[i] := iAmt[i] + _Amt;  // Amount (FCY)
    end;

    [Scope('OnPrem')]
    procedure WriteTotalRecord()
    begin
        // *** Total record
        PrepareControlArea('97'); // TA

        // 15 currency elements at 22 (3 x ISO, 6 x NoOfRecs + 13 x total amt)

        i := 1;
        for i := 1 to 15 do begin
            if iCurrCode[i] = '' then
                iCurrCode[i] := '000';

            iAmt[i] := iAmt[i] * 100;

            CurrencyElement[i] :=
              iCurrCode[i] +
              CopyStr('000000', 1, 6 - StrLen(Format(iNo[i]))) + // preceding zeros
              Format(iNo[i]) + // preceding zeros
              CopyStr('0000000000000', 1, 13 - StrLen(Format(iAmt[i], 0, '<Integer>'))) +
              Format(iAmt[i], 0, '<Integer>');
        end;

        // 50 + 15*21 + 35 = 400 Chars

        Filename.Write(
          CheckLine(ControlArea + CurrencyElement[1] + CurrencyElement[2] + CurrencyElement[3] +
            CurrencyElement[4] + CurrencyElement[5] + CurrencyElement[6] +
            CurrencyElement[7] + CurrencyElement[8] + CurrencyElement[9] +
            CurrencyElement[10] + CurrencyElement[11] + CurrencyElement[12] +
            CurrencyElement[13] + CurrencyElement[14] + CurrencyElement[15] +
            PadStr(' ', 320), 700));
    end;

    [Scope('OnPrem')]
    procedure PrepareControlArea(_TA: Code[2])
    var
        FileId: Text[3];
    begin
        // Header, 1 - 50, 50 Char
        // 123 456789 01234 5 678901234 567890123 45 67 890123 45 6 7890
        if _TA = '00' then begin
            FileId := '543';  // Navision identification
            if DiscTransfer then
                FileId := '036';
        end else
            FileId := '036';

        ControlArea := StrSubstNo(
            '#1#×#2####×00000×1×#3#######×#4#######×#5×#6×#7####×00×0×0000',
            FileId, xValuta,
            DelChr(DtaSetup."EZAG Debit Account No.", '=', '-'),
            DelChr(DtaSetup."EZAG Charges Account No.", '=', '-'),
            DtaSetup."Last EZAG Order No.",
            _TA,
            TaLineno);

        TaLineno := IncStr(TaLineno);  // Lineno. for next rec. Header starts with 000000
    end;

    [Scope('OnPrem')]
    procedure PrepareMessage(_PostTxt: Text[100]; _PostTxt2: Text[70])
    begin
        // Message: 4 x 35Z, Pos 403 - 542, 140 Char
        MessagePart := StrSubstNo(
            '#1#################################×#2#################################×' +
            '#3#################################×#4#################################',
            CopyStr(_PostTxt, 1, 35),
            CopyStr(_PostTxt, 36, 35),
            CopyStr(_PostTxt2, 1, 35),
            CopyStr(_PostTxt2, 36, 35));
    end;

    [Scope('OnPrem')]
    procedure CheckCountryCode()
    begin
        if not Country.Get(VendBank."Country/Region Code") then
            Error(Text040, VendBank."Country/Region Code", Vendor."No.");

        if StrLen(Country."EU Country/Region Code") <> 2 then
            Error(Text041, VendBank."Country/Region Code", Vendor."No.");
    end;

    [Scope('OnPrem')]
    procedure CheckLine(_Line: Text[1024]; _Length: Integer): Text[1024]
    begin
        _Line := DelChr(_Line, '=', '×');
        if not (StrLen(_Line) = _Length) then
            Error(Text070, "Gen. Journal Line"."Line No.");
        exit(_Line);
    end;

    [Scope('OnPrem')]
    procedure WriteTestFile(var _DtaSetup: Record "DTA Setup")
    var
        TestVendBankAcc: Record "Vendor Bank Account";
        TestVendor: Record Vendor;
        TestDocNo: Code[10];
        TestAmt: Decimal;
        TestTxt: Text[70];
    begin
        if not Confirm(Text047) then
            exit;

        Window.Open(
          Text050 +
          Text051 +
          Text052);

        DtaSetup.Get(_DtaSetup."Bank Code");
        DtaSetup.Copy(DtaSetup);
        xValuta := Format(CalcDate('<1W>', Today), 6, '<year><month,2><day,2>');
        PrepareFile();

        TestDocNo := 'TEST0000';
        TestAmt := 1.0;
        TestFile := true;  // Bei ESR/ESR+ Ref. Nr von dummy record

        TestVendBankAcc.Reset();
        if TestVendBankAcc.FindSet() then
            repeat
                if not ((TestVendBankAcc."Vendor No." = '') or
                        (TestVendBankAcc."ESR Type" = TestVendBankAcc."ESR Type"::"5/15") or
                        ((TestVendBankAcc."Payment Form" in [TestVendBankAcc."Payment Form"::ESR, TestVendBankAcc."Payment Form"::"ESR+"]) and
                         (TestVendBankAcc."ESR Account No." = '')))
                then begin
                    if not TestVendor.Get(TestVendBankAcc."Vendor No.") then
                        Error(Text055, TestVendBankAcc."Vendor No.", TestVendBankAcc.Code);

                    TestDocNo := IncStr(TestDocNo);
                    TestTxt := CopyStr(Text056 + TestVendBankAcc."Vendor No." + ' ' + TestVendBankAcc.Code + ' ' + Format(TestVendBankAcc."Payment Form"), 1, 60);

                    case TestVendBankAcc."ESR Type" of
                        TestVendBankAcc."ESR Type"::"9/27":
                            VendEntry."Reference No." := '330002000000000097010075184';
                        TestVendBankAcc."ESR Type"::"9/16":
                            VendEntry."Reference No." := '4097160015679962';
                    end;

                    WriteEzagRecord(
                        TestVendBankAcc."Vendor No.", TestVendBankAcc.Code, TestVendor."Currency Code", TestAmt,
                        0D, TestDocNo, '', TestTxt, '');
                end;
            until TestVendBankAcc.Next() = 0;

        WriteTotalRecord();

        Filename.Close();
        Window.Close();

        Message(Text057, _DtaSetup."EZAG Filename", _DtaSetup."EZAG File Folder", TotalNoOfRecs);
    end;

    local procedure CheckVendBankAccount(VendorBankAccount: Record "Vendor Bank Account")
    begin
        if (VendorBankAccount.IBAN = '') and (VendorBankAccount."Bank Account No." = '') then
            Error(Text062, VendorBankAccount."Vendor No.", VendorBankAccount.Code);
    end;
}

