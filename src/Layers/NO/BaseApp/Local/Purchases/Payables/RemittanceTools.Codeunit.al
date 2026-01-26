// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;

codeunit 15000002 "Remittance Tools"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        text018: Label 'Error in message to vendor. %1.\';
        text019: Label 'Formating of the text to %2 %3 is more then %4 chars long.\', Comment = 'Parameter 2 - Document Type, 3 - Document No., 4 - string length';
        text020: Label 'Message line starts with following: "%5..."\\';
        text021: Label 'Recipient ref. must be changed for vendor.';
        text022: Label 'Recipient ref. must be changed for remittance account %6';
        text023: Label 'Batch rejected, but no errors in this record.';
        text024: Label 'Erroneus enterprise no./customer no.';
        text025: Label 'Cannot Change/Cancel';
        text026: Label 'Total amount of invoices/credit notes can not be less then 0';
        text027: Label 'Serial number does not exist or is invalid';
        text028: Label 'Transaction type can not be changed in PAYFOR21';
        text029: Label 'Incorrect use of KID/ invalid KID';
        text030: Label 'Invalid credit account number';
        text031: Label 'Invalid debet account number';
        text032: Label 'Payment date invalid';
        text033: Label 'Ref. no. does not exist, or is invalid';
        text034: Label 'Password expired (password too old)';
        text035: Label 'Operator locked';
        text036: Label 'Invalid password';
        text037: Label 'Operator not authorised';
        text038: Label 'Invalid Operator ID';
        text039: Label 'Invalid version number in BETFOR00';
        text040: Label 'Error(s) in name/address fields';
        text041: Label 'Incorrect currency code';
        text042: Label 'Error in agreed exchange rate/forward rate';
        text043: Label 'Invalid authority report code';
        text044: Label 'Incorrect payee country/region code';
        text045: Label 'Error in sequence control field';
        text046: Label 'Incorrectly constructed batch';
        text047: Label 'Invalid transaction code';
        text048: Label 'Seal invalid';
        text049: Label 'Count error for number of transactions within a batch (BETFOR99)';
        text050: Label 'Sequence error in AH-sequence (application header)';
        text051: Label 'Unknown AH-PROCEDURE-ID';
        text052: Label 'Invalid AH-TRANSACTION DATE';
        text053: Label 'Invalid division';
        text054: Label 'Error unknown';
        text055: Label 'Error code %1: %2.', Comment = 'Parameter 1 - code, 2 - error message';
        text060: Label 'Missing debit/credit code';
        text061: Label 'Mixing of structured and unstructured message information not allowed';
        text062: Label 'Use of KID is mandatory for this beneficiary';
        text063: Label 'Invalid cheque code';
        text064: Label 'Invalid charges codes';
        text065: Label 'Invalid notification indicator';
        text066: Label 'Invalid priority code';
        text067: Label 'Invalid amount field';
        text068: Label 'Missing mandatory authority report free text for authority report code';
        text069: Label 'Error in SWIFT code field';
        text070: Label 'Missing new seal key ';
        text071: Label 'Incorrectly constructed payment order';
        text072: Label 'BETFOR not followed by sufficient number of records';
        text073: Label 'Errors in BETFOR99';
        text074: Label 'Errors in BETFOR00';
        BankAccountMsg: Label 'Bank account no.: %1\Postgiro account no.: %2';
        NotValidAccountMsg: Label 'This is not a valid accountno. ';
        StartingDigitWrongMsg: Label 'Starting digit %1 is wrong.';
        CountrolDigitWrong10Msg: Label 'Control-digit is wrong (modulus 10).';
        CountrolDigitWrong11Msg: Label 'Control-digit is wrong (modulus 11).';
        WrongNumberSizeMsg: Label 'Control-number should have 7 or 11 digits.';
        NotElevenDigitsMsg: Label 'Account no. should have 11 digits.';
        WrongKIDNo10Msg: Label 'This is not a valid KID no. (modulus10).';
        WrongKIDNo11Msg: Label 'This is not a valid KID no (modulus 11).';
        WrongKIDNo10and11Msg: Label 'This is not a valid KID no (modulus 10 and 11).';
        TooLongMessageErr: Label 'The message is too long. It can not be longer then %1 char.';
        NonDigitCharErr: Label 'Only the char. "0123456789,.-" and space can be used for account no.';
        WrongAccountTypeErr: Label 'Error: Wrong account type %1 in line %2.\Vendor no. %3, entry serial no. %4', Comment = 'Parameter 1 - Line No, 2 - Line Type, 3 - Vendor No, 4 - vendor entry no';
        WrongEntryErr: Label 'Error: %1 entry(s) in line %2.\Vendor no. %3, entry serial no. %4', Comment = 'Parameter 1 - number of entries, 2 - line no, 3 - Vendor No, 4 - Vendor Entry No';

    procedure CheckAccountNo(AccountNo: Text[30]; BankType: Integer): Text[250]
    var
        BankgiroText: Text[250];
        PostgiroText: Text[250];
    begin
        // RETUR: = ''=Not error <>''=return text creates error.
        case BankType of
            0:
                begin // Check bankgiro and postgiro
                    BankgiroText := CheckBankGiro(AccountNo);
                    PostgiroText := CheckPostGiro(AccountNo);
                    // If at least one of them is correct:
                    if (BankgiroText <> '') and (PostgiroText <> '') then
                        exit(StrSubstNo(BankAccountMsg, BankgiroText, PostgiroText));
                end;
            1:
                ; // Foreign. No account check.
        end;
        exit(''); // no error.
    end;

    procedure CheckPostGiro(AccountNo: Text[30]): Text[250]
    var
        TempStr: Text[30];
        ErrText: Text[250];
    begin
        // Check postgiro no. . Both 7 and 11 digits. [p60]
        ErrText := '';
        AccountNo := FormatAccountNo(AccountNo); // Delete blanks from account no.

        // Check the length:
        case StrLen(AccountNo) of
            7:
                begin
                    // Check 2 first digits [10.6 p60]
                    // Valid 2 first digits: [13..18].
                    TempStr := CopyStr(AccountNo, 1, 2);
                    if (TempStr < '13') or (TempStr > '18') then
                        ErrText := StrSubstNo(NotValidAccountMsg + StartingDigitWrongMsg, TempStr);

                    // Modulus 10 control:
                    if not Modulus10(AccountNo) then
                        ErrText := NotValidAccountMsg + CountrolDigitWrong10Msg;
                end;
            11:
                begin
                    // Check first 4 digits. [10.5 p60]
                    // Valid 4 first digits:
                    // [0801..0809] og [0813..0814] og [0823..0850]
                    TempStr := CopyStr(AccountNo, 1, 4);
                    if (TempStr < '0801') or
                       ((TempStr > '0809') and (TempStr < '0813')) or
                       ((TempStr > '0814') and (TempStr < '0823')) or
                       (TempStr > '0850')
                    then
                        ErrText := StrSubstNo(NotValidAccountMsg + StartingDigitWrongMsg, TempStr);

                    // Modulus 11 control of 11-digits account nos. [p59]:
                    if not Modulus11(AccountNo) then
                        ErrText := NotValidAccountMsg + CountrolDigitWrong11Msg;
                end;
            else
                ErrText := WrongNumberSizeMsg;
        end;

        // Return message:
        exit(ErrText);
    end;

    procedure CheckBankGiro(AccountNo: Text[30]): Text[250]
    var
        ErrText: Text[250];
    begin
        if StrLen(AccountNo) <> 11 then
            exit(NotValidAccountMsg);
        AccountNo := FormatAccountNo(AccountNo); // Delete blanks in account no.:

        if StrLen(AccountNo) <> 11 then
            ErrText := NotElevenDigitsMsg;
        if not Modulus11(AccountNo) then
            ErrText := NotValidAccountMsg + CountrolDigitWrong11Msg;
        exit(ErrText);
    end;

    procedure CheckKID(KidCode: Code[26]): Text[250]
    var
        Kid: Code[25];
        Method: Char;
        MethodStr: Text[1];
        ErrText: Text[250];
        TempKid: Code[60];
    begin
        // Modulus 10 and 11 control of KID [10.1 and 10.2 p57].
        // PARAMETERS:  KIDCode=KID, including control-type char. at the end (<, > eller -), if any.
        // If the control-sign is not specified, both modulus 10 and 11 are checked. If any of those is ok, the KID is ok.
        Method := KidCode[StrLen(KidCode)];
        MethodStr := ' ';
        MethodStr[1] := Method;

        TempKid := '00000000000000000000000000' + KidCode;
        // Format KID to 25 charachets with prepositive zero;
        if StrPos('<>-', MethodStr) <> 0 then
            Kid := CopyStr(TempKid, StrLen(TempKid) - 25, 25) // 25 last chars. without last control char..
        else
            Kid := CopyStr(TempKid, StrLen(TempKid) - 24); // 25 last chars

        case Method of
            '<': // Modulus 10 control:
                if not Modulus10KID(Kid) then
                    ErrText := WrongKIDNo10Msg;
            '>': // CDV-11 control:
                if not Modulus11KID(Kid) then
                    ErrText := WrongKIDNo11Msg;
            '-':
                ErrText := ''; // No control
            else // No control char. Check both modulus 10 and 11:
                if (not Modulus10KID(Kid)) and (not Modulus11KID(Kid)) then
                    ErrText := WrongKIDNo10and11Msg;
        end;

        exit(ErrText);
    end;

    procedure CheckMessage(AgreementCode: Code[10]; MessageText: Text[250])
    var
        RemAgreement: Record "Remittance Agreement";
    begin
        // Check the message length. Error if it's too long.
        RemAgreement.Get(AgreementCode);
        if StrLen(MessageText) > MaxMessageLength(RemAgreement) then
            Error(TooLongMessageErr, MaxMessageLength(RemAgreement));
    end;

    procedure Modulus10KID(Kid: Code[26]): Boolean
    var
        t: array[12] of Integer;
        i: Integer;
        TempStr: Text[30];
        ControlDigit: Text[30];
    begin
        // Rest = 0 er OK. [10.1 p57]

        ControlDigit := Kid; // Control digit. Later changed at char 2, 4, 6..24

        // Calculate control digit for char. 2, 4, 6, 8, 10..24:
        for i := 1 to 12 do
            Evaluate(t[i], CopyStr(Kid, i * 2, 1));

        // Multipl. with weight.:
        for i := 1 to 12 do begin
            t[i] := t[i] * 2; // Multiplicate with weighting.
                              // Check if larger then 10.
                              // If larger then 10, calcualte sum of the digits:
            if t[i] > 10 then begin
                TempStr := Format(t[i]);
                t[i] := 99 - StrCheckSum(TempStr, '11', 99);
            end;
            TempStr := Format(t[i]);
            ControlDigit[i * 2] := TempStr[1];
        end;

        // Sum of the digits dividable with 10 is OK:
        exit(StrCheckSum(ControlDigit, '1111111111111111111111111', 10) = 0);
    end;

    procedure Modulus11KID(Kid: Code[26]): Boolean
    begin
        // REST = 0 is OK.
        exit(StrCheckSum(Kid, '7654327654327654327654321', 11) = 0);
    end;

    procedure FormatAccountNo(AccountNo: Code[30]) Returnvar: Code[30]
    var
        i: Integer;
    begin
        // Format account no. Delete the blanks.
        Returnvar := '';
        // Deletes everything but 0..9:
        for i := 1 to StrLen(AccountNo) do begin
            // Controls valid char.:
            if StrPos('0123456789 -.,', CopyStr(AccountNo, i, 1)) = 0 then
                Error(NonDigitCharErr);
            // Create correct account no. with numerical chars. only:
            if StrPos('0123456789', CopyStr(AccountNo, i, 1)) > 0 then
                Returnvar := Returnvar + CopyStr(AccountNo, i, 1);
        end;
        exit(Returnvar);
    end;

    procedure FormatNum(FormatAmount: Decimal; Length: Integer; Decimals: Boolean): Text[50]
    var
        AmountStr: Text[50];
        DecimalStr: Text[50];
        IntegerStr: Text[50];
        TempDecimal: Decimal;
    begin
        // Format numerical field.
        // Decimals=True: Decimals are two last digits. =False: No decimals.
        // Note: Sign is NOT set.
        // RETURN: Text with number char., length, right-aligned amount and leading zeros.
        // Exmpl: beløp = 34,6 , length = 11, decimals = True. Returns='00000003460'.

        if Decimals then begin
            TempDecimal := (FormatAmount - Round(FormatAmount, 1, '<')) * 100; // Exmpl: 34,6 -> 60 Exmpl2: 34.56789 -> 56.789
            TempDecimal := Round(TempDecimal, 1, '<'); // Exmpl: 60 -> 60   Exmpl2: 56.789 -> 56
            DecimalStr := Format(TempDecimal, 2, '<integer>');
        end else
            DecimalStr := '';
        IntegerStr := Format(FormatAmount, Length - StrLen(DecimalStr), '<integer>');
        AmountStr := ConvertStr(IntegerStr + DecimalStr, ' ', '0');  // Replace ' ' with '0'.
        exit(AmountStr);
    end;

    procedure FormatNumStr(AmountText: Text[30]; Length: Integer): Text[50]
    var
        AmountNum: Decimal;
        FormattedAmount: Text[50];
        i: Integer;
    begin
        // Same as in FormatNum, only with text as a parameter.
        // ALL chars, except numbers, are deleted before converting to amount.

        // EVALUATE(amount,amountStr) is not in use, since amountStr is not allways a correct number.
        // Extract digits:
        FormattedAmount := '0';  // Is min. a '0'.
        for i := 1 to StrLen(AmountText) do
            if StrPos('0123456789', CopyStr(AmountText, i, 1)) > 0 then
                FormattedAmount := FormattedAmount + CopyStr(AmountText, i, 1);
        Evaluate(AmountNum, FormattedAmount);
        FormattedAmount := FormatNum(AmountNum, Length, false);  // False = no decimals.
        exit(FormattedAmount);
    end;

    procedure Modulus11(AccountNo: Text[30]): Boolean
    begin
        // Rest = 0 is OK. [10.3 p58]
        exit(StrCheckSum(AccountNo, '5432765432', 11) = 0);
    end;

    procedure Modulus10(AccountNo: Text[30]): Boolean
    var
        t: array[11] of Integer;
        TempStr: Text[30];
        i: Integer;
        ControlDigit: Text[30];
    begin
        // Rest = 0 is OK. [10.1 p57]
        // Create account no. with 11 chars:
        if StrLen(AccountNo) = 7 then
            AccountNo := StrSubstNo('0000%1', AccountNo);
        ControlDigit := AccountNo; // Control digit. Later changed at char. 2, 4, 6..10

        // Calculate ControlDigit at chars. 2, 4, 6, 8 and 10:
        Evaluate(t[1], CopyStr(AccountNo, 2, 1));
        Evaluate(t[2], CopyStr(AccountNo, 4, 1));
        Evaluate(t[3], CopyStr(AccountNo, 6, 1));
        Evaluate(t[4], CopyStr(AccountNo, 8, 1));
        Evaluate(t[5], CopyStr(AccountNo, 10, 1));
        // multipl. with weighting:
        for i := 1 to 5 do begin
            t[i] := t[i] * 2; // Multiplicate with weighting.
                              // Check if larger then 10.
                              // If larger then 10 calculate sum of the digits:
            if t[i] > 10 then begin
                TempStr := Format(t[i]);
                t[i] := 99 - StrCheckSum(TempStr, '11', 99); // sum of the digits
            end;
            TempStr := Format(t[i]);
            ControlDigit[i * 2] := TempStr[1];
        end;

        // sum of the digits is dividable with 10, OK:
        exit(StrCheckSum(ControlDigit, '11111111111', 10) = 0);
    end;

    procedure NextSeqNo(var RemAgreement: Record "Remittance Agreement"; NoType: Option Daily,Global): Code[6]
    var
        Returnvar: Code[10];
        NextNo: Integer;
    begin
        // Find next sequence number for RemAccount, depending on parameter.
        // Daily : no. is returned with the length of 6 chars. Global: the length is 4. Leading zeros.
        RemAgreement.LockTable();
        case NoType of
            NoType::Daily:
                begin
                    if RemAgreement."Latest Export" <> Today then // Not exported today. Start at 000001.
                        NextNo := 1
                    else
                        NextNo := RemAgreement."Latest Daily Sequence No." + 1;
                    if NextNo > 999999 then
                        NextNo := 1;
                    RemAgreement."Latest Daily Sequence No." := NextNo;
                    RemAgreement."Latest Export" := Today;
                    // Length 6 char:
                    Returnvar := StrSubstNo('00000%1', NextNo);
                    Returnvar := CopyStr(Returnvar, StrLen(Returnvar) - 5);
                end;
            NoType::Global:
                begin
                    NextNo := RemAgreement."Latest Sequence No." + 1;
                    if NextNo > 9999 then // Start from the beginning with 0000. OBS: The first one should be 0001.
                        NextNo := 0;
                    RemAgreement."Latest Sequence No." := NextNo;
                    // Length 4 char:
                    Returnvar := StrSubstNo('00000%1', NextNo);
                    Returnvar := CopyStr(Returnvar, StrLen(Returnvar) - 3); // Last 4 chars.
                end;
        end;
        RemAgreement.Modify(true);
        exit(Returnvar);
    end;

    procedure CreateJournalData(var GenJournalLine: Record "Gen. Journal Line"; VendEntry: Record "Vendor Ledger Entry")
    var
        Vendor: Record Vendor;
        RemAccount: Record "Remittance Account";
    begin
        // Insert remittance data in journal line
        GenJournalLine.TestField("Account Type", GenJournalLine."Account Type"::Vendor);
        Vendor.Get(GenJournalLine."Account No.");
        RemAccount.Get(Vendor."Remittance Account Code");

        // Insert remittance info:
        GenJournalLine.Validate("Remittance Account Code", Vendor."Remittance Account Code");
        GenJournalLine.Validate("Payment Due Date", VendEntry."Due Date");
        GenJournalLine.Validate("Remittance Type", RemAccount.Type);
        GenJournalLine.Validate("Payment Type Code Domestic", Vendor."Payment Type Code Domestic");
        GenJournalLine."Our Account No." := Vendor."Our Account No.";
        GenJournalLine.Validate("BOLS Text Code", Vendor."BOLS Text Code");
        GenJournalLine.Validate(KID, VendEntry.KID);
        GenJournalLine.Validate("Payment Type Code Abroad", Vendor."Payment Type Code Abroad");
        GenJournalLine.Validate("Specification (Norges Bank)", Vendor."Specification (Norges Bank)");
        GenJournalLine.Validate("Futures Contract No.", RemAccount."Futures Contract No.");
        GenJournalLine.Validate("Futures Contract Exch. Rate", RemAccount."Futures Contract Exch. Rate");

        GenJournalLine."Structured Payment" := not ((GenJournalLine.KID = '') and (GenJournalLine."External Document No." = ''));

        case RemAccount.Type of
            RemAccount.Type::Domestic:
                if not GenJournalLine."Structured Payment" then begin
                    // Insert formatted text on unstructured payments
                    GenJournalLine.Validate("Recipient Ref. 1", FormatRecipientRef(RemAccount, GenJournalLine, 1));
                    GenJournalLine.Validate("Recipient Ref. 2", FormatRecipientRef(RemAccount, GenJournalLine, 2));
                    GenJournalLine.Validate("Recipient Ref. 3", FormatRecipientRef(RemAccount, GenJournalLine, 3));
                end;
            RemAccount.Type::Foreign:
                GenJournalLine.Validate("Recipient Ref. Abroad", FormatRecipientRef(RemAccount, GenJournalLine, 0));
        end;
    end;

    procedure MarkEntry(JournalLine: Record "Gen. Journal Line"; Mark: Text[3]; PaymOrderID: Integer)
    var
        VendEntry: Record "Vendor Ledger Entry";
    begin
        // Marks the entries for journal line.
        // 1. vendEntryRec."On Hold" is marked, and therefor exempted from later payment suggestions.
        // Mark '' is used to delete marks.
        // 2. vendEntryRec."Remittance ID" is a reference for remittance.
        // If 0 is specified in PaymOrderID, the ID is not changed.

        // No entries to balance. No entries are marked then.
        if JournalLine."Applies-to Doc. No." = '' then
            exit;

        SearchEntry(JournalLine, VendEntry);

        // Mark entries:
        if PaymOrderID <> 0 then  // If id=0, the id is not changed in the entry:
            VendEntry.ModifyAll("Remittance ID", PaymOrderID);
        VendEntry.ModifyAll("On Hold", Mark);
    end;

    procedure SearchEntry(JournalLine: Record "Gen. Journal Line"; var VendEntry: Record "Vendor Ledger Entry")
    begin
        // Find entry(s) for journal line:
        VendEntry.Init();
        VendEntry.SetCurrentKey("Document No.");
        VendEntry.SetRange("Document Type", JournalLine."Applies-to Doc. Type");
        VendEntry.SetRange("Document No.", JournalLine."Applies-to Doc. No.");
        VendEntry.SetRange("Vendor No.", JournalLine."Account No.");
        VendEntry.FindLast();

        // Check if the entry is unique
        if VendEntry.Count <> 1 then
            Error(
              WrongEntryErr, VendEntry.Count, JournalLine."Line No.", VendEntry."Vendor No.", VendEntry."Entry No.");
        if JournalLine."Account Type" <> JournalLine."Account Type"::Vendor then
            Error(
              WrongAccountTypeErr, JournalLine."Line No.", JournalLine."Account Type", VendEntry."Vendor No.",
              VendEntry."Entry No.");
    end;

    procedure FormatRecipientRef(RemAccount: Record "Remittance Account"; GenJnlLine: Record "Gen. Journal Line"; RefNo: Integer): Text[80]
    var
        RemAgreement: Record "Remittance Agreement";
        Vendor: Record Vendor;
        VendEntry: Record "Vendor Ledger Entry";
        Message: Text[250];
        Ref1: Text[80];
        Ref2: Text[80];
        Ref3: Text[80];
        RefU: Text[80];
    begin
        // Format the message and check the length
        RemAgreement.Get(RemAccount."Remittance Agreement Code");
        Vendor.Get(GenJnlLine."Account No.");
        if GenJnlLine."Applies-to Doc. No." <> '' then
            SearchEntry(GenJnlLine, VendEntry)
        else
            VendEntry.Init();
        // Decide if the recipient ref. comes from vendor or rem. account, and if the text is for invoice or credit memo
        if Vendor."Own Vendor Recipient Ref." then begin
            if GenJnlLine.Amount >= 0 then begin
                Ref1 := Vendor."Recipient ref. 1 - inv.";
                Ref2 := Vendor."Recipient ref. 2 - inv.";
                Ref3 := Vendor."Recipient ref. 3 - inv.";
            end else begin
                Ref1 := Vendor."Recipient ref. 1 - cred.";
                Ref2 := Vendor."Recipient ref. 2 - cred.";
                Ref3 := Vendor."Recipient ref. 3 - cred.";
            end;
            RefU := Vendor."Recipient Ref. Abroad";
        end else begin
            if GenJnlLine.Amount >= 0 then begin
                Ref1 := RemAccount."Recipient ref. 1 - Invoice";
                Ref2 := RemAccount."Recipient ref. 2 - Invoice";
                Ref3 := RemAccount."Recipient ref. 3 - Invoice";
            end else begin
                Ref1 := RemAccount."Recipient ref. 1 - Cr. Memo";
                Ref2 := RemAccount."Recipient ref. 2 - Cr. Memo";
                Ref3 := RemAccount."Recipient ref. 3 - Cr. Memo";
            end;
            RefU := RemAccount."Recipient Ref. Abroad";
        end;
        // Decides which message is used
        case RemAccount.Type of
            RemAccount.Type::Domestic:
                case RefNo of
                    1:
                        Message := Ref1;
                    2:
                        Message := Ref2;
                    3:
                        Message := Ref3;
                end;
            RemAccount.Type::Foreign:
                Message := RefU;
        end;

        // Format the text. Following formating is done:
        // %1: document type
        // %2: VendEntry."External Document No."
        // %3: VendEntry."Our accountno."
        // %4: VendEntry."Document No."
        // %5: VendEntry.Description
        // %6: VendEntry.Amount
        // %7: VendEntry.Restamount
        // %8: VendEntry."Amount (NOK)"
        // %9: VendEntry."Currency code"
        // %10: VendEntry."Payment term"
        // %11: VendEntry.KID
        Message :=
          StrSubstNo(Message, VendEntry."Document Type", VendEntry."External Document No.", Vendor."Our Account No.",
            VendEntry."Document No.", VendEntry.Description, Abs(VendEntry.Amount), Abs(VendEntry."Remaining Amount"),
            Abs(VendEntry."Amount (LCY)"), VendEntry."Currency Code", VendEntry."Due Date", VendEntry.KID);

        if StrLen(Message) > MaxMessageLength(RemAgreement) then
            if Vendor."Own Vendor Recipient Ref." then
                Error(
                  text018 + text019 + text020 + text021,
                  VendEntry."Vendor No.", VendEntry."Document Type", VendEntry."Document No.",
                  MaxMessageLength(RemAgreement), CopyStr(Message, 1, 40))
            else
                Error(
                  text018 + text019 + text020 + text022,
                  VendEntry."Vendor No.", VendEntry."Document Type", VendEntry."Document No.",
                  MaxMessageLength(RemAgreement), CopyStr(Message, 1, 40),
                  RemAccount.Code);

        exit(Message);
    end;

    procedure MaxMessageLength(RemAccount: Record "Remittance Agreement"): Integer
    begin
        // Check text length
        if RemAccount."Payment System" = RemAccount."Payment System"::BBS then
            exit(80);

        exit(40);
    end;

    [Scope('OnPrem')]
    procedure NewFilename(FileName: Text[250]): Text[250]
    var
        File1: Text[250];
    begin
        // rename the file in a following way: Exmpl of a fileName=Text002:
        // 1. Evt. file 'c:\payment.d~~' is deleted.
        // 2. Evt. file 'c:\payment.da~' is renamed to 'c:\betaling.d~~'.
        // 3. File 'c:\payment.dat' is renamed to 'c:\payment.da~'.
        // This is used to save old versions of payment files and return data. If the user
        // forgets to import a file for ex., the file will get an ~ ending after the next import.
        // RETURN: New filename of the current file.

        // If one of the two last chras. is  ~ , the new filename is NOT created.
        // This because the name already exists, as an older file
        // for ex. if the user imports an old file

        exit(File1);
    end;

    procedure SettleWaitingJournal(GenJnlLine: Record "Gen. Journal Line")
    var
        WaitingJnlLine: Record "Waiting Journal";
    begin
        // Mark the status as settled in waiting journal belonging to the journal line
        if GenJnlLine."Waiting Journal Reference" = 0 then
            exit;
        WaitingJnlLine.Get(GenJnlLine."Waiting Journal Reference");
        WaitingJnlLine.Validate("Remittance Status", WaitingJnlLine."Remittance Status"::Settled);
        WaitingJnlLine.Modify(true);
        // Update entry. 'REM' OnHold-mark is removed:
        MarkEntry(GenJnlLine, '', 0);
    end;

    procedure SettlePaymOrdWithoutReturnFile(PaymOrder: Record "Remittance Payment Order"; GenJnlLine: Record "Gen. Journal Line")
    var
        WaitingJournal: Record "Waiting Journal";
        RemAccount: Record "Remittance Account";
        NoSeries: Codeunit "No. Series";
        NextLineNo: Integer;
        NextDocumentNo: Code[20];
    begin
        // Settle a payment order without import of a return file
        // Payments are created in a journal specified in GenJnlLine
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        if GenJnlLine.FindLast() then
            NextLineNo := GenJnlLine."Line No."
        else
            NextLineNo := 10000;
        RemAccount.Get(GenJnlLine."Remittance Account Code");

        WaitingJournal.SetRange("Payment Order ID - Sent", PaymOrder.ID);
        if WaitingJournal.FindSet() then
            repeat
                NextDocumentNo := NoSeries.GetNextNo(RemAccount."Document No. Series");

                GenJnlLine.Validate("Line No.", NextLineNo);
                NextLineNo := NextLineNo + 10000;
                GenJnlLine.Validate("Document No.", NextDocumentNo);
                GenJnlLine.Validate("Bal. Account Type", RemAccount."Account Type");

                GenJnlLine.Validate("Bal. Account No.", RemAccount."Account No.");
                SettlePaymentWithoutReturnFile(WaitingJournal, GenJnlLine);
            until WaitingJournal.Next() = 0;
    end;

    procedure SettlePaymentWithoutReturnFile(WaitingJournal: Record "Waiting Journal"; GenJnlLine: Record "Gen. Journal Line")
    var
        StoreGenJnlLine: Record "Gen. Journal Line";
    begin
        // Settle a payment without import of a return file
        // GenJnlline is initialized with following fields:
        // Line no., Document no., Bal. Account type, Bal. account no. Remaining fields are initialized here..
        StoreGenJnlLine := GenJnlLine;
        GenJnlLine.TransferFields(WaitingJournal);
        GenJnlLine.Validate("Line No.", StoreGenJnlLine."Line No.");
        GenJnlLine.Validate("Document No.", StoreGenJnlLine."Document No.");
        GenJnlLine.Validate("Bal. Account Type", StoreGenJnlLine."Bal. Account Type");
        GenJnlLine.Validate("Bal. Account No.", StoreGenJnlLine."Bal. Account No.");
        GenJnlLine.Insert(true);
    end;

    procedure InsertWarning(var GenJnlLine: Record "Gen. Journal Line"; Text: Text[100])
    begin
        GenJnlLine.Validate("Remittance Warning", true);
        GenJnlLine.Validate("Remittance Warning Text", Text);
    end;

    procedure PrintPaymentOverview(RemPaymOrderID: Integer)
    var
        RemPaymOrder: Record "Remittance Payment Order";
        WaitingJournalLine: Record "Waiting Journal";
    begin
        WaitingJournalLine.SetFilter(
          "Remittance Status", '%1|%2',
          WaitingJournalLine."Remittance Status"::Sent, WaitingJournalLine."Remittance Status"::Approved);
        if RemPaymOrder.Get(RemPaymOrderID) then
            WaitingJournalLine.SetRange("Payment Order ID - Sent", RemPaymOrder.ID);
        // TODO: Revert code after report upgrading.
        // PaymentOverview.SETTABLEVIEW(WaitingJournalLine);
        // PaymentOverview.Run();
    end;

    procedure ReturnError(ReturnCode: Text[2]): Text[250]
    var
        ErrorText: Text[250];
    begin
        // If error text returns '', then it's not an error
        case ReturnCode of
            '00':
                ErrorText := text023;
            '01':
                ErrorText := '';
            '02':
                ErrorText := '';
            '10':
                ErrorText := text024;
            '11':
                ErrorText := text025;
            '12':
                ErrorText := text026;
            '13':
                ErrorText := text027;
            '14':
                ErrorText := text028;
            '15':
                ErrorText := text060;
            '16':
                ErrorText := text061;
            '17':
                ErrorText := text029;
            '18':
                ErrorText := text062;
            '19':
                ErrorText := text030;
            '20':
                ErrorText := text031;
            '21':
                ErrorText := text032;
            '22':
                ErrorText := text033;
            '25':
                ErrorText := text034;
            '26':
                ErrorText := text035;
            '27':
                ErrorText := text036;
            '28':
                ErrorText := text037;
            '29':
                ErrorText := text038;
            '30':
                ErrorText := text039;
            '34':
                ErrorText := text040;
            '35':
                ErrorText := text041;
            '36':
                ErrorText := text042;
            '37':
                ErrorText := text063;
            '38':
                ErrorText := text064;
            '39':
                ErrorText := text065;
            '40':
                ErrorText := text066;
            '41':
                ErrorText := text043;
            '42':
                ErrorText := text067;
            '43':
                ErrorText := text068;
            '44':
                ErrorText := text044;
            '45':
                ErrorText := text069;
            '80':
                ErrorText := text045;
            '81':
                ErrorText := text046;
            '82':
                ErrorText := text047;
            '83':
                ErrorText := text048;
            '84':
                ErrorText := text070;
            '85':
                ErrorText := text071;
            '86':
                ErrorText := text072;
            '87':
                ErrorText := text073;
            '88':
                ErrorText := text074;
            '89':
                ErrorText := text049;
            '90':
                ErrorText := text050;
            '91':
                ErrorText := text051;
            '92':
                ErrorText := text052;
            '95':
                ErrorText := text053;
            else
                ErrorText := text054;
        end;
        if ErrorText <> '' then
            ErrorText := StrSubstNo(text055, ReturnCode, ErrorText);
        exit(ErrorText);
    end;

    procedure NextBBSPaymOrderNo(RemAgreement: Record "Remittance Agreement"): Integer
    begin
        // Find and update next payment order no. for BBS payments.
        RemAgreement.LockTable();
        RemAgreement."Latest BBS Payment Order No." := RemAgreement."Latest BBS Payment Order No." + 1;
        if RemAgreement."Latest BBS Payment Order No." > 9999999 then
            RemAgreement."Latest BBS Payment Order No." := 1;
        RemAgreement.Modify(true);
        exit(RemAgreement."Latest BBS Payment Order No.");
    end;

    procedure VendorInitRecipientRef(var Vendor: Record Vendor; RemAccount: Record "Remittance Account")
    begin
        case RemAccount.Type of
            RemAccount.Type::Domestic:
                begin
                    // Not specified. insert def.
                    Vendor.Validate("Recipient ref. 1 - inv.", RemAccount."Recipient ref. 1 - Invoice");
                    Vendor.Validate("Recipient ref. 2 - inv.", RemAccount."Recipient ref. 2 - Invoice");
                    Vendor.Validate("Recipient ref. 3 - inv.", RemAccount."Recipient ref. 3 - Invoice");
                    Vendor.Validate("Recipient ref. 1 - cred.", RemAccount."Recipient ref. 1 - Cr. Memo");
                    Vendor.Validate("Recipient ref. 2 - cred.", RemAccount."Recipient ref. 2 - Cr. Memo");
                    Vendor.Validate("Recipient ref. 3 - cred.", RemAccount."Recipient ref. 3 - Cr. Memo");
                end;
            RemAccount.Type::Foreign:
                Vendor.Validate("Recipient Ref. Abroad", RemAccount."Recipient Ref. Abroad");
        end;
    end;
}

