codeunit 135547 "Webhook Logs E2E"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [API] [Webhook]
    end;

    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        WebhookLogsTxt: Label 'webhookLogs', Locked = true;
        ActivityLogContextLbl: Label 'APIWEBHOOK', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetWebhookLogsMany()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] GET returns many messages in the payload when webhook subscriptions are enabled
        Initialize();

        // [GIVEN] webhookLogs URI without filters
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"API Webhook Logs", WebhookLogsTxt);

        // [WHEN] User sends a GET request
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Response code is 200 and response body contains messages
        Assert.IsTrue(StrPos(ResponseText, '"details":') > 0, 'Response does not contain messages');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetWebhookLogsSingle()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] GET returns single message in the payload when webhook subscriptions are enabled
        Initialize();

        // [GIVEN] webhookLogs URI for a single message
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(GetActivityLogId('second')), PAGE::"API Webhook Logs", WebhookLogsTxt);

        // [WHEN] User sends a GET request
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Response code is 200 and response body contains the specified message
        Assert.IsTrue((StrPos(ResponseText, '"second"') > 0) and (StrPos(ResponseText, '"yellow"') > 0), 'Message is not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostWebhookLogsNotAllowed()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] POST is not allowed for webhookLogs
        Initialize();

        // [GIVEN] webhookLogs URI for a single message
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"API Webhook Logs", WebhookLogsTxt);

        // [WHEN] User send a POST request
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '{"message":"new"}', ResponseText, 405);

        // [THEN] Expecting response code 405
        Assert.ExpectedError('405 (MethodNotAllowed)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchWebhookLogsNotAllowed()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] PATCH is not allowed for webhookLogs
        Initialize();

        // [GIVEN] webhookLogs URI for a single message
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(GetActivityLogId('second')), PAGE::"API Webhook Logs", WebhookLogsTxt);

        // [WHEN] User send a PATCH request
        asserterror LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(TargetURL, '{"message":"new"}', ResponseText, 405);

        // [THEN] Expecting response code 405
        Assert.ExpectedError('405 (MethodNotAllowed)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteWebhookLogsNotAllowed()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] DELETE is not allowed for webhookLogs
        Initialize();

        // [GIVEN] webhookLogs URI for a single message
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(GetActivityLogId('second')), PAGE::"API Webhook Logs", WebhookLogsTxt);

        // [WHEN] User send a DELETE request
        asserterror LibraryGraphMgt.DeleteFromWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 400);

        // [THEN] Expecting response code 400
        Assert.ExpectedError('400 (BadRequest)');
    end;

    local procedure Initialize()
    begin
        CleanActivityLogs();
        AddActivityLog('first', 'red');
        AddActivityLog('second', 'yellow');
        AddActivityLog('third', 'green');
        Commit();
    end;

    local procedure AddActivityLog(ActivityDescription: Text; ActivityMessage: Text)
    var
        FakeAPIWebhookSubscription: Record "API Webhook Subscription";
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.LogActivity(FakeAPIWebhookSubscription.RecordId, ActivityLog.Status::Success, ActivityLogContextLbl,
          ActivityDescription, ActivityMessage);
    end;

    local procedure GetActivityLogId(ActivityDescription: Text): Integer
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.SetRange(Context, ActivityLogContextLbl);
        ActivityLog.SetRange(Description, ActivityDescription);
        ActivityLog.FindFirst();
        exit(ActivityLog.ID);
    end;

    local procedure CleanActivityLogs()
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.SetRange(Context, ActivityLogContextLbl);
        ActivityLog.DeleteAll();
    end;
}

