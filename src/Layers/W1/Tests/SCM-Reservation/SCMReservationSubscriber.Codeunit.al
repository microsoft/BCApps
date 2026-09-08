codeunit 137113 "SCM Reservation Subscriber"
{
    EventSubscriberInstance = Manual;

    var
        ForceErrorForDocumentNo: Code[20];
        ForcedValidationErr: Label 'Forced error to simulate a validation failure during test.';

    procedure SetForceErrorForDocumentNo(DocumentNo: Code[20])
    begin
        ForceErrorForDocumentNo := DocumentNo;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Order Subform", 'OnBeforeNoOnAfterValidate', '', false, false)]
    local procedure ForceErrorOnNoOnAfterValidate(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
        if (ForceErrorForDocumentNo <> '') and (SalesLine."Document No." = ForceErrorForDocumentNo) then
            Error(ForcedValidationErr);
    end;
}
