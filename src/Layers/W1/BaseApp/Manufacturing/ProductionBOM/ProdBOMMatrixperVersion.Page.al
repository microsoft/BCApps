// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;

page 99000812 "Prod. BOM Matrix per Version"
{
    Caption = 'Prod. BOM Matrix per Version';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Production Matrix BOM Line";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(ShowLevel; ShowLevel)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Levels';
                    OptionCaption = 'Single,Multi';
                    ToolTip = 'Specifies a filter for this matrix. You can choose Single or Multi to show the lines in this filter.';

                    trigger OnValidate()
                    begin
                        ShowLevelOnAfterValidate();
                    end;
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
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
            action("&Show Matrix")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "Prod. BOM Mat. per Ver. Matrix";
                begin
                    Clear(MatrixForm);
                    MatrixForm.Load(MATRIX_CaptionSet, MatrixRecords, MATRIX_CurrSetLength, ProdBOM, ShowLevel);
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
                    GenerateMatrixColumns(Enum::"Matrix Page Step Type"::Previous);
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
                    GenerateMatrixColumns(Enum::"Matrix Page Step Type"::Next);
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
                actionref("&Show Matrix_Promoted"; "&Show Matrix")
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
        BuildMatrix();
    end;

    var
        MatrixRecords: array[32] of Record "Production BOM Version";
        MATRIX_MatrixRecord: Record "Production BOM Version";
        ProdBOM: Record "Production BOM Header";
        BOMMatrixMgt: Codeunit "BOM Matrix Management";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_CaptionRange: Text;
        ShowLevel: Option Single,Multi;
        PKFirstMatrixRecInSet: Text;
        MATRIX_CurrSetLength: Integer;

    procedure Set(var NewProdBOM: Record "Production BOM Header")
    begin
        ProdBOM.Copy(NewProdBOM);
    end;

    local procedure BuildMatrix()
    begin
        Clear(BOMMatrixMgt);
        BOMMatrixMgt.BOMMatrixFromBOM(ProdBOM, ShowLevel = ShowLevel::Multi);
        MATRIX_MatrixRecord.SetRange("Production BOM No.", ProdBOM."No.");
        GenerateMatrixColumns(Enum::"Matrix Page Step Type"::Initial);
    end;

    local procedure GenerateMatrixColumns(StepType: Enum "Matrix Page Step Type")
    var
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
        CurrentMatrixRecordOrdinal: Integer;
    begin
        Clear(MATRIX_CaptionSet);
        Clear(MatrixRecords);
        CurrentMatrixRecordOrdinal := 0;

        RecRef.GetTable(MATRIX_MatrixRecord);
        RecRef.SetTable(MATRIX_MatrixRecord);
        MatrixMgt.GenerateMatrixData(
            RecRef, StepType.AsInteger(), ArrayLen(MatrixRecords), 2, PKFirstMatrixRecInSet, MATRIX_CaptionSet,
            MATRIX_CaptionRange, MATRIX_CurrSetLength);

        if MATRIX_CurrSetLength > 0 then begin
            MATRIX_MatrixRecord.SetPosition(PKFirstMatrixRecInSet);
            MATRIX_MatrixRecord.Find();

            repeat
                CurrentMatrixRecordOrdinal := CurrentMatrixRecordOrdinal + 1;
                MatrixRecords[CurrentMatrixRecordOrdinal].Copy(MATRIX_MatrixRecord);
            until (CurrentMatrixRecordOrdinal = MATRIX_CurrSetLength) or (MATRIX_MatrixRecord.Next() <> 1);
        end;
    end;

    procedure SetCaption(): Text[80]
    begin
        exit(ProdBOM."No." + ' ' + ProdBOM.Description);
    end;

    local procedure ShowLevelOnAfterValidate()
    begin
        BuildMatrix();
        CurrPage.Update(false);
    end;
}

