// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.IO;
using System.Telemetry;

report 3010541 "DTA File"
{
    Caption = 'DTA File';
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
                if ("Account No." = '') or (Amount = 0) then  // incomplete lne
                    CurrReport.Skip();

                ClearVars();
                CheckDebitBank();

                if not VendBank.Get("Account No.", "Recipient Bank Account") then  // Bank connection
                    Error(Text007, "Recipient Bank Account", "Account No.");

                TotalLCY := TotalLCY + "Amount (LCY)";  // For message

                // Summary Pmt, if not ESR, same Account, Bank, Debit Bank, Currency
                SummaryPmtAmt := SummaryPmtAmt + Amount;
                NoOfGlLines := NoOfGlLines + 1;
                PrepareSummaryPmt();

                // Write DTA Rec. - or add amt. for summary pmt.
                NextGlLine.Copy("Gen. Journal Line");
                if (NextGlLine.Next() = 0) or
                   (SummaryPerVendor = false) or
                   (NextGlLine."Account No." <> "Account No.") or
                   (NextGlLine."Recipient Bank Account" <> "Recipient Bank Account") or
                   (NextGlLine."Debit Bank" <> "Debit Bank") or
                   (NextGlLine."Currency Code" <> "Currency Code") or
                   (VendBank."Payment Form" in [VendBank."Payment Form"::ESR, VendBank."Payment Form"::"ESR+"])
                then begin
                    AdjustSummaryPmtText();

                    DtaRecordWrite(
                      "Account No.", "Recipient Bank Account", "Currency Code", SummaryPmtAmt,
                      "Posting Date", "Document No.", "Applies-to Doc. No.", Description,
                      CopyStr(SummaryPmtTxt, 1, 60));

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
                // Prepare file, check setup
                DtaMgt.CheckSetup();
                PrepareFile(FileBank."Bank Code");

                // Key: Posting Date, Clearing
                SetRange("Account Type", "Account Type"::Vendor);
                SetRange("Document Type", "Document Type"::Payment);
                SetFilter(Amount, '<>0');
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
                    field("FileBank.""Bank Code"""; FileBank."Bank Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'DTA Bank for File';
                        Lookup = true;
                        TableRelation = "DTA Setup";
                        ToolTip = 'Specifies the DTA bank to which the information for the file name and backup copy are to be transferred.';
                    }
                    field(SummaryPerVendor; SummaryPerVendor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Combined payment for vendor';
                        ToolTip = 'Specifies if you want the payment lines to be combined for the same vendor, currency, bank, and debit bank.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            // Suggest bank for file
            if FileBank."Bank Code" = '' then begin
                FileBank.SetRange("DTA Main Bank", true);
                FileBank.SetRange("DTA/EZAG", FileBank."DTA/EZAG"::DTA);
                if FileBank.FindFirst() then;
            end;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUsage('0000KED', 'DTA Local CH Functionality', 'DTA File report');
        Filename.Close();

        if FileBank."File Format" = FileBank."File Format"::"Without CR/LF" then
            GeneralMgt.RemoveCrLf(FileBank."DTA File Folder" + FileBank."DTA Filename", ServerTempFilename, false)
        else
            DownloadToFile();

        if FileBank."Backup Copy" then begin
            FileBank.LockTable();
            FileBank."Last Backup No." := IncStr(FileBank."Last Backup No.");
            FileBank.Modify();
            BackupFilename := FileBank."Backup Folder" + 'DTA' + FileBank."Last Backup No." + '.BAK';
            if FileBank."File Format" = FileBank."File Format"::"With CR/LF" then
                FileMgt.DownloadHandler(ServerTempFilename, '', '', '', BackupFilename);
        end;

        Message(Text006, NoOfGlLines, GlSetup."LCY Code",
          Format(TotalLCY, 0, '<integer thousand><decimals,3>'), TotalNoOfRecs);
    end;

    var
        Text006: Label 'Total of %1 records for %2 %3 processed. %4 payment records created.';
        Text007: Label 'No bank connection found with bank code %1 for vendor %2.';
        Text010: Label 'The sender IDs and customer IDs of all debit banks, that is, DTA bank %1 and %2, must be identical.\If necessary, generate multiple files for your payments.';
        Text013: Label 'Processing Line:        #1###########\';
        Text014: Label 'Vendor Number:          #2###########';
        Text015: Label 'etc.';
        Text016: Label ' etc.';
        Text017: Label 'The posting date %1 is also the credit date and must be equal or later than the workdate.\Vendor: %2, application doc. no: %3.', Comment = 'Parameter 1 - date, 2 - vendor number, 3 - document number.';
        Text019: Label 'The payments have different posting dates. (%1 and %2)\If necessary, generate multiple files for your payments.';
        Text020: Label 'Vendor %1 is not defined in the table vendor.';
        Text029: Label 'ESR and ESR+ must have an application doc. no.\It is missing for document %1, vendor %2.';
        Text031: Label 'Vendor entry for invoice %1 of vendor %2 not found.';
        Text032: Label 'The amounts in the vendor ledger entry and the G/L journal must be identical for payment type ESR.\G/L journal: %1, vendor entry: %2.';
        Text035: Label 'Reference no. for invoice %1 of vendor %2 must have %3 digits according to the vendor bank definition.';
        Text046: Label 'This batch job writes a DTA Testfile to check the vendor banks. \For each vendor''s bank with payment type EZ Post, EZ Bank, Foreign bank and SWIFT, a record with 1.00 in the vendor''s currency is written.\Do you want to continue?';
        Text049: Label 'DTA Testfile\';
        Text050: Label 'Vendor     #1########\';
        Text051: Label 'Records    #2########';
        Text054: Label 'Vendor %1 for bank %2 not found.';
        Text055: Label 'DTA Account Test ';
        Text056: Label 'File "%1" for the account verification has been created successfully. It is now saved in the folder "%2".\\%3 records with CHF 1.00 each have been processed.', Comment = 'Parameter 1 - file name, 2 - file folder, 3 - number.';
        Text060: Label 'Error, there was no DTA record created.\%1.';
        Text061: Label 'The Amount off %1 is %2, it can have only a maximum of 2 decimal places.';
        Text063: Label 'IBAN %1 is to long.';
        Text070: Label 'The Entry %1 with Account No. %2 generates a wrong DTA Line, please check.';
        FileBank: Record "DTA Setup";
        DtaSetup: Record "DTA Setup";
        GlSetup: Record "General Ledger Setup";
        BankDirectory: Record "Bank Directory";
        VendBank: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        VendEntry: Record "Vendor Ledger Entry";
        NextGlLine: Record "Gen. Journal Line";
        DtaMgt: Codeunit DtaMgt;
        GeneralMgt: Codeunit GeneralMgt;
        FileMgt: Codeunit "File Management";
        Window: Dialog;
        Filename: File;
        TestFile: Boolean;
        SummaryPerVendor: Boolean;
        RecordText: array[10] of Text[280];
        FileText: array[10] of Text[128];
        BackupFilename: Text;
        FirstPostingDate: Date;
        LineNo: Code[5];
        TransNo: Code[11];
        xBenClr: Code[12];
        SummaryPmtAmt: Decimal;
        SummaryPmtTxt: Text[80];
        AmtWithComma: Code[16];
        ValutaCreation: array[2] of Text[10];
        xEsrAcc: Code[9];
        xVendoradr: array[4] of Code[24];
        xAcc: Code[34];
        xRefNo: Code[27];
        xChkDig: Code[2];
        xISO: Code[3];
        xForeignBankAccType: Code[1];
        xForeignBankAcc: Text[21];
        xForeignBankAdr: array[4] of Text[35];
        xDtaAccNo: Code[24];
        NoOfGlLines: Integer;
        TotalNoOfRecs: Integer;
        TotalLCY: Decimal;
        TotalAmt: Decimal;
        RecType: Integer;
        i: Integer;
        ServerTempFilename: Text[1024];

    local procedure CheckDebitBank()
    begin
        // Get Debit Bank
        "Gen. Journal Line".TestField("Debit Bank");
        // Only Pmt. for Debit Bank with identical sender and customer id
        DtaSetup.Get("Gen. Journal Line"."Debit Bank");
        if (FileBank."DTA Sender ID" <> DtaSetup."DTA Sender ID") or
           (FileBank."DTA Customer ID" <> DtaSetup."DTA Customer ID")
        then
            Error(Text010, FileBank."Bank Code", DtaSetup."Bank Code");
    end;

    local procedure PrepareFile(_Bankcode: Code[20])
    begin
        // Create file
        GlSetup.Get();
        FileBank.Get(_Bankcode);
        FileBank.TestField("DTA/EZAG", 0);  // DTA
        FileBank.TestField("DTA File Folder");
        FileBank.TestField("DTA Filename");

        Filename.TextMode := true;
        Filename.WriteMode := true;
        ServerTempFilename := FileMgt.ServerTempFileName('');
        Filename.Create(ServerTempFilename, TEXTENCODING::Windows);

        Window.Open(Text013 + // Processing line
          Text014); // Vendor no #1

        LineNo := '00000';
        TransNo := '00000000000';
    end;

    local procedure PrepareSummaryPmt()
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
                if StrLen(SummaryPmtTxt) < 50 then
                    // Additional lines with free space: + Ext. No.
                    SummaryPmtTxt := CopyStr(SummaryPmtTxt + ', ' + VendEntry."External Document No.", 1, 60)
                else
                    if StrPos(SummaryPmtTxt, Text015) = 0 then
                        // etc. not yet added
                        SummaryPmtTxt := CopyStr(SummaryPmtTxt, 1, 51) + Text016;
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
        if SummaryPmtTxt = VendEntry."External Document No." then // Only one Pmt.
            SummaryPmtTxt := ''
        else
            if StrPos("Gen. Journal Line".Description, VendEntry."External Document No.") > 0 then // Remove Ext. No in text
                "Gen. Journal Line".Description := CopyStr("Gen. Journal Line".Description, 1, StrPos("Gen. Journal Line".Description, VendEntry."External Document No.") - 3);
    end;

    local procedure DtaRecordWrite(_Vendor: Code[20]; _VendBank: Code[20]; _Curr: Code[10]; _Amt: Decimal; _PostDate: Date; _DocNo: Code[20]; _AppDocNo: Code[20]; _PostTxt: Text[100]; _PostTxt2: Text[60])
    var
        PostTxt: array[2] of Text[100];
    begin
        if ((_Amt * 100) mod 1) <> 0 then
            Error(Text061, _DocNo, _Amt);

        LineNo := IncStr(LineNo);
        TransNo := IncStr(TransNo);
        TotalAmt := TotalAmt + _Amt;  // For total rec
        TotalNoOfRecs := TotalNoOfRecs + 1;
        Window.Update(1, TotalNoOfRecs);
        Window.Update(2, _Vendor);

        // CHeck posting date
        if _PostDate < Today then
            Error(Text017, _PostDate, _Vendor, _AppDocNo);

        // All lines same posting date?
        if FirstPostingDate = 0D then  // Save first
            FirstPostingDate := _PostDate;
        if FirstPostingDate <> _PostDate then
            Error(Text019, FirstPostingDate, _PostDate);

        if not Vendor.Get(_Vendor) then  // for Address
            Error(Text020, _Vendor);

        Vendor.TestField(Name);
        Vendor.TestField(City);

        if not VendBank.Get(_Vendor, _VendBank) then  // Bank connection
            Error(Text007, _VendBank, _Vendor);

        xISO := DtaMgt.GetIsoCurrencyCode(_Curr);
        RecType := DtaMgt.GetRecordType(xISO, _Amt, _Vendor, _VendBank, 'DTA');

        // Format amount. Without ThousandSep, Decimal Comma
        AmtWithComma := Format(_Amt, 0, '<Integer><Decimals,3>');
        AmtWithComma := ConvertStr(AmtWithComma, '.', ',');  // Decimal point > Decimal comma

        // Perpare Date
        ValutaCreation[1] := Format(_PostDate, 6, '<year><month,2><day,2>'); // Debit
        ValutaCreation[2] := Format(Today, 6, '<year><month,2><day,2>');     // Creation Date

        if StrLen(DtaSetup."DTA Sender IBAN") <> 0 then
            xDtaAccNo := DtaMgt.IBANDELCHR(DtaSetup."DTA Sender IBAN")
        else
            xDtaAccNo := DtaSetup."DTA Debit Acc. No.";

        // Generate Line on DTA File
        case RecType of
            826:
                begin
                    // ***  T A   8 2 6  - ESR Payment only CHF
                    // -------------------------------
                    xVendoradr[1] := CopyStr(Vendor.Name, 1, 20);
                    xVendoradr[2] := CopyStr(Vendor.Address, 1, 20);
                    xVendoradr[3] := CopyStr(Vendor."Address 2", 1, 20);
                    xVendoradr[4] := CopyStr(Vendor."Post Code" + ' ' + Vendor.City, 1, 20);

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
                            Message(Text032, _Amt, -VendEntry."Amount (LCY)");
                    end;

                    // Extract ESR
                    FillEsrVars(_Vendor, _AppDocNo);

                    RType826(ValutaCreation, DtaSetup, LineNo, TransNo, xDtaAccNo, AmtWithComma, xEsrAcc,
                      xVendoradr, xRefNo, xChkDig, FileText);

                    // *** TA826 Datensatz schreiben, 3 x je 128 Zeichen + CR/LF

                    for i := 1 to ArrayLen(FileText) do
                        if FileText[i] <> '' then
                            Filename.Write(FileText[i]);
                end;   // End TA 826 ESR
            827:
                begin
                    // ***  T A   8 2 7  - Post / Bank Domestic
                    // ----------------------------------------
                    if VendBank."Payment Form" = VendBank."Payment Form"::"Post Payment Domestic" then begin  // PC Konto
                        VendBank.TestField("Giro Account No.");
                        xBenClr := '';
                        xAcc := VendBank."Giro Account No.";
                    end else begin
                        VendBank.TestField("Clearing No.");
                        VendBank.TestField("Bank Account No.");
                        xBenClr := DelChr(VendBank."Clearing No.", '<', '0');  // Remove leading Zeros
                        if VendBank.IBAN <> '' then begin
                            xAcc := DtaMgt.IBANDELCHR(VendBank.IBAN);

                            if StrLen(xAcc) > 21 then
                                Error(Text063, xAcc);
                        end else
                            xAcc := VendBank."Bank Account No.";
                    end;

                    xVendoradr[1] := CopyStr(Vendor.Name, 1, 24);
                    xVendoradr[2] := CopyStr(Vendor.Address, 1, 24);
                    xVendoradr[3] := CopyStr(Vendor."Address 2", 1, 24);
                    xVendoradr[4] := CopyStr(Vendor."Post Code" + ' ' + Vendor.City, 1, 24);

                    RType827(ValutaCreation, xBenClr, DtaSetup, LineNo, TransNo, xDtaAccNo, AmtWithComma, xAcc,
                      xVendoradr, _PostTxt, _PostTxt2, '0', FileText);

                    // *** TA827 Datensatz schreiben, 4 x je 128 Zeichen + CR/LF
                    for i := 1 to ArrayLen(FileText) do
                        if FileText[i] <> '' then
                            Filename.Write(FileText[i]);
                end; // End TA 827 Bank/Post Inland
            830:
                begin
                    // *** T A   8 3 0  -  Abroad and FCY domestic for Vendor without IBAN and EUR ESR
                    // -------------------------------------------------------------------------------

                    xForeignBankAcc := VendBank."Bank Identifier Code";
                    if VendBank.IBAN <> '' then begin
                        xAcc := DtaMgt.IBANDELCHR(VendBank.IBAN);
                        if StrLen(xAcc) > 21 then
                            Error(Text063, xAcc);
                    end else
                        xAcc := CopyStr(VendBank."Bank Account No.", 1, 21);
                    xVendoradr[1] := CopyStr(Vendor.Name, 1, 24);
                    xVendoradr[2] := CopyStr(Vendor.Address, 1, 24);
                    xVendoradr[3] := CopyStr(Vendor."Address 2", 1, 24);
                    xVendoradr[4] := CopyStr(Vendor."Post Code" + ' ' + Vendor.City, 1, 24);

                    case VendBank."Payment Form" of
                        VendBank."Payment Form"::"Bank Payment Domestic":
                            begin
                                VendBank.TestField("Clearing No.");
                                xForeignBankAcc := VendBank."Clearing No.";
                                xForeignBankAccType := 'D';
                                xForeignBankAdr[1] := CopyStr(VendBank.Name, 1, 24);
                                xForeignBankAdr[2] := CopyStr(VendBank.Address, 1, 24);
                                xForeignBankAdr[3] := CopyStr(VendBank."Address 2", 1, 24);
                                xForeignBankAdr[4] := CopyStr(VendBank."Post Code" + ' ' + VendBank.City, 1, 24);
                            end;
                        VendBank."Payment Form"::"Post Payment Domestic":
                            begin
                                xForeignBankAcc := '9000';
                                xAcc := VendBank."Giro Account No.";
                                xForeignBankAccType := 'D';
                                BankDirectory.Get(xForeignBankAcc);
                                xForeignBankAdr[1] := CopyStr(BankDirectory.Name, 1, 24);
                                xForeignBankAdr[2] := CopyStr(BankDirectory.Address, 1, 24);
                                xForeignBankAdr[3] := CopyStr(BankDirectory."Address 2", 1, 24);
                                xForeignBankAdr[4] := CopyStr(BankDirectory."Post Code" + ' ' + BankDirectory.City, 1, 24);
                            end;
                        VendBank."Payment Form"::"SWIFT Payment Abroad":
                            begin
                                VendBank.TestField("SWIFT Code");
                                xForeignBankAccType := 'A';
                                xForeignBankAdr[1] := VendBank."SWIFT Code";
                            end;
                        VendBank."Payment Form"::"Bank Payment Abroad":
                            begin
                                xForeignBankAccType := 'D';
                                xForeignBankAdr[1] := CopyStr(VendBank.Name, 1, 24);
                                xForeignBankAdr[2] := CopyStr(VendBank.Address, 1, 24);
                                xForeignBankAdr[3] := CopyStr(VendBank."Address 2", 1, 24);
                                xForeignBankAdr[4] := CopyStr(VendBank."Post Code" + ' ' + VendBank.City, 1, 24);
                            end;
                        VendBank."Payment Form"::ESR, VendBank."Payment Form"::"ESR+":
                            begin
                                FillEsrVars(_Vendor, _AppDocNo);
                                xForeignBankAcc := '9000';
                                xAcc := xEsrAcc;
                                xForeignBankAccType := 'D';
                                BankDirectory.Get(xForeignBankAcc);
                                xForeignBankAdr[1] := CopyStr(BankDirectory.Name, 1, 24);
                                xForeignBankAdr[2] := CopyStr(BankDirectory.Address, 1, 24);
                                xForeignBankAdr[3] := CopyStr(BankDirectory."Address 2", 1, 24);
                                xForeignBankAdr[4] := CopyStr(BankDirectory."Post Code" + ' ' + BankDirectory.City, 1, 24);
                            end;
                    end;

                    Clear(PostTxt);
                    PostTxt[1] := _PostTxt;
                    PostTxt[2] := _PostTxt2;
                    RType830(ValutaCreation, DtaSetup, LineNo, TransNo, xDtaAccNo, xISO, AmtWithComma, xForeignBankAccType,
                      xForeignBankAcc, xForeignBankAdr, xAcc, xVendoradr, PostTxt, xRefNo, xChkDig, "Gen. Journal Line"."Payment Fee Code",
                      FileText);

                    // *** TA830 write record, 5 x 128 char + CR/LF
                    for i := 1 to ArrayLen(FileText) do
                        if FileText[i] <> '' then
                            Filename.Write(FileText[i]);
                end;   // End TA 830 Ausland
            836:
                begin
                    // *** T A   8 3 6  -  Abroad and FCY domestic for Vendor with IBAN
                    // ----------------------------------------------------------------
                    xAcc := DtaMgt.IBANDELCHR(VendBank.IBAN);

                    if VendBank."Payment Form" = VendBank."Payment Form"::"SWIFT Payment Abroad" then begin
                        VendBank.TestField("SWIFT Code");
                        xForeignBankAccType := 'A';
                        xForeignBankAdr[1] := VendBank."SWIFT Code";
                    end else begin   // Foreign Bank
                        xForeignBankAccType := 'D';
                        xForeignBankAdr[1] := CopyStr(VendBank.Name, 1, 35);
                        xForeignBankAdr[2] := CopyStr(VendBank."Post Code" + ' ' + VendBank.City, 1, 35);
                    end;

                    xVendoradr[1] := CopyStr(Vendor.Name, 1, 24);
                    xVendoradr[2] := CopyStr(Vendor.Address, 1, 24);
                    xVendoradr[3] := CopyStr(Vendor."Post Code" + ' ' + Vendor.City, 1, 24);

                    RType836(ValutaCreation, DtaSetup, LineNo, TransNo, xDtaAccNo, xISO, AmtWithComma, xForeignBankAccType, xForeignBankAdr,
                      xAcc, xVendoradr, _PostTxt, _PostTxt2, "Gen. Journal Line"."Payment Fee Code", '0', FileText);

                    // *** TA836 write record, 5 x 128 char + CR/LF
                    for i := 1 to ArrayLen(FileText) do
                        if FileText[i] <> '' then
                            Filename.Write(FileText[i]);
                end; // End TA 836 IBAN}
            else
                Error(Text060, Vendor.Name);
        end;
    end;

    [Scope('OnPrem')]
    procedure WriteTotalRecord()
    begin
        if ((TotalAmt * 100) mod 1) <> 0 then
            Error(Text061, '', TotalAmt);

        LineNo := IncStr(LineNo);

        // Total Amt. with Dec. Comma
        AmtWithComma := Format(TotalAmt, 0, '<Integer><Decimals,3>');
        AmtWithComma := ConvertStr(AmtWithComma, '.', ',');  // Decimal point > Decimal comma

        // *** T O T A L   R E C O R D
        // ---------------------------
        Clear(FileText);
        // 12 345678 901234567890 12345 678901 2345678 90123 45678 901 2 3 4567890123456789
        FileText[1] := StrSubstNo(
            '01×000000×            ×00000×#1####×       ×#2###×#3###×890×0×0×#4##############',
            ValutaCreation[2],
            DtaSetup."DTA Sender ID",
            LineNo,
            AmtWithComma);

        FileText[1] := CheckLine(FileText[1] + PadStr(' ', 59));

        for i := 1 to ArrayLen(FileText) do
            if FileText[i] <> '' then
                Filename.Write(FileText[i]);
    end;

    [Scope('OnPrem')]
    procedure CheckLine(_Line: Text[280]): Text[128]
    begin
        _Line := DelChr(_Line, '=', '×');

        if not (StrLen(_Line) = 128) then
            Error(Text070, "Gen. Journal Line"."Line No.", "Gen. Journal Line"."Account No.");
        exit(_Line);
    end;

    [Scope('OnPrem')]
    procedure ClearVars()
    begin
        xChkDig := '';
        xBenClr := '';
        xAcc := '';

        Clear(xForeignBankAdr);
        Clear(xVendoradr);
    end;

    [Scope('OnPrem')]
    procedure WriteTestFile(var _DtaSetup: Record "DTA Setup"): Boolean
    var
        TestVendBank: Record "Vendor Bank Account";
        TestVendor: Record Vendor;
        TestDocNo: Code[10];
        TestDate: Date;
        TestAmt: Decimal;
        TestTxt: Text[50];
    begin
        if not Confirm(Text046) then
            exit(false);

        Window.Open(
          Text049 +
          Text050 +
          Text051);

        DtaSetup.Get(_DtaSetup."Bank Code");
        FileBank.Copy(DtaSetup);
        PrepareFile(FileBank."Bank Code");

        TestDocNo := 'TEST0000';
        TestDate := CalcDate('<1W>', Today);
        TestAmt := 1.0;
        TestFile := true;
        // Bei ESR/ESR+ Ref. Nr von Dummy Record
        TestVendBank.Reset();

        if TestVendBank.Find('-') then
            repeat
                if not ((TestVendBank."Vendor No." = '') or
                        (TestVendBank."Payment Form" in [TestVendBank."Payment Form"::"Cash Outpayment Order Domestic", TestVendBank."Payment Form"::"Post Payment Abroad",
                                            TestVendBank."Payment Form"::"Cash Outpayment Order Abroad"]) or (TestVendBank."ESR Type" = TestVendBank."ESR Type"::"5/15") or
                        ((TestVendBank."Payment Form" in [TestVendBank."Payment Form"::ESR, TestVendBank."Payment Form"::"ESR+"]) and (TestVendBank."ESR Account No." = '')))
                then begin
                    if not TestVendor.Get(TestVendBank."Vendor No.") then
                        Error(Text054, TestVendBank."Vendor No.", TestVendBank.Code);

                    ClearVars();
                    TestDocNo := IncStr(TestDocNo);
                    TestTxt := CopyStr(Text055 + TestVendBank."Vendor No." + ' ' + TestVendBank.Code + ' ' + Format(TestVendBank."Payment Form"), 1, 50);

                    case TestVendBank."ESR Type" of
                        TestVendBank."ESR Type"::"9/27":
                            VendEntry."Reference No." := '330002000000000097010075184';
                        TestVendBank."ESR Type"::"9/16":
                            VendEntry."Reference No." := '4097160015679962';
                    end;

                    DtaRecordWrite(
                      TestVendBank."Vendor No.", TestVendBank.Code, TestVendor."Currency Code", TestAmt,
                      TestDate, TestDocNo, '', TestTxt, '');
                end;

            until TestVendBank.Next() = 0;

        WriteTotalRecord();

        Filename.Close();
        Window.Close();

        Message(Text056, _DtaSetup."DTA Filename", _DtaSetup."DTA File Folder", TotalNoOfRecs);
        exit(true);
    end;

    local procedure FillEsrVars(_Vendor: Code[20]; _AppDocNo: Code[20])
    begin
        // Reference number 5/15
        if VendBank."ESR Type" = VendBank."ESR Type"::"5/15" then begin
            xEsrAcc := '0000' + VendBank."ESR Account No.";
            xRefNo := CopyStr(VendEntry."Reference No.", 1, 15);
            xChkDig := CopyStr(VendEntry."Reference No.", 17, 2);
            if StrLen(xRefNo) <> 15 then
                Error(Text035, _AppDocNo, _Vendor, 15);
        end;

        // 9/27
        if VendBank."ESR Type" = VendBank."ESR Type"::"9/27" then begin
            xEsrAcc := DelChr(VendBank."ESR Account No.", '=', '-');  // remove '-'
            xRefNo := VendEntry."Reference No.";
            if StrLen(xRefNo) <> 27 then
                Error(Text035, _AppDocNo, _Vendor, 27);
        end;

        // 9/16
        if VendBank."ESR Type" = VendBank."ESR Type"::"9/16" then begin
            xEsrAcc := DelChr(VendBank."ESR Account No.", '=', '-');  // remove '-'
            xRefNo := VendEntry."Reference No.";
            if StrLen(xRefNo) <> 16 then
                Error(Text035, _AppDocNo, _Vendor, 16);
            xRefNo := '00000000000' + xRefNo;
        end;
    end;

    [Scope('OnPrem')]
    procedure RType826(ValutaCreation: array[2] of Text[10]; DtaSetup: Record "DTA Setup"; LineNo: Code[5]; TransNo: Code[11]; xDtaAccNo: Code[24]; AmtWithComma: Code[16]; xEsrAcc: Code[9]; xVendoradr: array[4] of Code[24]; xRefNo: Code[27]; xChkDig: Code[2]; var ReturnRecord: array[10] of Text[128])
    begin
        Clear(RecordText);
        Clear(ReturnRecord);
        // Header, 1 - 53, 53 Zeichen
        // 12 345678 901234567890 12345 678901 2345678 90123 45678 901 2 3
        RecordText[1] := StrSubstNo(
            '01×#1####×            ×00000×#2####×#3#####×#4###×#5###×826×0×0',
            ValutaCreation[1],
            ValutaCreation[2],
            DtaSetup."DTA Sender Clearing",
            DtaSetup."DTA Sender ID",
            LineNo);

        // 54 - 128
        // 45678 90123456789 012345678901234567890123 456789 012 345678901234 56789012345678
        RecordText[1] := RecordText[1] + StrSubstNo(
            '#1###×#2#########×#3######################×      ×CHF×#4##########×              ',
            DtaSetup."DTA Customer ID",
            TransNo,
            xDtaAccNo,// DT4.10
            AmtWithComma);

        // Record 2, 1 - 82
        // 12 34567890123456789012 34567890123456789012 34567890123456789012 34567890123456789012
        RecordText[2] := StrSubstNo(
            '02×#1##################×#2##################×#3##################×#4##################',
            CopyStr(DtaSetup."DTA Sender Name", 1, 20),
            CopyStr(DtaSetup."DTA Sender Name 2", 1, 20),
            CopyStr(DtaSetup."DTA Sender Address", 1, 20),
            CopyStr(DtaSetup."DTA Sender City", 1, 20));
        RecordText[2] := RecordText[2] + PadStr(' ', 46);

        // Record 3, 1 - 74
        // 12 345 678901234 56789012345678901234 56789012345678901234 56789012345678901234
        RecordText[3] := StrSubstNo(
            '03×/C/×#1#######×#2##################×#3##################×#4##################',
            xEsrAcc,
            xVendoradr[1],
            xVendoradr[2],
            xVendoradr[3]);

        // Record 3, 75 - 128
        // 56789012345678901234 567890123456789012345678901 23 45678
        RecordText[3] := RecordText[3] + StrSubstNo(
            '#1##################×#2#########################×#3×     ',
            xVendoradr[4],
            xRefNo,
            xChkDig);

        CompressArray(RecordText);
        for i := 1 to ArrayLen(RecordText) do
            if RecordText[i] <> '' then
                ReturnRecord[i] := CheckLine(RecordText[i]);
    end;

    [Scope('OnPrem')]
    procedure RType827(ValutaCreation: array[2] of Text[10]; xBenClr: Code[12]; DtaSetup: Record "DTA Setup"; LineNo: Code[5]; TransNo: Code[11]; xDtaAccNo: Code[24]; AmtWithComma: Code[16]; xAcc: Code[34]; xVendoradr: array[4] of Code[24]; PostTxt: Text[100]; PostTxt2: Text[60]; PayRoll: Text[1]; var ReturnRecord: array[10] of Text[128])
    begin
        Clear(RecordText);
        Clear(ReturnRecord);

        // Header, 1 - 53, 53 Zeichen
        // 12 345678 901234567890 12345 678901 2345678 90123 45678 901 2 3
        RecordText[1] := StrSubstNo(
            '01×#1####×#2##########×00000×#3####×#4#####×#5###×#6###×827×#7',// achtung Salary FLAG!!
            ValutaCreation[1],
            xBenClr,// Benef. Clearing
            ValutaCreation[2],
            DtaSetup."DTA Sender Clearing",
            DtaSetup."DTA Sender ID",
            LineNo,
            PayRoll + '0');

        // 54 - 128
        // 45678 90123456789 012345678901234567890123 456789 012 345678901234 56789012345678
        RecordText[1] := RecordText[1] + StrSubstNo(
            '#1###×#2#########×#3######################×      ×CHF×#4##########×              ',
            DtaSetup."DTA Customer ID",
            TransNo,
            xDtaAccNo,
            AmtWithComma);

        // Record 2, 1 - 98
        // 12 345678901234567890123456 789012345678901234567890 123456789012345678901234 567890123456789012345678
        RecordText[2] := StrSubstNo(
            '02×#1######################×#2######################×#3######################×#4######################',
            DtaSetup."DTA Sender Name",
            DtaSetup."DTA Sender Name 2",
            DtaSetup."DTA Sender Address",
            DtaSetup."DTA Sender City");
        RecordText[2] := RecordText[2] + PadStr(' ', 30);

        // Record 3, 1 - 81
        // 12 345 678901234567890123456789012 345678901234567890123456 789012345678901234567890
        RecordText[3] := StrSubstNo(
            '03×/C/×#1#########################×#2######################×#3######################',
            xAcc,// Bank- or Post Account
            xVendoradr[1],
            xVendoradr[2]);

        // Record 3, 72 - 128
        // 123456789012345678901234 567890123456789012345678
        RecordText[3] := RecordText[3] + StrSubstNo(
            '#1######################×#2######################',
            xVendoradr[3],
            xVendoradr[4]);

        if (PostTxt <> '') or (PostTxt2 <> '') then begin
            // Record 4, 1 - 58
            // 12 3456789012345678901234567890 1234567890123456789012345678
            RecordText[4] := StrSubstNo(
                '04×#1##########################×#2##########################',
                CopyStr(PostTxt, 1, 28),
                CopyStr(PostTxt, 29, 28));

            // 9012345678901234567890123456 7890123456789012345678901234 56789012345678
            RecordText[4] := RecordText[4] + StrSubstNo(
                '#1##########################×#2##########################×#3############',
                CopyStr(PostTxt2, 1, 28),
                CopyStr(PostTxt2, 29, 28),
                PadStr(' ', 14));
        end;

        CompressArray(RecordText);
        for i := 1 to ArrayLen(RecordText) do
            if RecordText[i] <> '' then
                ReturnRecord[i] := CheckLine(RecordText[i]);
    end;

    [Scope('OnPrem')]
    procedure RType830(ValutaCreation: array[2] of Text[10]; DtaSetup: Record "DTA Setup"; LineNo: Code[5]; TransNo: Code[11]; xDtaAccNo: Code[24]; xISO: Code[3]; AmtWithComma: Code[16]; xForeignBankAccType: Code[1]; xForeignBankAcc: Text[21]; xForeignBankAdr: array[4] of Text[35]; xAcc: Code[34]; xVendoradr: array[4] of Code[24]; PostTxt: array[2] of Text[100]; xRefNo: Code[27]; xChkDig: Code[2]; Fees: Integer; var ReturnRecord: array[10] of Text[128])
    begin
        Clear(RecordText);
        Clear(ReturnRecord);

        // Fee 0 is equal 2
        // Fee Start with 1.. set Value right
        if Fees = 0 then
            Fees := 2
        else
            Fees := Fees - 1;

        // Header, 1 - 53, 53 Zeichen
        // 12 345678 901234567890 12345 678901 2345678 90123 45678 901 2 3
        RecordText[1] := StrSubstNo(
            '01×000000×            ×00000×#1####×#2#####×#3###×#4###×830×0×0',
            ValutaCreation[2],
            DtaSetup."DTA Sender Clearing",
            DtaSetup."DTA Sender ID",
            LineNo);

        // 54 - 128
        // 45678 90123456789 012345678901234567890123 456789 012 345678901234567 89012345678
        RecordText[1] := RecordText[1] + StrSubstNo(
            '#1###×#2#########×#3######################×#4####×#5#×#6#############×           ',
            DtaSetup."DTA Customer ID",
            TransNo,
            xDtaAccNo,
            ValutaCreation[1],
            xISO,// Currency Code
            AmtWithComma);

        // Record 2, 1 - 98
        // 12 345678901234 567890123456789012345678 901234567890123456789012 345678901234567890123456 789012345678901234567890'
        RecordText[2] := RecordText[2] + StrSubstNo(
            '02×            ×#1######################×#2######################×#3######################×#4######################',
            DtaSetup."DTA Sender Name",
            DtaSetup."DTA Sender Name 2",
            DtaSetup."DTA Sender Address",
            DtaSetup."DTA Sender City");
        RecordText[2] := RecordText[2] + PadStr(' ', 18);

        // Record 3, 1 - 75
        // 12 3456 789012345678901234567 890123456789012345678901 234567890123456789012345
        RecordText[3] := StrSubstNo(
            '03×#1##×#2###################×#3######################×#4######################',
            xForeignBankAccType + '/C/',// A = Swift, D = others
            xForeignBankAcc,// BLZ
            xForeignBankAdr[1],
            xForeignBankAdr[2]);

        // Record 3, 76 - 128
        // 678901234567890123456789 012345678901234567890123 45678
        RecordText[3] := RecordText[3] + StrSubstNo(
            '#1######################×#2######################×     ',
            xForeignBankAdr[3],
            xForeignBankAdr[4]);

        // Record 4, 1 - 75
        // 12 345 678901234567890123456 789012345678901234567890 123456789012345678901234
        RecordText[4] := StrSubstNo(
            '04×/C/×#1###################×#2######################×#3######################',
            xAcc,// Bank Account
            xVendoradr[1],
            xVendoradr[2]);

        // Record 4, 76 - 128
        // 567890123456789012345678 901234567890123456789012 345678
        RecordText[4] := RecordText[4] + StrSubstNo(
            '#1######################×#2######################×      ',
            xVendoradr[3],
            xVendoradr[4]);

        if not (VendBank."Payment Form" in [VendBank."Payment Form"::ESR, VendBank."Payment Form"::"ESR+"]) then begin
            // Record 5 1 - 62
            // 12 345678901234567890123456789012 345678901234567890123456789012
            RecordText[5] := StrSubstNo(
                '05×#1############################×#2############################',
                CopyStr(PostTxt[1], 1, 30),
                CopyStr(PostTxt[1], 31, 30));

            // 345678901234567890123456789012 345678901234567890123456789012 345678
            RecordText[5] := RecordText[5] + StrSubstNo(
                '#1############################×#2############################×#3####',
                CopyStr(PostTxt[2], 1, 30),
                CopyStr(PostTxt[2], 31, 30),
                PadStr(' ', 6));
        end else begin
            // Record 5, 75 - 128
            // 12 345678901234567890123456789012 345678901234567890123456789012
            RecordText[5] := StrSubstNo(
                '05×#1#########################   ×#2                            ',
                xRefNo,
                xChkDig);
            RecordText[5] := RecordText[5] + PadStr(' ', 66);
        end;

        case Fees of
            0:
                RecordText[6] := '06CHG/OUR' + PadStr(' ', 119);
            1:
                RecordText[6] := '06CHG/BEN' + PadStr(' ', 119);
        end;

        CompressArray(RecordText);
        for i := 1 to ArrayLen(RecordText) do
            if RecordText[i] <> '' then
                ReturnRecord[i] := CheckLine(RecordText[i]);
    end;

    [Scope('OnPrem')]
    procedure RType836(ValutaCreation: array[2] of Text[10]; DtaSetup: Record "DTA Setup"; LineNo: Code[5]; TransNo: Code[11]; xDtaAccNo: Code[24]; xISO: Code[3]; AmtWithComma: Code[16]; xForeignBankAccType: Code[1]; xForeignBankAdr: array[4] of Text[35]; xAcc: Code[34]; xVendoradr: array[4] of Code[24]; PostTxt: Text[100]; PostTxt2: Text[60]; Fees: Integer; PayRoll: Text[1]; var ReturnRecord: array[10] of Text[128])
    begin
        Clear(RecordText);
        Clear(ReturnRecord);

        // Fee 0 is equal 2
        // Fee Start with 1.. set Value right
        if Fees = 0 then
            Fees := 2
        else
            Fees := Fees - 1;

        // Header, 1 - 53, 53 Zeichen
        // 12 345678 901234567890 12345 678901 2345678 90123 45678 901 2 3
        // RecordText[1] := RecordText[1] + STRSUBSTNO(
        // '01×000000×            ×00000×#1####×#2#####×#3###×#4###×836×#7',
        RecordText[1] := StrSubstNo(
            '01×000000×            ×00000×#1####×#2#####×#3###×#4###×836×#5',
            ValutaCreation[2],
            DtaSetup."DTA Sender Clearing",
            DtaSetup."DTA Sender ID",
            LineNo,
            PayRoll + '0');

        // 54 - 128
        // 5      6          7                        9      0          1          2
        // 45678 90123456789 012345678901234567890123 456789 012 345678901234567 89012345678
        RecordText[1] := RecordText[1] + StrSubstNo(
            '#1###×#2#########×#3######################×#4####×#5#×#6#############×           ',
            DtaSetup."DTA Customer ID",
            TransNo,
            xDtaAccNo,
            ValutaCreation[1],
            xISO,// Currency Code
            AmtWithComma);

        // Record 2, 1 - 119
        // -         1          2         3          4         5         6         7         8          9         0         1
        // 12 345678901234 56789012345678901234567890123456789 01234567890123456789012345678901234 56789012345678901234567890123456789'
        RecordText[2] := StrSubstNo(
            '02×            ×#1#################################×#2' +
            '#################################×#3#################################',
            DtaSetup."DTA Sender Name",
            DtaSetup."DTA Sender Address",
            DtaSetup."DTA Sender City");
        RecordText[2] := RecordText[2] + PadStr(' ', 9);  // Fill up to 128 chars

        // Record 3, 1 - 75
        // -         1         2         3          4         5          6         7
        // 123 45678901234567890123456789012345678 90123456789012345678901234567890123
        RecordText[3] := StrSubstNo(
            '#1#×#2#################################×#3#################################',
            '03' + xForeignBankAccType,// A = Swift, D = others
            xForeignBankAdr[1],
            xForeignBankAdr[2]);

        // Record 3, 74 - 128
        // 7     8         9         9          1         2
        // 4567890123456789012345678901234567 890123456789012345678
        RecordText[3] := RecordText[3] + StrSubstNo(
            '#1################################×                     ',
            xAcc);

        // Record 4, 1 - 72
        // -         1         2         3          4         5         6         7
        // 12 34567890123456789012345678901234567 89012345678901234567890123456789012
        RecordText[4] := StrSubstNo(
            '04×#1#################################×#2#################################',
            xVendoradr[1],
            xVendoradr[2]);

        // Record 4, 73 - 128
        // 7      8         9         0         1         2
        // 34567890123456789012345678901234567 890123456789012345678
        RecordText[4] := RecordText[4] + StrSubstNo(
            '#1#################################×                     ',
            xVendoradr[3]);

        // Record 5 1 - 73
        // -         1         2         3          4         5         6         7
        // 123 45678901234567890123456789012345678 90123456789012345678901234567890123
        RecordText[5] := StrSubstNo(
            '05U×#1#################################×#2#################################',
            CopyStr(PostTxt, 1, 35),
            CopyStr(PostTxt, 36, 35));

        // Record 5 74 - 128
        // 7     8         9         0          1         2
        // 45678901234567890123456789012345678 90123456789012345678
        RecordText[5] := RecordText[5] + StrSubstNo(
            '#1#################################',
            CopyStr(PostTxt2, 1, 35));

        RecordText[5] := RecordText[5] + Format(Fees) + PadStr(' ', 19);

        CompressArray(RecordText);
        for i := 1 to ArrayLen(RecordText) do
            if RecordText[i] <> '' then
                ReturnRecord[i] := CheckLine(RecordText[i]);
    end;

    [Scope('OnPrem')]
    procedure DownloadToFile()
    begin
        FileMgt.DownloadHandler(ServerTempFilename, '', '', '', FileBank."DTA File Folder" + FileBank."DTA Filename");
    end;
}

