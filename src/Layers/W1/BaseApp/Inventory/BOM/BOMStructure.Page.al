// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM.Tree;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

page 5870 "BOM Structure"
{
    Caption = 'BOM Structure';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "BOM Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            grid(Option)
            {
                Caption = 'Option';
                field(ItemFilter; ItemFilter)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies the items that are shown in the BOM Structure window.';

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
                        RefreshPage();
                    end;
                }
            }
            repeater(Group)
            {
                Caption = 'Lines';
                IndentationColumn = Rec.Indentation;
                ShowAsTree = true;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the item''s position in the BOM structure. Lower-level items are indented under their parents.';
                }
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
                    Style = Strong;
                    StyleExpr = IsParentExpr;
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
                    ToolTip = 'Specifies if the BOM line has setup or data issues.';

                    trigger OnDrillDown()
                    begin
                        if HasWarning then
                            ShowWarnings();
                    end;
                }
                field("Low-Level Code"; Rec."Low-Level Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s level in the BOM structure.';
                    Visible = false;
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
                field("Lead-Time Offset"; Rec."Lead-Time Offset")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total number of days that are required to assemble or produce the item.';
                    Visible = false;
                }
                field("Safety Lead Time"; Rec."Safety Lead Time")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies any safety lead time that is defined for the item.';
                    Visible = false;
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how long it takes to replenish the item, by purchase, assembly, or production.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
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
                    ApplicationArea = Location;
                    Caption = 'Location';
                    Image = Warehouse;
                    ToolTip = 'View the actual and projected quantity of the item per location.';

                    trigger OnAction()
                    begin
                        ShowItemAvailability("Item Availability Type"::Location);
                    end;
                }
                action(Lot)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot';
                    Image = LotInfo;
                    RunObject = Page "Item Availability by Lot No.";
                    RunPageLink = "No." = field("No."),
                            "Location Filter" = field("Location Code"),
                            "Variant Filter" = field("Variant Code");
                    ToolTip = 'View the current and projected quantity of the item in each lot.';
                }
                action("BOM Level")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'BOM Level';
                    Image = BOMLevel;
                    ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                    trigger OnAction()
                    begin
                        ShowItemAvailability("Item Availability Type"::BOM);
                    end;
                }
            }
        }
        area(processing)
        {
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
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Show Warnings_Promoted"; "Show Warnings")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Item Availability by', Comment = 'Generated from the PromotedActionCategories property index 3.';

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
                actionref(Lot_Promoted; Lot)
                {
                }
                actionref("BOM Level_Promoted"; "BOM Level")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        DummyBOMWarningLog: Record "BOM Warning Log";
    begin
        IsParentExpr := not Rec."Is Leaf";

        HasWarning := not Rec.IsLineOk(false, DummyBOMWarningLog);

        if Rec.Type = Rec.Type::Item then
            Rec."Low-Level Code" := Rec.Indentation;
    end;

    trigger OnOpenPage()
    begin
        RefreshPage();
    end;

    var
        Item: Record Item;
        SourceRecordVar: Variant;
        IsParentExpr: Boolean;
        HasWarning: Boolean;
        CouldNotFindBOMLevelsErr: Label 'Could not find items with BOM levels.';
#pragma warning disable AA0074
        Text001: Label 'There are no warnings.';
#pragma warning restore AA0074

    protected var
        ItemFilter: Code[250];
        ShowBy: Enum "BOM Structure Show By";

    procedure InitItem(var NewItem: Record Item)
    begin
        Item := NewItem;
        ItemFilter := Item."No.";
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

    procedure RefreshPage()
    var
#if not CLEAN27
        AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header";
        ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line";
#endif
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
        RaiseError: Boolean;
        ErrorText: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN27
        case ShowBy of
            ShowBy::Assembly:
                AssemblyHeader := SourceRecordVar;
            ShowBy::Production:
                ProdOrderLine := SourceRecordVar;
        end;
        OnBeforeGenerateBOMTree(Rec, Item, AssemblyHeader, ProdOrderLine, ShowBy.AsInteger(), ItemFilter, IsHandled);
#endif
        OnBeforeRefreshPage(Rec, Item, SourceRecordVar, ShowBy, ItemFilter, IsHandled);
        if IsHandled then
            exit;

        Item.SetFilter("No.", ItemFilter);
        Item.SetRange("Date Filter", 0D, WorkDate());
        CalculateBOMTree.SetItemFilter(Item);
        case ShowBy of
            ShowBy::Item:
                begin
                    Item.FindFirst();
                    RaiseError := (not Item.HasBOM()) and (not Item.HasRoutingNo());
                    ErrorText := CouldNotFindBOMLevelsErr;
                    OnRefreshPageOnBeforeRaiseError(Item, RaiseError, ErrorText);
                    if RaiseError then
                        Error(ErrorText);
                    CalculateBOMTree.GenerateTreeForManyItems(Item, Rec, "BOM Tree Type"::" ");
                end;
            else
                CalculateBOMTree.GenerateTreeForSource(SourceRecordVar, Rec, "BOM Tree Type"::" ", ShowBy, WorkDate());
        end;
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

    local procedure ShowItemAvailability(AvailType: Enum "Item Availability Type")
    var
        ItemForShowAvailability: Record Item;
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
    begin
        Rec.TestField(Type, Rec.Type::Item);

        ItemForShowAvailability.Get(Rec."No.");
        ItemForShowAvailability.SetRange("No.", Rec."No.");
        ItemForShowAvailability.SetRange("Date Filter", 0D, Rec."Needed by Date");
        ItemForShowAvailability.SetFilter("Variant Filter", Rec."Variant Code");
        if ShowBy <> ShowBy::Item then
            ItemForShowAvailability.SetFilter("Location Filter", Rec."Location Code");

        ItemAvailabilityFormsMgt.ShowItemAvailabilityFromItem(ItemForShowAvailability, AvailType);
    end;

#if not CLEAN27
    [Obsolete('Replaced by event OnBeforeRefreshPage', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateBOMTree(var BOMBuffer: Record "BOM Buffer"; var Item: Record Item; var AsmHeader: Record Microsoft.Assembly.Document."Assembly Header"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ShowBy: Integer; ItemFilter: Code[250]; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRefreshPage(var BOMBuffer: Record "BOM Buffer"; var Item: Record Item; var SourceRecordVar: Variant; ShowBy: Enum "BOM Structure Show By"; ItemFilter: Code[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnRefreshPageOnBeforeRaiseError(var Item: Record Item; var RaiseError: Boolean; var ErrorText: Text)
    begin
    end;
}

