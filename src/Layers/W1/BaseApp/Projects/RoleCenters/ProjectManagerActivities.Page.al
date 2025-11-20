// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.RoleCenters;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Setup;
using Microsoft.Projects.Project.WIP;
using System;
using System.Environment;
using System.Visualization;
#if not CLEAN25
using Microsoft.Integration.SyncEngine;
using Microsoft.Integration.Dataverse;
#endif

page 9068 "Project Manager Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "Job Cue";

    layout
    {
        area(content)
        {
            cuegroup(Invoicing)
            {
                Caption = 'Invoicing';
                Visible = SetupIsComplete;
                field("Upcoming Invoices"; Rec."Upcoming Invoices")
                {
                    ApplicationArea = Jobs;
                    DrillDownPageID = "Job List";
                    ToolTip = 'Specifies the number of upcoming invoices that are displayed in the Project Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Invoices Due - Not Created"; Rec."Invoices Due - Not Created")
                {
                    ApplicationArea = Jobs;
                    DrillDownPageID = "Job List";
                    ToolTip = 'Specifies the number of invoices that are due but not yet created that are displayed in the Project Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("Job Create Sales Invoice")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project Create Sales Invoice';
                        RunObject = Report "Job Create Sales Invoice";
                        ToolTip = 'Create an invoice for a project or for one or more project tasks for a customer when either the work to be invoiced is complete or the date for invoicing based on an invoicing schedule has been reached.';
                    }
                }
            }
            cuegroup("Work in Process")
            {
                Caption = 'Work in Process';
                Visible = SetupIsComplete;
                field("WIP Not Posted"; Rec."WIP Not Posted")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Job List";
                    ToolTip = 'Specifies the amount of work in process that has not been posted that is displayed in the Service Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Completed - WIP Not Calculated"; Rec."Completed - WIP Not Calculated")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Job List";
                    ToolTip = 'Specifies the total of work in process that is complete but not calculated that is displayed in the Project Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("Update Job Item Cost")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Update Project Item Cost';
                        RunObject = Report "Update Job Item Cost";
                        ToolTip = 'Update the usage costs in the project ledger entries to match the actual costs in the item ledger entry. If adjustment value entries have a different date than the original value entry, such as when the inventory period is closed, then the project ledger is not updated.';
                    }
                    action("<Action15>")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project WIP Cockpit';
                        RunObject = Page "Job WIP Cockpit";
                        ToolTip = 'Get an overview of work in process (WIP). The Project WIP Cockpit is the central location to track WIP for all of your projects. Each line contains information about a project, including calculated and posted WIP.';
                    }
                }
            }
            cuegroup("Jobs to Budget")
            {
                Caption = 'Projects to Budget';
                Visible = SetupIsComplete;
                field("Jobs Over Budget"; Rec."Jobs Over Budget")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Over Budget';
                    DrillDownPageID = "Job List";
                    Editable = false;
                    ToolTip = 'Specifies the number of projects where the usage cost exceeds the budgeted cost.';
                }
            }
            cuegroup("Get started")
            {
                Caption = 'Get started';
                Visible = ReplayGettingStartedVisible;

                actions
                {
                    action(ShowStartInMyCompany)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Try with my own data';
                        Image = TileSettings;
                        ToolTip = 'Set up My Company with the settings you choose. We''ll show you how, it''s easy.';
                        Visible = false;

                        trigger OnAction()
                        begin
                            if UserTours.IsAvailable() and O365GettingStartedMgt.AreUserToursEnabled() then
                                UserTours.StartUserTour(O365GettingStartedMgt.GetChangeCompanyTourID());
                        end;
                    }
                    action(ReplayGettingStarted)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replay Getting Started';
                        Image = TileVideo;
                        ToolTip = 'Show the Getting Started guide again.';

                        trigger OnAction()
                        var
                            O365GettingStarted: Record "O365 Getting Started";
                        begin
                            if O365GettingStarted.Get(UserId, ClientTypeManagement.GetCurrentClientType()) then begin
                                O365GettingStarted."Tour in Progress" := false;
                                O365GettingStarted."Current Page" := 1;
                                O365GettingStarted.Modify();
                                Commit();
                            end;

                            O365GettingStartedMgt.LaunchWizard(true, false);
                        end;
                    }
                }
            }
            cuegroup(Jobs)
            {
                Caption = 'Projects';
                Visible = not SetupIsComplete;

                actions
                {
                    action("<PageJobSetup>")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Set Up Projects';
                        Image = TileSettings;
                        RunObject = Page "Jobs Setup Wizard";
                        RunPageMode = Create;
                        ToolTip = 'Open the assisted setup guide to set up how you want to use projects.';
                    }
                }
            }
#if not CLEAN25
            cuegroup("Data Integration")
            {
                Caption = 'Data Integration';
                Visible = false;
                ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                ObsoleteState = Pending;
                ObsoleteTag = '25.0';

                field("CDS Integration Errors"; Rec."FS Integration Errors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Integration Errors';
                    DrillDownPageID = "Integration Synch. Error List";
                    ToolTip = 'Specifies the number of errors related to data integration with Dynamics 365 Field Service.';
                    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';
                }
                field("Coupled Data Synch Errors"; Rec."Coupled Data Synch Errors")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Coupled Data Synchronization Errors';
                    DrillDownPageID = "CRM Skipped Records";
                    ToolTip = 'Specifies the number of errors that occurred in the latest synchronization of coupled data between Business Central and Dynamics 365 Field Service.';
                    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';
                }
            }
#endif
        }
    }

    actions
    {
        area(processing)
        {
            action("Set Up Cues")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Up Cues';
                Image = Setup;
                ToolTip = 'Set up the cues (status tiles) related to the role.';

                trigger OnAction()
                var
                    CueRecordRef: RecordRef;
                begin
                    CueRecordRef.GetTable(Rec);
                    CuesAndKpis.OpenCustomizePageForCurrentUser(CueRecordRef.Number);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        O365GettingStartedMgt.UpdateGettingStartedVisible(TileGettingStartedVisible, ReplayGettingStartedVisible);
    end;

    trigger OnInit()
    var
        JobsSetup: Record "Jobs Setup";
        MyCompName: Text;
    begin
        O365GettingStartedMgt.UpdateGettingStartedVisible(TileGettingStartedVisible, ReplayGettingStartedVisible);

        SetupIsComplete := false;

        MyCompName := CompanyName;

        if JobsSetup.FindFirst() then
            if MyCompName = MyCompanyTxt then
                SetupIsComplete := JobsSetup."Default Job Posting Group" <> ''
            else
                SetupIsComplete := JobsSetup."Job Nos." <> '';

        OnAfterInit(SetupIsComplete);
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.SetFilter("Date Filter", '>=%1', WorkDate());
        Rec.SetFilter("Date Filter2", '<%1&<>%2', WorkDate(), 0D);
        Rec.SetRange("User ID Filter", UserId());

        ShowIntelligentCloud := not EnvironmentInfo.IsSaaS();
    end;

    var
        CuesAndKpis: Codeunit "Cues And KPIs";
        O365GettingStartedMgt: Codeunit "O365 Getting Started Mgt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        EnvironmentInfo: Codeunit "Environment Information";
        [RunOnClient]
        [WithEvents]
        UserTours: DotNet UserTours;
        ReplayGettingStartedVisible: Boolean;
        TileGettingStartedVisible: Boolean;
        SetupIsComplete: Boolean;
        MyCompanyTxt: Label 'My Company';
        ShowIntelligentCloud: Boolean;

    procedure RefreshRoleCenter()
    begin
        CurrPage.Update();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInit(var SetupIsComplete: Boolean)
    begin
    end;

    trigger UserTours::ShowTourWizard(hasTourCompleted: Boolean)
    begin
    end;

    trigger UserTours::IsTourInProgressResultReady(isInProgress: Boolean)
    begin
    end;
}

