// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Absence;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using Microsoft.HumanResources.Employee;

page 5226 "Empl. Absences by Categories"
{
    Caption = 'Empl. Absences by Categories';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = Employee;

    layout
    {
        area(content)
        {
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
                        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                    end;
                }
                field(AbsenceAmountType; AbsenceAmountType)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Absence Amount Type';
                    ToolTip = 'Specifies the absence amounts that will be included in the overview.';
                }
                field(MATRIX_CaptionRange; MATRIX_CaptionRange)
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
                    MatrixForm: Page "Empl. Absences by Cat. Matrix";
                begin
                    EmployeeNoFilter := Rec."No.";
                    MatrixForm.Load(MATRIX_CaptionSet, MatrixRecords, PeriodType, AbsenceAmountType, EmployeeNoFilter);
                    MatrixForm.RunModal();
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
                    GenerateColumnCaptions("Matrix Page Step Type"::Previous);
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
                    GenerateColumnCaptions("Matrix Page Step Type"::Next);
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
        MatrixCaptions := 32;
        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
    end;

    var
        MatrixRecord: Record "Cause of Absence";
        MatrixRecords: array[32] of Record "Cause of Absence";
        PeriodType: Enum "Analysis Period Type";
        AbsenceAmountType: Enum "Analysis Amount Type";
        EmployeeNoFilter: Text[250];
        MATRIX_CaptionSet: array[32] of Text[80];
        PKFirstRecInCurrSet: Text;
        MATRIX_CaptionRange: Text;
        MatrixCaptions: Integer;

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

        MatrixMgt.GenerateMatrixData(RecRef, StepType.AsInteger(), ArrayLen(MatrixRecords), 1, PKFirstRecInCurrSet,
          MATRIX_CaptionSet, MATRIX_CaptionRange, MatrixCaptions);
        if MatrixCaptions > 0 then begin
            MatrixRecord.SetPosition(PKFirstRecInCurrSet);
            MatrixRecord.Find();
            repeat
                MatrixRecords[CurrentMatrixRecordOrdinal].Copy(MatrixRecord);
                CurrentMatrixRecordOrdinal := CurrentMatrixRecordOrdinal + 1;
            until (CurrentMatrixRecordOrdinal > MatrixCaptions) or (MatrixRecord.Next() <> 1);
        end;
    end;
}

