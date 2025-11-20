// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Structure;
using System.Security.User;

table 753 "Standard Item Journal Line"
{
    Caption = 'Standard Item Journal Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
            TableRelation = "Item Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
            NotBlank = true;
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item where(Blocked = const(false));

            trigger OnLookup()
            begin
                if "Entry Type" <> "Entry Type"::Output then
                    if Item.Get("Item No.") or Item.Get(xRec."Item No.") then;
                Item.SetRange(Blocked, false);
                if PAGE.RunModal(PAGE::"Item List", Item) = ACTION::LookupOK then
                    Validate("Item No.", Item."No.");
                Item.SetRange(Blocked);
            end;

            trigger OnValidate()
            var
                PriceType: Enum "Price Type";
            begin
                if "Item No." <> xRec."Item No." then begin
                    "Variant Code" := '';
                    "Bin Code" := '';
                    if ("Location Code" <> '') and ("Item No." <> '') then begin
                        GetLocation("Location Code");
                        if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code")
                    end;
                end;

                if "Item No." = '' then begin
                    CreateDimFromDefaultDim(Rec.FieldNo("Item No."));
                    exit;
                end;

                GetItem();
                Item.TestField(Blocked, false);
                Description := Item.Description;
                "Inventory Posting Group" := Item."Inventory Posting Group";
                "Item Category Code" := Item."Item Category Code";
                OnValidateItemNoOnAfterCopyItemValues(Rec, Item);

                if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
                   ("Item Charge No." <> '')
                then begin
                    if "Item No." <> xRec."Item No." then begin
                        RetrieveCosts();
                        "Indirect Cost %" := 0;
                        "Overhead Rate" := 0;
                    end;
                end else begin
                    "Indirect Cost %" := Item."Indirect Cost %";
                    "Overhead Rate" := Item."Overhead Rate";
                    if not "Phys. Inventory" then begin
                        RetrieveCosts();
                        "Unit Cost" := UnitCost;
                    end else
                        UnitCost := "Unit Cost";
                end;

                if "Entry Type" <> "Entry Type"::Output then
                    "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";

                case "Entry Type" of
                    "Entry Type"::Purchase,
                    "Entry Type"::Output:
                        ApplyPrice(PriceType::Purchase, FieldNo("Item No."));
                    "Entry Type"::"Positive Adjmt.",
                    "Entry Type"::"Negative Adjmt.",
                    "Entry Type"::Consumption:
                        "Unit Amount" := UnitCost;
                    "Entry Type"::Sale:
                        ApplyPrice(PriceType::Sale, FieldNo("Item No."));
                    "Entry Type"::Transfer:
                        begin
                            "Unit Amount" := 0;
                            "Unit Cost" := 0;
                            Amount := 0;
                        end;
                end;

                case "Entry Type" of
                    "Entry Type"::Purchase:
                        "Unit of Measure Code" := Item."Purch. Unit of Measure";
                    "Entry Type"::Sale:
                        "Unit of Measure Code" := Item."Sales Unit of Measure";
                    else
                        "Unit of Measure Code" := Item."Base Unit of Measure";
                end;

                Validate("Unit of Measure Code");
                if "Variant Code" <> '' then
                    Validate("Variant Code");
                if "Bin Code" <> '' then
                    Validate("Bin Code");

                CreateDimFromDefaultDim(Rec.FieldNo("Item No."));
            end;
        }
        field(5; "Entry Type"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Entry Type';

            trigger OnValidate()
            begin
                if not ("Entry Type" in ["Entry Type"::"Positive Adjmt.", "Entry Type"::"Negative Adjmt."]) then
                    TestField("Phys. Inventory", false);

                case "Entry Type" of
                    "Entry Type"::Purchase:
                        "Location Code" := UserMgt.GetLocation(1, '', UserMgt.GetPurchasesFilter());
                    "Entry Type"::Sale:
                        "Location Code" := UserMgt.GetLocation(0, '', UserMgt.GetSalesFilter());
                end;

                if "Item No." <> '' then
                    Validate("Location Code");

                Validate("Item No.");
                SetDefaultPriceCalculationMethod();
            end;
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;

            trigger OnValidate()
            begin
                if "Location Code" <> xRec."Location Code" then begin
                    "Bin Code" := '';
                    if ("Location Code" <> '') and ("Item No." <> '') then begin
                        GetLocation("Location Code");
                        if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code");
                    end;
                end;

                Validate("Unit of Measure Code");
                CreateDimFromDefaultDim(Rec.FieldNo("Location Code"));
            end;
        }
        field(10; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            Editable = false;
            TableRelation = "Inventory Posting Group";
        }
        field(13; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));

                "Quantity (Base)" := UOMMgt.CalcBaseQty(
                    "Item No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure",
                    "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FieldCaption(Quantity),
                    FieldCaption("Quantity (Base)")
                );

                GetUnitAmount(FieldNo(Quantity));
                UpdateAmount();
            end;
        }
        field(16; "Unit Amount"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Amount';

            trigger OnValidate()
            begin
                UpdateAmount();
                if "Item No." <> '' then
                    if "Value Entry Type" = "Value Entry Type"::Revaluation then
                        "Unit Cost" := "Unit Amount"
                    else
                        case "Entry Type" of
                            "Entry Type"::Purchase,
                            "Entry Type"::"Positive Adjmt.":
                                begin
                                    if "Entry Type" = "Entry Type"::"Positive Adjmt." then begin
                                        GetItem();
                                        if (CurrFieldNo = FieldNo("Unit Amount")) and
                                           (Item."Costing Method" = Item."Costing Method"::Standard)
                                        then
                                            Error(
                                              Text002,
                                              FieldCaption("Unit Amount"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                                    end;

                                    ReadGLSetup();
                                    if "Entry Type" = "Entry Type"::Purchase then
                                        "Unit Cost" := "Unit Amount";
                                    if "Entry Type" = "Entry Type"::"Positive Adjmt." then
                                        "Unit Cost" :=
                                          Round("Unit Amount" * (1 + "Indirect Cost %" / 100), GLSetup."Unit-Amount Rounding Precision") +
                                          "Overhead Rate" * "Qty. per Unit of Measure";
                                    if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                                       ("Item Charge No." = '')
                                    then
                                        Validate("Unit Cost");
                                end;
                            "Entry Type"::"Negative Adjmt.",
                            "Entry Type"::Consumption:
                                begin
                                    GetItem();
                                    if (CurrFieldNo = FieldNo("Unit Amount")) and
                                       (Item."Costing Method" = Item."Costing Method"::Standard)
                                    then
                                        Error(
                                          Text002,
                                          FieldCaption("Unit Amount"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                                    "Unit Cost" := "Unit Amount";
                                    if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                                       ("Item Charge No." = '')
                                    then
                                        Validate("Unit Cost");
                                end;
                        end;
            end;
        }
        field(17; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';

            trigger OnValidate()
            begin
                TestField("Item No.");
                RetrieveCosts();
                if "Entry Type" in ["Entry Type"::Purchase, "Entry Type"::"Positive Adjmt.", "Entry Type"::Consumption] then
                    if Item."Costing Method" = Item."Costing Method"::Standard then begin
                        if CurrFieldNo = FieldNo("Unit Cost") then
                            Error(
                              Text002,
                              FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");

                        "Unit Cost" := Round(UnitCost * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                    end;

                if ("Item Charge No." = '') and
                   ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                   (CurrFieldNo = FieldNo("Unit Cost"))
                then begin
                    case "Entry Type" of
                        "Entry Type"::Purchase:
                            "Unit Amount" := "Unit Cost";
                        "Entry Type"::"Positive Adjmt.":
                            begin
                                ReadGLSetup();
                                "Unit Amount" :=
                                  Round(
                                    ("Unit Cost" - "Overhead Rate" * "Qty. per Unit of Measure") / (1 + "Indirect Cost %" / 100),
                                    GLSetup."Unit-Amount Rounding Precision")
                            end;
                        "Entry Type"::"Negative Adjmt.",
                        "Entry Type"::Consumption:
                            begin
                                if Item."Costing Method" = Item."Costing Method"::Standard then
                                    Error(
                                      Text002,
                                      FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                                "Unit Amount" := "Unit Cost";
                            end;
                    end;
                    UpdateAmount();
                end;
            end;
        }
        field(18; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                TestField(Quantity);
                "Unit Amount" := Amount / Quantity;
                Validate("Unit Amount");
                ReadGLSetup();
                "Unit Amount" := Round("Unit Amount", GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(23; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(Rec.FieldNo("Salespers./Purch. Code"));
            end;
        }
        field(26; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(34; "Shortcut Dimension 1 Code"; Code[20])
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
        field(35; "Shortcut Dimension 2 Code"; Code[20])
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
        field(37; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField("Item No.");
                TestField("Value Entry Type", "Value Entry Type"::"Direct Cost");
                TestField("Item Charge No.", '');
                if "Entry Type" in ["Entry Type"::Sale, "Entry Type"::"Negative Adjmt."] then
                    Error(
                      Text003,
                      "Entry Type", FieldCaption("Entry Type"), FieldCaption("Indirect Cost %"));

                GetItem();
                if Item."Costing Method" = Item."Costing Method"::Standard then
                    Error(
                      Text002,
                      FieldCaption("Indirect Cost %"), Item.FieldCaption("Costing Method"), Item."Costing Method");

                "Unit Cost" :=
                  Round(
                    "Unit Amount" * (1 + "Indirect Cost %" / 100) +
                    "Overhead Rate" * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(41; "Standard Journal Code"; Code[10])
        {
            Caption = 'Standard Journal Code';
            TableRelation = "Standard Item Journal".Code;
        }
        field(42; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(47; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(48; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(49; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(53; "Qty. (Calculated)"; Decimal)
        {
            Caption = 'Qty. (Calculated)';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                Validate("Qty. (Phys. Inventory)");
            end;
        }
        field(54; "Qty. (Phys. Inventory)"; Decimal)
        {
            Caption = 'Qty. (Phys. Inventory)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Phys. Inventory", true);

                PhysInvtEntered := true;
                Quantity := 0;
                if "Qty. (Phys. Inventory)" >= "Qty. (Calculated)" then begin
                    Validate("Entry Type", "Entry Type"::"Positive Adjmt.");
                    Validate(Quantity, "Qty. (Phys. Inventory)" - "Qty. (Calculated)");
                end else begin
                    Validate("Entry Type", "Entry Type"::"Negative Adjmt.");
                    Validate(Quantity, "Qty. (Calculated)" - "Qty. (Phys. Inventory)");
                end;
                PhysInvtEntered := false;
            end;
        }
        field(56; "Phys. Inventory"; Boolean)
        {
            Caption = 'Phys. Inventory';
            Editable = false;
        }
        field(57; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(58; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(59; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(63; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(64; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(65; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
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
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."), Blocked = const(false));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                if Rec."Variant Code" <> '' then begin
                    ItemVariant.SetLoadFields(Description, Blocked);
                    ItemVariant.Get("Item No.", "Variant Code");
                    ItemVariant.TestField(Blocked, false);
                end;

                if "Variant Code" <> xRec."Variant Code" then begin
                    "Bin Code" := '';
                    if ("Location Code" <> '') and ("Item No." <> '') then begin
                        GetLocation("Location Code");
                        if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code")
                    end;
                end;

                if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                   ("Item Charge No." = '')
                then begin
                    GetUnitAmount(FieldNo("Variant Code"));
                    "Unit Cost" := UnitCost;
                    Validate("Unit Amount");
                    Validate("Unit of Measure Code");
                end;

                if Rec."Variant Code" = '' then
                    exit;

                Description := ItemVariant.Description;
            end;
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = if ("Entry Type" = filter(Purchase | "Positive Adjmt." | Output),
                                Quantity = filter(>= 0)) Bin.Code where("Location Code" = field("Location Code"),
                                                                      "Item Filter" = field("Item No."),
                                                                      "Variant Filter" = field("Variant Code"))
            else
            if ("Entry Type" = filter(Purchase | "Positive Adjmt." | Output),
                                                                               Quantity = filter(< 0)) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                                                                    "Item No." = field("Item No."),
                                                                                                                                    "Variant Code" = field("Variant Code"))
            else
            if ("Entry Type" = filter(Sale | "Negative Adjmt." | Transfer | Consumption),
                                                                                                                                             Quantity = filter(> 0)) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                                                                                                                                  "Item No." = field("Item No."),
                                                                                                                                                                                                  "Variant Code" = field("Variant Code"))
            else
            if ("Entry Type" = filter(Sale | "Negative Adjmt." | Transfer | Consumption),
                                                                                                                                                                                                           Quantity = filter(<= 0)) Bin.Code where("Location Code" = field("Location Code"),
                                                                                                                                                                                                                                                 "Item Filter" = field("Item No."),
                                                                                                                                                                                                                                                 "Variant Filter" = field("Variant Code"));

            trigger OnValidate()
            begin
                if "Bin Code" <> xRec."Bin Code" then begin
                    TestField("Location Code");
                    if "Bin Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Bin Mandatory");
                        Location.TestField("Directed Put-away and Pick", false);
                        GetBin("Location Code", "Bin Code");
                        TestField("Location Code", Bin."Location Code");
                    end;
                end;
            end;
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                GetItem();
                "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                GetUnitAmount(FieldNo("Unit of Measure Code"));
                ReadGLSetup();
                "Unit Cost" := Round(UnitCost * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");

                Validate("Unit Amount");
                if "Entry Type" <> "Entry Type"::Output then
                    Validate(Quantity);
            end;
        }
        field(5410; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(5411; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(5413; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(5701; "Originally Ordered No."; Code[20])
        {
            Caption = 'Originally Ordered No.';
            TableRelation = Item;
        }
        field(5702; "Originally Ordered Var. Code"; Code[10])
        {
            Caption = 'Originally Ordered Var. Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Originally Ordered No."));
        }
        field(5704; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        field(5705; Nonstock; Boolean)
        {
            Caption = 'Catalog';
        }
        field(5706; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;
        }
        field(5800; "Value Entry Type"; Enum "Cost Entry Type")
        {
            Caption = 'Value Entry Type';
        }
        field(5801; "Item Charge No."; Code[20])
        {
            Caption = 'Item Charge No.';
            TableRelation = "Item Charge";
        }
        field(5817; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(6600; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(99000755; "Overhead Rate"; Decimal)
        {
            Caption = 'Overhead Rate';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
                   ("Item Charge No." <> '')
                then begin
                    "Overhead Rate" := 0;
                    Validate("Indirect Cost %", 0);
                end else
                    Validate("Indirect Cost %");
            end;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Standard Journal Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnRename()
    begin
        Error(Text001, TableCaption);
    end;

    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        GLSetup: Record "General Ledger Setup";
        SKU: Record "Stockkeeping Unit";
        DimMgt: Codeunit DimensionManagement;
        WMSManagement: Codeunit "WMS Management";
        UserMgt: Codeunit "User Setup Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        UnitCost: Decimal;
        GLSetupRead: Boolean;
        PhysInvtEntered: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You cannot rename a %1.';
        Text002: Label 'You cannot change %1 when %2 is %3.';
        Text003: Label 'You cannot change %3 when %2 is %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure SetDefaultPriceCalculationMethod()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        case "Entry Type" of
            "Entry Type"::Purchase,
            "Entry Type"::Output:
                begin
                    PurchasesPayablesSetup.Get();
                    "Price Calculation Method" := PurchasesPayablesSetup."Price Calculation Method";
                end;
            "Entry Type"::Sale:
                begin
                    SalesReceivablesSetup.Get();
                    "Price Calculation Method" := SalesReceivablesSetup."Price Calculation Method";
                end;
            else
                "Price Calculation Method" := "Price Calculation Method"::" ";
        end;
    end;

    procedure GetPriceCalculationHandler(PriceType: Enum "Price Type"; var PriceCalculation: Interface "Price Calculation")
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        GetLineWithPrice(LineWithPrice);
        LineWithPrice.SetLine(PriceType, Rec);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
    end;

    procedure GetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    var
        StdItemJournalLinePrice: Codeunit "Std. Item Jnl. Line - Price";
    begin
        LineWithPrice := StdItemJournalLinePrice;
        OnAfterGetLineWithPrice(LineWithPrice);
    end;

    local procedure ApplyPrice(PriceType: Enum "Price Type"; CalledByFieldNo: Integer)
    var
        PriceCalculation: Interface "Price Calculation";
        Line: Variant;
    begin
        OnBeforeApplyPrice(Rec);
        GetPriceCalculationHandler(PriceType, PriceCalculation);
        PriceCalculation.ApplyPrice(CalledByFieldNo);
        PriceCalculation.GetLine(Line);
        Rec := Line;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Standard Journal Code", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if BinCode = '' then
            Clear(Bin)
        else
            if Bin.Code <> BinCode then
                Bin.Get(LocationCode, BinCode);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        IsHandled: Boolean;
        OldDimSetID: Integer;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, CurrFieldNo, DefaultDimSource, IsHandled);
        if IsHandled then
            exit;

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := Rec."Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnAfterCreateDim(Rec, CurrFieldNo, xRec, OldDimSetID, DefaultDimSource);
    end;

    local procedure GetItem()
    begin
        if Item."No." = "Item No." then
            exit;

        Item.Get("Item No.");
        OnAfterGetItem(Item, Rec);
    end;

    local procedure UpdateAmount()
    begin
        Amount := Round(Quantity * "Unit Amount");
    end;

    local procedure ReadGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
    end;

    local procedure RetrieveCosts()
    begin
        ReadGLSetup();
        GetItem();
        if GetSKU() then
            UnitCost := SKU."Unit Cost"
        else
            UnitCost := Item."Unit Cost";

        if "Entry Type" = "Entry Type"::Transfer then
            UnitCost := 0
        else
            if Item."Costing Method" <> Item."Costing Method"::Standard then
                UnitCost := Round(UnitCost, GLSetup."Unit-Amount Rounding Precision");

        OnAfterRetriveCosts(Rec, Item, SKU, UnitCost);
    end;

    local procedure GetSKU() Result: Boolean
    begin
        if (SKU."Location Code" = "Location Code") and
           (SKU."Item No." = "Item No.") and
           (SKU."Variant Code" = "Variant Code")
        then
            exit(true);
        if SKU.Get("Location Code", "Item No.", "Variant Code") then
            exit(true);

        Result := false;
        OnAfterGetSKU(Rec, Result);
    end;

    local procedure GetUnitAmount(CalledByFieldNo: Integer)
    var
        PriceType: Enum "Price Type";
        UnitCostValue: Decimal;
    begin
        RetrieveCosts();
        if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
           ("Item Charge No." <> '')
        then
            exit;

        UnitCostValue := UnitCost;
        if (CalledByFieldNo = FieldNo(Quantity)) and
           (Item."No." <> '') and (Item."Costing Method" <> Item."Costing Method"::Standard)
        then
            UnitCostValue := "Unit Cost" / UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");

        case "Entry Type" of
            "Entry Type"::Purchase:
                ApplyPrice(PriceType::Purchase, CalledByFieldNo);
            "Entry Type"::Sale:
                ApplyPrice(PriceType::Sale, CalledByFieldNo);
            "Entry Type"::"Positive Adjmt.":
                "Unit Amount" := Round(
                    ((UnitCostValue - "Overhead Rate") * "Qty. per Unit of Measure") / (1 + "Indirect Cost %" / 100),
                    GLSetup."Unit-Amount Rounding Precision");
            "Entry Type"::"Negative Adjmt.":
                if not "Phys. Inventory" then
                    "Unit Amount" := UnitCostValue * "Qty. per Unit of Measure"
                else
                    UnitCost := "Unit Cost";
            "Entry Type"::Transfer:
                "Unit Amount" := 0;
        end;
    end;

    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Item, Rec."Item No.", FieldNo = Rec.FieldNo("Item No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", Rec."Salespers./Purch. Code", FieldNo = Rec.FieldNo("Salespers./Purch. Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code", FieldNo = Rec.FieldNo("Location Code"));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var StandardItemJournalLine: Record "Standard Item Journal Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItem(var Item: Record Item; var StandardItemJournalLine: Record "Standard Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSKU(StandardItemJournalLine: Record "Standard Item Journal Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(StandardItemJournalLine: Record "Standard Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var StandardItemJournalLine: Record "Standard Item Journal Line"; var xStandardItemJournalLine: Record "Standard Item Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var StandardItemJournalLine: Record "Standard Item Journal Line"; CallingFieldNo: Integer; xStandardItemJournalLine: Record "Standard Item Journal Line"; OldDimSetID: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRetriveCosts(var StandardItemJournalLine: Record "Standard Item Journal Line"; Item: Record Item; StockkeepingUnit: Record "Stockkeeping Unit"; var UnitCost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var StandardItemJournalLine: Record "Standard Item Journal Line"; var xStandardItemJournalLine: Record "Standard Item Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterCopyItemValues(var StandardItemJournalLine: Record "Standard Item Journal Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyPrice(var StandardItemJournalLine: Record "Standard Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var StandardItemJournalLine: Record "Standard Item Journal Line"; CurrentFieldNo: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var IsHandled: Boolean)
    begin
    end;
}
