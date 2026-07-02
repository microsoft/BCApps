// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Resource;
using System.Text;
using System.Utilities;

page 228 "Res. Gr. Allocated per Job"
{
    Caption = 'Res. Gr. Allocated per Project';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = Job;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Resource Gr. Filter"; ResourceGrFilter)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource Gr. Filter';
                    Lookup = true;
                    TableRelation = "Resource Group";
                    ToolTip = 'Specifies the resource group that the allocations apply to.';
                }
            }
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
                        DateControl();
                        SetMatrixColumns(Enum::"Matrix Page Step Type"::Initial);
                        CurrPage.Update();
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    begin
                        DateControl();
                        SetMatrixColumns(Enum::"Matrix Page Step Type"::Initial);
                        CurrPage.Update();
                    end;
                }
                field(ColumnsSet; ColumnsSet)
                {
                    ApplicationArea = Jobs;
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
                ApplicationArea = Jobs;
                Caption = 'Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'Open the matrix window to see data according to the specified values.';

                trigger OnAction()
                var
                    JobPlanningLine: Record "Job Planning Line";
                    ResGrpPerJobFormWithMatrix: Page "ResGrp. Alloc. per Job Matrix";
                    IsHandled: Boolean;
                begin
                    IsHandled := false;
                    OnActionShowMatrix(JobRec, ResourceGrFilter, MatrixColumnCaptions, MatrixRecords, IsHandled);
                    if IsHandled then
                        exit;

                    JobPlanningLine.SetRange("Resource Group No.", ResourceGrFilter);
                    JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Resource);
                    JobRec.SetRange("Resource Gr. Filter", ResourceGrFilter);
                    OnActionShowMatrixOnAfterSetJobFilters(JobRec);
                    ResGrpPerJobFormWithMatrix.Load(JobRec, JobPlanningLine, MatrixColumnCaptions, MatrixRecords);
                    ResGrpPerJobFormWithMatrix.RunModal();
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Jobs;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    SetMatrixColumns(Enum::"Matrix Page Step Type"::Previous);
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
                    SetMatrixColumns(Enum::"Matrix Page Step Type"::Next);
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
        SetMatrixColumns(Enum::"Matrix Page Step Type"::Initial);
        if Rec.HasFilter then
            ResourceGrFilter := Rec.GetFilter("Resource Gr. Filter");
    end;

    var
        MatrixRecords: array[32] of Record Date;
        JobRec: Record Job;
        ResRec2: Record Resource;
        FilterTokens: Codeunit "Filter Tokens";
        DateFilter: Text;
        ResourceGrFilter: Text;
        PeriodType: Enum "Analysis Period Type";
        CurrSetLength: Integer;
        PKFirstRecInCurrSet: Text[1024];
        MatrixColumnCaptions: array[32] of Text[100];
        ColumnsSet: Text[1024];

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
            StepType.AsInteger(), 32, false, PeriodType, DateFilter, PKFirstRecInCurrSet, MatrixColumnCaptions,
            ColumnsSet, CurrSetLength, MatrixRecords);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnActionShowMatrix(var JobRec: Record Job; ResourceGrFilter: Text; MatrixColumnCaptions: array[32] of Text; MatrixRecords: array[32] of Record Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnActionShowMatrixOnAfterSetJobFilters(var JobRec: Record Job)
    begin
    end;
}

