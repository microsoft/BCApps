// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Enums;

page 563 "G/L Entries Dimension Overview"
{
    Caption = 'G/L Entries Dimension Overview';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "G/L Entry";

    layout
    {
        area(content)
        {
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(MATRIX_CaptionRange; MATRIX_CaptionRange)
                {
                    ApplicationArea = Dimensions;
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
                ApplicationArea = Dimensions;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "G/L Entries Dim. Overv. Matrix";
                begin
                    Clear(MatrixForm);
                    MatrixForm.Load(MATRIX_CaptionSet, MATRIX_PKFirstCaptionInCurrSet, MATRIX_CurrSetLength);
                    if RunOnTempRec then
                        MatrixForm.SetTempGLEntry(TempGLEntry)
                    else
                        MatrixForm.SetTableView(Rec);
                    MatrixForm.RunModal();
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Dimensions;
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
                ApplicationArea = Dimensions;
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
    begin
        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
    end;

    var
        MatrixRecord: Record Dimension;
        TempGLEntry: Record "G/L Entry" temporary;
        RunOnTempRec: Boolean;
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_PKFirstCaptionInCurrSet: Text;
        MATRIX_CaptionRange: Text;
        MATRIX_CurrSetLength: Integer;

    procedure SetTempGLEntry(var NewGLEntry: Record "G/L Entry")
    begin
        RunOnTempRec := true;
        TempGLEntry.DeleteAll();
        if NewGLEntry.Find('-') then
            repeat
                TempGLEntry := NewGLEntry;
                TempGLEntry.Insert();
            until NewGLEntry.Next() = 0;
    end;

    local procedure GenerateColumnCaptions(StepType: Enum "Matrix Page Step Type")
    var
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(MatrixRecord);
        RecRef.SetTable(MatrixRecord);

        MatrixMgt.GenerateMatrixData(
            RecRef, StepType.AsInteger(), ArrayLen(MATRIX_CaptionSet), 1,
            MATRIX_PKFirstCaptionInCurrSet, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrSetLength);
    end;
}

