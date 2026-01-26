// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using System.IO;

report 3010834 "Write LSV File"
{
    Caption = 'Write LSV File';
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
                    if not Confirm(Text003, true, "No.") then begin
                        Reset();
                        exit;
                    end;

                WriteFile("LSV Journal");
            end;

            trigger OnPreDataItem()
            begin
                Reset();
                SetRange("No.", LSVJourNo);

                if Count > 1 then
                    Error(Text000);

                FindFirst();
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
                    field(LSVJourNo; LSVJourNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No.';
                        Editable = false;
                        ToolTip = 'Specifies the number.';
                    }
                    field(TestSending; TestSending)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Test';
                        ToolTip = 'Specifies that a test file is created first.';
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
        TestSending := false;
    end;

    trigger OnPreReport()
    begin
        if LSVJourNo = 0 then
            Error(Text036);
    end;

    var
        Text000: Label 'Only one journal can be processed. Set a filter to the journal number.';
        Text001: Label 'The file for journal %1 was already written on %2. Do you want to write it again?';
        Text003: Label 'Do you want to write the LSV file for journal %1?';
        Text004: Label 'Write file\';
        Text005: Label 'Customer      #1########\';
        Text006: Label 'Entries       #2########';
        Text007: Label 'The remaining amount of the customer entries %1, which are assigned to collection %2, does not correspond to the amount in the LSV journal, %3.\\The reason might be that payments or credit memos for open invoices have been posted that have reduced the remaining amounts.\\Delete collection %2 and redo the collection suggestion.', Comment = 'Parameters 1 and 3 - numbers, 2 - journal number.';
        Text014: Label 'Customer %1 does not exist in the customer table.';
        Text015: Label 'No valid LSV bank was found for customer %1.\\If there is more than one bank for a customer, the bank to be used for LSV must be designated with the bank code %2 that has been defined in the LSV setup.';
        Text033: Label 'Invoice ';
        Text034: Label 'etc.';
        Text035: Label 'Please Close Collection before you create the file.';
        Text036: Label 'You can start this report only from LSV Journal.';
        Text037: Label 'Bank Account No. %1 is to long, only entries with 16 chars are allowed.';
        Text038: Label 'The entry %1 has length %2 and exceeds the allowed length of %3.';
        Text039: Label '%1 entry %2 (Document No. %4) for Customer %3 is not open.';
        LsvSetup: Record "LSV Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        LsvJour: Record "LSV Journal";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        EsrSetup: Record "ESR Setup";
        GLSetup: Record "General Ledger Setup";
        CHMgt: Codeunit CHMgt;
        GeneralMgt: Codeunit GeneralMgt;
        BankMgt: Codeunit BankMgt;
        FileMgt: Codeunit "File Management";
        Filename: File;
        Window: Dialog;
        TotalAmt: Decimal;
        NoOfLines: Integer;
        RecNumber: Code[7];
        AmtWithComma: Code[16];
        Cents: Code[6];
        EsrAccNo: Code[20];
        FileCurrency: Code[10];
        MessageTxt: Text[250];
        NoOfRecs: Integer;
        TestSending: Boolean;
        RecordLong: Text[1024];
        LSVJourNo: Integer;
        CollectionAmt: Decimal;
        EsrAdr: array[8] of Text[100];
        EsrType: Option "Based on ESR Bank",ESR,"ESR+";
        AmtTxt: Text[30];
        CurrencyCode: Code[10];
        DocType: Text[10];
        RefNo: Text[50];
        CodingLine: Text[100];
        Text042: Label 'Total %1 records %2 collection records for %3 %4 have been processed.', Comment = 'Parameters 1-3 - numbers, 4 - currency code.';
        ServerTempFilename: Text[1024];

    [Scope('OnPrem')]
    procedure WriteFile(_LsvJour: Record "LSV Journal")
    begin
        // *** Write file. Based on all inovice according to LSV journal
        LsvJour.Get(_LsvJour."No.");
        LsvSetup.Get(LsvJour."LSV Bank Code");
        EsrSetup.Get(LsvSetup."ESR Bank Code");
        PrepareFile();

        Window.Open(
          Text004 + // Write file
          Text005 + // Customer #1
          Text006); // Entries #2

        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("LSV No.");
        CustLedgEntry.SetRange("LSV No.", LsvJour."No.");

        if CustLedgEntry.FindSet() then
            repeat
                // Prepare amount and message
                CustLedgEntry.CalcFields("Remaining Amount");
                if not CustLedgEntry.Open then
                    Error(Text039, CustLedgEntry.TableCaption(),
                      CustLedgEntry."Entry No.", CustLedgEntry."Customer No.", CustLedgEntry."Document No.");
                CollectionAmt := CollectionAmt + CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible";
                PrepareMessage();
                NoOfLines := NoOfLines + 1;

                WriteCollectionRecord(
                  CustLedgEntry."Customer No.",
                  CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible",
                  LsvJour."Credit Date",
                  LsvJour."Collection Completed On");

                MessageTxt := '';
            until CustLedgEntry.Next() = 0;

        WriteTotalRecord(TotalAmt, LsvJour."Collection Completed On");
        RecordLong := '';
        Filename.Close();
        ServerTempFilename := GeneralMgt.RemoveCrLf(LsvSetup."LSV File Folder" + LsvSetup."LSV Filename", ServerTempFilename, true);

        Window.Close();

        if (LsvJour."LSV Status" <> LsvJour."LSV Status"::"File Created") or (LsvJour."File Written On" = 0D) then begin
            LsvJour."File Written On" := Today;
            if not TestSending then
                LsvJour."LSV Status" := LsvJour."LSV Status"::"File Created";
            LsvJour.Modify();
        end;

        LsvJour.CalcFields("Amount Plus");
        // Amount does not match
        if TotalAmt <> LsvJour."Amount Plus" then
            Error(Text007, TotalAmt, LsvJour."No.", LsvJour.Amount);

        if _LsvJour."Currency Code" = '' then begin
            GLSetup.Get();
            FileCurrency := GLSetup."LCY Code";
        end else
            FileCurrency := _LsvJour."Currency Code";

        FileMgt.DownloadHandler(ServerTempFilename, '', '', '', LsvSetup."LSV Filename");

        Message(Text042, NoOfLines, NoOfRecs, TotalAmt, FileCurrency);
    end;

    [Scope('OnPrem')]
    procedure PrepareFile()
    begin
        // Reset var, check setup, open file
        TotalAmt := 0;
        NoOfLines := 0;
        NoOfRecs := 0;

        LsvSetup.TestField("LSV Customer ID");
        LsvSetup.TestField("LSV Sender ID");
        LsvSetup.TestField("LSV Sender Clearing");
        LsvSetup.TestField("LSV Sender Name");
        LsvSetup.TestField("LSV Sender City");
        LsvSetup.TestField("LSV Sender IBAN");

        Filename.TextMode := true;
        Filename.WriteMode := true;
        ServerTempFilename := FileMgt.ServerTempFileName('');
        Filename.Create(ServerTempFilename);

        RecNumber := '0000000';
    end;

    [Scope('OnPrem')]
    procedure WriteCollectionRecord(_Customerno: Code[20]; _Amt: Decimal; _Valuta: Date; _CreationDate: Date)
    begin
        // Write record per customer entry
        RecNumber := IncStr(RecNumber);

        if not Customer.Get(_Customerno) then  // for Address
            Error(Text014, _Customerno);

        Customer.TestField(Name);
        Customer.TestField(City);

        // Get customer bank
        CustomerBankAccount.Reset();
        CustomerBankAccount.SetRange("Customer No.", _Customerno);
        if CustomerBankAccount.Count > 1 then
            CustomerBankAccount.SetRange(Code, LsvSetup."LSV Customer Bank Code");

        // Deb bank not found
        if not CustomerBankAccount.FindFirst() then
            Error(Text015, CustLedgEntry."Customer No.", LsvSetup."LSV Customer Bank Code");

        CustomerBankAccount.TestField("Bank Branch No.");
        if (CustomerBankAccount.IBAN = '') and (CustomerBankAccount."Bank Account No." = '') then begin
            CustomerBankAccount.TestField(IBAN);
            CustomerBankAccount.TestField("Bank Account No.");
        end;

        if (CustomerBankAccount.IBAN = '') and (CustomerBankAccount."Bank Account No." <> '') then
            if StrLen(CustomerBankAccount."Bank Account No.") > 16 then
                Error(Text037, CustomerBankAccount."Bank Account No.");

        // Whole CHF, no thousand separator + , + Cents, 2 digit. Also for FC
        Cents := Format((_Amt mod 1) + 1.001, 5);  // 0.05 = 1.051 = 05
        AmtWithComma := Format(Round(_Amt, 1, '<'), 0, 1) + ',' + CopyStr(Cents, 3, 2);

        // ***  TA 875, Debit Record
        AddRecord('8750', 0, 4);  // TA & VNR

        if TestSending then
            AddRecord('T', 1, 1)
        else
            AddRecord('P', 1, 1);  // VART

        AddRecord(Format(_Valuta, 8, '<year4><month,2><day,2>'), 0, 8);  // GVDAT
        AddRecord(CustomerBankAccount."Bank Branch No.", 1, 5);  // BC-ZP
        AddRecord(Format(_CreationDate, 8, '<year4><month,2><day,2>'), 0, 8); // EDAT
        AddRecord(LsvSetup."LSV Sender Clearing", 1, 5);    // BC-ZE
        AddRecord(LsvSetup."LSV Sender ID", 1, 5);  // ABS-ID
        AddRecord(RecNumber, 0, 7);  // ESEQ
        AddRecord(LsvSetup."LSV Customer ID", 1, 5);  // LSV-ID
        AddRecord(GeneralMgt.CheckCurrency(LsvSetup."LSV Currency Code"), 1, 3);  // WHG
        AddRecord(AmtWithComma, 0, 12);     // BETR
        AddRecord(DelChr(LsvSetup."LSV Sender IBAN"), 1, 34);  // KTO-ZE

        AddRecord(LsvSetup."LSV Sender Name", 1, 35); // ADR-ZE
        AddRecord(CopyStr(LsvSetup."LSV Sender Post Code" + ' ' + LsvSetup."LSV Sender City", 1, 35), 1, 35); // ADR-ZE
        AddRecord(LsvSetup."LSV Sender Name 2", 1, 35); // ADR-ZE
        AddRecord(LsvSetup."LSV Sender Address", 1, 35); // ADR-ZE

        if CustomerBankAccount.IBAN <> '' then     // KTO-ZP
            AddRecord(DelChr(CustomerBankAccount.IBAN), 1, 34)
        else begin
            AddRecord(CustomerBankAccount."Bank Account No.", 1, 16);  // Not more than 16 chars
            AddRecord(' ', 1, 18);  // fill up with blanks to 34
        end;

        AddRecord(CopyStr(Customer.Name, 1, 35), 1, 35); // ADR-ZP
        AddRecord(CopyStr(Customer."Post Code" + ' ' + Customer.City, 1, 35), 1, 35); // ADR-ZP
        AddRecord(CopyStr(Customer.Address, 1, 35), 1, 35); // ADR-ZP
        AddRecord(CopyStr(Customer."Address 2", 1, 35), 1, 35); // ADR-ZP

        AddRecord(CopyStr(MessageTxt, 1, 35), 1, 35);  // MIT-ZP
        AddRecord(CopyStr(MessageTxt, 36, 35), 1, 35);  // MIT-ZP
        AddRecord(CopyStr(MessageTxt, 71, 35), 1, 35);  // MIT-ZP
        AddRecord(CopyStr(MessageTxt, 106, 35), 1, 35);  // MIT-ZP

        SalesInvoiceHeader.Get(CustLedgEntry."Document No.");

        CHMgt.PrepareEsr(SalesInvoiceHeader, EsrSetup, EsrType, EsrAdr, AmtTxt, CurrencyCode, DocType, RefNo, CodingLine);

        AddRecord('A', 1, 1); // REF-FL

        AddRecord(DelChr(RefNo, '=', ' '), 1, 27); // REF-NR
        EsrAccNo := BankMgt.CheckPostAccountNo(EsrSetup."ESR Account No.");
        EsrAccNo := DelChr(EsrAccNo, '=', '-');
        AddRecord(EsrAccNo, 1, 9); // ESR-TN

        Filename.Write(RecordLong);
        RecordLong := '';

        NoOfRecs := NoOfRecs + 1;
        TotalAmt := TotalAmt + _Amt;  // Remaining amt - cash disc. possible
        Window.Update(1, CustLedgEntry."Customer No.");
        Window.Update(2, NoOfLines);
    end;

    [Scope('OnPrem')]
    procedure WriteTotalRecord(_TotalAmt: Decimal; _CreationDate: Date)
    begin
        RecNumber := IncStr(RecNumber);

        // Format total amt. No thousand separator + , + Cents, 2 digits
        Cents := Format((_TotalAmt mod 1) + 1.001, 5);  // 0.05 = 1.051 = 05
        AmtWithComma := Format(Round(_TotalAmt, 1, '<'), 0, 1) + ',' + CopyStr(Cents, 3, 2);

        // ***  TA 890, Debit Record
        AddRecord('8900', 0, 4);  // TA & VNR
        AddRecord(Format(_CreationDate, 8, '<year4><month,2><day,2>'), 0, 8); // EDAT
        AddRecord(LsvSetup."LSV Sender ID", 1, 5); // ABS-ID
        AddRecord(RecNumber, 0, 7);  // ESEQ
        AddRecord(LsvSetup."LSV Currency Code", 1, 3);   // WHG
        AddRecord(AmtWithComma, 0, 16); // TBETR

        Filename.Write(RecordLong);
    end;

    [Scope('OnPrem')]
    procedure PrepareMessage()
    begin
        if MessageTxt = '' then
            MessageTxt := Text033 + ' ' + CustLedgEntry."Document No."
        else
            if StrLen(MessageTxt + ' ' + CustLedgEntry."Document No.") < 100 then
                MessageTxt := MessageTxt + ' ' + CustLedgEntry."Document No."
            else
                if StrPos(MessageTxt, Text034) = 0 then  // etc. not yet added
                    MessageTxt := MessageTxt + ' ' + Text034;
    end;

    [Scope('OnPrem')]
    procedure AddRecord(Content: Text[100]; Type: Option N,X; Length: Integer)
    var
        i: Integer;
    begin
        if StrLen(Content) > Length then
            Error(Text038, Content, StrLen(Content), Length);

        i := 0;
        while (i < Length - StrLen(Content)) and (Type = Type::N) do begin
            RecordLong := RecordLong + '0';
            i := i + 1;
        end;

        RecordLong := RecordLong + Content;

        while (i < Length - StrLen(Content)) and (Type = Type::X) do begin
            RecordLong := RecordLong + ' ';
            i := i + 1;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetGlobals(ActLsvJour: Record "LSV Journal")
    begin
        LSVJourNo := ActLsvJour."No.";

        if ActLsvJour."LSV Status" < ActLsvJour."LSV Status"::Released then
            Error(Text035);
    end;
}

