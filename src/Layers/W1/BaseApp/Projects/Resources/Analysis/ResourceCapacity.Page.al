// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using Microsoft.Projects.Resources.Resource;
using System.Utilities;

page 213 "Resource Capacity"
{
    ApplicationArea = Jobs;
    Caption = 'Resource Capacity';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPlus;
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = Resource;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Jobs;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        SetMatrixColumns("Matrix Page Step Type"::Initial);
                        UpdateMatrixSubform();
                    end;
                }
                field(QtyType; QtyType)
                {
                    ApplicationArea = Jobs;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        UpdateMatrixSubform();
                    end;
                }
            }
            part(MatrixForm; "Resource Capacity Matrix")
            {
                ApplicationArea = Jobs;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Previous Set")
            {
                ApplicationArea = Jobs;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    SetMatrixColumns("Matrix Page Step Type"::Previous);
                    UpdateMatrixSubform();
                end;
            }
            action("Previous Column")
            {
                ApplicationArea = Jobs;
                Caption = 'Previous Column';
                Image = PreviousRecord;
                ToolTip = 'Go to the previous column.';

                trigger OnAction()
                begin
                    SetMatrixColumns("Matrix Page Step Type"::PreviousColumn);
                    UpdateMatrixSubform();
                end;
            }
            action("Next Column")
            {
                ApplicationArea = Jobs;
                Caption = 'Next Column';
                Image = NextRecord;
                ToolTip = 'Go to the next column.';

                trigger OnAction()
                begin
                    SetMatrixColumns("Matrix Page Step Type"::NextColumn);
                    UpdateMatrixSubform();
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Jobs;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    SetMatrixColumns("Matrix Page Step Type"::Next);
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

    trigger OnOpenPage()
    begin
        SetMatrixColumns("Matrix Page Step Type"::Initial);
        UpdateMatrixSubform();
    end;

    var
        MatrixRecords: array[32] of Record Date;
        PeriodType: Enum "Analysis Period Type";
        QtyType: Enum "Analysis Amount Type";
        MatrixColumnCaptions: array[32] of Text[1024];
        ColumnSet: Text[1024];
        PKFirstRecInCurrSet: Text[100];
        CurrSetLength: Integer;

    local procedure SetMatrixColumns(StepType: Enum "Matrix Page Step Type")
    var
        MatrixMgt: Codeunit "Matrix Management";
    begin
        MatrixMgt.GeneratePeriodMatrixData(
            StepType.AsInteger(), 12, false, PeriodType, '',
            PKFirstRecInCurrSet, MatrixColumnCaptions, ColumnSet, CurrSetLength, MatrixRecords);
    end;

    local procedure UpdateMatrixSubform()
    begin
        CurrPage.MatrixForm.PAGE.LoadMatrix(QtyType, MatrixColumnCaptions, MatrixRecords, CurrSetLength);
        CurrPage.Update(false);
    end;
}

