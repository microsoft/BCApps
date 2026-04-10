codeunit 131105 "Library - SMTP Mail Handler"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        RunOnAfterTrySendSubscriber: Boolean;
        SenderAddressGlobal: Text;
        SenderNameGlobal: Text;
        DisableSending: Boolean;

    [Scope('OnPrem')]
    procedure AddOnAfterTrySendIgnoringError(IgnoringErrorText: Text)
    begin
        TempNameValueBuffer.Name := CopyStr(IgnoringErrorText, 1, MaxStrLen(TempNameValueBuffer.Name));
        TempNameValueBuffer.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure ActivateOnAfterTrySendSubscriber()
    begin
        RunOnAfterTrySendSubscriber := true;
    end;

    [Scope('OnPrem')]
    procedure SetSenderAddress(SenderAddress: Text)
    begin
        SenderAddressGlobal := SenderAddress;
    end;

    [Scope('OnPrem')]
    procedure SetSenderName(SenderName: Text)
    begin
        SenderNameGlobal := SenderName;
    end;

    [Scope('OnPrem')]
    procedure SetDisableSending(NewDisableSending: Boolean)
    begin
        DisableSending := NewDisableSending;
    end;

    [Scope('OnPrem')]
    procedure DeactivateOnAfterTrySendSubscriber()
    begin
        RunOnAfterTrySendSubscriber := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mail Management", 'OnBeforeDoSending', '', false, false)]
    local procedure CancelSendingOnBeforeDoSending(var CancelSending: Boolean)
    begin
        CancelSending := DisableSending;
    end;
}

