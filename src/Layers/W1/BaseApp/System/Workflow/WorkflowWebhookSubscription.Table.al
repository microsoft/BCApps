namespace System.Automation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Integration.Entity;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System;
using System.Environment;
using System.Reflection;
using System.Text;

table 469 "Workflow Webhook Subscription"
{
    Caption = 'Workflow Webhook Subscription';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
        }
        field(2; "WF Definition Id"; Code[20])
        {
            Caption = 'WF Definition Id';
        }
        field(3; Conditions; BLOB)
        {
            Caption = 'Conditions';
        }
        field(4; "Notification Url"; BLOB)
        {
            Caption = 'Notification Url';
        }
        field(5; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(6; "User Id"; Code[50])
        {
            Caption = 'User Id';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "Client Id"; Guid)
        {
            Caption = 'Client Id';
        }
        field(8; "Client Type"; Text[50])
        {
            Caption = 'Client Type';
        }
        field(9; "Event Code"; Code[128])
        {
            Caption = 'Event Code';
        }
        field(10; "Created Date"; DateTime)
        {
            Caption = 'Created Date';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
        key(Key2; "WF Definition Id", Enabled)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        Workflow: Record Workflow;
        WorkflowWebhookSubBuffer: Record "Workflow Webhook Sub Buffer";
        IsTaskSchedulerAllowed: Boolean;
    begin
        // this would also clean up related Workflow table entry and Workflow Steps
        if Workflow.Get("WF Definition Id") then begin
            WorkflowWebhookSubBuffer.Init();
            WorkflowWebhookSubBuffer."WF Definition Id" := "WF Definition Id";
            WorkflowWebhookSubBuffer."Client Id" := "Client Id";
            WorkflowWebhookSubBuffer.Insert();

            IsTaskSchedulerAllowed := true;
            OnFindTaskSchedulerAllowed(IsTaskSchedulerAllowed);

            if IsTaskSchedulerAllowed then
                TASKSCHEDULER.CreateTask(CODEUNIT::"Workflow Webhook Sub Delete", 0, true,
                  CompanyName, 0DT, Workflow.RecordId)
            else
                CODEUNIT.Run(CODEUNIT::"Workflow Webhook Sub Delete", Workflow);
        end;
    end;

    trigger OnInsert()
    begin
        Id := CreateGuid();
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Created Date" := CurrentDateTime;
    end;

    trigger OnModify()
    var
        WorkflowWebhookSubscriptionPreviousRec: Record "Workflow Webhook Subscription";
        WorkflowWebhookSubBuffer: Record "Workflow Webhook Sub Buffer";
    begin
        // Inserting new record also calls OnModify so checking to ensure it's a proper insert rather than modify
        if IsInsert() then begin
            // Check if incoming Rec's Client ID exists already
            WorkflowWebhookSubscriptionPreviousRec.SetRange("Client Id", "Client Id");
            WorkflowWebhookSubscriptionPreviousRec.SetRange(Enabled, true);
            WorkflowWebhookSubscriptionPreviousRec.SetCurrentKey("Created Date");
            WorkflowWebhookSubscriptionPreviousRec.SetAscending("Created Date", false);
            if WorkflowWebhookSubscriptionPreviousRec.FindFirst() then
                // will be creating new workflow so disable previous one
                DisableWorkflow(WorkflowWebhookSubscriptionPreviousRec."WF Definition Id")
            else begin
                WorkflowWebhookSubBuffer.SetRange("Client Id", "Client Id");
                if WorkflowWebhookSubBuffer.FindSet() then
                    repeat
                        DisableWorkflow(WorkflowWebhookSubBuffer."WF Definition Id");
                    until WorkflowWebhookSubBuffer.Next() = 0;
            end;

            CreateWorkflowDefinition();
            EnableSubscriptionAndWorkflow(Rec);
        end;
    end;

    var
        JSONManagement: Codeunit "JSON Management";

        WorkflowWebhookSetup: Codeunit "Workflow Webhook Setup";
        UnableToParseEncodingErr: Label 'Unable to parse the Conditions. The provided Conditions were not in the correct Base64 encoded format.';
        UnableToParseInvalidJsonErr: Label 'Unable to parse the Conditions. The provided Conditions JSON was invalid.';
        NoControlOnPageErr: Label 'Unable to find a field with control name ''%1'' on page ''%2''.', Comment = '%1=control name;%2=page name';
        UnableToParseJsonArrayErr: Label 'Unable to parse ''%1'' because it was not a valid JSON array.', Comment = '%1=conditions property name';

    procedure SetConditions(ConditionsTxt: Text)
    var
        StreamOutObj: OutStream;
    begin
        // store as blob
        Clear(Conditions);
        Conditions.CreateOutStream(StreamOutObj);
        StreamOutObj.WriteText(ConditionsTxt);
    end;

    procedure SetNotificationUrl(NotificationURLTxt: Text)
    var
        StreamOutObj: OutStream;
    begin
        // store as blob
        Clear("Notification Url");
        "Notification Url".CreateOutStream(StreamOutObj);
        StreamOutObj.WriteText(NotificationURLTxt);
    end;

    procedure GetConditions() ConditionsText: Text
    var
        ReadStream: InStream;
    begin
        CalcFields(Conditions);
        Conditions.CreateInStream(ReadStream);
        ReadStream.ReadText(ConditionsText);
    end;

    procedure GetNotificationUrl() NotificationUrlText: Text
    var
        ReadStream: InStream;
    begin
        CalcFields("Notification Url");
        "Notification Url".CreateInStream(ReadStream);
        ReadStream.ReadText(NotificationUrlText);
    end;

    local procedure CreateWorkflowDefinition()
    var
        EventConditions: Text;
    begin
        EventConditions := CreateEventConditions(GetConditions(), "Event Code");

        // the second argument, Name, is empty at this point by design (hardcoded to be a text constant inside the function)
        "WF Definition Id" := WorkflowWebhookSetup.CreateWorkflowDefinition("Event Code", '', EventConditions, UserId);
    end;

    local procedure IsInsert(): Boolean
    begin
        // This is how we know a new record is being inserted into table
        exit("WF Definition Id" = '');
    end;

    local procedure EnableSubscription(var WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription")
    begin
        // Turn On a Subscription
        WorkflowWebhookSubscriptionRec.Enabled := true;
        WorkflowWebhookSubscriptionRec.Modify();
    end;

    local procedure EnableWorkflow(WorkflowCode: Code[20])
    var
        Workflow: Record Workflow;
    begin
        // Enable a workflow
        if Workflow.Get(WorkflowCode) then begin
            Workflow.Validate(Enabled, true);
            Workflow.Modify();
        end;
    end;

    local procedure DisableWorkflow(WorkflowCode: Code[20])
    var
        Workflow: Record Workflow;
    begin
        // Disable a workflow
        if Workflow.Get(WorkflowCode) then begin
            Workflow.Validate(Enabled, false);
            Workflow.Modify();
        end;
    end;

    local procedure EnableSubscriptionAndWorkflow(var WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription")
    begin
        // Enable Subscription and its corresponding Workflow
        EnableSubscription(WorkflowWebhookSubscriptionRec);
        EnableWorkflow(WorkflowWebhookSubscriptionRec."WF Definition Id");
    end;

    [Scope('OnPrem')]
    procedure CreateEventConditions(ConditionsTxt: Text; EventCode: Code[128]): Text
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        EventConditions: FilterPageBuilder;
        ConditionsObject: DotNet JObject;
        ConditionsCount: Integer;
        Result: Text;
        IsHandled: Boolean;
    begin
        if not TryDecodeConditions(ConditionsTxt) then
            SendAndLogError(GetLastErrorText, UnableToParseEncodingErr);

        if not TryParseJson(ConditionsTxt, ConditionsObject) then
            SendAndLogError(GetLastErrorText, UnableToParseInvalidJsonErr);

        ConditionsCount := 1;
        case EventCode of
            WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode():
                begin
                    AddEventConditionsWrapper(
                      'HeaderConditions', ConditionsObject, PAGE::"Sales Document Entity", EventConditions, ConditionsCount);
                    AddEventConditionsWrapper(
                      'LinesConditions', ConditionsObject, PAGE::"Sales Document Line Entity", EventConditions, ConditionsCount);
                    exit(
                      RequestPageParametersHelper.GetViewFromDynamicRequestPage(
                        EventConditions, WorkflowWebhookSetup.GetSalesDocCategoryTxt(), DATABASE::"Sales Header"));
                end;
            WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode():
                begin
                    AddEventConditionsWrapper(
                      'HeaderConditions', ConditionsObject, PAGE::"Purchase Document Entity", EventConditions, ConditionsCount);
                    AddEventConditionsWrapper(
                      'LinesConditions', ConditionsObject, PAGE::"Purchase Document Line Entity", EventConditions, ConditionsCount);
                    exit(
                      RequestPageParametersHelper.GetViewFromDynamicRequestPage(
                        EventConditions, WorkflowWebhookSetup.GetPurchaseDocCategoryTxt(), DATABASE::"Purchase Header"));
                end;
            WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode():
                begin
                    AddEventConditionsWrapper(
                      'Conditions', ConditionsObject, PAGE::"Gen. Journal Batch Entity", EventConditions, ConditionsCount);
                    exit(
                      RequestPageParametersHelper.GetViewFromDynamicRequestPage(
                        EventConditions, WorkflowWebhookSetup.GetFinCategoryTxt(), DATABASE::"Gen. Journal Batch"));
                end;
            WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode():
                begin
                    AddEventConditionsWrapper(
                      'Conditions', ConditionsObject, PAGE::"Gen. Journal Line Entity", EventConditions, ConditionsCount);
                    exit(
                      RequestPageParametersHelper.GetViewFromDynamicRequestPage(
                        EventConditions, WorkflowWebhookSetup.GetFinCategoryTxt(), DATABASE::"Gen. Journal Line"));
                end;
            WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode():
                begin
                    AddEventConditionsWrapper(
                      'Conditions', ConditionsObject, PAGE::"Workflow - Customer Entity", EventConditions, ConditionsCount);
                    exit(
                      RequestPageParametersHelper.GetViewFromDynamicRequestPage(
                        EventConditions, WorkflowWebhookSetup.GetSalesMktCategoryTxt(), DATABASE::Customer));
                end;
            WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode():
                begin
                    AddEventConditionsWrapper(
                      'Conditions', ConditionsObject, PAGE::"Workflow - Item Entity", EventConditions, ConditionsCount);
                    exit(
                      RequestPageParametersHelper.GetViewFromDynamicRequestPage(
                        EventConditions, WorkflowWebhookSetup.GetSalesMktCategoryTxt(), DATABASE::Item));
                end;
            WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode():
                begin
                    AddEventConditionsWrapper(
                      'Conditions', ConditionsObject, PAGE::"Workflow - Vendor Entity", EventConditions, ConditionsCount);
                    exit(
                      RequestPageParametersHelper.GetViewFromDynamicRequestPage(
                        EventConditions, WorkflowWebhookSetup.GetPurchPayCategoryTxt(), DATABASE::Vendor));
                end
            else begin
                OnCreateWorkflowEventConditions(ConditionsTxt, EventCode, ConditionsObject, EventConditions, ConditionsCount, Result, IsHandled);
                if IsHandled then
                    exit(Result);

                SendAndLogError(
                  StrSubstNo(WorkflowWebhookSetup.GetUnsupportedWorkflowEventCodeErr(), EventCode),
                  StrSubstNo(WorkflowWebhookSetup.GetUnsupportedWorkflowEventCodeErr(), EventCode));
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure AddEventConditionsWrapper(ConditionsPropertyName: Text; ConditionsObject: DotNet JObject; SourcePageNo: Integer; var EventConditions: FilterPageBuilder; var ConditionsCount: Integer)
    var
        ConditionsCollection: DotNet JToken;
    begin
        if ConditionsObject.TryGetValue(ConditionsPropertyName, ConditionsCollection) then begin
            if not TryInitializeCollection(ConditionsCollection) then
                SendAndLogError(GetLastErrorText, StrSubstNo(UnableToParseJsonArrayErr, ConditionsPropertyName));
            AddEventConditions(ConditionsCollection, EventConditions, SourcePageNo, ConditionsCount);
            ConditionsCount := ConditionsCount + 1;
        end;
    end;

    [TryFunction]
    local procedure TryInitializeCollection(var ConditionsCollection: DotNet JToken)
    begin
        JSONManagement.InitializeCollectionFromJArray(ConditionsCollection);
        // need to do some action on the collection to check if it is of Collection type
        if JSONManagement.GetCollectionCount() < 0 then
            Error(GetLastErrorText);
    end;

    local procedure AddEventConditions(ConditionsArray: DotNet JObject; var EventConditions: FilterPageBuilder; SourcePageNo: Integer; ConditionIndex: Integer)
    var
        TableMetadata: Record "Table Metadata";
        PageControlField: Record "Page Control Field";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        ConditionName: DotNet JToken;
        Condition: DotNet JObject;
        ConditionValue: DotNet JToken;
        FieldId: Integer;
        tableNo: Integer;
    begin
        // get source table id
        PageControlField.SetFilter(PageNo, '%1', SourcePageNo);
        PageControlField.FindFirst();
        tableNo := PageControlField.TableNo;
        RecRef.Open(tableNo);

        PageControlField.Reset();
        PageControlField.SetFilter(PageNo, '%1', SourcePageNo);

        foreach Condition in ConditionsArray do
            if Condition.TryGetValue('Name', ConditionName) and Condition.TryGetValue('Value', ConditionValue) then begin
                // get id of the field from the page in the page's source table
                PageControlField.SetFilter(ControlName, ConditionName.ToString());
                if not PageControlField.FindFirst() then
                    SendAndLogError(GetLastErrorText, StrSubstNo(NoControlOnPageErr, ConditionName.ToString(), GetPageName(SourcePageNo)));

                FieldId := PageControlField.FieldNo;
                FieldRef := RecRef.Field(FieldId);

                // filter Header/Lines Table
                // throws an error message if can not convert types
                FieldRef.SetFilter(ConditionValue.ToString());
            end;

        // create Filter Page Builder
        TableMetadata.Get(tableNo);
        EventConditions.AddTable(TableMetadata.Caption, tableNo);
        EventConditions.SetView(EventConditions.Name(ConditionIndex), RecRef.GetView());
    end;

    [TryFunction]
    local procedure TryParseJson(ConditionsTxt: Text; var ConditionsArray: DotNet JObject)
    begin
        JSONManagement.InitializeObject(ConditionsTxt);
        JSONManagement.GetJSONObject(ConditionsArray);
    end;

    [TryFunction]
    local procedure TryDecodeConditions(var ConditionsTxt: Text)
    var
        Convert: DotNet Convert;
        Encoding: DotNet Encoding;
    begin
        ConditionsTxt := Encoding.UTF8.GetString(Convert.FromBase64String(ConditionsTxt));
    end;

    local procedure SendAndLogError(ErrorText: Text; Description: Text)
    var
        Company: Record Company;
        ActivityLog: Record "Activity Log";
    begin
        // log exact error message
        Company.Get(CompanyName);
        ActivityLog.LogActivityForUser(
          Company.RecordId, ActivityLog.Status::Failed, 'Power Automate', Description, ErrorText, UserId);
        // send descriptive error to user
        Error(Description);
    end;

    procedure GetPageName(PageId: Integer): Text
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetFilter("Object ID", Format(PageId));
        AllObj.SetFilter("Object Type", 'PAGE');
        AllObj.FindFirst();
        exit(AllObj."Object Name");
    end;

    procedure GetUnableToParseEncodingErr(): Text
    begin
        exit(UnableToParseEncodingErr);
    end;

    procedure GetUnableToParseInvalidJsonErr(): Text
    begin
        exit(UnableToParseInvalidJsonErr);
    end;

    procedure GetNoControlOnPageErr(): Text
    begin
        exit(NoControlOnPageErr);
    end;

    procedure GetUnableToParseJsonArrayErr(): Text
    begin
        exit(UnableToParseJsonArrayErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindTaskSchedulerAllowed(var IsTaskSchedulingAllowed: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateWorkflowEventConditions(ConditionsTxt: Text; EventCode: Code[128]; ConditionsObject: DotNet JObject; var EventConditions: FilterPageBuilder; var ConditionsCount: Integer; var Result: Text; var IsHandled: Boolean)
    begin
    end;
}

