codeunit 148134 "Cash Doc. Release Handler CZP"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cash Document-Release CZP", 'OnBeforeCheckMandatoryFieldsSkipAmounts', '', false, false)]
    local procedure SetSkipAmountsTestFieldsOnBeforeCheckMandatoryFieldsSkipAmounts(CashDocumentHeaderCZP: Record "Cash Document Header CZP"; var SkipAmountsTestFields: Boolean)
    begin
        SkipAmountsTestFields := true;
    end;
}
