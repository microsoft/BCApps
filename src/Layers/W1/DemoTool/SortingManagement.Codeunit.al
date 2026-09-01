codeunit 101911 "Sorting Management"
{
    // Data are sorted in-casesensitive and according to numeric values by using this sort key.


    trigger OnRun()
    begin
    end;

    procedure MakeSortKey(String: Text[250]; var SortString: Text[250]; MaxLength: Integer)
    var
        ResultString: Text[250];
        String2: Text[250];
        StopChar: Char;
        i: Integer;
        j: Integer;
    begin
        StopChar := 'x';
        String2[1] := StopChar;
        String2 := UpperCase(String) + String2;
        i := 1;
        while String2[i] <> StopChar do begin
            j := i;
            while String2[j] in ['0' .. '9'] do
                j := j + 1;
            if j > i then begin
                ResultString := ResultString + LengthPrefix(j - i) + CopyStr(String2, i, j - i);
                i := j;
            end else begin
                ResultString := ResultString + CopyStr(String2, i, 1);
                i := i + 1;
            end;
        end;
        SortString := CopyStr(ResultString, 1, MaxLength);
    end;

    local procedure LengthPrefix(Length: Integer): Text[30]
    var
        String: Text[30];
    begin
        if Length <= 9 then
            exit(Format(Length - 1));

        String := Format(Length - 1);
        exit('9' + PadStr('', 3 - StrLen(String), '0') + String);
    end;
}

