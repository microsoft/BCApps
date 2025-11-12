namespace Microsoft.API.Webhooks;

using System.Integration;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.Graph;
using System.Utilities;
using System.Threading;
using System.Security.AccessControl;
using System.Environment.Configuration;
using System.DataAdministration;

codeunit 6153 "API Webhook Notification Mgt."
{
    // Registers notifications in table API Webhook Notification on entity insert, modify, rename and delete

    SingleInstance = true;
    Permissions = TableData "API Webhook Subscription" = rimd,
                  TableData "API Webhook Notification" = rimd,
                  TableData "API Webhook Notification Aggr" = rimd;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        APIWebhookCategoryLbl: Label 'AL API Webhook', Locked = true;
        JobQueueCategoryCodeLbl: Label 'APIWEBHOOK', Locked = true;
        JobQueueCategoryDescLbl: Label 'Send API Webhook Notifications';
        CreateNotificationMsg: Label 'Create new notification. Subscription: %1. Expiration time: %2. Table: %3. Last modified time: %4. Change type: %5. Notification ID: %6.', Locked = true;
        CannotCreateNotificationErr: Label 'Cannot create new notification. Subscription: %1. Expiration time: %2. Table: %3. Last modified time: %4. Change type: %5.', Locked = true;
        ZeroSystemIdTxt: Label 'The record has zero system ID. Subscription: %1. Expiration time: %2. Table: %3. Last modified time: %4. Change type: %5.', Locked = true;
        FilterMatchingMsg: Label 'The record in table %3 is matching the filter in %4 %5. Subscription: %1. Expiration time: %2', Locked = true;
        FilterMismatchingMsg: Label 'The record in table %3 is mismatching the filter in %4 %5. Subscription: %1. Expiration time: %2', Locked = true;
        DeleteSubscriptionMsg: Label 'Delete subscription. Subscription: %1. Expiration time: %2. Table: %3.', Locked = true;
        DeleteObsoleteOrUnsupportedSubscriptionMsg: Label 'Delete subscription for an obsolete or unsupported entity. Subscription: %1. Expiration time: %2. Table: %3.', Locked = true;
        UnsupportedFieldTypeErr: Label 'The %1 field in the %2 table is of an unsupported type.', Locked = true;
        ChangeTypeOption: Option Created,Updated,Deleted,Collection;
        CachedApiSubscriptionEnabled: Boolean;
        CachedDetailedLoggingEnabled: Boolean;
        FindingEntityMsg: Label 'Finding entity for subscription. Subscription: %1. Expiration time: %2. Table: %3.', Locked = true;
        CannotFindEntityErr: Label 'Cannot find entity. Subscription: %1. Expiration time: %2. Table: %3.', Locked = true;
        TemporarySourceTableErr: Label 'No support for entities with a temporary source table. Subscription: %1. Expiration time: %2. Table: %3.', Locked = true;
        JobQueueEntrySourceTableErr: Label 'No support for entities with source table Job Queue Entry. Subscription: %1. Expiration time: %2. Table: %3.', Locked = true;
        CompositeEntityKeyErr: Label 'No support for entities with a composite key. Subscription: %1. Expiration time: %2. Table: %3. Fields: %4.', Locked = true;
        IncorrectEntityKeyErr: Label 'Incorrect entity key. Subscription: %1. Expiration time: %2. Table: %3. Fields: %4. ', Locked = true;
        ScheduleJobMsg: Label 'Schedule job. Processing time: %1. Earliest start time: %2. Latest start time: %3.', Locked = true;
        ReadyJobExistsMsg: Label 'Ready job exists. Earliest start time: %1.', Locked = true;
        CreateJobCategoryMsg: Label 'Create new job category.', Locked = true;
        CreateJobMsg: Label 'Create new job. Earliest start time: %1.', Locked = true;
        DeleteHangingJobMsg: Label 'Delete hanging job. Earliest start time: %1.', Locked = true;
        FailedDeletingAPIWebhooksLbl: Label 'Failed deleting API Webhooks. Error Code %1, Error message: %2', Locked = true;
        UseCachedApiSubscriptionEnabled: Boolean;
        UseCachedDetailedLoggingEnabled: Boolean;
        TooManyJobsMsg: Label 'New job is not created. Count of jobs cannot exceed %1.', Locked = true;
        NoPermissionsTxt: Label 'No permissions.', Locked = true;
        TooManyNotificationsTxt: Label 'Too many notifications', Locked = true;
        FieldTok: Label 'Field', Locked = true;
        EqConstTok: Label '=CONST(', Locked = true;
        EqFilterTok: Label '=FILTER(', Locked = true;
        CachedTotalCountOfExistingNotifications: Boolean;
        TotalCountOfExistingNotifications: Integer;

    [Scope('OnPrem')]
    procedure OnDatabaseInsert(var RecRef: RecordRef)
    begin
        ProcessSubscriptions(RecRef, ChangeTypeOption::Created);
    end;

    [Scope('OnPrem')]
    procedure OnDatabaseModify(var RecRef: RecordRef)
    begin
        ProcessSubscriptions(RecRef, ChangeTypeOption::Updated);
    end;

    [Scope('OnPrem')]
    procedure OnDatabaseDelete(var RecRef: RecordRef)
    begin
        ProcessSubscriptions(RecRef, ChangeTypeOption::Deleted);
    end;

    [Scope('OnPrem')]
    procedure OnDatabaseRename(var RecRef: RecordRef; var xRecRef: RecordRef)
    begin
        ProcessSubscriptionsOnRename(RecRef, xRecRef);
    end;

    local procedure ProcessSubscriptions(var RecRef: RecordRef; ChangeType: Option)
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        ScheduleJobQueue: Boolean;
        EarliestStartDateTime: DateTime;
    begin
        if RecRef.IsTemporary then
            exit;

        if not GetSubscriptions(APIWebhookSubscription, RecRef.Number) then
            exit;

        repeat
            if ProcessSubscription(RecRef, APIWebhookSubscription, ChangeType) then
                ScheduleJobQueue := true;
        until APIWebhookSubscription.Next() = 0;

        if ScheduleJobQueue then begin
            EarliestStartDateTime := CurrentDateTime();
            ScheduleJob(EarliestStartDateTime);
        end;
    end;

    local procedure ProcessSubscription(var RecRef: RecordRef; var APIWebhookSubscription: Record "API Webhook Subscription"; ChangeType: Option): Boolean
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
    begin
        if not GetEntity(APIWebhookSubscription, ApiWebhookEntity) then begin
            Session.LogMessage('000024M', StrSubstNo(DeleteObsoleteOrUnsupportedSubscriptionMsg, APIWebhookSubscription.SystemId,
                DateTimeToString(APIWebhookSubscription."Expiration Date Time"), APIWebhookSubscription."Source Table Id"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
            exit(false);
        end;

        if CheckTableFilters(APIWebhookSubscription, ApiWebhookEntity, RecRef) then
            exit(RegisterNotification(ApiWebhookEntity, APIWebhookSubscription, RecRef, ChangeType));

        exit(false);
    end;

    local procedure ProcessSubscriptionsOnRename(var RecRef: RecordRef; var xRecRef: RecordRef)
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        ScheduleJobQueue: Boolean;
        EarliestStartDateTime: DateTime;
    begin
        if RecRef.IsTemporary then
            exit;

        if not GetSubscriptions(APIWebhookSubscription, RecRef.Number) then
            exit;

        repeat
            if ProcessSubscriptionOnRename(RecRef, xRecRef, APIWebhookSubscription) then
                ScheduleJobQueue := true;
        until APIWebhookSubscription.Next() = 0;

        if ScheduleJobQueue then begin
            EarliestStartDateTime := CurrentDateTime();
            ScheduleJob(EarliestStartDateTime);
        end;
    end;

    local procedure ProcessSubscriptionOnRename(var RecRef: RecordRef; var xRecRef: RecordRef; var APIWebhookSubscription: Record "API Webhook Subscription"): Boolean
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        RegisteredNotificationDeleted: Boolean;
        RegisteredNotificationCreated: Boolean;
        RecordSystemId: Guid;
    begin
        if not GetEntity(APIWebhookSubscription, ApiWebhookEntity) then begin
            Session.LogMessage('000024N', StrSubstNo(DeleteObsoleteOrUnsupportedSubscriptionMsg, APIWebhookSubscription.SystemId,
                DateTimeToString(APIWebhookSubscription."Expiration Date Time"), APIWebhookSubscription."Source Table Id"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
            exit(false);
        end;

        RecordSystemId := RecRef.Field(RecRef.SystemIdNo).Value();
        if IsNullGuid(RecordSystemId) then
            RecordSystemId := xRecRef.Field(RecRef.SystemIdNo).Value();

        if ApiWebhookEntity."OData Key Specified" then begin
            if not CheckTableFilters(APIWebhookSubscription, ApiWebhookEntity, RecRef) then
                exit(false);
            exit(RegisterNotification(ApiWebhookEntity, APIWebhookSubscription, RecRef, ChangeTypeOption::Updated, RecordSystemId));
        end;

        if CheckTableFilters(APIWebhookSubscription, ApiWebhookEntity, xRecRef) then
            RegisteredNotificationDeleted :=
              RegisterNotification(ApiWebhookEntity, APIWebhookSubscription, xRecRef, ChangeTypeOption::Deleted, RecordSystemId);
        if CheckTableFilters(APIwebhookSubscription, ApiWebhookEntity, RecRef) then
            RegisteredNotificationCreated :=
              RegisterNotification(ApiWebhookEntity, APIWebhookSubscription, RecRef, ChangeTypeOption::Created, RecordSystemId);
        exit(RegisteredNotificationDeleted or RegisteredNotificationCreated);
    end;

    local procedure GetSubscriptions(var APIWebhookSubscription: Record "API Webhook Subscription"; TableId: Integer): Boolean
    var
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
    begin
        if not IsApiSubscriptionEnabled() then
            exit(false);

        if APIWebhookSubscription.IsEmpty() then
            exit(false);

        APIWebhookSubscription.SetFilter("Expiration Date Time", '>%1', CurrentDateTime());
        APIWebhookSubscription.SetRange("Source Table Id", TableId);
        APIWebhookSubscription.SetFilter("Company Name", '%1|%2', CompanyName(), '');

        if not CDSIntegrationMgt.IsBusinessEventsEnabled() then
            APIWebhookSubscription.SetRange("Subscription Type", APIWebhookSubscription."Subscription Type"::Regular);

        exit(APIWebhookSubscription.FindSet());
    end;

    [Scope('OnPrem')]
    procedure GetDatabaseTableTriggerSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        Enabled: Boolean;
    begin
        if OnDatabaseDelete and OnDatabaseInsert and OnDatabaseModify and OnDatabaseRename then
            exit;

        if not GraphMgtGeneralTools.IsApiSubscriptionEnabled() then
            exit;

        APIWebhookSubscription.SetFilter("Expiration Date Time", '>%1', CurrentDateTime());
        APIWebhookSubscription.SetFilter("Company Name", '%1|%2', CompanyName, '');
        APIWebhookSubscription.SetRange("Source Table Id", TableID);
        Enabled := not APIWebhookSubscription.IsEmpty();
        if not Enabled then
            exit;

        OnDatabaseRename := true;
        OnDatabaseModify := true;
        OnDatabaseInsert := true;
        OnDatabaseDelete := true;
    end;

    [Scope('OnPrem')]
    procedure GetEntity(var APIWebhookSubscription: Record "API Webhook Subscription"; var ApiWebhookEntity: Record "Api Webhook Entity"): Boolean
    begin
        if IsDetailedLoggingEnabled() then
            Session.LogMessage('00006ZN', StrSubstNo(FindingEntityMsg, APIWebhookSubscription.SystemId, DateTimeToString(APIWebhookSubscription."Expiration Date Time"),
                APIWebhookSubscription."Source Table Id"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
        if APIWebhookSubscription."Source Table Id" = Database::"Job Queue Entry" then begin
            Session.LogMessage('0000HE3', StrSubstNo(JobQueueEntrySourceTableErr, APIWebhookSubscription.SystemId, DateTimeToString(APIWebhookSubscription."Expiration Date Time"),
                APIWebhookSubscription."Source Table Id"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
            exit(false);
        end;
        ApiWebhookEntity.SetRange(Publisher, APIWebhookSubscription."Entity Publisher");
        ApiWebhookEntity.SetRange(Group, APIWebhookSubscription."Entity Group");
        ApiWebhookEntity.SetRange(Version, APIWebhookSubscription."Entity Version");
        ApiWebhookEntity.SetRange(Name, APIWebhookSubscription."Entity Set Name");
        ApiWebhookEntity.SetRange("Table No.", APIWebhookSubscription."Source Table Id");
        if not ApiWebhookEntity.FindFirst() then begin
            Session.LogMessage('000029S', StrSubstNo(CannotFindEntityErr, APIWebhookSubscription.SystemId, DateTimeToString(APIWebhookSubscription."Expiration Date Time"),
                APIWebhookSubscription."Source Table Id"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
            exit(false);
        end;
        if ApiWebhookEntity."Table Temporary" then begin
            Session.LogMessage('000029T', StrSubstNo(TemporarySourceTableErr, APIWebhookSubscription.SystemId, DateTimeToString(APIWebhookSubscription."Expiration Date Time"),
                APIWebhookSubscription."Source Table Id"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
            exit(false);
        end;
        if StrPos(ApiWebhookEntity."Key Fields", ',') > 0 then begin
            Session.LogMessage('000029U', StrSubstNo(CompositeEntityKeyErr, APIWebhookSubscription.SystemId, DateTimeToString(APIWebhookSubscription."Expiration Date Time"),
                APIWebhookSubscription."Source Table Id", ApiWebhookEntity."Key Fields"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
            exit(false);
        end;
        exit(true);
    end;

    local procedure CheckTableFilters(var APIWebhookSubscription: Record "API Webhook Subscription"; var ApiWebhookEntity: Record "Api Webhook Entity"; var RecRef: RecordRef): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        TempRecRef: RecordRef;
        FiltersInStream: InStream;
        TableFilters: Text;
    begin
        TempBlob.FromRecord(ApiWebhookEntity, ApiWebhookEntity.FieldNo("Table Filters"));
        TempBlob.CreateInStream(FiltersInStream, TEXTENCODING::UTF8);
        FiltersInStream.Read(TableFilters);

        if TableFilters <> '' then begin
            TempRecRef.Open(RecRef.Number, true);
            TempRecRef.Init();
            CopyPrimaryKeyFields(RecRef, TempRecRef);
            CopyFilterFields(RecRef, TempRecRef, TableFilters);
            TempRecRef.Insert();
            TempRecRef.SetView(TableFilters);
            if TempRecRef.IsEmpty() then begin
                Session.LogMessage('00006ZO', StrSubstNo(FilterMismatchingMsg, APIWebhookSubscription.SystemId, DateTimeToString(APIWebhookSubscription."Expiration Date Time"),
                    RecRef.Number, ApiWebhookEntity."Object Type", ApiWebhookEntity."Object ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
                exit(false);
            end;
        end;
        if IsDetailedLoggingEnabled() then
            Session.LogMessage('00006ZP', StrSubstNo(FilterMatchingMsg, APIWebhookSubscription.SystemId, DateTimeToString(APIWebhookSubscription."Expiration Date Time"),
            RecRef.Number, ApiWebhookEntity."Object Type", ApiWebhookEntity."Object ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
        exit(true);
    end;

    local procedure CopyPrimaryKeyFields(var FromRecRef: RecordRef; var ToRecRef: RecordRef)
    var
        FromFieldRef: FieldRef;
        KeyRef: KeyRef;
        I: Integer;
    begin
        KeyRef := FromRecRef.KeyIndex(1);
        for I := 1 to KeyRef.FieldCount() do begin
            FromFieldRef := KeyRef.FieldIndex(I);
            CopyFieldValue(FromFieldRef, ToRecRef);
        end;
    end;

    local procedure CopyFilterFields(var FromRecRef: RecordRef; var ToRecRef: RecordRef; TableFilters: Text)
    var
        FromFieldRef: FieldRef;
        RemainingTableFilters: Text;
        FieldNoTxt: Text;
        FieldNo: Integer;
        FieldTokLen: Integer;
        Pos: Integer;
        EqPos: Integer;
        I: Integer;
        N: Integer;
    begin
        FieldTokLen := StrLen(FieldTok);
        N := StrLen(TableFilters);
        RemainingTableFilters := TableFilters;
        for I := 0 to N do
            if StrLen(RemainingTableFilters) > 0 then begin
                Pos := StrPos(RemainingTableFilters, FieldTok);
                if Pos > 0 then begin
                    RemainingTableFilters := CopyStr(RemainingTableFilters, Pos + FieldTokLen);
                    EqPos := StrPos(RemainingTableFilters, EqConstTok);
                    // At least one digit must be before "=" sign
                    if EqPos < 2 then
                        EqPos := StrPos(RemainingTableFilters, EqFilterTok);
                    // Integer max value is 2,147,483,647 so no more then Text[10]
                    if (EqPos > 1) and (EqPos < 12) then begin
                        FieldNoTxt := CopyStr(RemainingTableFilters, 1, EqPos - 1);
                        if Evaluate(FieldNo, FieldNoTxt) then
                            if FromRecRef.FieldExist(FieldNo) then begin
                                FromFieldRef := FromRecRef.Field(FieldNo);
                                CopyFieldValue(FromFieldRef, ToRecRef);
                            end;
                    end;
                end;
            end else
                I := N;
    end;

    local procedure CopyFieldValue(var FromFieldRef: FieldRef; var ToRecordRef: RecordRef)
    var
        ToFieldRef: FieldRef;
    begin
        if FromFieldRef.Class = FieldClass::Normal then begin
            ToFieldRef := ToRecordRef.Field(FromFieldRef.Number);
            ToFieldRef.Value := FromFieldRef.Value();
        end;
    end;

    [Scope('OnPrem')]
    procedure DeleteSubscription(var APIWebhookSubscription: Record "API Webhook Subscription")
    var
        APIWebhookNotification: Record "API Webhook Notification";
        APIWebhookNotificationAggr: Record "API Webhook Notification Aggr";
        [SecurityFiltering(SecurityFilter::Ignored)]
        APIWebhookSubscription2: Record "API Webhook Subscription";
        [SecurityFiltering(SecurityFilter::Ignored)]
        APIWebhookNotification2: Record "API Webhook Notification";
        [SecurityFiltering(SecurityFilter::Ignored)]
        APIWebhookNotificationAggr2: Record "API Webhook Notification Aggr";
    begin
        Session.LogMessage('00006ZQ', StrSubstNo(DeleteSubscriptionMsg, APIWebhookSubscription.SystemId,
            DateTimeToString(APIWebhookSubscription."Expiration Date Time"), APIWebhookSubscription."Source Table Id"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);

        if (not APIWebhookSubscription2.WritePermission()) or
           (not APIWebhookNotification2.WritePermission()) or
           (not APIWebhookNotificationAggr2.WritePermission()) then begin
            Session.LogMessage('0000DY1', NoPermissionsTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
            exit;
        end;

        APIWebhookNotification.SetRange("Subscription ID", APIWebhookSubscription."Subscription Id");
        if not APIWebhookNotification.IsEmpty() then begin
            ForceDeleteAPIWebhookNotifications(APIWebhookNotification);
            Commit();
        end;

        APIWebhookNotificationAggr.SetRange("Subscription ID", APIWebhookSubscription."Subscription Id");
        if not APIWebhookNotificationAggr.IsEmpty() then begin
            APIWebhookNotificationAggr.DeleteAll(true);
            Commit();
        end;
        if not APIWebhookSubscription.Delete() then;
    end;

    local procedure RegisterNotification(var ApiWebhookEntity: Record "Api Webhook Entity"; var APIWebhookSubscription: Record "API Webhook Subscription"; var RecRef: RecordRef; ChangeType: Option): Boolean
    var
        SavedRecordRef: RecordRef;
        RecordSystemId: Guid;
    begin
        RecordSystemId := RecRef.Field(RecRef.SystemIdNo).Value();
        if IsNullGuid(RecordSystemId) then
            if ChangeType = ChangeTypeOption::Updated then begin
                SavedRecordRef.Open(RecRef.Number);
                CopyPrimaryKeyFields(RecRef, SavedRecordRef);
                if SavedRecordRef.Find() then
                    RecordSystemId := SavedRecordRef.Field(SavedRecordRef.SystemIdNo).Value();
            end;
        exit(RegisterNotification(ApiWebhookEntity, APIWebhookSubscription, RecRef, ChangeType, RecordSystemId));
    end;

    procedure ForceDeleteAPIWebhookNotifications(var APIWebhookNotification: Record "API Webhook Notification")
    var
        I: Integer;
        NumberOfRetries: Integer;
        WaitBetweenDeletes: Integer;
        Success: Boolean;
    begin
        if APIWebhookNotification.IsEmpty() then
            exit;

        NumberOfRetries := 5;
        WaitBetweenDeletes := 1000;

        for I := 1 to NumberOfRetries do begin
            ClearLastError();
            Commit();
            OnDeleteAPIWebhookNotifications(APIWebhookNotification, Success);
            if Success then
                exit;

            Session.LogMessage('0000HRE', StrSubstNo(FailedDeletingAPIWebhooksLbl, GetLastErrorCode(), GetLastErrorText()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
            Sleep(WaitBetweenDeletes);
        end;

        ClearLastError();
    end;

    local procedure RegisterNotification(var ApiWebhookEntity: Record "Api Webhook Entity"; var APIWebhookSubscription: Record "API Webhook Subscription"; var RecRef: RecordRef; ChangeType: Option; RecordSystemId: Guid): Boolean
    var
        TotalAPIWebhookNotification: Record "API Webhook Notification";
        APIWebhookNotification: Record "API Webhook Notification";
        [SecurityFiltering(SecurityFilter::Ignored)]
        APIWebhookNotification2: Record "API Webhook Notification";
        APIWebhookNotificationSend: Codeunit "API Webhook Notification Send";
        FieldValue: Text;
    begin
        if not APIWebhookNotification2.WritePermission() then begin
            Session.LogMessage('0000DY2', NoPermissionsTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
            exit(false);
        end;

        if IsNullGuid(RecordSystemId) then begin
            Session.LogMessage('0000FMO', StrSubstNo(ZeroSystemIdTxt, APIWebhookSubscription.SystemId,
                DateTimeToString(APIWebhookSubscription."Expiration Date Time"), APIWebhookSubscription."Source Table Id",
                DateTimeToString(APIWebhookNotification."Last Modified Date Time"), APIWebhookNotification."Change Type"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
            exit(false);
        end;

        if not CachedTotalCountOfExistingNotifications then begin
            if not TotalAPIWebhookNotification.IsEmpty() then
                TotalCountOfExistingNotifications := TotalAPIWebhookNotification.Count()
            else
                Clear(TotalCountOfExistingNotifications);

            CachedTotalCountOfExistingNotifications := true;
        end;

        if TotalCountOfExistingNotifications > APIWebhookNotificationSend.GetMaxNumberOfLoggedNotifications() then begin
            Session.LogMessage('0000HF4', TooManyNotificationsTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
            exit(false);
        end;

        if TryGetEntityKeyValue(APIWebhookSubscription, ApiWebhookEntity, RecRef, FieldValue, RecordSystemId) then begin
            APIWebhookNotification.SetRange("Subscription ID");
            APIWebhookNotification.ID := Guid.CreateSequentialGuid();
            APIWebhookNotification."Subscription ID" := APIWebhookSubscription."Subscription Id";
            APIWebhookNotification."Created By User SID" := UserSecurityId();
            APIWebhookNotification."Change Type" := ChangeType;
            // Cannot use $systemModifiedAt as it is not updated yet in OnDatabaseModify
            APIWebhookNotification."Last Modified Date Time" := CurrentDateTime();
            APIWebhookNotification."Entity ID" := RecordSystemId;
            APIWebhookNotification."Entity Key Value" := CopyStr(FieldValue, 1, MaxStrLen(APIWebhookNotification."Entity Key Value"));
            if APIWebhookNotification.Insert(true) then begin
                TotalCountOfExistingNotifications += 1;
                if IsDetailedLoggingEnabled() then
                    Session.LogMessage('000024P', StrSubstNo(CreateNotificationMsg, APIWebhookSubscription.SystemId,
                        DateTimeToString(APIWebhookSubscription."Expiration Date Time"), APIWebhookSubscription."Source Table Id", DateTimeToString(APIWebhookNotification."Last Modified Date Time"),
                        APIWebhookNotification."Change Type", APIWebhookNotification.ID), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
                exit(true);
            end;
        end;

        Session.LogMessage('000029L', StrSubstNo(CannotCreateNotificationErr, APIWebhookSubscription.SystemId,
            DateTimeToString(APIWebhookSubscription."Expiration Date Time"), APIWebhookSubscription."Source Table Id",
            DateTimeToString(APIWebhookNotification."Last Modified Date Time"), APIWebhookNotification."Change Type"), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure TryGetEntityKeyField(var APIWebhookSubscription: Record "API Webhook Subscription"; var ApiWebhookEntity: Record "Api Webhook Entity"; var RecRef: RecordRef; var FieldRef: FieldRef): Boolean
    var
        FieldNo: Integer;
    begin
        if StrPos(ApiWebhookEntity."Key Fields", ',') > 0 then begin
            Session.LogMessage('000029M', StrSubstNo(CompositeEntityKeyErr, APIWebhookSubscription.SystemId, DateTimeToString(APIWebhookSubscription."Expiration Date Time"),
                RecRef.Number, ApiWebhookEntity."Key Fields"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
            exit(false);
        end;

        if not Evaluate(FieldNo, ApiWebhookEntity."Key Fields") then begin
            Session.LogMessage('000029N', StrSubstNo(IncorrectEntityKeyErr, APIWebhookSubscription.SystemId, DateTimeToString(APIWebhookSubscription."Expiration Date Time"),
                RecRef.Number, ApiWebhookEntity."Key Fields"), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
            exit(false);
        end;

        FieldRef := RecRef.Field(FieldNo);
        exit(true);
    end;

    local procedure TryGetEntityKeyValue(var APIWebhookSubscription: Record "API Webhook Subscription"; var ApiWebhookEntity: Record "Api Webhook Entity"; var RecRef: RecordRef; var FieldValue: Text; RecordSystemId: Guid): Boolean
    var
        FieldRef: FieldRef;
    begin
        if not TryGetEntityKeyField(APIWebhookSubscription, ApiWebhookEntity, RecRef, FieldRef) then
            exit(false);

        if FieldRef.Number = RecRef.SystemIdNo then begin
            FieldValue := LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(RecordSystemId));
            exit(true);
        end;

        if not GetRawFieldValue(FieldRef, FieldValue) then
            exit(false);

        exit(true);
    end;

    local procedure GetRawFieldValue(var FieldRef: FieldRef; var Value: Text): Boolean
    var
        Date: Date;
        Time: Time;
        DateTime: DateTime;
        BigInt: BigInteger;
        Decimal: Decimal;
        Bool: Boolean;
        Guid: Guid;
        ErrorMessage: Text;
    begin
        case FieldRef.Type of
            FieldType::GUID:
                begin
                    Guid := FieldRef.Value();
                    Value := LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(Guid));
                end;
            FieldType::Code, FieldType::Text:
                begin
                    Value := FieldRef.Value();
                    if Value <> '' then
                        Value := Format(FieldRef.Value);
                end;
            FieldType::Option:
                Value := Format(FieldRef);
            FieldType::Integer, FieldType::BigInteger:
                Value := Format(FieldRef.Value);
            FieldType::Boolean:
                begin
                    Bool := FieldRef.Value();
                    Value := SetBoolFormat(Bool);
                end;
            FieldType::Date:
                begin
                    Date := FieldRef.Value();
                    Value := SetDateFormat(Date);
                end;
            FieldType::Time:
                begin
                    Time := FieldRef.Value();
                    Value := SetTimeFormat(Time);
                end;
            FieldType::DateTime:
                begin
                    DateTime := FieldRef.Value();
                    Value := SetDateTimeFormat(DateTime);
                end;
            FieldType::Duration:
                begin
                    BigInt := FieldRef.Value();
                    // Use round to avoid conversion errors due to the conversion from decimal to long.
                    BigInt := Round(BigInt / 60000, 1);
                    Value := Format(BigInt);
                end;
            FieldType::DateFormula:
                Value := Format(FieldRef.Value);
            FieldType::Decimal:
                begin
                    Decimal := FieldRef.Value();
                    Value := SetDecimalFormat(Decimal);
                end;
            else begin
                ErrorMessage := StrSubstNo(UnsupportedFieldTypeErr, FieldRef.Caption, FieldRef.Record().Caption);
                Session.LogMessage('000029O', ErrorMessage, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
                exit(false);
            end;
        end;
        exit(true);
    end;

    local procedure SetDateFormat(InDate: Date) OutDate: Text
    begin
        OutDate := Format(InDate, 0, '<Year4>-<Month,2>-<Day,2>');
    end;

    local procedure SetTimeFormat(InTime: Time) OutTime: Text
    begin
        OutTime := ConvertStr(Format(InTime, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'), ' ', '0');
    end;

    local procedure SetDateTimeFormat(InDateTime: DateTime) OutDateTime: Text
    begin
        if InDateTime = 0DT then
            OutDateTime := SetDateFormat(0D) + 'T' + SetTimeFormat(0T) + 'Z'
        else
            OutDateTime := SetDateFormat(DT2Date(InDateTime)) + 'T' + SetTimeFormat(DT2Time(InDateTime)) + 'Z';
    end;

    local procedure SetDecimalFormat(InDecimal: Decimal) OutDecimal: Text
    begin
        OutDecimal := Format(InDecimal, 0, '<Sign>') + Format(InDecimal, 0, '<Integer>');

        if CopyStr(Format(InDecimal, 0, '<Decimals>'), 2) <> '' then
            OutDecimal := OutDecimal + '.' + CopyStr(Format(InDecimal, 0, '<Decimals>'), 2)
        else
            OutDecimal := OutDecimal + '.0';
    end;

    local procedure SetBoolFormat(InBoolean: Boolean) OutBoolean: Text
    begin
        if InBoolean then
            OutBoolean := 'true'
        else
            OutBoolean := 'false';
    end;

    [Scope('OnPrem')]
    procedure ScheduleJob(EarliestStartDateTime: DateTime)
    var
        JobQueueEntry: Record "Job Queue Entry";
        ProcessingDateTime: DateTime;
        LatestStartDateTime: DateTime;
    begin
        ProcessingDateTime := CurrentDateTime();
        LatestStartDateTime := EarliestStartDateTime + GetDelayTime();

        if IsDetailedLoggingEnabled() then
            Session.LogMessage('000070M', StrSubstNo(ScheduleJobMsg, DateTimeToString(ProcessingDateTime), DateTimeToString(EarliestStartDateTime), DateTimeToString(LatestStartDateTime)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);

        if not CanScheduleJob() then begin
            Session.LogMessage('0000EWY', NoPermissionsTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
            exit;
        end;

        JobQueueEntry.SetLoadFields(ID, "Earliest Start Date/Time", Scheduled, "System Task ID");
        JobQueueEntry.ReadIsolation := JobQueueEntry.ReadIsolation::ReadUnCommitted;
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"API Webhook Notification Send");
        JobQueueEntry.SetRange("Job Queue Category Code", JobQueueCategoryCodeLbl);
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Ready);
        JobQueueEntry.SetRange("Earliest Start Date/Time", EarliestStartDateTime, LatestStartDateTime);
        if JobQueueEntry.FindFirst() then begin
            JobQueueEntry.CalcFields(Scheduled);
            if JobQueueEntry.Scheduled then begin
                Session.LogMessage('000070O', StrSubstNo(ReadyJobExistsMsg, DateTimeToString(JobQueueEntry."Earliest Start Date/Time")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
                exit;
            end;
        end;

        JobQueueEntry.SetFilter(Status, '%1|%2', JobQueueEntry.Status::"In Process", JobQueueEntry.Status::Ready);
        JobQueueEntry.SetRange("Earliest Start Date/Time");
        if JobQueueEntry.Count() >= GetMaxNumberOfJobs() then
            if not DeleteHangingJob() then begin
                Session.LogMessage('000070P', StrSubstNo(TooManyJobsMsg, GetMaxNumberOfJobs()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
                exit;
            end;

        CreateJob(LatestStartDateTime);
    end;

    internal procedure CanScheduleJob(): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
        [SecurityFiltering(SecurityFilter::Ignored)]
        JobQueueEntry2: Record "Job Queue Entry";
        User: Record User;
        Handled: Boolean;
        CanCreateTask: Boolean;
    begin
        if not (JobQueueEntry2.WritePermission() and JobQueueEntry.ReadPermission()) then
            exit(false);
        if not (JobQueueEntry.HasRequiredPermissions()) then
            exit(false);
        OnCanCreateTask(Handled, CanCreateTask);
        if Handled then
            exit(CanCreateTask);
        if not TASKSCHEDULER.CanCreateTask() then
            exit(false);
        if not User.Get(UserSecurityId()) then
            exit(false);
        if User."License Type" = User."License Type"::"Limited User" then
            exit(false);
        exit(true);
    end;

    local procedure DeleteHangingJob(): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
        Deleted: Boolean;
    begin
        // delete the hanging job as it blocks staring other jobs of the same category
        JobQueueEntry.SetLoadFields(Scheduled, "Earliest Start Date/Time");
        JobQueueEntry.SetRange("Job Queue Category Code", JobQueueCategoryCodeLbl);
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"In Process");
        if JobQueueEntry.FindFirst() then begin
            JobQueueEntry.CalcFields(Scheduled);
            if not JobQueueEntry.Scheduled then begin
                Session.LogMessage('0000EF4', StrSubstNo(DeleteHangingJobMsg, DateTimeToString(JobQueueEntry."Earliest Start Date/Time")), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
                JobQueueEntry.Delete();
                Deleted := true;
            end;
        end;
        exit(Deleted);
    end;

    local procedure CreateJob(EarliestStartDateTime: DateTime)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if EarliestStartDateTime = 0DT then
            EarliestStartDateTime := CurrentDateTime() + GetDelayTime();

        Session.LogMessage('00006ZR', StrSubstNo(CreateJobMsg, DateTimeToString(EarliestStartDateTime)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);

        SetJobParameters(JobQueueEntry, EarliestStartDateTime);
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
    end;

    local procedure SetJobParameters(var JobQueueEntry: Record "Job Queue Entry"; EarliestStartDateTime: DateTime)
    begin
        CreateApiWebhookJobCategoryIfMissing();

        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"API Webhook Notification Send";
        JobQueueEntry."Job Queue Category Code" :=
          CopyStr(JobQueueCategoryCodeLbl, 1, MaxStrLen(JobQueueEntry."Job Queue Category Code"));
        JobQueueEntry."Earliest Start Date/Time" := EarliestStartDateTime;
        JobQueueEntry."Recurring Job" := false;
        JobQueueEntry."Maximum No. of Attempts to Run" := 2;
        JobQueueEntry."Rerun Delay (sec.)" := GetDelayTime() div 1000;
    end;

    local procedure CreateApiWebhookJobCategoryIfMissing()
    var
        JobQueueCategory: Record "Job Queue Category";
    begin
        if not JobQueueCategory.Get(JobQueueCategoryCodeLbl) then begin
            Session.LogMessage('00006ZS', CreateJobCategoryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', APIWebhookCategoryLbl);
            JobQueueCategory.Validate(Code, CopyStr(JobQueueCategoryCodeLbl, 1, MaxStrLen(JobQueueCategory.Code)));
            JobQueueCategory.Validate(Description, CopyStr(JobQueueCategoryDescLbl, 1, MaxStrLen(JobQueueCategory.Description)));
            JobQueueCategory.Insert(true);
        end;
    end;

    local procedure GetDelayTime(): Integer
    var
        ServerSetting: Codeunit "Server Setting";
        Handled: Boolean;
        DelayTime: Integer;
    begin
        OnGetDelayTime(Handled, DelayTime);
        if Handled then
            exit(DelayTime);

        DelayTime := ServerSetting.GetApiSubscriptionDelayTime();
        exit(DelayTime);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDelayTime(var Handled: Boolean; var Value: Integer)
    begin
    end;

    [Scope('OnPrem')]
    procedure IsDetailedLoggingEnabled(): Boolean
    var
        Handled: Boolean;
        Enabled: boolean;
    begin
        if UseCachedDetailedLoggingEnabled then
            exit(CachedDetailedLoggingEnabled);

        OnGetDetailedLoggingEnabled(Handled, Enabled);
        if Handled then begin
            CachedDetailedLoggingEnabled := Enabled;
            UseCachedDetailedLoggingEnabled := true;
            exit(Enabled);
        end;

        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"API Webhook Notification Mgt.", 'OnDeleteAPIWebhookNotifications', '', false, false)]
    local procedure HandleDeleteAPIWebhookNotification(var ApiWebhookNotification: Record "API Webhook Notification"; var Success: Boolean)
    begin
        ApiWebhookNotification.DeleteAll();
        Success := true;
    end;

    [InternalEvent(false, true)]
    local procedure OnDeleteAPIWebhookNotifications(var ApiWebhookNotification: Record "API Webhook Notification"; var Success: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDetailedLoggingEnabled(var Handled: Boolean; var Enabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanCreateTask(var Handled: Boolean; var CanCreateTask: Boolean)
    begin
    end;

    local procedure IsApiSubscriptionEnabled(): Boolean
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if UseCachedApiSubscriptionEnabled then
            exit(CachedApiSubscriptionEnabled);

        CachedApiSubscriptionEnabled := GraphMgtGeneralTools.IsApiSubscriptionEnabled();
        UseCachedApiSubscriptionEnabled := true;

        exit(CachedApiSubscriptionEnabled);
    end;

    procedure Reset()
    begin
        UseCachedApiSubscriptionEnabled := false;
        UseCachedDetailedLoggingEnabled := false;
        Clear(CachedApiSubscriptionEnabled);
        Clear(CachedDetailedLoggingEnabled);
    end;

    local procedure GetMaxNumberOfJobs(): Integer
    begin
        exit(20);
    end;

    local procedure DateTimeToString(Value: DateTime): Text
    begin
        exit(Format(Value, 0, '<Year4>-<Month,2>-<Day,2> <Hours24>:<Minutes,2>:<Seconds,2><Second dec.><Comma,.>'));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearDatabaseConfig', '', false, false)]
    local procedure HandleOnClearCompanyConfig(SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    begin
        CleanupAPIWebhookSetup();
    end;

    local procedure CleanupAPIWebhookSetup()
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        APIWebhookNotification: Record "API Webhook Notification";
        APIWebhookNotificationAggr: Record "API Webhook Notification Aggr";
    begin
        APIWebhookSubscription.DeleteAll();
        Commit();
        APIWebhookNotification.DeleteAll();
        Commit();
        APIWebhookNotificationAggr.DeleteAll();
        Commit();
    end;
}

