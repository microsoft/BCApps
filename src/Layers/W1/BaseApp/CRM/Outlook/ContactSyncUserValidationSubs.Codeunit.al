namespace Microsoft.CRM.Outlook;
codeunit 7100 "Contact Sync UserSubscriber"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Contact Sync User", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertContactSyncUser(var Rec: Record "Contact Sync User"; RunTrigger: Boolean)
    begin
        Rec.EnforceRecordOwnership();
        Rec.ValidateApprovedGraphDeltaUrl(Rec."Delta Url");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contact Sync User", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyContactSyncUser(var Rec: Record "Contact Sync User"; var xRec: Record "Contact Sync User"; RunTrigger: Boolean)
    begin
        Rec.EnforceRecordOwnershipOnModify(xRec."User ID");
        Rec.ValidateApprovedGraphDeltaUrl(Rec."Delta Url");
    end;
}
