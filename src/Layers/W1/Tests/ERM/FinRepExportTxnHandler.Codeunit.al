codeunit 135011 "Fin. Rep. Export Txn Handler"
{
    EventSubscriberInstance = Manual;
    Access = Internal;

    [EventSubscriber(ObjectType::Report, Report::"Export Acc. Sched. to Excel", 'OnIntegerOnAfterGetRecordOnAfterAccSchedLineSetFilter', '', false, false)]
    local procedure RunModalOnAfterAccSchedLineSetFilter(var AccScheduleLine: Record "Acc. Schedule Line")
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
    begin
        TempNameValueBuffer.Init();
        TempNameValueBuffer.ID := 1;
        TempNameValueBuffer.Value := CopyStr(AccScheduleLine."Schedule Name", 1, MaxStrLen(TempNameValueBuffer.Value));
        TempNameValueBuffer.Insert();
        Page.RunModal(Page::"Name/Value Lookup", TempNameValueBuffer);
    end;
}
