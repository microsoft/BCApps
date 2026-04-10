codeunit 139490 "Transfer Order Events"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Transfer Order] [Event]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestTransferOrderEvents()
    var
        TransferOrderEvents: Codeunit "Transfer Order Events";
    begin
        BindSubscription(TransferOrderEvents);
        VerifySubscriber('OnBeforeTransferOrderPostShipment');
        VerifySubscriber('OnAfterTransferOrderPostShipment');
        VerifySubscriber('OnBeforeTransferOrderPostReceipt');
        VerifySubscriber('OnAfterTransferOrderPostReceipt');
        VerifySubscriber('OnBeforeReleaseTransferDoc');
        VerifySubscriber('OnAfterReleaseTransferDoc');
    end;

    local procedure VerifySubscriber(Subscriber: Text)
    var
        EventSubscription: Record "Event Subscription";
    begin
        EventSubscription.SetRange("Subscriber Codeunit ID", 139490);
        EventSubscription.SetRange("Subscriber Function", Subscriber);
        Assert.IsTrue(EventSubscription.FindFirst(), StrSubstNo('%1 does not apear in the Event Subscriber list', Subscriber));
        Assert.IsTrue(EventSubscription.Active, StrSubstNo('%1 is not active', Subscriber));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnBeforeTransferOrderPostShipment', '', false, false)]
    procedure OnBeforeTransferOrderPostShipment(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnAfterTransferOrderPostShipment', '', false, false)]
    procedure OnAfterTransferOrderPostShipment(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforeTransferOrderPostReceipt', '', false, false)]
    procedure OnBeforeTransferOrderPostReceipt(var TransferHeader: Record "Transfer Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnAfterTransferOrderPostReceipt', '', false, false)]
    procedure OnAfterTransferOrderPostReceipt(var TransferHeader: Record "Transfer Header"; CommitIsSuppressed: Boolean; var TransferReceiptHeader: Record "Transfer Receipt Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Transfer Document", 'OnBeforeReleaseTransferDoc', '', false, false)]
    procedure OnBeforeReleaseTransferDoc(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Transfer Document", 'OnAfterReleaseTransferDoc', '', false, false)]
    procedure OnAfterReleaseTransferDoc(var TransferHeader: Record "Transfer Header")
    begin
    end;
}

