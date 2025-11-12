// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;
using System.Utilities;

report 7131 "Import Item Budget from Excel"
{
    Caption = 'Import Item Budget from Excel';
    ProcessingOnly = true;

    dataset
    {
        dataitem(ItemBudgetBuf; "Item Budget Buffer")
        {
            DataItemTableView = sorting("Item No.", "Source Type", "Source No.", "Location Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Budget Dimension 1 Code", "Budget Dimension 2 Code", "Budget Dimension 3 Code", Date);

            trigger OnAfterGetRecord()
            begin
                RecNo := RecNo + 1;
                ItemBudgetEntry.Init();
                ItemBudgetEntry.Validate("Entry No.", EntryNo);
                ItemBudgetEntry.Validate("Analysis Area", AnalysisArea);
                ItemBudgetEntry.Validate("Budget Name", ToItemBudgetName);
                ItemBudgetEntry.Validate("Item No.", "Item No.");
                ItemBudgetEntry.Validate("Location Code", "Location Code");
                ItemBudgetEntry.Validate(Date, Date);
                ItemBudgetEntry.Validate(Description, Description);
                ItemBudgetEntry.Validate("Source Type", "Source Type");
                ItemBudgetEntry.Validate("Source No.", "Source No.");
                ItemBudgetEntry.Validate("Sales Amount", "Sales Amount");
                ItemBudgetEntry.Validate(Quantity, Quantity);
                ItemBudgetEntry.Validate("Cost Amount", "Cost Amount");
                ItemBudgetEntry.Validate("Global Dimension 1 Code", "Global Dimension 1 Code");
                ItemBudgetEntry.Validate("Global Dimension 2 Code", "Global Dimension 2 Code");
                ItemBudgetEntry.Validate("Budget Dimension 1 Code", "Budget Dimension 1 Code");
                ItemBudgetEntry.Validate("Budget Dimension 2 Code", "Budget Dimension 2 Code");
                ItemBudgetEntry.Validate("Budget Dimension 3 Code", "Budget Dimension 3 Code");
                ItemBudgetEntry.Validate("User ID", UserId);
                ItemBudgetEntry.Insert(true);
                EntryNo := EntryNo + 1;
            end;

            trigger OnPostDataItem()
            begin
                if RecNo > 0 then
                    Message(Text004, ItemBudgetEntry.TableCaption(), RecNo);
            end;

            trigger OnPreDataItem()
            begin
                RecNo := 0;

                if ImportOption = ImportOption::"Replace entries" then begin
                    ItemBudgetEntry.SetRange("Analysis Area", AnalysisArea);
                    ItemBudgetEntry.SetRange("Budget Name", ToItemBudgetName);
                    ItemBudgetEntry.DeleteAll(true);
                end;

                ItemBudgetEntry.Reset();
                if ItemBudgetEntry.FindLast() then
                    EntryNo := ItemBudgetEntry."Entry No." + 1
                else
                    EntryNo := 1;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ToItemBudgetName; ToItemBudgetName)
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Budget Name';
                        ToolTip = 'Specifies the name of the budget.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            ItemBudgetName: Record "Item Budget Name";
                        begin
                            ItemBudgetName.FilterGroup := 2;
                            ItemBudgetName.SetRange("Analysis Area", AnalysisArea);
                            ItemBudgetName.FilterGroup := 0;
                            if PAGE.RunModal(PAGE::"Item Budget Names", ItemBudgetName) = ACTION::LookupOK then begin
                                Text := ItemBudgetName.Name;
                                exit(true);
                            end;
                        end;
                    }
                    field(ImportOption; ImportOption)
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Option';
                        OptionCaption = 'Replace entries,Add entries';
                        ToolTip = 'Specifies whether you want the program to add the budget entries from Excel to budget entries currently in the program, or you want the program to replace entries in Business Central with the budget entries from Excel.';
                    }
                    field(Description; Description)
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Description';
                        ToolTip = 'Specifies the description of what you are importing from Excel.';
                    }
                    field(PurchValueType; ValueType)
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Import Value as';
                        OptionCaption = ',Cost Amount,Quantity';
                        ToolTip = 'Specifies the type of value that the imported Excel budget contains.';
                        Visible = PurchValueTypeVisible;
                    }
                    field(SalesValueType; ValueType)
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Import Value as';
                        OptionCaption = 'Sales Amount,COGS Amount,Quantity';
                        ToolTip = 'Specifies the type of value that the imported Excel budget contains.';
                        Visible = SalesValueTypeVisible;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            PurchValueTypeVisible := true;
            SalesValueTypeVisible := true;
        end;

        trigger OnOpenPage()
        var
            ItemBudgetName: Record "Item Budget Name";
        begin
            Description := Text005 + Format(WorkDate());
            if not ItemBudgetName.Get(AnalysisArea, ToItemBudgetName) then
                ToItemBudgetName := '';

            ValueType := ValueTypeHidden;
            SalesValueTypeVisible := AnalysisArea = AnalysisArea::Sales;
            PurchValueTypeVisible := AnalysisArea = AnalysisArea::Purchase;
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        var
            FileMgt: Codeunit "File Management";
        begin
            if CloseAction = ACTION::OK then begin
                if ServerFileName = '' then
                    ServerFileName := FileMgt.UploadFile(Text006, ExcelExtensionTok);
                if ServerFileName = '' then
                    exit(false);

                SheetName := ExcelBuf.SelectSheetsName(ServerFileName);
                if SheetName = '' then
                    exit(false);
            end;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        ExcelBuf.DeleteAll();
        ItemBudgetBuf.DeleteAll();
    end;

    trigger OnPreReport()
    begin
        if ToItemBudgetName = '' then
            Error(Text000);

        if not ItemBudgetName.Get(AnalysisArea, ToItemBudgetName) then begin
            if not Confirm(Text001, false, ToItemBudgetName) then
                CurrReport.Break();
            ItemBudgetName."Analysis Area" := AnalysisArea;
            ItemBudgetName.Name := ToItemBudgetName;
            ItemBudgetName.Insert();
        end else begin
            if ItemBudgetName.Blocked then
                Error(Text002, ItemBudgetEntry.FieldCaption("Budget Name"), ToItemBudgetName);
            if not Confirm(
                 Text003, false,
                 LowerCase(Format(SelectStr(ImportOption + 1, Text010))),
                 ToItemBudgetName)
            then
                CurrReport.Break();
        end;

        ExcelBuf.LockTable();
        ItemBudgetBuf.LockTable();

        ExcelBuf.OpenBook(ServerFileName, SheetName);
        ExcelBuf.ReadSheet();

        AnalyseData();
    end;

    var
        ExcelBuf: Record "Excel Buffer";
        GLSetup: Record "General Ledger Setup";
        ItemBudgetName: Record "Item Budget Name";
        ItemBudgetEntry: Record "Item Budget Entry";
        ItemBudgetManagement: Codeunit "Item Budget Management";
        Window: Dialog;
        ServerFileName: Text;
        SheetName: Text[250];
        Description: Text[50];
        ToItemBudgetName: Code[10];
        RecNo: Integer;
        EntryNo: Integer;
        ImportOption: Option "Replace entries","Add entries";
        AnalysisArea: Enum "Analysis Area Type";
        ValueType: Option "Sales Amount","COGS / Cost Amount",Quantity;
        ValueTypeHidden: Option "Sales Amount","COGS / Cost Amount",Quantity;
        GlSetupRead: Boolean;
        SalesValueTypeVisible: Boolean;
        PurchValueTypeVisible: Boolean;

#pragma warning disable AA0074
        Text000: Label 'You must specify a budget name to import to.';
#pragma warning disable AA0470
        Text001: Label 'Do you want to create Item Budget Name %1?';
        Text002: Label '%1 %2 is blocked. You cannot import entries.';
        Text003: Label 'Are you sure you want to %1 for Budget Name %2?';
        Text004: Label '%1 table has been successfully updated with %2 entries.';
#pragma warning restore AA0470
        Text005: Label 'Imported from Excel ';
        Text006: Label 'Import Excel File';
        Text007: Label 'Table Data';
        Text008: Label 'Show as Lines';
        Text009: Label 'Show as Columns';
        Text010: Label 'Replace Entries,Add Entries';
#pragma warning disable AA0470
        Text011: Label 'The text %1 can only be specified once in the Excel worksheet.';
#pragma warning restore AA0470
        Text012: Label 'The filters specified by worksheet must be placed in the lines before the table.';
        Text013: Label 'Date Filter';
        Text014: Label 'Customer Filter';
        Text015: Label 'Vendor Filter';
        Text016: Label 'Analyzing Data...\\';
        Text017: Label 'Item Filter';
#pragma warning disable AA0470
        Text018: Label '%1 is not a valid dimension value.';
        Text019: Label '%1 is not a valid line definition.';
        Text020: Label '%1 is not a valid column definition.';
        Text021: Label 'You must specify a dimension value in row %1, column %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ExcelExtensionTok: Label '.xlsx', Locked = true;

    local procedure AnalyseData()
    var
        DateFilter: Text[30];
        LineDimCode: Text[30];
        ColumnDimCode: Text[30];
        ItemFilter: Code[20];
        LocationFilter: Code[10];
        GlobalDim1Filter: Code[20];
        GlobalDim2Filter: Code[20];
        BudgetDim1Filter: Code[20];
        BudgetDim2Filter: Code[20];
        BudgetDim3Filter: Code[20];
        SourceNoFilter: Code[20];
        CurrLineDimValue: Code[20];
        CurrColumnDimValue: Code[20];
        TotalRecNo: Integer;
        HeaderRowNo: Integer;
        SourceTypeFilter: Enum "Analysis Source Type";
        LineDimOption: Enum "Item Budget Dimension Type";
        ColumnDimOption: Enum "Item Budget Dimension Type";
    begin
        Window.Open(Text016 + '@1@@@@@@@@@@@@@@@@@@@@@@@@@\');
        TotalRecNo := ExcelBuf.Count();

        ItemBudgetBuf.DeleteAll();

        if ExcelBuf.Find('-') then
            repeat
                RecNo := RecNo + 1;
                Window.Update(1, Round(RecNo / TotalRecNo * 10000, 1));
                case true of
                    StrPos(ExcelBuf."Cell Value as Text", Text007) <> 0:
                        begin
                            if HeaderRowNo = 0 then
                                HeaderRowNo := ExcelBuf."Row No."
                            else
                                Error(Text011, Text007);

                            ConvertFiltersToValue(
                              DateFilter,
                              ItemFilter,
                              GlobalDim1Filter,
                              GlobalDim2Filter,
                              BudgetDim1Filter,
                              BudgetDim2Filter,
                              BudgetDim3Filter,
                              SourceNoFilter,
                              SourceTypeFilter);

                            if ItemBudgetManagement.DimCodeNotAllowed(LineDimCode, ItemBudgetName) then
                                Error(Text019, LineDimCode);

                            if ItemBudgetManagement.DimCodeNotAllowed(ColumnDimCode, ItemBudgetName) then
                                Error(Text020, ColumnDimCode);

                            ItemBudgetManagement.SetLineAndColumnDim(
                              ItemBudgetName,
                              LineDimCode,
                              LineDimOption,
                              ColumnDimCode,
                              ColumnDimOption);
                        end;
                    StrPos(ExcelBuf."Cell Value as Text", IsGlobalDimFilter(1)) <> 0:
                        begin
                            CheckFilterRowNo(HeaderRowNo);
                            ExcelBuf.SetRange("Row No.", ExcelBuf."Row No.");
                            if ExcelBuf.Next() <> 0 then
                                GlobalDim1Filter := CopyStr(ExcelBuf."Cell Value as Text", 1, MaxStrLen(GlobalDim1Filter));
                            ExcelBuf.SetRange("Row No.");
                        end;
                    StrPos(ExcelBuf."Cell Value as Text", IsGlobalDimFilter(2)) <> 0:
                        begin
                            CheckFilterRowNo(HeaderRowNo);
                            ExcelBuf.SetRange("Row No.", ExcelBuf."Row No.");
                            if ExcelBuf.Next() <> 0 then
                                GlobalDim2Filter := CopyStr(ExcelBuf."Cell Value as Text", 1, MaxStrLen(GlobalDim2Filter));
                            ExcelBuf.SetRange("Row No.");
                        end;
                    StrPos(ExcelBuf."Cell Value as Text", IsBudgetDimFilter(1)) <> 0:
                        begin
                            CheckFilterRowNo(HeaderRowNo);
                            ExcelBuf.SetRange("Row No.", ExcelBuf."Row No.");
                            if ExcelBuf.Next() <> 0 then
                                BudgetDim1Filter := CopyStr(ExcelBuf."Cell Value as Text", 1, MaxStrLen(BudgetDim1Filter));
                            ExcelBuf.SetRange("Row No.");
                        end;
                    StrPos(ExcelBuf."Cell Value as Text", IsBudgetDimFilter(2)) <> 0:
                        begin
                            CheckFilterRowNo(HeaderRowNo);
                            ExcelBuf.SetRange("Row No.", ExcelBuf."Row No.");
                            if ExcelBuf.Next() <> 0 then
                                BudgetDim2Filter := CopyStr(ExcelBuf."Cell Value as Text", 1, MaxStrLen(BudgetDim2Filter));
                            ExcelBuf.SetRange("Row No.");
                        end;
                    StrPos(ExcelBuf."Cell Value as Text", IsBudgetDimFilter(3)) <> 0:
                        begin
                            CheckFilterRowNo(HeaderRowNo);
                            ExcelBuf.SetRange("Row No.", ExcelBuf."Row No.");
                            if ExcelBuf.Next() <> 0 then
                                BudgetDim3Filter := CopyStr(ExcelBuf."Cell Value as Text", 1, MaxStrLen(BudgetDim3Filter));
                            ExcelBuf.SetRange("Row No.");
                        end;
                    StrPos(ExcelBuf."Cell Value as Text", Text017) <> 0:
                        begin
                            CheckFilterRowNo(HeaderRowNo);
                            ExcelBuf.SetRange("Row No.", ExcelBuf."Row No.");
                            if ExcelBuf.Next() <> 0 then
                                ItemFilter := CopyStr(ExcelBuf."Cell Value as Text", 1, MaxStrLen(ItemFilter));
                            ExcelBuf.SetRange("Row No.");
                        end;
                    StrPos(ExcelBuf."Cell Value as Text", Text013) <> 0:
                        begin
                            CheckFilterRowNo(HeaderRowNo);
                            ExcelBuf.SetRange("Row No.", ExcelBuf."Row No.");
                            if ExcelBuf.Next() <> 0 then
                                DateFilter := CopyStr(ExcelBuf."Cell Value as Text", 1, MaxStrLen(DateFilter));
                            ExcelBuf.SetRange("Row No.");
                        end;
                    StrPos(ExcelBuf."Cell Value as Text", Text014) <> 0:
                        begin
                            CheckFilterRowNo(HeaderRowNo);
                            ExcelBuf.SetRange("Row No.", ExcelBuf."Row No.");
                            if ExcelBuf.Next() <> 0 then begin
                                SourceTypeFilter := SourceTypeFilter::Customer;
                                SourceNoFilter := CopyStr(ExcelBuf."Cell Value as Text", 1, MaxStrLen(SourceNoFilter));
                            end;
                            ExcelBuf.SetRange("Row No.");
                        end;
                    StrPos(ExcelBuf."Cell Value as Text", Text015) <> 0:
                        begin
                            CheckFilterRowNo(HeaderRowNo);
                            ExcelBuf.SetRange("Row No.", ExcelBuf."Row No.");
                            if ExcelBuf.Next() <> 0 then begin
                                SourceTypeFilter := SourceTypeFilter::Vendor;
                                SourceNoFilter := CopyStr(ExcelBuf."Cell Value as Text", 1, MaxStrLen(SourceNoFilter));
                            end;
                            ExcelBuf.SetRange("Row No.");
                        end;
                    StrPos(ExcelBuf."Cell Value as Text", Text008) <> 0:
                        begin
                            CheckFilterRowNo(HeaderRowNo);
                            ExcelBuf.SetRange("Row No.", ExcelBuf."Row No.");
                            if ExcelBuf.Next() <> 0 then
                                LineDimCode := CopyStr(ExcelBuf."Cell Value as Text", 1, MaxStrLen(LineDimCode));
                            ExcelBuf.SetRange("Row No.");
                        end;
                    StrPos(ExcelBuf."Cell Value as Text", Text009) <> 0:
                        begin
                            CheckFilterRowNo(HeaderRowNo);
                            ExcelBuf.SetRange("Row No.", ExcelBuf."Row No.");
                            if ExcelBuf.Next() <> 0 then
                                ColumnDimCode := CopyStr(ExcelBuf."Cell Value as Text", 1, MaxStrLen(ColumnDimCode));
                            ExcelBuf.SetRange("Row No.");
                        end;
                    (ExcelBuf."Row No." > HeaderRowNo) and (HeaderRowNo <> 0):
                        begin
                            CurrLineDimValue := CopyStr(ExcelBuf."Cell Value as Text", 1, MaxStrLen(CurrLineDimValue));
                            ExcelBuf.SetRange("Row No.", ExcelBuf."Row No.");
                            while ExcelBuf.Next() <> 0 do begin
                                CurrColumnDimValue := GetCurrColumnDimValue(ExcelBuf."Column No.", HeaderRowNo);
                                ExchangeFiltersWithDimValue(
                                  CurrLineDimValue,
                                  CurrColumnDimValue,
                                  LineDimOption,
                                  ColumnDimOption,
                                  DateFilter,
                                  ItemFilter,
                                  LocationFilter,
                                  GlobalDim1Filter,
                                  GlobalDim2Filter,
                                  BudgetDim1Filter,
                                  BudgetDim2Filter,
                                  BudgetDim3Filter,
                                  SourceNoFilter,
                                  SourceTypeFilter);

                                ItemBudgetBuf.Init();
                                ItemBudgetBuf."Item No." := ItemFilter;
                                if SourceTypeFilter <> SourceTypeFilter::" " then
                                    ItemBudgetBuf."Source Type" := SourceTypeFilter
                                else
                                    ItemBudgetBuf."Source Type" := Enum::"Analysis Source Type".FromInteger(LineDimOption.AsInteger());
                                ItemBudgetBuf."Source No." := SourceNoFilter;
                                ItemBudgetBuf."Location Code" := LocationFilter;
                                ItemBudgetBuf."Global Dimension 1 Code" := GlobalDim1Filter;
                                ItemBudgetBuf."Global Dimension 2 Code" := GlobalDim2Filter;
                                ItemBudgetBuf."Budget Dimension 1 Code" := BudgetDim1Filter;
                                ItemBudgetBuf."Budget Dimension 2 Code" := BudgetDim2Filter;
                                ItemBudgetBuf."Budget Dimension 3 Code" := BudgetDim3Filter;
                                Evaluate(ItemBudgetBuf.Date, DateFilter);
                                case ValueType of
                                    ValueType::"Sales Amount":
                                        Evaluate(ItemBudgetBuf."Sales Amount", ExcelBuf."Cell Value as Text");
                                    ValueType::"COGS / Cost Amount":
                                        Evaluate(ItemBudgetBuf."Cost Amount", ExcelBuf."Cell Value as Text");
                                    ValueType::Quantity:
                                        Evaluate(ItemBudgetBuf.Quantity, ExcelBuf."Cell Value as Text");
                                end;
                                ItemBudgetBuf.Insert();
                            end;
                            ExcelBuf.SetRange("Row No.");
                        end;
                end;
            until ExcelBuf.Next() = 0;

        Window.Close();
    end;

    local procedure ExchangeFiltersWithDimValue(CurrLineDimValue: Code[20]; CurrColumnDimValue: Code[20]; LineDimOption: Enum "Item Budget Dimension Type"; ColumnDimOption: Enum "Item Budget Dimension Type"; var DateFilter: Text[30]; var ItemFilter: Code[20]; var LocationFilter: Code[10]; var GlobalDim1Filter: Code[20]; var GlobalDim2Filter: Code[20]; var BudgetDim1Filter: Code[20]; var BudgetDim2Filter: Code[20]; var BudgetDim3Filter: Code[20]; var SourceNoFilter: Code[20]; var SourceTypeFilter: Enum "Analysis Source Type")
    begin
        case LineDimOption of
            LineDimOption::Item:
                ItemFilter := CurrLineDimValue;
            LineDimOption::Customer:
                begin
                    SourceNoFilter := CurrLineDimValue;
                    if SourceTypeFilter = SourceTypeFilter::" " then
                        SourceTypeFilter := SourceTypeFilter::Customer;
                end;
            LineDimOption::Vendor:
                begin
                    SourceNoFilter := CurrLineDimValue;
                    if SourceTypeFilter = SourceTypeFilter::" " then
                        SourceTypeFilter := SourceTypeFilter::Vendor;
                end;
            LineDimOption::Period:
                DateFilter := CurrLineDimValue;
            LineDimOption::Location:
                LocationFilter := CopyStr(CurrLineDimValue, 1, MaxStrLen(LocationFilter));
            LineDimOption::"Global Dimension 1":
                GlobalDim1Filter := CurrLineDimValue;
            LineDimOption::"Global Dimension 2":
                GlobalDim2Filter := CurrLineDimValue;
            LineDimOption::"Budget Dimension 1":
                BudgetDim1Filter := CurrLineDimValue;
            LineDimOption::"Budget Dimension 2":
                BudgetDim2Filter := CurrLineDimValue;
            LineDimOption::"Budget Dimension 3":
                BudgetDim3Filter := CurrLineDimValue;
            else
                Error(Text018, CurrLineDimValue);
        end;

        case ColumnDimOption of
            ColumnDimOption::Item:
                ItemFilter := CurrColumnDimValue;
            ColumnDimOption::Customer:
                begin
                    SourceNoFilter := CurrColumnDimValue;
                    if SourceTypeFilter = SourceTypeFilter::" " then
                        SourceTypeFilter := SourceTypeFilter::Customer;
                end;
            ColumnDimOption::Vendor:
                begin
                    SourceNoFilter := CurrColumnDimValue;
                    if SourceTypeFilter = SourceTypeFilter::" " then
                        SourceTypeFilter := SourceTypeFilter::Vendor;
                end;
            ColumnDimOption::Period:
                DateFilter := CurrColumnDimValue;
            ColumnDimOption::Location:
                LocationFilter := CopyStr(CurrColumnDimValue, 1, MaxStrLen(LocationFilter));
            ColumnDimOption::"Global Dimension 1":
                GlobalDim1Filter := CurrColumnDimValue;
            ColumnDimOption::"Global Dimension 2":
                GlobalDim2Filter := CurrColumnDimValue;
            ColumnDimOption::"Budget Dimension 1":
                BudgetDim1Filter := CurrColumnDimValue;
            ColumnDimOption::"Budget Dimension 2":
                BudgetDim2Filter := CurrColumnDimValue;
            ColumnDimOption::"Budget Dimension 3":
                BudgetDim3Filter := CurrColumnDimValue;
            else
                Error(Text018, CurrColumnDimValue);
        end;
    end;

    local procedure GetCurrColumnDimValue(ColNo: Integer; HeaderRowNo: Integer): Code[20]
    var
        ExcelBuf2: Record "Excel Buffer";
    begin
        if not ExcelBuf2.Get(HeaderRowNo, ColNo) then
            Error(Text021, HeaderRowNo, ColNo);
        exit(ExcelBuf2."Cell Value as Text");
    end;

    local procedure ConvertFiltersToValue(var DateFilter: Text[30]; var ItemFilter: Code[20]; var GlobalDim1Filter: Code[20]; var GlobalDim2Filter: Code[20]; var BudgetDim1Filter: Code[20]; var BudgetDim2Filter: Code[20]; var BudgetDim3Filter: Code[20]; var SourceNoFilter: Code[20]; SourceTypeFilter: Enum "Analysis Source Type")
    var
        Item: Record Item;
        Calendar: Record Date;
        Cust: Record Customer;
        Vend: Record Vendor;
        DimValue: Record "Dimension Value";
        CurrDate: Date;
    begin
        if ItemFilter <> '' then begin
            Item.SetFilter("No.", ItemFilter);
            Item.FindFirst();
            ItemFilter := Item."No.";
        end;

        if DateFilter <> '' then begin
            Calendar.SetFilter("Period Start", DateFilter);
            DateFilter := Format(Calendar.GetRangeMin("Period Start"));
            Evaluate(CurrDate, DateFilter);
            Calendar.Get(Calendar."Period Type"::Date, CurrDate);
        end;

        if SourceNoFilter <> '' then
            case SourceTypeFilter of
                SourceTypeFilter::Customer:
                    begin
                        Cust.SetFilter("No.", SourceNoFilter);
                        SourceNoFilter := Cust.GetRangeMin("No.");
                        Cust.Get(SourceNoFilter);
                    end;
                SourceTypeFilter::Vendor:
                    begin
                        Vend.SetFilter("No.", SourceNoFilter);
                        SourceNoFilter := Vend.GetRangeMin("No.");
                        Vend.Get(SourceNoFilter);
                    end;
            end;

        GetGLSetup();
        if GlobalDim1Filter <> '' then begin
            DimValue.SetFilter(Code, GlobalDim1Filter);
            GlobalDim1Filter := DimValue.GetRangeMin(Code);
            DimValue.Get(GLSetup."Global Dimension 1 Code", GlobalDim1Filter);
        end;

        if GlobalDim2Filter <> '' then begin
            DimValue.SetFilter(Code, GlobalDim2Filter);
            GlobalDim2Filter := DimValue.GetRangeMin(Code);
            DimValue.Get(GLSetup."Global Dimension 2 Code", GlobalDim2Filter);
        end;

        if BudgetDim1Filter <> '' then begin
            DimValue.SetFilter(Code, BudgetDim1Filter);
            BudgetDim1Filter := DimValue.GetRangeMin(Code);
            DimValue.Get(ItemBudgetName."Budget Dimension 1 Code", BudgetDim1Filter);
        end;

        if BudgetDim2Filter <> '' then begin
            DimValue.SetFilter(Code, BudgetDim2Filter);
            BudgetDim2Filter := DimValue.GetRangeMin(Code);
            DimValue.Get(ItemBudgetName."Budget Dimension 2 Code", BudgetDim2Filter);
        end;

        if BudgetDim3Filter <> '' then begin
            DimValue.SetFilter(Code, BudgetDim3Filter);
            BudgetDim3Filter := DimValue.GetRangeMin(Code);
            DimValue.Get(ItemBudgetName."Budget Dimension 3 Code", BudgetDim3Filter);
        end;
    end;

    local procedure CheckFilterRowNo(HeaderRowNo: Integer)
    begin
        if (HeaderRowNo <> 0) and (ExcelBuf."Row No." > HeaderRowNo) then
            Error(Text012);
    end;

    local procedure IsGlobalDimFilter(DimNo: Integer): Text[30]
    var
        Dim: Record Dimension;
    begin
        GetGLSetup();
        case DimNo of
            1:
                if Dim.Get(GLSetup."Global Dimension 1 Code") then
                    ;
            2:
                if Dim.Get(GLSetup."Global Dimension 2 Code") then
                    ;
        end;
        exit(Dim."Filter Caption");
    end;

    local procedure IsBudgetDimFilter(DimNo: Integer): Text[30]
    var
        Dim: Record Dimension;
    begin
        case DimNo of
            1:
                if Dim.Get(ItemBudgetName."Budget Dimension 1 Code") then
                    ;
            2:
                if Dim.Get(ItemBudgetName."Budget Dimension 2 Code") then
                    ;
            3:
                if Dim.Get(ItemBudgetName."Budget Dimension 3 Code") then
                    ;
        end;
        exit(Dim."Filter Caption");
    end;

    local procedure GetGLSetup()
    begin
        if not GlSetupRead then
            GLSetup.Get();
        GlSetupRead := true;
    end;

    procedure SetParameters(NewToItemBudgetName: Code[10]; NewAnalysisArea: Integer; NewValueType: Integer)
    begin
        ToItemBudgetName := NewToItemBudgetName;
        AnalysisArea := "Analysis Area Type".FromInteger(NewAnalysisArea);
        ValueTypeHidden := NewValueType;
    end;

    procedure SetFileNameSilent(NewFileName: Text)
    begin
        ServerFileName := NewFileName;
    end;
}

