// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Absence;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using Microsoft.HumanResources.Employee;
using System.Utilities;

page 5225 "Absence Overview by Periods"
{
    Caption = 'Absence Overview by Periods';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = Employee;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field("Cause Of Absence Filter"; CauseOfAbsenceFilter)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Cause of Absence Filter';
                    TableRelation = "Cause of Absence";
                    ToolTip = 'Specifies the absence causes that will be included in the overview.';
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        SetMatrixColumns("Matrix Page Step Type"::Initial);
                    end;
                }
                field(QtyType; QtyType)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';
                }
                field(ColumnSet; ColumnSet)
                {
                    ApplicationArea = BasicHR;
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
                ApplicationArea = BasicHR;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    AbsOverviewByPeriodMatrix: Page "Abs. Overview by Period Matrix";
                begin
                    AbsOverviewByPeriodMatrix.LoadMatrix(MatrixColumnCaptions, MatrixRecords, CauseOfAbsenceFilter, QtyType);
                    AbsOverviewByPeriodMatrix.RunModal();
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = BasicHR;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    SetMatrixColumns("Matrix Page Step Type"::Previous);
                end;
            }
            action("Next Set")
            {
                ApplicationArea = BasicHR;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    SetMatrixColumns("Matrix Page Step Type"::Next);
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
        SetMatrixColumns("Matrix Page Step Type"::Initial);
        if Rec.HasFilter then
            CauseOfAbsenceFilter := Rec.GetFilter("Cause of Absence Filter");
    end;

    var
        MatrixRecords: array[32] of Record Date;
        QtyType: Enum "Analysis Amount Type";
        PeriodType: Enum "Analysis Period Type";
        CauseOfAbsenceFilter: Code[10];
        MatrixColumnCaptions: array[32] of Text[1024];
        ColumnSet: Text[1024];
        PKFirstRecInCurrSet: Text[100];
        CurrSetLength: Integer;

    procedure SetMatrixColumns(StepType: Enum "Matrix Page Step Type")
    var
        MatrixMgt: Codeunit "Matrix Management";
    begin
        MatrixMgt.GeneratePeriodMatrixData(
            StepType.AsInteger(), 32, false, PeriodType, '',
            PKFirstRecInCurrSet, MatrixColumnCaptions, ColumnSet, CurrSetLength, MatrixRecords);
    end;
}

