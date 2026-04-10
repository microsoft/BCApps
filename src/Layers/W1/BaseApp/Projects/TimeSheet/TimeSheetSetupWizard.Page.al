// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Security.User;
using System.Utilities;

page 977 "Time Sheet Setup Wizard"
{
    PageType = NavigatePage;
    RefreshOnActivate = true;
    Caption = 'Set Up Time Sheets';

    layout
    {
        area(Content)
        {
            group(Control17)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not (Step = Step::Finish);
                field(MediaResourcesStandardMediaReference; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control19)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and (Step = Step::Finish);
                field(MediaResourcesDoneMediaReference; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                InstructionalText = '';
                Visible = Step = Step::Start;
                group("Para1.1")
                {
                    Caption = 'Welcome to Time Sheet Setup';
                    InstructionalText = '';
                    label("Para1.1.1")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Track the time used on projects or create simple time registrations for resources.';
                    }
                    label("Para1.1.2")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'This guide will help you set up time sheets and specify the participants in the process. Participants include the time sheet administrator, the employees or resources who register time, and the approvers.';
                    }
                }
                group("Para1.2")
                {
                    Caption = 'Let''s go!';
                    group("Para1.2.1")
                    {
                        Caption = '';
                        InstructionalText = 'Choose Next to specify general settings, such as the first day of the week and the time sheet administrator.';
                    }
                }
            }
            group(Step2)
            {
                ShowCaption = false;
                Visible = Step = Step::Participants;
                group("Para2.1")
                {
                    ShowCaption = false;
                    group("Para2.1.1")
                    {
                        ShowCaption = false;
                        InstructionalText = 'Set up the participants in the time sheet process.';
                        group(Required)
                        {
                            Caption = 'Required:';
                            field(UserSetupStatus; UserSetupStatus)
                            {
                                ApplicationArea = Jobs;
                                ShowCaption = false;
                                StyleExpr = UserSetupStyleExpr;
                                Editable = false;

                                trigger OnDrillDown()
                                begin
                                    Page.RunModal(Page::"User Setup");
                                    UpdateControls();
                                end;
                            }
                            field(ResourcesStatus; ResourcesStatus)
                            {
                                ApplicationArea = Jobs;
                                ShowCaption = false;
                                StyleExpr = ResourcesStyleExpr;
                                Editable = false;

                                trigger OnDrillDown()
                                begin
                                    Page.RunModal(Page::"Resource List");
                                    UpdateControls();
                                end;
                            }
                        }
                        group(Optional)
                        {
                            Caption = 'Optional:';
                            field(EmployeesStatus; EmployeesStatus)
                            {
                                ApplicationArea = Jobs;
                                ShowCaption = false;
                                Editable = false;

                                trigger OnDrillDown()
                                begin
                                    Page.RunModal(Page::"Employee List");
                                    UpdateControls();
                                end;
                            }
                            field(CauseOfAbsenceStatus; CauseOfAbsenceStatus)
                            {
                                ApplicationArea = Jobs;
                                ShowCaption = false;
                                Editable = false;

                                trigger OnDrillDown()
                                begin
                                    Page.RunModal(Page::"Causes of Absence");
                                    UpdateControls();
                                end;
                            }
                        }
                        label(ParticipantsAddInfo)
                        {
                            Caption = 'If there is no data for the participants above, you can migrate or import data from other finance systems.';
                        }
                        field(LearnMoreHeader; LearnMoreTok)
                        {
                            ApplicationArea = Jobs;
                            Editable = false;
                            ShowCaption = false;
                            Caption = ' ';
                            ToolTip = 'View information about migrating business data from other finance systems.';

                            trigger OnDrillDown()
                            begin
                                Hyperlink(LearnMoreURLTxt);
                            end;
                        }
                    }
                }
            }
            group(Step3)
            {
                Visible = Step = Step::General;
                group(FirstDayOfWeekGroup)
                {
                    InstructionalText = 'All new time sheets will start on this workday.';
                    Caption = 'Choose the first day of the workweek';
                    field(FirstDayOfWeek; FirstWeekday)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Time Sheet First Weekday';
                        OptionCaption = 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';
                        ToolTip = 'Specifies the first weekday to use on a time sheet. The default is Monday.';

                        trigger OnValidate()
                        begin
                            ResourcesSetup.Get();
                            ResourcesSetup.Validate("Time Sheet First Weekday", FirstWeekday);
                            ResourcesSetup.Modify();
                        end;
                    }
                }
                group(TimeSheetAdminGroup)
                {
                    InstructionalText = 'A time sheet administrator can view, edit, and delete all time sheets.';
                    Caption = 'Choose a time sheet administrator';
                    field(TimeSheetAdmin; TimeSheetAdminUserId)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Time Sheet Administrator';
                        TableRelation = "User Setup";
                        ToolTip = 'Specifies the user who will administrate time sheets.';

                        trigger OnValidate()
                        begin
                            if TimeSheetAdminUserId = '' then begin
                                UserSetup.Reset();
                                UserSetup.ModifyAll("Time Sheet Admin.", false);
                            end else
                                if UserSetup.Get(TimeSheetAdminUserId) then begin
                                    UserSetup.Validate("Time Sheet Admin.", true);
                                    UserSetup.Modify();
                                end;
                        end;

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            UserSetup.Reset();
                            if Page.RunModal(Page::"User Setup", UserSetup) = Action::LookupOK then begin
                                UserSetup.Validate("Time Sheet Admin.", true);
                                UserSetup.Modify();
                            end;
                            UpdateGeneralInfo();
                        end;
                    }
                }
                group(TimeSheetAdminAddInfoGroup)
                {
                    ShowCaption = false;
                    label(TimeSheetAdminAddInfo)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'NOTE: You can add additional time sheet administrators on the User Setup page.';
                    }
                }
            }
            group(Step4)
            {
                InstructionalText = 'A time sheet approver is the person responsible for a job or project, such as a project manager, or the approver assigned to the resource, such as a manager.';
                Visible = Step = Step::Resources;
                group(TimeSheetByJobApprovalGroup)
                {
                    ShowCaption = false;
                    field(TimeSheetByJobApproval; TimeSheetByJobApproval)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'For projects, the person responsible is the approver';
                        OptionCaption = 'Never,,Always';
                        ToolTip = 'Specifies whether time sheets must be approved on a per-project basis by the user specified for the project.';

                        trigger OnValidate()
                        begin
                            ResourcesSetup.Get();
                            ResourcesSetup.Validate("Time Sheet by Job Approval", TimeSheetByJobApproval);
                            ResourcesSetup.Modify();
                        end;
                    }
                    part(Resources; "Time Sheet Setup Resources")
                    {
                        ApplicationArea = Jobs;
                        UpdatePropagation = Both;
                    }
                }
            }
            group(Step5)
            {
                InstructionalText = 'Time sheets can be used to register and approve employee absences. This requires that employees are linked to resources.';
                Visible = Step = Step::Employees;
                group(TimeSheetEmployeesGroup)
                {
                    ShowCaption = false;
                    label(TimeSheetEmployeesNoteInfo)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'NOTE: The links between employees and resources in the list below are suggested because their company email addresses match. If needed, you can change the suggested links.';
                    }
                    part(Employees; "Time Sheet Setup Employees")
                    {
                        ApplicationArea = Jobs;
                        UpdatePropagation = Both;
                    }
                }
            }
            group(Step6)
            {
                InstructionalText = 'Your time sheet setup is complete.';
                Visible = Step = Step::Finish;
                group(FinishGroup)
                {
                    ShowCaption = false;
                    group(RunCreateTimeSheetsGroup)
                    {
                        Caption = 'Are you ready to create time sheets now?';
                        field(RunCreateTimeSheets; RunCreateTimeSheets)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Create Time Sheets';
                            ToolTip = 'Specifies whether to create time sheets when you choose Finish.';
                        }
                    }
                    label(Finish2)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Choose Finish to apply the setup and complete the guide.';
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BackAction)
            {
                ApplicationArea = Jobs;
                Caption = '&Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(NextAction)
            {
                ApplicationArea = Jobs;
                Caption = '&Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(FinishAction)
            {
                ApplicationArea = Jobs;
                Caption = '&Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                begin
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Time Sheet Setup Wizard");

                    if RunCreateTimeSheets then begin
                        Commit();
                        Report.Run(Report::"Create Time Sheets");
                    end;

                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
        Step := Step::Start;
        UpdateControls();
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ResourcesSetup: Record "Resources Setup";
        UserSetup: Record "User Setup";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Start,Participants,General,Resources,Employees,Finish;
        FirstWeekday: Option Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday;
        TimeSheetByJobApproval: Option Never,,Always;
        TopBannerVisible: Boolean;
        UserSetupStatus: Text;
        ResourcesStatus: Text;
        EmployeesStatus: Text;
        CauseOfAbsenceStatus: Text;
        UserSetupStyleExpr: Text;
        ResourcesStyleExpr: Text;
        TimeSheetAdminUserId: Text[50];
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        FinishActionEnabled: Boolean;
        RunCreateTimeSheets: Boolean;
        UserSetupStatusTxt: Label 'User Setup (%1 users in User Setup)', Comment = '%1 - number';
        ResourcesStatusTxt: Label 'Resources (%1 resources)', Comment = '%1 - number';
        EmployeesStatusTxt: Label 'Employees (%1 employees)', Comment = '%1 - number';
        CauseofAbsenceStatusTxt: Label 'Causes of Absence (%1 causes of absence)', Comment = '%1 - number';
        LearnMoreTok: Label 'Learn more about migrating business data from other finance systems';
        LearnMoreURLTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2167200', Locked = true;

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

    local procedure NextStep(Backward: Boolean)
    var
        Employee: Record Employee;
    begin
        if Backward then
            Step := Step - 1
        else
            Step := Step + 1;

        if (Step = Step::Employees) then
            if Employee.IsEmpty() then
                NextStep(Backward)
            else
                MatchEmployeesWithResources();

        UpdateControls();
    end;

    local procedure UpdateControls()
    begin
        case Step of
            Step::Participants:
                UpdateParticipants();
            Step::General:
                UpdateGeneralInfo();
        end;

        NextActionEnabled := Step <> Step::Finish;
        BackActionEnabled := Step <> Step::Start;
        FinishActionEnabled := Step = Step::Finish;
    end;

    local procedure UpdateGeneralInfo()
    begin
        ResourcesSetup.Get();
        FirstWeekday := ResourcesSetup."Time Sheet First Weekday";
        UserSetup.SetRange("Time Sheet Admin.", true);
        if UserSetup.FindFirst() then
            TimeSheetAdminUserId := UserSetup."User ID"
        else
            TimeSheetAdminUserId := '';

    end;

    local procedure UpdateParticipants()
    begin
        UpdateUserSetupInfo();
        UpdateResourcesInfo();
        UpdateEmployeesInfo();
        UpdateCauseOfAbsenceInfo();
    end;

    local procedure UpdateUserSetupInfo()
    var
        UserSetupQty: Integer;
    begin
        UserSetup.Reset();
        UserSetupQty := UserSetup.Count();
        UserSetupStatus := StrSubstNo(UserSetupStatusTxt, UserSetupQty);
        if UserSetupQty = 0 then
            UserSetupStyleExpr := 'Attention'
        else
            UserSetupStyleExpr := 'Favorable';
    end;

    local procedure UpdateResourcesInfo()
    var
        Resource: Record Resource;
        ResourceQty: Integer;
    begin
        ResourceQty := Resource.Count();
        ResourcesStatus := StrSubstNo(ResourcesStatusTxt, ResourceQty);
        if ResourceQty = 0 then
            ResourcesStyleExpr := 'Attention'
        else
            ResourcesStyleExpr := 'Favorable';
    end;

    local procedure UpdateEmployeesInfo()
    var
        Employee: Record Employee;
    begin
        EmployeesStatus := StrSubstNo(EmployeesStatusTxt, Employee.Count());
    end;

    local procedure UpdateCauseOfAbsenceInfo()
    var
        CauseofAbsence: Record "Cause of Absence";
    begin
        CauseofAbsenceStatus := StrSubstNo(CauseofAbsenceStatusTxt, CauseofAbsence.Count());
    end;

    local procedure MatchEmployeesWithResources()
    var
        Resource: Record Resource;
        Email: Text;
    begin
        Resource.SetRange("Use Time Sheet", true);
        Resource.SetFilter("Time Sheet Owner User ID", '<>%1', '');
        if Resource.FindSet() then
            repeat
                if UserSetup.Get(Resource."Time Sheet Owner User ID") then
                    if GetUserEmail(Email) then
                        MatchEmployeesWithResource(Resource."No.", Email);
            until Resource.Next() = 0;
    end;

    local procedure GetUserEmail(var Email: Text): Boolean
    var
        User: Record User;
    begin
        if UserSetup."E-Mail" <> '' then begin
            Email := UserSetup."E-Mail";
            exit(true);
        end;

        User.SetRange("User Name", UserSetup."User ID");
        User.SetFilter("Authentication Email", '<>%1', '');
        if User.FindFirst() then begin
            Email := User."Authentication Email";
            exit(true);
        end;
    end;

    local procedure MatchEmployeesWithResource(ResourceNo: Code[20]; Email: Text)
    var
        Employee: Record Employee;
    begin
        Employee.SetRange("Company E-Mail", Email);
        Employee.SetRange("Resource No.", '');
        if not Employee.IsEmpty() then
            Employee.ModifyAll("Resource No.", ResourceNo);
    end;
}
