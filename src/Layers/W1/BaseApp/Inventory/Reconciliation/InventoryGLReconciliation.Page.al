// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reconciliation;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.Utilities;

page 5845 "Inventory - G/L Reconciliation"
{
    AdditionalSearchTerms = 'general ledger reconcile inventory';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory - G/L Reconciliation';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Dimension Code Buffer";
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    begin
                        InvtReportHeader.SetFilter("Posting Date Filter", DateFilter);
                        DateFilter := InvtReportHeader.GetFilter("Posting Date Filter");
                        DateFilterOnAfterValidate();
                    end;
                }
                field(ItemFilter; ItemFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies which items the information is shown for.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Item: Record Item;
                        ItemList: Page "Item List";
                    begin
                        Item.SetRange(Type, Item.Type::Inventory);
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
                        TestWarning();
                        ItemFilterOnAfterValidate();
                    end;
                }
                field(LocationFilter; LocationFilter)
                {
                    ApplicationArea = Location;
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies which item locations the information is shown for.';

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

                    trigger OnValidate()
                    begin
                        TestWarning();
                        LocationFilterOnAfterValidate();
                    end;
                }
                field(Show; ShowWarning)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Warning';
                    Editable = ShowEditable;
                    ToolTip = 'Specifies that a messages will be shown in the Warning field of the grid if there are any discrepancies between the inventory totals and G/L totals. If you choose the Warning field, the program gives you more information on what the warning means.';

                    trigger OnValidate()
                    begin
                        ShowWarningOnAfterValidate();
                    end;
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
                ApplicationArea = Basic, Suite;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "Inventory - G/L Recon Matrix";
                    i: Integer;
                begin
                    Clear(MatrixForm);
                    Clear(MatrixRecords);
                    Clear(MATRIX_CaptionSet);

                    if InvtReportHeader."Column Option" = InvtReportHeader."Line Option"::"Balance Sheet" then begin
                        if (ItemFilter = '') and (LocationFilter = '') then begin
                            if ShowWarning then
                                ColIntegerLine.SetRange(Number, 1, 7)
                            else
                                ColIntegerLine.SetRange(Number, 1, 6)
                        end else
                            ColIntegerLine.SetRange(Number, 1, 4)
                    end else
                        if InvtReportHeader."Column Option" = InvtReportHeader."Line Option"::"Income Statement" then
                            if (ItemFilter = '') and (LocationFilter = '') then begin
                                if ShowWarning then
                                    ColIntegerLine.SetRange(Number, 1, 19)
                                else
                                    ColIntegerLine.SetRange(Number, 1, 18)
                            end else
                                ColIntegerLine.SetRange(Number, 1, 16);
                    i := 1;

                    if FindRec(InvtReportHeader."Column Option", MatrixRecords[i], '-', false) then begin
                        MATRIX_CaptionSet[i] := MatrixRecords[i].Name;
                        i := i + 1;
                        while NextRec(InvtReportHeader."Column Option", MatrixRecords[i], 1, false) <> 0 do begin
                            MATRIX_CaptionSet[i] := MatrixRecords[i].Name;
                            i := i + 1;
                        end;
                    end;
                    if ShowWarning then
                        MATRIX_CurrentNoOfColumns := i
                    else
                        MATRIX_CurrentNoOfColumns := i - 1;

                    MatrixForm.Load(MATRIX_CaptionSet, MatrixRecords, MATRIX_CurrentNoOfColumns, ShowWarning,
                      DateFilter, ItemFilter, LocationFilter);
                    MatrixForm.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Show Matrix_Promoted"; "&Show Matrix")
                {
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if InvtReportHeader."Line Option" = InvtReportHeader."Line Option"::"Balance Sheet" then begin
            if (ItemFilter = '') and (LocationFilter = '') then begin
                if ShowWarning then
                    RowIntegerLine.SetRange(Number, 1, 7)
                else
                    RowIntegerLine.SetRange(Number, 1, 6)
            end else
                RowIntegerLine.SetRange(Number, 1, 4)
        end else
            if InvtReportHeader."Line Option" = InvtReportHeader."Line Option"::"Income Statement" then
                if (ItemFilter = '') and (LocationFilter = '') then begin
                    if ShowWarning then
                        RowIntegerLine.SetRange(Number, 1, 19)
                    else
                        RowIntegerLine.SetRange(Number, 1, 18)
                end else
                    RowIntegerLine.SetRange(Number, 1, 16);
        exit(FindRec(InvtReportHeader."Line Option", Rec, Which, true));
    end;

    trigger OnInit()
    begin
        ShowEditable := true;
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(NextRec(InvtReportHeader."Line Option", Rec, Steps, true));
    end;

    trigger OnOpenPage()
    begin
        GLSetup.Get();
        TestWarning();
        InvtReportHeader.SetFilter("Item Filter", ItemFilter);
        InvtReportHeader.SetFilter("Location Filter", LocationFilter);
        InvtReportHeader.SetFilter("Posting Date Filter", DateFilter);
        InvtReportHeader."Show Warning" := ShowWarning;

        if (LineDimCode = '') and (ColumnDimCode = '') then begin
            LineDimCode := Text004;
            ColumnDimCode := Text005;
        end;
        InvtReportHeader."Line Option" := DimCodeToOption(LineDimCode);
        InvtReportHeader."Column Option" := DimCodeToOption(ColumnDimCode);
    end;

    var
        MatrixRecords: array[32] of Record "Dimension Code Buffer";
        GLSetup: Record "General Ledger Setup";
        InvtReportHeader: Record "Inventory Report Header";
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        RowIntegerLine: Record "Integer";
        ColIntegerLine: Record "Integer";
        MATRIX_CaptionSet: array[32] of Text[100];
        MATRIX_CurrentNoOfColumns: Integer;
        LineDimCode: Text[20];
        ColumnDimCode: Text[20];
        DateFilter: Text[30];
        ItemFilter: Code[250];
        LocationFilter: Code[250];
#pragma warning disable AA0074
        Text004: Label 'Income Statement';
        Text005: Label 'Balance Sheet';
#pragma warning restore AA0074
        ShowWarning: Boolean;
        ShowEditable: Boolean;

    local procedure DimCodeToOption(DimCode: Text[30]): Integer
    begin
        case DimCode of
            '':
                exit(-1);
            Text005:
                exit(0);
            Text004:
                exit(1);
            else
                exit(-1);
        end;
    end;

    local procedure FindRec(DimOption: Option "Balance Sheet","Income Statement"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]; IsRow: Boolean): Boolean
    var
        Found: Boolean;
    begin
        case DimOption of
            DimOption::"Balance Sheet",
          DimOption::"Income Statement":
                if IsRow then begin
                    if Evaluate(RowIntegerLine.Number, DimCodeBuf.Code) then;
                    Found := RowIntegerLine.Find(Which);
                    if Found then
                        CopyDimValueToBuf(RowIntegerLine, DimCodeBuf, IsRow);
                end else begin
                    if Evaluate(ColIntegerLine.Number, DimCodeBuf.Code) then;
                    Found := ColIntegerLine.Find(Which);
                    if Found then
                        CopyDimValueToBuf(ColIntegerLine, DimCodeBuf, IsRow);
                end;
        end;
        exit(Found);
    end;

    local procedure NextRec(DimOption: Option "Balance Sheet","Income Statement"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer; IsRow: Boolean): Integer
    var
        ResultSteps: Integer;
    begin
        case DimOption of
            DimOption::"Balance Sheet",
          DimOption::"Income Statement":
                if IsRow then begin
                    if Evaluate(RowIntegerLine.Number, DimCodeBuf.Code) then;
                    ResultSteps := RowIntegerLine.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(RowIntegerLine, DimCodeBuf, IsRow);
                end else begin
                    if Evaluate(ColIntegerLine.Number, DimCodeBuf.Code) then;
                    ResultSteps := ColIntegerLine.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(ColIntegerLine, DimCodeBuf, IsRow);
                end;
        end;
        exit(ResultSteps);
    end;

    local procedure CopyDimValueToBuf(var TheDimValue: Record "Integer"; var TheDimCodeBuf: Record "Dimension Code Buffer"; IsRow: Boolean)
    begin
        case true of
            ((InvtReportHeader."Line Option" = InvtReportHeader."Line Option"::"Balance Sheet") and IsRow) or
              ((InvtReportHeader."Column Option" = InvtReportHeader."Column Option"::"Balance Sheet") and not IsRow):
                case TheDimValue.Number of
                    1:
                        InsertRow('1', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory), 0, false, TheDimCodeBuf);
                    2:
                        InsertRow('2', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory (Interim)"), 0, false, TheDimCodeBuf);
                    3:
                        InsertRow('3', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory"), 0, false, TheDimCodeBuf);
                    4:
                        InsertRow('4', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), 0, true, TheDimCodeBuf);
                    5:
                        InsertRow('5', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"), 0, true, TheDimCodeBuf);
                    6:
                        InsertRow('6', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference), 0, true, TheDimCodeBuf);
                    7:
                        InsertRow('7', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning), 0, true, TheDimCodeBuf);
                end;
            ((InvtReportHeader."Line Option" = InvtReportHeader."Line Option"::"Income Statement") and IsRow) or
              ((InvtReportHeader."Column Option" = InvtReportHeader."Column Option"::"Income Statement") and not IsRow):
                case TheDimValue.Number of
                    1:
                        InsertRow('1', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory To WIP"), 0, false, TheDimCodeBuf);
                    2:
                        InsertRow('2', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP To Interim"), 0, false, TheDimCodeBuf);
                    3:
                        InsertRow('3', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."COGS (Interim)"), 0, false, TheDimCodeBuf);
                    4:
                        InsertRow('4', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Direct Cost Applied"), 0, false, TheDimCodeBuf);
                    5:
                        InsertRow('5', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Overhead Applied"), 0, false, TheDimCodeBuf);
                    6:
                        InsertRow('6', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory Adjmt."), 0, false, TheDimCodeBuf);
                    7:
                        InsertRow('7', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Invt. Accrual (Interim)"), 0, false, TheDimCodeBuf);
                    8:
                        InsertRow('8', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.COGS), 0, false, TheDimCodeBuf);
                    9:
                        InsertRow('9', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Purchase Variance"), 0, false, TheDimCodeBuf);
                    10:
                        InsertRow('10', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Material Variance"), 0, false, TheDimCodeBuf);
                    11:
                        InsertRow('11', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Mat. Non-Inventory Variance"), 0, false, TheDimCodeBuf);
                    12:
                        InsertRow('12', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Capacity Variance"), 0, false, TheDimCodeBuf);
                    13:
                        InsertRow('13', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Subcontracted Variance"), 0, false, TheDimCodeBuf);
                    14:
                        InsertRow('14', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Capacity Overhead Variance"), 0, false, TheDimCodeBuf);
                    15:
                        InsertRow('15', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Mfg. Overhead Variance"), 0, false, TheDimCodeBuf);
                    16:
                        InsertRow('16', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), 0, true, TheDimCodeBuf);
                    17:
                        InsertRow('17', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"), 0, true, TheDimCodeBuf);
                    18:
                        InsertRow('18', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference), 0, true, TheDimCodeBuf);
                    19:
                        InsertRow('19', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning), 0, true, TheDimCodeBuf);
                end;
        end
    end;

    local procedure InsertRow(Code1: Code[10]; Name1: Text[80]; Indentation1: Integer; Bold1: Boolean; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := Code1;
        TheDimCodeBuf.Name := CopyStr(Name1, 1, MaxStrLen(TheDimCodeBuf.Name));
        TheDimCodeBuf.Indentation := Indentation1;
        TheDimCodeBuf."Show in Bold" := Bold1;
    end;

    local procedure TestWarning()
    begin
        ShowEditable := true;
        if ShowWarning then begin
            if (ItemFilter <> '') or (LocationFilter <> '') then begin
                ShowWarning := false;
                ShowEditable := false;
            end;
        end else
            if (ItemFilter <> '') or (LocationFilter <> '') then begin
                ShowWarning := false;
                ShowEditable := false;
            end;
    end;

    local procedure LocationFilterOnAfterValidate()
    begin
        InvtReportHeader.SetFilter("Location Filter", LocationFilter);
        CurrPage.Update();
    end;

    local procedure DateFilterOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure ItemFilterOnAfterValidate()
    begin
        InvtReportHeader.SetFilter("Item Filter", ItemFilter);
        CurrPage.Update();
    end;

    local procedure ShowWarningOnAfterValidate()
    begin
        InvtReportHeader."Show Warning" := ShowWarning;
        CurrPage.Update();
    end;
}

