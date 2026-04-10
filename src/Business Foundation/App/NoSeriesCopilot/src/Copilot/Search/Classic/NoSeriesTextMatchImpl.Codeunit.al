// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 337 "No. Series Text Match Impl."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    procedure IsRelevant(FirstString: Text; SecondString: Text): Boolean
    var
        Score: Decimal;
    begin
        FirstString := RemoveShortWords(FirstString);
        SecondString := RemoveShortWords(SecondString);

        Score := CalculateStringNearness(FirstString, SecondString, GetMatchLengthTreshold(), 100) / 100;

        exit(Score >= RequiredNearness());
    end;

    /// <summary>
    /// Computes a nearness score between strings. Nearness is based on repeatedly finding longest common substrings.
    /// Substring matches below Threshold are not considered.
    /// Normalizing factor is the max value returned by this procedure.
    /// </summary>
    /// <param name="FirstString">First string to match</param>
    /// <param name="SecondString">Second string to match</param>
    /// <param name="Threshold">Substring matches below Threshold are not considered</param>
    /// <param name="NormalizingFactor">Max value returned by this procedure</param>
    /// <returns>A number between 0 and NormalizingFactor, representing how much of the strings was matched</returns>
    local procedure CalculateStringNearness(FirstString: Text; SecondString: Text; Threshold: Integer; NormalizingFactor: Integer): Integer
    var
        Result: Text;
        TotalMatchedChars: Integer;
        MinLength: Integer;
        ShouldContinue: Boolean;
    begin
        if (FirstString = '') or (SecondString = '') then
            exit(0);

        FirstString := UpperCase(FirstString);
        SecondString := UpperCase(SecondString);

        MinLength := GetLengthOfShortestString(FirstString, SecondString);
        if MinLength = 0 then
            MinLength := 1;

        TotalMatchedChars := 0;
        Result := GetLongestCommonSubstring(FirstString, SecondString);
        ShouldContinue := IsSubstringConsideredForNearness(Result, Threshold);
        while ShouldContinue do begin
            TotalMatchedChars += StrLen(Result);
            FirstString := DelStr(FirstString, StrPos(FirstString, Result), StrLen(Result));
            SecondString := DelStr(SecondString, StrPos(SecondString, Result), StrLen(Result));
            Result := GetLongestCommonSubstring(FirstString, SecondString);
            ShouldContinue := IsSubstringConsideredForNearness(Result, Threshold);
        end;

        exit((NormalizingFactor * TotalMatchedChars) div MinLength);
    end;

    procedure GetLongestCommonSubstring(FirstString: Text; SecondString: Text): Text
    var
        Result: Text;
        Buffer: Text;
        i: Integer;
        j: Integer;
    begin
        FirstString := UpperCase(FirstString);
        SecondString := UpperCase(SecondString);
        Result := '';

        i := 1;
        while i + StrLen(Result) - 1 <= StrLen(FirstString) do begin
            j := 1;
            while (j + i - 1 <= StrLen(FirstString)) and (j <= StrLen(SecondString)) do begin
                if StrPos(SecondString, CopyStr(FirstString, i, j)) > 0 then
                    Buffer := CopyStr(FirstString, i, j);

                if StrLen(Buffer) > StrLen(Result) then
                    Result := Buffer;
                Buffer := '';
                j += 1;
            end;
            i += 1;
        end;

        exit(Result);
    end;


    local procedure GetLengthOfShortestString(FirstString: Text; SecondString: Text): Integer
    begin
        exit((StrLen(FirstString) + StrLen(SecondString) - Abs(StrLen(FirstString) - StrLen(SecondString))) / 2);
    end;

    local procedure IsSubstringConsideredForNearness(Substring: Text; MinThreshold: Integer): Boolean
    var
        Length: Integer;
    begin
        Length := StrLen(Substring);
        if Length <= 1 then
            exit(false);

        exit(MinThreshold <= Length);
    end;

    local procedure RemoveShortWords(OriginalText: Text): Text;
    var
        Words: List of [Text];
        Word: Text;
        Result: Text;
    begin
        Words := OriginalText.Split(' '); // split the text by spaces into a list of words
        foreach Word in Words do // loop through each word in the list
            if StrLen(Word) >= 3 then // check if the word length is at least 3
                Result += Word + ' '; // append the word and a space to the result
        Result := CopyStr(Result.TrimEnd(), 1, MaxStrLen(Result)); // remove the trailing space from the result
        OriginalText := Result; // assign the result back to the text parameter
        exit(OriginalText);
    end;

    local procedure GetMatchLengthTreshold(): Decimal
    begin
        exit(2);
    end;

    local procedure RequiredNearness(): Decimal
    begin
        exit(0.9)
    end;
}