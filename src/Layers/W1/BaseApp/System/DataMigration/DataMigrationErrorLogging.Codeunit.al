namespace System.Integration;

codeunit 1796 "Data Migration Error Logging"
{
    SingleInstance = true;

    procedure SetLastRecordUnderProcessing(NewLastRecordUnderProcessingId: Text)
    begin
        LastRecordsUnderProcessingIdList.Insert(1, NewLastRecordUnderProcessingId);
        LastrecordsUnderProcessingDateTime.Insert(1, Format(CurrentDateTime, 0, 9));
        if LastRecordsUnderProcessingIdList.Count() > GetMaximumLogSize() then begin
            LastRecordsUnderProcessingIdList.RemoveAt(GetMaximumLogSize() + 1);
            LastrecordsUnderProcessingDateTime.RemoveAt(GetMaximumLogSize() + 1);
        end;
    end;

    procedure GetLastRecordUnderProcessing(): Text
    var
        FirstItem: Text;
    begin
        if LastRecordsUnderProcessingIdList.Count() = 0 then
            exit('');

        if LastRecordsUnderProcessingIdList.Get(1, FirstItem) then
            exit(FirstItem);

        exit('');
    end;

    procedure GetFullListOfLastRecordsUnderProcessingAsText(): Text
    var
        CRLF: Text;
        FullText: Text;
        CurrentItem: Text;
        ModifiedDateTime: Text;
        I: Integer;
    begin
        if LastRecordsUnderProcessingIdList.Count() = 0 then
            exit('');

        CRLF[1] := 13;
        CRLF[2] := 10;
        FullText := '';
        for I := 1 to LastRecordsUnderProcessingIdList.Count() do begin
            LastRecordsUnderProcessingIdList.Get(I, CurrentItem);
            LastrecordsUnderProcessingDateTime.Get(I, ModifiedDateTime);
            FullText += ModifiedDateTime + SeparatorTxt + CurrentItem + CRLF;
        end;

        exit(FullText);
    end;

    procedure ClearLastRecordUnderProcessing()
    begin
        Clear(LastrecordsUnderProcessingDateTime);
        Clear(LastRecordsUnderProcessingIdList);
    end;

    local procedure GetMaximumLogSize(): Integer
    begin
        exit(100);
    end;

    var
        LastRecordsUnderProcessingIdList: List of [Text];
        LastrecordsUnderProcessingDateTime: List of [Text];
        SeparatorTxt: Label ' - ', Locked = true;
}