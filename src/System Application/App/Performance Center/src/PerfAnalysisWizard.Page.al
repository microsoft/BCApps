// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;

/// <summary>
/// Guided wizard that captures a slow scenario from the user and schedules a performance
/// analysis.
/// </summary>
page 8424 "Perf. Analysis Wizard"
{
    Caption = 'Describe the slow scenario';
    PageType = NavigatePage;
    ApplicationArea = All;
    SourceTable = "Performance Analysis";
    SourceTableTemporary = true;
    Permissions = tabledata "Performance Analysis" = RIMD;

    layout
    {
        area(Content)
        {
            group(Welcome)
            {
                Caption = 'Welcome';
                Visible = Step = Step::Welcome;
                InstructionalText = 'Tell us about the slow scenario. Based on your answers, we will start monitoring the performance over the next period, and then use AI to explain the results.';
            }
            group(Where)
            {
                Caption = 'Where were you?';
                Visible = Step = Step::Where;
                InstructionalText = 'Tell us which page you were on and what is slow on that page. If multiple scenarios are slow, then focus on the worst scenario first.';

                field(ScreenName; Rec."Trigger Object Name")
                {
                    Caption = 'Page';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the page you were on when the slowness occurred. Use the lookup to pick from the list of pages.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupPage(Text));
                    end;

                    trigger OnValidate()
                    begin
                        // Free-form typing is allowed but the page id is only known when picked
                        // via the lookup. Clear the id so we do not keep a stale value.
                        if Rec."Trigger Object Name" <> LastPickedObjectName then begin
                            Rec."Trigger Object Id" := 0;
                            Rec."Trigger Object Type" := Rec."Trigger Object Type"::" ";
                            LastPickedObjectName := '';
                        end;
                    end;
                }
                field(ActionName; Rec."Trigger Action Name")
                {
                    Caption = 'Scenario';
                    ApplicationArea = All;
                    ToolTip = 'Specifies what you were doing on the page, for example changing a field value, invoking an action, or closing the page. Use the lookup to pick from a list of scenarios.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupScenario(Text));
                    end;
                }
            }
            group(HowOften)
            {
                Caption = 'How often?';
                Visible = Step = Step::HowOften;
                InstructionalText = 'This determines how long the Performance Center should monitor.';

                field(Frequency; Rec."Frequency")
                {
                    Caption = 'Frequency';
                    ApplicationArea = All;
                    ToolTip = 'Specifies how often the scenario is slow.';
                }
            }
            group(HowSlow)
            {
                Caption = 'How fast should it be?';
                Visible = Step = Step::HowSlow;
                InstructionalText = 'How fast is the scenario normally? Or how fast would you expect it to be?';

                field(ExpectedSec; ExpectedSeconds)
                {
                    Caption = 'Normal/expected duration (seconds)';
                    ApplicationArea = All;
                    MinValue = 0;
                    ToolTip = 'Specifies how long you think it should take, in seconds. The profiler will flag anything that runs significantly longer than this.';
                }
            }
            group(Who)
            {
                Caption = 'Which user to monitor';
                Visible = (Step = Step::Who) and IsAdmin;
                InstructionalText = 'Which user should be monitored for slowness? Regular users can only monitor themselves. Administrators can monitor other users.';

                field(TargetUserName; TargetUserNameTxt)
                {
                    Caption = 'User to monitor';
                    ApplicationArea = All;
                    Editable = IsAdmin;
                    ToolTip = 'Specifies the user to monitor performance for. Use the lookup to pick a user.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        User: Record User;
                        UserSelection: Codeunit "User Selection";
                    begin
                        if not IsAdmin then
                            exit(false);
                        if UserSelection.Open(User) then begin
                            Rec."Target User" := User."User Security ID";
                            TargetUserNameTxt := User."User Name";
                            Text := TargetUserNameTxt;
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        // Free-form text is rejected silently: re-display the currently selected
                        // user's name so we never try to validate a GUID into the Target User field.
                        TargetUserNameTxt := ResolveUserName(Rec."Target User");
                    end;
                }
            }
            group(NotesStep)
            {
                Caption = 'Anything else?';
                Visible = Step = Step::Notes;
                InstructionalText = 'Add anything that might help, for example "it only happens in the morning" or "it started after I posted a batch".';

                field(Notes; Rec."Notes")
                {
                    Caption = 'Notes';
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Specifies any extra details that might help with the analysis.';
                }
            }
            group(Summary)
            {
                Caption = 'Here''s what happens next';
                Visible = Step = Step::Summary;
                InstructionalText = 'We have everything we need. Review the summary below and click Schedule analysis to start.';

                field(SummaryText; SummaryTextTxt)
                {
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    ApplicationArea = All;
                    ToolTip = 'Describes what will happen after you schedule the analysis.';
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
        Step: Option Welcome,Where,HowOften,HowSlow,Who,Notes,Summary;
        IsAdmin: Boolean;
        ExpectedSeconds: Integer;
        SummaryTextTxt: Text;
        TargetUserNameTxt: Text[132];
        LastPickedObjectName: Text[250];
        SummaryHeaderLbl: Label 'Here is what happens next:', Locked = true;
        SummaryLine1MonitorUserLbl: Label '• We will monitor %1 on %2 for about %3.', Comment = '%1 = user name, %2 = page name, %3 = duration';
        SummaryLine1MonitorLbl: Label '• We will monitor performance on %1 for about %2.', Comment = '%1 = page name, %2 = duration';
        SummaryLine1GenericLbl: Label '• We will monitor performance for about %1.', Comment = '%1 = duration';
        SummaryLine2ScenarioLbl: Label '• We will focus on: %1', Comment = '%1 = scenario description';
        SummaryLine3ThresholdLbl: Label '• Any run that takes longer than about %1 ms will be captured for analysis.', Comment = '%1 = threshold in ms';
        SummaryLine4AiLbl: Label '• When monitoring ends, AI will analyze the captured profiles and produce a conclusion.';
        SummaryLine5CardLbl: Label 'You can follow progress by going back to the Performance Analysis card.';
        PreviousAutoTitle: Text[250];

    trigger OnOpenPage()
    var
        UserPermissions: Codeunit "User Permissions";
    begin
        IsAdmin := UserPermissions.CanManageUsersOnTenant(UserSecurityId());
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."Id" := CreateGuid();
        Rec."Requested By" := UserSecurityId();
        Rec."Target User" := UserSecurityId();
        Rec."Scenario Activity Type" := Rec."Scenario Activity Type"::"Web Client";
        Rec."Frequency" := Rec."Frequency"::Always;
        Rec.Insert();
        TargetUserNameTxt := ResolveUserName(Rec."Target User");
        Step := Step::Welcome;
    end;

    local procedure GoNext()
    begin
        if Step = Step::Summary then
            exit;
        Step += 1;
        // Non-admins have no controls in the Who step, so skip it.
        if (Step = Step::Who) and not IsAdmin then
            Step += 1;
        if Step = Step::Summary then
            BuildSummary();
        CurrPage.Update(true);
    end;

    local procedure GoBack()
    begin
        if Step = Step::Welcome then
            exit;
        Step -= 1;
        if (Step = Step::Who) and not IsAdmin then
            Step -= 1;
        CurrPage.Update(false);
    end;

    local procedure BuildSummary()
    var
        TextBuilder: TextBuilder;
        Window: Duration;
        Threshold: Integer;
        UserName: Text;
        PageName: Text;
        Scenario: Text;
    begin
        ApplyDurations();
        Window := PreviewWindow(Rec."Frequency");
        Threshold := ThresholdForSummary();
        UserName := ResolveUserName(Rec."Target User");
        PageName := Rec."Trigger Object Name";
        Scenario := Rec."Trigger Action Name";

        TextBuilder.AppendLine(SummaryHeaderLbl);
        TextBuilder.AppendLine('');
        if (UserName <> '') and (UserName <> ResolveUserName(UserSecurityId())) and (PageName <> '') then
            TextBuilder.AppendLine(StrSubstNo(SummaryLine1MonitorUserLbl, UserName, PageName, FormatDurationForSummary(Window)))
        else
            if PageName <> '' then
                TextBuilder.AppendLine(StrSubstNo(SummaryLine1MonitorLbl, PageName, FormatDurationForSummary(Window)))
            else
                TextBuilder.AppendLine(StrSubstNo(SummaryLine1GenericLbl, FormatDurationForSummary(Window)));
        if Scenario <> '' then
            TextBuilder.AppendLine(StrSubstNo(SummaryLine2ScenarioLbl, Scenario));
        TextBuilder.AppendLine(StrSubstNo(SummaryLine3ThresholdLbl, Threshold));
        TextBuilder.AppendLine(SummaryLine4AiLbl);
        TextBuilder.AppendLine('');
        TextBuilder.AppendLine(SummaryLine5CardLbl);
        SummaryTextTxt := TextBuilder.ToText();

        // Pre-fill the analysis title so the created card has a meaningful name. The user
        // can rename from the card.
        if (Rec."Title" = '') or (Rec."Title" = PreviousAutoTitle) then begin
            Rec."Title" := BuildAutoTitle();
            PreviousAutoTitle := Rec."Title";
        end;
        if Rec.Modify() then;
    end;

    local procedure FormatDurationForSummary(D: Duration): Text
    var
        HoursLbl: Label '%1 hour', Comment = '%1 = number of hours (singular)';
        HoursPluralLbl: Label '%1 hours', Comment = '%1 = number of hours';
        DayLbl: Label '1 day', Locked = true;
        TwoDaysLbl: Label '%1 days', Comment = '%1 = number of days';
        TotalMs: BigInteger;
        H: Integer;
    begin
        TotalMs := D;
        H := TotalMs div (60 * 60 * 1000);
        if H = 24 then
            exit(DayLbl);
        if (H > 24) and ((H mod 24) = 0) then
            exit(StrSubstNo(TwoDaysLbl, H div 24));
        if H = 1 then
            exit(StrSubstNo(HoursLbl, 1));
        exit(StrSubstNo(HoursPluralLbl, H));
    end;

    local procedure ThresholdForSummary() Threshold: Integer
    begin
        // Mirror Perf. Analysis Mgt. Impl.: threshold is set below the expected duration so
        // the profiler also captures runs at the expected pace for comparison.
        if Rec."Expected Duration (ms)" > 0 then
            Threshold := Rec."Expected Duration (ms)" div 2
        else
            Threshold := 200;
        if Threshold < 200 then
            Threshold := 200;
        if Threshold > 60000 then
            Threshold := 60000;
    end;

    local procedure BuildAutoTitle(): Text[250]
    var
        PageAndScenarioLbl: Label 'Slowness on the %1 page: %2', Comment = '%1 = page name, %2 = scenario';
        PageOnlyLbl: Label 'Slowness on the %1 page', Comment = '%1 = page name';
        ScenarioOnlyLbl: Label 'Slow: %1', Comment = '%1 = scenario';
        GenericLbl: Label 'Slow scenario';
        Scenario: Text[250];
    begin
        Scenario := Rec."Trigger Action Name";
        // Trim a trailing period so it reads cleanly as part of a title.
        if (Scenario <> '') and (Scenario[StrLen(Scenario)] = '.') then
            Scenario := CopyStr(CopyStr(Scenario, 1, StrLen(Scenario) - 1), 1, MaxStrLen(Scenario));
        if (Rec."Trigger Object Name" <> '') and (Scenario <> '') then
            exit(CopyStr(StrSubstNo(PageAndScenarioLbl, Rec."Trigger Object Name", Scenario), 1, 250));
        if Rec."Trigger Object Name" <> '' then
            exit(CopyStr(StrSubstNo(PageOnlyLbl, Rec."Trigger Object Name"), 1, 250));
        if Scenario <> '' then
            exit(CopyStr(StrSubstNo(ScenarioOnlyLbl, Scenario), 1, 250));
        exit(GenericLbl);
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

    local procedure ApplyDurations()
    begin
        Rec."Expected Duration (ms)" := ExpectedSeconds * 1000;
    end;

    local procedure FinishWizard()
    var
        Persist: Record "Performance Analysis";
        Mgt: Codeunit "Perf. Analysis Mgt.";
        Card: Page "Perf. Analysis Card";
    begin
        ApplyDurations();
        Persist.Init();
        Persist.TransferFields(Rec, false);
        Mgt.RequestAnalysis(Persist);
        CurrPage.Close();
        Card.SetRecord(Persist);
        Card.Run();
    end;

    local procedure LookupPage(var Text: Text): Boolean
    var
        TempPageBuf: Record "Perf. Analysis Page Buf" temporary;
        AllObjWithCaption: Record AllObjWithCaption;
        PageLookup: Page "Perf. Analysis Page Lookup";
        Name: Text[250];
    begin
        PageLookup.LookupMode(true);
        if PageLookup.RunModal() <> Action::LookupOK then
            exit(false);
        PageLookup.GetRecord(TempPageBuf);
        if TempPageBuf."Page Id" = 0 then
            exit(false);
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Page, TempPageBuf."Page Id") and (AllObjWithCaption."Object Caption" <> '') then
            Name := CopyStr(AllObjWithCaption."Object Caption", 1, MaxStrLen(Name))
        else
            Name := TempPageBuf.Name;
        Rec."Trigger Object Type" := Rec."Trigger Object Type"::Page;
        Rec."Trigger Object Id" := TempPageBuf."Page Id";
        Rec."Trigger Object Name" := Name;
        Rec."Trigger Object System Name" := TempPageBuf.Name;
        Rec."Trigger Action Name" := '';
        Rec."Trigger Action System Name" := '';
        LastPickedObjectName := Name;
        Text := Name;
        exit(true);
    end;

    local procedure LookupScenario(var Text: Text): Boolean
    var
        TempScenarioBuf: Record "Perf. Analysis Control Buf" temporary;
        ScenarioLookup: Page "Perf. Analysis Control Lookup";
        ScenarioText: Text[250];
    begin
        if (Rec."Trigger Object Type" <> Rec."Trigger Object Type"::Page) or (Rec."Trigger Object Id" = 0) then
            exit(false);
        ScenarioLookup.LoadFromPage(Rec."Trigger Object Id");
        ScenarioLookup.LookupMode(true);
        if ScenarioLookup.RunModal() <> Action::LookupOK then
            exit(false);
        ScenarioLookup.GetRecord(TempScenarioBuf);
        if TempScenarioBuf."Scenario" = '' then
            exit(false);
        ScenarioText := CopyStr(TempScenarioBuf."Scenario", 1, MaxStrLen(ScenarioText));
        Rec."Trigger Action Name" := ScenarioText;
        Rec."Trigger Action System Name" := TempScenarioBuf.Name;
        Text := ScenarioText;
        exit(true);
    end;

    local procedure ResolveUserName(UserSecurityId: Guid): Text[132]
    var
        User: Record User;
    begin
        if IsNullGuid(UserSecurityId) then
            exit('');
        if User.Get(UserSecurityId) then
            exit(User."User Name");
        exit('');
    end;
}
