// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Document;
using System.Text;
using System.Utilities;

page 6009 "Res. Gr. Alloc. per Serv Order"
{
    Caption = 'Resource Group Allocated per Service Order';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Service Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ResourceGrFilter; ResourceGrFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resource Gr. Filter';
                    Lookup = true;
                    LookupPageID = "Resource Groups";
                    TableRelation = "Resource Group";
                    ToolTip = 'Specifies the resource group that the allocations apply to.';
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        DateControl();
                        SetMatrixColumns("Matrix Page Step Type"::Initial);
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    begin
                        DateControl();
                        SetMatrixColumns("Matrix Page Step Type"::Initial);
                    end;
                }
                field(ColumnsSet; ColumnsSet)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Column set';
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
                ApplicationArea = Basic, Suite;
                Caption = 'Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'Open the matrix window to see data according to the specified values.';

                trigger OnAction()
                var
                    HorizontalRecord: Record "Service Order Allocation";
                    ResPerServiceOrderMatrix: Page "ResGrp. All. per Serv.  Matrix";
                begin
                    HorizontalRecord.SetRange("Resource Group No.", ResourceGrFilter);
                    ServiceHeader.SetFilter("Resource Group Filter", ResourceGrFilter);
                    ResPerServiceOrderMatrix.Load(ServiceHeader, HorizontalRecord, MatrixColumnCaptions, MatrixRecords, CurrSetLength);
                    ResPerServiceOrderMatrix.RunModal();
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Basic, Suite;
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
                ApplicationArea = Basic, Suite;
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
        SetMatrixColumns("Matrix Page Step Type"::Initial);
        if Rec.HasFilter then
            ResourceGrFilter := Rec.GetFilter("Resource Group Filter");
    end;

    var
        MatrixRecords: array[32] of Record Date;
        ResRec2: Record Resource;
        ServiceHeader: Record "Service Header";
        FilterTokens: Codeunit "Filter Tokens";
        DateFilter: Text;
        ResourceGrFilter: Text;
        PeriodType: Enum "Analysis Period Type";
        PKFirstRecInCurrSet: Text[1024];
        MatrixColumnCaptions: array[32] of Text[100];
        ColumnsSet: Text[1024];
        CurrSetLength: Integer;

    local procedure DateControl()
    begin
        FilterTokens.MakeDateFilter(DateFilter);
        ResRec2.SetFilter("Date Filter", DateFilter);
        DateFilter := ResRec2.GetFilter("Date Filter");
    end;

    procedure SetMatrixColumns(StepType: Enum "Matrix Page Step Type")
    var
        MatrixMgt: Codeunit "Matrix Management";
    begin
        MatrixMgt.GeneratePeriodMatrixData(
            StepType.AsInteger(), 32, false, PeriodType, DateFilter,
            PKFirstRecInCurrSet, MatrixColumnCaptions, ColumnsSet, CurrSetLength, MatrixRecords);
    end;
}

