// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.Setup;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Calendar;
using Microsoft.Inventory;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

table 5700 "Stockkeeping Unit"
{
    Caption = 'Stockkeeping Unit';
    DrillDownPageID = "Stockkeeping Unit List";
    LookupPageID = "Stockkeeping Unit List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            OptimizeForTextSearch = true;
            NotBlank = true;
            TableRelation = Item where(Type = const(Inventory));

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if "Item No." = xRec."Item No." then
                    exit;

                if Item.Get("Item No.") then
                    CopyFromItem(Item);

                CalcFields(Description, "Description 2", "Assembly BOM", Inventory);
            end;
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                CalcFields(
                  Inventory, "Qty. on Purch. Order", "Qty. in Transit",
                  "Qty. on Sales Order", "Qty. on Job Order",
                  "Qty. on Assembly Order", "Qty. on Asm. Component");
            end;
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            begin
                if "Location Code" = '' then
                    Validate("Replenishment System");
                CheckTransferRoute();
                CalcFields(
                  Inventory, "Qty. on Purch. Order", "Qty. in Transit",
                  "Qty. on Sales Order", "Qty. on Job Order",
                  "Qty. on Assembly Order", "Qty. on Asm. Component");
            end;
        }
        field(4; Description; Text[100])
        {
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
            Caption = 'Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Description 2"; Text[50])
        {
            CalcFormula = lookup(Item."Description 2" where("No." = field("Item No.")));
            Caption = 'Description 2';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Assembly BOM"; Boolean)
        {
            CalcFormula = exist("BOM Component" where("Parent Item No." = field("Item No.")));
            Caption = 'Assembly BOM';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
        }
        field(22; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            begin
                Item.Get("Item No.");

                if Item.IsNonInventoriableType() then
                    exit;

                if Item."Costing Method" = Item."Costing Method"::Standard then
                    Validate("Standard Cost", "Unit Cost")
                else
                    TestNoEntriesExist(FieldCaption("Unit Cost"));
            end;
        }
        field(24; "Standard Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Standard Cost';
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateStandardCost(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                Item.Get("Item No.");
                if (Item."Costing Method" = Item."Costing Method"::Standard) and (CurrFieldNo <> 0) then
                    if not
                       Confirm(
                         Text001 +
                         Text002 +
                         Text003, false,
                         FieldCaption("Standard Cost"))
                    then begin
                        "Standard Cost" := xRec."Standard Cost";
                        exit;
                    end;

                ItemCostMgt.UpdateUnitCostSKU(Item, Rec, 0, 0, true, FieldNo("Standard Cost"));
            end;
        }
        field(25; "Last Direct Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Last Direct Cost';
            MinValue = 0;
        }
        field(31; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;

            trigger OnValidate()
            begin
                if (xRec."Vendor No." <> "Vendor No.") and
                   ("Vendor No." <> '')
                then
                    if Vend.Get("Vendor No.") then
                        "Lead Time Calculation" := Vend."Lead Time Calculation";
            end;
        }
        field(32; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
            OptimizeForTextSearch = true;
        }
        field(33; "Lead Time Calculation"; DateFormula)
        {
            Caption = 'Lead Time Calculation';

            trigger OnValidate()
            begin
                LeadTimeMgt.CheckLeadTimeIsNotNegative("Lead Time Calculation");
            end;
        }
        field(34; "Reorder Point"; Decimal)
        {
            Caption = 'Reorder Point';
            DecimalPlaces = 0 : 5;
        }
        field(35; "Maximum Inventory"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Maximum Inventory';
            DecimalPlaces = 0 : 5;
        }
        field(36; "Reorder Quantity"; Decimal)
        {
            Caption = 'Reorder Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(53; Comment; Boolean)
        {
            CalcFormula = exist("Stockkeeping Unit Comment Line" where("Item No." = field("Item No."),
                                                                        "Variant Code" = field("Variant Code"),
                                                                        "Location Code" = field("Location Code")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(64; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(65; "Global Dimension 1 Filter"; Code[20])
        {
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(66; "Global Dimension 2 Filter"; Code[20])
        {
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(68; Inventory; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("Item No."),
                                                                  "Location Code" = field("Location Code"),
                                                                  "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                  "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                  "Drop Shipment" = field("Drop Shipment Filter"),
                                                                  "Variant Code" = field("Variant Code")));
            Caption = 'Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(84; "Qty. on Purch. Order"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("Purchase Line"."Outstanding Qty. (Base)" where("Document Type" = const(Order),
                                                                               Type = const(Item),
                                                                               "No." = field("Item No."),
                                                                               "Location Code" = field("Location Code"),
                                                                               "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                               "Drop Shipment" = field("Drop Shipment Filter"),
                                                                               "Variant Code" = field("Variant Code"),
                                                                               "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Qty. on Purch. Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(85; "Qty. on Sales Order"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = sum("Sales Line"."Outstanding Qty. (Base)" where("Document Type" = const(Order),
                                                                            Type = const(Item),
                                                                            "No." = field("Item No."),
                                                                            "Location Code" = field("Location Code"),
                                                                            "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                            "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                            "Drop Shipment" = field("Drop Shipment Filter"),
                                                                            "Variant Code" = field("Variant Code"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Qty. on Sales Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(89; "Drop Shipment Filter"; Boolean)
        {
            Caption = 'Drop Shipment Filter';
            FieldClass = FlowFilter;
        }
        field(910; "Assembly Policy"; Enum "Assembly Policy")
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Assembly Policy';

            trigger OnValidate()
            begin
                if "Assembly Policy" = "Assembly Policy"::"Assemble-to-Order" then
                    TestField("Replenishment System", "Replenishment System"::Assembly);
            end;
        }
        field(977; "Qty. on Assembly Order"; Decimal)
        {
            CalcFormula = sum("Assembly Header"."Remaining Quantity (Base)" where("Document Type" = const(Order),
                                                                                   "Item No." = field("Item No."),
                                                                                   "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                   "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                   "Location Code" = field("Location Code"),
                                                                                   "Variant Code" = field("Variant Code"),
                                                                                   "Due Date" = field("Date Filter")));
            Caption = 'Qty. on Assembly Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(978; "Qty. on Asm. Component"; Decimal)
        {
            CalcFormula = sum("Assembly Line"."Remaining Quantity (Base)" where("Document Type" = const(Order),
                                                                                 Type = const(Item),
                                                                                 "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                 "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                 "No." = field("Item No."),
                                                                                 "Location Code" = field("Location Code"),
                                                                                 "Variant Code" = field("Variant Code"),
                                                                                 "Due Date" = field("Date Filter")));
            Caption = 'Qty. on Asm. Component';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(1001; "Qty. on Job Order"; Decimal)
        {
            CalcFormula = sum("Job Planning Line"."Remaining Qty. (Base)" where(Status = const(Order),
                                                                                 Type = const(Item),
                                                                                 "No." = field("Item No."),
                                                                                 "Location Code" = field("Location Code"),
                                                                                 "Variant Code" = field("Variant Code"),
                                                                                 "Planning Date" = field("Date Filter")));
            Caption = 'Qty. on Project Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5400; "Transfer-Level Code"; Integer)
        {
            Caption = 'Transfer-Level Code';
            Editable = false;
        }
        field(5401; "Lot Size"; Decimal)
        {
            Caption = 'Lot Size';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5410; "Discrete Order Quantity"; Integer)
        {
            Caption = 'Discrete Order Quantity';
            MinValue = 0;
        }
        field(5411; "Minimum Order Quantity"; Decimal)
        {
            Caption = 'Minimum Order Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5412; "Maximum Order Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Maximum Order Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5413; "Safety Stock Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Safety Stock Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5414; "Order Multiple"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Order Multiple';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5415; "Safety Lead Time"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Safety Lead Time';

            trigger OnValidate()
            begin
                CalendarMgt.CheckDateFormulaPositive("Safety Lead Time");
            end;
        }
        field(5416; "Components at Location"; Code[10])
        {
            Caption = 'Components at Location';
            TableRelation = Location;
        }
        field(5417; "Flushing Method"; Enum Microsoft.Manufacturing.Setup."Flushing Method")
        {
            Caption = 'Flushing Method';
            DataClassification = CustomerContent;
        }
        field(5419; "Replenishment System"; Enum "Replenishment System")
        {
            Caption = 'Replenishment System';

            trigger OnValidate()
            begin
                if "Replenishment System" <> "Replenishment System"::Assembly then
                    TestField("Assembly Policy", "Assembly Policy"::"Assemble-to-Stock");

                case "Replenishment System" of
                    "Replenishment System"::Purchase,
                    "Replenishment System"::"Prod. Order",
                    "Replenishment System"::Assembly:
                        begin
                            "Transfer-Level Code" := 0;
                            FromLocation := "Transfer-from Code";
                            if not UpdateTransferLevels(Rec) then
                                ShowLoopError();
                        end;
                    "Replenishment System"::Transfer:
                        begin
                            if "Location Code" = '' then
                                Error(
                                  Text004,
                                  FieldCaption("Location Code"), TableCaption(),
                                  "Replenishment System", FieldCaption("Replenishment System"));
                            Validate("Transfer-from Code");
                        end;
                    else
                        OnValidateReplenishmentSystemCaseElse(Rec);
                end;
            end;
        }
        field(5423; "Bin Filter"; Code[20])
        {
            Caption = 'Bin Filter';
            FieldClass = FlowFilter;
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(5428; "Time Bucket"; DateFormula)
        {
            Caption = 'Time Bucket';

            trigger OnValidate()
            begin
                CalendarMgt.CheckDateFormulaPositive("Time Bucket");
            end;
        }
        field(5440; "Reordering Policy"; Enum "Reordering Policy")
        {
            Caption = 'Reordering Policy';

            trigger OnValidate()
            begin
                "Include Inventory" :=
                  "Reordering Policy" in ["Reordering Policy"::"Lot-for-Lot",
                                          "Reordering Policy"::"Maximum Qty.",
                                          "Reordering Policy"::"Fixed Reorder Qty."];
            end;
        }
        field(5441; "Include Inventory"; Boolean)
        {
            Caption = 'Include Inventory';
        }
        field(5442; "Manufacturing Policy"; Enum Microsoft.Manufacturing.Setup."Manufacturing Policy")
        {
            Caption = 'Manufacturing Policy';
        }
        field(5443; "Rescheduling Period"; DateFormula)
        {
            Caption = 'Rescheduling Period';

            trigger OnValidate()
            begin
                CalendarMgt.CheckDateFormulaPositive("Rescheduling Period");
            end;
        }
        field(5444; "Lot Accumulation Period"; DateFormula)
        {
            Caption = 'Lot Accumulation Period';

            trigger OnValidate()
            begin
                CalendarMgt.CheckDateFormulaPositive("Lot Accumulation Period");
            end;
        }
        field(5445; "Dampener Period"; DateFormula)
        {
            Caption = 'Dampener Period';

            trigger OnValidate()
            begin
                CalendarMgt.CheckDateFormulaPositive("Dampener Period");
            end;
        }
        field(5446; "Dampener Quantity"; Decimal)
        {
            Caption = 'Dampener Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5447; "Overflow Level"; Decimal)
        {
            Caption = 'Overflow Level';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5448; "Plan Minimal Supply"; Boolean)
        {
            Caption = 'Plan Minimal Supply';
        }
        field(5700; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            var
                FromSKU: Record "Stockkeeping Unit";
                IsHandled: Boolean;
            begin
                FromSKU.SetRange("Location Code", "Transfer-from Code");
                FromSKU.SetRange("Item No.", "Item No.");
                FromSKU.SetRange("Variant Code", "Variant Code");
                if not FromSKU.FindFirst() then
                    "Transfer-Level Code" := -1
                else
                    "Transfer-Level Code" := FromSKU."Transfer-Level Code" - 1;
                FromLocation := "Transfer-from Code";
                IsHandled := false;
                OnValidateTransferfromCodeOnBeforeModify(Rec, IsHandled);
                if not IsHandled then
                    Modify(true);

                CheckTransferRoute();
            end;
        }
        field(5701; "Qty. in Transit"; Decimal)
        {
            CalcFormula = sum("Transfer Line"."Qty. in Transit (Base)" where("Derived From Line No." = const(0),
                                                                              "Item No." = field("Item No."),
                                                                              "Transfer-to Code" = field("Location Code"),
                                                                              "Variant Code" = field("Variant Code"),
                                                                              "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "Receipt Date" = field("Date Filter")));
            Caption = 'Qty. in Transit';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5702; "Trans. Ord. Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Transfer Line"."Outstanding Qty. (Base)" where("Derived From Line No." = const(0),
                                                                               "Item No." = field("Item No."),
                                                                               "Transfer-to Code" = field("Location Code"),
                                                                               "Variant Code" = field("Variant Code"),
                                                                               "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                               "Receipt Date" = field("Date Filter")));
            Caption = 'Trans. Ord. Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5703; "Trans. Ord. Shipment (Qty.)"; Decimal)
        {
            CalcFormula = sum("Transfer Line"."Outstanding Qty. (Base)" where("Derived From Line No." = const(0),
                                                                               "Item No." = field("Item No."),
                                                                               "Transfer-from Code" = field("Location Code"),
                                                                               "Variant Code" = field("Variant Code"),
                                                                               "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                               "Shipment Date" = field("Date Filter")));
            Caption = 'Trans. Ord. Shipment (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(7301; "Special Equipment Code"; Code[10])
        {
            Caption = 'Special Equipment Code';
            TableRelation = "Special Equipment";
        }
        field(7302; "Put-away Template Code"; Code[10])
        {
            Caption = 'Put-away Template Code';
            TableRelation = "Put-away Template Header";
        }
        field(7307; "Put-away Unit of Measure Code"; Code[10])
        {
            Caption = 'Put-away Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(7380; "Phys Invt Counting Period Code"; Code[10])
        {
            Caption = 'Phys Invt Counting Period Code';
            TableRelation = "Phys. Invt. Counting Period";

            trigger OnValidate()
            var
                PhysInvtCountPeriod: Record "Phys. Invt. Counting Period";
                PhysInvtCountPeriodMgt: Codeunit "Phys. Invt. Count.-Management";
            begin
                if "Phys Invt Counting Period Code" <> '' then begin
                    PhysInvtCountPeriod.Get("Phys Invt Counting Period Code");
                    PhysInvtCountPeriod.TestField("Count Frequency per Year");
                    if "Phys Invt Counting Period Code" <> xRec."Phys Invt Counting Period Code" then begin
                        if CurrFieldNo <> 0 then
                            if not Confirm(
                                 Text7380,
                                 false,
                                 FieldCaption("Phys Invt Counting Period Code"),
                                 FieldCaption("Next Counting Start Date"),
                                 FieldCaption("Next Counting End Date"))
                            then
                                Error(Text7381);

                        if ("Last Counting Period Update" = 0D) or
                           ("Phys Invt Counting Period Code" <> xRec."Phys Invt Counting Period Code")
                        then
                            PhysInvtCountPeriodMgt.CalcPeriod(
                              "Last Counting Period Update", "Next Counting Start Date", "Next Counting End Date",
                              PhysInvtCountPeriod."Count Frequency per Year");
                    end;
                end else begin
                    if not HideValidationDialog then
                        if not Confirm(Text003, false, FieldCaption("Phys Invt Counting Period Code")) then
                            Error(Text7381);
                    "Next Counting Start Date" := 0D;
                    "Next Counting End Date" := 0D;
                    "Last Counting Period Update" := 0D;
                end;
            end;
        }
        field(7381; "Last Counting Period Update"; Date)
        {
            Caption = 'Last Counting Period Update';
            Editable = false;
        }
        field(7383; "Last Phys. Invt. Date"; Date)
        {
            CalcFormula = max("Phys. Inventory Ledger Entry"."Posting Date" where("Item No." = field("Item No."),
                                                                                   "Location Code" = field("Location Code"),
                                                                                   "Variant Code" = field("Variant Code"),
                                                                                   "Phys Invt Counting Period Type" = filter(" " | SKU)));
            Caption = 'Last Phys. Invt. Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7384; "Use Cross-Docking"; Boolean)
        {
            AccessByPermission = TableData "Bin Content" = R;
            Caption = 'Use Cross-Docking';
            InitValue = true;
        }
        field(7385; "Next Counting Start Date"; Date)
        {
            Caption = 'Next Counting Start Date';
        }
        field(7386; "Next Counting End Date"; Date)
        {
            Caption = 'Next Counting End Date';
        }
        field(9110; "Qty. on Blanket Sales Order"; Decimal)
        {
            CalcFormula = sum("Sales Line"."Outstanding Qty. (Base)" where("Document Type" = const("Blanket Order"),
                                                                            Type = const(Item),
                                                                            "No." = field("Item No."),
                                                                            "Location Code" = field("Location Code"),
                                                                            "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                            "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                            "Drop Shipment" = field("Drop Shipment Filter"),
                                                                            "Variant Code" = field("Variant Code"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Qty. on Blanket Sales Order';
            ToolTip = 'Specifies how many units of the item are allocated to blanket sales orders, meaning listed on outstanding blanket sales order lines.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(9210; "Qty. on Blanket Purch. Order"; Decimal)
        {
            CalcFormula = sum("Purchase Line"."Outstanding Qty. (Base)" where("Document Type" = const("Blanket Order"),
                                                                            Type = const(Item),
                                                                            "No." = field("Item No."),
                                                                            "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                            "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                            "Location Code" = field("Location Code"),
                                                                            "Drop Shipment" = field("Drop Shipment Filter"),
                                                                            "Variant Code" = field("Variant Code"),
                                                                            "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Qty. on Blanket Purch. Order';
            ToolTip = 'Specifies how many units of the item are allocated to blanket purchase orders, meaning listed on outstanding blanket purchase order lines.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(99000770; "Purch. Req. Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Requisition Line"."Quantity (Base)" where(Type = const(Item),
                                                                          "No." = field("Item No."),
                                                                          "Location Code" = field("Location Code"),
                                                                          "Variant Code" = field("Variant Code"),
                                                                          "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Due Date" = field("Date Filter")));
            Caption = 'Purch. Req. Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
        }
        field(99000771; "Purch. Req. Release (Qty.)"; Decimal)
        {
            CalcFormula = sum("Requisition Line"."Quantity (Base)" where(Type = const(Item),
                                                                          "No." = field("Item No."),
                                                                          "Location Code" = field("Location Code"),
                                                                          "Variant Code" = field("Variant Code"),
                                                                          "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Order Date" = field("Date Filter")));
            Caption = 'Purch. Req. Release (Qty.)';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
        }
        field(5404; "Rolled-up Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Material Cost';
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(5405; "Rolled-up Capacity Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Capacity Cost';
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(5407; "Scrap %"; Decimal)
        {
            Caption = 'Scrap %';
            DecimalPlaces = 0 : 2;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5408; "Rolled-up Mat. Non-Invt. Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Material Non-Inventory Cost';
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(99000752; "Single-Level Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Material Cost';
            Editable = false;
        }
        field(99000753; "Single-Level Capacity Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Capacity Cost';
            Editable = false;
        }
        field(99000754; "Single-Level Subcontrd. Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Subcontrd. Cost';
            Editable = false;
        }
        field(99000755; "Single-Level Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Cap. Ovhd Cost';
            Editable = false;
        }
        field(99000756; "Single-Level Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Mfg. Ovhd Cost';
            Editable = false;
        }
        field(99000758; "Rolled-up Subcontracted Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Subcontracted Cost';
            Editable = false;
        }
        field(99000759; "Rolled-up Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Mfg. Ovhd Cost';
            Editable = false;
        }
        field(99000760; "Rolled-up Cap. Overhead Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Cap. Overhead Cost';
            Editable = false;
        }
        field(99000779; "Single-Lvl Mat. Non-Invt. Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Material Non-Inventory Cost';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Location Code", "Item No.", "Variant Code")
        {
            Clustered = true;
        }
        key(Key2; "Replenishment System", "Vendor No.", "Transfer-from Code")
        {
        }
        key(Key3; "Item No.", "Location Code", "Variant Code")
        {
        }
        key(Key4; "Item No.", "Transfer-Level Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        StockkeepingCommentLine: Record "Stockkeeping Unit Comment Line";
    begin
        StockkeepingCommentLine.SetRange("Item No.", "Item No.");
        StockkeepingCommentLine.SetRange("Variant Code", "Variant Code");
        StockkeepingCommentLine.SetRange("Location Code", "Location Code");
        StockkeepingCommentLine.DeleteAll();
    end;

    trigger OnInsert()
    begin
        if ("Variant Code" = '') and
           ("Location Code" = '')
        then
            Error(
              Text000,
              FieldCaption("Location Code"), FieldCaption("Variant Code"), TableCaption);

        "Last Date Modified" := Today;
        PlanningAssignment.AssignOne("Item No.", "Variant Code", "Location Code", WorkDate());
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
        PlanningAssignment.SKUChange(Rec, xRec);
    end;

    trigger OnRename()
    begin
        if ("Variant Code" = '') and
           ("Location Code" = '')
        then
            Error(
              Text000,
              FieldCaption("Location Code"), FieldCaption("Variant Code"), TableCaption);

        "Last Date Modified" := Today;
    end;

    var
        TransferRoute: Record "Transfer Route";
        Item: Record Item;
        PlanningAssignment: Record "Planning Assignment";
        Vend: Record Vendor;
        ItemCostMgt: Codeunit ItemCostManagement;
        CalendarMgt: Codeunit "Calendar Management";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        FromLocation: Code[10];
        ErrorString: Text[80];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You must specify a %1 or a %2 for each %3.';
#pragma warning restore AA0470
        Text001: Label 'There may be orders and open ledger entries for the item. ';
#pragma warning disable AA0470
        Text002: Label 'If you change %1 it may affect new orders and entries.\\';
        Text003: Label 'Do you want to change %1?';
        Text004: Label 'You must specify a %1 for this %2 to use %3 as %4.';
        Text005: Label 'You must specify a %1 from %2 %3 to %2 %4.';
        Text006: Label 'A circular reference in %1 has been detected:\%2 ->%3 ->%4';
        Text008: Label 'You cannot change %1 because there are one or more ledger entries for this SKU.';
        Text7380: Label 'If you change the %1, the %2 and %3 are calculated.\Do you still want to change the %1?', Comment = 'If you change the Phys Invt Counting Period Code, the Next Counting Start Date and Next Counting End Date are calculated.\Do you still want to change the Phys Invt Counting Period Code?';
#pragma warning restore AA0470
        Text7381: Label 'Cancelled.';
#pragma warning restore AA0074

    protected var
        HideValidationDialog: Boolean;

    local procedure TransferRouteExists(TransferFromCode: Code[10]; TransferToCode: Code[10]): Boolean
    begin
        TransferRoute.SetRange("Transfer-from Code", TransferFromCode);
        TransferRoute.SetRange("Transfer-to Code", TransferToCode);
        exit(TransferRoute.FindFirst());
    end;

    local procedure UpdateTransferLevels(FromSKU: Record "Stockkeeping Unit"): Boolean
    var
        ToSKU: Record "Stockkeeping Unit";
    begin
        ToSKU.SetCurrentKey("Replenishment System", "Vendor No.", "Transfer-from Code");
        ToSKU.SetRange("Replenishment System", "Replenishment System"::Transfer);
        ToSKU.SetRange("Transfer-from Code", FromSKU."Location Code");
        ToSKU.SetRange("Item No.", FromSKU."Item No.");
        ToSKU.SetRange("Variant Code", FromSKU."Variant Code");
        if ToSKU.Find('-') then
            repeat
                if ToSKU."Location Code" = FromLocation then begin
                    ErrorString := ToSKU."Location Code";
                    exit(false);
                end;
                ToSKU."Transfer-Level Code" := FromSKU."Transfer-Level Code" - 1;
                ToSKU.Modify();
                if not UpdateTransferLevels(ToSKU) then begin
                    if (StrLen(ErrorString) + StrLen(ToSKU."Location Code")) >
                       (MaxStrLen(ErrorString) - 9)
                    then begin
                        ErrorString := ErrorString + ' ->...';
                        ShowLoopError();
                    end;
                    ErrorString := ErrorString + ' ->' + ToSKU."Location Code";
                    exit(false);
                end;
            until ToSKU.Next() = 0;
        exit(true);
    end;

    local procedure ShowLoopError()
    begin
        Error(Text006, FieldCaption("Transfer-from Code"), ErrorString, "Location Code", "Transfer-from Code");
    end;

    procedure IsMfgSKU() Result: Boolean
    begin
        Result := "Replenishment System" = "Replenishment System"::"Prod. Order";
    end;

    procedure IsAssemblySKU() Result: Boolean
    begin
        Result := Rec."Replenishment System" = Rec."Replenishment System"::Assembly;
    end;

    protected procedure TestNoEntriesExist(CurrentFieldName: Text[100])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", "Item No.");
        ItemLedgEntry.SetRange("Variant Code", "Variant Code");
        ItemLedgEntry.SetRange("Location Code", "Location Code");
        if not ItemLedgEntry.IsEmpty() then
            Error(
              Text008,
              CurrentFieldName);
    end;

    procedure UpdateTempSKUTransferLevels(FromSKU: Record "Stockkeeping Unit"; var TempToSKU: Record "Stockkeeping Unit" temporary; FromLocationCode: Code[10]): Boolean
    var
        SavedPositionSKU: Record "Stockkeeping Unit";
    begin
        // Used by the planning engine to update the transfer level codes on a temporary SKU record set
        // generated based on actual transfer orders.

        TempToSKU.Reset();
        TempToSKU.SetCurrentKey("Item No.", "Location Code", "Variant Code");
        TempToSKU.SetRange("Transfer-from Code", FromSKU."Location Code");
        TempToSKU.SetRange("Item No.", FromSKU."Item No.");
        TempToSKU.SetRange("Variant Code", FromSKU."Variant Code");
        if TempToSKU.Find('-') then
            repeat
                if TempToSKU."Location Code" = FromLocationCode then begin
                    ErrorString := TempToSKU."Location Code";
                    exit(false);
                end;
                TempToSKU."Transfer-Level Code" := FromSKU."Transfer-Level Code" - 1;
                TempToSKU.Modify();

                SavedPositionSKU.Copy(TempToSKU);
                if not TempToSKU.UpdateTempSKUTransferLevels(TempToSKU, TempToSKU, FromLocationCode) then begin
                    if (StrLen(ErrorString) + StrLen(TempToSKU."Location Code")) >
                       (MaxStrLen(ErrorString) - 9)
                    then begin
                        ErrorString := ErrorString + ' ->...';
                        Error(
                          Text006,
                          FieldCaption("Transfer-from Code"), ErrorString, "Location Code", "Transfer-from Code");
                    end;
                    ErrorString := ErrorString + ' ->' + TempToSKU."Location Code";
                    exit(false);
                end;
                TempToSKU.Copy(SavedPositionSKU);
            until TempToSKU.Next() = 0;
        exit(true);
    end;

    local procedure CheckTransferRoute()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTransferRoute(Rec, IsHandled);
        if IsHandled then
            exit;

        if not UpdateTransferLevels(Rec) then
            ShowLoopError();

        if "Transfer-from Code" <> '' then
            if not TransferRouteExists("Transfer-from Code", "Location Code") then
                Error(
                  Text005,
                  TransferRoute.TableCaption(),
                  FieldCaption("Location Code"),
                  "Transfer-from Code",
                  "Location Code");
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure CopyFromItem(Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        OnBeforeCopyFromItem(Rec, Item, IsHandled);
        if IsHandled then
            exit;

        "Shelf No." := Item."Shelf No.";
        "Vendor No." := Item."Vendor No.";
        "Vendor Item No." := Item."Vendor Item No.";
        "Lead Time Calculation" := Item."Lead Time Calculation";
        "Reorder Point" := Item."Reorder Point";
        "Maximum Inventory" := Item."Maximum Inventory";
        "Reorder Quantity" := Item."Reorder Quantity";
        "Reordering Policy" := Item."Reordering Policy";
        "Include Inventory" := Item."Include Inventory";
        "Manufacturing Policy" := Item."Manufacturing Policy";
        "Discrete Order Quantity" := Item."Discrete Order Quantity";
        "Minimum Order Quantity" := Item."Minimum Order Quantity";
        "Maximum Order Quantity" := Item."Maximum Order Quantity";
        "Safety Stock Quantity" := Item."Safety Stock Quantity";
        "Order Multiple" := Item."Order Multiple";
        "Safety Lead Time" := Item."Safety Lead Time";
        "Replenishment System" := Item."Replenishment System";
        "Time Bucket" := Item."Time Bucket";
        "Rescheduling Period" := Item."Rescheduling Period";
        "Lot Accumulation Period" := Item."Lot Accumulation Period";
        "Dampener Period" := Item."Dampener Period";
        "Dampener Quantity" := Item."Dampener Quantity";
        "Overflow Level" := Item."Overflow Level";
        "Lot Size" := Item."Lot Size";
        "Assembly Policy" := Item."Assembly Policy";
        "Last Direct Cost" := Item."Last Direct Cost";
        "Standard Cost" := Item."Standard Cost";
        "Unit Cost" := Item."Unit Cost";
        "Flushing Method" := Item."Flushing Method";

        OnAfterCopyFromItem(Rec, Item);
    end;

    procedure TransferManufCostsFromItem(Item: Record Item)
    begin
        "Single-Level Material Cost" := Item."Single-Level Material Cost";
        "Single-Level Capacity Cost" := Item."Single-Level Capacity Cost";
        "Single-Level Subcontrd. Cost" := Item."Single-Level Subcontrd. Cost";
        "Single-Level Cap. Ovhd Cost" := Item."Single-Level Cap. Ovhd Cost";
        "Single-Level Mfg. Ovhd Cost" := Item."Single-Level Mfg. Ovhd Cost";
        "Single-Lvl Mat. Non-Invt. Cost" := Item."Single-Lvl Mat. Non-Invt. Cost";

        "Rolled-up Material Cost" := Item."Rolled-up Material Cost";
        "Rolled-up Capacity Cost" := Item."Rolled-up Capacity Cost";
        "Rolled-up Subcontracted Cost" := Item."Rolled-up Subcontracted Cost";
        "Rolled-up Mfg. Ovhd Cost" := Item."Rolled-up Mfg. Ovhd Cost";
        "Rolled-up Cap. Overhead Cost" := Item."Rolled-up Cap. Overhead Cost";
        "Rolled-up Mat. Non-Invt. Cost" := Item."Rolled-up Mat. Non-Invt. Cost";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromItem(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromItem(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransferRoute(var StockkeepingUnit: Record "Stockkeeping Unit"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateStandardCost(var StockkeepingUnit: Record "Stockkeeping Unit"; xStockkeepingUnit: Record "Stockkeeping Unit"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTransferfromCodeOnBeforeModify(var StockkeepingUnit: Record "Stockkeeping Unit"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReplenishmentSystemCaseElse(var StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;
}

