// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Inventory.Item;

page 9287 "Prod. BOM Mat. per Ver. Matrix"
{
    Caption = 'Prod. BOM Matrix per Version Matrix';
    DataCaptionExpression = SetCaption();
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Production Matrix BOM Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the item included in one ore more of the production BOM versions.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];
                    DecimalPlaces = 0 : 5;
                    Visible = Field1Visible;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];
                    DecimalPlaces = 0 : 5;
                    Visible = Field2Visible;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];
                    DecimalPlaces = 0 : 5;
                    Visible = Field3Visible;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];
                    DecimalPlaces = 0 : 5;
                    Visible = Field4Visible;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[5];
                    DecimalPlaces = 0 : 5;
                    Visible = Field5Visible;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[6];
                    DecimalPlaces = 0 : 5;
                    Visible = Field6Visible;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[7];
                    DecimalPlaces = 0 : 5;
                    Visible = Field7Visible;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[8];
                    DecimalPlaces = 0 : 5;
                    Visible = Field8Visible;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[9];
                    DecimalPlaces = 0 : 5;
                    Visible = Field9Visible;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[10];
                    DecimalPlaces = 0 : 5;
                    Visible = Field10Visible;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[11];
                    DecimalPlaces = 0 : 5;
                    Visible = Field11Visible;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[12];
                    DecimalPlaces = 0 : 5;
                    Visible = Field12Visible;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[13];
                    DecimalPlaces = 0 : 5;
                    Visible = Field13Visible;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[14];
                    DecimalPlaces = 0 : 5;
                    Visible = Field14Visible;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[15];
                    DecimalPlaces = 0 : 5;
                    Visible = Field15Visible;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[16];
                    DecimalPlaces = 0 : 5;
                    Visible = Field16Visible;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[17];
                    DecimalPlaces = 0 : 5;
                    Visible = Field17Visible;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[18];
                    DecimalPlaces = 0 : 5;
                    Visible = Field18Visible;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[19];
                    DecimalPlaces = 0 : 5;
                    Visible = Field19Visible;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[20];
                    DecimalPlaces = 0 : 5;
                    Visible = Field20Visible;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[21];
                    DecimalPlaces = 0 : 5;
                    Visible = Field21Visible;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[22];
                    DecimalPlaces = 0 : 5;
                    Visible = Field22Visible;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[23];
                    DecimalPlaces = 0 : 5;
                    Visible = Field23Visible;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[24];
                    DecimalPlaces = 0 : 5;
                    Visible = Field24Visible;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[25];
                    DecimalPlaces = 0 : 5;
                    Visible = Field25Visible;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[26];
                    DecimalPlaces = 0 : 5;
                    Visible = Field26Visible;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[27];
                    DecimalPlaces = 0 : 5;
                    Visible = Field27Visible;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[28];
                    DecimalPlaces = 0 : 5;
                    Visible = Field28Visible;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[29];
                    DecimalPlaces = 0 : 5;
                    Visible = Field29Visible;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[30];
                    DecimalPlaces = 0 : 5;
                    Visible = Field30Visible;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[31];
                    DecimalPlaces = 0 : 5;
                    Visible = Field31Visible;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[32];
                    DecimalPlaces = 0 : 5;
                    Visible = Field32Visible;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Item")
            {
                Caption = '&Item';
                Image = Item;
                action("&Card")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Card';
                    Image = EditLines;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = field("Item No.");
                    RunPageView = sorting("No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information for the production BOM.';
                }
                action("Ma&trix per Version")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ma&trix per Version';
                    Image = ProdBOMMatrixPerVersion;
                    ToolTip = 'View a list of all versions and items and the used quantity per item of a production BOM. You can use the matrix to compare different production BOM versions concerning the used items per version.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                        ProductionBOMHeader: Record "Production BOM Header";
                        ProdBOMMatrixPerVersion: Page "Prod. BOM Matrix per Version";
                    begin
                        Item.Get(Rec."Item No.");
                        Item.TestField("Production BOM No.");

                        ProductionBOMHeader.Get(Item."Production BOM No.");
                        ProdBOMMatrixPerVersion.Set(ProductionBOMHeader);
                        ProdBOMMatrixPerVersion.RunModal();
                    end;
                }
                action("Where-Used")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Where-Used';
                    Image = "Where-Used";
                    ToolTip = 'View a list of BOMs in which the item is used.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                        ProdBOMWhereUsed: Page "Prod. BOM Where-Used";
                    begin
                        Item.Get(Rec."Item No.");
                        ProdBOMWhereUsed.SetItem(Item, WorkDate());
                        ProdBOMWhereUsed.Run();
                    end;
                }
            }
        }
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

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(BOMMatrixMgt.FindRecord(Which, Rec));
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

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(BOMMatrixMgt.NextRecord(Steps, Rec));
    end;

    trigger OnOpenPage()
    begin
        BOMMatrixMgt.BOMMatrixFromBOM(ProdBOM, ShowLevel = ShowLevel::Multi);
        SetColumnVisibility();
    end;

    var
        MatrixRecords: array[32] of Record "Production BOM Version";
        ProdBOM: Record "Production BOM Header";
        BOMMatrixMgt: Codeunit "BOM Matrix Management";
        ShowLevel: Option Single,Multi;
        ComponentNeed: Decimal;
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[32] of Decimal;
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

    procedure Load(NewMatrixColumns: array[32] of Text[1024]; var NewMatrixRecords: array[32] of Record "Production BOM Version"; CurrentNoOfMatrixColumns: Integer; NewProdBOM: Record "Production BOM Header"; NewShowLevel: Option Single,Multi)
    begin
        CopyArray(MATRIX_CaptionSet, NewMatrixColumns, 1);
        CopyArray(MatrixRecords, NewMatrixRecords, 1);
        MATRIX_CurrentNoOfMatrixColumn := CurrentNoOfMatrixColumns;
        ProdBOM := NewProdBOM;
        ShowLevel := NewShowLevel;
        OnAfterLoad(NewMatrixColumns, NewMatrixRecords, CurrentNoOfMatrixColumns, NewProdBOM, NewShowLevel);
    end;

    local procedure MATRIX_OnAfterGetRecord(MATRIX_ColumnOrdinal: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMATRIX_OnAfterGetRecord(Rec, ProdBOM, MatrixRecords, MATRIX_CellData, MATRIX_ColumnOrdinal, ComponentNeed, IsHandled);
        if IsHandled then
            exit;

        ComponentNeed := BOMMatrixMgt.GetComponentNeed(Rec."Item No.", Rec."Variant Code", MatrixRecords[MATRIX_ColumnOrdinal]."Version Code");
        MATRIX_CellData[MATRIX_ColumnOrdinal] := ComponentNeed;
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

    procedure SetCaption(): Text
    begin
        exit(ProdBOM."No." + ' ' + ProdBOM.Description);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMATRIX_OnAfterGetRecord(var ProductionMatrixBOMLine: Record "Production Matrix BOM Line"; var ProductionBOMHeader: Record "Production BOM Header"; var MatrixRecords: array[32] of Record "Production BOM Version"; var MATRIX_CellData: array[32] of Decimal; MATRIX_ColumnOrdinal: Integer; var ComponentNeed: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLoad(NewMatrixColumns: array[32] of Text[1024]; var NewMatrixRecords: array[32] of Record "Production BOM Version"; CurrentNoOfMatrixColumns: Integer; NewProductionBOMHeader: Record "Production BOM Header"; NewShowLevel: Option Single,Multi)
    begin
    end;
}

