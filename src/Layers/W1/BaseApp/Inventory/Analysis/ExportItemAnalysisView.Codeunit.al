// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Item;
using Microsoft.Utilities;
using System.IO;

codeunit 7152 "Export Item Analysis View"
{

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        TempDimValue2: Record "Dimension Value" temporary;
        TempDimValue3: Record "Dimension Value" temporary;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        FileMgt: Codeunit "File Management";
        NoOfColumns: Integer;
        MaxLevelDim: array[3] of Integer;
#pragma warning disable AA0074
        Text000: Label 'You can only export Actual amounts and Budgeted amounts.\Please change the option in the Show field.';
        Text002: Label 'General Info._';
        Text003: Label 'None';
        Text004: Label 'Day';
        Text005: Label 'Week';
        Text006: Label 'Month';
        Text007: Label 'Quarter';
        Text008: Label 'Year';
        Text009: Label 'Accounting Period';
        Text011: Label 'Analysis by Dimension ';
        Text012: Label 'Amount Type';
        Text015: Label 'Date Filter';
        Text016: Label 'Budget Filter';
        Text018: Label 'Item';
        Text020: Label 'Budg. Sales Amount';
        Text022: Label 'Level';
        Text023: Label 'Analysis View Name';
        Text028: Label 'Show Opposite Sign';
        Text029: Label 'Yes';
        Text030: Label 'No';
        Text031: Label 'Data_';
        Text032: Label 'Sales Amount';
        Text033: Label 'Cost Amount';
        Text035: Label 'Budg. Cost Amount';
        Text036: Label 'Budg. Quantity';
        Text039: Label 'Location';
#pragma warning restore AA0074
        ServerFileName: Text;
        SkipDownload: Boolean;

    [Scope('OnPrem')]
    procedure ExportData(var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; ShowName: Boolean; DateFilter: Text; ItemFilter: Text; BudgetFilter: Text; Dim1Filter: Text; Dim2Filter: Text; Dim3Filter: Text; ShowActualBudg: Option "Actual Amounts","Budgeted Amounts",Variance,"Variance%","Index%"; LocationFilter: Text; Sign: Boolean)
    begin
        if (ShowActualBudg <> 0) and (ShowActualBudg <> 1) then
            Error(Text000);

        ServerFileName := FileMgt.ServerTempFileName('xlsx');
        CreateFillGeneralInfoSheet(
          ItemAnalysisViewEntry, Sign, DateFilter, ItemFilter, BudgetFilter, Dim1Filter, Dim2Filter, Dim3Filter, LocationFilter);

        TempExcelBuffer.CreateBook(ServerFileName, StrSubstNo('%1%2', Text002, ItemAnalysisViewEntry."Analysis View Code"));
        TempExcelBuffer.WriteSheet(StrSubstNo('%1%2', Text002, ItemAnalysisViewEntry."Analysis View Code"), CompanyName, UserId);

        CreateDataSheet(
          ItemAnalysisViewEntry, ShowName, ItemFilter, Dim1Filter, Dim2Filter,
          Dim3Filter, DateFilter, LocationFilter, BudgetFilter, Sign);

        TempExcelBuffer.SelectOrAddSheet(StrSubstNo('%1%2', Text031, ItemAnalysisViewEntry."Analysis View Code"));
        TempExcelBuffer.WriteAllToCurrentSheet(TempExcelBuffer);

        TempExcelBuffer.CloseBook();

        if not SkipDownload then
            TempExcelBuffer.OpenExcel();
    end;

    local procedure CreateDataSheet(var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; ShowName: Boolean; ItemFilter: Text; Dim1Filter: Text; Dim2Filter: Text; Dim3Filter: Text; DateFilter: Text; LocationFilter: Text; BudgetFilter: Text; Sign: Boolean)
    var
        ItemAnalysisViewEntry2: Record "Item Analysis View Entry";
        ItemAnalysisView: Record "Item Analysis View";
        StartDate: Date;
        EndDate: Date;
        WeekNo: Integer;
        Year: Integer;
        SignValue: Integer;
        NoOfLeadingColumns: Integer;
    begin
        TempExcelBuffer.DeleteAll();

        ItemAnalysisViewEntry2.Copy(ItemAnalysisViewEntry);
        ItemAnalysisView.Get(ItemAnalysisViewEntry."Analysis Area", ItemAnalysisViewEntry."Analysis View Code");
        ItemAnalysisViewEntry2.SetRange("Analysis Area", ItemAnalysisView."Analysis Area");
        ItemAnalysisViewEntry2.SetRange("Analysis View Code", ItemAnalysisView.Code);

        FindDimLevel(ItemAnalysisView."Dimension 1 Code", Dim1Filter, 1);
        FindDimLevel(ItemAnalysisView."Dimension 2 Code", Dim2Filter, 2);
        FindDimLevel(ItemAnalysisView."Dimension 3 Code", Dim3Filter, 3);

        SignValue := 1;
        if Sign then
            SignValue := -1;

        CreateRowWithColumnsCaptions(ItemAnalysisViewEntry2, ItemAnalysisView);

        CreateItemAnalysisViewEntryPart(ItemAnalysisViewEntry2, ItemAnalysisView, StartDate, EndDate, ShowName, SignValue);

        CreateItemAnalysisViewBudgetEntryPart(ItemAnalysisView, StartDate, EndDate, DateFilter,
          ItemFilter, LocationFilter, BudgetFilter, Dim1Filter, Dim2Filter, Dim3Filter, ShowName, SignValue);

        if ItemFilter <> '' then
            Item.SetFilter("No.", ItemFilter);
        if Item.Find('-') then
            repeat
                if not Item.Mark() then begin
                    FillOutItem(Item."No.", ShowName);
                    StartNewRow();
                end;
            until Item.Next() = 0;

        NoOfLeadingColumns := 1;
        if ItemAnalysisView."Dimension 1 Code" <> '' then
            WriteDimLine(1, Dim1Filter, ItemAnalysisView."Dimension 1 Code", NoOfLeadingColumns, ShowName);
        NoOfLeadingColumns := NoOfLeadingColumns + MaxLevelDim[1] + 1;

        if ItemAnalysisView."Dimension 2 Code" <> '' then
            WriteDimLine(2, Dim2Filter, ItemAnalysisView."Dimension 2 Code", NoOfLeadingColumns, ShowName);
        NoOfLeadingColumns := NoOfLeadingColumns + MaxLevelDim[2] + 1;

        if ItemAnalysisView."Dimension 3 Code" <> '' then
            WriteDimLine(3, Dim3Filter, ItemAnalysisView."Dimension 3 Code", NoOfLeadingColumns, ShowName);
        NoOfLeadingColumns := NoOfLeadingColumns + MaxLevelDim[3] + 1;

        WeekNo := Date2DWY(StartDate, 2);
        Year := Date2DWY(StartDate, 3);
        StartDate := DWY2Date(1, WeekNo, Year);

        NoOfLeadingColumns += 1;
        while StartDate <= EndDate do begin
            SetStartColumnNo(NoOfLeadingColumns);
            FillNextCellInRow(CalculatePeriodStart(StartDate, 0));
            FillNextCellInRow(CalculatePeriodStart(StartDate, 1));
            FillNextCellInRow(CalculatePeriodStart(StartDate, 2));
            FillNextCellInRow(CalculatePeriodStart(StartDate, 3));
            FillNextCellInRow(CalculatePeriodStart(StartDate, 4));
            StartNewRow();

            StartDate := CalcDate('<1W>', StartDate);
        end;
    end;

    local procedure CreateFillGeneralInfoSheet(var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; Sign: Boolean; DateFilter: Text; ItemFilter: Text; BudgetFilter: Text; Dim1Filter: Text; Dim2Filter: Text; Dim3Filter: Text; LocationFilter: Text)
    var
        ItemAnalysisView: Record "Item Analysis View";
        ItemAnalysisViewFilter: Record "Item Analysis View Filter";
        RowNoCount: Integer;
    begin
        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();

        FillCell(1, 1, ItemAnalysisView.TableCaption());
        FillCell(2, 2, ItemAnalysisViewEntry.FieldCaption(ItemAnalysisViewEntry."Analysis View Code"));
        FillCell(2, 3, ItemAnalysisViewEntry."Analysis View Code");
        FillCell(3, 2, Text023);
        ItemAnalysisView.Get(ItemAnalysisViewEntry."Analysis Area", ItemAnalysisViewEntry."Analysis View Code");
        FillCell(3, 3, ItemAnalysisView.Name);
        RowNoCount := 3;
        if ItemAnalysisView."Item Filter" <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, ItemAnalysisView.FieldCaption("Item Filter"));
            FillCell(RowNoCount, 3, ItemAnalysisView."Item Filter");
        end;
        RowNoCount := RowNoCount + 1;
        FillCell(RowNoCount, 2, ItemAnalysisView.FieldCaption("Date Compression"));
        case ItemAnalysisView."Date Compression" of
            0:
                FillCell(RowNoCount, 3, Text003);
            1:
                FillCell(RowNoCount, 3, Text004);
            2:
                FillCell(RowNoCount, 3, Text005);
            3:
                FillCell(RowNoCount, 3, Text006);
            4:
                FillCell(RowNoCount, 3, Text007);
            5:
                FillCell(RowNoCount, 3, Text008);
            6:
                FillCell(RowNoCount, 3, Text009);
        end;
        if ItemAnalysisView."Starting Date" <> 0D then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, ItemAnalysisView.FieldCaption("Starting Date"));
            FillCell(RowNoCount, 3, ItemAnalysisView."Starting Date");
        end;
        RowNoCount := RowNoCount + 1;
        FillCell(RowNoCount, 2, ItemAnalysisView.FieldCaption("Last Date Updated"));
        FillCell(RowNoCount, 3, ItemAnalysisView."Last Date Updated");
        ItemAnalysisViewFilter.SetRange("Analysis View Code", ItemAnalysisViewEntry."Analysis View Code");
        if ItemAnalysisViewFilter.FindSet() then
            repeat
                RowNoCount := RowNoCount + 1;
                FillCell(RowNoCount, 2, ItemAnalysisViewFilter."Dimension Code");
                FillCell(RowNoCount, 3, ItemAnalysisViewFilter."Dimension Value Filter");
            until ItemAnalysisViewFilter.Next() = 0;
        RowNoCount := RowNoCount + 1;
        FillCell(RowNoCount, 1, Text011);
        RowNoCount := RowNoCount + 1;
        FillCell(RowNoCount, 2, Text012);

        if DateFilter <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, Text015);
            FillCell(RowNoCount, 3, DateFilter);
        end;
        if ItemFilter <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, ItemAnalysisView.FieldCaption("Item Filter"));
            FillCell(RowNoCount, 3, ItemFilter);
        end;
        if LocationFilter <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, Text039);
            FillCell(RowNoCount, 3, LocationFilter);
        end;
        if BudgetFilter <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, Text016);
            FillCell(RowNoCount, 3, BudgetFilter);
        end;

        if Dim1Filter <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, ItemAnalysisView."Dimension 1 Code");
            FillCell(RowNoCount, 3, Dim1Filter);
        end;
        if Dim2Filter <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, ItemAnalysisView."Dimension 2 Code");
            FillCell(RowNoCount, 3, Dim2Filter);
        end;
        if Dim3Filter <> '' then begin
            RowNoCount := RowNoCount + 1;
            FillCell(RowNoCount, 2, ItemAnalysisView."Dimension 3 Code");
            FillCell(RowNoCount, 3, Dim3Filter);
        end;

        RowNoCount := RowNoCount + 1;
        FillCell(RowNoCount, 2, Text028);
        if Sign then
            FillCell(RowNoCount, 3, Text029)
        else
            FillCell(RowNoCount, 3, Text030);
    end;

    local procedure CreateRowWithColumnsCaptions(ItemAnalysisViewEntry: Record "Item Analysis View Entry"; ItemAnalysisView: Record "Item Analysis View")
    var
        i: Integer;
    begin
        NoOfColumns := NoOfColumns + 1;
        FillCell(1, NoOfColumns, Format(Text018) + ' ' + Format(Text022) + ' ' + Format(0));
        if ItemAnalysisView."Dimension 1 Code" <> '' then
            for i := 0 to MaxLevelDim[1] do begin
                NoOfColumns := NoOfColumns + 1;
                FillCell(1, NoOfColumns, ItemAnalysisView."Dimension 1 Code" + ' ' + Format(Text022) + ' ' + Format(i));
            end;
        if ItemAnalysisView."Dimension 2 Code" <> '' then
            for i := 0 to MaxLevelDim[2] do begin
                NoOfColumns := NoOfColumns + 1;
                FillCell(1, NoOfColumns, ItemAnalysisView."Dimension 2 Code" + ' ' + Format(Text022) + ' ' + Format(i));
            end;
        if ItemAnalysisView."Dimension 3 Code" <> '' then
            for i := 0 to MaxLevelDim[3] do begin
                NoOfColumns := NoOfColumns + 1;
                FillCell(1, NoOfColumns, ItemAnalysisView."Dimension 3 Code" + ' ' + Format(Text022) + ' ' + Format(i));
            end;

        FillNextCellInRow(Text004);
        FillNextCellInRow(Text005);
        FillNextCellInRow(Text006);
        FillNextCellInRow(Text007);
        FillNextCellInRow(Text008);
        FillNextCellInRow(Text009);
        FillNextCellInRow(Text032);
        FillNextCellInRow(Text033);
        FillNextCellInRow(ItemAnalysisViewEntry.FieldCaption(Quantity));
        FillNextCellInRow(Text039);
        FillNextCellInRow(Text020);
        FillNextCellInRow(Text035);
        FillNextCellInRow(Text036);

        StartNewRow();
    end;

    local procedure CreateItemAnalysisViewEntryPart(var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; ItemAnalysisView: Record "Item Analysis View"; var StartDate: Date; var EndDate: Date; ShowName: Boolean; SignValue: Integer)
    begin
        StartDate := ItemAnalysisViewEntry."Posting Date";

        if ItemAnalysisViewEntry.Find('-') then
            repeat
                if ItemAnalysisViewEntry."Item No." <> Item."No." then
                    if Item.Get(ItemAnalysisViewEntry."Item No.") then
                        Item.Mark(true);
                if ItemAnalysisViewEntry."Posting Date" = NormalDate(ItemAnalysisViewEntry."Posting Date") then begin
                    if ItemAnalysisViewEntry."Posting Date" >= EndDate then
                        EndDate := ItemAnalysisViewEntry."Posting Date"
                    else
                        if ItemAnalysisViewEntry."Posting Date" <= StartDate then
                            StartDate := ItemAnalysisViewEntry."Posting Date";
                    FillOutItem(ItemAnalysisViewEntry."Item No.", ShowName);
                    if ItemAnalysisView."Dimension 1 Code" <> '' then
                        FillOutDim(ItemAnalysisViewEntry."Dimension 1 Value Code", ItemAnalysisView."Dimension 1 Code", 1, ShowName);
                    if ItemAnalysisView."Dimension 2 Code" <> '' then
                        FillOutDim(ItemAnalysisViewEntry."Dimension 2 Value Code", ItemAnalysisView."Dimension 2 Code", 2, ShowName);
                    if ItemAnalysisView."Dimension 3 Code" <> '' then
                        FillOutDim(ItemAnalysisViewEntry."Dimension 3 Value Code", ItemAnalysisView."Dimension 3 Code", 3, ShowName);

                    FillNextCellInRow(CalculatePeriodStart(NormalDate(ItemAnalysisViewEntry."Posting Date"), -1));
                    FillNextCellInRow(CalculatePeriodStart(NormalDate(ItemAnalysisViewEntry."Posting Date"), 0));
                    FillNextCellInRow(CalculatePeriodStart(NormalDate(ItemAnalysisViewEntry."Posting Date"), 1));
                    FillNextCellInRow(CalculatePeriodStart(NormalDate(ItemAnalysisViewEntry."Posting Date"), 2));
                    FillNextCellInRow(CalculatePeriodStart(NormalDate(ItemAnalysisViewEntry."Posting Date"), 3));
                    FillNextCellInRow(CalculatePeriodStart(NormalDate(ItemAnalysisViewEntry."Posting Date"), 4));
                    FillNextCellInRow((ItemAnalysisViewEntry."Sales Amount (Actual)" + ItemAnalysisViewEntry."Sales Amount (Expected)") * SignValue);
                    FillNextCellInRow((ItemAnalysisViewEntry."Cost Amount (Actual)" + ItemAnalysisViewEntry."Cost Amount (Expected)" + ItemAnalysisViewEntry."Cost Amount (Non-Invtbl.)") * SignValue);
                    FillNextCellInRow(ItemAnalysisViewEntry.Quantity * SignValue);
                    FillNextCellInRow(Format(ItemAnalysisViewEntry."Location Code"));

                    StartNewRow();
                end;
            until ItemAnalysisViewEntry.Next() = 0;
    end;

    local procedure CreateItemAnalysisViewBudgetEntryPart(ItemAnalysisView: Record "Item Analysis View"; var StartDate: Date; var EndDate: Date; DateFilter: Text; ItemFilter: Text; LocationFilter: Text; BudgetFilter: Text; Dim1Filter: Text; Dim2Filter: Text; Dim3Filter: Text; ShowName: Boolean; SignValue: Integer)
    var
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
    begin
        ItemAnalysisViewBudgEntry.SetRange("Analysis Area", ItemAnalysisView."Analysis Area");
        ItemAnalysisViewBudgEntry.SetRange("Analysis View Code", ItemAnalysisView.Code);
        ItemAnalysisViewBudgEntry.SetFilter("Posting Date", DateFilter);
        ItemAnalysisViewBudgEntry.SetFilter("Item No.", ItemFilter);
        ItemAnalysisViewBudgEntry.SetFilter("Location Code", LocationFilter);
        ItemAnalysisViewBudgEntry.SetFilter("Budget Name", BudgetFilter);
        ItemAnalysisViewBudgEntry.SetFilter("Dimension 1 Value Code", Dim1Filter);
        ItemAnalysisViewBudgEntry.SetFilter("Dimension 2 Value Code", Dim2Filter);
        ItemAnalysisViewBudgEntry.SetFilter("Dimension 3 Value Code", Dim3Filter);
        if ItemAnalysisViewBudgEntry.Find('-') then
            repeat
                if ItemAnalysisViewBudgEntry."Item No." <> Item."No." then
                    if Item.Get(ItemAnalysisViewBudgEntry."Item No.") then
                        Item.Mark(true);
                if ItemAnalysisViewBudgEntry."Posting Date" = NormalDate(ItemAnalysisViewBudgEntry."Posting Date") then begin
                    if ItemAnalysisViewBudgEntry."Posting Date" >= EndDate then
                        EndDate := ItemAnalysisViewBudgEntry."Posting Date"
                    else
                        if ItemAnalysisViewBudgEntry."Posting Date" <= StartDate then
                            StartDate := ItemAnalysisViewBudgEntry."Posting Date";
                    FillOutItem(ItemAnalysisViewBudgEntry."Item No.", ShowName);

                    if ItemAnalysisView."Dimension 1 Code" <> '' then
                        FillOutDim(ItemAnalysisViewBudgEntry."Dimension 1 Value Code", ItemAnalysisView."Dimension 1 Code", 1, ShowName);
                    if ItemAnalysisView."Dimension 2 Code" <> '' then
                        FillOutDim(ItemAnalysisViewBudgEntry."Dimension 2 Value Code", ItemAnalysisView."Dimension 2 Code", 2, ShowName);
                    if ItemAnalysisView."Dimension 3 Code" <> '' then
                        FillOutDim(ItemAnalysisViewBudgEntry."Dimension 3 Value Code", ItemAnalysisView."Dimension 3 Code", 3, ShowName);

                    FillNextCellInRow(CalculatePeriodStart(NormalDate(ItemAnalysisViewBudgEntry."Posting Date"), -1));
                    FillNextCellInRow(CalculatePeriodStart(NormalDate(ItemAnalysisViewBudgEntry."Posting Date"), 0));
                    FillNextCellInRow(CalculatePeriodStart(NormalDate(ItemAnalysisViewBudgEntry."Posting Date"), 1));
                    FillNextCellInRow(CalculatePeriodStart(NormalDate(ItemAnalysisViewBudgEntry."Posting Date"), 2));
                    FillNextCellInRow(CalculatePeriodStart(NormalDate(ItemAnalysisViewBudgEntry."Posting Date"), 3));
                    FillNextCellInRow(CalculatePeriodStart(NormalDate(ItemAnalysisViewBudgEntry."Posting Date"), 4));
                    FillNextCellInRow('');
                    FillNextCellInRow('');
                    FillNextCellInRow('');
                    FillNextCellInRow(ItemAnalysisViewBudgEntry."Location Code");
                    FillNextCellInRow(ItemAnalysisViewBudgEntry."Sales Amount" * SignValue);
                    FillNextCellInRow(ItemAnalysisViewBudgEntry."Cost Amount" * SignValue);
                    FillNextCellInRow(ItemAnalysisViewBudgEntry.Quantity * SignValue);
                    StartNewRow();
                end;
            until ItemAnalysisViewBudgEntry.Next() = 0;
    end;

    local procedure CalculatePeriodStart(PostingDate: Date; DateCompression: Integer): Date
    var
        AccountingPeriod: Record "Accounting Period";
        PrevPostingDate: Date;
        PrevCalculatedPostingDate: Date;
    begin
        PrevPostingDate := 0D;
        case DateCompression of
            0:// Week :
                PostingDate := CalcDate('<CW+1D-1W>', PostingDate);
            1:// Month :
                PostingDate := CalcDate('<CM+1D-1M>', PostingDate);
            2:// Quarter :
                PostingDate := CalcDate('<CQ+1D-1Q>', PostingDate);
            3:// Year :
                PostingDate := CalcDate('<CY+1D-1Y>', PostingDate);
            4:// Period :
                begin
                    if PostingDate <> PrevPostingDate then begin
                        PrevPostingDate := PostingDate;
                        AccountingPeriod.SetRange("Starting Date", 0D, PostingDate);
                        if AccountingPeriod.FindLast() then
                            PrevCalculatedPostingDate := AccountingPeriod."Starting Date"
                        else
                            PrevCalculatedPostingDate := PostingDate;
                    end;
                    PostingDate := PrevCalculatedPostingDate;
                end;
        end;
        exit(PostingDate);
    end;

    local procedure FindDimLevel(DimCode: Code[20]; DimFilter: Text; ArrayNo: Integer)
    var
        DimValue: Record "Dimension Value";
    begin
        if DimCode = '' then
            exit;
        DimValue.SetRange("Dimension Code", DimCode);
        if DimValue.Find('-') then
            repeat
                TempDimValue2.Copy(DimValue);
                TempDimValue2.Insert();
                TempDimValue3.Copy(DimValue);
                TempDimValue3.Insert();
            until DimValue.Next() = 0;
        TempDimValue2.SetFilter(Code, DimFilter);
        if TempDimValue2.Find('-') then
            repeat
                if MaxLevelDim[ArrayNo] < TempDimValue2.Indentation then
                    MaxLevelDim[ArrayNo] := TempDimValue2.Indentation;
            until TempDimValue2.Next() = 0;
    end;

    local procedure FindDimParent(var Account: Code[20]; DimensionCode: Code[20])
    begin
        TempDimValue3.Reset();
        TempDimValue3.SetRange("Dimension Code", DimensionCode);
        TempDimValue3.Get(DimensionCode, Account);
        if TempDimValue3.Indentation <> 0 then begin
            TempDimValue3.SetRange(Indentation, TempDimValue3.Indentation - 1);
            TempDimValue3.Next(-1);
        end;
        Account := TempDimValue3.Code;
    end;

    local procedure FillOutDim(DimValueCode: Code[20]; DimCode: Code[20]; DimNo: Integer; ShowName: Boolean)
    var
        TempParentNameValueBuffer: Record "Name/Value Buffer" temporary;
        DimensionValue: Record "Dimension Value";
        Indent: Integer;
        i: Integer;
        DimValueCode2: Code[20];
    begin
        if DimValueCode <> '' then begin
            if TempDimValue2.Get(DimCode, DimValueCode) then
                TempDimValue2.Mark(true)
            else
                TempDimValue2.Init();
            DimValueCode2 := DimValueCode;
            Indent := TempDimValue2.Indentation;
            if (Indent <> 0) and (DimValueCode2 <> '') then
                for i := Indent downto 1 do begin
                    FindDimParent(DimValueCode2, DimCode);
                    TempDimValue2.Get(DimCode, DimValueCode2);
                    AddParentToBuffer(TempParentNameValueBuffer, i, TempDimValue2.Code, TempDimValue2.Name);
                end;

            if TempParentNameValueBuffer.FindSet() then
                repeat
                    AddAcc(ShowName, TempParentNameValueBuffer.Name, TempParentNameValueBuffer.Value);
                until TempParentNameValueBuffer.Next() = 0;

            if DimensionValue.Get(DimCode, DimValueCode) then;

            if DimensionValue.Indentation <> MaxLevelDim[DimNo] then
                for i := DimensionValue.Indentation + 1 to MaxLevelDim[DimNo] do
                    AddAcc(ShowName, DimensionValue.Code, DimensionValue.Name);

            AddAcc(ShowName, DimensionValue.Code, DimensionValue.Name);
        end else
            for i := 0 to MaxLevelDim[DimNo] do
                AddAcc(false, '', '');
    end;

    local procedure FillOutItem(ItemNo: Code[20]; ShowName: Boolean)
    begin
        AddAcc(ShowName and (ItemNo <> ''), ItemNo, Item.Description);
    end;

    local procedure FillCell(RowNo: Integer; ColumnNo: Integer; Value: Variant)
    begin
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", ColumnNo);
        case true of
            Value.IsDecimal or Value.IsInteger:
                TempExcelBuffer.Validate("Cell Type", TempExcelBuffer."Cell Type"::Number);
            Value.IsDate:
                TempExcelBuffer.Validate("Cell Type", TempExcelBuffer."Cell Type"::Date);
            else
                TempExcelBuffer.Validate("Cell Type", TempExcelBuffer."Cell Type"::Text);
        end;
        TempExcelBuffer."Cell Value as Text" := CopyStr(Format(Value), 1, MaxStrLen(TempExcelBuffer."Cell Value as Text"));
        TempExcelBuffer.Insert();
    end;

    local procedure FillNextCellInRow(Value: Variant)
    var
        RowNo: Integer;
        ColumnNo: Integer;
    begin
        RowNo := TempExcelBuffer."Row No.";
        ColumnNo := TempExcelBuffer."Column No." + 1;
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", ColumnNo);
        case true of
            Value.IsDecimal or Value.IsInteger:
                TempExcelBuffer.Validate("Cell Type", TempExcelBuffer."Cell Type"::Number);
            Value.IsDate:
                TempExcelBuffer.Validate("Cell Type", TempExcelBuffer."Cell Type"::Date);
            else
                TempExcelBuffer.Validate("Cell Type", TempExcelBuffer."Cell Type"::Text);
        end;
        TempExcelBuffer."Cell Value as Text" := CopyStr(Format(Value), 1, MaxStrLen(TempExcelBuffer."Cell Value as Text"));
        TempExcelBuffer.Insert();
    end;

    local procedure StartNewRow()
    var
        RowNo: Integer;
    begin
        RowNo := TempExcelBuffer."Row No." + 1;
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", 0);
    end;

    local procedure SetStartColumnNo(ColumntNo: Integer)
    begin
        TempExcelBuffer."Column No." := ColumntNo;
    end;

    procedure SetCommonFilters(CurrentAnalysisArea: Option; CurrentAnalysisViewCode: Code[10]; var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; DateFilter: Text[30]; ItemFilter: Code[250]; Dim1Filter: Code[250]; Dim2Filter: Code[250]; Dim3Filter: Code[250]; LocationFilter: Code[250])
    begin
        ItemAnalysisViewEntry.SetRange("Analysis Area", CurrentAnalysisArea);
        ItemAnalysisViewEntry.SetRange("Analysis View Code", CurrentAnalysisViewCode);
        if DateFilter <> '' then
            ItemAnalysisViewEntry.SetFilter("Posting Date", DateFilter);
        if ItemFilter <> '' then
            ItemAnalysisViewEntry.SetFilter("Item No.", ItemFilter);
        if Dim1Filter <> '' then
            ItemAnalysisViewEntry.SetFilter("Dimension 1 Value Code", Dim1Filter);
        if Dim2Filter <> '' then
            ItemAnalysisViewEntry.SetFilter("Dimension 2 Value Code", Dim2Filter);
        if Dim3Filter <> '' then
            ItemAnalysisViewEntry.SetFilter("Dimension 3 Value Code", Dim3Filter);
        if LocationFilter <> '' then
            ItemAnalysisViewEntry.SetFilter("Location Code", LocationFilter);

        OnAfterSetCommonFilters(ItemAnalysisViewEntry, CurrentAnalysisArea, CurrentAnalysisViewCode);
    end;

    local procedure AddAcc(ShowName: Boolean; Account: Text; AccName: Text)
    var
        CellValueAsText: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddAcc(ShowName, Account, AccName, IsHandled, Item, TempExcelBuffer);
        if not IsHandled then begin
            if Account = '' then
                CellValueAsText := ''
            else
                if ShowName then
                    CellValueAsText := Account + ' ' + AccName
                else
                    CellValueAsText := Account;

            FillNextCellInRow(CellValueAsText);
        end;

        OnAfterAddAcc(ShowName, Account, AccName, CellValueAsText, Item, TempExcelBuffer);
    end;

    local procedure AddParentToBuffer(var NameValueBuffer: Record "Name/Value Buffer"; id: Integer; AccountNumber: Text[250]; AccountName: Text[250])
    begin
        NameValueBuffer.Init();
        NameValueBuffer.ID := id;
        NameValueBuffer.Name := AccountNumber;
        NameValueBuffer.Value := AccountName;
        NameValueBuffer.Insert();
    end;

    local procedure WriteDimLine(DimNo: Integer; DimFilter: Text; DimCode: Code[20]; NoOfLeadingColumns: Integer; ShowName: Boolean)
    begin
        SetStartColumnNo(NoOfLeadingColumns);
        TempDimValue2.SetFilter(Code, DimFilter);
        TempDimValue2.SetFilter("Dimension Code", DimCode);
        TempDimValue2.SetRange("Dimension Value Type", TempDimValue2."Dimension Value Type"::Standard);
        if TempDimValue2.Find('-') then
            repeat
                if not TempDimValue2.Mark() then begin
                    FillOutDim(TempDimValue2.Code, DimCode, DimNo, ShowName);
                    StartNewRow();
                    SetStartColumnNo(NoOfLeadingColumns);
                end;
            until TempDimValue2.Next() = 0;
    end;

    procedure GetServerFileName(): Text
    begin
        exit(ServerFileName);
    end;

    procedure SetSkipDownload()
    begin
        SkipDownload := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCommonFilters(var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; CurrentAnalysisArea: Option; ItemAnalysisViewCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddAcc(ShowName: Boolean; var Account: Text; var AccName: Text; var IsHandled: Boolean; Item: Record Item; var TempExcelBuffer: Record "Excel Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddAcc(ShowName: Boolean; var Account: Text; var AccName: Text; var CellValueAsText: Text; Item: Record Item; var TempExcelBuffer: Record "Excel Buffer" temporary)
    begin
    end;
}

