codeunit 132476 "API Mock Events"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        MockIsAPIEnabled: Boolean;
        MockIntegrationManagementEnabled: Boolean;
        MultipleTestHandlersOnEventErr: Label 'There are multiple subscribers competing for the handled in the tests.';

    procedure SetAPIServicesEnabled(Value: Boolean)
    begin
        UnbindSubscription(this);
        SetIsAPIEnabled(Value);
        BindSubscription(this);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'OnGetIsAPIEnabled', '', false, false)]
    local procedure HandleOnGetIsAPIEnabled(var Handled: Boolean; var IsAPIEnabled: Boolean)
    begin
        if Handled then
            Error(MultipleTestHandlersOnEventErr);

        Handled := true;
        IsAPIEnabled := MockIsAPIEnabled;
    end;

    procedure SetIsAPIEnabled(NewIsAPIEnabled: Boolean)
    begin
        MockIsAPIEnabled := NewIsAPIEnabled;
    end;

    procedure SetIsIntegrationManagementEnabled(NewIsIntegrationManagementEnabled: Boolean)
    begin
        MockIntegrationManagementEnabled := NewIsIntegrationManagementEnabled;
    end;
}

