// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Setup;

using Microsoft.Foundation.NoSeries;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Projects.TimeSheet;
using System.Environment;
using System.Security.User;
using System.Utilities;

page 1824 "Jobs Setup Wizard"
{
    Caption = 'Projects Setup';
    DelayedInsert = true;
    PageType = NavigatePage;
    SourceTable = "Jobs Setup";

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not FinalStepVisible;
#pragma warning disable AA0100
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and FinalStepVisible;
#pragma warning disable AA0100
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control5)
            {
                ShowCaption = false;
                Visible = WelcomeStepVisible;
                group("Welcome to Jobs Setup")
                {
                    Caption = 'Welcome to Projects Setup';
                    InstructionalText = 'You can use projects to track costs such as time sheets that you can then charge to your customer. Choose between many reports to track your project''s profitability.';
                    Visible = WelcomeStepVisible;
                }
                group("Let's Go!")
                {
                    Caption = 'Let''s Go!';
                    InstructionalText = 'Choose Next so you can start the setup.';
                }
            }
            group(Control25)
            {
                ShowCaption = false;
                Visible = NoSeriesStepVisible;
                group(NumberSeriesHelpMessage)
                {
                    Caption = 'Number series are used to group projects with consecutive IDs. Please specify the number series that you want to use for the different types of project.';
                    Visible = NoSeriesStepVisible;
                    field(NoSeriesJob; NoSeriesJob)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Projects No Series:';
                        TableRelation = "No. Series".Code;

                        trigger OnValidate()
                        begin
                            if not NoSeries.Get(NoSeriesJob) then begin
                                Message(ValueNotExistMsg, JobsSetup.FieldName("Job Nos."));
                                NoSeriesJob := ''
                            end
                        end;
                    }
                    field(NoSeriesResource; NoSeriesResource)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource No Series:';
                        TableRelation = "No. Series".Code;

                        trigger OnValidate()
                        begin
                            if not NoSeries.Get(NoSeriesResource) then begin
                                Message(ValueNotExistMsg, ResourcesSetup.FieldName("Resource Nos."));
                                NoSeriesResource := ''
                            end
                        end;
                    }
                    field(NoSeriesTimeSheet; NoSeriesTimeSheet)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Time Sheet No Series:';
                        TableRelation = "No. Series".Code;

                        trigger OnValidate()
                        begin
                            if not NoSeries.Get(NoSeriesTimeSheet) then begin
                                Message(ValueNotExistMsg, ResourcesSetup.FieldName("Time Sheet Nos."));
                                NoSeriesTimeSheet := ''
                            end
                        end;
                    }
                    field(NoSeriesJobWIP; NoSeriesJobWIP)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project-WIP No Series:';
                        TableRelation = "No. Series".Code;

                        trigger OnValidate()
                        begin
                            if not NoSeries.Get(NoSeriesTimeSheet) then begin
                                Message(ValueNotExistMsg, JobsSetup.FieldName("Job WIP Nos."));
                                NoSeriesJobWIP := ''
                            end
                        end;
                    }
                }
            }
            group(Control7)
            {
                ShowCaption = false;
                Visible = PostWIPStepVisible;
                group("Specify the default posting group and WIP method.")
                {
                    Caption = 'Specify the default posting group and WIP method.';
                    InstructionalText = 'Specify the default accounts that will be used to post to for projects. The information is used when you create a new project, but you can change that for each project.';
                    Visible = PostWIPStepVisible;
                    field(DefaultJobPostingGroup; DefaultJobPostingGroup)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Default Project Posting Group';
                        TableRelation = "Job Posting Group".Code;

                        trigger OnValidate()
                        var
                            JobPostingGroup: Record "Job Posting Group";
                        begin
                            if not JobPostingGroup.Get(DefaultJobPostingGroup) then begin
                                Message(ValueNotExistMsg, JobsSetup.FieldName("Default Job Posting Group"));
                                DefaultJobPostingGroup := ''
                            end
                        end;
                    }
                    group(Control26)
                    {
                        InstructionalText = 'Specify the default method to be used for calculating work in process (WIP). If you do not want to calculate WIP, choose Completed Contract.';
                        ShowCaption = false;
                        Visible = PostWIPStepVisible;
                    }
                    field(DefaultWIPMethod; DefaultWIPMethod)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Default WIP Method';
                        TableRelation = "Job WIP Method".Code;

                        trigger OnValidate()
                        var
                            JobWIPMethod: Record "Job WIP Method";
                        begin
                            if not JobWIPMethod.Get(DefaultWIPMethod) then begin
                                Message(ValueNotExistMsg, JobsSetup.FieldName("Default WIP Posting Method"));
                                DefaultWIPMethod := ''
                            end
                        end;
                    }
                }
            }
            group(Control16)
            {
                ShowCaption = false;
                Visible = AskTimeSheetStepVisible;
                group("Do you want to set up time sheets?")
                {
                    Caption = 'Do you want to set up time sheets?';
                    Visible = AskTimeSheetStepVisible;
                    group(Control41)
                    {
                        InstructionalText = 'To start setting up time sheets, choose Yes. First, you will set up at least one user and one resource. ';
                        ShowCaption = false;
                        Visible = AskTimeSheetStepVisible;
                        field(YesCheckbox; CreateTimesheetYes)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Yes';

                            trigger OnValidate()
                            begin
                                if CreateTimesheetYes then begin
                                    CreateTimesheetNo := false;
                                    Step := Step::ResourcesSetup;
                                end
                            end;
                        }
                    }
                    group(Control42)
                    {
                        InstructionalText = 'To finish, choose No. You can set up time sheets later in the Time Sheet Setup window.';
                        ShowCaption = false;
                        Visible = AskTimeSheetStepVisible;
                        field(NoCheckbox; CreateTimesheetNo)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'No';

                            trigger OnValidate()
                            begin
                                if CreateTimesheetNo then begin
                                    CreateTimesheetYes := false;
                                    Step := Step::Finish;
                                end
                            end;
                        }
                    }
                }
            }
            group(Control19)
            {
                ShowCaption = false;
                Visible = ResourcesSetupStepVisible;
                group("Set up time sheet options")
                {
                    Caption = 'Set up time sheet options';
                    Visible = ResourcesSetupStepVisible;
                    field(FirstWeekday; FirstWeekday)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Time Sheet First Weekday';
                        OptionCaption = 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';
                    }
                    field(SuiteJobApproval; SuiteJobApproval)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Time Sheet by Project Approval';
                        OptionCaption = 'Time Sheet Approver User ID,Machine Only,Person Responsible';
                    }
                }
                group(Control2)
                {
                    InstructionalText = 'The time sheet approver that is specified for the resource will approve time sheets.';
                    ShowCaption = false;
                    Visible = ResourcesSetupStepVisible;
                }
                group(Control30)
                {
                    InstructionalText = 'Machine Only - For machine time sheets that are linked to a project, the responsible person for the project will approve the time sheets. For machine time sheets that are linked to a resource, the time sheets are approved by the specified time sheet approver.';
                    ShowCaption = false;
                    Visible = ResourcesSetupStepVisible;
                }
                group(Control9)
                {
                    InstructionalText = 'The person who is specified as the responsible person for the project will approve time sheets.';
                    ShowCaption = false;
                    Visible = ResourcesSetupStepVisible;
                }
            }
            group(AddUsers)
            {
                Caption = 'Add Users';
                Visible = AddUsersVisible;
                group("Set up Users")
                {
                    Caption = 'Set up Users';
                    InstructionalText = 'Add one or more users that you want to be able to create or approve time sheets. You can add more later.';
                    Visible = AddUsersVisible;
                    part("Add one or more users"; "Time Sheet User Setup Subform")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Add one or more users';
                    }
                }
            }
            group(AddResources)
            {
                Caption = 'Add Resources';
                Visible = AddResourcesVisible;
                group("Set up Resources")
                {
                    Caption = 'Set up Resources';
                    InstructionalText = 'Add one or more resources that you want to be able to use time sheets. Assign time sheet approvers as well. You can add more later. Click Next to continue after adding resources.';
                    Visible = AddResourcesVisible;
                    field(ResourceNo; ResourceNo)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource No:';
                        TableRelation = Resource."No.";
                    }
                    field(ResourceName; ResourceName)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Name:';
                    }
                    field(ResourceType; ResourceType)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Type:';
                    }
                    field(ResourceUseTimeSheet; ResourceUseTimeSheet)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Use Time Sheets:';
                    }
                    field(ResourceTimeSheetOwnerID; ResourceTimeSheetOwnerID)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Time Sheet Owner User ID:';
                        TableRelation = "User Setup";
                    }
                    field(ResourceTimeSheetApproverID; ResourceTimeSheetApproverID)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Time Sheet Approver User ID:';
                        TableRelation = "User Setup";
                    }
                }
            }
            group(Control38)
            {
                ShowCaption = false;
                Visible = DoTimeSheetStepVisible;
                group("Create Time Sheets")
                {
                    Caption = 'Create Time Sheets';
                    InstructionalText = 'Click Next to create time sheets.';
                    Visible = DoTimeSheetStepVisible;
                }
            }
            group(Control8)
            {
                ShowCaption = false;
                Visible = FinalStepVisible;
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    group(Control4)
                    {
                        InstructionalText = 'You have now set things up so you can start creating projects.';
                        ShowCaption = false;
                    }
                    group(Control43)
                    {
                        InstructionalText = 'Let''s get started with your first job!';
                        ShowCaption = false;
                    }
                    group(Control46)
                    {
                        InstructionalText = 'Click Finish then refresh your role center to see the Projects activities.';
                        ShowCaption = false;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionAddResource)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Add';
                Enabled = AddResourcesActionEnabled;
                Image = Add;
                InFooterBar = true;
                Visible = AddResourcesVisible;

                trigger OnAction()
                begin
                    AddResourceAction();
                end;
            }
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;
                Visible = not FinalStepVisible;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;
                Visible = not FinalStepVisible;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionCreateJob)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create a new project';
                Enabled = CreateJobActionEnabled;
                Image = Job;
                InFooterBar = true;
                Visible = FinalStepVisible;

                trigger OnAction()
                begin
                    CreateAJobAction();
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;
                Visible = FinalStepVisible;

                trigger OnAction()
                begin
                    FinishAction();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    begin
        Rec.Init();

        Step := Step::Welcome;
        EnableControls();

        if ResourcesSetup.FindFirst() then;
        if JobsSetup.FindFirst() then;

        if NoSeries.Get(JobTxt) then
            NoSeriesJob := JobTxt;
        if NoSeries.Get(ResourceTxt) then
            NoSeriesResource := ResourceTxt;
        if NoSeries.Get(TimeSheetTxt) then
            NoSeriesTimeSheet := TimeSheetTxt;
        if NoSeries.Get(JobWipTxt) then
            NoSeriesJobWIP := JobWipTxt;
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        JobsSetup: Record "Jobs Setup";
        ResourcesSetup: Record "Resources Setup";
        Resource: Record Resource;
        NoSeries: Record "No. Series";
        ClientTypeManagement: Codeunit "Client Type Management";
        NoSeriesJob: Code[10];
        NoSeriesResource: Code[10];
        NoSeriesTimeSheet: Code[10];
        NoSeriesJobWIP: Code[10];
        Step: Option Welcome,NoSeries,PostWIP,AskTimeSheet,ResourcesSetup,Users,Resources,DoTimeSheet,Finish;
        TopBannerVisible: Boolean;
        AddUsersVisible: Boolean;
        AddResourcesVisible: Boolean;
        WelcomeStepVisible: Boolean;
        NoSeriesStepVisible: Boolean;
        PostWIPStepVisible: Boolean;
        AskTimeSheetStepVisible: Boolean;
        ResourcesSetupStepVisible: Boolean;
        DoTimeSheetStepVisible: Boolean;
        FinalStepVisible: Boolean;
        FinishActionEnabled: Boolean;
        CreateJobActionEnabled: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        AddResourcesActionEnabled: Boolean;
        CreateTimesheetYes: Boolean;
        CreateTimesheetNo: Boolean;
        SelectYesNoMsg: Label 'To continue, specify if you want to set up time sheets.';
        DefaultJobPostingGroup: Code[20];
        DefaultWIPMethod: Code[20];
        SelectGroupAndBatchMsg: Label 'To continue, specify a default project posting group and WIP method.';
        ModifyRecord: Boolean;
        FirstWeekday: Option;
        SuiteJobApproval: Option;
        EnterResourceNoMsg: Label 'To add this resource, specify a resource number.';
        ExistingResourceMsg: Label 'This resource number already exists. To continue, specify a new resource number.';
        JobTxt: Label 'PROJECT', Locked = true;
        ResourceTxt: Label 'RES', Locked = true;
        TimeSheetTxt: Label 'TS';
        JobWipTxt: Label 'PROJ-WIP', Locked = true;
        ResourceNo: Code[20];
        ResourceName: Text[50];
        ResourceUseTimeSheet: Boolean;
        ResourceTimeSheetOwnerID: Code[50];
        ResourceTimeSheetApproverID: Code[50];
        ResourceType: Enum "Resource Type";
        ValueNotExistMsg: Label 'The value for field %1 does not exist. To continue, select an existing value from the lookup.', Comment = '%1=field name';

    local procedure EnableControls()
    begin
        if Step = Step::AskTimeSheet then
            if (DefaultJobPostingGroup = '') or (DefaultWIPMethod = '') then begin
                Message(SelectGroupAndBatchMsg);
                Step := Step - 1;
                exit;
            end;

        if Step = Step::ResourcesSetup then
            if (not CreateTimesheetNo) and (not CreateTimesheetYes) then begin
                Message(SelectYesNoMsg);
                Step := Step - 1;
                exit;
            end;

        ResetControls();

        case Step of
            Step::Welcome:
                ShowWelcomeStep();
            Step::Users:
                ShowAddUsersStep();
            Step::Resources:
                ShowAddResourcesStep();
            Step::NoSeries:
                ShowNoSeriesStep();
            Step::PostWIP:
                ShowPostWIPStep();
            Step::AskTimeSheet:
                ShowAskTimeSheetStep();
            Step::ResourcesSetup:
                ShowResourcesSetupStep();
            Step::DoTimeSheet:
                ShowDoTimeSheetStep();
            Step::Finish:
                ShowFinalStep();
        end;
    end;

    local procedure FinishAction()
    begin
        CurrPage.Close();
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else
            if Step <> Step::Finish then
                Step := Step + 1;

        EnableControls();
    end;

    local procedure AddResourceAction()
    begin
        if ResourceNo = '' then
            Message(EnterResourceNoMsg)
        else
            if not Resource.Get(ResourceNo) then begin
                Resource.Init();
                Resource."No." := ResourceNo;
                Resource.Name := ResourceName;
                Resource."Search Name" := Format(ResourceName);
                Resource.Type := ResourceType;
                Resource."Use Time Sheet" := ResourceUseTimeSheet;
                Resource."Time Sheet Owner User ID" := ResourceTimeSheetOwnerID;
                Resource."Time Sheet Approver User ID" := ResourceTimeSheetApproverID;
                Resource.Insert();
                ResourceNo := '';
                ResourceName := '';
                ResourceType := ResourceType::Person;
                ResourceUseTimeSheet := true;
                ResourceTimeSheetOwnerID := '';
                ResourceTimeSheetApproverID := '';
            end else
                Message(ExistingResourceMsg)
    end;

    local procedure ShowAddUsersStep()
    begin
        SetAllStepsFalse();
        AddUsersVisible := true;
        BackActionEnabled := true;
        FinishActionEnabled := false;
        AddResourcesActionEnabled := false;
        CreateJobActionEnabled := false;
    end;

    local procedure ShowAddResourcesStep()
    var
        NoSeries: Codeunit "No. Series";
    begin
        SetAllStepsFalse();
        AddResourcesVisible := true;
        FinishActionEnabled := false;
        CreateJobActionEnabled := false;

        ResourceUseTimeSheet := true;

        if (NoSeriesResource <> '') and (ResourceNo = '') then // Number series for Resource is set, auto-populate the Resource number
            ResourceNo := NoSeries.GetNextNo(NoSeriesResource, 0D);
    end;

    local procedure ShowWelcomeStep()
    begin
        SetAllStepsFalse();
        WelcomeStepVisible := true;
        FinishActionEnabled := false;
        BackActionEnabled := false;
        AddResourcesActionEnabled := false;
        CreateJobActionEnabled := false;
        CreateTimesheetYes := true;
        CreateTimesheetNo := false;
    end;

    local procedure ShowNoSeriesStep()
    begin
        SetAllStepsFalse();
        NoSeriesStepVisible := true;
        FinishActionEnabled := false;
        AddResourcesActionEnabled := false;
        CreateJobActionEnabled := false;
    end;

    local procedure ShowPostWIPStep()
    begin
        SetAllStepsFalse();
        PostWIPStepVisible := true;
        FinishActionEnabled := false;
        AddResourcesActionEnabled := false;
        CreateJobActionEnabled := false;
    end;

    local procedure ShowAskTimeSheetStep()
    begin
        SetAllStepsFalse();
        AskTimeSheetStepVisible := true;
        FinishActionEnabled := false;
        AddResourcesActionEnabled := false;
        CreateJobActionEnabled := false;
    end;

    local procedure ShowResourcesSetupStep()
    begin
        SetAllStepsFalse();
        ResourcesSetupStepVisible := true;
        FinishActionEnabled := false;
        AddResourcesActionEnabled := false;
        CreateJobActionEnabled := false;
    end;

    local procedure ShowDoTimeSheetStep()
    begin
        SaveResourceInformation();
        SaveJobsSetup();

        Commit();

        SetAllStepsFalse();
        FinalStepVisible := true;
        NextActionEnabled := false;
        AddResourcesActionEnabled := false;

        REPORT.Run(REPORT::"Create Time Sheets");
    end;

    local procedure ShowFinalStep()
    begin
        SetAllStepsFalse();
        FinalStepVisible := true;
        BackActionEnabled := false;
        NextActionEnabled := false;
        AddResourcesActionEnabled := false;

        if CreateTimesheetNo then begin
            SaveResourceInformation();
            SaveJobsSetup();
        end;
    end;

    local procedure ResetControls()
    begin
        FinishActionEnabled := true;
        BackActionEnabled := true;
        NextActionEnabled := true;
        AddResourcesActionEnabled := true;
        CreateJobActionEnabled := true;

        SetAllStepsFalse();
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    local procedure SaveJobsSetup()
    begin
        if not JobsSetup.FindFirst() then begin
            JobsSetup.Init();
            JobsSetup."Job Nos." := NoSeriesJob;
            JobsSetup."Job WIP Nos." := NoSeriesJobWIP;
            JobsSetup."Default Job Posting Group" := DefaultJobPostingGroup;
            JobsSetup."Default WIP Method" := DefaultWIPMethod;
            JobsSetup.Insert();
        end else begin
            JobsSetup.Get();
            if JobsSetup."Job Nos." <> NoSeriesJob then begin
                ModifyRecord := true;
                JobsSetup."Job Nos." := NoSeriesJob;
            end;

            if JobsSetup."Job WIP Nos." <> NoSeriesJobWIP then begin
                ModifyRecord := true;
                JobsSetup."Job WIP Nos." := NoSeriesJobWIP;
            end;

            if JobsSetup."Default Job Posting Group" <> DefaultJobPostingGroup then begin
                ModifyRecord := true;
                JobsSetup."Default Job Posting Group" := DefaultJobPostingGroup;
            end;

            if JobsSetup."Default WIP Method" <> DefaultWIPMethod then begin
                ModifyRecord := true;
                JobsSetup."Default WIP Method" := DefaultWIPMethod;
            end;

            if ModifyRecord = true then
                JobsSetup.Modify();
        end;
    end;

    local procedure SaveResourceInformation()
    begin
        SaveNoSeriesResourceTimeSheet();
        if CreateTimesheetYes then
            if not ResourcesSetup.FindFirst() then begin
                ResourcesSetup.Init();
                ResourcesSetup."Time Sheet First Weekday" := FirstWeekday;
                ResourcesSetup."Time Sheet by Job Approval" := SuiteJobApproval;
                ResourcesSetup.Insert();
            end else begin
                ResourcesSetup.Get();
                if ResourcesSetup."Time Sheet First Weekday" <> FirstWeekday then begin
                    ModifyRecord := true;
                    ResourcesSetup."Time Sheet First Weekday" := FirstWeekday;
                end;

                if ResourcesSetup."Time Sheet by Job Approval" <> SuiteJobApproval then begin
                    ModifyRecord := true;
                    ResourcesSetup."Time Sheet by Job Approval" := SuiteJobApproval;
                end;

                if ModifyRecord = true then
                    ResourcesSetup.Modify();
            end
    end;

    local procedure CreateAJobAction()
    begin
        PAGE.Run(PAGE::"Job Card");
        CurrPage.Close();
    end;

    local procedure SetAllStepsFalse()
    begin
        WelcomeStepVisible := false;
        AddUsersVisible := false;
        AddResourcesVisible := false;
        NoSeriesStepVisible := false;
        PostWIPStepVisible := false;
        AskTimeSheetStepVisible := false;
        ResourcesSetupStepVisible := false;
        DoTimeSheetStepVisible := false;
        FinalStepVisible := false;
    end;

    local procedure SaveNoSeriesResourceTimeSheet()
    begin
        if not ResourcesSetup.FindFirst() then begin
            ResourcesSetup.Init();
            ResourcesSetup."Resource Nos." := NoSeriesResource;
            ResourcesSetup."Time Sheet Nos." := NoSeriesTimeSheet;
            ResourcesSetup.Insert();
        end else begin
            ResourcesSetup.Get();
            if ResourcesSetup."Resource Nos." <> NoSeriesResource then begin
                ModifyRecord := true;
                ResourcesSetup."Resource Nos." := NoSeriesResource;
            end;

            if ResourcesSetup."Time Sheet Nos." <> NoSeriesTimeSheet then begin
                ModifyRecord := true;
                ResourcesSetup."Time Sheet Nos." := NoSeriesTimeSheet;
            end;

            if ModifyRecord = true then
                ResourcesSetup.Modify();
        end;
    end;
}

