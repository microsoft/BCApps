// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.IO;

report 3010839 "LSV Write DebitDirect File"
{
    Caption = 'Write DebitDirect File';
    ProcessingOnly = true;

    dataset
    {
        dataitem("LSV Journal"; "LSV Journal")
        {
            DataItemTableView = sorting("No.") order(ascending);

            trigger OnAfterGetRecord()
            begin
                if "File Written On" <> 0D then begin
                    if not Confirm(Text001, true, "No.", "File Written On") then
                        exit;
                end else
                    if not Confirm(Text003, true, "No.") then
                        exit;

                WriteFile("LSV Journal");
            end;

            trigger OnPreDataItem()
            begin
                "LSV Journal".SetRange("No.", "No.");
                LastLsvJour.Reset();
                LastLsvJour.SetRange("Credit Date", "LSV Journal"."Credit Date");
                if LastLsvJour.FindFirst() then begin
                    if LastLsvJour."DebitDirect Orderno." in ['', '99'] then
                        LastOrderNo := '00'
                    else
                        LastOrderNo := LastLsvJour."DebitDirect Orderno.";
                    "LSV Journal"."DebitDirect Orderno." := IncStr(LastOrderNo);
                    "LSV Journal".Modify();
                end else
                    "LSV Journal"."DebitDirect Orderno." := '01';

                if Count > 1 then
                    Error(Text000);
            end;
        }
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
                    field("""LSV Journal"".""No."""; "LSV Journal"."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No.';
                        Editable = false;
                        ToolTip = 'Specifies the number.';
                    }
                    field(Combine; CombineCollectionPerCust)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Combine per customer';
                        Editable = CombineEditable;
                        ToolTip = 'Specifies if you want to combine documents for a customer.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            CombineEditable := true;
        end;

        trigger OnOpenPage()
        begin
            LsvSetup.Get("LSV Journal"."LSV Bank Code");
            if LsvSetup."DebitDirect Import Filename" <> '' then begin
                CombineEditable := false;
                CombineCollectionPerCust := false;
            end;
        end;
    }

    labels
    {
    }

    var
        Text000: Label 'Only one journal can be processed. Set a filter to the journal number.';
        Text001: Label 'The file for journal %1 was already written on %2.\Do you want to write it again?';
        Text003: Label 'Do you want to write the LSV file for Journal %1?';
        Text004: Label 'Write file\';
        Text005: Label 'Customer      #1########\';
        Text006: Label 'Entries       #2########';
        Text007: Label 'The remaining amount of the customer entries %1, which are assigned to collection %2, does not correspond to the amount in the LSV journal, %3.\\The reason might be that payments or credit memos for open invoices have been posted that have reduced the remaining amounts.\\Delete collection %2 and redo the collection suggestion.', Comment = 'Parameters 1 and 3 - numbers, 2 - journal number.';
        Text014: Label 'Total %1 records %2 collection records for %3 %4 have been processed.', Comment = 'Parameters 1-3 - numbers, 4 - currency code.';
        Text015: Label 'Customer %1 does not exist in the customer table.';
        Text016: Label 'No valid LSV bank found for customer %1.\\If there is more than one bank for a customer, the bank to be used for LSV must be designated with the bank code %2 that has been defined in the LSV setup.';
        Text019: Label 'Post account is not defined for customer %1 with bank %2.';
        Text020: Label 'Post account %1 must have 11 digits, for example, 60-987654-5.\Customer %2, account %1.', Comment = '1 - general account number, 2 - customer number.';
        Text024: Label 'The currency code %1 is invalid. Only EUR and CHF can be collected.\Customer %2, amount %3.', Comment = 'Parameter 1 - currency code, 2 - customer number, 3 - amount;';
        Text027: Label 'This batch job creates a DebitDirect testfile to verify account numbers.\For all customers with payment form %1, a record with %2 1.00 is created.\Do you want to continue?', Comment = 'Parameter 1 - payment method code, 2 - currency code.';
        Text030: Label 'Account verification file\';
        Text031: Label 'Customer   #1########\';
        Text032: Label 'Records    #2########';
        Text033: Label 'Account verification testrecord';
        Text035: Label 'File %1 for the account verification has been created successfully.\It is now saved in the folder %2.\\%3 records with each %4 1.00 have been processed.', Comment = 'Parameter 1 - file name, 2 - folder name, 3 - number, 4 - currency code.';
        Text038: Label 'Invoice ';
        Text039: Label 'etc.';
        LsvSetup: Record "LSV Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        LsvJour: Record "LSV Journal";
        LastLsvJour: Record "LSV Journal";
        Customer: Record Customer;
        DebBank: Record "Customer Bank Account";
        NextCustEntry: Record "Cust. Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        LSVJournalLine: Record "LSV Journal Line";
        FileMgt: Codeunit "File Management";
        Window: Dialog;
        Filename: File;
        xValuta: Text[10];
        xPostAcc: Text[11];
        xISO: Code[10];
        CollectionAmt: Decimal;
        TotalAmt: Decimal;
        NoOfLines: Integer;
        TaLineno: Code[10];
        AmtWoComma: Code[16];
        LastOrderNo: Code[2];
        FileCurrency: Code[10];
        ControlArea: Text[80];
        AmtPart: Text[80];
        CustomerPart: Text[160];
        SparePart: Text[160];
        MessagePart: Text[160];
        OriginatorPart: Text[160];
        TotalPart: Text[30];
        CombineCollectionPerCust: Boolean;
        MessageTxt: Text[250];
        NoOfRecs: Integer;
        Text040: Label 'If you are working with automated processing confirmations by importing DebitDirect files you must not check field Combine by Customer.';
        Text041: Label 'Please Close Collection before you create the file.';
        ServerTempFilename: Text[1024];
        CombineEditable: Boolean;

    [Scope('OnPrem')]
    procedure WriteFile(_LsvJour: Record "LSV Journal")
    begin
        // All cust. entries according to LSV journal no.
        LsvJour.Get(_LsvJour."No.");
        LsvSetup.Get(LsvJour."LSV Bank Code");

        // This case should never happen, but this code ensure it
        if (LsvSetup."DebitDirect Import Filename" <> '') and CombineCollectionPerCust then
            Error(Text040);

        PrepareFile(LsvJour."Credit Date");

        Window.Open(
          Text004 + // Write file
          Text005 + // Customer #1
          Text006); // Entries #2

        // All entries per LSV journal - only one currency
        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("LSV No.");
        CustLedgEntry.SetRange("LSV No.", LsvJour."No.");

        if CustLedgEntry.Find('-') then
            repeat
                // Prepare amount and message
                CustLedgEntry.CalcFields("Remaining Amount");
                CollectionAmt := CollectionAmt + CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible";
                PrepareMessage();
                NoOfLines := NoOfLines + 1;

                NextCustEntry.Copy(CustLedgEntry);
                if (NextCustEntry.Next() = 0) or
                   (CombineCollectionPerCust = false) or
                   (NextCustEntry."Customer No." <> CustLedgEntry."Customer No.")
                then begin
                    LSVJournalLine.SetCurrentKey("LSV Journal No.", "Cust. Ledg. Entry No.");
                    LSVJournalLine.SetRange("LSV Journal No.", _LsvJour."No.");
                    LSVJournalLine.SetRange("Cust. Ledg. Entry No.", CustLedgEntry."Entry No.");
                    LSVJournalLine.FindFirst();
                    Evaluate(LSVJournalLine."Transaction No.", TaLineno);
                    LSVJournalLine.Modify();
                    WriteCollectionRecord(CustLedgEntry."Customer No.", CustLedgEntry."Currency Code", CollectionAmt);

                    CollectionAmt := 0;
                    MessageTxt := '';
                end;
            until CustLedgEntry.Next() = 0;

        WriteTotalRecord();

        Filename.Close();
        Window.Close();

        if (LsvJour."LSV Status" <> LsvJour."LSV Status"::"File Created") or (LsvJour."File Written On" = 0D) then begin
            LsvJour."File Written On" := Today;
            LsvJour."LSV Status" := LsvJour."LSV Status"::"File Created";
            LsvJour.Modify();
        end;

        LsvJour.CalcFields("Amount Plus");
        // Amount has changed
        if TotalAmt <> LsvJour."Amount Plus" then
            Error(Text007, TotalAmt, LsvJour."No.", LsvJour.Amount);

        if _LsvJour."Currency Code" = '' then begin
            GLSetup.Get();
            FileCurrency := GLSetup."LCY Code";
        end else
            FileCurrency := _LsvJour."Currency Code";

        FileMgt.DownloadHandler(ServerTempFilename, '', '', '', LsvSetup."LSV Filename");

        Message(Text014, NoOfLines, NoOfRecs, TotalAmt, FileCurrency);
    end;

    [Scope('OnPrem')]
    procedure PrepareFile(_Valuta: Date)
    begin
        // Reset var, check setup, open file
        TotalAmt := 0;
        NoOfLines := 0;
        NoOfRecs := 0;

        LsvSetup.TestField("DebitDirect Customerno.");
        LsvSetup.TestField("LSV Sender Name");
        LsvSetup.TestField("LSV Sender City");
        LsvSetup.TestField("LSV File Folder");
        LsvSetup.TestField("LSV Filename");

        Filename.TextMode := true;
        Filename.WriteMode := true;
        ServerTempFilename := FileMgt.ServerTempFileName('');
        Filename.Create(ServerTempFilename);

        TaLineno := '000000';
        xValuta := Format(_Valuta, 6, '<year><month,2><day,2>');

        // *** Write header, 50 + 650 blank + CR/LF
        PrepareControlArea('00');
        Filename.Write(ControlArea + PadStr(' ', 650));
    end;

    [Scope('OnPrem')]
    procedure PrepareControlArea(_TA: Code[2])
    begin
        // Header, 1 - 50, 50 Char
        // 036 Valuta Ku Nr.                      Nr TA Laufnr
        // 123 456789 012345 6 78901234 567890123 45 67 890123 45 6 7890
        ControlArea := StrSubstNo(
            '036_#1####_#2####_1_00000000_000000000_#3_#4_#5####_00_0_0000',
            xValuta,
            LsvSetup."DebitDirect Customerno.",
            LsvJour."DebitDirect Orderno.",
            _TA,
            TaLineno);

        ControlArea := DelChr(ControlArea, '=', '_');
        TaLineno := IncStr(TaLineno);  // Lineno. for next rec. Header starts with 000000
    end;

    [Scope('OnPrem')]
    procedure WriteCollectionRecord(_Customerno: Code[20]; _Currency: Code[10]; _Amt: Decimal)
    begin
        // Write record per customer entry
        if not Customer.Get(_Customerno) then  // for Address
            Error(Text015, _Customerno);

        Customer.TestField(Name);
        Customer.TestField(City);

        // Get customer bank
        DebBank.Reset();
        DebBank.SetRange("Customer No.", _Customerno);
        if DebBank.Count > 1 then
            DebBank.SetRange(Code, LsvSetup."LSV Customer Bank Code");

        if not DebBank.FindFirst() then
            Error(Text016, CustLedgEntry."Customer No.", LsvSetup."LSV Customer Bank Code");

        // CHeck post account
        if DebBank."Giro Account No." = '' then
            Error(Text019, DebBank."Customer No.", DebBank.Code);

        xPostAcc :=
          CopyStr(DebBank."Giro Account No.", 1, 3) + CopyStr('00000000000', 1, 11 - StrLen(DebBank."Giro Account No.")) +
          CopyStr(DebBank."Giro Account No.", 4);
        xPostAcc := DelChr(xPostAcc, '=', '-');
        if StrLen(xPostAcc) <> 9 then
            Error(Text020, Customer."No.", DebBank."Giro Account No.");

        // Currency code only CHF and EUR
        if _Currency = '' then
            xISO := 'CHF'
        else
            xISO := LsvSetup."LSV Currency Code";

        // Currency must be CHF or EUR
        if not (xISO in ['CHF', 'EUR']) then
            Error(Text024, xISO, Customer."No.", _Amt);

        // Amt 13 digits. No thousand and decimal separator. Preceding zeros.
        AmtWoComma := Format(_Amt, 0, '<Integer><Decimals,3>');
        AmtWoComma := DelChr(AmtWoComma, '=', '.,');  // Remove decimal
        AmtWoComma := CopyStr('0000000000000', 1, 13 - StrLen(AmtWoComma)) + AmtWoComma;

        // *** DebitDirect collection record
        PrepareControlArea('47');

        // Amount part: Pos 51 - 122, 72 chars
        // ISO remit amount           Post acc  spaces reference no or spaces      spaces
        // 123 4567890123456 7 890 12 345678901 234567 890123456789012345678901234 56789012
        AmtPart := StrSubstNo(
            '#1#_#2###########_ _   _  _#3#######_      _                           _        ',
            xISO,
            AmtWoComma,
            xPostAcc);
        AmtPart := DelChr(AmtPart, '=', '_');

        // Customer part, 4 x 35, Pos 123 - 262, 140 Char
        CustomerPart := StrSubstNo(
            '#1#################################_#2#################################_' +
            '#3#################################_#4########_#5#######################',
            Customer.Name,
            Customer."Name 2",
            Customer.Address,
            Customer."Post Code",
            Customer.City);
        CustomerPart := DelChr(CustomerPart, '=', '_');

        // Spare part: 4 x 35, Pos 263 - 402, 140 Char
        SparePart := PadStr(' ', 140);

        // Message, 4 x 35Z, Pos 403 - 542, 140 Chars
        MessagePart := PadStr(MessageTxt, 140, ' ');

        // Originator, blank, Pos 543 - 700, 158
        OriginatorPart := PadStr(' ', 158);

        // Write record 50 + 72 + 140 + 140 + 140 + 158 = 700 Char
        Filename.Write(ControlArea + AmtPart + CustomerPart + SparePart + MessagePart + OriginatorPart);

        NoOfRecs := NoOfRecs + 1;
        TotalAmt := TotalAmt + _Amt;
        Window.Update(1, CustLedgEntry."Customer No.");
        Window.Update(2, NoOfLines);
    end;

    [Scope('OnPrem')]
    procedure WriteTotalRecord()
    begin
        // *** Total Record
        AmtWoComma := Format(TotalAmt, 0, '<Integer><Decimals,3>');
        AmtWoComma := DelChr(AmtWoComma, '=', '.,');  // Remove decimal
        AmtWoComma := CopyStr('0000000000000', 1, 13 - StrLen(AmtWoComma)) + AmtWoComma;
        PrepareControlArea('97'); // TA

        // Currency element, 22 char
        // ISO Number Totalamount
        // 123 456789 0123456789012
        TotalPart := StrSubstNo(
            '#1#_#2####_#3###########',
            xISO,
            CopyStr('000000', 1, 6 - StrLen(Format(NoOfRecs))) + Format(NoOfRecs),// preceding zeros
            AmtWoComma);

        TotalPart := DelChr(TotalPart, '=', '_');

        Filename.Write(ControlArea + TotalPart + PadStr(' ', 628));
    end;

    [Scope('OnPrem')]
    procedure WriteTestFile(var _LsvSetup: Record "LSV Setup")
    begin
        if not Confirm(Text027, true, _LsvSetup."LSV Payment Method Code", _LsvSetup."LSV Currency Code") then
            exit;

        Window.Open(
          Text030 + // Verific. file
          Text031 + // Customer #1
          Text032); // Records #2

        LsvSetup := _LsvSetup;  // Function uses global vars

        MessageTxt := Text033;
        LsvJour."DebitDirect Orderno." := '99';
        PrepareFile(CalcDate('<1W>', Today));

        Customer.Reset();
        Customer.SetRange("Payment Method Code", LsvSetup."LSV Payment Method Code");
        if Customer.FindSet() then
            repeat
                WriteCollectionRecord(Customer."No.", LsvSetup."LSV Currency Code", 1.0);
            until Customer.Next() = 0;

        WriteTotalRecord();

        Filename.Close();
        Window.Close();

        Message(Text035, _LsvSetup."LSV Filename", _LsvSetup."LSV File Folder", NoOfRecs, _LsvSetup."LSV Currency Code");
    end;

    [Scope('OnPrem')]
    procedure PrepareMessage()
    begin
        if MessageTxt = '' then
            MessageTxt := Text038 + CustLedgEntry."Document No."
        else
            if StrLen(MessageTxt + ' ' + CustLedgEntry."Document No.") < 100 then
                MessageTxt := MessageTxt + ' ' + CustLedgEntry."Document No."
            else
                if StrPos(MessageTxt, Text039) = 0 then  // etc. not yet added
                    MessageTxt := MessageTxt + ' ' + Text039;
    end;

    [Scope('OnPrem')]
    procedure SetGlobals(ActualJournalNo: Integer)
    begin
        "LSV Journal".SetRange("No.", ActualJournalNo);
        "LSV Journal".Get(ActualJournalNo);

        if "LSV Journal"."LSV Status" < "LSV Journal"."LSV Status"::Released then
            Error(Text041);
    end;
}

