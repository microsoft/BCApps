// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.WorkCenter;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using System.Utilities;

page 99000769 "Work Center Calendar"
{
    Caption = 'Work Center Calendar';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Work Center";

    layout
    {
        area(content)
        {
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Initial);
                    end;
                }
                field(MATRIX_CaptionRange; MATRIX_CaptionRange)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Column Set';
                    Editable = false;
                    ToolTip = 'Specifies the range of values that are displayed in the matrix window, for example, the total period. To change the contents of the field, choose Next Set or Previous Set.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowMatrix)
            {
                ApplicationArea = Manufacturing;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "Work Center Calendar Matrix";
                begin
                    Clear(MatrixForm);
                    MatrixForm.Load(MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns);
                    MatrixForm.SetTableView(Rec);
                    MatrixForm.RunModal();
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Previous);
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Next);
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
                actionref(ShowMatrix_Promoted; ShowMatrix)
                {
                }
                actionref("Next Set_Promoted"; "Next Set")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Initial);
        MATRIX_UseNameForCaption := false;
        MATRIX_CurrentSetLenght := ArrayLen(MATRIX_CaptionSet);
    end;

    var
        MATRIX_MatrixRecords: array[32] of Record Date;
        MatrixMgt: Codeunit "Matrix Management";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_CaptionRange: Text;
        MATRIX_PrimKeyFirstCaptionInCu: Text;
        MATRIX_CurrentNoOfColumns: Integer;
        MATRIX_UseNameForCaption: Boolean;
        MATRIX_DateFilter: Text;
        MATRIX_CurrentSetLenght: Integer;
        PeriodType: Enum "Analysis Period Type";

    local procedure GenerateColumnCaptions(StepType: Enum "Matrix Page Step Type")
    begin
        MatrixMgt.GeneratePeriodMatrixData(
            StepType.AsInteger(), ArrayLen(MATRIX_CaptionSet), MATRIX_UseNameForCaption, PeriodType, MATRIX_DateFilter,
            MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentSetLenght, MATRIX_MatrixRecords);
    end;
}

