// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.Utilities;

page 5827 "Item Statistics"
{
    Caption = 'Item Statistics';
    DataCaptionExpression = ItemName;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Dimension Code Buffer";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ShowAsLines; ItemBuffer."Line Option")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show as Lines';
                    ToolTip = 'Specifies which values you want to show as lines in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';

                    trigger OnValidate()
                    begin
                        ItemBufferLineOptionOnAfterVal();
                    end;
                }
                field(ColumnDimCode; ColumnDimCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Show as Columns';
                    ToolTip = 'Specifies which values you want to show as columns in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        NewCode: Text[30];
                    begin
                        NewCode := GetDimSelection(ColumnDimCode);
                        if NewCode = ColumnDimCode then begin
                            GenerateColumnCaptions("Matrix Page Step Type"::Same);

                            exit(false);
                        end;
                        Text := NewCode;
                        ColumnDimCode := NewCode;
                        ValidateColumnDimCode();
                        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                        CurrPage.Update();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateColumnDimCode();
                        ColumnDimCodeOnAfterValidate();
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    begin
                        ItemBuffer.SetFilter("Date Filter", DateFilter);
                        DateFilter := ItemBuffer.GetFilter("Date Filter");
                        InternalDateFilter := DateFilter;
                        DateFilterOnAfterValidate();
                    end;
                }
                field(ItemFilter; ItemFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies a filter to specify the items that will be shown in the window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Item: Record Item;
                        ItemList: Page "Item List";
                    begin
                        ItemList.SetTableView(Item);
                        ItemList.LookupMode := true;
                        if ItemList.RunModal() = ACTION::LookupOK then begin
                            ItemList.GetRecord(Item);
                            Text := Item."No.";
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        ItemFilterOnAfterValidate();
                    end;
                }
                field(LocationFilter; LocationFilter)
                {
                    ApplicationArea = Location;
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies the locations that statistics are shown for.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Location: Record Location;
                        Locations: Page "Location List";
                    begin
                        Locations.SetTableView(Location);
                        Locations.LookupMode := true;
                        if Locations.RunModal() = ACTION::LookupOK then begin
                            Locations.GetRecord(Location);
                            Text := Location.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field(VariantFilter; VariantFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant Filter';
                    ToolTip = 'Specifies a filter to specify the variants that will be shown in the window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemVariant: Record "Item Variant";
                        ItemVariants: Page "Item Variants";
                    begin
                        ItemVariant.SetRange("Item No.", Item."No.");
                        ItemVariants.SetTableView(ItemVariant);
                        ItemVariants.LookupMode := true;
                        if ItemVariants.RunModal() = ACTION::LookupOK then begin
                            ItemVariants.GetRecord(ItemVariant);
                            Text := ItemVariant.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
            }
            group(Options)
            {
                Caption = 'Options';
                field(RoundingFactor; RoundingFactor)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rounding Factor';
                    ToolTip = 'Specifies the factor that is used to round the amounts.';
                }
                field(PerUnit; PerUnit)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate per Unit';
                    ToolTip = 'Specifies that item statistics will be calculated per unit.';
                }
                field(IncludeExpected; IncludeExpected)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include Expected';
                    ToolTip = 'Specifies whether to include costs that have not yet been invoiced in the item statistics. When goods have been received but not yet invoiced, the costs of those receipts are expected costs.';
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(ViewBy; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        PeriodTypeOnAfterValidate();
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                    end;
                }
                field(MATRIX_CaptionRange; MATRIX_CaptionRange)
                {
                    ApplicationArea = Basic, Suite;
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
                ApplicationArea = Basic, Suite;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "Item Statistics Matrix";
                begin
                    Clear(MatrixForm);
                    MatrixForm.LoadMatrix(
                        MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns,
                        RoundingFactor, PerUnit, IncludeExpected, ItemBuffer, Item, PeriodType, AmountType,
                        ColumnDimCode, DateFilter, ItemFilter, LocationFilter, VariantFilter);
                    MatrixForm.SetTableView(Rec);
                    MatrixForm.RunModal();
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Basic, Suite;
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
                ApplicationArea = Basic, Suite;
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

    trigger OnFindRecord(Which: Text): Boolean
    begin
        IntegerLineSetFilter();
        exit(FindRec(ItemBuffer."Line Option", Rec, Which));
    end;

    trigger OnOpenPage()
    begin
        GLSetup.Get();

        if Item."No." <> '' then
            ItemFilter := Item."No.";
        if Item.GetFilter("Date Filter") <> '' then
            DateFilter := Item.GetFilter(Item."Date Filter");
        if Item.GetFilter("Variant Filter") <> '' then
            VariantFilter := Item.GetFilter(Item."Variant Filter");
        if Item.GetFilter("Location Filter") <> '' then
            LocationFilter := Item.GetFilter(Item."Location Filter");

        if ColumnDimCode = '' then
            ColumnDimCode := Text002;

        ItemBuffer."Column Option" := DimCodeToOption(ColumnDimCode);
        PeriodInitialized := DateFilter <> '';
        FindPeriod('');
        ItemName := StrSubstNo('%1  %2', Item."No.", Item.Description);
        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Item: Record Item;
        ItemBuffer: Record "Item Statistics Buffer";
        IntegerLine: Record "Integer";
        MATRIX_MatrixRecords: array[32] of Record "Dimension Code Buffer";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_CaptionRange: Text;
        MATRIX_PrimKeyFirstCaptionInCu: Text;
        ColumnDimCode: Text[30];
        ItemName: Text[250];
        PeriodType: Enum "Analysis Period Type";
        RoundingFactor: Enum "Analysis Rounding Factor";
        AmountType: Enum "Analysis Amount Type";
        DateFilter: Text;
        InternalDateFilter: Text;
        ItemFilter: Text;
        VariantFilter: Text;
        LocationFilter: Text;
        PeriodInitialized: Boolean;
        PerUnit: Boolean;
        IncludeExpected: Boolean;
#pragma warning disable AA0074
        Text002: Label 'Period';
#pragma warning disable AA0470
        Text003: Label '%1 is not a valid column definition.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        MATRIX_CurrentNoOfColumns: Integer;

    local procedure IntegerLineSetFilter()
    begin
        if ItemBuffer."Line Option" = ItemBuffer."Line Option"::"Profit Calculation" then
            IntegerLine.SetRange(Number, 1, 5)
        else
            if ItemBuffer."Line Option" = ItemBuffer."Line Option"::"Cost Specification" then
                IntegerLine.SetRange(Number, 1, 9);

        OnAfterIntegerLineSetFilter(ItemBuffer, IntegerLine);
    end;

    local procedure GenerateColumnCaptions(StepType: Enum "Matrix Page Step Type")
    var
        MATRIX_PeriodRecords: array[32] of Record Date;
        Location: Record Location;
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
        i: Integer;
    begin
        Clear(MATRIX_CaptionSet);
        Clear(MATRIX_MatrixRecords);

        case ColumnDimCode of
            Text002:
                begin
                    MatrixMgt.GeneratePeriodMatrixData(
                        StepType.AsInteger(), ArrayLen(MATRIX_CaptionSet), false,
                        PeriodType, DateFilter, MATRIX_PrimKeyFirstCaptionInCu,
                        MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns, MATRIX_PeriodRecords);
                    for i := 1 to ArrayLen(MATRIX_CaptionSet) do begin
                        MATRIX_MatrixRecords[i]."Period Start" := MATRIX_PeriodRecords[i]."Period Start";
                        MATRIX_MatrixRecords[i]."Period End" := MATRIX_PeriodRecords[i]."Period End";
                    end;
                end;
            Location.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    RecRef.GetTable(Location);
                    RecRef.SetTable(Location);
                    MatrixMgt.GenerateMatrixData(
                        RecRef, StepType.AsInteger(), ArrayLen(MATRIX_CaptionSet), 1,
                        MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                end;
        end;
    end;

    local procedure DimCodeToOption(DimCode: Text[30]): Enum "Item Statistics Column Option"
    var
        Location: Record Location;
    begin
        case DimCode of
            '':
                exit(Enum::"Item Statistics Column Option"::Undefined);
            Text002:
                exit(Enum::"Item Statistics Column Option"::Period);
            Location.TableCaption():
                exit(Enum::"Item Statistics Column Option"::Location);
            else
                exit(Enum::"Item Statistics Column Option"::Undefined);
        end;
    end;

    local procedure FindRec(DimOption: Enum "Item Statistics Line Option"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]): Boolean
    var
        ItemCharge: Record "Item Charge";
        Location: Record Location;
        Period: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
        Found: Boolean;
    begin
        case DimOption of
            DimOption::"Profit Calculation",
            DimOption::"Cost Specification":
                begin
                    if Evaluate(IntegerLine.Number, DimCodeBuf.Code) then;
                    Found := IntegerLine.Find(Which);
                    if Found then
                        CopyDimValueToBuf(IntegerLine, DimCodeBuf);
                end;
            DimOption::"Purch. Item Charge Spec.",
            DimOption::"Sales Item Charge Spec.":
                begin
                    ItemCharge."No." := DimCodeBuf.Code;
                    Found := ItemCharge.Find(Which);
                    if Found then
                        CopyAddChargesToBuf(ItemCharge, DimCodeBuf);
                end;
            DimOption::Period:
                begin
                    if not PeriodInitialized then
                        DateFilter := '';
                    PeriodInitialized := true;
                    Period."Period Start" := DimCodeBuf."Period Start";
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter)
                    else
                        if not PeriodInitialized and (InternalDateFilter <> '') then
                            Period.SetFilter("Period Start", InternalDateFilter);
                    Found := PeriodPageMgt.FindDate(Which, Period, PeriodType);
                    if Found then
                        CopyPeriodToBuf(Period, DimCodeBuf);
                end;
            DimOption::Location:
                begin
                    Location.Code := DimCodeBuf.Code;
                    if LocationFilter <> '' then
                        Location.SetFilter(Code, LocationFilter);
                    Found := Location.Find(Which);
                    if Found then
                        CopyLocationToBuf(Location, DimCodeBuf);
                end;
        end;
        exit(Found);
    end;

    local procedure CopyDimValueToBuf(var TheDimValue: Record "Integer"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        case ItemBuffer."Line Option" of
            ItemBuffer."Line Option"::"Profit Calculation":
                case TheDimValue.Number of
                    1:
                        InsertRow('1', ItemBuffer.FieldCaption("Sales (LCY)"), 0, false, TheDimCodeBuf);
                    2:
                        InsertRow('2', ItemBuffer.FieldCaption("COGS (LCY)"), 0, false, TheDimCodeBuf);
                    3:
                        InsertRow('3', ItemBuffer.FieldCaption("Non-Invtbl. Costs (LCY)"), 0, false, TheDimCodeBuf);
                    4:
                        InsertRow('4', ItemBuffer.FieldCaption("Profit (LCY)"), 0, false, TheDimCodeBuf);
                    5:
                        InsertRow('5', ItemBuffer.FieldCaption("Profit %"), 0, false, TheDimCodeBuf);
                end;
            ItemBuffer."Line Option"::"Cost Specification":
                case TheDimValue.Number of
                    1:
                        InsertRow('1', ItemBuffer.FieldCaption("Inventoriable Costs"), 0, true, TheDimCodeBuf);
                    2:
                        InsertRow('2', ItemBuffer.FieldCaption("Direct Cost (LCY)"), 1, false, TheDimCodeBuf);
                    3:
                        InsertRow('3', ItemBuffer.FieldCaption("Revaluation (LCY)"), 1, false, TheDimCodeBuf);
                    4:
                        InsertRow('4', ItemBuffer.FieldCaption("Rounding (LCY)"), 1, false, TheDimCodeBuf);
                    5:
                        InsertRow('5', ItemBuffer.FieldCaption("Indirect Cost (LCY)"), 1, false, TheDimCodeBuf);
                    6:
                        InsertRow('6', ItemBuffer.FieldCaption("Variance (LCY)"), 1, false, TheDimCodeBuf);
                    7:
                        InsertRow('7', ItemBuffer.FieldCaption("Inventoriable Costs, Total"), 0, true, TheDimCodeBuf);
                    8:
                        InsertRow('8', ItemBuffer.FieldCaption("COGS (LCY)"), 0, true, TheDimCodeBuf);
                    9:
                        InsertRow('9', ItemBuffer.FieldCaption("Inventory (LCY)"), 0, true, TheDimCodeBuf);
                end;
        end;
        OnAfterCopyDimValueToBuf(ItemBuffer, TheDimValue, TheDimCodeBuf);
    end;

    local procedure CopyAddChargesToBuf(var TheItemCharge: Record "Item Charge"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := TheItemCharge."No.";
        TheDimCodeBuf.Name := CopyStr(
            StrSubstNo('%1 %2', TheItemCharge."No.", TheItemCharge.Description), 1, 50);
    end;

    local procedure CopyLocationToBuf(var TheLocation: Record Location; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := TheLocation.Code;
        TheDimCodeBuf.Name := TheLocation.Name;
    end;

    local procedure CopyPeriodToBuf(var ThePeriod: Record Date; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := Format(ThePeriod."Period Start");
        TheDimCodeBuf."Period Start" := ThePeriod."Period Start";
        TheDimCodeBuf."Period End" := ThePeriod."Period End";
        TheDimCodeBuf.Name := ThePeriod."Period Name";
    end;

    local procedure InsertRow(Code1: Code[10]; Name1: Text[80]; Indentation1: Integer; Bold1: Boolean; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := Code1;
        TheDimCodeBuf.Name := CopyStr(Name1, 1, MaxStrLen(TheDimCodeBuf.Name));
        TheDimCodeBuf.Indentation := Indentation1;
        TheDimCodeBuf."Show in Bold" := Bold1;
    end;

    local procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        if DateFilter <> '' then begin
            Calendar.SetFilter("Period Start", DateFilter);
            if not PeriodPageMgt.FindDate('+', Calendar, PeriodType) then
                PeriodPageMgt.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;

        PeriodPageMgt.FindDate(SearchText, Calendar, PeriodType);

        if AmountType = AmountType::"Net Change" then begin
            ItemBuffer.SetRange("Date Filter", Calendar."Period Start", Calendar."Period End");
            if ItemBuffer.GetRangeMin("Date Filter") = ItemBuffer.GetRangeMax(ItemBuffer."Date Filter") then
                ItemBuffer.SetRange("Date Filter", ItemBuffer.GetRangeMin(ItemBuffer."Date Filter"));
        end else
            ItemBuffer.SetRange("Date Filter", 0D, Calendar."Period End");

        InternalDateFilter := ItemBuffer.GetFilter("Date Filter");
    end;

    local procedure GetDimSelection(OldDimSelCode: Text[30]): Text[30]
    var
        Location: Record Location;
        DimSelection: Page "Dimension Selection";
    begin
        DimSelection.InsertDimSelBuf(false, Location.TableCaption(), Location.TableCaption());
        DimSelection.InsertDimSelBuf(false, Text002, Text002);

        DimSelection.LookupMode := true;
        if DimSelection.RunModal() = ACTION::LookupOK then
            exit(DimSelection.GetDimSelCode());

        exit(OldDimSelCode);
    end;

    local procedure ValidateColumnDimCode()
    var
        Location: Record Location;
    begin
        if (UpperCase(ColumnDimCode) <> UpperCase(Location.TableCaption())) and
           (UpperCase(ColumnDimCode) <> UpperCase(Text002)) and
           (ColumnDimCode <> '')
        then begin
            Message(Text003, ColumnDimCode);
            ColumnDimCode := '';
        end;

        ItemBuffer."Column Option" := DimCodeToOption(ColumnDimCode);
        InternalDateFilter := ItemBuffer.GetFilter("Date Filter");
        if (ItemBuffer."Line Option" <> ItemBuffer."Line Option"::Period)
           and (ItemBuffer."Column Option" <> ItemBuffer."Column Option"::Period)
        then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    procedure SetItem(var NewItem: Record Item)
    begin
        Item.Get(NewItem."No.");
        Item.CopyFilters(NewItem);

        OnAfterSetItem(Item, ItemFilter);
    end;

    local procedure ItemBufferLineOptionOnAfterVal()
    begin
        CurrPage.Update();
    end;

    local procedure DateFilterOnAfterValidate()
    begin
        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        CurrPage.Update();
    end;

    local procedure ColumnDimCodeOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure ItemFilterOnAfterValidate()
    begin
        Item."No." := ItemFilter;
        Item.Description := '';

        if StrLen(ItemFilter) <= 30 then
            if Item.Get(ItemFilter) then
                ItemName := StrSubstNo('%1  %2', Item."No.", Item.Description);
        ItemName := StrSubstNo('%1  %2', Item."No.", Item.Description);
    end;

    local procedure PeriodTypeOnAfterValidate()
    begin
        // IF ColumnDimOption = ColumnDimOption::Period THEN
        if ItemBuffer."Column Option" = ItemBuffer."Column Option"::Period then
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItem(var Item: Record item; var ItemFilter: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIntegerLineSetFilter(var ItemBuffer: Record "Item Statistics Buffer"; var IntegerLine: Record "Integer");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyDimValueToBuf(var ItemBuffer: Record "Item Statistics Buffer"; var TheDimValue: Record "Integer"; var TheDimCodeBuf: Record "Dimension Code Buffer");
    begin
    end;
}

