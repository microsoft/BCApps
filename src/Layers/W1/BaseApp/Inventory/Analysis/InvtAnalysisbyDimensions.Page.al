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
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Text;
using System.Utilities;

page 7159 "Invt. Analysis by Dimensions"
{
    Caption = 'Invt. Analysis by Dimensions';
    DataCaptionExpression = CurrentItemAnalysisViewCode;
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
                field(CurrentItemAnalysisViewCode; CurrentItemAnalysisViewCode)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Analysis View Code';
                    ToolTip = 'Specifies the code for the analysis view that the filter belongs to.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ItemAnalysisMgt.LookupItemAnalysisView(
                          CurrentAnalysisArea.AsInteger(), CurrentItemAnalysisViewCode, ItemAnalysisView, ItemStatisticsBuffer,
                          Dim1Filter, Dim2Filter, Dim3Filter);
                        ItemAnalysisMgt.SetLineAndColumnDim(
                          ItemAnalysisView, LineDimCode, LineDimType, ColumnDimCode, ColumnDimType);
                        UpdateFilterFields();
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        ItemAnalysisMgt.CheckAnalysisView(CurrentAnalysisArea.AsInteger(), CurrentItemAnalysisViewCode, ItemAnalysisView);
                        ItemAnalysisMgt.SetItemAnalysisView(
                          CurrentAnalysisArea.AsInteger(), CurrentItemAnalysisViewCode, ItemAnalysisView, ItemStatisticsBuffer,
                          Dim1Filter, Dim2Filter, Dim3Filter);
                        OnValidateCurrentItemAnalysisViewCodeOnAfterSetItemAnalysisView(ItemAnalysisView);
                        ItemAnalysisMgt.SetLineAndColumnDim(
                          ItemAnalysisView, LineDimCode, LineDimType, ColumnDimCode, ColumnDimType);
                        UpdateFilterFields();
                        CurrPage.Update(false);
                    end;
                }
                field(LineDimCode; LineDimCode)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show as Lines';
                    ToolTip = 'Specifies which values you want to show as lines in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        NewCode: Text[30];
                    begin
                        NewCode := ItemAnalysisMgt.GetDimSelection(LineDimCode, ItemAnalysisView);
                        if NewCode <> LineDimCode then begin
                            Text := NewCode;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            ColumnDimCode := '';
                            ItemAnalysisMgt.ValidateColumnDimTypeAndCode(
                              ItemAnalysisView, ColumnDimCode, ColumnDimType, LineDimType,
                              InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        end;
                        ItemAnalysisMgt.ValidateLineDimTypeAndCode(
                          ItemAnalysisView, LineDimCode, LineDimType, ColumnDimType,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        if LineDimType = LineDimType::Period then
                            Rec.SetCurrentKey("Period Start")
                        else
                            Rec.SetCurrentKey(Code);
                        CurrPage.Update(false);
                    end;
                }
                field(ColumnDimCode; ColumnDimCode)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show as Columns';
                    ToolTip = 'Specifies which values you want to show as columns in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        NewCode: Text[30];
                    begin
                        NewCode := ItemAnalysisMgt.GetDimSelection(ColumnDimCode, ItemAnalysisView);
                        if NewCode <> ColumnDimCode then begin
                            Text := NewCode;
                            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            LineDimCode := '';
                            ItemAnalysisMgt.ValidateLineDimTypeAndCode(
                              ItemAnalysisView, LineDimCode, LineDimType, ColumnDimType,
                              InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        end;
                        ItemAnalysisMgt.ValidateColumnDimTypeAndCode(
                          ItemAnalysisView, ColumnDimCode, ColumnDimType, LineDimType,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);

                        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                        CurrPage.Update(false);
                    end;
                }
                field(ValueType; ValueType)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show Value As';
                    ToolTip = 'Specifies how data is shown in the analysis view.';
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        ItemStatisticsBuffer.SetFilter("Date Filter", DateFilter);
                        DateFilter := ItemStatisticsBuffer.GetFilter("Date Filter");
                        InternalDateFilter := DateFilter;

                        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                        CurrPage.Update();
                    end;
                }
                field(ItemFilter; ItemFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies a filter to specify the items for which values will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemList: Page "Item List";
                    begin
                        ItemList.LookupMode(true);
                        OnLookupItemFilterOnBeforeRunItemList(ItemList, ItemAnalysisView);
                        if ItemList.RunModal() = ACTION::LookupOK then begin
                            Text := ItemList.GetSelectionFilter();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    var
                        ShouldUpdateColumnCaptions: Boolean;
                    begin
                        ItemStatisticsBuffer.SetFilter("Item Filter", ItemFilter);
                        ShouldUpdateColumnCaptions := ColumnDimType = ColumnDimType::Item;
                        OnValidateItemFilterOnAfterCalcShouldUpdateColumnCaptions(ItemAnalysisView, ItemStatisticsBuffer, ColumnDimType, ShouldUpdateColumnCaptions);
                        if ShouldUpdateColumnCaptions then
                            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                        CurrPage.Update(false);
                    end;
                }
                field(LocationFilter; LocationFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies the filter through which you want to analyze inventory entries.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        LocationList: Page "Location List";
                    begin
                        LocationList.LookupMode(true);
                        if LocationList.RunModal() = ACTION::LookupOK then begin
                            Text := LocationList.GetSelectionFilter();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    var
                        ShouldUpdateColumnCaptions: Boolean;
                    begin
                        ItemStatisticsBuffer.SetFilter("Location Filter", LocationFilter);
                        ShouldUpdateColumnCaptions := ColumnDimType = ColumnDimType::Location;
                        OnValidateItemFilterOnAfterCalcShouldUpdateColumnCaptions(ItemAnalysisView, ItemStatisticsBuffer, ColumnDimType, ShouldUpdateColumnCaptions);
                        if ShouldUpdateColumnCaptions then
                            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                        CurrPage.Update(false);
                    end;
                }
                field(BudgetFilter; BudgetFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Budget Filter';
                    ToolTip = 'Specifies the budget that information in the matrix is shown for.';
                    Visible = false;
                }
                field(Dim1Filter; Dim1Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = ItemAnalysisMgt.GetCaptionClass(1, ItemAnalysisView);
                    Caption = 'Dimension 1 Filter';
                    Enabled = Dim1FilterEnable;
                    ToolTip = 'Specifies a filter for the Dimension 1 for which entries will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(ItemAnalysisMgt.LookUpDimFilter(ItemAnalysisView."Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        ItemStatisticsBuffer.SetFilter("Dimension 1 Filter", Dim1Filter);
                        if ColumnDimType = ColumnDimType::"Dimension 1" then
                            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                        CurrPage.Update();
                    end;
                }
                field(Dim2Filter; Dim2Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = ItemAnalysisMgt.GetCaptionClass(2, ItemAnalysisView);
                    Caption = 'Dimension 2 Filter';
                    Enabled = Dim2FilterEnable;
                    ToolTip = 'Specifies a filter for the Dimension 2 for which entries will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(ItemAnalysisMgt.LookUpDimFilter(ItemAnalysisView."Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        ItemStatisticsBuffer.SetFilter("Dimension 2 Filter", Dim2Filter);
                        if ColumnDimType = ColumnDimType::"Dimension 2" then
                            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                        CurrPage.Update();
                    end;
                }
                field(Dim3Filter; Dim3Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = ItemAnalysisMgt.GetCaptionClass(3, ItemAnalysisView);
                    Caption = 'Dimension 3 Filter';
                    Enabled = Dim3FilterEnable;
                    ToolTip = 'Specifies a filter for the Dimension 3 for which entries will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(ItemAnalysisMgt.LookUpDimFilter(ItemAnalysisView."Dimension 3 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        ItemStatisticsBuffer.SetFilter("Dimension 3 Filter", Dim3Filter);
                        if ColumnDimType = ColumnDimType::"Dimension 3" then
                            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                        CurrPage.Update();
                    end;
                }
            }
            group(Options)
            {
                Caption = 'Options';
                field(ShowActualBudget; ShowActualBudget)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show';
                    ToolTip = 'Specifies if the selected value is shown in the window.';
                }
                field(RoundingFactor; RoundingFactor)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Rounding Factor';
                    ToolTip = 'Specifies the factor that is used to round the amounts.';
                }
                field(ShowColumnName; ShowColumnName)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show Column Name';
                    ToolTip = 'Specifies that the names of columns are shown in the matrix window.';

                    trigger OnValidate()
                    begin
                        GenerateColumnCaptions("Matrix Page Step Type"::Same);
                    end;
                }
                field(ShowOppositeSign; ShowOppositeSign)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show Opposite Sign';
                    MultiLine = true;
                    ToolTip = 'Specifies whether to show debits as negative amounts (with minus signs) and credits as positive amounts in the matrix window.';
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        if ColumnDimType = ColumnDimType::Period then
                            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                    end;
                }
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
        area(navigation)
        {
            group("&Actions")
            {
                Caption = '&Actions';
                Image = "Action";
                action(ReverseLinesAndColumns)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Reverse Lines and Columns';
                    Image = Undo;
                    ToolTip = 'Change the display of the matrix by inverting the values in the Show as Lines and Show as Columns fields.';

                    trigger OnAction()
                    var
                        TempDimCode: Text[30];
                    begin
                        TempDimCode := ColumnDimCode;
                        ColumnDimCode := LineDimCode;
                        LineDimCode := TempDimCode;
                        ItemAnalysisMgt.ValidateLineDimTypeAndCode(
                          ItemAnalysisView, LineDimCode, LineDimType, ColumnDimType,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        ItemAnalysisMgt.ValidateColumnDimTypeAndCode(
                          ItemAnalysisView, ColumnDimCode, ColumnDimType, LineDimType,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                    end;
                }
                action(ExportToExcel)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Export to Excel';
                    Image = ExportToExcel;
                    ToolTip = 'Export the information in the analysis report to Excel.';

                    trigger OnAction()
                    var
                        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
                        ItemAnalysisViewToExcel: Codeunit "Export Item Analysis View";
                    begin
                        ItemAnalysisViewToExcel.SetCommonFilters(
                          CurrentAnalysisArea.AsInteger(), CurrentItemAnalysisViewCode,
                          ItemAnalysisViewEntry, DateFilter, ItemFilter, Dim1Filter, Dim2Filter, Dim3Filter, LocationFilter);
                        ItemAnalysisViewEntry.FindFirst();
                        ItemAnalysisViewToExcel.ExportData(
                          ItemAnalysisViewEntry, ShowColumnName, DateFilter, ItemFilter, BudgetFilter,
                          Dim1Filter, Dim2Filter, Dim3Filter, ShowActualBudget.AsInteger(), LocationFilter, ShowOppositeSign);
                    end;
                }
            }
        }
        area(processing)
        {
            action(ShowMatrix)
            {
                ApplicationArea = Dimensions;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'View the actual analysis report according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "Invt. Analys by Dim. Matrix";
                begin
                    Clear(MatrixForm);
                    MatrixForm.LoadMatrix(
                        MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns,
                        LineDimType, ColumnDimType, RoundingFactor, DateFilter,
                        ValueType, ItemAnalysisView, CurrentItemAnalysisViewCode,
                        ItemFilter, LocationFilter, BudgetFilter, Dim1Filter, Dim2Filter, Dim3Filter, ShowOppositeSign);
                    OnShowMatrixActionOnBeforeRunMatrixForm(MatrixForm, ItemAnalysisView);
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
                actionref(ExportToExcel_Promoted; ExportToExcel)
                {
                }
                actionref(ReverseLinesAndColumns_Promoted; ReverseLinesAndColumns)
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        Dim3FilterEnable := true;
        Dim2FilterEnable := true;
        Dim1FilterEnable := true;
    end;

    trigger OnOpenPage()
    begin
        CurrentAnalysisArea := CurrentAnalysisArea::Inventory;

        GLSetup.Get();

        ItemAnalysisMgt.AnalysisViewSelection(
          CurrentAnalysisArea.AsInteger(), CurrentItemAnalysisViewCode, ItemAnalysisView, ItemStatisticsBuffer,
          Dim1Filter, Dim2Filter, Dim3Filter);

        if (NewItemAnalysisCode <> '') and (NewItemAnalysisCode <> CurrentItemAnalysisViewCode) then begin
            CurrentItemAnalysisViewCode := NewItemAnalysisCode;
            ItemAnalysisMgt.CheckAnalysisView(CurrentAnalysisArea.AsInteger(), CurrentItemAnalysisViewCode, ItemAnalysisView);
            ItemAnalysisMgt.SetItemAnalysisView(
              CurrentAnalysisArea.AsInteger(), CurrentItemAnalysisViewCode, ItemAnalysisView, ItemStatisticsBuffer,
              Dim1Filter, Dim2Filter, Dim3Filter);
        end;

        ItemAnalysisMgt.SetLineAndColumnDim(
          ItemAnalysisView, LineDimCode, LineDimType, ColumnDimCode, ColumnDimType);
        UpdateFilterFields();

        FindPeriod('');
        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
    end;

    var
        MATRIX_MatrixRecords: array[32] of Record "Dimension Code Buffer";
        GLSetup: Record "General Ledger Setup";
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
        ItemAnalysisMgt: Codeunit "Item Analysis Management";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_CaptionRange: Text;
        FirstColumn: Text;
        LastColumn: Text;
        MATRIX_PrimKeyFirstCaption: Text;
        MATRIX_CurrentNoOfColumns: Integer;
        CurrentAnalysisArea: Enum "Analysis Area Type";
        CurrentItemAnalysisViewCode: Code[10];
        ItemFilter: Code[250];
        LocationFilter: Code[250];
        BudgetFilter: Code[250];
        ValueType: Enum "Item Analysis Value Type";
        ShowActualBudget: Enum "Item Analysis Show Type";
        RoundingFactor: Enum "Analysis Rounding Factor";
        PeriodType: Enum "Analysis Period Type";
        Dim1Filter: Code[250];
        Dim2Filter: Code[250];
        Dim3Filter: Code[250];
        LineDimCode: Text[30];
        ColumnDimCode: Text[30];
        DateFilter: Text[30];
        InternalDateFilter: Text[30];
        PeriodInitialized: Boolean;
        ShowColumnName: Boolean;
        ShowOppositeSign: Boolean;
#pragma warning disable AA0074
        Text100: Label 'Period';
#pragma warning restore AA0074
        NewItemAnalysisCode: Code[10];
        Dim1FilterEnable: Boolean;
        Dim2FilterEnable: Boolean;
        Dim3FilterEnable: Boolean;

    protected var
        ItemAnalysisView: Record "Item Analysis View";
        LineDimType: Enum "Item Analysis Dimension Type";
        ColumnDimType: Enum "Item Analysis Dimension Type";

    protected procedure GenerateColumnCaptions(StepType: Enum "Matrix Page Step Type")
    var
        MATRIX_PeriodRecords: array[32] of Record Date;
        Location: Record Location;
        Item: Record Item;
        Customer: Record Customer;
        Vendor: Record Vendor;
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
        i: Integer;
    begin
        Clear(MATRIX_CaptionSet);
        Clear(MATRIX_MatrixRecords);
        FirstColumn := '';
        LastColumn := '';
        MATRIX_CurrentNoOfColumns := ArrayLen(MATRIX_CaptionSet);

        case ColumnDimCode of
            Text100: // Period
                begin
                    MatrixMgt.GeneratePeriodMatrixData(StepType.AsInteger(), ArrayLen(MATRIX_CaptionSet), ShowColumnName,
                      PeriodType, DateFilter, MATRIX_PrimKeyFirstCaption,
                      MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns, MATRIX_PeriodRecords);
                    for i := 1 to ArrayLen(MATRIX_CaptionSet) do begin
                        MATRIX_MatrixRecords[i]."Period Start" := MATRIX_PeriodRecords[i]."Period Start";
                        MATRIX_MatrixRecords[i]."Period End" := MATRIX_PeriodRecords[i]."Period End";
                    end;
                    FirstColumn := Format(MATRIX_PeriodRecords[1]."Period Start");
                    LastColumn := Format(MATRIX_PeriodRecords[MATRIX_CurrentNoOfColumns]."Period End");
                end;
            Location.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    Location.SetFilter(Code, LocationFilter);
                    RecRef.GetTable(Location);
                    RecRef.SetTable(Location);
                    MatrixMgt.GenerateMatrixData(RecRef, StepType.AsInteger(), ArrayLen(MATRIX_CaptionSet), 1,
                      MATRIX_PrimKeyFirstCaption, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(
                            RecRef, "Matrix Page Step Type"::Same.AsInteger(), ArrayLen(MATRIX_CaptionSet), 2,
                            MATRIX_PrimKeyFirstCaption, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            Item.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    Item.SetFilter("No.", ItemFilter);
                    RecRef.GetTable(Item);
                    RecRef.SetTable(Item);

                    MatrixMgt.GenerateMatrixData(RecRef, StepType.AsInteger(), ArrayLen(MATRIX_CaptionSet), 1,
                      MATRIX_PrimKeyFirstCaption, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(
                            RecRef, "Matrix Page Step Type"::Same.AsInteger(), ArrayLen(MATRIX_CaptionSet), 3,
                            MATRIX_PrimKeyFirstCaption, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            Customer.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    RecRef.GetTable(Customer);
                    RecRef.SetTable(Customer);
                    MatrixMgt.GenerateMatrixData(RecRef, StepType.AsInteger(), ArrayLen(MATRIX_CaptionSet), 1,
                      MATRIX_PrimKeyFirstCaption, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(RecRef, "Matrix Page Step Type"::Same.AsInteger(), ArrayLen(MATRIX_CaptionSet), 2,
                          MATRIX_PrimKeyFirstCaption, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            Vendor.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    RecRef.GetTable(Vendor);
                    RecRef.SetTable(Vendor);
                    MatrixMgt.GenerateMatrixData(RecRef, StepType.AsInteger(), ArrayLen(MATRIX_CaptionSet), 1,
                      MATRIX_PrimKeyFirstCaption, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(
                            RecRef, "Matrix Page Step Type"::Same.AsInteger(), ArrayLen(MATRIX_CaptionSet), 2,
                            MATRIX_PrimKeyFirstCaption, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            ItemAnalysisView."Dimension 1 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  ItemAnalysisView."Dimension 1 Code",
                  Dim1Filter, StepType.AsInteger(), MATRIX_PrimKeyFirstCaption, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            ItemAnalysisView."Dimension 2 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  ItemAnalysisView."Dimension 2 Code",
                  Dim2Filter, StepType.AsInteger(), MATRIX_PrimKeyFirstCaption, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            ItemAnalysisView."Dimension 3 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  ItemAnalysisView."Dimension 3 Code",
                  Dim3Filter, StepType.AsInteger(), MATRIX_PrimKeyFirstCaption, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
        end;

        OnAfterGenerateColumnCaptions(
            MatrixMgt, ItemAnalysisView, MATRIX_MatrixRecords, MATRIX_CaptionSet, MATRIX_PrimKeyFirstCaption, MATRIX_CaptionRange,
            MATRIX_CurrentNoOfColumns, ColumnDimCode, StepType, FirstColumn, LastColumn, ShowColumnName);
    end;

    local procedure FindPeriod(SearchText: Code[3])
    var
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        PeriodPageMgt.FindPeriodOnMatrixPage(
          DateFilter, InternalDateFilter, SearchText, PeriodType,
          (LineDimType <> LineDimType::Period) and (ColumnDimType <> ColumnDimType::Period));
    end;

    local procedure UpdateFilterFields()
    var
        ItemAnalysisViewFilter: Record "Item Analysis View Filter";
    begin
        ItemFilter := ItemAnalysisView."Item Filter";
        Dim1Filter := '';
        Dim2Filter := '';
        Dim3Filter := '';

        Dim1FilterEnable := ItemAnalysisView."Dimension 1 Code" <> '';
        Dim2FilterEnable := ItemAnalysisView."Dimension 2 Code" <> '';
        Dim3FilterEnable := ItemAnalysisView."Dimension 3 Code" <> '';

        if Dim1FilterEnable then
            if ItemAnalysisViewFilter.Get(
                 ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, ItemAnalysisView."Dimension 1 Code")
            then
                Dim1Filter := ItemAnalysisViewFilter."Dimension Value Filter";

        if Dim2FilterEnable then
            if ItemAnalysisViewFilter.Get(
                 ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, ItemAnalysisView."Dimension 2 Code")
            then
                Dim2Filter := ItemAnalysisViewFilter."Dimension Value Filter";

        if Dim3FilterEnable then
            if ItemAnalysisViewFilter.Get(
                 ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, ItemAnalysisView."Dimension 3 Code")
            then
                Dim3Filter := ItemAnalysisViewFilter."Dimension Value Filter";

        OnAfterUpdateFilterFields(ItemAnalysisView, ItemFilter, Dim1Filter, Dim2Filter, Dim3Filter);
    end;

    procedure SetCurrentAnalysisViewCode(NewAnalysisViewCode: Code[10])
    begin
        NewItemAnalysisCode := NewAnalysisViewCode;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGenerateColumnCaptions(var MatrixMgt: Codeunit "Matrix Management"; var ItemAnalysisView: Record "Item Analysis View"; var MATRIX_MatrixRecords: array[32] of Record "Dimension Code Buffer"; var MATRIX_CaptionSet: array[32] of Text[1024]; var MATRIX_PrimKeyFirstCaption: Text; var MATRIX_CaptionRange: Text; MATRIX_CurrentNoOfColumns: Integer; ColumnDimCode: Text[30]; StepType: Enum "Matrix Page Step Type"; var FirstColumn: Text; var LastColumn: Text; ShowColumnName: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateFilterFields(var ItemAnalysisView: Record "Item Analysis View"; var ItemFilter: Code[250]; var Dim1Filter: Code[250]; var Dim2Filter: Code[250]; var Dim3Filter: Code[250])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnLookupItemFilterOnBeforeRunItemList(var ItemList: Page "Item List"; ItemAnalysisView: Record "Item Analysis View")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnShowMatrixActionOnBeforeRunMatrixForm(var InvtAnalysByDimMatrix: Page "Invt. Analys by Dim. Matrix"; ItemAnalysisView: Record "Item Analysis View")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateCurrentItemAnalysisViewCodeOnAfterSetItemAnalysisView(var ItemAnalysisView: Record "Item Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemFilterOnAfterCalcShouldUpdateColumnCaptions(var ItemAnalysisView: Record "Item Analysis View"; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; ColumnDimType: Enum "Item Analysis Dimension Type"; var ShouldUpdateColumnCaptions: Boolean)
    begin
    end;
}

