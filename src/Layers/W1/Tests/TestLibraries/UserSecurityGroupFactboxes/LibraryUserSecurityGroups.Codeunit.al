codeunit 135106 "Library - User Security Groups"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"User Security Groups PBT", 'OnBeforeEnqueueBackgroundTask', '', false, false)]
    local procedure SkipEnqueueBackgroundTask(var Skip: Boolean)
    begin
        Skip := true;
    end;
}