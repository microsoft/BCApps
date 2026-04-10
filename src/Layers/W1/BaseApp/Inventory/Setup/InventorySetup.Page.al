// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Setup;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;

page 461 "Inventory Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Inventory Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Automatic Cost Posting"; Rec."Automatic Cost Posting")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Expected Cost Posting to G/L"; Rec."Expected Cost Posting to G/L")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                }
                field("Automatic Cost Adjustment"; Rec."Automatic Cost Adjustment")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Cost Adjustment Logging"; Rec."Cost Adjustment Logging")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Default Costing Method"; Rec."Default Costing Method")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Average Cost Calc. Type"; Rec."Average Cost Calc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Average Cost Period"; Rec."Average Cost Period")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Copy Comments Order to Shpt."; Rec."Copy Comments Order to Shpt.")
                {
                    ApplicationArea = Comments;
                    Importance = Additional;
                }
                field("Copy Comments Order to Rcpt."; Rec."Copy Comments Order to Rcpt.")
                {
                    ApplicationArea = Comments;
                    Importance = Additional;
                }
                field("Copy Comments to Invt. Doc."; Rec."Copy Comments to Invt. Doc.")
                {
                    ApplicationArea = Comments;
                    Importance = Additional;
                }
                field("Outbound Whse. Handling Time"; Rec."Outbound Whse. Handling Time")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
                }
                field("Inbound Whse. Handling Time"; Rec."Inbound Whse. Handling Time")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
                }
                field("Prevent Negative Inventory"; Rec."Prevent Negative Inventory")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Variant Mandatory if Exists"; Rec."Variant Mandatory if Exists")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether a variant must be selected if variants exist for an item. This is the default setting for all items. However, the same option is available on the Item Card page for items. That setting applies to the specific item. ';
                }
                field("Skip Prompt to Create Item"; Rec."Skip Prompt to Create Item")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Copy Item Descr. to Entries"; Rec."Copy Item Descr. to Entries")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Allow Invt. Doc. Reservation"; Rec."Allow Invt. Doc. Reservation")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Allow Inventory Adjustment"; Rec."Allow Inventory Adjustment")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Location)
            {
                Caption = 'Location';
                field("Location Mandatory"; Rec."Location Mandatory")
                {
                    ApplicationArea = Location;
                }
            }
            group(Planning)
            {
                Caption = 'Planning';
                field("Current Demand Forecast"; Rec."Current Demand Forecast")
                {
                    ApplicationArea = Planning;
                }
                field("Use Forecast on Locations"; Rec."Use Forecast on Locations")
                {
                    ApplicationArea = Planning;
                }
                field("Use Forecast on Variants"; Rec."Use Forecast on Variants")
                {
                    ApplicationArea = Planning;
                }
                field("Default Safety Lead Time"; Rec."Default Safety Lead Time")
                {
                    ApplicationArea = Planning;
                }
                field("Blank Overflow Level"; Rec."Blank Overflow Level")
                {
                    ApplicationArea = Planning;
                }
                field("Combined MPS/MRP Calculation"; Rec."Combined MPS/MRP Calculation")
                {
                    ApplicationArea = Planning;
                }
                field("Default Dampener Period"; Rec."Default Dampener Period")
                {
                    ApplicationArea = Planning;
                }
                field("Default Dampener %"; Rec."Default Dampener %")
                {
                    ApplicationArea = Planning;
                }
            }
            group(Dimensions)
            {
                Caption = 'Dimensions';
                field("Item Group Dimension Code"; Rec."Item Group Dimension Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Package Caption"; Rec."Package Caption")
                {
                    ApplicationArea = ItemTracking;
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Item Nos."; Rec."Item Nos.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Nonstock Item Nos."; Rec."Nonstock Item Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Catalog Item Nos.';
                    Importance = Additional;
                }
                field("Transfer Order Nos."; Rec."Transfer Order Nos.")
                {
                    ApplicationArea = Location;
                    Importance = Additional;
                }
                field("Posted Transfer Shpt. Nos."; Rec."Posted Transfer Shpt. Nos.")
                {
                    ApplicationArea = Location;
                    Importance = Additional;
                }
                field("Posted Transfer Rcpt. Nos."; Rec."Posted Transfer Rcpt. Nos.")
                {
                    ApplicationArea = Location;
                    Importance = Additional;
                }
                field("Posted Direct Trans. Nos."; Rec."Posted Direct Trans. Nos.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Direct Transfer Posting"; Rec."Direct Transfer Posting")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Inventory Put-away Nos."; Rec."Inventory Put-away Nos.")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
                }
                field("Posted Invt. Put-away Nos."; Rec."Posted Invt. Put-away Nos.")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
                }
                field("Inventory Pick Nos."; Rec."Inventory Pick Nos.")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
                }
                field("Posted Invt. Pick Nos."; Rec."Posted Invt. Pick Nos.")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
                }
                field("Inventory Movement Nos."; Rec."Inventory Movement Nos.")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
                }
                field("Registered Invt. Movement Nos."; Rec."Registered Invt. Movement Nos.")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
                }
                field("Internal Movement Nos."; Rec."Internal Movement Nos.")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
                }
                field("Phys. Invt. Order Nos."; Rec."Phys. Invt. Order Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Posted Phys. Invt. Order Nos."; Rec."Posted Phys. Invt. Order Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Invt. Receipt Nos."; Rec."Invt. Receipt Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Posted Invt. Receipt Nos."; Rec."Posted Invt. Receipt Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Invt. Shipment Nos."; Rec."Invt. Shipment Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Posted Invt. Shipment Nos."; Rec."Posted Invt. Shipment Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Package Nos."; Rec."Package Nos.")
                {
                    ApplicationArea = ItemTracking;
                    Importance = Additional;
                }
            }
            group("Gen. Journal Templates")
            {
                Caption = 'Journal Templates';
                Visible = IsJournalTemplatesVisible;

                field("Invt. Cost Jnl. Template Name";
                Rec."Invt. Cost Jnl. Template Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Invt. Cost Jnl. Batch Name"; Rec."Invt. Cost Jnl. Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("Schedule Cost Adjustment and Posting")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Schedule Cost Adjustment and Posting';
                Image = AdjustItemCost;
                Visible = AdjustCostWizardVisible;
                ToolTip = 'Get help with creating job queue entries for item entry cost adjustments and posting costs to G/L tasks.';
                trigger OnAction()
                begin
                    Page.RunModal(Page::"Cost Adj. Scheduling Wizard");
                end;
            }
            action("Inventory Periods")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Inventory Periods';
                Image = Period;
                RunObject = Page "Inventory Periods";
                ToolTip = 'Set up periods in combinations with your accounting periods that define when you can post transactions that affect the value of your item inventory. When you close an inventory period, you cannot post any changes to the inventory value, either expected or actual value, before the ending date of the inventory period.';
            }
            action("Units of Measure")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Units of Measure';
                Image = UnitOfMeasure;
                RunObject = Page "Units of Measure";
                ToolTip = 'Set up the units of measure, such as PSC or HOUR, that you can select from in the Item Units of Measure window that you access from the item card.';
            }
            action("Item Discount Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item Discount Groups';
                Image = Discount;
                RunObject = Page "Item Disc. Groups";
                ToolTip = 'Set up discount group codes that you can use as criteria when you define special discounts on a customer, vendor, or item card.';
            }
            action("Import Item Pictures")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Item Pictures';
                Image = Import;
                RunObject = Page "Import Item Pictures";
                ToolTip = 'Import item pictures from a ZIP file.';
            }
            group(Posting)
            {
                Caption = 'Posting';
                action("Inventory Posting Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Posting Setup';
                    Image = PostedInventoryPick;
                    RunObject = Page "Inventory Posting Setup";
                    ToolTip = 'Set up links between inventory posting groups, inventory locations, and general ledger accounts to define where transactions for inventory items are recorded in the general ledger.';
                }
                action("Inventory Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Posting Groups';
                    Image = ItemGroup;
                    RunObject = Page "Inventory Posting Groups";
                    ToolTip = 'Set up the posting groups that you assign to item cards to link business transactions made for the item with an inventory account in the general ledger to group amounts for that item type.';
                }
            }
            group("Journal Templates")
            {
                Caption = 'Journal Templates';
                action("Item Journal Templates")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Journal Templates';
                    Image = JournalSetup;
                    RunObject = Page "Item Journal Templates";
                    ToolTip = 'Set up number series and reason codes in the journals that you use for inventory adjustment. By using different templates you can design windows with different layouts and you can assign trace codes, number series, and reports to each template.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'General', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Schedule Cost Adjustment and Posting_Promoted"; "Schedule Cost Adjustment and Posting")
                {
                }
                actionref("Inventory Periods_Promoted"; "Inventory Periods")
                {
                }
                actionref("Units of Measure_Promoted"; "Units of Measure")
                {
                }
                actionref("Item Discount Groups_Promoted"; "Item Discount Groups")
                {
                }
                actionref("Import Item Pictures_Promoted"; "Import Item Pictures")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Inventory Posting Setup_Promoted"; "Inventory Posting Setup")
                {
                }
                actionref("Inventory Posting Groups_Promoted"; "Inventory Posting Groups")
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Journal Templates', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref("Item Journal Templates_Promoted"; "Item Journal Templates")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            OnOpenPageOnBeforeRecInsert(Rec);
            Rec.Insert();
        end;

        SetAdjustCostWizardActionVisibility();

        GLSetup.Get();
        IsJournalTemplatesVisible := GLSetup."Journal Templ. Name Mandatory";
    end;

    var
        GLSetup: Record "General Ledger Setup";
        SchedulingManager: Codeunit "Cost Adj. Scheduling Manager";
        AdjustCostWizardVisible: Boolean;
        IsJournalTemplatesVisible: Boolean;

    local procedure SetAdjustCostWizardActionVisibility()
    begin
        if (Rec."Automatic Cost Posting" = false) and (not SchedulingManager.PostInvCostToGLJobQueueExists()) or
           (Rec."Automatic Cost Adjustment" = Rec."Automatic Cost Adjustment"::Never) and (not SchedulingManager.AdjCostJobQueueExists()) then
            AdjustCostWizardVisible := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeRecInsert(var InventorySetup: Record "Inventory Setup")
    begin
    end;
}

