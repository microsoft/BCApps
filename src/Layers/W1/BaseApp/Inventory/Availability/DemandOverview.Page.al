// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;

page 5830 "Demand Overview"
{
    AccessByPermission = TableData Item = R;
    AdditionalSearchTerms = 'supply planning,availability overview';
    ApplicationArea = Planning;
    Caption = 'Demand Overview';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    RefreshOnActivate = true;
    SourceTable = "Availability Calc. Overview";
    SourceTableTemporary = true;
    SourceTableView = sorting("Item No.", Date, "Attached to Entry No.", Type);
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(StartDate; StartDate)
                {
                    ApplicationArea = Planning;
                    Caption = 'Start Date';
                    ToolTip = 'Specifies the start date of the period for which you want to calculate demand.';

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                    end;
                }
                field(EndDate; EndDate)
                {
                    ApplicationArea = Planning;
                    Caption = 'End Date';
                    ToolTip = 'Specifies the end date of the period for which you want to calculate demand. Enter a date that is later than the start date.';

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                    end;
                }
                field(DemandType; DemandType)
                {
                    ApplicationArea = Planning;
                    Caption = 'Demand Type';
                    ToolTip = 'Specifies a list of the types of orders for which you can calculate demand. Select one order type from the list:';

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                        DemandNoCtrlEnable := DemandType <> DemandType::"All Demands";
                    end;
                }
                field(DemandNoCtrl; DemandNo)
                {
                    ApplicationArea = Planning;
                    Caption = 'Demand No.';
                    Enabled = DemandNoCtrlEnable;
                    ToolTip = 'Specifies the number of the item for which the demand calculation was initiated.';

                    trigger OnLookup(var Text: Text) Result: Boolean
                    var
                        IsHandled: Boolean;
                    begin
#if not CLEAN25
                        IsHandled := false;
                        OnBeforeLookupDemandNo(Rec, TransformDemandTypeEnumToOption(DemandType), Result, IsHandled, Text);
                        if IsHandled then
                            exit(Result);
#endif
                        IsHandled := false;
                        OnBeforeOnLookupDemandNo(Rec, DemandType, Result, IsHandled, Text);
                        if IsHandled then
                            exit(Result);

                        OnLookupDemandNo(Rec, DemandType, Result, Text);
                    end;

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                    end;
                }
                field(IsCalculated; IsCalculated)
                {
                    ApplicationArea = Planning;
                    Caption = 'Calculated';
                    Editable = false;
                    ToolTip = 'Specifies whether the demand overview has been calculated. The check box is selected after you choose the Calculate button.';
                }
            }
            repeater(Control1)
            {
                IndentationColumn = TypeIndent;
                IndentationControls = Type;
                ShowAsTree = true;
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    HideValue = ItemNoHideValue;
                    Style = Strong;
                    StyleExpr = ItemNoEmphasize;
                    ToolTip = 'Specifies the identifier number for the item.';
                }
                field("Matches Criteria"; Rec."Matches Criteria")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies whether the line in the Demand Overview window is related to the lines where the demand overview was calculated.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = TypeEmphasize;
                    ToolTip = 'Specifies the type of availability being calculated.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    Style = Unfavorable;
                    StyleExpr = DateEmphasize;
                    ToolTip = 'Specifies the date of the availability calculation.';
                }
                field(SourceTypeText; SourceTypeText)
                {
                    ApplicationArea = Planning;
                    CaptionClass = Rec.FieldCaption("Source Type");
                    Editable = false;
                    HideValue = SourceTypeHideValue;
                    ToolTip = 'Specifies the source type of the availability calculation.';
                }
                field("Source Order Status"; Rec."Source Order Status")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    HideValue = SourceOrderStatusHideValue;
                    ToolTip = 'Specifies the order status of the item for which availability is being calculated.';
                    Visible = false;
                }
                field("Source ID"; Rec."Source ID")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the identifier code of the source.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies the description of the item for which availability is being calculated.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the location code of the item for which availability is being calculated.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field(QuantityText; QuantityText)
                {
                    ApplicationArea = Planning;
                    CaptionClass = Rec.FieldCaption(Quantity);
                    Caption = 'Quantity';
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item are demanded.';
                }
                field(ReservedQuantityText; ReservedQuantityText)
                {
                    ApplicationArea = Reservation;
                    CaptionClass = Rec.FieldCaption("Reserved Quantity");
                    Caption = 'Reserved Quantity';
                    Editable = false;
                    ToolTip = 'Specifies how many units of the demanded item are reserved.';
                }
                field("Running Total"; Rec."Running Total")
                {
                    ApplicationArea = Planning;
                    CaptionClass = Rec.FieldCaption("Running Total");
                    Editable = false;
                    HideValue = RunningTotalHideValue;
                    Style = Strong;
                    StyleExpr = RunningTotalEmphasize;
                    ToolTip = 'Specifies the total count of items from inventory, supply, and demand.';
                }
                field("Inventory Running Total"; Rec."Inventory Running Total")
                {
                    ApplicationArea = Planning;
                    CaptionClass = Rec.FieldCaption("Inventory Running Total");
                    Editable = false;
                    HideValue = InventoryRunningTotalHideValue;
                    Style = Strong;
                    StyleExpr = InventoryRunningTotalEmphasize;
                    ToolTip = 'Specifies the count of items in inventory.';
                    Visible = false;
                }
                field("Supply Running Total"; Rec."Supply Running Total")
                {
                    ApplicationArea = Planning;
                    CaptionClass = Rec.FieldCaption("Supply Running Total");
                    Editable = false;
                    HideValue = SupplyRunningTotalHideValue;
                    Style = Strong;
                    StyleExpr = SupplyRunningTotalEmphasize;
                    ToolTip = 'Specifies the count of items in supply.';
                    Visible = false;
                }
                field("Demand Running Total"; Rec."Demand Running Total")
                {
                    ApplicationArea = Planning;
                    CaptionClass = Rec.FieldCaption("Demand Running Total");
                    Editable = false;
                    HideValue = DemandRunningTotalHideValue;
                    Style = Strong;
                    StyleExpr = DemandRunningTotalEmphasize;
                    ToolTip = 'Specifies the count of items in demand.';
                    Visible = false;
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(ItemFilter; ItemFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies the item number or a filter on the item numbers that you want to trace.';

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
                        IsCalculated := false;
                    end;
                }
                field(LocationFilter; LocationFilter)
                {
                    ApplicationArea = Location;
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies the location you want to show item availability for.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Location: Record Location;
                        LocationList: Page "Location List";
                    begin
                        LocationList.SetTableView(Location);
                        LocationList.LookupMode := true;
                        if LocationList.RunModal() = ACTION::LookupOK then begin
                            LocationList.GetRecord(Location);
                            Text := Location.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                    end;
                }
                field(VariantFilter; VariantFilter)
                {
                    ApplicationArea = Service, Planning;
                    Caption = 'Variant Filter';
                    ToolTip = 'Specifies the variant code or a filter on the variant code that you want to trace.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemVariant: Record "Item Variant";
                        ItemVariants: Page "Item Variants";
                    begin
                        ItemVariant.SetFilter("Item No.", ItemFilter);
                        ItemVariants.SetTableView(ItemVariant);
                        ItemVariants.LookupMode := true;
                        if ItemVariants.RunModal() = ACTION::LookupOK then begin
                            ItemVariants.GetRecord(ItemVariant);
                            Text := ItemVariant.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Calculate)
            {
                ApplicationArea = Planning;
                Caption = 'Calculate';
                Image = Calculate;
                ToolTip = 'Update the window with any demand. ';

                trigger OnAction()
                begin
                    CalculationOfDemand := true;
                    InitTempTable();
                    IsCalculated := true;
                    Rec.SetRange("Matches Criteria");
                    if MatchCriteria then
                        Rec.SetRange("Matches Criteria", true);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Calculate_Promoted; Calculate)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        TypeIndent := 0;
        ItemNoHideValue := Rec.Type <> Rec.Type::Item;
        if Rec.Type = Rec.Type::Item then
            ItemNoEmphasize := Rec."Matches Criteria";

        TypeEmphasize := Rec."Matches Criteria" and (Rec.Type in [Rec.Type::Item, Rec.Type::"As of Date"]);
        TypeIndent := Rec.Level;

        SourceTypeText := Format(Rec."Source Type");
        SourceTypeTextOnFormat(SourceTypeText);

        if Rec.Type in [Rec.Type::Item, Rec.Type::"As of Date"] then begin
            QuantityText := '';
            ReservedQuantityText := '';
        end else begin
            QuantityText := Format(Rec.Quantity);
            ReservedQuantityText := Format(Rec."Reserved Quantity");
        end;

        SupplyRunningTotalHideValue := Rec.Type = Rec.Type::Item;
        SourceOrderStatusHideValue := Rec.Type = Rec.Type::Item;
        RunningTotalHideValue := Rec.Type = Rec.Type::Item;
        InventoryRunningTotalHideValue := Rec.Type = Rec.Type::Item;
        DemandRunningTotalHideValue := Rec.Type = Rec.Type::Item;

        DateEmphasize := Rec."Running Total" < 0;
        DescriptionEmphasize := Rec.Type = Rec.Type::Item;
        SupplyRunningTotalEmphasize := Rec.Type = Rec.Type::"As of Date";
        DemandRunningTotalEmphasize := Rec.Type = Rec.Type::"As of Date";
        RunningTotalEmphasize := Rec.Type = Rec.Type::"As of Date";
        InventoryRunningTotalEmphasize := Rec.Type = Rec.Type::"As of Date";
    end;

    trigger OnInit()
    begin
        DemandNoCtrlEnable := true;
        MatchCriteria := true;
    end;

    trigger OnOpenPage()
    begin
        InitTempTable();

        Rec.SetRange("Matches Criteria");
        if MatchCriteria then
            Rec.SetRange("Matches Criteria", true);
        DemandNoCtrlEnable := DemandType <> DemandType::"All Demands";
        CurrPage.Update(false);
    end;

    var
        TempAvailCalcOverview: Record "Availability Calc. Overview" temporary;
        CalcAvailOverview: Codeunit "Calc. Availability Overview";
        ItemFilter: Code[250];
        LocationFilter: Code[250];
        VariantFilter: Code[250];
        StartDate: Date;
        EndDate: Date;
        DemandType: Enum "Demand Order Source Type";
        DemandNo: Code[20];
        IsCalculated: Boolean;
        MatchCriteria: Boolean;
#pragma warning disable AA0074
        Text004: Label 'Inventory';
        Text020: Label 'Expanding...\';
#pragma warning disable AA0470
        Text021: Label 'Status    #1###################\';
#pragma warning restore AA0470
        Text022: Label 'Setting Filters';
        Text023: Label 'Fetching Items';
        Text025: Label 'Fetching Specific Entries in Dates';
        Text026: Label 'Displaying results';
#pragma warning restore AA0074

    protected var
        DemandNoCtrlEnable: Boolean;
        ItemNoHideValue: Boolean;
        ItemNoEmphasize: Boolean;
        TypeEmphasize: Boolean;
        TypeIndent: Integer;
        SourceTypeHideValue: Boolean;
        SourceTypeText: Text;
        SourceOrderStatusHideValue: Boolean;
        DescriptionEmphasize: Boolean;
        QuantityText: Text[1024];
        DateEmphasize: Boolean;
        ReservedQuantityText: Text[1024];
        RunningTotalHideValue: Boolean;
        RunningTotalEmphasize: Boolean;
        InventoryRunningTotalHideValue: Boolean;
        InventoryRunningTotalEmphasize: Boolean;
        SupplyRunningTotalHideValue: Boolean;
        SupplyRunningTotalEmphasize: Boolean;
        DemandRunningTotalHideValue: Boolean;
        DemandRunningTotalEmphasize: Boolean;
        CalculationOfDemand: Boolean;

    local procedure ApplyUserFilters(var AvailCalcOverview: Record "Availability Calc. Overview")
    begin
        AvailCalcOverview.Reset();
        AvailCalcOverview.SetFilter("Item No.", ItemFilter);
        if (StartDate <> 0D) or (EndDate <> 0D) then
            if EndDate <> 0D then
                AvailCalcOverview.SetRange(Date, StartDate, EndDate)
            else
                AvailCalcOverview.SetRange(Date, StartDate, DMY2Date(31, 12, 9999));
        if LocationFilter <> '' then
            AvailCalcOverview.SetFilter("Location Code", LocationFilter);
        if VariantFilter <> '' then
            AvailCalcOverview.SetFilter("Variant Code", VariantFilter);
    end;

    procedure InitTempTable()
    var
        AvailCalcOverviewFilters: Record "Availability Calc. Overview";
    begin
        if not CalculationOfDemand then
            exit;
        AvailCalcOverviewFilters.Copy(Rec);
        ApplyUserFilters(TempAvailCalcOverview);
        CalcAvailOverview.SetParameters(DemandType, DemandNo);
        CalcAvailOverview.Run(TempAvailCalcOverview);
        TempAvailCalcOverview.Reset();
        Rec.Reset();
        Rec.DeleteAll();
        if TempAvailCalcOverview.Find('-') then
            repeat
                if TempAvailCalcOverview.Level = 0 then begin
                    Rec := TempAvailCalcOverview;
                    Rec.Insert();
                end;
            until TempAvailCalcOverview.Next() = 0;
        Rec.CopyFilters(AvailCalcOverviewFilters);
        ExpandAll(TempAvailCalcOverview);
        Rec.Copy(AvailCalcOverviewFilters);
        if Rec.Find('-') then;
        IsCalculated := true;
    end;

    local procedure ExpandAll(var AvailCalcOverview: Record "Availability Calc. Overview")
    var
        AvailCalcOverviewFilters: Record "Availability Calc. Overview";
        Window: Dialog;
    begin
        Window.Open(Text020 + Text021);
        AvailCalcOverviewFilters.Copy(Rec);

        // Set Filters
        Window.Update(1, Text022);
        AvailCalcOverview.Reset();
        AvailCalcOverview.DeleteAll();
        ApplyUserFilters(AvailCalcOverview);
        CalcAvailOverview.SetParameters(DemandType, DemandNo);

        // Fetching Items
        Window.Update(1, Text023);
        Rec.Reset();
        if Rec.Find('+') then
            repeat
                if Rec.Type = Rec.Type::Item then begin
                    AvailCalcOverview := Rec;
                    if CalcAvailOverview.EntriesExist(AvailCalcOverview) then begin
                        AvailCalcOverview.Insert();
                        CalcAvailOverview.CalculateItem(AvailCalcOverview);
                    end;
                end;
            until Rec.Next(-1) = 0;

        // Fetch Entries in Dates
        Window.Update(1, Text025);
        if AvailCalcOverview.Find('+') then
            repeat
                Rec := AvailCalcOverview;
                if AvailCalcOverview.Type = Rec.Type::"As of Date" then
                    CalcAvailOverview.CalculateDate(AvailCalcOverview);
                AvailCalcOverview := Rec;
            until AvailCalcOverview.Next(-1) = 0;

        // Copy to View Table
        Window.Update(1, Text026);
        Rec.DeleteAll();
        if AvailCalcOverview.Find('-') then
            repeat
                Rec := AvailCalcOverview;
                Rec.Insert();
            until AvailCalcOverview.Next() = 0;

        Window.Close();
        Rec.Copy(AvailCalcOverviewFilters);
        if Rec.Find('-') then;
    end;

    procedure SetRecFilters()
    begin
        Rec.Reset();
        Rec.SetCurrentKey("Item No.", Date, "Attached to Entry No.", Type);
        CurrPage.Update(false);
    end;

#if not CLEAN25
    [Obsolete('Replaced by SetParameters() with enum', '25.0')]
    procedure Initialize(NewStartDate: Date; NewDemandType: Integer; NewDemandNo: Code[20]; NewItemNo: Code[20]; NewLocationFilter: Code[250])
    begin
        SetParameters(NewStartDate, TransformDemandTypeOptionToEnum(NewDemandType), NewDemandNo, NewItemNo, NewLocationFilter);
    end;

    [Obsolete('Temporary procedure used by Initialize()', '25.0')]
    local procedure TransformDemandTypeOptionToEnum(DemandTypeOption: Option): Enum "Demand Order Source Type"
    begin
        case DemandTypeOption of
            0: // " "
                exit("Demand Order Source Type"::"All Demands");
            1: // Sales
                exit("Demand Order Source Type"::"Sales Demand");
            2: // Production
                exit("Demand Order Source Type"::"Production Demand");
            3: // Jobs
                exit("Demand Order Source Type"::"Job Demand");
            4: // Services 
                exit("Demand Order Source Type"::"Service Demand");
            5: // Assembly
                exit("Demand Order Source Type"::"Assembly Demand");
        end;
    end;

    [Obsolete('Temporary procedure used by DemandNoCtrl - OnLookup for event publisher OnBeforeLookupDemandNo()', '25.0')]
    local procedure TransformDemandTypeEnumToOption(DemandTypeEnum: Enum "Demand Order Source Type"): Integer
    begin
        case DemandTypeEnum of
            DemandTypeEnum::"All Demands":
                exit(0); // " "
            DemandTypeEnum::"Sales Demand":
                exit(1); // Sales
            DemandTypeEnum::"Production Demand":
                exit(2); // Production
            DemandTypeEnum::"Job Demand":
                exit(3); // Jobs
            DemandTypeEnum::"Service Demand":
                exit(4); // Services
            DemandTypeEnum::"Assembly Demand":
                exit(5); // Assembly
        end;
    end;
#endif

    procedure SetParameters(NewStartDate: Date; NewDemandType: Enum "Demand Order Source Type"; NewDemandNo: Code[20]; NewItemNo: Code[20]; NewLocationFilter: Code[250])
    begin
        StartDate := NewStartDate;
        DemandType := NewDemandType;
        DemandNo := NewDemandNo;
        ItemFilter := NewItemNo;
        LocationFilter := NewLocationFilter;
        MatchCriteria := true;
    end;

    local procedure SourceTypeTextOnFormat(var Text: Text)
    begin
        SourceTypeHideValue := false;
        case Rec."Source Type" of
            DATABASE::"Item Ledger Entry":
                Text := Text004;
            else begin
                OnSourceTypeTextOnFormat(Rec, Text);
                if Text = '' then
                    SourceTypeHideValue := true;
            end;
        end;
    end;

    procedure SetCalculationParameter(CalculateDemandParam: Boolean)
    begin
        CalculationOfDemand := CalculateDemandParam;
    end;

#if not CLEAN25 
    [Obsolete('Replaced by OnBeforeOnLookupDemandNo() with enum', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDemandNo(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; DemandType: Option; var Result: Boolean; var IsHandled: Boolean; var Text: Text)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnLookupDemandNo(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; DemandType: Enum "Demand Order Source Type"; var Result: Boolean; var IsHandled: Boolean; var Text: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupDemandNo(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; DemandType: Enum "Demand Order Source Type"; var Result: Boolean; var Text: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSourceTypeTextOnFormat(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Text: Text)
    begin
    end;
}

