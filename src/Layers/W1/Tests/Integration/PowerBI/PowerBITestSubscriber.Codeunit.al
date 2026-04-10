codeunit 139097 "Power BI Test Subscriber"
{
    Access = Internal;
    EventSubscriberInstance = Manual;
    Subtype = Test; // This is to allow AssertError

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Power BI Service Mgt.", 'OnServiceProviderCreate', '', false, false)]
    local procedure SetServiceProvider(var PowerBIServiceProvider: Interface "Power BI Service Provider"; var Handled: Boolean)
    begin
        PowerBIServiceProvider := PowerBIMockServiceProvider;
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue - Enqueue", 'OnBeforeJobQueueScheduleTask', '', false, false)]
    local procedure ExecuteJobQueueInForeground(var JobQueueEntry: Record "Job Queue Entry"; var DoNotScheduleTask: Boolean)
    begin
        AssertCU.AreEqual(JobQueueEntry."Object ID to Run", Codeunit::"Power BI Report Synchronizer", 'Wrong codeunit scheduled');
        AssertCU.AreEqual(JobQueueEntry."Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit, 'Wrong codeunit scheduled');

        DoNotScheduleTask := true;

        TotalJobQueueExecutions += 1;
        if TotalJobQueueExecutions > 3 then
            Error('Too many executions');

        Commit(); // To allow Codeunit.Run

        AssertCU.AreEqual(not SynchronizerErrorExpected, Codeunit.Run(JobQueueEntry."Object ID to Run", JobQueueEntry), 'Unexpected codeunit outcome');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnAcquireTokenFromCache', '', false, false)]
    local procedure InjectAccessTokenCache(ResourceName: Text; var AccessToken: Text)
    begin
        AccessToken := 'Beaver==';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnCheckProvider', '', false, false)]
    local procedure CheckProvider(var Result: Boolean)
    begin
        Result := true;
    end;

    procedure SetFailAtStep(InputFailStep: Option)
    begin
        PowerBIMockServiceProvider.SetFailAtStep(InputFailStep);
    end;

    procedure SetRetryDateTime(InputRetryDateTime: DateTime)
    begin
        PowerBIMockServiceProvider.SetRetryDateTime(InputRetryDateTime);
    end;

    procedure SetExpectSynchronizerError(InputSynchronizerErrorExpected: Boolean)
    begin
        SynchronizerErrorExpected := InputSynchronizerErrorExpected;
    end;

    var
        AssertCU: Codeunit Assert;
        PowerBIMockServiceProvider: Codeunit "Power BI Mock Service Provider";
        TotalJobQueueExecutions: Integer;
        SynchronizerErrorExpected: Boolean;

}