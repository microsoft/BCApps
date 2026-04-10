namespace System.Automation;

using System;
using System.Environment;
using System.Utilities;

codeunit 1545 "Workflow Webhook Notification"
{
    // // Intended to be called from a Task (background session)

    EventSubscriberInstance = Manual;
    Permissions = TableData "Workflow Webhook Notification" = rimd;

    trigger OnRun()
    begin
    end;

    var
        RetryCounter: Integer;
        WaitTime: Integer;
        IsInitialized: Boolean;
        NotInitializedErr: Label 'The code unit is not initialized.';
        ArgumentNullErr: Label '%1 cannot be null.', Comment = '%1=Argument';
        ArgumentEmptyErr: Label '%1 cannot be empty.', Comment = '%1=Argument';
        DataIDTxt: Label 'DataID';
        WorkflowStepInstanceIDTxt: Label 'WorkflowStepInstanceID';
        NotificationUrlTxt: Label 'NotificationUrl';
        WorkflowWebhookCategoryLbl: Label 'AL Workflow Webhook', Locked = true;
        WorkflowWebhookCorrelationGuidTxt: Label 'Correlation GUID for workflow webhook notification created: %1', Locked = true;

    procedure Initialize(RetryCount: Integer; WaitTimeInMs: Integer)
    begin
        RetryCounter := RetryCount;
        WaitTime := WaitTimeInMs;
        IsInitialized := true;
    end;

    [Scope('OnPrem')]
    procedure SendNotification(DataID: Guid; WorkflowStepInstanceID: Guid; NotificationUrl: Text; RequestedByUserEmail: Text)
    var
        WorkflowWebhookNotificationTable: Record "Workflow Webhook Notification";
    begin
        if IsInitialized = false then
            Error(NotInitializedErr);

        if IsNullGuid(DataID) then
            Error(ArgumentNullErr, DataIDTxt);

        if IsNullGuid(WorkflowStepInstanceID) then
            Error(ArgumentNullErr, WorkflowStepInstanceIDTxt);

        if NotificationUrl = '' then
            Error(ArgumentEmptyErr, NotificationUrlTxt);

        GetNotificationRecord(WorkflowWebhookNotificationTable, WorkflowStepInstanceID);
        Notify(DataID, WorkflowStepInstanceID, NotificationUrl, RequestedByUserEmail, WorkflowWebhookNotificationTable);
    end;

    procedure StartNotification(WorkflowStepInstanceID: Guid)
    var
        WorkflowWebhookNotificationTable: Record "Workflow Webhook Notification";
    begin
        GetNotificationRecord(WorkflowWebhookNotificationTable, WorkflowStepInstanceID);
        WorkflowWebhookNotificationTable.Status := WorkflowWebhookNotificationTable.Status::Pending;
        WorkflowWebhookNotificationTable.Modify(true);
    end;

    local procedure Notify(DataID: Guid; WorkflowStepInstanceID: Guid; NotificationUrl: Text; RequestedByUserEmail: Text; var WorkflowWebhookNotification: Record "Workflow Webhook Notification")
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        Exception: DotNet Exception;
        HttpWebResponse: DotNet HttpWebResponse;
        WebException: DotNet WebException;
        Retry: Boolean;
        ErrorMessage: Text;
        ErrorDetails: Text;
    begin
        RetryCounter := RetryCounter - 1;
        if OnPostNotificationRequest(DataID, WorkflowStepInstanceID, NotificationUrl, RequestedByUserEmail) then begin
            WorkflowWebhookNotification.Status := WorkflowWebhookNotification.Status::Sent;
            WorkflowWebhookNotification.SetErrorMessage('');
            WorkflowWebhookNotification.SetErrorDetails('');
            WorkflowWebhookNotification.Modify(true);
            Commit();
        end else begin
            Exception := GetLastErrorObject();

            ErrorMessage := Exception.Message;
            ErrorDetails := Exception.StackTrace;

            if RetryCounter > 0 then begin
                Retry := true;
                DotNetExceptionHandler.Collect();
                if DotNetExceptionHandler.CastToType(WebException, GetDotNetType(WebException)) then begin
                    HttpWebResponse := WebException.Response;
                    if not IsNull(HttpWebResponse) then
                        if not IsNull(HttpWebResponse.StatusCode) then begin
                            ErrorDetails := StrSubstNo('%1 - StatusCode: %2 - StatusDescription: %3', ErrorDetails,
                                Format(HttpWebResponse.StatusCode), HttpWebResponse.StatusDescription);
                            Retry := ShouldRetry(HttpWebResponse.StatusCode, HttpWebResponse.StatusDescription);
                        end;
                end;
            end;

            if Retry then begin
                Sleep(WaitTime);
                Notify(DataID, WorkflowStepInstanceID, NotificationUrl, RequestedByUserEmail, WorkflowWebhookNotification);
            end else begin
                WorkflowWebhookNotification.SetErrorMessage(ErrorMessage);
                WorkflowWebhookNotification.SetErrorDetails(ErrorDetails);
                WorkflowWebhookNotification.Status := WorkflowWebhookNotification.Status::Failed;
                WorkflowWebhookNotification.Modify(true);
                Commit();
            end;
        end;
    end;

    [TryFunction]
    [IntegrationEvent(true, true)]
    [Scope('OnPrem')]
    procedure OnPostNotificationRequest(DataID: Guid; WorkflowStepInstanceID: Guid; NotificationUrl: Text; RequestedByUserEmail: Text)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Webhook Notification", 'OnPostNotificationRequest', '', false, false)]
    [TryFunction]
    local procedure PostNotificationRequest(var Sender: Codeunit "Workflow Webhook Notification"; DataID: Guid; WorkflowStepInstanceID: Guid; NotificationUrl: Text; RequestedByUserEmail: Text)
    begin
        PostHttpRequest(DataID, WorkflowStepInstanceID, NotificationUrl, RequestedByUserEmail);
    end;

    [TryFunction]
    local procedure PostHttpRequest(DataID: Guid; WorkflowStepInstanceID: Guid; NotificationUrl: Text; RequestedByUserEmail: Text)
    var
        HttpWebRequest: DotNet HttpWebRequest;
        HttpWebResponse: DotNet HttpWebResponse;
        RequestStr: DotNet Stream;
        StreamWriter: DotNet StreamWriter;
        Encoding: DotNet Encoding;
        WebhookPayload: Text;
        CorrelationGuid: Text;
    begin
        HttpWebRequest := HttpWebRequest.Create(NotificationUrl);
        CorrelationGuid := LowerCase(System.Format(CreateGuid(), 0, 4));
        HttpWebRequest.Method := 'POST';
        HttpWebRequest.ContentType('application/json');
        HttpWebRequest.Headers.Add('clientRequestId', CorrelationGuid);
        HttpWebRequest.Headers.Add('x-ms-correlation-id', CorrelationGuid);

        Session.LogMessage('0000KX6', StrSubstNo(WorkflowWebhookCorrelationGuidTxt, CorrelationGuid), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', WorkflowWebhookCategoryLbl);

        RequestStr := HttpWebRequest.GetRequestStream();
        StreamWriter := StreamWriter.StreamWriter(RequestStr, Encoding.ASCII);
        WebhookPayload := PrepareWebhookPayload(DataID, WorkflowStepInstanceID, RequestedByUserEmail);
        StreamWriter.Write(WebhookPayload);
        StreamWriter.Flush();
        StreamWriter.Close();
        StreamWriter.Dispose();

        HttpWebResponse := HttpWebRequest.GetResponse();
        HttpWebResponse.Close(); // close connection
        HttpWebResponse.Dispose(); // cleanup of IDisposable
    end;

    local procedure PrepareWebhookPayload(DataID: Guid; WorkflowStepInstanceID: Guid; RequestedByUserEmail: Text) WebhookPayload: Text
    var
        Company: Record Company;
        EnvironmentInformation: Codeunit "Environment Information";
        JsonPayload: JsonObject;
    begin
        JsonPayload.Add('Row Id', LowerCase(Format(DataID, 0, 4)));
        JsonPayload.Add('Workflow Step Id', LowerCase(Format(WorkflowStepInstanceID, 0, 4)));
        JsonPayload.Add('Requested By User Email', RequestedByUserEmail);

        if Company.ReadPermission then
            if Company.Get(CompanyName()) then
                JsonPayload.Add('Company Id', LowerCase(Format(Company.Id, 0, 4)));

        if EnvironmentInformation.IsSaaS() then
            JsonPayload.Add('Environment Name', EnvironmentInformation.GetEnvironmentName());

        JsonPayload.WriteTo(WebhookPayload);
    end;

    local procedure FindNotificationRecord(var WorkflowWebhookNotificationTable: Record "Workflow Webhook Notification"; WorkflowStepInstanceID: Guid): Boolean
    begin
        // Fetch current notification record
        WorkflowWebhookNotificationTable.SetRange("Workflow Step Instance ID", WorkflowStepInstanceID);
        exit(WorkflowWebhookNotificationTable.FindFirst());
    end;

    local procedure GetNotificationRecord(var WorkflowWebhookNotificationTable: Record "Workflow Webhook Notification"; WorkflowStepInstanceID: Guid)
    begin
        if not FindNotificationRecord(WorkflowWebhookNotificationTable, WorkflowStepInstanceID) then begin
            // Create Notification Record
            WorkflowWebhookNotificationTable.Init();
            WorkflowWebhookNotificationTable."Workflow Step Instance ID" := WorkflowStepInstanceID;
            WorkflowWebhookNotificationTable.Status := WorkflowWebhookNotificationTable.Status::Pending;
            WorkflowWebhookNotificationTable.Insert(true);
            FindNotificationRecord(WorkflowWebhookNotificationTable, WorkflowStepInstanceID);
        end;
    end;

    procedure GetCurrentRetryCounter(): Integer
    begin
        exit(RetryCounter);
    end;

    procedure ShouldRetry(StatusCode: Integer; StatusDescription: Text): Boolean
    begin
        if StatusCode = 404 then
            if (StatusDescription = 'WorkflowNotFound') or (StatusDescription = 'WorkflowTriggerVersionNotFound') then
                exit(false);

        if (StatusCode = 400) and (StatusDescription = 'WorkflowTriggerIsNotEnabled') then
            exit(false);

        exit(true);
    end;
}

