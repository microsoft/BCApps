// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Reconciliation;

/// <summary>
/// Provides text matching and similarity algorithms for payment reconciliation and data matching operations.
/// This codeunit implements fuzzy string matching logic used to compare bank statement data with
/// customer and vendor information, enabling automatic payment application based on text similarity.
/// Core algorithms include longest common substring detection, string nearness scoring, and text
/// normalization functions for optimal matching accuracy across different data formats.
/// </summary>
/// <remarks>
/// Key features include configurable similarity thresholds, normalization algorithms for consistent
/// text comparison, substring matching with adjustable minimum lengths, and scoring mechanisms
/// that balance precision with recall for payment matching scenarios. Used extensively by
/// automatic payment application processes to match party names, addresses, and transaction descriptions.
/// </remarks>
codeunit 1251 "Record Match Mgt."
{
    trigger OnRun()
    begin
    end;

    /// <summary>
    /// Finds and returns the longest common substring between two strings.
    /// Performs case-insensitive comparison to identify the longest sequence of characters
    /// that appears in both input strings. Used as a foundation for text similarity scoring
    /// in payment matching algorithms.
    /// </summary>
    /// <param name="FirstString">First string to compare for common substrings.</param>
    /// <param name="SecondString">Second string to compare for common substrings.</param>
    /// <returns>The longest common substring found between the two input strings.</returns>
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
    procedure CalculateStringNearness(FirstString: Text; SecondString: Text; Threshold: Integer; NormalizingFactor: Integer): Integer
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

    /// <summary>
    /// Like CalculateStringNearness, however it doesn't repeatedly takes substrings, only once.
    /// The result is normalized with respect to the length of the BaseString, in contrast with 
    /// CalculateStringNearness where it was normalized with respect ot the shorter one.
    /// </summary>
    /// <param name="ComparingString"></param>
    /// <param name="BaseString"></param>
    /// <param name="NormalizingFactor">Max value returned by this procedure</param>
    /// <returns>A number between 0 and NormalizingFactor representing how much of BaseString was found in ComparingString</returns>
    procedure CalculateExactStringNearness(ComparingString: Text; BaseString: Text; NormalizingFactor: Integer): Integer
    var
        LongestCommonLength: Integer;
    begin
        ComparingString := UpperCase(ComparingString);
        BaseString := UpperCase(BaseString);
        LongestCommonLength := StrLen(GetLongestCommonSubstring(ComparingString, BaseString));

        if BaseString = '' then
            exit(0);
        if StrLen(BaseString) < LongestCommonLength then
            exit(NormalizingFactor);
        exit((NormalizingFactor * LongestCommonLength) div StrLen(BaseString));
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

    local procedure GetLengthOfShortestString(FirstString: Text; SecondString: Text): Integer
    begin
        exit((StrLen(FirstString) + StrLen(SecondString) - Abs(StrLen(FirstString) - StrLen(SecondString))) / 2);
    end;

    /// <summary>
    /// Removes leading and trailing whitespace characters from a string.
    /// Provides consistent text normalization for string comparison operations,
    /// ensuring that whitespace differences do not affect matching accuracy.
    /// </summary>
    /// <param name="InputString">String to trim of leading and trailing whitespace.</param>
    /// <returns>String with leading and trailing whitespace removed.</returns>
    /// <summary>
    /// Removes leading and trailing whitespace characters from a string.
    /// Provides consistent text normalization for string comparison operations,
    /// ensuring that whitespace differences do not affect matching accuracy.
    /// </summary>
    /// <param name="InputString">Text string to trim of leading and trailing whitespace.</param>
    /// <returns>Input string with leading and trailing whitespace removed.</returns>
    procedure Trim(InputString: Text): Text
    begin
        exit(DelChr(DelChr(InputString, '<'), '>'));
    end;
}

