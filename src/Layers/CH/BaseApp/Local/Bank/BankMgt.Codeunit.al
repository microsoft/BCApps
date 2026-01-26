// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank;

using System.Reflection;

codeunit 11500 BankMgt
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Post account numbers must have a dash on the 3rd and the 2nd last position. i.e. 60-8000-7 or 01-20029-2.';
        Text002: Label 'The post account number must have at least 6 digits.';
        Text003: Label 'The check digit of post account %1 must be %2.';
        Text004: Label 'The check digit for %1 cannot be calculated. The source number may only consist of digits.';

    [Scope('OnPrem')]
    procedure CheckPostAccountNo(_InputAcc: Code[15]) _LongAccNo: Code[20]
    var
        TestString: Code[12];
        SourceCheckDigit: Code[1];
        CalculatedCheckDigit: Code[1];
    begin
        // 30-054703-2

        // CHeck dashes, length and check digit
        if _InputAcc = '' then
            exit;

        // Dash at pos 3 and last - 1
        if (CopyStr(_InputAcc, 3, 1) <> '-') or (CopyStr(_InputAcc, StrLen(_InputAcc) - 1, 1) <> '-') then
            Error(Text000);

        // Too short
        if StrLen(_InputAcc) < 6 then
            Error(Text002);

        // Expand input no. to 11 digits  60-9-9 -> 60-000009-9
        _LongAccNo := CopyStr(_InputAcc, 1, 3) + CopyStr('00000000000', 1, 11 - StrLen(_InputAcc)) + CopyStr(_InputAcc, 4);

        // Prepare no. for check: Remove dashes and check digit. Length 11 -> 9
        TestString := DelChr(_LongAccNo, '=', '-');

        // Last digit as check digit
        SourceCheckDigit := CopyStr(TestString, 9, 1);

        TestString := CopyStr(TestString, 1, 8);

        // Verify check digit
        CalculatedCheckDigit := CalcCheckDigit(TestString);

        if CalculatedCheckDigit <> SourceCheckDigit then
            Error(Text003, _InputAcc, CalculatedCheckDigit);
    end;

    [Scope('OnPrem')]
    procedure CalcCheckDigit(_Input: Text[250]) _Output: Code[1]
    var
        Tabl: array[10] of Integer;
        Carry: Integer;
        Maxlength: Integer;
        Pos: Integer;
        Test: Integer;
        i: Integer;
    begin
        // Verify modul 10 rec. check digit and return it
        if DelChr(_Input, '=', '01234567890') <> '' then
            Error(Text004, _Input);

        Tabl[1] := 0;
        Tabl[2] := 9;
        Tabl[3] := 4;
        Tabl[4] := 6;
        Tabl[5] := 8;
        Tabl[6] := 2;
        Tabl[7] := 7;
        Tabl[8] := 1;
        Tabl[9] := 3;
        Tabl[10] := 5;
        Carry := 0;
        Maxlength := StrLen(_Input);
        Pos := 1;

        while Pos < Maxlength + 1 do begin
            Evaluate(Test, CopyStr(_Input, Pos, 1)); // get 1 testnbr from string
            i := Test + Carry; // add carried to testchar
            if i > 9 then
                i := i - 10;
            Carry := Tabl[i + 1]; // get new carry from table
            Pos := Pos + 1; // set pointer to next char
        end;

        if Carry = 0 then
            Carry := 10; // adjust carry if 0

        _Output := Format(10 - Carry); // calc checkdig. from carry
    end;

    procedure IsCreditReferenceISO11649(PaymentReference: Text): Boolean
    var
        TypeHelper: Codeunit "Type Helper";
        PayRefTextBuilder: TextBuilder;
        PayRefString: Text;
        CurrChar: Char;
        CurrNumber: Integer;
        CheckDigits: Integer;
        Remainder: Integer;
        i: Integer;
    begin
        PaymentReference := DelChr(PaymentReference);
        PaymentReference := UpperCase(PaymentReference);

        // first two chars must be 'RF'
        if CopyStr(PaymentReference, 1, 2) <> 'RF' then
            exit(false);

        // 3rd and 4th chars must be digits
        if not Evaluate(CheckDigits, CopyStr(PaymentReference, 3, 2)) then
            exit(false);

        if StrLen(PaymentReference) > 25 then
            exit(false);

        // RF 12 34567 -> 34567 RF 00
        PaymentReference := CopyStr(PaymentReference, 5) + CopyStr(PaymentReference, 1, 2) + '00';

        for i := 1 to StrLen(PaymentReference) do begin
            CurrChar := PaymentReference[i];
            case true of
                TypeHelper.IsDigit(CurrChar):
                    CurrNumber := CurrChar - '0';   // convert char digit to int, '1' -> 1 etc.
                TypeHelper.IsUpper(CurrChar):
                    CurrNumber := CurrChar - 55;    // convert uppercase letter to int, 'A' -> 10 etc.
                else
                    exit(false);
            end;
            PayRefTextBuilder.Append(Format(CurrNumber));
        end;

        // string is used instead of integer to avoid Integer/BigInteger overflow.
        PayRefString := PayRefTextBuilder.ToText();
        for i := 1 to StrLen(PayRefString) do begin
            CurrChar := PayRefString[i];
            CurrNumber := CurrChar - '0';
            Remainder := (Remainder * 10 + CurrNumber) mod 97;
        end;

        exit(98 - Remainder = CheckDigits);
    end;

    procedure IsQRReference(PaymentReference: Text): Boolean
    var
        CheckDigit: Text[1];
    begin
        // QR Reference must be 27 chars long (26 + 1 check digit) and must contain digits only.
        PaymentReference := DelChr(PaymentReference);
        if (StrLen(PaymentReference) = 27) and (DelChr(PaymentReference, '=', '01234567890') = '') then begin
            CheckDigit := CalcCheckDigit(CopyStr(PaymentReference, 1, 26));
            exit(CheckDigit = CopyStr(PaymentReference, StrLen(PaymentReference)));
        end;

        exit(false);
    end;

    procedure IsQRIBAN(IBAN: Text): Boolean
    var
        IntValue: Integer;
    begin
        // QR-IBAN must have QR-IID between 30000 and 31999, these are positions 5..10, for example CH97 30024 503254925417.
        if Evaluate(IntValue, CopyStr(DelChr(IBAN), 5, 5)) then
            exit((IntValue >= 30000) and (IntValue <= 31999));

        exit(false);
    end;
}

