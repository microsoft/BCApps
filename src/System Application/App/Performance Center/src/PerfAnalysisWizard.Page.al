// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.Security.AccessControl;
using System.Security.User;

/// <summary>
/// Guided wizard that captures a slow scenario from the user and schedules a performance
/// analysis.
/// </summary>
page 5491 "Perf. Analysis Wizard"
{
    Caption = 'Report slow performance';
    PageType = NavigatePage;
    ApplicationArea = All;
    SourceTable = "Performance Analysis";
    SourceTableTemporary = true;
    DelayedInsert = true;
    Permissions = tabledata "Performance Analysis" = RIMD;

    layout
    {
        area(Content)
        {
            group(Welcome)
            {
                Caption = 'Welcome';
                Visible = Step = Step::Welcome;
                InstructionalText = 'Tell us about a slow scenario. Based on your answers we will schedule a performance analysis, capture what is going on and use AI to explain the results.';

                field(WhatWellDo; WhatWellDoLbl)
                {
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    ApplicationArea = All;
                    ToolTip = 'Describes what happens after you finish the wizard.';
                }
            }
            group(Scenario)
            {
                Caption = 'What is slow?';
                Visible = Step = Step::Scenario;
                InstructionalText = 'Pick the closest match.';

                field(ScenarioActivity; Rec."Scenario Activity Type")
                {
                    Caption = 'Scenario';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of activity that is slow.';
                }
            }
            group(Where)
            {
                Caption = 'Where exactly?';
                Visible = Step = Step::Where;
                InstructionalText = 'The more specific, the better we can filter later.';

                field(TriggerKind; Rec."Trigger Kind")
                {
                    Caption = 'Trigger';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the kind of trigger associated with the slow scenario.';
                }
                field(TriggerObjectId; Rec."Trigger Object Id")
                {
                    Caption = 'Object ID';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of the page, codeunit or report involved.';
                }
                field(TriggerObjectName; Rec."Trigger Object Name")
                {
                    Caption = 'Object name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the page, codeunit or report involved.';
                }
                field(TriggerActionName; Rec."Trigger Action Name")
                {
                    Caption = 'Action or field';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the specific action or field that triggered the slowness.';
                }
            }
            group(HowOften)
            {
                Caption = 'How often?';
                Visible = Step = Step::HowOften;
                InstructionalText = 'This determines how long we should monitor.';

                field(Frequency; Rec."Frequency")
                {
                    Caption = 'Frequency';
                    ApplicationArea = All;
                    ToolTip = 'Specifies how often the scenario is slow.';
                }
            }
            group(HowSlow)
            {
                Caption = 'How slow?';
                Visible = Step = Step::HowSlow;
                InstructionalText = 'Approximate numbers are fine.';

                field(ObservedMs; Rec."Observed Duration (ms)")
                {
                    Caption = 'Observed duration (ms)';
                    ApplicationArea = All;
                    ToolTip = 'Specifies roughly how long the action takes when it is slow, in milliseconds.';
                }
                field(ExpectedMs; Rec."Expected Duration (ms)")
                {
                    Caption = 'Expected duration (ms)';
                    ApplicationArea = All;
                    ToolTip = 'Specifies how long you would expect the action to take, in milliseconds.';
                }
            }
            group(Who)
            {
                Caption = 'Who is affected?';
                Visible = Step = Step::Who;
                InstructionalText = 'Only administrators can target another user.';

                field(TargetUser; Rec."Target User")
                {
                    Caption = 'Target user';
                    ApplicationArea = All;
                    Editable = IsAdmin;
                    ToolTip = 'Specifies the user to capture performance data for. Normal users can only target themselves.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        User: Record User;
                        UserSelection: Codeunit "User Selection";
                    begin
                        if not IsAdmin then
                            exit(false);
                        if UserSelection.Open(User) then begin
                            Rec."Target User" := User."User Security ID";
                            exit(true);
                        end;
                    end;
                }
            }
            group(NotesStep)
            {
                Caption = 'Anything else?';
                Visible = Step = Step::Notes;

                field(Notes; Rec."Notes")
                {
                    Caption = 'Notes';
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Specifies any extra details that might help us analyze the scenario.';
                }
            }
            group(Summary)
            {
                Caption = 'Summary';
                Visible = Step = Step::Summary;
                InstructionalText = 'Review the analysis that will be scheduled.';

                field(SummaryTitle; Rec."Title")
                {
                    Caption = 'Title';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the title for this performance analysis.';
                }
                field(SummaryText; SummaryTextTxt)
                {
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    ApplicationArea = All;
                    ToolTip = 'Describes the scheduled performance analysis.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Back)
            {
                Caption = 'Back';
                ApplicationArea = All;
                Enabled = Step <> Step::Welcome;
                Image = PreviousRecord;
                InFooterBar = true;
                ToolTip = 'Go to the previous step.';

                trigger OnAction()
                begin
                    GoBack();
                end;
            }
            action(Next)
            {
                Caption = 'Next';
                ApplicationArea = All;
                Visible = Step <> Step::Summary;
                Image = NextRecord;
                InFooterBar = true;
                ToolTip = 'Go to the next step.';

                trigger OnAction()
                begin
                    GoNext();
                end;
            }
            action(Finish)
            {
                Caption = 'Schedule analysis';
                ApplicationArea = All;
                Visible = Step = Step::Summary;
                Image = Approve;
                InFooterBar = true;
                ToolTip = 'Create the performance analysis and start capturing.';

                trigger OnAction()
                begin
                    FinishWizard();
                end;
            }
        }
    }

    var
        Step: Option Welcome,Scenario,Where,HowOften,HowSlow,Who,Notes,Summary;
        IsAdmin: Boolean;
        SummaryTextTxt: Text;
        WhatWellDoLbl: Label 'We will create a Performance Analysis record, schedule a profiler capture tailored to your answers and, once capture ends, use AI to filter the captured profiles and produce a conclusion. Everything is stored so you can review the report and ask follow-up questions.';
        SummaryFmtLbl: Label 'Monitoring %1 for up to %2 starting now, with a threshold of about %3 ms. AI filtering and analysis will run automatically when the capture ends.', Comment = '%1 activity, %2 window, %3 threshold ms';
        AutoTitleFmtLbl: Label 'Slow %1', Comment = '%1 trigger object name';

    trigger OnOpenPage()
    var
        UserPermissions: Codeunit "User Permissions";
    begin
        IsAdmin := UserPermissions.CanManageUsersOnTenant(UserSecurityId());
        Rec.Init();
        Rec."Id" := CreateGuid();
        Rec."Requested By" := UserSecurityId();
        Rec."Target User" := UserSecurityId();
        Rec."Scenario Activity Type" := Rec."Scenario Activity Type"::"Web Client";
        Rec."Frequency" := Rec."Frequency"::Always;
        Step := Step::Welcome;
    end;

    local procedure GoNext()
    begin
        if Step = Step::Summary then
            exit;
        Step += 1;
        if Step = Step::Summary then
            BuildSummary();
        CurrPage.Update(false);
    end;

    local procedure GoBack()
    begin
        if Step = Step::Welcome then
            exit;
        Step -= 1;
        CurrPage.Update(false);
    end;

    local procedure BuildSummary()
    var
        Window: Duration;
        Threshold: Integer;
    begin
        Window := PreviewWindow(Rec."Frequency");
        Threshold := Rec."Observed Duration (ms)" - 100;
        if Threshold < 200 then
            Threshold := 200;
        SummaryTextTxt := StrSubstNo(SummaryFmtLbl, Rec."Scenario Activity Type", Format(Window), Threshold);
        if Rec."Title" = '' then
            Rec."Title" := CopyStr(StrSubstNo(AutoTitleFmtLbl, Rec."Trigger Object Name"), 1, 250);
    end;

    local procedure PreviewWindow(Freq: Enum "Perf. Analysis Frequency") W: Duration
    begin
        case Freq of
            Freq::Always:
                W := 60 * 60 * 1000;
            Freq::ComesAndGoes:
                W := 8 * 60 * 60 * 1000;
            else
                W := 24 * 60 * 60 * 1000;
        end;
    end;

    local procedure FinishWizard()
    var
        Persist: Record "Performance Analysis";
        Mgt: Codeunit "Perf. Analysis Mgt.";
        Card: Page "Perf. Analysis Card";
    begin
        Persist.Init();
        Persist.TransferFields(Rec, false);
        Mgt.RequestAnalysis(Persist);
        CurrPage.Close();
        Card.SetRecord(Persist);
        Card.Run();
    end;
}
