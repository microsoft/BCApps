// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Sales.Customer;
using System.Utilities;

page 305 "Reservation Worksheet"
{
    ApplicationArea = Reservation;
    AutoSplitKey = true;
    Caption = 'Reservation Worksheet';
    DataCaptionFields = "Journal Batch Name";
    MultipleNewLines = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Reservation Wksh. Line";
    InsertAllowed = false;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            field(CurrentWkshBatchName; CurrentWkshBatchName)
            {
                Caption = 'Batch Name';
                ToolTip = 'Specifies the name of the journal batch of the reservation worksheet.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    ReservationWorksheetMgt.LookupName(CurrentWkshBatchName, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    ReservationWorksheetMgt.CheckName(CurrentWkshBatchName);
                    CurrentWkshBatchNameOnAfterValidate();
                end;
            }
            repeater(GroupName)
            {
                ShowCaption = false;

                field("Source Document"; ReservationWorksheetMgt.CreateSourceDocumentText(Rec))
                {
                    Caption = 'Source Document';
                    ToolTip = 'Specifies the source document on the demand line.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    Caption = 'Source Type';
                    ToolTip = 'Specifies the type of source document on the demand line.';
                    Visible = false;
                }
                field("Source ID"; Rec."Source ID")
                {
                    Caption = 'Source ID';
                    ToolTip = 'Specifies the number the source document on the demand line.';
                    Visible = false;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    Caption = 'Sell-to Customer No.';
                    ToolTip = 'Specifies the number of the customer, if any, on the demand line.';
                    Editable = false;
                    Visible = false;
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    Caption = 'Sell-to Customer Name';
                    ToolTip = 'Specifies the name of the customer, if any, on the demand line.';
                    Editable = false;
                }
                field("Demand Date"; Rec."Demand Date")
                {
                    Caption = 'Demand Date';
                    ToolTip = 'Specifies the demand date, which is the shipment date for sales orders and the due date for production components.';
                    Editable = false;
                }
                field(Accept; Rec.Accept)
                {
                    Caption = 'Accept';
                    ToolTip = 'Specifies if you want to reserve this demand line.';

                    trigger OnValidate()
                    begin
                        UpdateNeedsAttention();
                    end;
                }
                field("Item No."; Rec."Item No.")
                {
                    Caption = 'Item No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of the item on the demand line.';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies text that describes the entry.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    Caption = 'Description 2';
                    ToolTip = 'Specifies information in addition to the description.';
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies the variant of the item on the demand line.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    Caption = 'Location Code';
                    Editable = false;
                    ToolTip = 'Specifies the location code on the demand line.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                    Editable = false;
                    ToolTip = 'Specifies how each unit of the item is measured.';
                }
                field("Remaining Qty. to Reserve"; Rec."Remaining Qty. to Reserve")
                {
                    Caption = 'Remaining Qty. to Reserve';
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item on the demand line are not reserved from inventory.';
                    Style = Attention;
                    StyleExpr = NeedsAttention;
                }
                field("Qty. to Reserve"; Rec."Qty. to Reserve")
                {
                    Caption = 'Qty. to Reserve';
                    ToolTip = 'Specifies how many units of the item on the demand line you want to reserve.';
                    BlankZero = true;

                    trigger OnValidate()
                    begin
                        UpdateNeedsAttention();
                    end;
                }
                field("Available Qty. to Reserve"; Rec."Available Qty. to Reserve")
                {
                    Caption = 'Available Qty. to Reserve';
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item on the demand line can be reserved from inventory. This takes into account the Qty. to Reserve field on other demand lines with the same item number, location code, and variant code.';
                    Style = Ambiguous;
                    StyleExpr = NeedsAttention;
                }
            }
        }
        area(factboxes)
        {
            part(ReservationWkshFactbox; "Reservation Wksh. Factbox")
            {
                ApplicationArea = Reservation;
                SubPageLink = "Journal Batch Name" = field("Journal Batch Name"), "Line No." = field("Line No.");
            }
            part(ReservationWorksheetLog; "Reservation Wksh. Log Factbox")
            {
                ApplicationArea = Reservation;
                SubPageLink = "Journal Batch Name" = field("Journal Batch Name");
            }
            part(CustomerStatisticsFactbox; "Customer Statistics FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("Sell-to Customer No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Get Demand")
            {
                Caption = 'Get Demand';
                Image = GetSourceDoc;
                Ellipsis = true;
                ToolTip = 'Get demand lines from sales orders, production and assembly orders, service orders, and project usage.';

                trigger OnAction();
                begin
                    ReservationWorksheetMgt.CalculateDemand(CurrentWkshBatchName);
                    if Rec.FindFirst() then;
                end;
            }
            action("Accept Selected")
            {
                Caption = 'Accept';
                Image = SelectMore;
                ToolTip = 'Accept the selected demand lines.';

                trigger OnAction();
                var
                    ReservationWkshLine: Record "Reservation Wksh. Line";
                begin
                    CurrPage.SetSelectionFilter(ReservationWkshLine);
                    ReservationWorksheetMgt.AcceptSelected(ReservationWkshLine);
                    CurrPage.Update(false);
                end;
            }
            action(Reserve)
            {
                Caption = 'Make Reservation';
                Image = Reserve;
                Ellipsis = true;
                ToolTip = 'Reserve the selected demand lines for the quantity specified in the Qty. to Reserve field.';

                trigger OnAction();
                begin
                    ReservationWorksheetMgt.CarryOutAction(Rec);
                    CurrPage.Update(false);
                end;
            }
            action("Empty Batch")
            {
                Caption = 'Empty Batch';
                Image = Delete;
                ToolTip = 'Delete all demand lines from the reservation worksheet.';

                trigger OnAction();
                var
                    ReservationWkshBatch: Record "Reservation Wksh. Batch";
                    ConfirmManagement: Codeunit "Confirm Management";
                begin
                    if not ConfirmManagement.GetResponseOrDefault(EmptyBatchQst, false) then
                        exit;

                    ReservationWkshBatch.Get(CurrentWkshBatchName);
                    ReservationWkshBatch.EmptyBatch();
                    CurrPage.Update(false);
                end;
            }
            action("Allocate Quantity")
            {
                Caption = 'Allocate';
                Image = Allocate;
                ToolTip = 'Have the system populate Qty. to Reserve according to the allocation policy.';

                trigger OnAction();
                begin
                    ReservationWorksheetMgt.AllocateQuantity(Rec);
                    CurrPage.Update(false);
                end;
            }
            action("Delete Allocation")
            {
                Caption = 'Delete Allocation';
                Image = DeleteQtyToHandle;
                ToolTip = 'Have the system clear the value in the Qty. to Reserve field.';

                trigger OnAction();
                begin
                    ReservationWorksheetMgt.DeleteAllocation(Rec);
                    CurrPage.Update(false);
                end;
            }
            action("Allocation Policies")
            {
                Caption = 'Allocation Policies';
                Image = Allocations;
                Ellipsis = true;
                ToolTip = 'Set up allocation policies for the batch';

                trigger OnAction();
                var
                    AllocationPolicy: Record "Allocation Policy";
                begin
                    AllocationPolicy.SetRange("Journal Batch Name", CurrentWkshBatchName);
                    Page.Run(Page::"Allocation Policies", AllocationPolicy);
                end;
            }
        }
        area(Navigation)
        {
            action("Show Document")
            {
                Caption = 'Show Document';
                Image = ViewDocumentLine;
                Scope = Repeater;
                ToolTip = 'Show the source document for the demand line.';

                trigger OnAction();
                begin
                    ReservationWorksheetMgt.ShowSourceDocument(Rec);
                end;
            }
            action("Reservation Entries")
            {
                Caption = 'Reservation Entries';
                Image = ReservationLedger;
                ToolTip = 'Show the reservation entries for the demand line.';

                trigger OnAction();
                begin
                    ReservationWorksheetMgt.ShowReservationEntries(Rec);
                end;
            }
            group(ItemAvailabilityBy)
            {
                Caption = 'Item Availability by';
                Image = ItemAvailability;

                action(ByEvent)
                {
                    Caption = 'Event';
                    Image = "Event";
                    ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                        ItemAvailabilityByEvent: Page "Item Availability by Event";
                    begin
                        Item.Get(Rec."Item No.");
                        Item.SetRange("No.", Rec."Item No.");
                        Item.SetRange("Variant Filter", Rec."Variant Code");
                        Item.SetRange("Location Filter", Rec."Location Code");
                        Item.SetRange("Date Filter", 0D, Rec."Demand Date");
                        ItemAvailabilityByEvent.SetItem(Item);
                        if ItemAvailabilityByEvent.RunModal() = ACTION::LookupOK then;
                    end;
                }
                action(ByPeriod)
                {
                    Caption = 'Period';
                    Image = Period;
                    RunObject = Page "Item Availability by Periods";
                    RunPageLink = "No." = field("Item No."),
                                  "Location Filter" = field("Location Code"),
                                  "Variant Filter" = field("Variant Code");
                    ToolTip = 'Show the projected quantity of the item over time according to time periods, such as day, week, or month.';
                }
                action(ByVariant)
                {
                    Caption = 'Variant';
                    Image = ItemVariant;
                    RunObject = Page "Item Availability by Variant";
                    RunPageLink = "No." = field("Item No."),
                                  "Location Filter" = field("Location Code"),
                                  "Variant Filter" = field("Variant Code");
                    ToolTip = 'View how the inventory level of an item will develop over time according to the variant that you select.';
                }
                action(ByLocation)
                {
                    Caption = 'Location';
                    Image = Warehouse;
                    RunObject = Page "Item Availability by Location";
                    RunPageLink = "No." = field("Item No."),
                                  "Location Filter" = field("Location Code"),
                                  "Variant Filter" = field("Variant Code");
                    ToolTip = 'View the actual and projected quantity of the item per location.';
                }
                action(ByLot)
                {
                    Caption = 'Lot';
                    Image = LotInfo;
                    RunObject = Page "Item Availability by Lot No.";
                    RunPageLink = "No." = field("Item No."),
                                  "Location Filter" = field("Location Code"),
                                  "Variant Filter" = field("Variant Code");
                    ToolTip = 'View the current and projected quantity of the item in each lot.';
                }
                action(ByUOM)
                {
                    Caption = 'Unit of Measure';
                    Image = UnitOfMeasure;
                    RunObject = Page "Item Availability by UOM";
                    RunPageLink = "No." = field("Item No."),
                                  "Location Filter" = field("Location Code"),
                                  "Variant Filter" = field("Variant Code");
                    ToolTip = 'View the item''s availability by a unit of measure.';
                }
            }
            action("Create Transfer Order")
            {
                Caption = 'Create Transfer Order';
                Image = TransferOrder;
                ToolTip = 'Create a transfer order to move the item from another location to supply the demand line.';
                Ellipsis = true;
                Visible = false;

                trigger OnAction();
                var
                    TransferHeader: Record "Transfer Header";
                    LocationFromCode: Code[10];
                begin
                    LocationFromCode := GetSourceLocationForTransfer();
                    if not (LocationFromCode in ['', Rec."Location Code"]) then
                        ReservationWorksheetMgt.CreateTransferOrder(TransferHeader, Rec, LocationFromCode);

                    if not IsNullGuid(TransferHeader.SystemId) then
                        Page.Run(Page::"Transfer Order", TransferHeader);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Empty Batch_Promoted"; "Empty Batch") { }
                actionref("Retrieve Demand_Promoted"; "Get Demand") { }
            }
            group(Category_Category4)
            {
                Caption = 'Allocate';

                actionref("Allocate_Promoted"; "Allocate Quantity") { }
                actionref("Delete Allocation_Promoted"; "Delete Allocation") { }
                actionref("Allocation Policies_Promoted"; "Allocation Policies") { }
            }
            group(Category_Category6)
            {
                Caption = 'Reserve';

                actionref("Accept Selected_Promoted"; "Accept Selected") { }
                actionref("Reserve_Promoted"; Reserve) { }
            }
            group(Category_Category5)
            {
                Caption = 'Line';

                actionref("Show Document_Promoted"; "Show Document") { }
                actionref("Reservation Entries_Promoted"; "Reservation Entries") { }
                group("Item Availability by_Promoted")
                {
                    Caption = 'Item Availability by';

                    actionref(ByVariant_Promoted; ByVariant) { }
                    actionref(ByLocation_Promoted; ByLocation) { }
                    actionref(ByEvent_Promoted; ByEvent) { }
                    actionref(ByPeriod_Promoted; ByPeriod) { }
                    actionref(ByLot_Promoted; ByLot) { }
                    actionref(ByUOM_Promoted; ByUOM) { }
                }
                actionref("Create Transfer Order_Promoted"; "Create Transfer Order") { }
            }
        }
    }

    var
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        CurrentWkshBatchName: Code[10];
        DateFilter: Text;
        NeedsAttention: Boolean;
        EmptyBatchQst: Label 'Are you sure you want to empty the batch? This action will delele all lines, automatic allocations, and any manual edits that you have made.';

    procedure SetCurrentWkshBatchName(Name: Code[10])
    begin
        CurrentWkshBatchName := Name;
        ReservationWorksheetMgt.SetName(CurrentWkshBatchName, Rec);
    end;

    local procedure CurrentWkshBatchNameOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        ReservationWorksheetMgt.SetName(CurrentWkshBatchName, Rec);
        CurrPage.Update(false);
    end;

    local procedure GetSourceLocationForTransfer(): Code[10]
    var
        Location: Record Location;
        FilterPage: FilterPageBuilder;
    begin
        FilterPage.AddTable(Location.TableCaption, Database::Location);
        FilterPage.AddFieldNo(Location.TableCaption, Location.FieldNo(Code));
        if FilterPage.RunModal() then begin
            Location.SetView(FilterPage.GetView(Location.TableCaption));
            if (Location.Count = 1) and Location.FindFirst() then
                exit(Location.Code);
        end;

        exit('');
    end;

    local procedure UpdateNeedsAttention()
    begin
        NeedsAttention := (Rec."Remaining Qty. to Reserve" - Rec."Qty. to Reserve" > 0) and not Rec.Accept;
    end;

    trigger OnOpenPage()
    begin
        ReservationWorksheetMgt.OpenJnl(CurrentWkshBatchName, Rec);
        Rec.SetFilter("Demand Date", DateFilter);
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateNeedsAttention();
    end;
}
