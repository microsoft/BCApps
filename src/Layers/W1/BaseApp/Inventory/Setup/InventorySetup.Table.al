// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Setup;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Transfer;
using Microsoft.Upgrade;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.InventoryDocument;
using System.Globalization;
using System.Utilities;

table 313 "Inventory Setup"
{
    Caption = 'Inventory Setup';
    DrillDownPageID = "Inventory Setup";
    LookupPageID = "Inventory Setup";
    Permissions = TableData "Inventory Adjmt. Entry (Order)" = m;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Automatic Cost Posting"; Boolean)
        {
            Caption = 'Automatic Cost Posting';
            ToolTip = 'Specifies if value entries are automatically posted to the inventory account, adjustment account, and COGS account in the general ledger when an item transaction is posted. Alternatively, you can manually post the values at regular intervals with the Post Inventory Cost to G/L batch job. Note that costs must be adjusted before posting to the general ledger.';
        }
        field(3; "Location Mandatory"; Boolean)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Location Mandatory';
            ToolTip = 'Specifies if a location code is required when posting item transactions. This field, together with the Components at Location field in the Manufacturing Setup window, is very important in governing how the planning system handles demand lines with/without location codes. For more information, see "Planning with or without Locations" in Help.';
        }
        field(4; "Item Nos."; Code[20])
        {
            Caption = 'Item Nos.';
            ToolTip = 'Specifies the number series that will be used to assign numbers to items.';
            TableRelation = "No. Series";
        }
        field(30; "Automatic Cost Adjustment"; Enum "Automatic Cost Adjustment Type")
        {
            Caption = 'Automatic Cost Adjustment';
            ToolTip = 'Specifies if item value entries are automatically adjusted when an item transaction is posted. This ensures correct inventory valuation in the general ledger, so that sales and profit statistics are up to date. The cost adjustment forwards any cost changes from inbound entries, such as those for purchases or production output, to the related outbound entries, such as sales or transfers. To minimize reduced performance during posting, select a time option to define how far back in time from the work date an inbound transaction can occur to potentially trigger adjustment of related outbound value entries. Alternatively, you can manually adjust costs at regular intervals with the Adjust Cost - Item Entries batch job.';

            trigger OnValidate()
            begin
                if "Automatic Cost Adjustment" <> "Automatic Cost Adjustment"::Never then begin
                    Item.SetCurrentKey("Cost is Adjusted", "Allow Online Adjustment");
                    Item.SetRange("Cost is Adjusted", false);
                    Item.SetRange("Allow Online Adjustment", false);

                    UpdateItem();
                    UpdateInvtAdjmtEntryOrder();

                    InvtAdjmtEntryOrder.SetCurrentKey("Cost is Adjusted", "Allow Online Adjustment");
                    InvtAdjmtEntryOrder.SetRange("Cost is Adjusted", false);
                    InvtAdjmtEntryOrder.SetRange("Allow Online Adjustment", false);
                    InvtAdjmtEntryOrder.SetRange("Is Finished", true);

                    if not (Item.IsEmpty() and InvtAdjmtEntryOrder.IsEmpty) then
                        Message(Text000);
                end;
            end;
        }
        field(31; "Cost Adjustment Logging"; Enum "Cost Adjustment Logging Level")
        {
            Caption = 'Cost Adjustment Logging';
            ToolTip = 'Specifies if you want to log cost adjustments runs. Disabled: No logging. Errors Only: The program will only log cost adjustment runs that have errors. All: The program will log all cost adjustment runs.';
            DataClassification = CustomerContent;
        }
        field(35; "Current Demand Forecast"; Code[10])
        {
            Caption = 'Current Demand Forecast';
            ToolTip = 'Specifies the name of the relevant demand forecast to use to calculate a plan.';
            TableRelation = Microsoft.Manufacturing.Forecast."Production Forecast Name".Name;
#if not CLEAN27
            trigger OnValidate()
            var
                ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
            begin
                if "Current Demand Forecast" <> xRec."Current Demand Forecast" then begin
                    ManufacturingSetup.Get();
                    ManufacturingSetup.Validate("Current Production Forecast", "Current Demand Forecast");
                    ManufacturingSetup.Modify();
                end;
            end;
#endif
        }
        field(36; "Use Forecast on Variants"; Boolean)
        {
            Caption = 'Use forecast on variants';
            ToolTip = 'Specifies that actual demand for the selected demand forecast is nettet for the specified item variant. If you leave the check box empty, the program regards the demand forecast as valid for all variants.';
#if not CLEAN27
            trigger OnValidate()
            var
                ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
            begin
                if "Use Forecast on Variants" <> xRec."Use Forecast on Variants" then begin
                    ManufacturingSetup.Get();
                    ManufacturingSetup.Validate("Use Forecast on Variants", "Use Forecast on Variants");
                    ManufacturingSetup.Modify();
                end;
            end;
#endif
        }
        field(37; "Use Forecast on Locations"; Boolean)
        {
            Caption = 'Use forecast on locations';
            ToolTip = 'Specifies that actual demand for the selected demand forecast is nettet for the specified location only. If you leave the check box empty, the program regards the demand forecast as valid for all locations.';
#if not CLEAN27
            trigger OnValidate()
            var
                ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
            begin
                if "Use Forecast on Locations" <> xRec."Use Forecast on Locations" then begin
                    ManufacturingSetup.Get();
                    ManufacturingSetup.Validate("Use Forecast on Locations", "Use Forecast on Locations");
                    ManufacturingSetup.Modify();
                end;
            end;
#endif
        }
        field(38; "Combined MPS/MRP Calculation"; Boolean)
        {
            AccessByPermission = TableData "Planning Component" = R;
            Caption = 'Combined MPS/MRP Calculation';
            ToolTip = 'Specifies if both master production schedule and material requirements plan are run when you choose the Calc. Regenerative Plan action in the planning worksheet.';
            InitValue = true;
#if not CLEAN27
            trigger OnValidate()
            var
                ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
            begin
                if "Combined MPS/MRP Calculation" <> xRec."Combined MPS/MRP Calculation" then begin
                    ManufacturingSetup.Get();
                    ManufacturingSetup.Validate("Combined MPS/MRP Calculation", "Combined MPS/MRP Calculation");
                    ManufacturingSetup.Modify();
                end;
            end;
#endif
        }
        field(40; "Prevent Negative Inventory"; Boolean)
        {
            Caption = 'Prevent Negative Inventory';
            ToolTip = 'Specifies whether you can post a transaction that will bring the item''s inventory below zero. Negative inventory is always prevented for Consumption and Transfer type transactions.';
        }
        field(41; "Default Dampener %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Default Dampener %';
            ToolTip = 'Specifies a percentage of an item''s lot size by which an existing supply must change before a planning suggestion is made.';
            DecimalPlaces = 1 : 1;
            MinValue = 0;
#if not CLEAN27
            trigger OnValidate()
            var
                ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
            begin
                if "Default Dampener %" <> xRec."Default Dampener %" then begin
                    ManufacturingSetup.Get();
                    ManufacturingSetup.Validate("Default Dampener %", "Default Dampener %");
                    ManufacturingSetup.Modify();
                end;
            end;
#endif
        }
        field(42; "Default Safety Lead Time"; DateFormula)
        {
            Caption = 'Default Safety Lead Time';
            ToolTip = 'Specifies a time period that is added to the lead time of all items that do not have another value specified in the Safety Lead Time field.';
#if not CLEAN27
            trigger OnValidate()
            var
                ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
            begin
                if "Default Safety Lead Time" <> xRec."Default Safety Lead Time" then begin
                    ManufacturingSetup.Get();
                    ManufacturingSetup.Validate("Default Safety Lead Time", "Default Safety Lead Time");
                    ManufacturingSetup.Modify();
                end;
            end;
#endif
        }
        field(43; "Blank Overflow Level"; Option)
        {
            Caption = 'Blank Overflow Level';
            ToolTip = 'Specifies how the planning system should react if the Overflow Level field on the item or SKU card is empty.';
            OptionCaption = 'Allow Default Calculation,Use Item/SKU Values Only';
            OptionMembers = "Allow Default Calculation","Use Item/SKU Values Only";
#if not CLEAN27
            trigger OnValidate()
            var
                ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
            begin
                if "Blank Overflow Level" <> xRec."Blank Overflow Level" then begin
                    ManufacturingSetup.Get();
                    ManufacturingSetup.Validate("Blank Overflow Level", "Blank Overflow Level");
                    ManufacturingSetup.Modify();
                end;
            end;
#endif
        }
        field(44; "Default Dampener Period"; DateFormula)
        {
            Caption = 'Default Dampener Period';
            ToolTip = 'Specifies a period of time during which you do not want the planning system to propose to reschedule existing supply order''s forward. This value in this field applies to all items except for items that have a different value in the Dampener Period field on the item card. When a dampener time is set, an order is only rescheduled when the defined dampener time has passed since the order s original due date. Note: The dampener time that is applied to an item can never be higher than the value in the item''s Lot Accumulation Period field. This is because the inventory build-up time that occurs during a dampener period would conflict with the build-up period defined by the item''s lot accumulation period. Accordingly, the default dampener period generally applies to all items. However, if an item''s lot accumulation period is shorter than the default dampener period, then the item''s dampener time equals its lot accumulation period.';

            trigger OnValidate()
            var
#if not CLEAN27
                ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
#endif
                CalendarMgt: Codeunit "Calendar Management";
            begin
                CalendarMgt.CheckDateFormulaPositive("Default Dampener Period");
#if not CLEAN27
                if "Default Dampener Period" <> xRec."Default Dampener Period" then begin
                    ManufacturingSetup.Get();
                    ManufacturingSetup.Validate("Default Dampener Period", "Default Dampener Period");
                    ManufacturingSetup.Modify();
                end;
#endif
            end;
        }
        field(45; "Variant Mandatory if Exists"; Boolean)
        {
            Caption = 'Variant Mandatory if Exists';
            ToolTip = 'Specifies whether a variant must be selected if variants exist for an item. This is the default setting for all items. However, the same option is available on the Item Card page for items. That setting applies to the specific item.';
        }
        field(50; "Skip Prompt to Create Item"; Boolean)
        {
            Caption = 'Skip Prompt to Create Item';
            ToolTip = 'Specifies if a message about creating a new item card appears when you enter an item number that does not exist.';
            DataClassification = SystemMetadata;
        }
        field(51; "Copy Item Descr. to Entries"; Boolean)
        {
            Caption = 'Copy Item Descr. to Entries';
            ToolTip = 'Specifies if you want the description on item cards to be copied to item ledger entries during posting.';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                UpdateNameInLedgerEntries: Codeunit "Update Name In Ledger Entries";
            begin
                if "Copy Item Descr. to Entries" then
                    UpdateNameInLedgerEntries.NotifyAboutBlankNamesInLedgerEntries(RecordId);
            end;
        }
        field(60; "Allow Inventory Adjustment"; Boolean)
        {
            Caption = 'Allow Inventory Adjustment';
            ToolTip = 'Specifies if you want to allow manual adjustment of the inventory in the item card.';
            InitValue = true;
        }
        field(180; "Invt. Cost Jnl. Template Name"; Code[10])
        {
            Caption = 'Invt. Cost Jnl. Template Name';
            ToolTip = 'Specifies the name of the journal template to use for automatic and expected cost posting.';
            TableRelation = "Gen. Journal Template";

            trigger OnValidate()
            begin
                if "Invt. Cost Jnl. Template Name" = '' then
                    "Invt. Cost Jnl. Batch Name" := '';
            end;
        }
        field(181; "Invt. Cost Jnl. Batch Name"; Code[10])
        {
            Caption = 'Jnl. Batch Name Cost Posting';
            ToolTip = 'Specifies the name of the journal batch to use for automatic and expected cost posting.';
            TableRelation = if ("Invt. Cost Jnl. Template Name" = filter(<> '')) "Gen. Journal Batch".Name where("Journal Template Name" = field("Invt. Cost Jnl. Template Name"));

            trigger OnValidate()
            begin
                TestField("Invt. Cost Jnl. Template Name");
            end;
        }
        field(5700; "Transfer Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Transfer Order Nos.';
            ToolTip = 'Specifies the number series that will be used to assign numbers to transfer orders.';
            TableRelation = "No. Series";
        }
        field(5701; "Posted Transfer Shpt. Nos."; Code[20])
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Posted Transfer Shpt. Nos.';
            ToolTip = 'Specifies the number series that will be used to assign numbers to posted transfer shipments.';
            TableRelation = "No. Series";
        }
        field(5702; "Posted Transfer Rcpt. Nos."; Code[20])
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Posted Transfer Rcpt. Nos.';
            ToolTip = 'Specifies the number series that will be used to assign numbers to posted transfer receipts.';
            TableRelation = "No. Series";
        }
        field(5703; "Copy Comments Order to Shpt."; Boolean)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Copy Comments Order to Shpt.';
            ToolTip = 'Specifies that you want to copy the comments entered on the transfer order to the transfer shipment.';
            InitValue = true;
        }
        field(5704; "Copy Comments Order to Rcpt."; Boolean)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Copy Comments Order to Rcpt.';
            ToolTip = 'Specifies that you want to copy the comments entered on the transfer order to the transfer receipt.';
            InitValue = true;
        }
        field(5718; "Nonstock Item Nos."; Code[20])
        {
            AccessByPermission = TableData "Nonstock Item" = R;
            Caption = 'Catalog Item Nos.';
            ToolTip = 'Specifies the number series that will be used to assign numbers to catalog items.';
            TableRelation = "No. Series";
        }
        field(5790; "Outbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Outbound Whse. Handling Time';
            ToolTip = 'Specifies a date formula that calculates the time it takes to get items ready to ship. The time element is used to calculate the delivery date as follows: Shipment Date + Outbound Warehouse Handling Time = Planned Shipment Date + Shipping Time = Planned Delivery Date.';
        }
        field(5791; "Inbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Inbound Whse. Handling Time';
            ToolTip = 'Specifies a date formula that calculates the time it takes to make items available in inventory after they have been received. The time element is used to calculate the expected receipt date as follows: Order Date + Lead Time Calculation = Planned Receipt Date + Inbound Warehouse Handling Time + Safety Lead Time = Expected Receipt Date.';
        }
        field(5800; "Expected Cost Posting to G/L"; Boolean)
        {
            Caption = 'Expected Cost Posting to G/L';
            ToolTip = 'Specifies if value entries originating from receipt or shipment posting, but not from invoice posting are recoded in the general ledger. Expected costs represent the estimation of, for example, a purchased item''s cost that you record before you receive the invoice for the item. To post expected costs, interim accounts must exist in the general ledger for the relevant posting groups. Expected costs are only managed for item transactions, not for immaterial transaction types, such as capacity and item charges.';

            trigger OnValidate()
            var
                ChangeExpCostPostToGL: Codeunit "Change Exp. Cost Post. to G/L";
            begin
                if "Expected Cost Posting to G/L" <> xRec."Expected Cost Posting to G/L" then
                    if ItemLedgEntry.FindFirst() then begin
                        ChangeExpCostPostToGL.ChangeExpCostPostingToGL(Rec, "Expected Cost Posting to G/L");
                        Find();
                    end;
            end;
        }
        field(5801; "Default Costing Method"; Enum "Costing Method")
        {
            Caption = 'Default Costing Method';
            ToolTip = 'Specifies how your items'' cost flow is recorded and whether an actual or budgeted value is capitalized and used in the cost calculation. Your choice of costing method determines how the unit cost is calculated by making assumptions about the flow of physical items through your company. A different costing method on item cards will override this default. For more information, see "Design Details: Costing Methods" in Help.';
        }
        field(5804; "Average Cost Calc. Type"; Enum "Average Cost Calculation Type")
        {
            Caption = 'Average Cost Calc. Type';
            ToolTip = 'Specifies how costs are calculated for items using the Average costing method. Item: One average cost per item in the company is calculated. Item & Location & Variant: An average cost per item for each location and for each variant of the item in the company is calculated. This means that the average cost of this item depends on where it is stored and which variant, such as color, of the item you have selected.';
            InitValue = "Item & Location & Variant";
            NotBlank = true;

            trigger OnValidate()
            begin
                TestField("Average Cost Calc. Type");
                if "Average Cost Calc. Type" <> xRec."Average Cost Calc. Type" then
                    UpdateAvgCostItemSettings(FieldCaption("Average Cost Calc. Type"), Format("Average Cost Calc. Type"));
            end;
        }
        field(5805; "Average Cost Period"; Enum "Average Cost Period Type")
        {
            Caption = 'Average Cost Period';
            ToolTip = 'Specifies the period of time used to calculate the weighted average cost of items that apply the average costing method. All inventory decreases that were posted within an average cost period will receive the average cost calculated for that period. If you change the average cost period, only open fiscal years will be affected.';
            InitValue = Day;
            NotBlank = true;

            trigger OnValidate()
            begin
                TestField("Average Cost Period");
                if "Average Cost Period" <> xRec."Average Cost Period" then
                    UpdateAvgCostItemSettings(FieldCaption("Average Cost Period"), Format("Average Cost Period"));
            end;
        }
        field(5849; "Allow Invt. Doc. Reservation"; Boolean)
        {
            Caption = 'Allow Invt. Doc. Reservation';
            ToolTip = 'Specifies if you want to allow reservation for inventory receipts and shipments.';
        }
        field(5850; "Invt. Receipt Nos."; Code[20])
        {
            Caption = 'Invt. Receipt Nos.';
            ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
            TableRelation = "No. Series";
        }
        field(5851; "Posted Invt. Receipt Nos."; Code[20])
        {
            Caption = 'Posted Invt. Receipt Nos.';
            ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
            TableRelation = "No. Series";
        }
        field(5852; "Invt. Shipment Nos."; Code[20])
        {
            Caption = 'Invt. Shipment Nos.';
            ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
            TableRelation = "No. Series";
        }
        field(5853; "Posted Invt. Shipment Nos."; Code[20])
        {
            Caption = 'Posted Invt. Shipment Nos.';
            ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
            TableRelation = "No. Series";
        }
        field(5854; "Copy Comments to Invt. Doc."; Boolean)
        {
            Caption = 'Copy Comments to Invt. Doc.';
            ToolTip = 'Specifies that you want to copy the comments entered on the inventory document to the posted document.';
        }
        field(5855; "Direct Transfer Posting"; Option)
        {
            Caption = 'Direct Transfer Posting';
            ToolTip = 'Specifies if Direct Transfer will be posted as Shipment and Receipt or as single Direct Transfer document. There are different restrictions associated with different modes, for example Directed Transfer document does not support partial posting.';
            OptionCaption = 'Receipt and Shipment,Direct Transfer';
            OptionMembers = "Receipt and Shipment","Direct Transfer";
        }
        field(5856; "Posted Direct Trans. Nos."; Code[20])
        {
            Caption = 'Posted Direct Trans. Nos.';
            ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
            TableRelation = "No. Series";
        }
        field(5860; "Package Nos."; Code[20])
        {
            Caption = 'Package Nos.';
            ToolTip = 'Specifies the number series that will be used to assign numbers to item tracking packages.';
            TableRelation = "No. Series";
        }
        field(5875; "Phys. Invt. Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Phys. Invt. Order Header" = R;
            Caption = 'Phys. Invt. Order Nos.';
            ToolTip = 'Specifies the number series that will be used to assign numbers to physical inventory orders.';
            TableRelation = "No. Series";
        }
        field(5876; "Posted Phys. Invt. Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Phys. Invt. Order Header" = R;
            Caption = 'Posted Phys. Invt. Order Nos.';
            ToolTip = 'Specifies the number series that will be used to assign numbers to physical inventory orders when they are posted.';
            TableRelation = "No. Series";
        }
#if not CLEANSCHEMA27
        field(5877; "Invt. Orders Package Tracking"; Boolean)
        {
            Caption = 'Invt. Orders Package Tracking';
            ObsoleteReason = 'Temporary setup to enable/disable package tracking in Phys. Inventory Orders';
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
        }
#endif
        field(6500; "Package Caption"; Text[30])
        {
            Caption = 'Package Caption';
            ToolTip = 'Specifies the alternative caption of Package tracking dimension that you want to use for captions for this dimension. For example, Size.';
        }
        field(7101; "Item Group Dimension Code"; Code[20])
        {
            Caption = 'Item Group Dimension Code';
            ToolTip = 'Specifies the dimension code that you want to use for product groups in analysis reports.';
            TableRelation = Dimension;
        }
        field(7300; "Inventory Put-away Nos."; Code[20])
        {
            AccessByPermission = TableData "Posted Invt. Put-away Header" = R;
            Caption = 'Inventory Put-away Nos.';
            ToolTip = 'Specifies the number series that will be used to assign numbers to inventory put-always.';
            TableRelation = "No. Series";
        }
        field(7301; "Inventory Pick Nos."; Code[20])
        {
            AccessByPermission = TableData "Posted Invt. Pick Header" = R;
            Caption = 'Inventory Pick Nos.';
            ToolTip = 'Specifies the number series that will be used to assign numbers to inventory picks.';
            TableRelation = "No. Series";
        }
        field(7302; "Posted Invt. Put-away Nos."; Code[20])
        {
            AccessByPermission = TableData "Posted Invt. Put-away Header" = R;
            Caption = 'Posted Invt. Put-away Nos.';
            ToolTip = 'Specifies the number series that will be used to assign numbers to posted inventory put-always.';
            TableRelation = "No. Series";
        }
        field(7303; "Posted Invt. Pick Nos."; Code[20])
        {
            AccessByPermission = TableData "Posted Invt. Pick Header" = R;
            Caption = 'Posted Invt. Pick Nos.';
            ToolTip = 'Specifies the number series that will be used to assign numbers to posted inventory picks.';
            TableRelation = "No. Series";
        }
        field(7304; "Inventory Movement Nos."; Code[20])
        {
            AccessByPermission = TableData "Whse. Internal Put-away Header" = R;
            Caption = 'Inventory Movement Nos.';
            ToolTip = 'Specifies the number series that will be used to assign numbers to inventory movements.';
            TableRelation = "No. Series";
        }
        field(7305; "Registered Invt. Movement Nos."; Code[20])
        {
            AccessByPermission = TableData "Whse. Internal Put-away Header" = R;
            Caption = 'Registered Invt. Movement Nos.';
            ToolTip = 'Specifies the number series that will be used to assign numbers to registered inventory movements.';
            TableRelation = "No. Series";
        }
        field(7306; "Internal Movement Nos."; Code[20])
        {
            AccessByPermission = TableData "Whse. Internal Put-away Header" = R;
            Caption = 'Internal Movement Nos.';
            ToolTip = 'Specifies the number series that will be used to assign numbers to internal movements.';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        ItemLedgEntry: Record "Item Ledger Entry";
        Item: Record Item;
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ObjTransl: Record "Object Translation";

#pragma warning disable AA0074
        Text000: Label 'Some unadjusted value entries will not be covered with the new setting. You must run the Adjust Cost - Item Entries batch job once to adjust these.';
        Text004: Label 'The program has cancelled the change that would have caused an adjustment of all items.';
#pragma warning disable AA0470
        Text005: Label '%1 has been changed to %2. You should now run %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ItemEntriesAdjustQst: Label 'If you change the %1, the program must adjust all item entries.The adjustment of all entries can take several hours.\Do you really want to change the %1?', Comment = '%1 - field caption';

    procedure GetRecordOnce()
    var
        InventorySetupCodeunit: Codeunit "Inventory Setup";
    begin
        InventorySetupCodeunit.GetSetup(Rec);
    end;

    local procedure UpdateInvtAdjmtEntryOrder()
    var
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        InvtAdjmtEntryOrder.SetCurrentKey("Cost is Adjusted", "Allow Online Adjustment");
        InvtAdjmtEntryOrder.SetRange("Cost is Adjusted", false);
        InvtAdjmtEntryOrder.SetRange("Allow Online Adjustment", false);
        InvtAdjmtEntryOrder.SetRange("Is Finished", false);
        InvtAdjmtEntryOrder.SetRange("Order Type", InvtAdjmtEntryOrder."Order Type"::Production);
        InvtAdjmtEntryOrder.ModifyAll("Allow Online Adjustment", true);
    end;

    local procedure UpdateItem()
    var
        LocalItem: Record Item;
    begin
        LocalItem.Copy(Item);
        LocalItem.SetRange("Allow Online Adjustment", false);
        if not LocalItem.IsEmpty() then
            LocalItem.ModifyAll("Allow Online Adjustment", true);
    end;

    local procedure UpdateAvgCostItemSettings(FieldCaption: Text[80]; FieldValue: Text[80])
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(ItemEntriesAdjustQst, FieldCaption), false)
        then
            Error(Text004);

        CODEUNIT.Run(CODEUNIT::"Change Average Cost Setting", Rec);

        Message(
          Text005, FieldCaption, FieldValue,
          ObjTransl.TranslateObject(ObjTransl."Object Type"::Report, REPORT::"Adjust Cost - Item Entries"));
    end;

    procedure OptimGLEntLockForMultiuserEnv(): Boolean
    begin
        if Rec.Get() then
            if Rec."Automatic Cost Posting" then
                exit(false);

        exit(true);
    end;

    procedure AutomaticCostAdjmtRequired(): Boolean
    begin
        exit("Automatic Cost Adjustment" <> "Automatic Cost Adjustment"::Never);
    end;

    procedure UseLegacyPosting(): Boolean
    var
        FeatureKeyManagement: Codeunit System.Environment.Configuration."Feature Key Management";
    begin
        exit(not FeatureKeyManagement.IsConcurrentInventoryPostingEnabled());
    end;

    procedure GetComponentsAtLocation() LocationCode: Code[10]
    begin
        OnGetComponentsAtLocation(LocationCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetComponentsAtLocation(var LocationCode: Code[10])
    begin
    end;
}