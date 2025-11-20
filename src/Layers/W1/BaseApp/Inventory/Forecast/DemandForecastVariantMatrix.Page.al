// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Forecast;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using System.Text;
using System.Utilities;

page 2900 "Demand Forecast Variant Matrix"
{
    Caption = 'Demand Forecast Matrix';
    DataCaptionExpression = Rec."Production Forecast Name";
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Forecast Item Variant Loc";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies a description of the item.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies a variant code of the item.';
                    Visible = ShowVariants;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies a location code of the item.';
                    Visible = ShowLocations;
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];
                    ToolTip = 'Enter a value to create an entry in the demand forecast.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field1Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(1);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field2Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(2);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field3Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(3);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field4Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(4);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[5];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field5Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(5);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[6];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field6Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(6);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[7];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field7Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(7);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[8];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field8Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(8);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[9];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field9Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(9);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[10];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field10Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(10);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[11];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field11Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(11);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[12];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field12Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(12);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[13];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field13Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(13);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[14];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field14Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(14);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[15];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field15Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(15);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[16];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field16Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(16);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[17];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field17Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(17);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[18];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field18Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(18);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[19];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field19Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(19);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[20];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field20Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(20);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[21];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field21Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(21);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[22];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field22Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(22);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[23];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field23Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(23);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[24];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field24Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(24);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[25];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field25Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(25);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[26];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field26Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(26);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[27];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field27Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(27);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[28];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field28Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(28);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[29];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field29Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(29);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[30];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field30Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(30);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[31];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field31Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(31);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[32];
                    ToolTip = 'Enter a value to create Demand Forecast Entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = Field32Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(32);
                    end;

                    trigger OnValidate()
                    begin
                        QtyValidate(32);
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
        while MATRIX_CurrentColumnOrdinal < MATRIX_NoOfMatrixColumns do begin
            MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal + 1;
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        end;
        if (MATRIX_CurrentColumnOrdinal > 0) and (QtyType = QtyType::"Net Change") then
            Rec.SetRange("Date Filter", MatrixRecords[1]."Period Start", MatrixRecords[MATRIX_CurrentColumnOrdinal]."Period End");
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
        MaxRowsToLoadVal := MaxRowsToLoad();
    end;

    var
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

        MaxNumberOfRowsReachedMsg: Label 'Maximum number of rows to be loaded in the matrix has been set to %1 and hence only top %1 number of rows are loaded. Consider using %2 to load relevant rows.', Comment = '%1 is the default row limit set in MaxRowsToLoad(), %2 is Item Filter Field Caption';
        Text000Err: Label 'The Forecast On field must be Sales Items or Component.';
        Text001Tok: Label 'A forecast was previously made on the %1. Do you want all forecasts of the period %2-%3 moved to the start of the period?', Comment = '%1 = Date e.g. 01-10-11, %2 = Start Period e.g. 12/02/2012, %3 = End Period e.g. 12/03/2012';
        Text004Err: Label 'You must change view to Sales Items or Component.';

    protected var
        MatrixRecords: array[32] of Record Date;
        QtyType: Enum "Analysis Amount Type";
        ForecastType: Enum "Demand Forecast Type";
        ProductionForecastName: Code[10];
        DateFilter: Text;
        ShowVariants: Boolean;
        ShowLocations: Boolean;
        MaxRowsToLoadVal: Integer;
        MATRIX_NoOfMatrixColumns: Integer;
        MATRIX_CellData: array[32] of Decimal;
        MATRIX_CaptionSet: array[32] of Text[80];

    procedure Load(MatrixColumns1: array[32] of Text[1024]; var MatrixRecords1: array[32] of Record Date; ProdForecastName: Code[10]; DateFilter1: Text; ForecastTypeVal: Enum "Demand Forecast Type"; QtyTypeVal: Enum "Analysis Amount Type"; NoOfMatrixColumns1: Integer; ItemFilter: Text; LocationFilter: Text; IncludeLoc: Boolean; IncludeVar: Boolean; VariantFilter: Text)
    begin

        CopyArray(MATRIX_CaptionSet, MatrixColumns1, 1);
        CopyArray(MatrixRecords, MatrixRecords1, 1);

        ProductionForecastName := ProdForecastName;
        DateFilter := DateFilter1;
        ForecastType := ForecastTypeVal;
        QtyType := QtyTypeVal;
        MATRIX_NoOfMatrixColumns := NoOfMatrixColumns1;

        if ForecastType = ForecastType::Component then
            Rec.SetRange("Component Forecast", true);
        if ForecastType = ForecastType::"Sales Item" then
            Rec.SetRange("Component Forecast", false);
        if ForecastType = ForecastType::Both then
            Rec.SetRange("Component Forecast");

        SetVisible();
        LoadData(ItemFilter, LocationFilter, IncludeLoc, IncludeVar, VariantFilter);
        OnAfterLoad(Rec, ProductionForecastName, ForecastType);
    end;

    local procedure IncrementEntryNo(var EntryNo: Integer): Boolean
    var
        ProdForecastNameRec: Record "Production Forecast Name";
    begin
        EntryNo += 1;
        if EntryNo > MaxRowsToLoadVal then begin
            Message(MaxNumberOfRowsReachedMsg, MaxRowsToLoadVal, ProdForecastNameRec.FieldCaption("Item Filter"));
            exit(false);
        end else
            exit(true);
    end;

    local procedure LoadData(ItemFilter: Text; LocationFilter: Text; UseLocation: Boolean; UseVariant: Boolean; VariantFilter: Text)
    var
        Item: Record Item;
        SelectionFilterMgt: Codeunit SelectionFilterManagement;
        ItemWithVariantsAndLocationsQuery: Query "Item With Variants & Locations";
        ItemWithVariantsQuery: Query "Item With Variants";
        ItemWithLocationsQuery: Query "Item With Locations";
        EntryNo: Integer;
    begin
        Rec.DeleteAll();
        EntryNo := 0;
        ShowVariants := UseVariant;
        ShowLocations := UseLocation;
        Item.SetView(ItemFilter);
        if Item.IsEmpty() then
            exit;

        case GetQueryForMatrix(UseVariant, UseLocation) of
            Database::Item:
                begin
                    Item.SetRange(Type, Item.Type::Inventory);
                    if Item.FindSet() then
                        repeat
                            if not IncrementEntryNo(EntryNo) then
                                break;
                            Rec.Init();
                            Rec."Entry No." := EntryNo;
                            Rec."No." := Item."No.";
                            Rec.Description := Item.Description;
                            Rec.Insert();
                        until Item.Next() = 0;
                end;
            Query::"Item With Variants":
                begin
                    ItemWithVariantsQuery.SetFilter(No_, SelectionFilterMgt.GetSelectionFilterForItem(Item));
                    ItemWithVariantsQuery.SetFilter(VariantCode, VariantFilter);
                    ItemWithVariantsQuery.SetRange(Type, "Item Type"::Inventory);

                    if ItemWithVariantsQuery.Open() then
                        while ItemWithVariantsQuery.Read() do begin
                            if not IncrementEntryNo(EntryNo) then
                                break;
                            Rec.Init();
                            Rec."Entry No." := EntryNo;
                            Rec."No." := ItemWithVariantsQuery.No_;
                            Rec.Description := ItemWithVariantsQuery.Description;
                            Rec."Variant Code" := ItemWithVariantsQuery.VariantCode;
                            Rec."Variant Filter" := ItemWithVariantsQuery.VariantCode;
                            Rec.Insert();
                        end;
                    ItemWithVariantsQuery.Close();
                end;
            Query::"Item With Locations":
                begin
                    ItemWithLocationsQuery.SetFilter(No_, SelectionFilterMgt.GetSelectionFilterForItem(Item));
                    ItemWithLocationsQuery.SetFilter(LocationCode, LocationFilter);
                    ItemWithLocationsQuery.SetRange(Type, "Item Type"::Inventory);
                    ItemWithLocationsQuery.SetRange(Use_As_In_Transit, false);
                    if ItemWithLocationsQuery.Open() then
                        while ItemWithLocationsQuery.Read() do begin
                            if not IncrementEntryNo(EntryNo) then
                                break;
                            Rec.Init();
                            Rec."Entry No." := EntryNo;
                            Rec."No." := ItemWithLocationsQuery.No_;
                            Rec.Description := ItemWithLocationsQuery.Description;
                            Rec."Location Code" := ItemWithLocationsQuery.LocationCode;
                            Rec."Location Filter" := ItemWithLocationsQuery.LocationCode;
                            Rec.Insert();
                        end;
                    ItemWithLocationsQuery.Close();
                end;
            Query::"Item With Variants & Locations":
                begin
                    ItemWithVariantsAndLocationsQuery.SetFilter(No_, SelectionFilterMgt.GetSelectionFilterForItem(Item));
                    ItemWithVariantsAndLocationsQuery.SetFilter(LocationCode, LocationFilter);
                    ItemWithVariantsAndLocationsQuery.SetFilter(VariantCode, VariantFilter);
                    ItemWithVariantsAndLocationsQuery.SetRange(Type, "Item Type"::Inventory);
                    ItemWithVariantsAndLocationsQuery.SetRange(Use_As_In_Transit, false);
                    if ItemWithVariantsAndLocationsQuery.Open() then
                        while ItemWithVariantsAndLocationsQuery.Read() do begin
                            if not IncrementEntryNo(EntryNo) then
                                break;
                            Rec.Init();
                            Rec."Entry No." := EntryNo;
                            Rec."No." := ItemWithVariantsAndLocationsQuery.No_;
                            Rec.Description := ItemWithVariantsAndLocationsQuery.Description;
                            Rec."Variant Code" := ItemWithVariantsAndLocationsQuery.VariantCode;
                            Rec."Variant Filter" := ItemWithVariantsAndLocationsQuery.VariantCode;
                            Rec."Location Code" := ItemWithVariantsAndLocationsQuery.LocationCode;
                            Rec."Location Filter" := ItemWithVariantsAndLocationsQuery.LocationCode;
                            Rec.Insert();
                        end;
                    ItemWithVariantsAndLocationsQuery.Close();
                end;
        end;

        //Point to the first row of the matrix
        OnLoadDataOnBeforeRecFindFirst(Rec, ItemFilter, LocationFilter, UseLocation, UseVariant, VariantFilter);
        if not Rec.IsEmpty() then
            Rec.FindFirst();
    end;

    local procedure GetQueryForMatrix(UseVariant: Boolean; UseLocation: Boolean): Integer
    begin
        if UseLocation and UseVariant then
            exit(Query::"Item With Variants & Locations");

        if not (UseVariant or UseLocation) then
            exit(Database::Item);

        if UseVariant then
            exit(Query::"Item With Variants");

        if UseLocation then
            exit(Query::"Item With Locations");
    end;

    local procedure SetDateFilter(ColumnID: Integer)
    begin
        if DateFilter <> '' then
            MatrixRecords[ColumnID].SetFilter("Period Start", DateFilter)
        else
            MatrixRecords[ColumnID].SetRange("Period Start");

        if QtyType = QtyType::"Net Change" then
            if MatrixRecords[ColumnID]."Period Start" = MatrixRecords[ColumnID]."Period End" then
                Rec.SetRange("Date Filter", MatrixRecords[ColumnID]."Period Start")
            else
                Rec.SetRange("Date Filter", MatrixRecords[ColumnID]."Period Start", MatrixRecords[ColumnID]."Period End")
        else
            Rec.SetRange("Date Filter", 0D, MatrixRecords[ColumnID]."Period End");
    end;

    local procedure MatrixOnDrillDown(ColumnID: Integer)
    var
        ProductionForecastEntry: Record "Production Forecast Entry";
    begin
        SetDateFilter(ColumnID);
        ProductionForecastEntry.SetCurrentKey(
          "Production Forecast Name", "Item No.", "Location Code", "Forecast Date", "Component Forecast");
        ProductionForecastEntry.SetRange("Item No.", Rec."No.");
        if QtyType = QtyType::"Net Change" then
            ProductionForecastEntry.SetRange("Forecast Date", MatrixRecords[ColumnID]."Period Start", MatrixRecords[ColumnID]."Period End")
        else
            ProductionForecastEntry.SetRange("Forecast Date", 0D, MatrixRecords[ColumnID]."Period End");
        if ProductionForecastName <> '' then
            ProductionForecastEntry.SetRange("Production Forecast Name", ProductionForecastName)
        else
            ProductionForecastEntry.SetRange("Production Forecast Name");
        if Rec."Location Code" <> '' then
            ProductionForecastEntry.SetRange("Location Code", Rec."Location Code")
        else
            ProductionForecastEntry.SetRange("Location Code");

        if Rec."Variant Code" <> '' then
            ProductionForecastEntry.SetRange("Variant Code", Rec."Variant Code")
        else
            ProductionForecastEntry.SetRange("Variant Code");

        ProductionForecastEntry.SetFilter("Component Forecast", Rec.GetFilter("Component Forecast"));
        OnMatrixOnDrillDownOnBeforePageRun(Rec, ProductionForecastEntry);
        PAGE.Run(0, ProductionForecastEntry);
    end;

    local procedure MATRIX_OnAfterGetRecord(ColumnOrdinal: Integer)
    begin
        SetDateFilter(ColumnOrdinal);
        if ProductionForecastName <> '' then
            Rec.SetRange("Production Forecast Name", ProductionForecastName)
        else
            Rec.SetRange("Production Forecast Name");

        if Rec."Location Code" <> '' then
            Rec.SetFilter("Location Filter", Rec."Location Code")
        else
            Rec.SetRange("Location Filter");

        if Rec."Variant Code" <> '' then
            Rec.SetFilter("Variant Filter", Rec."Variant Code")
        else
            Rec.SetRange("Variant Filter");

        if ForecastType = ForecastType::Component then
            Rec.SetRange("Component Forecast", true);
        if ForecastType = ForecastType::"Sales Item" then
            Rec.SetRange("Component Forecast", false);
        if ForecastType = ForecastType::Both then
            Rec.SetRange("Component Forecast");

        Rec.CalcFields("Prod. Forecast Quantity (Base)");
        MATRIX_CellData[ColumnOrdinal] := Rec."Prod. Forecast Quantity (Base)";

        OnAfterMATRIX_OnAfterGetRecord(Rec, MATRIX_CellData[ColumnOrdinal]);
    end;

    local procedure SetVisible()
    begin
        Field1Visible := MATRIX_CaptionSet[1] <> '';
        Field2Visible := MATRIX_CaptionSet[2] <> '';
        Field3Visible := MATRIX_CaptionSet[3] <> '';
        Field4Visible := MATRIX_CaptionSet[4] <> '';
        Field5Visible := MATRIX_CaptionSet[5] <> '';
        Field6Visible := MATRIX_CaptionSet[6] <> '';
        Field7Visible := MATRIX_CaptionSet[7] <> '';
        Field8Visible := MATRIX_CaptionSet[8] <> '';
        Field9Visible := MATRIX_CaptionSet[9] <> '';
        Field10Visible := MATRIX_CaptionSet[10] <> '';
        Field11Visible := MATRIX_CaptionSet[11] <> '';
        Field12Visible := MATRIX_CaptionSet[12] <> '';
        Field13Visible := MATRIX_CaptionSet[13] <> '';
        Field14Visible := MATRIX_CaptionSet[14] <> '';
        Field15Visible := MATRIX_CaptionSet[15] <> '';
        Field16Visible := MATRIX_CaptionSet[16] <> '';
        Field17Visible := MATRIX_CaptionSet[17] <> '';
        Field18Visible := MATRIX_CaptionSet[18] <> '';
        Field19Visible := MATRIX_CaptionSet[19] <> '';
        Field20Visible := MATRIX_CaptionSet[20] <> '';
        Field21Visible := MATRIX_CaptionSet[21] <> '';
        Field22Visible := MATRIX_CaptionSet[22] <> '';
        Field23Visible := MATRIX_CaptionSet[23] <> '';
        Field24Visible := MATRIX_CaptionSet[24] <> '';
        Field25Visible := MATRIX_CaptionSet[25] <> '';
        Field26Visible := MATRIX_CaptionSet[26] <> '';
        Field27Visible := MATRIX_CaptionSet[27] <> '';
        Field28Visible := MATRIX_CaptionSet[28] <> '';
        Field29Visible := MATRIX_CaptionSet[29] <> '';
        Field30Visible := MATRIX_CaptionSet[30] <> '';
        Field31Visible := MATRIX_CaptionSet[31] <> '';
        Field32Visible := MATRIX_CaptionSet[32] <> '';
    end;

    local procedure QtyValidate(ColumnID: Integer)
    begin
        EnterBaseQty(ColumnID);
        ProdForecastQtyBase_OnValidate(ColumnID);
    end;

    local procedure EnterBaseQty(ColumnID: Integer)
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEnterBaseQty(Rec, ColumnID, IsHandled);
        if not IsHandled then begin
            Item.SetRange("No.", Rec."No.");
            Item.FindFirst();
            SetDateFilter(ColumnID);
            if QtyType = QtyType::"Net Change" then
                Item.SetRange("Date Filter", MatrixRecords[ColumnID]."Period Start", MatrixRecords[ColumnID]."Period End")
            else
                Item.SetRange("Date Filter", 0D, MatrixRecords[ColumnID]."Period End");

            if ProductionForecastName <> '' then
                Item.SetRange("Production Forecast Name", ProductionForecastName)
            else
                Item.SetRange("Production Forecast Name");

            if Rec."Location Code" <> '' then
                Item.SetFilter("Location Filter", Rec."Location Code")
            else
                Item.SetRange("Location Filter");

            if Rec."Variant Code" <> '' then
                Item.SetFilter("Variant Filter", Rec."Variant Code")
            else
                Item.SetRange("Variant Filter");

            if ForecastType = ForecastType::Component then
                Item.SetRange("Component Forecast", true);

            if ForecastType = ForecastType::"Sales Item" then
                Item.SetRange("Component Forecast", false);

            if ForecastType = ForecastType::Both then
                Item.SetRange("Component Forecast");

            OnEnterBaseQtyOnBeforeValidateProdForecastQty(Item, Rec, ColumnID, MatrixRecords);
            Item.Validate("Prod. Forecast Quantity (Base)", MATRIX_CellData[ColumnID]);
        end;
        OnAfterEnterBaseQty(MATRIX_CellData, ColumnID, QtyType, ProductionForecastName, ForecastType, Item);
    end;

    local procedure ProdForecastQtyBase_OnValidate(ColumnID: Integer)
    var
        ProdForecastEntry: Record "Production Forecast Entry";
        IsHandled: Boolean;
        ShouldConfirmMovingForecasts: Boolean;
    begin
        IsHandled := false;
        OnBeforeProdForecastQtyBase_OnValidate(Rec, ColumnID, IsHandled);
        if IsHandled then
            exit;

        if ForecastType = ForecastType::Both then
            Error(Text000Err);

        ProdForecastEntry.SetCurrentKey("Production Forecast Name", "Item No.", "Location Code", "Forecast Date", "Component Forecast");
        ProdForecastEntry.SetRange("Production Forecast Name", Rec.GetFilter("Production Forecast Name"));
        ProdForecastEntry.SetRange("Item No.", Rec."No.");
        ProdForecastEntry.SetFilter("Location Code", Rec.GetFilter("Location Filter"));
        ProdForecastEntry.SetRange(
          "Forecast Date",
          MatrixRecords[ColumnID]."Period Start",
          MatrixRecords[ColumnID]."Period End");
        ProdForecastEntry.SetFilter("Component Forecast", Rec.GetFilter("Component Forecast"));
        if ProdForecastEntry.FindLast() then begin
            ShouldConfirmMovingForecasts := ProdForecastEntry."Forecast Date" > MatrixRecords[ColumnID]."Period Start";
            OnProdForecastQtyBase_OnValidateOnAfterCalcShouldConfirmMovingForecasts(ProdForecastEntry, ColumnID, MatrixRecords, ShouldConfirmMovingForecasts);
            if ShouldConfirmMovingForecasts then
                if Confirm(
                     Text001Tok,
                     false,
                     ProdForecastEntry."Forecast Date",
                     MatrixRecords[ColumnID]."Period Start",
                     MatrixRecords[ColumnID]."Period End")
                then
                    ProdForecastEntry.ModifyAll("Forecast Date", MatrixRecords[ColumnID]."Period Start")
                else
                    Error(Text004Err);
        end;

    end;

    local procedure MaxRowsToLoad() ReturnValue: Integer
    begin
        ReturnValue := 10000;
        OnGetMaxRowsToLoad(ReturnValue);
        exit(ReturnValue);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterMATRIX_OnAfterGetRecord(var ForecastItemVariantLoc: Record "Forecast Item Variant Loc"; var MATRIXCellDataColumnOrdinal: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterEnterBaseQty(var MATRIX_CellData: array[32] of Decimal; ColumnID: Integer; QtyType: Enum "Analysis Amount Type"; ProductionForecastName: Code[10]; ForecastType: Enum "Demand Forecast Type"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLoad(var ForecastItemVariantLoc: Record "Forecast Item Variant Loc"; ProductionForecastName: Code[10]; ForecastType: Enum "Demand Forecast Type")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetMaxRowsToLoad(var MaxRowsToLoad: Integer);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeEnterBaseQty(var Item: Record "Forecast Item Variant Loc"; ColumnID: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeProdForecastQtyBase_OnValidate(var Item: Record "Forecast Item Variant Loc"; ColumnID: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnterBaseQtyOnBeforeValidateProdForecastQty(var Item: Record Item; var ForecastItemVariantLoc: Record "Forecast Item Variant Loc"; ColumnID: Integer; MatrixRecords: array[32] of Record Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadDataOnBeforeRecFindFirst(var ForecastItemVariantLoc: Record "Forecast Item Variant Loc"; ItemFilter: Text; LocationFilter: Text; UseLocation: Boolean; UseVariant: Boolean; VariantFilter: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatrixOnDrillDownOnBeforePageRun(var ForecastItemVariantLoc: Record "Forecast Item Variant Loc"; var ProductionForecastEntry: Record "Production Forecast Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdForecastQtyBase_OnValidateOnAfterCalcShouldConfirmMovingForecasts(var ProdForecastEntry: Record "Production Forecast Entry"; ColumnID: Integer; MatrixRecords: array[32] of Record Date; var ShouldConfirmMovingForecasts: Boolean)
    begin
    end;

}

