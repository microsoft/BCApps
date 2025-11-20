// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.Graph;
using Microsoft.Inventory;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.ADCS;
using Microsoft.Warehouse.Setup;
using System.Automation;
using System.Text;
using System.Reflection;
using System.DateTime;
using System.Utilities;

table 27 Item
{
    Caption = 'Item';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Item List";
    LookupPageID = "Item Lookup";
    Permissions = TableData "Bin Content" = d,
                  TableData "Planning Assignment" = d;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateNo(IsHandled, Rec, xRec, InventorySetup);
                if IsHandled then
                    exit;
                if "No." <> xRec."No." then begin
                    GetInvtSetup();
                    NoSeries.TestManual(InventorySetup."Item Nos.");
                    "No. Series" := '';
                    if xRec."No." = '' then
                        "Costing Method" := InventorySetup."Default Costing Method";
                end;
            end;
        }
        field(2; "No. 2"; Code[20])
        {
            Caption = 'No. 2';
            ToolTip = 'Specifies an alternative account number which can be used internally in the company.';
            OptimizeForTextSearch = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            begin
                if ("Search Description" = UpperCase(xRec.Description)) or ("Search Description" = '') then
                    "Search Description" := CopyStr(Description, 1, MaxStrLen("Search Description"));

                if "Created From Nonstock Item" then begin
                    NonstockItem.SetCurrentKey("Item No.");
                    NonstockItem.SetRange("Item No.", "No.");
                    if NonstockItem.FindFirst() then
                        if NonstockItem.Description = '' then begin
                            NonstockItem.Description := Description;
                            NonstockItem.Modify();
                        end;
                end;

                UpdateMyItem(FieldNo(Description));
            end;
        }
        field(4; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
            OptimizeForTextSearch = true;
        }
        field(5; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            OptimizeForTextSearch = true;
        }
        field(6; "Assembly BOM"; Boolean)
        {
            CalcFormula = exist("BOM Component" where("Parent Item No." = field("No.")));
            Caption = 'Assembly BOM';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            TableRelation = "Unit of Measure";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                TempItem: Record Item temporary;
                UnitOfMeasure: Record "Unit of Measure";
                IsHandled: Boolean;
                ValidateBaseUnitOfMeasure: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBaseUnitOfMeasure(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if CurrentClientType() in [ClientType::ODataV4, ClientType::API] then
                    if not TempItem.Get(Rec."No.") and IsNullGuid(Rec.SystemId) then
                        Rec.Insert(true);

                UpdateUnitOfMeasureId();

                OnValidateBaseUnitOfMeasure(ValidateBaseUnitOfMeasure);

                if not ValidateBaseUnitOfMeasure then
                    ValidateBaseUnitOfMeasure := "Base Unit of Measure" <> xRec."Base Unit of Measure";

                if ValidateBaseUnitOfMeasure then begin
                    TestNoOpenEntriesExist(FieldCaption("Base Unit of Measure"));

                    if "Base Unit of Measure" <> '' then begin
                        // If we can't find a Unit of Measure with a GET,
                        // then try with International Standard Code, as some times it's used as Code
                        if not UnitOfMeasure.Get("Base Unit of Measure") then begin
                            UnitOfMeasure.SetRange("International Standard Code", "Base Unit of Measure");
                            if not UnitOfMeasure.FindFirst() then
                                Error(UnitOfMeasureNotExistErr, "Base Unit of Measure");
                            "Base Unit of Measure" := UnitOfMeasure.Code;
                        end;

                        if not ItemUnitOfMeasure.Get("No.", "Base Unit of Measure") then
                            CreateItemUnitOfMeasure()
                        else
                            if ItemUnitOfMeasure."Qty. per Unit of Measure" <> 1 then
                                Error(BaseUnitOfMeasureQtyMustBeOneErr, "Base Unit of Measure", ItemUnitOfMeasure."Qty. per Unit of Measure");
                        UpdateQtyRoundingPrecisionForBaseUoM();
                    end;
                    "Sales Unit of Measure" := "Base Unit of Measure";
                    "Purch. Unit of Measure" := "Base Unit of Measure";
                end;
            end;
        }
        field(9; "Price Unit Conversion"; Integer)
        {
            Caption = 'Price Unit Conversion';
        }
        field(10; Type; Enum "Item Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnValidateTypeOnBeforeCheckExistsItemLedgerEntry(Rec, xRec, CurrFieldNo, IsHandled);
                if not IsHandled then
                    if ExistsItemLedgerEntry() then
                        Error(CannotChangeItemWithExistingDocumentLinesErr, FieldCaption(Type), TableCaption(), "No.", ItemLedgEntryTableCaptionTxt);
                TestNoWhseEntriesExist(FieldCaption(Type));
                CheckJournalsAndWorksheets(FieldNo(Type));
                CheckDocuments(FieldNo(Type));
                if IsNonInventoriableType() then
                    CheckUpdateFieldsForNonInventoriableItem();
            end;
        }
        field(11; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";

            trigger OnValidate()
            var
                InventoryPostGroupExists: Boolean;
            begin
                InventoryPostGroupExists := false;
                if "Inventory Posting Group" <> '' then begin
                    TestField(Type, Type::Inventory);
                    InventoryPostGroupExists := InventoryPostingGroup.Get("Inventory Posting Group");
                end;
                if InventoryPostGroupExists then
                    "Inventory Posting Group Id" := InventoryPostingGroup.SystemId
                else
                    Clear("Inventory Posting Group Id");
            end;
        }
        field(12; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
            OptimizeForTextSearch = true;
        }
        field(14; "Item Disc. Group"; Code[20])
        {
            Caption = 'Item Disc. Group';
            TableRelation = "Item Discount Group";
        }
        field(15; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            InitValue = true;
        }
        field(16; "Statistics Group"; Integer)
        {
            Caption = 'Statistics Group';
            ToolTip = 'Specifies the statistics group.';
        }
        field(17; "Commission Group"; Integer)
        {
            Caption = 'Commission Group';
        }
        field(18; "Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Price';
            MinValue = 0;

            trigger OnValidate()
            begin
                Validate("Price/Profit Calculation");

                UpdateMyItem(FieldNo("Unit Price"));
            end;
        }
        field(19; "Price/Profit Calculation"; Enum "Item Price Profit Calculation")
        {
            Caption = 'Price/Profit Calculation';

            trigger OnValidate()
            begin
                case "Price/Profit Calculation" of
                    "Price/Profit Calculation"::"Profit=Price-Cost":
                        if "Unit Price" <> 0 then
                            if "Unit Cost" = 0 then
                                "Profit %" := 0
                            else
                                "Profit %" :=
                                  Round(
                                    100 * (1 - "Unit Cost" /
                                           ("Unit Price" / (1 + CalcVAT()))), 0.00001)
                        else
                            "Profit %" := 0;
                    "Price/Profit Calculation"::"Price=Cost+Profit":
                        if "Profit %" < 100 then begin
                            GetGLSetup();
                            "Unit Price" :=
                              Round(
                                ("Unit Cost" / (1 - "Profit %" / 100)) *
                                (1 + CalcVAT()),
                                GLSetup."Unit-Amount Rounding Precision");
                            UpdateMyItem(FieldNo("Unit Price"));
                        end;
                end;
            end;
        }
        field(20; "Profit %"; Decimal)
        {
            Caption = 'Profit %';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;

            trigger OnValidate()
            begin
                Validate("Price/Profit Calculation");
            end;
        }
        field(21; "Costing Method"; Enum "Costing Method")
        {
            Caption = 'Costing Method';

            trigger OnValidate()
            begin
                if "Costing Method" = xRec."Costing Method" then
                    exit;

                if "Costing Method" <> "Costing Method"::FIFO then
                    TestField(Type, Type::Inventory);

                if "Costing Method" = "Costing Method"::Specific then begin
                    TestField("Item Tracking Code");

                    ItemTrackingCode.Get("Item Tracking Code");
                    if not ItemTrackingCode."SN Specific Tracking" then
                        Error(
                          Text018,
                          ItemTrackingCode.FieldCaption("SN Specific Tracking"),
                          Format(true), ItemTrackingCode.TableCaption(), ItemTrackingCode.Code,
                          FieldCaption("Costing Method"), "Costing Method");
                end;

                TestNoEntriesExist(FieldCaption("Costing Method"));

                ItemCostMgt.UpdateUnitCost(Rec, '', '', 0, 0, false, false, true, FieldNo("Costing Method"));
            end;
        }
        field(22; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateUnitCost(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if IsNonInventoriableType() then
                    exit;

                if "Costing Method" = "Costing Method"::Standard then
                    Validate("Standard Cost", "Unit Cost")
                else
                    TestNoEntriesExist(FieldCaption("Unit Cost"));
                Validate("Price/Profit Calculation");
            end;
        }
        field(24; "Standard Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
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

                if ("Costing Method" = "Costing Method"::Standard) and (CurrFieldNo <> 0) then
                    // Show confirmation dialog only for standard web client.
                    if GuiAllowed() then
                        if not
                           Confirm(
                             Text020 +
                             Text021 +
                             Text022, false,
                             FieldCaption("Standard Cost"))
                        then begin
                            "Standard Cost" := xRec."Standard Cost";
                            exit;
                        end;

                ItemCostMgt.UpdateUnitCost(Rec, '', '', 0, 0, false, false, true, FieldNo("Standard Cost"));
            end;
        }
        field(25; "Last Direct Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Last Direct Cost';
            MinValue = 0;
        }
        field(28; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;

            trigger OnValidate()
            begin
                if "Indirect Cost %" > 0 then
                    TestField(Type, Type::Inventory);
                if Rec."Indirect Cost %" <> xRec."Indirect Cost %" then
                    AdjustCostIfRequired(Rec.FieldCaption("Indirect Cost %"));

                ItemCostMgt.UpdateUnitCost(Rec, '', '', 0, 0, false, false, true, FieldNo("Indirect Cost %"));
            end;
        }
        field(29; "Cost is Adjusted"; Boolean)
        {
            Caption = 'Cost is Adjusted';
            Editable = false;
            InitValue = true;
        }
        field(30; "Allow Online Adjustment"; Boolean)
        {
            Caption = 'Allow Online Adjustment';
            Editable = false;
            InitValue = true;
        }
        field(31; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
            OptimizeForTextSearch = true;
            ValidateTableRelation = true;

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
            ToolTip = 'Specifies the number that the vendor uses for this item.';
            OptimizeForTextSearch = true;
        }
        field(33; "Lead Time Calculation"; DateFormula)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Lead Time Calculation';

            trigger OnValidate()
            begin
                LeadTimeMgt.CheckLeadTimeIsNotNegative("Lead Time Calculation");
            end;
        }
        field(34; "Reorder Point"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Reorder Point';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(35; "Maximum Inventory"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Maximum Inventory';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(36; "Reorder Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Reorder Quantity';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(37; "Alternative Item No."; Code[20])
        {
            Caption = 'Alternative Item No.';
            ToolTip = 'Specifies another identifier for this item.';
            OptimizeForTextSearch = true;
            TableRelation = Item;
        }
        field(38; "Unit List Price"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit List Price';
            MinValue = 0;
        }
        field(39; "Duty Due %"; Decimal)
        {
            Caption = 'Duty Due %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(40; "Duty Code"; Code[10])
        {
            Caption = 'Duty Code';
            OptimizeForTextSearch = true;
        }
        field(41; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(42; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(43; "Units per Parcel"; Decimal)
        {
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(44; "Unit Volume"; Decimal)
        {
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(45; Durability; Code[10])
        {
            Caption = 'Durability';
        }
        field(46; "Freight Type"; Code[10])
        {
            Caption = 'Freight Type';
        }
        field(47; "Tariff No."; Code[20])
        {
            Caption = 'Tariff No.';
            TableRelation = "Tariff Number";
            OptimizeForTextSearch = true;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                TariffNumber: Record "Tariff Number";
            begin
                if "Tariff No." = '' then
                    exit;

                if (not TariffNumber.WritePermission) or
                   (not TariffNumber.ReadPermission)
                then
                    exit;

                if TariffNumber.Get("Tariff No.") then
                    exit;

                TariffNumber.Init();
                TariffNumber."No." := "Tariff No.";
                TariffNumber.Insert();
            end;
        }
        field(48; "Duty Unit Conversion"; Decimal)
        {
            Caption = 'Duty Unit Conversion';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(49; "Country/Region Purchased Code"; Code[10])
        {
            Caption = 'Country/Region Purchased Code';
            TableRelation = "Country/Region";
        }
        field(50; "Budget Quantity"; Decimal)
        {
            Caption = 'Budget Quantity';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(51; "Budgeted Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Budgeted Amount';
        }
        field(52; "Budget Profit"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Budget Profit';
        }
        field(53; Comment; Boolean)
        {
            CalcFormula = exist("Comment Line" where("Table Name" = const(Item),
                                                      "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(54; Blocked; Boolean)
        {
            Caption = 'Blocked';

            trigger OnValidate()
            begin
                if not Blocked then
                    "Block Reason" := '';
            end;
        }
        field(55; "Cost is Posted to G/L"; Boolean)
        {
            CalcFormula = - exist("Post Value Entry to G/L" where("Item No." = field("No.")));
            Caption = 'Cost is Posted to G/L';
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "Block Reason"; Text[250])
        {
            Caption = 'Block Reason';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            begin
                if ("Block Reason" <> '') and ("Block Reason" <> xRec."Block Reason") then
                    TestField(Blocked, true);
            end;
        }
        field(61; "Last DateTime Modified"; DateTime)
        {
            Caption = 'Last DateTime Modified';
            Editable = false;
        }
        field(62; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(63; "Last Time Modified"; Time)
        {
            Caption = 'Last Time Modified';
            Editable = false;
        }
        field(64; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(65; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(66; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(67; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(68; Inventory; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("No."),
                                                                  "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                  "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                  "Location Code" = field("Location Filter"),
                                                                  "Drop Shipment" = field("Drop Shipment Filter"),
                                                                  "Variant Code" = field("Variant Filter"),
                                                                  "Lot No." = field("Lot No. Filter"),
                                                                  "Serial No." = field("Serial No. Filter"),
                                                                  "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                  "Package No." = field("Package No. Filter")));
            Caption = 'Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(69; "Net Invoiced Qty."; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry"."Invoiced Quantity" where("Item No." = field("No."),
                                                                             "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                             "Location Code" = field("Location Filter"),
                                                                             "Drop Shipment" = field("Drop Shipment Filter"),
                                                                             "Variant Code" = field("Variant Filter"),
                                                                             "Lot No." = field("Lot No. Filter"),
                                                                             "Serial No." = field("Serial No. Filter"),
                                                                             "Package No." = field("Package No. Filter")));
            Caption = 'Net Invoiced Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(70; "Net Change"; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("No."),
                                                                  "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                  "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                  "Location Code" = field("Location Filter"),
                                                                  "Drop Shipment" = field("Drop Shipment Filter"),
                                                                  "Posting Date" = field("Date Filter"),
                                                                  "Variant Code" = field("Variant Filter"),
                                                                  "Lot No." = field("Lot No. Filter"),
                                                                  "Serial No." = field("Serial No. Filter"),
                                                                  "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                  "Package No." = field("Package No. Filter")));
            Caption = 'Net Change';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(71; "Purchases (Qty.)"; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry"."Invoiced Quantity" where("Entry Type" = const(Purchase),
                                                                             "Item No." = field("No."),
                                                                             "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                             "Location Code" = field("Location Filter"),
                                                                             "Drop Shipment" = field("Drop Shipment Filter"),
                                                                             "Variant Code" = field("Variant Filter"),
                                                                             "Posting Date" = field("Date Filter"),
                                                                             "Lot No." = field("Lot No. Filter"),
                                                                             "Serial No." = field("Serial No. Filter"),
                                                                             "Package No." = field("Package No. Filter")));
            Caption = 'Purchases (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(72; "Sales (Qty.)"; Decimal)
        {
            CalcFormula = - sum("Value Entry"."Invoiced Quantity" where("Item Ledger Entry Type" = const(Sale),
                                                                        "Item No." = field("No."),
                                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                        "Location Code" = field("Location Filter"),
                                                                        "Drop Shipment" = field("Drop Shipment Filter"),
                                                                        "Variant Code" = field("Variant Filter"),
                                                                        "Posting Date" = field("Date Filter")));
            Caption = 'Sales (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(73; "Positive Adjmt. (Qty.)"; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry"."Invoiced Quantity" where("Entry Type" = const("Positive Adjmt."),
                                                                             "Item No." = field("No."),
                                                                             "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                             "Location Code" = field("Location Filter"),
                                                                             "Drop Shipment" = field("Drop Shipment Filter"),
                                                                             "Variant Code" = field("Variant Filter"),
                                                                             "Posting Date" = field("Date Filter"),
                                                                             "Lot No." = field("Lot No. Filter"),
                                                                             "Serial No." = field("Serial No. Filter"),
                                                                             "Package No." = field("Package No. Filter")));
            Caption = 'Positive Adjmt. (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(74; "Negative Adjmt. (Qty.)"; Decimal)
        {
            CalcFormula = - sum("Item Ledger Entry"."Invoiced Quantity" where("Entry Type" = const("Negative Adjmt."),
                                                                              "Item No." = field("No."),
                                                                              "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "Location Code" = field("Location Filter"),
                                                                              "Drop Shipment" = field("Drop Shipment Filter"),
                                                                              "Variant Code" = field("Variant Filter"),
                                                                              "Posting Date" = field("Date Filter"),
                                                                              "Lot No." = field("Lot No. Filter"),
                                                                              "Serial No." = field("Serial No. Filter"),
                                                                              "Package No." = field("Package No. Filter")));
            Caption = 'Negative Adjmt. (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(77; "Purchases (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Value Entry"."Purchase Amount (Actual)" where("Item Ledger Entry Type" = const(Purchase),
                                                                              "Item No." = field("No."),
                                                                              "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "Location Code" = field("Location Filter"),
                                                                              "Drop Shipment" = field("Drop Shipment Filter"),
                                                                              "Variant Code" = field("Variant Filter"),
                                                                              "Posting Date" = field("Date Filter")));
            Caption = 'Purchases (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(78; "Sales (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Value Entry"."Sales Amount (Actual)" where("Item Ledger Entry Type" = const(Sale),
                                                                           "Item No." = field("No."),
                                                                           "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                           "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Drop Shipment" = field("Drop Shipment Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Posting Date" = field("Date Filter")));
            Caption = 'Sales (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(79; "Positive Adjmt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Value Entry"."Cost Amount (Actual)" where("Item Ledger Entry Type" = const("Positive Adjmt."),
                                                                          "Item No." = field("No."),
                                                                          "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Location Code" = field("Location Filter"),
                                                                          "Drop Shipment" = field("Drop Shipment Filter"),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Posting Date" = field("Date Filter")));
            Caption = 'Positive Adjmt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(80; "Negative Adjmt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Value Entry"."Cost Amount (Actual)" where("Item Ledger Entry Type" = const("Negative Adjmt."),
                                                                          "Item No." = field("No."),
                                                                          "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Location Code" = field("Location Filter"),
                                                                          "Drop Shipment" = field("Drop Shipment Filter"),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Posting Date" = field("Date Filter")));
            Caption = 'Negative Adjmt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(83; "COGS (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = - sum("Value Entry"."Cost Amount (Actual)" where("Item Ledger Entry Type" = const(Sale),
                                                                           "Item No." = field("No."),
                                                                           "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                           "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Drop Shipment" = field("Drop Shipment Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Posting Date" = field("Date Filter")));
            Caption = 'COGS (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(84; "Qty. on Purch. Order"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("Purchase Line"."Outstanding Qty. (Base)" where("Document Type" = const(Order),
                                                                               Type = const(Item),
                                                                               "No." = field("No."),
                                                                               "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                               "Location Code" = field("Location Filter"),
                                                                               "Drop Shipment" = field("Drop Shipment Filter"),
                                                                               "Variant Code" = field("Variant Filter"),
                                                                               "Expected Receipt Date" = field("Date Filter"),
                                                                               "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Purch. Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(85; "Qty. on Sales Order"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = sum("Sales Line"."Outstanding Qty. (Base)" where("Document Type" = const(Order),
                                                                            Type = const(Item),
                                                                            "No." = field("No."),
                                                                            "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                            "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Drop Shipment" = field("Drop Shipment Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Shipment Date" = field("Date Filter"),
                                                                            "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Sales Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(87; "Price Includes VAT"; Boolean)
        {
            Caption = 'Price Includes VAT';

            trigger OnValidate()
            var
                VATPostingSetup: Record "VAT Posting Setup";
                SalesSetup: Record "Sales & Receivables Setup";
            begin
                if "Price Includes VAT" then begin
                    SalesSetup.Get();
                    SalesSetup.TestField("VAT Bus. Posting Gr. (Price)");
                    "VAT Bus. Posting Gr. (Price)" := SalesSetup."VAT Bus. Posting Gr. (Price)";
                    VATPostingSetup.Get("VAT Bus. Posting Gr. (Price)", "VAT Prod. Posting Group");
                end;
                Validate("Price/Profit Calculation");
            end;
        }
        field(89; "Drop Shipment Filter"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment Filter';
            FieldClass = FlowFilter;
        }
        field(90; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            Caption = 'VAT Bus. Posting Gr. (Price)';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                Validate("Price/Profit Calculation");
            end;
        }
        field(91; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            var
                GenProdPostGroupExists: Boolean;
                ShouldExit: Boolean;
            begin
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then begin
                    if CurrFieldNo <> 0 then begin
                        ShouldExit := false;
                        OnValidateGenProdPostingGroupOnConfirmChange(Rec, xRec."Gen. Prod. Posting Group", ShouldExit);
                        if ShouldExit then
                            exit;
                    end;

                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
                end;

                GenProdPostGroupExists := false;
                if "Gen. Prod. Posting Group" <> '' then
                    GenProdPostGroupExists := GenProdPostingGrp.Get("Gen. Prod. Posting Group");
                if GenProdPostGroupExists then
                    "Gen. Prod. Posting Group Id" := GenProdPostingGrp.SystemId
                else
                    Clear("Gen. Prod. Posting Group Id");

                Validate("Price/Profit Calculation");
            end;
        }
        field(92; Picture; MediaSet)
        {
            Caption = 'Picture';
        }
        field(93; "Transferred (Qty.)"; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry"."Invoiced Quantity" where("Entry Type" = const(Transfer),
                                                                             "Item No." = field("No."),
                                                                             "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                             "Location Code" = field("Location Filter"),
                                                                             "Drop Shipment" = field("Drop Shipment Filter"),
                                                                             "Variant Code" = field("Variant Filter"),
                                                                             "Posting Date" = field("Date Filter"),
                                                                             "Lot No." = field("Lot No. Filter"),
                                                                             "Serial No." = field("Serial No. Filter"),
                                                                             "Package No." = field("Package No. Filter")));
            Caption = 'Transferred (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(94; "Transferred (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Value Entry"."Sales Amount (Actual)" where("Item Ledger Entry Type" = const(Transfer),
                                                                           "Item No." = field("No."),
                                                                           "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                           "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Drop Shipment" = field("Drop Shipment Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Posting Date" = field("Date Filter")));
            Caption = 'Transferred (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(95; "Country/Region of Origin Code"; Code[10])
        {
            Caption = 'Country/Region of Origin Code';
            TableRelation = "Country/Region";
        }
        field(96; "Automatic Ext. Texts"; Boolean)
        {
            Caption = 'Automatic Ext. Texts';
        }
        field(97; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(98; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                UpdateTaxGroupId();
            end;
        }
        field(99; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                Validate("Price/Profit Calculation");
            end;
        }
        field(100; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Reserve';
            InitValue = Optional;

            trigger OnValidate()
            begin
                if Reserve in [Reserve::Optional, Reserve::Always] then
                    TestField(Type, Type::Inventory);
            end;
        }
        field(101; "Reserved Qty. on Inventory"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                           "Source Type" = const(32),
                                                                           "Source Subtype" = const("0"),
                                                                           "Reservation Status" = const(Reservation),
                                                                           "Serial No." = field("Serial No. Filter"),
                                                                           "Lot No." = field("Lot No. Filter"),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Package No." = field("Package No. Filter")));
            Caption = 'Reserved Qty. on Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(102; "Reserved Qty. on Purch. Orders"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                           "Source Type" = const(39),
                                                                           "Source Subtype" = const("1"),
                                                                           "Reservation Status" = const(Reservation),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Reserved Qty. on Purch. Orders';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(103; "Reserved Qty. on Sales Orders"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                            "Source Type" = const(37),
                                                                            "Source Subtype" = const("1"),
                                                                            "Reservation Status" = const(Reservation),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Reserved Qty. on Sales Orders';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(105; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(106; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(107; "Res. Qty. on Outbound Transfer"; Decimal)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                            "Source Type" = const(5741),
                                                                            "Source Subtype" = const("0"),
                                                                            "Reservation Status" = const(Reservation),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Res. Qty. on Outbound Transfer';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(108; "Res. Qty. on Inbound Transfer"; Decimal)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                           "Source Type" = const(5741),
                                                                           "Source Subtype" = const("1"),
                                                                           "Reservation Status" = const(Reservation),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Res. Qty. on Inbound Transfer';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(109; "Res. Qty. on Sales Returns"; Decimal)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                           "Source Type" = const(37),
                                                                           "Source Subtype" = const("5"),
                                                                           "Reservation Status" = const(Reservation),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Shipment Date" = field("Date Filter")));
            Caption = 'Res. Qty. on Sales Returns';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(110; "Res. Qty. on Purch. Returns"; Decimal)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                            "Source Type" = const(39),
                                                                            "Source Subtype" = const("5"),
                                                                            "Reservation Status" = const(Reservation),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Res. Qty. on Purch. Returns';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(120; "Stockout Warning"; Option)
        {
            Caption = 'Stockout Warning';
            OptionCaption = 'Default,No,Yes';
            OptionMembers = Default,No,Yes;
        }
        field(121; "Prevent Negative Inventory"; Option)
        {
            Caption = 'Prevent Negative Inventory';
            OptionCaption = 'Default,No,Yes';
            OptionMembers = Default,No,Yes;
        }
        field(122; "Variant Mandatory if Exists"; Option)
        {
            Caption = 'Variant Mandatory if Exists';
            OptionCaption = 'Default,No,Yes';
            OptionMembers = Default,No,Yes;
        }
        field(521; "Application Wksh. User ID"; Code[128])
        {
            Caption = 'Application Wksh. User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
#if not CLEANSCHEMA26
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::Item)));
        }
        field(910; "Assembly Policy"; Enum Microsoft.Assembly.Setup."Assembly Policy")
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Assembly Policy';

            trigger OnValidate()
            begin
                if "Assembly Policy" = "Assembly Policy"::"Assemble-to-Order" then
                    TestField("Replenishment System", "Replenishment System"::Assembly);
                if IsNonInventoriableType() then
                    TestField("Assembly Policy", "Assembly Policy"::"Assemble-to-Stock");
            end;
        }
        field(1001; "Qty. on Job Order"; Decimal)
        {
            CalcFormula = sum("Job Planning Line"."Remaining Qty. (Base)" where(Status = const(Order),
                                                                                 Type = const(Item),
                                                                                 "No." = field("No."),
                                                                                 "Location Code" = field("Location Filter"),
                                                                                 "Variant Code" = field("Variant Filter"),
                                                                                 "Planning Date" = field("Date Filter"),
                                                                                 "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Project Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(1002; "Res. Qty. on Job Order"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                            "Source Type" = const(1003),
                                                                            "Source Subtype" = const("2"),
                                                                            "Reservation Status" = const(Reservation),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Res. Qty. on Project Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(1217; GTIN; Code[14])
        {
            Caption = 'GTIN';
            OptimizeForTextSearch = true;
            Numeric = true;
            ExtendedDatatype = Barcode;
        }
        field(1700; "Default Deferral Template Code"; Code[10])
        {
            Caption = 'Default Deferral Template Code';
            TableRelation = "Deferral Template"."Deferral Code";
        }
        field(5400; "Low-Level Code"; Integer)
        {
            Caption = 'Low-Level Code';
            Editable = false;
        }
        field(5401; "Lot Size"; Decimal)
        {
            Caption = 'Lot Size';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(5402; "Serial Nos."; Code[20])
        {
            Caption = 'Serial Nos.';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "Serial Nos." <> '' then
                    TestField("Item Tracking Code");
            end;
        }
        field(5403; "Last Unit Cost Calc. Date"; Date)
        {
            Caption = 'Last Unit Cost Calc. Date';
            Editable = false;
        }
        field(5404; "Rolled-up Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Rolled-up Material Cost';
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(5405; "Rolled-up Capacity Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
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
            AutoFormatType = 0;
        }
        field(5408; "Rolled-up Mat. Non-Invt. Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Rolled-up Material Non-Inventory Cost';
            ToolTip = 'Specifies the Non-inventory material cost of all items at all levels of the parent item''s BOM.';
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(5409; "Inventory Value Zero"; Boolean)
        {
            Caption = 'Inventory Value Zero';

            trigger OnValidate()
            begin
                CheckForProductionOutput("No.");
            end;
        }
        field(5410; "Discrete Order Quantity"; Integer)
        {
            Caption = 'Discrete Order Quantity';
            MinValue = 0;
        }
        field(5411; "Minimum Order Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Minimum Order Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(5412; "Maximum Order Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Maximum Order Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(5413; "Safety Stock Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Safety Stock Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(5414; "Order Multiple"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Order Multiple';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(5415; "Safety Lead Time"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Safety Lead Time';
        }
        field(5417; "Flushing Method"; Enum Microsoft.Manufacturing.Setup."Flushing Method")
        {
            Caption = 'Flushing Method';
        }
        field(5419; "Replenishment System"; Enum "Replenishment System")
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Replenishment System';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                case "Replenishment System" of
                    "Replenishment System"::Purchase:
                        TestField("Assembly Policy", "Assembly Policy"::"Assemble-to-Stock");
                    "Replenishment System"::Transfer:
                        begin
                            IsHandled := false;
                            OnValidateReplenishmentSystemCaseTransfer(Rec, IsHandled);
                            if not IsHandled then
                                error(ReplenishmentSystemTransferErr);
                        end;
                    "Replenishment System"::Assembly:
                        begin
                            IsHandled := false;
                            OnValidateReplenishmentSystemCaseAssemblyr(Rec, IsHandled);
                            if not IsHandled then
                                TestField(Type, Type::Inventory);
                        end;
                    else
                        OnValidateReplenishmentSystemCaseElse(Rec);
                end;
            end;
        }
        field(5422; "Rounding Precision"; Decimal)
        {
            Caption = 'Rounding Precision';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
            AutoFormatType = 0;

            trigger OnValidate()
            begin
                if "Rounding Precision" <= 0 then
                    FieldError("Rounding Precision", Text027);
            end;
        }
        field(5423; "Bin Filter"; Code[20])
        {
            Caption = 'Bin Filter';
            FieldClass = FlowFilter;
            TableRelation = Bin.Code where("Location Code" = field("Location Filter"));
        }
        field(5424; "Variant Filter"; Code[10])
        {
            Caption = 'Variant Filter';
            FieldClass = FlowFilter;
            TableRelation = "Item Variant".Code where("Item No." = field("No."));
        }
        field(5425; "Sales Unit of Measure"; Code[10])
        {
            Caption = 'Sales Unit of Measure';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("No."));
        }
        field(5426; "Purch. Unit of Measure"; Code[10])
        {
            Caption = 'Purch. Unit of Measure';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("No."));
        }
        field(5427; "Unit of Measure Filter"; Code[10])
        {
            Caption = 'Unit of Measure Filter';
            FieldClass = FlowFilter;
            TableRelation = "Unit of Measure";
        }
        field(5428; "Time Bucket"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Time Bucket';

            trigger OnValidate()
            begin
                CalendarMgt.CheckDateFormulaPositive("Time Bucket");
            end;
        }
        field(5431; "Res. Qty. on Req. Line"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                           "Source Type" = const(246),
                                                                           "Source Subtype" = filter("0"),
                                                                           "Reservation Status" = const(Reservation),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Res. Qty. on Req. Line';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(5440; "Reordering Policy"; Enum "Reordering Policy")
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Reordering Policy';

            trigger OnValidate()
            begin
                "Include Inventory" :=
                  "Reordering Policy" in ["Reordering Policy"::"Lot-for-Lot",
                                          "Reordering Policy"::"Maximum Qty.",
                                          "Reordering Policy"::"Fixed Reorder Qty."];

                if "Reordering Policy" <> "Reordering Policy"::" " then
                    TestField(Type, Type::Inventory);
            end;
        }
        field(5441; "Include Inventory"; Boolean)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Include Inventory';
        }
        field(5442; "Manufacturing Policy"; Enum Microsoft.Manufacturing.Setup."Manufacturing Policy")
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Manufacturing Policy';
        }
        field(5443; "Rescheduling Period"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Rescheduling Period';

            trigger OnValidate()
            begin
                CalendarMgt.CheckDateFormulaPositive("Rescheduling Period");
            end;
        }
        field(5444; "Lot Accumulation Period"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Lot Accumulation Period';

            trigger OnValidate()
            begin
                CalendarMgt.CheckDateFormulaPositive("Lot Accumulation Period");
            end;
        }
        field(5445; "Dampener Period"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Dampener Period';

            trigger OnValidate()
            begin
                CalendarMgt.CheckDateFormulaPositive("Dampener Period");
            end;
        }
        field(5446; "Dampener Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Dampener Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(5447; "Overflow Level"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Overflow Level';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(5449; "Planning Transfer Ship. (Qty)."; Decimal)
        {
            CalcFormula = sum("Requisition Line"."Quantity (Base)" where("Worksheet Template Name" = filter(<> ''),
                                                                          "Journal Batch Name" = filter(<> ''),
                                                                          "Replenishment System" = const(Transfer),
                                                                          Type = const(Item),
                                                                          "No." = field("No."),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Transfer-from Code" = field("Location Filter"),
                                                                          "Transfer Shipment Date" = field("Date Filter")));
            Caption = 'Planning Transfer Ship. (Qty).';
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(5450; "Planning Worksheet (Qty.)"; Decimal)
        {
            CalcFormula = sum("Requisition Line"."Quantity (Base)" where("Planning Line Origin" = const(Planning),
                                                                          Type = const(Item),
                                                                          "No." = field("No."),
                                                                          "Location Code" = field("Location Filter"),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Due Date" = field("Date Filter"),
                                                                          "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Planning Worksheet (Qty.)';
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(5700; "Stockkeeping Unit Exists"; Boolean)
        {
            CalcFormula = exist("Stockkeeping Unit" where("Item No." = field("No.")));
            Caption = 'Stockkeeping Unit Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5701; "Manufacturer Code"; Code[10])
        {
            Caption = 'Manufacturer Code';
            TableRelation = Manufacturer;
            OptimizeForTextSearch = true;
        }
        field(5702; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
            OptimizeForTextSearch = true;

            trigger OnValidate()
            var
                ItemAttributeManagement: Codeunit "Item Attribute Management";
            begin
                if not IsTemporary then
                    ItemAttributeManagement.InheritAttributesFromItemCategory(Rec, "Item Category Code", xRec."Item Category Code");
                UpdateItemCategoryId();

                OnAfterValidateItemCategoryCode(Rec, xRec);
            end;
        }
        field(5703; "Created From Nonstock Item"; Boolean)
        {
            AccessByPermission = TableData "Nonstock Item" = R;
            Caption = 'Created From Catalog Item';
            Editable = false;
        }
        field(5706; "Substitutes Exist"; Boolean)
        {
            CalcFormula = exist("Item Substitution" where(Type = const(Item),
                                                           "No." = field("No.")));
            Caption = 'Substitutes Exist';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5707; "Qty. in Transit"; Decimal)
        {
            CalcFormula = sum("Transfer Line"."Qty. in Transit (Base)" where("Derived From Line No." = const(0),
                                                                              "Item No." = field("No."),
                                                                              "Transfer-to Code" = field("Location Filter"),
                                                                              "Variant Code" = field("Variant Filter"),
                                                                              "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "Receipt Date" = field("Date Filter"),
                                                                              "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. in Transit';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(5708; "Trans. Ord. Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Transfer Line"."Outstanding Qty. (Base)" where("Derived From Line No." = const(0),
                                                                               "Item No." = field("No."),
                                                                               "Transfer-to Code" = field("Location Filter"),
                                                                               "Variant Code" = field("Variant Filter"),
                                                                               "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                               "Receipt Date" = field("Date Filter"),
                                                                               "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Trans. Ord. Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(5709; "Trans. Ord. Shipment (Qty.)"; Decimal)
        {
            CalcFormula = sum("Transfer Line"."Outstanding Qty. (Base)" where("Derived From Line No." = const(0),
                                                                               "Item No." = field("No."),
                                                                               "Transfer-from Code" = field("Location Filter"),
                                                                               "Variant Code" = field("Variant Filter"),
                                                                               "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                               "Shipment Date" = field("Date Filter"),
                                                                               "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Trans. Ord. Shipment (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(5711; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;
            OptimizeForTextSearch = true;
        }
        field(5776; "Qty. Assigned to ship"; Decimal)
        {
            CalcFormula = sum("Warehouse Shipment Line"."Qty. Outstanding (Base)" where("Item No." = field("No."),
                                                                                         "Location Code" = field("Location Filter"),
                                                                                         "Variant Code" = field("Variant Filter"),
                                                                                         "Due Date" = field("Date Filter")));
            Caption = 'Qty. Assigned to ship';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(5777; "Qty. Picked"; Decimal)
        {
            CalcFormula = sum("Warehouse Shipment Line"."Qty. Picked (Base)" where("Item No." = field("No."),
                                                                                    "Location Code" = field("Location Filter"),
                                                                                    "Variant Code" = field("Variant Filter"),
                                                                                    "Due Date" = field("Date Filter")));
            Caption = 'Qty. Picked';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(5801; "Excluded from Cost Adjustment"; Boolean)
        {
            Caption = 'Excluded from Cost Adjustment';
            DataClassification = CustomerContent;
        }
        field(6500; "Item Tracking Code"; Code[10])
        {
            Caption = 'Item Tracking Code';
            TableRelation = "Item Tracking Code";
            OptimizeForTextSearch = true;

            trigger OnValidate()
            var
                EmptyDateFormula: DateFormula;
                IsHandled: Boolean;
            begin
                if "Item Tracking Code" <> '' then
                    TestField(Type, Type::Inventory);
                if "Item Tracking Code" = xRec."Item Tracking Code" then
                    exit;

                if not ItemTrackingCode.Get("Item Tracking Code") then
                    Clear(ItemTrackingCode);

                if not ItemTrackingCode2.Get(xRec."Item Tracking Code") then
                    Clear(ItemTrackingCode2);

                IsHandled := false;
                OnValidateItemTrackingCodeOnBeforeTestNoEntriesExist(Rec, xRec, CurrFieldNo, IsHandled);
                if ItemTrackingCode.IsSpecificTrackingChanged(ItemTrackingCode2) then
                    if not IsHandled then
                        TestNoEntriesExist(FieldCaption("Item Tracking Code"));

                if ItemTrackingCode.IsWarehouseTrackingChanged(ItemTrackingCode2) then
                    TestNoWhseEntriesExist(FieldCaption("Item Tracking Code"));

                if "Costing Method" = "Costing Method"::Specific then begin
                    TestNoEntriesExist(FieldCaption("Item Tracking Code"));

                    TestField("Item Tracking Code");

                    ItemTrackingCode.Get("Item Tracking Code");
                    if not ItemTrackingCode."SN Specific Tracking" then
                        Error(
                          Text018,
                          ItemTrackingCode.FieldCaption("SN Specific Tracking"),
                          Format(true), ItemTrackingCode.TableCaption(), ItemTrackingCode.Code,
                          FieldCaption("Costing Method"), "Costing Method");
                end;

                TestNoOpenDocumentsWithTrackingExist();

                if "Expiration Calculation" <> EmptyDateFormula then
                    if not ItemTrackingCodeUseExpirationDates() then
                        Error(ItemTrackingCodeIgnoresExpirationDateErr, "No.");
            end;
        }
        field(6501; "Lot Nos."; Code[20])
        {
            Caption = 'Lot Nos.';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "Lot Nos." <> '' then
                    TestField("Item Tracking Code");
            end;
        }
        field(6502; "Expiration Calculation"; DateFormula)
        {
            Caption = 'Expiration Calculation';

            trigger OnValidate()
            begin
                if Format("Expiration Calculation") <> '' then
                    if not ItemTrackingCodeUseExpirationDates() then
                        Error(ItemTrackingCodeIgnoresExpirationDateErr, "No.");
            end;
        }
        field(6503; "Lot No. Filter"; Code[50])
        {
            Caption = 'Lot No. Filter';
            FieldClass = FlowFilter;
        }
        field(6504; "Serial No. Filter"; Code[50])
        {
            Caption = 'Serial No. Filter';
            FieldClass = FlowFilter;
        }
        field(6515; "Package No. Filter"; Code[50])
        {
            Caption = 'Package No. Filter';
            CaptionClass = '6,3';
            FieldClass = FlowFilter;
        }
        field(6650; "Qty. on Purch. Return"; Decimal)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = sum("Purchase Line"."Outstanding Qty. (Base)" where("Document Type" = const("Return Order"),
                                                                               Type = const(Item),
                                                                               "No." = field("No."),
                                                                               "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                               "Location Code" = field("Location Filter"),
                                                                               "Drop Shipment" = field("Drop Shipment Filter"),
                                                                               "Variant Code" = field("Variant Filter"),
                                                                               "Expected Receipt Date" = field("Date Filter"),
                                                                               "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Purch. Return';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(6660; "Qty. on Sales Return"; Decimal)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            CalcFormula = sum("Sales Line"."Outstanding Qty. (Base)" where("Document Type" = const("Return Order"),
                                                                            Type = const(Item),
                                                                            "No." = field("No."),
                                                                            "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                            "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Drop Shipment" = field("Drop Shipment Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Shipment Date" = field("Date Filter"),
                                                                            "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Sales Return';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(7171; "No. of Substitutes"; Integer)
        {
            CalcFormula = count("Item Substitution" where(Type = const(Item),
                                                           "No." = field("No.")));
            Caption = 'No. of Substitutes';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7300; "Warehouse Class Code"; Code[10])
        {
            Caption = 'Warehouse Class Code';
            TableRelation = "Warehouse Class";
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
            AccessByPermission = TableData "Posted Invt. Put-away Header" = R;
            Caption = 'Put-away Unit of Measure Code';
            TableRelation = if ("No." = filter(<> '')) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            "Unit of Measure";
        }
        field(7380; "Phys Invt Counting Period Code"; Code[10])
        {
            Caption = 'Phys Invt Counting Period Code';
            TableRelation = "Phys. Invt. Counting Period";

            trigger OnValidate()
            var
                PhysInvtCountPeriod: Record "Phys. Invt. Counting Period";
                PhysInvtCountPeriodMgt: Codeunit "Phys. Invt. Count.-Management";
                IsHandled: Boolean;
            begin
                if ("Phys Invt Counting Period Code" <> '') and
                   (("Phys Invt Counting Period Code" <> xRec."Phys Invt Counting Period Code") or
                   (xRec."Phys Invt Counting Period Code" <> ''))
                then begin
                    PhysInvtCountPeriod.Get("Phys Invt Counting Period Code");
                    PhysInvtCountPeriod.TestField("Count Frequency per Year");
                    IsHandled := false;
                    OnValidatePhysInvtCountingPeriodCodeOnBeforeConfirmUpdate(Rec, xRec, PhysInvtCountPeriod, IsHandled);
                    if not IsHandled then
                        if xRec."Phys Invt Counting Period Code" <> '' then
                            if CurrFieldNo <> 0 then
                                if not Confirm(
                                     Text7380,
                                     false,
                                     FieldCaption("Phys Invt Counting Period Code"),
                                     FieldCaption("Next Counting Start Date"),
                                     FieldCaption("Next Counting End Date"))
                                then
                                    Error(Text7381);

                    if "Last Counting Period Update" <> 0D then
                        "Last Counting Period Update" := WorkDate();
                    PhysInvtCountPeriodMgt.CalcPeriod(
                      "Last Counting Period Update", "Next Counting Start Date", "Next Counting End Date",
                      PhysInvtCountPeriod."Count Frequency per Year");
                end else begin
                    if CurrFieldNo <> 0 then
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
            AccessByPermission = TableData "Phys. Invt. Item Selection" = R;
            Caption = 'Last Counting Period Update';
            Editable = false;
        }
        field(7383; "Last Phys. Invt. Date"; Date)
        {
            CalcFormula = max("Phys. Inventory Ledger Entry"."Posting Date" where("Item No." = field("No."),
                                                                                   "Phys Invt Counting Period Type" = filter(" " | Item)));
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
            Editable = false;
        }
        field(7386; "Next Counting End Date"; Date)
        {
            Caption = 'Next Counting End Date';
            Editable = false;
        }
        field(7387; "Unit Group Exists"; Boolean)
        {
            CalcFormula = exist("Unit Group" where("Source Id" = field(SystemId),
                                                "Source Type" = const(Item)));
            Caption = 'Unit Group Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7700; "Identifier Code"; Code[20])
        {
            CalcFormula = lookup("Item Identifier".Code where("Item No." = field("No.")));
            Caption = 'Identifier Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8001; "Unit of Measure Id"; Guid)
        {
            Caption = 'Unit of Measure Id';
            TableRelation = "Unit of Measure".SystemId;

            trigger OnValidate()
            begin
                UpdateUnitOfMeasureCode();
            end;
        }
        field(8002; "Tax Group Id"; Guid)
        {
            Caption = 'Tax Group Id';
            TableRelation = "Tax Group".SystemId;

            trigger OnValidate()
            begin
                UpdateTaxGroupCode();
            end;
        }
        field(8003; "Sales Blocked"; Boolean)
        {
            Caption = 'Sales Blocked';
            DataClassification = CustomerContent;
        }
        field(8004; "Purchasing Blocked"; Boolean)
        {
            Caption = 'Purchasing Blocked';
            DataClassification = CustomerContent;
        }
        field(8005; "Item Category Id"; Guid)
        {
            Caption = 'Item Category Id';
            DataClassification = SystemMetadata;
            TableRelation = "Item Category".SystemId;

            trigger OnValidate()
            begin
                UpdateItemCategoryCode();
            end;
        }
        field(8006; "Inventory Posting Group Id"; Guid)
        {
            Caption = 'Inventory Posting Group Id';
            TableRelation = "Inventory Posting Group".SystemId;

            trigger OnValidate()
            var
                InventoryPostGroupExists: Boolean;
            begin
                InventoryPostGroupExists := false;
                if not IsNullGuid("Inventory Posting Group Id") then
                    InventoryPostGroupExists := InventoryPostingGroup.GetBySystemId("Inventory Posting Group Id");
                if InventoryPostGroupExists then
                    Validate("Inventory Posting Group", InventoryPostingGroup."Code")
                else
                    Validate("Inventory Posting Group", '')
            end;
        }
        field(8007; "Gen. Prod. Posting Group Id"; Guid)
        {
            Caption = 'Gen. Prod. Posting Group Id';
            TableRelation = "Gen. Product Posting Group".SystemId;
            trigger OnValidate()
            var
                GenProductPostingGroup: Record "Gen. Product Posting Group";
                GenProdPostGroupExists: Boolean;
            begin
                GenProdPostGroupExists := false;
                if not IsNullGuid("Gen. Prod. Posting Group Id") then begin
                    GenProductPostingGroup.SetLoadFields("Code");
                    GenProdPostGroupExists := GenProductPostingGroup.GetBySystemId("Gen. Prod. Posting Group Id");
                end;

                if GenProdPostGroupExists then
                    Validate("Gen. Prod. Posting Group", GenProductPostingGroup."Code")
                else
                    Validate("Gen. Prod. Posting Group", '')
            end;
        }
        field(8010; "Service Blocked"; Boolean)
        {
            Caption = 'Service Blocked';
            DataClassification = CustomerContent;
        }
        field(8510; "Over-Receipt Code"; Code[20])
        {
            Caption = 'Over-Receipt Code';
            TableRelation = "Over-Receipt Code";
        }
        field(9110; "Qty. on Blanket Sales Order"; Decimal)
        {
            CalcFormula = sum("Sales Line"."Outstanding Qty. (Base)" where("Document Type" = const("Blanket Order"),
                                                                            Type = const(Item),
                                                                            "No." = field("No."),
                                                                            "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                            "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Drop Shipment" = field("Drop Shipment Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Shipment Date" = field("Date Filter"),
                                                                            "Unit of Measure Code" = field("Unit of Measure Filter")));
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
                                                                            "No." = field("No."),
                                                                            "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                            "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Drop Shipment" = field("Drop Shipment Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Expected Receipt Date" = field("Date Filter"),
                                                                            "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Blanket Purch. Order';
            ToolTip = 'Specifies how many units of the item are allocated to blanket purchase orders, meaning listed on outstanding blanket purchase order lines.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(99000752; "Single-Level Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Single-Level Material Cost';
            Editable = false;
        }
        field(99000753; "Single-Level Capacity Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Single-Level Capacity Cost';
            Editable = false;
        }
        field(99000754; "Single-Level Subcontrd. Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Single-Level Subcontrd. Cost';
            Editable = false;
        }
        field(99000755; "Single-Level Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Single-Level Cap. Ovhd Cost';
            Editable = false;
        }
        field(99000756; "Single-Level Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Mfg. Ovhd Cost';
            Editable = false;
        }
        field(99000757; "Overhead Rate"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Overhead Rate';

            trigger OnValidate()
            begin
                if "Overhead Rate" <> 0 then
                    TestField(Type, Type::Inventory);
                if Rec."Overhead Rate" <> xRec."Overhead Rate" then
                    AdjustCostIfRequired(Rec.FieldCaption("Overhead Rate"));
            end;
        }
        field(99000758; "Rolled-up Subcontracted Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Rolled-up Subcontracted Cost';
            Editable = false;
        }
        field(99000759; "Rolled-up Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Rolled-up Mfg. Ovhd Cost';
            Editable = false;
        }
        field(99000760; "Rolled-up Cap. Overhead Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Rolled-up Cap. Overhead Cost';
            Editable = false;
        }
        field(99000761; "Planning Issues (Qty.)"; Decimal)
        {
            CalcFormula = sum("Planning Component"."Expected Quantity (Base)" where("Item No." = field("No."),
                                                                                     "Due Date" = field("Date Filter"),
                                                                                     "Location Code" = field("Location Filter"),
                                                                                     "Variant Code" = field("Variant Filter"),
                                                                                     "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                     "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                     "Planning Line Origin" = const(" "),
                                                                                     "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Planning Issues (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(99000762; "Planning Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Requisition Line"."Quantity (Base)" where(Type = const(Item),
                                                                          "No." = field("No."),
                                                                          "Due Date" = field("Date Filter"),
                                                                          "Location Code" = field("Location Filter"),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Planning Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(99000768; "Planning Release (Qty.)"; Decimal)
        {
            CalcFormula = sum("Requisition Line"."Quantity (Base)" where(Type = const(Item),
                                                                          "No." = field("No."),
                                                                          "Starting Date" = field("Date Filter"),
                                                                          "Location Code" = field("Location Filter"),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Planning Release (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(99000770; "Purch. Req. Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Requisition Line"."Quantity (Base)" where(Type = const(Item),
                                                                          "No." = field("No."),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Location Code" = field("Location Filter"),
                                                                          "Drop Shipment" = field("Drop Shipment Filter"),
                                                                          "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Due Date" = field("Date Filter"),
                                                                          "Planning Line Origin" = const(" "),
                                                                          "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Purch. Req. Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(99000771; "Purch. Req. Release (Qty.)"; Decimal)
        {
            CalcFormula = sum("Requisition Line"."Quantity (Base)" where(Type = const(Item),
                                                                          "No." = field("No."),
                                                                          "Location Code" = field("Location Filter"),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Drop Shipment" = field("Drop Shipment Filter"),
                                                                          "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Order Date" = field("Date Filter"),
                                                                          "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Purch. Req. Release (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(99000773; "Order Tracking Policy"; Enum "Order Tracking Policy")
        {
            Caption = 'Order Tracking Policy';

            trigger OnValidate()
            var
                ReservEntry: Record "Reservation Entry";
                ActionMessageEntry: Record "Action Message Entry";
                TempReservationEntry: Record "Reservation Entry" temporary;
                ShouldRaiseRegenerativePlanningMessage: Boolean;
            begin
                if "Order Tracking Policy" <> "Order Tracking Policy"::None then
                    TestField(Type, Type::Inventory);
                if xRec."Order Tracking Policy" = "Order Tracking Policy" then
                    exit;

                ShouldRaiseRegenerativePlanningMessage := "Order Tracking Policy".AsInteger() > xRec."Order Tracking Policy".AsInteger();
                OnValidateOrderTrackingPolicyOnBeforeUpdateReservation(Rec, ShouldRaiseRegenerativePlanningMessage);
                if ShouldRaiseRegenerativePlanningMessage then
                    Message(Text99000000 + Text99000001, "Order Tracking Policy")
                else begin
                    ActionMessageEntry.SetCurrentKey("Reservation Entry");
                    ReservEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Reservation Status");
                    ReservEntry.SetRange("Item No.", "No.");
                    ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Tracking, ReservEntry."Reservation Status"::Surplus);
                    if ReservEntry.Find('-') then
                        repeat
                            ActionMessageEntry.SetRange("Reservation Entry", ReservEntry."Entry No.");
                            ActionMessageEntry.DeleteAll();
                            if "Order Tracking Policy" = "Order Tracking Policy"::None then
                                if ReservEntry.TrackingExists() then begin
                                    TempReservationEntry := ReservEntry;
                                    TempReservationEntry."Reservation Status" := TempReservationEntry."Reservation Status"::Surplus;
                                    TempReservationEntry.Insert();
                                end else
                                    ReservEntry.Delete();
                        until ReservEntry.Next() = 0;

                    if TempReservationEntry.Find('-') then
                        repeat
                            ReservEntry := TempReservationEntry;
                            ReservEntry.Modify();
                        until TempReservationEntry.Next() = 0;
                end;
            end;
        }
        field(99000774; "Prod. Forecast Quantity (Base)"; Decimal)
        {
            CalcFormula = sum(Microsoft.Manufacturing.Forecast."Production Forecast Entry"."Forecast Quantity (Base)" where("Item No." = field("No."),
                                                                                            "Production Forecast Name" = field("Production Forecast Name"),
                                                                                            "Forecast Date" = field("Date Filter"),
                                                                                            "Location Code" = field("Location Filter"),
                                                                                            "Component Forecast" = field("Component Forecast"),
                                                                                            "Variant Code" = field("Variant Filter")));
            Caption = 'Prod. Forecast Quantity (Base)';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(99000775; "Production Forecast Name"; Code[10])
        {
            Caption = 'Production Forecast Name';
            FieldClass = FlowFilter;
            TableRelation = Microsoft.Manufacturing.Forecast."Production Forecast Name";
        }
        field(99000776; "Component Forecast"; Boolean)
        {
            Caption = 'Component Forecast';
            FieldClass = FlowFilter;
        }
        field(99000875; Critical; Boolean)
        {
            Caption = 'Critical';
        }
        field(99000779; "Single-Lvl Mat. Non-Invt. Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Single-Level Material Non-Inventory Cost';
            ToolTip = 'Specifies the total Non-inventory material cost of all components on the parent item''s BOM';
            Editable = false;
        }
        field(99000780; "Allow Whse. Overpick"; Boolean)
        {
            Caption = 'Allow Whse. Overpick';
            ToolTip = 'Specifies that the record is allowed to be created in the Warehouse Pick list against the Released Production Order more than the quantity defined in the component Line. For example, system will allow to create Pick for 10 units even if the component in the BOM is defined for 3 units.';
        }
        field(99008500; "Common Item No."; Code[20])
        {
            Caption = 'Common Item No.';
            ToolTip = 'Specifies the unique common item number that the intercompany partners agree upon.';
            OptimizeForTextSearch = true;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Description")
        {
        }
        key(Key3; "Inventory Posting Group")
        {
        }
        key(Key4; "Shelf No.")
        {
        }
        key(Key5; "Vendor No.")
        {
        }
        key(Key6; "Gen. Prod. Posting Group")
        {
        }
        key(Key7; "Low-Level Code")
        {
            IncludedFields = "Cost is Adjusted", "Allow Online Adjustment", "Excluded from Cost Adjustment";
        }
        key(Key10; "Vendor Item No.", "Vendor No.")
        {
        }
        key(Key11; "Common Item No.")
        {
        }
        key(Key13; "Cost is Adjusted", "Allow Online Adjustment")
        {
            IncludedFields = "Excluded from Cost Adjustment";
        }
        key(Key14; Description)
        {
        }
        key(Key15; "Base Unit of Measure")
        {
        }
        key(Key16; Type)
        {
        }
        key(Key17; SystemModifiedAt)
        {
        }
        key(Key18; GTIN)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Base Unit of Measure", "Unit Price", Inventory, Blocked, "Vendor Item No.", "No. 2", "Alternative Item No.", "Common Item No.", GTIN, "Shelf No.")
        {
        }
        fieldgroup(Brick; "No.", Description, Inventory, "Unit Price", "Base Unit of Measure", "Description 2", Picture)
        {
        }
    }

    trigger OnDelete()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;

        ApprovalsMgmt.OnCancelItemApprovalRequest(Rec);

        CheckJournalsAndWorksheets(0);
        CheckDocuments(0);

        if not "Cost is Adjusted" then
            RunCostAdjustment(Rec);

        MoveEntries.MoveItemEntries(Rec);

        DeleteRelatedData();

        DeleteItemUnitGroup();
    end;

    trigger OnInsert()
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, IsHandled, xRec);
        if not IsHandled then begin
            if "No." = '' then begin
                GetInvtSetup();
                InventorySetup.TestField("Item Nos.");
                if NoSeries.AreRelated(InventorySetup."Item Nos.", xRec."No. Series") then
                    "No. Series" := xRec."No. Series"
                else
                    "No. Series" := InventorySetup."Item Nos.";
                "No." := NoSeries.GetNextNo("No. Series");
                Item.ReadIsolation(IsolationLevel::ReadUncommitted);
                Item.SetLoadFields("No.");
                while Item.Get("No.") do
                    "No." := NoSeries.GetNextNo("No. Series");
                "Costing Method" := InventorySetup."Default Costing Method";
                OnInsertOnAfterAssignNo(Rec, xRec);
            end;

            DimMgt.UpdateDefaultDim(
              DATABASE::Item, "No.",
              "Global Dimension 1 Code", "Global Dimension 2 Code");

            UpdateReferencedIds();
            SetLastDateTimeModified();

            UpdateItemUnitGroup();
        end;

        OnAfterOnInsert(Rec, xRec);
    end;

    trigger OnModify()
    var
        IsHandled: Boolean;
    begin
        UpdateReferencedIds();
        SetLastDateTimeModified();

        IsHandled := false;
        OnModifyOnBeforePlanningAssignmentItemChange(Rec, xRec, PlanningAssignment, IsHandled);
        if not IsHandled then
            PlanningAssignment.ItemChange(Rec, xRec);

        UpdateItemUnitGroup();
    end;

    trigger OnRename()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        JobPlanningLine: Record "Job Planning Line";
    begin
        SalesLine.RenameNo(SalesLine.Type::Item, xRec."No.", "No.");
        PurchaseLine.RenameNo(PurchaseLine.Type::Item, xRec."No.", "No.");
        TransferLine.RenameNo(xRec."No.", "No.");
        DimMgt.RenameDefaultDim(DATABASE::Item, xRec."No.", "No.");
        CommentLine.RenameCommentLine(CommentLine."Table Name"::Item, xRec."No.", "No.");
        JobPlanningLine.RenameNo(JobPlanningLine.Type::Item, xRec."No.", "No.");

        ApprovalsMgmt.OnRenameRecordInApprovalRequest(xRec.RecordId, RecordId);
        ItemAttributeValueMapping.RenameItemAttributeValueMapping(xRec."No.", "No.");
        SetLastDateTimeModified();

        UpdateItemUnitGroup();
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'Do you want to change %1?';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label 'Prices including VAT cannot be calculated when %1 is %2.';
        Text007: Label 'You cannot change %1 because there are one or more ledger entries for this item.';
        Text008: Label 'You cannot change %1 because there is at least one outstanding Purchase %2 that include this item.';
        Text018: Label '%1 must be %2 in %3 %4 when %5 is %6.';
        Text019: Label 'You cannot change %1 because there are one or more open ledger entries for this item.';
#pragma warning restore AA0470
        Text020: Label 'There may be orders and open ledger entries for the item. ';
#pragma warning disable AA0470
        Text021: Label 'If you change %1 it may affect new orders and entries.\\';
        Text022: Label 'Do you want to change %1?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        GLSetup: Record "General Ledger Setup";
        InventorySetup: Record "Inventory Setup";
#pragma warning disable AA0074
#pragma warning disable AA0470
        CannotChangeItemWithExistingDocumentLinesErr: Label 'You cannot change the %1 field on %2 %3 because at least one %4 exists for this item.', Comment = '%1 = Field Caption, %2 = Item Table Name, %3 = Item No., %4 = Table Name';
        CannotDeleteItemWithExistingDocumentLinesErr: Label 'You cannot delete %1 %2 because there is at least one %3 that includes this item.';
        Text025: Label '%1 must be an integer because %2 %3 is set up to use %4.';
        Text026: Label '%1 cannot be changed because the %2 has work in process (WIP). Changing the value may offset the WIP account.';
        Text7380: Label 'If you change the %1, the %2 and %3 are calculated.\Do you still want to change the %1?', Comment = 'If you change the Phys Invt Counting Period Code, the Next Counting Start Date and Next Counting End Date are calculated.\Do you still want to change the Phys Invt Counting Period Code?';
#pragma warning restore AA0470
        Text7381: Label 'Cancelled.';
        Text99000000: Label 'The change will not affect existing entries.\';
#pragma warning restore AA0074
        CommentLine: Record "Comment Line";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text99000001: Label 'If you want to generate %1 for existing entries, you must run a regenerative planning.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ItemVendor: Record "Item Vendor";
        ItemReference: Record "Item Reference";
        SalesPrepmtPct: Record "Sales Prepayment %";
        PurchPrepmtPct: Record "Purchase Prepayment %";
        ItemTranslation: Record "Item Translation";
        BOMComp: Record "BOM Component";
        VATPostingSetup: Record "VAT Posting Setup";
        ExtTextHeader: Record "Extended Text Header";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemJnlLine: Record "Item Journal Line";
        PlanningAssignment: Record "Planning Assignment";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ItemSub: Record "Item Substitution";
        Vend: Record Vendor;
        NonstockItem: Record "Nonstock Item";
        ItemIdent: Record "Item Identifier";
        RequisitionLine: Record "Requisition Line";
        ItemBudgetEntry: Record "Item Budget Entry";
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        ItemAnalysisBudgViewEntry: Record "Item Analysis View Budg. Entry";
        InventoryPostingGroup: Record "Inventory Posting Group";
        NoSeries: Codeunit "No. Series";
        MoveEntries: Codeunit MoveEntries;
        DimMgt: Codeunit DimensionManagement;
        CatalogItemMgt: Codeunit "Catalog Item Management";
        ItemCostMgt: Codeunit ItemCostManagement;
        CalendarMgt: Codeunit "Calendar Management";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        HasInvtSetup: Boolean;
        GLSetupRead: Boolean;
#pragma warning disable AA0074
        Text027: Label 'must be greater than 0.', Comment = 'starts with "Rounding Precision"';
#pragma warning disable AA0470
        Text028: Label 'You cannot perform this action because entries for item %1 are unapplied in %2 by user %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        BaseUnitOfMeasureQtyMustBeOneErr: Label 'The quantity per base unit of measure must be 1. %1 is set up with %2 per unit of measure.\\You can change this setup in the Item Units of Measure window.', Comment = '%1 Name of Unit of measure (e.g. BOX, PCS, KG...), %2 Qty. of %1 per base unit of measure ';
#pragma warning disable AA0470
        OpenDocumentTrackingErr: Label 'You cannot change "Item Tracking Code" because there is at least one open document that includes this item with specified tracking: Source Type = %1, Document No. = %2.';
#pragma warning restore AA0470
        SelectItemErr: Label 'You must select an existing item.';
        CreateNewItemTxt: Label 'Create a new item card for %1.', Comment = '%1 is the name to be used to create the customer. ';
        ItemNotRegisteredTxt: Label 'This item is not registered. To continue, choose one of the following options:';
        SelectItemTxt: Label 'Select an existing item.';
        UnitOfMeasureNotExistErr: Label 'The Unit of Measure with Code %1 does not exist.', Comment = '%1 = Code of Unit of measure';
        ItemLedgEntryTableCaptionTxt: Label 'Item Ledger Entry';
        ItemTrackingCodeIgnoresExpirationDateErr: Label 'The settings for expiration dates do not match on the item tracking code and the item. Both must either use, or not use, expiration dates.', Comment = '%1 is the Item number';
        ReplenishmentSystemTransferErr: Label 'The Replenishment System Transfer cannot be used for item.';
        WhseEntriesExistErr: Label 'You cannot change %1 because there are one or more warehouse entries for this item.', Comment = '%1: Changed field name';
        CostAdjustmentRequiredQst: Label 'You must complete the cost adjustment for the item before you can modify %1.\Do you want to run the cost adjustment now?', Comment = '%1: Field Caption';

    protected var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCode2: Record "Item Tracking Code";

    local procedure DeleteRelatedData()
    var
        BinContent: Record "Bin Content";
        MyItem: Record "My Item";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemVariant: Record "Item Variant";
        EntityText: Record "Entity Text";
    begin
        ItemBudgetEntry.SetCurrentKey("Analysis Area", "Budget Name", "Item No.");
        ItemBudgetEntry.SetRange("Item No.", "No.");
        ItemBudgetEntry.DeleteAll(true);

        ItemSub.Reset();
        ItemSub.SetRange(Type, ItemSub.Type::Item);
        ItemSub.SetRange("No.", "No.");
        ItemSub.DeleteAll();

        ItemSub.Reset();
        ItemSub.SetRange("Substitute Type", ItemSub."Substitute Type"::Item);
        ItemSub.SetRange("Substitute No.", "No.");
        ItemSub.DeleteAll();

        StockkeepingUnit.Reset();
        StockkeepingUnit.SetCurrentKey("Item No.");
        StockkeepingUnit.SetRange("Item No.", "No.");
        StockkeepingUnit.DeleteAll();

        CatalogItemMgt.NonstockItemDel(Rec);
        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Item);
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        ItemVendor.SetCurrentKey("Item No.");
        ItemVendor.SetRange("Item No.", "No.");
        ItemVendor.DeleteAll();

        ItemReference.SetRange("Item No.", "No.");
        ItemReference.DeleteAll();

        SalesPrepmtPct.SetRange("Item No.", "No.");
        SalesPrepmtPct.DeleteAll();

        PurchPrepmtPct.SetRange("Item No.", "No.");
        PurchPrepmtPct.DeleteAll();

        ItemTranslation.SetRange("Item No.", "No.");
        ItemTranslation.DeleteAll();

        ItemUnitOfMeasure.SetRange("Item No.", "No.");
        ItemUnitOfMeasure.DeleteAll();

        ItemVariant.SetRange("Item No.", "No.");
        ItemVariant.DeleteAll();

        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::Item);
        ExtTextHeader.SetRange("No.", "No.");
        ExtTextHeader.DeleteAll(true);

        ItemAnalysisViewEntry.SetRange("Item No.", "No.");
        ItemAnalysisViewEntry.DeleteAll();

        ItemAnalysisBudgViewEntry.SetRange("Item No.", "No.");
        ItemAnalysisBudgViewEntry.DeleteAll();

        PlanningAssignment.SetRange("Item No.", "No.");
        PlanningAssignment.DeleteAll();

        BOMComp.Reset();
        BOMComp.SetRange("Parent Item No.", "No.");
        BOMComp.DeleteAll();

        DimMgt.DeleteDefaultDim(DATABASE::Item, "No.");

        ItemIdent.Reset();
        ItemIdent.SetCurrentKey("Item No.");
        ItemIdent.SetRange("Item No.", "No.");
        ItemIdent.DeleteAll();

        BinContent.SetCurrentKey("Item No.");
        BinContent.SetRange("Item No.", "No.");
        BinContent.DeleteAll();

        MyItem.SetRange("Item No.", "No.");
        MyItem.DeleteAll();

        ItemAttributeValueMapping.Reset();
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.SetRange("No.", "No.");
        ItemAttributeValueMapping.DeleteAll();

        EntityText.SetRange(Company, CompanyName());
        EntityText.SetRange("Source Table Id", Database::Item);
        EntityText.SetRange("Source System Id", Rec.SystemId);
        EntityText.DeleteAll();

        OnAfterDeleteRelatedData(Rec);
    end;

    procedure AssistEdit() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, xRec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GetInvtSetup();
        InventorySetup.TestField("Item Nos.");
        if NoSeries.LookupRelatedNoSeries(InventorySetup."Item Nos.", xRec."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            if xRec."No." = '' then
                "Costing Method" := InventorySetup."Default Costing Method";
            OnAssistEditOnAfterAssignNo(Rec, xRec);
            exit(true);
        end;
    end;

    procedure FindItemVend(var ItemVend: Record "Item Vendor"; LocationCode: Code[10])
    var
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindItemVend(Rec, ItemVend, LocationCode, IsHandled);
        if IsHandled then
            exit;

        TestField("No.");
        ItemVend.Reset();
        ItemVend.SetRange("Item No.", "No.");
        ItemVend.SetRange("Vendor No.", ItemVend."Vendor No.");
        ItemVend.SetRange("Variant Code", ItemVend."Variant Code");
        OnFindItemVendOnAfterSetFilters(ItemVend, Rec);

        if not ItemVend.Find('+') then begin
            ItemVend."Item No." := "No.";
            ItemVend."Vendor Item No." := '';
            GetPlanningParameters.AtSKU(StockkeepingUnit, "No.", ItemVend."Variant Code", LocationCode);
            if ItemVend."Vendor No." = '' then
                ItemVend."Vendor No." := StockkeepingUnit."Vendor No.";
            if ItemVend."Vendor Item No." = '' then
                ItemVend."Vendor Item No." := StockkeepingUnit."Vendor Item No.";
            ItemVend."Lead Time Calculation" := StockkeepingUnit."Lead Time Calculation";
        end;
        OnFindItemVendOnAfterFindItemVend(ItemVend, Rec, StockkeepingUnit, LocationCode);
        ItemVend.FindLeadTimeCalculation(Rec, StockkeepingUnit, LocationCode);
        ItemVend.Reset();

        OnAfterFindItemVend(ItemVend, Rec, StockkeepingUnit, LocationCode);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::Item, "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure TestNoEntriesExist(CurrentFieldName: Text[100])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        if "No." = '' then
            exit;

        IsHandled := false;
        OnBeforeTestNoItemLedgEntiesExist(Rec, CurrentFieldName, IsHandled);
        if not IsHandled then begin
            ItemLedgEntry.SetRange("Item No.", "No.");
            if not ItemLedgEntry.IsEmpty() then
                Error(Text007, CurrentFieldName);
        end;

        IsHandled := false;
        OnBeforeTestNoPurchLinesExist(Rec, CurrentFieldName, IsHandled);
        if not IsHandled then begin
            PurchaseLine.SetCurrentKey("Document Type", Type, "No.");
            PurchaseLine.SetFilter(
              "Document Type", '%1|%2',
              PurchaseLine."Document Type"::Order,
              PurchaseLine."Document Type"::"Return Order");
            PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
            PurchaseLine.SetRange("No.", "No.");
            if PurchaseLine.FindFirst() then
                Error(Text008, CurrentFieldName, PurchaseLine."Document Type");
        end;
    end;

    procedure TestNoWhseEntriesExist(CurrentFieldName: Text)
    var
        WarehouseEntry: Record "Warehouse Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestNoWhseEntriesExist(Rec, CurrentFieldName, IsHandled);
        if IsHandled then
            exit;

        WarehouseEntry.SetRange("Item No.", "No.");
        if not WarehouseEntry.IsEmpty() then
            Error(WhseEntriesExistErr, CurrentFieldName);
    end;

    procedure TestNoOpenEntriesExist(CurrentFieldName: Text[100])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestNoOpenEntriesExist(Rec, ItemLedgEntry, CurrentFieldName, IsHandled);
        if IsHandled then
            exit;

        ItemLedgEntry.SetCurrentKey("Item No.", Open);
        ItemLedgEntry.SetRange("Item No.", "No.");
        ItemLedgEntry.SetRange(Open, true);
        if not ItemLedgEntry.IsEmpty() then
            Error(
              Text019,
              CurrentFieldName);
    end;

    local procedure TestNoOpenDocumentsWithTrackingExist()
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
        RecRef: RecordRef;
        SourceType: Integer;
        SourceID: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestNoOpenDocumentsWithTrackingExist(Rec, ItemTrackingCode2, IsHandled);
        if IsHandled then
            exit;

        if ItemTrackingCode2.Code = '' then
            exit;

        TrackingSpecification.SetRange("Item No.", "No.");
        if TrackingSpecification.FindFirst() then begin
            SourceType := TrackingSpecification."Source Type";
            SourceID := TrackingSpecification."Source ID";
        end else begin
            ReservationEntry.SetRange("Item No.", "No.");
            ReservationEntry.SetFilter("Item Tracking", '<>%1', ReservationEntry."Item Tracking"::None);
            if ReservationEntry.FindFirst() then begin
                SourceType := ReservationEntry."Source Type";
                SourceID := ReservationEntry."Source ID";
            end;
        end;

        if SourceType = 0 then
            exit;

        RecRef.Open(SourceType);
        Error(OpenDocumentTrackingErr, RecRef.Caption, SourceID);
    end;

    procedure ItemSKUGet(var Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10])
    var
        SKU: Record "Stockkeeping Unit";
    begin
        if Item.Get("No.") then
            if SKU.Get(LocationCode, Item."No.", VariantCode) then
                Item."Shelf No." := SKU."Shelf No.";
    end;

    procedure GetSKU(LocationCode: Code[10]; VariantCode: Code[10]) SKU: Record "Stockkeeping Unit" temporary
    var
        PlanningGetParameters: Codeunit "Planning-Get Parameters";
    begin
        PlanningGetParameters.AtSKU(SKU, "No.", VariantCode, LocationCode);
    end;

    local procedure GetInvtSetup()
    begin
        if not HasInvtSetup then begin
            InventorySetup.Get();
            HasInvtSetup := true;
        end;
    end;

    procedure IsMfgItem() Result: Boolean
    begin
        OnIsMfgItem(Rec, Result); // Internal event
        OnAfterIsMfgItem(Rec, Result); // Partner event
    end;

    procedure IsProductionBOM() Result: Boolean
    begin
        OnIsProductionBOM(Rec, Result); // Internal event
    end;

    procedure IsAssemblyItem() Result: Boolean
    begin
        OnIsAssemblyItem(Rec, Result); // Internal event
        OnAfterIsAssemblyItem(Rec, Result);
    end;

    procedure HasBOM() Result: Boolean
    begin
        CalcFields("Assembly BOM");
        if "Assembly BOM" then
            exit(true);

        OnAfterHasBOM(Rec, Result);
        exit(Result);
    end;

    procedure HasRoutingNo() Result: Boolean
    begin
        OnAfterHasRoutingNo(Rec, Result);
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    procedure CheckSerialNoQty(ItemNo: Code[20]; FieldName: Text[30]; Quantity: Decimal)
    var
        ItemRec: Record Item;
        ItemTrackingCode3: Record "Item Tracking Code";
    begin
        if Quantity = Round(Quantity, 1) then
            exit;
        ItemRec.SetLoadFields("No.", "Item Tracking Code");
        if not ItemRec.Get(ItemNo) then
            exit;
        if ItemRec."Item Tracking Code" = '' then
            exit;
        ItemTrackingCode3.SetLoadFields("SN Specific Tracking");
        if not ItemTrackingCode3.Get(ItemRec."Item Tracking Code") then
            exit;
        CheckSNSpecificTrackingInteger(ItemTrackingCode3, ItemRec, FieldName);
    end;

    local procedure CheckSNSpecificTrackingInteger(var ItemTrackingCode3: Record "Item Tracking Code"; var ItemRec: Record Item; FieldName: Text[30])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSNSpecificTrackingInteger(ItemRec, IsHandled);
        if IsHandled then
            exit;

        if ItemTrackingCode3."SN Specific Tracking" then
            Error(Text025,
              FieldName,
              TableCaption,
              ItemRec."No.",
              ItemTrackingCode3.FieldCaption("SN Specific Tracking"));
    end;

    local procedure CheckForProductionOutput(ItemNo: Code[20])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Output);
        if not ItemLedgEntry.IsEmpty() then
            Error(Text026, FieldCaption("Inventory Value Zero"), TableCaption);
    end;

    procedure CheckBlockedByApplWorksheet()
    var
        ApplicationWorksheet: Page "Application Worksheet";
    begin
        if "Application Wksh. User ID" <> '' then
            Error(Text028, "No.", ApplicationWorksheet.Caption, "Application Wksh. User ID");
    end;

    procedure CheckJournalsAndWorksheets(CurrFieldNo: Integer)
    begin
        CheckItemJnlLine(CurrFieldNo, FieldNo(Type), FieldCaption(Type));
        CheckStdCostWksh(CurrFieldNo);
        CheckReqLine(CurrFieldNo, FieldNo(Type), FieldCaption(Type));
    end;

    local procedure CheckItemJnlLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        IsHandled: Boolean;
    begin
        if "No." = '' then
            exit;

        IsHandled := false;
        OnBeforeCheckItemJnlLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine.SetRange("Item No.", "No.");
        if not ItemJnlLine.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(CannotDeleteItemWithExistingDocumentLinesErr, TableCaption(), "No.", ItemJnlLine.TableCaption());
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeItemWithExistingDocumentLinesErr, CheckFieldCaption, TableCaption(), "No.", ItemJnlLine.TableCaption());
        end;
    end;

    local procedure CheckStdCostWksh(CurrentFieldNo: Integer)
    var
        StandardCostWorksheet: Record Microsoft.Manufacturing.StandardCost."Standard Cost Worksheet";
        IsHandled: Boolean;
    begin
        if "No." = '' then
            exit;

        IsHandled := false;
        OnBeforeCheckStdCostWksh(Rec, CurrentFieldNo, IsHandled);
        if IsHandled then
            exit;

        StandardCostWorksheet.Reset();
        StandardCostWorksheet.SetRange(Type, StandardCostWorksheet.Type::Item);
        StandardCostWorksheet.SetRange("No.", "No.");
        if not StandardCostWorksheet.IsEmpty() then
            if CurrentFieldNo = 0 then
                Error(CannotDeleteItemWithExistingDocumentLinesErr, TableCaption(), "No.", StandardCostWorksheet.TableCaption());
    end;

    local procedure CheckReqLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        IsHandled: Boolean;
    begin
        if "No." = '' then
            exit;

        IsHandled := false;
        OnBeforeCheckReqLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;

        RequisitionLine.SetCurrentKey(Type, "No.");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", "No.");
        if not RequisitionLine.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(CannotDeleteItemWithExistingDocumentLinesErr, TableCaption(), "No.", RequisitionLine.TableCaption());
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeItemWithExistingDocumentLinesErr, CheckFieldCaption, TableCaption(), "No.", RequisitionLine.TableCaption());
        end;
    end;

    procedure CheckDocuments(CurrentFieldNo: Integer)
    begin
        CheckDocuments(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
    end;

    procedure CheckDocuments(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        IsHandled: Boolean;
    begin
        if "No." = '' then
            exit;

        IsHandled := false;
        OnBeforeCheckDocuments(Rec, CurrentFieldNo, IsHandled);
        if IsHandled then
            exit;

        OnAfterCheckDocuments(Rec, xRec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;

    procedure GetCannotChangeItemWithExistingDocumentLinesErr(): Text
    begin
        exit(CannotChangeItemWithExistingDocumentLinesErr);
    end;

    procedure GetCannotDeleteItemWithExistingDocumentLinesErr(): Text
    begin
        exit(CannotDeleteItemWithExistingDocumentLinesErr);
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure CheckBOMComponents() in codeunit CheckBOMComponent', '25.0')]
    procedure CheckBOM(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        CheckBOMComponent: Codeunit "Check BOM Component";
    begin
        CheckBOMComponent.CheckBOMComponents(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure CheckPurchLine() in codeunit CheckPurchDocumentLine', '25.0')]
    procedure CheckPurchLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        CheckPurchDocumentLine: Codeunit "Check Purchase Document Line";
    begin
        CheckPurchDocumentLine.CheckPurchaseLines(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure CheckSalesLine() in codeunit CheckSalesDocumentLine', '25.0')]
    procedure CheckSalesLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        CheckSalesDocumentLine: Codeunit "Check Sales Document Line";
    begin
        CheckSalesDocumentLine.CheckSalesLines(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure CheckPlanningCompLine() in codeunit CheckPlanningComponent', '25.0')]
    procedure CheckPlanningCompLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        CheckPlanningComponent: Codeunit "Check Planning Component";
    begin
        CheckPlanningComponent.CheckPlanningComponents(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;
#endif

    procedure CheckTransLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        CheckTransferDocument: Codeunit "Check Transfer Document";
    begin
        CheckTransferDocument.CheckTransferLines(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure CheckServiceLine() in codeunit CheckServiceDocument', '25.0')]
    procedure CheckServLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        CheckServiceDocument: Codeunit Microsoft.Service.Document."Check Service Document";
    begin
        CheckServiceDocument.CheckServiceLines(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure CheckServiceContractLine() in codeunit CheckServiceDocument', '25.0')]
    procedure CheckServContractLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        CheckServiceDocument: Codeunit Microsoft.Service.Document."Check Service Document";
    begin
        CheckServiceDocument.CheckServiceContractLines(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;
#endif

    procedure CheckUpdateFieldsForNonInventoriableItem()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckUpdateFieldsForNonInventoriableItem(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        CalcFields("Assembly BOM");
        TestField("Assembly BOM", false);

        CalcFields("Stockkeeping Unit Exists");
        TestField("Stockkeeping Unit Exists", false);

        Validate("Assembly Policy", "Assembly Policy"::"Assemble-to-Stock");
        Validate("Replenishment System", "Replenishment System"::Purchase);
        Validate(Reserve, Reserve::Never);
        Validate("Inventory Posting Group", '');
        Validate("Item Tracking Code", '');
        Validate("Costing Method", "Costing Method"::FIFO);
        Validate("Reordering Policy", "Reordering Policy"::" ");
        Validate("Order Tracking Policy", "Order Tracking Policy"::None);
        Validate("Indirect Cost %", 0);

        OnAfterCheckUpdateFieldsForNonInventoriableItem(Rec);
    end;

    procedure PreventNegativeInventory(): Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        case "Prevent Negative Inventory" of
            "Prevent Negative Inventory"::Yes:
                exit(true);
            "Prevent Negative Inventory"::No:
                exit(false);
            "Prevent Negative Inventory"::Default:
                begin
                    InventorySetup.Get();
                    exit(InventorySetup."Prevent Negative Inventory");
                end;
        end;
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure CheckJobPlanningLines() in codeunit CheckJobPlanningLine', '25.0')]
    procedure CheckJobPlanningLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        CheckJobPlanningLine: Codeunit "Check Job Planning Line";
    begin
        CheckJobPlanningLine.CheckJobPlanningLines(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;
#endif

    procedure CalcVAT(): Decimal
    begin
        if "Price Includes VAT" then begin
            VATPostingSetup.Get("VAT Bus. Posting Gr. (Price)", "VAT Prod. Posting Group");
            OnCalcVATOnAfterVATPostingSetupGet(VATPostingSetup);
            case VATPostingSetup."VAT Calculation Type" of
                VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                    VATPostingSetup."VAT %" := 0;
                VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                    Error(
                      Text006,
                      VATPostingSetup.FieldCaption("VAT Calculation Type"),
                      VATPostingSetup."VAT Calculation Type");
            end;
        end else
            Clear(VATPostingSetup);

        exit(VATPostingSetup."VAT %" / 100);
    end;

    procedure CalcUnitPriceExclVAT(): Decimal
    begin
        GetGLSetup();
        if 1 + CalcVAT() = 0 then
            exit(0);
        exit(Round("Unit Price" / (1 + CalcVAT()), GLSetup."Unit-Amount Rounding Precision"));
    end;

    procedure GetFirstItemNoFromLookup(ItemText: Text): Code[20]
    var
        Item: Record Item;
        SearchFilter: Text;
    begin
        if ItemText = '' then
            exit('');
        Item.SetLoadFields("No.");
        if StrLen(ItemText) <= MaxStrLen(Item."No.") then
            if Item.Get(ItemText) then
                exit(Item."No.");
        if StrLen(ItemText) <= MaxStrLen(Item."No.") then begin
            Item.SetFilter("No.", ItemText + '*');
            if Item.FindFirst() then
                exit(Item."No.");
            Item.SetRange("No.");
        end;

        // Filter the same way as in item lookup/dropdown, ref. fieldgroup for DropDown
        SearchFilter := '@*' + ItemText + '*';
        Item.FilterGroup(-1);
        Item.SetFilter("No.", SearchFilter);
        Item.SetFilter("No. 2", SearchFilter);
        Item.SetFilter(Description, SearchFilter);
        Item.SetFilter(GTIN, SearchFilter);
        Item.SetFilter("Vendor Item No.", SearchFilter);
        Item.SetFilter("Common Item No.", SearchFilter);
        Item.SetFilter("Shelf No.", SearchFilter);
        Item.FilterGroup(0);
        if Item.FindFirst() then
            exit(Item."No.");
        Error(SelectItemErr);
    end;

    procedure GetItemNo(ItemText: Text): Code[20]
    var
        ItemNo: Text[50];
    begin
        TryGetItemNo(ItemNo, ItemText, true);
        exit(CopyStr(ItemNo, 1, MaxStrLen("No.")));
    end;

    local procedure AsPriceAsset(var PriceAsset: Record "Price Asset"; PriceType: Enum "Price Type")
    begin
        PriceAsset.Init();
        PriceAsset."Price Type" := PriceType;
        PriceAsset."Asset Type" := PriceAsset."Asset Type"::Item;
        PriceAsset."Asset No." := "No.";
    end;

    procedure ShowPriceListLines(PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        PriceAsset: Record "Price Asset";
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        AsPriceAsset(PriceAsset, PriceType);
        PriceUXManagement.ShowPriceListLines(PriceAsset, PriceType, AmountType);
    end;

    procedure TryGetItemNo(var ReturnValue: Text[50]; ItemText: Text; DefaultCreate: Boolean): Boolean
    begin
        InventorySetup.Get();
        exit(TryGetItemNoOpenCard(ReturnValue, ItemText, DefaultCreate, true, not InventorySetup."Skip Prompt to Create Item"));
    end;

    procedure TryGetItemNoOpenCard(var ReturnValue: Text; ItemText: Text; DefaultCreate: Boolean; ShowItemCard: Boolean; ShowCreateItemOption: Boolean): Boolean
    var
        ItemView: Record Item;
    begin
        ItemView.SetRange(Blocked, false);
        exit(TryGetItemNoOpenCardWithView(ReturnValue, ItemText, DefaultCreate, ShowItemCard, ShowCreateItemOption, ItemView.GetView()));
    end;

    internal procedure TryGetItemNoOpenCardWithView(var ReturnValue: Text; ItemText: Text; DefaultCreate: Boolean; ShowItemCard: Boolean; ShowCreateItemOption: Boolean; View: Text): Boolean
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        FindRecordMgt: Codeunit "Find Record Management";
        ItemNo: Code[20];
        FoundRecordCount: Integer;
    begin
        ReturnValue := CopyStr(ItemText, 1, MaxStrLen(ReturnValue));
        if ItemText = '' then
            exit(DefaultCreate);

        FoundRecordCount :=
            FindRecordMgt.FindRecordByDescriptionAndView(ReturnValue, SalesLine.Type::Item.AsInteger(), ItemText, View);

        if FoundRecordCount = 1 then
            exit(true);

        if FoundRecordCount = 0 then begin
            ReturnValue := CopyStr(ItemText, 1, MaxStrLen(ReturnValue));
            if not DefaultCreate then
                exit(false);

            if not GuiAllowed then
                Error(SelectItemErr);

            OnTryGetItemNoOpenCardWithViewOnBeforeShowCreateItemOption(Rec);
            if Item.WritePermission then
                if ShowCreateItemOption then
                    case StrMenu(
                           StrSubstNo('%1,%2', StrSubstNo(CreateNewItemTxt, ConvertStr(ItemText, ',', '.')), SelectItemTxt), 1, ItemNotRegisteredTxt)
                    of
                        0:
                            Error('');
                        1:
                            begin
                                ReturnValue := CreateNewItem(CopyStr(ItemText, 1, MaxStrLen(Item.Description)), ShowItemCard);
                                exit(true);
                            end;
                    end
                else
                    exit(false);
        end;

        if not GuiAllowed then
            Error(SelectItemErr);

        if FoundRecordCount > 0 then begin
            Item.FilterGroup(-1); //to be used in PickItem
            Item.SetFilter("No.", ReturnValue);
            OnTryGetItemNoOpenCardOnAfterSetItemFilters(Item, ReturnValue);
        end;

        if ShowItemCard then
            ItemNo := PickItem(Item)
        else begin
            ReturnValue := '';
            exit(true);
        end;

        if ItemNo <> '' then begin
            ReturnValue := ItemNo;
            exit(true);
        end;

        ReturnValue := ItemText;

        if not DefaultCreate then
            exit(false);
        Error('');
    end;

    local procedure CreateNewItem(ItemName: Text[100]; ShowItemCard: Boolean): Code[20]
    var
        Item: Record Item;
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        ItemCard: Page "Item Card";
    begin
        OnBeforeCreateNewItem(Item, ItemName);
        if not ItemTemplMgt.InsertItemFromTemplate(Item) then
            Error(SelectItemErr);

        Item.Description := ItemName;
        Item.Modify(true);
        Commit();
        if not ShowItemCard then
            exit(Item."No.");
        Item.SetRange("No.", Item."No.");
        ItemCard.SetTableView(Item);
        if not (ItemCard.RunModal() = ACTION::OK) then
            Error(SelectItemErr);

        exit(Item."No.");
    end;

    local procedure CreateItemUnitOfMeasure()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateItemUnitOfMeasure(Rec, ItemUnitOfMeasure, IsHandled);
        if IsHandled then
            exit;

        ItemUnitOfMeasure.Init();
        if IsTemporary then
            ItemUnitOfMeasure."Item No." := "No."
        else
            ItemUnitOfMeasure.Validate("Item No.", "No.");
        ItemUnitOfMeasure.Validate(Code, "Base Unit of Measure");
        ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
        ItemUnitOfMeasure.Insert();
    end;

    procedure ShouldTryCostFromSKU(): Boolean
    var
        ShouldExit: Boolean;
    begin
        if Rec."Costing Method" <> Rec."Costing Method"::Standard then
            exit(false);

        OnShouldTryCostFromSKUOnCheckSKUCostOnMfg(ShouldExit);
        if ShouldExit then
            exit(false);

        InventorySetup.GetRecordOnce();
        exit(InventorySetup."Average Cost Calc. Type" = InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant");
    end;

    procedure PickItem(var Item: Record Item): Code[20]
    var
        ItemList: Page "Item List";
        FindRecordMgt: Codeunit "Find Record Management";
        RaiseNotification: Boolean;
    begin
        if Item.FilterGroup = -1 then
            ItemList.SetTempFilteredItemRec(Item);

        RaiseNotification := Item.Count > FindRecordMgt.GetMaxRecordCountToReturn();

        if Item.FindFirst() then;
        ItemList.SetTableView(Item);
        ItemList.SetRecord(Item);
        ItemList.LookupMode := true;
        if RaiseNotification then
            ItemList.DoShowNotification();
        if ItemList.RunModal() = ACTION::LookupOK then
            ItemList.GetRecord(Item)
        else
            Clear(Item);

        exit(Item."No.");
    end;

    procedure SetLastDateTimeModified()
    begin
        "Last DateTime Modified" := CurrentDateTime;
        "Last Date Modified" := DT2Date("Last DateTime Modified");
        "Last Time Modified" := DT2Time("Last DateTime Modified");
        OnAfterSetLastDateTimeModified(Rec);
    end;

    procedure SetLastDateTimeFilter(DateFilter: DateTime)
    var
        DotNet_DateTimeOffset: Codeunit DotNet_DateTimeOffset;
        SyncDateTimeUtc: DateTime;
        CurrentFilterGroup: Integer;
    begin
        SyncDateTimeUtc := DotNet_DateTimeOffset.ConvertToUtcDateTime(DateFilter);
        CurrentFilterGroup := FilterGroup;
        SetFilter("Last Date Modified", '>=%1', DT2Date(SyncDateTimeUtc));
        FilterGroup(-1);
        SetFilter("Last Date Modified", '>%1', DT2Date(SyncDateTimeUtc));
        SetFilter("Last Time Modified", '>%1', DT2Time(SyncDateTimeUtc));
        FilterGroup(CurrentFilterGroup);
    end;

    procedure UpdateCostIsAdjusted()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        NonAdjustedItemLedgEntryExists: Boolean;
        NonAdjustedAvgCostAdjmtEntryPointExists: Boolean;
        NonAdjustedInventoryAdjmtEntryOrderExists: Boolean;
        CostIsAdjusted: Boolean;
    begin
        ItemLedgerEntry.SetRange("Item No.", "No.");
        ItemLedgerEntry.SetRange("Applied Entry to Adjust", true);
        NonAdjustedItemLedgEntryExists := not ItemLedgerEntry.IsEmpty();

        AvgCostAdjmtEntryPoint.SetRange("Item No.", "No.");
        AvgCostAdjmtEntryPoint.SetRange("Cost Is Adjusted", false);
        NonAdjustedAvgCostAdjmtEntryPointExists := not AvgCostAdjmtEntryPoint.IsEmpty();

        InventoryAdjmtEntryOrder.SetRange("Item No.", "No.");
        InventoryAdjmtEntryOrder.SetRange("Cost Is Adjusted", false);
        InventoryAdjmtEntryOrder.SetRange("Order Type", InventoryAdjmtEntryOrder."Order Type"::Assembly);
        NonAdjustedInventoryAdjmtEntryOrderExists := not InventoryAdjmtEntryOrder.IsEmpty();

        InventoryAdjmtEntryOrder.SetRange("Order Type", InventoryAdjmtEntryOrder."Order Type"::Production);
        InventoryAdjmtEntryOrder.SetRange("Is Finished", true);
        NonAdjustedInventoryAdjmtEntryOrderExists := NonAdjustedInventoryAdjmtEntryOrderExists or not InventoryAdjmtEntryOrder.IsEmpty();

        CostIsAdjusted := not (NonAdjustedItemLedgEntryExists or NonAdjustedAvgCostAdjmtEntryPointExists or NonAdjustedInventoryAdjmtEntryOrderExists);
        if CostIsAdjusted <> "Cost is Adjusted" then begin
            "Cost is Adjusted" := CostIsAdjusted;
            Modify();
        end;
    end;

    procedure UpdateReplenishmentSystem() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateReplenishmentSystem(Rec, IsHandled, Result);
        if IsHandled then
            exit(Result);

        CalcFields("Assembly BOM");

        if "Assembly BOM" then begin
            if not (IsMfgItem() or IsAssemblyItem()) then begin
                Validate("Replenishment System", "Replenishment System"::Assembly);
                exit(true);
            end
        end else
            if IsAssemblyItem() then
                if "Assembly Policy" <> "Assembly Policy"::"Assemble-to-Order" then begin
                    Validate("Replenishment System", "Replenishment System"::Purchase);
                    exit(true);
                end;
    end;

    procedure UpdateUnitOfMeasureId()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if "Base Unit of Measure" = '' then begin
            Clear("Unit of Measure Id");
            exit;
        end;

        UnitOfMeasure.SetLoadFields(SystemId);
        if not UnitOfMeasure.Get("Base Unit of Measure") then
            exit;

        "Unit of Measure Id" := UnitOfMeasure.SystemId;
    end;

    local procedure UpdateQtyRoundingPrecisionForBaseUoM()
    var
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateQtyRoundingPrecisionForBaseUoM(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        // Reset Rounding Precision in old Base UOM
        if BaseItemUnitOfMeasure.Get("No.", xRec."Base Unit of Measure") then begin
            BaseItemUnitOfMeasure.Validate("Qty. Rounding Precision", 0);
            BaseItemUnitOfMeasure.Modify(true);
        end;
    end;

    procedure UpdateItemCategoryId()
    var
        ItemCategory: Record "Item Category";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if IsTemporary then
            exit;

        if not GraphMgtGeneralTools.IsApiEnabled() then
            exit;

        if "Item Category Code" = '' then begin
            Clear("Item Category Id");
            exit;
        end;

        if not ItemCategory.Get("Item Category Code") then
            exit;

        "Item Category Id" := ItemCategory.SystemId;

        OnAfterUpdateItemCategoryId(Rec, ItemCategory);
    end;

    procedure UpdateTaxGroupId()
    var
        TaxGroup: Record "Tax Group";
    begin
        if "Tax Group Code" = '' then begin
            Clear("Tax Group Id");
            exit;
        end;

        TaxGroup.SetLoadFields(SystemId);
        if not TaxGroup.Get("Tax Group Code") then
            exit;

        "Tax Group Id" := TaxGroup.SystemId;
    end;

    local procedure UpdateUnitOfMeasureCode()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.SetLoadFields("Code");
        if not IsNullGuid("Unit of Measure Id") then
            UnitOfMeasure.GetBySystemId("Unit of Measure Id");

        "Base Unit of Measure" := UnitOfMeasure.Code;
    end;

    local procedure UpdateTaxGroupCode()
    var
        TaxGroup: Record "Tax Group";
    begin
        TaxGroup.SetLoadFields("Code");
        if not IsNullGuid("Tax Group Id") then
            TaxGroup.GetBySystemId("Tax Group Id");

        Validate("Tax Group Code", TaxGroup.Code);
    end;

    local procedure UpdateItemCategoryCode()
    var
        ItemCategory: Record "Item Category";
    begin
        ItemCategory.SetLoadFields("Code");
        if not IsNullGuid("Item Category Id") then
            ItemCategory.GetBySystemId("Item Category Id");

        "Item Category Code" := ItemCategory.Code;
    end;

    procedure UpdateReferencedIds()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if IsTemporary then
            exit;

        if not GraphMgtGeneralTools.IsApiEnabled() then
            exit;

        UpdateUnitOfMeasureId();
        UpdateTaxGroupId();
        UpdateItemCategoryId();
    end;

    procedure GetReferencedIds(var TempField: Record "Field" temporary)
    var
        DataTypeManagement: Codeunit "Data Type Management";
    begin
        DataTypeManagement.InsertFieldToBuffer(TempField, DATABASE::Item, FieldNo("Unit of Measure Id"));
        DataTypeManagement.InsertFieldToBuffer(TempField, DATABASE::Item, FieldNo("Tax Group Id"));
        DataTypeManagement.InsertFieldToBuffer(TempField, DATABASE::Item, FieldNo("Item Category Id"));
    end;

    procedure IsServiceType(): Boolean
    begin
        exit(Type = Type::Service);
    end;

    procedure IsNonInventoriableType(): Boolean
    begin
        exit(Type in [Type::"Non-Inventory", Type::Service]);
    end;

    procedure IsInventoriableType(): Boolean
    begin
        exit(not IsNonInventoriableType());
    end;

    procedure IsVariantMandatory(IsTypeItem: Boolean; ItemNo: Code[20]): Boolean
    begin
        if IsTypeItem and (ItemNo <> '') then
            exit(IsVariantMandatory(ItemNo));
        exit(false)
    end;

    procedure IsVariantMandatory(): Boolean
    begin
        exit(IsVariantMandatory(Rec."No."));
    end;

    local procedure IsVariantMandatory(ItemNo: Code[20]) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsVariantMandatory(ItemNo, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if ItemNo <> Rec."No." then begin
            Rec.SetLoadFields("No.", "Variant Mandatory if Exists");
            if Rec.Get(ItemNo) then;
            Rec.SetLoadFields();
        end;
        if ItemNo <> Rec."No." then
            exit(false);
        if VariantMandatoryIfAvailable(false, false) then
            exit(VariantsAvailable(ItemNo))
        else
            exit(false);
    end;

    internal procedure IsVariantMandatory(InvtSetupDefaultSetting: boolean): Boolean
    begin
        if VariantMandatoryIfAvailable(true, InvtSetupDefaultSetting) then
            exit(VariantsAvailable())
        else
            exit(false);
    end;

    local procedure VariantMandatoryIfAvailable(InvtSetupDefaultIsKnown: boolean; InvtSetupDefaultSetting: boolean): Boolean
    begin
        case "Variant Mandatory if Exists" of
            "Variant Mandatory if Exists"::Default:
                begin
                    if InvtSetupDefaultIsKnown then
                        exit(InvtSetupDefaultSetting);
                    GetInvtSetup();
                    exit(InventorySetup."Variant Mandatory if Exists");
                end;
            "Variant Mandatory if Exists"::No:
                exit(false);
            "Variant Mandatory if Exists"::Yes:
                exit(true);
        end;
    end;

    local procedure VariantsAvailable(): Boolean
    begin
        exit(VariantsAvailable(Rec."No."));
    end;

    local procedure VariantsAvailable(ItemNo: Code[20]): Boolean
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.SetLoadFields("Item No.");
        ItemVariant.SetRange("Item No.", ItemNo);
        exit(not ItemVariant.IsEmpty());
    end;

    local procedure UpdateItemUnitGroup()
    var
        UnitGroup: Record "Unit Group";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if CRMIntegrationManagement.IsIntegrationEnabled() then begin
            UnitGroup.SetRange("Source Id", Rec.SystemId);
            UnitGroup.SetRange("Source Type", UnitGroup."Source Type"::Item);
            if UnitGroup.IsEmpty() then begin
                UnitGroup.Init();
                UnitGroup."Source Id" := Rec.SystemId;
                UnitGroup."Source No." := Rec."No.";
                UnitGroup."Source Type" := UnitGroup."Source Type"::Item;
                UnitGroup.Insert();
            end;
        end
    end;

    local procedure AdjustCostIfRequired(CheckFieldCaption: Text)
    var
        Item: Record Item;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if Rec."Cost is Adjusted" then
            exit;

        if not NonAdjustedProdOrAsmOrderExists() then
            exit;

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(CostAdjustmentRequiredQst, CheckFieldCaption)) then
            Error(Text7381);

        Item.Copy(Rec);

        RunCostAdjustment(Item);

        Rec.Get(Item."No.");
        Rec."Overhead Rate" := Item."Overhead Rate";
        Rec."Indirect Cost %" := Item."Indirect Cost %";
    end;

    local procedure NonAdjustedProdOrAsmOrderExists(): Boolean
    var
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        InventoryAdjmtEntryOrder.SetRange("Item No.", Rec."No.");
        InventoryAdjmtEntryOrder.SetRange("Cost is Adjusted", false);
        InventoryAdjmtEntryOrder.SetRange("Order Type", InventoryAdjmtEntryOrder."Order Type"::Assembly);
        if not InventoryAdjmtEntryOrder.IsEmpty() then
            exit(true);

        InventoryAdjmtEntryOrder.SetRange("Order Type", InventoryAdjmtEntryOrder."Order Type"::Production);
        InventoryAdjmtEntryOrder.SetRange("Is Finished", true);
        if not InventoryAdjmtEntryOrder.IsEmpty() then
            exit(true);

        exit(false);
    end;

    local procedure RunCostAdjustment(var Item: Record Item)
    var
        CostAdjustmentItemRunner: Codeunit "Cost Adjustment Item Runner";
    begin
        GetInvtSetup();
        Item.SetRecFilter();
        CostAdjustmentItemRunner.SetPostToGL(InventorySetup."Automatic Cost Posting");
        CostAdjustmentItemRunner.Run(Item);
    end;

    local procedure DeleteItemUnitGroup()
    var
        UnitGroup: Record "Unit Group";
    begin
        if UnitGroup.Get(UnitGroup."Source Type"::Item, Rec.SystemId) then
            UnitGroup.Delete();
    end;

    procedure CalcScheduledReceiptQty() Result: Decimal
    begin
        OnCalcScheduledReceiptQty(Rec, Result);
    end;

    procedure CalcQtyOnComponentLines() Result: Decimal
    begin
        OnCalcQtyOnComponentLines(Rec, Result);
    end;

    procedure CalcQtyOnProdOrder() Result: Decimal
    begin
        OnCalcQtyOnProdOrder(Rec, Result);
    end;

    procedure CalcResQtyonProdOrderComp() Result: Decimal
    begin
        OnCalcResQtyonProdOrderComp(Rec, Result);
    end;

    procedure CalcReservedQtyOnProdOrder() Result: Decimal
    begin
        OnCalcReservedQtyOnProdOrder(Rec, Result);
    end;

    procedure CalcPlannedOrderReceiptQty() Result: Decimal
    begin
        OnCalcPlannedOrderReceiptQty(Rec, Result);
    end;

    procedure CalcFPOrderReceiptQty() Result: Decimal
    begin
        OnCalcFPOrderReceiptQty(Rec, Result);
    end;

    procedure CalcRelOrderReceiptQty() Result: Decimal
    begin
        OnCalcRelOrderReceiptQty(Rec, Result);
    end;

    procedure CalcQtyOnServiceOrder() Result: Decimal
    begin
        OnCalcQtyOnServiceOrder(Rec, Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDocuments(var Item: Record Item; var xItem: Record Item; var CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRelatedData(Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsAssemblyItem(Item: Record Item; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsMfgItem(Item: Record Item; var Result: Boolean)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnIsProductionBOM(Item: Record Item; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsMfgItem(Item: Record Item; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsAssemblyItem(Item: Record Item; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var Item: Record Item; xItem: Record Item; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInsert(var Item: Record Item; var xItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetLastDateTimeModified(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var Item: Record Item; var xItem: Record Item; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSNSpecificTrackingInteger(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUpdateFieldsForNonInventoriableItem(var Item: Record Item; xItem: Record Item; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateItemUnitOfMeasure(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNewItem(var Item: Record Item; var ItemName: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var Item: Record Item; var IsHandled: Boolean; xRecItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoItemLedgEntiesExist(var Item: Record Item; CurrentFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoOpenDocumentsWithTrackingExist(Item: Record Item; ItemTrackingCode2: Record "Item Tracking Code"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoOpenEntriesExist(Item: Record Item; var ItemLedgerEntry: Record "Item Ledger Entry"; CurrentFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoPurchLinesExist(Item: Record Item; CurrentFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoWhseEntriesExist(Item: Record Item; CurrentFieldName: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQtyRoundingPrecisionForBaseUoM(var Item: Record Item; xItem: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var Item: Record Item; xItem: Record Item; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateStandardCost(var Item: Record Item; xItem: Record Item; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBaseUnitOfMeasure(var Item: Record Item; xItem: Record Item; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReplenishmentSystemCaseElse(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReplenishmentSystemCaseTransfer(var Item: Record Item; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindItemVendOnAfterSetFilters(var ItemVend: Record "Item Vendor"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTryGetItemNoOpenCardOnAfterSetItemFilters(var Item: Record Item; var ItemFilterContains: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBaseUnitOfMeasure(var ValidateBaseUnitOfMeasure: Boolean)
    begin
    end;

    procedure ExistsItemLedgerEntry(): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if "No." = '' then
            exit;

        ItemLedgEntry.SetRange("Item No.", "No.");
        exit(not ItemLedgEntry.IsEmpty);
    end;

    procedure ItemTrackingCodeUseExpirationDates(): Boolean
    begin
        if "Item Tracking Code" = '' then
            exit(false);

        ItemTrackingCode.SetLoadFields("Use Expiration Dates");
        ItemTrackingCode.Get("Item Tracking Code");
        ItemTrackingCode.SetLoadFields();
        exit(ItemTrackingCode."Use Expiration Dates");
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"My Item", 'rm')]
    local procedure UpdateMyItem(CallingFieldNo: Integer)
    var
        MyItem: Record "My Item";
    begin
        case CallingFieldNo of
            FieldNo(Description):
                begin
                    MyItem.SetRange("Item No.", "No.");
                    if not MyItem.IsEmpty() then
                        MyItem.ModifyAll(Description, Description);
                end;
            FieldNo("Unit Price"):
                begin
                    MyItem.SetRange("Item No.", "No.");
                    if not MyItem.IsEmpty() then
                        MyItem.ModifyAll("Unit Price", "Unit Price");
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePhysInvtCountingPeriodCodeOnBeforeConfirmUpdate(var Item: Record Item; xItem: Record Item; PhysInvtCountPeriod: Record "Phys. Invt. Counting Period"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateReplenishmentSystem(var Item: Record Item; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReplenishmentSystemCaseAssemblyr(var Item: Record Item; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUnitCost(var Item: Record Item; xItem: Record Item; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTryGetItemNoOpenCardWithViewOnBeforeShowCreateItemOption(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateItemCategoryCode(var Item: Record Item; xItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderTrackingPolicyOnBeforeUpdateReservation(var Item: Record Item; var ShouldRaiseRegenerativePlanningMessage: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATOnAfterVATPostingSetupGet(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDocuments(Item: Record Item; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeCheckPurchLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
        OnBeforeCheckPurchLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
    end;

    [Obsolete('Replace by same event in codeunit CheckPurchDocumentLine', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchLine(Item: Record Item; CurrFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeCheckSalesLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
        OnBeforeCheckSalesLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
    end;

    [Obsolete('Replace by same event in codeunit CheckSalesDocumentLine', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeCheckServLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
        OnBeforeCheckServLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
    end;

    [Obsolete('Moved to codeunit CheckServiceDocument', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeCheckServContractLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
        OnBeforeCheckServContractLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
    end;

    [Obsolete('Moved to codeunit CheckServiceDocument', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServContractLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeCheckProdOrderLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
        OnBeforeCheckProdOrderLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
    end;

    [Obsolete('Moved to codeunit CheckProdOrderDocument', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdOrderLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeCheckProdOrderCompLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
        OnBeforeCheckProdOrderCompLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
    end;

    [Obsolete('Moved to codeunit CheckProdOrderDocument', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdOrderCompLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeCheckBOM(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
        OnBeforeCheckBOM(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
    end;

    [Obsolete('Moved to codeunit CheckBOMComponent', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBOM(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeCheckProdBOMLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
        OnBeforeCheckProdBOMLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
    end;

    [Obsolete('Moved to codeunit CheckProdOrderDocument', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdBOMLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeCheckPlanningCompLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
        OnBeforeCheckPlanningCompLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
    end;

    [Obsolete('Moved to codeunit CheckPlanningComponent', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPlanningCompLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeCheckJobPlanningLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
        OnBeforeCheckJobPlanningLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
    end;

    [Obsolete('Moved to codeunit CheckJobPlanningLine', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckJobPlanningLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeCheckAsmHeader(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
        OnBeforeCheckAsmHeader(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
    end;

    [Obsolete('Moved to codeunit CheckAssemblyDocument', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAsmHeader(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeCheckAsmLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
        OnBeforeCheckAsmLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
    end;

    [Obsolete('Moved to codeunit CheckAssemblyDocument', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAsmLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeCheckTransLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
        OnBeforeCheckTransLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
    end;

    [Obsolete('Moved to codeunit CheckTransferDocument', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReqLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemJnlLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnCheckPurchLineOnAfterPurchLineSetFilters(Item: Record Item; var PurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    begin
        OnCheckPurchLineOnAfterPurchLineSetFilters(Item, PurchaseLine, CurrFieldNo, CheckFieldNo, CheckFieldCaption);
    end;

    [Obsolete('Moved to codeunit CheckPurchaseDocument', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCheckPurchLineOnAfterPurchLineSetFilters(Item: Record Item; var PurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsVariantMandatory(ItemNo: Code[20]; var IsHandled: Boolean; var Result: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNo(var IsHandled: Boolean; var Item: Record Item; xItem: Record Item; InventorySetup: Record "Inventory Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindItemVend(var Item: Record Item; var ItemVendor: Record "Item Vendor"; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnBeforePlanningAssignmentItemChange(var Item: Record Item; xItem: Record Item; PlanningAssignment: Record "Planning Assignment"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindItemVend(var ItemVendor: Record "Item Vendor"; Item: Record Item; StockkeepingUnit: Record "Stockkeeping Unit"; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTypeOnBeforeCheckExistsItemLedgerEntry(var Item: Record Item; xItem: Record Item; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckStdCostWksh(var Item: Record Item; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasBOM(var Item: Record Item; var Result: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasRoutingNo(var Item: Record Item; var Result: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckUpdateFieldsForNonInventoriableItem(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemTrackingCodeOnBeforeTestNoEntriesExist(var Item: Record Item; xItem: Record Item; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateGenProdPostingGroupOnConfirmChange(var Item: Record Item; xItemGenProdPostingGroupCode: Code[20]; var ShouldExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateItemCategoryId(var Item: Record Item; var ItemCategory: Record "Item Category")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindItemVendOnAfterFindItemVend(var ItemVendor: Record "Item Vendor"; Item: Record Item; var StockkeepingUnit: Record "Stockkeeping Unit"; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnAfterAssignNo(var Item: Record Item; xItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditOnAfterAssignNo(var Item: Record Item; xItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcScheduledReceiptQty(var Item: Record Item; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyOnComponentLines(var Item: Record Item; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyOnProdOrder(var Item: Record Item; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcResQtyonProdOrderComp(var Item: Record Item; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcReservedQtyOnProdOrder(var Item: Record Item; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPlannedOrderReceiptQty(var Item: Record Item; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcFPOrderReceiptQty(var Item: Record Item; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRelOrderReceiptQty(var Item: Record Item; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyOnServiceOrder(var Item: Record Item; var Result: Decimal)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnShouldTryCostFromSKUOnCheckSKUCostOnMfg(var ShouldExit: Boolean)
    begin
    end;
}
