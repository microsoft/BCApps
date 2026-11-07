// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Location;
using System.Utilities;

page 6069 "Contract Gain/Loss (Resp.Ctr)"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Contract Gain/Loss (Resp.Ctr)';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = Date;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(PeriodStart; PeriodStart)
                {
                    ApplicationArea = Service;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies the starting date of the period that you want to view.';
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(RespCrFilter; RespCrFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Responsibility Center Filter';
                    ToolTip = 'Specifies the contract gain/loss by responsibility center.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        RespCrCode.Reset();
                        if PAGE.RunModal(0, RespCrCode) = ACTION::LookupOK then begin
                            Text := RespCrCode.Code;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                        RespCrFilterOnAfterValidate();
                    end;
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Service;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Service;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';
                }
                field(MATRIX_CaptionRange; MATRIX_CaptionRange)
                {
                    ApplicationArea = Service;
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
                ApplicationArea = Service;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "Contr. G/Loss (Res.Ctr) Matrix";
                begin
                    if PeriodStart = 0D then
                        PeriodStart := WorkDate();
                    Clear(MatrixForm);

                    MatrixForm.LoadMatrix(
                        MATRIX_CaptionSet, MatrixRecords, MATRIX_CurrentNoOfColumns, AmountType,
                        PeriodType, RespCrFilter, PeriodStart);
                    MatrixForm.RunModal();
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Service;
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
                ApplicationArea = Service;
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

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(true);
    end;

    trigger OnOpenPage()
    begin
        if PeriodStart = 0D then
            PeriodStart := WorkDate();
        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
    end;

    var
        MatrixRecords: array[32] of Record "Responsibility Center";
        MatrixRecord: Record "Responsibility Center";
        RespCrCode: Record "Responsibility Center";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_CaptionRange: Text;
        PKFirstRecInCurrSet: Text;
        MATRIX_CurrentNoOfColumns: Integer;
        AmountType: Enum "Analysis Amount Type";
        PeriodType: Enum "Analysis Period Type";
        RespCrFilter: Text[250];
        PeriodStart: Date;

    local procedure GenerateColumnCaptions(StepType: Enum "Matrix Page Step Type")
    var
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
        CurrentMatrixRecordOrdinal: Integer;
    begin
        Clear(MATRIX_CaptionSet);
        Clear(MatrixRecords);
        CurrentMatrixRecordOrdinal := 1;
        if RespCrFilter <> '' then
            MatrixRecord.SetFilter(Code, RespCrFilter)
        else
            MatrixRecord.SetRange(Code);

        RecRef.GetTable(MatrixRecord);
        RecRef.SetTable(MatrixRecord);

        MatrixMgt.GenerateMatrixData(
            RecRef, StepType.AsInteger(), ArrayLen(MatrixRecords), 1, PKFirstRecInCurrSet,
            MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
        if MATRIX_CurrentNoOfColumns > 0 then begin
            MatrixRecord.SetPosition(PKFirstRecInCurrSet);
            MatrixRecord.Find();
            repeat
                MatrixRecords[CurrentMatrixRecordOrdinal].Copy(MatrixRecord);
                CurrentMatrixRecordOrdinal := CurrentMatrixRecordOrdinal + 1;
            until (CurrentMatrixRecordOrdinal > MATRIX_CurrentNoOfColumns) or (MatrixRecord.Next() <> 1);
        end;
    end;

    local procedure RespCrFilterOnAfterValidate()
    begin
        CurrPage.Update(true);
    end;
}

