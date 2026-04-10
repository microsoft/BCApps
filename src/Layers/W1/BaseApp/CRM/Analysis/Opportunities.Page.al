// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Analysis;

using Microsoft.CRM.Opportunity;
using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using System.Utilities;

page 5131 Opportunities
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Opportunities';
    DataCaptionExpression = Format(OutPutOption);
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "RM Matrix Management";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(TableOption; TableType)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Show as Lines';
                    ToolTip = 'Specifies which values you want to show as lines in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';
                }
                field(OutPutOption; OutPutOption)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Show';
                    ToolTip = 'Specifies if the selected value is shown in the window.';
                }
                field(RoundingFactor; RoundingFactor)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Rounding Factor';
                    ToolTip = 'Specifies the factor that is used to round the amounts.';
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(OptionStatusFilter; OptionStatusFilter)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Status Filter';
                    OptionCaption = 'In Progress,Won,Lost';
                    ToolTip = 'Specifies for which status opportunities are displayed.';
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        PeriodTypeOnAfterValidate();
                    end;
                }
                field(MATRIX_CaptionRange; MATRIX_CaptionRange)
                {
                    ApplicationArea = RelationshipMgmt;
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
                ApplicationArea = RelationshipMgmt;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "Opportunities Matrix";
                    EstValFilter: Text;
                    CloseOppFilter: Text;
                    SuccesChanceFilter: Text;
                    ProbabilityFilter: Text;
                    CompleteFilter: Text;
                    CaldCurrValFilter: Text;
                    SalesCycleFilter: Text;
                    CycleStageFilter: Text;
                begin
                    Clear(MatrixForm);
                    CloseOppFilter := Rec.GetFilter("Close Opportunity Filter");
                    SuccesChanceFilter := Rec.GetFilter("Chances of Success % Filter");
                    ProbabilityFilter := Rec.GetFilter("Probability % Filter");
                    CompleteFilter := Rec.GetFilter("Completed % Filter");
                    EstValFilter := Rec.GetFilter("Estimated Value Filter");
                    CaldCurrValFilter := Rec.GetFilter("Calcd. Current Value Filter");
                    SalesCycleFilter := Rec.GetFilter("Sales Cycle Filter");
                    CycleStageFilter := Rec.GetFilter("Sales Cycle Stage Filter");

                    MatrixForm.LoadMatrix(
                        MATRIX_CaptionSet, MatrixRecords, TableType, OutPutOption, RoundingFactor,
                        OptionStatusFilter, CloseOppFilter, SuccesChanceFilter, ProbabilityFilter, CompleteFilter, EstValFilter,
                        CaldCurrValFilter, SalesCycleFilter, CycleStageFilter, Periods);

                    MatrixForm.RunModal();
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    CreateCaptionSet("Matrix Page Step Type"::Previous);
                end;
            }
            action("Next Set")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    CreateCaptionSet("Matrix Page Step Type"::Next);
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

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(true);
    end;

    trigger OnOpenPage()
    begin
        CreateCaptionSet("Matrix Page Step Type"::Initial);
    end;

    var
        MatrixRecords: array[32] of Record Date;
        MatrixMgt: Codeunit "Matrix Management";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_CaptionRange: Text[80];
        PeriodType: Enum "Analysis Period Type";
        OptionStatusFilter: Option "In Progress",Won,Lost;
        OutPutOption: Enum "Opportunity Output";
        RoundingFactor: Enum "Analysis Rounding Factor";
        TableType: Enum "Opportunity Table Type";
        Periods: Integer;
        Datefilter: Text[1024];
        PKFirstRecInCurrSet: Text[100];

    local procedure CreateCaptionSet(StepType: Enum "Matrix Page Step Type")
    begin
        MatrixMgt.GeneratePeriodMatrixData(
            StepType.AsInteger(), ArrayLen(MatrixRecords), false, PeriodType, Datefilter, PKFirstRecInCurrSet,
            MATRIX_CaptionSet, MATRIX_CaptionRange, Periods, MatrixRecords);
    end;

    local procedure PeriodTypeOnAfterValidate()
    begin
        CreateCaptionSet("Matrix Page Step Type"::Initial);
    end;
}

