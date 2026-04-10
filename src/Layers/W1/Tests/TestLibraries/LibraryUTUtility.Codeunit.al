codeunit 131008 "Library UT Utility"
{

    trigger OnRun()
    begin
    end;

    var
        Str: Text[30];
        Str2: Text[30];

    procedure GetNewCode(): Code[20]
    begin
        if Str = '' then
            Str := 'XX000';
        Str := IncStr(Str);
        exit(Format(Time) + Str);
    end;

    procedure GetNewCode10(): Code[10]
    begin
        if Str2 = '' then
            Str2 := 'X000';
        Str2 := IncStr(Str2);
        exit(CopyStr(Format(Time, 0, '<Standard Format,2>'), 1, 6) + Str2);
    end;

    procedure Clear()
    begin
        Str := '';
        Str2 := '';
    end;
}

