// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
page 50112 "Report Filename Preview"
{
    Caption = 'Example File Name';
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "Report Filename Pattern";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            field(ResultingFileName; ResultingFileName)
            {
                // No caption. The factbox is already called Example File Name, so a caption here
                // said the same thing twice - and truncated to "Resulting file ..." it said it
                // badly. The value is the whole content of the box.
                ShowCaption = false;
                ToolTip = 'Specifies an example of the file name this pattern produces. The values show the form each value takes and are not read from any record, so the example works before any records exist. Use Test Pattern to try the pattern on real records.';
                ApplicationArea = All;
                MultiLine = true;
                StyleExpr = ResultStyle;
            }
            // A run over many records collapses every value read off the records into a
            // first-to-last range, so the same pattern produces a different name. Showing only
            // the single-record form advertised a name that a report printing a list will never
            // produce. Both are shapes; neither reads a document.
            group(OverManyRecords)
            {
                // The caption belongs on the GROUP, not on the field. A factbox is narrow, and a
                // field caption there is given a fixed share of that width and truncated to fit -
                // the wording came out as "Ov...". A group caption gets a line of its own across
                // the whole box, which is the only place a phrase fits.
                //
                // Captioned as the pattern card captions its own group, because both are groups
                // and Business Central captions a group with a short noun phrase. "Over several
                // records" reads as a column header - which is exactly what it is on the placeholder
                // list, where it heads a column saying what each placeholder turns into. One idea,
                // two places, two jobs: a noun phrase names a group, and the longer wording
                // describes behaviour wherever behaviour is being described.
                Caption = 'Multiple Records';
                Visible = HasManyRecordsExample;

                field(OverManyRecordsName; OverManyRecordsName)
                {
                    ShowCaption = false;
                    ToolTip = 'Specifies an example of the file name when the report is run for several records at once. Where the run covers no more than the number named individually the values are listed; beyond that they collapse to a first-to-last range. Both are shown when a pattern can produce both.';
                    ApplicationArea = All;
                    MultiLine = true;
                }
            }
            // A group, not the field itself. A field's Visible cannot change after the page
            // opens - Microsoft documents dynamic visibility for group, part and action controls
            // only - so the expression that used to sit on this field was evaluated once, while
            // the explanation was still empty, and the note could never appear.
            group(Notes)
            {
                ShowCaption = false;
                Visible = HasExplanation;

                field(Explanation; Explanation)
                {
                    // Not shown, for the reason the two fields above already give: a factbox is
                    // narrow, a field caption there is truncated to whatever share of the width
                    // it is given, and "Notes" came out as a bare "N" sitting beside the text.
                    // The caption is kept because it is what a screen reader announces; only its
                    // display is suppressed.
                    ShowCaption = false;
                    Caption = 'Notes';
                    ToolTip = 'Explains why the pattern cannot produce a name, when it cannot.';
                    ApplicationArea = All;
                    MultiLine = true;
                    StyleExpr = 'Ambiguous';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        ResultingFileName := '';
        Explanation := '';
        OverManyRecordsName := '';

        // The shape, not a real document. A company on its first day has no invoice to preview
        // against, an administrator may have no permission to read one, and reading one would
        // put somebody's real figures on a setup card - a real person's pay, for a payroll
        // report. Test Pattern is the deliberate act that uses real data.
        if ReportFilenamePreviewMgt.TryPreviewShape(Rec, ResultingFileName, Explanation) then
            ResultStyle := 'Favorable'
        else begin
            ResultingFileName := KeepsExistingMsg;
            ResultStyle := 'Ambiguous';
        end;

        BuildMultipleRecordsExample();
        HasExplanation := Explanation <> '';
    end;

    /// <summary>
    /// The example for a run covering several records.
    ///
    /// There are two shapes, not one, and which applies depends on how many records the run
    /// covers: the values are listed while there are no more than the pattern names
    /// individually, and collapse to first-to-last beyond that. Showing only the collapsed form
    /// told an administrator naming three individually that a run over two produces a range,
    /// which it does not.
    ///
    /// Both go into one field, on two lines, because a factbox is too narrow to caption two
    /// fields - the caption gets a fixed share of the width and is truncated, which is why the
    /// group carries the caption here and the field carries none. Where only one shape exists
    /// it is shown alone and unlabelled, exactly as before.
    /// </summary>
    local procedure BuildMultipleRecordsExample()
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        TypeHelper: Codeunit "Type Helper";
        AFewRecords: Text;
        ManyRecords: Text;
        HasFew: Boolean;
        HasMany: Boolean;
    begin
        OverManyRecordsName := '';

        HasFew := ReportFilenamePreviewMgt.TryPreviewShapeOverAFewRecords(Rec, AFewRecords);
        HasMany := ReportFilenamePreviewMgt.TryPreviewShapeOverManyRecords(Rec, ManyRecords);

        HasManyRecordsExample := HasFew or HasMany;

        case true of
            HasFew and HasMany and (AFewRecords <> ManyRecords):
                OverManyRecordsName :=
                    StrSubstNo(AFewLbl, AFewRecords) + TypeHelper.NewLine() + StrSubstNo(ManyLbl, ManyRecords);
            HasMany:
                OverManyRecordsName := ManyRecords;
            HasFew:
                OverManyRecordsName := AFewRecords;
        end;
    end;

    var
        ResultingFileName: Text;
        OverManyRecordsName: Text;
        Explanation: Text;
        ResultStyle: Text;
        HasManyRecordsExample: Boolean;
        HasExplanation: Boolean;
        AFewLbl: Label 'A few: %1', Comment = '%1 the file name when the run covers a few records';
        ManyLbl: Label 'Many: %1', Comment = '%1 the file name when the run covers more than are named individually';
        KeepsExistingMsg: Label 'This pattern cannot produce a name';
}
