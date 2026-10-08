namespace Microsoft.Sustainability.Posting;

using Microsoft.Sustainability.Ledger;

codeunit 6228 "Sust. Preview Posting Handler"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sustainability Post Mgt", 'OnInsertLedgerEntryOnBeforeInsert', '', false, false)]
    local procedure OnInsertLedgerEntryOnBeforeInsert(var SustainabilityLedgerEntry: Record "Sustainability Ledger Entry"; var IsHandled: Boolean)
    var
        SustPreviewPostInstance: Codeunit "Sust. Preview Post Instance";
    begin
        if IsHandled then
            exit;
        SustPreviewPostInstance.InsertSustLedgEntry(SustainabilityLedgerEntry, true);
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sustainability Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnInsertSustLedgEntry(var Rec: Record "Sustainability Ledger Entry"; RunTrigger: Boolean)
    var
        SustPreviewPostInstance: Codeunit "Sust. Preview Post Instance";
    begin
        SustPreviewPostInstance.InsertSustLedgEntry(Rec, RunTrigger);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sustainability Value Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnInsertSustValueEntry(var Rec: Record "Sustainability Value Entry"; RunTrigger: Boolean)
    var
        SustPreviewPostInstance: Codeunit "Sust. Preview Post Instance";
    begin
        SustPreviewPostInstance.InsertSustValueEntry(Rec, RunTrigger);
    end;

    procedure TryBindPostingPreviewHandler(): Boolean
    begin
        exit(BindSubscription(this));
    end;

    procedure TryUnbindPostingPreviewHandler(): Boolean
    begin
        exit(UnbindSubscription(this));
    end;
}