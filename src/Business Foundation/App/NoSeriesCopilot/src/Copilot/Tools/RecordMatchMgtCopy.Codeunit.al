codeunit 337 "Record Match Mgt. Copy"
{
    //TODO: This is a copy of codeunit 1251 "Record Match Mgt." CalculateStringNearness(). It should be moved to a system app, or replaced with a system function
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

    //TODO: This is a copy of codeunit 1251 "Record Match Mgt." GetLongestCommonSubstring(). It should be moved to a system app, or replaced with a system function
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


    //TODO: This is a copy of codeunit 1251 "Record Match Mgt." GetLengthOfShortestString(). It should be moved to a system app, or replaced with a system function
    local procedure GetLengthOfShortestString(FirstString: Text; SecondString: Text): Integer
    begin
        exit((StrLen(FirstString) + StrLen(SecondString) - Abs(StrLen(FirstString) - StrLen(SecondString))) / 2);
    end;

    //TODO: This is a copy of codeunit 1251 "Record Match Mgt." IsSubstringConsideredForNearness(). It should be moved to a system app, or replaced with a system function
    local procedure IsSubstringConsideredForNearness(Substring: Text; MinThreshold: Integer): Boolean
    var
        Length: Integer;
    begin
        Length := StrLen(Substring);
        if Length <= 1 then
            exit(false);

        exit(MinThreshold <= Length);
    end;

    //TODO: This is a copy of codeunit 7250 "Bank Rec. AI Matching Impl." RemoveShortWords(). It should be moved to a system app, or replaced with a system function
    procedure RemoveShortWords(Text: Text[250]): Text[250];
    var
        Words: List of [Text];
        Word: Text[250];
        Result: Text[250];
    begin
        Words := Text.Split(' '); // split the text by spaces into a list of words
        foreach Word in Words do // loop through each word in the list
            if StrLen(Word) >= 3 then // check if the word length is at least 3
                Result += Word + ' '; // append the word and a space to the result
        Result := CopyStr(Result.TrimEnd(), 1, MaxStrLen(Result)); // remove the trailing space from the result
        Text := Result; // assign the result back to the text parameter
        exit(Text);
    end;
}