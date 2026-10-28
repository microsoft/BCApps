// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

page 8126 "Report Filename Pattern Card"
{
    Caption = 'Report Filename Pattern';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Report Filename Pattern";
    DataCaptionExpression = Rec.DisplayCaption();

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(ReportName; Rec."Report Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowMandatory = false;

                    trigger OnAssistEdit()
                    begin
                        // Assist-edits must commit before opening a modal lookup.
                        CurrPage.SaveRecord();
                        Commit();
                        Rec.LookupReport();
                        // Update(true): LookupReport validates without Modify, so the change
                        // still has to be saved.
                        Rec.CalcFields(Rec."Report Name", Rec."Table Caption");
                        CurrPage.Update(true);
                    end;
                }
                field(TableCaption; Rec."Table Caption")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowMandatory = false;

                    trigger OnAssistEdit()
                    begin
                        CurrPage.SaveRecord();
                        Commit();
                        Rec.LookupTable();
                        Rec.CalcFields(Rec."Report Name", Rec."Table Caption");
                        CurrPage.Update(true);
                    end;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
            }
            group(Conditions)
            {
                Caption = 'Conditions';

                field(TableFilterText; TableFilterText)
                {
                    Caption = 'Table Filter';
                    ToolTip = 'Specifies a filter the records must match for this pattern to apply, such as a reminder level. Choose the fields and values on the filter page rather than typing a filter.';
                    ApplicationArea = All;
                    Editable = false;
                    ShowMandatory = false;

                    trigger OnAssistEdit()
                    begin
                        // The lookup writes the Blob with Modify, so the row must exist.
                        CurrPage.SaveRecord();
                        Commit();
                        Rec.LookupTableFilter();
                        // Update(false): the lookup has already saved the record.
                        CurrPage.Update(false);
                    end;
                }
                field(RouteFilterText; RouteFilterText)
                {
                    Caption = 'Output Route Filter';
                    // Same tooltip as the table field this shows. Change them together.
                    ToolTip = 'Specifies which ways out of Business Central this pattern applies to, such as Print|Preview. All routes when it is blank. Choose the field to select routes; each one says what produces a file on it.';
                    ApplicationArea = All;
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        CurrPage.SaveRecord();
                        Commit();
                        Rec.LookupOutputRouteFilter();
                        CurrPage.Update(false);
                    end;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = All;
                }
                field(LanguageCodeField; LanguageFieldName)
                {
                    // Keep the caption and tooltip in sync with the table field.
                    Caption = 'Language Code Field';
                    ToolTip = 'Specifies which field on the table holds the language of the record: a field that relates to the Language table. Where a run covers several records, they must all have the same language, or the run has none. Suggested when the table has one such field.';
                    ApplicationArea = All;
                    Importance = Additional;
                    Editable = false;
                    ShowMandatory = false;

                    trigger OnAssistEdit()
                    begin
                        CurrPage.SaveRecord();
                        Commit();
                        Rec.LookupLanguageCodeField();
                        // Update(true): LookupLanguageCodeField validates without Modify, so the
                        // change still has to be saved.
                        CurrPage.Update(true);
                    end;
                }
            }
            group(FileName)
            {
                Caption = 'File Name';

                field("File Name Pattern"; Rec."File Name Pattern")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                }
                field("Date Format"; Rec."Date Format")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        UpdateDateExample();
                    end;
                }
                field(DateExample; DateExample)
                {
                    Caption = 'Date Example';
                    ToolTip = 'Specifies how a date is written in the file name with the chosen format. It is the same for every user and every language, so a file name means the same thing to everyone who receives it.';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(SeveralDocuments)
            {
                Caption = 'Multiple Records';
                InstructionalText = 'A file name normally identifies one record. These settings apply only when one file covers several records - for example, when you run the report for a range of invoices or for several customers. They decide how many different values each placeholder lists, what goes between them, and the word that joins the first and the last value when there are too many to name. A report run for a single record never uses them.';

                field("Max. Values Named"; Rec."Max. Values Named")
                {
                    ApplicationArea = All;
                }
                field("Separator"; Rec."Separator")
                {
                    ApplicationArea = All;
                }
                field("Range Word"; Rec."Range Word")
                {
                    ApplicationArea = All;
                }
            }
        }
        area(FactBoxes)
        {
            part(Preview; "Report Filename Preview")
            {
                // Overrides the part page's caption, so keep them the same.
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
            action(AvailablePlaceholders)
            {
                Caption = 'Available Placeholders';
                ToolTip = 'Shows the placeholders this report and table can supply, and adds the one you choose to the end of the file name pattern. To put it somewhere else, move it within the file name pattern afterwards.';
                ApplicationArea = All;
                Image = SelectField;

                trigger OnAction()
                var
                    TempChosenPlaceholder: Record "Report Filename Plh. Buffer" temporary;
                    ReportFilenamePlaceholders: Page "Report Filename Placeholders";
                begin
                    CurrPage.SaveRecord();
                    Commit();

                    ReportFilenamePlaceholders.SetContext(Rec);
                    ReportFilenamePlaceholders.LookupMode(true);
                    if ReportFilenamePlaceholders.RunModal() <> Action::LookupOK then
                        exit;

                    ReportFilenamePlaceholders.GetRecord(TempChosenPlaceholder);
                    AppendPlaceholder(TempChosenPlaceholder.Placeholder);
                end;
            }
            action(ClearReport)
            {
                Caption = 'Clear report';
                ToolTip = 'Removes the report from this pattern and keeps its table, so the pattern applies to every report on that table.';
                ApplicationArea = All;
                Image = ClearFilter;
                Enabled = Rec."Report ID" <> 0;

                trigger OnAction()
                begin
                    Rec.ClearReport();
                    Rec.CalcFields(Rec."Report Name", Rec."Table Caption");
                    CurrPage.Update(true);
                end;
            }
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
                    // Persist this pattern so the test page includes it when selecting a winner.
                    // Commit before RunModal to leave the write transaction.
                    CurrPage.SaveRecord();
                    Commit();

                    TestPatternPage.SetPattern(Rec);
                    TestPatternPage.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(AvailablePlaceholders_Promoted; AvailablePlaceholders)
                {
                }
                actionref(TestPattern_Promoted; TestPattern)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        // Also here, not only on the list: a LocalScope notification appears on the page the user
        // is working on.
        ReportFilenameMgt.NotifyIfSwitchedOff();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateDateExample();
        Rec.CalcFields(Rec."Report Name", Rec."Table Caption");
        LanguageFieldName := Rec.LanguageCodeFieldCaption();
        TableFilterText := Rec.GetTableFilterDisplayText();
        if TableFilterText = '' then
            TableFilterText := Rec.NoTableFilterText();
        RouteFilterText := Rec.OutputRouteFilterText();
    end;

    /// <summary>
    /// Appends, because AL exposes no caret position in a text field. Validated so the binding is
    /// rebuilt and checked now.
    /// </summary>
    /// <param name="Placeholder">Brackets included.</param>
    local procedure AppendPlaceholder(Placeholder: Text)
    begin
        if Placeholder = '' then
            exit;

        // Refused rather than truncated, which would cut off the closing bracket.
        if StrLen(Rec."File Name Pattern") + StrLen(Placeholder) > MaxStrLen(Rec."File Name Pattern") then
            Error(PatternTooLongErr, Placeholder, MaxStrLen(Rec."File Name Pattern"));

        Rec.Validate("File Name Pattern", CopyStr(Rec."File Name Pattern" + Placeholder, 1, MaxStrLen(Rec."File Name Pattern")));
        CurrPage.Update(true);
    end;

    local procedure UpdateDateExample()
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        DateExample := ReportFilenameMgt.FormatSampleDate(Rec."Date Format");
    end;

    var
        DateExample: Text;
        TableFilterText: Text;
        RouteFilterText: Text;
        LanguageFieldName: Text;
        PatternTooLongErr: Label 'Adding %1 would make the file name pattern longer than the %2 characters it can hold. Shorten the file name pattern first.', Comment = '%1 the placeholder that was chosen, %2 the maximum length';
}
