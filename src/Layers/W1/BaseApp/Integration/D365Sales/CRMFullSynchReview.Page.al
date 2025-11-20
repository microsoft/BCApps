// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;

page 5331 "CRM Full Synch. Review"
{
    Caption = 'Dataverse Full Synch. Review';
    PageType = Worksheet;
    SourceTable = "CRM Full Synch. Review Line";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Editable = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name.';
                }
                field("Dependency Filter"; Rec."Dependency Filter")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a dependency to the synchronization of another record, such as a customer that must be synchronized before a contact can be synchronized.';
                    Visible = false;
                }
                field("Job Queue Entry Status"; Rec."Job Queue Entry Status")
                {
                    ApplicationArea = Suite;
                    StyleExpr = JobQueueEntryStatusStyle;
                    ToolTip = 'Specifies the status of the job queue entry.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowJobQueueLogEntry();
                    end;
                }
                field(ActiveSession; Rec.IsActiveSession())
                {
                    ApplicationArea = Suite;
                    Caption = 'Active Session';
                    ToolTip = 'Specifies whether the session is active.';
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the synchronization direction.';
                }
                field("To Int. Table Job Status"; Rec."To Int. Table Job Status")
                {
                    ApplicationArea = Suite;
                    StyleExpr = ToIntTableJobStatusStyle;
                    ToolTip = 'Specifies the status of jobs for data going to the integration table. ';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowSynchJobLog(Rec."To Int. Table Job ID");
                    end;
                }
                field("From Int. Table Job Status"; Rec."From Int. Table Job Status")
                {
                    ApplicationArea = Suite;
                    StyleExpr = FromIntTableJobStatusStyle;
                    ToolTip = 'Specifies the status of jobs for data coming from the integration table. ';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowSynchJobLog(Rec."From Int. Table Job ID");
                    end;
                }
                field("Initial Synchronization Recommendation"; InitialSynchRecommendation)
                {
                    Caption = 'Recommendation';
                    ApplicationArea = Suite;
                    Enabled = SynchRecommendationDrillDownEnabled;
                    StyleExpr = InitialSynchRecommendationStyle;
                    ToolTip = 'Specifies the recommended action for the initial synchronization.';

                    trigger OnDrillDown()
                    var
                        IntegrationFieldMapping: Record "Integration Field Mapping";
                        IntegrationTableMapping: Record "Integration Table Mapping";
                    begin
                        if not (InitialSynchRecommendation in [MatchBasedCouplingTxt, CouplingCriteriaSelectedTxt]) then
                            exit;

                        if not IntegrationTableMapping.Get(Rec.Name) then
                            exit;

                        IntegrationFieldMapping.SetMatchBasedCouplingFilters(IntegrationTableMapping);
                        if Page.RunModal(Page::"Match Based Coupling Criteria", IntegrationFieldMapping) = Action::LookupOK then
                            CurrPage.Update(false);
                    end;
                }
                field("Multi Company Synch. Enabled"; Rec."Multi Company Synch. Enabled")
                {
                    ApplicationArea = Suite;
                    Visible = MultiCompanyCheckboxEnabled;
                    ToolTip = 'Specifies if the multi-company synchronization should be enabled for the corresponding integration table mapping.';

                    trigger OnValidate()
                    begin
                        Message(ResetToApplyTxt);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Start)
            {
                ApplicationArea = Suite;
                Caption = 'Sync All';
                Enabled = ActionStartEnabled;
                Image = Start;
                ToolTip = 'Start all the default integration projects for synchronizing Business Central record types and Dataverse entities, as defined on the Integration Table Mappings page. Mappings with finished project status will be skipped.';

                trigger OnAction()
                var
                    CDSConnectionSetup: Record "CDS Connection Setup";
                    CRMSynchHelper: Codeunit "CRM Synch. Helper";
                    OwnershipModel: Option;
                    handled: Boolean;
                    QuestionTxt: Text;
                begin
                    CRMSynchHelper.OnGetCDSOwnershipModel(OwnershipModel, handled);
                    if handled and (OwnershipModel = CDSConnectionSetup."Ownership Model"::Team) then
                        QuestionTxt := StartInitialSynchTeamOwnershipModelQst
                    else
                        QuestionTxt := StrSubstNo(StartInitialSynchPersonOwnershipModelQst, PRODUCTNAME.Short(), CRMProductName.CDSServiceName());
                    if Confirm(QuestionTxt) then
                        Rec.Start();
                end;
            }
            action(Restart)
            {
                ApplicationArea = Suite;
                Caption = 'Restart';
                Enabled = ActionRestartEnabled;
                Image = Refresh;
                ToolTip = 'Restart the integration project for synchronizing Business Central record types and Dataverse entities, as defined on the Integration Table Mappings page.';
                trigger OnAction()
                begin
                    Rec.Delete();
                    Rec.Generate(InitialSynchRecommendations, DeletedLines);
                    Rec.Start();
                end;
            }
            action(Reset)
            {
                ApplicationArea = Suite;
                Caption = 'Reset';
                Enabled = ActionResetEnabled;
                Image = ResetStatus;
                ToolTip = 'Removes all lines, readds all Integration Table Mappings and recalculates synchronization recommendations.';
                trigger OnAction()
                begin
                    Rec.DeleteAll();
                    Clear(InitialSynchRecommendations);
                    Clear(DeletedLines);
                    Rec.Generate();
                end;
            }
            action(ScheduleFullSynch)
            {
                ApplicationArea = Suite;
                Caption = 'Recommend Full Synchronization';
                Enabled = ActionRecommendFullSynchEnabled;
                Image = RefreshLines;
                ToolTip = 'Recommend full synchronization job for the selected line.';

                trigger OnAction()
                begin
                    if InitialSynchRecommendations.ContainsKey(Rec.Name) then
                        InitialSynchRecommendations.Remove(Rec.Name);
                    InitialSynchRecommendations.Add(Rec.Name, Rec."Initial Synch Recommendation"::"Full Synchronization");
                    Rec.Delete();
                    Rec.Generate(InitialSynchRecommendations, DeletedLines);
                end;
            }
            action(ToggleMultiCompany)
            {
                ApplicationArea = Suite;
                Caption = 'Toggle Multi-Company Synchronization';
                Visible = MultiCompanyCheckboxEnabled;
                Image = ToggleBreakpoint;
                ToolTip = 'Toggle multi-company synchronization for this table mapping.';

                trigger OnAction()
                var
                    IntegrationTableMapping: Record "Integration Table Mapping";
                begin
                    Rec.Validate("Multi Company Synch. Enabled", (not Rec."Multi Company Synch. Enabled"));
                    Commit();

                    if InitialSynchRecommendations.ContainsKey(Rec.Name) then
                        InitialSynchRecommendations.Remove(Rec.Name);

                    IntegrationTableMapping.Get(Rec.Name);
                    InitialSynchRecommendations.Add(Rec.Name, Rec.GetInitialSynchRecommendation(IntegrationTableMapping, InitialSynchRecommendations));
                    Rec.Delete();
                    Rec.Generate(InitialSynchRecommendations, DeletedLines);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Start_Promoted; Start)
                {
                }
                actionref(Restart_Promoted; Restart)
                {
                }
                actionref(Reset_Promoted; Reset)
                {
                }
                actionref(ScheduleFullSynch_Promoted; ScheduleFullSynch)
                {
                }
                actionref(ToggleMultiCompany_Promoted; ToggleMultiCompany)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        ActionStartEnabled := (not Rec.IsThereActiveSessionInProgress()) and Rec.IsThereBlankStatusLine();
        ActionResetEnabled := (not Rec.IsThereActiveSessionInProgress());
        ActionRestartEnabled := (not Rec.IsThereActiveSessionInProgress()) and ((Rec."Job Queue Entry Status" = Rec."Job Queue Entry Status"::Error) or (Rec."Job Queue Entry Status" = Rec."Job Queue Entry Status"::Finished));
        ActionRecommendFullSynchEnabled := ActionResetEnabled and (Rec."Initial Synch Recommendation" = Rec."Initial Synch Recommendation"::"Couple Records");
        JobQueueEntryStatusStyle := Rec.GetStatusStyleExpression(Format(Rec."Job Queue Entry Status"));
        ToIntTableJobStatusStyle := Rec.GetStatusStyleExpression(Format(Rec."To Int. Table Job Status"));
        FromIntTableJobStatusStyle := Rec.GetStatusStyleExpression(Format(Rec."From Int. Table Job Status"));
        if not InitialSynchRecommendations.ContainsKey(Rec.Name) then
            InitialSynchRecommendations.Add(Rec.Name, Rec."Initial Synch Recommendation");

        if Rec."Initial Synch Recommendation" <> Rec."Initial Synch Recommendation"::"Couple Records" then
            InitialSynchRecommendation := Format(Rec."Initial Synch Recommendation")
        else begin
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", Rec.Name);
            IntegrationFieldMapping.SetRange("Use For Match-Based Coupling", true);
            if IntegrationFieldMapping.IsEmpty() then
                InitialSynchRecommendation := MatchBasedCouplingTxt
            else
                InitialSynchRecommendation := CouplingCriteriaSelectedTxt
        end;
        if InitialSynchRecommendation = CouplingCriteriaSelectedTxt then
            InitialSynchRecommendationStyle := 'Favorable'
        else
            InitialSynchRecommendationStyle := Rec.GetInitialSynchRecommendationStyleExpression(Format(Rec."Initial Synch Recommendation"));
        SynchRecommendationDrillDownEnabled := (InitialSynchRecommendation in [MatchBasedCouplingTxt, CouplingCriteriaSelectedTxt]);
    end;

    trigger OnOpenPage()
    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
    begin
        Clear(DeletedLines);
        Rec.Generate(SkipEntitiesNotFullSyncReady);
        MultiCompanyCheckboxEnabled := CDSIntegrationImpl.MultipleCompaniesConnected();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        DeletedLines.Add(Rec.Name);
    end;

    [Scope('OnPrem')]
    procedure SetSkipEntitiesNotFullSyncReady()
    begin
        SkipEntitiesNotFullSyncReady := true;
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";
        ActionStartEnabled: Boolean;
        ActionResetEnabled: Boolean;
        ActionRestartEnabled: Boolean;
        ActionRecommendFullSynchEnabled: Boolean;
        SkipEntitiesNotFullSyncReady: Boolean;
        SynchRecommendationDrillDownEnabled: Boolean;
        MultiCompanyCheckboxEnabled: Boolean;
        InitialSynchRecommendations: Dictionary of [Code[20], Integer];
        DeletedLines: List of [Code[20]];
        JobQueueEntryStatusStyle: Text;
        ToIntTableJobStatusStyle: Text;
        FromIntTableJobStatusStyle: Text;
        StartInitialSynchPersonOwnershipModelQst: Label 'Full synchronization will synchronize all coupled and uncoupled records.\You should use this option only when you are synchronizing data for the first time.\The synchronization will run in the background, so you can continue with other tasks.\To check the status, return to this page or refresh it.\\Before running full synchronization, you should couple all %1 salespeople to %2 users.\\Do you want to continue?', Comment = '%1 - product name, %2 = Dataverse service name';
        StartInitialSynchTeamOwnershipModelQst: Label 'Full synchronization will synchronize all coupled and uncoupled records.\You should use this option only when you are synchronizing data for the first time.\The synchronization will run in the background, so you can continue with other tasks.\To check the status, return to this page or refresh it.\\Do you want to continue?';
        InitialSynchRecommendation: Text;
        InitialSynchRecommendationStyle: Text;
        MatchBasedCouplingTxt: Label 'Select Coupling Criteria';
        CouplingCriteriaSelectedTxt: Label 'Review Selected Coupling Criteria';
        ResetToApplyTxt: Label 'Choose action ''Reset'' to apply the change.';
}

