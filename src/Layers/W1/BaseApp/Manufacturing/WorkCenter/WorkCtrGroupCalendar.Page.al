// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.WorkCenter;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Setup;
using System.Utilities;

page 99000771 "Work Ctr. Group Calendar"
{
    Caption = 'Work Ctr. Group Calendar';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Work Center Group";

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
                field(CapacityUoM; CapacityUoM)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Capacity Shown In';
                    TableRelation = "Capacity Unit of Measure".Code;
                    ToolTip = 'Specifies how the capacity is shown (minutes, days, or hours).';
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
                    MatrixForm: Page "Work Ctr. Grp. Calendar Matrix";
                begin
                    Clear(MatrixForm);
                    MatrixForm.Load(MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentSetLenght, CapacityUoM);
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

                actionref(ShowMatrix_Promoted; ShowMatrix)
                {
                }
                actionref("Previous Set_Promoted"; "Previous Set")
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
        MfgSetup.Get();
        MfgSetup.TestField("Show Capacity In");
        CapacityUoM := MfgSetup."Show Capacity In";
    end;

    var
        MATRIX_MatrixRecords: array[32] of Record Date;
        MfgSetup: Record "Manufacturing Setup";
        MatrixMgt: Codeunit "Matrix Management";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_CaptionRange: Text;
        MATRIX_PrimKeyFirstCaptionInCu: Text;
        MATRIX_CurrentSetLenght: Integer;
        MATRIX_UseNameForCaption: Boolean;
        MATRIX_DateFilter: Text;
        PeriodType: Enum "Analysis Period Type";
        CapacityUoM: Code[10];

    local procedure GenerateColumnCaptions(StepType: Enum "Matrix Page Step Type")
    begin
        MatrixMgt.GeneratePeriodMatrixData(
            StepType.AsInteger(), ArrayLen(MATRIX_CaptionSet), MATRIX_UseNameForCaption, PeriodType, MATRIX_DateFilter,
            MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentSetLenght, MATRIX_MatrixRecords);
    end;
}

