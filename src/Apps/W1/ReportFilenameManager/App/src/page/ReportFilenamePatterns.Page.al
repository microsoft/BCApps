// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
page 50110 "Report Filename Patterns"
{
    Caption = 'Report Filename Patterns';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    // Tell Me matches whole words, and an administrator looking for this is as likely to type
    // "file name" as the product's own one-word spelling.
    AdditionalSearchTerms = 'file name, file names, document name, PDF name, attachment name, email attachment name, report naming';
    SourceTable = "Report Filename Pattern";
    // Grouped by table, so the patterns that can compete for the same files sit together. It used
    // to open in the order rows were created.
    SourceTableView = sorting("Table No.", "Report ID", "Language Code");
    CardPageId = "Report Filename Pattern Card";
    // Read-only, as 187 of Base Application's list pages with a card page are - Customer List
    // among them. A pattern is authored with Available Placeholders and five assist-edits, none
    // of which a grid can offer, so the card is the only editing surface. The card opens from
    // the first column, exactly as a customer does.
    //
    // There is no Edit action. There was one, bound to Enter, and it matched none of those 187
    // pages: 180 add no action for opening the card at all, and the other seven caption theirs
    // Card. Counted from the Base Application 28.4 source on 28 September 2026.
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
                // Third, and dimmed rows behind it, following the closest thing Microsoft ships:
                // Quality Management's Inspection Source Configuration list, which also says what
                // applies to which records through a filter. It puts Enabled straight after the
                // identifying columns and styles every field in the row, so a row that is turned
                // off reads as off at a glance. Here it used to be the eighth column, which
                // in practice meant off the right-hand edge - a pattern could sit there doing
                // nothing with no visible sign of it.
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    StyleExpr = RowStyleText;
                }
                // Which pattern wins when several apply to one file, worked out by the same
                // procedure naming uses, so the two cannot disagree. Shown only where patterns are
                // compared - the list Show Overlapping Patterns opens - because beside a pattern that
                // competes with nothing the number means nothing and reads as a setting to manage.
                // That list is told it is the overlap view before it opens, since a field's
                // visibility is read only when its page opens (Microsoft Learn, Visible property).
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
                Caption = 'Test Pattern';
                ToolTip = 'Opens a page where you choose records and see the file name they would get, and whether that name comes from this pattern, from another pattern, or is Business Central''s own file name.';
                ApplicationArea = All;
                Image = TestFile;

                trigger OnAction()
                var
                    TestPatternPage: Page "Report Filename Test";
                begin
                    // Run in code rather than with RunObject, so that it opens modally, and so
                    // that the pattern is handed in: the page holds no record of its own, which is
                    // what stops it offering to step through the other patterns.
                    TestPatternPage.SetPattern(Rec);
                    TestPatternPage.RunModal();
                end;
            }
            // The list is read-only on purpose, so without these every copy, and every pattern
            // turned on or off, meant opening its card - tedious once patterns are multiplied
            // across output routes and languages.
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
            // Answers "what else could name this file?" from the list, for a pattern at a time, in
            // a list of its own where Priority says which of them wins. Close it to return.
            action(ShowOverlappingPatterns)
            {
                Caption = 'Show Overlapping Patterns';
                ToolTip = 'Opens the patterns that could apply to the same files as the selected pattern, with their priorities, so you can see which one is used. Table filters are not compared, so use Test Pattern to check real records.';
                ApplicationArea = All;
                Image = FilterLines;
                // Not offered inside the overlap list itself, which already is the answer.
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
        // The same words the card shows for the same row. The list used to show nothing here.
        if TableFilterText = '' then
            TableFilterText := Rec.NoTableFilterText();
        RouteFilterText := Rec.OutputRouteFilterText();

        RowStyle := RowStyle::None;
        if not Rec.Enabled then
            RowStyle := RowStyle::Subordinate;
        RowStyleText := Format(RowStyle);
    end;

    trigger OnOpenPage()
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        if ShowingOverlap then
            NarrowToOverlap();

        // Turned off comes first: with the feature off, no pattern names anything, and an
        // administrator looking at a list of enabled patterns would otherwise have no way to know.
        if ReportFilenameMgt.NotifyIfSwitchedOff() then
            exit;

        if Rec.IsEmpty() then
            ShowEmptyStateNotification();
    end;

    /// <summary>
    /// Turns the selected patterns on or off. Each is checked as the card checks it, so a pattern
    /// that is not complete cannot be turned on from here either - and the refusal names the
    /// pattern, because with several selected the card's own message would not say which.
    /// </summary>
    /// <param name="NewEnabled">True to turn the patterns on, false to turn them off.</param>
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
    /// Opens the patterns that could compete with the selected one, the selected one included, in
    /// a list of their own with Priority. When nothing else could apply, it says so and opens
    /// nothing: a list of the one row would read as a filter gone wrong.
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
    /// Makes this list the overlap view for a pattern: only the patterns that could compete with
    /// it, with Priority shown. Called before the page opens, which is when a field's visibility
    /// is read.
    /// </summary>
    /// <param name="Selected">The pattern whose competitors are shown.</param>
    internal procedure SetOverlapping(Selected: Record "Report Filename Pattern")
    begin
        OverlapWith := Selected;
        ShowingOverlap := true;
    end;

    /// <summary>
    /// Narrows the list to the patterns that could compete with OverlapWith, it included. Marks
    /// rather than a filter, because what overlaps is a comparison between two rows, which no
    /// field filter can express. Choosing the All view in the filter pane opens the page afresh,
    /// so it becomes the ordinary list - every pattern, under its own title, without Priority -
    /// as a list Business Central opens from a cue becomes unfiltered when its filter is removed.
    /// A filter handed in with SetTableView does not survive that either (measured in the
    /// container client on 8 October); only an action's own RunPageLink does.
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
        EmptyNotification.Message(EmptyStateMsg);
        EmptyNotification.Scope(NotificationScope::LocalScope);
        EmptyNotification.Send();
    end;

    var
        OverlapWith: Record "Report Filename Pattern";
        TableFilterText: Text;
        RouteFilterText: Text;
        RowStyleText: Text;
        ShowingOverlap: Boolean;
        OverlapCaptionLbl: Label 'Patterns Overlapping %1', Comment = '%1 the pattern, as its card is titled';
        EmptyStateMsg: Label 'No file name patterns are set up. Every report gets Business Central''s own file name until you add one.';
        CannotTurnOnErr: Label '%1 cannot be turned on. %2', Comment = '%1 the pattern, %2 why it cannot';
        UnnamedPatternLbl: Label 'A pattern with nothing filled in';
}
