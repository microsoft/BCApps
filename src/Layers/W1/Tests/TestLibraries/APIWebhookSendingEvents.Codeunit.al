codeunit 135090 "API Webhook Sending Events"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        ProcessingStatus: Text;
        CustomIsAPIEnabled: Boolean;
        CustomAPISubscriptionsEnabled: Boolean;
        CustomDelayTime: Integer;
        CustomMaxNumberOfNotifications: Integer;
        CustomMaxNumberOfAttempts: Integer;
        CustomSendingNotificationTimeout: Integer;
        UseCustomIsAPIEnabled: Boolean;
        UseCustomAPISubscriptionsEnabled: Boolean;
        UseCustomDelayTime: Boolean;
        UseCustomMaxNumberOfNotifications: Boolean;
        UseCustomMaxNumberOfAttempts: Boolean;
        UseCustomSendingNotificationTimeout: Boolean;
        JobQueueCategoryCodeLbl: Label 'APIWEBHOOK', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'OnGetIsAPIEnabled', '', false, false)]
    local procedure HandleOnGetIsAPIEnabled(var Handled: Boolean; var IsAPIEnabled: Boolean)
    begin
        if not UseCustomIsAPIEnabled then
            exit;

        Handled := true;
        IsAPIEnabled := CustomIsAPIEnabled;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'OnGetAPISubscriptionsEnabled', '', false, false)]
    local procedure HandleOnGetAPISubscriptionsEnabled(var Handled: Boolean; var APISubscriptionsEnabled: Boolean)
    begin
        if not UseCustomAPISubscriptionsEnabled then
            exit;

        Handled := true;
        APISubscriptionsEnabled := CustomAPISubscriptionsEnabled;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"API Webhook Notification Mgt.", 'OnGetDelayTime', '', false, false)]
    local procedure HandleOnGetDelayTime(var Handled: Boolean; var Value: Integer)
    begin
        if not UseCustomDelayTime then
            exit;

        Handled := true;
        Value := CustomDelayTime;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"API Webhook Notification Send", 'OnGetMaxNumberOfNotifications', '', false, false)]
    local procedure HandleOnGetMaxNumberOfNotifications(var Handled: Boolean; var Value: Integer)
    begin
        if not UseCustomMaxNumberOfNotifications then
            exit;

        Handled := true;
        Value := CustomMaxNumberOfNotifications;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"API Webhook Notification Send", 'OnGetMaxNumberOfAttempts', '', false, false)]
    local procedure HandleOnGetMaxNumberOfAttempts(var Handled: Boolean; var Value: Integer)
    begin
        if not UseCustomMaxNumberOfAttempts then
            exit;

        Handled := true;
        Value := CustomMaxNumberOfAttempts;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"API Webhook Notification Send", 'OnGetSendingNotificationTimeout', '', false, false)]
    local procedure HandleOnGetSendingNotificationTimeout(var Handled: Boolean; var Value: Integer)
    begin
        if not UseCustomSendingNotificationTimeout then
            exit;

        Handled := true;
        Value := CustomSendingNotificationTimeout;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"API Webhook Notification Send", 'OnBeforeProcessNotifications', '', false, false)]
    local procedure HandleOnBeforeProcessNotifications()
    begin
        ProcessingStatus := 'Started';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"API Webhook Notification Send", 'OnAfterProcessNotifications', '', false, false)]
    local procedure HandleOnAfterProcessNotifications()
    begin
        ProcessingStatus := 'Finished';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"API Webhook Notification Send", 'OnBeforeDeleteInactiveJobs', '', false, false)]
    local procedure HandleOnBeforeDeleteInactiveJobs()
    begin
        MarkOnHoldJobsAsReady();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"API Webhook Notification Send", 'OnBeforeSendNotification', '', false, false)]
    local procedure HandleOnBeforeSendNotification(NotificationUrl: Text; Payload: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        ValueJArray: DotNet JArray;
        PayloadJObject: DotNet JObject;
        ValueJObject: DotNet JObject;
        ExpectedSubscriptionID: Text;
        ExpectedChangeType: Text;
        ExpectedNotificationUrl: Text;
        ExpectedResourceUrl: Text;
        ExpectedEntityCount: Integer;
        ActualSubscriptionID: Text;
        ActualChangeType: Text;
        ActualResourceUrl: Text;
        ActualEntityCount: Integer;
        I: Integer;
    begin
        ExpectedNotificationUrl := LibraryVariableStorage.DequeueText();
        ExpectedEntityCount := LibraryVariableStorage.DequeueInteger();
        Assert.AreEqual(ExpectedNotificationUrl, NotificationUrl, 'Incorrect notification URL');

        JSONManagement.InitializeObject(Payload);
        JSONManagement.GetJSONObject(PayloadJObject);
        JSONManagement.GetArrayPropertyValueFromJObjectByName(PayloadJObject, 'value', ValueJArray);
        ActualEntityCount := ValueJArray.Count();
        Assert.AreEqual(ExpectedEntityCount, ActualEntityCount, 'Invalid number of entities');

        JSONManagement.InitializeCollectionFromJArray(ValueJArray);

        for I := 0 to ActualEntityCount - 1 do begin
            ExpectedSubscriptionID := LibraryVariableStorage.DequeueText();
            ExpectedChangeType := LibraryVariableStorage.DequeueText();
            ExpectedResourceUrl := LibraryVariableStorage.DequeueText();
            JSONManagement.GetJObjectFromCollectionByIndex(ValueJObject, I);
            GraphMgtGeneralTools.GetMandatoryStringPropertyFromJObject(ValueJObject, 'subscriptionId', ActualSubscriptionID);
            GraphMgtGeneralTools.GetMandatoryStringPropertyFromJObject(ValueJObject, 'changeType', ActualChangeType);
            GraphMgtGeneralTools.GetMandatoryStringPropertyFromJObject(ValueJObject, 'resource', ActualResourceUrl);
            Assert.AreEqual(ExpectedSubscriptionID, ActualSubscriptionID, 'Invalid subscription ID');
            Assert.AreEqual(ExpectedChangeType, ActualChangeType, 'Invalid change type');
            Assert.AreEqual(ExpectedResourceUrl, ActualResourceUrl, 'Invalid resource');
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"API Webhook Notification Send", 'OnAfterSendNotification', '', false, false)]
    local procedure HandleOnAfterSendNotification(ErrorMessage: Text; ErrorDetails: Text; var HttpStatusCode: DotNet HttpStatusCode)
    var
        ExpectedStatusCode: Integer;
        ActualStatusCode: Integer;
    begin
        ExpectedStatusCode := LibraryVariableStorage.DequeueInteger();
        if not IsNull(HttpStatusCode) then
            ActualStatusCode := HttpStatusCode;
        Assert.AreEqual(ExpectedStatusCode, ActualStatusCode,
          StrSubstNo('Incorrect HTTP status code.%1%2', ErrorMessage, ErrorDetails));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"API Webhook Notification Mgt.", 'OnCanCreateTask', '', false, false)]
    local procedure HandleOnCanCreateTask(var Handled: Boolean; var CanCreateTask: Boolean)
    begin
        Handled := true;
        CanCreateTask := true;
    end;

    [Scope('OnPrem')]
    procedure AssertEmptyQueue()
    begin
        LibraryVariableStorage.AssertEmpty();
    end;

    [Scope('OnPrem')]
    procedure EnqueueVariable(Variable: Variant)
    begin
        LibraryVariableStorage.Enqueue(Variable);
    end;

    [Scope('OnPrem')]
    procedure SetApiEnabled(Value: Boolean)
    begin
        CustomIsAPIEnabled := Value;
        UseCustomIsAPIEnabled := true;
    end;

    [Scope('OnPrem')]
    procedure SetApiSubscriptionsEnabled(Value: Boolean)
    begin
        CustomAPISubscriptionsEnabled := Value;
        UseCustomAPISubscriptionsEnabled := true;
    end;

    [Scope('OnPrem')]
    procedure SetDelayTime(Value: Integer)
    begin
        CustomDelayTime := Value;
        UseCustomDelayTime := true;
    end;

    [Scope('OnPrem')]
    procedure SetMaxNumberOfNotifications(Value: Integer)
    begin
        CustomMaxNumberOfNotifications := Value;
        UseCustomMaxNumberOfNotifications := true;
    end;

    [Scope('OnPrem')]
    procedure SetMaxNumberOfAttempts(Value: Integer)
    begin
        CustomMaxNumberOfAttempts := Value;
        UseCustomMaxNumberOfAttempts := true;
    end;

    [Scope('OnPrem')]
    procedure SetSendingNotificationTimeout(Value: Integer)
    begin
        CustomSendingNotificationTimeout := Value;
        UseCustomSendingNotificationTimeout := true;
    end;

    [Scope('OnPrem')]
    procedure GetProcessingStatus(): Text
    begin
        exit(ProcessingStatus);
    end;

    [Scope('OnPrem')]
    procedure Reset()
    begin
        LibraryVariableStorage.Clear();
        UseCustomIsAPIEnabled := false;
        UseCustomAPISubscriptionsEnabled := false;
        UseCustomDelayTime := false;
        UseCustomMaxNumberOfNotifications := false;
        UseCustomMaxNumberOfAttempts := false;
        UseCustomSendingNotificationTimeout := false;
        Clear(CustomIsAPIEnabled);
        Clear(CustomAPISubscriptionsEnabled);
        Clear(CustomDelayTime);
        Clear(CustomMaxNumberOfNotifications);
        Clear(CustomMaxNumberOfAttempts);
        Clear(CustomSendingNotificationTimeout);
        ProcessingStatus := 'Not started';
    end;

    local procedure MarkOnHoldJobsAsReady()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduledTask: Record "Scheduled Task";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"API Webhook Notification Send");
        JobQueueEntry.SetRange("Job Queue Category Code", JobQueueCategoryCodeLbl);
        if JobQueueEntry.FindSet(true) then
            repeat
                if JobQueueEntry.Status = JobQueueEntry.Status::"On Hold" then begin
                    JobQueueEntry.Status := JobQueueEntry.Status::Ready;
                    JobQueueEntry."System Task ID" := CreateGuid();
                    JobQueueEntry.Modify(true);
                    if not ScheduledTask.Get(JobQueueEntry."System Task ID") then begin
                        ScheduledTask.ID := JobQueueEntry."System Task ID";
                        ScheduledTask.Insert();
                    end;
                end;
            until JobQueueEntry.Next() = 0;
    end;
}

