// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Posting;

using Microsoft.Finance.Analysis;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Utilities;

page 5662 "FA Posting Types Overview"
{
    Caption = 'FA Posting Types Overview';
    DataCaptionExpression = '';
    DataCaptionFields = "No.", Description;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Fixed Asset";
    AboutTitle = 'About FA Posting Types Overview';
    AboutText = 'With the **FA Posting Types Overview**, you can specify different time intervals in the View by field. In the View as field, you can select **Net Change** to display the net change in the amount for each period, or you can select **Balance at Date** to display the amount as of the last day in each period.';

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(RoundingFactor; RoundingFactor)
                {
                    ApplicationArea = FixedAssets;
                    AutoFormatType = 1;
                    Caption = 'Rounding Factor';
                    ToolTip = 'Specifies the factor that is used to round the amounts.';
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                AboutTitle = 'Manage Matrix Options';
                AboutText = 'Specify the view by and view as details to configure/review the asset-wise book value, acquisition cost, and depreciation.';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        SetStartFilter(' ');
                    end;
                }
                field(MATRIX_CaptionRange; MATRIX_CaptionRange)
                {
                    ApplicationArea = FixedAssets;
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
                ApplicationArea = FixedAssets;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "FA Posting Types Overv. Matrix";
                begin
                    Clear(MatrixForm);
                    MatrixForm.LoadMatrix(
                      MATRIX_CaptionSet, MatrixRecords, NoOfColumns, Rec.GetFilter("FA Posting Date Filter"), RoundingFactor);
                    MatrixForm.RunModal();
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions("Matrix Page Step Type"::Previous);
                end;
            }
            action("Next Set")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions("Matrix Page Step Type"::Next);
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
    var
        FAMatrixPostingType: Record "FA Matrix Posting Type";
    begin
        FAMatrixPostingType.CreateTypes();

        PeriodType := PeriodType::Year;
        AmountType := AmountType::"Balance at Date";
        NoOfColumns := GetMatrixDimension();
        SetStartFilter(' ');
        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
    end;

    var
        Calendar: Record Date;
        MatrixRecord: Record "FA Matrix Posting Type";
        MatrixRecords: array[32] of Record "FA Matrix Posting Type";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_CaptionRange: Text;
        MATRIX_PKFirstRecInCurrSet: Text;
        MATRIX_CurrentNoOfColumns: Integer;
        PeriodType: Enum "Analysis Period Type";
        RoundingFactor: Enum "Analysis Rounding Factor";
        NoOfColumns: Integer;

    protected var
        AmountType: Enum "Analysis Amount Type";

    procedure SetStartFilter(SearchString: Code[10])
    var
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        if Rec.GetFilter("FA Posting Date Filter") <> '' then begin
            Calendar.SetFilter("Period Start", Rec.GetFilter("FA Posting Date Filter"));
            if not PeriodPageMgt.FindDate('+', Calendar, PeriodType) then
                PeriodPageMgt.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodPageMgt.FindDate(SearchString, Calendar, PeriodType);
        if AmountType = AmountType::"Net Change" then begin
            Rec.SetRange("FA Posting Date Filter", Calendar."Period Start", Calendar."Period End");
            if Rec.GetRangeMin("FA Posting Date Filter") = Rec.GetRangeMax("FA Posting Date Filter") then
                Rec.SetRange("FA Posting Date Filter", Rec.GetRangeMin("FA Posting Date Filter"));
        end else
            Rec.SetRange("FA Posting Date Filter", 0D, Calendar."Period End");
    end;

    local procedure GenerateColumnCaptions(StepType: Enum "Matrix Page Step Type")
    var
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
        CurrentMatrixRecordOrdinal: Integer;
    begin
        Clear(MATRIX_CaptionSet);
        Clear(MatrixRecords);
        CurrentMatrixRecordOrdinal := 1;

        RecRef.GetTable(MatrixRecord);
        RecRef.SetTable(MatrixRecord);

        MatrixMgt.GenerateMatrixData(
          RecRef, StepType.AsInteger(), ArrayLen(MatrixRecords), 2, MATRIX_PKFirstRecInCurrSet,
          MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);

        if MATRIX_CurrentNoOfColumns > 0 then begin
            MatrixRecord.SetPosition(MATRIX_PKFirstRecInCurrSet);
            MatrixRecord.Find();
            repeat
                MatrixRecords[CurrentMatrixRecordOrdinal].Copy(MatrixRecord);
                CurrentMatrixRecordOrdinal := CurrentMatrixRecordOrdinal + 1;
            until (CurrentMatrixRecordOrdinal > MATRIX_CurrentNoOfColumns) or (MatrixRecord.Next() <> 1);
        end;
    end;

    local procedure GetMatrixDimension(): Integer
    begin
        exit(ArrayLen(MATRIX_CaptionSet));
    end;
}

