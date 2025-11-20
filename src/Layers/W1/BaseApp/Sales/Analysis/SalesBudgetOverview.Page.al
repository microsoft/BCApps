// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Text;
using System.Utilities;

page 7139 "Sales Budget Overview"
{
    Caption = 'Sales Budget Overview';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SaveValues = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrentBudgetName; CurrentBudgetName)
                {
                    ApplicationArea = SalesBudget;
                    Caption = 'Item Budget Name';
                    ToolTip = 'Specifies the name of the budget to be shown in the window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ItemBudgetManagement.LookupItemBudgetName(
                          CurrentBudgetName, ItemBudgetName, ItemStatisticsBuffer,
                          BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
                        ItemBudgetManagement.ValidateLineDimTypeAndCode(
                          ItemBudgetName, LineDimCode, LineDimType, ColumnDimType,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        ItemBudgetManagement.ValidateColumnDimTypeAndCode(
                          ItemBudgetName, ColumnDimCode, ColumnDimType, LineDimType,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        UpdateDimCtrls();
                        UpdateMatrixSubForm();
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        ItemBudgetManagement.CheckBudgetName(CurrentAnalysisArea.AsInteger(), CurrentBudgetName, ItemBudgetName);
                        UpdateMatrixSubForm();
                        CurrentBudgetNameOnAfterValida();
                    end;
                }
                field(LineDimCode; LineDimCode)
                {
                    ApplicationArea = SalesBudget;
                    Caption = 'Show as Lines';
                    ToolTip = 'Specifies which values you want to show as lines in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        NewCode: Text[30];
                    begin
                        NewCode := ItemBudgetManagement.GetDimSelection(LineDimCode, ItemBudgetName);
                        if NewCode <> LineDimCode then begin
                            Text := NewCode;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            ColumnDimCode := '';
                            ItemBudgetManagement.ValidateColumnDimTypeAndCode(
                              ItemBudgetName, ColumnDimCode, ColumnDimType, LineDimType,
                              InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        end;
                        ItemBudgetManagement.ValidateLineDimTypeAndCode(
                          ItemBudgetName, LineDimCode, LineDimType, ColumnDimType,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        LineDimCodeOnAfterValidate();
                    end;
                }
                field(ColumnDimCode; ColumnDimCode)
                {
                    ApplicationArea = SalesBudget;
                    Caption = 'Show as Columns';
                    ShowMandatory = true;
                    ToolTip = 'Specifies which values you want to show as columns in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        NewCode: Text[30];
                    begin
                        NewCode := ItemBudgetManagement.GetDimSelection(ColumnDimCode, ItemBudgetName);
                        if NewCode <> ColumnDimCode then begin
                            Text := NewCode;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            LineDimCode := '';
                            ItemBudgetManagement.ValidateLineDimTypeAndCode(
                              ItemBudgetName, LineDimCode, LineDimType, ColumnDimType,
                              InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        end;
                        ItemBudgetManagement.ValidateColumnDimTypeAndCode(
                          ItemBudgetName, ColumnDimCode, ColumnDimType, LineDimType,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);

                        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                        ColumnDimCodeOnAfterValidate();
                    end;
                }
                field(ValueType; ValueType)
                {
                    ApplicationArea = SalesBudget;
                    Caption = 'Show Value as';
                    ToolTip = 'Specifies if you want to view the item values by sales amount, cost amount, or quantity.';

                    trigger OnValidate()
                    begin
                        ValueTypeOnAfterValidate();
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = SalesBudget;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        PeriodTypeOnAfterValidate();
                    end;
                }
                field(RoundingFactor; RoundingFactor)
                {
                    ApplicationArea = SalesBudget;
                    Caption = 'Rounding Factor';
                    ToolTip = 'Specifies the factor that is used to round the amounts in the columns.';

                    trigger OnValidate()
                    begin
                        RoundingFactorOnAfterValidate();
                    end;
                }
                field(ShowColumnName; ShowColumnName)
                {
                    ApplicationArea = SalesBudget;
                    Caption = 'Show Column Name';
                    ToolTip = 'Specifies that the names of columns are shown in the matrix window.';

                    trigger OnValidate()
                    begin
                        ShowColumnNameOnAfterValidate();
                    end;
                }
            }
            part(MATRIX; "Sales Budget Overview Matrix")
            {
                ApplicationArea = SalesBudget;
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = SalesBudget;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies a date filter by which budget amounts are displayed.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        ItemStatisticsBuffer.SetFilter("Date Filter", DateFilter);
                        DateFilter := ItemStatisticsBuffer.GetFilter("Date Filter");
                        InternalDateFilter := DateFilter;
                        DateFilterOnAfterValidate();
                    end;
                }
                field(SalesCodeFilterCtrl; SourceNoFilter)
                {
                    ApplicationArea = SalesBudget;
                    Caption = 'Customer Filter';
                    ToolTip = 'Specifies the filter that applies to the customers to whom items are sold.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CustList: Page "Customer List";
                        VendList: Page "Vendor List";
                    begin
                        case SourceTypeFilter of
                            SourceTypeFilter::Customer:
                                begin
                                    CustList.LookupMode := true;
                                    if CustList.RunModal() = ACTION::LookupOK then
                                        Text := CustList.GetSelectionFilter()
                                    else
                                        exit(false);
                                end;
                            SourceTypeFilter::Vendor:
                                begin
                                    VendList.LookupMode := true;
                                    if VendList.RunModal() = ACTION::LookupOK then
                                        Text := VendList.GetSelectionFilter()
                                    else
                                        exit(false);
                                end;
                        end;

                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        SourceNoFilterOnAfterValidate();
                    end;
                }
                field(ItemFilter; ItemFilter)
                {
                    ApplicationArea = SalesBudget;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies which items to include in the budget overview.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemList: Page "Item List";
                    begin
                        ItemList.LookupMode(true);
                        if ItemList.RunModal() = ACTION::LookupOK then begin
                            Text := ItemList.GetSelectionFilter();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        ItemFilterOnAfterValidate();
                    end;
                }
                field(BudgetDim1Filter; BudgetDim1Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(1);
                    Caption = 'Budget Dimension 1 Filter';
                    Enabled = BudgetDim1FilterEnable;
                    ToolTip = 'Specifies a filter by a budget dimension. ';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(ItemBudgetName."Budget Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        BudgetDim1FilterOnAfterValidat();
                    end;
                }
                field(BudgetDim2Filter; BudgetDim2Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(2);
                    Caption = 'Budget Dimension 2 Filter';
                    Enabled = BudgetDim2FilterEnable;
                    ToolTip = 'Specifies a second filter by a budget dimension. ';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(ItemBudgetName."Budget Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        BudgetDim2FilterOnAfterValidat();
                    end;
                }
                field(BudgetDim3Filter; BudgetDim3Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(3);
                    Caption = 'Budget Dimension 3 Filter';
                    Enabled = BudgetDim3FilterEnable;
                    ToolTip = 'Specifies a third filter by a budget dimension. ';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(ItemBudgetName."Budget Dimension 3 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        BudgetDim3FilterOnAfterValidat();
                    end;
                }
                field(GlobalDim1Filter; GlobalDim1Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,3,1';
                    Caption = 'Global Dimension 1 Filter';
                    ToolTip = 'Specifies by which global dimension data is shown. Global dimensions are the dimensions that you analyze most frequently. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(GLSetup."Global Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        GlobalDim1FilterOnAfterValidat();
                    end;
                }
                field(GlobalDim2Filter; GlobalDim2Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,3,2';
                    Caption = 'Global Dimension 2 Filter';
                    ToolTip = 'Specifies by which global dimension data is shown. Global dimensions are the dimensions that you analyze most frequently. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(GLSetup."Global Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        GlobalDim2FilterOnAfterValidat();
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Reverse Lines and Columns")
                {
                    ApplicationArea = SalesBudget;
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
                        ItemBudgetManagement.ValidateLineDimTypeAndCode(
                          ItemBudgetName, LineDimCode, LineDimType, ColumnDimType,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        ItemBudgetManagement.ValidateColumnDimTypeAndCode(
                          ItemBudgetName, ColumnDimCode, ColumnDimType, LineDimType,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                        UpdateMatrixSubForm();
                    end;
                }
                separator(Action53)
                {
                }
                action(DeleteBudget)
                {
                    ApplicationArea = SalesBudget;
                    Caption = 'Delete Budget';
                    Image = Delete;
                    ToolTip = 'Delete the current budget.';

                    trigger OnAction()
                    begin
                        ItemBudgetManagement.DeleteBudget(
                          CurrentAnalysisArea.AsInteger(), CurrentBudgetName,
                          ItemFilter, DateFilter,
                          SourceTypeFilter.AsInteger(), SourceNoFilter,
                          GlobalDim1Filter, GlobalDim2Filter,
                          BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
                    end;
                }
                separator(Action55)
                {
                }
            }
            group("Export to Excel")
            {
                Caption = 'Export to Excel';
                Image = ExportToExcel;
                action("Create New Document")
                {
                    ApplicationArea = SalesBudget;
                    Caption = 'Create New Document';
                    Image = ExportToExcel;
                    ToolTip = 'Open the analysis report in a new Excel workbook. This creates an Excel workbook on your device.';

                    trigger OnAction()
                    var
                        ExportItemBudgetToExcel: Report "Export Item Budget to Excel";
                    begin
                        ExportItemBudgetToExcel.SetParameters(
                          CurrentAnalysisArea,
                          CurrentBudgetName,
                          ValueType,
                          GlobalDim1Filter, GlobalDim2Filter,
                          BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter,
                          DateFilter,
                          SourceTypeFilter, SourceNoFilter,
                          ItemFilter,
                          InternalDateFilter, PeriodInitialized, PeriodType,
                          LineDimType, ColumnDimType, LineDimCode, ColumnDimCode, RoundingFactor);
                        ExportItemBudgetToExcel.Run();
                    end;
                }
                action("Update Existing Document")
                {
                    ApplicationArea = SalesBudget;
                    Caption = 'Update Existing Document';
                    Image = ExportToExcel;
                    ToolTip = 'Refresh the data in an existing Excel workbook. You must specify the workbook that you want to update.';

                    trigger OnAction()
                    var
                        ExportItemBudgetToExcel: Report "Export Item Budget to Excel";
                    begin
                        ExportItemBudgetToExcel.SetParameters(
                          CurrentAnalysisArea, CurrentBudgetName, ValueType,
                          GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter,
                          DateFilter, SourceTypeFilter, SourceNoFilter, ItemFilter,
                          InternalDateFilter, PeriodInitialized, PeriodType,
                          LineDimType, ColumnDimType, LineDimCode, ColumnDimCode, RoundingFactor);
                        ExportItemBudgetToExcel.SetUpdateExistingWorksheet(true);
                        ExportItemBudgetToExcel.Run();
                    end;
                }
            }
            action("Import from Excel")
            {
                ApplicationArea = SalesBudget;
                Caption = 'Import from Excel';
                Ellipsis = true;
                Image = ImportExcel;
                ToolTip = 'Import a budget that you exported to Excel earlier.';

                trigger OnAction()
                var
                    ImportItemBudgetFromExcel: Report "Import Item Budget from Excel";
                begin
                    ImportItemBudgetFromExcel.SetParameters(CurrentBudgetName, CurrentAnalysisArea.AsInteger(), ValueType.AsInteger());
                    ImportItemBudgetFromExcel.RunModal();
                    Clear(ImportItemBudgetFromExcel);
                end;
            }
            action("Next Period")
            {
                ApplicationArea = SalesBudget;
                Caption = 'Next Period';
                Image = NextRecord;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    if (LineDimType = LineDimType::Period) or (ColumnDimType = ColumnDimType::Period) then
                        exit;
                    FindPeriod('>');
                    CurrPage.Update();
                    UpdateMatrixSubForm();
                end;
            }
            action("Previous Period")
            {
                ApplicationArea = SalesBudget;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    if (LineDimType = LineDimType::Period) or (ColumnDimType = ColumnDimType::Period) then
                        exit;
                    FindPeriod('<');
                    CurrPage.Update();
                    UpdateMatrixSubForm();
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = SalesBudget;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions("Matrix Page Step Type"::Previous);
                    UpdateMatrixSubForm();
                end;
            }
            action("Previous Column")
            {
                ApplicationArea = SalesBudget;
                Caption = 'Previous Column';
                Image = PreviousRecord;
                ToolTip = 'Go to the previous column.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions("Matrix Page Step Type"::PreviousColumn);
                    UpdateMatrixSubForm();
                end;
            }
            action("Next Column")
            {
                ApplicationArea = SalesBudget;
                Caption = 'Next Column';
                Image = NextRecord;
                ToolTip = 'Go to the next column.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions("Matrix Page Step Type"::NextColumn);
                    UpdateMatrixSubForm();
                end;
            }
            action("Next Set")
            {
                ApplicationArea = SalesBudget;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions("Matrix Page Step Type"::Next);
                    UpdateMatrixSubForm();
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
                actionref("Previous Column_Promoted"; "Previous Column")
                {
                }
                actionref("Next Column_Promoted"; "Next Column")
                {
                }
                actionref("Next Set_Promoted"; "Next Set")
                {
                }
                actionref("Next Period_Promoted"; "Next Period")
                {
                }
                actionref("Previous Period_Promoted"; "Previous Period")
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        BudgetDim3FilterEnable := true;
        BudgetDim2FilterEnable := true;
        BudgetDim1FilterEnable := true;
    end;

    trigger OnOpenPage()
    begin
        CurrentAnalysisArea := CurrentAnalysisArea::Sales;
        ItemBudgetManagement.BudgetNameSelection(
          CurrentAnalysisArea.AsInteger(), CurrentBudgetName, ItemBudgetName, ItemStatisticsBuffer,
          BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);

        if (NewBudgetName <> '') and (CurrentBudgetName <> NewBudgetName) then begin
            CurrentBudgetName := NewBudgetName;
            ItemBudgetManagement.CheckBudgetName(CurrentAnalysisArea.AsInteger(), CurrentBudgetName, ItemBudgetName);
            ItemBudgetManagement.SetItemBudgetName(
              CurrentBudgetName, ItemBudgetName, ItemStatisticsBuffer,
              BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
        end;

        ItemBudgetManagement.SetLineAndColumnDim(
          ItemBudgetName, LineDimCode, LineDimType, ColumnDimCode, ColumnDimType);

        GLSetup.Get();
        SourceTypeFilter := SourceTypeFilter::Customer;

        UpdateDimCtrls();

        FindPeriod('');
        GenerateColumnCaptions("Matrix Page Step Type"::Initial);

        OnOpenPageOnBeforeUpdateMatrixSubform(ItemBudgetName, DateFilter, SourceNoFilter, ItemFilter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter, GlobalDim1Filter, GlobalDim2Filter);
        UpdateMatrixSubForm();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ItemBudgetName: Record "Item Budget Name";
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
        MATRIX_MatrixRecords: array[32] of Record "Dimension Code Buffer";
        ItemBudgetManagement: Codeunit "Item Budget Management";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_CaptionRange: Text;
        FirstColumn: Text;
        LastColumn: Text;
        MATRIX_PrimKeyFirstCaptionInCu: Text;
        MATRIX_CurrentNoOfColumns: Integer;
        CurrentAnalysisArea: Enum "Analysis Area Type";
        SourceTypeFilter: Enum "Analysis Source Type";
        SourceNoFilter: Text;
        ItemFilter: Text;
        ValueType: Enum "Item Analysis Value Type";
        RoundingFactor: Enum "Analysis Rounding Factor";
        LineDimType: Enum "Item Budget Dimension Type";
        ColumnDimType: Enum "Item Budget Dimension Type";
        GlobalDim1Filter: Text;
        GlobalDim2Filter: Text;
        BudgetDim1Filter: Text;
        BudgetDim2Filter: Text;
        BudgetDim3Filter: Text;
        LineDimCode: Text[30];
        ColumnDimCode: Text[30];
        DateFilter: Text;
        InternalDateFilter: Text;
        PeriodInitialized: Boolean;
        ShowColumnName: Boolean;
#pragma warning disable AA0074
        Text003: Label '1,6,,Budget Dimension 1 Filter';
        Text004: Label '1,6,,Budget Dimension 2 Filter';
        Text005: Label '1,6,,Budget Dimension 3 Filter';
        Text100: Label 'Period';
#pragma warning restore AA0074
        NewBudgetName: Code[10];
        BudgetDim1FilterEnable: Boolean;
        BudgetDim2FilterEnable: Boolean;
        BudgetDim3FilterEnable: Boolean;

    protected var
        CurrentBudgetName: Code[10];
        PeriodType: Enum "Analysis Period Type";

    local procedure GenerateColumnCaptions(StepType: Enum "Matrix Page Step Type")
    var
        MATRIX_PeriodRecords: array[32] of Record Date;
        Location: Record Location;
        Item: Record Item;
        Customer: Record Customer;
        Vendor: Record Vendor;
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        i: Integer;
    begin
        Clear(MATRIX_CaptionSet);
        Clear(MATRIX_MatrixRecords);
        FirstColumn := '';
        LastColumn := '';
        MATRIX_CurrentNoOfColumns := 12;

        if ColumnDimCode = '' then
            exit;

        case ColumnDimCode of
            Text100:  // Period
                begin
                    MatrixMgt.GeneratePeriodMatrixData(
                      StepType.AsInteger(), 12, ShowColumnName,
                      PeriodType, DateFilter, MATRIX_PrimKeyFirstCaptionInCu,
                      MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns, MATRIX_PeriodRecords);
                    for i := 1 to 12 do begin
                        MATRIX_MatrixRecords[i]."Period Start" := MATRIX_PeriodRecords[i]."Period Start";
                        MATRIX_MatrixRecords[i]."Period End" := MATRIX_PeriodRecords[i]."Period End";
                    end;
                    FirstColumn := Format(MATRIX_PeriodRecords[1]."Period Start");
                    LastColumn := Format(MATRIX_PeriodRecords[MATRIX_CurrentNoOfColumns]."Period End");
                end;
            Location.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    RecRef.GetTable(Location);
                    RecRef.SetTable(Location);
                    MatrixMgt.GenerateMatrixData(
                      RecRef, StepType.AsInteger(), 12, 1,
                      MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(
                          RecRef, "Matrix Page Step Type"::Same.AsInteger(), 12, 2,
                          MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            Item.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    RecRef.GetTable(Item);
                    RecRef.SetTable(Item);
                    if ItemFilter <> '' then begin
                        FieldRef := RecRef.Field(Item.FieldNo("No."));
                        FieldRef.SetFilter(ItemFilter);
                    end;
                    MatrixMgt.GenerateMatrixData(
                      RecRef, StepType.AsInteger(), 12, 1,
                      MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(
                          RecRef, "Matrix Page Step Type"::Same.AsInteger(), 12, 3,
                          MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            Customer.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    RecRef.GetTable(Customer);
                    RecRef.SetTable(Customer);
                    if SourceNoFilter <> '' then begin
                        FieldRef := RecRef.Field(Customer.FieldNo("No."));
                        FieldRef.SetFilter(SourceNoFilter);
                    end;
                    MatrixMgt.GenerateMatrixData(
                      RecRef, StepType.AsInteger(), 12, 1,
                      MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(
                          RecRef, "Matrix Page Step Type"::Same.AsInteger(), 12, 2,
                          MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            Vendor.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    RecRef.GetTable(Vendor);
                    RecRef.SetTable(Vendor);
                    MatrixMgt.GenerateMatrixData(
                      RecRef, StepType.AsInteger(), 12, 1,
                      MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(
                          RecRef, "Matrix Page Step Type"::Same.AsInteger(), 12, 2,
                          MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            GLSetup."Global Dimension 1 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  GLSetup."Global Dimension 1 Code",
                  GlobalDim1Filter, StepType.AsInteger(), MATRIX_PrimKeyFirstCaptionInCu, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            GLSetup."Global Dimension 2 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  GLSetup."Global Dimension 2 Code",
                  GlobalDim2Filter, StepType.AsInteger(), MATRIX_PrimKeyFirstCaptionInCu, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            ItemBudgetName."Budget Dimension 1 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  ItemBudgetName."Budget Dimension 1 Code",
                  BudgetDim1Filter, StepType.AsInteger(), MATRIX_PrimKeyFirstCaptionInCu, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            ItemBudgetName."Budget Dimension 2 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  ItemBudgetName."Budget Dimension 2 Code",
                  BudgetDim2Filter, StepType.AsInteger(), MATRIX_PrimKeyFirstCaptionInCu, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            ItemBudgetName."Budget Dimension 3 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  ItemBudgetName."Budget Dimension 3 Code",
                  BudgetDim3Filter, StepType.AsInteger(), MATRIX_PrimKeyFirstCaptionInCu, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
        end;
    end;

    local procedure FindPeriod(SearchText: Code[3])
    var
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        PeriodPageMgt.FindPeriodOnMatrixPage(
          DateFilter, InternalDateFilter, SearchText, PeriodType,
          (LineDimType <> LineDimType::Period) and (ColumnDimType <> ColumnDimType::Period));
    end;

    local procedure GetCaptionClass(BudgetDimType: Integer): Text[250]
    begin
        if ItemBudgetName.Name <> CurrentBudgetName then
            ItemBudgetName.Get(CurrentAnalysisArea, CurrentBudgetName);
        case BudgetDimType of
            1:
                begin
                    if ItemBudgetName."Budget Dimension 1 Code" <> '' then
                        exit('1,6,' + ItemBudgetName."Budget Dimension 1 Code");
                    exit(Text003);
                end;
            2:
                begin
                    if ItemBudgetName."Budget Dimension 2 Code" <> '' then
                        exit('1,6,' + ItemBudgetName."Budget Dimension 2 Code");
                    exit(Text004);
                end;
            3:
                begin
                    if ItemBudgetName."Budget Dimension 3 Code" <> '' then
                        exit('1,6,' + ItemBudgetName."Budget Dimension 3 Code");
                    exit(Text005);
                end;
        end;
    end;

    local procedure LookUpDimFilter(Dim: Code[20]; var Text: Text[250]): Boolean
    var
        DimVal: Record "Dimension Value";
        DimValList: Page "Dimension Value List";
    begin
        if Dim = '' then
            exit(false);
        DimVal.SetRange("Dimension Code", Dim);
        DimValList.SetTableView(DimVal);
        DimValList.LookupMode(true);
        if DimValList.RunModal() = ACTION::LookupOK then begin
            DimValList.GetRecord(DimVal);
            Text := DimValList.GetSelectionFilter();
        end;
        exit(true);
    end;

    local procedure UpdateDimCtrls()
    begin
        BudgetDim1FilterEnable := ItemBudgetName."Budget Dimension 1 Code" <> '';
        BudgetDim2FilterEnable := ItemBudgetName."Budget Dimension 2 Code" <> '';
        BudgetDim3FilterEnable := ItemBudgetName."Budget Dimension 3 Code" <> '';
    end;

    procedure SetNewBudgetName(NewPurchBudgetName: Code[10])
    begin
        NewBudgetName := NewPurchBudgetName;
    end;

    local procedure UpdateMatrixSubForm()
    begin
        CurrPage.MATRIX.PAGE.SetFilters(
          DateFilter, ItemFilter, SourceNoFilter,
          GlobalDim1Filter, GlobalDim2Filter,
          BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
        CurrPage.MATRIX.PAGE.LoadMatrix(
          MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns,
          CurrentBudgetName, LineDimType, ColumnDimType, RoundingFactor, ValueType, PeriodType);
        CurrPage.Update(false);
    end;

    local procedure CurrentBudgetNameOnAfterValida()
    begin
        ItemBudgetManagement.SetItemBudgetName(
          CurrentBudgetName, ItemBudgetName, ItemStatisticsBuffer,
          BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
        ItemBudgetManagement.ValidateLineDimTypeAndCode(
          ItemBudgetName, LineDimCode, LineDimType, ColumnDimType,
          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
        ItemBudgetManagement.ValidateColumnDimTypeAndCode(
          ItemBudgetName, ColumnDimCode, ColumnDimType, LineDimType,
          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
        UpdateDimCtrls();
        CurrPage.Update(false);
    end;

    local procedure ColumnDimCodeOnAfterValidate()
    begin
        FindPeriod('');
        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        UpdateMatrixSubForm();
    end;

    local procedure LineDimCodeOnAfterValidate()
    begin
        FindPeriod('');
        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        UpdateMatrixSubForm();
    end;

    local procedure ValueTypeOnAfterValidate()
    begin
        FindPeriod('');
        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        UpdateMatrixSubForm();
    end;

    local procedure PeriodTypeOnAfterValidate()
    begin
        if ColumnDimType = ColumnDimType::Period then
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        UpdateMatrixSubForm();
    end;

    local procedure ShowColumnNameOnAfterValidate()
    begin
        GenerateColumnCaptions("Matrix Page Step Type"::Same);
        UpdateMatrixSubForm();
    end;

    local procedure RoundingFactorOnAfterValidate()
    begin
        UpdateMatrixSubForm();
    end;

    local procedure BudgetDim3FilterOnAfterValidat()
    begin
        if ColumnDimType = ColumnDimType::"Budget Dimension 3" then
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        UpdateMatrixSubForm();
    end;

    local procedure BudgetDim2FilterOnAfterValidat()
    begin
        if ColumnDimType = ColumnDimType::"Budget Dimension 2" then
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        UpdateMatrixSubForm();
    end;

    local procedure BudgetDim1FilterOnAfterValidat()
    begin
        if ColumnDimType = ColumnDimType::"Budget Dimension 1" then
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        UpdateMatrixSubForm();
    end;

    local procedure GlobalDim2FilterOnAfterValidat()
    begin
        if ColumnDimType = ColumnDimType::"Global Dimension 2" then
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        UpdateMatrixSubForm();
    end;

    local procedure GlobalDim1FilterOnAfterValidat()
    begin
        if ColumnDimType = ColumnDimType::"Global Dimension 1" then
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        UpdateMatrixSubForm();
    end;

    local procedure SourceNoFilterOnAfterValidate()
    begin
        if ColumnDimType = ColumnDimType::Customer then
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        UpdateMatrixSubForm();
    end;

    local procedure ItemFilterOnAfterValidate()
    begin
        if ColumnDimType = ColumnDimType::Item then
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        UpdateMatrixSubForm();
    end;

    local procedure DateFilterOnAfterValidate()
    begin
        if ColumnDimType = ColumnDimType::Period then
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        UpdateMatrixSubForm();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeUpdateMatrixSubform(ItemBudgetName: Record "Item Budget Name"; var DateFilter: Text; var SourceNoFilter: Text; var ItemFilter: Text; var BudgetDim1Filter: Text; var BudgetDim2Filter: Text; var BudgetDim3Filter: Text; var GlobalDim1Filter: Text; var GlobalDim2Filter: Text)
    begin
    end;
}

