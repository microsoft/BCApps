// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using System.Reflection;

page 8127 "Report Filename Preview"
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
            }
            group(OverManyRecords)
            {
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

        if not ReportFilenamePreviewMgt.TryPreviewShape(Rec, ResultingFileName, Explanation) then
            ResultingFileName := KeepsExistingMsg;

        BuildMultipleRecordsExample();
        HasExplanation := Explanation <> '';
    end;

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
        HasManyRecordsExample: Boolean;
        HasExplanation: Boolean;
        AFewLbl: Label 'A few: %1', Comment = '%1 the file name when the run covers a few records';
        ManyLbl: Label 'Many: %1', Comment = '%1 the file name when the run covers more than are named individually';
        KeepsExistingMsg: Label 'This pattern cannot produce a name';
}
