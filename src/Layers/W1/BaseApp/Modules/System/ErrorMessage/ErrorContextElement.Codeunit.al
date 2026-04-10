namespace System.Utilities;

codeunit 30 "Error Context Element"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        ContextRecordID: RecordID;
        ContextFieldNo: Integer;
        Description: Text[250];
        ElementID: Integer;

    procedure GetID(): Integer
    begin
        exit(ElementID);
    end;

    procedure Set(ID: Integer; ContextRecID: RecordID; ContextFldNo: Integer; AdditionalInfo: Text[250])
    begin
        ContextRecordID := ContextRecID;
        ContextFieldNo := ContextFldNo;
        Description := AdditionalInfo;
        ElementID := ID;
    end;

    procedure GetData(var ID: Integer; var ContextRecID: RecordID; var ContextFldNo: Integer; var AdditionalInfo: Text[250])
    begin
        ContextRecID := ContextRecordID;
        ContextFldNo := ContextFieldNo;
        AdditionalInfo := Description;
        ID := ElementID;
    end;

    procedure Copy(ErrorContextElement: Codeunit "Error Context Element")
    var
        ContextRecID: RecordID;
        ID: Integer;
        ContextFldNo: Integer;
        AdditionalInfo: Text[250];
    begin
        ErrorContextElement.GetData(ID, ContextRecID, ContextFldNo, AdditionalInfo);
        Set(ID, ContextRecID, ContextFldNo, AdditionalInfo);
    end;

    procedure GetErrorMessage(var ErrorMessage: Record "Error Message")
    begin
        ErrorMessage.ID := ElementID;
        ErrorMessage.Validate("Context Record ID", ContextRecordID);
        ErrorMessage.Validate("Context Field Number", ContextFieldNo);
        ErrorMessage."Additional Information" := Description;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Error Message Management", 'OnGetTopElementData', '', false, false)]
    local procedure OnGetTopElementDataHandler(var TopElementID: Integer; var ContextRecID: RecordID; var ContextFldNo: Integer; var AdditionalInfo: Text[250])
    begin
        if TopElementID < ElementID then
            GetData(TopElementID, ContextRecID, ContextFldNo, AdditionalInfo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Error Message Management", 'OnGetTopElement', '', false, false)]
    local procedure OnGetTopElementHandler(var TopElementID: Integer)
    begin
        if TopElementID < ElementID then
            TopElementID := ElementID;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Error Message Management", 'OnGetTopContext', '', false, false)]
    local procedure OnGetTopContextHandler(var ErrorMessage: Record "Error Message")
    begin
        if ErrorMessage.ID < ElementID then
            GetErrorMessage(ErrorMessage);
    end;
}

