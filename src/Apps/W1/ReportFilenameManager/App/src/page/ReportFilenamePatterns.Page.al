// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

page 8125 "Report Filename Patterns"
{
    Caption = 'Report Filename Patterns';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    // Tell Me matches the letters and words typed, so "file name" is added beside the caption's "Filename".
    AdditionalSearchTerms = 'file name, file names, document name, PDF name, attachment name, email attachment name, report naming';
    SourceTable = "Report Filename Pattern";
    // Grouped by table, so patterns that can compete for the same files sit together.
    SourceTableView = sorting("Table No.", "Report ID", "Language Code");
    CardPageId = "Report Filename Pattern Card";
    // Read-only: patterns are edited on the card, where the assist-edits are.
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Patterns)
            {
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = All;
                    DrillDown = false;
                    StyleExpr = RowStyleText;
                }
                field("Report Name"; Rec."Report Name")
                {
                    ApplicationArea = All;
                    DrillDown = false;
                    StyleExpr = RowStyleText;
                }
                // Next to the identifying columns, with disabled rows dimmed, as on Quality
                // Management's Quality Inspection Source Configurations list.
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    StyleExpr = RowStyleText;
                }
                // Computed by the same procedure naming uses. Shown only in the overlap view, which
                // is set before the page opens: a field's Visible variable must be resolved by
                // OnInit or OnOpenPage.
                field(Priority; Rec.Priority())
                {
                    Caption = 'Priority';
                    ToolTip = 'Specifies which pattern is used when more than one applies to the same file. 1 is the highest. It follows from what the pattern specifies: a table filter counts most, then a report, a table, an output route and a language. When two patterns have the same priority, the one created first is used.';
                    ApplicationArea = All;
                    StyleExpr = RowStyleText;
                    Visible = ShowingOverlap;
                }
                field("File Name Pattern"; Rec."File Name Pattern")
                {
                    ApplicationArea = All;
                    Width = 40;
                    StyleExpr = RowStyleText;
                }
                field(RouteFilterText; RouteFilterText)
                {
                    Caption = 'Output Route Filter';
                    ToolTip = 'Specifies which ways out of Business Central this pattern applies to, such as Print|Preview. All routes when it is blank.';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = RowStyleText;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = All;
                    StyleExpr = RowStyleText;
                }
                field(TableFilterText; TableFilterText)
                {
                    Caption = 'Table Filter';
                    ToolTip = 'Specifies a filter the records must match for this pattern to apply, such as a reminder level.';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = RowStyleText;
                }
                field("Date Format"; Rec."Date Format")
                {
                    ApplicationArea = All;
                    StyleExpr = RowStyleText;
                }
            }
        }
        area(FactBoxes)
        {
            part(Preview; "Report Filename Preview")
            {
                Caption = 'Example File Name';
                ApplicationArea = All;
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestPattern)
            {
                Caption = 'Test pattern';
                ToolTip = 'Opens a page where you choose records and see the file name they would get, and whether that name comes from this pattern, from another pattern, or is Business Central''s own file name.';
                ApplicationArea = All;
                Image = TestFile;

                trigger OnAction()
                var
                    TestPatternPage: Page "Report Filename Test";
                begin
                    // Not RunObject: the pattern is handed in, so the page cannot step through others.
                    TestPatternPage.SetPattern(Rec);
                    TestPatternPage.RunModal();
                end;
            }
            action(CopyPattern)
            {
                Caption = 'Copy';
                ToolTip = 'Creates a copy of the selected pattern, turned off, and opens it so you can change it - for example, to make a version for another output route or language.';
                ApplicationArea = All;
                Image = Copy;

                trigger OnAction()
                var
                    NewPattern: Record "Report Filename Pattern";
                begin
                    Rec.CopyToNewPattern(NewPattern);
                    Commit();
                    Page.Run(Page::"Report Filename Pattern Card", NewPattern);
                end;
            }
            action(EnablePatterns)
            {
                Caption = 'Enable';
                ToolTip = 'Turns on the selected patterns. A pattern must have a file name pattern and a report or a table before it can be turned on.';
                ApplicationArea = All;
                Image = Approve;

                trigger OnAction()
                begin
                    SetEnabledOnSelection(true);
                end;
            }
            action(DisablePatterns)
            {
                Caption = 'Disable';
                ToolTip = 'Turns off the selected patterns. They are kept, and name nothing until they are turned on again.';
                ApplicationArea = All;
                Image = Reject;

                trigger OnAction()
                begin
                    SetEnabledOnSelection(false);
                end;
            }
            action(ShowOverlappingPatterns)
            {
                Caption = 'Show overlapping patterns';
                ToolTip = 'Opens the patterns that could apply to the same files as the selected pattern, with their priorities, so you can see which one is used. Table filters are not compared, so use Test Pattern to check real records.';
                ApplicationArea = All;
                Image = FilterLines;
                Visible = not ShowingOverlap;

                trigger OnAction()
                begin
                    ShowOverlapping();
                end;
            }
        }
        area(Navigation)
        {
            action(Setup)
            {
                Caption = 'Setup';
                ToolTip = 'Opens the setup, where you turn file name patterns on or off and set the maximum file name length for all patterns.';
                ApplicationArea = All;
                Image = Setup;
                RunObject = page "Report Filename Setup";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(TestPattern_Promoted; TestPattern)
                {
                }
                actionref(CopyPattern_Promoted; CopyPattern)
                {
                }
                actionref(ShowOverlappingPatterns_Promoted; ShowOverlappingPatterns)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        RowStyle: Option None,Standard,StandardAccent,Strong,StrongAccent,Attention,AttentionAccent,Favorable,Unfavorable,Ambiguous,Subordinate;
    begin
        TableFilterText := Rec.GetTableFilterDisplayText();
        if TableFilterText = '' then
            TableFilterText := Rec.NoTableFilterText();
        RouteFilterText := Rec.OutputRouteFilterText();

        RowStyle := RowStyle::None;
        if not Rec.Enabled then
            RowStyle := RowStyle::Subordinate;
        RowStyleText := Format(RowStyle);

        // A pattern was added after the empty-list notification was shown.
        if EmptyStateShown then
            RecallEmptyStateNotification();
    end;

    trigger OnOpenPage()
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        if ShowingOverlap then
            NarrowToOverlap();

        // The switched-off notification takes precedence over the empty-list one.
        if ReportFilenameMgt.NotifyIfSwitchedOff() then
            exit;

        if Rec.IsEmpty() then
            ShowEmptyStateNotification();
    end;

    /// <summary>
    /// Validates each pattern as the card does; the error names the pattern, since several may be selected.
    /// </summary>
    local procedure SetEnabledOnSelection(NewEnabled: Boolean)
    var
        Pattern: Record "Report Filename Pattern";
        PatternName: Text;
    begin
        CurrPage.SetSelectionFilter(Pattern);
        if Pattern.FindSet(true) then
            repeat
                if Pattern.Enabled <> NewEnabled then begin
                    if not TryValidateEnabled(Pattern, NewEnabled) then begin
                        PatternName := Pattern.DisplayCaption();
                        if PatternName = '' then
                            PatternName := Pattern."File Name Pattern";
                        if PatternName = '' then
                            PatternName := UnnamedPatternLbl;
                        Error(CannotTurnOnErr, PatternName, GetLastErrorText());
                    end;
                    Pattern.Modify(true);
                end;
            until Pattern.Next() = 0;
        CurrPage.Update(false);
    end;

    [TryFunction]
    local procedure TryValidateEnabled(var Pattern: Record "Report Filename Pattern"; NewEnabled: Boolean)
    begin
        Pattern.Validate(Enabled, NewEnabled);
    end;

    /// <summary>
    /// When nothing competes, shows a message instead of a one-row list.
    /// </summary>
    local procedure ShowOverlapping()
    var
        Selected: Record "Report Filename Pattern";
        OverlapList: Page "Report Filename Patterns";
    begin
        Selected := Rec;
        if not Selected.HasCompetitor() then begin
            Message('%1', Selected.NothingCompetesMessage());
            exit;
        end;

        OverlapList.SetOverlapping(Selected);
        OverlapList.Run();
    end;

    /// <summary>
    /// Must be called before the page opens, when field visibility is read.
    /// </summary>
    internal procedure SetOverlapping(Selected: Record "Report Filename Pattern")
    begin
        OverlapWith := Selected;
        ShowingOverlap := true;
    end;

    /// <summary>
    /// Uses marks, because overlap compares two rows, which no field filter can express.
    /// </summary>
    local procedure NarrowToOverlap()
    begin
        Rec.ClearMarks();
        if Rec.FindSet() then
            repeat
                if OverlapWith.CanCompeteWith(Rec) then
                    Rec.Mark(true);
            until Rec.Next() = 0;
        Rec.MarkedOnly(true);
        if Rec.Get(OverlapWith."Entry No.") then;
        CurrPage.Caption(StrSubstNo(OverlapCaptionLbl, OverlapWith.DisplayCaption()));
    end;

    local procedure ShowEmptyStateNotification()
    var
        EmptyNotification: Notification;
    begin
        EmptyNotification.Id(EmptyStateNotificationId());
        EmptyNotification.Message(EmptyStateMsg);
        EmptyNotification.Scope(NotificationScope::LocalScope);
        EmptyNotification.Send();
        EmptyStateShown := true;
    end;

    /// <summary>
    /// A notification stays until dismissed, so it is recalled once a pattern is added.
    /// </summary>
    local procedure RecallEmptyStateNotification()
    var
        EmptyNotification: Notification;
    begin
        EmptyNotification.Id(EmptyStateNotificationId());
        EmptyNotification.Recall();
        EmptyStateShown := false;
    end;

    local procedure EmptyStateNotificationId(): Guid
    begin
        exit('9ab1117f-cce3-42a4-8b3b-457ac5c796bb');
    end;

    var
        OverlapWith: Record "Report Filename Pattern";
        TableFilterText: Text;
        RouteFilterText: Text;
        RowStyleText: Text;
        ShowingOverlap: Boolean;
        EmptyStateShown: Boolean;
        OverlapCaptionLbl: Label 'Patterns Overlapping %1', Comment = '%1 the pattern, as its card is titled';
        EmptyStateMsg: Label 'No file name patterns are set up. Every report gets Business Central''s own file name until you add one.';
        CannotTurnOnErr: Label '%1 cannot be turned on. %2', Comment = '%1 the pattern, %2 why it cannot';
        UnnamedPatternLbl: Label 'A pattern with nothing filled in';
}
