// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Structure;
using System.Automation;
using System.Security.AccessControl;

table 246 "Requisition Line"
{
    Caption = 'Requisition Line';
    DataCaptionFields = "Journal Batch Name", "Line No.";
    DrillDownPageID = "Requisition Lines";
    LookupPageID = "Requisition Lines";
#if not CLEAN28
    Permissions = TableData Microsoft.Manufacturing.Routing."Routing Header" = r,
                  TableData Microsoft.Manufacturing.ProductionBOM."Production BOM Header" = r;
#endif
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Worksheet Template Name"; Code[10])
        {
            Caption = 'Worksheet Template Name';
            TableRelation = "Req. Wksh. Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Requisition Wksh. Name".Name where("Worksheet Template Name" = field("Worksheet Template Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Type; Enum "Requisition Line Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            var
                NewType: Enum "Requisition Line Type";
            begin
                if Type <> xRec.Type then begin
                    NewType := Type;

                    DeleteRelations();
                    "Dimension Set ID" := 0;
                    "No." := '';
                    "Variant Code" := '';
                    "Location Code" := '';
                    CleanProdOrderNo();
                    ReqLineReserve.VerifyChange(Rec, xRec);
                    OnResetReqLineFields(Rec);
                    Init();
                    Type := NewType;
                end;
            end;
        }
        field(5; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const(Item)) Item;

            trigger OnValidate()
            var
                ShouldValidateUnitofMeasureCode: Boolean;
                IsHandled: Boolean;
            begin
                CheckActionMessageNew();
                ReqLineReserve.VerifyChange(Rec, xRec);
                IsHandled := false;
                OnValidateNoOnBeforeDeleteRelations(Rec, xRec, IsHandled);
                if not IsHandled then
                    DeleteRelations();

                if "No." = '' then begin
                    CreateDimFromDefaultDim();
                    Init();
                    Type := xRec.Type;
                    exit;
                end;

                if "No." <> xRec."No." then begin
                    "Variant Code" := '';
                    CleanProdOrderNo();
                    OnResetReqLineFields(Rec);
                end;

                TestField(Type);
                case Type of
                    Type::"G/L Account":
                        CopyFromGLAcc();
                    Type::Item:
                        CopyFromItem();
                end;

                OnValidateNoOnAfterAssignFieldsForNo(Rec, xRec);

                ShouldValidateUnitofMeasureCode := "Planning Line Origin" <> "Planning Line Origin"::"Order Planning";
                OnValidateNoOfAfterCalcShouldValidateUnitofMeasureCode(Rec, xRec, Item, ShouldValidateUnitofMeasureCode);
                if ShouldValidateUnitofMeasureCode then
                    if ("Replenishment System" = "Replenishment System"::Purchase) and
                       (Item."Purch. Unit of Measure" <> '')
                    then
                        Validate("Unit of Measure Code", Item."Purch. Unit of Measure")
                    else
                        Validate("Unit of Measure Code", Item."Base Unit of Measure");

                CreateDimFromDefaultDim();
            end;
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(8; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));

                "Quantity (Base)" :=
                    UOMMgt.CalcBaseQty(
                        "No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure",
                        "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FieldCaption(Quantity),
                        FieldCaption("Quantity (Base)"));

                if Type = Type::Item then begin
                    OnValidateQuantityOnBeforeGetDirectCost(Rec, xRec, CurrFieldNo);
                    GetDirectCost(FieldNo(Quantity));
                    SetRemaningQuantity();

                    if (CurrFieldNo = FieldNo(Quantity)) or (CurrentFieldNo = FieldNo(Quantity)) then
                        SetActionMessage();

                    "Net Quantity (Base)" := (Quantity - "Original Quantity") * "Qty. per Unit of Measure";

                    OnValidateQuantityOnBeforeUnitCost(Rec, CurrFieldNo, CurrentFieldNo);
                    Validate("Unit Cost");
                    if ValidateFields() then
                        if "Ending Date" <> 0D then
                            Validate("Ending Time")
                        else begin
                            if "Starting Date" = 0D then
                                "Starting Date" := WorkDate();
                            Validate("Starting Time");
                        end;
                    ReqLineReserve.VerifyQuantity(Rec, xRec);
                end;
            end;
        }
        field(9; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                Vend: Record Vendor;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupVendorNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                IsHandled := false;
                OnValidateVendorNoOnBeforeLookupVendor(Rec, IsHandled);
                if not IsHandled then
                    if LookupVendor(Vend, true) then
                        Validate("Vendor No.", Vend."No.");

                OnAfterLookupVendorNo(Rec, Vend);
            end;

            trigger OnValidate()
            var
                Vend: Record Vendor;
                ItemVend: Record "Item Vendor";
                TempSKU: Record "Stockkeeping Unit" temporary;
                IsHandled: Boolean;
            begin
                CheckActionMessageNew();
                if "Vendor No." <> '' then
                    if Vend.Get("Vendor No.") then begin
                        if Vend."Privacy Blocked" then begin
                            if PlanningResiliency then
                                TempPlanningErrorLog.SetError(
                                  StrSubstNo(Text031, Vend.TableCaption(), Vend."No."),
                                  Database::Vendor, CopyStr(Vend.GetPosition(), 1, 250));
                            Vend.VendPrivacyBlockedErrorMessage(Vend, false);
                        end;
                        CheckVendorBlocked(Vend);
                        OnValidateVendorNoOnAfterCheckVendor(Rec, Vend, CurrFieldNo);

                        if "Order Date" = 0D then
                            Validate("Order Date", WorkDate());

                        IsHandled := false;
                        OnValidateVendorNoOnBeforeValidateCurrencyCode(Rec, Vend, IsHandled);
                        if not IsHandled then
                            Validate("Currency Code", Vend."Currency Code");
                        if ("Planning Line Origin" <> "Planning Line Origin"::Planning) or ("Price Calculation Method" = "Price Calculation Method"::" ") then
                            "Price Calculation Method" := Vend.GetPriceCalculationMethod();
                        ValidateItemDescriptionAndQuantity(Vend);
                        SetPurchaserCode(Vend."Purchaser Code", "Purchaser Code");
                    end else begin
                        if ValidateFields() then
                            Error(Text005, FieldCaption("Vendor No."), "Vendor No.");
                        "Vendor No." := '';
                        if ("Planning Line Origin" <> "Planning Line Origin"::Planning) or ("Price Calculation Method" = "Price Calculation Method"::" ") then
                            "Price Calculation Method" := Vend.GetPriceCalculationMethod();
                    end
                else begin
                    UpdateDescription();
                    if ("Planning Line Origin" <> "Planning Line Origin"::Planning) or ("Price Calculation Method" = "Price Calculation Method"::" ") then
                        "Price Calculation Method" := Vend.GetPriceCalculationMethod();
                end;
                UpdateDescription();

                GetLocationCode();
                OnValidateVendorNoOnAfterGetLocationCode(Rec);
                GetDefaultBinCode();
                OnValidateVendorNoOnAfterGetDefaultBinCode(Rec);

                "Order Address Code" := '';

                if (Type = Type::Item) and ("No." <> '') and (not IsProdOrder()) then begin
                    if ItemVend.Get("Vendor No.", "No.", "Variant Code") then begin
                        IsHandled := false;
                        OnValidateVendorNoOnBeforeSetVendorItemNoFromItemVend(Rec, IsHandled);
                        if not IsHandled then
                            "Vendor Item No." := ItemVend."Vendor Item No.";
                        if not DoNotUpdateOrderReceiptDate then
                            UpdateOrderReceiptDate(ItemVend."Lead Time Calculation");
                    end else begin
                        GetPlanningParameters.AtSKU(TempSKU, "No.", "Variant Code", "Location Code");
                        if "Vendor No." = TempSKU."Vendor No." then
                            "Vendor Item No." := TempSKU."Vendor Item No."
                        else
                            "Vendor Item No." := '';
                    end;
                    OnValidateVendorNoOnBeforeGetDirectCost(Rec, xRec, CurrFieldNo);
                    GetDirectCost(FieldNo("Vendor No."))
                end;
                "Supply From" := "Vendor No.";
                OnValidateVendorNoOnAfterSetSupplyFrom(Rec);

                UpdateDim();
            end;
        }
        field(10; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
        }
        field(12; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            var
                ShouldExitDueDate: Boolean;
            begin
                if (CurrFieldNo = FieldNo("Due Date")) or (CurrentFieldNo = FieldNo("Due Date")) then
                    SetActionMessage();

                ShouldExitDueDate := "Due Date" = 0D;
                OnValidateDueDateOnAfterCalcShouldExitDueDate(Rec, xRec, CurrFieldNo, ShouldExitDueDate);
                if ShouldExitDueDate then
                    exit;

                if (CurrFieldNo = FieldNo("Due Date")) or (CurrentFieldNo = FieldNo("Due Date")) or (CurrFieldNo = FieldNo("Location Code")) then
                    if (Type = Type::Item) and
                       ("Planning Level" = 0)
                    then
                        Validate(
                          "Ending Date",
                          LeadTimeMgt.GetPlannedEndingDate("No.", "Location Code", "Variant Code", "Due Date", '', "Ref. Order Type"))
                    else
                        Validate("Ending Date", "Due Date");

                CheckDueDateToDemandDate();
            end;
        }
        field(13; "Requester ID"; Code[50])
        {
            Caption = 'Requester ID';
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit System.Security.User."User Selection";
            begin
                UserSelection.ValidateUserName("Requester ID");
            end;
        }
        field(14; Confirmed; Boolean)
        {
            Caption = 'Confirmed';
        }
        field(15; "Shortcut Dimension 1 Code"; Code[20])
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
        field(16; "Shortcut Dimension 2 Code"; Code[20])
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
        field(17; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            var
                ItemVend: Record "Item Vendor";
                ShouldGetDefaultBin: Boolean;
            begin
                ValidateLocationChange();
                CheckActionMessageNew();
                "Bin Code" := '';
                ReqLineReserve.VerifyChange(Rec, xRec);

                if Type = Type::Item then begin
                    UpdateReplenishmentSystem();
                    if "Location Code" <> xRec."Location Code" then
                        if ("Location Code" <> '') and ("No." <> '') and not IsDropShipment() then begin
                            GetLocation("Location Code");
                            ShouldGetDefaultBin := Location."Bin Mandatory" and not Location."Directed Put-away and Pick";
                            OnValidateLocationCodeOnBeforeGetDefaultBin(Rec, ShouldGetDefaultBin, Location, CurrFieldNo);
                            if ShouldGetDefaultBin then
                                WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", "Bin Code");
                        end;
                    if ItemVend.Get("Vendor No.", "No.", "Variant Code") then
                        "Vendor Item No." := ItemVend."Vendor Item No.";
                end;
                GetDirectCost(FieldNo("Location Code"));
                CreateDimFromDefaultDim();
                Validate("Due Date");
            end;
        }
        field(18; "Recurring Method"; Option)
        {
            BlankZero = true;
            Caption = 'Recurring Method';
            OptionCaption = ',Fixed,Variable';
            OptionMembers = ,"Fixed",Variable;
        }
        field(19; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(20; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';
        }
        field(21; "Order Date"; Date)
        {
            Caption = 'Order Date';

            trigger OnValidate()
            begin
                "Starting Date" := "Order Date";

                GetDirectCost(FieldNo("Order Date"));

                if CurrFieldNo = FieldNo("Order Date") then
                    Validate("Starting Date");
            end;
        }
        field(22; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
        }
        field(23; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
            Editable = false;
            TableRelation = "Sales Header"."No." where("Document Type" = const(Order));

            trigger OnValidate()
            begin
                ReqLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(24; "Sales Order Line No."; Integer)
        {
            Caption = 'Sales Order Line No.';
            Editable = false;

            trigger OnValidate()
            begin
                ReqLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(25; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            Editable = false;
            TableRelation = Customer;

            trigger OnValidate()
            begin
                if "Sell-to Customer No." = '' then
                    "Ship-to Code" := ''
                else
                    Rec.Validate("Ship-to Code", '');

                ReqLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(26; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            Editable = false;
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Sell-to Customer No."));

            trigger OnValidate()
            var
                Cust: Record Customer;
                ShipToAddr: Record "Ship-to Address";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeOnValidateShipToCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Ship-to Code" <> '' then begin
                    ShipToAddr.Get("Sell-to Customer No.", "Ship-to Code");
                    "Location Code" := ShipToAddr."Location Code";
                end else begin
                    Cust.Get("Sell-to Customer No.");
                    "Location Code" := Cust."Location Code";
                end;
            end;
        }
        field(28; "Order Address Code"; Code[10])
        {
            Caption = 'Order Address Code';
            TableRelation = "Order Address".Code where("Vendor No." = field("Vendor No."));
        }
        field(29; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            var
                Currency: Record Currency;
                CurrExchRate: Record "Currency Exchange Rate";
            begin
                Currency.Initialize("Currency Code");
                if "Currency Code" <> '' then begin
                    TestField("Order Date");
                    if PlanningResiliency then
                        CheckExchRate(Currency);
                    OnValidateCurrencyCodeOnBeforeUpdateCurrencyFactor(Rec, CurrExchRate);
                    Rec.Validate("Currency Factor", CurrExchRate.ExchangeRate("Order Date", "Currency Code"));
                end else
                    Rec.Validate("Currency Factor", 0);

                GetDirectCost(FieldNo("Currency Code"));
            end;
        }
        field(30; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;

            trigger OnValidate()
            var
                CurrExchRate: Record "Currency Exchange Rate";
            begin
                if "Currency Code" <> '' then
                    TestField("Currency Factor");
                if "Currency Factor" <> xRec."Currency Factor" then begin
                    OnValidateCurrencyFactorOnBeforeUpdateDirectUnitCost(Rec, CurrExchRate);
                    if xRec."Currency Factor" <> 0 then
                        "Direct Unit Cost" :=
                          CurrExchRate.ExchangeAmtFCYToLCY(
                            "Order Date", xRec."Currency Code", "Direct Unit Cost", xRec."Currency Factor");
                    if "Currency Factor" <> 0 then
                        "Direct Unit Cost" :=
                          CurrExchRate.ExchangeAmtLCYToFCY(
                            "Order Date", "Currency Code", "Direct Unit Cost", "Currency Factor");
                end;
            end;
        }
        field(31; "Reserved Quantity"; Decimal)
        {
            CalcFormula = sum("Reservation Entry".Quantity where("Source ID" = field("Worksheet Template Name"),
                                                                  "Source Ref. No." = field("Line No."),
                                                                  "Source Type" = const(246),
                                                                  "Source Subtype" = const("0"),
                                                                  "Source Batch Name" = field("Journal Batch Name"),
                                                                  "Source Prod. Order Line" = const(0),
                                                                  "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(43; "Purchaser Code"; Code[20])
        {
            Caption = 'Purchaser Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim();
            end;
        }
        field(73; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
            Editable = false;
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
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."));

            trigger OnValidate()
            var
                ItemVend: Record "Item Vendor";
                ShouldGetDefaultBin: Boolean;
            begin
                if "Variant Code" <> '' then begin
                    TestField(Type, Type::Item);
                    GetItemVariant();
                    ErrorIfItemVariantIsBlocked();
                end;
                CheckActionMessageNew();
                ReqLineReserve.VerifyChange(Rec, xRec);

                CalcFields("Reserved Qty. (Base)");
                TestField("Reserved Qty. (Base)", 0);

                GetDirectCost(FieldNo("Variant Code"));
                if "Variant Code" <> '' then begin
                    UpdateDescription();
                    UpdateReplenishmentSystem();
                    if "Variant Code" <> xRec."Variant Code" then begin
                        "Bin Code" := '';
                        if ("Location Code" <> '') and ("No." <> '') then begin
                            GetLocation("Location Code");
                            ShouldGetDefaultBin := Location."Bin Mandatory" and not Location."Directed Put-away and Pick";
                            OnBeforeGetDefaultBin(Rec, ShouldGetDefaultBin);
                            if ShouldGetDefaultBin then
                                WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", "Bin Code");
                        end;
                    end;
                    if ItemVend.Get("Vendor No.", "No.", "Variant Code") then
                        "Vendor Item No." := ItemVend."Vendor Item No.";
                end else
                    Validate("No.");
            end;
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"),
                                            "Item Filter" = field("No."),
                                            "Variant Filter" = field("Variant Code"));

            trigger OnValidate()
            begin
                CheckActionMessageNew();
                if (CurrFieldNo = FieldNo("Bin Code")) and
                   ("Action Message" <> "Action Message"::" ")
                then
                    TestField("Action Message", "Action Message"::New);
                TestField(Type, Type::Item);
                TestField("Location Code");
                GetItem();
                Item.TestField(Type, Item.Type::Inventory);
                if ("Bin Code" <> xRec."Bin Code") and ("Bin Code" <> '') then begin
                    GetLocation("Location Code");
                    Location.TestField("Bin Mandatory");
                    Location.TestField("Directed Put-away and Pick", false);
                    GetBin("Location Code", "Bin Code");
                    TestField("Location Code", Bin."Location Code");
                end;
                ReqLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5405; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(5406; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            "Unit of Measure";

            trigger OnValidate()
            begin
                CheckActionMessageNew();
                if (Type = Type::Item) and ("No." <> '') and (not IsProdOrder()) then
                    AssignItemUnitCostAndQuantitiesForUOM()
                else
                    if not IsProdOrder() then
                        "Qty. per Unit of Measure" := 1
                    else
                        "Qty. per Unit of Measure" := 0;

                OnValidateUnitofMeasureCodeOnBeforeGetDirectCost(Rec, Item);
                GetDirectCost(FieldNo("Unit of Measure Code"));

                if "Planning Line Origin" = "Planning Line Origin"::"Order Planning" then
                    SetSupplyQty("Demand Quantity (Base)", "Needed Quantity (Base)")
                else
                    Validate(Quantity);
            end;
        }
        field(5408; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantityBase(Rec, IsHandled, xRec, CurrFieldNo, CurrentFieldNo);
                if IsHandled then
                    exit;

                TestProdOrderNo();
                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(5431; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Source ID" = field("Worksheet Template Name"),
                                                                           "Source Ref. No." = field("Line No."),
                                                                           "Source Type" = const(246),
                                                                           "Source Subtype" = const("0"),
                                                                           "Source Batch Name" = field("Journal Batch Name"),
                                                                           "Source Prod. Order Line" = const(0),
                                                                           "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5520; "Demand Type"; Integer)
        {
            Caption = 'Demand Type';
            Editable = false;
            TableRelation = System.Reflection.AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(5521; "Demand Subtype"; Option)
        {
            Caption = 'Demand Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9";
        }
        field(5522; "Demand Order No."; Code[20])
        {
            Caption = 'Demand Order No.';
            Editable = false;
        }
        field(5525; "Demand Line No."; Integer)
        {
            Caption = 'Demand Line No.';
            Editable = false;
        }
        field(5526; "Demand Ref. No."; Integer)
        {
            Caption = 'Demand Ref. No.';
            Editable = false;
        }
        field(5527; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(5530; "Demand Date"; Date)
        {
            Caption = 'Demand Date';
            Editable = false;
        }
        field(5532; "Demand Quantity"; Decimal)
        {
            Caption = 'Demand Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5533; "Demand Quantity (Base)"; Decimal)
        {
            Caption = 'Demand Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5538; "Needed Quantity"; Decimal)
        {
            BlankZero = true;
            Caption = 'Needed Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5539; "Needed Quantity (Base)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Needed Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5540; Reserve; Boolean)
        {
            Caption = 'Reserve';

            trigger OnValidate()
            begin
                GetItem();
                if Item.Reserve <> Item.Reserve::Optional then
                    TestField(Reserve, Item.Reserve = Item.Reserve::Always);
                if Reserve and IsProdDemand() then
                    Error(Text030);
                TestField("Planning Level", 0);
                TestField("Planning Line Origin", "Planning Line Origin"::"Order Planning");
            end;
        }
        field(5541; "Qty. per UOM (Demand)"; Decimal)
        {
            Caption = 'Qty. per UOM (Demand)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5542; "Unit Of Measure Code (Demand)"; Code[10])
        {
            Caption = 'Unit Of Measure Code (Demand)';
            Editable = false;
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."));
        }
        field(5552; "Supply From"; Code[20])
        {
            Caption = 'Supply From';
            TableRelation = if ("Replenishment System" = const(Purchase)) Vendor
            else
            if ("Replenishment System" = const(Transfer)) Location where("Use As In-Transit" = const(false));

            trigger OnLookup()
            var
                Vend: Record Vendor;
            begin
                case "Replenishment System" of
                    "Replenishment System"::Purchase:
                        if LookupVendor(Vend, true) then
                            Validate("Supply From", Vend."No.");
                    "Replenishment System"::Transfer:
                        if LookupFromLocation(Location) then
                            Validate("Supply From", Location.Code);
                    else
                        OnLookupSupplyFromOnCaseReplenishmentSystemElse(Rec);
                end;
            end;

            trigger OnValidate()
            begin
                case "Replenishment System" of
                    "Replenishment System"::Purchase:
                        Validate("Vendor No.", "Supply From");
                    "Replenishment System"::Transfer:
                        Validate("Transfer-from Code", "Supply From");
                    else
                        OnValidateSupplyFromOnCaseReplenishmentSystemElse(Rec);
                end;
            end;
        }
        field(5553; "Original Item No."; Code[20])
        {
            Caption = 'Original Item No.';
            Editable = false;
            TableRelation = Item;
        }
        field(5554; "Original Variant Code"; Code[10])
        {
            Caption = 'Original Variant Code';
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Original Item No."));
        }
        field(5560; Level; Integer)
        {
            Caption = 'Level';
            Editable = false;
        }
        field(5563; "Demand Qty. Available"; Decimal)
        {
            Caption = 'Demand Qty. Available';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5590; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(5701; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = if (Type = const(Item)) "Item Category";
        }
        field(5702; Nonstock; Boolean)
        {
            Caption = 'Catalog';
        }
        field(5703; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;
        }
        field(5706; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            begin
                CheckActionMessageNew();
                "Supply From" := "Transfer-from Code";
            end;
        }
        field(5707; "Transfer Shipment Date"; Date)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Transfer Shipment Date';
            Editable = false;
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7002; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            MaxValue = 100;
            MinValue = 0;
        }
        field(7100; "Blanket Purch. Order Exists"; Boolean)
        {
            CalcFormula = exist("Purchase Line" where("Document Type" = const("Blanket Order"),
                                                       Type = const(Item),
                                                       "No." = field("No."),
                                                       "Outstanding Quantity" = filter(<> 0)));
            Caption = 'Blanket Purch. Order Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7110; "Custom Sorting Order"; Code[50])
        {
        }
        field(99000755; "MPS Order"; Boolean)
        {
            Caption = 'MPS Order';
        }
        field(99000756; "Planning Flexibility"; Enum "Reservation Planning Flexibility")
        {
            Caption = 'Planning Flexibility';

            trigger OnValidate()
            begin
                if "Planning Flexibility" <> xRec."Planning Flexibility" then
                    ReqLineReserve.UpdatePlanningFlexibility(Rec);
            end;
        }
        field(99000757; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
        }
        field(99000882; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(99000883; "Gen. Business Posting Group"; Code[20])
        {
            Caption = 'Gen. Business Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(99000884; "Low-Level Code"; Integer)
        {
            Caption = 'Low-Level Code';
            Editable = false;
        }
        field(99000888; "Original Quantity"; Decimal)
        {
            BlankZero = true;
            Caption = 'Original Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(99000889; "Finished Quantity"; Decimal)
        {
            Caption = 'Finished Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(99000890; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(99000891; "Original Due Date"; Date)
        {
            Caption = 'Original Due Date';
            Editable = false;
        }
        field(99000894; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                if Type = Type::Item then begin
                    OnValidateStartingDate(Rec);
                    Validate("Starting Time");
                end;
            end;
        }
        field(99000895; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            var
                ShouldSetDueDate: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateStartingTime(Rec, ShouldSetDueDate, IsHandled, CurrFieldNo, CurrentFieldNo, xRec);
                if IsHandled then
                    exit;

                TestField(Type, Type::Item);
                if ReqLine.Get("Worksheet Template Name", "Journal Batch Name", "Line No.") then
                    PlanningLineMgt.Recalculate(Rec, 0)
                else
                    CalcEndingDate('');

                CheckEndingDate(ValidateFields());

                ShouldSetDueDate := true;
                OnValidateStartingTimeOnBeforeSetDueDate(Rec, ShouldSetDueDate, xRec, CurrentFieldNo, CurrFieldNo);
                if ShouldSetDueDate then
                    SetDueDate();

                SetActionMessage();
                OnValidateStartingTimeOnBeforeUpdateDateTime(Rec);
                UpdateDatetime();
            end;
        }
        field(99000896; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                CheckEndingDate(ValidateFields());

                if Type = Type::Item then begin
                    Validate("Ending Time");
                    OnValidateEndingDate(Rec);
                end;
            end;
        }
        field(99000897; "Ending Time"; Time)
        {
            Caption = 'Ending Time';

            trigger OnValidate()
            var
                ShouldSetDueDate: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateEndingTime(Rec, ShouldSetDueDate, IsHandled, CurrFieldNo, CurrentFieldNo);
                if IsHandled then
                    exit;

                TestField(Type, Type::Item);
                if ReqLine.Get("Worksheet Template Name", "Journal Batch Name", "Line No.") then
                    PlanningLineMgt.RecalculateWithOptionalModify(Rec, 1, false)
                else
                    CalcStartingDate('');

                ShouldSetDueDate := (CurrFieldNo in [FieldNo("Ending Date"), FieldNo("Ending Date-Time")]) and (CurrentFieldNo <> FieldNo("Due Date"));
                OnValidateEndingTimeOnBeforeSetDueDate(Rec, ShouldSetDueDate);
                if ShouldSetDueDate then
                    SetDueDate();

                SetActionMessage();
                OnValidateEndingTimeOnBeforeUpdateDateTime(Rec);
                UpdateDatetime();
            end;
        }
        field(99000899; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
        }
        field(99000900; "Overhead Rate"; Decimal)
        {
            Caption = 'Overhead Rate';
            DecimalPlaces = 0 : 5;
        }
        field(99000901; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateUnitCost(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestField(Type, Type::Item);
                TestField("No.");

                Item.Get("No.");
                if Item."Costing Method" = Item."Costing Method"::Standard then begin
                    if CurrFieldNo = FieldNo("Unit Cost") then
                        Error(
                          Text006,
                          FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                    "Unit Cost" := Item."Unit Cost" * "Qty. per Unit of Measure";
                end;
                "Cost Amount" := Round("Unit Cost" * Quantity);
            end;
        }
        field(99000902; "Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount';
            Editable = false;
            MinValue = 0;
        }
        field(99000903; "Replenishment System"; Enum "Replenishment System")
        {
            Caption = 'Replenishment System';

            trigger OnValidate()
            var
                StockkeepingUnit: Record "Stockkeeping Unit";
            begin
                TestField(Type, Type::Item);
                CheckActionMessageNew();
                if ValidateFields() and
                   ("Replenishment System" = xRec."Replenishment System") and
                   ("No." = xRec."No.") and
                   ("Location Code" = xRec."Location Code") and
                   ("Variant Code" = xRec."Variant Code")
                then
                    exit;

                TestField(Type, Type::Item);
                TestField("No.");
                GetItem();

                if Item.IsNonInventoriableType() then
                    TestField("Replenishment System", "Replenishment System"::Purchase);

                StockkeepingUnit := Item.GetSKU("Location Code", "Variant Code");
                OnValidateReplenishmentSystemOnAfterSetStockkeepingUnit(Rec, StockkeepingUnit, Subcontracting);

                "Supply From" := '';

                case "Replenishment System" of
                    "Replenishment System"::Purchase:
                        SetReplenishmentSystemFromPurchase(StockkeepingUnit);
                    "Replenishment System"::Transfer:
                        SetReplenishmentSystemFromTransfer(StockkeepingUnit);
                    else
                        OnValidateReplenishmentSystemCaseElse(Rec, StockkeepingUnit);
                end;
            end;
        }
        field(99000904; "Ref. Order No."; Code[20])
        {
            Caption = 'Ref. Order No.';
            Editable = false;
            TableRelation = if ("Ref. Order Type" = const(Purchase)) "Purchase Header"."No." where("Document Type" = const(Order))
            else
            if ("Ref. Order Type" = const(Transfer)) "Transfer Header"."No." where("No." = field("Ref. Order No."));
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnLookupRefOrderNoOnBeforeOpenPage(Rec, IsHandled);
                if not IsHandled then
                    LookupRefOrderNo();
            end;
        }
        field(99000905; "Ref. Order Type"; Enum "Requisition Ref. Order Type")
        {
            Caption = 'Ref. Order Type';
            Editable = false;
        }
        field(99000906; "Ref. Order Status"; Enum Microsoft.Manufacturing.Document."Production Order Status")
        {
            BlankZero = true;
            Caption = 'Ref. Order Status';
            Editable = false;
        }
        field(99000907; "Ref. Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Ref. Line No.';
            Editable = false;
        }
        field(99000908; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(99000910; "Expected Component Cost Amt."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Planning Component"."Cost Amount" where("Worksheet Template Name" = field("Worksheet Template Name"),
                                                                        "Worksheet Batch Name" = field("Journal Batch Name"),
                                                                        "Worksheet Line No." = field("Line No.")));
            Caption = 'Expected Component Cost Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000911; "Finished Qty. (Base)"; Decimal)
        {
            Caption = 'Finished Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(99000912; "Remaining Qty. (Base)"; Decimal)
        {
            Caption = 'Remaining Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(99000913; "Related to Planning Line"; Integer)
        {
            Caption = 'Related to Planning Line';
            Editable = false;
        }
        field(99000914; "Planning Level"; Integer)
        {
            Caption = 'Planning Level';
            Editable = false;
        }
        field(99000915; "Planning Line Origin"; Enum "Planning Line Origin Type")
        {
            Caption = 'Planning Line Origin';
            Editable = false;
        }
        field(99000916; "Action Message"; Enum "Action Message Type")
        {
            Caption = 'Action Message';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateActionMessage(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if ("Action Message" = xRec."Action Message") or
                   (("Action Message" in ["Action Message"::" ", "Action Message"::New]) and
                    (xRec."Action Message" in ["Action Message"::" ", "Action Message"::New]))
                then
                    exit;
                TestField("Action Message", xRec."Action Message");
            end;
        }
        field(99000917; "Accept Action Message"; Boolean)
        {
            Caption = 'Accept Action Message';

            trigger OnValidate()
            begin
                if "Action Message" = "Action Message"::" " then
                    Validate("Action Message", "Action Message"::New);
            end;
        }
        field(99000918; "Net Quantity (Base)"; Decimal)
        {
            Caption = 'Net Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(99000919; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';

            trigger OnValidate()
            begin
                "Starting Date" := DT2Date("Starting Date-Time");
                "Starting Time" := DT2Time("Starting Date-Time");

                Validate("Starting Date");
            end;
        }
        field(99000920; "Ending Date-Time"; DateTime)
        {
            Caption = 'Ending Date-Time';

            trigger OnValidate()
            begin
                "Ending Date" := DT2Date("Ending Date-Time");
                "Ending Time" := DT2Time("Ending Date-Time");

                Validate("Ending Date");
            end;
        }
        field(99000921; "Order Promising ID"; Code[20])
        {
            Caption = 'Order Promising ID';
        }
        field(99000922; "Order Promising Line No."; Integer)
        {
            Caption = 'Order Promising Line No.';
        }
        field(99000923; "Order Promising Line ID"; Integer)
        {
            Caption = 'Order Promising Line ID';
        }
    }

    keys
    {
        key(Key1; "Worksheet Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Worksheet Template Name", "Journal Batch Name", "Vendor No.", "Sell-to Customer No.", "Ship-to Code", "Order Address Code", "Currency Code", "Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Location Code", "Transfer-from Code", "Purchasing Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key3; Type, "No.", "Variant Code", "Location Code", "Sales Order No.", "Planning Line Origin", "Due Date", "Drop Shipment")
        {
            IncludedFields = "Quantity (Base)";
        }
        key(Key4; Type, "No.", "Variant Code", "Location Code", "Sales Order No.", "Order Date")
        {
            IncludedFields = "Quantity (Base)";
        }
        key(Key5; Type, "No.", "Variant Code", "Location Code", "Starting Date")
        {
            IncludedFields = "Quantity (Base)";
        }
        key(Key6; "Worksheet Template Name", "Journal Batch Name", Type, "No.", "Due Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key7; "Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.")
        {
        }
        key(Key8; "Replenishment System", Type, "No.", "Variant Code", "Transfer-from Code", "Transfer Shipment Date")
        {
            IncludedFields = "Quantity (Base)";
        }
        key(Key9; "Order Promising ID", "Order Promising Line ID", "Order Promising Line No.")
        {
        }
        key(Key10; "User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.")
        {
        }
        key(Key11; "User ID", "Demand Type", "Demand Subtype", "Demand Order No.", "Demand Line No.", "Demand Ref. No.")
        {
        }
        key(Key12; "User ID", "Worksheet Template Name", "Journal Batch Name", "Line No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key13; "Worksheet Template Name", "Journal Batch Name", "Custom Sorting Order")
        {
        }
        key(Key14; "Demand Order No.", "Demand Ref. No.", "Demand Subtype", "Demand Line No.", "Demand Type")
        {
            IncludedFields = "User ID";
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "No.", Description, Quantity, "Replenishment System", "Order Date")
        { }
    }

    trigger OnDelete()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;

        // Lines are deleted 1 by 1, this actually check if this is the last line in the Requisition Worksheet Name.
        RequisitionLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", "Journal Batch Name");
        RequisitionLine.SetFilter("Line No.", '<>%1', "Line No.");
        if RequisitionLine.IsEmpty() then
            if RequisitionWkshName.Get(Rec."Worksheet Template Name", Rec."Journal Batch Name") then
                ApprovalsMgmt.PreventDeletingRecordWithOpenApprovalEntry(RequisitionWkshName);

        ReqLine.Reset();
        ReqLine.Get("Worksheet Template Name", "Journal Batch Name", "Line No.");
        while (ReqLine.Next() <> 0) and (ReqLine.Level > Level) do
            ReqLine.Delete(true);

        ReqLineReserve.DeleteLine(Rec);

        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);

        DeleteRelations();
    end;

    trigger OnInsert()
    var
        Rec2: Record "Requisition Line";
    begin
        if CurrentKey <> Rec2.CurrentKey then begin
            Rec2 := Rec;
            Rec2.SetRecFilter();
            Rec2.SetRange("Line No.");
            if Rec2.FindLast() then
                "Line No." := Rec2."Line No." + 10000;
        end;

        ReqLineReserve.VerifyQuantity(Rec, xRec);

        ReqWkshTemplate.Get("Worksheet Template Name");
        ReqWkshName.Get("Worksheet Template Name", "Journal Batch Name");

        ApprovalsMgmt.PreventInsertRecIfOpenApprovalEntryExist(ReqWkshName);

        Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");

        OnAfterOnInsert(Rec, ReqWkshTemplate, ReqWkshName);
    end;

    trigger OnModify()
    begin
        CheckOpenApprovalEntryExistForCurrentUser();
        ReqLineReserve.VerifyChange(Rec, xRec);
    end;

    trigger OnRename()
    begin
        ApprovalsMgmt.OnRenameRecordInApprovalRequest(xRec.RecordId(), RecordId());
        Error(Text004, TableCaption);
    end;

    var
        ReqWkshName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
        ItemVariant: Record "Item Variant";
        Location: Record Location;
        Bin: Record Bin;
        ReqLineReserve: Codeunit "Req. Line-Reserve";
        UOMMgt: Codeunit "Unit of Measure Management";
        DimMgt: Codeunit DimensionManagement;
        LeadTimeMgt: Codeunit "Lead-Time Management";
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        WMSManagement: Codeunit "WMS Management";
        ConfirmManagement: Codeunit System.Utilities."Confirm Management";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        BlockReservation: Boolean;
        DoNotUpdateOrderReceiptDate: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'You cannot rename a %1.';
        Text005: Label '%1 %2 does not exist.';
        Text006: Label 'You cannot change %1 when %2 is %3.';
        Text007: Label 'There is no %1 for this line.';
#pragma warning restore AA0470
        Text008: Label 'There is no replenishment order for this line.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text028: Label 'The %1 on this %2 must match the %1 on the sales order line it is associated with.';
        Text029: Label 'Line %1 has a %2 that exceeds the %3.';
#pragma warning restore AA0470
        Text030: Label 'You cannot reserve components with status Planned.';
#pragma warning disable AA0470
        Text031: Label '%1 %2 is blocked.';
        Text037: Label 'The currency exchange rate for the %1 %2 that vendor %3 uses on the order date %4, does not have an %5 specified.';
        Text038: Label 'The currency exchange rate for the %1 %2 that vendor %3 uses on the order date %4, does not exist.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ConfirmDeleteAllLinesQst: Label 'Go ahead and delete all lines?';
        BlockedErr: Label 'You cannot choose %1 %2 because the %3 check box is selected on its %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        ItemVariantPrimaryKeyLbl: Label '%1, %2', Comment = '%1 - Item No., %2 - Variant Code', Locked = true;

    protected var
        Item: Record Item;
        ReqWkshTemplate: Record "Req. Wksh. Template";
        TempPlanningErrorLog: Record "Planning Error Log" temporary;
        PlanningLineMgt: Codeunit "Planning Line Management";
        CurrentFieldNo: Integer;
        PlanningResiliency: Boolean;
        Subcontracting: Boolean;
        MissingFieldValueErr: Label '%1 %2 has no %3 defined.', Comment = '%1 %2 - Item No., %3 - field caption';

    local procedure AssignItemUnitCostAndQuantitiesForUOM()
    var
        IsHandled: Boolean;
    begin
        GetItem();
        IsHandled := false;
        OnBeforeAssignItemUnitCostAndQuantitiesForUOM(Rec, xRec, Item, IsHandled);
        if IsHandled then
            exit;

        "Unit Cost" := Item."Unit Cost";
        "Overhead Rate" := Item."Overhead Rate";
        "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
        "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
        "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");
        if "Unit of Measure Code" <> '' then begin
            "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
            "Unit Cost" := Round(Item."Unit Cost" * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        end else
            "Qty. per Unit of Measure" := 1;

    end;

    local procedure CopyFromGLAcc()
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Get("No.");
        GLAcc.CheckGLAcc();
        GLAcc.TestField("Direct Posting", true);
        CopyDescriptionFromGLAcc(GLAcc);
    end;

    local procedure CopyDescriptionFromGLAcc(GLAcc: Record "G/L Account")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDescriptionFromGLAcc(Rec, IsHandled);
        if IsHandled then
            exit;

        Description := GLAcc.Name;
    end;

    procedure CopyFromItem()
    begin
        GetItem();
        OnBeforeCopyFromItem(Rec, Item, xRec, CurrFieldNo, TempPlanningErrorLog, PlanningResiliency);

        if PlanningResiliency and Item.Blocked then
            TempPlanningErrorLog.SetError(
              StrSubstNo(Text031, Item.TableCaption(), Item."No."),
              Database::Item, CopyStr(Item.GetPosition(), 1, 250));
        CheckBlockedItem();
        "Low-Level Code" := Item."Low-Level Code";
        "Item Category Code" := Item."Item Category Code";
        "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        "Gen. Business Posting Group" := '';
        if PlanningResiliency and (Item."Base Unit of Measure" = '') then
            TempPlanningErrorLog.SetError(
              StrSubstNo(MissingFieldValueErr, Item.TableCaption(), Item."No.",
                Item.FieldCaption("Base Unit of Measure")),
              Database::Item, CopyStr(Item.GetPosition(), 1, 250));
        Item.TestField("Base Unit of Measure");
        "Indirect Cost %" := Item."Indirect Cost %";
        UpdateReplenishmentSystem();
        "Accept Action Message" := true;
        "Action Message" := "Action Message"::New;
        GetDirectCost(FieldNo("No."));
        SetFromBinCode();

        OnAfterCopyFromItem(Rec, Item, CurrFieldNo);
    end;

    local procedure CheckBlockedItem()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBlockedItem(Rec, IsHandled);
        if IsHandled then
            exit;

        Item.TestField(Blocked, false);
    end;

    local procedure GetItem()
    begin
        TestField("No.");
        if "No." <> Item."No." then
            Item.Get("No.");
    end;

    procedure ShowReservation()
    var
        ReservationPage: Page Reservation;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowReservation(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::Item);
        TestField("No.");
        Clear(ReservationPage);
        ReservationPage.SetReservSource(Rec);
        ReservationPage.RunModal();
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        ReservEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservEntry);
        if Modal then
            PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
    end;

    procedure UpdateOrderReceiptDate(LeadTimeCalc: DateFormula)
    var
        IsHandled: Boolean;
    begin
        OnBeforeUpdateOrderReceiptDate(Rec, LeadTimeCalc, IsHandled);
        if IsHandled then
            exit;

        CalcFields("Reserved Qty. (Base)");
        if "Reserved Qty. (Base)" = 0 then begin
            if "Order Date" <> 0D then
                "Starting Date" := "Order Date"
            else begin
                "Starting Date" := WorkDate();
                "Order Date" := "Starting Date";
            end;
            CalcEndingDate(Format(LeadTimeCalc));
            CheckEndingDate(ValidateFields());
            SetDueDate();
        end else
            if (Format(LeadTimeCalc) = '') or ("Due Date" = 0D) then
                "Order Date" := 0D
            else
                if "Due Date" <> 0D then begin
                    "Ending Date" :=
                      LeadTimeMgt.GetPlannedEndingDate(
                        "No.", "Location Code", "Variant Code", "Due Date", '', "Ref. Order Type");
                    CalcStartingDate(Format(LeadTimeCalc));
                end;

        SetActionMessage();
        UpdateDatetime();

        OnAfterUpdateOrderReceiptDate(Rec, LeadTimeCalc);
    end;

    procedure LookupVendor(var Vend: Record Vendor; PreferItemVendorCatalog: Boolean): Boolean
    var
        ItemVend: Record "Item Vendor";
        LookupThroughItemVendorCatalog: Boolean;
        IsHandled: Boolean;
        IsVendorSelected: Boolean;
    begin
        IsHandled := false;
        IsVendorSelected := false;
        OnBeforeLookupVendor(Rec, Vend, PreferItemVendorCatalog, IsHandled, IsVendorSelected);
        if IsHandled then
            exit(IsVendorSelected);

        if (Type = Type::Item) and ItemVend.ReadPermission then begin
            ItemVend.Init();
            ItemVend.SetRange("Item No.", "No.");
            ItemVend.SetRange("Vendor No.", "Vendor No.");
            if "Variant Code" <> '' then
                ItemVend.SetRange("Variant Code", "Variant Code");
            if not ItemVend.FindLast() then begin
                ItemVend."Item No." := "No.";
                ItemVend."Variant Code" := "Variant Code";
                ItemVend."Vendor No." := "Vendor No.";
            end;
            ItemVend.SetRange("Vendor No.");
            LookupThroughItemVendorCatalog := not ItemVend.IsEmpty() or PreferItemVendorCatalog;
        end;

        if LookupThroughItemVendorCatalog then begin
            if PAGE.RunModal(0, ItemVend) = ACTION::LookupOK then
                exit(Vend.Get(ItemVend."Vendor No."));
        end else begin
            Vend."No." := "Vendor No.";
            exit(PAGE.RunModal(0, Vend) = ACTION::LookupOK);
        end;
    end;

    procedure LookupFromLocation(var Location2: Record Location): Boolean
    begin
        Location2.Code := "Transfer-from Code";
        Location2.SetRange("Use As In-Transit", false);
        OnLookupFromLocationOnAfterSetFilters(Rec, Location2);
        exit(PAGE.RunModal(0, Location2) = ACTION::LookupOK);
    end;

    procedure UpdateDescription()
    var
        ItemVariantLocal: Record "Item Variant";
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDescription(Rec, CurrFieldNo, IsHandled, xRec);
        if IsHandled then
            exit;

        if (Type <> Type::Item) or ("No." = '') then
            exit;


        IsHandled := false;
        OnUpdateWorkCenterDescription(Rec, IsHandled);
        if IsHandled then
            exit;

        if Rec."Variant Code" = '' then begin
            GetItem();
            Description := Item.Description;
            "Description 2" := Item."Description 2";
            if Item."Purch. Unit of Measure" = '' then
                "Unit of Measure Code" := Item."Base Unit of Measure";
            OnUpdateDescriptionFromItem(Rec, Item);
        end else begin
            ItemVariantLocal.Get("No.", "Variant Code");
            Description := ItemVariantLocal.Description;
            "Description 2" := ItemVariantLocal."Description 2";
            OnUpdateDescriptionFromItemVariant(Rec, ItemVariantLocal);
        end;

        if SalesLine.Get(SalesLine."Document Type"::Order, "Sales Order No.", "Sales Order Line No.") then begin
            Description := SalesLine.Description;
            "Description 2" := SalesLine."Description 2";
            OnUpdateDescriptionFromSalesLine(Rec, SalesLine);
        end;

        if "Vendor No." <> '' then
            UpdateItemReferenceDescription();
        OnAfterUpdateDescription(Rec, Item, ItemVariantLocal, CurrFieldNo);
    end;

    local procedure ValidateItemDescriptionAndQuantity(Vendor: Record Vendor)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateItemDescriptionAndQuantity(Rec, Vendor, IsHandled);
        if IsHandled then
            exit;

        if Type = Type::Item then
            UpdateDescription();
        Validate(Quantity);
    end;

    local procedure UpdateItemReferenceDescription()
    var
        ItemReference: Record "Item Reference";
        ItemTranslation: Record "Item Translation";
        Vendor: Record Vendor;
        IsHandled: Boolean;
    begin
        OnBeforeUpdateItemReferenceDescription(Rec, IsHandled);
        if IsHandled then
            exit;
        if not ItemReference.FindItemDescription(
                Description, "Description 2", "No.", "Variant Code", "Unit of Measure Code",
                Rec."Order Date", Enum::"Item Reference Type"::Vendor, "Vendor No.")
        then begin
            Vendor.Get("Vendor No.");
            if Vendor."Language Code" <> '' then
                if ItemTranslation.Get("No.", "Variant Code", Vendor."Language Code") then begin
                    Description := ItemTranslation.Description;
                    "Description 2" := ItemTranslation."Description 2";
                    OnUpdateDescriptionFromItemTranslation(Rec, ItemTranslation);
                end;
        end;
    end;

    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        ReqLineReserve.Block(SetBlock);
    end;

    procedure BlockDynamicTrackingOnComp(SetBlock: Boolean)
    begin
        BlockReservation := SetBlock;
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, DefaultDimSource, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup.Purchases, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        if "Ref. Order No." <> '' then
            GetDimFromRefOrderLine(true);

        if ("Demand Type" = Database::"Job Planning Line") then
            UpdateJobTaskDimensions();

        OnAfterCreateDim(Rec, xRec);
    end;

    local procedure UpdateDim()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource);
        UpdateDim(DefaultDimSource);
    end;

    procedure UpdateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SalesLine: Record "Sales Line";
        DimManagement: Codeunit DimensionManagement;
        DimSetIDArr: array[10] of Integer;
    begin
        CreateDim(DefaultDimSource);
        if "Demand Type" <> Database::"Sales Line" then
            exit;
        SalesLine.Get("Demand Subtype", "Demand Order No.", "Demand Line No.");
        DimSetIDArr[2] := SalesLine."Dimension Set ID";
        DimSetIDArr[1] := "Dimension Set ID";
        DimSetIDArr[1] := DimManagement.GetCombinedDimensionSetID(DimSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        Validate("Dimension Set ID", DimSetIDArr[1]);

        OnAfterUpdateDim(Rec, DefaultDimSource);
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

    procedure OpenItemTrackingLines()
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        TestField("Quantity (Base)");
        ReqLineReserve.CallItemTracking(Rec);
    end;

    procedure DeleteRelations()
    begin
        DeleteRelations(false);
    end;

    procedure DeleteRelations(DeleteAllLines: Boolean)
    var
        PlanningComponent: Record "Planning Component";
        UntrackedPlanningElement: Record "Untracked Planning Element";
        ReservationEntry: Record "Reservation Entry";
        PlngComponentReserve: Codeunit "Plng. Component-Reserve";
        IsHandled: Boolean;
    begin
        if not DeleteAllLines then begin
            if Type <> Type::Item then
                exit;
            PlanningComponent.SetRange("Worksheet Line No.", "Line No.");
            UntrackedPlanningElement.SetRange("Worksheet Line No.", "Line No.");
        end;

        PlanningComponent.SetRange("Worksheet Template Name", "Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", "Journal Batch Name");
        if PlanningComponent.FindSet() then
            repeat
                PlanningComponent.BlockDynamicTracking(BlockReservation);
                IsHandled := false;
                OnDeleteRelationsOnBeforePlanningComponentDelete(Rec, IsHandled);
                if not IsHandled then
                    if not DeleteAllLines then
                        PlanningComponent.Delete(true)
                    else
                        PlanningComponent.Delete(PlngComponentReserve.FindReservEntry(PlanningComponent, ReservationEntry));
            until PlanningComponent.Next() = 0;

        UntrackedPlanningElement.SetRange("Worksheet Template Name", "Worksheet Template Name");
        UntrackedPlanningElement.SetRange("Worksheet Batch Name", "Journal Batch Name");
        if not UntrackedPlanningElement.IsEmpty() then
            UntrackedPlanningElement.DeleteAll();

        OnAfterDeleteRelations(Rec, DeleteAllLines);
    end;

    procedure DeleteMultiLevel()
    var
        ReqLine2: Record "Requisition Line";
    begin
        OnBeforeDeleteMultiLevel(Rec);
        ReqLine2.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        ReqLine2.SetRange("Ref. Order Type", "Ref. Order Type");
        ReqLine2.SetRange("Ref. Order Status", "Ref. Order Status");
        ReqLine2.SetRange("Ref. Order No.", "Ref. Order No.");
        ReqLine2.SetRange("Worksheet Template Name", "Worksheet Template Name");
        ReqLine2.SetRange("Journal Batch Name", "Journal Batch Name");
        ReqLine2.SetFilter("Line No.", '<>%1', "Line No.");
        ReqLine2.SetFilter("Planning Level", '>0');
        OnDeleteMultiLevelOnAfterSetFilterReqLine2(Rec, ReqLine2);
        if ReqLine2.Find('-') then
            repeat
                ReqLineReserve.DeleteLine(ReqLine2);
                ReqLine2.CalcFields("Reserved Qty. (Base)");
                ReqLine2.TestField("Reserved Qty. (Base)", 0);
                ReqLine2.DeleteRelations();
                ReqLine2.Delete();
            until ReqLine2.Next() = 0;
        OnAfterDeleteMultiLevel(Rec);
    end;

    procedure ClearPlanningWorksheet(SkipConfirm: Boolean)
    var
        RequisitionLine: Record "Requisition Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        RequisitionLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if not RequisitionLine.FindSet() then
            exit;

        if GuiAllowed and not SkipConfirm then
            if not Confirm(ConfirmDeleteAllLinesQst) then
                exit;

        repeat
            if ReqLineReserve.FindReservEntry(RequisitionLine, ReservationEntry) then begin
                ReqLineReserve.DeleteLine(RequisitionLine);
                RequisitionLine.TestField("Reserved Qty. (Base)", 0);
            end;
            OnClearPlanningWorksheetOnBeforeRequisitionLineDelete(RequisitionLine);
            RequisitionLine.Delete();
        until RequisitionLine.Next() = 0;

        DeleteRelations(true);
    end;

    internal procedure ClearOrderPlanningWorksheet()
    var
        RequisitionLine: Record "Requisition Line";
        OrderPlanningMgt: Codeunit "Order Planning Mgt.";
    begin
        if IsEmpty() then
            exit;

        if not ConfirmManagement.GetResponse(ConfirmDeleteAllLinesQst, false) then
            exit;

        DeleteAll();
        OrderPlanningMgt.PrepareRequisitionRecord(RequisitionLine);
    end;

    /// <summary>
    /// Populates values of 'Order Date', 'Recurring Method' and 'Price Calculation Method' fields for a new requisition line.
    /// </summary>
    /// <param name="LastReqLine">Source requisition line record. </param>
    procedure SetUpNewLine(LastReqLine: Record "Requisition Line")
    var
        Vendor: Record Vendor;
    begin
        ReqWkshTemplate.Get("Worksheet Template Name");
        ReqWkshName.Get("Worksheet Template Name", "Journal Batch Name");
        ReqLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
        ReqLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if ReqLine.Find('-') then
            "Order Date" := LastReqLine."Order Date"
        else
            "Order Date" := WorkDate();

        "Recurring Method" := LastReqLine."Recurring Method";
        "Price Calculation Method" := Vendor.GetPriceCalculationMethod();

        OnAfterSetUpNewLine(Rec, LastReqLine);
    end;

    local procedure CheckEndingDate(ShowWarning: Boolean)
    var
        CheckDateConflict: Codeunit "Reservation-Check Date Confl.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckEndingDate(Rec, ShowWarning, IsHandled);
        if IsHandled then
            exit;

        CheckDateConflict.ReqLineCheck(Rec, ShowWarning);
        ReqLineReserve.VerifyChange(Rec, xRec);
    end;

    /// <summary>
    /// Sets the value of field 'Due Date' for the current requisition line.
    /// </summary>
    procedure SetDueDate()
    begin
        if "Ending Date" = 0D then
            exit;
        if (Type = Type::Item) and
           ("Planning Level" = 0)
        then
            "Due Date" :=
              LeadTimeMgt.GetPlannedDueDate("No.", "Location Code", "Variant Code", "Ending Date", '', "Ref. Order Type")
        else
            "Due Date" := "Ending Date";

        CheckDueDateToDemandDate();

        OnAfterSetDueDate(Rec);
    end;

    /// <summary>
    /// Sets the global variable 'CurrentFieldNo'.
    /// </summary>
    /// <param name="NewCurrFieldNo">Specified field number. </param>
    procedure SetCurrFieldNo(NewCurrFieldNo: Integer)
    begin
        CurrentFieldNo := NewCurrFieldNo;
    end;

    procedure CheckDueDateToDemandDate()
    begin
        if ("Planning Line Origin" = "Planning Line Origin"::"Order Planning") and
           ("Due Date" > "Demand Date") and
           ("Demand Date" <> 0D) and
           ValidateFields()
        then
            Message(Text029, "Line No.", FieldCaption("Due Date"), FieldCaption("Demand Date"));
    end;

    procedure CheckActionMessageNew()
    begin
        if "Action Message" <> "Action Message"::" " then
            if ShouldCheckNewActionMessage() then
                TestField("Action Message", "Action Message"::New);
    end;

    local procedure ShouldCheckNewActionMessage() ShouldCheck: Boolean
    begin
        ShouldCheck :=
            CurrFieldNo in [FieldNo(Type),
                            FieldNo("No."),
                            FieldNo("Variant Code"),
                            FieldNo("Location Code"),
                            FieldNo("Bin Code"),
                            FieldNo("Replenishment System"),
                            FieldNo("Unit of Measure Code"),
                            FieldNo("Vendor No."),
                            FieldNo("Transfer-from Code")];

        OnAfterShouldCheckNewActionMessage(Rec, CurrFieldNo, ShouldCheck);
    end;

    procedure SetActionMessage()
    begin
        if ValidateFields() and
           ("Action Message" <> "Action Message"::" ") and
           ("Action Message" <> "Action Message"::New)
        then begin
            if (Quantity <> xRec.Quantity) and ("Original Quantity" = 0) then
                "Original Quantity" := xRec.Quantity;
            if ("Due Date" <> xRec."Due Date") and ("Original Due Date" = 0D) then
                "Original Due Date" := xRec."Due Date";
            if Quantity = 0 then
                "Action Message" := "Action Message"::Cancel
            else
                if "Original Quantity" <> 0 then
                    if "Original Due Date" <> 0D then
                        "Action Message" := "Action Message"::"Resched. & Chg. Qty."
                    else
                        "Action Message" := "Action Message"::"Change Qty."
                else
                    if "Original Due Date" <> 0D then
                        "Action Message" := "Action Message"::Reschedule;

            if "Action Message" <> xRec."Action Message" then
                Clear("Planning Line Origin");
        end;
    end;

    procedure ValidateFields() Result: Boolean
    begin
        Result := (CurrFieldNo <> 0) or (CurrentFieldNo <> 0);
        OnAfterValidateFields(Rec, CurrFieldNo, CurrentFieldNo, Result);
    end;

    /// <summary>
    /// Prepares and transfers relevant field values from provided purchase line to the current requisition line.
    /// </summary>
    /// <param name="PurchOrderLine">Source purchase line record. </param>
    /// <remarks>In case no purchase header is found for the provided 'PurchOrderLine', error will be invoked. </remarks>
    procedure GetPurchOrderLine(PurchOrderLine: Record "Purchase Line")
    var
        PurchHeader2: Record "Purchase Header";
    begin
        if PurchOrderLine.Type <> PurchOrderLine.Type::Item then
            exit;
        PurchOrderLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        PurchHeader2.Get(PurchOrderLine."Document Type", PurchOrderLine."Document No.");
        Item.Get(PurchOrderLine."No.");

        TransferFromPurchaseLine(PurchOrderLine);
    end;

    /// <summary>
    /// Prepares and transfers relevant field values from provided transfer line to the current requisition line.
    /// </summary>
    /// <param name="TransLine">Source transfer line record. </param>
    /// <remarks>In case no transfer header is found for the provided 'TransLine', error will be invoked. </remarks>
    procedure GetTransLine(TransLine: Record "Transfer Line")
    var
        TransHeader: Record "Transfer Header";
    begin
        TransLine.CalcFields(
          "Reserved Quantity Inbnd.",
          "Reserved Quantity Outbnd.",
          "Reserved Qty. Inbnd. (Base)",
          "Reserved Qty. Outbnd. (Base)");
        TransHeader.Get(TransLine."Document No.");
        Item.Get(TransLine."Item No.");

        TransferFromTransLine(TransLine);
    end;

    /// <summary>
    /// Runs the report 'Get Action Messages' in reference to the current requisition line. 
    /// </summary>
    procedure GetActionMessages()
    var
        GetActionMsgReport: Report "Get Action Messages";
    begin
        GetActionMsgReport.SetTemplAndWorksheet("Worksheet Template Name", "Journal Batch Name");
        GetActionMsgReport.RunModal();
    end;

    /// <summary>
    /// Calculates values of fields 'Remaining Quantity' and 'Remaining Quantity (Base)' for the current requisition line.
    /// </summary>
    /// <param name="RemainingQty">Parameter to hold the value of field 'Remaining Quantity'. </param>
    /// <param name="RemainingQtyBase">Parameter to hold the value of field 'Remaining Quantity (Base)'. </param>
    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        RemainingQty := 0;
        RemainingQtyBase := "Net Quantity (Base)" - Abs("Reserved Qty. (Base)");
    end;

    /// <summary>
    /// Calculates reserve quantity information for the current requisition line.
    /// </summary>
    /// <param name="QtyReserved">Parameter to hold the value of field 'Reserved Quantity'. </param>
    /// <param name="QtyReservedBase">Parameter to hold the value of field 'Reserved Qty. (Base)'. </param>
    /// <param name="QtyToReserve">Parameter to hold the quantity to reserve. </param>
    /// <param name="QtyToReserveBase">Parameter to hold the quantity to reserve base value. </param>
    /// <returns>Returns quantity per unit of measure information for the current record. </returns>
    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReservationQty(Rec, QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, Result, IsHandled);
        if IsHandled then
            exit(Result);

        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := "Reserved Quantity";
        QtyReservedBase := "Reserved Qty. (Base)";
        QtyToReserve := Quantity;
        QtyToReserveBase := "Quantity (Base)";
        exit("Qty. per Unit of Measure");
    end;

    /// <summary>
    /// Combines values of 'Worksheet Template Name', 'Journal Batch Name' and 'No.' fields of the current requisition line. 
    /// </summary>
    /// <returns>Returns source requisiton line information. </returns>
    procedure GetSourceCaption(): Text
    begin
        exit(StrSubstNo('%1 %2 %3', "Worksheet Template Name", "Journal Batch Name", "No."));
    end;

    /// <summary>
    /// Copies values from the current record to specified reservation entry record.
    /// </summary>
    /// <param name="ReservEntry">Specified reservation entry. </param>
    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(
            Database::"Requisition Line", 0, "Worksheet Template Name", "Line No.", "Journal Batch Name", 0);
        ReservEntry.SetItemData("No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        if Type <> Type::Item then
            ReservEntry."Item No." := '';
        ReservEntry."Expected Receipt Date" := "Due Date";
        ReservEntry."Shipment Date" := "Due Date";
        ReservEntry."Planning Flexibility" := "Planning Flexibility";

        OnAfterSetReservationEntry(ReservEntry, Rec);
    end;

    /// <summary>
    /// Sets filters from the current requisition line to specified reservation entry record.
    /// </summary>
    /// <param name="ReservEntry">Specified reservation entry. </param>
    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(Database::"Requisition Line", 0, "Worksheet Template Name", "Line No.", false);
        ReservEntry.SetSourceFilter("Journal Batch Name", 0);

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    /// <summary>
    /// Checks whether reservation entries related to the current requisition line exist. 
    /// </summary>
    /// <returns>Returns 'true' if reservation entry is found, otherwise 'false'. </returns>
    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        exit(not ReservEntry.IsEmpty);
    end;


    /// <summary>
    /// Sets filters from provided reference document line to the current requisition line.
    /// </summary>
    /// <param name="RefOrderType">Provided reference order type. </param>
    /// <param name="RefOrderStatus">Provided reference order status. </param>
    /// <param name="RefOrderNo">Provided reference order number. </param>
    /// <param name="RefLineNo">Provided reference order line number. </param>
    procedure SetRefOrderFilters(RefOrderType: Enum "Requisition Ref. Order Type"; RefOrderStatus: Option; RefOrderNo: Code[20]; RefLineNo: Integer)
    begin
        SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        SetRange("Ref. Order Type", RefOrderType);
        SetRange("Ref. Order Status", RefOrderStatus);
        SetRange("Ref. Order No.", RefOrderNo);
        SetRange("Ref. Line No.", RefLineNo);
    end;

    procedure TransferFromPurchaseLine(var PurchLine: Record "Purchase Line")
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        Item.Get(PurchLine."No.");

        Type := Type::Item;
        "No." := PurchLine."No.";
        "Variant Code" := PurchLine."Variant Code";
        Description := PurchLine.Description;
        "Description 2" := PurchLine."Description 2";
        "Location Code" := PurchLine."Location Code";
        "Dimension Set ID" := PurchLine."Dimension Set ID";
        "Shortcut Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
        "Bin Code" := PurchLine."Bin Code";
        "Gen. Prod. Posting Group" := PurchLine."Gen. Prod. Posting Group";
        "Gen. Business Posting Group" := PurchLine."Gen. Bus. Posting Group";
        "Low-Level Code" := Item."Low-Level Code";
        "Order Date" := PurchHeader."Order Date";
        "Starting Date" := "Order Date";
        "Ending Date" := PurchLine."Planned Receipt Date";
        "Due Date" := PurchLine."Expected Receipt Date";
        Quantity := PurchLine.Quantity;
        "Finished Quantity" := PurchLine."Quantity Received";
        "Remaining Quantity" := PurchLine."Outstanding Quantity";
        BlockDynamicTracking(true);
        Validate("Unit Cost", PurchLine."Unit Cost (LCY)");
        BlockDynamicTracking(false);
        "Indirect Cost %" := PurchLine."Indirect Cost %";
        "Overhead Rate" := PurchLine."Overhead Rate";
        "Unit of Measure Code" := PurchLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := PurchLine."Qty. per Unit of Measure";
        "Quantity (Base)" := PurchLine."Quantity (Base)";
        "Finished Qty. (Base)" := PurchLine."Qty. Received (Base)";
        "Remaining Qty. (Base)" := PurchLine."Outstanding Qty. (Base)";
        "Replenishment System" := "Replenishment System"::Purchase;
        "MPS Order" := PurchLine."MPS Order";
        "Planning Flexibility" := PurchLine."Planning Flexibility";
        "Ref. Order No." := PurchLine."Document No.";
        "Ref. Order Type" := "Ref. Order Type"::Purchase;
        "Ref. Line No." := PurchLine."Line No.";
        "Vendor No." := PurchLine."Buy-from Vendor No.";
        Validate("Currency Code", PurchLine."Currency Code");

        OnAfterTransferFromPurchaseLine(Rec, PurchLine);

        GetDimFromRefOrderLine(false);
    end;

    procedure TransferFromTransLine(var TransLine: Record "Transfer Line")
    var
        TransHeader: Record "Transfer Header";
    begin
        TransHeader.Get(TransLine."Document No.");
        Item.Get(TransLine."Item No.");
        Type := Type::Item;
        "No." := TransLine."Item No.";
        "Variant Code" := TransLine."Variant Code";
        Description := TransLine.Description;
        "Description 2" := TransLine."Description 2";
        "Location Code" := TransLine."Transfer-to Code";
        "Dimension Set ID" := TransLine."Dimension Set ID";
        "Shortcut Dimension 1 Code" := TransLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := TransLine."Shortcut Dimension 2 Code";
        "Gen. Prod. Posting Group" := TransLine."Gen. Prod. Posting Group";
        "Low-Level Code" := Item."Low-Level Code";
        "Starting Date" := CalcDate(TransLine."Outbound Whse. Handling Time", TransLine."Shipment Date");
        "Ending Date" := CalcDate(TransLine."Shipping Time", "Starting Date");
        "Due Date" := TransLine."Receipt Date";
        Quantity := TransLine.Quantity;
        "Finished Quantity" := TransLine."Quantity Received";
        "Remaining Quantity" := TransLine."Outstanding Quantity";
        BlockDynamicTracking(false);
        "Unit of Measure Code" := TransLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := TransLine."Qty. per Unit of Measure";
        "Quantity (Base)" := TransLine."Quantity (Base)";
        "Finished Qty. (Base)" := TransLine."Qty. Received (Base)";
        "Remaining Qty. (Base)" := TransLine."Outstanding Qty. (Base)";
        "Replenishment System" := "Replenishment System"::Transfer;
        "Ref. Order No." := TransLine."Document No.";
        "Ref. Order Type" := "Ref. Order Type"::Transfer;
        "Ref. Line No." := TransLine."Line No.";
        "Transfer-from Code" := TransLine."Transfer-from Code";
        "Transfer Shipment Date" := TransLine."Shipment Date";

        OnAfterTransferFromTransLine(Rec, TransLine);

        GetDimFromRefOrderLine(false);
    end;

    procedure GetDimFromRefOrderLine(AddToExisting: Boolean)
    var
        PurchLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        DimSetIDArr: array[10] of Integer;
        i: Integer;
        IsHandled: Boolean;
    begin
        if AddToExisting then begin
            i := 1;
            DimSetIDArr[i] := "Dimension Set ID";
        end;
        i := i + 1;

        case "Ref. Order Type" of
            "Ref. Order Type"::Purchase:
                if PurchLine.Get(PurchLine."Document Type"::Order, "Ref. Order No.", "Ref. Line No.") then
                    DimSetIDArr[i] := PurchLine."Dimension Set ID";
            "Ref. Order Type"::Transfer:
                begin
                    IsHandled := false;
                    OnGetDimFromRefOrderLineOnBeforeSetDimSetIDTypeTransfer(Rec, DimSetIDArr, i, IsHandled);
                    if not IsHandled then
                        if TransferLine.Get("Ref. Order No.", "Ref. Line No.") then
                            DimSetIDArr[i] := TransferLine."Dimension Set ID";
                end;
            else
                OnGetDimFromRefOrderLineElseCase(Rec, DimSetIDArr, i);
        end;
        "Dimension Set ID" := DimMgt.GetCombinedDimensionSetID(DimSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure TransferFromActionMessage(var ActionMessageEntry: Record "Action Message Entry")
    var
        ReservEntry: Record "Reservation Entry";
        EndDate: Date;
    begin
        if not ReservEntry.Get(ActionMessageEntry."Reservation Entry", true) then
            ReservEntry.Get(ActionMessageEntry."Reservation Entry", false);
        BlockDynamicTracking(true);
        Type := Type::Item;
        Validate("No.", ReservEntry."Item No.");
        BlockDynamicTracking(false);
        Validate("Variant Code", ReservEntry."Variant Code");
        Validate("Location Code", ReservEntry."Location Code");
        Description := ReservEntry.Description;

        if ReservEntry.Positive then
            EndDate := ReservEntry."Expected Receipt Date"
        else
            EndDate := ReservEntry."Shipment Date";

        if EndDate <> 0D then
            "Due Date" := EndDate
        else
            "Due Date" := WorkDate();

        if ShouldUpdateEndingDateForSourceType(ReservEntry."Source Type") then
            "Ending Date" :=
                LeadTimeMgt.GetPlannedEndingDate(
                ReservEntry."Item No.", ReservEntry."Location Code", ReservEntry."Variant Code",
                "Due Date", "Vendor No.", "Ref. Order Type");

        OnAfterTransferFromActionMessage(Rec, ActionMessageEntry, ReservEntry);
    end;

    local procedure ShouldUpdateEndingDateForSourceType(SourceType: Integer) ShouldUpdate: Boolean
    begin
        if SourceType in [Database::"Transfer Line", Database::"Purchase Line", Database::"Requisition Line"] then
            ShouldUpdate := true;

        OnAfterShouldUpdateEndingDateForSourceType(SourceType, ShouldUpdate);
    end;

    procedure TransferToTrackingEntry(var TrkgReservEntry: Record "Reservation Entry"; PointerOnly: Boolean)
    begin
        TrkgReservEntry.SetSource(
          Database::"Requisition Line", 0, "Worksheet Template Name", "Line No.", "Journal Batch Name", 0);
        if PointerOnly then
            exit;

        TrkgReservEntry."Item No." := "No.";
        TrkgReservEntry."Location Code" := "Location Code";
        TrkgReservEntry.Description := '';
        TrkgReservEntry."Creation Date" := Today;
        TrkgReservEntry."Created By" := CopyStr(UserId(), 1, 50);
        TrkgReservEntry."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
        TrkgReservEntry."Variant Code" := "Variant Code";
        CalcFields("Reserved Quantity");
        TrkgReservEntry.Quantity := "Remaining Quantity" - "Reserved Quantity";
        TrkgReservEntry."Quantity (Base)" := TrkgReservEntry.Quantity * TrkgReservEntry."Qty. per Unit of Measure";
        TrkgReservEntry.Positive := TrkgReservEntry."Quantity (Base)" > 0;
        if "Planning Level" > 0 then
            TrkgReservEntry."Reservation Status" := TrkgReservEntry."Reservation Status"::Reservation
        else
            TrkgReservEntry."Reservation Status" := TrkgReservEntry."Reservation Status"::Tracking;
        if TrkgReservEntry.Positive then
            TrkgReservEntry."Expected Receipt Date" := "Due Date"
        else
            TrkgReservEntry."Shipment Date" := "Due Date";

        OnAfterTransferToTrackingEntry(TrkgReservEntry, Rec);
    end;

    procedure UpdateDatetime()
    begin
        "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time");
        "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time");
    end;

    /// <summary>
    /// Gets item unit cost of the current requisition line. 
    /// </summary>
    /// <param name="CalledByFieldNo">Indicates the number of the field which invoked the method. </param>
    procedure GetDirectCost(CalledByFieldNo: Integer)
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        PriceCalculation: Interface "Price Calculation";
        PriceType: enum "Price Type";
        Line: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDirectCost(Rec, xRec, CalledByFieldNo, CurrFieldNo, Subcontracting, IsHandled);
        if IsHandled then
            exit;

        if ("Replenishment System" = "Replenishment System"::Purchase) and not Subcontracting then begin
            IsHandled := false;
            OnGetDirectCostOnBeforePriceCalculation(Rec, IsHandled);
            if not IsHandled then begin
                GetLineWithPrice(LineWithPrice);
                LineWithPrice.SetLine(PriceType::Purchase, Rec);
                PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
                PriceCalculation.ApplyDiscount();
                PriceCalculation.ApplyPrice(CalledByFieldNo);
                PriceCalculation.GetLine(Line);
                Rec := Line;
            end;
        end;

        OnAfterGetDirectCost(Rec, CalledByFieldNo);
    end;

    procedure GetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    var
        RequisitionLinePrice: Codeunit "Requisition Line - Price";
    begin
        LineWithPrice := RequisitionLinePrice;
        OnAfterGetLineWithPrice(LineWithPrice);
    end;

    local procedure ValidateLocationChange()
    var
        Purchasing: Record Purchasing;
        SalesOrderLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateLocationChange(Rec, IsHandled);

        case true of
            "Location Code" = xRec."Location Code":
                exit;
            "Purchasing Code" = '':
                exit;
            not Purchasing.Get("Purchasing Code"):
                exit;
            not Purchasing."Special Order":
                exit;
            not SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, "Sales Order No.", "Sales Order Line No."):
                exit;
            "Location Code" = SalesOrderLine."Location Code":
                exit;
            IsHandled:
                exit;
        end;

        Error(Text028, FieldCaption("Location Code"), TableCaption);
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
          ItemTrackingMgt.ComposeRowID(
            Database::"Requisition Line", 0, "Worksheet Template Name", "Journal Batch Name", 0, "Line No."));
    end;

    /// <summary>
    /// Calculates value for the field 'Ending Date' based on provided 'LeadTime' formula or current requisition line. 
    /// </summary>
    /// <param name="LeadTime">Provided lead time formula. </param>
    /// <remarks>In case 'LeadTime' is empty, lead time code will be defined according to the reference order type. </remarks>
    procedure CalcEndingDate(LeadTime: Code[20])
    var
        RoutingExists: Boolean;
    begin
        OnBeforeCalcEndingDate(Rec, LeadTime);

        case "Ref. Order Type" of
            "Ref. Order Type"::Purchase:
                if LeadTime = '' then
                    LeadTime := LeadTimeMgt.PurchaseLeadTime("No.", "Location Code", "Variant Code", "Vendor No.");
            "Ref. Order Type"::"Prod. Order":
                begin
                    OnRoutingLineExists(Rec, RoutingExists);
                    if RoutingExists then
                        exit;

                    if LeadTime = '' then
                        LeadTime := LeadTimeMgt.ManufacturingLeadTime("No.", "Location Code", "Variant Code");
                end;
            "Ref. Order Type"::Assembly:
                begin
                    OnRoutingLineExists(Rec, RoutingExists);
                    if RoutingExists then
                        exit;

                    if LeadTime = '' then
                        LeadTime := LeadTimeMgt.ManufacturingLeadTime("No.", "Location Code", "Variant Code");
                end;
            "Ref. Order Type"::Transfer:
                CalcTransferShipmentDate();
            else
                exit;
        end;

        "Ending Date" :=
          LeadTimeMgt.GetPlannedEndingDate(
            "No.", "Location Code", "Variant Code", "Vendor No.", LeadTime, "Ref. Order Type", "Starting Date");

        OnAfterCalcEndingDate(Rec, LeadTime);
    end;

    /// <summary>
    /// Calculates value for the field 'Starting Date' based on provided 'LeadTime' formula for the current requisition line. 
    /// </summary>
    /// <param name="LeadTime">Provided lead time formula.</param>
    /// <remarks>In case 'LeadTime' is empty, lead time code will be defined according to the reference order type. 
    /// 'Order Date' of the current requisition line will be set to newly calculated 'Starting Date'. </remarks>
    procedure CalcStartingDate(LeadTime: Code[20])
    var
        IsHandled: Boolean;
        RoutingExists: Boolean;
    begin
        OnBeforeCalcStartingDate(Rec, LeadTime);

        case "Ref. Order Type" of
            "Ref. Order Type"::Purchase:
                if LeadTime = '' then
                    LeadTime :=
                      LeadTimeMgt.PurchaseLeadTime(
                        "No.", "Location Code", "Variant Code", "Vendor No.");
            "Ref. Order Type"::"Prod. Order":
                begin
                    OnRoutingLineExists(Rec, RoutingExists);
                    if RoutingExists then
                        exit;

                    if LeadTime = '' then
                        LeadTime := LeadTimeMgt.ManufacturingLeadTime("No.", "Location Code", "Variant Code");
                end;
            "Ref. Order Type"::Assembly:
                begin
                    OnRoutingLineExists(Rec, RoutingExists);
                    if RoutingExists then
                        exit;

                    if LeadTime = '' then
                        LeadTime := LeadTimeMgt.ManufacturingLeadTime("No.", "Location Code", "Variant Code");
                end;
            "Ref. Order Type"::" ":
                exit;
        end;

        "Starting Date" :=
          LeadTimeMgt.GetPlannedStartingDate(
            "No.", "Location Code", "Variant Code", "Vendor No.", LeadTime, "Ref. Order Type", "Ending Date");

        IsHandled := false;
        OnCalcStartingDateOnBeforeValidateOrderDate(Rec, LeadTime, IsHandled);
        if not IsHandled then
            Validate("Order Date", "Starting Date");

        if "Ref. Order Type" = "Ref. Order Type"::Transfer then
            CalcTransferShipmentDate();
    end;

    local procedure CalcTransferShipmentDate()
    var
        TransferRoute: Record "Transfer Route";
        DateFormula: DateFormula;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcTransferShipmentDate(Rec, IsHandled);
        if IsHandled then
            exit;

        Evaluate(DateFormula, LeadTimeMgt.WhseOutBoundHandlingTime("Transfer-from Code"));
        TransferRoute.CalcShipmentDateBackward("Transfer Shipment Date", "Starting Date", DateFormula, "Transfer-from Code");
    end;

    local procedure GetLocation(LocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetLocation(Rec, Location, LocationCode, IsHandled);
        if IsHandled then
            exit;

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

    procedure SetSubcontracting(NewSubcontracting: Boolean)
    begin
        Subcontracting := NewSubcontracting;
    end;

    procedure IsSubcontracting(): Boolean
    begin
        exit(Subcontracting);
    end;

    /// <summary>
    /// Populates corresponding values of the current requisition line in reference to the provided unplanned demand.
    /// </summary>
    /// <param name="UnplannedDemand">Source unplanned demand record.</param>
    procedure TransferFromUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand")
    begin
        InitRecordForOrderPlanning();

        OnTransferFromUnplannedDemandOnBeforeSetType(Rec);
        Type := Type::Item;
        "No." := UnplannedDemand."Item No.";
        "Location Code" := UnplannedDemand."Location Code";
        "Bin Code" := UnplannedDemand."Bin Code";
        Validate("No.");
        Validate("Variant Code", UnplannedDemand."Variant Code");
        UpdateDescription();
        "Unit Of Measure Code (Demand)" := UnplannedDemand."Unit of Measure Code";
        "Qty. per UOM (Demand)" := UnplannedDemand."Qty. per Unit of Measure";
        Reserve := UnplannedDemand.Reserve;
        SetDemandTypeFromUnplannedDemand(UnplannedDemand);
        "Demand Subtype" := UnplannedDemand."Demand SubType";
        "Demand Order No." := UnplannedDemand."Demand Order No.";
        "Demand Line No." := UnplannedDemand."Demand Line No.";
        "Demand Ref. No." := UnplannedDemand."Demand Ref. No.";

        OnTransferFromUnplannedDemandOnBeforeSetStatus(Rec, UnplannedDemand);
        Status := UnplannedDemand.Status;

        Level := 1;
        "Action Message" := ReqLine."Action Message"::New;
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Drop Shipment" := UnplannedDemand."Drop Shipment";

        UpdateSalesOrderDetailForDropShipment();

        UpdateDim();

        OnAfterTransferFromUnplannedDemand(Rec, UnplannedDemand);
    end;

    local procedure InitRecordForOrderPlanning()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitRecordForOrderPlanning(Rec, IsHandled);
        if IsHandled then
            exit;

        Init();
        "Journal Batch Name" := GetJnlBatchNameForOrderPlanning();
        "Line No." := "Line No." + 10000;
        "Planning Line Origin" := "Planning Line Origin"::"Order Planning";
    end;

    /// <summary>
    /// Sets values of 'Demand Date', 'Order Date', 'Starting Date' and 'Ending Date' fields of the current record based on provided 'DemandDate'.
    /// </summary>
    /// <param name="DemandDate">Provided demand date.</param>
    procedure SetSupplyDates(DemandDate: Date)
    begin
        "Demand Date" := DemandDate;
        "Starting Date" := "Demand Date";
        "Order Date" := "Demand Date";
        Validate("Due Date", "Demand Date");

        if "Planning Level" = 0 then begin
            Validate(
              "Ending Date",
              LeadTimeMgt.GetPlannedEndingDate(
                "No.", "Location Code", "Variant Code", "Due Date", '', "Ref. Order Type"));
            OnSetSupplyDatesOnAfterValidateEndingDate(Rec);
        end else begin
            Validate("Ending Date", "Due Date");
            Validate("Ending Time", 0T);
        end;

        OnAfterSetSupplyDates(Rec);
    end;

    /// <summary>
    /// Calculates demanded and needed quantities based on provided parameters 'DemandQtyBase' and 'NeededQtyBase'.
    /// </summary>
    /// <param name="DemandQtyBase">Provided demanded quantity. </param>
    /// <param name="NeededQtyBase">Provided needed quantitiy. </param>
    /// <remarks>Validation of the field 'Quantity' will be triggered. </remarks>
    procedure SetSupplyQty(DemandQtyBase: Decimal; NeededQtyBase: Decimal)
    begin
        if "Qty. per Unit of Measure" = 0 then
            "Qty. per Unit of Measure" := 1;

        "Demand Quantity" := Round(DemandQtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        "Demand Quantity (Base)" := DemandQtyBase;
        "Needed Quantity" := Round(NeededQtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        if "Needed Quantity" < NeededQtyBase / "Qty. per Unit of Measure" then
            "Needed Quantity" := Round(NeededQtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision(), '>');
        "Needed Quantity (Base)" := NeededQtyBase;
        "Demand Qty. Available" :=
          Round((DemandQtyBase - NeededQtyBase) / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        Validate(Quantity, "Needed Quantity");
    end;

    procedure SetResiliencyOn(WkshTemplName: Code[10]; JnlBatchName: Code[10]; ItemNo: Code[20])
    begin
        PlanningResiliency := true;
        TempPlanningErrorLog.SetJnlBatch(WkshTemplName, JnlBatchName, ItemNo);
    end;

    procedure GetResiliencyError(var PlanningErrorLog: Record "Planning Error Log"): Boolean
    begin
        exit(TempPlanningErrorLog.GetError(PlanningErrorLog));
    end;

    procedure SetResiliencyError(TheError: Text[250]; TheTableID: Integer; TheTablePosition: Text[250])
    begin
        TempPlanningErrorLog.SetError(TheError, TheTableID, TheTablePosition);
    end;

    procedure SetDemandTypeFromUnplannedDemand(UnplannedDemand: Record "Unplanned Demand")
    begin
        OnSetDemandTypeFromUnplannedDemand(Rec, UnplannedDemand);
    end;

    local procedure CheckExchRate(Currency: Record Currency)
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.SetRange("Currency Code", "Currency Code");
        CurrExchRate.SetRange("Starting Date", 0D, "Order Date");
        case true of
            not CurrExchRate.FindLast():
                TempPlanningErrorLog.SetError(
                  StrSubstNo(
                    Text038,
                    Currency.TableCaption(), Currency.Code, "Vendor No.", "Order Date"),
                  Database::Currency, CopyStr(Currency.GetPosition(), 1, 250));
            CurrExchRate."Exchange Rate Amount" = 0:
                TempPlanningErrorLog.SetError(
                  StrSubstNo(
                    Text037,
                    Currency.TableCaption(), Currency.Code, "Vendor No.",
                    "Order Date", CurrExchRate.FieldCaption("Exchange Rate Amount")),
                  Database::Currency, CopyStr(Currency.GetPosition(), 1, 250));
            CurrExchRate."Relational Exch. Rate Amount" = 0:
                TempPlanningErrorLog.SetError(
                  StrSubstNo(
                    Text037,
                    Currency.TableCaption(), Currency.Code, "Vendor No.",
                    "Order Date", CurrExchRate.FieldCaption("Relational Exch. Rate Amount")),
                  Database::Currency, CopyStr(Currency.GetPosition(), 1, 250));
        end;
    end;

    local procedure CheckVendorBlocked(Vend: Record Vendor)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckVendorBlocked(Rec, Vend, IsHandled, CurrentFieldNo);
        if IsHandled then
            exit;

        if Vend.Blocked = Vend.Blocked::All then begin
            if PlanningResiliency then
                TempPlanningErrorLog.SetError(
                  StrSubstNo(Text031, Vend.TableCaption(), Vend."No."),
                  Database::Vendor, CopyStr(Vend.GetPosition(), 1, 250));
            Vend.VendBlockedErrorMessage(Vend, false);
        end;
    end;

    /// <summary>
    /// Filters corresponding fields of the current record based on provided item record.
    /// </summary>
    /// <param name="Item">Provided item record. </param>
    procedure FilterLinesWithItemToPlan(var Item2: Record Item)
    begin
        Reset();
        SetCurrentKey(Type, "No.");
        SetRange(Type, Type::Item);
        SetRange("No.", Item2."No.");
        SetRange("Sales Order No.", '');
        SetFilter("Variant Code", Item2.GetFilter("Variant Filter"));
        SetFilter("Location Code", Item2.GetFilter("Location Filter"));
        SetFilter("Due Date", Item2.GetFilter("Date Filter"));
        Item2.CopyFilter("Global Dimension 1 Filter", "Shortcut Dimension 1 Code");
        Item2.CopyFilter("Global Dimension 2 Filter", "Shortcut Dimension 2 Code");
        SetRange("Planning Line Origin", "Planning Line Origin"::" ");
        SetFilter("Quantity (Base)", '<>0');
        SetFilter("Unit of Measure Code", Item2.GetFilter("Unit of Measure Filter"));

        OnAfterFilterLinesWithItemToPlan(Rec, Item);
    end;

    /// <summary>
    /// Gets filtered requisition line based on values from provided item record. 
    /// </summary>
    /// <param name="Item">Provided item record.</param>
    /// <returns>Returns 'true' if filtered requisition line is found, otherwise 'false'.</returns>
    procedure FindLinesWithItemToPlan(var Item2: Record Item): Boolean
    begin
        FilterLinesWithItemToPlan(Item2);
        exit(Find('-'));
    end;

    /// <summary>
    /// Sets filters on corresponding fields of requisition lines based on specified reservation entry, availability date filter and parameter 'Positive'.
    /// </summary>
    /// <param name="ReservationEntry">Specified reservation entry record.</param>
    /// <param name="AvailabilityFilter">Specified availability date filter.</param>
    /// <param name="Positive">In case 'true', 'Quantity (Base)' is to have value greater than zero, otherwise negative value.</param>
    procedure FilterLinesForReservation(ReservationEntry: Record "Reservation Entry"; AvailabilityFilter: Text; Positive: Boolean)
    begin
        Reset();
        SetCurrentKey(
          Type, "No.", "Variant Code", "Location Code", "Sales Order No.", "Planning Line Origin", "Due Date");
        SetRange(Type, Type::Item);
        SetRange("No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Location Code", ReservationEntry."Location Code");
        SetRange("Sales Order No.", '');
        SetFilter("Due Date", AvailabilityFilter);
        if Positive then
            SetFilter("Quantity (Base)", '>0')
        else
            SetFilter("Quantity (Base)", '<0');

        OnAfterFilterLinesForReservation(Rec, ReservationEntry);
    end;

    procedure FindCurrForecastName(var ForecastName: Code[10]): Boolean
    var
        UntrackedPlanningElement: Record "Untracked Planning Element";
    begin
        if (Type <> Type::Item) or
           ("Planning Line Origin" <> "Planning Line Origin"::Planning)
        then
            exit(false);

        UntrackedPlanningElement.SetRange("Worksheet Template Name", "Worksheet Template Name");
        UntrackedPlanningElement.SetRange("Worksheet Batch Name", "Journal Batch Name");
        UntrackedPlanningElement.SetRange("Item No.", "No.");
        UntrackedPlanningElement.SetRange("Source Type", 99000852); // Database::"Production Forecast Entry"
        UntrackedPlanningElement.SetLoadFields("Source ID");
        if UntrackedPlanningElement.FindFirst() then begin
            ForecastName := CopyStr(UntrackedPlanningElement."Source ID", 1, 10);
            exit(true);
        end;
    end;

    /// <summary>
    /// Depicts dimensions of the current requisition line. 
    /// </summary>
    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', "Worksheet Template Name", "Journal Batch Name", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec, xRec);
    end;

    /// <summary>
    /// Calcuates original base quantity from fields 'Original Quantity' and 'Qty. per Unit of Measure' of the current requisition line.
    /// </summary>
    /// <returns>Returns calculated quantity base value.</returns>
    procedure GetOriginalQtyBase(): Decimal
    begin
        exit(UOMMgt.CalcBaseQty("Original Quantity", "Qty. per Unit of Measure"));
    end;

    local procedure SetFromBinCode()
    var
        IsHandled: Boolean;
        ShouldGetDefaultBin: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetFromBinCode(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Location Code" <> '') and ("No." <> '') then begin
            GetLocation("Location Code");
            OnSetFromBinCodeOnSetBinCode(Rec, Location);
            ShouldGetDefaultBin := ("Bin Code" = '') and Location."Bin Mandatory" and not Location."Directed Put-away and Pick";
            OnBeforeGetDefaultBin(Rec, ShouldGetDefaultBin);
            if ShouldGetDefaultBin then
                WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", "Bin Code");
        end;
    end;

    local procedure GetDefaultBinCode()
    begin
        if Rec."Replenishment System" <> Rec."Replenishment System"::Purchase then
            exit;
        if (Rec."Sales Order No." <> '') and Rec."Drop Shipment" then
            exit;
        if ("Location Code" <> '') and ("No." <> '') then
            if not IsDropShipment() then begin
                GetLocation("Location Code");
                if ("Bin Code" = '') and Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                    WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", "Bin Code");
            end;
    end;

    /// <summary>
    /// Checks whether the current requisition line is a drop shipment.
    /// </summary>
    /// <returns>Returns 'true' if requisition line is a drop shipment, otherwise 'false'. </returns>
    procedure IsDropShipment(): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        if "Drop Shipment" then
            exit(true);

        if "Replenishment System" = "Replenishment System"::Purchase then
            if SalesLine.Get(SalesLine."Document Type"::Order, "Sales Order No.", "Sales Order Line No.") then
                exit(SalesLine."Drop Shipment");
        exit(false);
    end;

    /// <summary>
    /// Sets location code for the current requisition line record.
    /// </summary>
    procedure GetLocationCode()
    var
        Vend: Record Vendor;
        IsHandled: Boolean;
    begin
        if not IsLocationCodeAlterable() or IsDropShipmentOrSpecialOrder() then
            exit;

        IsHandled := false;
        OnGetLocationCodeOnBeforeUpdate(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if "Vendor No." <> '' then begin
            Vend.Get("Vendor No.");
            if Vend."Location Code" <> '' then
                "Location Code" := Vend."Location Code";
        end else
            "Location Code" := '';
    end;

    procedure IsDropShipmentOrSpecialOrder(): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        if "Replenishment System" = "Replenishment System"::Purchase then begin
            SalesLine.SetLoadFields("Drop Shipment", "Special Order");
            if SalesLine.Get(SalesLine."Document Type"::Order, "Sales Order No.", "Sales Order Line No.") then
                exit(SalesLine."Drop Shipment" or SalesLine."Special Order");
        end;
    end;

    local procedure IsLocationCodeAlterable(): Boolean
    begin
        if (CurrFieldNo = 0) and (CurrentFieldNo = 0) then
            exit(false);

        if (CurrFieldNo = FieldNo("Location Code")) or (CurrentFieldNo = FieldNo("Location Code")) then
            exit(false);

        if (CurrFieldNo = FieldNo("Replenishment System")) or (CurrentFieldNo = FieldNo("Replenishment System")) then
            exit(false);

        if "Planning Line Origin" <> "Planning Line Origin"::" " then
            exit(false);

        exit(true);
    end;

    procedure LookupRefOrderNo()
    var
        PurchHeader: Record "Purchase Header";
        TransHeader: Record "Transfer Header";
        IsHandled: Boolean;
    begin
        case "Ref. Order Type" of
            "Ref. Order Type"::Purchase:
                if PurchHeader.Get(PurchHeader."Document Type"::Order, "Ref. Order No.") then
                    PAGE.Run(PAGE::"Purchase Order", PurchHeader)
                else
                    Message(Text007, PurchHeader.TableCaption());
            "Ref. Order Type"::Transfer:
                if TransHeader.Get("Ref. Order No.") then
                    PAGE.Run(PAGE::"Transfer Order", TransHeader)
                else
                    Message(Text007, TransHeader.TableCaption());
            else begin
                IsHandled := false;
                OnLookupRefOrderNoElseCase(Rec, IsHandled);
                if not IsHandled then
                    Message(Text008);
            end;
        end;
    end;

    local procedure SetRemaningQuantity()
    begin
        "Remaining Quantity" := Quantity - "Finished Quantity";
        "Remaining Qty. (Base)" := "Remaining Quantity" * "Qty. per Unit of Measure";

        OnAfterSetRemaningQuantity(Rec, xRec, CurrFieldNo, CurrentFieldNo);
    end;

    local procedure SetReplenishmentSystemFromPurchase(StockkeepingUnit: Record "Stockkeeping Unit")
    begin
        "Ref. Order Type" := "Ref. Order Type"::Purchase;
        Clear("Ref. Order Status");
        "Ref. Order No." := '';
        DeleteRelations();
        CleanProdBOMNo();
        UpdateUnitOfMeasureCodeFromItemPurchUnitOfMeasure();
        Validate("Transfer-from Code", '');

        ValidateVendorNoWithStockkeepingUnit(StockkeepingUnit);

        OnAfterSetReplenishmentSystemFromPurchase(Rec, Item, StockkeepingUnit);
    end;

    local procedure ValidateVendorNoWithStockkeepingUnit(StockkeepingUnit: Record "Stockkeeping Unit")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateVendorNoWithStockkeepingUnit(Rec, StockkeepingUnit, IsHandled);
        if IsHandled then
            exit;

        if StockkeepingUnit."Vendor No." = '' then
            Validate("Vendor No.")
        else
            Validate("Vendor No.", StockkeepingUnit."Vendor No.");
    end;

    local procedure UpdateUnitOfMeasureCodeFromItemPurchUnitOfMeasure()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitOfMeasureCodeFromItemPurchUnitOfMeasure(Rec, Item, IsHandled);
        if IsHandled then
            exit;

        if Item."Purch. Unit of Measure" <> '' then
            Validate("Unit of Measure Code", Item."Purch. Unit of Measure");
    end;

    procedure UpdateUnitOfMeasureCodeFromItemBaseUnitOfMeasure()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitOfMeasureCodeFromItemBaseUnitOfMeasure(Rec, Item, IsHandled);
        if IsHandled then
            exit;

        Validate("Unit of Measure Code", Item."Base Unit of Measure");
    end;

    local procedure SetReplenishmentSystemFromTransfer(StockkeepingUnit: Record "Stockkeeping Unit")
    begin
        OnBeforeSetReplenishmentSystemFromTransfer(Rec, Item, StockkeepingUnit, CurrFieldNo);

        "Ref. Order Type" := "Ref. Order Type"::Transfer;
        Clear("Ref. Order Status");
        "Ref. Order No." := '';
        DeleteRelations();
        Validate("Vendor No.", '');
        CleanProdBOMNo();
        Validate("Transfer-from Code", StockkeepingUnit."Transfer-from Code");
        UpdateUnitOfMeasureCodeFromItemBaseUnitOfMeasure();

        OnAfterSetReplenishmentSystemFromTransfer(Rec, Item, StockkeepingUnit, CurrFieldNo);
    end;

    local procedure UpdateReplenishmentSystem()
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        GetItem();
        StockkeepingUnit := Item.GetSKU("Location Code", "Variant Code");
        if Subcontracting then
            StockkeepingUnit."Replenishment System" := StockkeepingUnit."Replenishment System"::"Prod. Order";
        ValidateReplenishmentSystem(StockkeepingUnit);
    end;

    local procedure ValidateReplenishmentSystem(StockkeepingUnit: Record "Stockkeeping Unit")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateReplenishmentSystem(Rec, StockkeepingUnit, IsHandled);
        if IsHandled then
            exit;
        Validate("Replenishment System", StockkeepingUnit."Replenishment System");
    end;

    procedure GetJnlBatchNameForOrderPlanning(): Code[10]
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.ReadIsolation := RequisitionLine.ReadIsolation::ReadUncommitted;
        RequisitionLine.SetLoadFields("Journal Batch Name");
        RequisitionLine.SetRange("Worksheet Template Name", '');
        RequisitionLine.SetFilter("Journal Batch Name", '<>%1', '');
        RequisitionLine.SetRange("User ID", UserId());
        if RequisitionLine.FindFirst() then
            exit(RequisitionLine."Journal Batch Name");

        RequisitionLine.SetRange("User ID");
        if RequisitionLine.FindLast() then
            exit(IncStr(RequisitionLine."Journal Batch Name"));

        exit('0');
    end;

    procedure CreateDimFromDefaultDim()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.ReqLineTypeToTableID(Rec.Type), Rec."No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::Vendor, Rec."Vendor No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code");
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", Rec."Purchaser Code");
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, Rec."Demand Order No.");

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, CurrFieldNo);
    end;

    local procedure SetPurchaserCode(PurchaserCodeToCheck: Code[20]; var PurchaserCodeToAssign: Code[20])
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetPurchaserCode(Rec, PurchaserCodeToCheck, PurchaserCodeToAssign, IsHandled);
        if IsHandled then
            exit;

        if PurchaserCodeToCheck = '' then
            PurchaserCodeToCheck := GetUserSetupPurchaserCode();
        if SalespersonPurchaser.Get(PurchaserCodeToCheck) then begin
            if SalespersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser) then
                PurchaserCodeToAssign := ''
            else
                PurchaserCodeToAssign := PurchaserCodeToCheck;
        end else
            PurchaserCodeToAssign := '';
    end;

    local procedure GetUserSetupPurchaserCode(): Code[20]
    var
        UserSetup: Record System.Security.User."User Setup";
    begin
        UserSetup.SetLoadFields("Salespers./Purch. Code");
        if not UserSetup.Get(UserId) then
            exit('');

        exit(UserSetup."Salespers./Purch. Code");
    end;

    local procedure UpdateJobTaskDimensions()
    var
        JobPlanningLine: Record "Job Planning Line";
        DimSetIDArr: array[10] of Integer;
    begin
        DimSetIDArr[1] := "Dimension Set ID";

        JobPlanningLine.SetRange("Job No.", "Demand Order No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", "Demand Line No.");
        if JobPlanningLine.FindFirst() then
            DimSetIDArr[2] := DimMgt.CreateDimSetFromJobTaskDim(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        "Dimension Set ID" := DimMgt.GetCombinedDimensionSetID(DimSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    local procedure GetItemVariant()
    begin
        if Rec."Variant Code" = '' then begin
            Clear(ItemVariant);
            exit;
        end;

        if (ItemVariant."Item No." <> Rec."No.") or (ItemVariant.Code <> Rec."Variant Code") then begin
            ItemVariant.SetLoadFields("Blocked");
            ItemVariant.Get(Rec."No.", Rec."Variant Code");
        end;
    end;

    local procedure UpdateSalesOrderDetailForDropShipment()
    var
        SalesLine: Record "Sales Line";
    begin
        if Rec."Demand Type" <> Database::"Sales Line" then
            exit;

        if not Rec."Drop Shipment" then
            exit;

        SalesLine.SetLoadFields("Sell-to Customer No.");
        if not SalesLine.Get(Rec."Demand Subtype", Rec."Demand Order No.", Rec."Demand Line No.") then
            exit;

        Rec."Sales Order No." := SalesLine."Document No.";
        Rec."Sales Order Line No." := SalesLine."Line No.";
        Rec."Sell-to Customer No." := SalesLine."Sell-to Customer No.";
    end;

    procedure ReserveBindingOrder(TrackingSpecification: Record "Tracking Specification"; SourceDescription: Text[100]; ExpectedDate: Date; ReservQty: Decimal; ReservQtyBase: Decimal; UpdateReserve: Boolean)
    begin
        OnReserveBindingOrder(Rec, TrackingSpecification, SourceDescription, ExpectedDate, ReservQty, ReservQtyBase, UpdateReserve);
    end;

    local procedure ErrorIfItemVariantIsBlocked()
    begin
        if ItemVariant.Blocked then
            Error(BlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemVariantPrimaryKeyLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption(Blocked));
    end;

    procedure CleanProdOrderNo()
    begin
        OnCleanProdOrderNo(Rec);
    end;

    procedure CleanProdBOMNo()
    begin
        OnCleanProdBOMNo(Rec);
    end;

    procedure SetOperationNoFilterToBlank()
    begin
        OnSetOperationNoFilterToBlank(Rec);
    end;

    procedure IsProdOrder() Result: Boolean
    begin
        OnIsProdOrder(Rec, Result);
    end;

    procedure IsProductionBOM() Result: Boolean
    begin
        OnIsProductionBOM(Rec, Result);
    end;

    procedure IsProdDemand() Result: Boolean
    begin
        OnIsProdDemand(Rec, Result);
    end;

    procedure ResetReqLineFields()
    begin
        OnResetReqLineFields(Rec);
    end;

    procedure TestProdOrderNo()
    begin
        OnTestProdOrderNo(Rec);
    end;

    procedure SetDoNotUpdateOrderReceiptDate(NewUpdateOrderReceiptDate: Boolean)
    begin
        DoNotUpdateOrderReceiptDate := NewUpdateOrderReceiptDate;
    end;

    local procedure CheckOpenApprovalEntryExistForCurrentUser()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        if RequisitionWkshName.Get("Worksheet Template Name", "Journal Batch Name") then
            ApprovalsMgmt.PreventModifyRecIfOpenApprovalEntryExistForCurrentUser(RequisitionWkshName);
    end;

    procedure CheckRequisitionWkshLineRestriction()
    begin
        OnCheckRequisitionWkshLinePostRestrictions();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var RequisitionLine: Record "Requisition Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDescription(var RequisitionLine: Record "Requisition Line"; Item: Record Item; ItemVariant: Record "Item Variant"; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromItem(var RequisitionLine: Record "Requisition Line"; Item: Record Item; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var ReqLine: Record "Requisition Line"; xReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteMultiLevel(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRelations(var RequisitionLine: Record "Requisition Line"; DeleteAllLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var RequisitionLine: Record "Requisition Line"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesForReservation(var RequisitionLine: Record "Requisition Line"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDirectCost(var RequisitionLine: Record "Requisition Line"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInsert(var RequisitionLine: Record "Requisition Line"; ReqWkshTemplate: Record "Req. Wksh. Template"; RequisitionWkshName: Record "Requisition Wksh. Name")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDueDate(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRemaningQuantity(var RequisitionLine: Record "Requisition Line"; xRequisitionLine: Record "Requisition Line"; CallingFieldNo: Integer; GlobalCurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReplenishmentSystemFromPurchase(var RequisitionLine: Record "Requisition Line"; Item: Record Item; StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromActionMessage(var RequisitionLine: Record "Requisition Line"; var ActionMessageEntry: Record "Action Message Entry"; var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReplenishmentSystemFromTransfer(var RequisitionLine: Record "Requisition Line"; Item: Record Item; StockkeepingUnit: Record "Stockkeeping Unit"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationEntry(var ReservEntry: Record "Reservation Entry"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPurchaseLine(var ReqLine: Record "Requisition Line"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromTransLine(var ReqLine: Record "Requisition Line"; TransLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromUnplannedDemand(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferToTrackingEntry(var ReservationEntry: Record "Reservation Entry"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateOrderReceiptDate(var RequisitionLine: Record "Requisition Line"; LeadTimeCalc: DateFormula)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateFields(RequisitionLine: Record "Requisition Line"; CurrFieldNo: Integer; CurrentFieldNo: Integer; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var RequisitionLine: Record "Requisition Line"; xRequisitionLine: Record "Requisition Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromItem(var RequisitionLine: Record "Requisition Line"; Item: Record Item; xRequisitionLine: Record "Requisition Line"; FieldNo: Integer; var TempPlanningErrorLog: Record "Planning Error Log" temporary; PlanningResiliency: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBlockedItem(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEndingDate(var RequisitionLine: Record "Requisition Line"; var ShowWarning: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVendorBlocked(var RequisitionLine: Record "Requisition Line"; var Vendor: Record Vendor; var IsHandled: Boolean; GlobalCurrentFieldNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteMultiLevel(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultBin(var RequisitionLine: Record "Requisition Line"; var ShouldGetDefaultBin: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDirectCost(var ReqLine: Record "Requisition Line"; xReqLine: Record "Requisition Line"; CalledByFieldNo: Integer; FieldNo: Integer; Subcontracting: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReservationQty(var RequisitionLine: Record "Requisition Line"; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRecordForOrderPlanning(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupVendor(var RequisitionLine: Record "Requisition Line"; var Vendor: Record Vendor; var PreferItemVendorCatalog: Boolean; var IsHandled: Boolean; var IsVendorSelected: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupVendorNo(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetFromBinCode(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVendorNoWithStockkeepingUnit(var RequisitionLine: Record "Requisition Line"; StockkeepingUnit: Record "Stockkeeping Unit"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateItemDescriptionAndQuantity(var RequisitionLine: Record "Requisition Line"; Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var RequisitionLine: Record "Requisition Line"; xRequisitionLine: Record "Requisition Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDescription(var RequisitionLine: Record "Requisition Line"; CalledByFieldNo: Integer; var IsHandled: Boolean; xRequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOrderReceiptDate(var RequisitionLine: Record "Requisition Line"; LeadTimeCalc: DateFormula; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityBase(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean; xRequisitionLine: Record "Requisition Line"; FieldNo: Integer; FieldNo2: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUnitCost(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateReplenishmentSystem(var RequisitionLine: Record "Requisition Line"; StockkeepingUnit: Record "Stockkeeping Unit"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetLocationCodeOnBeforeUpdate(var RequisitionLine: Record "Requisition Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupSupplyFromOnCaseReplenishmentSystemElse(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSupplyFromOnCaseReplenishmentSystemElse(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOfAfterCalcShouldValidateUnitofMeasureCode(var RequisitionLine: Record "Requisition Line"; xRequisitionLine: Record "Requisition Line"; Item: Record Item; var ShouldVaidateUnitofMeasureCode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDescriptionFromItem(var RequisitionLine: Record "Requisition Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDescriptionFromItemVariant(var RequisitionLine: Record "Requisition Line"; ItemVariant: Record "Item Variant")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDescriptionFromItemTranslation(var RequisitionLine: Record "Requisition Line"; ItemTranslation: Record "Item Translation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDescriptionFromSalesLine(var RequisitionLine: Record "Requisition Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateEndingTimeOnBeforeSetDueDate(var RequisitionLine: Record "Requisition Line"; var ShouldSetDueDate: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStartingTimeOnBeforeSetDueDate(var RequisitionLine: Record "Requisition Line"; var ShouldSetDueDate: Boolean; xRequisitionLine: Record "Requisition Line"; CurrentFieldNo: Integer; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnBeforeGetDefaultBin(var RequisitionLine: Record "Requisition Line"; var ShouldGetDefaultBin: Boolean; Location: Record Location; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeUnitCost(var RequisitionLine: Record "Requisition Line"; CallingFieldNo: Integer; GlobalCurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReplenishmentSystemCaseElse(var RequisitionLine: Record "Requisition Line"; var StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReplenishmentSystemOnAfterSetStockkeepingUnit(var RequisitionLine: Record "Requisition Line"; var StockkeepingUnit: Record "Stockkeeping Unit"; Subcontracting: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVendorNoOnAfterGetLocationCode(var RequisitionLine: Record "Requisition Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcStartingDate(var RequisitionLine: Record "Requisition Line"; var LeadTime: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcEndingDate(var RequisitionLine: Record "Requisition Line"; var LeadTime: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDescriptionFromGLAcc(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupVendorNo(var RequisitionLine: Record "Requisition Line"; var Vend: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReservation(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateStartingTime(var RequisitionLine: Record "Requisition Line"; var ShouldSetDueDate: Boolean; var IsHandled: Boolean; CallingFieldNo: Integer; CurrentFieldNo: Integer; xRequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLocationChange(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateEndingTime(var RequisitionLine: Record "Requisition Line"; var ShouldSetDueDate: Boolean; var IsHandled: Boolean; CallingFieldNo: Integer; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetLocation(var RequisitionLine: Record "Requisition Line"; var Location: Record Location; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromUnplannedDemandOnBeforeSetType(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var RequisitionLine: Record "Requisition Line"; LastReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDim(var RequisitionLine: Record "Requisition Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromUnplannedDemandOnBeforeSetStatus(var RequisitionLine: Record "Requisition Line"; var UnplannedDemand: Record "Unplanned Demand")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRelationsOnBeforePlanningComponentDelete(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSupplyDates(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateActionMessage(var RequisitionLine: Record "Requisition Line"; var xRequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitofMeasureCodeOnBeforeGetDirectCost(var RequisitionLine: Record "Requisition Line"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitOfMeasureCodeFromItemBaseUnitOfMeasure(var RequisitionLine: Record "Requisition Line"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitOfMeasureCodeFromItemPurchUnitOfMeasure(var RequisitionLine: Record "Requisition Line"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupFromLocationOnAfterSetFilters(RequisitionLine: Record "Requisition Line"; var Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcEndingDate(var Rec: Record "Requisition Line"; LeadTime: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDirectCostOnBeforePriceCalculation(var Rec: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcStartingDateOnBeforeValidateOrderDate(var Rec: Record "Requisition Line"; var LeadTime: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetReplenishmentSystemFromTransfer(var RequisitionLine: Record "Requisition Line"; Item: Record Item; StockkeepingUnit: Record "Stockkeeping Unit"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcTransferShipmentDate(var Rec: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteMultiLevelOnAfterSetFilterReqLine2(ReqLine: Record "Requisition Line"; var ReqLine2: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupRefOrderNoOnBeforeOpenPage(var ReqLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDimFromRefOrderLineOnBeforeSetDimSetIDTypeTransfer(ReqLine: Record "Requisition Line"; var DimSetIDArr: array[10] of Integer; i: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCurrencyCodeOnBeforeUpdateCurrencyFactor(var ReqLine: Record "Requisition Line"; var CurrExchRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnValidateShipToCode(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignItemUnitCostAndQuantitiesForUOM(var RequisitionLine: Record "Requisition Line"; xRequisitionLine: Record "Requisition Line"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeGetDirectCost(var RequisitionLine: Record "Requisition Line"; xRequisitionLine: Record "Requisition Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateDueDateOnAfterCalcShouldExitDueDate(var RequisitionLine: Record "Requisition Line"; xRequisitionLine: Record "Requisition Line"; CurrentFieldNo: Integer; var ShouldExitDueDate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVendorNoOnBeforeSetVendorItemNoFromItemVend(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVendorNoOnBeforeGetDirectCost(var RequisitionLine: Record "Requisition Line"; xRequisitionLine: Record "Requisition Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPurchaserCode(var RequisitionLine: Record "Requisition Line"; PurchaserCodeToCheck: Code[20]; var PurchaserCodeToAssign: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCurrencyFactorOnBeforeUpdateDirectUnitCost(var RequisitionLine: Record "Requisition Line"; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterAssignFieldsForNo(var RequisitionLine: Record "Requisition Line"; xRequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetDemandTypeFromUnplannedDemand(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReserveBindingOrder(var RequisitionLine: Record "Requisition Line"; TrackingSpecification: Record "Tracking Specification"; SourceDescription: Text[100]; ExpectedDate: Date; ReservQty: Decimal; ReservQtyBase: Decimal; UpdateReserve: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var RequisitionLine: Record "Requisition Line"; xRequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsProdOrder(var RequisitionLine: Record "Requisition Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsProductionBOM(var RequisitionLine: Record "Requisition Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsProdDemand(var RequisitionLine: Record "Requisition Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCleanProdOrderNo(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCleanProdBOMNo(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestProdOrderNo(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDimFromRefOrderLineElseCase(var RequisitionLine: Record "Requisition Line"; DimSetIDArr: array[10] of Integer; i: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupRefOrderNoElseCase(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnClearPlanningWorksheetOnBeforeRequisitionLineDelete(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRoutingLineExists(var RequisitionLine: Record "Requisition Line"; var RoutingExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStartingDate(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateEndingDate(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStartingTimeOnBeforeUpdateDateTime(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateEndingTimeOnBeforeUpdateDateTime(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFromBinCodeOnSetBinCode(var RequisitionLine: Record "Requisition Line"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldCheckNewActionMessage(var RequisitionLine: Record "Requisition Line"; CurrentFieldNo: Integer; var ShouldCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateWorkCenterDescription(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldUpdateEndingDateForSourceType(SourceType: Integer; var ShouldUpdate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetSupplyDatesOnAfterValidateEndingDate(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVendorNoOnBeforeLookupVendor(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVendorNoOnAfterCheckVendor(var RequisitionLine: Record "Requisition Line"; Vend: Record Vendor; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVendorNoOnAfterSetSupplyFrom(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResetReqLineFields(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetOperationNoFilterToBlank(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var RequisitionLine: Record "Requisition Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateItemReferenceDescription(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckRequisitionWkshLinePostRestrictions()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeDeleteRelations(var RequisitionLine: Record "Requisition Line"; xRequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVendorNoOnBeforeValidateCurrencyCode(var RequisitionLine: Record "Requisition Line"; Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVendorNoOnAfterGetDefaultBinCode(var RequisitionLine: Record "Requisition Line");
    begin
    end;
}