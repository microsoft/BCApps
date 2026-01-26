// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using Microsoft.Sales.Customer;
using System.Utilities;

page 12147 "Customer Aging"
{
    Caption = 'Customer Aging';
    DataCaptionExpression = '';
    PageType = Card;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(RoundingFactor; RoundingFactor)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rounding Factor';
                    ToolTip = 'Specifies the rounding factor.';
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View By';
                    ToolTip = 'Specifies how you want to see the data.';

                    trigger OnValidate()
                    begin
                        // FindPeriod('');;
                        PeriodTypeOnAfterValidate();
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View as';
                    ToolTip = 'Specifies how you want to see the data.';
                }
                field(MATRIX_CaptionRange; MATRIX_CaptionRange)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Column Set';
                    Editable = false;
                    ToolTip = 'Specifies the column set.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Show Matrix")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'Generate the overview of customer aging amounts.';

                trigger OnAction()
                var
                    MatrixForm: Page "Customer Aging Matrix";
                begin
                    Clear(MatrixForm);
                    MatrixForm.Load(MATRIX_CaptionSet, MatrixRecords, MATRIX_CurrentNoOfColumns, RoundingFactor.AsInteger(), AmountType.AsInteger(),
                      Rec.GetFilter("Global Dimension 1 Filter"), Rec.GetFilter("Global Dimension 2 Filter"));
                    MatrixForm.RunModal();
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Next Set';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(SetWanted::Next);
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Previous Set';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(SetWanted::Previous);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Show Matrix_Promoted"; "&Show Matrix")
                {
                }
                actionref("Next Set_Promoted"; "Next Set")
                {
                }
                actionref("Previous Set_Promoted"; "Previous Set")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        MATRIX_GenerateColumnCaptions(SetWanted::Initial);
    end;

    var
        MatrixRecords: array[32] of Record Date;
        MATRIX_CaptionSet: array[32] of Text[1024];
        MATRIX_CaptionRange: Text[1024];
        MATRIX_PrimKeyFirstCaptionInCu: Text[1024];
        MATRIX_CurrentNoOfColumns: Integer;
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";
        RoundingFactor: Enum "Analysis Rounding Factor";
        MATRIX_CurrentSetLength: Integer;
        SetWanted: Option Initial,Previous,Same,Next;

    [Scope('OnPrem')]
    procedure MATRIX_GenerateColumnCaptions(SetWanted: Option Initial,Previous,Same,Next)
    var
        MatrixMgt: Codeunit "Matrix Management";
    begin
        MatrixMgt.GeneratePeriodMatrixData(SetWanted, ArrayLen(MATRIX_CaptionSet), false, PeriodType, Rec.GetFilter("Date Filter"),
          MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentSetLength, MatrixRecords);
    end;

    local procedure PeriodTypeOnAfterValidate()
    begin
        MATRIX_GenerateColumnCaptions(SetWanted::Initial);
    end;
}

