// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;

page 5530 "Item Availability by Event"
{
    Caption = 'Item Availability by Event';
    DataCaptionExpression = GetPageCaption();
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = "Inventory Page Data";
    SourceTableTemporary = true;
    SourceTableView = sorting("Period Start", "Line No.")
                      order(ascending);

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(ItemNo; ItemNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item No.';
                    TableRelation = Item;
                    ToolTip = 'Specifies the item that availability is shown for.';

                    trigger OnValidate()
                    begin
                        ValidateItemNo();
                    end;
                }
                field(VariantFilter; VariantFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant Filter';
                    ToolTip = 'Specifies item variants that availability is shown for.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemVariant: Record "Item Variant";
                        ItemVariants: Page "Item Variants";
                    begin
                        ItemVariant.SetFilter("Item No.", ItemNo);
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
                        if VariantFilter <> Item.GetFilter("Variant Filter") then begin
                            Item.SetRange("Variant Filter");
                            if VariantFilter <> '' then
                                Item.SetFilter("Variant Filter", VariantFilter);
                            InitAndCalculatePeriodEntries();
                            CurrPage.Update(false);
                        end;
                    end;
                }
                field(LocationFilter; LocationFilter)
                {
                    ApplicationArea = Location;
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies the location that availability is shown for.';

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
                        if LocationFilter <> Item.GetFilter("Location Filter") then begin
                            Item.SetRange("Location Filter");
                            if LocationFilter <> '' then
                                Item.SetFilter("Location Filter", LocationFilter);
                            InitAndCalculatePeriodEntries();
                            CurrPage.Update(false);
                        end;
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    Importance = Promoted;
                    OptionCaption = 'Day,Week,Month,Quarter,Year';
                    ToolTip = 'Specifies which time intervals to group and view the availability figures.';

                    trigger OnValidate()
                    begin
                        CalculatePeriodEntries();
                    end;
                }
                field(LastUpdateTime; LastUpdateTime)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Updated';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies when the availability figures in the Item Availability by Event window were last updated.';
                }
                field(ForecastName; ForecastName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Forecast Name';
                    Importance = Promoted;
                    TableRelation = Microsoft.Manufacturing.Forecast."Production Forecast Name";
                    ToolTip = 'Specifies a demand forecast you want to include as demand, when showing the item''s availability figures.';

                    trigger OnValidate()
                    begin
                        InitAndCalculatePeriodEntries();
                    end;
                }
                field(IncludePlanningSuggestions; IncludePlanningSuggestions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include Planning Suggestions';
                    ToolTip = 'Specifies whether to include suggestions in planning or requisition worksheets, in the availability figures.';

                    trigger OnValidate()
                    begin
                        if IncludePlanningSuggestions then
                            IncludeBlanketOrders := true;

                        InitAndCalculatePeriodEntries();
                    end;
                }
                field(IncludeBlanketOrders; IncludeBlanketOrders)
                {
                    ApplicationArea = Suite;
                    Caption = 'Include Blanket Sales Orders';
                    Editable = not IncludePlanningSuggestions;
                    ToolTip = 'Specifies that anticipated demand from blanket sales orders is included in availability figures.';

                    trigger OnValidate()
                    begin
                        InitAndCalculatePeriodEntries();
                    end;
                }
            }
            repeater(Control5)
            {
                Editable = false;
                IndentationColumn = Rec.Level;
                IndentationControls = Description;
                ShowAsTree = true;
                TreeInitialState = CollapseAll;
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the first date in the selected period where a supply or demand event occurs that changes the item''s availability figures.';
                }
                field("Period Start"; Rec."Period Start")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies on which date the period starts, such as the first day of March, if the period is Month.';
                    Visible = true;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the description of the availability line.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the type of the source document or source line.';
                }
                field(Source; Rec.Source)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies which type of document or line the availability figure is based on.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the number of the document that the availability figure is based on.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the location of the demand document, from which the Item Availability by Event window was opened.';
                    Visible = false;
                }
                field("Gross Requirement"; Rec."Gross Requirement")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the item''s total demand.';
                }
                field("Reserved Requirement"; Rec."Reserved Requirement")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the quantity of the item that is reserved from requirement.';
                }
                field("Scheduled Receipt"; Rec."Scheduled Receipt")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the sum of items on existing supply orders.';
                }
                field("Reserved Receipt"; Rec."Reserved Receipt")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the quantity of the item that is reserved from receipt.';
                }
                field("Remaining Quantity (Base)"; Rec."Remaining Quantity (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the difference between the finished quantity and the planned quantity on the production order.';
                    Visible = false;
                }
                field("Projected Inventory"; Rec."Projected Inventory")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Projected Available Balance';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Enabled = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the item''s availability. This quantity includes all known supply and demand but does not include anticipated demand from demand forecasts or blanket sales orders or suggested supplies from planning or requisition worksheets.';
                }
                field(Forecast; Rec.Forecast)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the quantity that is demanded on the demand forecast that the availability figure is based on.';
                }
                field("Forecasted Projected Inventory"; Rec."Forecasted Projected Inventory")
                {
                    ApplicationArea = Basic, Suite;
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the item''s inventory, including anticipated demand from demand forecasts or blanket sales orders.';
                }
                field("Remaining Forecast"; Rec."Remaining Forecast")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the quantity that remains on the demand forecast, after the forecast quantity on the availability line has been consumed.';
                }
                field("Action Message"; Rec."Action Message")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the action message of the planning or requisition line that this availability figure is based on.';
                }
                field("Action Message Qty."; Rec."Action Message Qty.")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the quantity that is suggested in the planning or requisition line that this availability figure is based on.';
                }
                field("Suggested Projected Inventory"; Rec."Suggested Projected Inventory")
                {
                    ApplicationArea = Basic, Suite;
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the item''s inventory, including the suggested supplies that occur in planning or requisition worksheet lines.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Recalculate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Recalculate';
                Image = Refresh;
                ToolTip = 'Update the availability numbers with any changes made by other users.';

                trigger OnAction()
                begin
                    InitAndCalculatePeriodEntries();
                end;
            }
            action("Show Document")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Document';
                Enabled = EnableShowDocumentAction;
                Image = View;
                ShortCutKey = 'Shift+F7';
                ToolTip = 'Open the document that the selected line exists on.';

                trigger OnAction()
                begin
                    CalcInventoryPageData.ShowDocument(Rec."Source Document ID");
                end;
            }
        }
        area(navigation)
        {
            group("&Item")
            {
                Caption = '&Item';
                Image = Item;
                group("&Item Availability by")
                {
                    Caption = '&Item Availability by';
                    Image = ItemAvailability;
                    action(Period)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'Show the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            PAGE.Run(PAGE::"Item Availability by Periods", Item, Item."No.");
                        end;
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                        trigger OnAction()
                        begin
                            PAGE.Run(PAGE::"Item Availability by Variant", Item, Item."No.");
                        end;
                    }
                    action(Location)
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Location;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            PAGE.Run(PAGE::"Item Availability by Location", Item, Item."No.");
                        end;
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailabilityFromItem(Item, "Item Availability Type"::BOM);
                        end;
                    }
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Recalculate_Promoted; Recalculate)
                {
                }
                actionref("Show Document_Promoted"; "Show Document")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Emphasize := EmphasizeLine();
        EnableShowDocumentAction := HasSourceDocument();
    end;

    trigger OnOpenPage()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        OnBeforeOnOpenPage(IncludeBlanketOrders, PeriodType, Item, LocationFilter);
        if ItemIsSet() then
            InitAndCalculatePeriodEntries()
        else
            InitItemRequestFields();
        if InventorySetup.ReadPermission then begin
            InventorySetup.Get();
            ForecastName := InventorySetup."Current Demand Forecast";
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            SelectedDate := Rec."Period Start";
    end;

    var
        Item: Record Item;
        CalcInventoryPageData: Codeunit "Calc. Inventory Page Data";
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        ForecastName: Code[10];
        LastUpdateTime: DateTime;
        SelectedDate: Date;
        IncludePlanningSuggestions: Boolean;
        IncludeBlanketOrders: Boolean;
        Emphasize: Boolean;
        EnableShowDocumentAction: Boolean;

    protected var
        TempInvtPageData: Record "Inventory Page Data" temporary;
        ItemNo: Code[20];
        LocationFilter: Text;
        VariantFilter: Text;
        PeriodType: Option Day,Week,Month,Quarter,Year;

    protected procedure InitAndCalculatePeriodEntries()
    begin
        Initialize();
        CalculatePeriodEntries();
    end;

    local procedure CalculatePeriodEntries()
    begin
        TempInvtPageData.Reset();
        TempInvtPageData.DeleteAll();
        TempInvtPageData.SetCurrentKey("Period Start", "Line No.");
        CalcInventoryPageData.CreatePeriodEntries(TempInvtPageData, PeriodType);

        Rec.Reset();
        Rec.DeleteAll();
        Rec.SetCurrentKey("Period Start", "Line No.");

        TempInvtPageData.SetRange(Level, 0);
        if TempInvtPageData.Find('-') then
            repeat
                CalcInventoryPageData.DetailsForPeriodEntry(TempInvtPageData, true);
                CalcInventoryPageData.DetailsForPeriodEntry(TempInvtPageData, false);
            until TempInvtPageData.Next() = 0;
        TempInvtPageData.SetRange(Level);

        ExpandAll();
    end;

    local procedure Initialize()
    var
        IsHandled: Boolean;
    begin
        Item.SetRange("Drop Shipment Filter", false);
        IsHandled := false;
        OnBeforeInitialize(Item, ForecastName, IncludeBlanketOrders, IncludePlanningSuggestions, IsHandled);
        if not IsHandled then
            CalcInventoryPageData.Initialize(Item, ForecastName, IncludeBlanketOrders, 0D, IncludePlanningSuggestions);
        LastUpdateTime := CurrentDateTime;
    end;

    local procedure ExpandAll()
    var
        RunningInventory: Decimal;
        RunningInventoryForecast: Decimal;
        RunningInventoryPlan: Decimal;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        Rec.SetCurrentKey("Period Start", "Line No.");

        if TempInvtPageData.Find('-') then
            repeat
                Rec := TempInvtPageData;
                Rec.UpdateInventorys(RunningInventory, RunningInventoryForecast, RunningInventoryPlan);
                Rec.Insert();
            until TempInvtPageData.Next() = 0;

        if Rec.Find('-') then;
    end;

    local procedure EmphasizeLine(): Boolean
    begin
        exit(Rec.Level = 0);
    end;

    local procedure HasSourceDocument(): Boolean
    begin
        exit((Rec.Level > 0) and (Format(Rec."Source Document ID") <> ''));
    end;

    local procedure InitItemRequestFields()
    begin
        Clear(Item);
        Clear(ItemNo);
        Clear(LocationFilter);
        Clear(VariantFilter);
        Clear(LastUpdateTime);
    end;

    local procedure UpdateItemRequestFields(var Item: Record Item)
    begin
        ItemNo := Item."No.";
        LocationFilter := '';
        if Item.GetFilter("Location Filter") <> '' then
            LocationFilter := Item.GetFilter("Location Filter");
        VariantFilter := '';
        if Item.GetFilter("Variant Filter") <> '' then
            VariantFilter := Item.GetFilter("Variant Filter");
    end;

    local procedure ItemIsSet(): Boolean
    begin
        exit(Item."No." <> '');
    end;

    local procedure GetPageCaption(): Text[250]
    begin
        exit(StrSubstNo('%1 %2', Item."No.", Item.Description));
    end;

    procedure SetItem(var NewItem: Record Item)
    begin
        CheckItemRecordIsAccessible(NewItem);
        Item.Copy(NewItem);
        UpdateItemRequestFields(Item);
        OnAfterSetItem(Item);
    end;

    local procedure CheckItemRecordIsAccessible(var NewItem: Record Item)
    var
        CheckItem: Record Item;
    begin
        if (NewItem."No." <> '') then begin
            CheckItem.SetLoadFields("No.");
            CheckItem.Get(NewItem."No.");
        end;
    end;

    procedure SetForecastName(NewForcastName: Code[10])
    begin
        ForecastName := NewForcastName;
    end;

    procedure SetIncludePlan(NewIncludePlanningSuggestions: Boolean)
    begin
        IncludePlanningSuggestions := NewIncludePlanningSuggestions;
    end;

    procedure GetSelectedDate(): Date
    begin
        exit(SelectedDate);
    end;

    protected procedure ValidateItemNo()
    begin
        if ItemNo <> Item."No." then begin
            Item.Get(ItemNo);
            if LocationFilter <> '' then
                Item.SetFilter("Location Filter", LocationFilter);
            if VariantFilter <> '' then
                Item.SetFilter("Variant Filter", VariantFilter);
            OnValidateItemNoOnBeforeInitAndCalculatePeriodEntries(Item);
            InitAndCalculatePeriodEntries();
            CurrPage.Update(false);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnBeforeInitAndCalculatePeriodEntries(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItem(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnOpenPage(var IncludeBlanketOrders: Boolean; var PeriodType: Option; var Item: Record Item; var LocationFilter: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInitialize(var Item: Record Item; var ForecastName: Code[10]; var IncludeBlanketOrders: Boolean; var IncludePlanningSuggestions: Boolean; var IsHandled: Boolean)
    begin
    end;
}

