// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;
using System;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.IO;
using System.Reflection;
using System.Text;
using System.Threading;
using Microsoft.API;

codeunit 5465 "Graph Mgt - General Tools"
{
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = TableData "Sales Invoice Header" = rimd,
                  TableData "Sales Cr.Memo Header" = rimd,
                  TableData "Purch. Inv. Header" = rimd;

    trigger OnRun()
    begin
        ApiSetup();
    end;

    var
        CannotChangeIDErr: Label 'Value of Id is immutable.';
        CannotChangeLastDateTimeModifiedErr: Label 'Value of LastDateTimeModified is immutable.';
        MissingFieldValueErr: Label '%1 must be specified.', Comment = '%1 = Property name';
        AggregateErrorTxt: Label 'AL APIAggregate', Locked = true;
        AggregateIsMissingMainRecordTxt: Label 'Aggregate does not have main record.';
        JobQueueIsRunningErr: Label 'The job queue entry is already running. Stop the existing job queue entry, and then schedule a new entry.';
        JobQueueEntryUpdateRecordsDescTxt: Label 'Job to update API records';
        JobQEntriesCreatedQst: Label 'A job queue entry for updating the records has been created.\\ The process may take several hours to complete. We recommend that you schedule the job for a time slot outside your organization''s working hours. \\Do you want to open the Job Queue Entries and configure the Job Queue?';
        StartJobQueueNowQst: Label 'Would you like to run the job to update the records now?';
        JobQueueHasBeenStartedMsg: Label 'The job queue entry will start executing shortly.';
        JobQueueNotScheudledMsg: Label 'The job has been created and set to On Hold.';
        APIDataUpgradeCategoryLbl: Label 'APIUpgrade', Locked = true;

    [Scope('OnPrem')]
    procedure GetMandatoryStringPropertyFromJObject(var JsonObject: DotNet JObject; PropertyName: Text; var PropertyValue: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        Found: Boolean;
    begin
        Found := JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, PropertyName, PropertyValue);
        if not Found then
            Error(MissingFieldValueErr, PropertyName);
    end;

    procedure HandleUpdateReferencedIdFieldOnItem(var RecRef: RecordRef; NewId: Guid; var Handled: Boolean; DatabaseNumber: Integer; RecordFieldNumber: Integer)
    var
        IdFieldRef: FieldRef;
    begin
        if Handled then
            exit;

        if RecRef.Number <> DatabaseNumber then
            exit;

        IdFieldRef := RecRef.Field(RecordFieldNumber);
        IdFieldRef.Value(NewId);

        Handled := true;
    end;

    [Scope('OnPrem')]
    procedure InsertOrUpdateODataType(NewKey: Code[50]; NewDescription: Text[250]; OdmDefinition: Text)
    var
        ODataEdmType: Record "OData Edm Type";
        ODataOutStream: OutStream;
        ODataInStream: InStream;
        ExistingEDMDefinition: Text;
        RecordExist: Boolean;
    begin
        if not ODataEdmType.WritePermission then
            exit;

        ODataEdmType.SetAutoCalcFields("Edm Xml");
        RecordExist := ODataEdmType.Get(NewKey);

        if not RecordExist then begin
            Clear(ODataEdmType);
            ODataEdmType.Key := NewKey;
        end;

        if RecordExist then
            if ODataEdmType."Edm Xml".HasValue() then begin
                ODataEdmType."Edm Xml".CreateInStream(ODataInStream, TEXTENCODING::UTF8);
                ODataInStream.ReadText(ExistingEDMDefinition);

                if (ODataEdmType.Description = NewDescription) and (ExistingEDMDefinition = OdmDefinition) then
                    exit;
            end;

        ODataEdmType.Validate(Description, NewDescription);
        ODataEdmType."Edm Xml".CreateOutStream(ODataOutStream, TEXTENCODING::UTF8);
        ODataOutStream.WriteText(OdmDefinition);

        if RecordExist then
            ODataEdmType.Modify(true)
        else
            ODataEdmType.Insert(true);
    end;

    [Scope('Cloud')]
    procedure ProcessNewRecordFromAPI(var InsertedRecordRef: RecordRef; var TempFieldSet: Record "Field"; ModifiedDateTime: DateTime)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        UpdatedRecRef: RecordRef;
    begin
        if not ConfigTmplSelectionRules.FindTemplateBasedOnRecordFields(InsertedRecordRef, ConfigTemplateHeader) then
            exit;

        if ConfigTemplateManagement.ApplyTemplate(InsertedRecordRef, TempFieldSet, UpdatedRecRef, ConfigTemplateHeader) then
            InsertedRecordRef := UpdatedRecRef.Duplicate();
    end;

    [Scope('Cloud')]
    procedure ProcessNewRecordFromAPI(var InsertedRecordRef: RecordRef; var TempFieldSet: Record "Field"; ModifiedDateTime: DateTime; var ConfigTemplateHeader: Record "Config. Template Header")
    var
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        UpdatedRecRef: RecordRef;
    begin
        if not ConfigTmplSelectionRules.FindTemplateBasedOnRecordFields(InsertedRecordRef, ConfigTemplateHeader) then
            exit;

        if ConfigTemplateManagement.ApplyTemplate(InsertedRecordRef, TempFieldSet, UpdatedRecRef, ConfigTemplateHeader) then
            InsertedRecordRef := UpdatedRecRef.Duplicate();
    end;

    procedure ErrorIdImmutable()
    begin
        Error(CannotChangeIDErr);
    end;

    procedure ErrorLastDateTimeModifiedImmutable()
    begin
        Error(CannotChangeLastDateTimeModifiedErr);
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure ApiSetup()
    begin
    end;

    procedure IsApiEnabled(): Boolean
    var
        ServerSetting: Codeunit "Server Setting";
        Handled: Boolean;
        IsAPIEnabled: Boolean;
    begin
        OnGetIsAPIEnabled(Handled, IsAPIEnabled);
        if Handled then
            exit(IsAPIEnabled);

        exit(ServerSetting.GetApiServicesEnabled());
    end;

    procedure IsApiSubscriptionEnabled(): Boolean
    var
        ServerSetting: Codeunit "Server Setting";
        Handled: Boolean;
        APISubscriptionsEnabled: Boolean;
    begin
        if not IsApiEnabled() then
            exit(false);

        OnGetAPISubscriptionsEnabled(Handled, APISubscriptionsEnabled);
        if Handled then
            exit(APISubscriptionsEnabled);

        exit(ServerSetting.GetApiSubscriptionsEnabled());
    end;

    procedure APISetupIfEnabled()
    begin
        if IsApiEnabled() then
            ApiSetup();
    end;

    procedure TranslateNAVCurrencyCodeToCurrencyCode(var CachedLCYCurrencyCode: Code[10]; CurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode <> '' then
            exit(CurrencyCode);

        if CachedLCYCurrencyCode = '' then begin
            GeneralLedgerSetup.Get();
            CachedLCYCurrencyCode := GeneralLedgerSetup."LCY Code";
        end;

        exit(CachedLCYCurrencyCode);
    end;

    procedure TranslateCurrencyCodeToNAVCurrencyCode(var CachedLCYCurrencyCode: Code[10]; CurrentCurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if CurrentCurrencyCode = '' then
            exit('');

        // Update LCY cache
        if CachedLCYCurrencyCode = '' then begin
            GeneralLedgerSetup.Get();
            CachedLCYCurrencyCode := GeneralLedgerSetup."LCY Code";
        end;

        if CachedLCYCurrencyCode = CurrentCurrencyCode then
            exit('');

        exit(CurrentCurrencyCode);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', true, true)]
    local procedure InitDemoCompanyApisForSaaS()
    var
        CompanyInformation: Record "Company Information";
        APIEntitiesSetup: Record "API Entities Setup";
        EnvironmentInfo: Codeunit "Environment Information";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;

        if not CompanyInformation.Get() then
            exit;

        if not CompanyInformation."Demo Company" then
            exit;

        APIEntitiesSetup.SafeGet();

        if APIEntitiesSetup."Demo Company API Initialized" then
            exit;

        GraphMgtGeneralTools.ApiSetup();

        APIEntitiesSetup.SafeGet();
        APIEntitiesSetup.Validate("Demo Company API Initialized", true);
        APIEntitiesSetup.Modify(true);
    end;

    procedure TransferRelatedRecordIntegrationIDs(var OriginalRecordRef: RecordRef; var UpdatedRecordRef: RecordRef; var TempRelatedRecodIdsField: Record "Field")
    var
        OriginalFieldRef: FieldRef;
        UpdatedFieldRef: FieldRef;
    begin
        // We cannot use GETTABLE to set values back e.g. RecRef.GETTABLE(Customer) since it will interupt Insert/Modify transaction.
        // The Insert and Modify triggers will not run. We can assign the fields via FieldRef.
        if not TempRelatedRecodIdsField.FindFirst() then
            exit;

        repeat
            OriginalFieldRef := OriginalRecordRef.Field(TempRelatedRecodIdsField."No.");
            UpdatedFieldRef := UpdatedRecordRef.Field(TempRelatedRecodIdsField."No.");
            OriginalFieldRef.Value := UpdatedFieldRef.Value();
        until TempRelatedRecodIdsField.Next() = 0;
    end;

    procedure CleanAggregateWithoutParent(MainRecordVariant: Variant)
    var
        MainRecordRef: RecordRef;
    begin
        MainRecordRef.GetTable(MainRecordVariant);
        MainRecordRef.Delete();
        Session.LogMessage('00001QW', AggregateIsMissingMainRecordTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AggregateErrorTxt);
    end;

    procedure ScheduleUpdateAPIRecordsJob(CodeunitID: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        FindOrCreateJobQueue(JobQueueEntry, CodeunitID);
        if Confirm(JobQEntriesCreatedQst) then begin
            Page.Run(Page::"Job Queue Entry Card", JobQueueEntry);
            exit;
        end;

        if Confirm(StartJobQueueNowQst) then begin
            Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
            Message(JobQueueHasBeenStartedMsg);
            exit;
        end;

        Message(JobQueueNotScheudledMsg);
    end;

    local procedure FindOrCreateJobQueue(var JobQueueEntry: Record "Job Queue Entry"; CodeunitID: Integer)
    var
        JobQueueExist: Boolean;
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CodeunitID);
        JobQueueExist := JobQueueEntry.FindFirst();
        if JobQueueExist then
            if JobQueueEntry.Status = JobQueueEntry.Status::"In Process" then
                Error(JobQueueIsRunningErr);

        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CodeunitID;
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Recurring Job" := false;
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Description := CopyStr(JobQueueEntryUpdateRecordsDescTxt, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Job Queue Category Code" := APIDataUpgradeCategoryLbl;
        if not JobQueueExist then
            JobQueueEntry.Insert(true)
        else
            JobQueueEntry.Modify(true);
    end;

    procedure StripBrackets(StringWithBrackets: Text): Text
    begin
        if StringWithBrackets[1] = '{' then
            exit(CopyStr(Format(StringWithBrackets), 2, 36));
        exit(StringWithBrackets);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetIsAPIEnabled(var Handled: Boolean; var IsAPIEnabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAPISubscriptionsEnabled(var Handled: Boolean; var APISubscriptionsEnabled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Config. Template Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnDeleteConfigTemplates(var Rec: Record "Config. Template Header"; RunTrigger: Boolean)
    var
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
    begin
        if Rec.IsTemporary() then
            exit;
        if RunTrigger then begin
            ConfigTmplSelectionRules.SetRange("Template Code", Rec.Code);
            ConfigTmplSelectionRules.DeleteAll();
        end;
    end;

    procedure GetIdWithoutBrackets(Id: Guid): Text
    begin
        exit(Format(Id).TrimStart('{').TrimEnd('}'));
    end;
}

