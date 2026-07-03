// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.Foundation.Company;
using System.Reflection;

/// <summary>
/// Defines country-specific VAT registration number formats for validation and duplicate checking.
/// Provides pattern matching capabilities and business rules enforcement for VAT numbers across different jurisdictions.
/// </summary>
codeunit 13381 "VAT Reg. No. Format NL"
{
    [EventSubscriber(ObjectType::Table, Database::"VAT Registration No. Format", OnBeforeCheckCompanyInfo, '', false, false)]
    local procedure OnBeforeCheckCompanyInfo(VATRegNo: Text[20]; var IsHandled: Boolean)
    var
        CompanyInformation: Record "Company Information";
        Mod11ErrorText: Text;
        Mod97ErrorText: Text;
        Number: Integer;
    begin
        if not CompanyInformation.Get() then
            exit;

        if UpperCase(CopyStr(VATRegNo, 1, 2)) <> 'NL' then
            if CompanyInformation."Country/Region Code" <> 'NL' then
                exit  // Not an NL VAT Registration No.
            else
                if not Evaluate(Number, CopyStr(VATRegNo, 1, 2)) then
                    exit; // Not an NL VAT Registration No.

        // last two chars must be digits
        Number := 0;
        if not Evaluate(Number, CopyStr(VATRegNo, StrLen(VATRegNo) - 1)) then
            Error(SummaryTwoErr, VATRegNoFormatErr, VATRegNoLastTwoCharsErr);
        if Number = 0 then
            Error(SummaryTwoErr, VATRegNoFormatErr, VATRegNoLastTwoCharsErr);

        Mod11ErrorText := ValidateVATMod11Algorithm(VATRegNo);
        Mod97ErrorText := ValidateVATMod97Algorithm(VATRegNo);
        if (Mod11ErrorText <> '') and (Mod97ErrorText <> '') then
            Error(SummaryThreeErr, VATRegNoFormatErr, Mod11ErrorText, Mod97ErrorText);

        IsHandled := true;
    end;

    local procedure ValidateVATMod11Algorithm(VATRegNo: Text[20]): Text;
    var
        TypeHelper: Codeunit "Type Helper";
        i: Integer;
        Digit: Integer;
        Weight: Integer;
        Total: Integer;
    begin
        if UpperCase(CopyStr(VATRegNo, 1, 2)) = 'NL' then
            VATRegNo := DelStr(VATRegNo, 1, 2);

        if CopyStr(VATRegNo, 1, 3) = '000' then
            exit(VATRegNoShouldNotStartWithErr);

        for i := 1 to 8 do begin
            if TypeHelper.IsDigit(VATRegNo[i]) then
                Evaluate(Digit, Format(VATRegNo[i]))
            else
                exit(VATMod11NotAllowedCharErr);
            Weight := 10 - i;
            Total := Total + Digit * Weight;
        end;

        if TypeHelper.IsDigit(VATRegNo[9]) then
            Evaluate(Digit, Format(VATRegNo[9]))
        else
            exit(VATMod11NotAllowedCharErr);
        Total := Total mod 11;

        if Digit <> Total then
            exit(VATMod11Err);
    end;

    local procedure ValidateVATMod97Algorithm(VATRegNo: Text[20]): Text
    var
        TypeHelper: Codeunit "Type Helper";
        VATDigitTextBuilder: TextBuilder;
        VATDigitString: Text;
        CurrChar: Char;
        CurrNumber: Integer;
        Remainder: Integer;
        i: Integer;
    begin
        // Valid from January 1, 2020 for natural persons who are VAT entrepreneurs.
        // Positions 1-2 must be NL, positions 13-14 must be digits. Positions 3-12 can contain digits, uppercase letters, '+' and '*'.
        // Each letter is replaced by two-digit number, where 'A' = 10, 'B' = 11, ..., 'Z' = 35; '+' = 36, '*' = 37.
        // Remainder of division the converted VAT number by 97 must be equal to 1.
        // Example: NL123456789B13 is converted to 2321 123456789 11 13, i.e. to 23211234567891113 integer number. 23211234567891113 mod 97 = 1, it is a valid VAT number.
        if CopyStr(VATRegNo, 1, 2) <> 'NL' then
            exit(VATFirstTwoCharsErr);

        if StrLen(VATRegNo) <> 14 then
            exit(VATLengthErr);

        for i := 1 to StrLen(VATRegNo) do begin
            CurrChar := VATRegNo[i];
            case true of
                TypeHelper.IsDigit(CurrChar):
                    CurrNumber := CurrChar - '0';   // convert char digit to int, '1' -> 1 etc.
                TypeHelper.IsUpper(CurrChar):
                    CurrNumber := CurrChar - 55;    // convert uppercase letter to int, 'A' -> 10 etc.
                CurrChar = '+':
                    CurrNumber := 36;               // special case for '+' and '*'
                CurrChar = '*':
                    CurrNumber := 37;
                else
                    exit(VATMod97NotAllowedCharErr);
            end;
            VATDigitTextBuilder.Append(Format(CurrNumber));
        end;

        // string is used instead of integer to avoid Integer/BigInteger overflow.
        VATDigitString := VATDigitTextBuilder.ToText();
        for i := 1 to StrLen(VATDigitString) do begin
            CurrChar := VATDigitString[i];
            CurrNumber := CurrChar - '0';
            Remainder := (Remainder * 10 + CurrNumber) mod 97;
        end;

        if Remainder <> 1 then
            exit(VATMod97Err);
    end;

    var
        VATRegNoFormatErr: Label 'The entered VAT Registration number is not in agreement with the format specified for electronic tax declaration: ';
        VATRegNoShouldNotStartWithErr: Label 'The VAT Registration number should not start with ''''000''''.';
        VATRegNoLastTwoCharsErr: Label 'The last two characters of the VAT Registration number must be digits, but not equal to ''''00''''.';
        VATLengthErr: Label 'The VAT registration number must be 14 characters long.';
        VATFirstTwoCharsErr: Label 'The first two characters of the VAT registration number must be ''NL''.';
        VATMod11NotAllowedCharErr: Label 'The VAT registration number must have the format NLdddddddddBdd where d is a digit.';
        VATMod97NotAllowedCharErr: Label 'The VAT registration number for a natural person must have the format NLXXXXXXXXXXdd where d is a digit, and x can be a digit, an uppercase letter, ''+'', or ''*''.';
        VATMod11Err: Label 'The VAT registration number is not valid according to the Modulus-11 checksum algorithm.';
        VATMod97Err: Label 'The VAT registration number is not valid according to the Modulus-97 checksum algorithm.';
        SummaryTwoErr: Label '%1%2', Comment = '%1 - VAT registration number, %2 - error text';
        SummaryThreeErr: Label '%1%2 %3', Comment = '%1 - VAT registration number, %2 - error text, %3 - additional error text';
}
