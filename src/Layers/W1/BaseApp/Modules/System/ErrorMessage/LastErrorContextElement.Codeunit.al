namespace System.Utilities;

codeunit 31 "Last Error Context Element"
{
    SingleInstance = true;

    var
        LastErrorContextElement: Codeunit "Error Context Element";

    procedure Set(var ErrorContextElement: Codeunit "Error Context Element")
    begin
        LastErrorContextElement.Copy(ErrorContextElement);
    end;

    procedure Set(ID: Integer; ContextRecID: RecordID; ContextFldNo: Integer; AdditionalInfo: Text[250])
    begin
        LastErrorContextElement.Set(ID, ContextRecID, ContextFldNo, AdditionalInfo);
    end;

    procedure GetErrorMessage(var ErrorMessage: Record "Error Message")
    begin
        ErrorMessage.Init();
        LastErrorContextElement.GetErrorMessage(ErrorMessage);
        ErrorMessage.Context := false;
    end;
}