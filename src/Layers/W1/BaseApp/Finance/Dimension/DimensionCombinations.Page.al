// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;

page 538 "Dimension Combinations"
{
    ApplicationArea = Dimensions;
    Caption = 'Dimension Combinations';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = Dimension;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ShowColumnName; ShowColumnName)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show Column Name';
                    ToolTip = 'Specifies that the names of columns are shown in the matrix window.';

                    trigger OnValidate()
                    begin
                        ShowColumnNameOnPush();
                        ShowColumnNameOnAfterValidate();
                    end;
                }
            }
            part(MatrixForm; "Dimension Combinations Matrix")
            {
                ApplicationArea = Dimensions;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Previous Set")
            {
                ApplicationArea = Dimensions;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    // SetPoints(Direction::Backward);
                    GenerateColumnCaptions("Matrix Page Step Type"::Previous);
                    UpdateMatrixSubform();
                end;
            }
            action("Previous Column")
            {
                ApplicationArea = Dimensions;
                Caption = 'Previous Column';
                Image = PreviousRecord;
                ToolTip = 'Go to the previous column.';

                trigger OnAction()
                begin
                    // SetPoints(Direction::Backward);
                    GenerateColumnCaptions("Matrix Page Step Type"::PreviousColumn);
                    UpdateMatrixSubform();
                end;
            }
            action("Next Column")
            {
                ApplicationArea = Dimensions;
                Caption = 'Next Column';
                Image = NextRecord;
                ToolTip = 'Go to the next column.';

                trigger OnAction()
                begin
                    // SetPoints(Direction::Forward);
                    GenerateColumnCaptions("Matrix Page Step Type"::NextColumn);
                    UpdateMatrixSubform();
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Dimensions;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    // SetPoints(Direction::Forward);
                    GenerateColumnCaptions("Matrix Page Step Type"::Next);
                    UpdateMatrixSubform();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Previous Set_Promoted"; "Previous Set")
                {
                }
                actionref("Previous Column_Promoted"; "Previous Column")
                {
                }
                actionref("Next Column_Promoted"; "Next Column")
                {
                }
                actionref("Next Set_Promoted"; "Next Set")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.Name := Rec.GetMLName(GlobalLanguage);
    end;

    trigger OnOpenPage()
    begin
        MaximumNoOfCaptions := ArrayLen(MATRIX_CaptionSet);
        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        UpdateMatrixSubform();
    end;

    var
        MatrixRecords: array[32] of Record Dimension;
        MatrixRecord: Record Dimension;
        SelectedDimensionCombination: Record "Dimension Combination";
        MatrixMgm: Codeunit "Matrix Management";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_ColumnSet: Text;
        MATRIX_CaptionFieldNo: Integer;
        ShowColumnName: Boolean;
        MaximumNoOfCaptions: Integer;
        PrimaryKeyFirstCaptionInCurrSe: Text;
        MATRIX_CurrSetLength: Integer;
        NoDimensionsErr: Label 'No dimensions are available in the database.';

    local procedure GenerateColumnCaptions(StepType: Enum "Matrix Page Step Type")
    var
        RecRef: RecordRef;
        CurrentMatrixRecordOrdinal: Integer;
    begin
        if SelectedDimensionCombination."Dimension 2 Code" <> '' then
            MatrixRecord.SetRange(Code, SelectedDimensionCombination."Dimension 2 Code");
        RecRef.GetTable(MatrixRecord);

        if RecRef.IsEmpty() then
            Error(NoDimensionsErr);

        if ShowColumnName then
            MATRIX_CaptionFieldNo := 2
        else
            MATRIX_CaptionFieldNo := 1;

        MatrixMgm.GenerateMatrixData(RecRef, StepType.AsInteger(), MaximumNoOfCaptions, MATRIX_CaptionFieldNo, PrimaryKeyFirstCaptionInCurrSe,
          MATRIX_CaptionSet, MATRIX_ColumnSet, MATRIX_CurrSetLength);

        Clear(MatrixRecords);
        MatrixRecord.SetPosition(PrimaryKeyFirstCaptionInCurrSe);
        CurrentMatrixRecordOrdinal := 1;
        repeat
            MatrixRecords[CurrentMatrixRecordOrdinal].Copy(MatrixRecord);
            CurrentMatrixRecordOrdinal := CurrentMatrixRecordOrdinal + 1;
        until (CurrentMatrixRecordOrdinal = ArrayLen(MatrixRecords)) or (MatrixRecord.Next() <> 1);
    end;

    local procedure UpdateMatrixSubform()
    begin
        CurrPage.MatrixForm.PAGE.SetSelectedDimCode(SelectedDimensionCombination."Dimension 1 Code");
        CurrPage.MatrixForm.PAGE.Load(MATRIX_CaptionSet, MatrixRecords, ShowColumnName);
        CurrPage.Update(false);
    end;

    procedure SetSelectedRecord(DimensionCombination: Record "Dimension Combination")
    begin
        SelectedDimensionCombination := DimensionCombination;
    end;

    local procedure ShowColumnNameOnAfterValidate()
    begin
        UpdateMatrixSubform();
    end;

    local procedure ShowColumnNameOnPush()
    begin
        GenerateColumnCaptions("Matrix Page Step Type"::Same);
        UpdateMatrixSubform();
    end;
}

