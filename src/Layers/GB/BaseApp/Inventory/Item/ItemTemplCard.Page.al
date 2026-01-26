// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Setup;

page 1384 "Item Templ. Card"
{
    Caption = 'Item Template';
    PageType = Card;
    SourceTable = "Item Templ.";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the template.';
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series that will be used to assign numbers to items.';
                }
            }
            group(Item)
            {
                Caption = 'Item';
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example an item that is placed in quarantine.';
                }
                field("Sales Blocked"; Rec."Sales Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the item cannot be entered on sales documents, except return orders and credit memos, and journals.';
                }
                field("Purchasing Blocked"; Rec."Purchasing Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the item cannot be entered on purchase documents, except return orders and credit memos, and journals.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the item card represents a physical inventory unit (Inventory), a labor time unit (Service), or a physical unit that is not tracked in inventory (Non-Inventory).';
                }
                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the base unit used to measure the item, such as piece, box, or pallet. The base unit of measure also serves as the conversion basis for alternate units of measure.';
                }
                field("Item Category Code"; Rec."Item Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category that the item belongs to. Item categories also contain any assigned item attributes.';
                }
                field("Manufacturer Code"; Rec."Manufacturer Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the manufacturer of the catalog item.';
                    Visible = false;
                }
                field("Automatic Ext. Texts"; Rec."Automatic Ext. Texts")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that an extended text that you have set up will be added automatically on sales or purchase documents for this item.';
                }
                field("Common Item No."; Rec."Common Item No.")
                {
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies the unique common item number that the intercompany partners agree upon.';
                    Visible = false;
                }
                field("Purchasing Code"; Rec."Purchasing Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for a special procurement method, such as drop shipment.';
                    Visible = false;
                }
                field(GTIN; Rec.GTIN)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the Global Trade Item Number (GTIN) for the item. For example, the GTIN is used with bar codes to track items, and when sending and receiving documents electronically. The GTIN number typically contains a Universal Product Code (UPC), or European Article Number (EAN).';
                    Visible = false;
                }
                field(VariantMandatoryDefaultYes; Rec."Variant Mandatory if Exists")
                {
                    ApplicationArea = Basic, Suite;
                    OptionCaption = 'Default (Yes),No,Yes';
                    ToolTip = 'Specifies whether a variant must be selected if variants exist for the item.';
                    Visible = ShowVariantMandatoryDefaultYes;
                }
                field(VariantMandatoryDefaultNo; Rec."Variant Mandatory if Exists")
                {
                    ApplicationArea = Basic, Suite;
                    OptionCaption = 'Default (No),No,Yes';
                    ToolTip = 'Specifies whether a variant must be selected if variants exist for the item.';
                    Visible = not ShowVariantMandatoryDefaultYes;
                }
                field("Statistics Group"; Rec."Statistics Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
            group(InventoryGrp)
            {
                Caption = 'Inventory';
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies where to find the item in the warehouse. This is informational only.';
                }
                field("Net Weight"; Rec."Net Weight")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the net weight of the item.';
                    Visible = false;
                }
                field("Gross Weight"; Rec."Gross Weight")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the gross weight of the item.';
                    Visible = false;
                }
                field("Unit Volume"; Rec."Unit Volume")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the volume of one unit of the item.';
                    Visible = false;
                }
                field("Over-Receipt Code"; Rec."Over-Receipt Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the policy that will be used for the item if more items than ordered are received.';
                    Visible = false;
                }
            }
            group(CostsAndPosting)
            {
                Caption = 'Costs & Posting';
                group(CostDetails)
                {
                    Caption = 'Cost Details';
                    field("Standard Cost"; Rec."Standard Cost")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the unit cost that is used as an estimation to be adjusted with variances later. It is typically used in assembly and production where costs can vary.';
                        Visible = false;
                    }
                    field("Unit Cost"; Rec."Unit Cost")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                        Visible = false;
                    }
                    field("Costing Method"; Rec."Costing Method")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies how the item''s cost flow is recorded and whether an actual or budgeted value is capitalized and used in the cost calculation.';
                    }
                    field("Indirect Cost %"; Rec."Indirect Cost %")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
                    }
                    field("Inventory Value Zero"; Rec."Inventory Value Zero")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies whether the item on inventory must be excluded from inventory valuation. This is relevant if the item is kept on inventory on someone else''s behalf.';
                        Visible = false;
                    }
                }
                group(PostingDetails)
                {
                    Caption = 'Posting Details';
                    field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    }
                    field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    }
                    field("Tax Group Code"; Rec."Tax Group Code")
                    {
                        ApplicationArea = SalesTax;
                        Importance = Promoted;
                        ToolTip = 'Specifies the tax group that is used to calculate and post sales tax.';
                    }
                    field("Inventory Posting Group"; Rec."Inventory Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies links between business transactions made for the item and an inventory account in the general ledger, to group amounts for that item type.';
                    }
                    field("Default Deferral Template Code"; Rec."Default Deferral Template Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Default Deferral Template';
                        ToolTip = 'Specifies how revenue or expenses for the item are deferred to other accounting periods by default.';
                        Visible = false;
                    }
                }
                group(ForeignTrade)
                {
                    Caption = 'Foreign Trade';
                    field("Tariff No."; Rec."Tariff No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies a code for the item''s tariff number.';
                    }
                    field("Country/Region of Origin Code"; Rec."Country/Region of Origin Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies a code for the country/region where the item was produced or processed.';
                        Visible = false;
                    }
                }
            }
            group(PricesAndSales)
            {
                Caption = 'Prices & Sales';
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                    Visible = false;
                }
                field("Price Includes VAT"; Rec."Price Includes VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if the Unit Price and Line Amount fields on sales document lines for this item should be shown with or without VAT.';
                }
                field("Price/Profit Calculation"; Rec."Price/Profit Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the relationship between the Unit Cost, Unit Price, and Profit Percentage fields associated with this item.';
                }
                field("Profit %"; Rec."Profit %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the profit margin that you want to sell the item at. You can enter a profit percentage manually or have it entered according to the Price/Profit Calculation field';
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to include the item when calculating an invoice discount on documents where the item is traded.';
                }
                field("Item Disc. Group"; Rec."Item Disc. Group")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies an item group code that can be used as a criterion to grant a discount when the item is sold to a certain customer.';
                }
                field("VAT Bus. Posting Gr. (Price)"; Rec."VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies the VAT business posting group for customers for whom you want the sales price including VAT to apply.';
                    Visible = false;
                }
#if not CLEAN27
                field("Reverse Charge Applies"; Rec."Reverse Charge Applies")
                {
                    ApplicationArea = Basic, Suite;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Reverse Charge VAT GB app';
                    ObsoleteTag = '27.0';
                    ToolTip = 'Specifies if this item is subject to reverse charge.';
                }
#endif
            }
            group(Replenishment)
            {
                Caption = 'Replenishment';
                field("Replenishment System"; Rec."Replenishment System")
                {
                    ApplicationArea = Assembly, Planning;
                    Caption = 'Replenishment System';
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of supply order created by the planning system when the item needs to be replenished.';
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = Assembly, Planning;
                    ToolTip = 'Specifies a date formula for the amount of time it takes to replenish the item.';
                }
                group(Purchase)
                {
                    Caption = 'Purchase';
                    field("Vendor No."; Rec."Vendor No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the vendor code of who supplies this item by default.';
                    }
                    field("Vendor Item No."; Rec."Vendor Item No.")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies the number that the vendor uses for this item.';
                        Visible = false;
                    }
                }
                group(Replenishment_Assembly)
                {
                    Caption = 'Assembly';
                    field("Assembly Policy"; Rec."Assembly Policy")
                    {
                        ApplicationArea = Assembly;
                        ToolTip = 'Specifies which default order flow is used to supply this assembly item.';
                    }
                }
            }
            group(Planning)
            {
                Caption = 'Planning';
                field("Reordering Policy"; Rec."Reordering Policy")
                {
                    ApplicationArea = Planning;
                    Importance = Promoted;
                    ToolTip = 'Specifies the reordering policy.';

                    trigger OnValidate()
                    begin
                        EnablePlanningControls();
                    end;
                }
                field(Reserve; Rec.Reserve)
                {
                    ApplicationArea = Reservation;
                    Importance = Additional;
                    ToolTip = 'Specifies if and how the item will be reserved. Never: It is not possible to reserve the item. Optional: You can reserve the item manually. Always: The item is automatically reserved from demand, such as sales orders, against inventory, purchase orders, assembly orders, and production orders.';
                    Visible = false;
                }
                field("Order Tracking Policy"; Rec."Order Tracking Policy")
                {
                    ApplicationArea = Planning;
                    Importance = Promoted;
                    ToolTip = 'Specifies if and how order tracking entries are created and maintained between supply and its corresponding demand.';
                    Visible = false;
                }
                field("Dampener Period"; Rec."Dampener Period")
                {
                    ApplicationArea = Planning;
                    Importance = Additional;
                    ToolTip = 'Specifies a period of time during which you do not want the planning system to propose to reschedule existing supply orders forward. The dampener period limits the number of insignificant rescheduling of existing supply to a later date if that new date is within the dampener period. The dampener period function is only initiated if the supply can be rescheduled to a later date and not if the supply can be rescheduled to an earlier date. Accordingly, if the suggested new supply date is after the dampener period, then the rescheduling suggestion is not blocked. If the lot accumulation period is less than the dampener period, then the dampener period is dynamically set to equal the lot accumulation period. This is not shown in the value that you enter in the Dampener Period field. The last demand in the lot accumulation period is used to determine whether a potential supply date is in the dampener period. If this field is empty, then the value in the Default Dampener Period field in the Manufacturing Setup window applies. The value that you enter in the Dampener Period field must be a date formula, and one day (1D) is the shortest allowed period.';
                    Visible = false;
                    Enabled = DampenerPeriodEnable;
                }
                field("Dampener Quantity"; Rec."Dampener Quantity")
                {
                    ApplicationArea = Planning;
                    Importance = Additional;
                    ToolTip = 'Specifies a dampener quantity to block insignificant change suggestions for an existing supply, if the change quantity is lower than the dampener quantity.';
                    Visible = false;
                    Enabled = DampenerQtyEnable;
                }
                field(Critical; Rec.Critical)
                {
                    ApplicationArea = OrderPromising;
                    ToolTip = 'Specifies if the item is included in availability calculations to promise a shipment date for its parent item.';
                    Visible = false;
                }
                field("Safety Lead Time"; Rec."Safety Lead Time")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a date formula to indicate a safety lead time that can be used as a buffer period for production and other delays.';
                    Visible = false;
                    Enabled = SafetyLeadTimeEnable;
                }
                field("Safety Stock Quantity"; Rec."Safety Stock Quantity")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a quantity of stock to have in inventory to protect against supply-and-demand fluctuations during replenishment lead time.';
                    Visible = false;
                    Enabled = SafetyStockQtyEnable;
                }
                group(LotForLotParameters)
                {
                    Visible = false;
                    Caption = 'Lot-for-Lot Parameters';
                    field("Include Inventory"; Rec."Include Inventory")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies that the inventory quantity is included in the projected available balance when replenishment orders are calculated.';
                        Visible = false;
                        Enabled = IncludeInventoryEnable;

                        trigger OnValidate()
                        begin
                            EnablePlanningControls()
                        end;
                    }
                    field("Lot Accumulation Period"; Rec."Lot Accumulation Period")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies a period in which multiple demands are accumulated into one supply order when you use the Lot-for-Lot reordering policy.';
                        Visible = false;
                        Enabled = LotAccumulationPeriodEnable;
                    }
                    field("Rescheduling Period"; Rec."Rescheduling Period")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies a period within which any suggestion to change a supply date always consists of a Reschedule action and never a Cancel + New action.';
                        Visible = false;
                        Enabled = ReschedulingPeriodEnable;
                    }
                }
                group(ReorderPointParameters)
                {
                    Caption = 'Reorder-Point Parameters';
                    group(Control64)
                    {
                        ShowCaption = false;
                        field("Reorder Point"; Rec."Reorder Point")
                        {
                            ApplicationArea = Planning;
                            ToolTip = 'Specifies a stock quantity that sets the inventory below the level that you must replenish the item.';
                            Enabled = ReorderPointEnable;
                        }
                        field("Reorder Quantity"; Rec."Reorder Quantity")
                        {
                            ApplicationArea = Planning;
                            ToolTip = 'Specifies a standard lot size quantity to be used for all order proposals.';
                            Visible = false;
                            Enabled = ReorderQtyEnable;
                        }
                        field("Maximum Inventory"; Rec."Maximum Inventory")
                        {
                            ApplicationArea = Planning;
                            ToolTip = 'Specifies a quantity that you want to use as a maximum inventory level.';
                            Visible = false;
                            Enabled = MaximumInventoryEnable;
                        }
                    }
                    field("Overflow Level"; Rec."Overflow Level")
                    {
                        ApplicationArea = Planning;
                        Importance = Additional;
                        ToolTip = 'Specifies a quantity you allow projected inventory to exceed the reorder point, before the system suggests to decrease supply orders.';
                        Visible = false;
                        Enabled = OverflowLevelEnable;
                    }
                    field("Time Bucket"; Rec."Time Bucket")
                    {
                        ApplicationArea = Planning;
                        Importance = Additional;
                        ToolTip = 'Specifies a time period that defines the recurring planning horizon used with Fixed Reorder Qty. or Maximum Qty. reordering policies.';
                        Visible = false;
                        Enabled = TimeBucketEnable;
                    }
                }
                group(OrderModifiers)
                {
                    Caption = 'Order Modifiers';
                    group(Control61)
                    {
                        ShowCaption = false;
                        field("Minimum Order Quantity"; Rec."Minimum Order Quantity")
                        {
                            ApplicationArea = Planning;
                            ToolTip = 'Specifies a minimum allowable quantity for an item order proposal.';
                            Enabled = MinimumOrderQtyEnable;
                        }
                        field("Maximum Order Quantity"; Rec."Maximum Order Quantity")
                        {
                            ApplicationArea = Planning;
                            ToolTip = 'Specifies a maximum allowable quantity for an item order proposal.';
                            Visible = false;
                            Enabled = MaximumOrderQtyEnable;
                        }
                        field("Order Multiple"; Rec."Order Multiple")
                        {
                            ApplicationArea = Planning;
                            ToolTip = 'Specifies a parameter used by the planning system to round the quantity of planned supply orders to a multiple of this value.';
                            Visible = false;
                            Enabled = OrderMultipleEnable;
                        }
                    }
                }
            }
            group(ItemTracking)
            {
                Caption = 'Item Tracking';
                field("Item Tracking Code"; Rec."Item Tracking Code")
                {
                    ApplicationArea = ItemTracking;
                    Importance = Promoted;
                    ToolTip = 'Specifies how serial, lot or package numbers assigned to the item are tracked in the supply chain.';
                }
                field("Serial Nos."; Rec."Serial Nos.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a number series code to assign consecutive serial numbers to items produced.';
                }
                field("Lot Nos."; Rec."Lot Nos.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number series code that will be used when assigning lot numbers.';
                }
                field("Expiration Calculation"; Rec."Expiration Calculation")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the date formula for calculating the expiration date on the item tracking line. Note: This field will be ignored if the involved item has Require Expiration Date Entry set to Yes on the Item Tracking Code page.';
                    Visible = false;
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                field("Warehouse Class Code"; Rec."Warehouse Class Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the warehouse class code for the item.';
                }
                field("Special Equipment Code"; Rec."Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
                    ToolTip = 'Specifies the code of the equipment that warehouse employees must use when handling the item.';
                }
                field("Put-away Template Code"; Rec."Put-away Template Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the put-away template by which the program determines the most appropriate zone and bin for storage of the item after receipt.';
                }
                field("Phys Invt Counting Period Code"; Rec."Phys Invt Counting Period Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the counting period that indicates how often you want to count the item in a physical inventory.';
                    Visible = false;
                }
                field("Use Cross-Docking"; Rec."Use Cross-Docking")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
                    ToolTip = 'Specifies if this item can be cross-docked.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Dimensions)
            {
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Image = Dimensions;
                RunObject = Page "Default Dimensions";
                RunPageLink = "Table ID" = const(1382),
                              "No." = field(Code);
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
            }
            action(CopyTemplate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Template';
                Image = Copy;
                ToolTip = 'Copies all information to the current template from the selected one.';

                trigger OnAction()
                var
                    ItemTempl: Record "Item Templ.";
                    ItemTemplList: Page "Item Templ. List";
                begin
                    Rec.TestField(Code);
                    ItemTempl.SetFilter(Code, '<>%1', Rec.Code);
                    ItemTemplList.LookupMode(true);
                    ItemTemplList.SetTableView(ItemTempl);
                    if ItemTemplList.RunModal() = Action::LookupOK then begin
                        ItemTemplList.GetRecord(ItemTempl);
                        Rec.CopyFromTemplate(ItemTempl);
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CopyTemplate_Promoted; CopyTemplate)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        if Rec.Code <> '' then
            exit;

        if not InventorySetup.Get() then
            exit;

        Rec."Costing Method" := InventorySetup."Default Costing Method";
        OnAfterOnNewRecord(Rec);
    end;

    trigger OnInit()
    begin
        InitControls();
    end;

    trigger OnOpenPage()
    begin
        EnablePlanningControls();
        EnableShowVariantMandatory();
    end;

    var
        ShowVariantMandatoryDefaultYes: Boolean;

    protected var
        TimeBucketEnable: Boolean;
        SafetyLeadTimeEnable: Boolean;
        SafetyStockQtyEnable: Boolean;
        ReorderPointEnable: Boolean;
        ReorderQtyEnable: Boolean;
        MaximumInventoryEnable: Boolean;
        MinimumOrderQtyEnable: Boolean;
        MaximumOrderQtyEnable: Boolean;
        OrderMultipleEnable: Boolean;
        IncludeInventoryEnable: Boolean;
        ReschedulingPeriodEnable: Boolean;
        LotAccumulationPeriodEnable: Boolean;
        DampenerPeriodEnable: Boolean;
        DampenerQtyEnable: Boolean;
        OverflowLevelEnable: Boolean;

    local procedure InitControls()
    begin
        OverflowLevelEnable := true;
        DampenerQtyEnable := true;
        DampenerPeriodEnable := true;
        LotAccumulationPeriodEnable := true;
        ReschedulingPeriodEnable := true;
        IncludeInventoryEnable := true;
        OrderMultipleEnable := true;
        MaximumOrderQtyEnable := true;
        MinimumOrderQtyEnable := true;
        MaximumInventoryEnable := true;
        ReorderQtyEnable := true;
        ReorderPointEnable := true;
        SafetyStockQtyEnable := true;
        SafetyLeadTimeEnable := true;
        TimeBucketEnable := true;
    end;

    local procedure EnablePlanningControls()
    var
        PlanningParameters: Record "Planning Parameters";
        PlanningGetParameters: Codeunit "Planning-Get Parameters";
    begin
        PlanningParameters."Reordering Policy" := Rec."Reordering Policy";
        PlanningParameters."Include Inventory" := Rec."Include Inventory";
        PlanningGetParameters.SetPlanningParameters(PlanningParameters);

        TimeBucketEnable := PlanningParameters."Time Bucket Enabled";
        SafetyLeadTimeEnable := PlanningParameters."Safety Lead Time Enabled";
        SafetyStockQtyEnable := PlanningParameters."Safety Stock Qty Enabled";
        ReorderPointEnable := PlanningParameters."Reorder Point Enabled";
        ReorderQtyEnable := PlanningParameters."Reorder Quantity Enabled";
        MaximumInventoryEnable := PlanningParameters."Maximum Inventory Enabled";
        MinimumOrderQtyEnable := PlanningParameters."Minimum Order Qty Enabled";
        MaximumOrderQtyEnable := PlanningParameters."Maximum Order Qty Enabled";
        OrderMultipleEnable := PlanningParameters."Order Multiple Enabled";
        IncludeInventoryEnable := PlanningParameters."Include Inventory Enabled";
        ReschedulingPeriodEnable := PlanningParameters."Rescheduling Period Enabled";
        LotAccumulationPeriodEnable := PlanningParameters."Lot Accum. Period Enabled";
        DampenerPeriodEnable := PlanningParameters."Dampener Period Enabled";
        DampenerQtyEnable := PlanningParameters."Dampener Quantity Enabled";
        OverflowLevelEnable := PlanningParameters."Overflow Level Enabled";
    end;

    local procedure EnableShowVariantMandatory()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        ShowVariantMandatoryDefaultYes := InventorySetup."Variant Mandatory if Exists";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnNewRecord(var ItemTempl: Record "Item Templ.")
    begin
    end;
}
