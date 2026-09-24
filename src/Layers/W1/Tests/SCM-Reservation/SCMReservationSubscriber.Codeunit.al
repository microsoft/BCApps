codeunit 137113 "SCM Reservation Subscriber"
{
    EventSubscriberInstance = Manual;

    var
        ForceErrorForDocumentNo: Code[20];
        ForcedValidationErr: Label 'Forced error to simulate a validation failure during test.';
        CaptureReadIsolation: Boolean;
        RequestedJournalIsolation: IsolationLevel;
        JournalReadIsolation: IsolationLevel;
        JournalReadCount: Integer;

    procedure SetForceErrorForDocumentNo(DocumentNo: Code[20])
    begin
        ForceErrorForDocumentNo := DocumentNo;
    end;

    procedure CaptureReservationReadIsolation(JournalIsolation: IsolationLevel)
    begin
        CaptureReadIsolation := true;
        RequestedJournalIsolation := JournalIsolation;
        JournalReadCount := 0;
    end;

    procedure GetJournalReadIsolation(var ReadCount: Integer): IsolationLevel
    begin
        ReadCount := JournalReadCount;
        exit(JournalReadIsolation);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl. Line-Reserve", 'OnReservEntryExistOnBeforeReservationEntryIsEmpty', '', false, false)]
    local procedure CaptureJournalReadIsolation(var ReservationEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        if not CaptureReadIsolation then
            exit;
        if RequestedJournalIsolation <> IsolationLevel::Default then
            ReservationEntry.ReadIsolation(RequestedJournalIsolation);
        JournalReadCount += 1;
        JournalReadIsolation := ReservationEntry.ReadIsolation();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Order Subform", 'OnBeforeNoOnAfterValidate', '', false, false)]
    local procedure ForceErrorOnNoOnAfterValidate(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
        if (ForceErrorForDocumentNo <> '') and (SalesLine."Document No." = ForceErrorForDocumentNo) then
            Error(ForcedValidationErr);
    end;
}
