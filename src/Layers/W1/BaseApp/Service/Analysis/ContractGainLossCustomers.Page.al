// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using Microsoft.Sales.Customer;
using System.Utilities;

page 6067 "Contract Gain/Loss (Customers)"
{
    ApplicationArea = Service;
    Caption = 'Contract Gain/Loss (Customers)';
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

                    trigger OnValidate()
                    begin
                        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                    end;
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(CustomerNo; CustomerNo)
                {
                    ApplicationArea = Service;
                    Caption = 'Customer No. Filter';
                    ToolTip = 'Specifies which customers are included in the window by setting filters.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        if PAGE.RunModal(0, Cust) = ACTION::LookupOK then begin
                            Text := Cust."No.";
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if not Cust.Get(CustomerNo) then
                            Clear(Cust);
                        ShipToCodeFilter := '';
                        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                        CustomerNoOnAfterValidate();
                    end;
                }
                field(ShipToCodeFilter; ShipToCodeFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Ship-to Code Filter';
                    ToolTip = 'Specifies which customers are included in the view by setting filters in Ship-to fields. If you do not set any filters, the window will include information about all customers.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ShiptoAddr.Reset();
                        ShiptoAddr.SetRange("Customer No.", CustomerNo);
                        if PAGE.RunModal(0, ShiptoAddr) = ACTION::LookupOK then begin
                            Text := ShiptoAddr.Code;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                        ShipToCodeFilterOnAfterValidat();
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
                    MatrixForm: Page "Contr. G/Loss (Cust.) Matrix";
                begin
                    if CustomerNo = '' then
                        Error(Text003);
                    if PeriodStart = 0D then
                        PeriodStart := WorkDate();
                    Clear(MatrixForm);

                    MatrixForm.LoadMatrix(MATRIX_CaptionSet, MatrixRecords, MATRIX_CurrentNoOfColumns, AmountType, PeriodType,
                      CustomerNo, PeriodStart, ShipToCodeFilter);
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
        ShiptoAddr: Record "Ship-to Address";
        Cust: Record Customer;
        MatrixRecords: array[32] of Record "Ship-to Address";
        MatrixRecord: Record "Ship-to Address";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_CaptionRange: Text;
        PKFirstRecInCurrSet: Text;
        MATRIX_CurrentNoOfColumns: Integer;
        AmountType: Enum "Analysis Amount Type";
        PeriodType: Enum "Analysis Period Type";
        PeriodStart: Date;
        CustomerNo: Code[20];
        ShipToCodeFilter: Text[250];
#pragma warning disable AA0074
        Text003: Label 'You must choose a customer in Filters, Customer No. Filter.';
#pragma warning restore AA0074

    local procedure GenerateColumnCaptions(StepType: Enum "Matrix Page Step Type")
    var
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
        CurrentMatrixRecordOrdinal: Integer;
    begin
        Clear(MATRIX_CaptionSet);
        Clear(MatrixRecords);
        CurrentMatrixRecordOrdinal := 1;
        MatrixRecord.SetRange("Customer No.", CustomerNo);
        if ShipToCodeFilter <> '' then
            MatrixRecord.SetFilter(Code, ShipToCodeFilter);
        RecRef.GetTable(MatrixRecord);
        RecRef.SetTable(MatrixRecord);

        MatrixMgt.GenerateMatrixData(
            RecRef, StepType.AsInteger(), ArrayLen(MatrixRecords), 2, PKFirstRecInCurrSet,
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

    local procedure CustomerNoOnAfterValidate()
    begin
        CurrPage.Update(true);
    end;

    local procedure ShipToCodeFilterOnAfterValidat()
    begin
        CurrPage.Update(true);
    end;
}

