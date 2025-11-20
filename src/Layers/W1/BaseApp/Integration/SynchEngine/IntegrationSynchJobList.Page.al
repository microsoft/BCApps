// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using System.Reflection;
using Microsoft.Integration.Dataverse;

page 5338 "Integration Synch. Job List"
{
    ApplicationArea = Suite;
    Caption = 'Integration Synchronization Jobs';
    DataCaptionExpression = Rec."Integration Table Mapping Name";
    DeleteAllowed = true;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Integration Synch. Job";
    SourceTableView = sorting("Start Date/Time", ID)
                      order(descending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Start Date/Time"; Rec."Start Date/Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the data and time that the integration synchronization job started.';
                }
                field("Finish Date/Time"; Rec."Finish Date/Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date and time that the integration synchronization job completed.';
                }
                field(Duration; Duration)
                {
                    ApplicationArea = Suite;
                    Caption = 'Duration';
                    HideValue = DoHideDuration;
                    ToolTip = 'Specifies how long the data synchronization has taken.';
                }
                field("Integration Table Mapping Name"; Rec."Integration Table Mapping Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the table mapping that was used for the integration synchronization job.';
                    Visible = false;
                }
                field(Uncoupled; Rec.Uncoupled)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of records that were uncoupled during the integration synchronization job.';
                    Visible = UncouplingSpecificColumnsVisible;
                }
                field(Coupled; Rec.Coupled)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of records that were coupled by matching an existing entity during the integration synchronization job.';
                    Visible = CouplingSpecificColumnsVisible;
                }
                field(Inserted; Rec.Inserted)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of new records that were created in the destination database table (such as the Dynamics 365 Sales Account entity or Business Central Customer table) by the integration synchronization job.';
                    Visible = SynchSpecificColumnsVisible;

                    trigger OnDrillDown()
                    var
                        IntegrationTableMapping: Record "Integration Table Mapping";
                        LocalRecordRef: RecordRef;
                        VarLocalRecordRef: Variant;
                    begin
                        if Rec."Synch. Direction" <> Rec."Synch. Direction"::FromIntegrationTable then
                            exit;

                        if Rec.Inserted = 0 then
                            exit;

                        if not IntegrationTableMapping.Get(Rec."Integration Table Mapping Name") then
                            exit;

                        if IntegrationTableMapping."Table ID" = 0 then
                            exit;

                        LocalRecordRef.Open(IntegrationTableMapping."Table ID");
                        LocalRecordRef.Field(LocalRecordRef.SystemCreatedAtNo()).SetRange(Rec."Start Date/Time", Rec."Finish Date/Time");
                        if not LocalRecordRef.IsEmpty() then begin
                            VarLocalRecordRef := LocalRecordRef;
                            PAGE.Run(0, VarLocalRecordRef);
                        end;
                    end;

                }
                field(Modified; Rec.Modified)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of records that were modified in the destination database table (such as the Dynamics 365 Sales Account entity or Dynamics 365 Customer table) by the integration synchronization job.';
                }
                field(Deleted; Rec.Deleted)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies entries that were deleted when synchronizing Dynamics 365 Sales data and Dynamics 365 data.';
                    Visible = SynchSpecificColumnsVisible;
                }
                field(Unchanged; Rec.Unchanged)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of records that were not changed in the destination database table (such as the Dynamics 365 Sales Account entity or Dynamics 365 Customer table) by the integration synchronization job.';
                    Visible = SynchSpecificColumnsVisible;
                }
                field(Failed; Rec.Failed)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of errors that occurred during the integration synchronization job.';

                    trigger OnDrillDown()
                    var
                        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
                    begin
                        IntegrationSynchJobErrors.SetCurrentKey("Date/Time", "Integration Synch. Job ID");
                        IntegrationSynchJobErrors.Ascending := false;

                        IntegrationSynchJobErrors.FilterGroup(2);
                        IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", Rec.ID);
                        IntegrationSynchJobErrors.FilterGroup(0);

                        IntegrationSynchJobErrors.FindFirst();
                        PAGE.Run(PAGE::"Integration Synch. Error List", IntegrationSynchJobErrors);
                    end;
                }
                field(Skipped; Rec.Skipped)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of records that were skipped during the integration synchronization job.';

                    trigger OnDrillDown()
                    var
                        IntegrationTableMapping: Record "Integration Table Mapping";
                        CRMIntegrationRecord: Record "CRM Integration Record";
                        CRMSkippedRecords: Page "CRM Skipped Records";
                    begin
                        if IntegrationTableMapping.Get(Rec."Integration Table Mapping Name") then begin
                            CRMIntegrationRecord.SetRange("Table ID", IntegrationTableMapping."Table ID");
                            CRMIntegrationRecord.SetRange(Skipped, true);
                            if CRMIntegrationRecord.FindFirst() then begin
                                CRMSkippedRecords.SetRecords(CRMIntegrationRecord);
                                CRMSkippedRecords.Run();
                            end;
                        end;
                    end;
                }
                field("Synch. Direction"; Rec."Synch. Direction")
                {
                    ApplicationArea = Suite;
                    Caption = 'Synch. Direction';
                    ToolTip = 'Specifies in which direction data is synchronized.';
                    Visible = false;
                }
                field(Direction; SynchDirection)
                {
                    ApplicationArea = Suite;
                    Caption = 'Direction';
                    ToolTip = 'Specifies in which direction data is synchronized.';
                    Visible = SynchSpecificColumnsVisible;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Suite;
                    Caption = 'Type';
                    ToolTip = 'Specifies the type of the integration synchronization job.';
                    Visible = SynchSpecificColumnsVisible and UncouplingSpecificColumnsVisible and CouplingSpecificColumnsVisible;
                }
                field(Message; Rec.Message)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a message that occurred as a result of the integration synchronization job.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Delete7days)
            {
                ApplicationArea = Suite;
                Caption = 'Delete Entries Older Than 7 Days';
                Enabled = HasRecords;
                Image = ClearLog;
                ToolTip = 'Delete log information for job queue entries that are older than seven days.';

                trigger OnAction()
                begin
                    Rec.DeleteEntries(7);
                end;
            }
            action(Delete0days)
            {
                ApplicationArea = Suite;
                Caption = 'Delete All Entries';
                Enabled = HasRecords;
                Image = Delete;
                ToolTip = 'Delete all error log information for job queue entries.';

                trigger OnAction()
                begin
                    Rec.DeleteEntries(0);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Delete7days_Promoted; Delete7days)
                {
                }
                actionref(Delete0days_Promoted; Delete0days)
                {
                }
            }
        }
    }

    trigger OnInit()
    var
        TempIntegrationSynchJob: Record "Integration Synch. Job" temporary;
        JobTypeFilter: Text;
    begin
        JobTypeFilter := Rec.GetFilter(Type);
        if JobTypeFilter <> '' then begin
            TempIntegrationSynchJob.SetRange(Type, TempIntegrationSynchJob.Type::Uncoupling);
            UncouplingSpecificColumnsVisible := Rec.GetFilter(Type) = TempIntegrationSynchJob.GetFilter(Type);
            TempIntegrationSynchJob.SetRange(Type, TempIntegrationSynchJob.Type::Coupling);
            CouplingSpecificColumnsVisible := Rec.GetFilter(Type) = TempIntegrationSynchJob.GetFilter(Type);
            SynchSpecificColumnsVisible := (not UncouplingSpecificColumnsVisible) and (not CouplingSpecificColumnsVisible);
            if UncouplingSpecificColumnsVisible then
                CurrPage.Caption(IntegrationUncouplingJobsCaptionTxt);
            if CouplingSpecificColumnsVisible then
                CurrPage.Caption(IntegrationCouplingJobsCaptionTxt);
        end else begin
            UncouplingSpecificColumnsVisible := true;
            CouplingSpecificColumnsVisible := true;
            SynchSpecificColumnsVisible := true;
        end;
    end;

    trigger OnAfterGetRecord()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        TableMetadata: Record "Table Metadata";
    begin
        SynchDirection := '';
        if IntegrationTableMapping.Get(Rec."Integration Table Mapping Name") then begin
            TableMetadata.Get(IntegrationTableMapping."Table ID");
            if not (Rec.Type in [Rec.Type::Uncoupling, Rec.Type::Coupling]) then
                if Rec."Synch. Direction" = Rec."Synch. Direction"::ToIntegrationTable then
                    SynchDirection :=
                      StrSubstNo(SynchDirectionTxt, TableMetadata.Caption, IntegrationTableMapping.GetExtendedIntegrationTableCaption())
                else
                    SynchDirection :=
                      StrSubstNo(SynchDirectionTxt, IntegrationTableMapping.GetExtendedIntegrationTableCaption(), TableMetadata.Caption);
        end;
        DoHideDuration := Rec."Finish Date/Time" < Rec."Start Date/Time";
        if DoHideDuration then
            Clear(Duration)
        else
            Duration := Rec."Finish Date/Time" - Rec."Start Date/Time";

        HasRecords := not Rec.IsEmpty();
    end;

    var
        SynchDirectionTxt: Label '%1 to %2.', Comment = '%1 = Source table caption, %2 = Destination table caption';
        IntegrationUncouplingJobsCaptionTxt: Label 'Integration Uncoupling Jobs';
        IntegrationCouplingJobsCaptionTxt: Label 'Integration Coupling Jobs';
        SynchDirection: Text;
        DoHideDuration: Boolean;
        Duration: Duration;
        HasRecords: Boolean;
        CouplingSpecificColumnsVisible: Boolean;
        UncouplingSpecificColumnsVisible: Boolean;
        SynchSpecificColumnsVisible: Boolean;
}

