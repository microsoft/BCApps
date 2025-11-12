// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Reports;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using System.Security.User;
using System.Utilities;

table 83 "Item Journal Line"
{
    Caption = 'Item Journal Line';
    DrillDownPageID = "Item Journal Lines";
    LookupPageID = "Item Journal Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Item Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            var
#if not CLEAN26
                DummyMachineCenter: Record Microsoft.Manufacturing.MachineCenter."Machine Center";
                DummyWorkCenter: Record Microsoft.Manufacturing.WorkCenter."Work Center";
#endif
            begin
                if "Item No." <> xRec."Item No." then begin
                    "Variant Code" := '';
                    "Bin Code" := '';
                    "Unit of Measure Code" := '';
                    if CurrFieldNo <> 0 then begin
                        GetItem();
                        if Item.IsInventoriableType() then
                            WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Item No."));
                    end;
                    if ("Location Code" <> '') then begin
                        GetLocation("Location Code");
                        if IsDefaultBin() and Item.IsInventoriableType() then
                            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code")
                    end;
                    SetNewBinCodeForSameLocationTransfer();
                end;

                if IsEntryTypeProduction() then begin
                    if "Item No." <> '' then
                        GetItem();
                    if Item.IsInventoriableType() then
                        WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec);
                end;

                if "Item No." = '' then begin
                    CreateDimFromDefaultDim(Rec.FieldNo("Item No."));
                    OnValidateItemNoOnAfterCreateDimInitial(Rec);
                    exit;
                end;

                GetItem();
                OnValidateItemNoOnAfterGetItem(Rec, Item);
                DisplayErrorIfItemIsBlocked(Item);
                ValidateTypeWithItemNo();

                if "Value Entry Type" = "Value Entry Type"::Revaluation then
                    Item.TestField("Inventory Value Zero", false);
                OnValidateItemNoOnBeforeSetDescription(Rec, Item);
                Description := Item.Description;
                "Inventory Posting Group" := Item."Inventory Posting Group";
                "Item Category Code" := Item."Item Category Code";

                if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
                   ("Item Charge No." <> '')
                then begin
                    if "Item No." <> xRec."Item No." then begin
                        TestField("Partial Revaluation", false);
                        RetrieveCosts();
                        "Indirect Cost %" := 0;
                        "Overhead Rate" := 0;
                        "Inventory Value Per" := "Inventory Value Per"::" ";
                        Validate("Applies-to Entry", 0);
                        "Partial Revaluation" := false;
                    end;
                end else begin
                    OnValidateItemNoOnBeforeAssignIndirectCostPct(Rec, Item);
                    "Indirect Cost %" := Item."Indirect Cost %";
                    "Overhead Rate" := Item."Overhead Rate";
                    if not "Phys. Inventory" or (Item."Costing Method" = Item."Costing Method"::Standard) then begin
                        RetrieveCosts();
                        "Unit Cost" := UnitCost;
                    end else
                        UnitCost := "Unit Cost";
                end;
                OnValidateItemNoOnAfterCalcUnitCost(Rec, Item);

                if ("Item No." <> xRec."Item No.") and
                   ((IsEntryTypeOutput() and ("No." = '')) or (not IsEntryTypeOutput())) or
                   ("Value Entry Type" = "Value Entry Type"::Revaluation)
                then
                    "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";

                case "Entry Type" of
                    "Entry Type"::Purchase:
                        ApplyPrice("Price Type"::Purchase, FieldNo("Item No."));
                    "Entry Type"::"Positive Adjmt.",
                    "Entry Type"::"Negative Adjmt.",
                    "Entry Type"::Sale:
                        ApplyPrice("Price Type"::Sale, FieldNo("Item No."));
                    "Entry Type"::Transfer:
                        begin
                            "Unit Amount" := 0;
                            "Unit Cost" := 0;
                            Amount := 0;
                        end;
                end;
                OnValidateItemNoOnSetCostAndPrice(Rec, UnitCost);
#if not CLEAN26
                OnValidateItemNoOnAfterCalcUnitAmount(Rec, DummyWorkCenter, DummyMachineCenter);
#endif

                case "Entry Type" of
                    "Entry Type"::Purchase:
                        "Unit of Measure Code" := Item."Purch. Unit of Measure";
                    "Entry Type"::Sale:
                        "Unit of Measure Code" := Item."Sales Unit of Measure";
                end;
                OnValidateItemNoOnAfterValidateUnitofMeasureCode(Rec, xRec, Item, CurrFieldNo);

                if "Unit of Measure Code" = '' then
                    "Unit of Measure Code" := Item."Base Unit of Measure";

                if "Value Entry Type" = "Value Entry Type"::Revaluation then
                    "Unit of Measure Code" := Item."Base Unit of Measure";
                OnValidateItemNoOnBeforeValidateUnitOfMeasureCode(Rec, Item, CurrFieldNo, xRec);
                Validate("Unit of Measure Code");
                if "Variant Code" <> '' then
                    if not IsEntryTypeProduction() then
                        Validate("Variant Code");

                OnAfterOnValidateItemNoAssignByEntryType(Rec, Item);

                CheckItemAvailable(FieldNo("Item No."));

                if ((not IsOrderTypeAsmOrProd()) or ("Order No." = '')) and not "Phys. Inventory" then
                    CreateDimFromDefaultDim(Rec.FieldNo("Item No."));

                OnBeforeVerifyReservedQty(Rec, xRec, FieldNo("Item No."));
                ItemJnlLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            var
                CheckDateConflict: Codeunit "Reservation-Check Date Confl.";
            begin
                TestField("Posting Date");
                Validate("Document Date", "Posting Date");
                CheckDateConflict.ItemJnlLineCheck(Rec, CurrFieldNo <> 0);
            end;
        }
        field(5; "Entry Type"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Entry Type';

            trigger OnValidate()
            begin
                if not ("Entry Type" in ["Entry Type"::"Positive Adjmt.", "Entry Type"::"Negative Adjmt."]) then
                    TestField("Phys. Inventory", false);

                if CurrFieldNo <> 0 then begin
                    GetItem();
                    if Item.IsInventoriableType() then
                        WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Entry Type"));
                end;

                case "Entry Type" of
                    "Entry Type"::Purchase:
                        if UserMgt.GetRespCenter(1, '') <> '' then
                            "Location Code" := UserMgt.GetLocation(1, '', UserMgt.GetPurchasesFilter());
                    "Entry Type"::Sale:
                        begin
                            if UserMgt.GetRespCenter(0, '') <> '' then
                                "Location Code" := UserMgt.GetLocation(0, '', UserMgt.GetSalesFilter());
                            CheckItemAvailable(FieldNo("Entry Type"));
                        end;
                    else
                        OnValidateEntryTypeOnUpdateByEntryType(Rec);
                end;

                OnValidateEntryTypeBeforeValidateLocationCode(Rec);

                if xRec."Location Code" = '' then
                    if Location.Get("Location Code") then
                        if Location."Directed Put-away and Pick" then
                            "Location Code" := '';

                if "Item No." <> '' then
                    Validate("Location Code");

                Validate("Item No.");
                if "Entry Type" <> "Entry Type"::Transfer then begin
                    "New Location Code" := '';
                    "New Bin Code" := '';
                end;

                if not IsEntryTypeOutput() then
                    Type := Type::" ";

                SetDefaultPriceCalculationMethod();

                ItemJnlLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            Editable = false;
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const(Item)) Item;
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
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
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateLocationCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Entry Type".AsInteger() <= "Entry Type"::Transfer.AsInteger() then
                    TestField("Item No.");

                ValidateItemDirectCostUnitAmount();

                if IsEntryTypeProduction() then begin
                    GetItem();
                    if Item.IsInventoriableType() then
                        WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec);
                end;

                if "Location Code" <> xRec."Location Code" then begin
                    "Bin Code" := '';
                    if CurrFieldNo <> 0 then begin
                        GetItem();
                        if Item.IsInventoriableType() then
                            WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Location Code"));
                    end;
                    if ("Location Code" <> '') and ("Item No." <> '') then begin
                        GetLocation("Location Code");
                        GetItem();
                        if IsDefaultBin() and Item.IsInventoriableType() then
                            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code");
                    end;
                    if "Entry Type" = "Entry Type"::Transfer then begin
                        "New Location Code" := "Location Code";
                        "New Bin Code" := "Bin Code";
                    end;
                end;

                Validate("Unit of Measure Code");

                CreateDimFromDefaultDim(Rec.FieldNo("Location Code"));

                ItemJnlLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(10; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            Editable = false;
            TableRelation = "Inventory Posting Group";
        }
        field(11; "Source Posting Group"; Code[20])
        {
            Caption = 'Source Posting Group';
            Editable = false;
            TableRelation = if ("Source Type" = const(Customer)) "Customer Posting Group"
            else
            if ("Source Type" = const(Vendor)) "Vendor Posting Group"
            else
            if ("Source Type" = const(Item)) "Inventory Posting Group";
        }
        field(13; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                CallWhseCheck: Boolean;
            begin
                if ("Entry Type".AsInteger() <= "Entry Type"::Transfer.AsInteger()) and (Quantity <> 0) then
                    TestField("Item No.");

                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                CallWhseCheck := IsEntryTypeConsumption();
                OnValidateQuantityOnAfterSetCallWhseCheck(Rec, CallWhseCheck);
                if CallWhseCheck then begin
                    GetItem();
                    if Item.IsInventoriableType() then
                        WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec);
                end;

                if CurrFieldNo <> 0 then begin
                    GetItem();
                    if Item.IsInventoriableType() then
                        WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption(Quantity));
                end;

                "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));
                if IsEntryTypeOutput() and ("Value Entry Type" <> "Value Entry Type"::Revaluation) then
                    "Invoiced Quantity" := 0
                else
                    "Invoiced Quantity" := Quantity;
                "Invoiced Qty. (Base)" := CalcBaseQty("Invoiced Quantity", FieldCaption("Invoiced Quantity"), FieldCaption("Invoiced Qty. (Base)"));

                CheckSerialNoQty();

                OnValidateQuantityOnBeforeGetUnitAmount(Rec, xRec, CurrFieldNo);

                GetUnitAmount(FieldNo(Quantity));
                UpdateAmount();

                CheckItemAvailable(FieldNo(Quantity));

                if "Entry Type" = "Entry Type"::Transfer then begin
                    "Qty. (Calculated)" := 0;
                    "Qty. (Phys. Inventory)" := 0;
                    "Last Item Ledger Entry No." := 0;
                end;

                CheckReservedQtyBase();

                if Item."Item Tracking Code" <> '' then
                    ItemJnlLineReserve.VerifyQuantity(Rec, xRec);
            end;
        }
        field(15; "Invoiced Quantity"; Decimal)
        {
            Caption = 'Invoiced Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
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
                                          Round(
                                            "Unit Amount" * (1 + "Indirect Cost %" / 100), GLSetup."Unit-Amount Rounding Precision") +
                                          "Overhead Rate" * "Qty. per Unit of Measure";
                                    if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                                       ("Item Charge No." = '')
                                    then
                                        Validate("Unit Cost");
                                end;
                            "Entry Type"::"Negative Adjmt.":
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
                            else
                                OnValidateUnitAmountOnUpdateByEntryType(Rec, CurrFieldNo);
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
                        "Entry Type"::"Negative Adjmt.":
                            begin
                                if Item."Costing Method" = Item."Costing Method"::Standard then
                                    Error(
                                      Text002,
                                      FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                                "Unit Amount" := "Unit Cost";
                            end;
                        else
                            OnValidateUnitCostOnUpdateByEntryType(Rec, CurrFieldNo);
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
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateAmount(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestField(Quantity);
                "Unit Amount" := Amount / Quantity;
                Validate("Unit Amount");
                ReadGLSetup();
                "Unit Amount" := Round("Unit Amount", GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(22; "Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Discount Amount';
            Editable = false;
        }
        field(23; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            begin
                if ("Order Type" <> GetOrderTypeProduction()) or ("Order No." = '') then
                    CreateDimFromDefaultDim(rec.FieldNo("Salespers./Purch. Code"));
            end;
        }
        field(26; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(29; "Applies-to Entry"; Integer)
        {
            Caption = 'Applies-to Entry';

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Applies-to Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
                ItemTrackingLines: Page "Item Tracking Lines";
                ShowTrackingExistsError: Boolean;
                IsHandled: Boolean;
                ShouldCheckItemLedgEntryFieldsForOutput: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateAppliesToEntry(Rec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Applies-to Entry" <> 0 then begin
                    ItemLedgEntry.Get("Applies-to Entry");

                    if "Value Entry Type" = "Value Entry Type"::Revaluation then begin
                        if "Inventory Value Per" <> "Inventory Value Per"::" " then
                            Error(Text006, FieldCaption("Applies-to Entry"));

                        if "Inventory Value Per" = "Inventory Value Per"::" " then
                            if not RevaluationPerEntryAllowed("Item No.") then
                                Error(RevaluationPerEntryNotAllowedErr);

                        InitRevalJnlLine(ItemLedgEntry);
                        ItemLedgEntry.TestField(Positive, true);
                    end else begin
                        TestField(Quantity);
                        if Signed(Quantity) * ItemLedgEntry.Quantity > 0 then begin
                            if Quantity > 0 then
                                FieldError(Quantity, Text030);
                            if Quantity < 0 then
                                FieldError(Quantity, Text029);
                        end;
                        ShowTrackingExistsError := ItemLedgEntry.TrackingExists();
                        OnValidateAppliesToEntryOnAferCalcShowTrackingExistsError(Rec, xRec, ShowTrackingExistsError);
                        if ShowTrackingExistsError then
                            Error(Text033, FieldCaption("Applies-to Entry"), ItemTrackingLines.Caption);

                        if not ItemLedgEntry.Open then
                            Message(Text032, "Applies-to Entry");

                        ShouldCheckItemLedgEntryFieldsForOutput := IsEntryTypeOutput();
                        OnValidateAppliestoEntryOnAfterCalcShouldCheckItemLedgEntryFieldsForOutput(Rec, ItemLedgEntry, ShouldCheckItemLedgEntryFieldsForOutput);
                        if ShouldCheckItemLedgEntryFieldsForOutput then begin
                            ItemLedgEntry.TestField("Order Type", GetOrderTypeProduction());
                            ItemLedgEntry.TestField("Order No.", "Order No.");
                            ItemLedgEntry.TestField("Order Line No.", "Order Line No.");
                            ItemLedgEntry.TestField("Entry Type", "Entry Type");
                        end;
                    end;

                    "Location Code" := ItemLedgEntry."Location Code";
                    "Variant Code" := ItemLedgEntry."Variant Code";
                end else
                    if "Value Entry Type" = "Value Entry Type"::Revaluation then begin
                        Validate("Unit Amount", 0);
                        Validate(Quantity, 0);
                        "Inventory Value (Calculated)" := 0;
                        "Inventory Value (Revalued)" := 0;
                        "Location Code" := '';
                        "Variant Code" := '';
                        "Bin Code" := '';
                    end;
            end;
        }
        field(32; "Item Shpt. Entry No."; Integer)
        {
            Caption = 'Item Shpt. Entry No.';
            Editable = false;
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
                      Text002,
                      FieldCaption("Indirect Cost %"), FieldCaption("Entry Type"), "Entry Type");

                GetItem();
                if Item."Costing Method" = Item."Costing Method"::Standard then
                    Error(
                      Text002,
                      FieldCaption("Indirect Cost %"), Item.FieldCaption("Costing Method"), Item."Costing Method");

                if "Entry Type" <> "Entry Type"::Purchase then
                    "Unit Cost" :=
                      Round(
                        "Unit Amount" * (1 + "Indirect Cost %" / 100) +
                        "Overhead Rate" * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(39; "Source Type"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(40; "Shpt. Method Code"; Code[10])
        {
            Caption = 'Shpt. Method Code';
            TableRelation = "Shipment Method";
        }
        field(41; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(42; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(43; "Recurring Method"; Option)
        {
            BlankZero = true;
            Caption = 'Recurring Method';
            OptionCaption = ',Fixed,Variable';
            OptionMembers = ,"Fixed",Variable;
        }
        field(44; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';

            trigger OnValidate()
            begin
                CheckItemTracking(FieldNo("Expiration Date"));
            end;
        }
        field(45; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';
        }
        field(46; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
            Editable = false;
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
        field(50; "New Location Code"; Code[10])
        {
            Caption = 'New Location Code';
            TableRelation = Location;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                OnBeforeValidateNewLocationCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestField("Entry Type", "Entry Type"::Transfer);
                if "New Location Code" <> xRec."New Location Code" then begin
                    "New Bin Code" := '';
                    if ("New Location Code" <> '') and ("Item No." <> '') then begin
                        GetLocation("New Location Code");
                        GetItem();
                        if IsDefaultBin() and Item.IsInventoriableType() then
                            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "New Location Code", "New Bin Code")
                    end;
                end;

                CreateNewDimFromDefaultDim(Rec.FieldNo("New Location Code"));

                ItemJnlLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(51; "New Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1,' + Text007;
            Caption = 'New Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                TestField("Entry Type", "Entry Type"::Transfer);
                ValidateNewShortcutDimCode(1, "New Shortcut Dimension 1 Code");
            end;
        }
        field(52; "New Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2,' + Text007;
            Caption = 'New Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                TestField("Entry Type", "Entry Type"::Transfer);
                ValidateNewShortcutDimCode(2, "New Shortcut Dimension 2 Code");
            end;
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

                if CurrFieldNo <> 0 then begin
                    GetItem();
                    if Item.IsInventoriableType() then
                        WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Qty. (Phys. Inventory)"));
                end;

                "Qty. (Phys. Inventory)" := UOMMgt.RoundAndValidateQty("Qty. (Phys. Inventory)", "Qty. Rounding Precision (Base)", FieldCaption("Qty. (Phys. Inventory)"));

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
        field(55; "Last Item Ledger Entry No."; Integer)
        {
            Caption = 'Last Item Ledger Entry No.';
            Editable = false;
            TableRelation = "Item Ledger Entry";
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
        field(60; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(62; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
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
        field(68; "Reserved Quantity"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("Reservation Entry".Quantity where("Source ID" = field("Journal Template Name"),
                                                                  "Source Ref. No." = field("Line No."),
                                                                  "Source Type" = const(83),
#pragma warning disable AL0603
                                                                  "Source Subtype" = field("Entry Type"),
#pragma warning restore
                                                                  "Source Batch Name" = field("Journal Batch Name"),
                                                                  "Source Prod. Order Line" = const(0),
                                                                  "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(72; "Unit Cost (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Unit Cost (ACY)';
            Editable = false;
        }
        field(73; "Source Currency Code"; Code[10])
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Source Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(79; "Document Type"; Enum "Item Ledger Document Type")
        {
            Caption = 'Document Type';
        }
        field(80; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(86; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
        }
        field(90; "Order Type"; Enum "Inventory Order Type")
        {
            Caption = 'Order Type';
            Editable = false;

            trigger OnValidate()
            begin
                if "Order Type" = xRec."Order Type" then
                    exit;
                Validate("Order No.", '');
                "Order Line No." := 0;
            end;
        }
        field(91; "Order No."; Code[20])
        {
            Caption = 'Order No.';

            trigger OnValidate()
            begin
                case "Order Type" of
                    "Order Type"::Transfer, GetOrderTypeService(), "Order Type"::" ":
                        Error(Text002, FieldCaption("Order No."), FieldCaption("Order Type"), "Order Type");
                    else
                        OnValidateOrderNoOnCaseOrderTypeElse(Rec, xRec);
                end;
            end;
        }
        field(92; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';

            trigger OnValidate()
            begin
                TestField("Order No.");
                OnValidateOrderLineNoOnCaseOrderTypeElse(Rec, xRec);
            end;
        }
        field(101; "Applies-to Rem. Quantity"; Decimal)
        {
            Caption = 'Applies-to Remaining Quantity';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Item Application Entry".Quantity where("Inbound Item Entry No." = field("Applies-to Entry"), "Posting Date" = field(upperlimit("Posting Date"))));
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
        field(481; "New Dimension Set ID"; Integer)
        {
            Caption = 'New Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(904; "Assemble to Order"; Boolean)
        {
            Caption = 'Assemble to Order';
            Editable = false;
        }
        field(1000; "Job No."; Code[20])
        {
            Caption = 'Project No.';
        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
        }
        field(1002; "Job Purchase"; Boolean)
        {
            Caption = 'Project Purchase';
        }
        field(1030; "Job Contract Entry No."; Integer)
        {
            Caption = 'Project Contract Entry No.';
            Editable = false;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                GetItem();
                GetItemVariant();
                DisplayErrorIfItemVariantIsBlocked(ItemVariant);

                if IsEntryTypeProduction() and Item.IsInventoriableType() then
                    WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec);

                if "Variant Code" <> xRec."Variant Code" then begin
                    if not IsEntryTypeOutput() then
                        "Bin Code" := '';
                    if (CurrFieldNo <> 0) and Item.IsInventoriableType() then
                        WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Variant Code"));
                    if ("Location Code" <> '') and ("Item No." <> '') then begin
                        GetLocation("Location Code");
                        if IsDefaultBin() and Item.IsInventoriableType() then
                            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code")
                    end;
                    SetNewBinCodeForSameLocationTransfer();
                end;
                if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                   ("Item Charge No." = '')
                then begin
                    GetUnitAmount(FieldNo("Variant Code"));
                    "Unit Cost" := UnitCost;
                    Validate("Unit Amount");
                    Validate("Unit of Measure Code");
                    ItemJnlLineReserve.VerifyChange(Rec, xRec);
                end;

                if "Variant Code" <> '' then
                    Description := ItemVariant.Description
                else
                    Description := Item.Description;
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
            var
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
                IsHandled: Boolean;
            begin
                if "Bin Code" <> xRec."Bin Code" then begin
                    TestField("Location Code");
                    if "Bin Code" <> '' then begin
                        GetItem();
                        Item.TestField(Type, Item.Type::Inventory);
                        GetBin("Location Code", "Bin Code");
                        GetLocation("Location Code");
                        IsHandled := false;
                        OnBinCodeOnBeforeTestBinMandatory(Rec, IsHandled);
                        if not IsHandled then
                            Location.TestField("Bin Mandatory");
                        if CurrFieldNo <> 0 then
                            WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Bin Code"));
                        TestField("Location Code", Bin."Location Code");
                        WhseIntegrationMgt.CheckBinTypeAndCode(
                            Database::"Item Journal Line", FieldCaption("Bin Code"), "Location Code", "Bin Code", "Entry Type".AsInteger());
                    end;
                    SetNewBinCodeForSameLocationTransfer();

                    IsHandled := false;
                    OnBinCodeOnCheckProdOrderCompBinCodeCheckNeeded(Rec, IsHandled);
                    if not IsHandled then
                        OnValidateBinCodeOnCompBinCheck(Rec);
                end;

                ItemJnlLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5406; "New Bin Code"; Code[20])
        {
            Caption = 'New Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("New Location Code"),
                                            "Item Filter" = field("Item No."),
                                            "Variant Filter" = field("Variant Code"));

            trigger OnValidate()
            var
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
            begin
                TestField("Entry Type", "Entry Type"::Transfer);
                if "New Bin Code" <> xRec."New Bin Code" then begin
                    TestField("New Location Code");
                    if "New Bin Code" <> '' then begin
                        GetItem();
                        Item.TestField(Type, Item.Type::Inventory);
                        GetBin("New Location Code", "New Bin Code");
                        GetLocation("New Location Code");
                        Location.TestField("Bin Mandatory");
                        if CurrFieldNo <> 0 then
                            WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("New Bin Code"));
                        TestField("New Location Code", Bin."Location Code");
                        WhseIntegrationMgt.CheckBinTypeAndCode(
                            Database::"Item Journal Line", FieldCaption("New Bin Code"), "New Location Code", "New Bin Code", "Entry Type".AsInteger());
                    end;
                end;

                ItemJnlLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                OnBeforeValidateUnitOfMeasureCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                GetItem();
                "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");

                OnValidateUnitOfMeasureCodeOnBeforeWhseValidateSourceLine(Rec, xRec);
                if IsEntryTypeProduction() and Item.IsInventoriableType() then
                    WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec);

                if (CurrFieldNo <> 0) and Item.IsInventoriableType() then
                    WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Unit of Measure Code"));

                GetUnitAmount(FieldNo("Unit of Measure Code"));
                if "Value Entry Type" = "Value Entry Type"::Revaluation then
                    TestField("Qty. per Unit of Measure", 1);

                ReadGLSetup();
                IsHandled := false;
                OnValidateUnitOfMeasureCodeOnBeforeCalcUnitCost(Rec, UnitCost, IsHandled);
                if not IsHandled then
                    "Unit Cost" := Round(UnitCost * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");

                if "Entry Type" = "Entry Type"::Consumption then begin
                    "Indirect Cost %" := Round(Item."Indirect Cost %" * "Qty. per Unit of Measure", 1);
                    "Overhead Rate" :=
                      Round(Item."Overhead Rate" * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                    "Unit Amount" := Round(UnitCost * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                end;

                if "No." <> '' then
                    Validate("Cap. Unit of Measure Code");

                Validate("Unit Amount");

                IsHandled := false;
                OnValidateUnitOfMeasureCodeOnBeforeValidateQuantity(Rec, IsHandled);
                if not IsHandled then
                    Validate(Quantity);

                CheckItemAvailable(FieldNo("Unit of Measure Code"));
            end;
        }
        field(5408; "Derived from Blanket Order"; Boolean)
        {
            Caption = 'Derived from Blanket Order';
            Editable = false;
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
        field(5415; "Invoiced Qty. (Base)"; Decimal)
        {
            Caption = 'Invoiced Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5468; "Reserved Qty. (Base)"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Source ID" = field("Journal Template Name"),
                                                                           "Source Ref. No." = field("Line No."),
                                                                           "Source Type" = const(83),
#pragma warning disable AL0603
                                                                           "Source Subtype" = field("Entry Type"),
#pragma warning restore
                                                                           "Source Batch Name" = field("Journal Batch Name"),
                                                                           "Source Prod. Order Line" = const(0),
                                                                           "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5560; Level; Integer)
        {
            Caption = 'Level';
            Editable = false;
        }
        field(5561; "Flushing Method"; Enum Microsoft.Manufacturing.Setup."Flushing Method")
        {
            Caption = 'Flushing Method';
            Editable = false;
        }
        field(5562; "Changed by User"; Boolean)
        {
            Caption = 'Changed by User';
            Editable = false;
        }
        field(5701; "Originally Ordered No."; Code[20])
        {
            AccessByPermission = TableData "Item Substitution" = R;
            Caption = 'Originally Ordered No.';
            TableRelation = Item;
        }
        field(5702; "Originally Ordered Var. Code"; Code[10])
        {
            AccessByPermission = TableData "Item Substitution" = R;
            Caption = 'Originally Ordered Var. Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Originally Ordered No."));
        }
        field(5703; "Out-of-Stock Substitution"; Boolean)
        {
            Caption = 'Out-of-Stock Substitution';
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
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;
        }
        field(5725; "Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Item Reference No.';
            ExtendedDatatype = Barcode;

            trigger OnLookup()
            begin
                ItemReferenceManagement.ItemJournalReferenceNoLookup(Rec);
            end;

            trigger OnValidate()
            var
                ItemReference: Record "Item Reference";
            begin
                ItemReferenceManagement.ValidateItemJournalReferenceNo(Rec, ItemReference, true, CurrFieldNo);
            end;
        }
        field(5726; "Item Reference Unit of Measure"; Code[10])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Item Reference Unit of Measure';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(5727; "Item Reference Type"; Enum "Item Reference Type")
        {
            Caption = 'Item Reference Type';
        }
        field(5728; "Item Reference Type No."; Code[30])
        {
            Caption = 'Item Reference Type No.';
        }
        field(5791; "Planned Delivery Date"; Date)
        {
            Caption = 'Planned Delivery Date';
        }
        field(5793; "Order Date"; Date)
        {
            Caption = 'Order Date';
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
        field(5802; "Inventory Value (Calculated)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inventory Value (Calculated)';
            Editable = false;

            trigger OnValidate()
            begin
                ReadGLSetup();
                "Unit Cost (Calculated)" :=
                  Round("Inventory Value (Calculated)" / Quantity, GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(5803; "Inventory Value (Revalued)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inventory Value (Revalued)';
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField("Value Entry Type", "Value Entry Type"::Revaluation);
                Validate(Amount, "Inventory Value (Revalued)" - "Inventory Value (Calculated)");
                ReadGLSetup();
                if ("Unit Cost (Revalued)" <> xRec."Unit Cost (Revalued)") or
                   ("Inventory Value (Revalued)" <> xRec."Inventory Value (Revalued)")
                then begin
                    if CurrFieldNo <> FieldNo("Unit Cost (Revalued)") then
                        "Unit Cost (Revalued)" :=
                          Round("Inventory Value (Revalued)" / Quantity, GLSetup."Unit-Amount Rounding Precision");

                    if CurrFieldNo <> 0 then
                        ClearSingleAndRolledUpCosts();
                end
            end;
        }
        field(5804; "Variance Type"; Enum "Cost Variance Type")
        {
            Caption = 'Variance Type';
        }
        field(5805; "Inventory Value Per"; Option)
        {
            Caption = 'Inventory Value Per';
            Editable = false;
            OptionCaption = ' ,Item,Location,Variant,Location and Variant';
            OptionMembers = " ",Item,Location,Variant,"Location and Variant";
        }
        field(5806; "Partial Revaluation"; Boolean)
        {
            Caption = 'Partial Revaluation';
            Editable = false;
        }
        field(5807; "Applies-from Entry"; Integer)
        {
            Caption = 'Applies-from Entry';
            MinValue = 0;

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Applies-from Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
                ItemTrackingLines: Page "Item Tracking Lines";
                IsHandled: Boolean;
            begin
                if "Applies-from Entry" <> 0 then begin
                    TestField(Quantity);
                    if Signed(Quantity) < 0 then begin
                        if Quantity > 0 then
                            FieldError(Quantity, Text030);
                        if Quantity < 0 then
                            FieldError(Quantity, Text029);
                    end;
                    ItemLedgEntry.Get("Applies-from Entry");
                    ItemLedgEntry.TestField(Positive, false);

                    OnValidateAppliesfromEntryOnBeforeCheckTrackingExistsError(Rec, ItemLedgEntry, IsHandled);
                    if not IsHandled then
                        if ItemLedgEntry.TrackingExists() then
                            Error(Text033, FieldCaption("Applies-from Entry"), ItemTrackingLines.Caption);
                    "Unit Cost" := CalcUnitCost(ItemLedgEntry);
                end;
            end;
        }
        field(5808; "Invoice No."; Code[20])
        {
            Caption = 'Invoice No.';
        }
        field(5809; "Unit Cost (Calculated)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (Calculated)';
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Value Entry Type", "Value Entry Type"::Revaluation);
            end;
        }
        field(5810; "Unit Cost (Revalued)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (Revalued)';
            MinValue = 0;

            trigger OnValidate()
            begin
                ReadGLSetup();
                TestField("Value Entry Type", "Value Entry Type"::Revaluation);
                if "Unit Cost (Revalued)" <> xRec."Unit Cost (Revalued)" then
                    Validate(
                      "Inventory Value (Revalued)",
                      Round(
                        "Unit Cost (Revalued)" * Quantity, GLSetup."Amount Rounding Precision"));
            end;
        }
        field(5811; "Applied Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Applied Amount';
            Editable = false;
        }
        field(5812; "Update Standard Cost"; Boolean)
        {
            Caption = 'Update Standard Cost';

            trigger OnValidate()
            begin
                TestField("Inventory Value Per");
                GetItem();
                Item.TestField("Costing Method", Item."Costing Method"::Standard);
            end;
        }
        field(5813; "Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount (ACY)';
        }
        field(5817; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(5818; Adjustment; Boolean)
        {
            Caption = 'Adjustment';
        }
        field(5819; "Applies-to Value Entry"; Integer)
        {
            Caption = 'Applies-to Value Entry';
        }
        field(5820; "Invoice-to Source No."; Code[20])
        {
            Caption = 'Invoice-to Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor;
        }
        field(5830; Type; Enum Microsoft.Manufacturing.Capacity."Capacity Type Journal")
        {
            Caption = 'Type';
            InitValue = " ";

            trigger OnValidate()
            begin
                CheckEntryType();
                Validate("No.", '');
            end;
        }
        field(5831; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(Resource)) Resource;

            trigger OnValidate()
            var
                Resource: Record Resource;
            begin
                CheckEntryType();
                if "No." = '' then begin
                    OnValidateNoOnBeforeValidateItemNo(Rec);
                    Validate("Item No.");
                    OnValidateNoOnAfterValidateItemNo(Rec);
                    exit;
                end;

                case Type of
                    Type::Resource:
                        begin
                            Resource.Get("No.");
                            Resource.CheckResourcePrivacyBlocked(false);
                            Resource.TestField(Blocked, false);
                        end;
                end;

                OnAfterValidateNo(Rec);
            end;
        }
        field(5858; "Cap. Unit of Measure Code"; Code[10])
        {
            Caption = 'Cap. Unit of Measure Code';
            TableRelation = if (Type = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("No."))
            else
            Microsoft.Manufacturing.Capacity."Capacity Unit of Measure";

            trigger OnValidate()
            begin
                if Type <> Type::Resource then
                    OnValidateCapUnitOfMeasureCodeOnSetQtyPerCapUnitOfMeasure(Rec);

                if "Order No." <> '' then
                    OnValidateCapUnitOfMeasureCodeOnCaseOrderTypeElse(Rec);

                ReadGLSetup();
                "Unit Cost" :=
                  Round("Unit Cost" * "Qty. per Cap. Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                "Unit Amount" :=
                  Round("Unit Amount" * "Qty. per Cap. Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                Validate("Unit Amount");
            end;
        }
        field(5859; "Qty. per Cap. Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Cap. Unit of Measure';
            DecimalPlaces = 0 : 5;
        }
        field(5887; "Unit Cost Calculation"; Enum "Unit Cost Calculation Type")
        {
            Caption = 'Unit Cost Calculation';
        }
        field(5888; Subcontracting; Boolean)
        {
            Caption = 'Subcontracting';
            DataClassification = CustomerContent;
        }
        field(6500; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnValidate()
            begin
                CheckItemTracking(FieldNo("Serial No."));
            end;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';

            trigger OnValidate()
            begin
                CheckItemTracking(FieldNo("Lot No."));
            end;
        }
        field(6502; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';

            trigger OnValidate()
            begin
                CheckItemTracking(FieldNo("Warranty Date"));
            end;
        }
        field(6503; "New Serial No."; Code[50])
        {
            Caption = 'New Serial No.';
            Editable = false;
        }
        field(6504; "New Lot No."; Code[50])
        {
            Caption = 'New Lot No.';
            Editable = false;
        }
        field(6505; "New Item Expiration Date"; Date)
        {
            Caption = 'New Item Expiration Date';
        }
        field(6506; "Item Expiration Date"; Date)
        {
            Caption = 'Item Expiration Date';
            Editable = false;
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';

            trigger OnValidate()
            begin
                CheckItemTracking(FieldNo("Package No."));
            end;
        }
        field(6516; "New Package No."; Code[50])
        {
            Caption = 'New Package No.';
            CaptionClass = '6,1';
            Editable = false;
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
        field(7315; "Warehouse Adjustment"; Boolean)
        {
            Caption = 'Warehouse Adjustment';
        }
        field(7316; "Direct Transfer"; Boolean)
        {
            Caption = 'Direct Transfer';
            DataClassification = SystemMetadata;
        }
        field(7380; "Phys Invt Counting Period Code"; Code[10])
        {
            Caption = 'Phys Invt Counting Period Code';
            Editable = false;
            TableRelation = "Phys. Invt. Counting Period";
        }
        field(7381; "Phys Invt Counting Period Type"; Option)
        {
            Caption = 'Phys Invt Counting Period Type';
            Editable = false;
            OptionCaption = ' ,Item,SKU';
            OptionMembers = " ",Item,SKU;
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
        field(99000756; "Single-Level Material Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Material Cost';
        }
        field(99000757; "Single-Level Capacity Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Capacity Cost';
        }
        field(99000758; "Single-Level Subcontrd. Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Subcontrd. Cost';
        }
        field(99000759; "Single-Level Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Cap. Ovhd Cost';
        }
        field(99000760; "Single-Level Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Mfg. Ovhd Cost';
        }
        field(99000761; "Rolled-up Material Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Material Cost';
        }
        field(99000762; "Rolled-up Capacity Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Capacity Cost';
        }
        field(99000763; "Rolled-up Subcontracted Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Subcontracted Cost';
        }
        field(99000764; "Rolled-up Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Mfg. Ovhd Cost';
        }
        field(99000765; "Rolled-up Cap. Overhead Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Cap. Overhead Cost';
        }
        field(99000766; "Single-Lvl Mat. Non-Invt. Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Material Non-Inventory Cost';
        }
        field(99000767; "Rolled-up Mat. Non-Invt. Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Material Non-Inventory Cost';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Entry Type", "Item No.", "Variant Code", "Location Code", "Bin Code", "Posting Date")
        {
            IncludedFields = "Quantity (Base)";
        }
        key(Key3; "Entry Type", "Item No.", "Variant Code", "New Location Code", "New Bin Code", "Posting Date")
        {
            IncludedFields = "Quantity (Base)";
        }
        key(Key4; "Item No.", "Posting Date")
        {
        }
        key(Key5; "Journal Template Name", "Journal Batch Name", "Item No.", "Location Code", "Variant Code")
        {
        }
        key(Key6; "Journal Template Name", "Journal Batch Name", "Document No.")
        {
        }
        key(Key7; "Journal Template Name", "Journal Batch Name", "Document No.", "Item No.", "Location Code", "Bin Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Item No.", Description, Quantity, "Document No.", "Document Date")
        { }
    }

    trigger OnDelete()
    begin
        ItemJnlLineReserve.DeleteLine(Rec);

        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);
    end;

    trigger OnInsert()
    begin
        ItemJnlTemplate.Get("Journal Template Name");
        ItemJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        if Rec."Posting No. Series" = '' then
            Rec."Posting No. Series" := ItemJnlBatch."Posting No. Series";
        if Rec."Posting No. Series" = '' then
            Rec."Posting No. Series" := ItemJnlTemplate."Posting No. Series";

        Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
        Rec.ValidateNewShortcutDimCode(1, "New Shortcut Dimension 1 Code");
        Rec.ValidateNewShortcutDimCode(2, "New Shortcut Dimension 2 Code");

        CheckPlanningAssignment();
    end;

    trigger OnModify()
    begin
        OnBeforeVerifyReservedQty(Rec, xRec, 0);
        ItemJnlLineReserve.VerifyChange(Rec, xRec);
        CheckPlanningAssignment();
    end;

    trigger OnRename()
    begin
        ItemJnlLineReserve.RenameLine(Rec, xRec);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 must be reduced.';
        Text002: Label 'You cannot change %1 when %2 is %3.';
        Text006: Label 'You must not enter %1 in a revaluation sum line.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        GLSetup: Record "General Ledger Setup";
        Location: Record Location;
        Bin: Record Bin;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
        UOMMgt: Codeunit "Unit of Measure Management";
        UserMgt: Codeunit "User Setup Management";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        WMSManagement: Codeunit "WMS Management";
        ItemReferenceManagement: Codeunit "Item Reference Management";
        GLSetupRead: Boolean;
#pragma warning disable AA0074
        Text007: Label 'New ';
        Text029: Label 'must be positive';
        Text030: Label 'must be negative';
#pragma warning disable AA0470
        Text032: Label 'When posting, the entry %1 will be opened first.';
        Text033: Label 'If the item carries serial, lot or package numbers, then you must use the %1 field in the %2 window.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        RevaluationPerEntryNotAllowedErr: Label 'This item has already been revalued with the Calculate Inventory Value function, so you cannot use the Applies-to Entry field as that may change the valuation.';
        BlockedErr: Label 'You cannot choose %1 %2 because the %3 check box is selected on its %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        SalesBlockedErr: Label 'You cannot sell %1 %2 because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        PurchasingBlockedErr: Label 'You cannot purchase %1 %2 because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        ServiceSalesBlockedErr: Label 'You cannot sell %1 %2 via service because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        ItemVariantPrimaryKeyLbl: Label '%1, %2', Comment = '%1 - Item No., %2 - Variant Code', Locked = true;
        SerialNoRequiredErr: Label 'You must assign a serial number for item %1.', Comment = '%1 - Item No.';
        LotNoRequiredErr: Label 'You must assign a lot number for item %1.', Comment = '%1 - Item No.';
        DocNoFilterErr: Label 'The document numbers cannot be renumbered while there is an active filter on the Document No. field.';
        RenumberDocNoQst: Label 'If you have many documents it can take time to sort them, and %1 might perform slowly during the process. In those cases we suggest that you sort them during non-working hours. Do you want to continue?', Comment = '%1= Business Central';
        IncorrectQtyForSNErr: Label 'Quantity must be -1, 0 or 1 when Serial No. is stated.';
        ItemTrackingExistsErr: Label 'You cannot change %1 because item tracking already exists for this journal line.', Comment = '%1 - Serial, Lot or Package No.';

    protected var
        ItemJnlLine: Record "Item Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerSetupRead: Boolean;
        DimMgt: Codeunit DimensionManagement;
        PhysInvtEntered: Boolean;
        UnitCost: Decimal;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GeneralLedgerSetupRead then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetupRead := true;
        end;
        exit(GeneralLedgerSetup."Additional Reporting Currency")
    end;

    /// <summary>
    /// Determines if the current item journal line is considered empty based on its quantity, time, item number,
    /// and value entry type.
    /// </summary>
    /// <returns>True if the item journal line is considered empty, otherwise false.</returns>
    procedure EmptyLine() Result: Boolean
    begin
        Result :=
          (Quantity = 0) and
          ((TimeIsEmpty() and ("Item No." = '')) or
           ("Value Entry Type" = "Value Entry Type"::Revaluation));
        OnAfterEmptyLine(Rec, Result);
    end;

    /// <summary>
    /// Determines if the current item journal line is for a deleted item based on its entry type, value entry type,
    /// item number, item charge number, and invoiced quantity.
    /// </summary>
    /// <returns>True if the item journal line is for a deleted item, otherwise false.</returns>
    procedure IsValueEntryForDeletedItem(): Boolean
    begin
        exit(
          (IsEntryTypeOutput() or ("Value Entry Type" = "Value Entry Type"::Rounding)) and
          ("Item No." = '') and ("Item Charge No." = '') and ("Invoiced Qty. (Base)" <> 0));
    end;

    internal procedure CalcReservedQuantity()
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if IsSourceSales() then begin
            SetReservEntrySourceFilters(ReservationEntry, false);
            ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
            ReservationEntry.CalcSums("Quantity (Base)");
            "Reserved Qty. (Base)" := ReservationEntry."Quantity (Base)"
        end else
            CalcFields("Reserved Qty. (Base)");
    end;

    /// <summary>
    /// Updates the amount of the current item journal line to reflect changes in quantity and unit amount.
    /// </summary>
    procedure UpdateAmount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAmount(Rec, IsHandled);
        if IsHandled then
            exit;

        Amount := Round(Quantity * "Unit Amount");

        OnAfterUpdateAmount(Rec);
    end;

    local procedure SelectItemEntry(CurrentFieldNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemJnlLine2: Record "Item Journal Line";
        PositiveFilterValue: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeSelectItemEntry(Rec, xRec, CurrentFieldNo);

        IsHandled := false;
        OnSelectItemEntryOnSetFilters(Rec, ItemLedgEntry, CurrentFieldNo, IsHandled);
        if not IsHandled then begin
            ItemLedgEntry.SetCurrentKey("Item No.", Positive);
            ItemLedgEntry.SetRange("Item No.", "Item No.");
        end;

        if "Location Code" <> '' then
            ItemLedgEntry.SetRange("Location Code", "Location Code");

        if CurrentFieldNo = FieldNo("Applies-to Entry") then begin
            if Quantity <> 0 then begin
                PositiveFilterValue := (Signed(Quantity) < 0) or ("Value Entry Type" = "Value Entry Type"::Revaluation);
                ItemLedgEntry.SetRange(Positive, PositiveFilterValue);
            end;

            if "Value Entry Type" <> "Value Entry Type"::Revaluation then begin
                ItemLedgEntry.SetCurrentKey("Item No.", Open);
                ItemLedgEntry.SetRange(Open, true);
            end;
        end else
            ItemLedgEntry.SetRange(Positive, false);

        OnSelectItemEntryOnBeforeOpenPage(ItemLedgEntry, Rec, CurrentFieldNo);

        if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then begin
            ItemJnlLine2 := Rec;
            if CurrentFieldNo = FieldNo("Applies-to Entry") then
                ItemJnlLine2.Validate("Applies-to Entry", ItemLedgEntry."Entry No.")
            else
                ItemJnlLine2.Validate("Applies-from Entry", ItemLedgEntry."Entry No.");
            CheckItemAvailable(CurrentFieldNo);
            Rec := ItemJnlLine2;
        end;

        OnAfterSelectItemEntry(Rec);
    end;

    /// <summary>
    /// Checks if the item is available based on the current item journal line.
    /// </summary>
    /// <remarks>
    /// An error or a notification is raised if the item is out of stock.
    /// </remarks>
    /// <param name="CalledByFieldNo">Field number that called the item availability check.</param>
    procedure CheckItemAvailable(CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        if (CurrFieldNo = 0) or (CurrFieldNo <> CalledByFieldNo) then // Prevent two checks on quantity
            exit;

        IsHandled := false;
        OnBeforeCheckItemAvailable(Rec, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        if (CurrFieldNo <> 0) and ("Item No." <> '') and (Quantity <> 0) and
           ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and ("Item Charge No." = '')
        then
            if ItemCheckAvail.ItemJnlCheckLine(Rec) then
                ItemCheckAvail.RaiseUpdateInterruptedError();
    end;

    local procedure CheckReservedQtyBase()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReservedQtyBase(Rec, Item, IsHandled);
        if IsHandled then
            exit;

        CalcFields("Reserved Qty. (Base)");
        if Abs("Quantity (Base)") < Abs("Reserved Qty. (Base)") then
            Error(Text001, FieldCaption("Reserved Qty. (Base)"));
    end;

    procedure GetItem()
    begin
        if Item."No." <> "Item No." then
            Item.Get("Item No.");

        OnAfterGetItemChange(Item, Rec);
    end;

    local procedure GetItemVariant()
    begin
        if Rec."Variant Code" = '' then begin
            Clear(ItemVariant);
            exit;
        end;

        if (ItemVariant."Item No." <> Rec."Item No.") or (ItemVariant.Code <> Rec."Variant Code") then
            ItemVariant.Get(Rec."Item No.", Rec."Variant Code");

        OnAfterGetItemVariantChange(ItemVariant, Rec);
    end;

    /// <summary>
    /// Initializes a new item journal line based on the previous item journal line record.
    /// </summary>
    /// <param name="LastItemJnlLine">Previous item journal line record.</param>
    procedure SetUpNewLine(LastItemJnlLine: Record "Item Journal Line")
    var
        NoSeries: Codeunit "No. Series";
    begin
        ItemJnlTemplate.Get("Journal Template Name");
        ItemJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        ItemJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if ItemJnlLine.FindFirst() then begin
            OnSetUpNewLineOnAfterFindItemJnlLine(Rec, ItemJnlLine, LastItemJnlLine);
            "Posting Date" := LastItemJnlLine."Posting Date";
            "Document Date" := LastItemJnlLine."Posting Date";
            if (ItemJnlTemplate.Type in
                [ItemJnlTemplate.GetConsumptionTemplateType(), ItemJnlTemplate.GetOutputTemplateType()])
            then begin
                if not IsDocNoProdOrderNo() then
                    "Document No." := LastItemJnlLine."Document No."
            end else
                "Document No." := LastItemJnlLine."Document No.";
        end else begin
            "Posting Date" := WorkDate();
            "Document Date" := WorkDate();
            if ItemJnlBatch."No. Series" <> '' then
                "Document No." := NoSeries.PeekNextNo(ItemJnlBatch."No. Series", "Posting Date");
            if (ItemJnlTemplate.Type in
                [ItemJnlTemplate.GetConsumptionTemplateType(), ItemJnlTemplate.GetOutputTemplateType()]) and
               not IsDocNoProdOrderNo()
            then
                if ItemJnlBatch."No. Series" <> '' then
                    "Document No." := NoSeries.PeekNextNo(ItemJnlBatch."No. Series", "Posting Date");
        end;
        "Recurring Method" := LastItemJnlLine."Recurring Method";
        "Entry Type" := LastItemJnlLine."Entry Type";
        "Source Code" := ItemJnlTemplate."Source Code";
        "Reason Code" := ItemJnlBatch."Reason Code";
        "Posting No. Series" := ItemJnlBatch."Posting No. Series";
        if ItemJnlTemplate.Type = ItemJnlTemplate.Type::Revaluation then begin
            "Value Entry Type" := "Value Entry Type"::Revaluation;
            "Entry Type" := "Entry Type"::"Positive Adjmt.";
        end;

        OnSetUpNewLineOnBeforeSetDefaultPriceCalculationMethod(Rec, ItemJnlBatch, DimMgt);
        SetDefaultPriceCalculationMethod();

        case "Entry Type" of
            "Entry Type"::Purchase:
                "Location Code" := UserMgt.GetLocation(1, '', UserMgt.GetPurchasesFilter());
            "Entry Type"::Sale:
                "Location Code" := UserMgt.GetLocation(0, '', UserMgt.GetSalesFilter());
        end;

        if IsEntryTypeOutput() then
            Clear(DimMgt);

        if Location.Get("Location Code") then
            if Location."Directed Put-away and Pick" then
                "Location Code" := '';

        OnAfterSetupNewLine(Rec, LastItemJnlLine, ItemJnlTemplate, ItemJnlBatch);
    end;

    local procedure SetDefaultPriceCalculationMethod()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        "Price Calculation Method" := "Price Calculation Method"::" ";
        case "Entry Type" of
            "Entry Type"::Purchase:
                begin
                    PurchasesPayablesSetup.Get();
                    "Price Calculation Method" := PurchasesPayablesSetup."Price Calculation Method";
                end;
            "Entry Type"::Sale:
                begin
                    SalesReceivablesSetup.Get();
                    "Price Calculation Method" := SalesReceivablesSetup."Price Calculation Method";
                end;
        end;
        OnAfterSetDefaultPriceCalculationMethod(Rec);
    end;

    /// <summary>
    /// Sets the document-related fields of an item journal line.
    /// </summary>
    /// <param name="DocType">Document type to set.</param>
    /// <param name="DocNo">Document no. to set.</param>
    /// <param name="ExtDocNo">External document no. to set.</param>
    /// <param name="PostingNos">Posting no. series to set.</param>
    procedure SetDocNos(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20];
                                     ExtDocNo: Text[35];
                                     PostingNos: Code[20])
    begin
        "Document Type" := DocType;
        "Document No." := DocNo;
        "External Document No." := ExtDocNo;
        "Posting No. Series" := PostingNos;
    end;

    local procedure SetNewBinCodeForSameLocationTransfer()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetNewBinCodeForSameLocationTransfer(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if ("Entry Type" = "Entry Type"::Transfer) and ("Location Code" = "New Location Code") then
            "New Bin Code" := "Bin Code";
    end;

    /// <summary>
    /// Updates the unit amount of the current item journal line.
    /// </summary>
    /// <param name="CalledByFieldNo">Field number that called the unit amount update.</param>
    procedure GetUnitAmount(CalledByFieldNo: Integer)
    var
        PriceType: Enum "Price Type";
        UnitCostValue: Decimal;
        IsHandled: Boolean;
    begin
        RetrieveCosts();
        if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
           ("Item Charge No." <> '')
        then
            exit;

        OnBeforeGetUnitAmount(Rec, CalledByFieldNo, IsHandled);
        if IsHandled then
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
                "Unit Amount" :=
                  Round(
                    ((UnitCostValue - "Overhead Rate") * "Qty. per Unit of Measure") / (1 + "Indirect Cost %" / 100),
                    GLSetup."Unit-Amount Rounding Precision");
            "Entry Type"::"Negative Adjmt.":
                "Unit Amount" := UnitCostValue * "Qty. per Unit of Measure";
            "Entry Type"::Transfer:
                "Unit Amount" := 0;
        end;

        OnAfterGetUnitAmount(Rec, UnitCost);
    end;

    /// <summary>
    /// Updates the price of the item journal line.
    /// </summary>
    /// <param name="PriceType">The price type for which the price or discount will be calculated.</param>
    /// <param name="CalledByFieldNo">Field number that called the price update.</param>
    procedure ApplyPrice(PriceType: Enum "Price Type"; CalledByFieldNo: Integer)
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        PriceCalculation: Interface "Price Calculation";
        Line: Variant;
    begin
        GetLineWithPrice(LineWithPrice);
        LineWithPrice.SetLine(PriceType, Rec);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
        PriceCalculation.ApplyPrice(CalledByFieldNo);
        PriceCalculation.GetLine(Line);
        Rec := Line;
    end;

    /// <summary>
    /// Gets the default or overridden line with price interface implementation.
    /// </summary>
    /// <param name="LineWithPrice">Return value: line with price implementation.</param>
    procedure GetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    var
        ItemJournalLinePrice: Codeunit "Item Journal Line - Price";
    begin
        LineWithPrice := ItemJournalLinePrice;
        OnAfterGetLineWithPrice(LineWithPrice);
    end;

    /// <summary>
    /// Adjusts the sign of the provided value based on the document type of the item journal line.
    /// </summary>
    /// <param name="Value">The value to adjust the sign of.</param>
    /// <returns>Signed value.</returns>
    procedure Signed(Value: Decimal) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSigned(Rec, Value, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case "Entry Type" of
            "Entry Type"::Purchase,
          "Entry Type"::"Positive Adjmt.":
                Result := Value;
            "Entry Type"::Sale,
          "Entry Type"::"Negative Adjmt.",
          "Entry Type"::Transfer:
                Result := -Value;
        end;
        OnAfterSigned(Rec, Value, Result);
    end;

    /// <summary>
    /// Determines if the item journal line is inbound based on the quantities.
    /// </summary>
    /// <returns>True if item journal line is inbound, otherwise false.</returns>
    procedure IsInbound(): Boolean
    begin
        exit((Signed(Quantity) > 0) or (Signed("Invoiced Quantity") > 0));
    end;

    /// <summary>
    /// Opens a page for editing item tracking lines for the item journal line.
    /// </summary>
    procedure OpenItemTrackingLines(IsReclass: Boolean)
    begin
        ItemJnlLineReserve.CallItemTracking(Rec, IsReclass);
    end;

    /// <summary>
    /// Creates dimensions for the item journal line based on the provided default dimension sources.
    /// </summary>
    /// <param name="DefaultDimSource">The list of default dimension sources.</param>
    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        CreateDim(DefaultDimSource, 0, 0);
    end;

    /// <summary>
    /// Creates dimensions for the item journal line based on the provided default dimension sources,
    /// an inherited dimension set ID and an inherited table number.
    /// </summary>
    /// <remarks>
    /// Also updates the shortcut dimension codes and sets the new dimension set ID and new shortcut dimension codes
    /// if the entry type is transfer.
    /// </remarks>
    /// <param name="DefaultDimSource">The list of default dimension sources.</param>
    /// <param name="InheritFromDimSetID">Dimension set ID to inherit.</param>
    /// <param name="InheritFromTableNo">
    /// Table number to inherit from. This parameter is used to specify the table number for the new temporary
    /// dimension buffer that are created based on the dimension set entries associated with InheritFromDimSetID.
    /// These temporary records are used later in the procedure to determine the default dimension set ID.
    /// </param>
    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; InheritFromDimSetID: Integer; InheritFromTableNo: Integer)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        SourceCode: Code[10];
        IsHandled: Boolean;
        OldDimSetID: Integer;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, IsHandled, CurrFieldNo, DefaultDimSource, InheritFromDimSetID, InheritFromTableNo);
        if IsHandled then
            exit;

        SourceCode := "Source Code";
        if SourceCode = '' then
            if ItemJournalTemplate.Get("Journal Template Name") then
                SourceCode := ItemJournalTemplate."Source Code";

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := Rec."Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCode,
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", InheritFromDimSetID, InheritFromTableNo);
        OnCreateDimOnBeforeUpdateGlobalDimFromDimSetID(Rec, xRec, CurrFieldNo, OldDimSetID, DefaultDimSource, InheritFromDimSetID, InheritFromTableNo);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        if "Entry Type" = "Entry Type"::Transfer then
            if Rec."New Location Code" <> '' then
                CreateNewDimFromDefaultDim(Rec.FieldNo("New Location Code"))
            else begin
                "New Dimension Set ID" := "Dimension Set ID";
                "New Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                "New Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            end;
    end;

    /// <summary>
    /// Sets dimensions to the item journal line from the provided dimension set.
    /// </summary>
    /// <param name="DimesionSetID">Dimension set ID to copy from.</param>
    procedure CopyDim(DimesionSetID: Integer)
    var
        DimSetEntry: Record "Dimension Set Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDim(Rec, DimesionSetID, IsHandled);
        if IsHandled then
            exit;

        ReadGLSetup();
        "Dimension Set ID" := DimesionSetID;
        DimSetEntry.SetRange("Dimension Set ID", DimesionSetID);
        DimSetEntry.SetRange("Dimension Code", GLSetup."Global Dimension 1 Code");
        if DimSetEntry.FindFirst() then
            "Shortcut Dimension 1 Code" := DimSetEntry."Dimension Value Code"
        else
            "Shortcut Dimension 1 Code" := '';
        DimSetEntry.SetRange("Dimension Code", GLSetup."Global Dimension 2 Code");
        if DimSetEntry.FindFirst() then
            "Shortcut Dimension 2 Code" := DimSetEntry."Dimension Value Code"
        else
            "Shortcut Dimension 2 Code" := '';
    end;

    /// <summary>
    /// Verifies whether the provided shortcut dimension code and value are valid.
    /// </summary>
    /// <param name="FieldNumber">Number of the shortcut dimension.</param>
    /// <param name="ShortcutDimCode">Value of the shortcut dimension.</param>
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    local procedure ValidateItemDirectCostUnitAmount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateItemDirectCostUnitAmount(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
           ("Item Charge No." = '') and
           ("No." = '')
        then begin
            GetUnitAmount(FieldNo("Location Code"));
            "Unit Cost" := UnitCost;
            Validate("Unit Amount");
            CheckItemAvailable(FieldNo("Location Code"));
        end;
    end;

    /// <summary>
    /// Opens a page for selecting a dimension code, then assigns the selected value to the provided number
    /// of the shortcut dimension.
    /// </summary>
    /// <param name="FieldNumber">Number of the shortcut dimension.</param>
    /// <param name="ShortcutDimCode">Return value: Value of the selected shortcut dimension.</param>
    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    /// <summary>
    /// Gets an array of shortcut dimension values from the dimensions of the item journal line.
    /// </summary>
    /// <param name="ShortcutDimCode">Return value: The array of shortcut dimension values.</param>
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    /// <summary>
    /// Verifies whether the provided new shortcut dimension code and value are valid.
    /// </summary>
    /// <param name="FieldNumber">Number of the shortcut dimension.</param>
    /// <param name="NewShortcutDimCode">Value of the new shortcut dimension.</param>
    procedure ValidateNewShortcutDimCode(FieldNumber: Integer; var NewShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, NewShortcutDimCode, "New Dimension Set ID");
    end;

    /// <summary>
    /// Opens a page for selecting a dimension code, then assigns the selected value to the presented number of
    /// the new shortcut dimension.
    /// </summary>
    /// <param name="FieldNumber">Number of the shortcut dimension.</param>
    /// <param name="NewShortcutDimCode">Return value: Value of the selected new shortcut dimension.</param>
    procedure LookupNewShortcutDimCode(FieldNumber: Integer; var NewShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, NewShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, NewShortcutDimCode, "New Dimension Set ID");
    end;

    /// <summary>
    /// Gets an array of new shortcut dimension values from the dimensions of the item journal line.
    /// </summary>
    /// <param name="NewShortcutDimCode">Return value: The array of new shortcut dimension values.</param>
    procedure ShowNewShortcutDimCode(var NewShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("New Dimension Set ID", NewShortcutDimCode);
    end;

    local procedure InitRevalJnlLine(ItemLedgEntry2: Record "Item Ledger Entry")
    var
        ItemApplnEntry: Record "Item Application Entry";
        ValueEntry: Record "Value Entry";
        CostAmtActual: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitRevalJnlLine(Rec, ItemLedgEntry2, IsHandled);
        if IsHandled then
            exit;

        if "Value Entry Type" <> "Value Entry Type"::Revaluation then
            exit;

        ItemLedgEntry2.TestField("Item No.", "Item No.");
        ItemLedgEntry2.TestField("Completely Invoiced", true);
        ItemLedgEntry2.TestField(Positive, true);
        ItemApplnEntry.CheckAppliedFromEntryToAdjust(ItemLedgEntry2."Entry No.");

        Validate("Entry Type", ItemLedgEntry2."Entry Type");
        "Posting Date" := ItemLedgEntry2."Posting Date";
        Validate("Unit Amount", 0);
        Validate(Quantity, ItemLedgEntry2."Invoiced Quantity");

        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry2."Entry No.");
        ValueEntry.SetFilter("Entry Type", '<>%1', ValueEntry."Entry Type"::Rounding);
        ValueEntry.Find('-');
        repeat
            if not (ValueEntry."Expected Cost" or ValueEntry."Partial Revaluation") then
                CostAmtActual := CostAmtActual + ValueEntry."Cost Amount (Actual)";
        until ValueEntry.Next() = 0;

        Validate("Inventory Value (Calculated)", CostAmtActual);
        Validate("Inventory Value (Revalued)", CostAmtActual);

        "Location Code" := ItemLedgEntry2."Location Code";
        "Variant Code" := ItemLedgEntry2."Variant Code";
        "Applies-to Entry" := ItemLedgEntry2."Entry No.";
        CopyDim(ItemLedgEntry2."Dimension Set ID");

        OnAfterInitRevalJnlLine(Rec, ItemLedgEntry2);
    end;

    /// <summary>
    /// Copies provided document-related fields to the current item journal line record.
    /// </summary>
    /// <param name="DocType">Document type to set.</param>
    /// <param name="DocNo">Document no. to set.</param>
    /// <param name="ExtDocNo">External document no. to set.</param>
    /// <param name="SourceCode">Source code to set.</param>
    /// <param name="NoSeriesCode">Posting no. series code to set.</param>
    procedure CopyDocumentFields(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20]; ExtDocNo: Text[35]; SourceCode: Code[10]; NoSeriesCode: Code[20])
    begin
        "Document Type" := DocType;
        "Document No." := DocNo;
        "External Document No." := ExtDocNo;
        "Source Code" := SourceCode;
        if NoSeriesCode <> '' then
            "Posting No. Series" := NoSeriesCode;
    end;

    /// <summary>
    /// Copies fields from the provided sales header record to the current item journal line.
    /// </summary>
    /// <param name="SalesHeader">Sales header to copy from.</param>
    procedure CopyFromSalesHeader(SalesHeader: Record "Sales Header")
    begin
        "Posting Date" := SalesHeader."Posting Date";
        "Document Date" := SalesHeader."Document Date";
        "VAT Reporting Date" := SalesHeader."VAT Reporting Date";
        "Order Date" := SalesHeader."Order Date";
        "Source Posting Group" := SalesHeader."Customer Posting Group";
        "Salespers./Purch. Code" := SalesHeader."Salesperson Code";
        "Reason Code" := SalesHeader."Reason Code";
        "Source Currency Code" := SalesHeader."Currency Code";
        "Shpt. Method Code" := SalesHeader."Shipment Method Code";
        "Price Calculation Method" := SalesHeader."Price Calculation Method";

        OnAfterCopyItemJnlLineFromSalesHeader(Rec, SalesHeader);
    end;

    /// <summary>
    /// Copies fields from the provided sales line record to the current item journal line.
    /// </summary>
    /// <param name="SalesLine">Sales line to copy from.</param>
    procedure CopyFromSalesLine(SalesLine: Record "Sales Line")
    begin
        "Item No." := SalesLine."No.";
        Description := SalesLine.Description;
        "Shortcut Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := SalesLine."Dimension Set ID";
        "Location Code" := SalesLine."Location Code";
        "Bin Code" := SalesLine."Bin Code";
        "Variant Code" := SalesLine."Variant Code";
        "Inventory Posting Group" := SalesLine."Posting Group";
        "Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        "Transaction Type" := SalesLine."Transaction Type";
        "Transport Method" := SalesLine."Transport Method";
        "Entry/Exit Point" := SalesLine."Exit Point";
        Area := SalesLine.Area;
        "Transaction Specification" := SalesLine."Transaction Specification";
        "Drop Shipment" := SalesLine."Drop Shipment";
        "Entry Type" := "Entry Type"::Sale;
        "Unit of Measure Code" := SalesLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := SalesLine."Qty. per Unit of Measure";
        "Qty. Rounding Precision" := SalesLine."Qty. Rounding Precision";
        "Qty. Rounding Precision (Base)" := SalesLine."Qty. Rounding Precision (Base)";
        "Derived from Blanket Order" := SalesLine."Blanket Order No." <> '';
        "Item Reference No." := SalesLine."Item Reference No.";
        "Originally Ordered No." := SalesLine."Originally Ordered No.";
        "Originally Ordered Var. Code" := SalesLine."Originally Ordered Var. Code";
        "Out-of-Stock Substitution" := SalesLine."Out-of-Stock Substitution";
        "Item Category Code" := SalesLine."Item Category Code";
        Nonstock := SalesLine.Nonstock;
        "Purchasing Code" := SalesLine."Purchasing Code";
        "Return Reason Code" := SalesLine."Return Reason Code";
        "Planned Delivery Date" := SalesLine."Planned Delivery Date";
        "Document Line No." := SalesLine."Line No.";
        "Unit Cost" := SalesLine."Unit Cost (LCY)";
        "Unit Cost (ACY)" := SalesLine."Unit Cost";
        "Value Entry Type" := "Value Entry Type"::"Direct Cost";
        "Source Type" := "Source Type"::Customer;
        "Source No." := SalesLine."Sell-to Customer No.";
        "Price Calculation Method" := SalesLine."Price Calculation Method";
        "Invoice-to Source No." := SalesLine."Bill-to Customer No.";

        OnAfterCopyItemJnlLineFromSalesLine(Rec, SalesLine);
    end;

    /// <summary>
    /// Copies fields from the provided purchase header record to the current item journal line.
    /// </summary>
    /// <param name="PurchHeader">Purchase header to copy from.</param>
    procedure CopyFromPurchHeader(PurchHeader: Record "Purchase Header")
    begin
        "Posting Date" := PurchHeader."Posting Date";
        "Document Date" := PurchHeader."Document Date";
        "VAT Reporting Date" := PurchHeader."VAT Reporting Date";
        "Source Posting Group" := PurchHeader."Vendor Posting Group";
        "Salespers./Purch. Code" := PurchHeader."Purchaser Code";
        "Country/Region Code" := PurchHeader."Buy-from Country/Region Code";
        "Reason Code" := PurchHeader."Reason Code";
        "Source Currency Code" := PurchHeader."Currency Code";
        "Shpt. Method Code" := PurchHeader."Shipment Method Code";
        "Price Calculation Method" := PurchHeader."Price Calculation Method";

        OnAfterCopyItemJnlLineFromPurchHeader(Rec, PurchHeader);
    end;

    /// <summary>
    /// Copies fields from the provided purchase line record to the current item journal line.
    /// </summary>
    /// <param name="PurchLine">Purchase line to copy from.</param>
    procedure CopyFromPurchLine(PurchLine: Record "Purchase Line")
    begin
        "Item No." := PurchLine."No.";
        Description := PurchLine.Description;
        "Shortcut Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := PurchLine."Dimension Set ID";
        "Location Code" := PurchLine."Location Code";
        "Bin Code" := PurchLine."Bin Code";
        "Variant Code" := PurchLine."Variant Code";
        "Item Category Code" := PurchLine."Item Category Code";
        "Inventory Posting Group" := PurchLine."Posting Group";
        "Gen. Bus. Posting Group" := PurchLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := PurchLine."Gen. Prod. Posting Group";
        "Job No." := PurchLine."Job No.";
        "Job Task No." := PurchLine."Job Task No.";
        if "Job No." <> '' then
            "Job Purchase" := true;
        "Applies-to Entry" := PurchLine."Appl.-to Item Entry";
        "Transaction Type" := PurchLine."Transaction Type";
        "Transport Method" := PurchLine."Transport Method";
        "Entry/Exit Point" := PurchLine."Entry Point";
        Area := PurchLine.Area;
        "Transaction Specification" := PurchLine."Transaction Specification";
        "Drop Shipment" := PurchLine."Drop Shipment";
        "Entry Type" := "Entry Type"::Purchase;
        "Unit of Measure Code" := PurchLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := PurchLine."Qty. per Unit of Measure";
        "Qty. Rounding Precision" := PurchLine."Qty. Rounding Precision";
        "Qty. Rounding Precision (Base)" := PurchLine."Qty. Rounding Precision (Base)";
        "Item Reference No." := PurchLine."Item Reference No.";
        "Document Line No." := PurchLine."Line No.";
        "Unit Cost" := PurchLine."Unit Cost (LCY)";
        "Unit Cost (ACY)" := PurchLine."Unit Cost";
        "Value Entry Type" := "Value Entry Type"::"Direct Cost";
        "Source Type" := "Source Type"::Vendor;
        "Source No." := PurchLine."Buy-from Vendor No.";
        "Price Calculation Method" := PurchLine."Price Calculation Method";
        "Invoice-to Source No." := PurchLine."Pay-to Vendor No.";
        "Purchasing Code" := PurchLine."Purchasing Code";
        "Indirect Cost %" := PurchLine."Indirect Cost %";
        "Overhead Rate" := PurchLine."Overhead Rate";
        "Return Reason Code" := PurchLine."Return Reason Code";

        OnAfterCopyItemJnlLineFromPurchLine(Rec, PurchLine);
    end;

#if not CLEAN25
    [Obsolete('Moved to table Service Header', '25.0')]
    /// <summary>
    /// Copies fields from the provided service header record to the current item journal line.
    /// </summary>
    /// <param name="ServiceHeader">Service header to copy from.</param>
    procedure CopyFromServHeader(ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
        ServiceHeader.CopyToItemJnlLine(Rec);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to table Service Line', '25.0')]
    /// <summary>
    /// Copies fields from the provided service line record to the current item journal line.
    /// </summary>
    /// <param name="ServiceLine">Service line to copy from.</param>
    procedure CopyFromServLine(ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
        ServiceLine.CopyToItemJnlLine(Rec);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to table Service Shipment Header', '25.0')]
    /// <summary>
    /// Copies fields from the provided service shipment header record to the current item journal line.
    /// </summary>
    /// <param name="ServShptHeader">Service shipment header to copy from.</param>
    procedure CopyFromServShptHeader(ServShptHeader: Record Microsoft.Service.History."Service Shipment Header")
    begin
        ServShptHeader.CopyToItemJnlLine(Rec);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to table Service Shipment Line', '25.0')]
    /// <summary>
    /// Copies fields from the provided service shipment line record to the current item journal line.
    /// </summary>
    /// <param name="ServShptLine">Service shipment line to copy from.</param>
    procedure CopyFromServShptLine(ServShptLine: Record Microsoft.Service.History."Service Shipment Line")
    begin
        ServShptLine.CopyToItemJnlLine(Rec);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to table Service Shipment Line', '25.0')]
    /// <summary>
    /// Copies fields from the provided service shipment line record to the current item journal line.
    /// </summary>
    /// <param name="ServShptLine">Service shipment line to copy from.</param>
    procedure CopyFromServShptLineUndo(ServShptLine: Record Microsoft.Service.History."Service Shipment Line")
    begin
        ServShptLine.CopyToItemJnlLineUndo(Rec);
    end;
#endif

    /// <summary>
    /// Copies fields from the provided job journal line record to the current item journal line.
    /// </summary>
    /// <param name="JobJnlLine">Job journal line to copy from.</param>
    procedure CopyFromJobJnlLine(JobJnlLine: Record "Job Journal Line")
    begin
        "Line No." := JobJnlLine."Line No.";
        "Item No." := JobJnlLine."No.";
        "Posting Date" := JobJnlLine."Posting Date";
        "Document Date" := JobJnlLine."Document Date";
        "Document No." := JobJnlLine."Document No.";
        "External Document No." := JobJnlLine."External Document No.";
        Description := JobJnlLine.Description;
        "Location Code" := JobJnlLine."Location Code";
        "Applies-to Entry" := JobJnlLine."Applies-to Entry";
        "Applies-from Entry" := JobJnlLine."Applies-from Entry";
        "Shortcut Dimension 1 Code" := JobJnlLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := JobJnlLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := JobJnlLine."Dimension Set ID";
        "Country/Region Code" := JobJnlLine."Country/Region Code";
        "Entry Type" := "Entry Type"::"Negative Adjmt.";
        "Source Code" := JobJnlLine."Source Code";
        "Gen. Bus. Posting Group" := JobJnlLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := JobJnlLine."Gen. Prod. Posting Group";
        "Posting No. Series" := JobJnlLine."Posting No. Series";
        "Variant Code" := JobJnlLine."Variant Code";
        "Bin Code" := JobJnlLine."Bin Code";
        "Unit of Measure Code" := JobJnlLine."Unit of Measure Code";
        "Reason Code" := JobJnlLine."Reason Code";
        "Transaction Type" := JobJnlLine."Transaction Type";
        "Transport Method" := JobJnlLine."Transport Method";
        "Entry/Exit Point" := JobJnlLine."Entry/Exit Point";
        Area := JobJnlLine.Area;
        "Transaction Specification" := JobJnlLine."Transaction Specification";
        "Invoiced Quantity" := JobJnlLine.Quantity;
        "Invoiced Qty. (Base)" := JobJnlLine."Quantity (Base)";
        "Source Currency Code" := JobJnlLine."Source Currency Code";
        Quantity := JobJnlLine.Quantity;
        "Quantity (Base)" := JobJnlLine."Quantity (Base)";
        "Qty. per Unit of Measure" := JobJnlLine."Qty. per Unit of Measure";
        "Qty. Rounding Precision" := JobJnlLine."Qty. Rounding Precision";
        "Qty. Rounding Precision (Base)" := JobJnlLine."Qty. Rounding Precision (Base)";
        "Unit Cost" := JobJnlLine."Unit Cost (LCY)";
        "Unit Cost (ACY)" := JobJnlLine."Unit Cost";
        Amount := JobJnlLine."Total Cost (LCY)";
        "Amount (ACY)" := JobJnlLine."Total Cost";
        "Value Entry Type" := "Value Entry Type"::"Direct Cost";
        "Job No." := JobJnlLine."Job No.";
        "Job Task No." := JobJnlLine."Job Task No.";
        "Shpt. Method Code" := JobJnlLine."Shpt. Method Code";

        OnAfterCopyItemJnlLineFromJobJnlLine(Rec, JobJnlLine);
    end;

    local procedure ReadGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;

        OnAfterReadGLSetup(GLSetup);
    end;

    /// <summary>
    /// Retrieves and sets the global UnitCost variable for an item journal line.
    /// </summary>
    /// <remarks>
    /// Global UnitCost variable is used to set and calculate unit cost and unit amount in various places.
    /// </remarks>
    protected procedure RetrieveCosts()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveCosts(Rec, UnitCost, IsHandled);
        if IsHandled then
            exit;

        if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
           ("Item Charge No." <> '')
        then
            exit;

        ReadGLSetup();
        GetItem();

        UnitCost := FindUnitCost();

        OnRetrieveCostsOnAfterSetUnitCost(Rec, UnitCost, Item);

        if "Entry Type" = "Entry Type"::Transfer then
            UnitCost := 0
        else
            if Item."Costing Method" <> Item."Costing Method"::Standard then
                UnitCost := Round(UnitCost, GLSetup."Unit-Amount Rounding Precision");
    end;

    local procedure FindUnitCost() UnitCost: Decimal
    var
        SKU: Record "Stockkeeping Unit";
        InventorySetup: Record "Inventory Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindUnitCost(Rec, UnitCost, IsHandled);
        if IsHandled then
            exit;

        InventorySetup.Get();
        if InventorySetup."Average Cost Calc. Type" = InventorySetup."Average Cost Calc. Type"::Item then
            UnitCost := Item."Unit Cost"
        else
            if SKU.Get("Location Code", "Item No.", "Variant Code") then
                UnitCost := SKU."Unit Cost"
            else
                UnitCost := Item."Unit Cost";
    end;

    local procedure CalcUnitCost(ItemLedgEntry: Record "Item Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        UnitCost2: Decimal;
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        if CostCalcMgt.CanIncNonInvCostIntoProductionItem() then begin
            ValueEntry.CalcSums("Cost Amount (Expected)", "Cost Amount (Actual)", "Cost Amount (Non-Invtbl.)");
            UnitCost2 := (ValueEntry."Cost Amount (Expected)" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Non-Invtbl.)") / ItemLedgEntry.Quantity
        end else begin
            ValueEntry.CalcSums("Cost Amount (Expected)", "Cost Amount (Actual)");
            UnitCost2 := (ValueEntry."Cost Amount (Expected)" + ValueEntry."Cost Amount (Actual)") / ItemLedgEntry.Quantity;
        end;

        exit(Abs(UnitCost2 * "Qty. per Unit of Measure"));
    end;

    local procedure ClearSingleAndRolledUpCosts()
    begin
        "Single-Level Material Cost" := "Unit Cost (Revalued)";
        "Single-Level Capacity Cost" := 0;
        "Single-Level Subcontrd. Cost" := 0;
        "Single-Level Cap. Ovhd Cost" := 0;
        "Single-Level Mfg. Ovhd Cost" := 0;
        "Single-Lvl Mat. Non-Invt. Cost" := 0;
        "Rolled-up Material Cost" := "Unit Cost (Revalued)";
        "Rolled-up Capacity Cost" := 0;
        "Rolled-up Subcontracted Cost" := 0;
        "Rolled-up Mfg. Ovhd Cost" := 0;
        "Rolled-up Cap. Overhead Cost" := 0;
        "Rolled-up Mat. Non-Invt. Cost" := 0;
    end;

    /// <summary>
    /// Determines if time related fields of the current item journal line record are empty.
    /// </summary>
    /// <remarks>
    /// Time related fields consists of setup time, run time, and stop time fields.
    /// </remarks>
    /// <returns>True if time related fields are empty, otherwise false.</returns>
    procedure TimeIsEmpty() Result: Boolean
    begin
        OnTimeIsEmpty(Rec, Result);
    end;

    /// <summary>
    /// Determines if only the stop time field of the current item journal line record is set.
    /// </summary>
    /// <remarks>
    /// In order to return true, setup time and run time fields must not be set.
    /// </remarks>
    /// <returns>True if only the stop time is set, otherwise false.</returns>
    procedure OnlyStopTime() Result: Boolean
    begin
        OnOnlyStopTime(Rec, Result);
    end;

    local procedure GetOrderTypeProduction() OrderType: Enum "Inventory Order Type"
    begin
        OnGetOrderTypeProduction(OrderType);

    end;

    local procedure GetOrderTypeService() OrderType: Enum "Inventory Order Type"
    begin
        OnGetOrderTypeService(OrderType);
    end;

    /// <summary>
    /// Generates a unique identifier text for a item journal line record which is used for item tracking.
    /// </summary>
    /// <returns>Generated text.</returns>
    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
          ItemTrackingMgt.ComposeRowID(Database::"Item Journal Line", "Entry Type".AsInteger(),
            "Journal Template Name", "Journal Batch Name", 0, "Line No."));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);

        OnAfterGetLocation(Location, LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if BinCode = '' then
            Clear(Bin)
        else
            if (Bin.Code <> BinCode) or (Bin."Location Code" <> LocationCode) then
                Bin.Get(LocationCode, BinCode);
    end;

    /// <summary>
    /// Returns a formatted text that represents the source of an item journal line record.
    /// </summary>
    /// <remarks>
    /// The resulting text consists of the journal template name, journal batch name and item number separated by space.
    /// </remarks>
    /// <returns>Formatted text of the journal template name, journal batch name and item number separated by space.</returns>
    procedure GetSourceCaption(): Text
    begin
        exit(StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Item No."));
    end;

    /// <summary>
    /// Initializes the reservation entries from the item journal line.
    /// </summary>
    /// <param name="ReservEntry">Return value: Initialized reservation entry.</param>
    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(Database::"Item Journal Line", "Entry Type".AsInteger(), "Journal Template Name", "Line No.", "Journal Batch Name", 0);
        ReservEntry.SetItemData("Item No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        ReservEntry."Expected Receipt Date" := "Posting Date";
        ReservEntry."Shipment Date" := "Posting Date";

        OnAfterSetReservationEntry(ReservEntry, Rec);
    end;

    /// <summary>
    /// Filters reservation entry from the item journal line.
    /// </summary>
    /// <param name="ReservEntry">Return value: Filtered reservation entry.</param>
    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        SetReservEntrySourceFilters(ReservEntry, false);
        ReservEntry.SetTrackingFilterFromItemJnlLine(Rec);

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    procedure SetReservEntrySourceFilters(var ReservEntry: Record "Reservation Entry"; SourceKey: Boolean)
    begin
        if IsSourceSales() then
            ReservEntry.SetSourceFilter(Database::"Item Journal Line", "Entry Type".AsInteger(), "Document No.", "Document Line No.", SourceKey)
        else
            ReservEntry.SetSourceFilter(Database::"Item Journal Line", "Entry Type".AsInteger(), "Journal Template Name", "Line No.", SourceKey);
        ReservEntry.SetSourceFilter("Journal Batch Name", 0);
        OnAfterSetReservEntrySourceFilters(ReservEntry, SourceKey);
    end;

    internal procedure IsSourceSales(): Boolean
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        if ("Entry Type" = Rec."Entry Type"::"Sale") then begin
            SourceCodeSetup.SetLoadFields(Sales);
            SourceCodeSetup.Get();
            exit("Source Code" = SourceCodeSetup.Sales);
        end;
    end;

    /// <summary>
    /// Checks if reservation entry exists for the item journal line.
    /// </summary>
    /// <returns>True if reservation entry exists, otherwise false.</returns>
    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        ReservEntry.ClearTrackingFilter();
        exit(not ReservEntry.IsEmpty);
    end;

    local procedure CheckPlanningAssignment()
    begin
        if ("Quantity (Base)" <> 0) and ("Item No." <> '') and ("Posting Date" <> 0D) and
           ("Entry Type" in ["Entry Type"::"Negative Adjmt.", "Entry Type"::"Positive Adjmt.", "Entry Type"::Transfer])
        then begin
            if ("Entry Type" = "Entry Type"::Transfer) and ("Location Code" = "New Location Code") then
                exit;

            ItemJnlLineReserve.AssignForPlanning(Rec);
        end;
    end;

    /// <summary>
    /// Performs a lookup for the item of an item journal line based on its entry type.
    /// </summary>
    procedure LookupItemNo()
    var
        ItemList: Page "Item List";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupItemNo(Rec, IsHandled);
        if IsHandled then
            exit;

        ItemList.LookupMode := true;
        if "Item No." <> '' then
            if Item.Get("Item No.") then
                ItemList.SetRecord(Item);
        if ItemList.RunModal() = ACTION::LookupOK then begin
            ItemList.GetRecord(Item);
            Validate("Item No.", Item."No.");
        end;
    end;

    /// <summary>
    /// Updates the unit amount for an item journal line record based on various factors such as the item's
    /// indirect cost percentage, overhead rate, quantity per unit of measure, and entry type.
    /// </summary>
    procedure RecalculateUnitAmount()
    var
        ItemJnlLine1: Record "Item Journal Line";
        PriceType: Enum "Price Type";
    begin
        GetItem();

        if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
           ("Item Charge No." <> '')
        then begin
            "Indirect Cost %" := 0;
            "Overhead Rate" := 0;
        end else begin
            "Indirect Cost %" := Item."Indirect Cost %";
            "Overhead Rate" := Item."Overhead Rate";
        end;

        "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
        OnRecalculateUnitAmountOnAfterCalcQtyPerUnitOfMeasure(Rec, xRec);
        GetUnitAmount(FieldNo("Unit of Measure Code"));

        ReadGLSetup();

        UpdateAmount();

        case "Entry Type" of
            "Entry Type"::Purchase:
                begin
                    ItemJnlLine1.Copy(Rec);
                    ItemJnlLine1.ApplyPrice(PriceType::Purchase, FieldNo("Unit of Measure Code"));
                    "Unit Cost" := Round(ItemJnlLine1."Unit Amount" * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                end;
            "Entry Type"::Sale:
                "Unit Cost" := Round(UnitCost * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
            "Entry Type"::"Positive Adjmt.":
                "Unit Cost" :=
                  Round(
                    "Unit Amount" * (1 + "Indirect Cost %" / 100), GLSetup."Unit-Amount Rounding Precision") +
                  "Overhead Rate" * "Qty. per Unit of Measure";
            "Entry Type"::"Negative Adjmt.":
                if not "Phys. Inventory" then
                    "Unit Cost" := UnitCost * "Qty. per Unit of Measure";
        end;

        if "Entry Type" in ["Entry Type"::Purchase, "Entry Type"::"Positive Adjmt."] then
            if Item."Costing Method" = Item."Costing Method"::Standard then
                "Unit Cost" := Round(UnitCost * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");

        OnAfterRecalculateUnitAmount(Rec, xRec, CurrFieldNo);
    end;

    /// <summary>
    /// Determines whether an item journal line represents a reclassification.
    /// </summary>
    /// <param name="ItemJnlLine">Item journal line to check.</param>
    /// <returns>True if item journal line represents a reclassification, otherwise false.</returns>
    procedure IsReclass(ItemJnlLine: Record "Item Journal Line"): Boolean
    begin
        if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer) and
           ((ItemJnlLine."Order Type" <> ItemJnlLine."Order Type"::Transfer) or (ItemJnlLine."Order No." = ''))
        then
            exit(true);
        exit(false);
    end;

    /// <summary>
    /// Opens a page for editing dimensions for the item journal line.
    /// </summary>
    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec, xRec);
    end;

    /// <summary>
    /// Opens a page for editing the dimension set associated with a reclassification in the current item journal line.
    /// </summary>
    procedure ShowReclasDimensions()
    begin
        DimMgt.EditReclasDimensionSet(
          "Dimension Set ID", "New Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."),
          "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "New Shortcut Dimension 1 Code", "New Shortcut Dimension 2 Code");
    end;

    /// <summary>
    /// Toggles the visibility of item journal lines based on whether they have associated error messages.
    /// </summary>
    /// <remarks>
    /// When the ShowAllLinesEnabled flag is true, all item journal lines are shown.
    /// When the flag is false, only item journal lines with associated error messages are shown.
    /// </remarks>
    /// <param name="ShowAllLinesEnabled">Return value: Flag to enable or disable item journal lines with errors.</param>
    procedure SwitchLinesWithErrorsFilter(var ShowAllLinesEnabled: Boolean)
    var
        TempErrorMessage: Record "Error Message" temporary;
        ItemJournalErrorsMgt: Codeunit "Item Journal Errors Mgt.";
    begin
        if ShowAllLinesEnabled then begin
            MarkedOnly(false);
            ShowAllLinesEnabled := false;
        end else begin
            ItemJournalErrorsMgt.GetErrorMessages(TempErrorMessage);
            if TempErrorMessage.FindSet() then
                repeat
                    if Rec.Get(TempErrorMessage."Context Record ID") then
                        Rec.Mark(true)
                until TempErrorMessage.Next() = 0;
            MarkedOnly(true);
            ShowAllLinesEnabled := true;
        end;
    end;

    local procedure RevaluationPerEntryAllowed(ItemNo: Code[20]) Result: Boolean
    var
        ValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRevaluationPerEntryAllowed(Rec, ItemNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GetItem();
        if Item."Costing Method" <> Item."Costing Method"::Average then
            exit(true);

        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
        ValueEntry.SetRange("Partial Revaluation", true);
        exit(ValueEntry.IsEmpty);
    end;

    /// <summary>
    /// Clears the tracking information (serial, lot and package number) of an item journal line.
    /// </summary>
    procedure ClearTracking()
    begin
        "Serial No." := '';
        "Lot No." := '';

        OnAfterClearTracking(Rec);
    end;

    /// <summary>
    /// Clears the expiration and warranty dates of the item journal line.
    /// </summary>
    procedure ClearDates()
    begin
        "Expiration Date" := 0D;
        "Warranty Date" := 0D;
    end;

    /// <summary>
    /// Copies tracking information (serial, lot and package number) from a reservation entry to an item journal line.
    /// </summary>
    /// <param name="ReservationEntry">Reservation entry to copy tracking information from.</param>
    procedure CopyTrackingFromReservEntry(ReservationEntry: Record "Reservation Entry")
    begin
        "Serial No." := ReservationEntry."Serial No.";
        "Lot No." := ReservationEntry."Lot No.";

        OnAfterCopyTrackingFromReservEntry(Rec, ReservationEntry);
    end;

    /// <summary>
    /// Copies tracking information (serial, lot and package number) from a item ledger entry to an item journal line.
    /// </summary>
    /// <param name="ItemLedgEntry">Item ledger entry to copy tracking information from.</param>
    procedure CopyTrackingFromItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgEntry."Serial No.";
        "Lot No." := ItemLedgEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    /// <summary>
    /// Copies tracking information (serial, lot and package number) from a tracking specification to an item journal line.
    /// </summary>
    /// <param name="TrackingSpecification">Tracking specification to copy tracking information from.</param>
    procedure CopyTrackingFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";

        OnAfterCopyTrackingFromSpec(Rec, TrackingSpecification);
    end;

    /// <summary>
    /// Copies new tracking information (new serial number and new lot number) from a tracking specification
    /// to an item journal line.
    /// </summary>
    /// <param name="TrackingSpecification">Tracking specification to copy tracking information from.</param>
    procedure CopyNewTrackingFromNewSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "New Serial No." := TrackingSpecification."New Serial No.";
        "New Lot No." := TrackingSpecification."New Lot No.";

        OnAfterCopyNewTrackingFromNewSpec(Rec, TrackingSpecification);
    end;

    /// <summary>
    /// Copies tracking information (serial, lot and package number) from a item ledger entry to an item journal line.
    /// </summary>
    /// <param name="ItemLedgEntry">Item ledger entry to copy tracking information from.</param>
    procedure CopyNewTrackingFromOldItemLedgerEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        "New Serial No." := ItemLedgEntry."Serial No.";
        "New Lot No." := ItemLedgEntry."Lot No.";

        OnAfterCopyNewTrackingFromOldItemLedgerEntry(Rec, ItemLedgEntry);
    end;

    /// <summary>
    /// Set tracking information (serial, lot and package number) filter from a item ledger entry to an item journal line.
    /// </summary>
    /// <param name="ItemledgerEntry">Item ledger entry to copy tracking information from.</param>
    procedure SetTrackingFilterFromItemLedgerEntry(ItemledgerEntry: Record "Item Ledger Entry")
    begin
        SetRange("Serial No.", ItemLedgerEntry."Serial No.");
        SetRange("Lot No.", ItemLedgerEntry."Lot No.");

        OnAfterSetTrackingFilterFromItemLedgerEntry(Rec, ItemLedgerEntry);
    end;

    /// <summary>
    /// Determines whether tracking information exists for an item journal line.
    /// </summary>
    /// <returns>True if the tracking exists, otherwise false.</returns>
    procedure TrackingExists() IsTrackingExist: Boolean
    begin
        IsTrackingExist := ("Serial No." <> '') or ("Lot No." <> '');

        OnAfterTrackingExists(Rec, IsTrackingExist);
    end;

    /// <summary>
    /// Determines whether the current item journal line has the same tracking information as the provided item journal line.
    /// </summary>
    /// <param name="ItemJournalLine">Item journal line to check the tracking information from.</param>
    /// <returns>True if the tracking information is the same, otherwise false.</returns>
    procedure HasSameTracking(ItemJournalLine: Record "Item Journal Line"): Boolean
    begin
        exit(
          (Rec."Serial No." = ItemJournalLine."Serial No.") and
          (Rec."Lot No." = ItemJournalLine."Lot No.") and
          (Rec."Package No." = ItemJournalLine."Package No."));
    end;

    /// <summary>
    /// Determines whether the current item journal line has the same serial, lot and package numbers as the new serial, lot and package numbers.
    /// </summary>
    /// <returns>True if the tracking information is the same, otherwise false.</returns>
    procedure HasSameNewTracking() IsSameTracking: Boolean
    begin
        IsSameTracking := ("Serial No." = "New Serial No.") and ("Lot No." = "New Lot No.");

        OnAfterHasSameNewTracking(Rec, IsSameTracking);
    end;

    /// <summary>
    /// Tests if the item number, variant code and location code in an item journal line are the same as the provided values.
    /// </summary>
    /// <param name="ItemNo">Item number to check.</param>
    /// <param name="VariantCode">Variant code to check.</param>
    /// <param name="LocationCode">Location code to check.</param>
    procedure TestItemFields(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestItemFields(Rec, ItemNo, VariantCode, LocationCode, IsHandled);
        if IsHandled then
            exit;

        TestField("Item No.", ItemNo);
        TestField("Variant Code", VariantCode);
        TestField("Location Code", LocationCode);
    end;

    /// <summary>
    /// Checks if the provided item is blocked and raises an error message if it is.
    /// </summary>
    /// <param name="Item">Item to check.</param>
    procedure DisplayErrorIfItemIsBlocked(Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDisplayErrorIfItemIsBlocked(Item, Rec, IsHandled);
        if IsHandled then
            exit;

        if Item.Blocked then
            Error(BlockedErr, Item.TableCaption(), Item."No.", Item.FieldCaption(Blocked));

        if "Item Charge No." <> '' then
            exit;

        case "Entry Type" of
            "Entry Type"::Purchase:
                if Item."Purchasing Blocked" and
                   not ("Document Type" in ["Document Type"::"Purchase Return Shipment", "Document Type"::"Purchase Credit Memo"])
                   and ("Value Entry Type" <> "Value Entry Type"::Revaluation)
                then
                    Error(PurchasingBlockedErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Purchasing Blocked"));
            "Entry Type"::Sale:
                case "Order Type" of
                    GetOrderTypeService():
                        if Item."Service Blocked" and
                           not ("Document Type" in ["Document Type"::"Service Credit Memo"])
                        then
                            Error(ServiceSalesBlockedErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Service Blocked"));
                    else
                        if Item."Sales Blocked" and
                           not ("Document Type" in ["Document Type"::"Sales Return Receipt", "Document Type"::"Sales Credit Memo"])
                        then
                            Error(SalesBlockedErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Sales Blocked"));
                end;
        end;

        OnAfterDisplayErrorIfItemIsBlocked(Item, Rec);
    end;

    /// <summary>
    /// Checks if the provided item variant is blocked and raises an error message if it is.
    /// </summary>
    /// <param name="ItemVariant">Item variant to check.</param>
    procedure DisplayErrorIfItemVariantIsBlocked(ItemVariant: Record "Item Variant")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDisplayErrorIfItemVariantIsBlocked(ItemVariant, Rec, IsHandled);
        if IsHandled then
            exit;

        if ItemVariant.Blocked then
            Error(BlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemVariantPrimaryKeyLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption(Blocked));

        case Rec."Entry Type" of
            Rec."Entry Type"::Purchase:
                if ItemVariant."Purchasing Blocked" and not (Rec."Document Type" in [Rec."Document Type"::"Purchase Return Shipment", Rec."Document Type"::"Purchase Credit Memo"]) then
                    Error(PurchasingBlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemVariantPrimaryKeyLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption("Purchasing Blocked"));
            "Entry Type"::Sale:
                case "Order Type" of
                    GetOrderTypeService():
                        if ItemVariant."Service Blocked" and not (Rec."Document Type" in [Rec."Document Type"::"Service Credit Memo"]) then
                            Error(ServiceSalesBlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemVariantPrimaryKeyLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption("Service Blocked"));
                    else
                        if ItemVariant."Sales Blocked" and not (Rec."Document Type" in [Rec."Document Type"::"Sales Return Receipt", Rec."Document Type"::"Sales Credit Memo"]) then
                            Error(SalesBlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemVariantPrimaryKeyLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption("Sales Blocked"));
                end;
        end;

        OnAfterDisplayErrorIfItemVariantIsBlocked(ItemVariant, Rec);
    end;

    /// <summary>
    /// Determines whether an item journal line represents a purchase return.
    /// </summary>
    /// <returns>True if an item journal line represents a purchase return, otherwise false.</returns>
    procedure IsPurchaseReturn(): Boolean
    begin
        exit(
          ("Document Type" in ["Document Type"::"Purchase Credit Memo",
                               "Document Type"::"Purchase Return Shipment",
                               "Document Type"::"Purchase Invoice",
                               "Document Type"::"Purchase Receipt"]) and
          (Quantity < 0));
    end;

    /// <summary>
    /// Determines whether the current item journal line record was opened from a batch.
    /// </summary>
    /// <remarks>
    /// It checks the filters applied to the journal batch name and journal template name fields.
    /// </remarks>
    /// <returns>True if the current item journal line record was opened from a batch, otherwise false.</returns>
    procedure IsOpenedFromBatch(): Boolean
    var
        ItemJournalBatch: Record "Item Journal Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if TemplateFilter <> '' then
                ItemJournalBatch.SetFilter("Journal Template Name", TemplateFilter);
            ItemJournalBatch.SetFilter(Name, BatchFilter);
            ItemJournalBatch.FindFirst();
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    /// <summary>
    /// Triggers the OnCheckItemJournalLinePostRestrictions event to check any additional restrictions
    /// before posting item journal line.
    /// </summary>
    procedure CheckItemJournalLineRestriction()
    begin
        OnCheckItemJournalLinePostRestrictions();
    end;

    local procedure CheckEntryType()
    begin
        OnAfterCheckEntryType(Rec);
    end;

    /// <summary>
    /// Tests if the tracking information (serial, lot and package number) in the item journal line is empty.
    /// </summary>
    procedure CheckTrackingIsEmpty()
    begin
        TestField("Serial No.", '');
        TestField("Lot No.", '');

        OnAfterCheckTrackingisEmpty(Rec);
    end;

    /// <summary>
    /// Tests if the new tracking information (new serial number and new lot number) in the item journal line is empty.
    /// </summary>
    procedure CheckNewTrackingIsEmpty()
    begin
        TestField("New Serial No.", '');
        TestField("New Lot No.", '');

        OnAfterCheckNewTrackingisEmpty(Rec);
    end;

    /// <summary>
    /// Tests if the tracking information (serial, lot and package number) in the item journal line is equal to the
    /// tracking information in the provided item ledger entry.
    /// </summary>
    /// <param name="ItemLedgerEntry">Item ledger entry to test the tracking information from.</param>
    procedure CheckTrackingEqualItemLedgEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        TestField("Lot No.", ItemLedgerEntry."Lot No.");
        TestField("Serial No.", ItemLedgerEntry."Serial No.");

        OnAfterCheckTrackingEqualItemLedgEntry(Rec, ItemLedgerEntry);
    end;

    /// <summary>
    /// Tests if the tracking information (serial, lot and package number) in the item journal line is equal to the
    /// tracking information in the provided tracking specifiation.
    /// </summary>
    /// <param name="TrackingSpecification">Tracking specification to test the tracking information from.</param>
    procedure CheckTrackingEqualTrackingSpecification(TrackingSpecification: Record "Tracking Specification")
    begin
        TestField("Lot No.", TrackingSpecification."Lot No.");
        TestField("Serial No.", TrackingSpecification."Serial No.");

        OnAfterCheckTrackingEqualTrackingSpecification(Rec, TrackingSpecification);
    end;

    /// <summary>
    /// Tests if the tracking information (serial, lot and package number) of the item journal line are filled if
    /// required by the item tracking setup.
    /// </summary>
    /// <param name="ItemTrackingSetup">Item tracking setup to use.</param>
    procedure CheckTrackingIfRequired(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Serial No. Required" then
            TestField("Serial No.");
        if ItemTrackingSetup."Lot No. Required" then
            TestField("Lot No.");

        OnAfterCheckTrackingIfRequired(Rec, ItemTrackingSetup);
    end;

    /// <summary>
    /// Tests if the new tracking information (new serial number and new lot number) of the item journal line are filled
    /// if required by the item tracking setup.
    /// </summary>
    /// <param name="ItemTrackingSetup">Item tracking setup to use.</param>
    procedure CheckNewTrackingIfRequired(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Serial No. Required" then
            TestField("New Serial No.");
        if ItemTrackingSetup."Lot No. Required" then
            TestField("New Lot No.");

        OnAfterCheckNewTrackingIfRequired(Rec, ItemTrackingSetup);
    end;

    /// <summary>
    /// Tests if the new tracking information (new serial number and new lot number) of the item journal line
    /// is required and not empty. If the tracking information is required and empty, an error message is raised.
    /// </summary>
    /// <param name="ItemTrackingSetup">Item tracking setup to use.</param>
    procedure CheckTrackingIfRequiredNotBlank(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Serial No. Required" and ("Serial No." = '') then
            Error(SerialNoRequiredErr, "Item No.");
        if ItemTrackingSetup."Lot No. Required" and ("Lot No." = '') then
            Error(LotNoRequiredErr, "Item No.");

        OnAfterCheckTrackingIfRequiredNotBlank(Rec, ItemTrackingSetup);
    end;

    /// <summary>
    /// Tests the type of the item journal line based on the type of the associated item.
    /// </summary>
    /// <remarks>
    /// It ensures that service items and non-inventoriable items are used correctly in item journal lines.
    /// </remarks>
    procedure ValidateTypeWithItemNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateTypeWithItemNo(Rec, Item, IsHandled);
        if IsHandled then
            exit;
        // Validate the item type when defining a relation with another table

        // Service is not a valid item type
        // i.e items of type service cannot be in a relation with another table
        if Item.IsServiceType() then
            Item.TestField(Type, Item.Type::Inventory);

        // Non-inventoriable item types are valid only for the following entry types
        if Item.IsNonInventoriableType() and not IsEntryTypeConsumption() then
            Item.TestField(Type, Item.Type::Inventory);
    end;

    local procedure IsEntryTypeConsumption() Result: Boolean
    begin
        OnAfterIsEntryTypeConsumption(Rec, Result);
    end;

    procedure IsEntryTypeOutput() Result: Boolean
    begin
        OnAfterIsEntryTypeOutput(Rec, Result);
    end;

    local procedure IsEntryTypeProduction() Result: Boolean
    begin
        OnAfterIsEntryTypeProduction(Rec, Result);
    end;

    local procedure IsOrderTypeAsmOrProd() Result: Boolean
    begin
        OnAfterIsOrderTypeAsmOrProd(Rec, Result);
    end;

    local procedure IsDocNoProdOrderNo() Result: Boolean
    begin
        OnAfterIsDocNoProdOrderNo(Rec, Result);
    end;

    /// <summary>
    /// Determines if the item journal line does not represent an internal warehouse movement.
    /// </summary>
    /// <returns>True if the item journal line does not represent an internal warehouse movement, otherwise false.</returns>
    procedure IsNotInternalWhseMovement(): Boolean
    begin
        exit(
          not (("Entry Type" = "Entry Type"::Transfer) and
               ("Location Code" = "New Location Code") and
               ("Dimension Set ID" = "New Dimension Set ID") and
               ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
               not Adjustment));
    end;

    /// <summary>
    /// Runs the inventory movement report for the item journal lines that have the same journal template name and
    /// journal batch name as the current item journal line.
    /// </summary>
    procedure PrintInventoryMovement()
    begin
        Rec.SetRange("Journal Template Name", Rec."Journal Template Name");
        Rec.SetRange("Journal Batch Name", Rec."Journal Batch Name");
        Report.RunModal(Report::"Inventory Movement", true, true, Rec);
    end;

    local procedure IsDefaultBin() Result: Boolean
    begin
        Result := Location."Bin Mandatory" and not Location."Directed Put-away and Pick";

        OnAfterIsDefaultBin(Location, Result);
    end;

    procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text) Result: Decimal
    begin
        Result := UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName);
        OnAfterCalcBaseQty(Rec, xRec, FromFieldName, Result);
    end;

    /// <summary>
    /// Initializes the dimensions for the item journal line if default dimensions are defined for the related entry.
    /// </summary>
    /// <param name="FieldNo">The field number for which to initialize the dimensions.</param>
    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        if not DimMgt.IsDefaultDimDefinedForTable(GetTableValuePair(FieldNo)) then
            exit;
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure CreateNewDimFromDefaultDim(FieldNo: Integer)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        SourceCode: Code[10];
    begin
        if not DimMgt.IsDefaultDimDefinedForTable(GetTableValuePair(FieldNo)) then
            exit;
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);

        SourceCode := "Source Code";
        if SourceCode = '' then
            if ItemJournalTemplate.Get("Journal Template Name") then
                SourceCode := ItemJournalTemplate."Source Code";

        "New Shortcut Dimension 1 Code" := '';
        "New Shortcut Dimension 2 Code" := '';
        "New Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCode,
            "New Shortcut Dimension 1 Code", "New Shortcut Dimension 2 Code", 0, 0);
        DimMgt.UpdateGlobalDimFromDimSetID("New Dimension Set ID", "New Shortcut Dimension 1 Code", "New Shortcut Dimension 2 Code");
    end;

    local procedure GetTableValuePair(FieldNo: Integer) TableValuePair: Dictionary of [Integer, Code[20]]
    begin
        case true of
            FieldNo = Rec.FieldNo("Item No."):
                TableValuePair.Add(Database::Item, Rec."Item No.");
            FieldNo = Rec.FieldNo("Salespers./Purch. Code"):
                TableValuePair.Add(Database::"Salesperson/Purchaser", Rec."Salespers./Purch. Code");
            FieldNo = Rec.FieldNo("Location Code"):
                TableValuePair.Add(Database::Location, Rec."Location Code");
            FieldNo = Rec.FieldNo("New Location Code"):
                TableValuePair.Add(Database::Location, Rec."New Location Code");
        end;

        OnAfterInitTableValuePair(Rec, TableValuePair, FieldNo);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Item, Rec."Item No.", FieldNo = Rec.FieldNo("Item No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", Rec."Salespers./Purch. Code", FieldNo = Rec.FieldNo("Salespers./Purch. Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code", FieldNo = Rec.FieldNo("Location Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."New Location Code", FieldNo = Rec.FieldNo("New Location Code"));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    /// <summary>
    /// Renumbers the document number of the current item journal line based on the number series specified in the
    /// associated item journal batch.
    /// </summary>
    /// <remarks>
    /// An error will be raised if there is an active filter on the document number field.
    /// A commit is used during renumbering.
    /// </remarks>
    procedure RenumberDocumentNo()
    var
        ItemJnlLine2: Record "Item Journal Line";
        NoSeries: Codeunit "No. Series";
        DocNo: Code[20];
        FirstDocNo: Code[20];
        FirstTempDocNo: Code[20];
        LastTempDocNo: Code[20];
    begin
        if SkipRenumberDocumentNo() then
            exit;

        ItemJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        ItemJnlBatch.TestField("No. Series");

        if GetFilter("Document No.") <> '' then
            Error(DocNoFilterErr);
        FirstDocNo := NoSeries.PeekNextNo(ItemJnlBatch."No. Series", "Posting Date");
        FirstTempDocNo := GetTempRenumberDocumentNo();
        // step1 - renumber to non-existing document number
        DocNo := FirstTempDocNo;
        ItemJnlLine2 := Rec;
        ItemJnlLine2.Reset();
        RenumberDocNoOnLines(DocNo, ItemJnlLine2);
        LastTempDocNo := DocNo;

        // step2 - renumber to real document number (within Filter)
        DocNo := FirstDocNo;
        ItemJnlLine2.CopyFilters(Rec);
        ItemJnlLine2 := Rec;
        RenumberDocNoOnLines(DocNo, ItemJnlLine2);

        // step3 - renumber to real document number (outside filter)
        DocNo := IncStr(DocNo);
        ItemJnlLine2.Reset();
        ItemJnlLine2.SetRange("Document No.", FirstTempDocNo, LastTempDocNo);
        RenumberDocNoOnLines(DocNo, ItemJnlLine2);

        if Get("Journal Template Name", "Journal Batch Name", "Line No.") then;
    end;

    local procedure GetTempRenumberDocumentNo(): Code[20]
    begin
        exit('RENUMBERED-000000001');
    end;

    local procedure SkipRenumberDocumentNo() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSkipRenumberDocumentNo(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(GuiAllowed() and not DIALOG.Confirm(StrSubstNo(RenumberDocNoQst, ProductName.Short()), true));
    end;

    local procedure RenumberDocNoOnLines(var DocNo: Code[20]; var ItemJnlLine2: Record "Item Journal Line")
    var
        LastItemJnlLine: Record "Item Journal Line";
        ItemJnlLine3: Record "Item Journal Line";
        NoSeries: Codeunit "No. Series";
        FirstDocNo: Code[20];
        TempFirstDocNo: Code[20];
        First: Boolean;
        IsHandled: Boolean;
        PrevPostingDate: Date;
    begin
        IsHandled := false;
        OnBeforeRenumberDocNoOnLines(DocNo, ItemJnlLine2, IsHandled);
        if IsHandled then
            exit;

        FirstDocNo := DocNo;
        ItemJnlLine2.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Document No.");
        ItemJnlLine2.SetRange("Journal Template Name", ItemJnlLine2."Journal Template Name");
        ItemJnlLine2.SetRange("Journal Batch Name", ItemJnlLine2."Journal Batch Name");
        LastItemJnlLine.Init();
        First := true;
        if ItemJnlLine2.FindSet() then
            repeat
                if ((FirstDocNo <> GetTempRenumberDocumentNo()) and (ItemJnlLine2.GetFilter("Document No.") = '')) then begin
                    Commit();
                    ItemJnlBatch.Get(ItemJnlLine2."Journal Template Name", ItemJnlLine2."Journal Batch Name");
                    TempFirstDocNo := NoSeries.PeekNextNo(ItemJnlBatch."No. Series", ItemJnlLine2."Posting Date");
                    if (FirstDocNo <> TempFirstDocNo) and (FirstDocNo <> IncStr(TempFirstDocNo)) then begin
                        DocNo := TempFirstDocNo;
                        FirstDocNo := DocNo;
                        First := true;
                    end;
                end;
                if ItemJnlLine2."Document No." = FirstDocNo then
                    exit;
                if not First and
                    ((ItemJnlLine2."Posting Date" <> PrevPostingDate) or
                    (ItemJnlLine2."Document No." = '')) and
                    not LastItemJnlLine.EmptyLine()
                then
                    DocNo := IncStr(DocNo);
                PrevPostingDate := ItemJnlLine2."Posting Date";
                ItemJnlLine3.Get(ItemJnlLine2."Journal Template Name", ItemJnlLine2."Journal Batch Name", ItemJnlLine2."Line No.");
                ItemJnlLine3."Document No." := DocNo;
                ItemJnlLine3.Modify();
                First := false;
                LastItemJnlLine := ItemJnlLine2;
            until ItemJnlLine2.Next() = 0;

        OnAfterRenumberDocNoOnLines(DocNo, ItemJnlLine2);
    end;

    internal procedure CreateItemTrackingLines(UpdateTracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.Copy(Rec);
        ItemJnlLineReserve.CreateItemTracking(ItemJournalLine);
        if UpdateTracking then
            UpdateItemTracking(ItemJournalLine);
    end;

    internal procedure UpdateItemTracking(var ItemJournalLine: Record "Item Journal Line")
    var
        TempItemJournalLine: Record "Item Journal Line" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        SingleItemTrackingExists: Boolean;
    begin
        ItemJournalLine.Find();
        TempItemJournalLine := ItemJournalLine;

        if ItemJournalLine.GetItemTracking(TempTrackingSpecification) then
            if TempTrackingSpecification.Count() = 1 then begin
                SingleItemTrackingExists := true;
                ItemJournalLine.CopyTrackingFromSpec(TempTrackingSpecification);
                ItemJournalLine."Expiration Date" := TempTrackingSpecification."Expiration Date";
                ItemJournalLine."Warranty Date" := TempTrackingSpecification."Warranty Date";
            end;

        if not SingleItemTrackingExists then begin
            ItemJournalLine.ClearTracking();
            ItemJournalLine.ClearDates();
        end;

        if not ItemJournalLine.HasSameTracking(TempItemJournalLine) then
            ItemJournalLine.Modify();
    end;

    local procedure IsItemTrackingEnabledInBatch(): Boolean
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        if ItemJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
            exit(ItemJournalBatch."Item Tracking on Lines");

        exit(false);
    end;

    local procedure CheckItemTracking(CalledByFieldNo: Integer)
    var
        FieldCap: Text;
        IsHandled: Boolean;
    begin
        OnBeforeCheckItemTracking(Rec, IsHandled);
        if IsHandled then
            exit;

        if not IsItemTrackingEnabledInBatch() then begin
            ClearTracking();
            ClearDates();
            exit;
        end;

        case CalledByFieldNo of
            FieldNo("Serial No."):
                begin
                    CheckSerialNoQty();
                    if "Serial No." <> '' then
                        if HasItemTracking() then
                            FieldCap := FieldCaption("Serial No.");
                end;
            FieldNo("Lot No."):
                if "Lot No." <> '' then
                    if HasItemTracking() then
                        FieldCap := FieldCaption("Lot No.");
            FieldNo("Package No."):
                if "Package No." <> '' then
                    if HasItemTracking() then
                        FieldCap := FieldCaption("Package No.");
            FieldNo("Warranty Date"):
                if "Warranty Date" <> 0D then
                    if HasItemTracking() then
                        FieldCap := FieldCaption("Warranty Date");
            FieldNo("Expiration Date"):
                if "Expiration Date" <> 0D then
                    if HasItemTracking() then
                        FieldCap := FieldCaption("Expiration Date");
        end;

        if FieldCap <> '' then
            Error(ItemTrackingExistsErr, FieldCap);
    end;

    local procedure HasItemTracking(): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        SetReservationFilters(ReservationEntry);
        ReservationEntry.ClearTrackingFilter();
        exit(not ReservationEntry.IsEmpty());
    end;

    internal procedure GetItemTracking(var TempTrackingSpecification: Record "Tracking Specification" temporary): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        SetReservationFilters(ReservationEntry);
        ReservationEntry.ClearTrackingFilter();
        exit(ItemTrackingManagement.SumUpItemTracking(ReservationEntry, TempTrackingSpecification, false, true));
    end;

    /// <summary>
    /// Opens the item tracking summary page to update the tracking information for an item journal line
    /// based on the specified tracking type.
    /// </summary>
    /// <param name="TrackingType">Item tracking type on which tracking information should be assigned.</param>
    procedure LookUpTrackingSummary(TrackingType: Enum "Item Tracking Type")
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingDataCollection: Codeunit "Item Tracking Data Collection";
        Math: Codeunit "Math";
    begin
        ItemJnlLineReserve.InitFromItemJnlLine(TempTrackingSpecification, Rec);
        GetItem();
        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingDataCollection.SetCurrentBinAndItemTrkgCode('', ItemTrackingCode);
        ItemTrackingDataCollection.AssistEditTrackingNo(
            TempTrackingSpecification, not IsInbound(), Math.Sign(Signed(Quantity)),
            TrackingType, Quantity);

        case TrackingType of
            TrackingType::"Serial No.":
                if TempTrackingSpecification."Serial No." <> '' then begin
                    "Serial No." := TempTrackingSpecification."Serial No.";
                    "Lot No." := TempTrackingSpecification."Lot No.";
                    "Package No." := TempTrackingSpecification."Package No.";
                    "Expiration Date" := TempTrackingSpecification."Expiration Date";
                end;
            TrackingType::"Lot No.":
                if TempTrackingSpecification."Lot No." <> '' then begin
                    "Lot No." := TempTrackingSpecification."Lot No.";
                    "Expiration Date" := TempTrackingSpecification."Expiration Date";
                end;
            TrackingType::"Package No.":
                if TempTrackingSpecification."Package No." <> '' then begin
                    "Package No." := TempTrackingSpecification."Package No.";
                    "Expiration Date" := TempTrackingSpecification."Expiration Date";
                end;
            else
                OnLookUpTrackingSummaryOnCaseOrderTypeElse(Rec, TempTrackingSpecification, TrackingType);
        end;

        OnAfterLookUpTrackingSummary(Rec, TempTrackingSpecification, TrackingType);
    end;

    local procedure CheckSerialNoQty()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSerialNoQty(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Serial No." = '') and ("New Serial No." = '') then
            exit;
        if not ("Quantity (Base)" in [-1, 0, 1]) then
            Error(IncorrectQtyForSNErr);
    end;

    /// <summary>
    /// Gets the date required for item journal line calculations.
    /// </summary>
    /// <returns>The date for calculations.</returns>
    procedure GetDateForCalculations() CalculationDate: Date;
    begin
        CalculationDate := Rec."Posting Date";
        if CalculationDate = 0D then
            CalculationDate := WorkDate();
    end;

    /// <summary>
    /// Event triggered after initializing default dimension sources for the Item Journal Line record.
    /// Subscribing to this event allows developers to extend the standard behavior of initializing default dimesions for the item journal record.
    /// </summary>
    /// <param name="ItemJournalLine">The Item Journal Line record.</param>
    /// <param name="DefaultDimSource">The list of default dimension sources.</param>
    /// <param name="FieldNo">The field number that triggered the validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var ItemJournalLine: Record "Item Journal Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggerd before creating a dimension for an item journal line.
    /// Subscribing to this event allows developers to implement custom logic or override asigning default source dimensions to the item journal line.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record to which dimensions are being assigned.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default validation logic should be skipped.</param>
    /// <param name="CurrFieldNo">The current field number being processed.</param>
    /// <param name="DefaultDimSource">A list of dictionaries containing default dimension sources, with each dictionary mapping an integer (dimension type) to a dimension code.</param>
    /// <param name="InheritFromDimSetID">The dimension set ID from which dimensions will be inherited, if applicable.</param>
    /// <param name="InheritFromTableNo">The table number from which dimensions will be inherited, if applicable.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean; CurrFieldNo: Integer; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; InheritFromDimSetID: Integer; InheritFromTableNo: Integer)
    begin
    end;


    /// <summary>
    /// Event triggered after the new item journal line has been set up.
    /// This event allows developers to add custom logic or make adjustments to the record after the new line has been configured.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record that was set up.</param>
    /// <param name="LastItemJournalLine">Provided item journal line record used as a source.</param>
    /// <param name="ItemJournalTemplate">Item journal template record defining the template settings for tue current item journal record.</param>
    /// <param name="ItemJnlBatch">Item journal batch record containing batch-specific settings for tue current item journal record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupNewLine(var ItemJournalLine: Record "Item Journal Line"; var LastItemJournalLine: Record "Item Journal Line"; ItemJournalTemplate: Record "Item Journal Template"; ItemJnlBatch: Record "Item Journal Batch")
    begin
    end;

    /// <summary>
    /// Event triggered after calculating the signed value.
    /// This event allows developers to adjust or log the signed value after the main procedure logic has executed.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record for which the signed value was calculated.</param>
    /// <param name="Value">The original value provided to the procedure.</param>
    /// <param name="Result">The resulting signed value calculated by the procedure. Developers can modify this value if needed within the event logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSigned(ItemJournalLine: Record "Item Journal Line"; Value: Decimal; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBaseQty(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; FromFieldName: Text; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingisEmpty(ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckNewTrackingisEmpty(ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingEqualItemLedgEntry(ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingEqualTrackingSpecification(ItemJournalLine: Record "Item Journal Line"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTracking(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after copying data from the "Sales Header" to the current record.
    /// This event allows developers to implement custom logic or make adjustments to the current record after data has been copied from the "Sales Header."
    /// </summary>
    /// <param name="ItemJnlLine">The current item journal line record to which the data from the "Sales Header" has been copied.</param>
    /// <param name="SalesHeader">Provided "Sales Header" record from which data was copied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromSalesHeader(var ItemJnlLine: Record "Item Journal Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Event triggered after copying data from the "Sales Line" to the current record.
    /// This event allows developers to implement custom logic or make adjustments to the current record after data has been copied from the "Sales Line."
    /// </summary>
    /// <param name="ItemJnlLine">The current record to which the data from the "Sales Line" has been copied.</param>
    /// <param name="SalesLine">Provided "Sales Line" record from which data was copied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromSalesLine(var ItemJnlLine: Record "Item Journal Line"; SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Event triggered after copying data from the "Purchase Header" to the current record.
    /// This event allows developers to implement custom logic or make adjustments to the current record after data has been copied from the "Purchase Header."
    /// </summary>
    /// <param name="ItemJnlLine">The current Item journal line record to which the data from the "Purchase Header" has been copied.</param>
    /// <param name="PurchHeader">Provided "Purchase Header" record from which data was copied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromPurchHeader(var ItemJnlLine: Record "Item Journal Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    /// <summary>
    /// Event triggered after copying data from the "Purchase Line" to the current record.
    /// This event allows developers to implement custom logic or make adjustments to the current record after data has been copied from the "Purchase Line."
    /// </summary>
    /// <param name="ItemJnlLine">The current record to which the data from the "Purchase Line" has been copied.</param>
    /// <param name="PurchLine">Provided "Purchase Line" record from which data was copied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromPurchLine(var ItemJnlLine: Record "Item Journal Line"; PurchLine: Record "Purchase Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterCopyItemJnlLineFromServHeader(var ItemJnlLine: Record "Item Journal Line"; ServHeader: Record Microsoft.Service.Document."Service Header")
    begin
        OnAfterCopyItemJnlLineFromServHeader(ItemJnlLine, ServHeader);
    end;

    [Obsolete('Replaced by event OnAfterCopyToItemJnlLine in table Service Header', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServHeader(var ItemJnlLine: Record "Item Journal Line"; ServHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterCopyItemJnlLineFromServLine(var ItemJnlLine: Record "Item Journal Line"; ServLine: Record Microsoft.Service.Document."Service Line")
    begin
        OnAfterCopyItemJnlLineFromServLine(ItemJnlLine, ServLine);
    end;

    [Obsolete('Replaced by event OnAfterCopyToItemJnlLine in table Service Line', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServLine(var ItemJnlLine: Record "Item Journal Line"; ServLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterCopyItemJnlLineFromServShptHeader(var ItemJnlLine: Record "Item Journal Line"; ServShptHeader: Record Microsoft.Service.History."Service Shipment Header")
    begin
        OnAfterCopyItemJnlLineFromServShptHeader(ItemJnlLine, ServShptHeader);
    end;

    [Obsolete('Replaced by event OnAfterCopyToItemJnlLine in table Service Shipment Header', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServShptHeader(var ItemJnlLine: Record "Item Journal Line"; ServShptHeader: Record Microsoft.Service.History."Service Shipment Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterCopyItemJnlLineFromServShptLine(var ItemJnlLine: Record "Item Journal Line"; ServShptLine: Record Microsoft.Service.History."Service Shipment Line")
    begin
        OnAfterCopyItemJnlLineFromServShptLine(ItemJnlLine, ServShptLine);
    end;

    [Obsolete('Replaced by event OnAfterCopyToItemJnlLine in table Service Shipment Line', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServShptLine(var ItemJnlLine: Record "Item Journal Line"; ServShptLine: Record Microsoft.Service.History."Service Shipment Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterCopyItemJnlLineFromServShptLineUndo(var ItemJnlLine: Record "Item Journal Line"; ServShptLine: Record Microsoft.Service.History."Service Shipment Line")
    begin
        OnAfterCopyItemJnlLineFromServShptLineUndo(ItemJnlLine, ServShptLine);
    end;

    [Obsolete('Replaced by event OnAfterCopyToItemJnlLineUndo in table Service Shipment Line', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServShptLineUndo(var ItemJnlLine: Record "Item Journal Line"; ServShptLine: Record Microsoft.Service.History."Service Shipment Line")
    begin
    end;
#endif

    /// <summary>
    /// Event triggered after copying data from the "Job Journal Line" to the current record.
    /// This event allows developers to implement custom logic or make adjustments to the current record after data has been copied from the "Job Journal Line."
    /// </summary>
    /// <param name="ItemJournalLine">The current record to which the data from the "Job Journal Line" has been copied.</param>
    /// <param name="JobJnlLine">Provided "Job Journal Line" record from which data was copied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromJobJnlLine(var ItemJournalLine: Record "Item Journal Line"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromReservEntry(var ItemJournalLine: Record "Item Journal Line"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var ItemJournalLine: Record "Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromSpec(var ItemJournalLine: Record "Item Journal Line"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyNewTrackingFromNewSpec(var ItemJournalLine: Record "Item Journal Line"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyNewTrackingFromOldItemLedgerEntry(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDisplayErrorIfItemIsBlocked(var Item: Record Item; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDisplayErrorIfItemVariantIsBlocked(var ItemVariant: Record "Item Variant"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;


    /// <summary>
    /// Event triggered after getting the global "Item" record based on the "Item No." field value.
    /// This event allows developers to apply additional logic or handle changes after the global "Item" record has been retrieved.
    /// </summary>
    /// <param name="Item">Global "Item" record that has been retrieved.</param>
    /// <param name="ItemJournalLine">The current item journal line record whose "Item No." field was used to retrieve the item.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemChange(var Item: Record Item; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after getting the global "Item Variant" record and synchronizing it with the "Variant Code" and "Item No." fields.
    /// This event allows developers to apply additional logic or handle changes after the "Item Variant" record has been retrieved.
    /// </summary>
    /// <param name="ItemVariant">Global "Item Variant" record that has been retrieved.</param>
    /// <param name="ItemJournalLine">The current item journal line record whose "Variant Code" and "Item No." fields were used to retrieve the item variant.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemVariantChange(var ItemVariant: Record "Item Variant"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving the line with price.
    /// This event allows developers to modify or enhance the behavior of the `LineWithPrice` interface after it has been set. Custom logic can be applied to tailor the behavior of the assigned interface.
    /// </summary>
    /// <param name="LineWithPrice">The "Line With Price" interface that has been set to the "Item Journal Line - Price" codeunit. Developers can use this parameter to extend or modify its behavior.</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterGetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    begin
    end;

    /// <summary>
    /// Event triggered after calculating the "Unit Amount" for the current item journal line record.
    /// This event allows developers to add custom logic or make adjustments to the calculated "Unit Amount" value after the procedure has completed its logic.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record for which the unit amount was calculated.</param>
    /// <param name="UnitCost">The calculated unit cost used in determining the unit amount. This value reflects the item's cost adjusted for its unit of measure and any applicable indirect costs.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetUnitAmount(var ItemJournalLine: Record "Item Journal Line"; UnitCost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasSameNewTracking(ItemJournalLine: Record "Item Journal Line"; var IsSameTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnValidateItemNoAssignByEntryType(var ItemJournalLine: Record "Item Journal Line"; var Item: Record Item)
    begin
    end;

    /// <summary>
    /// Event triggered after the "General Ledger Setup" has been read.
    /// This event allows developers to implement custom logic or make adjustments after the "General Ledger Setup" has been successfully loaded into memory.
    /// </summary>
    /// <param name="GLSetup">The global "General Ledger Setup" record that was read.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterReadGLSetup(var GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculateUnitAmount(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after setting the fields of a "Reservation Entry" record in the "SetReservationEntry" procedure.
    /// This event allows developers to implement custom logic or modify the "Reservation Entry" record after its fields have been populated using the provided data.
    /// </summary>
    /// <param name="ReservEntry">The "Reservation Entry" record whose fields have been set.</param>
    /// <param name="ItemJournalLine">Current item journal line record used to populate the "Reservation Entry" record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationEntry(var ReservEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line");
    begin
    end;

    /// <summary>
    /// Event triggered after setting filters on a "Reservation Entry" record in the "SetReservationFilters" procedure.
    /// This event allows developers to implement custom filters or modify the "Reservation Entry" record after its filters have been set using the current record data.
    /// </summary>
    /// <param name="ReservEntry">The "Reservation Entry" record with filters applied.</param>
    /// <param name="ItemJournalLine">Current item journal line record used to set the filters on the "Reservation Entry" record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingExists(var ItemJournalLine: Record "Item Journal Line"; var IsTrackingExist: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after updating the "Amount" field in the current item journal line record.
    /// This event allows developers to add custom logic after the "Amount" field has been updated.
    /// For example, additional calculations or validations can be performed at this stage
    /// </summary>
    /// <param name="ItemJournalLine">The record containing the updated "Amount" field.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmount(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after validating the shortcut dimension code for the current item journal line record.
    /// This event allows developers to adjust or log the validated dimension code and its integration with the "Dimension Set ID".
    /// </summary>
    /// <param name="ItemJournalLine">The current current item journal line record for which the shortcut dimension code was validated.</param>
    /// <param name="xItemJournalLine">The previous state of the record before the validation process.</param>
    /// <param name="FieldNumber">The field number of the shortcut dimension that was validated.</param>
    /// <param name="ShortcutDimCode">The validated shortcut dimension code. Developers can use this parameter to review or further process the validated code.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    /// <summary>
    /// Event triggered before performing the item availability check.
    /// This event allows developers to add custom logic or override the default behavior of the item availability check.
    /// </summary>
    /// <param name="ItemJournalLine">The current "Item Journal Line" record being checked for item availability.</param>
    /// <param name="CalledByFieldNo">The number of the field that triggered the check.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default logic should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailable(ItemJournalLine: Record "Item Journal Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before checking the reserved quantity (base) during the valid.tion of quantity
    /// This event allows developers to override or enhance the logic for checking reserved quantities in base units.
    /// </summary>
    /// <param name="ItemJournalLine">The current record being validated for reserved quantities.</param>
    /// <param name="Item">Provided global item record.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default logic should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReservedQtyBase(var ItemJournalLine: Record "Item Journal Line"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDisplayErrorIfItemIsBlocked(var Item: Record Item; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDisplayErrorIfItemVariantIsBlocked(var ItemVariant: Record "Item Variant"; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before calculating the unit cost in the "FindUnitCost" procedure.
    /// This event allows developers to implement custom logic for calculating the unit cost.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record for which the unit cost is being calculated.</param>
    /// <param name="UnitCost">The calculated unit cost. This can be set by the subscriber to override the default calculation.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default validation logic should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindUnitCost(var ItemJournalLine: Record "Item Journal Line"; var UnitCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before calculating the "Unit Amount".
    /// This event allows developers to add custom logic or override the default unit amount calculation.
    /// </summary>
    /// <param name="ItemJournalLine">The current record for which the unit amount is being calculated.</param>
    /// <param name="CalledByFieldNo">The field number that initiated the calculation.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default calculation logic should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnitAmount(var ItemJournalLine: Record "Item Journal Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before executing the lookup logic for the "Item No." field in the "LookupItemNo" procedure.
    /// This event allows developers to implement custom logic or modify the behavior before the default lookup logic for the "Item No." field is executed.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record for which the "Item No." lookup is being performed.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default lookup logic should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupItemNo(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before retrieving and calculating costs.
    /// This event allows developers to implement custom logic or override the default cost retrieval process.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record for which costs are being retrieved.</param>
    /// <param name="UnitCost">The calculated unit cost for the record. Developers can modify this value in the event logic.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default calculation logic should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveCosts(var ItemJournalLine: Record "Item Journal Line"; var UnitCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRevaluationPerEntryAllowed(ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before initializing the selection of an "Item Ledger Entry" in the "SelectItemEntry" procedure.
    /// This event allows developers to add custom logic or modify the behavior before the selection process begins.
    /// For example, additional filters or setup logic can be applied to the record or process.
    /// </summary>
    /// <param name="ItemJournalLine">The current record being processed in the "SelectItemEntry" procedure.</param>
    /// <param name="xItemJournalLine">The previous version of the record before modifications.</param>
    /// <param name="CurrentFieldNo">The number of the field that has triggered the validation process.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectItemEntry(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered before setting the "New Bin Code" for same-location transfers.
    /// This event allows developers to implement custom logic or override the default behavior for setting the "New Bin Code".
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record where the "New Bin Code" is set.</param>
    /// <param name="CurrentFieldNo">The field number currently being processed.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default procedure logic should be skipped.</param> gasa
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetNewBinCodeForSameLocationTransfer(var ItemJournalLine: Record "Item Journal Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Applies-to Entry" field in the current item journal line record.
    /// This event allows developers to add custom logic or override the default behavior before the "Applies-to Entry" field has been validated.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    /// <param name="CurrentFieldNo">The number of the field that has triggered the validation process.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default validation logic should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAppliesToEntry(var ItemJournalLine: Record "Item Journal Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the Amount field.
    /// This event allows developers to add custom logic or skip the default processing.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default validation logic should be skipped.</param>
    /// <remarks>For instance, it can be used to change how 'Unit Amount' will be calculated.</remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAmount(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the direct cost "Unit Amount" for the current item journal line record.
    /// This event allows developers to implement custom logic or override the default validation process.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record for which the direct cost "Unit Amount" is being validated.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default validation logic should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateItemDirectCostUnitAmount(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Unit of Measure Code" field in the current item journal line record.
    /// This event allows developers to add custom logic or override the default behavior before the "Unit of Measure Code" field has been validated.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default validation logic should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUnitOfMeasureCode(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Quantity (Base)" field in the current item journal line record.
    /// This event allows developers to add custom logic or override the default behavior before the "Quantity (Base)" field has been validated.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    /// <param name="xItemJournalLine">The previous version of the item journal line record before the change.</param>
    /// <param name="FieldNo">The number of the field that has triggered the validation process.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default validation logic should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityBase(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Output Quantity (Base)" field in the current item journal line record.
    /// This event allows developers to add custom logic or override the default behavior before the "Output Quantity (Base)" field has been validated.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    /// <param name="xItemJournalLine">The previous version of the item journal line record before the change.</param>
    /// <param name="FieldNo">The number of the field that has triggered the validation process.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default validation logic should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyReservedQty(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckItemJournalLinePostRestrictions()
    begin
    end;

    /// <summary>
    /// Event triggered after finding the first item journal line in the current batch.
    /// This event allows developers to add custom logic or modify the current item journal line record after the first line is found.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being set up.</param>
    /// <param name="FirstItemJournalLine">Item journal line record representing the first line found in the current batch.</param>
    /// <param name="LastItemJnlLine">Provided item journal line record used as a reference for setup.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetUpNewLineOnAfterFindItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var FirstItemJournalLine: Record "Item Journal Line"; var LastItemJnlLine: Record "Item Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before opening the "Item Ledger Entries" page in the "SelectItemEntry" procedure.
    /// This event allows developers to customize or apply additional logic to the "Item Ledger Entry" record
    /// before it is displayed on the "Item Ledger Entries" page.
    /// </summary>
    /// <param name="ItemLedgerEntry">The "Item Ledger Entry" record being prepared for display.</param>
    /// <param name="ItemJournalLine">The current record being processed in the "SelectItemEntry" procedure.</param>
    /// <param name="CurrentFieldNo">The field number currently being processed, which determines the context of the selection.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSelectItemEntryOnBeforeOpenPage(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCapUnitOfMeasureCodeOnCaseOrderTypeElse(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCapUnitOfMeasureCodeOnSetQtyPerCapUnitOfMeasure(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpTrackingSummaryOnCaseOrderTypeElse(var ItemJournalLine: Record "Item Journal Line"; TempTrackingSpecification: Record "Tracking Specification" temporary; TrackingType: Enum "Item Tracking Type")
    begin
    end;

    /// <summary>
    /// Event triggered before checking if tracking exists for selected item ledger entry during the validation of the "Applies-from Entry" field.
    /// In case tracking exists error will be thrown.
    /// This event allows developers to add custom logic or override the default behavior when verifying if tracking exists for the "Applies-from Entry".
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    /// <param name="ItemLedgEntry">The item ledger entry record associated with the "Applies-from Entry" field.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default tracking existence check should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateAppliesfromEntryOnBeforeCheckTrackingExistsError(ItemJournalLine: Record "Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving the item during validation of the "Item No." field.
    /// This event allows developers to execute custom logic after the item has been retrieved during validation.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    /// <param name="Item">The retrived "Item" record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterGetItem(var ItemJournalLine: Record "Item Journal Line"; Item: Record Item)
    begin
    end;

    /// <summary>
    /// Event triggered after determining whether the system should check source of the item ledger entry.
    /// If the item journal line "Entry Type" is "Output", then the system should check if item ledger entry must be created from production order.
    /// This event allows developers to execute custom logic after the default process of source item ledger entry checking has been executed.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    /// <param name="ItemLedgEntry">The related item ledger entry record retrieved using the "Applies-to Entry" field.</param>
    /// <param name="ShouldCheckItemLedgEntryFieldsForOutput">A boolean parameter indicating whether additional checks on the item ledger entry fields should be performed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateAppliestoEntryOnAfterCalcShouldCheckItemLedgEntryFieldsForOutput(var ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ShouldCheckItemLedgEntryFieldsForOutput: Boolean)
    begin
    end;

#if not CLEAN26
    [Obsolete('Replaced by event OnValidateOrderNoOnAfterCopyFromAssemblyHeader in codeunit Asm. Item Journal Mgt.', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderNoOnAfterProcessOrderTypeAssembly(var ItemJournalLine: Record "Item Journal Line"; ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
    end;
#endif

    /// <summary>
    /// Event triggered when the "Order Type" is recognized as an unhandled case during the validation of the "Order No." field.
    /// This event allows developers to extend the logic for unhandled "Order Type" cases during the validation of the "Order No." field.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderNoOnCaseOrderTypeElse(var ItemJournalLine: Record "Item Journal Line"; var xItemJournalLine: Record "Item Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after setting filters on the production order line record during the validation of the "Order Line No." field.
    /// This event allows developers to add custom logic or modify the behavior after filters are applied to the production order line record.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    /// <param name="ProdOrderLine">The production order line record with the applied filters.</param>
    /// <remarks>It can be used to reset or add additional filters to the production order line.</remarks>
    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderLineNoOnCaseOrderTypeElse(var ItemJournalLine: Record "Item Journal Line"; var xItemJournalLine: Record "Item Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before calculating unit amount during the validation of the "Quantity" field.
    /// This event allows developers to add custom logic or perform additional actions before the unit amount has been calculated.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record that is being processed.</param>
    /// <param name="xItemJournalLine">The previous version of the item journal line record before the change.</param>
    /// <param name="CurrFieldNo">The number of field that has triggered the validation process.</param> gasa
    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeGetUnitAmount(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; CallingFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after calculating whether to show an error for existing item tracking on the "Applies-to Entry" field.
    /// This event allows developers to modify the logic or state of the "ShowTrackingExistsError" parameter.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    /// <param name="xItemJournalLine">The previous version of the item journal line record before the change.</param>
    /// <param name="ShowTrackingExistsError">A boolean parameter indicating whether an error for existing item tracking should be displayed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateAppliesToEntryOnAferCalcShowTrackingExistsError(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; var ShowTrackingExistsError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestItemFields(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the shortcut dimension code to the current item journal line record.
    /// This event allows developers to implement custom logic or modify the dimension code before the validation logic is executed.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record for which the shortcut dimension code is being validated.</param>
    /// <param name="xItemJournalLine">The previous state of the record before the validation process.</param>
    /// <param name="FieldNumber">The field number of the shortcut dimension being validated.</param>
    /// <param name="ShortcutDimCode">The shortcut dimension code to be validated. Developers can modify this parameter within the event logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    /// <summary>
    /// Event triggered before calculating the unit cost during the validation of the "Unit of Measure Code" field.
    /// This event allows developers to modify or override the default calculation logic for the unit cost.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    /// <param name="UnitCost">The unit cost value to be calculated. Developers can modify this value within the event.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default unit cost calculation should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnBeforeCalcUnitCost(var ItemJournalLine: Record "Item Journal Line"; var UnitCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before calling validation of warehouse source line during the validation of the "Unit of Measure Code" field.
    /// This event allows developers to implement custom logic or make modifications before warehouse validation has been performed for the source line.
    /// </summary>
    /// <param name="ItemJournalLine">The current record representing the item journal line being processed.</param>
    /// <param name="xItemJournalLine">The previous version of the item journal line record before the change.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnBeforeWhseValidateSourceLine(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnBeforeValidateQuantity(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Event triggered before updating the "Amount" field incurrent item journal line.
    /// This event allows developers to add custom logic or override the standard "Amount" calculation logic.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default logic should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmount(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after setting the unit cost for the current record.
    /// This event allows developers to adjust or log the unit cost after it has been calculated.
    /// </summary>
    /// <param name="ItemJournalLine">The current record for which costs were retrieved.</param>
    /// <param name="UnitCost">The calculated unit cost for the record after the default logic has been executed. Developers can adjust this value further if needed.</param>
    /// <param name="Item">The "Item" record associated with the cost calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnRetrieveCostsOnAfterSetUnitCost(var ItemJournalLine: Record "Item Journal Line"; var UnitCost: Decimal; Item: Record Item)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the unit of measure code for the "Item No." field.
    /// This event allows developers to execute custom logic before the unit of measure code validation.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record.</param>
    /// <param name="Item">The "Item" record being validated.</param>
    /// <param name="CurrFieldNo">The number of field that triggered the validation.</param>
    /// <param name="xItemJournalLine">The previous state of the item journal line record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnBeforeValidateUnitOfmeasureCode(var ItemJournalLine: Record "Item Journal Line"; var Item: Record Item; CurrFieldNo: Integer; xItemJournalLine: Record "Item Journal Line");
    begin
    end;

    /// <summary>
    /// Event triggered before setting the description on item journal line from the retrived item record.
    /// This event allows developers to modify the record or item before the description has been set.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record.</param>
    /// <param name="Item">The related item record retrieved using the "Item No." field.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnBeforeSetDescription(var ItemJournalLine: Record "Item Journal Line"; Item: Record Item)
    begin
    end;

    /// <summary>
    /// Event triggered after calculating the unit cost during validation of the "Item No." field.
    /// This event allows developers to execute custom logic after unit cost calculation has been completed.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record.</param>
    /// <param name="Item">The related item record retrieved using the "Item No." field.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterCalcUnitCost(var ItemJournalLine: Record "Item Journal Line"; Item: Record Item)
    begin
    end;

#if not CLEAN26
    [Obsolete('Replaced by event OnValidateItemNoOnSetCostAndPrice', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterCalcUnitAmount(var ItemJournalLine: Record "Item Journal Line"; WorkCenter: Record Microsoft.Manufacturing.WorkCenter."Work Center"; MachineCenter: Record Microsoft.Manufacturing.MachineCenter."Machine Center")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnSetCostAndPrice(var ItemJournalLine: Record "Item Journal Line"; UnitCost: Decimal)
    begin
    end;

    ///<summary>
    ///Event triggered after creating default dimensions for the current record if field "Item No." is empty.
    ///This event allows developers to add custom dimensions after default ones have been created.
    ///</summary>
    ///<param name="ItemJournalLine">The current item journal line record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterCreateDimInitial(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDim(var ItemJournalLine: Record "Item Journal Line"; DimenionSetID: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Location Code" field in the item journal line.
    /// This event allows developers to add custom logic or override the default behavior before the "Location Code" field has been validated.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    /// <param name="xItemJournalLine">The previous version of the item journal line record before the change.</param>
    /// <param name="IsHandled">A boolean parameter that, in case true, indicates that the default validation logic should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLocationCode(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsDefaultBin(Location: Record Location; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving or clearing a location record in the "GetLocation" procedure.
    /// This event allows developers to perform additional actions after the location record has been retrieved based on the provided location code.
    /// </summary>
    /// <param name="Location">The "Location" record that has been retrieved or cleared.</param>
    /// <param name="LocationCode">Provided location code used to retrieve the "Location" record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLocation(var Location: Record Location; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingIfRequired(ItemJournalLine: Record "Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckNewTrackingIfRequired(ItemJournalLine: Record "Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingIfrequiredNotBlank(ItemJournalLine: Record "Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    /// <summary>
    /// Event triggered after initializing the revaluation journal line.
    /// This event allows developers to adjust or log the initialized revaluation journal line after the default logic has been executed.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record representing the revaluation journal line that was initialized.</param>
    /// <param name="ItemLedgEntry2">The "Item Ledger Entry" record used as the source for initialization.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRevalJnlLine(var ItemJournalLine: Record "Item Journal Line"; ItemLedgEntry2: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemLedgerEntry(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculateUnitAmountOnAfterCalcQtyPerUnitOfMeasure(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered to determine if a bin code check is needed for the production order component during the validation of the "Bin Code" field.
    /// This event allows developers to add custom logic or override the default behavior for checking the production order component's bin code.
    /// </summary>
    /// <param name="ItemJournalLine">The current record representing the item journal line being processed.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default bin code check for the production order component should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBinCodeOnCheckProdOrderCompBinCodeCheckNeeded(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var ItemJournalLine: Record "Item Journal Line"; var xItemJournalLine: Record "Item Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before assigning indirect cost percentage and overhead rate during validation of the "Item No." field.
    /// This event allows developers to modify these fields or execute additional logic before the values have been assigned.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    /// <param name="Item">The related item record retrieved using the "Item No." field.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnBeforeAssignIndirectCostPct(var ItemJournalLine: Record "Item Journal Line"; Item: Record Item)
    begin
    end;

    /// <summary>
    /// Event triggered before setting the default price calculation method.
    /// This event allows developers to override or extend the default behavior for setting the price calculation method in the item journal line.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being procesed.</param>
    /// <param name="ItemJnlBatch">The item journal batch record containing batch-specific settings for tue current item journal record.</param>
    /// <param name="DimMgt">The dimension management codeunit used for handling dimensions.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetUpNewLineOnBeforeSetDefaultPriceCalculationMethod(var ItemJournalLine: Record "Item Journal Line"; ItemJnlBatch: Record "Item Journal Batch"; var DimMgt: Codeunit DimensionManagement)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSkipRenumberDocumentNo(ItemJournalLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRenumberDocNoOnLines(var DocNo: Code[20]; var ItemJnlLine2: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRenumberDocNoOnLines(var DocNo: Code[20]; var ItemJnlLine2: Record "Item Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before testing the "Bin Mandatory" field on a selected Location of the current item journal line during the validation of the "Bin Code" field.
    /// This event allows developers to add custom logic or override the default behavior when testing the "Bin Mandatory" field for the selected Location.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default testing logic of the "Bin Mandatory" field should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBinCodeOnBeforeTestBinMandatory(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeCopyItemJnlLineFromServLine(var ItemJournalLine: Record "Item Journal Line"; ServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
        OnBeforeCopyItemJnlLineFromServLine(ItemJournalLine, ServiceLine, IsHandled);
    end;

    [Obsolete('Replaced by event OnBeforeCopyToItemJnlLine in table Service Line', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyItemJnlLineFromServLine(var ItemJournalLine: Record "Item Journal Line"; ServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTracking(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after the selection process for an item ledger entry is completed.
    /// This event allows developers to add custom logic or postprocessing after an entry has been selected.
    /// </summary>
    /// <param name="ItemJournalLine">The updated "Item Journal Line" record after the selection process.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSelectItemEntry(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before initializing the revaluation journal line.
    /// This event allows developers to implement custom logic or override the default initialization process.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record representing the revaluation journal line being initialized.</param>
    /// <param name="ItemLedgEntry2">The "Item Ledger Entry" record used as the source for initialization.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default validation logic should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRevalJnlLine(var ItemJournalLine: Record "Item Journal Line"; ItemLedgEntry2: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookUpTrackingSummary(var ItemJournalLine: Record "Item Journal Line"; TempTrackingSpecification: Record "Tracking Specification" temporary; TrackingType: Enum "Item Tracking Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitTableValuePair(var ItemJournalLine: Record "Item Journal Line"; var TableValuePair: Dictionary of [Integer, Code[20]]; FieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered before calculating the signed value.
    /// This event allows developers to implement custom logic for determining the signed value.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record for which the signed value is being calculated.</param>
    /// <param name="Value">The original value provided to the procedure.</param>
    /// <param name="Result">The resulting signed value. Developers can set this parameter to the desired value within the event logic.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default validation logic should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSigned(ItemJournalLine: Record "Item Journal Line"; var Value: Decimal; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTypeWithItemNo(var ItemJournalLine: Record "Item Journal Line"; Item: Record "Item"; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Event triggered before updating global dimensions from the calculated "Dimension Set ID".
    /// This event allows developers to customize the update process for global dimensions after the "Dimension Set ID" is calculated.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being updated with dimensions.</param>
    /// <param name="xItemJournalLine">The record before the current modifications were made.</param>
    /// <param name="CurrentFieldNo">The field number currently being processed, providing context for dimension creation.</param>
    /// <param name="OldDimSetID">The previous "Dimension Set ID" value before it was updated.</param>
    /// <param name="DefaultDimSource">A list of dictionaries containing default dimension sources, with each dictionary mapping an integer (dimension type) to a dimension code.</param>
    /// <param name="InheritFromDimSetID">The dimension set ID from which dimensions were inherited, if applicable.</param>
    /// <param name="InheritFromTableNo">The table number from which dimensions were inherited, if applicable.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCreateDimOnBeforeUpdateGlobalDimFromDimSetID(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; CurrentFieldNo: Integer; OldDimSetID: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; InheritFromDimSetID: Integer; InheritFromTableNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSerialNoQty(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after setting source filters on a "Reservation Entry" record in the "SetReservEntrySourceFilters" procedure.
    /// This event allows developers to implement custom filters or modify the "Reservation Entry" record after its source filters have been set based on the provided source key and context.
    /// </summary>
    /// <param name="ReservationEntry">The "Reservation Entry" record with source filters applied.</param>
    /// <param name="SourceKey">A boolean parameter indicating whether the source key is included in the filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservEntrySourceFilters(var ReservationEntry: Record "Reservation Entry"; SourceKey: Boolean);
    begin
    end;

    /// <summary>
    /// Event triggered after evaluating whether a current line is considered empty based on values of Quantity, 'Item No.' and 'Value Entry Type'.
    /// This event allows developers to add custom logic or modify the result of the empty line evaluation.
    /// For example, additional conditions can be checked or the result can be overridden based on specific business requirements.
    /// </summary>
    /// <param name="ItemJournalLine">The record being evaluated to determine if it qualifies as an empty line.</param>
    /// <param name="Result">A boolean value indicating whether the line is considered empty.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterEmptyLine(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "New Location Code" field in the item journal line.
    /// This event allows developers to add custom logic or override the default behavior before the "New Location Code" field has been validated.
    /// </summary>
    /// <param name="ItemJournalLine">The current item journal line record being processed.</param>
    /// <param name="xItemJournalLine">The previous version of the item journal line record before the change.</param>
    /// <param name="IsHandled">A boolean parameter that, if set to true, indicates that the default validation logic should be skipped.</param>
    /// <remarks> Developer can overide the rule that field 'Entry Type' must be 'Transfer' in order to validate new value.</remarks> gasa
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNewLocationCode(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateEntryTypeOnUpdateByEntryType(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitAmountOnUpdateByEntryType(var ItemJournalLine: Record "Item Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitCostOnUpdateByEntryType(var ItemJournalLine: Record "Item Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDefaultPriceCalculationMethod(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckEntryType(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEntryTypeConsumption(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEntryTypeOutput(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEntryTypeProduction(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsOrderTypeAsmOrProd(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsDocNoProdOrderNo(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterValidateUnitofMeasureCode(var ItemJournalLine: Record "Item Journal Line"; var xItemJournalLine: Record "Item Journal Line"; var Item: Record Item; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterValidateItemNo(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeValidateItemNo(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterSetCallWhseCheck(var ItemJournalLine: Record "Item Journal Line"; var CallWhseCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBinCodeOnCompBinCheck(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectItemEntryOnSetFilters(var ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateNo(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTimeIsEmpty(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnlyStopTime(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetOrderTypeProduction(var OrderType: Enum "Inventory Order Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetOrderTypeService(var OrderType: Enum "Inventory Order Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateEntryTypeBeforeValidateLocationCode(var ItemJnlLine: Record "Item Journal Line")
    begin
    end;
}
