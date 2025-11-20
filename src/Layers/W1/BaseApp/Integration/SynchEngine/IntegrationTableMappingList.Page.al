// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Sales.Document;
using System.Reflection;
using System.Threading;
using System.Globalization;

page 5335 "Integration Table Mapping List"
{
    ApplicationArea = Suite;
    Caption = 'Integration Table Mappings';
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Integration Table Mapping";
    SourceTableView = where("Delete After Synchronization" = const(false));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the integration table mapping entry.';
                }
                field(TableCaptionValue; TableCaptionValue)
                {
                    ApplicationArea = Suite;
                    Caption = 'Table';
                    Editable = false;
                    ToolTip = 'Specifies the name of the Business Central table to map to the integration table.';
                }
                field(TableFilterValue; TableFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'Table Filter';
                    ToolTip = 'Specifies the synchronization inclusion filter on the Business Central table. Records that fall outside this filter are not synchronized.';

                    trigger OnAssistEdit()
                    var
                        FilterPageBuilder: FilterPageBuilder;
                    begin
                        FilterPageBuilder.AddTable(TableCaptionValue, Rec."Table ID");
                        if TableFilter <> '' then
                            FilterPageBuilder.SetView(TableCaptionValue, TableFilter);
                        if FilterPageBuilder.RunModal() then begin
                            TableFilter := FilterPageBuilder.GetView(TableCaptionValue, false);
                            CheckBidirectionalSalesOrderTableFilter(TableFilter);
                            Rec.SetTableFilter(TableFilter);
                        end;
                    end;
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the synchronization direction.';
                }
                field(IntegrationTableCaptionValue; IntegrationTableCaptionValue)
                {
                    ApplicationArea = Suite;
                    Caption = 'Integration Table';
                    Enabled = false;
                    ToolTip = 'Specifies the name of the integration table to map to the Business Central table.';
                }
                field(IntegrationTableFilter; IntegrationTableFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'Integration Table Filter';
                    ToolTip = 'Specifies the synchronization inclusion filter on the table in the system you are integrating with. Records that fall outside this filter are not synchronized.';

                    trigger OnAssistEdit()
                    var
                        FilterPageBuilder: FilterPageBuilder;
                    begin
                        Codeunit.Run(Codeunit::"CRM Integration Management");
                        FilterPageBuilder.AddTable(IntegrationTableCaptionValue, Rec."Integration Table ID");
                        if IntegrationTableFilter <> '' then
                            FilterPageBuilder.SetView(IntegrationTableCaptionValue, IntegrationTableFilter);
                        Commit();
                        if FilterPageBuilder.RunModal() then begin
                            IntegrationTableFilter := FilterPageBuilder.GetView(IntegrationTableCaptionValue, false);
                            Session.LogMessage('0000EG5', StrSubstNo(UserEditedIntegrationTableFilterTxt, Rec.Name), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
                            CheckBidirectionalSalesOrderIntegrationTableFilter(IntegrationTableFilter);
                            Rec.SuggestToIncludeEntitiesWithNullCompany(IntegrationTableFilter);
                            Rec.SetIntegrationTableFilter(IntegrationTableFilter);
                        end;
                    end;
                }
                field("Synch. Only Coupled Records"; Rec."Synch. Only Coupled Records")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the synchronization engine will process only currently coupled records or couple the newly created records as well.';
                }
                field("Multi Company Synch. Enabled"; Rec."Multi Company Synch. Enabled")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the multi-company synchronization is enabled for this mapping.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(IntegrationFieldCaption; IntegrationFieldCaptionValue)
                {
                    ApplicationArea = Suite;
                    Caption = 'Integration Field';
                    Editable = false;
                    ToolTip = 'Specifies the ID of the field in the integration table to map to the Business Central table.';

                    trigger OnDrillDown()
                    var
                        CRMOptionMapping: Record "CRM Option Mapping";
                        "Field": Record "Field";
                    begin
                        if Rec."Int. Table UID Field Type" = Field.Type::Option then begin
                            CRMOptionMapping.FilterGroup(2);
                            CRMOptionMapping.SetRange("Table ID", Rec."Table ID");
                            CRMOptionMapping.FilterGroup(0);
                            PAGE.RunModal(PAGE::"CRM Option Mapping", CRMOptionMapping);
                        end;
                    end;
                }
                field(IntegrationFieldType; IntegrationFieldTypeValue)
                {
                    ApplicationArea = Suite;
                    Caption = 'Integration Field Type';
                    Editable = false;
                    ToolTip = 'Specifies the type of the field in the integration table to map to the Business Central table.';
                }
#if not CLEAN25            
                field("Table Config Template Code"; Rec."Table Config Template Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a configuration template to use when creating new records in the Business Central table (specified by the Table ID field) during synchronization.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced with Table Config Templates field';
                    ObsoleteTag = '25.0';
                }
                field("Int. Tbl. Config Template Code"; Rec."Int. Tbl. Config Template Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a configuration template to use for creating new records in the integration table.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced with Table Config Templates field';
                    ObsoleteTag = '25.0';
                }
#endif
                field("Table Config Templates"; TableConfigTemplates)
                {
                    ApplicationArea = Suite;
                    Caption = 'Table Config Templates';
                    ToolTip = 'Specifies configuration templates to use when creating new records in the Business Central table (specified by the Table ID field) during synchronization.';
                    Editable = false;

                    trigger OnAssistEdit()
                    var
                        TableConfigTemplate: Record "Table Config Template";
                        TableConfigTemplates: Page "Table Config Templates";
                    begin
                        TableConfigTemplate.SetRange("Integration Table Mapping Name", Rec.Name);
                        TableConfigTemplates.SetTableView(TableConfigTemplate);
                        TableConfigTemplates.RunModal();
                    end;
                }
                field("Int. Table Config Templates"; IntTableConfigTemplates)
                {
                    ApplicationArea = Suite;
                    Caption = 'Integration Table Config Templates';
                    ToolTip = 'Specifies configuration templates to use for creating new records in the integration table.';
                    Editable = false;

                    trigger OnAssistEdit()
                    var
                        IntTableConfigTemplate: Record "Int. Table Config Template";
                        IntTableConfigTemplates: Page "Int. Table Config Templates";
                    begin
                        IntTableConfigTemplate.SetRange("Integration Table Mapping Name", Rec.Name);
                        IntTableConfigTemplates.SetTableView(IntTableConfigTemplate);
                        IntTableConfigTemplates.RunModal();
                    end;
                }
                field("Int. Tbl. Caption Prefix"; Rec."Int. Tbl. Caption Prefix")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies text that appears before the caption of the integration table wherever the caption is used.';
                    Visible = false;
                }
                field("Synch. Modified On Filter"; Rec."Synch. Modified On Filter")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a date/time filter that uses the date on which records were modified to determine which records to synchronize from the system you are integrating with. The filter is based on the Modified On field on the integration table records.';
                }
                field("Synch. Int. Tbl. Mod. On Fltr."; Rec."Synch. Int. Tbl. Mod. On Fltr.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a date/time filter that uses the date on which records were modified to determine which records to synchronize to the integration system. The filter is based on the SystemModifiedAt field on the Business Central table records.';
                }
                field("Deletion-Conflict Resolution"; Rec."Deletion-Conflict Resolution")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the action to take when a coupled record is deleted in one of the connected applications.';
                }
                field("Update-Conflict Resolution"; Rec."Update-Conflict Resolution")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the action to take when a coupled record is updated in both of the connected applications.';
                }
                field("Disable Event Job Resch."; Rec."Disable Event Job Resch.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if event-based rescheduling of synchronization jobs should be turned off for this table mapping.';
                }
                field("User Defined"; Rec."User Defined")
                {
                    Editable = false;
                    ToolTip = 'Specifies if the field is generated manually through the integration table mapping wizard.';
                }
            }
        }
        area(factboxes)
        {
            part(Troubleshooting; "Int. Table Mapping Errors")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = Name = field(Name);
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(FieldMapping)
            {
                ApplicationArea = Suite;
                Caption = 'Fields';
                Enabled = HasRecords;
                Image = Relationship;
                RunObject = Page "Integration Field Mapping List";
                RunPageLink = "Integration Table Mapping Name" = field(Name);
                RunPageMode = View;
                ToolTip = 'View fields in integration tables that are mapped to fields in Business Central.';
            }
            action(ResetConfiguration)
            {
                ApplicationArea = Suite;
                Caption = 'Use Default Synchronization Setup';
                Image = ResetStatus;
                ToolTip = 'Resets the integration table mappings and synchronization jobs to the default values for a connection with the integration system. All current mappings are deleted.';

                trigger OnAction()
                var
                    IntegrationTableMapping: Record "Integration Table Mapping";
                    CRMIntegrationMgt: Codeunit "CRM Integration Management";
                begin
                    CurrPage.SetSelectionFilter(IntegrationTableMapping);

                    if IntegrationTableMapping.IsEmpty() then
                        Error(NoRecSelectedErr);

                    CRMIntegrationMgt.ResetIntTableMappingDefaultConfiguration(IntegrationTableMapping);

                    if Confirm(JobQEntryCreatedQst) then
                        ShowJobQueueEntry(IntegrationTableMapping);
                end;
            }
            action(JobQueueEntry)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Job Queue Entry';
                Enabled = HasRecords;
                Image = JobListSetup;
                ToolTip = 'View or edit the job queue entry for this integration table mapping.';

                trigger OnAction()
                begin
                    ShowJobQueueEntry(Rec);
                end;
            }
            action("View Integration Synch. Job Log")
            {
                ApplicationArea = Suite;
                Caption = 'Integration Synch. Job Log';
                Enabled = HasRecords;
                Image = Log;
                ToolTip = 'View the status of the individual synchronization jobs. This includes synchronization jobs that have been run from the job queue and manual synchronization jobs that were performed on records from the Business Central client.';

                trigger OnAction()
                var
                    IntegrationTableMapping: Record "Integration Table Mapping";
                begin
                    CurrPage.SetSelectionFilter(IntegrationTableMapping);
                    Rec.ShowSynchronizationLog(IntegrationTableMapping);
                end;
            }
            action(SynchronizeNow)
            {
                ApplicationArea = Suite;
                Caption = 'Synchronize Modified Records';
                Enabled = HasRecords and (Rec."Parent Name" = '');
                Image = Refresh;
                ToolTip = 'Synchronize records that have been modified since the last time they were synchronized.';

                trigger OnAction()
                var
                    Field: Record Field;
                    IntegrationSynchJobList: Page "Integration Synch. Job List";
                begin
                    if Rec.IsEmpty() then
                        exit;

                    if Rec."Int. Table UID Field Type" = Field.Type::Option then
                        Rec.SynchronizeOptionNow(false, false)
                    else
                        Rec.SynchronizeNow(false);
                    Message(SynchronizeModifiedScheduledMsg, IntegrationSynchJobList.Caption);
                end;
            }
            action(SynchronizeAll)
            {
                ApplicationArea = Suite;
                Caption = 'Run Full Synchronization';
                Enabled = HasRecords and (Rec."Parent Name" = '');
                Image = RefreshLines;
                ToolTip = 'Start a job for full synchronization between records in Business Central and the integration system for each of the selected integration table mappings.';

                trigger OnAction()
                var
                    Field: Record Field;
                    IntegrationSynchJobList: Page "Integration Synch. Job List";
                begin
                    if Rec.IsEmpty() then
                        exit;

                    if not Confirm(StartFullSynchronizationQst) then
                        exit;

                    if Rec."Int. Table UID Field Type" = Field.Type::Option then
                        Rec.SynchronizeOptionNow(true, false)
                    else
                        Rec.SynchronizeNow(true);
                    Message(FullSynchronizationScheduledMsg, IntegrationSynchJobList.Caption);
                end;
            }
            action(UnconditionalSynchronizeAll)
            {
                ApplicationArea = Suite;
                Caption = 'Run Unconditional Full Synchronization';
                Enabled = HasRecords and (Rec."Parent Name" = '') and (Rec.Direction <> Rec.Direction::Bidirectional);
                Image = RefreshLines;
                ToolTip = 'Start the full synchronization job for all records of this type in Business Central and the integration system. This includes records that have already been synchronized.';

                trigger OnAction()
                var
                    Field: Record Field;
                    IntegrationSynchJobList: Page "Integration Synch. Job List";
                begin
                    if Rec.IsEmpty() then
                        exit;

                    if not Confirm(StartUnconditionalFullSynchronizationQst) then
                        exit;

                    if Rec."Int. Table UID Field Type" = Field.Type::Option then
                        Rec.SynchronizeOptionNow(true, true)
                    else
                        Rec.SynchronizeNow(true, true);
                    Message(FullSynchronizationScheduledMsg, IntegrationSynchJobList.Caption);
                end;
            }
            action("View Integration Uncouple Job Log")
            {
                ApplicationArea = Suite;
                Caption = 'Integration Uncouple Job Log';
                Enabled = HasRecords;
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                Image = Log;
                ToolTip = 'View the status of jobs for uncoupling records. The jobs were run either from the job queue, or manually, in Business Central.';

                trigger OnAction()
                var
                    IntegrationTableMapping: Record "Integration Table Mapping";
                begin
                    CurrPage.SetSelectionFilter(IntegrationTableMapping);
                    Rec.ShowUncouplingLog(IntegrationTableMapping);
                end;
            }
            action("View Integration Coupling Job Log")
            {
                ApplicationArea = Suite;
                Caption = 'Integration Coupling Job Log';
                Enabled = HasRecords;
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                Image = Log;
                ToolTip = 'View the status of jobs for match-based coupling of records.';

                trigger OnAction()
                var
                    IntegrationTableMapping: Record "Integration Table Mapping";
                begin
                    CurrPage.SetSelectionFilter(IntegrationTableMapping);
                    Rec.ShowCouplingLog(IntegrationTableMapping);
                end;
            }
            action(RemoveCoupling)
            {
                ApplicationArea = Suite;
                Caption = 'Delete Couplings';
                Enabled = HasRecords and (Rec."Parent Name" = '');
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                Image = UnLinkAccount;
                ToolTip = 'Delete couplings between the selected Business Central record types records in the integration system.';

                trigger OnAction()
                var
                    IntegrationTableMapping: Record "Integration Table Mapping";
                    FilteredIntegrationTableMapping: Record "Integration Table Mapping";
                    CRMOptionMapping: Record "CRM Option Mapping";
                    Field: Record Field;
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    IntegrationSynchJobList: Page "Integration Synch. Job List";
                    ForegroundCount: Integer;
                    JobCount: Integer;
                    ConfirmMsg: Text;
                    ResultMsg: Text;
                begin
                    CurrPage.SetSelectionFilter(IntegrationTableMapping);
                    if not IntegrationTableMapping.FindSet() then
                        exit;

                    CurrPage.SetSelectionFilter(FilteredIntegrationTableMapping);
                    FilteredIntegrationTableMapping.SetRange(Type, FilteredIntegrationTableMapping.Type::Dataverse);
                    FilteredIntegrationTableMapping.SetRange("Uncouple Codeunit ID", Codeunit::"CDS Int. Table Uncouple");
                    if not FilteredIntegrationTableMapping.IsEmpty() then begin
                        ConfirmMsg := StartUncouplingQst;
                        ResultMsg := RemoveCouplingsScheduledMsg;
                    end else begin
                        ConfirmMsg := StartUncouplingForegroundQst;
                        ResultMsg := UncouplingCompletedMsg;
                    end;
                    if not Confirm(ConfirmMsg) then
                        exit;

                    repeat
                        if IntegrationTableMapping."Int. Table UID Field Type" = Field.Type::Option then begin
                            CRMOptionMapping.SetRange("Table ID", IntegrationTableMapping."Table ID");
                            CRMOptionMapping.SetRange("Integration Table ID", IntegrationTableMapping."Integration Table ID");
                            CRMOptionMapping.DeleteAll();
                        end else
                            CRMIntegrationManagement.RemoveCoupling(IntegrationTableMapping."Table ID", IntegrationTableMapping."Integration Table ID");
                        if IntegrationTableMapping."Uncouple Codeunit ID" = Codeunit::"CDS Int. Table Uncouple" then
                            JobCount += 1
                        else
                            ForegroundCount += 1;
                    until IntegrationTableMapping.Next() = 0;

                    if ForegroundCount > 0 then
                        Message(ResultMsg, IntegrationSynchJobList.Caption, JobCount, StrSubstNo(RemoveCouplingsForegroundMsg, ForegroundCount))
                    else
                        Message(ResultMsg, IntegrationSynchJobList.Caption, JobCount, '');
                end;
            }
            action(MatchBasedCoupling)
            {
                ApplicationArea = Suite;
                Caption = 'Match-Based Coupling';
                Enabled = HasRecords and (Rec."Parent Name" = '') and (((Rec.Name = 'SALESORDER-ORDER') and (not BidirectionalSalesOrderIntegrationEnabled)) or (Rec.Name <> 'SALESORDER-ORDER'));
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                Image = LinkAccount;
                ToolTip = 'Make couplings between the selected Business Central table and the integration table based on matching criteria.';

                trigger OnAction()
                var
                    IntegrationTableMapping: Record "Integration Table Mapping";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    IntegrationSynchJobList: Page "Integration Synch. Job List";
                    ConfirmMsg: Text;
                    ResultMsg: Text;
                begin
                    CurrPage.SetSelectionFilter(IntegrationTableMapping);
                    if not IntegrationTableMapping.FindFirst() then
                        exit;

                    ConfirmMsg := StartMatchBasedCouplingQst;
                    ResultMsg := MatchBasedCouplingScheduledMsg;
                    if not Confirm(ConfirmMsg) then
                        exit;

                    if CRMIntegrationManagement.MatchBasedCoupling(IntegrationTableMapping."Table ID") then
                        Message(ResultMsg, IntegrationSynchJobList.Caption);
                end;
            }
            action(ManualIntTableMappingWizard)
            {
                ApplicationArea = Suite;
                Caption = 'New Table Mapping';
                Image = New;
                RunObject = Page "CDS New Man. Int. Table Wizard";
                ToolTip = 'Create a new integration table mapping.';
            }
            action(ManualIntTableMapping)
            {
                ApplicationArea = Suite;
                Caption = 'Manual Integration Table Mappings';
                Image = Navigate;
                RunObject = Page "Man. Int. Table Mapping List";
                ToolTip = 'See created manual integration mappings.';
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Synchronization', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("View Integration Synch. Job Log_Promoted"; "View Integration Synch. Job Log")
                {
                }
                actionref(SynchronizeNow_Promoted; SynchronizeNow)
                {
                }
                actionref(SynchronizeAll_Promoted; SynchronizeAll)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Mapping', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(JobQueueEntry_Promoted; JobQueueEntry)
                {
                }
                actionref(ResetConfiguration_Promoted; ResetConfiguration)
                {
                }
                actionref(FieldMapping_Promoted; FieldMapping)
                {
                }
                actionref(ManualIntTableMappingWizard_Promoted; ManualIntTableMappingWizard)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Uncoupling', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref("View Integration Uncouple Job Log_Promoted"; "View Integration Uncouple Job Log")
                {
                }
                actionref(RemoveCoupling_Promoted; RemoveCoupling)
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Coupling', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref("View Integration Coupling Job Log_Promoted"; "View Integration Coupling Job Log")
                {
                }
                actionref(MatchBasedCoupling_Promoted; MatchBasedCoupling)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        IntegrationTableCaptionValue := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, Rec."Integration Table ID");
        TableCaptionValue := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, Rec."Table ID");
        IntegrationFieldCaptionValue := GetFieldCaption();
        IntegrationFieldTypeValue := GetFieldType();

        TableFilter := Rec.GetTableFilter();
        IntegrationTableFilter := Rec.GetIntegrationTableFilter();

        HasRecords := not Rec.IsEmpty();

        TableConfigTemplates := Rec.GetTableConfigTemplates(Rec.Name);
        IntTableConfigTemplates := Rec.GetIntTableConfigTemplates(Rec.Name);
    end;

    trigger OnInit()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        SetCRMIntegrationEnabledState();
        SetCDSIntegrationEnabledState();
        BidirectionalSalesOrderIntegrationEnabled := CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled();
    end;

    var
        ObjectTranslation: Record "Object Translation";
        TypeHelper: Codeunit "Type Helper";
        TableCaptionValue: Text[250];
        IntegrationFieldCaptionValue: Text;
        IntegrationFieldTypeValue: Text;
        IntegrationTableCaptionValue: Text[250];
        TableFilter: Text;
        IntegrationTableFilter: Text;
        JobQEntryCreatedQst: Label 'A synchronization job queue entry has been created.\\Do you want to view the job queue entry?';
        StartFullSynchronizationQst: Label 'You are about to synchronize all data within the mapping.\The synchronization will run in the background, so you can continue with other tasks.\\Do you want to continue?';
        StartUnconditionalFullSynchronizationQst: Label 'You are about to synchronize all data in the selected mapping, regardless of whether the data has been modified after the last synchronization.\Use this action only if you have recently added a new field mapping and you want to synchronize its value.\We recommend that you use the Integration Table Filter and Table Filter fields on the Integration Table Mappings page to limit the synchronization to a maximum of 5000 records for each run.\\Do you want to continue?';
        StartUncouplingQst: Label 'You are about to uncouple the selected mappings, which means data for the records will no longer synchronize.\The uncoupling will run in the background, so you can continue with other tasks.\\Do you want to continue?';
        StartMatchBasedCouplingQst: Label 'You are about to couple records in Business Central table with records in the integration table from the selected mapping, based on the matching criteria that you must define.\The coupling will run in the background, so you can continue with other tasks.\\Do you want to continue?';
        StartUncouplingForegroundQst: Label 'You are about to uncouple the selected mappings, which means data for the records will no longer synchronize.\\Do you want to continue?';
        UncouplingCompletedMsg: Label 'Uncoupling completed.';
        SynchronizeModifiedScheduledMsg: Label 'Synchronization is scheduled for Modified Records.\Details are available on the %1 page.', Comment = '%1 caption from page Integration Synch. Job List';
        FullSynchronizationScheduledMsg: Label 'Full Synchronization is scheduled.\Details are available on the %1 page.', Comment = '%1 caption from page Integration Synch. Job List';
        RemoveCouplingsScheduledMsg: Label 'Uncoupling is scheduled for %2 mappings. %3\Details are available on the %1 page.', Comment = '%1 - caption from page 5344, %2 - scheduled job count, %3 - additional foreground job message';
        MatchBasedCouplingScheduledMsg: Label 'Match-based coupling is scheduled. \Details are available on the %1 page.', Comment = '%1 - caption from page 5344';
        RemoveCouplingsForegroundMsg: Label '%1 mappings are uncoupled.', Comment = '%1 - foreground uncoupling count';
        NoRecSelectedErr: Label 'You must choose at least one integration table mapping.';
        UserEditedIntegrationTableFilterTxt: Label 'The user edited the Integration Table Filter on %1 mapping.', Locked = true;
        TelemetryCategoryTok: Label 'AL Dataverse Integration', Locked = true;
        HasRecords: Boolean;
        CRMIntegrationEnabled: Boolean;
        CDSIntegrationEnabled: Boolean;
        BidirectionalSalesOrderTableFilterErr: Label 'Bidirectional Sales Order Integration can only synchronize released Business Central sales orders.';
        BidirectionalSalesOrderIntegrationTableFilterErr: Label 'Bidirectional Sales Order Integration can only synchronize submitted Dynamics 365 Sales sales orders.';
        BidirectionalSalesOrderIntegrationEnabled: Boolean;
        TableConfigTemplates: Text;
        IntTableConfigTemplates: Text;

    local procedure GetFieldCaption(): Text
    var
        "Field": Record "Field";
    begin
        if TypeHelper.GetField(Rec."Integration Table ID", Rec."Integration Table UID Fld. No.", Field) then
            exit(Field."Field Caption");
    end;

    local procedure GetFieldType(): Text
    var
        "Field": Record "Field";
    begin
        Field.Type := Rec."Int. Table UID Field Type";
        exit(Format(Field.Type))
    end;

    local procedure SetCRMIntegrationEnabledState()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
    end;

    local procedure SetCDSIntegrationEnabledState()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
    end;

    local procedure ShowJobQueueEntry(var IntegrationTableMapping: Record "Integration Table Mapping");
    var
        JQueueEntry: Record "Job Queue Entry";
    begin
        JQueueEntry.SetRange("Object Type to Run", JQueueEntry."Object Type to Run"::Codeunit);
        JQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
        JQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
        if JQueueEntry.FindFirst() then
            Page.Run(Page::"Job Queue Entries", JQueueEntry);
    end;

    local procedure CheckBidirectionalSalesOrderTableFilter(SelectedFilter: Text)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        SalesHeader: Record "Sales Header";
        StatusFilter: Text;
        TypeFilter: Text;
    begin
        if Rec."Table ID" = Database::"Sales Header" then
            if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then begin
                SalesHeader.SetView(SelectedFilter);
                StatusFilter := SalesHeader.GetFilter(Status);
                if StatusFilter <> Format(SalesHeader.Status::Released) then
                    Error(BidirectionalSalesOrderTableFilterErr);
                TypeFilter := SalesHeader.GetFilter("Document Type");
                if TypeFilter <> Format(SalesHeader."Document Type"::Order) then
                    Error(BidirectionalSalesOrderTableFilterErr);
            end;
    end;

    local procedure CheckBidirectionalSalesOrderIntegrationTableFilter(SelectedFilter: Text)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSalesorder: Record "CRM Salesorder";
        StatusFilter: Text;
    begin
        if Rec."Integration Table ID" = Database::"CRM Salesorder" then
            if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then begin
                CRMSalesorder.SetView(SelectedFilter);
                StatusFilter := CRMSalesorder.GetFilter(StateCode);
                if StatusFilter <> Format(CRMSalesorder.StateCode::Submitted) then
                    Error(BidirectionalSalesOrderIntegrationTableFilterErr);
            end;
    end;
}

