codeunit 137226 "Copy Location Test Subscriber"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    var
        TargetLocationCode: Code[10];
        CopyAllOptions: Boolean;

    procedure SetTargetLocationCode(NewTargetCode: Code[10])
    begin
        TargetLocationCode := NewTargetCode;
    end;

    procedure SetCopyAllOptions(CopyAll: Boolean)
    begin
        CopyAllOptions := CopyAll;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Location", 'OnBeforeOnRun', '', false, false)]
    local procedure OnBeforeOnRunCopyLocation(Location: Record Location; var NewLocationCode: Code[10]; var IsLocationCopied: Boolean; var IsHandled: Boolean)
    var
        TempCopyLocationBuffer: Record "Copy Location Buffer" temporary;
        CopyLocation: Codeunit "Copy Location";
    begin
        if TargetLocationCode = '' then
            exit;

        IsHandled := true;

        TempCopyLocationBuffer.Init();
        TempCopyLocationBuffer."Source Location Code" := Location.Code;
        TempCopyLocationBuffer."Target Location Code" := TargetLocationCode;
        TempCopyLocationBuffer.Zones := CopyAllOptions;
        TempCopyLocationBuffer.Bins := CopyAllOptions;
        TempCopyLocationBuffer."Warehouse Employees" := CopyAllOptions;
        TempCopyLocationBuffer."Inventory Posting Setup" := CopyAllOptions;
        TempCopyLocationBuffer.Dimensions := CopyAllOptions;
        TempCopyLocationBuffer."Transfer Routes" := CopyAllOptions;
        TempCopyLocationBuffer.Insert();

        CopyLocation.SetCopyLocationBuffer(TempCopyLocationBuffer);
        CopyLocation.DoCopyLocation();
        NewLocationCode := CopyLocation.GetNewLocationCode();
        IsLocationCopied := true;
    end;
}
