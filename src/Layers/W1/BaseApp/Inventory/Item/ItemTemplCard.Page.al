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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Item)
            {
                Caption = 'Item';
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sales Blocked"; Rec."Sales Blocked")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Purchasing Blocked"; Rec."Purchasing Blocked")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ShowMandatory = true;
                }
                field("Item Category Code"; Rec."Item Category Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Manufacturer Code"; Rec."Manufacturer Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Automatic Ext. Texts"; Rec."Automatic Ext. Texts")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Common Item No."; Rec."Common Item No.")
                {
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    Visible = false;
                }
                field("Purchasing Code"; Rec."Purchasing Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field(GTIN; Rec.GTIN)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field(VariantMandatoryDefaultYes; Rec."Variant Mandatory if Exists")
                {
                    ApplicationArea = Basic, Suite;
                    OptionCaption = 'Default (Yes),No,Yes';
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
                }
                field("Net Weight"; Rec."Net Weight")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field("Gross Weight"; Rec."Gross Weight")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field("Unit Volume"; Rec."Unit Volume")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Over-Receipt Code"; Rec."Over-Receipt Code")
                {
                    ApplicationArea = All;
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
                        Visible = false;
                    }
                    field("Unit Cost"; Rec."Unit Cost")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        Visible = false;
                    }
                    field("Costing Method"; Rec."Costing Method")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Indirect Cost %"; Rec."Indirect Cost %")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Inventory Value Zero"; Rec."Inventory Value Zero")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
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
                    }
                    field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ShowMandatory = true;
                    }
                    field("Tax Group Code"; Rec."Tax Group Code")
                    {
                        ApplicationArea = SalesTax;
                        Importance = Promoted;
                    }
                    field("Inventory Posting Group"; Rec."Inventory Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                    }
                    field("Default Deferral Template Code"; Rec."Default Deferral Template Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Default Deferral Template';
                        Visible = false;
                    }
                }
                group(ForeignTrade)
                {
                    Caption = 'Foreign Trade';
                    field("Tariff No."; Rec."Tariff No.")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Country/Region of Origin Code"; Rec."Country/Region of Origin Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
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
                    Visible = false;
                }
                field("Price Includes VAT"; Rec."Price Includes VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Price/Profit Calculation"; Rec."Price/Profit Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Profit %"; Rec."Profit %")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Item Disc. Group"; Rec."Item Disc. Group")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("VAT Bus. Posting Gr. (Price)"; Rec."VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies the VAT business posting group for customers for whom you want the sales price including VAT to apply.';
                    Visible = false;
                }
            }
            group(Replenishment)
            {
                Caption = 'Replenishment';
                field("Replenishment System"; Rec."Replenishment System")
                {
                    ApplicationArea = Assembly, Planning;
                    Caption = 'Replenishment System';
                    Importance = Promoted;
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = Assembly, Planning;
                }
                group(Purchase)
                {
                    Caption = 'Purchase';
                    field("Vendor No."; Rec."Vendor No.")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Vendor Item No."; Rec."Vendor Item No.")
                    {
                        ApplicationArea = Planning;
                        Visible = false;
                    }
                }
                group(Replenishment_Assembly)
                {
                    Caption = 'Assembly';
                    field("Assembly Policy"; Rec."Assembly Policy")
                    {
                        ApplicationArea = Assembly;
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

                    trigger OnValidate()
                    begin
                        EnablePlanningControls();
                    end;
                }
                field(Reserve; Rec.Reserve)
                {
                    ApplicationArea = Reservation;
                    Importance = Additional;
                    Visible = false;
                }
                field("Order Tracking Policy"; Rec."Order Tracking Policy")
                {
                    ApplicationArea = Planning;
                    Importance = Promoted;
                    Visible = false;
                }
                field("Dampener Period"; Rec."Dampener Period")
                {
                    ApplicationArea = Planning;
                    Importance = Additional;
                    Visible = false;
                    Enabled = DampenerPeriodEnable;
                }
                field("Dampener Quantity"; Rec."Dampener Quantity")
                {
                    ApplicationArea = Planning;
                    Importance = Additional;
                    Visible = false;
                    Enabled = DampenerQtyEnable;
                }
                field(Critical; Rec.Critical)
                {
                    ApplicationArea = OrderPromising;
                    Visible = false;
                }
                field("Safety Lead Time"; Rec."Safety Lead Time")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                    Enabled = SafetyLeadTimeEnable;
                }
                field("Safety Stock Quantity"; Rec."Safety Stock Quantity")
                {
                    ApplicationArea = Planning;
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
                        Visible = false;
                        Enabled = LotAccumulationPeriodEnable;
                    }
                    field("Rescheduling Period"; Rec."Rescheduling Period")
                    {
                        ApplicationArea = Planning;
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
                            Enabled = ReorderPointEnable;
                        }
                        field("Reorder Quantity"; Rec."Reorder Quantity")
                        {
                            ApplicationArea = Planning;
                            Visible = false;
                            Enabled = ReorderQtyEnable;
                        }
                        field("Maximum Inventory"; Rec."Maximum Inventory")
                        {
                            ApplicationArea = Planning;
                            Visible = false;
                            Enabled = MaximumInventoryEnable;
                        }
                    }
                    field("Overflow Level"; Rec."Overflow Level")
                    {
                        ApplicationArea = Planning;
                        Importance = Additional;
                        Visible = false;
                        Enabled = OverflowLevelEnable;
                    }
                    field("Time Bucket"; Rec."Time Bucket")
                    {
                        ApplicationArea = Planning;
                        Importance = Additional;
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
                            Enabled = MinimumOrderQtyEnable;
                        }
                        field("Maximum Order Quantity"; Rec."Maximum Order Quantity")
                        {
                            ApplicationArea = Planning;
                            Visible = false;
                            Enabled = MaximumOrderQtyEnable;
                        }
                        field("Order Multiple"; Rec."Order Multiple")
                        {
                            ApplicationArea = Planning;
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
                }
                field("Serial Nos."; Rec."Serial Nos.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Lot Nos."; Rec."Lot Nos.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Expiration Calculation"; Rec."Expiration Calculation")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                field("Warehouse Class Code"; Rec."Warehouse Class Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Special Equipment Code"; Rec."Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
                }
                field("Put-away Template Code"; Rec."Put-away Template Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Phys Invt Counting Period Code"; Rec."Phys Invt Counting Period Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    Visible = false;
                }
                field("Use Cross-Docking"; Rec."Use Cross-Docking")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
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
