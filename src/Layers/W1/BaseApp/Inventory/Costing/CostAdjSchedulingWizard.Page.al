// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using System.Environment;
using System.Threading;

page 2875 "Cost Adj. Scheduling Wizard"
{
    PageType = NavigatePage;
    Extensible = false;
    Caption = 'Schedule Cost Adjustment and Posting';

    layout
    {
        area(Content)
        {
            group(Done)
            {
                ShowCaption = false;
                Visible = TopBannerVisible and DoneVisible;

                field(NotDoneIcon; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(NotDone)
            {
                ShowCaption = false;
                Visible = TopBannerVisible and not DoneVisible;

                field(DoneIcon; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
            }

            group(Welcome)
            {
                ShowCaption = false;
                Visible = Step = Step::Welcome;

                group("Welcome to Schedule Cost Adjustment and Posting setup guide")
                {
                    Caption = 'Welcome to the Schedule Cost Adjustment and Posting setup guide';
                    InstructionalText = 'Optimize performance by creating and scheduling job queue entries to run in the background for inventory cost adjustments and posting. Background job queue entries do not affect the work you’re doing in the foreground and run on the schedule you specify.';
                }
                group("Let's go!")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next to choose the job queue entry to create.';
                }
            }
            group(Selection)
            {
                ShowCaption = false;
                Visible = Step = Step::Selection;

                group(ChoseEntries)
                {
                    Caption = 'Choose the job queue entry to create.​';

                    field(CreatePostToGLSchedule; CreatePostInvCostToGLSchedule)
                    {
                        ApplicationArea = All;
                        Caption = 'Post Inventory Cost to G/L​​';
                        ToolTip = 'Create a job queue entry that will post costs for all items at a specified time. For example, outside working hours. The default will be 2 AM, but you can change that.';
                        Enabled = PostInvCostToGLOptionEnabled;

                        trigger OnValidate()
                        begin
                            UpdateViewState();
                        end;
                    }

                    field(CreateCostAdjSchedule; CreateAdjCostSchedule)
                    {
                        ApplicationArea = All;
                        Caption = 'Adjust Cost – Item Entries​';
                        ToolTip = 'Create a job queue entry that will adjust costs for all items at a specified time. For example, outside working hours. The default will be 1 AM, but you can change that.';
                        Enabled = AdjCostOptionEnabled;

                        trigger OnValidate()
                        begin
                            UpdateViewState();
                        end;
                    }

                    group(ExistingJobQueueHelperText)
                    {
                        Visible = not AdjCostOptionEnabled or not PostInvCostToGLOptionEnabled;
                        Caption = 'One, or both, of the job queue entries already exist';
                        InstructionalText = 'If a toggle is not available for a job queue entry above, it already exists. You can edit, delete, and replace job queue entries on the Job Queue Entries page.';
                    }
                }
            }
            group(Finish)
            {
                ShowCaption = false;
                Visible = Step = Step::Finish;

                group("That's it!")
                {
                    Caption = 'That''s it!';
                    InstructionalText = 'You are about to create and schedule the job queue entries to run at the default times. You can edit the schedule on the Job Queue Entries page afterward.';

                    group(PostToGLSchedule)
                    {
                        Visible = CreatePostInvCostToGLSchedule;
                        Caption = 'Post Inventory Cost to G/L';
                        InstructionalText = 'Scheduled to run every day at 2 AM.';
                    }

                    group(CostAdjSchedule)
                    {
                        Visible = CreateAdjCostSchedule;
                        Caption = 'Adjust Cost - Item Entries';
                        InstructionalText = 'Scheduled to run every day at 1 AM.';
                    }
                }

                group(OpenAfterFinishGroup)
                {
                    ShowCaption = false;

                    field(OpenJobQueueListAfterFinish; OpenJobQueueListAfterFinish)
                    {
                        ApplicationArea = All;
                        Caption = 'View the job queue entries when finished.';
                        ToolTip = 'Open the Job Queue Entries page to view and edit details for job queue entries when you choose Finish.';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionBack)
            {
                ApplicationArea = All;
                Caption = 'Back';
                InFooterBar = true;
                Image = PreviousRecord;
                Enabled = PrevButtonEnabled;

                trigger OnAction()
                begin
                    Step := Step - 1;
                    UpdateViewState();
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                InFooterBar = true;
                Image = NextRecord;
                Enabled = NextButtonEnabled;

                trigger OnAction()
                begin
                    Step := Step + 1;
                    UpdateViewState();
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                InFooterBar = true;
                Image = NextRecord;
                Enabled = FinishButtonEnabled;

                trigger OnAction()
                begin
                    OnFinish();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();

        // Check if there is an existing schedule for each type. We do not support disabling of the schedule.
        AdjCostOptionEnabled := not SchedulingManager.AdjCostJobQueueExists();
        PostInvCostToGLOptionEnabled := not SchedulingManager.PostInvCostToGLJobQueueExists();

        Step := Step::Welcome;
        UpdateViewState();
    end;

    local procedure LoadTopBanners()
    begin
        if MediaResourcesStandard.Get('ASSISTEDSETUP-NOTEXT-400PX.PNG') and
            MediaResourcesDone.Get('ASSISTEDSETUPDONE-NOTEXT-400PX.PNG') and (CurrentClientType() = ClientType::Web)
        then
            TopBannerVisible := MediaResourcesDone."Media Reference".HasValue();
    end;

    local procedure UpdateViewState()
    begin
        case Step of
            Step::Welcome:
                begin
                    PrevButtonEnabled := false;
                    NextButtonEnabled := true;
                    FinishButtonEnabled := false;
                    DoneVisible := false;
                end;

            Step::Selection:
                begin
                    PrevButtonEnabled := true;
                    NextButtonEnabled := CreateAdjCostSchedule or CreatePostInvCostToGLSchedule;
                    FinishButtonEnabled := false;
                    DoneVisible := false;
                end;

            Step::Finish:
                begin
                    PrevButtonEnabled := true;
                    NextButtonEnabled := false;
                    FinishButtonEnabled := true;
                    DoneVisible := true;
                    CurrPage.Update(false);
                end;
        end;
    end;

    local procedure OnFinish()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CurrPage.Close();

        if CreateAdjCostSchedule then
            SchedulingManager.CreateAdjCostJobQueue();

        if CreatePostInvCostToGLSchedule then
            SchedulingManager.CreatePostInvCostToGLJobQueue();

        if OpenJobQueueListAfterFinish then begin
            SchedulingManager.SetupDisplayJobQueueEntriesFilter(JobQueueEntry);
            Page.Run(Page::"Job Queue Entries", JobQueueEntry);
        end;
    end;

    var
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        SchedulingManager: Codeunit "Cost Adj. Scheduling Manager";
        Step: Option Welcome,Selection,Finish;
        TopBannerVisible: Boolean;
        DoneVisible: Boolean;
        PrevButtonEnabled: Boolean;
        NextButtonEnabled: Boolean;
        FinishButtonEnabled: Boolean;
        AdjCostOptionEnabled: Boolean;
        CreateAdjCostSchedule: Boolean;
        PostInvCostToGLOptionEnabled: Boolean;
        CreatePostInvCostToGLSchedule: Boolean;
        OpenJobQueueListAfterFinish: Boolean;
}
