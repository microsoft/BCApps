codeunit 132474 "Send Email Mock"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Email Item", 'OnBeforeSend', '', false, false)]
    local procedure HandleOnBeforeSend(EmailScenario: Enum "Email Scenario"; var EmailItem: Record "Email Item"; var HideMailDialog: Boolean; var IsHandled: Boolean; var MailManagement: Codeunit "Mail Management"; var Result: Boolean)
    begin
        if not SupportedScenarios.Contains(EmailScenario) then
            exit;

        IsHandled := true;

        if EmailAddressToFailSending.Contains(EmailItem."Send to") then begin
            Result := false;
            CopyEmailItem(EmailItem, TempGlobalEmailItemsFailedSending);
            exit;
        end;

        Result := true;
        CopyEmailItem(EmailItem, TempGlobalEmailItemsSent);
    end;

    procedure AddSupportedScenario(Scenario: Enum "Email Scenario")
    begin
        SupportedScenarios.Add(Scenario);
    end;

    procedure AddEmailAddressToFailSending(EmailAddress: Text)
    begin
        EmailAddressToFailSending.Add(EmailAddress);
    end;

    procedure GetEmailsSent(var TempEmailItemsSent: Record "Email Item" temporary)
    begin
        TempEmailItemsSent.Reset();
        TempEmailItemsSent.DeleteAll();

        if not TempGlobalEmailItemsSent.FindSet() then
            exit;

        repeat
            CopyEmailItem(TempGlobalEmailItemsSent, TempEmailItemsSent);
        until TempGlobalEmailItemsSent.Next() = 0;
    end;

    procedure GetEmailsFailedSending(var TempEmailItemsFailedSending: Record "Email Item" temporary)
    begin
        TempEmailItemsFailedSending.Reset();
        TempEmailItemsFailedSending.DeleteAll();

        if not TempGlobalEmailItemsFailedSending.FindSet() then
            exit;

        repeat
            CopyEmailItem(TempGlobalEmailItemsFailedSending, TempEmailItemsFailedSending);
        until TempGlobalEmailItemsFailedSending.Next() = 0;
    end;

    local procedure CopyEmailItem(var SourceEmailItem: Record "Email Item"; var TempDestinationEmailItem: Record "Email Item" temporary)
    var
        TempBlobList: Codeunit "Temp Blob List";
        AttachmentNames: List of [Text];
    begin
        TempDestinationEmailItem.Copy(SourceEmailItem);
        SourceEmailItem.GetAttachments(TempBlobList, AttachmentNames);
        TempDestinationEmailItem.SetAttachments(TempBlobList, AttachmentNames);
        if IsNullGuid(TempDestinationEmailItem.ID) then
            TempDestinationEmailItem.ID := CreateGuid();

        TempDestinationEmailItem.Insert(true);
    end;

    var
        TempGlobalEmailItemsSent: Record "Email Item" temporary;
        TempGlobalEmailItemsFailedSending: Record "Email Item" temporary;
        SupportedScenarios: List of [Enum "Email Scenario"];
        EmailAddressToFailSending: List of [Text];
}