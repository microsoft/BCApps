// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using System.Reflection;

page 8132 "Report Filename Test"
{
    // Shows the file name a chosen run would get, and whether it comes from this pattern, another
    // pattern, or Business Central; the latter two say why.

    Caption = 'Test Pattern';
    // No source table: the caller hands the pattern in (SetPattern). Not a StandardDialog,
    // because nothing here is confirmed or saved.
    PageType = Card;
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Trying)
            {
                Caption = 'Pattern';

                field(PatternText; PatternText)
                {
                    Caption = 'File Name Pattern';
                    ToolTip = 'Specifies the file name pattern being tested.';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(Against)
            {
                Caption = 'Test Run';
                InstructionalText = 'A report run covers one record, some records or every record, and produces one file either way. Choose what this run covers, then choose the record or set the filter. The result shows the name the file would get, and whether it comes from this pattern, from another pattern, or is Business Central''s own file name.';

                // Only for a pattern that names no report, so report placeholders can be filled.
                // Visible on a group, because a field's Visible is not re-evaluated after opening.
                group(WhichReport)
                {
                    ShowCaption = false;
                    Visible = NeedsReport;

                    field(TestReportText; TestReportText)
                    {
                        Caption = 'Report';
                        ToolTip = 'Specifies which report is run. This pattern names no report, so it applies to all of them, and a name that uses the report name cannot be worked out until one is chosen.';
                        ApplicationArea = All;

                        trigger OnAssistEdit()
                        begin
                            ChooseReport();
                        end;

                        trigger OnValidate()
                        begin
                            TypedReport();
                        end;
                    }
                }
                // Which pattern wins can depend on the route. Defaults to the pattern's first route, or Any.
                field(TestRoute; TestRoute)
                {
                    Caption = 'Output Route';
                    ToolTip = 'Specifies which way out of Business Central the run takes, such as Print, Preview or Email. A pattern limited to some routes names only those. Choose Any for a run where Business Central does not say which route it takes. Only patterns for every route name such a run.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        ExplainAgain();
                    end;
                }
                field(RunScope; RunScope)
                {
                    Caption = 'Run Covers';
                    ToolTip = 'Specifies how many of the table''s records the run covers: one record, some records or every record. A run over every record needs nothing else chosen.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        ScopeChosen();
                    end;
                }
                field(RunTargetText; RunTargetText)
                {
                    Caption = 'Records';
                    ToolTip = 'Specifies which records the run covers. Use the lookup to choose a record or set a filter, depending on what the run covers. A run over every record fills this in by itself.';
                    ApplicationArea = All;
                    // Editable, so a value can also be typed; OnValidate handles typed values.
                    // Not mandatory: Every Record needs nothing here.

                    trigger OnAssistEdit()
                    begin
                        ChooseForScope();
                    end;

                    trigger OnValidate()
                    begin
                        TypedForScope();
                    end;
                }
            }
            // No caption: the web client collapses FastTabs after the first two, and an uncaptioned
            // group cannot be collapsed.
            group(Outcome)
            {
                ShowCaption = false;

                field(ResultingFileName; ResultingFileName)
                {
                    Caption = 'File Name';
                    ToolTip = 'Specifies the name the file would get for the run you described.';
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    StyleExpr = ResultStyle;
                }
                field(RecordsInTheRun; RecordsInTheRun)
                {
                    Caption = 'No. of Records';
                    ToolTip = 'Specifies how many records this run covers, so it is clear whether the file is being named for one record or for many.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(NameComesFrom; NameComesFrom)
                {
                    Caption = 'Name Source';
                    ToolTip = 'Specifies whether the name comes from this pattern, from another pattern, or is Business Central''s own file name.';
                    ApplicationArea = All;
                    Editable = false;
                    // Wraps so the longest answer is not truncated.
                    MultiLine = true;
                }
                // A group, because a field's Visible is not re-evaluated after the page opens.
                group(Explanation)
                {
                    ShowCaption = false;
                    Visible = HasWhy;

                    field(WhyNotThisPattern; WhyNotThisPattern)
                    {
                        Caption = 'Reason';
                        ToolTip = 'Explains why the name does not come from this pattern.';
                        ApplicationArea = All;
                        Editable = false;
                        MultiLine = true;
                        StyleExpr = 'Ambiguous';
                    }
                }
            }
        }
    }

    local procedure ExplainTypedRecord()
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        // Errors when nothing matches.
        ReportFilenamePreviewMgt.FindRecordByDescription(Pattern."Table No.", RunTargetText, ChosenRecordId);
        Explain();
    end;

    /// <summary>
    /// Clears the previous choice, since a record and a filter do not carry over. Every Record
    /// shows its result immediately.
    /// </summary>
    local procedure ScopeChosen()
    begin
        ClearResult();

        if RunScope = RunScope::"Every Record" then
            CoverEveryRecord();
    end;

    /// <summary>
    /// Fills the field with the description of an empty filter, so it does not look unset.
    /// </summary>
    local procedure CoverEveryRecord()
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        Clear(RunFilterView);
        RunTargetText := ReportFilenamePreviewMgt.DescribeSelection(Pattern."Table No.", '');
        LastShownRunSelection := RunTargetText;

        ExplainRun();
    end;

    local procedure ChooseForScope()
    begin
        case RunScope of
            RunScope::"One Record":
                ChooseRecord();
            RunScope::"Some Records":
                ChooseRun();
            RunScope::"Every Record":
                Message(EveryRecordNeedsNothingMsg);
        end;
    end;

    /// <summary>
    /// A typed value acts like a choice where it can, and raises an error where it cannot.
    /// </summary>
    local procedure TypedForScope()
    begin
        case RunScope of
            RunScope::"One Record":
                begin
                    if RunTargetText = '' then begin
                        ClearResult();
                        exit;
                    end;
                    ExplainTypedRecord();
                end;
            RunScope::"Some Records":
                begin
                    if RunTargetText = '' then begin
                        ClearResult();
                        exit;
                    end;
                    // The shown text describes a filter and cannot be parsed back.
                    if RunTargetText <> LastShownRunSelection then
                        Error(SetRunWithLookupErr);
                end;
            RunScope::"Every Record":
                if RunTargetText <> LastShownRunSelection then
                    Error(EveryRecordCannotBeTypedErr);
        end;
    end;

    local procedure ClearResult()
    begin
        Clear(ChosenRecordId);
        Clear(RunFilterView);
        Clear(RunTargetText);
        Clear(LastShownRunSelection);
        Clear(RecordsInTheRun);
        Clear(ResultingFileName);
        Clear(NameComesFrom);
        Clear(WhyNotThisPattern);
        HasWhy := false;
        CurrPage.Update(false);
    end;

    /// <summary>
    /// A filter and a single record are alternatives, so setting the filter clears the record.
    /// </summary>
    local procedure ChooseRun()
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        if not ReportFilenamePreviewMgt.ChooseRunToTest(Pattern, RunFilterView, RunTargetText) then
            exit;

        Clear(ChosenRecordId);
        LastShownRunSelection := RunTargetText;

        ExplainRun();
    end;

    local procedure ExplainRun()
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        ReportFilenamePreviewMgt.ExplainNameForRun(
            Pattern, TestRoute, RunFilterView, ResultingFileName, NameComesFrom, WhyNotThisPattern, FromThisPattern);

        ShowResult(CountForRun());
    end;

    local procedure ChooseRecord()
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        if not ReportFilenamePreviewMgt.ChooseRecordToTest(Pattern, ChosenRecordId, RunTargetText) then
            exit;

        Explain();
    end;

    /// <summary>
    /// Shared by the lookup and typing. Works from ChosenRecordId, not the displayed text.
    /// </summary>
    local procedure Explain()
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        Clear(RunFilterView);
        Clear(LastShownRunSelection);

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, TestRoute, ChosenRecordId, ResultingFileName, NameComesFrom, WhyNotThisPattern, FromThisPattern);

        ShowResult(1);
    end;

    local procedure ShowResult(Records: Integer)
    begin
        RecordsInTheRun := Records;
        HasWhy := WhyNotThisPattern <> '';
        if FromThisPattern then
            ResultStyle := 'Favorable'
        else
            ResultStyle := 'Ambiguous';

        CurrPage.Update(false);
    end;

    /// <returns>Zero when the count cannot be read, rather than a stale number.</returns>
    local procedure CountForRun() Records: Integer
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        if not ReportFilenamePreviewMgt.TryCountRun(Pattern."Table No.", RunFilterView, Records) then
            Records := 0;
    end;

    internal procedure SetPattern(var PatternToTest: Record "Report Filename Pattern")
    begin
        Pattern := PatternToTest;
        PatternText := Pattern."File Name Pattern";
        NeedsReport := Pattern."Report ID" = 0;
        TestRoute := Pattern.DefaultTestRoute();
    end;

    /// <summary>
    /// Sets the report on this page's copy of the pattern only; it is never saved. Assigned, not
    /// validated, because validating Report ID can replace the pattern's table, language code field
    /// and binding (SuggestFromReport).
    /// </summary>
    local procedure ChooseReport()
    var
        ReportMetadata: Record "Report Metadata";
        ReportLookup: Page "Report Filename Report Lookup";
    begin
        if Pattern."Report ID" <> 0 then
            if ReportMetadata.Get(Pattern."Report ID") then
                ReportLookup.SetRecord(ReportMetadata);
        if Pattern."Table No." <> 0 then
            ReportLookup.SetReportsAbout(Pattern."Table No.");

        ReportLookup.LookupMode(true);
        if ReportLookup.RunModal() <> Action::LookupOK then
            exit;

        ReportLookup.GetRecord(ReportMetadata);
        SetTestReport(ReportMetadata);
    end;

    local procedure TypedReport()
    var
        ReportMetadata: Record "Report Metadata";
    begin
        if TestReportText = '' then begin
            Pattern."Report ID" := 0;
            ClearResult();
            exit;
        end;

        ReportMetadata.SetRange(Caption, CopyStr(TestReportText, 1, MaxStrLen(ReportMetadata.Caption)));
        ReportMetadata.SetRange(ProcessingOnly, false);
        if not ReportMetadata.FindFirst() then
            Error(NoReportCalledThatErr, TestReportText);

        SetTestReport(ReportMetadata);
    end;

    local procedure SetTestReport(var ReportMetadata: Record "Report Metadata")
    begin
        Pattern."Report ID" := ReportMetadata.ID;
        TestReportText := ReportMetadata.Caption;

        ExplainAgain();
    end;

    local procedure ExplainAgain()
    begin
        if ChosenRecordId.TableNo() <> 0 then begin
            Explain();
            exit;
        end;

        if LastShownRunSelection <> '' then
            ExplainRun();
    end;

    var
        Pattern: Record "Report Filename Pattern";
        ChosenRecordId: RecordId;
        RecordsInTheRun: Integer;
        RunScope: Enum "Report Filename Run Scope";
        TestRoute: Enum "Report Filename Output Route";
        PatternText: Text;
        TestReportText: Text;
        RunTargetText: Text;
        RunFilterView: Text;
        LastShownRunSelection: Text;
        ResultingFileName: Text;
        NameComesFrom: Text;
        WhyNotThisPattern: Text;
        ResultStyle: Text;
        HasWhy: Boolean;
        NeedsReport: Boolean;
        FromThisPattern: Boolean;
        SetRunWithLookupErr: Label 'Use the lookup beside this field to set the records the run covers. What is shown here is a description, not something that can be typed back in.';
        EveryRecordCannotBeTypedErr: Label 'This run covers every record, so there is nothing to choose here. Change what the run covers if you want to name one record or set a filter.';
        EveryRecordNeedsNothingMsg: Label 'This run already covers every record, so there is nothing to choose. Change what the run covers if you want to name one record or set a filter.';
        NoReportCalledThatErr: Label 'There is no report called %1. Use the lookup beside this field to choose one.', Comment = '%1 what was typed';
}
