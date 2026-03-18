namespace System.Integration;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Environment.Configuration;
using System.Threading;

codeunit 1798 "Data Migration Mgt."
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        DataMigrationError: Record "Data Migration Error";
        DataMigrationStatus: Record "Data Migration Status";
        Retry: Boolean;
        DataCreationFailed: Boolean;
    begin
        EnableDataMigrationNotificationForAllUsers();
        DataMigrationStatus.Get(Rec."Record ID to Process");
        DataMigrationStatus.SetRange("Migration Type", DataMigrationStatus."Migration Type");
        Retry := Rec."Parameter String" = RetryTxt;

        OnBeforeMigrationStarted(DataMigrationStatus, Retry);

        if not Retry then begin
            DataMigrationStatus.SetRange(Status, DataMigrationStatus.Status::Pending);
            DataMigrationFacade.OnFillStagingTables();
            // Close the transaction here otherwise the CODEUNIT.RUN cannot be invoked
            Commit();
        end else
            DataMigrationStatus.SetRange(Status, DataMigrationStatus.Status::"Completed with Errors");

        // migrate GL accounts (delete the existing ones on a first migration and if GL accounts are migrated)
        DataMigrationStatus.SetRange("Destination Table ID", DATABASE::"G/L Account");
        if DataMigrationStatus.FindFirst() and not Retry then
            if not CODEUNIT.Run(CODEUNIT::"Data Migration Del G/L Account") then
                DataMigrationError.CreateEntryNoStagingTable(DataMigrationStatus."Migration Type", DATABASE::"G/L Account");

        if CheckAbortRequestedAndMigrateEntity(
             DataMigrationStatus, DATABASE::"G/L Account", CODEUNIT::"GL Acc. Data Migration Facade", Retry)
        then
            exit;

        // migrate customers
        if CheckAbortRequestedAndMigrateEntity(DataMigrationStatus, DATABASE::Customer, CODEUNIT::"Customer Data Migration Facade", Retry) then
            exit;

        // migrate vendor
        if CheckAbortRequestedAndMigrateEntity(DataMigrationStatus, DATABASE::Vendor, CODEUNIT::"Vendor Data Migration Facade", Retry) then
            exit;

        // migrate items
        if CheckAbortRequestedAndMigrateEntity(DataMigrationStatus, DATABASE::Item, CODEUNIT::"Item Data Migration Facade", Retry) then
            exit;

        // migrate any other tables if any
        CheckAbortAndMigrateRemainingEntities(DataMigrationStatus, Retry);
        OnCreatePostMigrationData(DataMigrationStatus, DataCreationFailed);
        OnValidateMigration(DataMigrationStatus, DataCreationFailed);
        if DataCreationFailed then
            exit;

        OnAfterMigrationFinished(DataMigrationStatus, false, StartTime, Retry);
    end;

    var
        DataMigrationStatusFacade: Codeunit "Data Migration Status Facade";
        DataMigrationFacade: Codeunit "Data Migration Facade";
        AbortRequested: Boolean;
        StartTime: DateTime;
        RetryTxt: Label 'Retry', Locked = true;
        DataMigrationNotCompletedQst: Label 'A data migration is already in progress. To see the status of the migration, go to the %1 page. Do you want to do that now?', Comment = '%1 is the caption for Data Migration Overview';
        CustomerTableNotEmptyErr: Label 'The migration has stopped because we found some customers in %1. You must delete them and then restart the migration.', Comment = '%1 product name ';
        ItemTableNotEmptyErr: Label 'The migration has stopped because we found some items in %1. You must delete them and then restart the migration.', Comment = '%1 product name ';
        VendorTableNotEmptyErr: Label 'The migration has stopped because we found some vendors in %1. You must delete them and then restart the migration.', Comment = '%1 product name ';
        DataMigrationInProgressMsg: Label 'We''re migrating data to %1.', Comment = '%1 product name ';
        DataMigrationCompletedWithErrosMsg: Label 'Data migration has stopped due to errors. Go to the %1 page to fix them.', Comment = '%1 Data Migration Overview page';
        DataMigrationEntriesToPostMsg: Label 'Data migration is complete, however, there are still a few things to do. Go to the Data Migration Overview page for more information.';
        DataMigrationFinishedMsg: Label 'Yes! The data you chose was successfully migrated.';
        DataMigrationNotificationNameTxt: Label 'Data migration notification';
        DataMigrationNotificationDescTxt: Label 'Show a warning when data migration is either in progress or has completed.';
        DontShowTxt: Label 'Don''t show again';
        MigrationStatus: Option Pending,"In Progress","Completed with errors",Completed,Stopped,Failed,"Not Started";
        GoThereNowTxt: Label 'Go there now';
        MoreInfoTxt: Label 'Learn more';
        DataMigrationHelpTopicURLTxt: Label 'https://go.microsoft.com/fwlink/?linkid=859445', Locked = true;
        CustomersEmptyListNotificationNameTxt: Label 'Show a suggestion to import customers when none exists.';
        VendorsEmptyListNotificationNameTxt: Label 'Show a suggestion to import vendors when none exists.';
        ItemsEmptyListNotificationNameTxt: Label 'Show a suggestion to import items when none exists.';
        CustomerContactNotificationNameTxt: Label 'Show a suggestion to create contacts for newly created customers.';
        VendorContactNotificationNameTxt: Label 'Show a suggestion to create contacts for newly created vendors.';
        CustContactNotificationDescTxt: Label 'Show a suggestion to create contacts for customers.';
        VendContactNotificationDescTxt: Label 'Show a suggestion to create contacts for vendors.';

    local procedure HandleEntityMigration(var DataMigrationStatus: Record "Data Migration Status"; BaseAppMigrationCodeunitToRun: Integer; Retry: Boolean)
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        if DataMigrationStatus.FindFirst() then
            if DataMigrationStatus."Source Staging Table ID" > 0 then
                StagingTableEntityMigration(DataMigrationStatus, BaseAppMigrationCodeunitToRun, Retry)
            else begin
                DataMigrationStatusFacade.UpdateLineStatus(DataMigrationStatus."Migration Type",
                  DataMigrationStatus."Destination Table ID", DataMigrationStatus.Status::"In Progress");
                DataMigrationError.ClearEntryNoStagingTable(DataMigrationStatus."Migration Type",
                  DataMigrationStatus."Destination Table ID");
                Commit(); // save the dashboard before calling the extension codeunit
                if CODEUNIT.Run(DataMigrationStatus."Migration Codeunit To Run") then begin
                    DataMigrationStatus.Get(DataMigrationStatus."Migration Type", DataMigrationStatus."Destination Table ID");
                    if DataMigrationStatus."Migrated Number" = 0 then
                        DataMigrationStatusFacade.IncrementMigratedRecordCount(
                          DataMigrationStatus."Migration Type", DataMigrationStatus."Destination Table ID", DataMigrationStatus."Total Number");
                    DataMigrationStatus.SetRange(Status, DataMigrationStatus.Status::"In Progress");
                    if DataMigrationStatus.FindSet() then
                        DataMigrationStatusFacade.UpdateLineStatus(
                          DataMigrationStatus."Migration Type", DataMigrationStatus."Destination Table ID", DataMigrationStatus.Status::Completed);
                end else begin
                    DataMigrationError.CreateEntryNoStagingTable(DataMigrationStatus."Migration Type",
                      DataMigrationStatus."Destination Table ID");
                    DataMigrationStatusFacade.UpdateLineStatus(
                      DataMigrationStatus."Migration Type",
                      DataMigrationStatus."Destination Table ID",
                      DataMigrationStatus.Status::Failed);
                end;
            end;
        Commit(); // save the dashboard as the job could fail on the next task
    end;

    local procedure StagingTableEntityMigration(DataMigrationStatus: Record "Data Migration Status"; BaseAppCodeunitToRun: Integer; Retry: Boolean)
    var
        TempDataMigrationParametersBatch: Record "Data Migration Parameters" temporary;
        DummyDataMigrationStatus: Record "Data Migration Status";
        DataMigrationError: Record "Data Migration Error";
        StagingTableRecRef: RecordRef;
        "Count": Integer;
    begin
        StagingTableRecRef.Open(DataMigrationStatus."Source Staging Table ID");
        if StagingTableRecRef.FindSet() then begin
            DataMigrationStatusFacade.UpdateLineStatus(DataMigrationStatus."Migration Type",
              DataMigrationStatus."Destination Table ID", DummyDataMigrationStatus.Status::"In Progress");
            repeat
                if AbortRequested then
                    exit;

                DataMigrationError.Reset();
                if not Retry or
                   (Retry and
                    DataMigrationError.FindEntry(DataMigrationStatus."Migration Type",
                      DataMigrationStatus."Destination Table ID", StagingTableRecRef.RecordId) and
                    DataMigrationError."Scheduled For Retry" = true)
                then begin
                    Count += 1;

                    TempDataMigrationParametersBatch.Init();
                    TempDataMigrationParametersBatch.Key := Count;
                    TempDataMigrationParametersBatch."Migration Type" := DataMigrationStatus."Migration Type";
                    TempDataMigrationParametersBatch."Staging Table Migr. Codeunit" := DataMigrationStatus."Migration Codeunit To Run";
                    TempDataMigrationParametersBatch."Staging Table RecId To Process" := StagingTableRecRef.RecordId;
                    TempDataMigrationParametersBatch.Insert();

                    DataMigrationError.ClearEntry(DataMigrationStatus."Migration Type",
                      DataMigrationStatus."Destination Table ID",
                      StagingTableRecRef.RecordId);
                end;
                if Count = 100 then begin
                    // try to process batch
                    Commit(); // to save the transaction that has deleted the errors
                    ProcessBatch(DataMigrationStatus, BaseAppCodeunitToRun, TempDataMigrationParametersBatch, Count);
                    Count := 0;
                    TempDataMigrationParametersBatch.DeleteAll();
                end;
            until StagingTableRecRef.Next() = 0;

            if AbortRequested then
                exit;

            if Count > 0 then begin
                Commit(); // to save the transaction that has deleted the errors
                ProcessBatch(DataMigrationStatus, BaseAppCodeunitToRun, TempDataMigrationParametersBatch, Count);
            end;
        end;

        DataMigrationStatus.CalcFields("Error Count");
        if DataMigrationStatus."Error Count" = 0 then
            DataMigrationStatusFacade.UpdateLineStatus(
              DataMigrationStatus."Migration Type", DataMigrationStatus."Destination Table ID",
              DummyDataMigrationStatus.Status::Completed)
        else
            DataMigrationStatusFacade.UpdateLineStatus(
              DataMigrationStatus."Migration Type", DataMigrationStatus."Destination Table ID",
              DummyDataMigrationStatus.Status::"Completed with Errors");
    end;

    local procedure ProcessBatch(DataMigrationStatus: Record "Data Migration Status"; BaseAppCodeunitToRun: Integer; var TempDataMigrationParametersBatch: Record "Data Migration Parameters" temporary; "Count": Integer)
    var
        TempDataMigrationParametersSingle: Record "Data Migration Parameters" temporary;
        DataMigrationError: Record "Data Migration Error";
    begin
        // try to process batch
        if CODEUNIT.Run(BaseAppCodeunitToRun, TempDataMigrationParametersBatch) then begin
            // the batch was processed fine, update the dashboard
            DataMigrationStatusFacade.IncrementMigratedRecordCount(DataMigrationStatus."Migration Type",
              DataMigrationStatus."Destination Table ID", Count);
            Commit(); // save the dashboard status before calling the next Codeunit.RUN
        end else begin
            // the batch processing failed
            TempDataMigrationParametersBatch.FindSet();
            repeat
                // process one by one
                TempDataMigrationParametersSingle.DeleteAll();
                TempDataMigrationParametersSingle.Init();
                TempDataMigrationParametersSingle.TransferFields(TempDataMigrationParametersBatch);
                TempDataMigrationParametersSingle.Insert();

                if CODEUNIT.Run(BaseAppCodeunitToRun, TempDataMigrationParametersSingle) then begin
                    // single record processing succeeded, update dashboard
                    DataMigrationStatusFacade.IncrementMigratedRecordCount(DataMigrationStatus."Migration Type",
                      DataMigrationStatus."Destination Table ID", 1);
                    Commit(); // save the dashboard status before calling the next Codeunit.RUN
                end else begin
                    DataMigrationError.CreateEntry(DataMigrationStatus."Migration Type",
                      DataMigrationStatus."Destination Table ID", TempDataMigrationParametersSingle."Staging Table RecId To Process");
                    Commit(); // save the new errors discovered
                end;
            until TempDataMigrationParametersBatch.Next() = 0;
        end;
    end;

    procedure RunStagingTableMigrationCodeunit(CodeunitToRun: Integer; StagingTableEntityVariant: Variant): Boolean
    begin
        exit(CODEUNIT.Run(CodeunitToRun, StagingTableEntityVariant));
    end;

    [EventSubscriber(ObjectType::Page, Page::"Data Migration Overview", 'OnRequestAbort', '', false, false)]
    local procedure OnRequestAbortSubscriber()
    begin
        AbortRequested := true;
    end;

    local procedure CheckAbortRequestedAndMigrateEntity(var DataMigrationStatus: Record "Data Migration Status"; DestinationTableId: Integer; BaseAppCodeunitToRun: Integer; ReRun: Boolean): Boolean
    begin
        if AbortRequested then begin
            DataMigrationStatus.Reset();
            DataMigrationStatus.SetRange("Migration Type", DataMigrationStatus."Migration Type");
            SetAbortStatus(DataMigrationStatus);
            OnAfterMigrationFinished(DataMigrationStatus, true, StartTime, ReRun);
            exit(true);
        end;

        DataMigrationStatus.SetRange("Destination Table ID", DestinationTableId);
        HandleEntityMigration(DataMigrationStatus, BaseAppCodeunitToRun, ReRun);
    end;

    local procedure CheckAbortAndMigrateRemainingEntities(DataMigrationStatus: Record "Data Migration Status"; Retry: Boolean)
    begin
        if AbortRequested then begin
            DataMigrationStatus.Reset();
            DataMigrationStatus.SetRange("Migration Type", DataMigrationStatus."Migration Type");
            SetAbortStatus(DataMigrationStatus);
            OnAfterMigrationFinished(DataMigrationStatus, true, StartTime, Retry);
            exit;
        end;

        DataMigrationStatus.SetFilter("Destination Table ID", StrSubstNo('<>%1&<>%2&<>%3&<>%4',
            DATABASE::Item,
            DATABASE::Customer,
            DATABASE::"G/L Account",
            DATABASE::Vendor));
        DataMigrationStatus.SetRange(Status, DataMigrationStatus.Status::Pending);
        if DataMigrationStatus.FindSet() then
            repeat
                HandleEntityMigration(DataMigrationStatus, DataMigrationStatus."Migration Codeunit To Run", Retry);
            until DataMigrationStatus.Next() = 0;
    end;

    procedure SetStartTime(Value: DateTime)
    begin
        StartTime := Value;
    end;

    procedure SetAbortStatus(var DataMigrationStatus: Record "Data Migration Status")
    begin
        DataMigrationStatus.SetFilter(
          Status, StrSubstNo('%1|%2', DataMigrationStatus.Status::"In Progress", DataMigrationStatus.Status::Pending));
        if DataMigrationStatus.FindSet() then
            repeat
                DataMigrationStatus.Status := DataMigrationStatus.Status::Stopped;
                DataMigrationStatus.Modify(true);
            until DataMigrationStatus.Next() = 0;
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnBeforeMigrationStarted(var DataMigrationStatus: Record "Data Migration Status"; Retry: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCreatePostMigrationData(var DataMigrationStatus: Record "Data Migration Status"; var DataCreationFailed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnValidateMigration(var DataMigrationStatus: Record "Data Migration Status"; var DataCreationFailed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAfterMigrationFinished(var DataMigrationStatus: Record "Data Migration Status"; WasAborted: Boolean; StartTime: DateTime; Retry: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Mgt.", 'OnBeforeMigrationStarted', '', true, true)]
    local procedure OnBeforeMigrationStartedSubscriber(var Sender: Codeunit "Data Migration Mgt."; var DataMigrationStatus: Record "Data Migration Status"; Retry: Boolean)
    var
        Message: Text;
    begin
        Sender.SetStartTime(CurrentDateTime);
        if Retry then
            Message := 'Migration started.'
        else
            Message := 'Migration restarted.';
        Session.LogMessage('00001I7', Message, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', StrSubstNo('Data Migration (%1)', DataMigrationStatus."Migration Type"));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Mgt.", 'OnAfterMigrationFinished', '', true, true)]
    local procedure OnAfterMigrationFinishedSubscriber(var DataMigrationStatus: Record "Data Migration Status"; WasAborted: Boolean; StartTime: DateTime; Retry: Boolean)
    var
        TotalNumberOfRecords: Integer;
        Message: Text;
        MigrationDurationAsInt: BigInteger;
    begin
        DataMigrationStatus.SetRange("Destination Table ID", DATABASE::"G/L Account");
        if DataMigrationStatus.FindFirst() then
            TotalNumberOfRecords += DataMigrationStatus."Total Number";

        DataMigrationStatus.SetRange("Destination Table ID", DATABASE::Item);
        if DataMigrationStatus.FindFirst() then
            TotalNumberOfRecords += DataMigrationStatus."Total Number";

        DataMigrationStatus.SetRange("Destination Table ID", DATABASE::Vendor);
        if DataMigrationStatus.FindFirst() then
            TotalNumberOfRecords += DataMigrationStatus."Total Number";

        DataMigrationStatus.SetRange("Destination Table ID", DATABASE::Customer);
        if DataMigrationStatus.FindFirst() then
            TotalNumberOfRecords += DataMigrationStatus."Total Number";

        MigrationDurationAsInt := CurrentDateTime - StartTime;
        if WasAborted then
            Message := StrSubstNo('Migration aborted after %1', MigrationDurationAsInt)
        else
            Message := StrSubstNo('The migration of %1 records in total took: %2.', TotalNumberOfRecords, MigrationDurationAsInt);

        if Retry then
            Message += '(Migration was restarted)';

        Session.LogMessage('00001DA', Message, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', StrSubstNo('Data Migration (%1)', DataMigrationStatus."Migration Type"));
    end;

    procedure StartMigration(MigrationType: Text[250]; Retry: Boolean)
    var
        DataMigrationError: Record "Data Migration Error";
        DataMigrationStatus: Record "Data Migration Status";
        JobQueueEntry: Record "Job Queue Entry";
        JobParameters: Text[250];
        StartNewSession: Boolean;
        CheckExistingData: Boolean;
    begin
        CheckMigrationInProgress(Retry);

        StartNewSession := false;
        CheckExistingData := true;
        OnBeforeStartMigration(StartNewSession, CheckExistingData);

        if CheckExistingData then
            CheckDataAlreadyExist(MigrationType, Retry);

        DataMigrationStatus.Reset();
        DataMigrationStatus.SetRange("Migration Type", MigrationType);
        if not Retry then begin
            DataMigrationStatus.SetRange(Status, DataMigrationStatus.Status::Pending);
            if DataMigrationStatus.FindSet() then
                repeat
                    DataMigrationError.SetRange("Migration Type", MigrationType);
                    DataMigrationError.SetRange("Destination Table ID", DataMigrationStatus."Destination Table ID");
                    DataMigrationError.DeleteAll();
                until DataMigrationStatus.Next() = 0;
        end else
            DataMigrationStatus.SetRange(Status, DataMigrationStatus.Status::"Completed with Errors");

        Commit(); // commit the dashboard changes so the OnRun call on the migration codeunit will not fail because of this uncommited transaction

        if Retry then
            JobParameters := RetryTxt;
        DataMigrationStatus.FindFirst();
        if StartNewSession then
            // run the migration in a background session
            JobQueueEntry.ScheduleJobQueueEntryWithParameters(CODEUNIT::"Data Migration Mgt.",
            DataMigrationStatus.RecordId, JobParameters)
        else begin
            JobQueueEntry."Record ID to Process" := DataMigrationStatus.RecordId;
            JobQueueEntry."Parameter String" := JobParameters;
            CODEUNIT.Run(CODEUNIT::"Data Migration Mgt.", JobQueueEntry);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartMigration(var StartNewSession: Boolean; var CheckExistingData: Boolean)
    begin
    end;

    procedure CheckMigrationInProgress(Retry: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
        DataMigrationOverview: Page "Data Migration Overview";
        Status: Option;
    begin
        Status := GetMigrationStatus();

        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Data Migration Mgt.");
        JobQueueEntry.SetFilter(Status, '%1|%2|%3',
          JobQueueEntry.Status::"In Process",
          JobQueueEntry.Status::"On Hold",
          JobQueueEntry.Status::Ready);
        if (Status = MigrationStatus::Pending) and not JobQueueEntry.FindFirst() then
            exit;

        if (Status in [MigrationStatus::"Completed with errors",
                       MigrationStatus::"In Progress",
                       MigrationStatus::Pending]) and not Retry
        then begin
            if Confirm(StrSubstNo(DataMigrationNotCompletedQst, DataMigrationOverview.Caption)) then
                DataMigrationOverview.Run();
            Error('');
        end;
    end;

    procedure GetMigrationStatus(): Integer
    var
        DataMigrationStatus: Record "Data Migration Status";
    begin
        if DataMigrationStatus.IsEmpty() then
            exit(MigrationStatus::"Not Started");

        DataMigrationStatus.SetRange(Status, DataMigrationStatus.Status::"In Progress");
        if DataMigrationStatus.FindFirst() then
            exit(MigrationStatus::"In Progress");

        DataMigrationStatus.SetRange(Status, DataMigrationStatus.Status::Stopped);
        if DataMigrationStatus.FindFirst() then
            exit(MigrationStatus::Stopped);

        DataMigrationStatus.SetFilter(Status, '=%1', DataMigrationStatus.Status::Failed);
        if DataMigrationStatus.FindFirst() then
            exit(MigrationStatus::Failed);

        DataMigrationStatus.SetRange(Status, DataMigrationStatus.Status::"Completed with Errors");
        if DataMigrationStatus.FindFirst() then
            exit(MigrationStatus::"Completed with errors");

        DataMigrationStatus.SetFilter(Status, '<>%1', DataMigrationStatus.Status::Completed);
        if not DataMigrationStatus.FindFirst() then
            exit(MigrationStatus::Completed);

        exit(MigrationStatus::Pending);
    end;

    local procedure CheckDataAlreadyExist(MigrationType: Text[250]; Retry: Boolean)
    begin
        if Retry then
            exit;

        // check tables are clear. For GL accounts, we delete them automatically
        ThrowErrorIfTableNotEmpty(MigrationType, DATABASE::Customer, StrSubstNo(CustomerTableNotEmptyErr, PRODUCTNAME.Short()));
        ThrowErrorIfTableNotEmpty(MigrationType, DATABASE::Vendor, StrSubstNo(VendorTableNotEmptyErr, PRODUCTNAME.Short()));
        ThrowErrorIfTableNotEmpty(MigrationType, DATABASE::Item, StrSubstNo(ItemTableNotEmptyErr, PRODUCTNAME.Short()));
    end;

    local procedure ThrowErrorIfTableNotEmpty(MigrationType: Text[250]; TableId: Integer; ErrorMessageErr: Text)
    var
        DataMigrationStatus: Record "Data Migration Status";
        RecRef: RecordRef;
    begin
        if DataMigrationStatus.Get(MigrationType, TableId) then begin
            if DataMigrationStatus.Status <> DataMigrationStatus.Status::Pending then
                exit;
            RecRef.Open(TableId);
            if not RecRef.IsEmpty() then
                Error(ErrorMessageErr);
        end;
    end;

    procedure StartDataMigrationWizardFromNotification(Notification: Notification)
    begin
        PAGE.Run(PAGE::"Data Migration Wizard");
    end;

    procedure ShowDataMigrationRelatedGlobalNotifications()
    var
        DataMigrationStatus: Record "Data Migration Status";
        DataMigrationOverview: Page "Data Migration Overview";
        Notification: Notification;
    begin
        if not IsGlobalNotificationEnabled() then
            exit;

        if DataMigrationStatus.IsEmpty() then
            exit;

        Notification.Id(GetGlobalNotificationId());
        case GetMigrationStatus() of
            MigrationStatus::Pending,
            MigrationStatus::"In Progress":
                begin
                    Notification.Message(StrSubstNo(DataMigrationInProgressMsg, PRODUCTNAME.Short()));
                    Notification.AddAction(MoreInfoTxt, CODEUNIT::"Data Migration Mgt.", 'ShowMoreInfoPage');
                end;
            MigrationStatus::"Completed with errors",
            MigrationStatus::Failed:
                begin
                    Notification.Message(StrSubstNo(DataMigrationCompletedWithErrosMsg, DataMigrationOverview.Caption));
                    Notification.AddAction(GoThereNowTxt, CODEUNIT::"Data Migration Mgt.", 'ShowDataMigrationOverviewFromNotification');
                end;
            MigrationStatus::Completed:
                if CheckForEntitiesToBePosted() then begin
                    Notification.Message(DataMigrationEntriesToPostMsg);
                    Notification.AddAction(GoThereNowTxt, CODEUNIT::"Data Migration Mgt.", 'ShowDataMigrationOverviewFromNotification');
                end else begin
                    Notification.Message(DataMigrationFinishedMsg);
                    Notification.AddAction(DontShowTxt, CODEUNIT::"Data Migration Mgt.", 'DisableDataMigrationRelatedGlobalNotifications');
                end;
            else
                exit;
        end;

        Notification.Send();
    end;

    [Scope('OnPrem')]
    procedure GetGlobalNotificationId(): Guid
    begin
        exit('47707336-D917-4238-942F-39715F52BE4E');
    end;

    [Scope('OnPrem')]
    procedure GetCustomerContactNotificationId(): Guid
    begin
        exit('351199D7-6C9B-40F1-8E78-ff9E67C546C9');
    end;

    [Scope('OnPrem')]
    procedure GetVendorContactNotificationId(): Guid
    begin
        exit('08DB77DB-1F41-4379-8615-1B581A0225FA');
    end;

    internal procedure GetItemListEmptyNotificationId(): Guid
    begin
        exit('91ec9d2f-5328-4543-a4bb-565910ad168f');
    end;

    internal procedure GetCustomerListEmptyNotificationId(): Guid
    begin
        exit('ce4f84ea-a382-433a-a908-e2b22799321a');
    end;

    internal procedure GetVendorListEmptyNotificationId(): Guid
    begin
        exit('920c72f6-4771-4984-a223-5f941951cd40');
    end;

    local procedure IsGlobalNotificationEnabled(): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabled(GetGlobalNotificationId()));
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetGlobalNotificationId(), DataMigrationNotificationNameTxt, DataMigrationNotificationDescTxt, true);
        InsertDefaultCustomerContactNotification(true);
        InsertDefaultVendorContactNotification(true);
        InsertDefaultCustomerListEmptyNotification(true);
        InsertDefaultVendorListEmptyNotification(true);
        InsertDefaultItemListEmptyNotification(true);
    end;

    procedure ShowDataMigrationOverviewFromNotification(Notification: Notification)
    begin
        PAGE.Run(PAGE::"Data Migration Overview");
    end;

    procedure IsMigrationInProgress(): Boolean
    begin
        exit(GetMigrationStatus() in [MigrationStatus::"In Progress", MigrationStatus::Pending]);
    end;

    procedure ShowMoreInfoPage(Notification: Notification)
    begin
        if PAGE.RunModal(PAGE::"Data Migration About") = ACTION::LookupOK then
            ShowDataMigrationOverviewFromNotification(Notification);
    end;

    procedure CheckForEntitiesToBePosted(): Boolean
    var
        DataMigrationStatus: Record "Data Migration Status";
        DummyCode: Code[10];
    begin
        DataMigrationStatus.SetFilter(
          Status, '%1|%2', DataMigrationStatus.Status::Completed, DataMigrationStatus.Status::"Completed with Errors");

        if not DataMigrationStatus.FindSet() then
            exit(false);
        repeat
            if DestTableHasAnyTransactions(DataMigrationStatus, DummyCode) then
                exit(true);
        until DataMigrationStatus.Next() = 0;
    end;

    procedure DestTableHasAnyTransactions(var DataMigrationStatus: Record "Data Migration Status"; var JournalBatchName: Code[10]): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        case DataMigrationStatus."Destination Table ID" of
            DATABASE::Vendor:
                begin
                    DataMigrationFacade.OnFindBatchForVendorTransactions(DataMigrationStatus."Migration Type", JournalBatchName);
                    if JournalBatchName = '' then
                        exit(false);
                    GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
                    GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
                    GenJournalLine.SetFilter("Account No.", '<>%1', '');
                    exit(GenJournalLine.FindFirst());
                end;
            DATABASE::Customer:
                begin
                    DataMigrationFacade.OnFindBatchForCustomerTransactions(DataMigrationStatus."Migration Type", JournalBatchName);
                    if JournalBatchName = '' then
                        exit(false);
                    GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
                    GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Customer);
                    GenJournalLine.SetFilter("Account No.", '<>%1', '');
                    exit(GenJournalLine.FindFirst());
                end;
            DATABASE::Item:
                begin
                    DataMigrationFacade.OnFindBatchForItemTransactions(DataMigrationStatus."Migration Type", JournalBatchName);
                    if JournalBatchName = '' then
                        exit(false);
                    ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
                    ItemJournalLine.SetFilter("Item No.", '<>%1', '');
                    exit(not ItemJournalLine.IsEmpty());
                end;
            else begin
                DataMigrationFacade.OnFindBatchForAccountTransactions(DataMigrationStatus, JournalBatchName);
                if JournalBatchName = '' then
                    exit(false);
                GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
                GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
                GenJournalLine.SetFilter("Account No.", '<>%1', '');
                exit(not GenJournalLine.IsEmpty());
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowHelpTopicPage(Notification: Notification)
    begin
        HyperLink(DataMigrationHelpTopicURLTxt);
    end;

    procedure GetDataMigrationHelpTopicURL(): Text
    begin
        exit(DataMigrationHelpTopicURLTxt)
    end;

    [Scope('OnPrem')]
    procedure DisableDataMigrationRelatedGlobalNotifications(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetGlobalNotificationId()) then
            MyNotifications.InsertDefault(GetGlobalNotificationId(), DataMigrationNotificationNameTxt, DataMigrationNotificationDescTxt, false);
    end;

    local procedure EnableDataMigrationNotificationForAllUsers()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.SetRange("Notification Id", GetGlobalNotificationId());
        if MyNotifications.FindSet() then
            repeat
                MyNotifications.Enabled := true;
                MyNotifications.Modify(true);
            until MyNotifications.Next() = 0;
    end;

    procedure InsertDefaultCustomerContactNotification(Enabled: Boolean)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(
          GetCustomerContactNotificationId(), CustomerContactNotificationNameTxt, CustContactNotificationDescTxt, Enabled);
    end;

    procedure InsertDefaultVendorContactNotification(Enabled: Boolean)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(
          GetVendorContactNotificationId(), VendorContactNotificationNameTxt, VendContactNotificationDescTxt, Enabled);
    end;

    procedure InsertDefaultCustomerListEmptyNotification(Enabled: Boolean)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(
          GetCustomerListEmptyNotificationId(), CustomersEmptyListNotificationNameTxt, '', Enabled);
    end;

    procedure InsertDefaultVendorListEmptyNotification(Enabled: Boolean)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(
          GetVendorListEmptyNotificationId(), VendorsEmptyListNotificationNameTxt, '', Enabled);
    end;

    procedure InsertDefaultItemListEmptyNotification(Enabled: Boolean)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(
          GetItemListEmptyNotificationId(), ItemsEmptyListNotificationNameTxt, '', Enabled);
    end;

    procedure UpdateMigrationStatus(var DataMigrationStatus: Record "Data Migration Status")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not (DataMigrationStatus.Status in [DataMigrationStatus.Status::Pending, DataMigrationStatus.Status::"In Progress"]) then
            exit;
        JobQueueEntry.SetFilter(Status, '%1|%2', JobQueueEntry.Status::Ready, JobQueueEntry.Status::"In Process");
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Data Migration Mgt.");
        if JobQueueEntry.FindFirst() then
            exit;

        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Error);
        if JobQueueEntry.FindFirst() then begin
            DataMigrationStatus.Validate(Status, DataMigrationStatus.Status::Failed);
            DataMigrationStatus.Modify(true);
        end;
    end;

    procedure CheckIfMigrationIsCompleted(CurrentDataMigrationStatus: Record "Data Migration Status")
    var
        DataMigrationStatus: Record "Data Migration Status";
        DataMigrationFacade: Codeunit "Data Migration Facade";
    begin
        DataMigrationStatus.SetRange("Migration Type", CurrentDataMigrationStatus."Migration Type");
        DataMigrationStatus.SetFilter("Destination Table ID", '<>%1', CurrentDataMigrationStatus."Destination Table ID");
        DataMigrationStatus.SetFilter(
          Status,
          '%1|%2|%3',
          DataMigrationStatus.Status::"In Progress",
          DataMigrationStatus.Status::Pending,
          DataMigrationStatus.Status::"Completed with Errors");
        if DataMigrationStatus.IsEmpty() then
            DataMigrationFacade.OnMigrationCompleted(CurrentDataMigrationStatus);
    end;
}

