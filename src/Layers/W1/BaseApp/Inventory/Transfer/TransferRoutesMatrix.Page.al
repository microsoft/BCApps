// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Inventory.Location;

page 9285 "Transfer Routes Matrix"
{
    Caption = 'Transfer Routes Matrix';
    DataCaptionExpression = '';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = Location;
    SourceTableView = where("Use As In-Transit" = const(false));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Location;
                    Caption = 'Transfer-from Code';
                    ToolTip = 'Specifies a location code for the warehouse or distribution center where your items are handled and stored before being sold.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Location;
                    Caption = 'Transfer-from Name';
                    ToolTip = 'Specifies the name or address of the location that items are transferred from.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];
                    Visible = Field1Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];
                    Visible = Field2Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];
                    Visible = Field3Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];
                    Visible = Field4Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[5];
                    Visible = Field5Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[6];
                    Visible = Field6Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[7];
                    Visible = Field7Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[8];
                    Visible = Field8Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[9];
                    Visible = Field9Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[10];
                    Visible = Field10Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[11];
                    Visible = Field11Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[12];
                    Visible = Field12Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[13];
                    Visible = Field13Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[14];
                    Visible = Field14Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[15];
                    Visible = Field15Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[16];
                    Visible = Field16Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[17];
                    Visible = Field17Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[18];
                    Visible = Field18Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[19];
                    Visible = Field19Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[20];
                    Visible = Field20Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[21];
                    Visible = Field21Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[22];
                    Visible = Field22Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[23];
                    Visible = Field23Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[24];
                    Visible = Field24Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[25];
                    Visible = Field25Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[26];
                    Visible = Field26Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[27];
                    Visible = Field27Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[28];
                    Visible = Field28Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[29];
                    Visible = Field29Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[30];
                    Visible = Field30Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[31];
                    Visible = Field31Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = Location;
                    CaptionClass = '3,' + MATRIX_CaptionSet[32];
                    Visible = Field32Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(32);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        MATRIX_CurrentColumnOrdinal: Integer;
    begin
        MATRIX_CurrentColumnOrdinal := 0;
        while MATRIX_CurrentColumnOrdinal < MATRIX_CurrentNoOfMatrixColumn do begin
            MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal + 1;
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        end;
    end;

    trigger OnInit()
    begin
        Field32Visible := true;
        Field31Visible := true;
        Field30Visible := true;
        Field29Visible := true;
        Field28Visible := true;
        Field27Visible := true;
        Field26Visible := true;
        Field25Visible := true;
        Field24Visible := true;
        Field23Visible := true;
        Field22Visible := true;
        Field21Visible := true;
        Field20Visible := true;
        Field19Visible := true;
        Field18Visible := true;
        Field17Visible := true;
        Field16Visible := true;
        Field15Visible := true;
        Field14Visible := true;
        Field13Visible := true;
        Field12Visible := true;
        Field11Visible := true;
        Field10Visible := true;
        Field9Visible := true;
        Field8Visible := true;
        Field7Visible := true;
        Field6Visible := true;
        Field5Visible := true;
        Field4Visible := true;
        Field3Visible := true;
        Field2Visible := true;
        Field1Visible := true;
    end;

    trigger OnOpenPage()
    begin
        SetColumnVisibility();
    end;

    var
        MatrixRecords: array[32] of Record Location;
        TransferRoute: Record "Transfer Route";
        Specification: Text[80];
        Show: Enum "Transfer Routes Show";
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[32] of Text[80];
        MATRIX_CaptionSet: array[32] of Text[80];
        Field1Visible: Boolean;
        Field2Visible: Boolean;
        Field3Visible: Boolean;
        Field4Visible: Boolean;
        Field5Visible: Boolean;
        Field6Visible: Boolean;
        Field7Visible: Boolean;
        Field8Visible: Boolean;
        Field9Visible: Boolean;
        Field10Visible: Boolean;
        Field11Visible: Boolean;
        Field12Visible: Boolean;
        Field13Visible: Boolean;
        Field14Visible: Boolean;
        Field15Visible: Boolean;
        Field16Visible: Boolean;
        Field17Visible: Boolean;
        Field18Visible: Boolean;
        Field19Visible: Boolean;
        Field20Visible: Boolean;
        Field21Visible: Boolean;
        Field22Visible: Boolean;
        Field23Visible: Boolean;
        Field24Visible: Boolean;
        Field25Visible: Boolean;
        Field26Visible: Boolean;
        Field27Visible: Boolean;
        Field28Visible: Boolean;
        Field29Visible: Boolean;
        Field30Visible: Boolean;
        Field31Visible: Boolean;
        Field32Visible: Boolean;

    procedure LoadMatrix(NewMatrixColumns: array[32] of Text[1024]; var NewMatrixRecords: array[32] of Record Location; NewCurrentNoOfMatrixColumns: Integer; NewShow: Enum "Transfer Routes Show")
    begin
        CopyArray(MATRIX_CaptionSet, NewMatrixColumns, 1);
        CopyArray(MatrixRecords, NewMatrixRecords, 1);
        MATRIX_CurrentNoOfMatrixColumn := NewCurrentNoOfMatrixColumns;
        Show := NewShow;
    end;

    local procedure MATRIX_OnAfterGetRecord(MATRIX_ColumnOrdinal: Integer)
    begin
        ShowRouteSpecification(MATRIX_ColumnOrdinal);
        if (Format(Specification) = '') and (MatrixRecords[MATRIX_ColumnOrdinal].Code <> Rec.Code) then
            Specification := '...';

        MATRIX_CellData[MATRIX_ColumnOrdinal] := Format(Specification);
    end;

    local procedure ShowRouteSpecification(MATRIX_ColumnOrdinal: Integer)
    begin
        Specification := '';
        if TransferRoute.Get(Rec.Code, MatrixRecords[MATRIX_ColumnOrdinal].Code) then
            case Show of
                Show::"Shipping Agent Code":
                    Specification := TransferRoute."Shipping Agent Code";
                Show::"Shipping Agent Service Code":
                    Specification := TransferRoute."Shipping Agent Service Code";
                Show::"In-Transit Code":
                    Specification := TransferRoute."In-Transit Code";
                else
                    RunShowRouteSpecificationCaseElse();
            end;
    end;

    local procedure MATRIX_OnAssistEdit(MATRIX_ColumnOrdinal: Integer)
    begin
        if MatrixRecords[MATRIX_ColumnOrdinal].Code <> Rec.Code then begin
            if not TransferRoute.Get(Rec.Code, MatrixRecords[MATRIX_ColumnOrdinal].Code) then begin
                TransferRoute.Init();
                TransferRoute.Validate("Transfer-from Code", Rec.Code);
                TransferRoute.Validate("Transfer-to Code", MatrixRecords[MATRIX_ColumnOrdinal].Code);
                TransferRoute.Insert();
                Commit();
            end;
            PAGE.RunModal(PAGE::"Transfer Route Specification", TransferRoute);
        end;
    end;

    procedure SetColumnVisibility()
    begin
        Field1Visible := MATRIX_CurrentNoOfMatrixColumn >= 1;
        Field2Visible := MATRIX_CurrentNoOfMatrixColumn >= 2;
        Field3Visible := MATRIX_CurrentNoOfMatrixColumn >= 3;
        Field4Visible := MATRIX_CurrentNoOfMatrixColumn >= 4;
        Field5Visible := MATRIX_CurrentNoOfMatrixColumn >= 5;
        Field6Visible := MATRIX_CurrentNoOfMatrixColumn >= 6;
        Field7Visible := MATRIX_CurrentNoOfMatrixColumn >= 7;
        Field8Visible := MATRIX_CurrentNoOfMatrixColumn >= 8;
        Field9Visible := MATRIX_CurrentNoOfMatrixColumn >= 9;
        Field10Visible := MATRIX_CurrentNoOfMatrixColumn >= 10;
        Field11Visible := MATRIX_CurrentNoOfMatrixColumn >= 11;
        Field12Visible := MATRIX_CurrentNoOfMatrixColumn >= 12;
        Field13Visible := MATRIX_CurrentNoOfMatrixColumn >= 13;
        Field14Visible := MATRIX_CurrentNoOfMatrixColumn >= 14;
        Field15Visible := MATRIX_CurrentNoOfMatrixColumn >= 15;
        Field16Visible := MATRIX_CurrentNoOfMatrixColumn >= 16;
        Field17Visible := MATRIX_CurrentNoOfMatrixColumn >= 17;
        Field18Visible := MATRIX_CurrentNoOfMatrixColumn >= 18;
        Field19Visible := MATRIX_CurrentNoOfMatrixColumn >= 19;
        Field20Visible := MATRIX_CurrentNoOfMatrixColumn >= 20;
        Field21Visible := MATRIX_CurrentNoOfMatrixColumn >= 21;
        Field22Visible := MATRIX_CurrentNoOfMatrixColumn >= 22;
        Field23Visible := MATRIX_CurrentNoOfMatrixColumn >= 23;
        Field24Visible := MATRIX_CurrentNoOfMatrixColumn >= 24;
        Field25Visible := MATRIX_CurrentNoOfMatrixColumn >= 25;
        Field26Visible := MATRIX_CurrentNoOfMatrixColumn >= 26;
        Field27Visible := MATRIX_CurrentNoOfMatrixColumn >= 27;
        Field28Visible := MATRIX_CurrentNoOfMatrixColumn >= 28;
        Field29Visible := MATRIX_CurrentNoOfMatrixColumn >= 29;
        Field30Visible := MATRIX_CurrentNoOfMatrixColumn >= 30;
        Field31Visible := MATRIX_CurrentNoOfMatrixColumn >= 31;
        Field32Visible := MATRIX_CurrentNoOfMatrixColumn >= 32;
    end;

    local procedure RunShowRouteSpecificationCaseElse()
    begin
        OnShowRouteSpecificationOnCaseElse(TransferRoute, Show, Specification);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnShowRouteSpecificationOnCaseElse(var TransferRoute: Record "Transfer Route"; var Show: Enum "Transfer Routes Show"; var SpecificationText: Text[80])
    begin
    end;
}

