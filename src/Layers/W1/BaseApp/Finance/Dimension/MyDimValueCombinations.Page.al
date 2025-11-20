// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;

page 9252 "MyDim Value Combinations"
{
    Caption = 'Dimension Value Combinations';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ShowColumnName; ShowColumnName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Show Column Name';
                    ToolTip = 'Specifies that the names of columns are shown in the matrix window.';

                    trigger OnValidate()
                    begin
                        ShowColumnNameOnPush();
                    end;
                }
            }
            part(MatrixForm; "Dim. Value Combinations Matrix")
            {
                ApplicationArea = Suite;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(PreviousSet)
            {
                ApplicationArea = Suite;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions("Matrix Page Step Type"::Previous);
                    UpdateMatrixSubform();
                end;
            }
            action(PreviousColumn)
            {
                ApplicationArea = Suite;
                Caption = 'Previous Column';
                Image = PreviousRecord;
                ToolTip = 'Go to the previous column.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions("Matrix Page Step Type"::PreviousColumn);
                    UpdateMatrixSubform();
                end;
            }
            action(NextColumn)
            {
                ApplicationArea = Suite;
                Caption = 'Next Column';
                Image = NextRecord;
                ToolTip = 'Go to the next column.';

                trigger OnAction()
                begin
                    // SetPoints(3);
                    GenerateColumnCaptions("Matrix Page Step Type"::NextColumn);
                    UpdateMatrixSubform();
                end;
            }
            action(NextSet)
            {
                ApplicationArea = Suite;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    // SetPoints(3);
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

                actionref(PreviousSet_Promoted; PreviousSet)
                {
                }
                actionref(PreviousColumn_Promoted; PreviousColumn)
                {
                }
                actionref(NextColumn_Promoted; NextColumn)
                {
                }
                actionref(NextSet_Promoted; NextSet)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        MaximumNoOfCaptions := ArrayLen(MATRIX_CaptionSet);
        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        UpdateMatrixSubform();
    end;

    var
        MatrixRecords: array[32] of Record "Dimension Value";
        MatrixRecord: Record "Dimension Value";
        DimensionValueCombination: Record "Dimension Value Combination";
        MatrixMgm: Codeunit "Matrix Management";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_ColumnSet: Text;
        MATRIX_CaptionFieldNo: Integer;
        ShowColumnName: Boolean;
        MaximumNoOfCaptions: Integer;
        PrimaryKeyFirstCaptionInCurrSe: Text;
        Row: Code[20];
        MATRIX_CurrSetLength: Integer;

    procedure SetSelectedDimValueComb(NewDimensionValueCombination: Record "Dimension Value Combination")
    begin
        DimensionValueCombination := NewDimensionValueCombination;
        Load(
          DimensionValueCombination."Dimension 1 Code", DimensionValueCombination."Dimension 2 Code", true);
    end;

    procedure Load(_Row: Code[20]; _Column: Code[20]; _ShowColumnName: Boolean)
    begin
        Row := _Row;
        ShowColumnName := _ShowColumnName;
        MatrixRecord.SetRange("Dimension Code", _Column);

        OnAfterLoad(MatrixRecord, _Row, _Column, _ShowColumnName);
    end;

    local procedure GenerateColumnCaptions(StepType: Enum "Matrix Page Step Type")
    var
        RecRef: RecordRef;
        CurrentMatrixRecordOrdinal: Integer;
    begin
        OnBeforeGenerateColumnCaptions(MatrixRecord, StepType);

        if DimensionValueCombination."Dimension 2 Code" <> '' then
            MatrixRecord.SetRange(Code, DimensionValueCombination."Dimension 2 Value Code");
        RecRef.GetTable(MatrixRecord);
        if ShowColumnName then
            MATRIX_CaptionFieldNo := 3
        else
            MATRIX_CaptionFieldNo := 2;

        MatrixMgm.GenerateMatrixData(
            RecRef, StepType.AsInteger(), MaximumNoOfCaptions, MATRIX_CaptionFieldNo, PrimaryKeyFirstCaptionInCurrSe,
            MATRIX_CaptionSet, MATRIX_ColumnSet, MATRIX_CurrSetLength);
        Clear(MatrixRecords);
        MatrixRecord.SetPosition(PrimaryKeyFirstCaptionInCurrSe);
        repeat
            CurrentMatrixRecordOrdinal += 1;
            MatrixRecords[CurrentMatrixRecordOrdinal].Copy(MatrixRecord);
        until (CurrentMatrixRecordOrdinal = ArrayLen(MatrixRecords)) or (MatrixRecord.Next() <> 1);
    end;

    local procedure UpdateMatrixSubform()
    begin
        CurrPage.MatrixForm.PAGE.SetSelectedDimValue(DimensionValueCombination."Dimension 1 Value Code");
        CurrPage.MatrixForm.PAGE.Load(MATRIX_CaptionSet, MatrixRecords, Row, MATRIX_CurrSetLength);
        CurrPage.Update(false);
    end;

    local procedure ShowColumnNameOnPush()
    begin
        GenerateColumnCaptions("Matrix Page Step Type"::Same);
        UpdateMatrixSubform();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLoad(var MatrixRecordDimensionValue: Record "Dimension Value"; _Row: Code[20]; _Column: Code[20]; _ShowColumnName: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateColumnCaptions(var MatrixRecordDimensionValue: Record "Dimension Value"; StepType: Enum "Matrix Page Step Type")
    begin
    end;
}

