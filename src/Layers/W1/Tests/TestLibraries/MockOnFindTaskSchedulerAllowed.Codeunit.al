codeunit 132497 MockOnFindTaskSchedulerAllowed
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Webhook Management", 'OnFindTaskSchedulerAllowed', '', false, false)]
    local procedure FindTaskSchedulerAllowed(var IsTaskSchedulingAllowed: Boolean)
    begin
        IsTaskSchedulingAllowed := false;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Workflow Webhook Subscription", 'OnFindTaskSchedulerAllowed', '', false, false)]
    local procedure FindTaskSchedulerAllowedForWFWHSubscription(var IsTaskSchedulingAllowed: Boolean)
    begin
        IsTaskSchedulingAllowed := false;
    end;
}

