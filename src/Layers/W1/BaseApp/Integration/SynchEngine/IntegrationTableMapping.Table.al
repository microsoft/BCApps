// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using Microsoft.CRM.Opportunity;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Sales.Document;
using System.IO;
using System.Reflection;
using System.Telemetry;
using System.Threading;

table 5335 "Integration Table Mapping"
{
    Caption = 'Integration Table Mapping';
    DrillDownPageID = "Integration Table Mapping List";
    LookupPageID = "Integration Table Mapping List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[20])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = "Table Metadata".ID;
        }
        field(3; "Integration Table ID"; Integer)
        {
            Caption = 'Integration Table ID';
            TableRelation = "Table Metadata".ID;
        }
        field(4; "Synch. Codeunit ID"; Integer)
        {
            Caption = 'Synch. Codeunit ID';
            TableRelation = "Table Metadata".ID;
        }
        field(5; "Integration Table UID Fld. No."; Integer)
        {
            Caption = 'Integration Table UID Fld. No.';
            Description = 'Integration Table Unique Identifier Field No.';

            trigger OnValidate()
            var
                "Field": Record "Field";
                TypeHelper: Codeunit "Type Helper";
            begin
                Field.Get("Integration Table ID", "Integration Table UID Fld. No.");
                TypeHelper.TestFieldIsNotObsolete(Field);
                "Int. Table UID Field Type" := Field.Type;
            end;
        }
        field(6; "Int. Tbl. Modified On Fld. No."; Integer)
        {
            Caption = 'Int. Tbl. Modified On Fld. No.';
            Description = 'Integration Table Modified On Field No.';
        }
        field(7; "Int. Table UID Field Type"; Integer)
        {
            Caption = 'Int. Table UID Field Type';
            Editable = false;
        }
        field(8; "Table Config Template Code"; Code[10])
        {
            Caption = 'Table Config Template Code';
            TableRelation = "Config. Template Header".Code where("Table ID" = field("Table ID"));
            /// Replaced with Integration Table Config Template table for Dataverse type mappings
            /// used only for Master Data Management mappings
        }
        field(9; "Int. Tbl. Config Template Code"; Code[10])
        {
            Caption = 'Int. Tbl. Config Template Code';
            TableRelation = "Config. Template Header".Code where("Table ID" = field("Integration Table ID"));
            /// Replaced with Integration Table Config Template table for Dataverse type mappings
            /// used only for Master Data Management mappings
        }
        field(10; Direction; Option)
        {
            Caption = 'Direction';
            OptionCaption = 'Bidirectional,ToIntegrationTable,FromIntegrationTable';
            OptionMembers = Bidirectional,ToIntegrationTable,FromIntegrationTable;

            trigger OnValidate()
            var
                "Field": Record "Field";
                IntegrationFieldMapping: Record "Integration Field Mapping";
                CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
                JobQueueEntry: Record "Job Queue Entry";
                NoEnabledFieldMappingsExist: Boolean;
            begin
                if "Int. Table UID Field Type" = Field.Type::Option then
                    if Direction = Direction::Bidirectional then
                        Error(OptionMappingCannotBeBidirectionalErr)
                    else begin
                        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", Name);
                        IntegrationFieldMapping.ModifyAll(Direction, Direction);

                        if CRMFullSynchReviewLine.Get(Name) then
                            if CRMFullSynchReviewLine.Direction <> Direction then begin
                                CRMFullSynchReviewLine.Direction := Direction;
                                CRMFullSynchReviewLine.Modify();
                            end;

                        if Direction = Direction::ToIntegrationTable then begin
                            JobQueueEntry.SetRange("Record ID to Process", RecordId);
                            JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
                            JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
                            if JobQueueEntry.FindFirst() then
                                if JobQueueEntry.Status = JobQueueEntry.Status::Ready then begin
                                    JobQueueEntry.Status := JobQueueEntry.Status::"On Hold with Inactivity Timeout";
                                    JobQueueEntry.Modify();
                                end;
                        end;
                    end
                else begin
                    IntegrationFieldMapping.SetRange("Integration Table Mapping Name", Rec.Name);
                    IntegrationFieldMapping.SetRange(Status, IntegrationFieldMapping.Status::Enabled);
                    NoEnabledFieldMappingsExist := IntegrationFieldMapping.IsEmpty();
                    IntegrationFieldMapping.SetRange(Direction, Rec.Direction);
                    if not NoEnabledFieldMappingsExist then
                        if IntegrationFieldMapping.IsEmpty() then
                            if GuiAllowed() then
                                Error(DirectionFieldsErr, Format(Rec.Direction))
                            else
                                Error(DirectionFieldsNoUIHintErr, Format(Rec.Direction))
                end;

                if Rec.Direction <> Rec.Direction::FromIntegrationTable then
                    if Rec."Multi Company Synch. Enabled" then
                        Message(ChangeDirectionMultiCompanyMsg);

            end;
        }
        field(11; "Int. Tbl. Caption Prefix"; Text[30])
        {
            Caption = 'Int. Tbl. Caption Prefix';
        }
        field(12; "Synch. Int. Tbl. Mod. On Fltr."; DateTime)
        {
            Caption = 'Synch. Int. Tbl. Mod. On Fltr.';
            Description = 'Scheduled synch. Integration Table Modified On Filter';
        }
        field(13; "Synch. Modified On Filter"; DateTime)
        {
            Caption = 'Synch. Modified On Filter';
            Description = 'Scheduled synch. Modified On Filter';
        }
        field(14; "Table Filter"; BLOB)
        {
            Caption = 'Table Filter';
        }
        field(15; "Integration Table Filter"; BLOB)
        {
            Caption = 'Integration Table Filter';
        }
        field(16; "Synch. Only Coupled Records"; Boolean)
        {
            Caption = 'Synch. Only Coupled Records';
            InitValue = true;

            trigger OnValidate()
            begin
                CheckDeletionConflictResolutionStrategy();
            end;
        }
        field(17; "Parent Name"; Code[20])
        {
            Caption = 'Parent Name';
        }
        field(18; "Graph Delta Token"; Text[250])
        {
            Caption = 'Graph Delta Token';
        }
        field(19; "Int. Tbl. Delta Token Fld. No."; Integer)
        {
            Caption = 'Int. Tbl. Delta Token Fld. No.';
        }
        field(20; "Int. Tbl. ChangeKey Fld. No."; Integer)
        {
            Caption = 'Int. Tbl. ChangeKey Fld. No.';
        }
        field(21; "Int. Tbl. State Fld. No."; Integer)
        {
            Caption = 'Int. Tbl. State Fld. No.';
        }
        field(22; "Delete After Synchronization"; Boolean)
        {
            Caption = 'Delete After Synchronization';
        }
        field(23; "BC Rec Page Id"; Integer)
        {
            Caption = 'The Id of the BC Record Page';
        }
        field(24; "CDS Rec Page Id"; Integer)
        {
            Caption = 'The Id of the Dataverse Record Page';
        }
        field(25; "Deletion-Conflict Resolution"; Enum "Integration Deletion Conflict Resolution")
        {
            Caption = 'Resolve Deletion Conflicts';

            trigger OnValidate()
            begin
                CheckDeletionConflictResolutionStrategy();
            end;
        }
        field(26; "Update-Conflict Resolution"; Enum "Integration Update Conflict Resolution")
        {
            Caption = 'Resolve Update Conflicts';
        }
        field(27; "Uncouple Codeunit ID"; Integer)
        {
            Caption = 'Uncouple Codeunit ID';
            TableRelation = "CodeUnit Metadata".ID;
        }
        field(28; "Coupling Codeunit ID"; Integer)
        {
            Caption = 'Coupling Codeunit ID';
            TableRelation = "CodeUnit Metadata".ID;
        }
        field(29; "Synch. After Bulk Coupling"; Boolean)
        {
            Caption = 'Synch. After Match-Based Coupling';
        }
        field(30; "Dependency Filter"; Text[250])
        {
            Caption = 'Dependency Filter';
        }
        field(31; "Create New in Case of No Match"; Boolean)
        {
            Caption = 'Create New in Case of No Match';
        }
        field(32; Type; Enum "Integration Table Mapping Type")
        {
            Caption = 'Type';
        }
        field(33; "Disable Event Job Resch."; Boolean)
        {
            Caption = 'Disable Event-driven Synch. Job Rescheduling';

            trigger OnValidate()
            begin
                if not GuiAllowed() then
                    exit;

                if Rec."Disable Event Job Resch." then
                    if not Confirm(DisableEventDrivenReshedulingQst) then
                        Error('');

                if not Confirm(EnableEventDrivenReshedulingQst) then
                    Error('');
            end;
        }
        field(34; "Multi Company Synch. Enabled"; Boolean)
        {
            Caption = 'Multi-Company Synchronization Enabled';

            trigger OnValidate()
            var
                FeatureTelemetry: Codeunit "Feature Telemetry";
            begin
                FeatureTelemetry.LogUptake('0000LCM', 'Dataverse Multi-Company Synch', Enum::"Feature Uptake Status"::Discovered);
                FeatureTelemetry.LogUptake('0000LCN', 'Dataverse Multi-Company Synch', Enum::"Feature Uptake Status"::"Set up");
                if Rec."Multi Company Synch. Enabled" then
                    Rec.EnableMultiCompanySynchronization()
                else
                    Rec.DisableMultiCompanySynchronization();
            end;
        }
        field(35; "Table Caption"; Text[250])
        {
            Caption = 'Table Caption';
        }
        field(98; "No. of Errors"; Integer)
        {
            Caption = 'Number of Errors';
            FieldClass = FlowField;
            CalcFormula = sum("Integration Synch. Job".Failed where("Integration Table Mapping Name" = field(Name)));
        }
        field(99; "No. of Skipped"; Integer)
        {
            Caption = 'Number of Skipped Records';
            FieldClass = FlowField;
            CalcFormula = count("CRM Integration Record" where("Table ID" = field("Table ID"), Skipped = const(true)));
        }
        field(100; "Full Sync is Running"; Boolean)
        {
            Caption = 'Full Sync is Running';
            Description = 'This is set to TRUE when FullSync starts, and to FALSE when FullSync completes.';

            trigger OnValidate()
            begin
                if xRec.Get(Name) then;
                if (not xRec."Full Sync is Running") and "Full Sync is Running" then begin
                    "Last Full Sync Start DateTime" := CurrentDateTime;
                    "Full Sync Session ID" := SessionId();
                end;
                if not "Full Sync is Running" then
                    "Full Sync Session ID" := 0;
            end;
        }
        field(101; "Full Sync Session ID"; Integer)
        {
            Caption = 'Full Sync Session ID';
            Description = 'The ID of the session running the FullSync must be 0 if FullSync is not running.';
        }
        field(102; "Last Full Sync Start DateTime"; DateTime)
        {
            Caption = 'Last Full Sync Start DateTime';
            Description = 'The starting date and time of the last time FullSync was run. This is used to re-run in case FullSync failed to reset these fields.';
        }
        field(103; "User Defined"; Boolean)
        {
            Caption = 'User Defined';
            Description = 'Indicates whether the table mapping was defined manually by the user or by the system.';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
        key(Key2; "Table ID", "Integration Table ID")
        {
        }
        key(Key3; "Table ID", "Integration Table ID", Type)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        ManIntegrationTableMapping: Record "Man. Integration Table Mapping";
        TableConfigTemplate: Record "Table Config Template";
        IntTableConfigTemplate: Record "Int. Table Config Template";
    begin
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", Name);
        IntegrationFieldMapping.DeleteAll();

        ManIntegrationTableMapping.SetRange(Name, Name);
        if ManIntegrationTableMapping.IsEmpty() then begin
            TableConfigTemplate.SetRange("Integration Table Mapping Name", Name);
            TableConfigTemplate.DeleteAll();

            IntTableConfigTemplate.SetRange("Integration Table Mapping Name", Name);
            IntTableConfigTemplate.DeleteAll();
        end;
    end;

    var
        JobLogEntryNo: Integer;
        DateType: Option ,Integration,Local;
        ConfirmIncludeEntitiesWithNoCompanyQst: Label 'Do you want the Integration Table Filter to include %1 entities with no value in %2 attribute?', Comment = '%1 - Dataverse service name; %2 - attribute name of a Dataverse entity';
        OptionMappingCannotBeBidirectionalErr: Label 'Option mappings can only synchronize from integration table or to integration table.';
        UserChoseNotToIncludeEntitiesWithEmptyCompanyNameTxt: Label 'User chose not to include %1 entities with empty company id in the Integration Table Filter of the %2 mapping.', Locked = true;
        RemoveCouplingStrategyQst: Label 'Synch. Only Coupled Records is unchecked. Therefore, if conflict resolution strategy removes a broken coupling, a subsequent scheduled synchronization job may recreate the coupling. Do you want to continue?';
        TelemetryCategoryTok: Label 'AL Dataverse Integration', Locked = true;
        CompanyIdFieldNameTxt: Label 'CompanyId', Locked = true;
        DisableEventDrivenReshedulingQst: Label 'This will disable the event-based rescheduling of synchronization jobs for this table. \\The frequency of the synchronization job runs is specified in the Inactivity Timeout Period field on the corresponding job queue entry. \\Do you want to continue?';
        EnableEventDrivenReshedulingQst: Label 'This will enable the event-based rescheduling of synchronization jobs for this table. \\The synchronization job will be rescheduled within 30-60 seconds after an insertion, change or deletion on the corresponding table. \\In case of no changes during a long period, the synchronization job will be rescheduled as specified in the Inactivity Timeout Period field on the corresponding job queue entry. \\Do you want to continue?';
        CompanyFilterRemovedQst: Label 'This will remove the company field filter from Integration Table Filter and make the synchronization engine process %1 entities regardless of their Company field value. Do you want to continue?', Comment = '%1 - a table caption';
        CompanyFilterRemovedExtendedMsg: Label '%1 entities will be synchronized regardless of their Company field value. To control which entities get synchronized to this company, set the Integration Table Filter on other fields. We strongly recommend to set the direction of this mapping to ''From Integration''. \\If you set it up to synchronize bidirectionally or to synchronize ''To Integration'', to avoid duplicates being created, use match-based coupling or consolidated filtering across companies instead of just unchecking the Synch. Only Coupled Records checkbox. \\If your number series do not guarantee uniqueness of primary key values across multiple companies, then use a transformation rule in the direction ''To Integration'' to add a prefix to primary key values, to ensure their uniqueness in Dataverse.', Comment = '%1 - a table caption';
        CompanyFilterRemovedShortMsg: Label '%1 entities will be synchronized regardless of their Company field value. To control which entities get synchronized to this company, set the Integration Table Filter on other fields.', Comment = '%1 - a table caption';
        CompanyFilterResetMsg: Label 'The company field filter on the Integration Table Filter is reset to default.';
        CompanyFilterStrengthenedQst: Label 'This will make the synchronization engine process only %1 entities that correspond to the current company. Do you want to continue?', Comment = '%1 - a table caption';
        CompanyFilterResetToDefaultQst: Label 'This will reset the company field filter from Integration Table Filter to the default. Do you want to continue?';
        CompanyFilterStrengthenedMsg: Label 'The synchronization will consider only %1 entities that correspond to this company. \\To make Business Central process %1 entities that are originally created in %3, the %3 users must set their Company value to match the company %2.', Comment = '%1 - a table caption; %2 - current company name; %3 - Dynamics 365 service name';
        InstallLatestSolutionConfirmLbl: Label 'This functionality requires the latest integration solution to be imported on your Dataverse environment. You will be prompted to sign in with your Dataverse administrator account credentials. Do you want to continue?';
        OrTok: Label '%1|%2', Locked = true;
        ChangeDirectionMultiCompanyMsg: Label 'This mapping is set up for multi-company synchronization. We strongly recommend to set the direction of this mapping to ''From Integration''. \\If you set it up to synchronize bidirectionally or to synchronize ''To Integration'', to avoid duplicates being created, use match-based coupling or consolidated filtering across companies instead of just unchecking the Synch. Only Coupled Records checkbox. \\If your number series do not guarantee uniqueness of primary key values across multiple companies, then use a Transformation Rule in the direction ''To Integration'' to add a prefix to primary key values, to ensure their uniqueness in Dataverse.';
        DirectionFieldsErr: Label 'You must set the direction of at least one enabled integration field mapping to ''%1''. Choose the Fields action to edit the integration field mappings.', Comment = '%1 - an option value';
        DirectionFieldsNoUIHintErr: Label 'You must set the direction of at least one enabled integration field mapping to ''%1''.', Comment = '%1 - an option value';
        MultipleConfigTemplatesLbl: Label '%1 templates', Comment = '%1 - number of templates';

    procedure FindFilteredRec(RecordRef: RecordRef; var OutOfMapFilter: Boolean) Found: Boolean
    var
        TempRecRef: RecordRef;
    begin
        TempRecRef.Open(RecordRef.Number, true);
        CopyRecordReference(RecordRef, TempRecRef, false);
        if "Table ID" = RecordRef.Number then
            SetRecordRefFilter(TempRecRef)
        else
            SetIntRecordRefFilter(TempRecRef);
        Found := TempRecRef.Find();
        OutOfMapFilter := not Found;
        TempRecRef.Close();
    end;

    [Scope('Cloud')]
    procedure FindMapping(TableNo: Integer; IntegrationTableNo: Integer): Boolean
    begin
        SetRange("Table ID", TableNo);
        SetRange("Integration Table ID", IntegrationTableNo);
        SetRange("Delete After Synchronization", false);
        exit(FindFirst());
    end;

    procedure FindMappingForTable(TableId: Integer): Boolean
    begin
        SetRange("Table ID", TableId);
        SetRange("Delete After Synchronization", false);
        exit(FindFirst());
    end;

    procedure DoesExistForTable(TableId: Integer): Boolean
    begin
        SetRange("Table ID", TableId);
        SetRange("Delete After Synchronization", false);
        exit(not IsEmpty());
    end;

    procedure IsFullSynch(): Boolean
    begin
        exit("Full Sync is Running" and "Delete After Synchronization");
    end;

    procedure GetName() Result: Code[20]
    begin
        if "Delete After Synchronization" then
            Result := "Parent Name";
        if Result = '' then
            Result := Name;
    end;

    procedure GetDirection(): Integer
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Get(GetName());
        exit(IntegrationTableMapping.Direction);
    end;

    procedure GetJobLogEntryNo(): Integer
    begin
        exit(JobLogEntryNo)
    end;

    procedure GetTempDescription(): Text
    var
        Separator: Text;
    begin
        case Direction of
            Direction::Bidirectional:
                Separator := '<->';
            Direction::ToIntegrationTable:
                Separator := '->';
            Direction::FromIntegrationTable:
                Separator := '<-';
        end;
        exit(
          StrSubstNo(
            '%1 %2 %3', GetTableCaption("Table ID"), Separator, GetTableCaption("Integration Table ID")));
    end;

    procedure GetExtendedIntegrationTableCaption(): Text
    var
        TableCaption: Text;
    begin
        TableCaption := GetTableExternalName("Integration Table ID");
        if TableCaption <> '' then
            if "Int. Tbl. Caption Prefix" <> '' then
                exit(StrSubstNo('%1 %2', "Int. Tbl. Caption Prefix", TableCaption));
        exit(TableCaption);
    end;

    procedure GetUserFriendlyMappingName(): Text
    var
        LocalRecordRef: RecordRef;
        IntegrationRecordRef: RecordRef;
    begin
        if (Rec."Table ID" = 0) or (Rec."Integration Table ID" = 0) then
            exit('');

        LocalRecordRef.Open(Rec."Table ID");
        IntegrationRecordRef.Open(Rec."Integration Table ID");

        if Rec."Table ID" = Rec."Integration Table ID" then
            exit(LocalRecordRef.Caption());

        exit(LocalRecordRef.Caption() + ' - ' + IntegrationRecordRef.Caption());
    end;

    local procedure GetTableCaption(ID: Integer): Text
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(ID) then
            exit(TableMetadata.Caption);
        exit('');
    end;

    local procedure GetTableExternalName(ID: Integer): Text
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(ID) then
            exit(TableMetadata.ExternalName);
        exit('');
    end;

    procedure SetTableFilter("Filter": Text)
    var
        OutStream: OutStream;
    begin
        "Table Filter".CreateOutStream(OutStream);
        OutStream.Write(Filter);
    end;

    procedure GetTableFilter() Value: Text
    var
        InStream: InStream;
    begin
        CalcFields("Table Filter");
        "Table Filter".CreateInStream(InStream);
        InStream.Read(Value);
    end;

    procedure SetIntegrationTableFilter(IntTableFilter: Text)
    var
        OutStream: OutStream;
    begin
        "Integration Table Filter".CreateOutStream(OutStream);
        OutStream.Write(IntTableFilter);
    end;

    [Scope('OnPrem')]
    procedure SuggestToIncludeEntitiesWithNullCompany(var IntTableFilter: Text);
    var
        Field: Record "Field";
        CRMProductName: Codeunit "CRM Product Name";
        CompanyIdFieldNo: Integer;
        CompanyIdFilterStartPos: Integer;
        CompanyIdFilter: Text;
        ModifiedCompanyIdFilter: Text;
        OrNullGuid: Text;
    begin
        OrNullGuid := '|{00000000-0000-0000-0000-000000000000}';
        Field.SetRange(TableNo, "Integration Table ID");
        Field.SetRange(Type, Field.Type::GUID);
        Field.SetRange(FieldName, CompanyIdFieldNameTxt);
        if not Field.FindFirst() then
            exit;
        CompanyIdFieldNo := Field."No.";

        CompanyIdFilterStartPos := IntTableFilter.IndexOf('Field' + Format(CompanyIdFieldNo) + '=1');
        if CompanyIdFilterStartPos <= 0 then
            exit;

        CompanyIdFilter := CopyStr(IntTableFilter, CompanyIdFilterStartPos);
        CompanyIdFilter := CopyStr(CompanyIdFilter, 1, CompanyIdFilter.IndexOf(')'));

        if (CompanyIdFilter = '') or (CompanyIdFilter.IndexOf(OrNullGuid) > 0) then
            exit;

        if not Confirm(StrSubstNo(ConfirmIncludeEntitiesWithNoCompanyQst, CRMProductName.CDSServiceName(), Field."Field Caption")) then begin
            Session.LogMessage('0000EG4', StrSubstNo(UserChoseNotToIncludeEntitiesWithEmptyCompanyNameTxt, CRMProductName.CDSServiceName(), Name), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit;
        end;

        ModifiedCompanyIdFilter := CompanyIdFilter.Replace(')', OrNullGuid + ')');
        IntTableFilter := IntTableFilter.Replace(CompanyIdFilter, ModifiedCompanyIdFilter);
    end;

    procedure GetIntegrationTableFilter() Value: Text
    var
        InStream: InStream;
    begin
        CalcFields("Integration Table Filter");
        "Integration Table Filter".CreateInStream(InStream);
        InStream.Read(Value);
    end;

    procedure SetIntTableModifiedOn(ModifiedOn: DateTime)
    begin
        if (ModifiedOn <> 0DT) and (ModifiedOn > "Synch. Int. Tbl. Mod. On Fltr.") then begin
            "Synch. Int. Tbl. Mod. On Fltr." := ModifiedOn;
            Modify(true);
        end;
    end;

    procedure SetTableModifiedOn(ModifiedOn: DateTime)
    begin
        if (ModifiedOn <> 0DT) and (ModifiedOn > "Synch. Modified On Filter") then begin
            "Synch. Modified On Filter" := ModifiedOn;
            Modify(true);
        end;
    end;

    procedure SetJobLogEntryNo(NewJobLogEntryNo: Integer)
    begin
        JobLogEntryNo := NewJobLogEntryNo;
    end;

    procedure ShowLog(JobIDFilter: Text)
    begin
        ShowLog('', JobIDFilter, '');
    end;

    procedure ShowSynchronizationLog(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        TempIntegrationSynchJob: Record "Integration Synch. Job" temporary;
        NameFilter: Text;
    begin
        NameFilter := GetNameFilter(IntegrationTableMapping);
        TempIntegrationSynchJob.SetRange(Type, TempIntegrationSynchJob.Type::Synchronization);
        ShowLog(NameFilter, '', TempIntegrationSynchJob.GetFilter(Type));
    end;

    procedure ShowUncouplingLog(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        TempIntegrationSynchJob: Record "Integration Synch. Job" temporary;
        NameFilter: Text;
    begin
        NameFilter := GetNameFilter(IntegrationTableMapping);
        TempIntegrationSynchJob.SetRange(Type, TempIntegrationSynchJob.Type::Uncoupling);
        ShowLog(NameFilter, '', TempIntegrationSynchJob.GetFilter(Type));
    end;

    procedure ShowCouplingLog(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        TempIntegrationSynchJob: Record "Integration Synch. Job" temporary;
        NameFilter: Text;
    begin
        NameFilter := GetNameFilter(IntegrationTableMapping);
        TempIntegrationSynchJob.SetRange(Type, TempIntegrationSynchJob.Type::Coupling);
        ShowLog(NameFilter, '', TempIntegrationSynchJob.GetFilter(Type));
    end;

    procedure SetOriginalJobQueueEntryOnHold(var JobQueueEntry: Record "Job Queue Entry"; var PrevStatus: Option)
    var
        OriginalIntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if Rec."Full Sync is Running" then begin
            OriginalIntegrationTableMapping.Get(Rec."Parent Name");
            JobQueueEntry.SetRange("Record ID to Process", OriginalIntegrationTableMapping.RecordId);
            if JobQueueEntry.FindFirst() then begin
                PrevStatus := JobQueueEntry.Status;
                JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");
            end;
        end;
    end;

    procedure SetOriginalJobQueueEntryStatus(var JobQueueEntry: Record "Job Queue Entry"; Status: Option)
    var
        OriginalIntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if Rec."Full Sync is Running" then begin
            OriginalIntegrationTableMapping.Get(Rec."Parent Name");
            OriginalIntegrationTableMapping.CopyModifiedOnFilters(Rec);
            if JobQueueEntry.FindFirst() then
                JobQueueEntry.SetStatus(Status);
        end;
    end;

    procedure UpdateTableMappingModifiedOn(LatestModifiedOn: array[2] of DateTime)
    var
        IsChanged: Boolean;
    begin
        if LatestModifiedOn[DateType::Integration] > Rec."Synch. Modified On Filter" then begin
            Rec."Synch. Modified On Filter" := LatestModifiedOn[DateType::Integration];
            IsChanged := true;
        end;
        if LatestModifiedOn[DateType::Local] > Rec."Synch. Int. Tbl. Mod. On Fltr." then begin
            Rec."Synch. Int. Tbl. Mod. On Fltr." := LatestModifiedOn[DateType::Local];
            IsChanged := true;
        end;
        if IsChanged then
            Rec.Modify(true);
    end;

    local procedure CopyRecordReference(FromRec: RecordRef; var ToRec: RecordRef; ValidateOnInsert: Boolean)
    var
        FromField: FieldRef;
        ToField: FieldRef;
        Counter: Integer;
    begin
        if FromRec.Number <> ToRec.Number then
            exit;

        ToRec.Init();
        for Counter := 1 to FromRec.FieldCount do begin
            FromField := FromRec.FieldIndex(Counter);
            if not (FromField.Type in [FieldType::BLOB, FieldType::TableFilter]) then begin
                ToField := ToRec.Field(FromField.Number);
                ToField.Value := FromField.Value();
            end;
        end;
        ToRec.Insert(ValidateOnInsert);
    end;

    local procedure ShowLog(NameFilter: Text; JobIDFilter: Text; JobTypeFilter: Text)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        if (NameFilter = '') and (Name = '') then
            exit;

        IntegrationSynchJob.SetCurrentKey("Start Date/Time", ID);
        IntegrationSynchJob.Ascending := false;
        IntegrationSynchJob.FilterGroup(2);
        if NameFilter <> '' then
            IntegrationSynchJob.SetFilter("Integration Table Mapping Name", NameFilter)
        else
            IntegrationSynchJob.SetRange("Integration Table Mapping Name", Name);
        IntegrationSynchJob.FilterGroup(0);
        if JobIDFilter <> '' then
            IntegrationSynchJob.SetFilter(ID, JobIDFilter);
        if JobTypeFilter <> '' then
            IntegrationSynchJob.SetFilter(Type, JobTypeFilter);
        if IntegrationSynchJob.FindFirst() then;
        Page.Run(Page::"Integration Synch. Job List", IntegrationSynchJob);
    end;

    local procedure GetNameFilter(var IntegrationTableMapping: Record "Integration Table Mapping"): Text
    var
        NameFilter: Text;
    begin
        if IntegrationTableMapping.FindSet() then
            repeat
                if Name <> '' then begin
                    if NameFilter <> '' then
                        NameFilter += '|';
                    NameFilter += IntegrationTableMapping.Name;
                end;
            until IntegrationTableMapping.Next() = 0;
        exit(NameFilter);
    end;

    procedure SynchronizeNow(ResetLastSynchModifiedOnDateTime: Boolean)
    begin
        SynchronizeNow(ResetLastSynchModifiedOnDateTime, false);
    end;

    procedure SynchronizeNow(ResetLastSynchModifiedOnDateTime: Boolean; ResetSynchonizationTimestampOnRecords: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        IsHandled: Boolean;
    begin
        OnSynchronizeNow(Rec, ResetLastSynchModifiedOnDateTime, ResetSynchonizationTimestampOnRecords, IsHandled);
        if IsHandled then
            exit;

        Codeunit.Run(Codeunit::"CRM Integration Management");
        if ResetLastSynchModifiedOnDateTime then begin
            Clear("Synch. Modified On Filter");
            Clear("Synch. Int. Tbl. Mod. On Fltr.");
            Modify();
        end;
        if ResetSynchonizationTimestampOnRecords then begin
            CRMIntegrationManagement.RepairBrokenCouplings(true);
            CRMIntegrationRecord.SetRange("Table ID", "Table ID");
            case Direction of
                Direction::ToIntegrationTable:
                    CRMIntegrationRecord.ModifyAll("Last Synch. Modified On", 0DT);
                Direction::FromIntegrationTable:
                    CRMIntegrationRecord.ModifyAll("Last Synch. CRM Modified On", 0DT);
            end
        end;
        Commit();
        CRMSetupDefaults.CreateJobQueueEntry(Rec);
    end;

    [Scope('OnPrem')]
    procedure SynchronizeOptionNow(ResetLastSynchModifiedOnDateTime: Boolean; ResetSynchonizationTimestampOnRecords: Boolean)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        Codeunit.Run(Codeunit::"CRM Integration Management");
        if ResetLastSynchModifiedOnDateTime then begin
            Clear("Synch. Modified On Filter");
            Clear("Synch. Int. Tbl. Mod. On Fltr.");
            Modify();
        end;
        if ResetSynchonizationTimestampOnRecords then begin
            CRMOptionMapping.SetRange("Table ID", "Table ID");
            CRMOptionMapping.SetRange("Integration Table ID", "Integration Table ID");
            if Direction = Direction::ToIntegrationTable then
                CRMOptionMapping.ModifyAll("Last Synch. Modified On", 0DT);
        end;
        Commit();
        CRMSetupDefaults.CreateJobQueueEntry(Rec);
    end;

    procedure GetRecordRef(ID: Variant; var IntegrationRecordRef: RecordRef): Boolean
    var
        IDFieldRef: FieldRef;
        RecordID: RecordID;
        TextKey: Text;
    begin
        IntegrationRecordRef.Close();
        if ID.IsGuid then begin
            IntegrationRecordRef.Open("Integration Table ID");
            IDFieldRef := IntegrationRecordRef.Field("Integration Table UID Fld. No.");
            IDFieldRef.SetFilter(ID);
            exit(IntegrationRecordRef.FindFirst());
        end;

        if ID.IsRecordId then begin
            RecordID := ID;
            if RecordID.TableNo = "Table ID" then
                exit(IntegrationRecordRef.Get(ID));
        end;

        if ID.IsText then begin
            IntegrationRecordRef.Open("Integration Table ID");
            IDFieldRef := IntegrationRecordRef.Field("Integration Table UID Fld. No.");
            TextKey := ID;
            IDFieldRef.SetFilter('%1', TextKey);
            exit(IntegrationRecordRef.FindFirst());
        end;
    end;

    procedure SetIntRecordRefFilter(var IntRecordRef: RecordRef)
    var
        ModifiedOnFieldRef: FieldRef;
        TableFilter: Text;
    begin
        TableFilter := GetIntegrationTableFilter();
        if TableFilter <> '' then
            IntRecordRef.SetView(TableFilter);

        if "Synch. Modified On Filter" <> 0DT then begin
            ModifiedOnFieldRef := IntRecordRef.Field("Int. Tbl. Modified On Fld. No.");
            ModifiedOnFieldRef.SetFilter('>%1', "Synch. Modified On Filter" - 999);
        end;
    end;

    procedure SetIntRecordRefFilter(var IntRecordRef: RecordRef; TableFilter: Text)
    var
        ModifiedOnFieldRef: FieldRef;
    begin
        if TableFilter <> '' then
            IntRecordRef.SetView(TableFilter);

        if "Synch. Modified On Filter" <> 0DT then begin
            ModifiedOnFieldRef := IntRecordRef.Field("Int. Tbl. Modified On Fld. No.");
            ModifiedOnFieldRef.SetFilter('>%1', "Synch. Modified On Filter" - 999);
        end;
    end;

    procedure SetRecordRefFilter(var RecordRef: RecordRef)
    var
        TableFilter: Text;
    begin
        TableFilter := GetTableFilter();
        if TableFilter <> '' then
            RecordRef.SetView(TableFilter);
    end;

    procedure CopyModifiedOnFilters(FromIntegrationTableMapping: Record "Integration Table Mapping")
    begin
        "Synch. Modified On Filter" := FromIntegrationTableMapping."Synch. Modified On Filter";
        "Synch. Int. Tbl. Mod. On Fltr." := FromIntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr.";
        Modify();
    end;

    [Scope('Cloud')]
    procedure CreateRecord(MappingName: Code[20]; TableNo: Integer; IntegrationTableNo: Integer; IntegrationTableUIDFieldNo: Integer; IntegrationTableModifiedFieldNo: Integer; TableConfigTemplateCode: Code[10]; IntegrationTableConfigTemplateCode: Code[10]; SynchOnlyCoupledRecords: Boolean; DirectionArg: Option; Prefix: Text[30])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        UncoupleCodeunitId: Integer;
        CouplingCodeunitId: Integer;
    begin
        if DirectionArg in [IntegrationTableMapping.Direction::ToIntegrationTable, IntegrationTableMapping.Direction::Bidirectional] then
            if CDSIntegrationMgt.HasCompanyIdField(IntegrationTableNo) then
                UncoupleCodeunitId := Codeunit::"CDS Int. Table Uncouple";
        CouplingCodeunitId := Codeunit::"CDS Int. Table Couple";
        CreateRecord(MappingName, TableNo, IntegrationTableNo, IntegrationTableUIDFieldNo, IntegrationTableModifiedFieldNo, TableConfigTemplateCode, IntegrationTableConfigTemplateCode, SynchOnlyCoupledRecords, DirectionArg, Prefix, Codeunit::"CRM Integration Table Synch.", UncoupleCodeunitId, CouplingCodeunitId);
    end;

    [Scope('Cloud')]
    procedure CreateRecord(MappingName: Code[20]; TableNo: Integer; IntegrationTableNo: Integer; IntegrationTableUIDFieldNo: Integer; IntegrationTableModifiedFieldNo: Integer; TableConfigTemplateCode: Code[10]; IntegrationTableConfigTemplateCode: Code[10]; SynchOnlyCoupledRecords: Boolean; DirectionArg: Option; Prefix: Text[30]; SynchCodeunitId: Integer; UncoupleCodeunitId: Integer)
    var
        Field: Record Field;
    begin
        if Get(MappingName) then
            Delete(true);
        Init();
        Name := MappingName;
        "Table ID" := TableNo;
        "Integration Table ID" := IntegrationTableNo;
        "Synch. Codeunit ID" := SynchCodeunitId;
        "Uncouple Codeunit ID" := UncoupleCodeunitId;
        Validate("Integration Table UID Fld. No.", IntegrationTableUIDFieldNo);
        "Int. Tbl. Modified On Fld. No." := IntegrationTableModifiedFieldNo;
        Direction := DirectionArg;
        "Int. Tbl. Caption Prefix" := Prefix;
        "Synch. Only Coupled Records" := SynchOnlyCoupledRecords;
        if "Int. Table UID Field Type" = Field.Type::Option then
            "Coupling Codeunit ID" := Codeunit::"CDS Int. Option Couple"
        else
            "Coupling Codeunit ID" := Codeunit::"CDS Int. Table Couple";
        Insert(true);
        if TableConfigTemplateCode <> '' then
            CreateTableConfigTemplate(Rec, TableConfigTemplateCode);
        if IntegrationTableConfigTemplateCode <> '' then
            CreateIntTableConfigTemplate(Rec, IntegrationTableConfigTemplateCode);
    end;

    [Scope('Cloud')]
    procedure CreateRecord(MappingName: Code[20]; TableNo: Integer; IntegrationTableNo: Integer; IntegrationTableUIDFieldNo: Integer; IntegrationTableModifiedFieldNo: Integer; TableConfigTemplateCode: Code[10]; IntegrationTableConfigTemplateCode: Code[10]; SynchOnlyCoupledRecords: Boolean; DirectionArg: Option; Prefix: Text[30]; SynchCodeunitId: Integer; UncoupleCodeunitId: Integer; CouplingCodeunitId: Integer)
    begin
        if Get(MappingName) then
            Delete(true);
        Init();
        Name := MappingName;
        "Table ID" := TableNo;
        "Integration Table ID" := IntegrationTableNo;
        "Synch. Codeunit ID" := SynchCodeunitId;
        "Uncouple Codeunit ID" := UncoupleCodeunitId;
        Validate("Integration Table UID Fld. No.", IntegrationTableUIDFieldNo);
        "Int. Tbl. Modified On Fld. No." := IntegrationTableModifiedFieldNo;
        Direction := DirectionArg;
        "Int. Tbl. Caption Prefix" := Prefix;
        "Synch. Only Coupled Records" := SynchOnlyCoupledRecords;
        "Coupling Codeunit ID" := CouplingCodeunitId;
        Insert(true);
        if TableConfigTemplateCode <> '' then
            CreateTableConfigTemplate(Rec, TableConfigTemplateCode);
        if IntegrationTableConfigTemplateCode <> '' then
            CreateIntTableConfigTemplate(Rec, IntegrationTableConfigTemplateCode);
    end;

    procedure SetFullSyncStartAndCommit()
    begin
        Validate("Full Sync is Running", true);
        Modify();
        Commit();
        Get(Name);
    end;

    procedure SetFullSyncEndAndCommit()
    begin
        Validate("Full Sync is Running", false);
        Modify();
        Commit();
        Get(Name);
    end;

    procedure IsFullSyncAllowed(): Boolean
    begin
        Get(Name);
        if not "Full Sync is Running" then
            exit(true);

        if not IsSessionActive("Full Sync Session ID") then begin
            SetFullSyncEndAndCommit();
            exit(true);
        end;
        if Abs(CurrentDateTime - "Last Full Sync Start DateTime") >= OneDayInMiliseconds() then
            exit(true);
        exit(false)
    end;

    internal procedure EnableMultiCompanySynchronization()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSCompany: Record "CDS Company";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMProductName: Codeunit "CRM Product Name";
        IntegrationRecordRef: RecordRef;
        CompanyIdFieldRef: FieldRef;
        IsHandled: Boolean;
        MessageTxt: Text;
    begin
        OnEnableMultiCompanySynchronization(Rec, IsHandled);
        if (IsHandled) then
            exit;

        if Rec.Type <> Rec.Type::Dataverse then
            exit;

        Codeunit.Run(Codeunit::"CRM Integration Management");

        if CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            if CRMIntegrationManagement.CheckSolutionVersionOutdated() then
                if CRMConnectionSetup.Get() then
                    if GuiAllowed() then
                        if Confirm(InstallLatestSolutionConfirmLbl) then
                            CRMConnectionSetup.DeployCRMSolution(true)
                        else
                            Error('');

        case Rec."Table ID" of
            Database::"Sales Header",
            Database::Opportunity:
                begin
                    IntegrationRecordRef.Open(Rec."Integration Table ID");

                    if not CDSIntegrationImpl.FindCompanyIdField(IntegrationRecordRef, CompanyIdFieldRef) then
                        exit;

                    if not CDSIntegrationMgt.GetCDSCompany(CDSCompany) then
                        exit;

                    if GuiAllowed() then
                        if not Confirm(StrSubstNo(CompanyFilterStrengthenedQst, IntegrationRecordRef.Caption())) then
                            Error('');

                    IntegrationRecordRef.SetView(Rec.GetIntegrationTableFilter());
                    CompanyIdFieldRef.SetRange(CDSCompany.CompanyId);
                    Rec.SetIntegrationTableFilter(CRMSetupDefaults.GetTableFilterFromView(Rec."Integration Table ID", IntegrationRecordRef.Caption(), IntegrationRecordRef.GetView()));
                    MessageTxt := StrSubstNo(CompanyFilterStrengthenedMsg, IntegrationRecordRef.Caption(), CompanyName(), CRMProductName.SHORT());
                    if Rec.Modify() then
                        if GuiAllowed() then
                            if MessageTxt <> '' then
                                Message(MessageTxt);
                end;
            else begin
                IntegrationRecordRef.Open(Rec."Integration Table ID");

                if not CDSIntegrationImpl.FindCompanyIdField(IntegrationRecordRef, CompanyIdFieldRef) then
                    exit;

                if GuiAllowed() then
                    if not Confirm(StrSubstNo(CompanyFilterRemovedQst, IntegrationRecordRef.Caption())) then
                        Error('');
                IntegrationRecordRef.SetView(Rec.GetIntegrationTableFilter());
                CompanyIdFieldRef.SetRange();
                Rec.SetIntegrationTableFilter(CRMSetupDefaults.GetTableFilterFromView(Rec."Integration Table ID", IntegrationRecordRef.Caption(), IntegrationRecordRef.GetView()));
                if Rec.Modify() then
                    if GuiAllowed() then
                        if Rec.Direction = Rec.Direction::FromIntegrationTable then
                            Message(StrSubstNo(CompanyFilterRemovedShortMsg, IntegrationRecordRef.Caption()))
                        else
                            Message(StrSubstNo(CompanyFilterRemovedExtendedMsg, IntegrationRecordRef.Caption()));
            end;
        end;
    end;

    internal procedure DisableMultiCompanySynchronization()
    var
        CDSCompany: Record "CDS Company";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        IntegrationRecordRef: RecordRef;
        CompanyIdFieldRef: FieldRef;
        IsHandled: Boolean;
        EmptyGuid: Guid;
    begin
        OnDisableMultiCompanySynchronization(Rec, IsHandled);
        if (IsHandled) then
            exit;

        if Rec.Type <> Rec.Type::Dataverse then
            exit;

        Codeunit.Run(Codeunit::"CRM Integration Management");
        IntegrationRecordRef.Open(Rec."Integration Table ID");

        if not CDSIntegrationImpl.FindCompanyIdField(IntegrationRecordRef, CompanyIdFieldRef) then
            exit;

        if not CDSIntegrationMgt.GetCDSCompany(CDSCompany) then
            exit;

        if GuiAllowed() then
            if not Confirm(StrSubstNo(CompanyFilterResetToDefaultQst)) then
                Error('');

        IntegrationRecordRef.SetView(Rec.GetIntegrationTableFilter());
        CompanyIdFieldRef.SetFilter(StrSubstno(OrTok, CDSCompany.CompanyId, EmptyGuid));
        Rec.SetIntegrationTableFilter(CRMSetupDefaults.GetTableFilterFromView(Rec."Integration Table ID", IntegrationRecordRef.Caption(), IntegrationRecordRef.GetView()));
        if Rec.Modify() then
            if GuiAllowed() then
                Message(CompanyFilterResetMsg);
    end;

    procedure IsMappingEnabled(RequestedDirection: Option Bidirectional,ToIntegrationTable,FromIntegrationTable): Boolean
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        IsHandled, Result : Boolean;
    begin
        OnBeforeIsMappingEnabled(RequestedDirection, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Rec.Direction <> RequestedDirection then
            case RequestedDirection of
                RequestedDirection::Bidirectional:
                    exit(false);
                RequestedDirection::FromIntegrationTable:
                    if Rec.Direction = Rec.Direction::ToIntegrationTable then
                        exit(false);
                RequestedDirection::ToIntegrationTable:
                    if Rec.Direction = Rec.Direction::FromIntegrationTable then
                        exit(false);
            end;

        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", Rec.Name);
        case RequestedDirection of
            RequestedDirection::Bidirectional:
                IntegrationFieldMapping.SetRange(Direction, IntegrationFieldMapping.Direction::Bidirectional);
            RequestedDirection::FromIntegrationTable:
                IntegrationFieldMapping.SetFilter(Direction, '%1|%2', IntegrationFieldMapping.Direction::FromIntegrationTable, IntegrationFieldMapping.Direction::Bidirectional);
            RequestedDirection::ToIntegrationTable:
                IntegrationFieldMapping.SetFilter(Direction, '%1|%2', IntegrationFieldMapping.Direction::ToIntegrationTable, IntegrationFieldMapping.Direction::Bidirectional);
        end;
        IntegrationFieldMapping.SetRange(Status, IntegrationFieldMapping.Status::Enabled);
        exit(not IntegrationFieldMapping.IsEmpty());
    end;

    procedure IsFieldMappingEnabled(FieldNo: Integer; IntegrationTableFieldNo: Integer; RequestedDirection: Option Bidirectional,ToIntegrationTable,FromIntegrationTable): Boolean
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        IsHandled, Result : Boolean;
    begin
        OnBeforeIsFieldMappingEnabled(FieldNo, IntegrationTableFieldNo, RequestedDirection, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not IsMappingEnabled(RequestedDirection) then
            exit(false);

        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", Rec.Name);
        IntegrationFieldMapping.SetRange("Field No.", FieldNo);
        IntegrationFieldMapping.SetRange("Integration Table Field No.", IntegrationTableFieldNo);
        case RequestedDirection of
            RequestedDirection::Bidirectional:
                IntegrationFieldMapping.SetRange(Direction, IntegrationFieldMapping.Direction::Bidirectional);
            RequestedDirection::FromIntegrationTable:
                IntegrationFieldMapping.SetFilter(Direction, '%1|%2', IntegrationFieldMapping.Direction::FromIntegrationTable, IntegrationFieldMapping.Direction::Bidirectional);
            RequestedDirection::ToIntegrationTable:
                IntegrationFieldMapping.SetFilter(Direction, '%1|%2', IntegrationFieldMapping.Direction::ToIntegrationTable, IntegrationFieldMapping.Direction::Bidirectional);
        end;
        IntegrationFieldMapping.SetRange(Status, IntegrationFieldMapping.Status::Enabled);
        exit(not IntegrationFieldMapping.IsEmpty());
    end;

    local procedure OneDayInMiliseconds(): Integer
    begin
        exit(24 * 60 * 60 * 1000)
    end;

    procedure GetTableConfigTemplates(IntegrationTableMappingName: Code[20]): Text
    var
        TableConfigTemplate: Record "Table Config Template";
    begin
        TableConfigTemplate.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        case TableConfigTemplate.Count() of
            0:
                exit('');
            1:
                begin
                    TableConfigTemplate.FindFirst();
                    exit(TableConfigTemplate."Table Config Template Code");
                end;
            else
                exit(StrSubstNo(MultipleConfigTemplatesLbl, Format(TableConfigTemplate.Count())));
        end;
    end;

    procedure GetIntTableConfigTemplates(IntegrationTableMappingName: Code[20]): Text
    var
        IntegrationTableConfigTemplate: Record "Int. Table Config Template";
    begin
        IntegrationTableConfigTemplate.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        case IntegrationTableConfigTemplate.Count() of
            0:
                exit('');
            1:
                begin
                    IntegrationTableConfigTemplate.FindFirst();
                    exit(IntegrationTableConfigTemplate."Int. Tbl. Config Template Code");
                end;
            else
                exit(StrSubstNo(MultipleConfigTemplatesLbl, Format(IntegrationTableConfigTemplate.Count())));
        end;
    end;

    local procedure CreateTableConfigTemplate(IntegrationTableMapping: Record "Integration Table Mapping"; TableConfigTemplateCode: Code[10])
    var
        TableConfigTemplate: Record "Table Config Template";
    begin
        TableConfigTemplate."Integration Table Mapping Name" := IntegrationTableMapping.Name;
        TableConfigTemplate.Validate("Table ID", IntegrationTableMapping."Table ID");
        TableConfigTemplate.Validate("Integration Table ID", IntegrationTableMapping."Integration Table ID");
        TableConfigTemplate.Validate("Table Config Template Code", TableConfigTemplateCode);
        TableConfigTemplate.Insert();
    end;

    local procedure CreateIntTableConfigTemplate(IntegrationTableMapping: Record "Integration Table Mapping"; IntegrationTableConfigTemplateCode: Code[10])
    var
        IntTableConfigTemplate: Record "Int. Table Config Template";
    begin
        IntTableConfigTemplate."Integration Table Mapping Name" := IntegrationTableMapping.Name;
        IntTableConfigTemplate.Validate("Integration Table ID", IntegrationTableMapping."Integration Table ID");
        IntTableConfigTemplate.Validate("Table ID", IntegrationTableMapping."Table ID");
        IntTableConfigTemplate.Validate("Int. Tbl. Config Template Code", IntegrationTableConfigTemplateCode);
        IntTableConfigTemplate.Insert();
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnIsCreateNewInCaseOfNoMatchControlVisible(var IntegrationTableMapping: Record "Integration Table Mapping"; var CreateNewInCaseOfNoMatchControlVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeNow(var IntegrationTableMapping: Record "Integration Table Mapping"; ResetLastSynchModifiedOnDateTime: Boolean; ResetSynchonizationTimestampOnRecords: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnEnableMultiCompanySynchronization(var IntegrationTableMapping: Record "Integration Table Mapping"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnDisableMultiCompanySynchronization(var IntegrationTableMapping: Record "Integration Table Mapping"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsMappingEnabled(RequestedDirection: Option Bidirectional,ToIntegrationTable,FromIntegrationTable; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsFieldMappingEnabled(FieldNo: Integer; IntegrationTableFieldNo: Integer; RequestedDirection: Option Bidirectional,ToIntegrationTable,FromIntegrationTable; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    local procedure CheckDeletionConflictResolutionStrategy()
    begin
        if Rec."Deletion-Conflict Resolution" = Rec."Deletion-Conflict Resolution"::"Remove Coupling" then
            if not Rec."Synch. Only Coupled Records" then
                if GuiAllowed() then
                    if not Confirm(RemoveCouplingStrategyQst) then
                        Error('');
    end;
}

