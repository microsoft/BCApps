namespace Microsoft.Test.Sustainability;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Posting;

codeunit 148230 "Sust Preview Test Subscriber"
{
    EventSubscriberInstance = Manual;
    TableNo = "Sustainability Jnl. Line";

    trigger OnRun()
    var
        SustainabilityPostMgt: Codeunit "Sustainability Post Mgt";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        SustainabilityPostMgt.InsertLedgerEntry(Rec);
        GenJnlPostPreview.ThrowError();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        SustainabilityJnlLine: Record "Sustainability Jnl. Line";
        SustPreviewTestSubscriber: Codeunit "Sust Preview Test Subscriber";
    begin
        SustPreviewTestSubscriber := Subscriber;
        SustainabilityJnlLine.Copy(RecVar);
        Result := SustPreviewTestSubscriber.Run(SustainabilityJnlLine);
    end;
}
