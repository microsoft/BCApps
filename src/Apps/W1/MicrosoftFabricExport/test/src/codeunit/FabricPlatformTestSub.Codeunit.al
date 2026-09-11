namespace Microsoft.FabricExport;

codeunit 140010 "Fabric Platform Test Sub"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    var
        EnableCalled: Boolean;
        StartCalled: Boolean;
        StopCalled: Boolean;
        DisableCalled: Boolean;

    procedure Reset()
    begin
        EnableCalled := false;
        StartCalled := false;
        StopCalled := false;
        DisableCalled := false;
    end;

    procedure WasEnableCalled(): Boolean
    begin
        exit(EnableCalled);
    end;

    procedure WasStartCalled(): Boolean
    begin
        exit(StartCalled);
    end;

    procedure WasStopCalled(): Boolean
    begin
        exit(StopCalled);
    end;

    procedure WasDisableCalled(): Boolean
    begin
        exit(DisableCalled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Fabric Platform Mgt", OnBeforeEnableExport, '', false, false)]
    local procedure OnBeforeEnable(var IsHandled: Boolean)
    begin
        EnableCalled := true;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Fabric Platform Mgt", OnBeforeStartExport, '', false, false)]
    local procedure OnBeforeStart(var IsHandled: Boolean)
    begin
        StartCalled := true;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Fabric Platform Mgt", OnBeforeStopExport, '', false, false)]
    local procedure OnBeforeStop(var IsHandled: Boolean)
    begin
        StopCalled := true;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Fabric Platform Mgt", OnBeforeDisableExport, '', false, false)]
    local procedure OnBeforeDisable(var IsHandled: Boolean)
    begin
        DisableCalled := true;
        IsHandled := true;
    end;
}
