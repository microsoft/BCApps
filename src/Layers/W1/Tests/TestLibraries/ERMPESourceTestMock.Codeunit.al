codeunit 131336 "ERM PE Source Test Mock"
{
    SingleInstance = true;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        Current: Integer;
    begin
        Current := TempBlobList.Count();
        "File Name" := StrSubstNo('ERM PE Source test moq (Key = %1)', Current);
        TempBlobList.Get(Current, TempBlob);
        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo("File Content"));
        RecordRef.SetTable(Rec)
    end;

    var
        TempBlobList: Codeunit "Temp Blob List";

    [Scope('OnPrem')]
    procedure GetTempBlobList(var TempBlobList2: Codeunit "Temp Blob List")
    begin
        TempBlobList2 := TempBlobList
    end;

    [Scope('OnPrem')]
    procedure SetTempBlobList(TempBlobList2: Codeunit "Temp Blob List")
    begin
        TempBlobList := TempBlobList2
    end;

    [Scope('OnPrem')]
    procedure ClearTempBlobList()
    begin
        Clear(TempBlobList)
    end;
}

