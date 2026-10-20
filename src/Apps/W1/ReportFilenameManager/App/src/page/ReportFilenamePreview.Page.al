// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
page 43002 "Report Filename Preview"
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
                ShowCaption = false;
                ToolTip = 'Specifies an example of the file name this pattern produces. The values show the form each value takes and are not read from any record, so the example works before any records exist. Use Test Pattern to try the pattern on real records.';
                ApplicationArea = All;
                MultiLine = true;
                StyleExpr = ResultStyle;
            }
            // A run over many records produces a different name than a single-record run.
            group(OverManyRecords)
            {
                // Caption on the group; the field shows none.
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
            // Visible is on a group because a field's Visible is not re-evaluated after the page opens.
            group(Notes)
            {
                ShowCaption = false;
                Visible = HasExplanation;

                field(Explanation; Explanation)
                {
                    // Not shown; the caption still names the control.
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

        // Shaped without a document, so no record's values are shown. Test Pattern is the action
        // that uses real records.
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
    /// A few records are listed individually; beyond the pattern's limit they collapse to a
    /// first-to-last range. Both forms share one field.
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
