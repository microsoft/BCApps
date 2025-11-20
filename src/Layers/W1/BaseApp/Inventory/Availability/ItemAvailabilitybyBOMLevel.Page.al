// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.BOM.Tree;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Reports;

page 5871 "Item Availability by BOM Level"
{
    Caption = 'Item Availability by BOM Level';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "BOM Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Option)
            {
                Caption = 'Option';
                field(ItemFilter; ItemFilter)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies the item you want to show availability information for.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Item: Record Item;
                        ItemList: Page "Item List";
                    begin
                        ItemList.SetTableView(Item);
                        ItemList.LookupMode := true;
                        if ItemList.RunModal() = Action::LookupOK then begin
                            ItemList.GetRecord(Item);
                            Text := Item."No.";
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                        RefreshPage();
                    end;
                }
                field(LocationFilter; LocationFilter)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies the location that you want to show item availability for.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Location: Record Location;
                        LocationList: Page "Location List";
                    begin
                        LocationList.SetTableView(Location);
                        LocationList.LookupMode := true;
                        if LocationList.RunModal() = Action::LookupOK then begin
                            LocationList.GetRecord(Location);
                            Text := Location.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                        RefreshPage();
                    end;
                }
                field(VariantFilter; VariantFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant Filter';
                    ToolTip = 'Specifies the item variant you want to show availability for.';

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
                        RefreshPage();
                    end;
                }
                field(DemandDate; DemandDate)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Demand Date';
                    ToolTip = 'Specifies the date when you want to potentially make the parents, or top items, shown in the Item Availability by BOM Level window.';

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                        RefreshPage();
                    end;
                }
                field(IsCalculated; IsCalculated)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Calculated';
                    Editable = false;
                    ToolTip = 'Specifies that the low-level code of the item on the line has been calculated.';
                }
                field(ShowTotalAvailability; ShowTotalAvailability)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Show Total Availability';
                    ToolTip = 'Specifies whether the Item Availability by BOM Level window shows availability of all items, including the potential availability of parents.';

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                        RefreshPage();
                    end;
                }
            }
            repeater(Group)
            {
                Caption = 'Lines';
                IndentationColumn = Rec.Indentation;
                ShowAsTree = true;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = IsParentExpr;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    ToolTip = 'Specifies the item''s description.';
                }
                field(HasWarning; HasWarning)
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Caption = 'Warning';
                    Editable = false;
                    Style = Attention;
                    StyleExpr = HasWarning;
                    ToolTip = 'Specifies if the BOM line has setup or data issues. Choose the field to open the BOM Warning Log window to see a description of the issue.';

                    trigger OnDrillDown()
                    begin
                        if HasWarning then
                            ShowWarnings();
                    end;
                }
                field(Bottleneck; Rec.Bottleneck)
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Specifies which item in the BOM structure restricts you from making a larger quantity than what is shown in the Able to Make Top Item field.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant code that you entered in the Variant Filter field in the Item Availability by BOM Level window.';
                    Visible = false;
                }
                field("Qty. per Parent"; Rec."Qty. per Parent")
                {
                    ApplicationArea = Assembly;
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the component are required to assemble or produce one unit of the parent.';
                }
                field("Qty. per Top Item"; Rec."Qty. per Top Item")
                {
                    ApplicationArea = Assembly;
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the component are required to assemble or produce one unit of the top item.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Replenishment System"; Rec."Replenishment System")
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    ToolTip = 'Specifies the item''s replenishment system.';
                }
                field("Available Quantity"; Rec."Available Quantity")
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item on the line are available, regardless of how many parents you can make with the item.';
                }
                field("Unused Quantity"; Rec."Unused Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the part of the item''s total availability that is not required to make the quantities that are shown in the fields.';
                    Visible = false;
                }
                field("Needed by Date"; Rec."Needed by Date")
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    ToolTip = 'Specifies when the item must be available to make the parent or top item.';
                }
                field("Able to Make Parent"; Rec."Able to Make Parent")
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the BOM item on the collapsible line above it can be assembled or produced.';
                }
                field("Able to Make Top Item"; Rec."Able to Make Top Item")
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the BOM item on the top line can be assembled or produced.';
                }
                field("Gross Requirement"; Rec."Gross Requirement")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the total demand for the item.';
                    Visible = false;
                }
                field("Scheduled Receipts"; Rec."Scheduled Receipts")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item are inbound on orders.';
                    Visible = false;
                }
                field("Safety Lead Time"; Rec."Safety Lead Time")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies any safety lead time that is defined for the item.';
                    Visible = false;
                }
                field("Rolled-up Lead-Time Offset"; Rec."Rolled-up Lead-Time Offset")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the cumulative lead time of components under a parent item.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
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
                    action("Event")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ShowItemAvailability("Item Availability Type"::"Event");
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            ShowItemAvailability("Item Availability Type"::Period);
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
                            ShowItemAvailability("Item Availability Type"::Variant);
                        end;
                    }
                    action(Location)
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            ShowItemAvailability("Item Availability Type"::Location);
                        end;
                    }
                }
            }
        }
        area(processing)
        {
            action("Previous Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    DemandDate := CalcDate('<-1D>', DemandDate);
                    RefreshPage();
                end;
            }
            action("Next Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Period';
                Image = NextRecord;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    DemandDate := CalcDate('<+1D>', DemandDate);
                    RefreshPage();
                end;
            }
            action("Show Warnings")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Warnings';
                Image = ErrorLog;
                ToolTip = 'View details about bottlenecks.';

                trigger OnAction()
                begin
                    ShowWarningsForAllLines();
                end;
            }
            action("Item Card")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item';
                Image = Item;
                RunObject = Page "Item Card";
                RunPageLink = "No." = field("No.");
                RunPageView = sorting("No.");
                ShortcutKey = 'Shift+F7';
                ToolTip = 'View detailed information for the child item.';
            }
        }
        area(reporting)
        {
            action("Item - Able to Make (Timeline)")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item - Able to Make (Timeline)';
                Image = Trendscape;
                ToolTip = 'View five key availability figures over time for the selected parent item. The figures change according to expected supply and demand events and to supply that is based on available components that can be assembled or produced. You can use the report to see whether you can fulfill a sales order for an item on a specified date by looking at its current availability in combination with the potential quantities that its components can supply if an assembly order were started.';

                trigger OnAction()
                begin
                    ShowAbleToMakeTimeline();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Previous Period_Promoted"; "Previous Period")
                {
                }
                actionref("Next Period_Promoted"; "Next Period")
                {
                }
                actionref("Show Warnings_Promoted"; "Show Warnings")
                {
                }
                actionref("Item Card_Promoted"; "Item Card")
                {
                }
            }
            group("Category_Item Availability by")
            {
                Caption = 'Item Availability by';

                actionref(Event_Promoted; "Event")
                {
                }
                actionref(Period_Promoted; Period)
                {
                }
                actionref(Variant_Promoted; Variant)
                {
                }
                actionref(Location_Promoted; Location)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Item - Able to Make (Timeline)_Promoted"; "Item - Able to Make (Timeline)")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        DummyBOMWarningLog: Record "BOM Warning Log";
    begin
        IsParentExpr := not Rec."Is Leaf";

        HasWarning := not Rec.IsLineOk(false, DummyBOMWarningLog);
    end;

    trigger OnOpenPage()
    begin
        ShowTotalAvailability := true;
        if DemandDate = 0D then
            DemandDate := WorkDate();
        OnOpenPageOnBeforeRefreshPage(Rec);
        RefreshPage();
    end;

    var
        IsParentExpr: Boolean;
        HasWarning: Boolean;
#pragma warning disable AA0074
        Text000: Label 'Could not find items with BOM levels.';
        Text001: Label 'There are no warnings.';
#pragma warning restore AA0074

    protected var
        Item: Record Item;
        SourceRecordVar: Variant;
        ItemFilter: Code[250];
        LocationFilter: Code[250];
        VariantFilter: Code[250];
        DemandDate: Date;
        ShowTotalAvailability: Boolean;
        IsCalculated: Boolean;
        ShowBy: Enum "BOM Structure Show By";

    procedure InitItem(var NewItem: Record Item)
    begin
        Item.Copy(NewItem);
        ItemFilter := Item."No.";
        VariantFilter := Item.GetFilter("Variant Filter");
        LocationFilter := Item.GetFilter("Location Filter");
        ShowBy := ShowBy::Item;
    end;

    procedure InitSource(NewSourceRecordVar: Variant; NewShowBy: Enum "BOM Structure Show By")
    begin
        SourceRecordVar := NewSourceRecordVar;
        ShowBy := NewShowBy;
    end;

#if not CLEAN27
    [Obsolete('Replaced by procedure InitSource()', '27.0')]
    procedure InitAsmOrder(NewAsmHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
        SourceRecordVar := NewAsmHeader;
        ShowBy := ShowBy::Assembly;
    end;
#endif

#if not CLEAN27
    [Obsolete('Replaced by procedure InitSource()', '27.0')]
    procedure InitProdOrder(NewProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
        SourceRecordVar := NewProdOrderLine;
        ShowBy := ShowBy::Production;
    end;
#endif

    procedure InitDate(NewDemandDate: Date)
    begin
        DemandDate := NewDemandDate;
    end;

    protected procedure RefreshPage()
    var
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
        IsHandled: Boolean;
    begin
        Item.SetRange("Date Filter", 0D, DemandDate);
        Item.SetFilter("Location Filter", LocationFilter);
        Item.SetFilter("Variant Filter", VariantFilter);
        Item.SetFilter("No.", ItemFilter);
        CalculateBOMTree.SetItemFilter(Item);

        CalculateBOMTree.SetShowTotalAvailability(ShowTotalAvailability);
        case ShowBy of
            ShowBy::Item:
                begin
                    Item.FindFirst();
                    IsHandled := false;
                    OnRefreshPageOnBeforeCheckItemHasBOM(Item, IsHandled);
                    if not IsHandled then
                        if not Item.HasBOM() then
                            Error(Text000);
                    CalculateBOMTree.GenerateTreeForManyItems(Item, Rec, "BOM Tree Type"::Availability);
                end;
            else
                CalculateBOMTree.GenerateTreeForSource(SourceRecordVar, Rec, "BOM Tree Type"::Availability, ShowBy, DemandDate);
        end;

        CurrPage.Update(false);
        IsCalculated := true;
    end;

    procedure GetSelectedDate(): Date
    begin
        exit(DemandDate);
    end;

    local procedure ShowItemAvailability(AvailType: Enum "Item Availability Type")
    var
        ItemForShowAvailability: Record Item;
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
    begin
        Rec.TestField(Rec.Type, Rec.Type::Item);

        ItemForShowAvailability.Get(Rec."No.");
        ItemForShowAvailability.SetRange("No.", Rec."No.");
        ItemForShowAvailability.SetRange("Date Filter", 0D, Rec."Needed by Date");
        ItemForShowAvailability.SetFilter("Location Filter", LocationFilter);
        ItemForShowAvailability.SetFilter("Variant Filter", Rec."Variant Code");
        if ShowBy <> ShowBy::Item then
            ItemForShowAvailability.SetFilter("Location Filter", Rec."Location Code");
        if Rec.Indentation = 0 then
            ItemForShowAvailability.SetFilter("Variant Filter", VariantFilter);

        ItemAvailabilityFormsMgt.ShowItemAvailabilityFromItem(ItemForShowAvailability, AvailType);
    end;

    local procedure ShowAbleToMakeTimeline()
    var
        ItemAbleToMake: Record Item;
        ItemAbleToMakeTimeline: Report "Item - Able to Make (Timeline)";
    begin
        Rec.TestField(Type, Rec.Type::Item);

        ItemAbleToMake.Get(Rec."No.");
        ItemAbleToMake.SetRange("No.", Rec."No.");

        if Rec.Indentation = 0 then
            case ShowBy of
                ShowBy::Item:
                    begin
                        ItemAbleToMake.SetFilter("Location Filter", LocationFilter);
                        ItemAbleToMake.SetFilter("Variant Filter", VariantFilter);
                    end;
                else
                    ItemAbleToMakeTimeline.InitSource(SourceRecordVar, ShowBy);
            end
        else begin
            ItemAbleToMake.SetFilter("Location Filter", LocationFilter);
            ItemAbleToMake.SetFilter("Variant Filter", VariantFilter);
        end;

        ItemAbleToMakeTimeline.SetTableView(ItemAbleToMake);
        ItemAbleToMakeTimeline.Initialize(Rec."Needed by Date", 0, 7, true);
        ItemAbleToMakeTimeline.Run();
    end;

    local procedure ShowWarnings()
    var
        TempBOMWarningLog: Record "BOM Warning Log" temporary;
    begin
        if Rec.IsLineOk(true, TempBOMWarningLog) then
            Message(Text001)
        else
            Page.RunModal(Page::"BOM Warning Log", TempBOMWarningLog);
    end;

    local procedure ShowWarningsForAllLines()
    var
        TempBOMWarningLog: Record "BOM Warning Log" temporary;
    begin
        if Rec.AreAllLinesOk(TempBOMWarningLog) then
            Message(Text001)
        else
            Page.RunModal(Page::"BOM Warning Log", TempBOMWarningLog);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRefreshPageOnBeforeCheckItemHasBOM(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeRefreshPage(var BOMBuffer: Record "BOM Buffer")
    begin
    end;
}

