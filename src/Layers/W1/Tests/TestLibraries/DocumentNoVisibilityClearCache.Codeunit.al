codeunit 137777 "DocumentNoVisibilityClearCache"
{
    var
        DocumentNoVisibility: codeunit DocumentNoVisibility;

    [EventSubscriber(ObjectType::Table, Database::"No. Series", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnNoSeriesModify()
    begin
        DocumentNoVisibility.ClearState();
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnNoSeriesInsert()
    begin
        DocumentNoVisibility.ClearState();
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnNoSeriesDelete()
    begin
        DocumentNoVisibility.ClearState();
    end;
}