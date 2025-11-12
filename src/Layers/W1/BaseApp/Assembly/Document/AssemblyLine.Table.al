// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Assembly.Setup;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Structure;

table 901 "Assembly Line"
{
    Caption = 'Assembly Line';
    DrillDownPageID = "Assembly Lines";
    LookupPageID = "Assembly Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Assembly Document Type")
        {
            Caption = 'Document Type';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Assembly Header"."No." where("Document Type" = field("Document Type"));

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(10; Type; Enum "BOM Component Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                TestField("Consumed Quantity", 0);
                VerifyReservationChange(Rec, xRec);
                TestStatusOpen();

                "No." := '';
                "Variant Code" := '';
                "Location Code" := '';
                "Bin Code" := '';
                InitResourceUsageType();
                "Inventory Posting Group" := '';
                "Gen. Prod. Posting Group" := '';
                Clear("Lead-Time Offset");
            end;
        }
        field(11; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(Item)) Item where(Type = filter(Inventory | "Non-Inventory"))
            else
            if (Type = const(Resource)) Resource;

            trigger OnValidate()
            begin
                "Location Code" := '';
                "Bin Code" := '';
                TestField("Consumed Quantity", 0);
                CalcFields("Reserved Quantity");
                AssemblyWarehouseMgt.AssemblyLineVerifyChange(Rec, xRec);
                if "No." <> '' then
                    CheckItemAvailable(FieldNo("No."));
                VerifyReservationChange(Rec, xRec);
                TestStatusOpen();

                if "No." <> xRec."No." then begin
                    "Variant Code" := '';
                    InitResourceUsageType();
                end;

                if "No." = '' then
                    Init()
                else begin
                    GetHeader();

                    if Rec."No." <> xRec."No." then
                        Validate("Dimension Set ID", 0);

                    "Due Date" := AssemblyHeader."Starting Date";
                    Rec.Validate("Gen. Bus. Posting Group", AssemblyHeader."Gen. Bus. Posting Group");
                    case Type of
                        Type::Item:
                            CopyFromItem();
                        Type::Resource:
                            CopyFromResource();
                    end
                end;
            end;
        }
        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."), Code = field("Variant Code"));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                TestField(Type, Type::Item);
                TestField("Consumed Quantity", 0);
                CalcFields("Reserved Quantity");
                TestField("Reserved Quantity", 0);
                AssemblyWarehouseMgt.AssemblyLineVerifyChange(Rec, xRec);
                CheckItemAvailable(FieldNo("Variant Code"));
                VerifyReservationChange(Rec, xRec);
                TestStatusOpen();

                if Rec."Variant Code" = '' then begin
                    GetItemResource();
                    Description := Item.Description;
                    "Description 2" := Item."Description 2"
                end else begin
                    ItemVariant.SetLoadFields(Description, "Description 2", Blocked);
                    ItemVariant.Get("No.", "Variant Code");
                    ItemVariant.TestField(Blocked, false);
                    Description := ItemVariant.Description;
                    "Description 2" := ItemVariant."Description 2";
                end;

                GetDefaultBin();
                "Unit Cost" := GetUnitCost();
                "Cost Amount" := CalcCostAmount(Quantity, "Unit Cost");
            end;
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(14; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(18; "Lead-Time Offset"; DateFormula)
        {
            Caption = 'Lead-Time Offset';

            trigger OnValidate()
            begin
                GetHeader();
                ValidateLeadTimeOffset(AssemblyHeader, "Lead-Time Offset", true);
            end;
        }
        field(19; "Resource Usage Type"; Option)
        {
            Caption = 'Resource Usage Type';
            OptionCaption = ' ,Direct,Fixed';
            OptionMembers = " ",Direct,"Fixed";

            trigger OnValidate()
            begin
                if "Resource Usage Type" = xRec."Resource Usage Type" then
                    exit;

                if Type = Type::Resource then
                    TestField("Resource Usage Type")
                else
                    TestField("Resource Usage Type", "Resource Usage Type"::" ");

                GetHeader();
                Validate(Quantity, CalcQuantity("Quantity per", AssemblyHeader.Quantity));
            end;
        }
        field(20; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            begin
                TestField(Type, Type::Item);

                AssemblyWarehouseMgt.AssemblyLineVerifyChange(Rec, xRec);
                CheckItemAvailable(FieldNo("Location Code"));
                VerifyReservationChange(Rec, xRec);
                TestStatusOpen();

                GetDefaultBin();

                "Unit Cost" := GetUnitCost();
                "Cost Amount" := CalcCostAmount(Quantity, "Unit Cost");
                CreateDimFromDefaultDim(AssemblyHeader."Dimension Set ID");
            end;
        }
        field(21; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(22; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(23; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));

            trigger OnLookup()
            var
                WMSManagement: Codeunit "WMS Management";
                BinCode: Code[20];
            begin
                TestField(Type, Type::Item);
                if Quantity > 0 then
                    BinCode := WMSManagement.BinContentLookUp("Location Code", "No.", "Variant Code", '', "Bin Code")
                else
                    BinCode := WMSManagement.BinLookUp("Location Code", "No.", "Variant Code", '');

                if BinCode <> '' then
                    Validate("Bin Code", BinCode);
            end;

            trigger OnValidate()
            var
                WMSManagement: Codeunit "WMS Management";
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
            begin
                TestStatusOpen();
                TestField(Type, Type::Item);
                if "Bin Code" <> '' then begin
                    TestField("Location Code");
                    Item.Get("No.");
                    Item.TestField(Type, Item.Type::Inventory);
                    WMSManagement.FindBin("Location Code", "Bin Code", '');
                    WhseIntegrationMgt.CheckBinTypeAndCode(
                        DATABASE::"Assembly Line", FieldCaption("Bin Code"), "Location Code", "Bin Code", 0);
                    CheckBin();
                end;
            end;
        }
        field(25; Position; Code[10])
        {
            Caption = 'Position';
        }
        field(26; "Position 2"; Code[10])
        {
            Caption = 'Position 2';
        }
        field(27; "Position 3"; Code[10])
        {
            Caption = 'Position 3';
        }
        field(38; "Appl.-to Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-to Item Entry';

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Appl.-to Item Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                if "Appl.-to Item Entry" <> 0 then begin
                    TestField(Type, Type::Item);
                    TestField(Quantity);
                    if Quantity < 0 then
                        FieldError(Quantity, Text029);
                    ItemLedgEntry.Get("Appl.-to Item Entry");
                    ItemLedgEntry.TestField(Positive, true);
                    "Location Code" := ItemLedgEntry."Location Code";
                    OnValidateApplToItemEntryOnBeforeShowNotOpenItemLedgerEntryMessage(Rec, xRec, ItemLedgEntry, CurrFieldNo);
                    if not ItemLedgEntry.Open then
                        Message(Text042, "Appl.-to Item Entry");
                end;
            end;
        }
        field(39; "Appl.-from Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-from Item Entry';
            MinValue = 0;

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Appl.-from Item Entry"));
            end;
        }
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            var
                UOMMgt: Codeunit "Unit of Measure Management";
            begin
                AssemblyWarehouseMgt.AssemblyLineVerifyChange(Rec, xRec);

                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));

                "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));
                OnValidateQuantityOnAfterCalcBaseQty(Rec, xRec, CurrFieldNo);
                InitRemainingQty();
                InitQtyToConsume();

                CheckItemAvailable(FieldNo(Quantity));
                VerifyReservationQuantity(Rec, xRec);

                "Cost Amount" := CalcCostAmount(Quantity, "Unit Cost");
            end;
        }
        field(41; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantityBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(42; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(43; "Remaining Quantity (Base)"; Decimal)
        {
            Caption = 'Remaining Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(44; "Consumed Quantity"; Decimal)
        {
            Caption = 'Consumed Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Consumed Quantity (Base)" := CalcBaseQty("Consumed Quantity", FieldCaption("Consumed Quantity"), FieldCaption("Consumed Quantity (Base)"));
                InitRemainingQty();
            end;
        }
        field(45; "Consumed Quantity (Base)"; Decimal)
        {
            Caption = 'Consumed Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(46; "Quantity to Consume"; Decimal)
        {
            Caption = 'Quantity to Consume';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                UOMMgt: Codeunit "Unit of Measure Management";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantitytoConsume(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                AssemblyWarehouseMgt.AssemblyLineVerifyChange(Rec, xRec);

                "Quantity to Consume" := UOMMgt.RoundAndValidateQty("Quantity to Consume", "Qty. Rounding Precision", FieldCaption("Quantity to Consume"));

                RoundQty("Remaining Quantity");
                if "Quantity to Consume" > "Remaining Quantity" then
                    Error(Text003,
                      FieldCaption("Quantity to Consume"), FieldCaption("Remaining Quantity"), "Remaining Quantity");

                Validate(
                    "Quantity to Consume (Base)",
                    CalcBaseQty("Quantity to Consume", FieldCaption("Quantity to Consume"), FieldCaption("Quantity to Consume (Base)"))
                );
            end;
        }
        field(47; "Quantity to Consume (Base)"; Decimal)
        {
            Caption = 'Quantity to Consume (Base)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(48; "Reserved Quantity"; Decimal)
        {
            CalcFormula = - sum("Reservation Entry".Quantity where("Source ID" = field("Document No."),
                                                                   "Source Ref. No." = field("Line No."),
                                                                   "Source Type" = const(901),
#pragma warning disable AL0603
                                                                   "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                   "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(49; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Source ID" = field("Document No."),
                                                                            "Source Ref. No." = field("Line No."),
                                                                            "Source Type" = const(901),
#pragma warning disable AL0603
                                                                            "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                            "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; "Avail. Warning"; Boolean)
        {
            Caption = 'Avail. Warning';
            Editable = false;
        }
        field(51; "Substitution Available"; Boolean)
        {
            CalcFormula = exist("Item Substitution" where(Type = const(Item),
                                                           "Substitute Type" = const(Item),
                                                           "No." = field("No."),
                                                           "Variant Code" = field("Variant Code")));
            Caption = 'Substitution Available';
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                GetHeader();
                ValidateDueDate(AssemblyHeader, "Due Date", true);
            end;
        }
        field(53; Reserve; Enum "Reserve Method")
        {
            Caption = 'Reserve';

            trigger OnValidate()
            begin
                if Reserve <> Reserve::Never then begin
                    TestField(Type, Type::Item);
                    TestField("No.");
                end;

                CalcFields("Reserved Qty. (Base)");
                if Reserve = Reserve::Never then
                    TestField("Reserved Qty. (Base)", 0);

                if xRec.Reserve = Reserve::Always then begin
                    GetItemResource();
                    if Item.Reserve = Item.Reserve::Always then
                        TestField(Reserve, Reserve::Always);
                end;
            end;
        }
        field(60; "Quantity per"; Decimal)
        {
            Caption = 'Quantity per';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantityPer(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                AssemblyWarehouseMgt.AssemblyLineVerifyChange(Rec, xRec);
                if Type = Type::" " then
                    Error(Text99000002, FieldCaption("Quantity per"), FieldCaption(Type), Type::" ");
                RoundQty("Quantity per");
                OnValidateQuantityPerOnAfterRoundQty(Rec);

                GetHeader();
                Validate(Quantity, CalcQuantity("Quantity per", AssemblyHeader.Quantity));
                Validate(
                  "Quantity to Consume",
                  MinValue(MaxQtyToConsume(), CalcQuantity("Quantity per", AssemblyHeader."Quantity to Assemble")));
            end;
        }
        field(61; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(62; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(63; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(64; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(65; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            var
                SkuItemUnitCost: Decimal;
            begin
                TestField("No.");
                GetItemResource();
                if Type = Type::Item then begin
                    SkuItemUnitCost := GetUnitCost();
                    if Item."Costing Method" = Item."Costing Method"::Standard then
                        if "Unit Cost" <> SkuItemUnitCost then
                            Error(
                              Text99000002,
                              FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                end;

                "Cost Amount" := CalcCostAmount(Quantity, "Unit Cost");
            end;
        }
        field(67; "Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Cost Amount';
            Editable = false;
        }
        field(72; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(80; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            if (Type = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("No."));

            trigger OnValidate()
            begin
                AssemblyWarehouseMgt.AssemblyLineVerifyChange(Rec, xRec);
                TestStatusOpen();

                GetItemResource();
                SetQtyPerUoMAndQtyRoundingPrecision();

                CheckItemAvailable(FieldNo("Unit of Measure Code"));
                "Unit Cost" := GetUnitCost();
                Validate(Quantity);
            end;
        }
        field(82; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
            AutoFormatType = 0;
        }
        field(83; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
            AutoFormatType = 0;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            var
                DimMgt: Codeunit DimensionManagement;
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(7301; "Pick Qty."; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding" where("Activity Type" = filter(<> "Put-away"),
                                                                                  "Source Type" = const(901),
#pragma warning disable AL0603
                                                                                  "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                                  "Source No." = field("Document No."),
                                                                                  "Source Line No." = field("Line No."),
                                                                                  "Source Subline No." = const(0),
                                                                                  "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                  "Action Type" = filter(" " | Place),
                                                                                  "Original Breakbulk" = const(false),
                                                                                  "Breakbulk No." = const(0)));
            Caption = 'Pick Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(7302; "Pick Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding (Base)" where("Activity Type" = filter(<> "Put-away"),
                                                                                         "Source Type" = const(901),
#pragma warning disable AL0603
                                                                                         "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                                         "Source No." = field("Document No."),
                                                                                         "Source Line No." = field("Line No."),
                                                                                         "Source Subline No." = const(0),
                                                                                         "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                         "Action Type" = filter(" " | Place),
                                                                                         "Original Breakbulk" = const(false),
                                                                                         "Breakbulk No." = const(0)));
            Caption = 'Pick Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(7303; "Qty. Picked"; Decimal)
        {
            Caption = 'Qty. Picked';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Picked (Base)" := CalcBaseQty("Qty. Picked", FieldCaption("Qty. Picked"), FieldCaption("Qty. Picked (Base)"));
            end;
        }
        field(7304; "Qty. Picked (Base)"; Decimal)
        {
            Caption = 'Qty. Picked (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Document No.", Type, "Location Code")
        {
            IncludedFields = "Cost Amount", Quantity, "No.";
        }
        key(Key3; "Document Type", Type, "No.", "Variant Code", "Location Code", "Due Date")
        {
            IncludedFields = "Remaining Quantity (Base)", "Qty. Picked (Base)", "Consumed Quantity (Base)";
        }
        key(Key4; Type, "No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "No.", Description, Quantity, Type, "Unit of Measure Code")
        { }
    }

    trigger OnDelete()
    var
        WhseAssemblyRelease: Codeunit "Whse.-Assembly Release";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        TestStatusOpen();
        ConfirmDeletion();

        AssemblyWarehouseMgt.AssemblyLineDelete(Rec);
        WhseAssemblyRelease.DeleteLine(Rec);
        AssemblyLineReserve.DeleteLine(Rec);
        ItemTrackingMgt.DeleteWhseItemTrkgLines(
          DATABASE::"Assembly Line", "Document Type".AsInteger(), "Document No.", '', 0, "Line No.", "Location Code", true);

        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);
    end;

    trigger OnInsert()
    begin
        TestStatusOpen();
        VerifyReservationQuantity(Rec, xRec);
    end;

    trigger OnModify()
    begin
        AssemblyWarehouseMgt.AssemblyLineVerifyChange(Rec, xRec);
        VerifyReservationChange(Rec, xRec);
    end;

    trigger OnRename()
    begin
        Error(Text002, TableCaption);
    end;

    var
        Item: Record Item;
        Resource: Record Resource;
        AssemblyHeader: Record "Assembly Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
        GLSetup: Record "General Ledger Setup";
        ItemSubstMgt: Codeunit "Item Subst.";
        AssemblyWarehouseMgt: Codeunit "Assembly Warehouse Mgt.";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        GLSetupRead: Boolean;
        TestReservationDateConflict: Boolean;
        SkipVerificationsThatChangeDatabase: Boolean;
        CalledFromHeader: Boolean;

#pragma warning disable AA0074
        Text001: Label 'Automatic reservation is not possible.\Do you want to reserve items manually?';
#pragma warning disable AA0470
        Text002: Label 'You cannot rename an %1.';
        Text003: Label '%1 cannot be higher than the %2, which is %3.';
#pragma warning restore AA0470
        Text029: Label 'must be positive', Comment = 'starts with "Quantity"';
#pragma warning disable AA0470
        Text042: Label 'When posting the Applied to Ledger Entry, %1 will be opened first.';
        Text049: Label '%1 cannot be later than %2 because the %3 is set to %4.';
        Text050: Label 'Due Date %1 is before work date %2.';
        Text99000002: Label 'You cannot change %1 when %2 is ''%3''.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        AvailabilityPageTitleLbl: Label 'The available inventory for item %1 is lower than the entered quantity at this location.', Comment = '%1=Item No.';
        ConfirmDeleteQst: Label '%1 = %2 is greater than %3 = %4. If you delete the %5, the items will remain in the operation area until you put them away.\Any related item tracking information defined during the pick process will be deleted.\Do you still want to delete the %5?', Comment = '%1 = FieldCaption("Qty. Picked"), %2 = "Qty. Picked", %3 = FieldCaption(Consumed Quantity), %4 = Consumed Quantity, %5 = TableCaption';

    protected var
        StatusCheckSuspended: Boolean;

    procedure InitRemainingQty()
    begin
        "Remaining Quantity" := MaxValue(Quantity - "Consumed Quantity", 0);
        "Remaining Quantity (Base)" := MaxValue("Quantity (Base)" - "Consumed Quantity (Base)", 0);

        OnAfterInitRemainingQty(Rec, xRec, CurrFieldNo);
    end;

    procedure InitQtyToConsume()
    begin
        OnBeforeInitQtyToConsume(Rec, xRec, CurrFieldNo);

        GetHeader();
        "Quantity to Consume" :=
          MinValue(MaxQtyToConsume(), CalcQuantity("Quantity per", AssemblyHeader."Quantity to Assemble"));
        RoundQty("Quantity to Consume");
        if MaxQtyToConsumeBase() <> 0 then
            "Quantity to Consume (Base)" := MinValue(MaxQtyToConsumeBase(), CalcBaseQty("Quantity to Consume", FieldCaption("Quantity to Consume"), FieldCaption("Quantity to Consume (Base)")))
        else
            "Quantity to Consume (Base)" := 0;

        OnAfterInitQtyToConsume(Rec, xRec, CurrFieldNo);
    end;

    procedure MaxQtyToConsume(): Decimal
    begin
        exit("Remaining Quantity");
    end;

    local procedure MaxQtyToConsumeBase(): Decimal
    begin
        exit("Remaining Quantity (Base)");
    end;

    local procedure GetSKU()
    var
        SKU: Record "Stockkeeping Unit";
        Result: Boolean;
    begin
        if Type = Type::Item then
            if (StockkeepingUnit."Location Code" = "Location Code") and
               (StockkeepingUnit."Item No." = "No.") and
               (StockkeepingUnit."Variant Code" = "Variant Code")
            then
                exit;
        GetItemResource();
        StockkeepingUnit := Item.GetSKU("Location Code", "Variant Code");
        Result := SKU.Get("Location Code", "No.", "Variant Code");
        OnAfterGetSKU(Rec, Result);
    end;

    procedure GetUnitCost(): Decimal
    var
        UnitCost: Decimal;
    begin
        GetItemResource();

        case Type of
            Type::Item:
                begin
                    GetSKU();
                    UnitCost := StockkeepingUnit."Unit Cost" * "Qty. per Unit of Measure";
                end;
            Type::Resource:
                UnitCost := Resource."Unit Cost" * "Qty. per Unit of Measure";
        end;

        OnAfterGetUnitCost(Rec, UnitCost);

        exit(RoundUnitAmount(UnitCost));
    end;

    procedure CalcCostAmount(Qty: Decimal; UnitCost: Decimal): Decimal
    begin
        exit(Round(Qty * UnitCost));
    end;

    local procedure RoundUnitAmount(UnitAmount: Decimal): Decimal
    begin
        GetGLSetup();

        exit(Round(UnitAmount, GLSetup."Unit-Amount Rounding Precision"));
    end;

    procedure ShowReservation()
    var
        Reservation: Page Reservation;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowReservation(Rec, IsHandled);
        if IsHandled then
            exit;

        if Type = Type::Item then begin
            TestField("No.");
            TestField(Reserve);
            Clear(Reservation);
            Reservation.SetReservSource(Rec);
            Reservation.RunModal();
        end;
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if Type = Type::Item then begin
            TestField("No.");
            ReservEntry.InitSortingAndFilters(true);
            SetReservationFilters(ReservEntry);
            if Modal then
                PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
            else
                PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
        end;
    end;

    procedure UpdateAvailWarning() Result: Boolean
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAvailWarning(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        "Avail. Warning" := false;
        if Type = Type::Item then
            "Avail. Warning" := ItemCheckAvail.AsmOrderLineShowWarning(Rec);
        exit("Avail. Warning");
    end;

    procedure CheckItemAvailable(CalledByFieldNo: Integer)
    var
        AssemblySetup: Record "Assembly Setup";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemAvailable(Rec, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        if not UpdateAvailWarning() then
            exit;

        if "Document Type" <> "Document Type"::Order then
            exit;

        AssemblySetup.Get();
        if not AssemblySetup."Stockout Warning" then
            exit;

        if (CalledByFieldNo = CurrFieldNo) or
           ((CalledByFieldNo = FieldNo("No.")) and (CurrFieldNo <> 0)) or
           ((CalledByFieldNo = FieldNo(Quantity)) and (CurrFieldNo = FieldNo("Quantity per")))
        then
            if ItemCheckAvail.AssemblyLineCheck(Rec) then
                ItemCheckAvail.RaiseUpdateInterruptedError();
    end;

    [Scope('OnPrem')]
    procedure ShowAvailabilityWarning()
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        TestField(Type, Type::Item);

        if "Due Date" = 0D then begin
            GetHeader();
            if AssemblyHeader."Due Date" <> 0D then
                Validate("Due Date", AssemblyHeader."Due Date")
            else
                Validate("Due Date", WorkDate());
        end;

        ItemCheckAvail.AssemblyLineCheck(Rec);
    end;

    procedure ShowAvailabilityWarningPage()
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        ItemAvailabilityCheck: Page "Item Availability Check";
        ItemNo: Code[20];
        UnitOfMeasureCode: Code[10];
        InventoryQty: Decimal;
        GrossReq: Decimal;
        ReservedReq: Decimal;
        SchedRcpt: Decimal;
        ReservedRcpt: Decimal;
        CurrentQuantity: Decimal;
        CurrentReservedQty: Decimal;
        TotalQuantity: Decimal;
        EarliestAvailDate: Date;
    begin
        TestField(Type, Type::Item);

        if "Due Date" = 0D then begin
            GetHeader();
            if AssemblyHeader."Due Date" <> 0D then
                Validate("Due Date", AssemblyHeader."Due Date")
            else
                Validate("Due Date", WorkDate());
        end;

        if not ItemCheckAvail.AsmOrderLineShowWarning(Rec) then
            exit;

        ItemCheckAvail.FetchCalculation(
          ItemNo, UnitOfMeasureCode, InventoryQty,
          GrossReq, ReservedReq, SchedRcpt, ReservedRcpt,
          CurrentQuantity, CurrentReservedQty, TotalQuantity, EarliestAvailDate);

        ItemAvailabilityCheck.InitializeFromData(ItemNo, UnitOfMeasureCode, InventoryQty,
          GrossReq, ReservedReq, SchedRcpt, ReservedRcpt, CurrentQuantity, CurrentReservedQty, TotalQuantity,
          EarliestAvailDate, "Location Code");
        ItemAvailabilityCheck.SetHeading(StrSubstNo(AvailabilityPageTitleLbl, ItemNo));
        ItemAvailabilityCheck.RunModal();
    end;

    procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        exit(UOMMgt.CalcBaseQty(
            "No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    local procedure CalcQtyFromBase(QtyBase: Decimal): Decimal
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        exit(
          UOMMgt.CalcQtyFromBase(
            "No.", "Variant Code", "Unit of Measure Code", QtyBase, "Qty. per Unit of Measure"));
    end;

    procedure IsInbound(): Boolean
    begin
        if "Document Type" in ["Document Type"::Order, "Document Type"::Quote, "Document Type"::"Blanket Order"] then
            exit("Quantity (Base)" < 0);

        exit(false);
    end;

    procedure OpenItemTrackingLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenItemTrackingLines(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::Item);
        TestField("No.");
        TestField("Quantity (Base)");
        AssemblyLineReserve.CallItemTracking(Rec);
    end;

    local procedure GetItemResource()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItemResource(Rec, Item, Resource, IsHandled);
        if IsHandled then
            exit;

        if Type = Type::Item then
            if Item."No." <> "No." then
                Item.Get("No.");
        if Type = Type::Resource then
            if Resource."No." <> "No." then
                Resource.Get("No.");
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true
        end
    end;

    local procedure GetLocation(var Location: Record Location; LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure AutoReserve()
    var
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutoReserve(Rec, IsHandled);
        if Ishandled then
            exit;

        if Type <> Type::Item then
            exit;

        TestField("No.");
        if Reserve <> Reserve::Always then
            exit;

        if "Remaining Quantity (Base)" <> 0 then begin
            TestField("Due Date");
            ReservMgt.SetReservSource(Rec);
            ReservMgt.AutoReserve(FullAutoReservation, '', "Due Date", "Remaining Quantity", "Remaining Quantity (Base)");
            Find();
            if not FullAutoReservation and (CurrFieldNo <> 0) then
                if Confirm(Text001, true) then begin
                    Commit();
                    Rec.ShowReservation();
                    Find();
                end;
        end;
    end;

    procedure ReservationStatus(): Integer
    var
        Status: Option " ",Partial,Complete;
    begin
        if (Reserve = Reserve::Never) or ("Remaining Quantity" = 0) then
            exit(Status::" ");

        CalcFields("Reserved Quantity");
        if "Reserved Quantity" = 0 then begin
            if Reserve = Reserve::Always then
                exit(Status::Partial);
            exit(Status::" ");
        end;

        if "Reserved Quantity" < "Remaining Quantity" then
            exit(Status::Partial);

        exit(Status::Complete);
    end;

    procedure SetTestReservationDateConflict(NewTestReservationDateConflict: Boolean)
    begin
        TestReservationDateConflict := NewTestReservationDateConflict;
    end;

    procedure GetHeader(): Record "Assembly Header"
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetHeader(Rec, AssemblyHeader, IsHandled);
        if IsHandled then
            exit;

        if (AssemblyHeader."No." <> "Document No.") and ("Document No." <> '') then
            AssemblyHeader.Get(Rec."Document Type", Rec."Document No.");

        exit(AssemblyHeader)
    end;

    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        RemainingQty := "Remaining Quantity" - Abs("Reserved Quantity");
        RemainingQtyBase := "Remaining Quantity (Base)" - Abs("Reserved Qty. (Base)");
    end;

    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal): Decimal
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := "Reserved Quantity";
        QtyReservedBase := "Reserved Qty. (Base)";
        QtyToReserve := "Remaining Quantity";
        QtyToReserveBase := "Remaining Quantity (Base)";
        exit("Qty. per Unit of Measure");
    end;

    procedure GetSourceCaption(): Text[80]
    begin
        exit(StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"Assembly Line", "Document Type".AsInteger(), "Document No.", "Line No.", '', 0);
        ReservEntry.SetItemData("No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        if Type <> Type::Item then
            ReservEntry."Item No." := '';
        ReservEntry."Expected Receipt Date" := "Due Date";
        ReservEntry."Shipment Date" := "Due Date";
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Assembly Line", "Document Type".AsInteger(), "Document No.", "Line No.", false);
        ReservEntry.SetSourceFilter('', 0);

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        exit(not ReservEntry.IsEmpty);
    end;

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; HeaderDimensionSetID: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
        AssemblySetup: Record "Assembly Setup";
        DimMgt: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
        IsHandled: Boolean;
    begin
        if SkipVerificationsThatChangeDatabase then
            exit;

        IsHandled := false;
        OnBeforeCreateDim(Rec, CurrFieldNo, DefaultDimSource, HeaderDimensionSetID, IsHandled);
        if not IsHandled then begin
            SourceCodeSetup.Get();

            "Shortcut Dimension 1 Code" := '';
            "Shortcut Dimension 2 Code" := '';
            AssemblySetup.Get();
            case AssemblySetup."Copy Component Dimensions from" of
                AssemblySetup."Copy Component Dimensions from"::"Order Header":
                    begin
                        DimensionSetIDArr[1] :=
                          DimMgt.GetRecDefaultDimID(
                            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup.Assembly,
                            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code",
                            0, 0);
                        DimensionSetIDArr[2] := HeaderDimensionSetID;
                    end;
                AssemblySetup."Copy Component Dimensions from"::"Item/Resource Card":
                    begin
                        DimensionSetIDArr[2] :=
                          DimMgt.GetRecDefaultDimID(
                            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup.Assembly,
                            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code",
                            0, 0);
                        DimensionSetIDArr[1] := HeaderDimensionSetID;
                    end;
            end;

            "Dimension Set ID" :=
              DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;

        OnAfterCreateDim(Rec, DefaultDimSource, HeaderDimensionSetID);
    end;

    procedure UpdateDim(NewHeaderSetID: Integer; OldHeaderSetID: Integer)
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        "Dimension Set ID" := DimMgt.GetDeltaDimSetID("Dimension Set ID", NewHeaderSetID, OldHeaderSetID);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterUpdateDim(Rec);
    end;

    local procedure UpdateCombinedDimension(HeaderDimensionSetID: Integer)
    var
        AssemblySetup: Record "Assembly Setup";
        DimMgt: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
    begin
        AssemblySetup.Get();
        case AssemblySetup."Copy Component Dimensions from" of
            AssemblySetup."Copy Component Dimensions from"::"Order Header":
                begin
                    DimensionSetIDArr[1] := "Dimension Set ID";
                    DimensionSetIDArr[2] := HeaderDimensionSetID;
                end;
            AssemblySetup."Copy Component Dimensions from"::"Item/Resource Card":
                begin
                    DimensionSetIDArr[2] := "Dimension Set ID";
                    DimensionSetIDArr[1] := HeaderDimensionSetID;
                end;
        end;

        "Dimension Set ID" := DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowItemSub()
    begin
        ItemSubstMgt.ItemAssemblySubstGet(Rec);
    end;

    procedure ShowAssemblyList()
    var
        BomComponent: Record "BOM Component";
    begin
        TestField(Type, Type::Item);
        BomComponent.SetRange("Parent Item No.", "No.");
        PAGE.Run(PAGE::"Assembly BOM", BomComponent);
    end;

    procedure ExplodeAssemblyList()
    var
        AssemblyLineManagement: Codeunit "Assembly Line Management";
    begin
        AssemblyLineManagement.ExplodeAsmList(Rec);
    end;

    procedure CalcQuantityPer(Qty: Decimal): Decimal
    begin
        GetHeader();
        AssemblyHeader.TestField(Quantity);

        if FixedUsage() then
            exit(Qty);

        exit(Qty / AssemblyHeader.Quantity);
    end;

    procedure CalcBOMQuantity(LineType: Enum "BOM Component Type"; QtyPer: Decimal; HeaderQty: Decimal; HeaderQtyPerUOM: Decimal; LineResourceUsageType: Option): Decimal
    var
        UOMMgt: Codeunit "Unit of Measure Management";
        IsHandled: Boolean;
        ReturnBOMQuantity: Decimal;
    begin
        IsHandled := false;
        ReturnBOMQuantity := 0;
        OnBeforeCalcBOMQuantity(Rec, LineType, QtyPer, HeaderQty, HeaderQtyPerUOM, LineResourceUsageType, ReturnBOMQuantity, IsHandled);
        if IsHandled then
            exit(ReturnBOMQuantity);

        if FixedUsage(LineType, LineResourceUsageType) then
            exit(QtyPer);

        if QtyPer = 0 then
            exit(0);

        CheckingRoundingPrecision();

        if ("Qty. Rounding Precision" <> 0) then
            exit(UOMMgt.RoundToItemRndPrecision(QtyPer * HeaderQty * HeaderQtyPerUOM, "Qty. Rounding Precision"));
        exit(QtyPer * HeaderQty * HeaderQtyPerUOM);
    end;

    local procedure CalcQuantity(LineQtyPer: Decimal; HeaderQty: Decimal): Decimal
    begin
        exit(CalcBOMQuantity(Type, LineQtyPer, HeaderQty, 1, "Resource Usage Type"));
    end;

    procedure SetItemToPlanFilters(var Item: Record Item; DocumentType: Enum "Assembly Document Type")
    begin
        Reset();
        SetCurrentKey("Document Type", Type, "No.", "Variant Code", "Location Code");
        SetRange("Document Type", DocumentType);
        SetRange(Type, Type::Item);
        SetRange("No.", Item."No.");
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        SetFilter("Location Code", Item.GetFilter("Location Filter"));
        SetFilter("Due Date", Item.GetFilter("Date Filter"));
        SetFilter("Shortcut Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        SetFilter("Shortcut Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        SetFilter("Remaining Quantity (Base)", '<>0');
        SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));

        OnAfterFilterLinesWithItemToPlan(Rec, Item, DocumentType.AsInteger());
    end;

    procedure FindItemToPlanLines(var Item: Record Item; DocumentType: Enum "Assembly Document Type"): Boolean
    begin
        SetItemToPlanFilters(Item, DocumentType);
        exit(Find('-'));
    end;

    procedure ItemToPlanLinesExist(var Item: Record Item; DocumentType: Enum "Assembly Document Type"): Boolean
    begin
        SetItemToPlanFilters(Item, DocumentType);
        exit(not IsEmpty);
    end;

    procedure FilterLinesForReservation(ReservationEntry: Record "Reservation Entry"; DocumentType: Option; AvailabilityFilter: Text; Positive: Boolean)
    begin
        Reset();
        SetCurrentKey(
          "Document Type", Type, "No.", "Variant Code", "Location Code", "Due Date");
        SetRange("Document Type", DocumentType);
        SetRange(Type, Type::Item);
        SetRange("No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Location Code", ReservationEntry."Location Code");
        SetFilter("Due Date", AvailabilityFilter);
        if Positive then
            SetFilter("Remaining Quantity (Base)", '<0')
        else
            SetFilter("Remaining Quantity (Base)", '>0');

        OnAfterFilterLinesForReservation(Rec, ReservationEntry, DocumentType, AvailabilityFilter, Positive);
    end;

    local procedure SelectItemEntry(CurrentFieldNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        AsmLine3: Record "Assembly Line";
    begin
        ItemLedgEntry.SetRange("Item No.", "No.");
        ItemLedgEntry.SetRange("Location Code", "Location Code");
        ItemLedgEntry.SetRange("Variant Code", "Variant Code");

        if CurrentFieldNo = FieldNo("Appl.-to Item Entry") then begin
            ItemLedgEntry.SetCurrentKey("Item No.", Open);
            ItemLedgEntry.SetRange(Positive, true);
            ItemLedgEntry.SetRange(Open, true);
        end else begin
            ItemLedgEntry.SetCurrentKey("Item No.", Positive);
            ItemLedgEntry.SetRange(Positive, false);
            ItemLedgEntry.SetFilter("Shipped Qty. Not Returned", '<0');
        end;
        if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then begin
            AsmLine3 := Rec;
            if CurrentFieldNo = FieldNo("Appl.-to Item Entry") then
                AsmLine3.Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No.")
            else
                AsmLine3.Validate("Appl.-from Item Entry", ItemLedgEntry."Entry No.");
            Rec := AsmLine3;
        end;
    end;

    procedure SetItemFilter(var Item: Record Item)
    begin
        if Type = Type::Item then begin
            Item.Get("No.");
            if "Due Date" = 0D then
                "Due Date" := WorkDate();
            Item.SetRange("Date Filter", 0D, "Due Date");
            Item.SetRange("Location Filter", "Location Code");
            Item.SetRange("Variant Filter", "Variant Code");
        end;
    end;

    local procedure CalcAvailQuantities(var Item: Record Item; var GrossRequirement: Decimal; var ScheduledReceipt: Decimal; var ExpectedInventory: Decimal; var AvailableInventory: Decimal; var EarliestDate: Date)
    var
        OldAssemblyLine: Record "Assembly Line";
        CompanyInfo: Record "Company Information";
        AvailableToPromise: Codeunit "Available to Promise";
        LookaheadDateFormula: DateFormula;
        AvailabilityDate: Date;
        ReservedReceipt: Decimal;
        ReservedRequirement: Decimal;
        QtyAvailable: Decimal;
        PeriodType: Enum "Analysis Period Type";
    begin
        OnBeforeCalcAvailQuantities(Rec);
        SetItemFilter(Item);
        CalcAvailBaseQuantities(Item, AvailableInventory, ScheduledReceipt, ReservedReceipt, ReservedRequirement, GrossRequirement);

        if OrderLineExists(OldAssemblyLine) then
            if OldAssemblyLine."Due Date" > "Due Date" then
                AvailableToPromise.SetChangedAsmLine(OldAssemblyLine)
            else
                GrossRequirement -= OldAssemblyLine."Remaining Quantity (Base)";

        CompanyInfo.Get();
        LookaheadDateFormula := CompanyInfo."Check-Avail. Period Calc.";
        if Format(LookaheadDateFormula) <> '' then begin
            AvailabilityDate := Item.GetRangeMax("Date Filter");
            PeriodType := CompanyInfo."Check-Avail. Time Bucket";

            GrossRequirement :=
              GrossRequirement +
              AvailableToPromise.CalculateForward(
                Item, PeriodType,
                AvailabilityDate + 1,
                AvailableToPromise.GetPeriodEndingDate(CalcDate(LookaheadDateFormula, AvailabilityDate), PeriodType));
        end;

        EarliestDate :=
          AvailableToPromise.CalcEarliestAvailabilityDate(
            Item, "Remaining Quantity (Base)", "Due Date",
            OldAssemblyLine."Remaining Quantity (Base)", OldAssemblyLine."Due Date",
            QtyAvailable,
            CompanyInfo."Check-Avail. Time Bucket", CompanyInfo."Check-Avail. Period Calc.");

        ExpectedInventory :=
          CalcExpectedInventory(AvailableInventory, ScheduledReceipt - ReservedReceipt, GrossRequirement - ReservedRequirement);

        OnAfterCalcExpectedInventory(Rec, Item, ExpectedInventory, AvailableInventory, ScheduledReceipt, ReservedReceipt, GrossRequirement, ReservedRequirement);

        AvailableInventory := CalcQtyFromBase(AvailableInventory);
        GrossRequirement := CalcQtyFromBase(GrossRequirement);
        ScheduledReceipt := CalcQtyFromBase(ScheduledReceipt);
        ExpectedInventory := CalcQtyFromBase(ExpectedInventory);
    end;

    local procedure CalcAvailBaseQuantities(var Item: Record Item; var AvailableInventory: Decimal; var ScheduledReceipt: Decimal; var ReservedReceipt: Decimal; var ReservedRequirement: Decimal; var GrossRequirement: Decimal)
    var
        AvailableToPromise: Codeunit "Available to Promise";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAvailBaseQuantities(Rec, Item, AvailableInventory, ScheduledReceipt, ReservedReceipt, ReservedRequirement, GrossRequirement, IsHandled);
        if IsHandled then
            exit;

        AvailableInventory := AvailableToPromise.CalcAvailableInventory(Item);
        ScheduledReceipt := AvailableToPromise.CalcScheduledReceipt(Item);
        ReservedReceipt := AvailableToPromise.CalcReservedReceipt(Item);
        ReservedRequirement := AvailableToPromise.CalcReservedRequirement(Item);
        GrossRequirement := AvailableToPromise.CalcGrossRequirement(Item);
    end;

    local procedure CalcExpectedInventory(Inventory: Decimal; ScheduledReceipt: Decimal; GrossRequirement: Decimal): Decimal
    begin
        exit(Inventory + ScheduledReceipt - GrossRequirement);
    end;

    procedure CalcAvailToAssemble(AssemblyHeader: Record "Assembly Header"; var Item: Record Item; var GrossRequirement: Decimal; var ScheduledReceipt: Decimal; var ExpectedInventory: Decimal; var AvailableInventory: Decimal; var EarliestDate: Date; var AbleToAssemble: Decimal)
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        TestField("Quantity per");

        CalcAvailQuantities(
          Item,
          GrossRequirement,
          ScheduledReceipt,
          ExpectedInventory,
          AvailableInventory,
          EarliestDate);

        if ExpectedInventory < "Remaining Quantity (Base)" then begin
            if ExpectedInventory < 0 then begin
                AbleToAssemble := 0;
                if AvailableInventory >= "Remaining Quantity (Base)" then
                    AbleToAssemble := AssemblyHeader."Remaining Quantity";
            end else
                AbleToAssemble := Round(ExpectedInventory / "Quantity per", UOMMgt.QtyRndPrecision(), '<');

        end else begin
            AbleToAssemble := AssemblyHeader."Remaining Quantity";
            EarliestDate := 0D;
        end;
    end;

    local procedure MaxValue(Value: Decimal; Value2: Decimal): Decimal
    begin
        if Value < Value2 then
            exit(Value2);

        exit(Value);
    end;

    local procedure MinValue(Value: Decimal; Value2: Decimal): Decimal
    begin
        if Value < Value2 then
            exit(Value);

        exit(Value2);
    end;

    procedure RoundQty(var Qty: Decimal)
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        Qty := UOMMgt.RoundQty(Qty, "Qty. Rounding Precision");
    end;

    procedure FixedUsage(): Boolean
    begin
        exit(FixedUsage(Type, "Resource Usage Type"));
    end;

    local procedure FixedUsage(LineType: Enum "BOM Component Type"; LineResourceUsageType: Option): Boolean
    begin
        if (LineType = Type::Resource) and (LineResourceUsageType = "Resource Usage Type"::Fixed) then
            exit(true);

        exit(false);
    end;

    local procedure InitResourceUsageType()
    begin
        case Type of
            Type::" ", Type::Item:
                "Resource Usage Type" := "Resource Usage Type"::" ";
            Type::Resource:
                "Resource Usage Type" := "Resource Usage Type"::Direct;
        end;
    end;

    procedure SignedXX(Value: Decimal): Decimal
    begin
        case "Document Type" of
            "Document Type"::Quote,
            "Document Type"::Order,
            "Document Type"::"Blanket Order":
                exit(-Value);
        end;
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(ItemTrackingMgt.ComposeRowID(DATABASE::"Assembly Line", "Document Type".AsInteger(), "Document No.", '', 0, "Line No."));
    end;

    local procedure CheckBin()
    var
        BinContent: Record "Bin Content";
        Bin: Record Bin;
        Location: Record Location;
    begin
        if "Bin Code" <> '' then begin
            GetLocation(Location, "Location Code");
            if not Location."Check Whse. Class" then
                exit;

            if BinContent.Get(
                 "Location Code", "Bin Code",
                 "No.", "Variant Code", "Unit of Measure Code")
            then
                BinContent.CheckWhseClass(false)
            else begin
                Bin.Get("Location Code", "Bin Code");
                Bin.CheckWhseClass("No.", false);
            end;
        end;
    end;

    procedure GetDefaultBin()
    begin
        if (Type <> Type::Item) or not IsInventoriableItem() then
            exit;
        if (Quantity * xRec.Quantity > 0) and
           ("No." = xRec."No.") and
           ("Location Code" = xRec."Location Code") and
           ("Variant Code" = xRec."Variant Code")
        then
            exit;
        Validate("Bin Code", FindBin());
    end;

    procedure FindBin() NewBinCode: Code[20]
    var
        Location: Record Location;
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindBin(Rec, NewBinCode, IsHandled);
        if IsHandled then
            exit(NewBinCode);

        if ("Location Code" <> '') and ("No." <> '') then begin
            GetLocation(Location, "Location Code");
            NewBinCode := Location."To-Assembly Bin Code";
            if NewBinCode <> '' then
                exit;

            if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", NewBinCode);
        end;

        OnAfterFindBin(Rec, NewBinCode);
    end;

    procedure TestStatusOpen()
    begin
        if StatusCheckSuspended then
            exit;

        Clear(AssemblyHeader);
        GetHeader();
        if Type in [Type::Item, Type::Resource] then
            AssemblyHeader.TestField(Status, AssemblyHeader.Status::Open);
    end;

    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    procedure CompletelyPicked(): Boolean
    var
        Location: Record Location;
    begin
        TestField(Type, Type::Item);
        GetLocation(Location, "Location Code");
        if Location."Require Shipment" then
            exit("Qty. Picked (Base)" - "Consumed Quantity (Base)" >= "Remaining Quantity (Base)");
        exit("Qty. Picked (Base)" - "Consumed Quantity (Base)" >= "Quantity to Consume (Base)");
    end;

    procedure CalcQtyToPick(): Decimal
    var
        QtyToPick: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyToPick(Rec, QtyToPick, IsHandled);
        if IsHandled then
            exit(QtyToPick);

        CalcFields("Pick Qty.");
        exit(Quantity - "Qty. Picked" - "Pick Qty.");
    end;

    procedure CalcQtyToPickBase(): Decimal
    var
        QtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyToPickBase(Rec, QtyToPickBase, IsHandled);
        if IsHandled then
            exit(QtyToPickBase);

        CalcFields("Pick Qty. (Base)");
        exit("Quantity (Base)" - "Qty. Picked (Base)" - "Pick Qty. (Base)");
    end;

    procedure CalcQtyPickedNotConsumed(): Decimal
    begin
        exit("Qty. Picked" - "Consumed Quantity");
    end;

    procedure CalcQtyPickedNotConsumedBase(): Decimal
    begin
        exit("Qty. Picked (Base)" - "Consumed Quantity (Base)");
    end;

    procedure ItemExists(ItemNo: Code[20]): Boolean
    var
        Item2: Record Item;
    begin
        if Type <> Type::Item then
            exit(false);

        if not Item2.Get(ItemNo) then
            exit(false);
        exit(true);
    end;

    procedure ShowTracking()
    var
        OrderTracking: Page "Order Tracking";
    begin
        OrderTracking.SetVariantRec(Rec, Rec."No.", Rec."Remaining Quantity (Base)", Rec."Due Date", Rec."Due Date");
        OrderTracking.RunModal();
    end;

    local procedure OrderLineExists(var AssemblyLine: Record "Assembly Line"): Boolean
    begin
        exit(
          ("Document Type" = "Document Type"::Order) and
          AssemblyLine.Get("Document Type", "Document No.", "Line No.") and
          (AssemblyLine.Type = Type) and
          (AssemblyLine."No." = "No.") and
          (AssemblyLine."Location Code" = "Location Code") and
          (AssemblyLine."Variant Code" = "Variant Code") and
          (AssemblyLine."Bin Code" = "Bin Code"));
    end;

    procedure VerifyReservationQuantity(var NewAsmLine: Record "Assembly Line"; var OldAsmLine: Record "Assembly Line")
    begin
        if SkipVerificationsThatChangeDatabase then
            exit;
        AssemblyLineReserve.VerifyQuantity(NewAsmLine, OldAsmLine);
    end;

    procedure VerifyReservationChange(var NewAsmLine: Record "Assembly Line"; var OldAsmLine: Record "Assembly Line")
    begin
        if SkipVerificationsThatChangeDatabase then
            exit;
        AssemblyLineReserve.VerifyChange(NewAsmLine, OldAsmLine);
    end;

    procedure VerifyReservationDateConflict(NewAsmLine: Record "Assembly Line")
    var
        AsmReservCheckDateConfl: Codeunit "Asm. ReservCheckDateConfl";
    begin
        if SkipVerificationsThatChangeDatabase then
            exit;
        AsmReservCheckDateConfl.AssemblyLineCheck(NewAsmLine, (CurrFieldNo <> 0) or TestReservationDateConflict);
    end;

    procedure SetSkipVerificationsThatChangeDatabase(State: Boolean)
    begin
        SkipVerificationsThatChangeDatabase := State;
    end;

    procedure GetSkipVerificationsThatChangeDatabase(): Boolean
    begin
        exit(SkipVerificationsThatChangeDatabase);
    end;

    procedure ValidateDueDate(AsmHeader: Record "Assembly Header"; NewDueDate: Date; ShowDueDateBeforeWorkDateMsg: Boolean)
    var
        MaxDate: Date;
    begin
        OnBeforeValidateDueDate(Rec, AsmHeader, NewDueDate, ShowDueDateBeforeWorkDateMsg);

        "Due Date" := NewDueDate;
        TestStatusOpen();

        MaxDate := LatestPossibleDueDate(AsmHeader."Starting Date");
        if "Due Date" > MaxDate then
            Error(Text049, FieldCaption("Due Date"), MaxDate, AsmHeader.FieldCaption("Starting Date"), AsmHeader."Starting Date");

        if (xRec."Due Date" <> "Due Date") and (Quantity <> 0) then
            VerifyReservationDateConflict(Rec);

        CheckItemAvailable(FieldNo("Due Date"));
        AssemblyWarehouseMgt.AssemblyLineVerifyChange(Rec, xRec);

        if ("Due Date" < WorkDate()) and ShowDueDateBeforeWorkDateMsg then
            Message(Text050, "Due Date", WorkDate());
    end;

    procedure ValidateLeadTimeOffset(AsmHeader: Record "Assembly Header"; NewLeadTimeOffset: DateFormula; ShowDueDateBeforeWorkDateMsg: Boolean)
    var
        ZeroDF: DateFormula;
    begin
        "Lead-Time Offset" := NewLeadTimeOffset;
        TestStatusOpen();

        if Type <> Type::Item then
            TestField("Lead-Time Offset", ZeroDF);
        ValidateDueDate(AsmHeader, LatestPossibleDueDate(AsmHeader."Starting Date"), ShowDueDateBeforeWorkDateMsg);
    end;

    local procedure LatestPossibleDueDate(HeaderStartingDate: Date): Date
    begin
        exit(HeaderStartingDate - (CalcDate("Lead-Time Offset", WorkDate()) - WorkDate()));
    end;

    procedure TestItemFields(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        TestField(Type, Type::Item);
        TestField("No.", ItemNo);
        TestField("Variant Code", VariantCode);
        TestField("Location Code", LocationCode);
    end;

    local procedure CopyFromItem()
    begin
        OnBeforeCopyFromItem(Rec);

        GetItemResource();
        if IsInventoriableItem() then begin
            "Location Code" := AssemblyHeader."Location Code";
            Item.TestField("Inventory Posting Group");
        end;

        Item.TestField(Blocked, false);
        "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        "Inventory Posting Group" := Item."Inventory Posting Group";
        GetDefaultBin();
        Description := Item.Description;
        "Description 2" := Item."Description 2";
        "Unit Cost" := GetUnitCost();
        Validate("Unit of Measure Code", Item."Base Unit of Measure");
        CreateDimFromDefaultDim(AssemblyHeader."Dimension Set ID");
        Reserve := Item.Reserve;
        Validate(Quantity);
        Validate("Quantity to Consume",
          MinValue(MaxQtyToConsume(), CalcQuantity("Quantity per", AssemblyHeader."Quantity to Assemble")));

        OnAfterCopyFromItem(Rec, Item, AssemblyHeader);
    end;

    local procedure CopyFromResource()
    begin
        OnBeforeCopyFromResource(Rec);

        GetItemResource();
        Resource.TestField("Gen. Prod. Posting Group");
        "Gen. Prod. Posting Group" := Resource."Gen. Prod. Posting Group";
        "Inventory Posting Group" := '';
        Description := Resource.Name;
        "Description 2" := Resource."Name 2";
        "Unit Cost" := GetUnitCost();
        Validate("Unit of Measure Code", Resource."Base Unit of Measure");
        CreateDimFromDefaultDim(AssemblyHeader."Dimension Set ID");
        Validate(Quantity);
        Validate("Quantity to Consume",
          MinValue(MaxQtyToConsume(), CalcQuantity("Quantity per", AssemblyHeader."Quantity to Assemble")));

        OnAfterCopyFromResource(Rec, Resource, AssemblyHeader);
    end;

    procedure IsInventoriableItem(): Boolean
    begin
        if Type <> Type::Item then
            exit(false);
        if "No." = '' then
            exit(false);
        GetItemResource();
        exit(Item.IsInventoriableType());
    end;

    procedure CreateDimFromDefaultDim(HeaderDimensionSetID: Integer)
    var
        DimMgt: Codeunit DimensionManagement;
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource);
        if DimMgt.IsDefaultDimDefinedForTable(GetTableValuePair(CurrFieldNo)) then
            CreateDim(DefaultDimSource, HeaderDimensionSetID)
        else
            UpdateCombinedDimension(HeaderDimensionSetID);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.TypeToTableID4(Rec.Type.AsInteger()), Rec."No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code");

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource);
    end;

    local procedure GetTableValuePair(FieldNo: Integer) TableValuePair: Dictionary of [Integer, Code[20]]
    var
        DimMgt: Codeunit DimensionManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitTableValuePair(TableValuePair, FieldNo, IsHandled, Rec);
        if IsHandled then
            exit;

        case true of
            FieldNo = Rec.FieldNo("No."):
                TableValuePair.Add(DimMgt.TypeToTableID4(Rec.Type.AsInteger()), Rec."No.");
            FieldNo = Rec.FieldNo("Location Code"):
                TableValuePair.Add(Database::Location, Rec."Location Code");
        end;
        OnAfterInitTableValuePair(TableValuePair, FieldNo, Rec);
    end;

    procedure SetAssemblyHeader(NewAssemblyHeader: Record "Assembly Header")
    begin
        AssemblyHeader := NewAssemblyHeader;
    end;

    procedure CheckIfAssemblyLineMeetsReservedFromStockSetting(QtyToPost: Decimal; ReservedFromStock: Enum "Reservation From Stock") Result: Boolean
    var
        QtyReservedFromStock: Decimal;
    begin
        Result := true;

        if not Rec.IsInventoriableItem() then
            exit(true);

        if ReservedFromStock = ReservedFromStock::" " then
            exit(true);

        QtyReservedFromStock := AssemblyLineReserve.GetReservedQtyFromInventory(Rec);

        case ReservedFromStock of
            ReservedFromStock::Full:
                if QtyToPost <> QtyReservedFromStock then
                    Result := false;
            ReservedFromStock::"Full and Partial":
                if QtyReservedFromStock = 0 then
                    Result := false;
            else
                OnCheckIfAssemblyLineMeetsReservedFromStockSetting(QtyToPost, ReservedFromStock, Result);
        end;

        exit(Result);
    end;

    local procedure ConfirmDeletion()
    var
        Location: Record Location;
    begin
        if CalledFromHeader then
            exit;

        if "Consumed Quantity" < "Qty. Picked" then begin
            if "Location Code" <> '' then begin
                GetLocation(Location, "Location Code");
                if Location."Asm. Consump. Whse. Handling" = Location."Asm. Consump. Whse. Handling"::"No Warehouse Handling" then
                    exit;
            end;

            if not Confirm(
                StrSubstNo(
                    ConfirmDeleteQst,
                    FieldCaption("Qty. Picked"),
                    "Qty. Picked",
                    FieldCaption("Consumed Quantity"),
                    "Consumed Quantity",
                    TableCaption),
                false)
            then
                Error('');
        end;
    end;

    local procedure SetQtyPerUoMAndQtyRoundingPrecision()
    var
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetQtyPerUoMAndQtyRoundingPrecision(Rec, IsHandled);
        if IsHandled then
            exit;

        case Type of
            Type::Item:
                begin
                    "Qty. per Unit of Measure" := UnitOfMeasureManagement.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                    "Qty. Rounding Precision" := UnitOfMeasureManagement.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                    "Qty. Rounding Precision (Base)" := UnitOfMeasureManagement.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");
                end;
            Type::Resource:
                "Qty. per Unit of Measure" := UnitOfMeasureManagement.GetResQtyPerUnitOfMeasure(Resource, "Unit of Measure Code");
            else
                "Qty. per Unit of Measure" := 1;
        end;
    end;

    internal procedure ShowAssemblyDocument()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Get(Rec."Document Type", Rec."Document No.");
        case AssemblyHeader."Document Type" of
            AssemblyHeader."Document Type"::Quote:
                Page.Run(Page::"Assembly Quote", AssemblyHeader);
            AssemblyHeader."Document Type"::Order:
                Page.Run(Page::"Assembly Order", AssemblyHeader);
            AssemblyHeader."Document Type"::"Blanket Order":
                Page.Run(Page::"Blanket Assembly Order", AssemblyHeader);
        end;
    end;

    procedure SuspendDeletionCheck(Suspend: Boolean)
    begin
        CalledFromHeader := Suspend;
    end;

    procedure GetSuspendDeletionCheck(): Boolean
    begin
        exit(CalledFromHeader);
    end;

    local procedure CheckingRoundingPrecision()
    var
        Item2: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        UOMQtyRoundPrecision: Decimal;
    begin
        if (Rec.Type <> Rec.Type::Item) or (Rec."No." = '') then
            exit;

        if not Item2.Get(Rec."No.") or (Rec."Unit of Measure Code" = '') then
            exit;

        UOMQtyRoundPrecision := UOMMgt.GetQtyRoundingPrecision(Item2, Rec."Unit of Measure Code");

        if (Item2."Rounding Precision" = 0) or (UOMQtyRoundPrecision = 0) then
            exit;

        if Item2."Base Unit of Measure" <> Rec."Unit of Measure Code" then begin
            Rec."Qty. Rounding Precision" := UOMQtyRoundPrecision;
            Rec."Qty. Rounding Precision (Base)" := Item2."Rounding Precision";
            exit;
        end;

        Rec."Qty. Rounding Precision" := Item2."Rounding Precision";
        Rec."Qty. Rounding Precision (Base)" := Item2."Rounding Precision";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var AssemblyLine: Record "Assembly Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcExpectedInventory(var AssemblyLine: Record "Assembly Line"; var Item: Record Item; var ExpectedInventory: Decimal; AvailableInventory: Decimal; ScheduledReceipt: Decimal; ReservedReceipt: Decimal; GrossRequirement: Decimal; ReservedRequirement: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromItem(var AssemblyLine: Record "Assembly Line"; Item: Record Item; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromResource(var AssemblyLine: Record "Assembly Line"; Resource: Record Resource; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var AssemblyLine: Record "Assembly Line"; Item: Record Item; DocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var AssemblyLine: Record "Assembly Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; HeaderDimensionSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesForReservation(var AssemblyLine: Record "Assembly Line"; ReservEntry: Record "Reservation Entry"; DocumentType: Option; AvailabilityFilter: Text; Positive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSKU(AssemblyLine: Record "Assembly Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetUnitCost(var AssemblyLine: Record "Assembly Line"; var UnitCost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRemainingQty(var AssemblyLine: Record "Assembly Line"; xAssemblyLine: Record "Assembly Line"; CurrentFieldNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToConsume(var AssemblyLine: Record "Assembly Line"; xAssemblyLine: Record "Assembly Line"; CurrentFieldNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; AssemblyLine: Record "Assembly Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDim(var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var AssemblyLine: Record "Assembly Line"; var xAssemblyLine: Record "Assembly Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserve(var AssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyToPick(var AssemblyLine: Record "Assembly Line"; var QtyToPick: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyToPickBase(var AssemblyLine: Record "Assembly Line"; var QtyToPickBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetHeader(var AssemblyLine: Record "Assembly Line"; var AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemResource(AssemblyLine: Record "Assembly Line"; var Item: Record Item; var Resource: Record Resource; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindBin(var AssemblyLine: Record "Assembly Line"; var NewBinCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToConsume(var AssemblyLine: Record "Assembly Line"; xAssemblyLine: Record "Assembly Line"; CurrentFieldNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenItemTrackingLines(var AssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var AssemblyLine: Record "Assembly Line"; var xAssemblyLine: Record "Assembly Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityBase(var AssemblyLine: Record "Assembly Line"; var xAssemblyLine: Record "Assembly Line"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityPer(var AssemblyLine: Record "Assembly Line"; xAssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailable(var AssemblyLine: Record "Assembly Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAvailQuantities(var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAvailBaseQuantities(var AssemblyLine: Record "Assembly Line"; var Item: Record Item; var AvailableInventory: Decimal; var ScheduledReceipt: Decimal; var ReservedReceipt: Decimal; var ReservedRequirement: Decimal; var GrossRequirement: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromItem(var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromResource(var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReservation(var AssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAvailWarning(var AssemblyLine: Record "Assembly Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDueDate(var AsmLine: Record "Assembly Line"; AsmHeader: Record "Assembly Header"; NewDueDate: Date; var ShowDueDateBeforeWorkDateMsg: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterCalcBaseQty(var AssemblyLine: Record "Assembly Line"; xAssemblyLine: Record "Assembly Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityPerOnAfterRoundQty(var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateApplToItemEntryOnBeforeShowNotOpenItemLedgerEntryMessage(var AssemblyLine: Record "Assembly Line"; xAssemblyLine: Record "Assembly Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantitytoConsume(var AssemblyLine: Record "Assembly Line"; xAssemblyLine: Record "Assembly Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitTableValuePair(var TableValuePair: Dictionary of [Integer, Code[20]]; FieldNo: Integer; var IsHandled: Boolean; var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitTableValuePair(var TableValuePair: Dictionary of [Integer, Code[20]]; FieldNo: Integer; var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindBin(var AssemblyLine: Record "Assembly Line"; var NewBinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBOMQuantity(var AssemblyLine: Record "Assembly Line"; LineType: Enum "BOM Component Type"; QtyPer: Decimal; HeaderQty: Decimal; HeaderQtyPerUOM: Decimal; LineResourceUsageType: Option; var ReturnBOMQuantity: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var AssemblyLine: Record "Assembly Line"; CallingFieldNo: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; HeaderDimensionSetID: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIfAssemblyLineMeetsReservedFromStockSetting(QtyToPost: Decimal; ReservedFromStock: Enum "Reservation From Stock"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetQtyPerUoMAndQtyRoundingPrecision(var AssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;
}
