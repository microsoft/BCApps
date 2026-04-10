codeunit 131010 "Library - Office Host Provider"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempExchangeObjectInternal: Record "Exchange Object" temporary;
        GlobalEmailBody: Text;
        InvokeExtensionMsg: Label '%1|%2|%3|%4|%5', Locked = true;

    local procedure Abbreviate(String: Text) Result: Text
    var
        DotNetString: DotNet String;
        Separator: DotNet String;
    begin
        DotNetString := String;
        Separator := '|';

        if DotNetString.Contains(Separator) then begin
            foreach String in DotNetString.Split(Separator.ToCharArray()) do
                Result += CopyStr(String, 1, 100) + '|';

            Result := CopyStr(Result, 1, StrLen(Result) - 1);
        end else
            Result := CopyStr(StrSubstNo('%1', String), 1, 100);
    end;

    local procedure CanHandle(): Boolean
    var
        OfficeAddinSetup: Record "Office Add-in Setup";
    begin
        if OfficeAddinSetup.Get() then
            exit(OfficeAddinSetup."Office Host Codeunit ID" = CODEUNIT::"Library - Office Host Provider");

        exit(false);
    end;

    procedure CreateEmailAttachments(ContentType: Text[250]; AttachmentCount: Integer; OCRAction: Option InitiateSendToOCR,InitiateSendToIncomingDocuments,InitiateSendToWorkFlow; RecRef: RecordRef)
    var
        TempExchangeObject: Record "Exchange Object" temporary;
        TempBlob: Codeunit "Temp Blob";
        LibraryUtility: Codeunit "Library - Utility";
        FileContent: BigText;
        BlobInStream: InStream;
        OutStream: OutStream;
    begin
        repeat
            TempExchangeObject.Init();
            TempExchangeObject.Validate(Type, TempExchangeObject.Type::Attachment);
            TempExchangeObject.Validate("Item ID", CreateGuid());
            TempExchangeObject.Validate(Name, CreateGuid());
            TempExchangeObject.Validate("Parent ID", CreateGuid());
            TempExchangeObject.Validate("Content Type", ContentType);
            TempExchangeObject.Validate(InitiatedAction, OCRAction);
            TempExchangeObject.Validate(RecId, RecRef.RecordId());
            // add an attachment
            FileContent.AddText(LibraryUtility.GenerateRandomAlphabeticText(10, 0));
            TempBlob.CreateOutStream(OutStream);
            FileContent.Write(OutStream);
            TempBlob.CreateInStream(BlobInStream);
            TempExchangeObject.SetContent(BlobInStream);
            if not TempExchangeObject.Insert(true) then
                TempExchangeObject.Modify(true);
            AttachmentCount := AttachmentCount - 1;
        until AttachmentCount = 0;
        Commit();
        TempExchangeObjectInternal.Copy(TempExchangeObject, true);
    end;


    procedure SetEmailBody(NewEmailBody: Text)
    begin
        GlobalEmailBody := NewEmailBody;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Office Host Management", 'OnInitializeHost', '', false, false)]
    local procedure OnInitializeHost(NewOfficeHost: DotNet OfficeHost; NewHostType: Text)
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        if not CanHandle() then
            exit;

        NameValueBuffer.Init();
        NameValueBuffer.ID := SessionId();
        NameValueBuffer.Name := CopyStr(NewHostType, 1, MaxStrLen(NameValueBuffer.Name));
        NameValueBuffer.Insert(true);
        Commit();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Office Host Management", 'OnInitializeContext', '', false, false)]
    local procedure OnInitializeContext(TempNewOfficeAddinContext: Record "Office Add-in Context" temporary)
    var
        OfficeAddinContext: Record "Office Add-in Context";
    begin
        if not CanHandle() then
            exit;

        OfficeAddinContext.DeleteAll();
        OfficeAddinContext := TempNewOfficeAddinContext;
        OfficeAddinContext.Insert(true);
        Commit();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Office Host Management", 'OnGetHostType', '', false, false)]
    local procedure OnGetHostType(var HostType: Text)
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        if not CanHandle() then
            exit;

        NameValueBuffer.Get(SessionId());
        HostType := NameValueBuffer.Name;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Office Host Management", 'OnCloseCurrentPage', '', false, false)]
    local procedure OnCloseCurrentPage()
    begin
        if not CanHandle() then
            exit;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Office Host Management", 'OnInvokeExtension', '', false, false)]
    local procedure OnInvokeExtension(FunctionName: Text; Parameter1: Variant; Parameter2: Variant; Parameter3: Variant; Parameter4: Variant)
    begin
        if not CanHandle() then
            exit;

        Parameter1 := Abbreviate(Parameter1);
        Parameter2 := Abbreviate(Parameter2);
        Parameter3 := Abbreviate(Parameter3);
        Parameter4 := Abbreviate(Parameter4);
        Message(InvokeExtensionMsg, FunctionName, Parameter1, Parameter2, Parameter3, Parameter4);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Office Host Management", 'OnIsHostInitialized', '', false, false)]
    local procedure OnIsHostInitialzed(var Result: Boolean)
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        if not CanHandle() then
            exit;

        Result := NameValueBuffer.Get(SessionId());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Office Host Management", 'OnIsAvailable', '', false, false)]
    local procedure OnIsAvailable(var Result: Boolean)
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        if not CanHandle() then
            exit;

        Result := NameValueBuffer.Get(SessionId());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Office Host Management", 'OnGetTempOfficeAddinContext', '', false, false)]
    local procedure OnGetTempOfficeAddinContext(var TempOfficeAddinContext: Record "Office Add-in Context" temporary)
    var
        OfficeAddinContext: Record "Office Add-in Context";
    begin
        if not CanHandle() then
            exit;

        if OfficeAddinContext.FindLast() then
            TempOfficeAddinContext.Copy(OfficeAddinContext);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Office Host Management", 'OnEmailHasAttachments', '', false, false)]
    local procedure OnEmailHasAttachments(var Result: Boolean)
    begin
        if not CanHandle() then
            exit;

        if not TempExchangeObjectInternal.IsEmpty() then
            Result := true;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Office Host Management", 'OnGetEmailAndAttachmentsForEntity', '', false, false)]
    local procedure OnGetEmailAndAttachmentsForEntity(var TempExchangeObject: Record "Exchange Object" temporary; "Action": Option InitiateSendToOCR,InitiateSendToIncomingDocuments,InitiateSendToWorkFlow,InitiateSendToAttachments; RecRef: RecordRef)
    begin
        if not CanHandle() then
            exit;

        TempExchangeObject.Copy(TempExchangeObjectInternal, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Office Host Management", 'OnGetEmailBody', '', false, false)]
    local procedure OnGetEmailBody(ItemID: Text[250]; var EmailBody: Text)
    begin
        if not CanHandle() then
            exit;

        EmailBody := GlobalEmailBody;
    end;
}

