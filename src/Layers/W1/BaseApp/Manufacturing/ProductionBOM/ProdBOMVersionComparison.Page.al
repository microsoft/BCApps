// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using System.Telemetry;

page 9288 "Prod. BOM Version Comparison"
{
    Caption = 'Production BOM Version Comparison';
    DataCaptionExpression = SetCaption();
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
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
                field(Matrix_CaptionRange; Matrix_CaptionRange)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Column Set';
                    Editable = false;
                    ToolTip = 'Specifies the range of values that are displayed in the matrix window, for example, the total period. To change the contents of the field, choose Next Set or Previous Set.';
                }
            }
            repeater(ProductionMatrixBOMLines)
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
                field(BOMField1; BOMMatrix_CellData)
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + BOMMatrix_CaptionSet;
                    DecimalPlaces = 0 : 5;
                }
                field(Field1; Matrix_CellData[1])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[1];
                    DecimalPlaces = 0 : 5;
                    Visible = Field1Visible;
                }
                field(Field2; Matrix_CellData[2])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[2];
                    DecimalPlaces = 0 : 5;
                    Visible = Field2Visible;
                }
                field(Field3; Matrix_CellData[3])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[3];
                    DecimalPlaces = 0 : 5;
                    Visible = Field3Visible;
                }
                field(Field4; Matrix_CellData[4])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[4];
                    DecimalPlaces = 0 : 5;
                    Visible = Field4Visible;
                }
                field(Field5; Matrix_CellData[5])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[5];
                    DecimalPlaces = 0 : 5;
                    Visible = Field5Visible;
                }
                field(Field6; Matrix_CellData[6])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[6];
                    DecimalPlaces = 0 : 5;
                    Visible = Field6Visible;
                }
                field(Field7; Matrix_CellData[7])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[7];
                    DecimalPlaces = 0 : 5;
                    Visible = Field7Visible;
                }
                field(Field8; Matrix_CellData[8])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[8];
                    DecimalPlaces = 0 : 5;
                    Visible = Field8Visible;
                }
                field(Field9; Matrix_CellData[9])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[9];
                    DecimalPlaces = 0 : 5;
                    Visible = Field9Visible;
                }
                field(Field10; Matrix_CellData[10])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[10];
                    DecimalPlaces = 0 : 5;
                    Visible = Field10Visible;
                }
                field(Field11; Matrix_CellData[11])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[11];
                    DecimalPlaces = 0 : 5;
                    Visible = Field11Visible;
                }
                field(Field12; Matrix_CellData[12])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[12];
                    DecimalPlaces = 0 : 5;
                    Visible = Field12Visible;
                }
                field(Field13; Matrix_CellData[13])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[13];
                    DecimalPlaces = 0 : 5;
                    Visible = Field13Visible;
                }
                field(Field14; Matrix_CellData[14])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[14];
                    DecimalPlaces = 0 : 5;
                    Visible = Field14Visible;
                }
                field(Field15; Matrix_CellData[15])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[15];
                    DecimalPlaces = 0 : 5;
                    Visible = Field15Visible;
                }
                field(Field16; Matrix_CellData[16])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[16];
                    DecimalPlaces = 0 : 5;
                    Visible = Field16Visible;
                }
                field(Field17; Matrix_CellData[17])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[17];
                    DecimalPlaces = 0 : 5;
                    Visible = Field17Visible;
                }
                field(Field18; Matrix_CellData[18])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[18];
                    DecimalPlaces = 0 : 5;
                    Visible = Field18Visible;
                }
                field(Field19; Matrix_CellData[19])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[19];
                    DecimalPlaces = 0 : 5;
                    Visible = Field19Visible;
                }
                field(Field20; Matrix_CellData[20])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[20];
                    DecimalPlaces = 0 : 5;
                    Visible = Field20Visible;
                }
                field(Field21; Matrix_CellData[21])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[21];
                    DecimalPlaces = 0 : 5;
                    Visible = Field21Visible;
                }
                field(Field22; Matrix_CellData[22])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[22];
                    DecimalPlaces = 0 : 5;
                    Visible = Field22Visible;
                }
                field(Field23; Matrix_CellData[23])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[23];
                    DecimalPlaces = 0 : 5;
                    Visible = Field23Visible;
                }
                field(Field24; Matrix_CellData[24])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[24];
                    DecimalPlaces = 0 : 5;
                    Visible = Field24Visible;
                }
                field(Field25; Matrix_CellData[25])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[25];
                    DecimalPlaces = 0 : 5;
                    Visible = Field25Visible;
                }
                field(Field26; Matrix_CellData[26])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[26];
                    DecimalPlaces = 0 : 5;
                    Visible = Field26Visible;
                }
                field(Field27; Matrix_CellData[27])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[27];
                    DecimalPlaces = 0 : 5;
                    Visible = Field27Visible;
                }
                field(Field28; Matrix_CellData[28])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[28];
                    DecimalPlaces = 0 : 5;
                    Visible = Field28Visible;
                }
                field(Field29; Matrix_CellData[29])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[29];
                    DecimalPlaces = 0 : 5;
                    Visible = Field29Visible;
                }
                field(Field30; Matrix_CellData[30])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[30];
                    DecimalPlaces = 0 : 5;
                    Visible = Field30Visible;
                }
                field(Field31; Matrix_CellData[31])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[31];
                    DecimalPlaces = 0 : 5;
                    Visible = Field31Visible;
                }
                field(Field32; Matrix_CellData[32])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + Matrix_CaptionSet[32];
                    DecimalPlaces = 0 : 5;
                    Visible = Field32Visible;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
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
                actionref("Next Set_Promoted"; "Next Set")
                {
                }
            }
        }
        area(Navigation)
        {
            group("Item")
            {
                Caption = 'Item';
                Image = Item;
                action("Card")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = field("Item No.");
                    RunPageView = sorting("No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information for the item.';
                }
                action("Matrix per Version")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Production BOM Version Comparison';
                    Image = ProdBOMMatrixPerVersion;
                    ToolTip = 'For a production BOM set for the item, view a list of all versions and items and the used quantity per item. You can use the matrix to compare different production BOM versions concerning the used items per version.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                        ProductionBOMHeader: Record "Production BOM Header";
                        ProdBOMVersionComparison: Page "Prod. BOM Version Comparison";
                    begin
                        Item.Get(Rec."Item No.");
                        Item.TestField("Production BOM No.");

                        ProductionBOMHeader.Get(Item."Production BOM No.");
                        ProdBOMVersionComparison.Set(ProductionBOMHeader);
                        ProdBOMVersionComparison.RunModal();
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
        Matrix_CurrentColumnOrdinal: Integer;
    begin
        BOMMatrix_CellData := BOMMatrixManagement.GetComponentNeed(Rec."Item No.", Rec."Variant Code", '');
        Matrix_CurrentColumnOrdinal := 0;
        while Matrix_CurrentColumnOrdinal < Matrix_CurrSetLength do begin
            Matrix_CurrentColumnOrdinal := Matrix_CurrentColumnOrdinal + 1;
            Matrix_OnAfterGetRecord(Matrix_CurrentColumnOrdinal);
        end;
        SetColumnVisibility();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(BOMMatrixManagement.FindRecord(Which, Rec));
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
        exit(BOMMatrixManagement.NextRecord(Steps, Rec));
    end;

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000OC3', 'Production BOM Version Comparison', Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000OC4', 'Production BOM Version Comparison', Enum::"Feature Uptake Status"::Used);
        BuildMatrix();
        SetColumnVisibility();
    end;

    var
        CurrentProductionBOMHeader: Record "Production BOM Header";
        MatrixRecords: array[32] of Record "Production BOM Version";
        Matrix_MatrixRecord: Record "Production BOM Version";
        BOMMatrixManagement: Codeunit "BOM Matrix Management";
        ShowLevel: Option Single,Multi;
        ComponentNeed: Decimal;
        Matrix_CellData: array[32] of Decimal;
        BOMMatrix_CellData: Decimal;
        Matrix_CaptionSet: array[32] of Text[80];
        BOMMatrix_CaptionSet: Text;
        Matrix_CaptionRange: Text;
        PKFirstMatrixRecInSet: Text;
        Matrix_CurrSetLength: Integer;
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

    local procedure Matrix_OnAfterGetRecord(Matrix_ColumnOrdinal: Integer)
    begin
        ComponentNeed := BOMMatrixManagement.GetComponentNeed(Rec."Item No.", Rec."Variant Code", MatrixRecords[Matrix_ColumnOrdinal]."Version Code");
        Matrix_CellData[Matrix_ColumnOrdinal] := ComponentNeed;
    end;

    procedure SetColumnVisibility()
    begin
        Field1Visible := Matrix_CurrSetLength >= 1;
        Field2Visible := Matrix_CurrSetLength >= 2;
        Field3Visible := Matrix_CurrSetLength >= 3;
        Field4Visible := Matrix_CurrSetLength >= 4;
        Field5Visible := Matrix_CurrSetLength >= 5;
        Field6Visible := Matrix_CurrSetLength >= 6;
        Field7Visible := Matrix_CurrSetLength >= 7;
        Field8Visible := Matrix_CurrSetLength >= 8;
        Field9Visible := Matrix_CurrSetLength >= 9;
        Field10Visible := Matrix_CurrSetLength >= 10;
        Field11Visible := Matrix_CurrSetLength >= 11;
        Field12Visible := Matrix_CurrSetLength >= 12;
        Field13Visible := Matrix_CurrSetLength >= 13;
        Field14Visible := Matrix_CurrSetLength >= 14;
        Field15Visible := Matrix_CurrSetLength >= 15;
        Field16Visible := Matrix_CurrSetLength >= 16;
        Field17Visible := Matrix_CurrSetLength >= 17;
        Field18Visible := Matrix_CurrSetLength >= 18;
        Field19Visible := Matrix_CurrSetLength >= 19;
        Field20Visible := Matrix_CurrSetLength >= 20;
        Field21Visible := Matrix_CurrSetLength >= 21;
        Field22Visible := Matrix_CurrSetLength >= 22;
        Field23Visible := Matrix_CurrSetLength >= 23;
        Field24Visible := Matrix_CurrSetLength >= 24;
        Field25Visible := Matrix_CurrSetLength >= 25;
        Field26Visible := Matrix_CurrSetLength >= 26;
        Field27Visible := Matrix_CurrSetLength >= 27;
        Field28Visible := Matrix_CurrSetLength >= 28;
        Field29Visible := Matrix_CurrSetLength >= 29;
        Field30Visible := Matrix_CurrSetLength >= 30;
        Field31Visible := Matrix_CurrSetLength >= 31;
        Field32Visible := Matrix_CurrSetLength >= 32;
    end;

    procedure SetCaption(): Text
    begin
        exit(CurrentProductionBOMHeader."No." + ' ' + CurrentProductionBOMHeader.Description);
    end;

    local procedure ShowLevelOnAfterValidate()
    begin
        BuildMatrix();
        CurrPage.Update(false);
    end;

    local procedure BuildMatrix()
    begin
        Clear(BOMMatrixManagement);
        BOMMatrixManagement.BOMMatrixFromBOM(CurrentProductionBOMHeader, ShowLevel = ShowLevel::Multi);
        Matrix_MatrixRecord.SetRange("Production BOM No.", CurrentProductionBOMHeader."No.");
        GenerateMatrixColumns(Enum::"Matrix Page Step Type"::Initial);
    end;

    local procedure GenerateMatrixColumns(StepType: Enum "Matrix Page Step Type")
    var
        MatrixManagement: Codeunit "Matrix Management";
        RecRef: RecordRef;
        CurrentMatrixRecordOrdinal: Integer;
    begin
        Clear(Matrix_CaptionSet);
        Clear(MatrixRecords);
        CurrentMatrixRecordOrdinal := 0;

        BOMMatrix_CaptionSet := Format(CurrentProductionBOMHeader."No.");

        Clear(RecRef);
        RecRef.GetTable(Matrix_MatrixRecord);
        RecRef.SetTable(Matrix_MatrixRecord);
        MatrixManagement.GenerateMatrixData(
            RecRef, StepType.AsInteger(), ArrayLen(MatrixRecords), 2, PKFirstMatrixRecInSet, Matrix_CaptionSet,
            Matrix_CaptionRange, Matrix_CurrSetLength);

        if Matrix_CurrSetLength > 0 then begin
            Matrix_MatrixRecord.SetPosition(PKFirstMatrixRecInSet);
            Matrix_MatrixRecord.Find();

            repeat
                CurrentMatrixRecordOrdinal := CurrentMatrixRecordOrdinal + 1;
                MatrixRecords[CurrentMatrixRecordOrdinal].Copy(Matrix_MatrixRecord);
            until (CurrentMatrixRecordOrdinal = Matrix_CurrSetLength) or (Matrix_MatrixRecord.Next() <> 1);
        end;
    end;

    procedure Set(var NewProductionBOMHeader: Record "Production BOM Header")
    begin
        CurrentProductionBOMHeader.Copy(NewProductionBOMHeader);
    end;
}

