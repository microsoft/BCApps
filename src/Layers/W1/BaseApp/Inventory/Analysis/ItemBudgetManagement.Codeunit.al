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
using System.Utilities;

codeunit 7130 "Item Budget Management"
{

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        PrevItemBudgetName: Record "Item Budget Name";
        MatrixMgt: Codeunit "Matrix Management";
        GLSetupRead: Boolean;
        GlobalDimType: Enum "Item Budget Dimension Type";

#pragma warning disable AA0074
        Text001: Label 'DEFAULT';
        Text002: Label 'Default budget';
        Text003: Label 'Period';
#pragma warning disable AA0470
        Text004: Label '%1 is not a valid line definition.';
        Text005: Label '%1 is not a valid column definition.';
#pragma warning restore AA0470
        Text006: Label 'Do you want to delete the budget entries shown?';
        Text007: Label '<Sign><Integer Thousand><Decimals,2>', Locked = true;
#pragma warning restore AA0074

    procedure BudgetNameSelection(CurrentAnalysisArea: Option; var CurrentItemBudgetName: Code[10]; var ItemBudgetName: Record "Item Budget Name"; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var BudgetDim1Filter: Text; var BudgetDim2Filter: Text; var BudgetDim3Filter: Text)
    begin
        if not ItemBudgetName.Get(CurrentAnalysisArea, CurrentItemBudgetName) then begin
            ItemBudgetName.FilterGroup := 2;
            ItemBudgetName.SetRange("Analysis Area", CurrentAnalysisArea);
            ItemBudgetName.FilterGroup := 0;
            if not ItemBudgetName.Find('-') then begin
                ItemBudgetName.Init();
                ItemBudgetName."Analysis Area" := "Analysis Area Type".FromInteger(CurrentAnalysisArea);
                ItemBudgetName.Name := Text001;
                ItemBudgetName.Description := Text002;
                ItemBudgetName.Insert(true);
            end;
            CurrentItemBudgetName := ItemBudgetName.Name;
        end;

        SetItemBudgetName(
          CurrentItemBudgetName, ItemBudgetName, ItemStatisticsBuffer,
          BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
    end;

    procedure CheckBudgetName(CurrentAnalysisType: Option; CurrentItemBudgetName: Code[10]; var ItemBudgetName: Record "Item Budget Name")
    begin
        ItemBudgetName.Get(CurrentAnalysisType, CurrentItemBudgetName);
    end;

    procedure SetItemBudgetName(CurrentItemBudgetName: Code[10]; var ItemBudgetName: Record "Item Budget Name"; var ItemStatisticsBuf: Record "Item Statistics Buffer"; var BudgetDim1Filter: Text; var BudgetDim2Filter: Text; var BudgetDim3Filter: Text)
    begin
        ItemStatisticsBuf.SetRange("Budget Filter", CurrentItemBudgetName);
        if PrevItemBudgetName.Name <> '' then begin
            if ItemBudgetName."Budget Dimension 1 Code" <> PrevItemBudgetName."Budget Dimension 1 Code" then
                BudgetDim1Filter := '';
            if ItemBudgetName."Budget Dimension 2 Code" <> PrevItemBudgetName."Budget Dimension 2 Code" then
                BudgetDim2Filter := '';
            if ItemBudgetName."Budget Dimension 3 Code" <> PrevItemBudgetName."Budget Dimension 3 Code" then
                BudgetDim3Filter := '';
        end;
        ItemStatisticsBuf.SetFilter("Dimension 1 Filter", BudgetDim1Filter);
        ItemStatisticsBuf.SetFilter("Dimension 2 Filter", BudgetDim2Filter);
        ItemStatisticsBuf.SetFilter("Dimension 3 Filter", BudgetDim3Filter);

        PrevItemBudgetName := ItemBudgetName;
    end;

    procedure LookupItemBudgetName(var CurrentItemBudgetName: Code[10]; var ItemBudgetName: Record "Item Budget Name"; var ItemStatisticsBuf: Record "Item Statistics Buffer"; var BudgetDim1Filter: Text; var BudgetDim2Filter: Text; var BudgetDim3Filter: Text)
    var
        ItemBudgetName2: Record "Item Budget Name";
    begin
        ItemBudgetName2.Copy(ItemBudgetName);
        ItemBudgetName2.FilterGroup := 2;
        ItemBudgetName2.SetRange("Analysis Area", ItemBudgetName2."Analysis Area");
        ItemBudgetName2.FilterGroup := 0;
        if PAGE.RunModal(0, ItemBudgetName2) = ACTION::LookupOK then begin
            ItemBudgetName := ItemBudgetName2;
            CurrentItemBudgetName := ItemBudgetName.Name;
            SetItemBudgetName(
              CurrentItemBudgetName, ItemBudgetName, ItemStatisticsBuf,
              BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
        end else
            BudgetNameSelection(
              ItemBudgetName."Analysis Area".AsInteger(), CurrentItemBudgetName, ItemBudgetName, ItemStatisticsBuf,
              BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
    end;

    procedure SetLineAndColumnDim(ItemBudgetName: Record "Item Budget Name"; var LineDimCode: Text[30]; var LineDimType: Enum "Item Budget Dimension Type"; var ColumnDimCode: Text[30]; var ColumnDimType: Enum "Item Budget Dimension Type")
    var
        Item: Record Item;
    begin
        if (LineDimCode = '') and (ColumnDimCode = '') then begin
            LineDimCode := Item.TableCaption();
            ColumnDimCode := Text003;
        end;

        OnBeforeSetLineAndColumnDim(ItemBudgetName, LineDimCode, LineDimType, ColumnDimCode, ColumnDimType);

        LineDimType := DimCodeToType(LineDimCode, ItemBudgetName);
        ColumnDimType := DimCodeToType(ColumnDimCode, ItemBudgetName);

        OnAfterSetLineAndColumnDim(ItemBudgetName, LineDimCode, LineDimType, ColumnDimCode, ColumnDimType);
    end;

    procedure FindRecord(ItemBudgetName: Record "Item Budget Name"; DimType: Enum "Item Budget Dimension Type"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]; ItemFilter: Text; SourceNoFilter: Text; PeriodType: Enum "Analysis Period Type"; DateFilter: Text; var PeriodInitialized: Boolean; InternalDateFilter: Text; GlobalDim1Filter: Text; GlobalDim2Filter: Text; BudgetDim1Filter: Text; BudgetDim2Filter: Text; BudgetDim3Filter: Text): Boolean
    var
        Item: Record Item;
        Cust: Record Customer;
        Vend: Record Vendor;
        Location: Record Location;
        Period: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
        Found: Boolean;
    begin
        GetGLSetup();
        case DimType of
            GlobalDimType::Item:
                begin
                    Item."No." := DimCodeBuf.Code;
                    if ItemFilter <> '' then
                        Item.SetFilter("No.", ItemFilter);
                    OnFindRecOnBeforeItemFind(Item);
                    Found := Item.Find(Which);
                    if Found then
                        CopyItemToBuf(Item, DimCodeBuf);
                end;
            GlobalDimType::Customer:
                begin
                    Cust."No." := DimCodeBuf.Code;
                    if SourceNoFilter <> '' then
                        Cust.SetFilter("No.", SourceNoFilter);
                    Found := Cust.Find(Which);
                    if Found then
                        CopyCustToBuf(Cust, DimCodeBuf);
                end;
            GlobalDimType::Vendor:
                begin
                    Vend."No." := DimCodeBuf.Code;
                    if SourceNoFilter <> '' then
                        Vend.SetFilter("No.", SourceNoFilter);
                    Found := Vend.Find(Which);
                    if Found then
                        CopyVendToBuf(Vend, DimCodeBuf);
                end;
            GlobalDimType::Period:
                begin
                    Period."Period Start" := DimCodeBuf."Period Start";
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter)
                    else
                        if not PeriodInitialized and (InternalDateFilter <> '') then
                            Period.SetFilter("Period Start", InternalDateFilter);
                    Found := PeriodPageMgt.FindDate(Which, Period, PeriodType);
                    if Found then
                        CopyPeriodToBuf(Period, DimCodeBuf, DateFilter);
                    PeriodInitialized := true;
                end;
            GlobalDimType::Location:
                begin
                    Location.Code := DimCodeBuf.Code;
                    if SourceNoFilter <> '' then
                        Location.SetFilter(Code, SourceNoFilter);
                    Found := Location.Find(Which);
                    if Found then
                        CopyLocationToBuf(Location, DimCodeBuf);
                end;
            GlobalDimType::"Global Dimension 1":
                Found := FindDim(DimCodeBuf, Which, GlobalDim1Filter, GLSetup."Global Dimension 1 Code");
            GlobalDimType::"Global Dimension 2":
                Found := FindDim(DimCodeBuf, Which, GlobalDim2Filter, GLSetup."Global Dimension 2 Code");
            GlobalDimType::"Budget Dimension 1":
                Found := FindDim(DimCodeBuf, Which, BudgetDim1Filter, ItemBudgetName."Budget Dimension 1 Code");
            GlobalDimType::"Budget Dimension 2":
                Found := FindDim(DimCodeBuf, Which, BudgetDim2Filter, ItemBudgetName."Budget Dimension 2 Code");
            GlobalDimType::"Budget Dimension 3":
                Found := FindDim(DimCodeBuf, Which, BudgetDim3Filter, ItemBudgetName."Budget Dimension 3 Code");
        end;
        exit(Found);
    end;

    local procedure FindDim(var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]; DimFilter: Text; DimCode: Code[20]): Boolean
    var
        DimVal: Record "Dimension Value";
    begin
        if DimFilter <> '' then
            DimVal.SetFilter(Code, DimFilter);
        DimVal."Dimension Code" := DimCode;
        DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
        DimVal.Code := DimCodeBuf.Code;
        if DimVal.Find(Which) then begin
            CopyDimValToBuf(DimVal, DimCodeBuf);
            exit(true);
        end
    end;

    procedure NextRecord(ItemBudgetName: Record "Item Budget Name"; DimType: Enum "Item Budget Dimension Type"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer; ItemFilter: Text; SourceNoFilter: Text; PeriodType: Enum "Analysis Period Type"; DateFilter: Text; GlobalDim1Filter: Text; GlobalDim2Filter: Text; BudgetDim1Filter: Text; BudgetDim2Filter: Text; BudgetDim3Filter: Text): Integer
    var
        Item: Record Item;
        Cust: Record Customer;
        Vend: Record Vendor;
        Location: Record Location;
        Period: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
        ResultSteps: Integer;
    begin
        GetGLSetup();
        case DimType of
            GlobalDimType::Item:
                begin
                    Item."No." := DimCodeBuf.Code;
                    if ItemFilter <> '' then
                        Item.SetFilter("No.", ItemFilter);
                    OnNextRecOnBeforeItemFind(Item);
                    ResultSteps := Item.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyItemToBuf(Item, DimCodeBuf);
                end;
            GlobalDimType::Customer:
                begin
                    Cust."No." := DimCodeBuf.Code;
                    if SourceNoFilter <> '' then
                        Cust.SetFilter("No.", SourceNoFilter);
                    OnNextRecOnBeforeCustomerFindNext(Cust);
                    ResultSteps := Cust.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyCustToBuf(Cust, DimCodeBuf);
                end;
            GlobalDimType::Vendor:
                begin
                    Vend."No." := DimCodeBuf.Code;
                    if SourceNoFilter <> '' then
                        Vend.SetFilter("No.", SourceNoFilter);
                    OnNextRecOnBeforeVendorFindNext(Vend);
                    ResultSteps := Vend.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyVendToBuf(Vend, DimCodeBuf);
                end;
            GlobalDimType::Period:
                begin
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter);
                    Period."Period Start" := DimCodeBuf."Period Start";
                    ResultSteps := PeriodPageMgt.NextDate(Steps, Period, PeriodType);
                    if ResultSteps <> 0 then
                        CopyPeriodToBuf(Period, DimCodeBuf, DateFilter);
                end;
            GlobalDimType::Location:
                begin
                    Location.Code := DimCodeBuf.Code;
                    if SourceNoFilter <> '' then
                        Location.SetFilter(Code, SourceNoFilter);
                    ResultSteps := Location.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyLocationToBuf(Location, DimCodeBuf);
                end;
            GlobalDimType::"Global Dimension 1":
                ResultSteps := NextDim(DimCodeBuf, Steps, GlobalDim1Filter, GLSetup."Global Dimension 1 Code");
            GlobalDimType::"Global Dimension 2":
                ResultSteps := NextDim(DimCodeBuf, Steps, GlobalDim2Filter, GLSetup."Global Dimension 2 Code");
            GlobalDimType::"Budget Dimension 1":
                ResultSteps := NextDim(DimCodeBuf, Steps, BudgetDim1Filter, ItemBudgetName."Budget Dimension 1 Code");
            GlobalDimType::"Budget Dimension 2":
                ResultSteps := NextDim(DimCodeBuf, Steps, BudgetDim2Filter, ItemBudgetName."Budget Dimension 2 Code");
            GlobalDimType::"Budget Dimension 3":
                ResultSteps := NextDim(DimCodeBuf, Steps, BudgetDim3Filter, ItemBudgetName."Budget Dimension 3 Code");
        end;
        exit(ResultSteps);
    end;

    local procedure NextDim(var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer; DimFilter: Text; DimCode: Code[20]): Integer
    var
        DimVal: Record "Dimension Value";
        ActualSteps: Integer;
    begin
        if DimFilter <> '' then
            DimVal.SetFilter(Code, DimFilter);
        DimVal."Dimension Code" := DimCode;
        DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
        DimVal.Code := DimCodeBuf.Code;
        ActualSteps := DimVal.Next(Steps);
        if ActualSteps <> 0 then
            CopyDimValToBuf(DimVal, DimCodeBuf);
        exit(ActualSteps);
    end;

    procedure SetBufferFilters(var ItemStatisticsBuf: Record "Item Statistics Buffer"; ItemBudgetName: Record "Item Budget Name"; ItemFilter: Text; SourceTypeFilter: Enum "Analysis Source Type"; SourceNoFilter: Text; DateFilter: Text; GlobalDim1Filter: Text; GlobalDim2Filter: Text; BudgetDim1Filter: Text; BudgetDim2Filter: Text; BudgetDim3Filter: Text)
    begin
        ItemStatisticsBuf.Reset();
        ItemStatisticsBuf.SetRange("Analysis Area Filter", ItemBudgetName."Analysis Area");
        ItemStatisticsBuf.SetRange("Budget Filter", ItemBudgetName.Name);
        if ItemFilter <> '' then
            ItemStatisticsBuf.SetFilter("Item Filter", ItemFilter);
        if SourceNoFilter <> '' then begin
            ItemStatisticsBuf.SetFilter("Source Type Filter", '%1', SourceTypeFilter);
            ItemStatisticsBuf.SetFilter("Source No. Filter", SourceNoFilter);
        end;
        if DateFilter <> '' then
            ItemStatisticsBuf.SetFilter("Date Filter", DateFilter);
        if GlobalDim1Filter <> '' then
            ItemStatisticsBuf.SetFilter("Global Dimension 1 Filter", GlobalDim1Filter);
        if GlobalDim2Filter <> '' then
            ItemStatisticsBuf.SetFilter("Global Dimension 2 Filter", GlobalDim2Filter);
        if BudgetDim1Filter <> '' then
            ItemStatisticsBuf.SetFilter("Dimension 1 Filter", BudgetDim1Filter);
        if BudgetDim2Filter <> '' then
            ItemStatisticsBuf.SetFilter("Dimension 2 Filter", BudgetDim2Filter);
        if BudgetDim3Filter <> '' then
            ItemStatisticsBuf.SetFilter("Dimension 3 Filter", BudgetDim3Filter);
    end;

    procedure SetDimensionFilters(var ItemStatisticsBuf: Record "Item Statistics Buffer"; DimType: Enum "Item Budget Dimension Type"; DimCodeBuf: Record "Dimension Code Buffer")
    begin
        case DimType of
            GlobalDimType::Item:
                ItemStatisticsBuf.SetRange("Item Filter", DimCodeBuf.Code);
            GlobalDimType::Customer:
                begin
                    ItemStatisticsBuf.SetRange("Source Type Filter", ItemStatisticsBuf."Source Type Filter"::Customer);
                    ItemStatisticsBuf.SetRange("Source No. Filter", DimCodeBuf.Code);
                end;
            GlobalDimType::Vendor:
                begin
                    ItemStatisticsBuf.SetRange("Source Type Filter", ItemStatisticsBuf."Source Type Filter"::Vendor);
                    ItemStatisticsBuf.SetRange("Source No. Filter", DimCodeBuf.Code);
                end;
            GlobalDimType::Location:
                ItemStatisticsBuf.SetRange("Location Filter", DimCodeBuf.Code);
            GlobalDimType::Period:
                ItemStatisticsBuf.SetRange("Date Filter", DimCodeBuf."Period Start", DimCodeBuf."Period End");
            GlobalDimType::"Global Dimension 1":
                if DimCodeBuf.Totaling <> '' then
                    ItemStatisticsBuf.SetFilter("Global Dimension 1 Filter", DimCodeBuf.Totaling)
                else
                    ItemStatisticsBuf.SetRange("Global Dimension 1 Filter", DimCodeBuf.Code);
            GlobalDimType::"Global Dimension 2":
                if DimCodeBuf.Totaling <> '' then
                    ItemStatisticsBuf.SetFilter("Global Dimension 2 Filter", DimCodeBuf.Totaling)
                else
                    ItemStatisticsBuf.SetRange("Global Dimension 2 Filter", DimCodeBuf.Code);
            GlobalDimType::"Budget Dimension 1":
                if DimCodeBuf.Totaling <> '' then
                    ItemStatisticsBuf.SetFilter("Dimension 1 Filter", DimCodeBuf.Totaling)
                else
                    ItemStatisticsBuf.SetRange("Dimension 1 Filter", DimCodeBuf.Code);
            GlobalDimType::"Budget Dimension 2":
                if DimCodeBuf.Totaling <> '' then
                    ItemStatisticsBuf.SetFilter("Dimension 2 Filter", DimCodeBuf.Totaling)
                else
                    ItemStatisticsBuf.SetRange("Dimension 2 Filter", DimCodeBuf.Code);
            GlobalDimType::"Budget Dimension 3":
                if DimCodeBuf.Totaling <> '' then
                    ItemStatisticsBuf.SetFilter("Dimension 3 Filter", DimCodeBuf.Totaling)
                else
                    ItemStatisticsBuf.SetRange("Dimension 3 Filter", DimCodeBuf.Code);
        end;
    end;

    local procedure DimCodeToType(DimCode: Code[20]; ItemBudgetName: Record "Item Budget Name") Result: Enum "Item Budget Dimension Type"
    var
        Location: Record Location;
        Item: Record Item;
        Cust: Record Customer;
        Vend: Record Vendor;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDimCodeToType(DimCode, ItemBudgetName, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GetGLSetup();
        case DimCode of
            '':
                exit(Enum::"Item Budget Dimension Type"::Undefined);
            UpperCase(Item.TableCaption()):
                exit(Enum::"Item Budget Dimension Type"::Item);
            UpperCase(Cust.TableCaption()):
                exit(Enum::"Item Budget Dimension Type"::Customer);
            UpperCase(Vend.TableCaption()):
                exit(Enum::"Item Budget Dimension Type"::Vendor);
            UpperCase(Text003):
                exit(Enum::"Item Budget Dimension Type"::Period);
            UpperCase(Location.TableCaption()):
                exit(Enum::"Item Budget Dimension Type"::Location);
            GLSetup."Global Dimension 1 Code":
                exit(Enum::"Item Budget Dimension Type"::"Global Dimension 1");
            GLSetup."Global Dimension 2 Code":
                exit(Enum::"Item Budget Dimension Type"::"Global Dimension 2");
            ItemBudgetName."Budget Dimension 1 Code":
                exit(Enum::"Item Budget Dimension Type"::"Budget Dimension 1");
            ItemBudgetName."Budget Dimension 2 Code":
                exit(Enum::"Item Budget Dimension Type"::"Budget Dimension 2");
            ItemBudgetName."Budget Dimension 3 Code":
                exit(Enum::"Item Budget Dimension Type"::"Budget Dimension 3");
            else
                exit(Enum::"Item Budget Dimension Type"::Undefined);
        end;
    end;

    procedure GetDimSelection(OldDimSelCode: Text[30]; ItemBudgetName: Record "Item Budget Name"): Text[30]
    var
        Item: Record Item;
        Cust: Record Customer;
        Vend: Record Vendor;
        Location: Record Location;
        DimSelection: Page "Dimension Selection";
    begin
        GetGLSetup();
        DimSelection.InsertDimSelBuf(false, Item.TableCaption(), Item.TableCaption());
        DimSelection.InsertDimSelBuf(false, Cust.TableCaption(), Cust.TableCaption());
        DimSelection.InsertDimSelBuf(false, Location.TableCaption(), Location.TableCaption());
        DimSelection.InsertDimSelBuf(false, Vend.TableCaption(), Vend.TableCaption());
        DimSelection.InsertDimSelBuf(false, Text003, Text003);
        if GLSetup."Global Dimension 1 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, GLSetup."Global Dimension 1 Code", '');
        if GLSetup."Global Dimension 2 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, GLSetup."Global Dimension 2 Code", '');
        if ItemBudgetName."Budget Dimension 1 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, ItemBudgetName."Budget Dimension 1 Code", '');
        if ItemBudgetName."Budget Dimension 2 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, ItemBudgetName."Budget Dimension 2 Code", '');
        if ItemBudgetName."Budget Dimension 3 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, ItemBudgetName."Budget Dimension 3 Code", '');

        OnGetDimSelectionOnBeforeDimSelectionRunModal(DimSelection, ItemBudgetName);
        DimSelection.LookupMode := true;
        if DimSelection.RunModal() = ACTION::LookupOK then
            exit(DimSelection.GetDimSelCode());
        exit(OldDimSelCode);
    end;

    procedure ValidateLineDimTypeAndCode(ItemBudgetName: Record "Item Budget Name"; var LineDimCode: Text[30]; var LineDimType: Enum "Item Budget Dimension Type"; ColumnDimType: Enum "Item Budget Dimension Type"; var InternalDateFilter: Text; var DateFilter: Text; var ItemStatisticsBuf: Record "Item Statistics Buffer"; var PeriodInitialized: Boolean)
    begin
        if DimCodeNotAllowed(LineDimCode, ItemBudgetName) then begin
            Message(Text004, LineDimCode);
            LineDimCode := '';
        end;
        LineDimType := DimCodeToType(LineDimCode, ItemBudgetName);
        InternalDateFilter := ItemStatisticsBuf.GetFilter("Date Filter");
        if (not OptionIsPeriod(LineDimType)) and (not OptionIsPeriod(ColumnDimType)) then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    procedure ValidateColumnDimTypeAndCode(ItemBudgetName: Record "Item Budget Name"; var ColumnDimCode: Text[30]; var ColumnDimType: Enum "Item Budget Dimension Type"; LineDimType: Enum "Item Budget Dimension Type"; var InternalDateFilter: Text; var DateFilter: Text; var ItemStatisticsBuf: Record "Item Statistics Buffer"; var PeriodInitialized: Boolean)
    begin
        if DimCodeNotAllowed(ColumnDimCode, ItemBudgetName) then begin
            Message(Text005, ColumnDimCode);
            ColumnDimCode := '';
        end;
        ColumnDimType := DimCodeToType(ColumnDimCode, ItemBudgetName);
        InternalDateFilter := ItemStatisticsBuf.GetFilter("Date Filter");
        if (not OptionIsPeriod(ColumnDimType)) and (not OptionIsPeriod(LineDimType)) then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    procedure DimCodeNotAllowed(DimCode: Text[30]; ItemBudgetName: Record "Item Budget Name") Result: Boolean
    var
        Item: Record Item;
        Cust: Record Customer;
        Vend: Record Vendor;
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDimCodeNotAllowed(DimCode, ItemBudgetName, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GetGLSetup();
        exit(
          not (UpperCase(DimCode) in
               [UpperCase(Item.TableCaption()),
                UpperCase(Cust.TableCaption()),
                UpperCase(Vend.TableCaption()),
                UpperCase(Location.TableCaption()),
                UpperCase(Text003),
                ItemBudgetName."Budget Dimension 1 Code",
                ItemBudgetName."Budget Dimension 2 Code",
                ItemBudgetName."Budget Dimension 3 Code",
                GLSetup."Global Dimension 1 Code",
                GLSetup."Global Dimension 2 Code",
                '']));
    end;

    procedure FormatToAmount(var AmountAsText: Text[250]; RoundingFactor: Enum "Analysis Rounding Factor")
    var
        Amount: Decimal;
    begin
        if (AmountAsText = '') or (RoundingFactor = RoundingFactor::None) then
            exit;
        Evaluate(Amount, AmountAsText);
        Amount := MatrixMgt.RoundAmount(Amount, RoundingFactor);
        if Amount = 0 then
            AmountAsText := ''
        else
            case RoundingFactor of
                RoundingFactor::"1":
                    AmountAsText := Format(Amount);
                RoundingFactor::"1000", RoundingFactor::"1000000":
                    AmountAsText := Format(Amount, 0, Text007);
            end;
    end;

    procedure DrillDownBudgetAmount(ItemBudgetName: Record "Item Budget Name"; ItemFilter: Text; SourceTypeFilter: Enum "Analysis Source Type"; SourceNoFilter: Text; DateFilter: Text; GlobalDim1Filter: Text; GlobalDim2Filter: Text; BudgetDim1Filter: Text; BudgetDim2Filter: Text; BudgetDim3Filter: Text; RowDimType: Enum "Item Budget Dimension Type"; RowDimCodeBuf: Record "Dimension Code Buffer"; ColDimType: Enum "Item Budget Dimension Type"; ColDimCodeBuf: Record "Dimension Code Buffer"; ValueType: Enum "Item Analysis Value Type"; LinesOnly: Boolean)
    var
        ItemStatisticsBuf: Record "Item Statistics Buffer";
        ItemBudgetEntry: Record "Item Budget Entry";
    begin
        SetBufferFilters(
          ItemStatisticsBuf, ItemBudgetName,
          ItemFilter, SourceTypeFilter, SourceNoFilter, DateFilter,
          GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
        SetDimensionFilters(ItemStatisticsBuf, RowDimType, RowDimCodeBuf);
        if not LinesOnly then
            SetDimensionFilters(ItemStatisticsBuf, ColDimType, ColDimCodeBuf);

        ItemBudgetEntry.SetRange("Analysis Area", ItemBudgetName."Analysis Area");
        ItemBudgetEntry.SetRange("Budget Name", ItemBudgetName.Name);

        if ItemStatisticsBuf.GetFilter("Item Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Item Filter", ItemBudgetEntry."Item No.");
        if ItemStatisticsBuf.GetFilter("Global Dimension 1 Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Global Dimension 1 Filter", ItemBudgetEntry."Global Dimension 1 Code");
        if ItemStatisticsBuf.GetFilter("Global Dimension 2 Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Global Dimension 2 Filter", ItemBudgetEntry."Global Dimension 2 Code");
        if ItemStatisticsBuf.GetFilter("Dimension 1 Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Dimension 1 Filter", ItemBudgetEntry."Budget Dimension 1 Code");
        if ItemStatisticsBuf.GetFilter("Dimension 2 Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Dimension 2 Filter", ItemBudgetEntry."Budget Dimension 2 Code");
        if ItemStatisticsBuf.GetFilter("Dimension 3 Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Dimension 3 Filter", ItemBudgetEntry."Budget Dimension 3 Code");
        if ItemStatisticsBuf.GetFilter("Location Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Location Filter", ItemBudgetEntry."Location Code");
        if ItemStatisticsBuf.GetFilter("Date Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Date Filter", ItemBudgetEntry.Date)
        else
            ItemBudgetEntry.SetRange(Date, 0D, DMY2Date(31, 12, 9999));

        if ItemStatisticsBuf.GetFilter("Source No. Filter") <> '' then begin
            ItemStatisticsBuf.CopyFilter("Source Type Filter", ItemBudgetEntry."Source Type");
            ItemStatisticsBuf.CopyFilter("Source No. Filter", ItemBudgetEntry."Source No.");
            ItemBudgetEntry.SetCurrentKey("Analysis Area", "Budget Name", "Source Type", "Source No.", "Item No.");
        end else
            ItemBudgetEntry.SetCurrentKey("Analysis Area", "Budget Name", "Item No.");

        case ValueType of
            ValueType::"Sales Amount":
                PAGE.Run(0, ItemBudgetEntry, ItemBudgetEntry."Sales Amount");
            ValueType::"Cost Amount":
                PAGE.Run(0, ItemBudgetEntry, ItemBudgetEntry."Cost Amount");
            ValueType::Quantity:
                PAGE.Run(0, ItemBudgetEntry, ItemBudgetEntry.Quantity);
            else
                OnDrillDownBudgetAmountOnValueTypeCaseElse(ValueType, ItemBudgetEntry);
        end;
    end;

    procedure DeleteBudget(AnalysisArea: Integer; ItemBudgetName: Code[10]; ItemFilter: Text; DateFilter: Text; SourceTypeFilter: Option; SourceNoFilter: Text; GlobalDim1Filter: Text; GlobalDim2Filter: Text; BudgetDim1Filter: Text; BudgetDim2Filter: Text; BudgetDim3Filter: Text)
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
    begin
        if Confirm(Text006) then begin
            ItemBudgetEntry.SetRange("Analysis Area", AnalysisArea);
            ItemBudgetEntry.SetRange("Budget Name", ItemBudgetName);
            if ItemFilter <> '' then
                ItemBudgetEntry.SetFilter("Item No.", ItemFilter);
            if DateFilter <> '' then
                ItemBudgetEntry.SetFilter(Date, DateFilter);
            if SourceNoFilter <> '' then begin
                ItemBudgetEntry.SetRange("Source Type", SourceTypeFilter);
                ItemBudgetEntry.SetFilter("Source No.", SourceNoFilter);
            end;
            if GlobalDim1Filter <> '' then
                ItemBudgetEntry.SetFilter("Global Dimension 1 Code", GlobalDim1Filter);
            if GlobalDim2Filter <> '' then
                ItemBudgetEntry.SetFilter("Global Dimension 2 Code", GlobalDim2Filter);
            if BudgetDim1Filter <> '' then
                ItemBudgetEntry.SetFilter("Budget Dimension 1 Code", BudgetDim1Filter);
            if BudgetDim2Filter <> '' then
                ItemBudgetEntry.SetFilter("Budget Dimension 2 Code", BudgetDim2Filter);
            if BudgetDim3Filter <> '' then
                ItemBudgetEntry.SetFilter("Budget Dimension 3 Code", BudgetDim3Filter);
            ItemBudgetEntry.SetCurrentKey("Entry No.");
            if ItemBudgetEntry.FindFirst() then
                UpdateItemAnalysisView.SetLastBudgetEntryNo(ItemBudgetEntry."Entry No." - 1);
            ItemBudgetEntry.SetCurrentKey("Analysis Area", ItemBudgetEntry."Budget Name");
            ItemBudgetEntry.DeleteAll(true);
        end;
    end;

    local procedure GetGLSetup()
    begin
        if GLSetupRead then
            exit;
        GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure CopyItemToBuf(var Item: Record Item; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        DimCodeBuf.Init();
        DimCodeBuf.Code := Item."No.";
        DimCodeBuf.Name := Item.Description;

        OnAfterCopyItemToBuf(Item, DimCodeBuf);
    end;

    local procedure CopyCustToBuf(var Cust: Record Customer; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        DimCodeBuf.Init();
        DimCodeBuf.Code := Cust."No.";
        DimCodeBuf.Name := Cust.Name;
    end;

    local procedure CopyVendToBuf(var Vend: Record Vendor; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        DimCodeBuf.Init();
        DimCodeBuf.Code := Vend."No.";
        DimCodeBuf.Name := Vend.Name;
    end;

    local procedure CopyPeriodToBuf(var DatePeriod: Record Date; var DimCodeBuf: Record "Dimension Code Buffer"; DateFilter: Text)
    var
        DatePeriod2: Record Date;
    begin
        DimCodeBuf.Init();
        DimCodeBuf.Code := Format(DatePeriod."Period Start");
        DimCodeBuf."Period Start" := DatePeriod."Period Start";
        DimCodeBuf."Period End" := DatePeriod."Period End";
        if DateFilter <> '' then begin
            DatePeriod2.SetFilter("Period End", DateFilter);
            if DatePeriod2.GetRangeMax("Period End") < DimCodeBuf."Period End" then
                DimCodeBuf."Period End" := DatePeriod2.GetRangeMax("Period End");
        end;
        DimCodeBuf.Name := DatePeriod."Period Name";
    end;

    local procedure CopyLocationToBuf(var Location: Record Location; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        DimCodeBuf.Init();
        DimCodeBuf.Code := Location.Code;
        if Location.Name <> '' then
            DimCodeBuf.Name := Location.Name
    end;

    local procedure CopyDimValToBuf(var DimVal: Record "Dimension Value"; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        DimCodeBuf.Init();
        DimCodeBuf.Code := DimVal.Code;
        DimCodeBuf.Name := DimVal.Name;
        DimCodeBuf.Totaling := DimVal.Totaling;
        DimCodeBuf.Indentation := DimVal.Indentation;
        DimCodeBuf."Show in Bold" := DimVal."Dimension Value Type" <> DimVal."Dimension Value Type"::Standard;
    end;

    procedure CalculateAmount(ValueType: Enum "Item Analysis Value Type"; SetColumnFilter: Boolean; var ItemStatisticsBuf: Record "Item Statistics Buffer"; ItemBudgetName: Record "Item Budget Name"; ItemFilter: Text; SourceTypeFilter: Enum "Analysis Source Type"; SourceNoFilter: Text; DateFilter: Text; GlobalDim1Filter: Text; GlobalDim2Filter: Text; BudgetDim1Filter: Text; BudgetDim2Filter: Text; BudgetDim3Filter: Text; RowDimType: Enum "Item Budget Dimension Type"; RowDimCodeBuf: Record "Dimension Code Buffer"; ColDimType: Enum "Item Budget Dimension Type"; ColDimCodeBuf: Record "Dimension Code Buffer") Result: Decimal
    begin
        SetBufferFilters(
          ItemStatisticsBuf, ItemBudgetName, ItemFilter, SourceTypeFilter, SourceNoFilter,
          DateFilter, GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
        SetDimensionFilters(ItemStatisticsBuf, RowDimType, RowDimCodeBuf);
        if SetColumnFilter then
            SetDimensionFilters(ItemStatisticsBuf, ColDimType, ColDimCodeBuf);

        case ValueType of
            ValueType::"Sales Amount":
                begin
                    ItemStatisticsBuf.CalcFields("Budgeted Sales Amount");
                    exit(ItemStatisticsBuf."Budgeted Sales Amount");
                end;
            ValueType::"Cost Amount":
                begin
                    ItemStatisticsBuf.CalcFields("Budgeted Cost Amount");
                    exit(ItemStatisticsBuf."Budgeted Cost Amount");
                end;
            ValueType::Quantity:
                begin
                    ItemStatisticsBuf.CalcFields("Budgeted Quantity");
                    exit(ItemStatisticsBuf."Budgeted Quantity");
                end;
            else begin
                OnCalculateAmountOnValueTypeCaseElse(ValueType, ItemStatisticsBuf, Result);
                exit(Result);
            end;
        end;
    end;

    procedure SetAmount(ValueType: Enum "Item Analysis Value Type"; SetColumnFilter: Boolean; var ItemStatisticsBuf: Record "Item Statistics Buffer"; ItemBudgetName: Record "Item Budget Name"; ItemFilter: Text; SourceTypeFilter: Enum "Analysis Source Type"; SourceNoFilter: Text; DateFilter: Text; GlobalDim1Filter: Text; GlobalDim2Filter: Text; BudgetDim1Filter: Text; BudgetDim2Filter: Text; BudgetDim3Filter: Text; RowDimType: Enum "Item Budget Dimension Type"; RowDimCodeBuf: Record "Dimension Code Buffer"; ColDimType: Enum "Item Budget Dimension Type"; ColDimCodeBuf: Record "Dimension Code Buffer"; NewAmount: Decimal)
    begin
        SetBufferFilters(
          ItemStatisticsBuf, ItemBudgetName, ItemFilter, SourceTypeFilter, SourceNoFilter,
          DateFilter, GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
        SetDimensionFilters(ItemStatisticsBuf, RowDimType, RowDimCodeBuf);
        if SetColumnFilter then
            SetDimensionFilters(ItemStatisticsBuf, ColDimType, ColDimCodeBuf);

        case ValueType of
            ValueType::"Sales Amount":
                begin
                    ItemStatisticsBuf.CalcFields("Budgeted Sales Amount");
                    ItemStatisticsBuf.Validate("Budgeted Sales Amount", NewAmount);
                end;
            ValueType::"Cost Amount":
                begin
                    ItemStatisticsBuf.CalcFields("Budgeted Cost Amount");
                    ItemStatisticsBuf.Validate("Budgeted Cost Amount", NewAmount);
                end;
            ValueType::Quantity:
                begin
                    ItemStatisticsBuf.CalcFields("Budgeted Quantity");
                    ItemStatisticsBuf.Validate("Budgeted Quantity", NewAmount);
                end;
            else
                OnSetAmountOnValueTypeCaseElse(ValueType, ItemStatisticsBuf);
        end;
    end;

    local procedure OptionIsPeriod(DimOption: Enum "Item Budget Dimension Type"): Boolean
    begin
        exit(DimOption = GlobalDimType::Period);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemToBuf(var Item: Record Item; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRecOnBeforeItemFind(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNextRecOnBeforeItemFind(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNextRecOnBeforeCustomerFindNext(var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNextRecOnBeforeVendorFindNext(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDimCodeToType(DimCode: Text[30]; ItemBudgetName: Record "Item Budget Name"; var Result: Enum "Item Budget Dimension Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDimSelectionOnBeforeDimSelectionRunModal(var DimensionSelection: Page "Dimension Selection"; var ItemBudgetName: Record "Item Budget Name")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDimCodeNotAllowed(DimCode: Text[30]; ItemBudgetName: Record "Item Budget Name"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetLineAndColumnDim(ItemBudgetName: Record "Item Budget Name"; var LineDimCode: Text[30]; var LineDimType: Enum "Item Budget Dimension Type"; var ColumnDimCode: Text[30]; var ColumnDimType: Enum "Item Budget Dimension Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetLineAndColumnDim(ItemBudgetName: Record "Item Budget Name"; var LineDimCode: Text[30]; var LineDimType: Enum "Item Budget Dimension Type"; var ColumnDimCode: Text[30]; var ColumnDimType: Enum "Item Budget Dimension Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownBudgetAmountOnValueTypeCaseElse(ItemAnalysisValueType: Enum "Item Analysis Value Type"; var ItemBudgetEntry: Record "Item Budget Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateAmountOnValueTypeCaseElse(ItemAnalysisValueType: Enum "Item Analysis Value Type"; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetAmountOnValueTypeCaseElse(ItemAnalysisValueType: Enum "Item Analysis Value Type"; var ItemStatisticsBuffer: Record "Item Statistics Buffer")
    begin
    end;
}

