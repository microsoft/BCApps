// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Inventory.Journal;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Service.Contract;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Posting;
using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using System.Environment.Configuration;
using System.Reflection;
using System.Utilities;

table 5902 "Service Line"
{
    Caption = 'Service Line';
    DrillDownPageID = "Service Line List";
    LookupPageID = "Service Line List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Service Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Service Header"."No." where("Document Type" = field("Document Type"));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Type; Enum "Service Line Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                CheckIfCanBeModified();

                GetServHeader();
                TestStatusOpen();
                TestField("Qty. Shipped Not Invoiced", 0);
                TestField("Quantity Shipped", 0);
                TestField("Shipment No.", '');

                if xRec.Type = xRec.Type::Item then
                    ServiceWarehouseMgt.ServiceLineVerifyChange(Rec, xRec);

                if Type = Type::Item then begin
                    GetLocation("Location Code");
                    Location.TestField("Directed Put-away and Pick", false);
                end;

                UpdateReservation(FieldNo(Type));

                ServiceLine := Rec;

                if "Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"] then
                    UpdateServDocRegister(true);
                ClearFields();

                "Currency Code" := ServiceLine."Currency Code";
                ValidateServiceItemLineNumber(ServiceLine);

                if Type = Type::Item then begin
                    if ServHeader.WhsePickConflict("Document Type", "Document No.", ServHeader."Shipping Advice") then
                        DisplayConflictError(ServHeader.InvPickConflictResolutionTxt());
                    if ServHeader.WhseShipmentConflict("Document Type", "Document No.", ServHeader."Shipping Advice") then
                        DisplayConflictError(ServHeader.WhseShpmtConflictResolutionTxt());
                end;
            end;
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const(Item), "Document Type" = filter(<> "Credit Memo")) Item where(Blocked = const(false), "Service Blocked" = const(false))
            else
            if (Type = const(Item), "Document Type" = filter("Credit Memo")) Item where(Blocked = const(false))
            else
            if (Type = const(Resource)) Resource
            else
            if (Type = const(Cost)) "Service Cost";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                CheckIfCanBeModified();

                IsHandled := false;
                OnValidateNoOnBeforeTestFields(Rec, CurrFieldNo, IsHandled);
                if not IsHandled then begin
                    TestField("Qty. Shipped Not Invoiced", 0);
                    TestField("Quantity Shipped", 0);
                    TestField("Shipment No.", '');
                end;
                CheckItemAvailable(FieldNo("No."));
                TestStatusOpen();

                ClearFields();

                UpdateReservation(FieldNo("No."));

                if "No." = '' then
                    exit;

                GetServHeader();

                OnValidateNoOnBeforeCustomerCheck(Rec);
                if ServHeader."Document Type" = ServHeader."Document Type"::Quote then begin
                    if ServHeader."Customer No." = '' then
                        Error(
                          Text031,
                          ServHeader.FieldCaption("Customer No."));
                    if ServHeader."Bill-to Customer No." = '' then
                        Error(
                          Text031,
                          ServHeader.FieldCaption("Bill-to Customer No."));
                end else
                    ServHeader.TestField("Customer No.");

                InitHeaderDefaults(ServHeader);

                if "Service Item Line No." <> 0 then begin
                    ServItemLine.Get("Document Type", "Document No.", "Service Item Line No.");
                    Validate("Contract No.", ServItemLine."Contract No.")
                end else
                    Validate("Contract No.", ServHeader."Contract No.");

                case Type of
                    Type::" ":
                        CopyFromStdTxt();
                    Type::"G/L Account":
                        CopyFromGLAccount();
                    Type::Cost:
                        CopyFromCost();
                    Type::Item:
                        begin
                            CopyFromItem();
                            if ServItem.Get("Service Item No.") then
                                CopyFromServItem(ServItem);
                        end;
                    Type::Resource:
                        CopyFromResource();
                end;

                OnValidateNoOnAfterCopyFields(Rec, xRec, ServHeader);

                if Type <> Type::" " then begin
                    PlanPriceCalcByField(FieldNo("No."));

                    IsHandled := false;
                    OnBeforeValidateVATProdPostingGroup(Rec, xRec, IsHandled);
                    if not IsHandled then
                        Validate("VAT Prod. Posting Group");
                    Validate("Unit of Measure Code");
                    if Quantity <> 0 then begin
                        InitOutstanding();
                        if "Document Type" = "Document Type"::"Credit Memo" then
                            InitQtyToInvoice()
                        else
                            InitQtyToShip();
                        UpdateWithWarehouseShip();
                    end;
                    AdjustMaxLabourUnitPrice("Unit Price");

                    if (Type <> Type::Cost) and
                       not ReplaceServItemAction
                    then
                        Validate(Quantity, xRec.Quantity);
                    UpdateUnitPriceByField(FieldNo("No."), false);
                    UpdateAmounts();
                end;
                UpdateReservation(FieldNo("No."));

                GetDefaultBin();

                if not IsTemporary then
                    CreateDimFromDefaultDim(Rec.FieldNo("No."));

                if ServiceLine.Get("Document Type", "Document No.", "Line No.") then
                    Modify();
            end;
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdateWithWarehouseShip();
                GetServHeader();
                if Type = Type::Item then begin
                    if Quantity <> 0 then
                        ServiceWarehouseMgt.ServiceLineVerifyChange(Rec, xRec);
                    if "Location Code" <> xRec."Location Code" then begin
                        TestField("Reserved Quantity", 0);
                        TestField("Shipment No.", '');
                        TestField("Qty. Shipped Not Invoiced", 0);
                        CheckItemAvailable(FieldNo("Location Code"));
                        UpdateReservation(FieldNo("Location Code"));
                    end;
                    GetUnitCost();
                end;
                GetDefaultBin();
                CreateDimFromDefaultDim(Rec.FieldNo("Location Code"));
            end;
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = if (Type = const(Item)) "Inventory Posting Group";
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(13; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                Item: Record Item;
                ItemLedgEntry: Record "Item Ledger Entry";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantity(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                GetServHeader();
                TestField(Type);
                TestField("No.");
                TestStatusOpen();

                TestQuantityPositive();

                case "Spare Part Action" of
                    "Spare Part Action"::Permanent, "Spare Part Action"::"Temporary":
                        if Quantity <> 1 then
                            Error(Text011, ServItem.TableCaption());
                    "Spare Part Action"::"Component Replaced", "Spare Part Action"::"Component Installed":
                        if Quantity <> Round(Quantity, 1) then
                            Error(Text026, FieldCaption(Quantity));
                end;

                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));

                "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));
                OnValidateQuantityOnAfterCalcQuantityBase(Rec, xRec);

                if "Document Type" <> "Document Type"::"Credit Memo" then begin
                    if (Quantity * "Quantity Shipped" < 0) or
                       ((Abs(Quantity) < Abs("Quantity Shipped")) and ("Shipment No." = ''))
                    then
                        FieldError(Quantity, StrSubstNo(Text003, FieldCaption("Quantity Shipped")));
                    if ("Quantity (Base)" * "Qty. Shipped (Base)" < 0) or
                       ((Abs("Quantity (Base)") < Abs("Qty. Shipped (Base)")) and ("Shipment No." = ''))
                    then
                        FieldError("Quantity (Base)", StrSubstNo(Text003, FieldCaption("Qty. Shipped (Base)")));
                end;

                if (xRec.Quantity <> Quantity) or (xRec."Quantity (Base)" <> "Quantity (Base)") then begin
                    InitOutstanding();
                    if "Document Type" = "Document Type"::"Credit Memo" then
                        InitQtyToInvoice()
                    else
                        InitQtyToShip();
                end;
                CheckItemAvailable(FieldNo(Quantity));

                if (Quantity * xRec.Quantity < 0) or (Quantity = 0) then
                    InitItemAppl(false);

                if xRec.Quantity <> Quantity then
                    PlanPriceCalcByField(FieldNo(Quantity));

                if Type = Type::Item then begin
                    ServiceWarehouseMgt.ServiceLineVerifyChange(Rec, xRec);
                    UpdateReservation(FieldNo(Quantity));
                    UpdateWithWarehouseShip();
                    if ("Quantity (Base)" * xRec."Quantity (Base)" <= 0) and ("No." <> '') then begin
                        GetItem(Item);

                        OnValidateQuantityOnBeforeGetUnitCost(Rec, CurrFieldNo);
                        if (Item."Costing Method" = Item."Costing Method"::Standard) and not IsShipment() then
                            GetUnitCost();
                    end;
                    if ("Appl.-from Item Entry" <> 0) and (xRec.Quantity < Quantity) then
                        CheckApplFromItemLedgEntry(ItemLedgEntry);
                end else
                    Validate("Line Discount %");

                OnValidateQuantityOnBeforeResetAmounts(Rec, xRec);
                if (xRec.Quantity <> Quantity) and (Quantity = 0) and
                   ((Amount <> 0) or
                    ("Amount Including VAT" <> 0) or
                    ("VAT Base Amount" <> 0))
                then begin
                    Amount := 0;
                    "Amount Including VAT" := 0;
                    "VAT Base Amount" := 0;
                end;
                if "Job Planning Line No." <> 0 then
                    Validate("Job Planning Line No.");

                UpdateUnitPriceByField(FieldNo(Quantity), true);
            end;
        }
        field(16; "Outstanding Quantity"; Decimal)
        {
            Caption = 'Outstanding Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(17; "Qty. to Invoice"; Decimal)
        {
            Caption = 'Qty. to Invoice';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                CheckQtyToInvoicePositive();

                if "Qty. to Invoice" > 0 then begin
                    "Qty. to Consume" := 0;
                    "Qty. to Consume (Base)" := 0;
                end;

                if "Qty. to Invoice" = MaxQtyToInvoice() then
                    InitQtyToInvoice()
                else begin
                    "Qty. to Invoice (Base)" := CalcBaseQty("Qty. to Invoice", FieldCaption("Qty. to Invoice"), FieldCaption("Qty. to Invoice (Base)"));
                    ValidateQuantityInvIsBalanced();
                end;
                if ("Qty. to Invoice" * Quantity < 0) or
               (Abs("Qty. to Invoice") > Abs(MaxQtyToInvoice()))
            then
                    Error(
                      Text000,
                      MaxQtyToInvoice());
                if ("Qty. to Invoice (Base)" * "Quantity (Base)" < 0) or
                   (Abs("Qty. to Invoice (Base)") > Abs(MaxQtyToInvoiceBase()))
                then
                    Error(
                      Text001,
                      MaxQtyToInvoiceBase());
                ClearVATDifference();

                if (xRec."Qty. to Consume" <> "Qty. to Consume") or
                   (xRec."Qty. to Consume (Base)" <> "Qty. to Consume (Base)")
                then
                    Validate("Line Discount %")
                else begin
                    CalcInvDiscToInvoice();
                    UpdateAmounts();
                end;
            end;
        }
        field(18; "Qty. to Ship"; Decimal)
        {
            Caption = 'Qty. to Ship';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                CheckQtyToShipPositive();

                if (CurrFieldNo <> 0) and
                   (Type = Type::Item) and
                   ("Qty. to Ship" <> 0)
                then
                    CheckWarehouse();

                if "Qty. to Ship" = "Outstanding Quantity" then begin
                    if not LineRequiresShipmentOrReceipt() then
                        InitQtyToShip()
                    else begin
                        "Qty. to Ship (Base)" := CalcBaseQty("Qty. to Ship", FieldCaption("Qty. to Ship"), FieldCaption("Qty. to Ship (Base)"));
                        ValidateQuantityShipIsBalanced();
                    end;
                    if "Qty. to Consume" <> 0 then
                        Validate("Qty. to Consume", "Qty. to Ship")
                    else
                        Validate("Qty. to Consume", 0);
                end else begin
                    "Qty. to Ship (Base)" := CalcBaseQty("Qty. to Ship", FieldCaption("Qty. to Ship"), FieldCaption("Qty. to Ship (Base)"));
                    ValidateQuantityShipIsBalanced();

                    if "Qty. to Consume" <> 0 then
                        Validate("Qty. to Consume", "Qty. to Ship")
                    else
                        Validate("Qty. to Consume", 0);
                end;

                IsHandled := false;
                OnValidateQtyToShipOnBeforeQtyToShipCheck(Rec, xRec, CurrFieldNo, IsHandled);
                if not IsHandled then begin
                    if not CanShipQty() then
                        Error(Text016, "Outstanding Quantity");

                    if not CanShipBaseQty() then
                        Error(Text017, "Outstanding Qty. (Base)");
                end;
            end;
        }
        field(22; "Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            CaptionClass = GetCaptionClass(FieldNo("Unit Price"));
            Caption = 'Unit Price';

            trigger OnValidate()
            begin
                TestStatusOpen();
                GetServHeader();
                if ("Appl.-to Service Entry" > 0) and (CurrFieldNo <> 0) then
                    Error(Text052, FieldCaption("Unit Price"));
                if ("Unit Price" > ServHeader."Max. Labor Unit Price") and
                   (Type = Type::Resource) and
                   (ServHeader."Max. Labor Unit Price" <> 0)
                then
                    Error(
                      Text022,
                      FieldCaption("Unit Price"), ServHeader.FieldCaption("Max. Labor Unit Price"),
                      ServHeader.TableCaption());

                Validate("Line Discount %");
            end;
        }
        field(23; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                GetServHeader();
                Currency.Initialize("Currency Code");
                if "Unit Cost (LCY)" <> xRec."Unit Cost (LCY)" then
                    if (CurrFieldNo = FieldNo("Unit Cost (LCY)")) and
                       (Type = Type::Item) and ("No." <> '') and ("Quantity (Base)" <> 0)
                    then begin
                        GetItem(Item);
                        if (Item."Costing Method" = Item."Costing Method"::Standard) and not IsShipment() then begin
                            if "Document Type" in ["Document Type"::"Credit Memo"] then
                                Error(
                                  Text037,
                                  FieldCaption("Unit Cost (LCY)"), Item.FieldCaption("Costing Method"),
                                  Item."Costing Method", FieldCaption(Quantity));
                            Error(
                              Text038,
                              FieldCaption("Unit Cost (LCY)"), Item.FieldCaption("Costing Method"),
                              Item."Costing Method", FieldCaption(Quantity));
                        end;
                    end;

                if "Currency Code" <> '' then begin
                    Currency.TestField("Unit-Amount Rounding Precision");
                    "Unit Cost" :=
                      Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          GetDate(), "Currency Code", "Unit Cost (LCY)",
                          ServHeader."Currency Factor"), Currency."Unit-Amount Rounding Precision")
                end else
                    "Unit Cost" := "Unit Cost (LCY)";

                UpdateRemainingCostsAndAmounts();
            end;
        }
        field(25; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(27; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Line Discount %") then
                    TestStatusOpen();
                GetServHeader();
                if (CurrFieldNo in
                    [FieldNo("Line Discount %"),
                     FieldNo("Line Discount Amount"),
                     FieldNo("Line Amount")]) and
                   ("Document Type" <> "Document Type"::Invoice)
                then
                    CheckLineDiscount("Line Discount %");

                "Line Discount Amount" :=
                  Round(
                    Round(CalcChargeableQty() * "Unit Price", Currency."Amount Rounding Precision") *
                    "Line Discount %" / 100, Currency."Amount Rounding Precision");
                "Inv. Discount Amount" := 0;
                "Inv. Disc. Amount to Invoice" := 0;
                "Pmt. Discount Amount" := 0;

                UpdateAmounts();
                NotifyOnMissingSetup(FieldNo("Line Discount Amount"));
            end;
        }
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';

            trigger OnValidate()
            begin
                TestStatusOpen();
                GetServHeader();
                TestQtyFromLineDiscountAmount();
                if "Line Discount Amount" <> xRec."Line Discount Amount" then
                    UpdateLineDiscPct();
                "Inv. Discount Amount" := 0;
                "Inv. Disc. Amount to Invoice" := 0;
                "Pmt. Discount Amount" := 0;
                Validate("Line Discount %");
            end;
        }
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;

            trigger OnValidate()
            begin
                GetServHeader();
                Amount := Round(Amount, Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            "VAT Base Amount" :=
                              Round(Amount * (1 - GetVatBaseDiscountPct(ServHeader) / 100), Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              Round(Amount + "VAT Base Amount" * GetVATPct() / 100, Currency."Amount Rounding Precision");
                            OnValidateAmountOnAfterCalculateNormalVAT(Rec, ServHeader, Currency);
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        if Amount <> 0 then
                            FieldError(Amount,
                              StrSubstNo(
                                Text013, FieldCaption("VAT Calculation Type"),
                                "VAT Calculation Type"));
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            ServHeader.TestField("VAT Base Discount %", 0);
                            "VAT Base Amount" := Round(Amount, Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              Amount +
                              SalesTaxCalculate.CalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable", ServHeader."Posting Date",
                                "VAT Base Amount", "Quantity (Base)", ServHeader."Currency Factor");
                            OnAfterSalesTaxCalculate(Rec, ServHeader, Currency);
                            UpdateVATPercent("VAT Base Amount", "Amount Including VAT" - "VAT Base Amount");
                            "Amount Including VAT" := Round("Amount Including VAT", Currency."Amount Rounding Precision");
                        end;
                end;

                "Pmt. Discount Amount" := 0;
                InitOutstandingAmount();
            end;
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;

            trigger OnValidate()
            begin
                GetServHeader();
                "Amount Including VAT" := Round("Amount Including VAT", Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            Amount :=
                              Round(
                                "Amount Including VAT" /
                                (1 + (1 - GetVatBaseDiscountPct(ServHeader) / 100) * GetVATPct() / 100),
                                Currency."Amount Rounding Precision");
                            "VAT Base Amount" :=
                              Round(Amount * (1 - GetVatBaseDiscountPct(ServHeader) / 100), Currency."Amount Rounding Precision");
                            OnValidateAmountIncludingVATOnAfterCalculateNormalVAT(Rec, ServHeader, Currency);
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            ServHeader.TestField("VAT Base Discount %", 0);
                            Amount :=
                              SalesTaxCalculate.ReverseCalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable", ServHeader."Posting Date",
                                "Amount Including VAT", "Quantity (Base)", ServHeader."Currency Factor");
                            OnAfterSalesTaxCalculateReverse(Rec, ServHeader, Currency);
                            UpdateVATPercent(Amount, "Amount Including VAT" - Amount);
                            Amount := Round(Amount, Currency."Amount Rounding Precision");
                            "VAT Base Amount" := Amount;
                        end;
                end;

                "Pmt. Discount Amount" := 0;
                InitOutstandingAmount();
            end;
        }
        field(32; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            InitValue = true;

            trigger OnValidate()
            begin
                TestStatusOpen();
                if ("Allow Invoice Disc." <> xRec."Allow Invoice Disc.") and
                   not "Allow Invoice Disc."
                then begin
                    "Inv. Discount Amount" := 0;
                    "Inv. Disc. Amount to Invoice" := 0;
                    "Pmt. Discount Amount" := 0;
                    UpdateAmounts();
                end;
            end;
        }
        field(34; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
        }
        field(35; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
        }
        field(36; "Units per Parcel"; Decimal)
        {
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
        }
        field(37; "Unit Volume"; Decimal)
        {
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
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

                    ItemLedgEntry.Get("Appl.-to Item Entry");
                    ItemLedgEntry.TestField(Positive, true);
                    Validate("Unit Cost (LCY)", CalcUnitCost(ItemLedgEntry));
                    "Location Code" := ItemLedgEntry."Location Code";
                    OnValidateApplToItemEntryOnBeforeShowNotOpenItemLedgerEntryMessage(Rec, xRec, ItemLedgEntry, CurrFieldNo);
                    if not ItemLedgEntry.Open then
                        Message(Text042, "Appl.-to Item Entry");
                end;
            end;
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
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
        field(41; "Shortcut Dimension 2 Code"; Code[20])
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
        field(42; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            Editable = false;
            TableRelation = "Customer Price Group";

            trigger OnValidate()
            begin
                if Type = Type::Item then begin
                    if "Customer Price Group" <> xRec."Customer Price Group" then
                        PlanPriceCalcByField(FieldNo("Customer Price Group"));
                    UpdateUnitPriceByField(FieldNo("Customer Price Group"), false);
                end;
            end;
        }
        field(45; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job."No." where("Bill-to Customer No." = field("Bill-to Customer No."));

            trigger OnValidate()
            var
                Job: Record Job;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestField("Quantity Consumed", 0);
                Validate("Job Task No.", '');

                if "Job No." <> '' then begin
                    Job.Get("Job No.");
                    Job.TestBlocked();
                end;

                CreateDimFromDefaultDim(Rec.FieldNo("Job No."));
            end;
        }
        field(46; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobTaskNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestField("Quantity Consumed", 0);
                if "Job Task No." = '' then
                    "Job Line Type" := "Job Line Type"::" ";

                if "Job Task No." <> xRec."Job Task No." then
                    Validate("Job Planning Line No.", 0);
            end;
        }
        field(47; "Job Line Type"; Enum "Job Line Type")
        {
            Caption = 'Project Line Type';

            trigger OnValidate()
            begin
                TestField("Quantity Consumed", 0);
                TestField("Job No.");
                TestField("Job Task No.");
                if "Job Planning Line No." <> 0 then
                    Error(Text048, FieldCaption("Job Line Type"), FieldCaption("Job Planning Line No."));
            end;
        }
        field(52; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";

            trigger OnValidate()
            var
                WorkType: Record "Work Type";
            begin
                if Type = Type::Resource then begin
                    TestStatusOpen();
                    if WorkType.Get("Work Type Code") then
                        Validate("Unit of Measure Code", WorkType."Unit of Measure Code");

                    OnValidateWorkTypeCodeOnBeforePlanPriceCalcByField(Rec, xRec);
                    if "Work Type Code" <> xRec."Work Type Code" then
                        PlanPriceCalcByField(FieldNo("Work Type Code"));
                    UpdateUnitPriceByField(FieldNo("Work Type Code"), true);
                end;
            end;
        }
        field(57; "Outstanding Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Outstanding Amount';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record Currency;
            begin
                GetServHeader();
                Currency2.InitRoundingPrecision();
                if ServHeader."Currency Code" <> '' then
                    "Outstanding Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GetDate(), "Currency Code",
                          "Outstanding Amount", ServHeader."Currency Factor"),
                        Currency2."Amount Rounding Precision")
                else
                    "Outstanding Amount (LCY)" :=
                      Round("Outstanding Amount", Currency2."Amount Rounding Precision");
            end;
        }
        field(58; "Qty. Shipped Not Invoiced"; Decimal)
        {
            Caption = 'Qty. Shipped Not Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(59; "Shipped Not Invoiced"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Shipped Not Invoiced';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record Currency;
            begin
                GetServHeader();
                Currency2.InitRoundingPrecision();
                if ServHeader."Currency Code" <> '' then
                    "Shipped Not Invoiced (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GetDate(), "Currency Code",
                          "Shipped Not Invoiced", ServHeader."Currency Factor"),
                        Currency2."Amount Rounding Precision")
                else
                    "Shipped Not Invoiced (LCY)" :=
                      Round("Shipped Not Invoiced", Currency2."Amount Rounding Precision");
            end;
        }
        field(60; "Quantity Shipped"; Decimal)
        {
            Caption = 'Quantity Shipped';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(61; "Quantity Invoiced"; Decimal)
        {
            Caption = 'Quantity Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(63; "Shipment No."; Code[20])
        {
            Caption = 'Shipment No.';

            trigger OnLookup()
            var
                ServShptHeader: Record "Service Shipment Header";
            begin
                GetServHeader();
                if "Document Type" = "Document Type"::"Credit Memo" then begin
                    ServShptHeader.Reset();
                    ServShptHeader.SetCurrentKey("Customer No.", "Posting Date");
                    ServShptHeader.FilterGroup(2);
                    ServShptHeader.SetRange("Customer No.", ServHeader."Customer No.");
                    ServShptHeader.SetRange("Ship-to Code", ServHeader."Ship-to Code");
                    ServShptHeader.SetRange("Bill-to Customer No.", ServHeader."Bill-to Customer No.");
                    ServShptHeader.FilterGroup(0);
                    ServShptHeader."No." := "Shipment No.";
                    if PAGE.RunModal(0, ServShptHeader) = ACTION::LookupOK then
                        Validate("Shipment No.", ServShptHeader."No.");
                end
            end;

            trigger OnValidate()
            var
                ServShptHeader: Record "Service Shipment Header";
                ServDocReg: Record "Service Document Register";
            begin
                if "Shipment No." <> xRec."Shipment No." then begin
                    if "Shipment No." <> '' then begin
                        GetServHeader();
                        if "Document Type" = "Document Type"::"Credit Memo" then begin
                            ServShptHeader.Reset();
                            ServShptHeader.SetCurrentKey("Customer No.", "Posting Date");
                            ServShptHeader.SetRange("Customer No.", ServHeader."Customer No.");
                            ServShptHeader.SetRange("Ship-to Code", ServHeader."Ship-to Code");
                            ServShptHeader.SetRange("Bill-to Customer No.", ServHeader."Bill-to Customer No.");
                            ServShptHeader.SetRange("No.", "Shipment No.");
                            ServShptHeader.FindFirst();
                        end;
                    end;
                    TestField("Appl.-to Service Entry", 0);
                    ServDocReg.Reset();
                    ServDocReg.SetRange("Destination Document Type", "Document Type");
                    ServDocReg.SetRange("Destination Document No.", "Document No.");
                    ServDocReg.SetRange("Source Document Type", ServDocReg."Source Document Type"::Order);
                    ServDocReg.SetRange("Source Document No.", xRec."Shipment No.");
                    ServDocReg.DeleteAll();
                    Clear(ServDocReg);
                end;
            end;
        }
        field(64; "Shipment Line No."; Integer)
        {
            Caption = 'Shipment Line No.';
            Editable = false;
        }
        field(65; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(68; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            Editable = false;

            trigger OnValidate()
            begin
                TestField(Quantity);
                CalcInvDiscToInvoice();
                UpdateAmounts();
            end;
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            var
                GenBusPostingGroup: Record "Gen. Business Posting Group";
            begin
                if "Gen. Bus. Posting Group" <> xRec."Gen. Bus. Posting Group" then
                    if GenBusPostingGroup.ValidateVatBusPostingGroup(GenBusPostingGroup, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGroup."Def. VAT Bus. Posting Group");
            end;
        }
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            var
                GenProdPostingGroup: Record "Gen. Product Posting Group";
            begin
                TestStatusOpen();
                if "Gen. Prod. Posting Group" <> xRec."Gen. Prod. Posting Group" then
                    if GenProdPostingGroup.ValidateVatProdPostingGroup(GenProdPostingGroup, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGroup."Def. VAT Prod. Posting Group");
            end;
        }
        field(77; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(78; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(79; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(80; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            Editable = false;
            TableRelation = "Service Line"."Line No." where("Document Type" = field("Document Type"),
                                                             "Document No." = field("Document No."));
        }
        field(81; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(82; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(83; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(85; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                UpdateAmounts();
            end;
        }
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate()
            begin
                UpdateAmounts();
            end;
        }
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdateAmounts();
            end;
        }
        field(88; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            var
                VATPostingSetup: Record "VAT Posting Setup";
            begin
                TestStatusOpen();
                ClearVATDifference();
                VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                CopyFromVATPostingSetup(VATPostingSetup);

                OnValidateVATProdPostingGroupOnAfterCopyFields(Rec, xRec, ServHeader);

                CheckVATCalculationType(VATPostingSetup);
                GetServHeader();
                if ServHeader."Prices Including VAT" and (Type in [Type::Item, Type::Resource]) then
                    Validate("Unit Price",
                      Round(
                        "Unit Price" * (100 + GetVATPct()) / (100 + xRec.GetVATPct()),
                        Currency."Unit-Amount Rounding Precision"));
                UpdateAmounts();
            end;
        }
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(92; "Outstanding Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Outstanding Amount (LCY)';
            Editable = false;
        }
        field(93; "Shipped Not Invoiced (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Shipped Not Invoiced (LCY)';
            Editable = false;
        }
        field(95; "Reserved Quantity"; Decimal)
        {
            CalcFormula = - sum("Reservation Entry".Quantity where("Source ID" = field("Document No."),
                                                                   "Source Ref. No." = field("Line No."),
                                                                   "Source Type" = const(5902),
#pragma warning disable AL0603
                                                                   "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                   "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(96; Reserve; Enum "Reserve Method")
        {
            Caption = 'Reserve';

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if Reserve in [Reserve::Optional, Reserve::Always] then begin
                    TestField(Type, Type::Item);
                    TestField("No.");
                end;
                CalcFields("Reserved Qty. (Base)");
                if (Reserve = Reserve::Never) and ("Reserved Qty. (Base)" > 0) then
                    TestField("Reserved Qty. (Base)", 0);

                if xRec.Reserve = Reserve::Always then begin
                    GetItem(Item);
                    if Item.Reserve = Item.Reserve::Always then
                        TestField(Reserve, Reserve::Always);
                end;
            end;
        }
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            Editable = false;
        }
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Line Amount"));
            Caption = 'Line Amount';

            trigger OnValidate()
            var
                ServAmountsMgt: Codeunit "Serv-Amounts Mgt.";
                LineDiscountAmountExpected: Decimal;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateLineAmount(Rec, xRec, Currency, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField(Type);
                TestQtyFromLineAmount();
                TestField("Unit Price");
                Currency.Initialize("Currency Code");
                "Line Amount" := Round("Line Amount", Currency."Amount Rounding Precision");
                LineDiscountAmountExpected := Round(CalcChargeableQty() * "Unit Price", Currency."Amount Rounding Precision") - "Line Amount";
                if ServAmountsMgt.AmountsDifferByMoreThanRoundingPrecision(LineDiscountAmountExpected, "Line Discount Amount", Currency."Amount Rounding Precision") then
                    Validate("Line Discount Amount", LineDiscountAmountExpected);
                GetServHeader();
                if ServHeader."Tax Area Code" = '' then
                    UpdateVATAmounts();
            end;
        }
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(105; "Inv. Disc. Amount to Invoice"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Disc. Amount to Invoice';
            Editable = false;
        }
        field(106; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(145; "Pmt. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Pmt. Discount Amount';

            trigger OnValidate()
            begin
                TestField(Quantity);
                UpdateAmounts();
            end;
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
        field(950; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            TableRelation = "Time Sheet Header";
        }
        field(951; "Time Sheet Line No."; Integer)
        {
            Caption = 'Time Sheet Line No.';
            TableRelation = "Time Sheet Line"."Line No." where("Time Sheet No." = field("Time Sheet No."));
        }
        field(952; "Time Sheet Date"; Date)
        {
            Caption = 'Time Sheet Date';
            TableRelation = "Time Sheet Detail".Date where("Time Sheet No." = field("Time Sheet No."),
                                                            "Time Sheet Line No." = field("Time Sheet Line No."));
        }
        field(1019; "Job Planning Line No."; Integer)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Project Planning Line No.';

            trigger OnLookup()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                JobPlanningLine.SetRange("Job No.", "Job No.");
                JobPlanningLine.SetRange("Job Task No.", "Job Task No.");
                case Type of
                    Type::"G/L Account":
                        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::"G/L Account");
                    Type::Item:
                        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
                end;
                JobPlanningLine.SetRange("No.", "No.");
                JobPlanningLine.SetRange("Usage Link", true);
                JobPlanningLine.SetRange("System-Created Entry", false);

                if PAGE.RunModal(0, JobPlanningLine) = ACTION::LookupOK then
                    Validate("Job Planning Line No.", JobPlanningLine."Line No.");
            end;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                if "Job Planning Line No." <> 0 then begin
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    JobPlanningLine.TestField("Job No.", "Job No.");
                    JobPlanningLine.TestField("Job Task No.", "Job Task No.");
                    case Type of
                        Type::Resource:
                            JobPlanningLine.TestField(Type, JobPlanningLine.Type::Resource);
                        Type::Item:
                            JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
                        Type::"G/L Account":
                            JobPlanningLine.TestField(Type, JobPlanningLine.Type::"G/L Account");
                    end;
                    JobPlanningLine.TestField("No.", "No.");
                    JobPlanningLine.TestField("Usage Link", true);
                    JobPlanningLine.TestField("System-Created Entry", false);
                    "Job Line Type" := JobPlanningLine.ConvertToJobLineType();
                    Validate("Job Remaining Qty.", JobPlanningLine."Remaining Qty." - Quantity);
                end else
                    Validate("Job Remaining Qty.", 0);
            end;
        }
        field(1030; "Job Remaining Qty."; Decimal)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project Remaining Qty.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                if ("Job Remaining Qty." <> 0) and ("Job Planning Line No." = 0) then
                    Error(Text047, FieldCaption("Job Remaining Qty."), FieldCaption("Job Planning Line No."));

                if "Job Planning Line No." <> 0 then begin
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    if JobPlanningLine.Quantity >= 0 then begin
                        if "Job Remaining Qty." < 0 then
                            "Job Remaining Qty." := 0;
                    end else
                        if "Job Remaining Qty." > 0 then
                            "Job Remaining Qty." := 0;
                end;
                "Job Remaining Qty. (Base)" := CalcBaseQty("Job Remaining Qty.", FieldCaption("Job Remaining Qty."), FieldCaption("Job Remaining Qty. (Base)"));
                UpdateRemainingCostsAndAmounts();
            end;
        }
        field(1031; "Job Remaining Qty. (Base)"; Decimal)
        {
            Caption = 'Project Remaining Qty. (Base)';
        }
        field(1032; "Job Remaining Total Cost"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Project Remaining Total Cost';
            Editable = false;
        }
        field(1033; "Job Remaining Total Cost (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            Caption = 'Project Remaining Total Cost (LCY)';
            Editable = false;
        }
        field(1034; "Job Remaining Line Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Project Remaining Line Amount';
            Editable = false;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item), "Document Type" = filter(<> "Credit Memo")) "Item Variant".Code where("Item No." = field("No."), Blocked = const(false), "Service Blocked" = const(false))
            else
            if (Type = const(Item), "Document Type" = filter("Credit Memo")) "Item Variant".Code where("Item No." = field("No."), Blocked = const(false));

            trigger OnValidate()
            var
                Item: Record Item;
                ItemVariant: Record "Item Variant";
                ServOrderManagement: Codeunit ServOrderManagement;
            begin
                if "Variant Code" <> '' then
                    TestField(Type, Type::Item);
                TestStatusOpen();

                if xRec."Variant Code" <> "Variant Code" then begin
                    TestField("Qty. Shipped Not Invoiced", 0);
                    TestField("Shipment No.", '');
                    InitItemAppl(false);
                end;

                CheckItemAvailable(FieldNo("Variant Code"));
                UpdateReservation(FieldNo("Variant Code"));
                OnValidateVariantCodeOnAfterUpdateReservation(Rec);

                if Type = Type::Item then begin
                    GetUnitCost();
                    if "Variant Code" <> xRec."Variant Code" then
                        PlanPriceCalcByField(FieldNo("Variant Code"));
                    ServiceWarehouseMgt.ServiceLineVerifyChange(Rec, xRec);
                end;

                GetDefaultBin();

                if Rec."Variant Code" = '' then begin
                    if Type = Type::Item then begin
                        GetItem(Item);
                        Description := Item.Description;
                        "Description 2" := Item."Description 2";
                        UpdateItemReference();
                        OnValidateVariantCodeOnAssignItem(Rec, Item);
                        GetItemTranslation();
                    end;
                    exit;
                end;

                ItemVariant.Get("No.", "Variant Code");
                if ItemVariant."Service Blocked" then
                    if ServOrderManagement.IsCreditDocumentType("Document Type") then
                        SendBlockedItemVariantNotification();
                Description := ItemVariant.Description;
                "Description 2" := ItemVariant."Description 2";
                OnValidateVariantCodeOnAssignItemVariant(Rec, ItemVariant);

                if Rec.Type = Rec.Type::Item then
                    UpdateItemReference();
                GetServHeader();
                if ServHeader."Language Code" <> '' then
                    GetItemTranslation();

                UpdateUnitPriceByField(FieldNo("Variant Code"), true);
            end;
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = if ("Document Type" = filter(Order | Invoice),
                                "Location Code" = filter(<> ''),
                                Type = const(Item)) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                  "Item No." = field("No."),
                                                                                  "Variant Code" = field("Variant Code"))
            else
            if ("Document Type" = filter("Credit Memo"),
                                                                                           "Location Code" = filter(<> ''),
                                                                                           Type = const(Item)) Bin.Code where("Location Code" = field("Location Code"));

            trigger OnLookup()
            var
                WMSManagement: Codeunit "WMS Management";
                BinCode: Code[20];
            begin
                TestField("Location Code");
                TestField(Type, Type::Item);

                if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then
                    BinCode := WMSManagement.BinContentLookUp("Location Code", "No.", "Variant Code", '', "Bin Code")
                else
                    if "Document Type" = "Document Type"::"Credit Memo" then
                        BinCode := WMSManagement.BinLookUp("Location Code", "No.", "Variant Code", '');

                if BinCode <> '' then
                    Validate("Bin Code", BinCode);
            end;

            trigger OnValidate()
            var
                Item: Record Item;
                WMSManagement: Codeunit "WMS Management";
                WhseIntegrationManagement: Codeunit "Whse. Integration Management";
            begin
                TestField("Location Code");
                TestField(Type, Type::Item);

                GetItem(Item);
                Item.TestField(Type, Item.Type::Inventory);

                if "Bin Code" <> '' then
                    if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then
                        WMSManagement.FindBinContent("Location Code", "Bin Code", "No.", "Variant Code", '')
                    else
                        if "Document Type" = "Document Type"::"Credit Memo" then
                            WMSManagement.FindBin("Location Code", "Bin Code", '');

                if xRec."Bin Code" <> "Bin Code" then begin
                    TestField("Qty. Shipped Not Invoiced", 0);
                    TestField("Shipment No.", '');
                end;

                if "Bin Code" <> '' then
                    WhseIntegrationManagement.CheckBinTypeAndCode(
                        DATABASE::"Service Line", FieldCaption("Bin Code"), "Location Code", "Bin Code", "Document Type".AsInteger());
            end;
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5405; Planned; Boolean)
        {
            Caption = 'Planned';
            Editable = false;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            if (Type = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("No."))
            else
            "Unit of Measure";

            trigger OnValidate()
            var
                Item: Record Item;
                UnitOfMeasure: Record "Unit of Measure";
                UnitOfMeasureTranslation: Record "Unit of Measure Translation";
                ResUnitofMeasure: Record "Resource Unit of Measure";
            begin
                TestField("Quantity Shipped", 0);
                TestField("Qty. Shipped (Base)", 0);
                TestStatusOpen();

                if "Unit of Measure Code" = '' then
                    "Unit of Measure" := ''
                else begin
                    if not UnitOfMeasure.Get("Unit of Measure Code") then
                        UnitOfMeasure.Init();
                    "Unit of Measure" := UnitOfMeasure.Description;
                    GetServHeader();
                    if ServHeader."Language Code" <> '' then begin
                        UnitOfMeasureTranslation.SetRange(Code, "Unit of Measure Code");
                        UnitOfMeasureTranslation.SetRange("Language Code", ServHeader."Language Code");
                        if UnitOfMeasureTranslation.FindFirst() then
                            "Unit of Measure" := UnitOfMeasureTranslation.Description;
                    end;
                end;

                OnValidateUnitOfMeasureOnAfterAssignUnitofMeasureValue(Rec);

                case Type of
                    Type::Item:
                        begin
                            if Quantity <> 0 then
                                ServiceWarehouseMgt.ServiceLineVerifyChange(Rec, xRec);
                            GetItem(Item);
                            GetUnitCost();
                            if "Unit of Measure Code" <> xRec."Unit of Measure Code" then
                                PlanPriceCalcByField(FieldNo("Unit of Measure Code"));
                            "Gross Weight" := Item."Gross Weight" * "Qty. per Unit of Measure";
                            "Net Weight" := Item."Net Weight" * "Qty. per Unit of Measure";
                            "Unit Volume" := Item."Unit Volume" * "Qty. per Unit of Measure";
                            "Units per Parcel" := Round(Item."Units per Parcel" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                            "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                            "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");

                            if "Qty. per Unit of Measure" > xRec."Qty. per Unit of Measure" then
                                InitItemAppl(false);
                        end;
                    Type::Resource:
                        begin
                            if "Unit of Measure Code" = '' then begin
                                GetResource();
                                "Unit of Measure Code" := Resource."Base Unit of Measure";
                                if UnitOfMeasure.Get("Unit of Measure Code") then
                                    "Unit of Measure" := UnitOfMeasure.Description;
                            end;
                            ResUnitofMeasure.Get("No.", "Unit of Measure Code");
                            "Qty. per Unit of Measure" := ResUnitofMeasure."Qty. per Unit of Measure";
                            if "Unit of Measure Code" <> xRec."Unit of Measure Code" then
                                PlanPriceCalcByField(FieldNo("Unit of Measure Code"));
                        end;
                    Type::"G/L Account", Type::" ", Type::Cost:
                        "Qty. per Unit of Measure" := 1;
                end;

                OnValidateUnitOfMeasureCodeOnBeforeValidateQuantity(Rec, Item);
                Validate(Quantity);
                UpdateUnitPriceByField(FieldNo("Unit of Measure Code"), true);
                CheckItemAvailable(FieldNo("Unit of Measure Code"));
                UpdateReservation(FieldNo("Unit of Measure Code"));
            end;
        }
        field(5408; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(5409; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(5415; "Quantity (Base)"; Decimal)
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

                if "Quantity (Base)" < 0 then
                    FieldError("Quantity (Base)", Text029);

                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(5416; "Outstanding Qty. (Base)"; Decimal)
        {
            Caption = 'Outstanding Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5417; "Qty. to Invoice (Base)"; Decimal)
        {
            Caption = 'Qty. to Invoice (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyToInvoiceBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Qty. to Invoice (Base)" < 0 then
                    FieldError("Qty. to Invoice (Base)", Text029);

                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Invoice", "Qty. to Invoice (Base)");
            end;
        }
        field(5418; "Qty. to Ship (Base)"; Decimal)
        {
            Caption = 'Qty. to Ship (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyToShipBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Qty. to Ship (Base)" < 0 then
                    FieldError("Qty. to Ship (Base)", Text029);

                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Ship", "Qty. to Ship (Base)");
            end;
        }
        field(5458; "Qty. Shipped Not Invd. (Base)"; Decimal)
        {
            Caption = 'Qty. Shipped Not Invd. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5460; "Qty. Shipped (Base)"; Decimal)
        {
            Caption = 'Qty. Shipped (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5461; "Qty. Invoiced (Base)"; Decimal)
        {
            Caption = 'Qty. Invoiced (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5495; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Source ID" = field("Document No."),
                                                                            "Source Ref. No." = field("Line No."),
                                                                            "Source Type" = const(5902),
#pragma warning disable AL0603
                                                                            "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                            "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure");
                UpdatePlanned();
            end;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            Editable = false;
            TableRelation = "Responsibility Center";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateResponsibilityCenter(Rec, DimMgt, IsHandled);
                if IsHandled then
                    exit;

                CreateDimFromDefaultDim(Rec.FieldNo("Responsibility Center"));
            end;
        }
        field(5702; "Substitution Available"; Boolean)
        {
            CalcFormula = exist("Item Substitution" where(Type = const(Item),
                                                           "No." = field("No."),
                                                           "Substitute Type" = const(Item)));
            Caption = 'Substitution Available';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5709; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        field(5710; Nonstock; Boolean)
        {
            Caption = 'Catalog';
            Editable = false;
        }
        field(5750; "Whse. Outstanding Qty. (Base)"; Decimal)
        {
            BlankZero = true;
            CalcFormula = sum("Warehouse Shipment Line"."Qty. Outstanding (Base)" where("Source Type" = const(5902),
#pragma warning disable AL0603
                                                                                         "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                                         "Source No." = field("Document No."),
                                                                                         "Source Line No." = field("Line No.")));
            Caption = 'Whse. Outstanding Qty. (Base)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5725; "Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Item Reference No.';
            ExtendedDatatype = Barcode;

            trigger OnLookup()
            begin
                GetServHeader();
                ServItemReferenceMgt.ServiceReferenceNoLookUp(Rec, ServHeader);
            end;

            trigger OnValidate()
            var
                ItemReference: Record "Item Reference";
            begin
                GetServHeader();
                "Customer No." := ServHeader."Customer No.";
                ServItemReferenceMgt.ValidateServiceReferenceNo(Rec, ServHeader, ItemReference, true, CurrFieldNo);
            end;
        }
        field(5726; "Item Reference Unit of Measure"; Code[10])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Reference Unit of Measure';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."));
        }
        field(5727; "Item Reference Type"; Enum "Item Reference Type")
        {
            Caption = 'Item Reference Type';
        }
        field(5728; "Item Reference Type No."; Code[30])
        {
            Caption = 'Item Reference Type No.';
        }
        field(5752; "Completely Shipped"; Boolean)
        {
            Caption = 'Completely Shipped';
            Editable = false;
        }
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';

            trigger OnValidate()
            begin
                TestStatusOpen();
                if ("Requested Delivery Date" <> xRec."Requested Delivery Date") and
                   ("Promised Delivery Date" <> 0D)
                then
                    Error(
                      Text046,
                      FieldCaption("Requested Delivery Date"),
                      FieldCaption("Promised Delivery Date"));

                if "Requested Delivery Date" <> 0D then
                    Validate("Planned Delivery Date", "Requested Delivery Date")
            end;
        }
        field(5791; "Promised Delivery Date"; Date)
        {
            Caption = 'Promised Delivery Date';

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Promised Delivery Date" <> 0D then
                    Validate("Planned Delivery Date", "Promised Delivery Date")
                else
                    Validate("Requested Delivery Date");
            end;
        }
        field(5792; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Time';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(5794; "Planned Delivery Date"; Date)
        {
            Caption = 'Planned Delivery Date';

            trigger OnValidate()
            begin
                Validate("Needed by Date", "Planned Delivery Date");
            end;
        }
        field(5796; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Shipping Agent Code" <> xRec."Shipping Agent Code" then
                    Validate("Shipping Agent Service Code", '');
            end;
        }
        field(5797; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));

            trigger OnValidate()
            var
                ShippingAgentServices: Record "Shipping Agent Services";
            begin
                TestStatusOpen();
                if "Shipping Agent Service Code" <> xRec."Shipping Agent Service Code" then
                    Clear("Shipping Time");

                if ShippingAgentServices.Get("Shipping Agent Code", "Shipping Agent Service Code") then
                    "Shipping Time" := ShippingAgentServices."Shipping Time"
                else begin
                    GetServHeader();
                    "Shipping Time" := ServHeader."Shipping Time";
                end;

                if ShippingAgentServices."Shipping Time" <> xRec."Shipping Time" then
                    Validate("Shipping Time", "Shipping Time");
            end;
        }
        field(5811; "Appl.-from Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-from Item Entry';
            MinValue = 0;

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Appl.-from Item Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                if "Appl.-from Item Entry" <> 0 then begin
                    CheckApplFromItemLedgEntry(ItemLedgEntry);
                    Validate("Unit Cost (LCY)", CalcUnitCost(ItemLedgEntry));
                end;
            end;
        }
        field(5902; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            TableRelation = if ("Document Type" = filter(<> "Credit Memo")) "Service Item"."No." where(Blocked = filter(<> All))
            else
            if ("Document Type" = filter("Credit Memo")) "Service Item"."No.";

            trigger OnLookup()
            begin
                if "Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"] then begin
                    ServItem.Reset();
                    ServItem.SetCurrentKey("Customer No.");
                    ServItem.FilterGroup(2);
                    ServItem.SetRange("Customer No.", "Customer No.");
                    ServItem.FilterGroup(0);
                    OnLookupServiceItemNoOnAfterServItemSetFilters(Rec, ServHeader, ServItem);
                    if PAGE.RunModal(0, ServItem) = ACTION::LookupOK then
                        Validate("Service Item No.", ServItem."No.");
                end
                else begin
                    ServItemLine.Reset();
                    ServItemLine.SetCurrentKey("Document Type", "Document No.", "Service Item No.");
                    ServItemLine.FilterGroup(2);
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "Document No.");
                    ServItemLine.FilterGroup(0);
                    ServItemLine."Service Item No." := "Service Item No.";
                    if PAGE.RunModal(0, ServItemLine) = ACTION::LookupOK then
                        Validate("Service Item Line No.", ServItemLine."Line No.");
                end;

                if "Service Item No." <> xRec."Service Item No." then
                    Validate("No.");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateServiceItemNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestField("Quantity Shipped", 0);
                TestField("Shipment No.", '');
                if "Service Item No." <> '' then begin
                    if "Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"] then
                        exit;
                    ServItemLine.Reset();
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "Document No.");
                    ServItemLine.SetRange("Service Item No.", "Service Item No.");
                    ServItemLine.Find('-');
                    Validate("Service Item Line No.", ServItemLine."Line No.");
                end;

                if "Service Item No." <> xRec."Service Item No." then begin
                    if "Service Item No." = '' then
                        Validate("Service Item Line No.", 0);
                    Validate("No.");
                end;
            end;
        }
        field(5903; "Appl.-to Service Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-to Service Entry';
            Editable = false;
        }
        field(5904; "Service Item Line No."; Integer)
        {
            Caption = 'Service Item Line No.';
            TableRelation = "Service Item Line"."Line No." where("Document Type" = field("Document Type"),
                                                                  "Document No." = field("Document No."));

            trigger OnValidate()
            var
                ServOrderManagement: Codeunit ServOrderManagement;
            begin
                TestField("Quantity Shipped", 0);
                ErrorIfAlreadySelectedSI("Service Item Line No.");
                if ServItemLine.Get("Document Type", "Document No.", "Service Item Line No.") then begin
                    "Service Item No." := ServItemLine."Service Item No.";
                    "Service Item Serial No." := ServItemLine."Serial No.";
                    ServOrderManagement.CheckServiceItemBlockedForAll(ServItemLine);
                    "Fault Area Code" := ServItemLine."Fault Area Code";
                    "Symptom Code" := ServItemLine."Symptom Code";
                    "Fault Code" := ServItemLine."Fault Code";
                    "Resolution Code" := ServItemLine."Resolution Code";
                    "Service Price Group Code" := ServItemLine."Service Price Group Code";
                    "Serv. Price Adjmt. Gr. Code" := ServItemLine."Serv. Price Adjmt. Gr. Code";
                    OnValidateServiceItemLineNoOnBeforeValidateContractNo(Rec, ServItemLine);
                    if "No." <> '' then
                        Validate("Contract No.", ServItemLine."Contract No.");
                end else begin
                    "Service Item No." := '';
                    "Service Item Serial No." := '';
                end;
                CalcFields("Service Item Line Description");
            end;
        }
        field(5905; "Service Item Serial No."; Code[50])
        {
            Caption = 'Service Item Serial No.';

            trigger OnLookup()
            begin
                ServItemLine.Reset();
                ServItemLine.SetRange("Document Type", "Document Type");
                ServItemLine.SetRange("Document No.", "Document No.");
                ServItemLine."Serial No." := "Service Item Serial No.";
                if PAGE.RunModal(0, ServItemLine) = ACTION::LookupOK then
                    Validate("Service Item Line No.", ServItemLine."Line No.");
            end;

            trigger OnValidate()
            begin
                if "Service Item Serial No." <> '' then begin
                    ServItemLine.Reset();
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "Document No.");
                    ServItemLine.SetRange("Serial No.", "Service Item Serial No.");
                    ServItemLine.Find('-');
                    Validate("Service Item Line No.", ServItemLine."Line No.");
                end;
            end;
        }
        field(5906; "Service Item Line Description"; Text[100])
        {
            CalcFormula = lookup("Service Item Line".Description where("Document Type" = field("Document Type"),
                                                                        "Document No." = field("Document No."),
                                                                        "Line No." = field("Service Item Line No.")));
            Caption = 'Service Item Line Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5907; "Serv. Price Adjmt. Gr. Code"; Code[10])
        {
            Caption = 'Serv. Price Adjmt. Gr. Code';
            Editable = false;
            TableRelation = "Service Price Adjustment Group";
        }
        field(5908; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5909; "Order Date"; Date)
        {
            Caption = 'Order Date';
            Editable = false;
        }
        field(5910; "Needed by Date"; Date)
        {
            Caption = 'Needed by Date';

            trigger OnValidate()
            begin
                TestStatusOpen();
                if CurrFieldNo = FieldNo("Needed by Date") then
                    if xRec."Needed by Date" <> 0D then
                        TestField("Needed by Date");
                if "Needed by Date" <> 0D then
                    CheckItemAvailable(FieldNo("Needed by Date"));
                if CurrFieldNo = FieldNo("Planned Delivery Date") then
                    UpdateReservation(CurrFieldNo)
                else
                    UpdateReservation(FieldNo("Needed by Date"));
                "Planned Delivery Date" := "Needed by Date";
            end;
        }
        field(5916; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            Editable = false;
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
        field(5917; "Qty. to Consume"; Decimal)
        {
            BlankZero = true;
            Caption = 'Qty. to Consume';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if CurrFieldNo = FieldNo("Qty. to Consume") then
                    CheckWarehouse();

                CheckQtyToConsumePositive();

                if "Qty. to Consume" = MaxQtyToConsume() then
                    InitQtyToConsume()
                else begin
                    "Qty. to Consume (Base)" := CalcBaseQty("Qty. to Consume", FieldCaption("Qty. to Consume"), FieldCaption("Qty. to Consume (Base)"));
                    ValidateQuantityConsumeIsBalanced();

                    InitQtyToInvoice();
                end;

                if "Qty. to Consume" > 0 then begin
                    "Qty. to Ship" := "Qty. to Consume";
                    "Qty. to Ship (Base)" := "Qty. to Consume (Base)";
                    ValidateQuantityShipIsBalanced();
                    "Qty. to Invoice" := 0;
                    "Qty. to Invoice (Base)" := 0;
                end;

                OnValidateQtyToConsumeOnBeforeQtyToConsumeCheck(Rec, xRec, CurrFieldNo, IsHandled);
                if not IsHandled then begin
                    if ("Qty. to Consume" * Quantity < 0) or
                       (Abs("Qty. to Consume") > Abs(MaxQtyToConsume()))
                    then
                        Error(
                          Text028,
                          MaxQtyToConsume());
                    if ("Qty. to Consume (Base)" * "Quantity (Base)" < 0) or
                       (Abs("Qty. to Consume (Base)") > Abs(MaxQtyToConsumeBase()))
                    then
                        Error(
                          Text032,
                          MaxQtyToConsumeBase());
                end;

                if (xRec."Qty. to Consume" <> "Qty. to Consume") or
                   (xRec."Qty. to Consume (Base)" <> "Qty. to Consume (Base)")
                then
                    Validate("Line Discount %");
            end;
        }
        field(5918; "Quantity Consumed"; Decimal)
        {
            Caption = 'Quantity Consumed';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5919; "Qty. to Consume (Base)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Qty. to Consume (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyToConsumeBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if LineRequiresShipmentOrReceipt() then
                    exit;
                if "Qty. to Consume (Base)" < 0 then
                    FieldError("Qty. to Consume (Base)", Text029);

                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Invoice", "Qty. to Invoice (Base)");
            end;
        }
        field(5920; "Qty. Consumed (Base)"; Decimal)
        {
            Caption = 'Qty. Consumed (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5928; "Service Price Group Code"; Code[10])
        {
            Caption = 'Service Price Group Code';
            TableRelation = "Service Price Group";
        }
        field(5929; "Fault Area Code"; Code[10])
        {
            Caption = 'Fault Area Code';
            TableRelation = "Fault Area";

            trigger OnValidate()
            begin
                if "Fault Area Code" <> xRec."Fault Area Code" then
                    "Fault Code" := '';
            end;
        }
        field(5930; "Symptom Code"; Code[10])
        {
            Caption = 'Symptom Code';
            TableRelation = "Symptom Code";

            trigger OnValidate()
            begin
                if "Symptom Code" <> xRec."Symptom Code" then
                    "Fault Code" := '';
            end;
        }
        field(5931; "Fault Code"; Code[10])
        {
            Caption = 'Fault Code';
            TableRelation = "Fault Code".Code where("Fault Area Code" = field("Fault Area Code"),
                                                     "Symptom Code" = field("Symptom Code"));
        }
        field(5932; "Resolution Code"; Code[10])
        {
            Caption = 'Resolution Code';
            TableRelation = "Resolution Code";
        }
        field(5933; "Exclude Warranty"; Boolean)
        {
            Caption = 'Exclude Warranty';
            Editable = true;

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateExcludeWarranty(Rec, xRec, HideWarrantyWarning, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if not (Type in [Type::Item, Type::Resource]) then
                    if CurrFieldNo = FieldNo("Exclude Warranty") then
                        FieldError(Type)
                    else
                        exit;

                if CurrFieldNo = FieldNo("Exclude Warranty") then begin
                    ServItemLine.Get("Document Type", "Document No.", "Service Item Line No.");
                    ServItemLine.TestField(Warranty, true);
                    if "Exclude Warranty" and (not Warranty) then
                        FieldError(Warranty);
                end;
                if HideWarrantyWarning = false then
                    if "Fault Reason Code" <> '' then begin
                        FaultReasonCode.Get("Fault Reason Code");
                        if FaultReasonCode."Exclude Warranty Discount" and
                           not "Exclude Warranty"
                        then
                            Error(
                              Text008,
                              FieldCaption("Exclude Warranty"),
                              FaultReasonCode.FieldCaption("Exclude Warranty Discount"),
                              "Fault Reason Code",
                              FaultReasonCode.TableCaption());
                    end;
                if HideWarrantyWarning = false then
                    if "Exclude Warranty" <> xRec."Exclude Warranty" then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(Text009, FieldCaption("Exclude Warranty")), true)
                        then begin
                            "Exclude Warranty" := xRec."Exclude Warranty";
                            exit;
                        end;
                Validate("Contract No.");
                if "Exclude Warranty" then
                    Validate(Warranty, false)
                else
                    Validate(Warranty, true);
            end;
        }
        field(5934; Warranty; Boolean)
        {
            Caption = 'Warranty';
            Editable = false;

            trigger OnValidate()
            begin
                UpdateDiscountsAmounts();
                UpdateUnitPrice(FieldNo(Warranty));
            end;
        }
        field(5936; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = "Service Contract Header"."Contract No." where("Contract Type" = const(Contract));

            trigger OnLookup()
            var
                ServContractHeader: Record "Service Contract Header";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupContractNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                GetServHeader();
                ServContractHeader.FilterGroup(2);
                ServContractHeader.SetRange("Customer No.", ServHeader."Customer No.");
                ServContractHeader.SetRange("Contract Type", ServContractHeader."Contract Type"::Contract);
                ServContractHeader.FilterGroup(0);
                if (PAGE.RunModal(0, ServContractHeader) = ACTION::LookupOK) and
                   ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"])
                then
                    Validate("Contract No.", ServContractHeader."Contract No.");
            end;

            trigger OnValidate()
            var
                Res: Record Resource;
                ServCost: Record "Service Cost";
                ContractGroup: Record "Contract Group";
                ContractServDisc: Record "Contract/Service Discount";
                ServContractHeader: Record "Service Contract Header";
                IsHandled: Boolean;
            begin
                if "Shipment Line No." <> 0 then
                    if "Shipment No." <> '' then
                        FieldError("Contract No.");

                if "Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"] then begin
                    if "Contract No." <> xRec."Contract No." then begin
                        TestField("Appl.-to Service Entry", 0);
                        UpdateServDocRegister(false);
                    end;
                end else begin
                    ServMgtSetup.Get();
                    if not ServItem.Get("Service Item No.") then
                        Clear(ServItem);
                    if "Contract No." = '' then
                        "Contract Disc. %" := 0
                    else begin
                        GetServHeader();
                        if ServContractHeader.Get(ServContractHeader."Contract Type"::Contract, "Contract No.") then begin
                            if (ServContractHeader."Starting Date" <= WorkDate()) and not "Exclude Contract Discount" then begin
                                if not ContractGroup.Get(ServContractHeader."Contract Group Code") then
                                    ContractGroup.Init();
                                if not ContractGroup."Disc. on Contr. Orders Only" or
                                   (ContractGroup."Disc. on Contr. Orders Only" and (ServHeader."Contract No." <> ''))
                                then
                                    case Type of
                                        Type::" ":
                                            "Contract Disc. %" := 0;
                                        Type::Item:
                                            begin
                                                ContractServDisc.Init();
                                                ContractServDisc."Contract Type" := ContractServDisc."Contract Type"::Contract;
                                                ContractServDisc."Contract No." := ServContractHeader."Contract No.";
                                                ContractServDisc.Type := ContractServDisc.Type::"Service Item Group";
                                                ContractServDisc."No." := ServItem."Service Item Group Code";
                                                ContractServDisc."Starting Date" := "Posting Date";
                                                OnValidateContractNoOnBeforeContractDiscountFind(Rec, ContractServDisc, ServItem);
                                                CODEUNIT.Run(CODEUNIT::"ContractDiscount-Find", ContractServDisc);
                                                "Contract Disc. %" := ContractServDisc."Discount %";
                                            end;
                                        Type::Resource:
                                            begin
                                                Res.Get("No.");
                                                ContractServDisc.Init();
                                                ContractServDisc."Contract Type" := ContractServDisc."Contract Type"::Contract;
                                                ContractServDisc."Contract No." := ServContractHeader."Contract No.";
                                                ContractServDisc.Type := ContractServDisc.Type::"Resource Group";
                                                ContractServDisc."No." := Res."Resource Group No.";
                                                ContractServDisc."Starting Date" := "Posting Date";
                                                OnValidateContractNoOnBeforeContractDiscountFind(Rec, ContractServDisc, ServItem);
                                                CODEUNIT.Run(CODEUNIT::"ContractDiscount-Find", ContractServDisc);
                                                "Contract Disc. %" := ContractServDisc."Discount %";
                                            end;
                                        Type::Cost:
                                            begin
                                                ServCost.Get("No.");
                                                ContractServDisc.Init();
                                                ContractServDisc."Contract Type" := ContractServDisc."Contract Type"::Contract;
                                                ContractServDisc."Contract No." := ServContractHeader."Contract No.";
                                                ContractServDisc.Type := ContractServDisc.Type::Cost;
                                                ContractServDisc."No." := "No.";
                                                ContractServDisc."Starting Date" := "Posting Date";
                                                OnValidateContractNoOnBeforeContractDiscountFind(Rec, ContractServDisc, ServItem);
                                                CODEUNIT.Run(CODEUNIT::"ContractDiscount-Find", ContractServDisc);
                                                "Contract Disc. %" := ContractServDisc."Discount %";
                                            end;
                                    end
                                else
                                    "Contract Disc. %" := 0;
                            end;
                        end else
                            "Contract Disc. %" := 0;
                    end;

                    IsHandled := false;
                    OnValidateContractNoOnBeforeAssignWarrantyDisc(Rec, IsHandled);
                    if not IsHandled then
                        if Warranty then
                            case Type of
                                Type::Item:
                                    "Warranty Disc. %" := ServItem."Warranty % (Parts)";
                                Type::Resource:
                                    "Warranty Disc. %" := ServItem."Warranty % (Labor)";
                                else
                                    "Warranty Disc. %" := 0;
                            end;

                    UpdateDiscountsAmounts();
                end;
            end;
        }
        field(5938; "Contract Disc. %"; Decimal)
        {
            Caption = 'Contract Disc. %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                UpdateAmounts();
            end;
        }
        field(5939; "Warranty Disc. %"; Decimal)
        {
            Caption = 'Warranty Disc. %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if Warranty <> xRec.Warranty then
                    PlanPriceCalcByField(FieldNo(Warranty));
                UpdateUnitPriceByField(FieldNo(Warranty), false);
                UpdateAmounts();
            end;
        }
        field(5965; "Component Line No."; Integer)
        {
            Caption = 'Component Line No.';
        }
        field(5966; "Spare Part Action"; Option)
        {
            Caption = 'Spare Part Action';
            OptionCaption = ' ,Permanent,Temporary,Component Replaced,Component Installed';
            OptionMembers = " ",Permanent,"Temporary","Component Replaced","Component Installed";
        }
        field(5967; "Fault Reason Code"; Code[10])
        {
            Caption = 'Fault Reason Code';
            TableRelation = "Fault Reason Code";

            trigger OnValidate()
            var
                NewWarranty: Boolean;
                OldExcludeContractDiscount: Boolean;
                IsHandled: Boolean;
            begin
                SetHideWarrantyWarning := true;
                OldExcludeContractDiscount := "Exclude Contract Discount";
                if FaultReasonCode.Get("Fault Reason Code") then begin
                    IsHandled := false;
                    OnValidateFaultReasonCodeOnBeforeExcludeWarrantyDiscountCheck(Rec, xRec, IsHandled);
                    if not IsHandled then
                        if FaultReasonCode."Exclude Warranty Discount" and
                           (not (Type in [Type::Item, Type::Resource]))
                        then
                            Error(
                              Text027,
                              FieldCaption("Fault Reason Code"),
                              FaultReasonCode.Code,
                              FaultReasonCode.FieldCaption("Exclude Warranty Discount"));
                    "Exclude Contract Discount" := FaultReasonCode."Exclude Contract Discount";
                    NewWarranty := (not FaultReasonCode."Exclude Warranty Discount") and
                      ("Exclude Warranty" or Warranty);
                    Validate("Exclude Warranty",
                      FaultReasonCode."Exclude Warranty Discount" and
                      ("Exclude Warranty" or Warranty));
                    Validate(Warranty, NewWarranty);
                    if OldExcludeContractDiscount and (not "Exclude Contract Discount") then
                        Validate("Contract No.");
                end else begin
                    "Exclude Contract Discount" := false;
                    if "Exclude Warranty" then begin
                        Validate("Exclude Warranty", false);
                        Validate(Warranty, true);
                    end else
                        if OldExcludeContractDiscount <> "Exclude Contract Discount" then
                            if OldExcludeContractDiscount and (not "Exclude Contract Discount") then
                                Validate("Contract No.")
                            else
                                Validate(Warranty);
                end;
            end;
        }
        field(5968; "Replaced Item No."; Code[20])
        {
            Caption = 'Replaced Item No.';
            TableRelation = if ("Replaced Item Type" = const(Item)) Item
            else
            if ("Replaced Item Type" = const("Service Item")) "Service Item";
        }
        field(5969; "Exclude Contract Discount"; Boolean)
        {
            Caption = 'Exclude Contract Discount';
            Editable = true;

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if Type = Type::"G/L Account" then
                    FieldError(Type);

                if "Fault Reason Code" <> '' then begin
                    FaultReasonCode.Get("Fault Reason Code");
                    if FaultReasonCode."Exclude Contract Discount" and
                       not "Exclude Contract Discount"
                    then
                        Error(
                          Text008,
                          FieldCaption("Exclude Contract Discount"),
                          FaultReasonCode.FieldCaption("Exclude Contract Discount"),
                          "Fault Reason Code",
                          FaultReasonCode.TableCaption());
                end;

                if "Exclude Contract Discount" <> xRec."Exclude Contract Discount" then begin
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(Text009, FieldCaption("Exclude Contract Discount")), true)
                    then begin
                        "Exclude Contract Discount" := xRec."Exclude Contract Discount";
                        exit;
                    end;
                    Validate("Contract No.");
                    Validate(Warranty);
                end;
            end;
        }
        field(5970; "Replaced Item Type"; Enum "Replaced Service Item Component Type")
        {
            Caption = 'Replaced Item Type';
        }
        field(5994; "Price Adjmt. Status"; Option)
        {
            Caption = 'Price Adjmt. Status';
            Editable = false;
            OptionCaption = ' ,Adjusted,Modified';
            OptionMembers = " ",Adjusted,Modified;
        }
        field(5997; "Line Discount Type"; Enum "Service Line Discount Type")
        {
            Caption = 'Line Discount Type';
            Editable = false;
        }
        field(5999; "Copy Components From"; Option)
        {
            Caption = 'Copy Components From';
            OptionCaption = 'None,Item BOM,Old Service Item,Old Serv.Item w/o Serial No.';
            OptionMembers = "None","Item BOM","Old Service Item","Old Serv.Item w/o Serial No.";
        }
        field(6608; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";

            trigger OnValidate()
            var
                ReturnReason: Record "Return Reason";
                ShouldValidateLocationCode: Boolean;
            begin
                if "Return Reason Code" = '' then
                    PlanPriceCalcByField(FieldNo("Return Reason Code"));

                if ReturnReason.Get("Return Reason Code") then begin
                    ShouldValidateLocationCode := ((ReturnReason."Default Location Code" <> '') and (not IsNonInventoriableItem()));
                    OnValidateReturnReasonCodeOnBeforeValidateLocationCode(Rec, ReturnReason, ShouldValidateLocationCode);
                    if ShouldValidateLocationCode then
                        Validate("Location Code", ReturnReason."Default Location Code");
                    if ReturnReason."Inventory Value Zero" then begin
                        Validate("Unit Cost (LCY)", 0);
                        Validate("Unit Price", 0);
                    end else
                        if "Unit Price" = 0 then
                            PlanPriceCalcByField(FieldNo("Return Reason Code"));
                end;
                UpdateUnitPriceByField(FieldNo("Return Reason Code"), false);
            end;
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            InitValue = true;
        }
        field(7002; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";

            trigger OnValidate()
            begin
                if Type = Type::Item then begin
                    if "Customer Disc. Group" <> xRec."Customer Disc. Group" then
                        PlanPriceCalcByField(FieldNo("Customer Disc. Group"));
                    UpdateUnitPriceByField(FieldNo("Customer Disc. Group"), false);
                end;
            end;
        }
        field(7300; "Qty. Picked"; Decimal)
        {
            Caption = 'Qty. Picked';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Picked (Base)" := CalcBaseQty("Qty. Picked", FieldCaption("Qty. Picked"), FieldCaption("Qty. Picked (Base)"));
                "Completely Picked" := "Qty. Picked" >= 0;
            end;
        }
        field(7301; "Qty. Picked (Base)"; Decimal)
        {
            Caption = 'Qty. Picked (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(7302; "Completely Picked"; Boolean)
        {
            Caption = 'Completely Picked';
            Editable = false;
        }
        field(7303; "Pick Qty. (Base)"; Decimal)
        {
            Caption = 'Pick Qty. (Base)';
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
        key(Key2; Type, "No.", "Order Date")
        {
        }
        key(Key3; "Service Item No.", Type, "Posting Date")
        {
        }
        key(Key4; "Document Type", "Bill-to Customer No.", "Currency Code", "Document No.")
        {
            IncludedFields = "Outstanding Amount", "Shipped Not Invoiced", "Outstanding Amount (LCY)", "Shipped Not Invoiced (LCY)";
        }
        key(Key5; "Document Type", "Document No.", "Service Item No.")
        {
        }
        key(Key6; "Document Type", "Document No.", "Service Item Line No.", "Serv. Price Adjmt. Gr. Code")
        {
            IncludedFields = "Line Amount";
        }
        key(Key7; "Document Type", "Document No.", "Service Item Line No.", Type, "No.")
        {
        }
        key(Key8; Type, "No.", "Variant Code", "Location Code", "Needed by Date", "Document Type", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code")
        {
            IncludedFields = "Quantity (Base)", "Outstanding Qty. (Base)";
        }
        key(Key9; "Appl.-to Service Entry")
        {
        }
        key(Key10; "Document Type", "Document No.", "Service Item Line No.", "Component Line No.")
        {
        }
        key(Key11; "Fault Reason Code")
        {
        }
        key(Key12; "Document Type", "Customer No.", "Shipment No.", "Document No.")
        {
            IncludedFields = "Outstanding Amount (LCY)";
        }
        key(Key13; "Document Type", "Document No.", "Location Code")
        {
        }
        key(Key14; "Document Type", "Document No.", Type, "No.")
        {
        }
        key(Key15; "Document No.", "Document Type")
        {
            IncludedFields = Amount, "Amount Including VAT", "Outstanding Amount", "Shipped Not Invoiced", "Outstanding Amount (LCY)", "Shipped Not Invoiced (LCY)", "Line Amount";
        }
        key(Key16; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Type, "No.", Description, Quantity, "Unit of Measure Code", "Line Amount")
        {
        }
        fieldgroup(Brick; "No.", Description, "Line Amount", Quantity, "Unit of Measure Code")
        { }
    }

    trigger OnDelete()
    var
        Item: Record Item;
        ServiceLine2: Record "Service Line";
        IsHandled: Boolean;
        CheckServiceDocumentType: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;

        TestStatusOpen();
        if Type = Type::Item then
            ServiceWarehouseMgt.ServiceLineDelete(Rec);
        if Type in [Type::"G/L Account", Type::Cost, Type::Resource] then
            TestField("Qty. Shipped Not Invoiced", 0);


        CheckServiceDocumentType := ("Document Type" = "Document Type"::Invoice) and ("Appl.-to Service Entry" > 0);
        OnDeleteOnBeforeServiceEntriesError(Rec, CheckServiceDocumentType);
        if CheckServiceDocumentType then
            Error(Text045);

        if (Rec.Quantity <> 0) and Rec.ItemExists(Rec."No.") then begin
            ServiceLineReserve.DeleteLine(Rec);
            CalcFields("Reserved Qty. (Base)");
            TestField("Reserved Qty. (Base)", 0);
            if "Shipment No." = '' then
                TestField("Qty. Shipped Not Invoiced", 0);
        end;

        ServiceLineReserve.DeleteLine(Rec);

        IsHandled := false;
        OnDeleteOnDelNonStockFSMBeforeModify(Rec, IsHandled);
        if not IsHandled then
            if (Type = Type::Item) and Item.Get("No.") then
                ServCatalogItemMgt.DelNonStockFSM(Rec);

        if (Type <> Type::" ") and
           (("Contract No." <> '') or
            ("Shipment No." <> ''))
        then
            UpdateServDocRegister(true);

        if "Line No." <> 0 then begin
            ServiceLine2.Reset();
            ServiceLine2.SetRange("Document Type", "Document Type");
            ServiceLine2.SetRange("Document No.", "Document No.");
            ServiceLine2.SetRange("Attached to Line No.", "Line No.");
            ServiceLine2.SetFilter("Line No.", '<>%1', "Line No.");
            OnDeleteOnAfterServiceLineSetFilter(ServiceLine2, Rec);
            ServiceLine2.DeleteAll(true);
        end;

        OnAfterOnDelete(Rec);
    end;

    trigger OnInsert()
    begin
        if TempTrackingSpecification.FindFirst() then
            InsertItemTracking();

        if Quantity <> 0 then
            ServiceLineReserve.VerifyQuantity(Rec, xRec);

        if Type = Type::Item then begin
            OnInsertOnBeforeDisplayConflictError(Rec);
            if ServHeader.WhsePickConflict("Document Type", "Document No.", ServHeader."Shipping Advice") then
                DisplayConflictError(ServHeader.InvPickConflictResolutionTxt());
            OnInsertOnAfterDisplayConflictError(Rec);
        end;

        IsCustCrLimitChecked := false;
    end;

    trigger OnModify()
    begin
        if "Document Type" = ServiceLine."Document Type"::Invoice then
            CheckIfCanBeModified();

        if "Spare Part Action" in
           ["Spare Part Action"::"Component Replaced",
            "Spare Part Action"::"Component Installed",
            "Spare Part Action"::" "]
        then begin
            if (Type <> xRec.Type) or ("No." <> xRec."No.") then
                ServiceLineReserve.DeleteLine(Rec);
            UpdateReservation(0);
        end;

        UpdateServiceLedgerEntry();
        OnModifyOnAfterUpdateServiceLedgerEntry(Rec, xRec);

        IsCustCrLimitChecked := false;
    end;

    trigger OnRename()
    begin
        Error(Text002, TableCaption);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot invoice more than %1 units.';
        Text001: Label 'You cannot invoice more than %1 base units.';
        Text002: Label 'You cannot rename a %1.';
        Text003: Label 'must not be less than %1';
        Text004: Label 'You must confirm %1 %2, because %3 is not equal to %4 in %5 %6.';
#pragma warning restore AA0470
        Text005: Label 'The update has been interrupted to respect the warning.';
        Text006: Label 'Replace Component,New Component,Ignore';
#pragma warning disable AA0470
        Text007: Label 'You must select a %1.';
        Text008: Label 'You cannot change the value of the %1 field because the %2 field in the Fault Reason Codes window contains a check mark for the %3 %4.';
        Text009: Label 'You have changed the value of the field %1.\Do you want to continue ?';
        Text010: Label '%1 cannot be less than %2.';
        Text011: Label 'When replacing a %1 the quantity must be 1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ManualReserveQst: Label 'Automatic reservation is not possible.\Do you want to reserve items manually?';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text013: Label ' must be 0 when %1 is %2.';
        Text015: Label 'You have already selected %1 %2 for replacement.';
        Text016: Label 'You cannot ship more than %1 units.';
        Text017: Label 'You cannot ship more than %1 base units.';
        Text018: Label '%1 %2 is greater than %3 and was adjusted to %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CompAlreadyReplacedErr: Label 'The component that you selected has already been replaced in service line %1.', Comment = '%1 = Line No.';
        SalesSetup: Record "Sales & Receivables Setup";
        ServMgtSetup: Record "Service Mgt. Setup";
        ServiceLine: Record "Service Line";
        ServItem: Record "Service Item";
        ServItemLine: Record "Service Item Line";
        Resource: Record Resource;
        Location: Record Location;
        FaultReasonCode: Record "Fault Reason Code";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        SKU: Record "Stockkeeping Unit";
        DimMgt: Codeunit DimensionManagement;
        ServDimMgt: Codeunit "Serv. Dimension Management";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        UOMMgt: Codeunit "Unit of Measure Management";
        ServCatalogItemMgt: Codeunit "Serv. Catalog Item Mgt.";
        ServItemReferenceMgt: Codeunit "Serv. Item Reference Mgt.";
        ServiceLineReserve: Codeunit "Service Line-Reserve";
        ServiceWarehouseMgt: Codeunit "Service Warehouse Mgt.";
        FieldCausedPriceCalculation: Integer;
        Select: Integer;
        CalledFromServiceItemLine: Boolean;
        FullAutoReservation: Boolean;
        HideReplacementDialog: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text022: Label 'The %1 cannot be greater than the %2 set on the %3.';
#pragma warning restore AA0470
        Text023: Label 'You must enter a serial number.';
#pragma warning restore AA0074
        ReplaceServItemAction: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text026: Label 'When replacing or creating a service item component you may only enter a whole number into the %1 field.';
        Text027: Label 'The %1 %2 with a check mark in the %3 field cannot be entered if the service line type is other than Item or Resource.';
        Text028: Label 'You cannot consume more than %1 units.';
#pragma warning restore AA0470
        Text029: Label 'must be positive';
        Text030: Label 'must be negative';
#pragma warning disable AA0470
        Text031: Label 'You must specify %1.';
        Text032: Label 'You cannot consume more than %1 base units.';
#pragma warning restore AA0470
        Text033: Label 'The line you are trying to change has the adjusted price.\';
        Text034: Label 'Do you want to continue?';
        Text035: Label 'Warehouse';
        Text036: Label 'Inventory';
#pragma warning disable AA0470
        Text037: Label 'You cannot change %1 when %2 is %3 and %4 is positive.';
        Text038: Label 'You cannot change %1 when %2 is %3 and %4 is negative.';
        Text039: Label 'You cannot return more than %1 units for %2 %3.';
#pragma warning restore AA0470
        Text041: Label 'There were no Resource Lines to split.';
#pragma warning disable AA0470
        Text042: Label 'When posting the Applied to Ledger Entry %1 will be opened first';
#pragma warning restore AA0470
#pragma warning restore AA0074
        HideCostWarning: Boolean;
        HideWarrantyWarning: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text043: Label 'You cannot change the value of the %1 field manually if %2 for this line is %3.';
#pragma warning restore AA0470
        Text044: Label 'Do you want to split the resource line and use it to create resource lines\for the other service items with divided amounts?';
        Text045: Label 'You cannot delete this service line because one or more service entries exist for this line.';
#pragma warning disable AA0470
        Text046: Label 'You cannot change the %1 when the %2 has been filled in.';
        Text047: Label '%1 can only be set when %2 is set.';
        Text048: Label '%1 cannot be changed when %2 is set.';
        Text049: Label '%1 is required for %2 = %3.', Comment = 'Example: Inventory put-away is required for Line 50000.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        WhseRequirementMsg: Label '%1 is required for this line. The entered information may be disregarded by warehouse activities.', Comment = '%1=Document';
        StatusCheckSuspended: Boolean;
#pragma warning disable AA0074
        Text051: Label 'You cannot add an item line.';
#pragma warning disable AA0470
        Text052: Label 'You cannot change the %1 field because one or more service entries exist for this line.';
#pragma warning restore AA0470
        Text053: Label 'You cannot modify the service line because one or more service entries exist for this line.';
#pragma warning restore AA0074
        IsCustCrLimitChecked: Boolean;
        LocationChangedMsg: Label 'Item %1 with serial number %2 is stored on location %3. The Location Code field on the service line will be updated.', Comment = '%1 = Item No., %2 = Item serial No., %3 = Location code';
        LineDiscountPctErr: Label 'The value in the Line Discount % field must be between 0 and 100.';
        BlockedItemNotificationMsg: Label 'Item %1 is blocked, but it is allowed on this type of document.', Comment = '%1 is Item No.';
        BlockedItemVariantNotificationMsg: Label 'Item Variant %1 for Item %2 is blocked, but it is allowed on this type of document.', Comment = '%1 - Item Variant Code, %2 - Item No.';

    protected var
        ServHeader: Record "Service Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;

    procedure CheckItemAvailable(CalledByFieldNo: Integer)
    var
        ServItemCheckAvail: Codeunit "Serv. Item Check Avail.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemAvailable(Rec, xRec, CalledByFieldNo, IsHandled, CurrFieldNo);
        if not IsHandled then begin

            ValidateNeededByDate();

            if CurrFieldNo <> CalledByFieldNo then
                exit;
            if not GuiAllowed then
                exit;
            if (Type <> Type::Item) or ("No." = '') then
                exit;
            if Quantity <= 0 then
                exit;

            IsHandled := false;
            OnCheckItemAvailableOnBeforeCheckNonStock(Rec, CalledByFieldNo, IsHandled);
            if IsHandled then
                exit;

            if Nonstock then
                exit;
            if not ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) then
                exit;

            if ServItemCheckAvail.ServiceInvLineCheck(Rec) then
                ServItemCheckAvail.RaiseUpdateInterruptedError();
        end;

        OnAfterCheckItemAvailable(Rec, CalledByFieldNo);
    end;

    local procedure ValidateNeededByDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateNeededByDate(ServHeader, Rec, IsHandled);
        if IsHandled then
            exit;

        if "Needed by Date" = 0D then begin
            GetServHeader();
            if ServHeader."Order Date" <> 0D then
                Validate("Needed by Date", ServHeader."Order Date")
            else
                Validate("Needed by Date", WorkDate());
        end;

    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        DimensionSetID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();
        GetServHeader();
        if not ServItemLine.Get(ServHeader."Document Type", ServHeader."No.", "Service Item Line No.") then
            ServItemLine.Init();

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        DimensionSetID := ServItemLine."Dimension Set ID";
        if DimensionSetID = 0 then
            DimensionSetID := ServHeader."Dimension Set ID";
        UpdateDimSetupFromDimSetID(DefaultDimSource, DimensionSetID);
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup."Service Management",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", DimensionSetID, DATABASE::Customer);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterCreateDim(Rec, CurrFieldNo);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        Rec.ValidateShortcutDimCode(FieldNumber, ShortcutDimCode);
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    protected procedure ReplaceServItem(): Boolean
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServOrderManagement: Codeunit ServOrderManagement;
        ServItemReplacement: Page "Service Item Replacement";
        SerialNo: Code[50];
        VariantCode: Code[10];
        LocationCode: Code[10];
        IsHandled: Boolean;
    begin
        ErrorIfAlreadySelectedSI("Service Item Line No.");
        Clear(ServItemReplacement);
        ServItemReplacement.SetValues("Service Item No.", "No.", "Variant Code");
        Commit();
        if ServItemReplacement.RunModal() = ACTION::OK then begin
            SerialNo := ServItemReplacement.ReturnSerialNo();
            VariantCode := ServItemReplacement.ReturnVariantCode();
            if not ServOrderManagement.IsCreditDocumentType("Document Type") then begin
                ItemVariant.SetLoadFields("Service Blocked");
                if ItemVariant.Get("No.", "Variant Code") then
                    ItemVariant.TestField("Service Blocked", false);
            end;

            GetItem(Item);
            if SerialNo = '' then
                CheckItemTrackingCode(Item)
            else
                if FindSerialNoStorageLocation(LocationCode, Item."No.", SerialNo, VariantCode) and (LocationCode <> "Location Code") then begin
                    Validate("Location Code", LocationCode);
                    Message(StrSubstNo(LocationChangedMsg, Item."No.", SerialNo, LocationCode));
                end;

            "Variant Code" := VariantCode;
            IsHandled := false;
            OnReplaceServItemOnAfterAssignVariantCode(Rec, ServItemReplacement, SerialNo, IsHandled);
            if not IsHandled then begin
                Validate(Quantity, 1);
                TempTrackingSpecification.DeleteAll();
                TempTrackingSpecification."Serial No." := SerialNo;
                TempTrackingSpecification."Variant Code" := VariantCode;
                TempTrackingSpecification.Insert();
                if "Line No." <> 0 then
                    InsertItemTracking();
                case ServItemReplacement.ReturnReplacement() of
                    0:
                        "Spare Part Action" := "Spare Part Action"::"Temporary";
                    1:
                        "Spare Part Action" := "Spare Part Action"::Permanent;
                end;
            end;
            "Copy Components From" := ServItemReplacement.ReturnCopyComponentsFrom();
            OnReplaceServItemOnCopyFromReplacementItem(Rec);
            exit(true);
        end;
        ServiceLineReserve.DeleteLine(Rec);
        ClearFields();
        Validate("No.", '');
        exit(false);
    end;

    local procedure FindSerialNoStorageLocation(var LocationCode: Code[10]; ItemNo: Code[20]; SerialNo: Code[50]; VariantCode: Code[10]): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Serial No.", SerialNo);
        ItemLedgerEntry.SetRange("Variant Code", VariantCode);
        ItemLedgerEntry.SetRange(Open, true);
        if not ItemLedgerEntry.FindLast() then
            exit(false);

        LocationCode := ItemLedgerEntry."Location Code";
        exit(true);
    end;

    local procedure CheckItemTrackingCode(ReplacementItem: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if ReplacementItem."Item Tracking Code" = '' then
            exit;

        ItemTrackingCode.Get(ReplacementItem."Item Tracking Code");
        if ItemTrackingCode."SN Specific Tracking" then
            Error(Text023);
    end;

    local procedure CheckVATCalculationType(VATPostingSetup: Record "VAT Posting Setup")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckVATCalculationType(Rec, VATPostingSetup, IsHandled);
        if IsHandled then
            exit;

        case "VAT Calculation Type" of
            "VAT Calculation Type"::"Reverse Charge VAT",
            "VAT Calculation Type"::"Sales Tax":
                ClearVATPct();
            "VAT Calculation Type"::"Full VAT":
                TestField(Type, Type::Cost);
        end;
    end;

    local procedure CheckQtyToInvoicePositive()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQtyToInvoicePositive(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if "Qty. to Invoice" < 0 then
            FieldError("Qty. to Invoice", Text029);
    end;

    local procedure CheckQtyToShipPositive()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQtyToShipPositive(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if "Qty. to Ship" < 0 then
            FieldError("Qty. to Ship", Text029);
    end;

    local procedure CheckQtyToConsumePositive()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQtyToConsumePositive(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if "Qty. to Consume" < 0 then
            FieldError("Qty. to Consume", Text029);
    end;

    local procedure TestQuantityPositive()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestQuantityPositive(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if Quantity < 0 then
            FieldError(Quantity, Text029);
    end;

    local procedure TestQtyFromLineAmount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestQtyFromLineAmount(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        TestField(Quantity);
    end;

    local procedure ErrorIfAlreadySelectedSI(ServItemLineNo: Integer)
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        if "Document Type" <> "Document Type"::Order then
            exit;
        if ServItemLineNo <> 0 then begin
            ServItemLine.Get("Document Type", "Document No.", ServItemLineNo);
            if (ServItemLine."Service Item No." = '') or
               (ServItemLine."Item No." = '') or
               (ServItemLine."Item No." <> "No.")
            then
                exit;
        end;

        IsHandled := false;
        OnBeforeCheckErrorSelectedSI(Rec, ServItemLineNo, IsHandled);
        if IsHandled then
            exit;

        ServiceLine.Reset();
        ServiceLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.", Type, "No.");
        ServiceLine.SetRange("Document Type", "Document Type");
        ServiceLine.SetRange("Document No.", "Document No.");
        ServiceLine.SetRange("Service Item Line No.", ServItemLineNo);
        ServiceLine.SetRange(Type, Type::Item);
        ServiceLine.SetFilter("Line No.", '<>%1', "Line No.");
        ServiceLine.SetRange("No.", "No.");
        if ServiceLine.FindFirst() then
            Error(Text015, Item.TableCaption(), "No.");
    end;

    procedure CalculateDiscount()
    var
        Discounts: array[4] of Decimal;
        i: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateDiscount(Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if "Exclude Warranty" or not Warranty then
            Discounts[1] := 0
        else begin
            if GetServiceItemLine() then
                case Type of
                    Type::Item:
                        "Warranty Disc. %" := ServItemLine."Warranty % (Parts)";
                    Type::Resource:
                        "Warranty Disc. %" := ServItemLine."Warranty % (Labor)";
                end;
            Discounts[1] := "Warranty Disc. %";
        end;

        if "Exclude Contract Discount" then
            if ((CurrFieldNo = FieldNo("Fault Reason Code")) or CalledFromServiceItemLine) and (not "Exclude Warranty") then
                Discounts[2] := "Line Discount %"
            else
                Discounts[2] := 0
        else
            Discounts[2] := "Contract Disc. %";

        SetCalledFromServiceItemLine(false);

        ServHeader.Get(Rec."Document Type", Rec."Document No.");

        ApplyDiscount(ServHeader);
        Discounts[3] := "Line Discount %";
        if Discounts[3] > 100 then
            Discounts[3] := 100;

        "Line Discount Type" := "Line Discount Type"::" ";
        "Line Discount %" := 0;

        if "Line Discount Type" = "Line Discount Type"::Manual then
            Discounts[4] := "Line Discount %"
        else
            Discounts[4] := 0;

        for i := 1 to 4 do
            if Discounts[i] > "Line Discount %" then begin
                "Line Discount Type" := "Service Line Discount Type".FromInteger(i);
                "Line Discount %" := Discounts[i];
            end;

        OnAfterCalculateDiscount(Rec);
    end;

    local procedure GetLineWithCalculatedPrice(var PriceCalculation: Interface "Price Calculation")
    var
        Line: Variant;
    begin
        PriceCalculation.GetLine(Line);
        Rec := Line;
    end;

    procedure GetPriceCalculationHandler(PriceType: Enum "Price Type"; ServiceHeader: Record "Service Header"; var PriceCalculation: Interface "Price Calculation")
    var
        PriceCalculationMgt: codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        if (ServiceHeader."No." = '') and ("Document No." <> '') then
            ServiceHeader.Get(Rec."Document Type", Rec."Document No.");
        GetLineWithPrice(LineWithPrice);
        LineWithPrice.SetLine(PriceType, ServiceHeader, Rec);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
    end;

    procedure GetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    var
        ServiceLinePrice: Codeunit "Service Line - Price";
    begin
        LineWithPrice := ServiceLinePrice;
        OnAfterGetLineWithPrice(LineWithPrice);
    end;

    procedure ApplyDiscount(ServiceHeader: Record "Service Header")
    var
        PriceCalculation: Interface "Price Calculation";
        PriceType: Enum "Price Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApplyDiscount(ServiceHeader, Rec, IsHandled);
        if IsHandled then
            exit;
        GetPriceCalculationHandler(PriceType::Sale, ServiceHeader, PriceCalculation);
        PriceCalculation.ApplyDiscount();
        GetLineWithCalculatedPrice(PriceCalculation);
    end;

    procedure PickDiscount()
    var
        ServiceHeader: Record "Service Header";
        PriceCalculation: Interface "Price Calculation";
        PriceType: Enum "Price Type";
    begin
        GetPriceCalculationHandler(PriceType::Sale, ServiceHeader, PriceCalculation);
        PriceCalculation.PickDiscount();
        GetLineWithCalculatedPrice(PriceCalculation);

        OnAfterPickDiscount(Rec, PriceCalculation);
    end;

    procedure PickPrice()
    var
        ServiceHeader: Record "Service Header";
        PriceCalculation: Interface "Price Calculation";
        PriceType: Enum "Price Type";
    begin
        GetPriceCalculationHandler(PriceType::Sale, ServiceHeader, PriceCalculation);
        PriceCalculation.PickPrice();
        GetLineWithCalculatedPrice(PriceCalculation);

        OnAfterPickPrice(Rec, PriceCalculation);
    end;

    procedure CountDiscount(ShowAll: Boolean): Integer;
    var
        ServiceHeader: Record "Service Header";
        PriceCalculation: Interface "Price Calculation";
        PriceType: Enum "Price Type";
    begin
        GetPriceCalculationHandler(PriceType::Sale, ServiceHeader, PriceCalculation);
        exit(PriceCalculation.CountDiscount(ShowAll));
    end;

    procedure CountPrice(ShowAll: Boolean): Integer;
    var
        ServiceHeader: Record "Service Header";
        PriceCalculation: Interface "Price Calculation";
        PriceType: Enum "Price Type";
    begin
        GetPriceCalculationHandler(PriceType::Sale, ServiceHeader, PriceCalculation);
        exit(PriceCalculation.CountPrice(ShowAll));
    end;

    procedure DiscountExists(ShowAll: Boolean): Boolean;
    var
        ServiceHeader: Record "Service Header";
        PriceCalculation: Interface "Price Calculation";
        PriceType: Enum "Price Type";
    begin
        GetPriceCalculationHandler(PriceType::Sale, ServiceHeader, PriceCalculation);
        exit(PriceCalculation.IsDiscountExists(ShowAll));
    end;

    procedure PriceExists(ShowAll: Boolean): Boolean;
    var
        ServiceHeader: Record "Service Header";
        PriceCalculation: Interface "Price Calculation";
        PriceType: Enum "Price Type";
    begin
        GetPriceCalculationHandler(PriceType::Sale, ServiceHeader, PriceCalculation);
        exit(PriceCalculation.IsPriceExists(ShowAll));
    end;

    procedure UpdateAmounts()
    var
        ServCheckCreditLimit: Codeunit "Serv. Check Credit Limit";
        ExpectedLineAmount: Decimal;
        ShouldCheckCrLimit: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAmounts(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if GuiAllowed and (CurrFieldNo <> 0) then
            ConfirmAdjPriceLineChange();

        GetServHeader();

        if Rec."Line Amount" <> xRec."Line Amount" then
            "VAT Difference" := 0;
        ExpectedLineAmount :=
            Round(CalcChargeableQty() * "Unit Price", Currency."Amount Rounding Precision") - "Line Discount Amount";
        OnUpdateAmountsOnAfterCalcExpectedLineAmount(Rec, xRec, ExpectedLineAmount);
        if "Line Amount" <> ExpectedLineAmount then begin
            "Line Amount" := ExpectedLineAmount;
            ClearVATDifference();
        end;
        if ServHeader."Tax Area Code" = '' then
            UpdateVATAmounts();

        InitOutstandingAmount();
        ShouldCheckCrLimit := not IsCustCrLimitChecked and (CurrFieldNo <> 0);
        OnUpdateAmountsOnAfterCalcShouldCheckCrLimit(Rec, IsCustCrLimitChecked, CurrFieldNo, ShouldCheckCrLimit);
        if ShouldCheckCrLimit then begin
            IsCustCrLimitChecked := true;
            ServCheckCreditLimit.ServiceLineCheck(Rec);
        end;
        UpdateRemainingCostsAndAmounts();

        OnAfterUpdateAmounts(Rec);
    end;

    local procedure NotifyOnMissingSetup(FieldNumber: Integer)
    var
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
    begin
        if CurrFieldNo = 0 then
            exit;
        SalesSetup.Get();
        DiscountNotificationMgt.RecallNotification(SalesSetup.RecordId);
        if (FieldNumber = FieldNo("Line Discount Amount")) and ("Line Discount Amount" = 0) then
            exit;
        DiscountNotificationMgt.NotifyAboutMissingSetup(
          SalesSetup.RecordId, "Gen. Bus. Posting Group", "Gen. Prod. Posting Group",
          SalesSetup."Discount Posting", SalesSetup."Discount Posting"::"Invoice Discounts");
    end;

    procedure GetItem(var Item: Record Item)
    begin
        TestField("No.");
        Item.Get("No.");
    end;

    procedure GetDate(): Date
    begin
        if ServHeader."Document Type" = ServHeader."Document Type"::Quote then
            exit(WorkDate());

        exit(ServHeader."Posting Date");
    end;

    procedure GetServHeader(): Record "Service Header"
    begin
        GetServHeader(ServHeader, Currency);
        exit(ServHeader);
    end;

    procedure GetServHeader(var OutServiceHeader: Record "Service Header"; var OutCurrency: Record Currency)
    var
    begin
        TestField("Document No.");
        if ("Document Type" <> ServHeader."Document Type") or ("Document No." <> ServHeader."No.") then begin
            ServHeader.Get(Rec."Document Type", Rec."Document No.");
            if ServHeader."Currency Code" = '' then
                Currency.InitRoundingPrecision()
            else begin
                ServHeader.TestField("Currency Factor");
                Currency.Get(ServHeader."Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;
        end;

        OutServiceHeader := ServHeader;
        OutCurrency := Currency;
    end;

    local procedure GetServiceItemLine(): Boolean
    begin
        if ("Document Type" <> ServItemLine."Document Type") or
           ("Document No." <> ServItemLine."Document No.") or
           ("Service Item Line No." <> ServItemLine."Line No.")
        then
            exit(ServItemLine.Get("Document Type", "Document No.", "Service Item Line No."));

        exit(true);
    end;

    local procedure InitHeaderDefaults(ServHeader: Record "Service Header")
    var
        ServOrderMgt: Codeunit ServOrderManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitHeaderDefaults(Rec, ServHeader, IsHandled);
        if not IsHandled then begin
            "Customer No." := ServHeader."Customer No.";
            InitServHeaderShipToCode();
            if "Posting Date" = 0D then
                "Posting Date" := ServHeader."Posting Date";
            "Document Type" := ServHeader."Document Type";

            "Order Date" := ServHeader."Order Date";
            "Replaced Item No." := '';
            "Component Line No." := 0;
            "Spare Part Action" := 0;
            "Price Adjmt. Status" := "Price Adjmt. Status"::" ";
            "Exclude Warranty" := false;
            "Exclude Contract Discount" := false;
            "Fault Reason Code" := '';

            "Bill-to Customer No." := ServHeader."Bill-to Customer No.";
            "Price Calculation Method" := ServHeader."Price Calculation Method";
            "Customer Price Group" := ServHeader."Customer Price Group";
            "Customer Disc. Group" := ServHeader."Customer Disc. Group";
            "Allow Line Disc." := ServHeader."Allow Line Disc.";
            "Bin Code" := '';
            "Transaction Type" := ServHeader."Transaction Type";
            "Transport Method" := ServHeader."Transport Method";
            "Exit Point" := ServHeader."Exit Point";
            Area := ServHeader.Area;
            "Transaction Specification" := ServHeader."Transaction Specification";

            "Location Code" := '';
            if Type = Type::Resource then
                "Location Code" := ServOrderMgt.FindResLocationCode("No.", ServHeader."Order Date");
            if "Location Code" = '' then
                "Location Code" := ServHeader."Location Code";

            OnInitHeaderDefaultsOnAfterAssignLocationCode(Rec, ServHeader);

            if Type = Type::Item then begin
                if (xRec."No." <> "No.") and (Quantity <> 0) then
                    ServiceWarehouseMgt.ServiceLineVerifyChange(Rec, xRec);
                GetLocation("Location Code");
            end;

            "Gen. Bus. Posting Group" := ServHeader."Gen. Bus. Posting Group";
            "VAT Bus. Posting Group" := ServHeader."VAT Bus. Posting Group";
            "Tax Area Code" := ServHeader."Tax Area Code";
            "Tax Liable" := ServHeader."Tax Liable";
            "Responsibility Center" := ServHeader."Responsibility Center";
            "Posting Date" := ServHeader."Posting Date";
            "Currency Code" := ServHeader."Currency Code";

            "Shipping Agent Code" := ServHeader."Shipping Agent Code";
            "Shipping Agent Service Code" := ServHeader."Shipping Agent Service Code";
            "Shipping Time" := ServHeader."Shipping Time";

            SetInheritedDimensionSetID(ServHeader);
        end;

        OnAfterAssignHeaderValues(Rec, ServHeader);
    end;

    local procedure SetInheritedDimensionSetID(ServHeader: Record "Service Header")
    begin
        if ServItemLine."Dimension Set ID" <> 0 then begin
            "Shortcut Dimension 1 Code" := ServItemLine."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := ServItemLine."Shortcut Dimension 2 Code";
            "Dimension Set ID" := ServItemLine."Dimension Set ID";
        end else begin
            "Shortcut Dimension 1 Code" := ServHeader."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := ServHeader."Shortcut Dimension 2 Code";
            "Dimension Set ID" := ServHeader."Dimension Set ID";
        end;
    end;

    local procedure InitServHeaderShipToCode()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitServHeaderShipToCode(Rec, ServHeader, IsHandled);
        if IsHandled then
            exit;

        if "Service Item Line No." <> 0 then begin
            ServItemLine.Get(ServHeader."Document Type", ServHeader."No.", "Service Item Line No.");
            "Ship-to Code" := ServItemLine."Ship-to Code";
        end else
            "Ship-to Code" := ServHeader."Ship-to Code";
    end;

    procedure IsPriceCalcCalledByField(CurrPriceFieldNo: Integer): Boolean;
    begin
        exit(FieldCausedPriceCalculation = CurrPriceFieldNo);
    end;

    procedure PlanPriceCalcByField(CurrPriceFieldNo: Integer)
    begin
        if FieldCausedPriceCalculation = 0 then
            FieldCausedPriceCalculation := CurrPriceFieldNo;
    end;

    procedure ClearFieldCausedPriceCalculation()
    begin
        FieldCausedPriceCalculation := 0;
    end;

    procedure UpdateUnitPrice(CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitPriceProcedure(Rec, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        ClearFieldCausedPriceCalculation();
        PlanPriceCalcByField(CalledByFieldNo);
        UpdateUnitPriceByField(CalledByFieldNo, false);
    end;

    local procedure UpdateUnitPriceByField(CalledByFieldNo: Integer; CalcCost: Boolean)
    var
        PriceType: Enum "Price Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitPriceByField(Rec, CalledByFieldNo, CalcCost, IsHandled);
        if IsHandled then
            exit;

        if not IsPriceCalcCalledByField(CalledByFieldNo) then
            exit;

        OnBeforeUpdateUnitPrice(Rec, xRec, CalledByFieldNo, CurrFieldNo);

        TestField("Qty. per Unit of Measure");
        ServHeader.Get(Rec."Document Type", Rec."Document No.");

        CalculateDiscount();
        ApplyPrice(PriceType::Sale, ServHeader, CalledByFieldNo);
        Validate("Unit Price");
        if CalcCost then begin
            ApplyPrice(PriceType::Purchase, ServHeader, CalledByFieldNo);
            Validate("Unit Cost (LCY)");
        end;

        ClearFieldCausedPriceCalculation();
        OnAfterUpdateUnitPrice(Rec, xRec, CalledByFieldNo, CurrFieldNo);
    end;

    procedure ApplyPrice(PriceType: Enum "Price Type"; ServiceHeader: Record "Service Header"; CalledByFieldNo: Integer)
    var
        PriceCalculation: Interface "Price Calculation";
        Line: Variant;
    begin
        GetPriceCalculationHandler(PriceType, ServiceHeader, PriceCalculation);
        PriceCalculation.ApplyPrice(CalledByFieldNo);
        PriceCalculation.GetLine(Line);
        Rec := Line;
    end;

    procedure ShowDimensions()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDimensions(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if ("Contract No." <> '') and ("Appl.-to Service Entry" <> 0) then
            ViewDimensionSetEntries()
        else
            "Dimension Set ID" :=
              DimMgt.EditDimensionSet(
                Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."),
                "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        OnAfterShowDimensions(Rec, xRec);
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

        TestField(Type, Type::Item);
        TestField("No.");
        TestField(Reserve);
        Clear(Reservation);
        Reservation.SetReservSource(Rec);
        Reservation.RunModal();
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

    procedure AutoReserve()
    begin
        AutoReserve(true);
    end;

    procedure AutoReserve(ShowReservationForm: Boolean)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ReservationEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        ConfirmManagement: Codeunit "Confirm Management";
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutoReserve(Rec, xRec, FullAutoReservation, ServiceLineReserve, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::Item);
        TestField("No.");
        if Reserve = Reserve::Never then
            FieldError(Reserve);
        ServiceLineReserve.ReservQuantity(Rec, QtyToReserve, QtyToReserveBase);
        if QtyToReserveBase <> 0 then begin
            ReservMgt.SetReservSource(Rec);
            if ReplaceServItemAction then begin
                ServiceLineReserve.FindReservEntry(Rec, ReservationEntry);
                ReservMgt.SetTrackingFromReservEntry(ReservationEntry);
            end;
            ReservMgt.AutoReserve(FullAutoReservation, '', "Order Date", QtyToReserve, QtyToReserveBase);
            Find();
            ServiceMgtSetup.Get();
            if (not FullAutoReservation) and (not ServiceMgtSetup."Skip Manual Reservation") and ShowReservationForm then begin
                Commit();
                if ConfirmManagement.GetResponse(ManualReserveQst, true) then begin
                    Rec.ShowReservation();
                    Find();
                end;
            end;
            UpdatePlanned();
        end;
    end;

    protected procedure ClearFields()
    var
        TempServLine: Record "Service Line" temporary;
    begin
        TempServLine := Rec;
        Init();
        SystemId := TempServLine.SystemId;

        if CurrFieldNo <> FieldNo(Type) then
            "No." := TempServLine."No.";

        Type := TempServLine.Type;
        if Type <> Type::" " then
            Quantity := TempServLine.Quantity;

        "Line No." := TempServLine."Line No.";
        Validate("Service Item Line No.", TempServLine."Service Item Line No.");
        "Service Item No." := TempServLine."Service Item No.";
        "Service Item Serial No." := TempServLine."Service Item Serial No.";
        "Document Type" := TempServLine."Document Type";
        "Document No." := TempServLine."Document No.";
        "Gen. Bus. Posting Group" := TempServLine."Gen. Bus. Posting Group";
        "Order Date" := TempServLine."Order Date";
        "Customer No." := TempServLine."Customer No.";
        "Ship-to Code" := TempServLine."Ship-to Code";
        "Posting Date" := TempServLine."Posting Date";
        "System-Created Entry" := TempServLine."System-Created Entry";
        "Price Adjmt. Status" := "Price Adjmt. Status"::" ";
        "Time Sheet No." := TempServLine."Time Sheet No.";
        "Time Sheet Line No." := TempServLine."Time Sheet Line No.";
        "Time Sheet Date" := TempServLine."Time Sheet Date";
        if "No." <> xRec."No." then
            Validate("Job Planning Line No.", 0);

        OnAfterClearFields(Rec, xRec, TempServLine, CurrFieldNo);
    end;

    procedure ShowNonstock()
    var
        NonstockItem: Record "Nonstock Item";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowNonstock(Rec, xRec, IsHandled);
        if not IsHandled then begin
            TestField(Type, Type::Item);
            TestField("No.", '');
            if PAGE.RunModal(PAGE::"Catalog Item List", NonstockItem) = ACTION::LookupOK then begin
                CheckNonstockItemTemplate(NonstockItem);

                "No." := NonstockItem."Entry No.";
                ServCatalogItemMgt.NonStockFSM(Rec);
                Validate("No.", "No.");
                Validate("Unit Price", NonstockItem."Unit Price");
                OnShowNonstockOnAfterUpdateFromNonstockItem(Rec, xRec);
            end;
        end;

        OnAfterShowNonstock(Rec);
    end;

    procedure CalcLineAmount() LineAmount: Decimal
    begin
        LineAmount := "Line Amount" - "Inv. Discount Amount";

        OnAfterCalcLineAmount(Rec, LineAmount);
    end;

    local procedure CanShipQty(): Boolean
    begin
        if Abs("Qty. to Ship") > Abs("Outstanding Quantity") then
            exit(false);

        if ("Qty. to Ship" < 0) and (Quantity > 0) or
           ("Qty. to Ship" > 0) and (Quantity < 0)
        then
            exit(false);

        if ("Outstanding Quantity" < 0) and (Quantity > 0) or
           ("Outstanding Quantity" > 0) and (Quantity < 0)
        then
            exit(false);

        exit(true);
    end;

    local procedure CanShipBaseQty(): Boolean
    begin
        if Abs("Qty. to Ship (Base)") > Abs("Outstanding Qty. (Base)") then
            exit(false);

        if ("Qty. to Ship (Base)" < 0) and ("Quantity (Base)" > 0) or
           ("Qty. to Ship (Base)" > 0) and ("Quantity (Base)" < 0)
        then
            exit(false);

        if ("Outstanding Qty. (Base)" < 0) and ("Quantity (Base)" > 0) or
           ("Outstanding Qty. (Base)" > 0) and ("Quantity (Base)" < 0)
        then
            exit(false);

        exit(true);
    end;

    local procedure CopyFromCost()
    var
        ServCost: Record "Service Cost";
        GLAcc: Record "G/L Account";
        ConfirmManagement: Codeunit "Confirm Management";
        ShouldShowConfirm: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromCost(Rec, HideCostWarning, IsHandled);
        if not IsHandled then begin
            ServCost.Get("No.");
            ShouldShowConfirm := (ServCost."Cost Type" = ServCost."Cost Type"::Travel) and (ServHeader."Service Zone Code" <> ServCost."Service Zone Code") and not HideCostWarning;
            OnCopyFromCostOnAfterCalcShouldShowConfirm(Rec, ServCost, HideCostWarning, ShouldShowConfirm);
            if ShouldShowConfirm then
                if not ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(
                       Text004, ServCost.TableCaption(), "No.",
                       ServCost.FieldCaption("Service Zone Code"),
                       ServHeader.FieldCaption("Service Zone Code"),
                       ServHeader.TableCaption(), ServHeader."No."), true)
                then
                    Error(Text005);
            Description := ServCost.Description;
            Validate("Unit Cost (LCY)", ServCost."Default Unit Cost");
            "Unit Price" := ServCost."Default Unit Price";
            "Unit of Measure Code" := ServCost."Unit of Measure Code";
            GLAcc.Get(ServCost."Account No.");
            if CheckProdPostingGroups() then
                GLAcc.TestField("Gen. Prod. Posting Group");
            "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
            "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
            "Tax Group Code" := GLAcc."Tax Group Code";
            if "Service Item Line No." <> 0 then
                if FaultReasonCode.Get(ServItemLine."Fault Reason Code") and
                   (not FaultReasonCode."Exclude Warranty Discount")
                then
                    Validate("Fault Reason Code", ServItemLine."Fault Reason Code");
            Quantity := ServCost."Default Quantity";
        end;

        OnAfterAssignServCostValues(Rec, ServCost);
    end;

    local procedure CopyFromStdTxt()
    var
        StandardText: Record "Standard Text";
    begin
        "Tax Area Code" := '';
        "Tax Liable" := false;
        StandardText.Get("No.");
        Description := StandardText.Description;

        OnAfterAssignStdTxtValues(Rec, StandardText);
    end;

    local procedure CopyFromGLAccount()
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Get("No.");
        GLAcc.CheckGLAcc();
        if not "System-Created Entry" then
            GLAcc.TestField("Direct Posting", true);
        Description := GLAcc.Name;
        "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        "Tax Group Code" := GLAcc."Tax Group Code";
        "Allow Invoice Disc." := false;

        OnAfterAssignGLAccountValues(Rec, GLAcc, ServHeader);
    end;

    local procedure CopyFromItem()
    var
        Item: Record Item;
        ServOrderManagement: Codeunit ServOrderManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromItem(Rec, IsHandled);
        if IsHandled then
            exit;

        GetItem(Item);
        if Item."Service Blocked" then
            if ServOrderManagement.IsCreditDocumentType("Document Type") then
                SendBlockedItemNotification();
        if Item.IsInventoriableType() then
            Item.TestField("Inventory Posting Group");
        Item.TestField("Gen. Prod. Posting Group");
        Description := Item.Description;
        "Description 2" := Item."Description 2";
        GetUnitCost();
        "Allow Invoice Disc." := Item."Allow Invoice Disc.";
        "Units per Parcel" := Item."Units per Parcel";
        CalcFields("Substitution Available");

        "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
        "Tax Group Code" := Item."Tax Group Code";
        "Posting Group" := Item."Inventory Posting Group";
        "Item Category Code" := Item."Item Category Code";
        "Variant Code" := '';
        Nonstock := Item."Created From Nonstock Item";
        if Item."Sales Unit of Measure" <> '' then
            "Unit of Measure Code" := Item."Sales Unit of Measure"
        else
            "Unit of Measure Code" := Item."Base Unit of Measure";

        if ServHeader."Language Code" <> '' then
            GetItemTranslation();

        if Item.Reserve = Item.Reserve::Optional then
            Reserve := ServHeader.Reserve
        else
            Reserve := Item.Reserve;

        if "Service Item Line No." <> 0 then begin
            "Warranty Disc. %" := ServItemLine."Warranty % (Parts)";
            Warranty :=
              ServItemLine.Warranty and
              (ServHeader."Order Date" >= ServItemLine."Warranty Starting Date (Parts)") and
              (ServHeader."Order Date" <= ServItemLine."Warranty Ending Date (Parts)") and
              not "Exclude Warranty";
            Validate("Fault Reason Code", ServItemLine."Fault Reason Code");
        end else begin
            Warranty := false;
            "Warranty Disc. %" := 0;
        end;

        OnAfterAssignItemValues(Rec, Item, xRec, CurrFieldNo, ServHeader);
    end;

    procedure CopyFromServItem(ServItem: Record "Service Item")
    var
        ServItem2: Record "Service Item";
        ServItemComponent: Record "Service Item Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromServItem(Rec, ServItem, ServItemComponent, IsHandled, HideReplacementDialog, ServItemLine, Select, ReplaceServItemAction);
        if IsHandled then
            exit;

        if ServItem."Item No." = "No." then begin
            ServItemLine.Reset();
            if not HideReplacementDialog then begin
                ReplaceServItemAction := ReplaceServItem();
                if not ReplaceServItemAction then
                    exit;
            end;
        end else begin
            ServItem.CalcFields("Service Item Components");
            if ServItem."Service Item Components" and not HideReplacementDialog then begin
                Select := StrMenu(Text006, GetStrMenuDefaultValue());
                case Select of
                    1:
                        begin
                            Commit();
                            ServItemComponent.Reset();
                            ServItemComponent.SetRange(Active, true);
                            ServItemComponent.SetRange("Parent Service Item No.", ServItem."No.");
                            if PAGE.RunModal(0, ServItemComponent) = ACTION::LookupOK then begin
                                "Replaced Item Type" :=
                                    Enum::"Replaced Service Item Component Type".FromInteger(ServItemComponent.Type.AsInteger() + 1);
                                "Replaced Item No." := ServItemComponent."No.";
                                "Component Line No." := ServItemComponent."Line No.";
                                CheckIfServItemReplacement("Component Line No.");
                                if ServItemComponent.Type = ServItemComponent.Type::"Service Item" then begin
                                    ServItem2.Get(ServItemComponent."No.");
                                    "Warranty Disc. %" := ServItem2."Warranty % (Parts)";
                                end;
                                "Spare Part Action" := "Spare Part Action"::"Component Replaced";
                            end else
                                Error(Text007, ServItemComponent.TableCaption());
                        end;
                    2:
                        begin
                            "Replaced Item No." := '';
                            "Component Line No." := 0;
                            "Spare Part Action" := "Spare Part Action"::"Component Installed";
                        end;
                end;
            end;
        end;

        OnAfterAssignServItemValues(Rec, ServItem, ServItemComponent, HideReplacementDialog);
    end;

    local procedure GetStrMenuDefaultValue() DefaultValue: Integer
    begin
        DefaultValue := 3;
        OnAfterGetStrMenuDefaultValue(DefaultValue);
    end;

    local procedure CopyFromResource()
    var
        Res: Record Resource;
        PriceType: Enum "Price Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromResource(Rec, IsHandled);
        if not IsHandled then begin
            Res.Get("No.");
            Res.CheckResourcePrivacyBlocked(false);
            Res.TestField(Blocked, false);
            Res.TestField("Gen. Prod. Posting Group");
            OnCopyFromResourceOnAfterCheckResource(Rec, Res);
            Description := Res.Name;
            "Description 2" := Res."Name 2";
            if "Service Item Line No." <> 0 then begin
                "Warranty Disc. %" := ServItemLine."Warranty % (Labor)";
                Warranty :=
                  ServItemLine.Warranty and
                  (ServHeader."Order Date" >= ServItemLine."Warranty Starting Date (Labor)") and
                  (ServHeader."Order Date" <= ServItemLine."Warranty Ending Date (Labor)") and
                  not "Exclude Warranty";
                Validate("Fault Reason Code", ServItemLine."Fault Reason Code");
            end else begin
                Warranty := false;
                "Warranty Disc. %" := 0;
            end;
            "Unit of Measure Code" := Res."Base Unit of Measure";
            "Gen. Prod. Posting Group" := Res."Gen. Prod. Posting Group";
            "VAT Prod. Posting Group" := Res."VAT Prod. Posting Group";
            "Tax Group Code" := Res."Tax Group Code";
            ApplyPrice(PriceType::Purchase, ServHeader, FieldNo("Unit of Measure Code"));
            Validate("Unit Cost (LCY)");
        end;

        OnAfterAssignResourceValues(Rec, Res);
    end;

    procedure ShowItemSub()
    var
        ServItemSubstitution: Codeunit "Serv. Item Substitution";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowItemSub(Rec, IsHandled);
        if IsHandled then
            exit;

        ServItemSubstitution.ItemServiceSubstGet(Rec);
    end;

    procedure SetHideReplacementDialog(NewHideReplacementDialog: Boolean)
    begin
        HideReplacementDialog := NewHideReplacementDialog;

        OnAfterSetHideReplacementDialog(Rec, HideReplacementDialog);
    end;

    procedure GetHideReplacementDialog(): Boolean
    begin
        exit(HideReplacementDialog);
    end;

    procedure CheckIfServItemReplacement(ComponentLineNo: Integer)
    begin
        if "Service Item Line No." <> 0 then begin
            ServiceLine.Reset();
            ServiceLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.", "Component Line No.");
            ServiceLine.SetRange("Document Type", "Document Type");
            ServiceLine.SetRange("Document No.", "Document No.");
            ServiceLine.SetRange("Service Item Line No.", "Service Item Line No.");
            ServiceLine.SetFilter("Line No.", '<>%1', "Line No.");
            ServiceLine.SetRange("Component Line No.", ComponentLineNo);
            ServiceLine.SetFilter("Spare Part Action", '<>%1', "Spare Part Action"::" ");
            if ServiceLine.FindFirst() then
                Error(CompAlreadyReplacedErr, ServiceLine."Line No.");
        end;
    end;

    procedure IsInbound(): Boolean
    begin
        case "Document Type" of
            "Document Type"::Quote, "Document Type"::Order, ServiceLine."Document Type"::Invoice:
                exit("Quantity (Base)" < 0);
            ServiceLine."Document Type"::"Credit Memo":
                exit("Quantity (Base)" > 0);
        end;

        exit(false);
    end;

    procedure OpenItemTrackingLines()
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        TestField("Quantity (Base)");
        ServiceLineReserve.CallItemTracking(Rec);
    end;

    protected procedure InsertItemTracking()
    var
        ReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        ServiceLine := Rec;
        if TempTrackingSpecification.FindFirst() then begin
            ServiceLineReserve.DeleteLine(Rec);
            Clear(CreateReservEntry);
            ReservEntry.CopyTrackingFromSpec(TempTrackingSpecification);
            CreateReservEntry.CreateReservEntryFor(
                DATABASE::"Service Line",
                ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.",
                '', 0, ServiceLine."Line No.", ServiceLine."Qty. per Unit of Measure",
                ServiceLine.Quantity, ServiceLine."Quantity (Base)", ReservEntry);
            OnInsertItemTrackingOnBeforeCreateEntry(Rec);
            CreateReservEntry.CreateEntry(
                ServiceLine."No.", ServiceLine."Variant Code", ServiceLine."Location Code", ServiceLine.Description,
                0D, ServiceLine."Posting Date", 0, Enum::"Reservation Status"::Surplus);
            TempTrackingSpecification.DeleteAll();
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure GetDefaultBin()
    var
        Bin: Record Bin;
        BinType: Record "Bin Type";
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultBin(Rec, CurrFieldNo, IsHandled, ReplaceServItemAction);
        if IsHandled then
            exit;

        if (Type <> Type::Item) or IsNonInventoriableItem() then
            exit;

        "Bin Code" := '';

        if ("Location Code" <> '') and ("No." <> '') then begin
            GetLocation("Location Code");
            if not Location."Bin Mandatory" then
                exit;
            if (not Location."Directed Put-away and Pick") or ("Document Type" <> "Document Type"::Order) then begin
                WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", "Bin Code");
                if ("Document Type" <> "Document Type"::Order) and ("Bin Code" <> '') and Location."Directed Put-away and Pick"
                then begin
                    // Clear the bin code if the bin is not of pick type
                    Bin.Get("Location Code", "Bin Code");
                    BinType.Get(Bin."Bin Type Code");
                    if not BinType.Pick then
                        "Bin Code" := '';
                end;
            end;
        end;
    end;

    procedure GetItemTranslation()
    var
        ItemTranslation: Record "Item Translation";
    begin
        GetServHeader();
        if ItemTranslation.Get("No.", "Variant Code", ServHeader."Language Code") then begin
            Description := ItemTranslation.Description;
            "Description 2" := ItemTranslation."Description 2";
            OnAfterGetItemTranslation(Rec, ServHeader, ItemTranslation);
        end;
    end;

    procedure GetSKU() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSKU(Rec, Result, IsHandled, SKU);
        if IsHandled then
            exit(Result);

        if (SKU."Location Code" = "Location Code") and
           (SKU."Item No." = "No.") and
           (SKU."Variant Code" = "Variant Code")
        then
            exit(true);
        if SKU.Get("Location Code", "No.", "Variant Code") then
            exit(true);

        Result := false;
        OnAfterGetSKU(Rec, Result);
    end;

    procedure GetUnitCost()
    var
        Item: Record Item;
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        GetItem(Item);
        "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
        if GetSKU() then
            Validate("Unit Cost (LCY)", SKU."Unit Cost" * "Qty. per Unit of Measure")
        else
            Validate("Unit Cost (LCY)", Item."Unit Cost" * "Qty. per Unit of Measure");

        OnAfterGetUnitCost(Rec, Item);
    end;

    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        RemainingQty := "Outstanding Quantity" - Abs("Reserved Quantity");
        RemainingQtyBase := "Outstanding Qty. (Base)" - Abs("Reserved Qty. (Base)");
    end;

    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal): Decimal
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := "Reserved Quantity";
        QtyReservedBase := "Reserved Qty. (Base)";
        QtyToReserve := "Outstanding Quantity";
        QtyToReserveBase := "Outstanding Qty. (Base)";
        exit("Qty. per Unit of Measure");
    end;

    procedure GetSourceCaption(): Text
    begin
        exit(StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"Service Line", "Document Type".AsInteger(), "Document No.", "Line No.", '', 0);
        ReservEntry.SetItemData("No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        if Type <> Type::Item then
            ReservEntry."Item No." := '';
        ReservEntry."Expected Receipt Date" := "Needed by Date";
        ReservEntry."Shipment Date" := "Needed by Date";
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Service Line", "Document Type".AsInteger(), "Document No.", "Line No.", false);
        ReservEntry.SetSourceFilter('', 0);
    end;

    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        exit(not ReservEntry.IsEmpty);
    end;


    procedure AfterResourseFindCost(var ResourceCost: Record "Resource Cost");
    begin
        OnAfterResourseFindCost(Rec, ResourceCost);
    end;

    procedure InitOutstanding()
    begin
        if "Document Type" = "Document Type"::"Credit Memo" then begin
            "Outstanding Quantity" := Quantity;
            "Outstanding Qty. (Base)" := "Quantity (Base)";
        end else begin
            "Outstanding Quantity" := Quantity - "Quantity Shipped";
            "Outstanding Qty. (Base)" := "Quantity (Base)" - "Qty. Shipped (Base)";
            "Qty. Shipped Not Invoiced" := "Quantity Shipped" - "Quantity Invoiced" - "Quantity Consumed";
            "Qty. Shipped Not Invd. (Base)" := "Qty. Shipped (Base)" - "Qty. Invoiced (Base)" - "Qty. Consumed (Base)";
        end;

        OnInitOutstandingOnAfterInitOutstandingQuantity(Rec);

        CalcFields("Reserved Quantity");
        Planned := "Reserved Quantity" = "Outstanding Quantity";
        "Completely Shipped" := (Quantity <> 0) and ("Outstanding Quantity" = 0);
        InitOutstandingAmount();

        OnAfterInitOutstanding(Rec);
    end;

    procedure InitOutstandingAmount()
    var
        AmountInclVAT: Decimal;
    begin
        if (Quantity = 0) or (CalcChargeableQty() = 0) then begin
            "Outstanding Amount" := 0;
            "Outstanding Amount (LCY)" := 0;
            "Shipped Not Invoiced" := 0;
            "Shipped Not Invoiced (LCY)" := 0;
        end else begin
            GetServHeader();
            AmountInclVAT := CalcLineAmount();
            if not ServHeader."Prices Including VAT" then
                if "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" then
                    AmountInclVAT := AmountInclVAT +
                      Round(
                        SalesTaxCalculate.CalculateTax(
                          "Tax Area Code", "Tax Group Code", "Tax Liable", ServHeader."Posting Date",
                          CalcLineAmount(), "Quantity (Base)", ServHeader."Currency Factor"),
                        Currency."Amount Rounding Precision")
                else
                    AmountInclVAT :=
                      Round(
                        AmountInclVAT *
                        (1 + "VAT %" / 100 * (1 - GetVatBaseDiscountPct(ServHeader) / 100)),
                        Currency."Amount Rounding Precision");
            Validate(
              "Outstanding Amount",
              Round(
                AmountInclVAT * "Outstanding Quantity" / Quantity,
                Currency."Amount Rounding Precision"));
            if "Document Type" <> "Document Type"::"Credit Memo" then
                Validate(
                  "Shipped Not Invoiced",
                  Round(
                    AmountInclVAT * "Qty. Shipped Not Invoiced" / CalcChargeableQty(),
                    Currency."Amount Rounding Precision"));
        end;

        OnAfterInitOutstandingAmount(Rec, ServHeader, Currency);
    end;

    procedure InitQtyToShip()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitQtyToShip(Rec, CurrFieldNo, IsHandled);
        if not IsHandled then begin
            if LineRequiresShipmentOrReceipt() then begin
                "Qty. to Ship" := 0;
                "Qty. to Ship (Base)" := 0;
            end else begin
                "Qty. to Ship" := "Outstanding Quantity";
                "Qty. to Ship (Base)" := "Outstanding Qty. (Base)";
            end;
            Validate("Qty. to Consume");

            IsHandled := false;
            OnInitQtyToShipOnBeforeInitQtyToInvoice(Rec, IsHandled);
            if not IsHandled then
                InitQtyToInvoice();

        end;
        OnAfterInitQtyToShip(Rec, CurrFieldNo);
    end;

    procedure InitQtyToInvoice()
    begin
        "Qty. to Invoice" := MaxQtyToInvoice();
        "Qty. to Invoice (Base)" := MaxQtyToInvoiceBase();
        ClearVATDifference();
        OnInitQtyToInvoiceOnBeforeCalcInvDiscToInvoice(Rec, CurrFieldNo);
        CalcInvDiscToInvoice();

        OnAfterInitQtyToInvoice(Rec, CurrFieldNo);
    end;

    procedure MaxQtyToInvoice(): Decimal
    begin
        if "Document Type" = "Document Type"::"Credit Memo" then
            exit(Quantity);

        exit("Quantity Shipped" + "Qty. to Ship" - "Quantity Invoiced" - "Quantity Consumed" - "Qty. to Consume");
    end;

    local procedure MaxQtyToInvoiceBase(): Decimal
    begin
        if "Document Type" = "Document Type"::"Credit Memo" then
            exit("Quantity (Base)");

        exit(
          "Qty. Shipped (Base)" + "Qty. to Ship (Base)" -
          "Qty. Invoiced (Base)" - "Qty. Consumed (Base)" -
          "Qty. to Consume (Base)");
    end;

    internal procedure GetVatBaseDiscountPct(ServiceHeader: Record "Service Header") Result: Decimal
    begin
        Result := ServiceHeader."VAT Base Discount %";
        OnAfterGetVatBaseDiscountPct(Rec, ServiceHeader, Result);
    end;

    local procedure CalcInvDiscToInvoice()
    var
        OldInvDiscAmtToInv: Decimal;
    begin
        GetServHeader();
        OldInvDiscAmtToInv := "Inv. Disc. Amount to Invoice";
        if (Quantity = 0) or (CalcChargeableQty() = 0) then
            Validate("Inv. Disc. Amount to Invoice", 0)
        else
            Validate(
              "Inv. Disc. Amount to Invoice",
              Round(
                "Inv. Discount Amount" * "Qty. to Invoice" / CalcChargeableQty(),
                Currency."Amount Rounding Precision"));

        if OldInvDiscAmtToInv <> "Inv. Disc. Amount to Invoice" then begin
            "Amount Including VAT" := "Amount Including VAT" - "VAT Difference";
            ClearVATDifference();
        end;
        NotifyOnMissingSetup(FieldNo("Inv. Discount Amount"));

        OnAfterCalcInvDiscToInvoice(Rec, OldInvDiscAmtToInv);
    end;

    procedure ItemExists(ItemNo: Code[20]): Boolean
    var
        Item2: Record Item;
    begin
        if Type = Type::Item then
            if not Item2.Get(ItemNo) then
                exit(false);
        exit(true);
    end;

    local procedure InitItemAppl(OnlyApplTo: Boolean)
    begin
        "Appl.-to Item Entry" := 0;
        if not OnlyApplTo then
            "Appl.-from Item Entry" := 0;
    end;

    local procedure GetResource()
    begin
        TestField("No.");
        if "No." <> Resource."No." then
            Resource.Get("No.");
    end;

    procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    begin
        if not ServHeader.Get("Document Type", "Document No.") then begin
            ServHeader."No." := '';
            ServHeader.Init();
        end;
        if ServHeader."Prices Including VAT" then
            exit('2,1,' + GetFieldCaption(FieldNumber));

        exit('2,0,' + GetFieldCaption(FieldNumber));
    end;

    local procedure GetFieldCaption(FieldNumber: Integer): Text[100]
    var
        "Field": Record "Field";
    begin
        Field.Get(DATABASE::"Service Line", FieldNumber);
        exit(Field."Field Caption");
    end;

    procedure UpdateVATAmounts()
    var
        ServiceLine2: Record "Service Line";
        TotalLineAmount: Decimal;
        TotalInvDiscAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalVATDifference: Decimal;
        TotalQuantityBase: Decimal;
        TotalVATBaseAmount: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeUpdateVATAmounts(Rec);

        GetServHeader();
        ServiceLine2.SetRange("Document Type", "Document Type");
        ServiceLine2.SetRange("Document No.", "Document No.");
        ServiceLine2.SetFilter("Line No.", '<>%1', "Line No.");
        if "Line Amount" = 0 then
            if xRec."Line Amount" >= 0 then
                ServiceLine2.SetFilter(Amount, '>%1', 0)
            else
                ServiceLine2.SetFilter(Amount, '<%1', 0)
        else
            if "Line Amount" > 0 then
                ServiceLine2.SetFilter(Amount, '>%1', 0)
            else
                ServiceLine2.SetFilter(Amount, '<%1', 0);
        ServiceLine2.SetRange("VAT Identifier", "VAT Identifier");
        ServiceLine2.SetRange("Tax Group Code", "Tax Group Code");

        if "Line Amount" = "Inv. Discount Amount" then begin
            Amount := 0;
            "VAT Base Amount" := 0;
            "Amount Including VAT" := 0;
            OnUpdateVATAmountOnAfterClearAmounts(Rec);
        end else begin
            TotalLineAmount := 0;
            TotalInvDiscAmount := 0;
            TotalAmount := 0;
            TotalAmountInclVAT := 0;
            TotalQuantityBase := 0;
            TotalVATBaseAmount := 0;
            if ("VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax") or
               (("VAT Calculation Type" in
                 ["VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT"]) and
                ("VAT %" <> 0))
            then
                if not ServiceLine2.IsEmpty() then begin
                    ServiceLine2.CalcSums(
                      "Line Amount", "Inv. Discount Amount", Amount, "Amount Including VAT", "Quantity (Base)", "VAT Base Amount");
                    TotalLineAmount := ServiceLine2."Line Amount";
                    TotalInvDiscAmount := ServiceLine2."Inv. Discount Amount";
                    TotalAmount := ServiceLine2.Amount;
                    TotalAmountInclVAT := ServiceLine2."Amount Including VAT";
                    TotalVATDifference := ServiceLine2."VAT Difference";
                    TotalQuantityBase := ServiceLine2."Quantity (Base)";
                    TotalVATBaseAmount := ServiceLine2."VAT Base Amount";
                end;

            if ServHeader."Prices Including VAT" then
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            Amount :=
                              (TotalLineAmount - TotalInvDiscAmount + CalcLineAmount()) / (1 + GetVATPct() / 100) -
                              TotalAmount;
                            "VAT Base Amount" :=
                              Round(
                                Amount * (1 - GetVatBaseDiscountPct(ServHeader) / 100), Currency."Amount Rounding Precision");
                            OnUpdateVATAmountsOnAfterCalculateVATBaseAmount(Rec, ServHeader, Currency, TotalAmount, TotalVATBaseAmount);
                            "Amount Including VAT" :=
                              Round(TotalAmount + Amount +
                                (TotalAmount + Amount) * (1 - GetVatBaseDiscountPct(ServHeader) / 100) * GetVATPct() / 100 -
                                TotalAmountInclVAT, Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                            Amount := Round(Amount, Currency."Amount Rounding Precision");
                            OnUpdateVATAmountsIfPricesInclVATOnAfterNormalVATCalc(Rec, ServHeader, Currency);
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            ServHeader.TestField("VAT Base Discount %", 0);
                            Amount :=
                              SalesTaxCalculate.ReverseCalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable", ServHeader."Posting Date",
                                TotalAmountInclVAT + "Amount Including VAT", TotalQuantityBase + "Quantity (Base)",
                                ServHeader."Currency Factor") -
                              TotalAmount;
                            OnAfterSalesTaxCalculateReverse(Rec, ServHeader, Currency);
                            UpdateVATPercent(Amount, "Amount Including VAT" - Amount);
                            Amount := Round(Amount, Currency."Amount Rounding Precision");
                            "VAT Base Amount" := Amount;
                        end;
                end
            else begin
                IsHandled := false;
                OnUpdateVATAmountsOnBeforeCalculateAmountWithNoVAT(Rec, TotalAmount, TotalAmountInclVAT, IsHandled);
                if not IsHandled then
                    case "VAT Calculation Type" of
                        "VAT Calculation Type"::"Normal VAT",
                      "VAT Calculation Type"::"Reverse Charge VAT":
                            begin
                                Amount := Round(CalcLineAmount(), Currency."Amount Rounding Precision");
                                "VAT Base Amount" :=
                                  Round(Amount * (1 - GetVatBaseDiscountPct(ServHeader) / 100), Currency."Amount Rounding Precision");
                                "Amount Including VAT" :=
                                  TotalAmount + Amount +
                                  Round(
                                    (TotalAmount + Amount) * (1 - GetVatBaseDiscountPct(ServHeader) / 100) * GetVATPct() / 100,
                                    Currency."Amount Rounding Precision", Currency.VATRoundingDirection()) -
                                  TotalAmountInclVAT + TotalVATDifference;
                                OnUpdateVATAmountsIfPricesExclVATOnAfterNormalVATCalc(Rec, ServHeader, Currency);
                            end;
                        "VAT Calculation Type"::"Full VAT":
                            begin
                                Amount := 0;
                                "VAT Base Amount" := 0;
                                "Amount Including VAT" := CalcLineAmount();
                            end;
                        "VAT Calculation Type"::"Sales Tax":
                            begin
                                Amount := Round(CalcLineAmount(), Currency."Amount Rounding Precision");
                                "VAT Base Amount" := Amount;
                                "Amount Including VAT" :=
                                  TotalAmount + Amount +
                                  Round(
                                    SalesTaxCalculate.CalculateTax(
                                      "Tax Area Code", "Tax Group Code", "Tax Liable", ServHeader."Posting Date",
                                      TotalAmount + Amount, TotalQuantityBase + "Quantity (Base)",
                                      ServHeader."Currency Factor"), Currency."Amount Rounding Precision") -
                                  TotalAmountInclVAT;
                                OnAfterSalesTaxCalculate(Rec, ServHeader, Currency);
                                UpdateVATPercent("VAT Base Amount", "Amount Including VAT" - "VAT Base Amount");
                            end;
                    end;
            end;
        end;

        OnAfterUpdateVATAmounts(Rec);
    end;

    procedure MaxQtyToConsume() Result: Decimal
    begin
        Result := Quantity - "Quantity Shipped";
        OnAfterMaxQtyToConsume(Rec, Result);
    end;

    procedure MaxQtyToConsumeBase() Result: Decimal
    begin
        Result := "Quantity (Base)" - "Qty. Shipped (Base)";
        OnAfterMaxQtyToConsumeBase(Rec, Result);
    end;

    procedure InitQtyToConsume()
    var
        IsHandled: Boolean;
    begin
        "Qty. to Consume" := MaxQtyToConsume();
        "Qty. to Consume (Base)" := MaxQtyToConsumeBase();
        IsHandled := false;
        OnAfterInitQtyToConsume(Rec, CurrFieldNo, IsHandled);
        if not IsHandled then
            InitQtyToInvoice();
    end;

    procedure SetServHeader(NewServHeader: Record "Service Header")
    begin
        ServHeader := NewServHeader;

        if ServHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            ServHeader.TestField("Currency Factor");
            Currency.Get(ServHeader."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    procedure SetServiceItemLine(var NewServiceItemLine: Record "Service Item Line")
    begin
        ServItemLine := NewServiceItemLine;
    end;

    procedure CalcVATAmountLines(QtyType: Option General,Invoicing,Shipping,Consuming; var ServHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line"; isShip: Boolean)
    var
        Currency: Record Currency;
        QtyFactor: Decimal;
        TotalVATAmount: Decimal;
        RoundingLineInserted: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnUpdateCalcVATAmountLines(ServHeader, ServiceLine, VATAmountLine, QtyType, isShip, IsHandled);
        if IsHandled then
            exit;

        Currency.Initialize(ServHeader."Currency Code");

        VATAmountLine.DeleteAll();

        ServiceLine.SetRange("Document Type", ServHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServHeader."No.");
        ServiceLine.SetFilter(Type, '>0');
        ServiceLine.SetFilter(Quantity, '<>0');
        OnCalcVATAmountLinesOnAfterServiceLineSetFilters(ServiceLine, ServHeader);
        if ServiceLine.FindSet() then
            repeat
                if ServiceLine.Type = ServiceLine.Type::"G/L Account" then
                    RoundingLineInserted := (ServiceLine."No." = ServiceLine.GetCPGInvRoundAcc(ServHeader)) or RoundingLineInserted;
                if ServiceLine."VAT Calculation Type" in
                   [ServiceLine."VAT Calculation Type"::"Reverse Charge VAT", ServiceLine."VAT Calculation Type"::"Sales Tax"]
                then
                    ClearVATPct();

                if not FindVATAmountLine(ServiceLine, VATAmountLine) then
                    InsertVATAmountLine(ServiceLine, VATAmountLine);

                QtyFactor := 0;
                case QtyType of
                    QtyType::Invoicing:
                        begin
                            case true of
                                (ServiceLine."Document Type" in [ServiceLine."Document Type"::Order, ServiceLine."Document Type"::Invoice]) and not isShip:
                                    begin
                                        if ServiceLine.CalcChargeableQty() <> 0 then
                                            QtyFactor := GetAbsMin(ServiceLine."Qty. to Invoice", ServiceLine."Qty. Shipped Not Invoiced") / ServiceLine.CalcChargeableQty();
                                        VATAmountLine.Quantity :=
                                          VATAmountLine.Quantity + GetAbsMin(ServiceLine."Qty. to Invoice (Base)", ServiceLine."Qty. Shipped Not Invd. (Base)");
                                    end;
                                ServiceLine."Document Type" in [ServiceLine."Document Type"::"Credit Memo"]:
                                    begin
                                        QtyFactor := GetAbsMin(ServiceLine."Qty. to Invoice", ServiceLine.Quantity) / ServiceLine.Quantity;
                                        VATAmountLine.Quantity += GetAbsMin(ServiceLine."Qty. to Invoice (Base)", ServiceLine."Quantity (Base)");
                                    end;
                                else begin
                                    if ServiceLine.CalcChargeableQty() <> 0 then
                                        QtyFactor := ServiceLine."Qty. to Invoice" / ServiceLine.CalcChargeableQty();
                                    VATAmountLine.Quantity += ServiceLine."Qty. to Invoice (Base)";
                                end;
                            end;
                            VATAmountLine."Line Amount" += Round(ServiceLine."Line Amount" * QtyFactor, Currency."Amount Rounding Precision");
                            if ServiceLine."Allow Invoice Disc." then
                                VATAmountLine."Inv. Disc. Base Amount" += Round(ServiceLine."Line Amount" * QtyFactor, Currency."Amount Rounding Precision");
                            VATAmountLine."Invoice Discount Amount" += ServiceLine."Inv. Disc. Amount to Invoice";
                            VATAmountLine."Pmt. Discount Amount" +=
                              Round(ServiceLine."Pmt. Discount Amount" * QtyFactor, Currency."Amount Rounding Precision");
                            VATAmountLine."VAT Difference" += ServiceLine."VAT Difference";
                            OnCalcVATAmountLinesOnBeforeVATAmountLineModifyInvoicing(ServiceLine, VATAmountLine);
                            VATAmountLine.Modify();
                        end;
                    QtyType::Shipping:
                        begin
                            if ServiceLine."Document Type" in
                               [ServiceLine."Document Type"::"Credit Memo"]
                            then begin
                                QtyFactor := 1;
                                VATAmountLine.Quantity += ServiceLine."Quantity (Base)";
                            end else begin
                                QtyFactor := ServiceLine."Qty. to Ship" / ServiceLine.Quantity;
                                VATAmountLine.Quantity += ServiceLine."Qty. to Ship (Base)";
                            end;
                            VATAmountLine."Line Amount" += Round(ServiceLine."Line Amount" * QtyFactor, Currency."Amount Rounding Precision");
                            if ServiceLine."Allow Invoice Disc." then
                                VATAmountLine."Inv. Disc. Base Amount" += Round(ServiceLine."Line Amount" * QtyFactor, Currency."Amount Rounding Precision");
                            VATAmountLine."Invoice Discount Amount" +=
                              Round(ServiceLine."Inv. Discount Amount" * QtyFactor, Currency."Amount Rounding Precision");
                            VATAmountLine."Pmt. Discount Amount" += ServiceLine."Pmt. Discount Amount";
                            VATAmountLine."VAT Difference" += ServiceLine."VAT Difference";
                            OnCalcVATAmountLinesOnBeforeVATAmountLineModifyShipping(ServiceLine, VATAmountLine);
                            VATAmountLine.Modify();
                        end;
                    QtyType::Consuming:
                        case true of
                            (ServiceLine."Document Type" = ServiceLine."Document Type"::Order) and not isShip:
                                begin
                                    QtyFactor := GetAbsMin(ServiceLine."Qty. to Consume", ServiceLine."Qty. Shipped Not Invoiced") / ServiceLine.Quantity;
                                    VATAmountLine.Quantity += GetAbsMin(ServiceLine."Qty. to Consume (Base)", ServiceLine."Qty. Shipped Not Invd. (Base)");
                                end;
                            else begin
                                QtyFactor := ServiceLine."Qty. to Consume" / ServiceLine.Quantity;
                                VATAmountLine.Quantity += ServiceLine."Qty. to Consume (Base)";
                            end;
                        end;
                    else begin
                        VATAmountLine.Quantity += ServiceLine."Quantity (Base)";
                        VATAmountLine."Line Amount" += ServiceLine."Line Amount";
                        if ServiceLine."Allow Invoice Disc." then
                            VATAmountLine."Inv. Disc. Base Amount" += ServiceLine."Line Amount";
                        VATAmountLine."Invoice Discount Amount" += ServiceLine."Inv. Discount Amount";
                        VATAmountLine."Pmt. Discount Amount" += ServiceLine."Pmt. Discount Amount";
                        VATAmountLine."VAT Difference" += ServiceLine."VAT Difference";
                        OnCalcVATAmountLinesOnBeforeVATAmountLineModifyElseCase(ServiceLine, VATAmountLine);
                        VATAmountLine.Modify();
                    end;
                end;
                TotalVATAmount += ServiceLine."Amount Including VAT" - ServiceLine.Amount + ServiceLine."VAT Difference";
                OnCalcVATAmountLinesOnAfterCalcLineTotals(VATAmountLine, ServHeader, ServiceLine, Currency, QtyType, TotalVATAmount);
            until ServiceLine.Next() = 0;
        VATAmountLine.Reset();
        ServiceLine.SetRange(Type);
        ServiceLine.SetRange(Quantity);

        IsHandled := false;
        OnCalcVATAmountLinesOnBeforeUpdateLines(TotalVATAmount, Currency, ServHeader, VATAmountLine, IsHandled);
        if not IsHandled then
            VATAmountLine.UpdateLines(
                TotalVATAmount, Currency, ServHeader."Currency Factor", ServHeader."Prices Including VAT", ServHeader."VAT Base Discount %",
                ServHeader."Tax Area Code", ServHeader."Tax Liable", ServHeader."Posting Date");

        OnCalcVATAmountLinesOnBeforeUpdateVATAmountLine(ServiceLine, VATAmountLine, TotalVATAmount, Currency, RoundingLineInserted);

        if RoundingLineInserted and (TotalVATAmount <> 0) then
            if FindVATAmountLine(ServiceLine, VATAmountLine) then begin
                VATAmountLine."VAT Amount" := VATAmountLine."VAT Amount" + TotalVATAmount;
                VATAmountLine."Amount Including VAT" := VATAmountLine."Amount Including VAT" + TotalVATAmount;
                VATAmountLine."Calculated VAT Amount" := VATAmountLine."Calculated VAT Amount" + TotalVATAmount;
                VATAmountLine.Modify();
            end;

        OnAfterCalcVATAmountLines(ServHeader, ServiceLine, VATAmountLine, QtyType);
    end;

    local procedure FindVATAmountLine(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line"): Boolean
    begin
        VATAmountLine.Reset();
        VATAmountLine.SetRange("VAT Identifier", ServiceLine."VAT Identifier");
        VATAmountLine.SetRange("VAT Calculation Type", ServiceLine."VAT Calculation Type");
        VATAmountLine.SetRange("Tax Group Code", ServiceLine."Tax Group Code");
        VATAmountLine.SetRange("Use Tax", false);
        VATAmountLine.SetRange(Positive, ServiceLine."Line Amount" >= 0);
        OnFindVATAmountLineOnAfterSetFilters(ServiceLine, VATAmountLine);
        exit(VATAmountLine.FindFirst());
    end;

    local procedure InsertVATAmountLine(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
        VATAmountLine.Init();
        VATAmountLine."VAT Identifier" := ServiceLine."VAT Identifier";
        VATAmountLine."VAT Calculation Type" := ServiceLine."VAT Calculation Type";
        VATAmountLine."Tax Group Code" := ServiceLine."Tax Group Code";
        VATAmountLine."Use Tax" := false;
        VATAmountLine."VAT %" := ServiceLine."VAT %";
        VATAmountLine.Modified := true;
        VATAmountLine.Positive := ServiceLine."Line Amount" >= 0;
        VATAmountLine."Includes Prepayment" := false;
        VATAmountLine."Non-Deductible VAT %" := 0;
        OnInsertVATAmountOnBeforeInsert(ServiceLine, VATAmountLine);
        VATAmountLine.Insert();
    end;

    local procedure GetAbsMin(QTyToHandle: Decimal; QtyHandled: Decimal): Decimal
    begin
        if QtyHandled = 0 then
            exit(QTyToHandle);
        if Abs(QtyHandled) < Abs(QTyToHandle) then
            exit(QtyHandled);

        exit(QTyToHandle);
    end;

    procedure UpdateVATOnLines(QtyType: Option General,Invoicing,Shipping; var ServHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line")
    var
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        NewAmount: Decimal;
        NewAmountIncludingVAT: Decimal;
        NewVATBaseAmount: Decimal;
        VATAmount: Decimal;
        VATDifference: Decimal;
        InvDiscAmount: Decimal;
        LineAmountToInvoice: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateVATOnLines(Rec, xRec, ServHeader, VATAmountLine, QtyType, IsHandled);
        if IsHandled then
            exit;

        if QtyType = QtyType::Shipping then
            exit;

        Currency.Initialize(ServHeader."Currency Code");

        TempVATAmountLineRemainder.DeleteAll();

        ServiceLine.SetRange("Document Type", ServHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServHeader."No.");
        ServiceLine.SetFilter(Type, '>0');
        ServiceLine.SetFilter(Quantity, '<>0');
        case QtyType of
            QtyType::Invoicing:
                ServiceLine.SetFilter("Qty. to Invoice", '<>0');
            QtyType::Shipping:
                ServiceLine.SetFilter("Qty. to Ship", '<>0');
        end;
        ServiceLine.LockTable();
        if ServiceLine.Find('-') then
            repeat
                FindVATAmountLine(ServiceLine, VATAmountLine);
                if VATAmountLine.Modified then begin
                    if not FindVATAmountLine(ServiceLine, TempVATAmountLineRemainder) then begin
                        TempVATAmountLineRemainder := VATAmountLine;
                        TempVATAmountLineRemainder.Init();
                        TempVATAmountLineRemainder.Insert();
                    end;

                    if QtyType = QtyType::General then
                        LineAmountToInvoice := ServiceLine."Line Amount"
                    else
                        LineAmountToInvoice :=
                          Round(ServiceLine."Line Amount" * ServiceLine."Qty. to Invoice" / ServiceLine.CalcChargeableQty(), Currency."Amount Rounding Precision");

                    if ServiceLine."Allow Invoice Disc." then begin
                        if VATAmountLine."Inv. Disc. Base Amount" = 0 then
                            InvDiscAmount := 0
                        else begin
                            TempVATAmountLineRemainder."Invoice Discount Amount" +=
                              VATAmountLine."Invoice Discount Amount" * LineAmountToInvoice / VATAmountLine."Inv. Disc. Base Amount";
                            InvDiscAmount :=
                              Round(
                                TempVATAmountLineRemainder."Invoice Discount Amount", Currency."Amount Rounding Precision");
                            TempVATAmountLineRemainder."Invoice Discount Amount" -= InvDiscAmount;
                        end;
                        if QtyType = QtyType::General then begin
                            ServiceLine."Inv. Discount Amount" := InvDiscAmount;
                            CalcInvDiscToInvoice();
                        end else
                            ServiceLine."Inv. Disc. Amount to Invoice" := InvDiscAmount;
                    end else
                        InvDiscAmount := 0;

                    if QtyType = QtyType::General then
                        if ServHeader."Prices Including VAT" then begin
                            if (VATAmountLine.CalcLineAmount() = 0) or (ServiceLine."Line Amount" = 0) then begin
                                VATAmount := 0;
                                NewAmountIncludingVAT := 0;
                            end else begin
                                VATAmount := CalcVATAmount(TempVATAmountLineRemainder, VATAmountLine, ServiceLine.CalcLineAmount(), VATAmountLine.CalcLineAmount());
                                NewAmountIncludingVAT :=
                                  TempVATAmountLineRemainder."Amount Including VAT" +
                                  VATAmountLine."Amount Including VAT" * ServiceLine.CalcLineAmount() / VATAmountLine.CalcLineAmount();
                            end;
                            NewAmount :=
                              Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision") -
                              Round(VATAmount, Currency."Amount Rounding Precision");
                            NewVATBaseAmount :=
                              Round(
                                NewAmount * (1 - GetVatBaseDiscountPct(ServHeader) / 100),
                                Currency."Amount Rounding Precision");
                            OnUpdateVATOnLinesOnAfterSetNewVATBaseAmountPriceInclVAT(ServiceLine, ServHeader, VATAmountLine, TempVATAmountLineRemainder, NewAmount, NewVATBaseAmount);
                        end else begin
                            if ServiceLine."VAT Calculation Type" = ServiceLine."VAT Calculation Type"::"Full VAT" then begin
                                VATAmount := ServiceLine.CalcLineAmount() - ServiceLine."Pmt. Discount Amount";
                                NewAmount := 0;
                                NewVATBaseAmount := 0;
                            end else begin
                                NewAmount := ServiceLine.CalcLineAmount() - ServiceLine."Pmt. Discount Amount";
                                NewVATBaseAmount :=
                                  Round(
                                    NewAmount * (1 - GetVatBaseDiscountPct(ServHeader) / 100),
                                    Currency."Amount Rounding Precision");
                                OnUpdateVATOnLinesOnAfterSetNewVATBaseAmountPriceExclVAT(ServiceLine, ServHeader, VATAmountLine, TempVATAmountLineRemainder, NewAmount, NewVATBaseAmount);
                                if VATAmountLine."VAT Base" = 0 then
                                    VATAmount := 0
                                else
                                    VATAmount := CalcVATAmount(TempVATAmountLineRemainder, VATAmountLine, NewAmount, VATAmountLine."VAT Base");
                            end;
                            NewAmountIncludingVAT := NewAmount + Round(VATAmount, Currency."Amount Rounding Precision");
                        end
                    else begin
                        if VATAmountLine.CalcLineAmount() = 0 then
                            ClearVATDifference()
                        else
                            CalcVATDifference(TempVATAmountLineRemainder, VATAmountLine, LineAmountToInvoice - InvDiscAmount, VATDifference);
                        if LineAmountToInvoice = 0 then
                            ServiceLine.ClearVATDifference()
                        else
                            ServiceLine.RoundVATDifference(VATDifference, Currency);
                    end;

                    if QtyType = QtyType::General then begin
                        ServiceLine.Amount := NewAmount;
                        ServiceLine."Amount Including VAT" := Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                        ServiceLine."VAT Base Amount" := NewVATBaseAmount;
                        OnUpdateVATOnLinesOnAfterSetVATBaseAmountGeneral(ServiceLine, VATAmountLine, Currency, NewVATBaseAmount);
                    end;
                    ServiceLine.InitOutstanding();
                    ServiceLine.Modify();

                    TempVATAmountLineRemainder."Amount Including VAT" :=
                      NewAmountIncludingVAT - Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                    TempVATAmountLineRemainder."VAT Amount" := VATAmount - NewAmountIncludingVAT + NewAmount;
                    TempVATAmountLineRemainder."VAT Difference" := VATDifference - ServiceLine."VAT Difference";
                    OnUpdateVATOnLinesOnBeforeTempVATAmountLineRemainderModify(TempVATAmountLineRemainder, ServiceLine, NewVATBaseAmount);
                    TempVATAmountLineRemainder.Modify();
                end;
            until ServiceLine.Next() = 0;
        VATAmountLine.Reset();
        ServiceLine.SetRange(Type);
        ServiceLine.SetRange(Quantity);
        ServiceLine.SetRange("Qty. to Invoice");
        ServiceLine.SetRange("Qty. to Ship");

        OnAfterUpdateVATOnLines(ServHeader, ServiceLine, VATAmountLine, QtyType);
    end;

    local procedure CalcVATAmount(var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; VATAmountLine: Record "VAT Amount Line"; NewAmount: Decimal; NewBase: Decimal) VATAmount: Decimal
    begin
        VATAmount :=
            TempVATAmountLineRemainder."VAT Amount" + VATAmountLine."VAT Amount" * NewAmount / NewBase;

        OnAfterCalcVATAmount(VATAmountLine, NewAmount, NewBase, VATAmount);
    end;

    local procedure CalcUnitCost(ItemLedgEntry: Record "Item Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
        UnitCost: Decimal;
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
        UnitCost :=
          (ValueEntry."Cost Amount (Expected)" + ValueEntry."Cost Amount (Actual)") / ItemLedgEntry.Quantity;

        exit(Abs(UnitCost * "Qty. per Unit of Measure"));
    end;

    local procedure SelectItemEntry(CurrentFieldNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ServLine3: Record "Service Line";
    begin
        ItemLedgEntry.SetRange("Item No.", "No.");
        if "Location Code" <> '' then
            ItemLedgEntry.SetRange("Location Code", "Location Code");
        ItemLedgEntry.SetRange("Variant Code", "Variant Code");

        if CurrentFieldNo = FieldNo("Appl.-to Item Entry") then begin
            ItemLedgEntry.SetCurrentKey("Item No.", Open);
            ItemLedgEntry.SetRange(Positive, true);
            ItemLedgEntry.SetRange(Open, true);
        end else begin
            ItemLedgEntry.SetCurrentKey("Item No.", Positive);
            ItemLedgEntry.SetRange(Positive, false);
        end;
        if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then begin
            ServLine3 := Rec;
            if CurrentFieldNo = FieldNo("Appl.-to Item Entry") then
                ServLine3.Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No.")
            else
                ServLine3.Validate("Appl.-from Item Entry", ItemLedgEntry."Entry No.");
            CheckItemAvailable(CurrentFieldNo);
            Rec := ServLine3;
        end;
    end;

    procedure CalcChargeableQty() ChargableQty: Decimal
    begin
        ChargableQty := Quantity - "Quantity Consumed" - "Qty. to Consume";
        OnAfterCalcChargeableQty(Rec, ChargableQty);
        exit(ChargableQty);
    end;

    procedure SignedXX(Value: Decimal): Decimal
    begin
        case "Document Type" of
            "Document Type"::Quote,
          "Document Type"::Order,
          "Document Type"::Invoice:
                exit(-Value);
            "Document Type"::"Credit Memo":
                exit(Value);
        end;
    end;

    procedure IsShipment(): Boolean
    begin
        exit(SignedXX("Quantity (Base)") < 0);
    end;

    local procedure AdjustMaxLabourUnitPrice(ResUnitPrice: Decimal)
    var
        Res: Record Resource;
    begin
        if Type <> Type::Resource then
            exit;
        if (ResUnitPrice > ServHeader."Max. Labor Unit Price") and
           (ServHeader."Max. Labor Unit Price" <> 0)
        then begin
            Res.Get("No.");
            "Unit Price" := ServHeader."Max. Labor Unit Price";
            Message(
              StrSubstNo(
                Text018,
                Res.TableCaption(), FieldCaption("Unit Price"),
                ServHeader.FieldCaption("Max. Labor Unit Price"),
                ServHeader."Max. Labor Unit Price"));
        end
    end;

    procedure CheckLineDiscount(LineDisc: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLineDiscount(Rec, LineDisc, IsHandled);
        if IsHandled then
            exit;

        if ("Line Discount Type" = "Line Discount Type"::"Contract Disc.") and
           ("Contract No." <> '') and not "Exclude Contract Discount" and
           not ("Document Type" = "Document Type"::Invoice)
        then
            Error(Text043, FieldCaption("Line Discount %"), FieldCaption("Line Discount Type"), "Line Discount Type");

        if (LineDisc < "Warranty Disc. %") and
           Warranty and not "Exclude Warranty"
        then
            Error(Text010, FieldCaption("Line Discount %"), FieldCaption("Warranty Disc. %"));

        if "Line Discount %" <> 0 then
            "Line Discount Type" := "Line Discount Type"::Manual
        else
            "Line Discount Type" := "Line Discount Type"::" ";
    end;

    procedure ConfirmAdjPriceLineChange()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmAdjPriceLineChange(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Price Adjmt. Status" = "Price Adjmt. Status"::Adjusted then
            if ConfirmManagement.GetResponseOrDefault(Text033 + Text034, true) then
                "Price Adjmt. Status" := "Price Adjmt. Status"::Modified
            else
                Error('');
    end;

    procedure SetHideCostWarning(Value: Boolean)
    begin
        HideCostWarning := Value;
        OnAfterSetHideCostWarning(Rec, HideCostWarning);
    end;

    local procedure CheckApplFromItemLedgEntry(var ItemLedgEntry: Record "Item Ledger Entry")
    var
        QtyBase: Decimal;
        ShippedQtyNotReturned: Decimal;
    begin
        if "Appl.-from Item Entry" = 0 then
            exit;

        TestField(Type, Type::Item);
        TestField(Quantity);
        if "Document Type" in ["Document Type"::"Credit Memo"] then begin
            if Quantity < 0 then
                FieldError(Quantity, Text029);
        end else
            if Quantity > 0 then
                FieldError(Quantity, Text030);

        ItemLedgEntry.Get("Appl.-from Item Entry");
        ItemLedgEntry.TestField(Positive, false);
        ItemLedgEntry.TestField("Item No.", "No.");
        ItemLedgEntry.TestField("Variant Code", "Variant Code");
        ItemLedgEntry.CheckTrackingDoesNotExist(RecordId, FieldCaption("Appl.-from Item Entry"));

        if "Document Type" in ["Document Type"::"Credit Memo"] then
            QtyBase := "Quantity (Base)"
        else
            QtyBase := "Qty. to Ship (Base)";

        if Abs(QtyBase) > -ItemLedgEntry."Shipped Qty. Not Returned" then begin
            if "Qty. per Unit of Measure" = 0 then
                ShippedQtyNotReturned := ItemLedgEntry."Shipped Qty. Not Returned"
            else
                ShippedQtyNotReturned :=
                  Round(ItemLedgEntry."Shipped Qty. Not Returned" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
            Error(
              Text039,
              -ShippedQtyNotReturned, ItemLedgEntry.TableCaption(), ItemLedgEntry."Entry No.");
        end;

        OnAfterCheckApplFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    procedure SetHideWarrantyWarning(Value: Boolean)
    begin
        HideWarrantyWarning := Value;
        OnAfterSetHideWarrantyWarning(rec, HideWarrantyWarning);
    end;

    procedure SplitResourceLine()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        SumQty: Decimal;
        Qty: Decimal;
        TempDiscount: Decimal;
        NoOfServItems: Integer;
        NextLine: Integer;
    begin
        TestField(Type, Type::Resource);
        TestField("No.");
        TestField("Service Item Line No.");
        TestField(Quantity);
        TestField("Quantity Shipped", 0);

        ServItemLine.Reset();
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "Document No.");
        NoOfServItems := ServItemLine.Count();
        if NoOfServItems <= 1 then
            Error(Text041);

        if ConfirmManagement.GetResponseOrDefault(Text044, true) then begin
            ServiceLine.Reset();
            ServiceLine.SetRange("Document Type", "Document Type");
            ServiceLine.SetRange("Document No.", "Document No.");
            if ServiceLine.FindLast() then
                NextLine := ServiceLine."Line No." + 10000
            else
                NextLine := 10000;

            Qty := Round(Quantity / NoOfServItems, 0.01);
            if ServItemLine.Find('-') then
                repeat
                    if ServItemLine."Line No." <> "Service Item Line No." then begin
                        Clear(ServiceLine);
                        ServiceLine.Init();
                        ServiceLine."Document Type" := "Document Type";
                        ServiceLine."Document No." := "Document No.";
                        ServiceLine."Line No." := NextLine;
                        ServiceLine.Insert(true);
                        ServiceLine.TransferFields(Rec, false);
                        ServiceLine.Validate("Service Item Line No.", ServItemLine."Line No.");
                        ServiceLine.Validate("No.");

                        ServiceLine.Validate(Quantity, Qty);
                        SumQty := SumQty + Qty;
                        if "Qty. to Consume" > 0 then
                            ServiceLine.Validate("Qty. to Consume", Qty);

                        ServiceLine.Validate("Contract No.", ServItemLine."Contract No.");
                        if not ServiceLine."Exclude Warranty" then
                            ServiceLine.Validate(Warranty, ServItemLine.Warranty);

                        TempDiscount := "Line Discount %" - "Contract Disc. %" - "Warranty Disc. %";
                        if TempDiscount > 0 then begin
                            ServiceLine."Line Discount %" := ServiceLine."Line Discount %" + TempDiscount;
                            if ServiceLine."Line Discount %" > 100 then
                                ServiceLine."Line Discount %" := 100;
                            ServiceLine.Validate("Line Discount %");
                        end;

                        ServiceLine.Modify(true);
                        NextLine := NextLine + 10000;
                    end;
                until ServItemLine.Next() = 0;

            if ServiceLine.Get("Document Type", "Document No.", "Line No.") then begin
                if "Qty. to Consume" > 0 then
                    ServiceLine.Validate("Qty. to Consume", Quantity - SumQty);
                ServiceLine.Validate(Quantity, Quantity - SumQty);
                ServiceLine.Modify(true);
            end;
        end;
    end;

    local procedure UpdateDiscountsAmounts()
    begin
        if Type <> Type::" " then begin
            TestField("Qty. per Unit of Measure");
            CalculateDiscount();
            Validate("Unit Price");
        end;
    end;

    procedure UpdateRemainingCostsAndAmounts()
    var
        TotalPrice: Decimal;
        AmountRoundingPrecision: Decimal;
        AmountRoundingPrecisionFCY: Decimal;
    begin
        if "Job Remaining Qty." <> 0 then begin
            Clear(Currency);
            Currency.InitRoundingPrecision();
            AmountRoundingPrecision := Currency."Amount Rounding Precision";
            GetServHeader();
            AmountRoundingPrecisionFCY := Currency."Amount Rounding Precision";

            "Job Remaining Total Cost" := Round("Unit Cost" * "Job Remaining Qty.", AmountRoundingPrecisionFCY);
            "Job Remaining Total Cost (LCY)" := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  GetDate(), "Currency Code",
                  "Job Remaining Total Cost", ServHeader."Currency Factor"),
                AmountRoundingPrecision);

            TotalPrice := Round("Job Remaining Qty." * "Unit Price", AmountRoundingPrecisionFCY);
            "Job Remaining Line Amount" := TotalPrice - Round(TotalPrice * "Line Discount %" / 100, AmountRoundingPrecisionFCY);
        end else begin
            "Job Remaining Total Cost" := 0;
            "Job Remaining Total Cost (LCY)" := 0;
            "Job Remaining Line Amount" := 0;
        end;
    end;

    local procedure UpdateServDocRegister(DeleteRecord: Boolean)
    var
        ServiceLine2: Record "Service Line";
        ServDocReg: Record "Service Document Register";
    begin
        ServiceLine2.Reset();
        ServiceLine2.SetRange("Document Type", "Document Type");
        ServiceLine2.SetRange("Document No.", "Document No.");
        if DeleteRecord then
            ServiceLine2.SetRange("Contract No.", "Contract No.")
        else
            ServiceLine2.SetRange("Contract No.", xRec."Contract No.");
        ServiceLine2.SetFilter("Line No.", '<>%1', "Line No.");

        if ServiceLine2.IsEmpty() then
            if xRec."Contract No." <> '' then begin
                ServDocReg.Reset();
                if "Document Type" = "Document Type"::Invoice then
                    ServDocReg.SetRange("Destination Document Type", ServDocReg."Destination Document Type"::Invoice)
                else
                    if "Document Type" = "Document Type"::"Credit Memo" then
                        ServDocReg.SetRange("Destination Document Type", ServDocReg."Destination Document Type"::"Credit Memo");
                ServDocReg.SetRange("Destination Document No.", "Document No.");
                ServDocReg.SetRange("Source Document Type", ServDocReg."Source Document Type"::Contract);
                ServDocReg.SetRange("Source Document No.", xRec."Contract No.");
                ServDocReg.DeleteAll();
            end;

        if ("Contract No." <> '') and (Type <> Type::" ") and not DeleteRecord then
            if "Document Type" = "Document Type"::Invoice then
                ServDocReg.InsertServiceSalesDocument(
                  ServDocReg."Source Document Type"::Contract, "Contract No.",
                  ServDocReg."Destination Document Type"::Invoice, "Document No.")
            else
                if "Document Type" = "Document Type"::"Credit Memo" then
                    ServDocReg.InsertServiceSalesDocument(
                      ServDocReg."Source Document Type"::Contract, "Contract No.",
                      ServDocReg."Destination Document Type"::"Credit Memo", "Document No.");
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
            ItemTrackingMgt.ComposeRowID(
                DATABASE::"Service Line", "Document Type".AsInteger(), "Document No.", '', 0, "Line No."));
    end;

    procedure UpdatePlanned(): Boolean
    begin
        CalcFields("Reserved Quantity");
        if Planned = ("Reserved Quantity" = "Outstanding Quantity") then
            exit(false);
        Planned := not Planned;
        exit(true);
    end;

    procedure UpdateReservation(CalledByFieldNo: Integer)
    begin
        if (CurrFieldNo <> CalledByFieldNo) and (CurrFieldNo <> 0) then
            exit;

        case CalledByFieldNo of
            FieldNo("Needed by Date"), FieldNo("Planned Delivery Date"):
                if (xRec."Needed by Date" <> "Needed by Date") and
                   (Quantity <> 0) and
                   (Reserve <> Reserve::Never)
                then
                    ServiceLineReserve.ServiceInvLineCheck(Rec, true);
            FieldNo(Quantity):
                ServiceLineReserve.VerifyQuantity(Rec, xRec);
        end;
        ServiceLineReserve.VerifyChange(Rec, xRec);
        UpdatePlanned();
    end;

    procedure ShowTracking()
    var
        OrderTracking: Page "Order Tracking";
    begin
        OrderTracking.SetVariantRec(Rec, Rec."No.", Rec."Outstanding Qty. (Base)", Rec."Needed by Date", Rec."Needed by Date");
        OrderTracking.RunModal();
    end;

    procedure ShowOrderPromisingLine()
    var
        OrderPromisingLine: Record "Order Promising Line";
        OrderPromisingLines: Page "Order Promising Lines";
    begin
        OrderPromisingLine.SetRange("Source Type", OrderPromisingLine."Source Type"::"Service Order");
        OrderPromisingLine.SetRange("Source Type", OrderPromisingLine."Source Type"::"Service Order");
        OrderPromisingLine.SetRange("Source ID", "Document No.");
        OrderPromisingLine.SetRange("Source Line No.", "Line No.");

        OrderPromisingLines.SetSource(OrderPromisingLine."Source Type"::"Service Order");
        OrderPromisingLines.SetTableView(OrderPromisingLine);
        OrderPromisingLines.RunModal();
    end;

    procedure FilterLinesWithItemToPlan(var Item: Record Item)
    begin
        Reset();
        SetCurrentKey(Type, "No.", "Variant Code", "Location Code", "Needed by Date", "Document Type");
        SetRange("Document Type", "Document Type"::Order);
        SetRange(Type, Type::Item);
        SetRange("No.", Item."No.");
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        SetFilter("Location Code", Item.GetFilter("Location Filter"));
        SetFilter("Needed by Date", Item.GetFilter("Date Filter"));
        SetFilter("Shortcut Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        SetFilter("Shortcut Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        SetFilter("Outstanding Qty. (Base)", '<>0');
        SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));

        OnAfterFilterLinesWithItemToPlan(Rec, Item);
    end;

    procedure FindLinesWithItemToPlan(var Item: Record Item): Boolean
    begin
        FilterLinesWithItemToPlan(Item);
        exit(Find('-'));
    end;

    procedure LinesWithItemToPlanExist(var Item: Record Item): Boolean
    begin
        FilterLinesWithItemToPlan(Item);
        exit(not IsEmpty);
    end;

    procedure FindLinesForReservation(ReservationEntry: Record "Reservation Entry"; AvailabilityFilter: Text; Positive: Boolean)
    begin
        Reset();
        SetCurrentKey(Type, "No.", "Variant Code", "Location Code", "Needed by Date", "Document Type");
        SetRange(Type, Type::Item);
        SetRange("No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Location Code", ReservationEntry."Location Code");
        SetFilter("Needed by Date", AvailabilityFilter);
        if Positive then
            SetFilter("Quantity (Base)", '<0')
        else
            SetFilter("Quantity (Base)", '>0');
        SetRange("Job No.", ' ');
        OnAfterFindLinesForReservation(Rec, ReservationEntry, AvailabilityFilter, Positive);
    end;

    local procedure UpdateServiceLedgerEntry()
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        LCYRoundingPrecision: Decimal;
        CurrencyFactor: Decimal;
    begin
        if "Appl.-to Service Entry" = 0 then
            exit;
        if not ServiceLedgerEntry.Get("Appl.-to Service Entry") then
            exit;
        if ("Unit Price" = xRec."Unit Price") and ("Unit Cost" = xRec."Unit Cost") and (Amount = xRec.Amount) and
           ("Line Discount Amount" = xRec."Line Discount Amount") and ("Line Discount %" = xRec."Line Discount %")
        then
            exit;

        CurrencyFactor := 1;
        if "Currency Code" <> '' then begin
            CurrencyExchangeRate.SetRange("Currency Code", "Currency Code");
            CurrencyExchangeRate.SetRange("Starting Date", 0D, "Order Date");
            if CurrencyExchangeRate.FindLast() then
                CurrencyFactor := CurrencyExchangeRate."Adjustment Exch. Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount";
        end;
        GeneralLedgerSetup.Get();
        LCYRoundingPrecision := 0.01;
        if Currency.Get(GeneralLedgerSetup."LCY Code") then
            LCYRoundingPrecision := Currency."Amount Rounding Precision";

        if "Unit Price" <> xRec."Unit Price" then
            ServiceLedgerEntry."Unit Price" := -Round("Unit Price" / CurrencyFactor, LCYRoundingPrecision);
        if "Unit Cost (LCY)" <> xRec."Unit Cost (LCY)" then
            ServiceLedgerEntry."Unit Cost" := "Unit Cost (LCY)";
        if Amount <> xRec.Amount then begin
            ServiceLedgerEntry.Amount := -Amount;
            ServiceLedgerEntry."Amount (LCY)" := -Round(Amount / CurrencyFactor, LCYRoundingPrecision);
        end;
        if "Line Discount Amount" <> xRec."Line Discount Amount" then
            ServiceLedgerEntry."Discount Amount" := Round("Line Discount Amount" / CurrencyFactor, LCYRoundingPrecision);
        if "Line Discount %" <> xRec."Line Discount %" then
            ServiceLedgerEntry."Discount %" := "Line Discount %";
        ServiceLedgerEntry.Modify();
    end;

    local procedure ValidateServiceItemLineNumber(var ServiceLine: Record "Service Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateServiceItemLineNumber(Rec, IsHandled);
        if IsHandled then
            exit;

        Validate("Service Item Line No.", ServiceLine."Service Item Line No.");

        OnAfterValidateServiceItemLineNumber(Rec, ServiceLine);
    end;

    local procedure ValidateQuantityInvIsBalanced()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQuantityInvIsBalanced(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        UOMMgt.ValidateQtyIsBalanced(Quantity, "Quantity (Base)", "Qty. to Invoice", "Qty. to Invoice (Base)", "Quantity Invoiced", "Qty. Invoiced (Base)");
    end;

    local procedure ValidateQuantityShipIsBalanced()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQuantityShipIsBalanced(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        UOMMgt.ValidateQtyIsBalanced(Quantity, "Quantity (Base)", "Qty. to Ship", "Qty. to Ship (Base)", "Quantity Shipped", "Qty. Shipped (Base)");
    end;

    local procedure ValidateQuantityConsumeIsBalanced()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQuantityConsumeIsBalanced(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        UOMMgt.ValidateQtyIsBalanced(Quantity, "Quantity (Base)", "Qty. to Consume", "Qty. to Consume (Base)", "Quantity Consumed", "Qty. Consumed (Base)");
    end;

    procedure UpdateWithWarehouseShip()
    var
        IsHandled: Boolean;
    begin
        if Type <> Type::Item then
            exit;

        IsHandled := false;
        OnBeforeUpdateWithWarehouseShipOnAfterVerifyType(Rec, IsHandled);

        if IsHandled then
            exit;

        if "Document Type" in ["Document Type"::Quote, "Document Type"::Order] then
            if Location.RequireShipment("Location Code") then begin
                Validate("Qty. to Ship", 0);
                Validate("Qty. to Invoice", 0);
            end else
                Validate("Qty. to Ship", "Outstanding Quantity");
    end;

    local procedure CheckWarehouse()
    var
        Location2: Record Location;
        WhseSetup: Record "Warehouse Setup";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ShowDialog: Option " ",Message,Error;
        DialogText: Text[100];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWarehouse(Rec, IsHandled);
        if IsHandled then
            exit;

        GetLocation("Location Code");
        if "Location Code" = '' then begin
            WhseSetup.Get();
            Location2."Require Shipment" := WhseSetup."Require Shipment";
            Location2."Require Pick" := WhseSetup."Require Pick";
            Location2."Require Receive" := WhseSetup."Require Receive";
            Location2."Require Put-away" := WhseSetup."Require Put-away";
        end else
            Location2 := Location;

        DialogText := Text035 + ' ';

        if "Document Type" = "Document Type"::Order then
            if Location2."Directed Put-away and Pick" then begin
                ShowDialog := ShowDialog::Error;
                if Quantity >= 0 then
                    DialogText := DialogText + ' ' + Location2.GetRequirementText(Location2.FieldNo("Require Shipment"))
                else
                    DialogText := DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Receive"));
            end else begin
                if (Quantity >= 0) and (Location2."Require Shipment" or Location2."Require Pick") then begin
                    if WhseValidateSourceLine.WhseLinesExist(DATABASE::"Service Line", "Document Type".AsInteger(), "Document No.", "Line No.", 0, Quantity)
                    then
                        ShowDialog := ShowDialog::Error
                    else
                        if Location2."Require Shipment" then
                            ShowDialog := ShowDialog::Message;
                    if Location2."Require Shipment" then
                        DialogText :=
                          DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Shipment"))
                    else begin
                        DialogText := Text036;
                        DialogText :=
                          DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Pick"));
                    end;
                end;

                if (Quantity < 0) and (Location2."Require Receive" or Location2."Require Put-away") then begin
                    if WhseValidateSourceLine.WhseLinesExist(
                         DATABASE::"Service Line", "Document Type".AsInteger(), "Document No.", "Line No.", 0, Quantity)
                    then
                        ShowDialog := ShowDialog::Error
                    else
                        if Location2."Require Receive" then
                            ShowDialog := ShowDialog::Message;
                    if Location2."Require Receive" then
                        DialogText := DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Receive"))
                    else
                        DialogText := Text036 + ' ' + Location2.GetRequirementText(Location2.FieldNo("Require Put-away"));
                end;
            end;

        case ShowDialog of
            ShowDialog::Message:
                Message(WhseRequirementMsg, DialogText);
            ShowDialog::Error:
                Error(Text049, DialogText, FieldCaption("Line No."), "Line No.");
        end;

        HandleDedicatedBin(true);
    end;

    local procedure HandleDedicatedBin(IssueWarning: Boolean)
    var
        WhseIntegrationMgt: Codeunit "Whse. Integration Management";
    begin
        WhseIntegrationMgt.CheckIfBinDedicatedOnSrcDoc("Location Code", "Bin Code", IssueWarning);
    end;

    procedure TestStatusOpen()
    var
        ServHeader: Record "Service Header";
    begin
        ServHeader.Get(Rec."Document Type", Rec."Document No.");
        OnBeforeTestStatusOpen(Rec, ServHeader);

        if StatusCheckSuspended then
            exit;

        if (Type = Type::Item) or (xRec.Type = Type::Item) then
            ServHeader.TestField("Release Status", ServHeader."Release Status"::Open);

        OnAfterTestStatusOpen(Rec, ServHeader);
    end;

    local procedure TestQtyFromLineDiscountAmount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestQtyFromLineDiscountAmount(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        TestField(Quantity);
    end;

    procedure SuspendStatusCheck(bSuspend: Boolean)
    begin
        StatusCheckSuspended := bSuspend;
    end;

    procedure LineRequiresShipmentOrReceipt(): Boolean
    var
        LocationToCheck: Record Location;
    begin
        if "Document Type" <> "Document Type"::Order then
            exit(false);

        if not IsInventoriableItem() then
            exit(false);

        if LocationToCheck.RequireShipment("Location Code") then
            exit(true);
        if LocationToCheck.RequireReceive("Location Code") then
            exit(true);

        exit(false);
    end;

    local procedure DisplayConflictError(ErrTxt: Text[500])
    var
        DisplayedError: Text[600];
    begin
        DisplayedError := Text051 + ErrTxt;
        Error(DisplayedError);
    end;

    procedure GetDueDate(): Date
    begin
        exit(EvaluateDaysBack("Shipping Time", "Needed by Date"));
    end;

    procedure GetShipmentDate(): Date
    var
        Location: Record Location;
        InventorySetup: Record "Inventory Setup";
    begin
        if Location.Get("Location Code") then
            exit(EvaluateDaysBack(Location."Outbound Whse. Handling Time", GetDueDate()));
        InventorySetup.Get();
        exit(EvaluateDaysBack(InventorySetup."Outbound Whse. Handling Time", GetDueDate()));
    end;

    procedure GetDateForCalculations() CalculationDate: Date;
    begin
        if Rec."Document No." = '' then
            CalculationDate := Rec."Posting Date"
        else begin
            Rec.GetServHeader();
            if ServHeader."Document Type" in [ServHeader."Document Type"::Invoice, ServHeader."Document Type"::"Credit Memo"] then
                CalculationDate := ServHeader."Posting Date"
            else
                CalculationDate := ServHeader."Order Date";
        end;
        if CalculationDate = 0D then
            CalculationDate := WorkDate();
    end;

    procedure OutstandingInvoiceAmountFromShipment(CustomerNo: Code[20]): Decimal
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetCurrentKey("Document Type", "Customer No.", "Shipment No.");
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Invoice);
        ServiceLine.SetRange("Customer No.", CustomerNo);
        ServiceLine.SetFilter("Shipment No.", '<>%1', '');
        ServiceLine.CalcSums("Outstanding Amount (LCY)");
        exit(ServiceLine."Outstanding Amount (LCY)");
    end;

    local procedure EvaluateDaysBack(InputFormula: DateFormula; InputDate: Date): Date
    var
        DFCode: Code[10];
        DF: DateFormula;
    begin
        if Format(InputFormula) = '' then
            exit(InputDate);
        DFCode := Format(InputFormula);
        if not (CopyStr(DFCode, 1, 1) in ['+', '-']) then
            DFCode := '+' + DFCode;
        DFCode := ConvertStr(DFCode, '+-', '-+');
        Evaluate(DF, DFCode);
        exit(CalcDate(DF, InputDate));
    end;

    local procedure CheckIfCanBeModified()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfCanBeModified(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        if ("Appl.-to Service Entry" > 0) and ("Contract No." <> '') then
            Error(Text053);
    end;

    local procedure ViewDimensionSetEntries()
    begin
        DimMgt.ShowDimensionSet(
          "Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."));
    end;

    procedure TestItemFields(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        TestField(Type, Type::Item);
        TestField("No.", ItemNo);
        TestField("Variant Code", VariantCode);
        TestField("Location Code", LocationCode);
    end;

    procedure TestBinCode()
    var
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestBinCode(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Location Code" = '') or (Type <> Type::Item) then
            exit;

        if Rec.IsNonInventoriableItem() then
            exit;

        Location.Get("Location Code");
        if not Location."Bin Mandatory" then
            exit;
        if ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) or
           not Location."Directed Put-away and Pick"
        then
            TestField("Bin Code");
    end;

    procedure GetNextLineNo(ServiceLineSource: Record "Service Line"; BelowxRec: Boolean): Integer
    var
        ServiceLine: Record "Service Line";
        LowLineNo: Integer;
        HighLineNo: Integer;
        NextLineNo: Integer;
        LineStep: Integer;
    begin
        LowLineNo := 0;
        HighLineNo := 0;
        NextLineNo := 0;
        LineStep := 10000;
        ServiceLine.SetRange("Document Type", "Document Type");
        ServiceLine.SetRange("Document No.", "Document No.");

        if ServiceLine.Find('+') then
            if not ServiceLine.Get(ServiceLineSource."Document Type", ServiceLineSource."Document No.", ServiceLineSource."Line No.") then
                NextLineNo := ServiceLine."Line No." + LineStep
            else
                if BelowxRec then begin
                    ServiceLine.FindLast();
                    NextLineNo := ServiceLine."Line No." + LineStep;
                end else
                    if ServiceLine.Next(-1) = 0 then begin
                        LowLineNo := 0;
                        HighLineNo := ServiceLineSource."Line No.";
                    end else begin
                        ServiceLine := ServiceLineSource;
                        ServiceLine.Next(-1);
                        LowLineNo := ServiceLine."Line No.";
                        HighLineNo := ServiceLineSource."Line No.";
                    end
        else
            NextLineNo := LineStep;

        if NextLineNo = 0 then
            NextLineNo := Round((LowLineNo + HighLineNo) / 2, 1, '<');

        if ServiceLine.Get("Document Type", "Document No.", NextLineNo) then
            exit(0);
        exit(NextLineNo);
    end;

    procedure GetLineNo(): Integer
    var
        ServLine: Record "Service Line";
    begin
        if "Line No." <> 0 then
            if not ServLine.Get("Document Type", "Document No.", "Line No.") then
                exit("Line No.");

        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "Document No.");
        if ServLine.FindLast() then
            exit(ServLine."Line No." + 10000);
        exit(10000);
    end;

    procedure GetCPGInvRoundAcc(ServiceHeader: Record "Service Header") AccountNo: Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCPGInvRoundAcc(ServiceHeader, AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        SalesSetup.GetRecordOnce();
        if SalesSetup."Invoice Rounding" and (ServiceHeader."Bill-to Customer No." <> '') then begin
            Customer.Get(ServiceHeader."Bill-to Customer No.");
            CustomerPostingGroup.Get(Customer."Customer Posting Group");
            exit(CustomerPostingGroup."Invoice Rounding Account");
        end;
    end;

    procedure DeleteWithAttachedLines()
    begin
        SetRange("Document Type", "Document Type");
        SetRange("Document No.", "Document No.");
        SetRange("Attached to Line No.", "Line No.");
        DeleteAll();

        SetRange("Document Type");
        SetRange("Document No.");
        SetRange("Attached to Line No.");
        Delete();
    end;

    procedure IsNonInventoriableItem(): Boolean
    var
        Item: Record Item;
    begin
        if Type <> Type::Item then
            exit(false);
        if "No." = '' then
            exit(false);
        Item.SetLoadFields(Type);
        GetItem(Item);
        exit(Item.IsNonInventoriableType());
    end;

    procedure IsInventoriableItem(): Boolean
    var
        Item: Record Item;
    begin
        if Type <> Type::Item then
            exit(false);
        if "No." = '' then
            exit(false);
        Item.SetLoadFields(Type);
        GetItem(Item);
        exit(Item.IsInventoriableType());
    end;

    procedure SelectMultipleItems()
    var
        Item: Record "Item";
        ServiceItemLine: Record "Service Item Line";
        ItemListPage: Page "Item List";
        SelectionFilter: Text;
    begin
        OnBeforeSelectMultipleItems(Rec);

        ServiceItemLine.SetRange("Document Type", Rec."Document Type");
        ServiceItemLine.SetRange("Document No.", Rec."Document No.");
        ServiceItemLine.SetRange("Line No.", Rec."Service Item Line No.");
        ServiceItemLine.SetRange("Service Item No.", Rec."Service Item No.");
        ServiceItemLine.SetLoadFields("Item No.");
        if ServiceItemLine.FindFirst() then
            if ServiceItemLine."Item No." <> '' then
                Item.SetFilter("No.", '<>%1', ServiceItemLine."Item No.");

        SelectionFilter := ItemListPage.SelectActiveItemsForService(Item);

        if SelectionFilter <> '' then
            AddItems(SelectionFilter);

        OnAfterSelectMultipleItems(Rec);
    end;

    local procedure AddItems(SelectionFilter: Text)
    var
        Item: Record "Item";
        NewServiceLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddItems(Rec, SelectionFilter, IsHandled);
        if IsHandled then
            exit;

        NewServiceLine.SetHideReplacementDialog(true);
        InitNewLine(NewServiceLine);
        Item.SetLoadFields("No.");
        Item.SetFilter("No.", SelectionFilter);
        if Item.FindSet() then
            repeat
                AddItem(NewServiceLine, Item."No.");
            until Item.Next() = 0;
    end;

    local procedure AddItem(var NewServiceLine: Record "Service Line"; ItemNo: Code[20])
    begin
        NewServiceLine."Line No." += 10000;
        NewServiceLine."No." := '';
        NewServiceLine.Validate(Type, NewServiceLine.Type::Item);
        NewServiceLine.Validate("No.", ItemNo);
        NewServiceLine.Insert(true);
    end;

    local procedure InitNewLine(var NewServiceLine: Record "Service Line")
    var
        ExistingServiceLine: Record "Service Line";
    begin
        NewServiceLine.Copy(Rec);
        ExistingServiceLine.SetRange("Document Type", NewServiceLine."Document Type");
        ExistingServiceLine.SetRange("Document No.", NewServiceLine."Document No.");
        if ExistingServiceLine.FindLast() then
            NewServiceLine."Line No." := ExistingServiceLine."Line No."
        else
            NewServiceLine."Line No." := 0;

        if NewServiceLine.Quantity <> 0 then begin
            NewServiceLine."Quantity Consumed" := 0;
            NewServiceLine."Quantity Invoiced" := 0;
            NewServiceLine."Quantity Shipped" := 0;
            NewServiceLine."Qty. Consumed (Base)" := 0;
            NewServiceLine."Qty. Invoiced (Base)" := 0;
            NewServiceLine."Qty. Shipped (Base)" := 0;
            NewServiceLine.Validate(Quantity, 0);
        end;

        NewServiceLine.Type := NewServiceLine.Type::Item;
        NewServiceLine."No." := '';
    end;

    local procedure UpdateDimSetupFromDimSetID(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; InheritFromDimSetID: Integer)
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        DimMgt.GetDimensionSet(TempDimSetEntry, InheritFromDimSetID);
        ServHeader.Get(Rec."Document Type", Rec."Document No.");
        UpdateDimSetupByDefaultDim(Database::"Service Order Type", ServHeader."Service Order Type", TempDimSetEntry, DefaultDimSource);
        UpdateDimSetupByDefaultDim(Database::Customer, ServHeader."Bill-to Customer No.", TempDimSetEntry, DefaultDimSource);
        UpdateDimSetupByDefaultDim(Database::"Salesperson/Purchaser", ServHeader."Salesperson Code", TempDimSetEntry, DefaultDimSource);
        UpdateDimSetupByDefaultDim(Database::"Service Contract Header", ServHeader."Contract No.", TempDimSetEntry, DefaultDimSource);
        UpdateDimSetupByDefaultDim(Database::"Service Item", ServItemLine."Service Item No.", TempDimSetEntry, DefaultDimSource);
        UpdateDimSetupByDefaultDim(Database::"Service Item Group", ServItemLine."Service Item Group Code", TempDimSetEntry, DefaultDimSource);
    end;

    local procedure UpdateDimSetupByDefaultDim(SourceID: Integer; SourceNo: Code[20]; var TempDimSetEntry: Record "Dimension Set Entry" temporary; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        DefaultDim: Record "Default Dimension";
        SourceCodeSetup: Record "Source Code Setup";
        DefaultDimensionPriority: Record "Default Dimension Priority";
        TableAdded: Boolean;
    begin
        if SourceNo = '' then
            exit;

        SourceCodeSetup.Get();
        DefaultDimensionPriority.SetRange("Source Code", SourceCodeSetup."Service Management");
        DefaultDimensionPriority.SetRange("Table ID", SourceID);
        if DefaultDimensionPriority.IsEmpty() then
            exit;

        DefaultDim.SetRange("Table ID", SourceID);
        DefaultDim.SetRange("No.", SourceNo);
        if DefaultDim.FindSet() then
            repeat
                TempDimSetEntry.SetRange("Dimension Code", DefaultDim."Dimension Code");
                TempDimSetEntry.SetRange("Dimension Value Code", DefaultDim."Dimension Value Code");
                if TempDimSetEntry.FindFirst() then begin
                    DimMgt.AddDimSource(DefaultDimSource, DefaultDim."Table ID", DefaultDim."No.");
                    TableAdded := true;
                end;
            until (DefaultDim.Next() = 0) or TableAdded;
    end;

    local procedure UpdateLineDiscPct()
    var
        LineDiscountPct: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLineDiscPct(Rec, Currency, IsHandled);
        if IsHandled then
            exit;

        if Round(CalcChargeableQty() * "Unit Price", Currency."Amount Rounding Precision") <> 0 then begin
            LineDiscountPct := Round(
                "Line Discount Amount" / Round(CalcChargeableQty() * "Unit Price", Currency."Amount Rounding Precision") * 100,
                0.00001);
            if not (LineDiscountPct in [0 .. 100]) then
                Error(LineDiscountPctErr);
            "Line Discount %" := LineDiscountPct;
        end else
            "Line Discount %" := 0;
    end;

    local procedure UpdateVATPercent(BaseAmount: Decimal; VATAmount: Decimal)
    begin
        if BaseAmount <> 0 then
            "VAT %" := Round(100 * VATAmount / BaseAmount, 0.00001)
        else
            ClearVATPct();
    end;

    local procedure CheckNonstockItemTemplate(NonstockItem: Record "Nonstock Item")
    var
        ItemTempl: Record "Item Templ.";
    begin
        ItemTempl.Get(NonstockItem."Item Templ. Code");
        ItemTempl.TestField("Gen. Prod. Posting Group");
        ItemTempl.TestField("Inventory Posting Group");
    end;

    procedure SwitchLinesWithErrorsFilter(var ShowAllLinesEnabled: Boolean)
    var
        TempLineErrorMessage: Record "Error Message" temporary;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
    begin
        if ShowAllLinesEnabled then begin
            MarkedOnly(false);
            ShowAllLinesEnabled := false;
        end else begin
            DocumentErrorsMgt.GetErrorMessages(TempLineErrorMessage);
            if TempLineErrorMessage.FindSet() then
                repeat
                    if Rec.Get(TempLineErrorMessage."Context Record ID") then
                        Rec.Mark(true)
                until TempLineErrorMessage.Next() = 0;
            MarkedOnly(true);
            ShowAllLinesEnabled := true;
        end;
    end;

    local procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    begin
        exit(UOMMgt.CalcBaseQty(
            "No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        if DimMgt.IsDefaultDimDefinedForTable(GetTableValuePair(FieldNo)) then
            CreateDim(DefaultDimSource);
    end;

    local procedure GetTableValuePair(FieldNo: Integer) TableValuePair: Dictionary of [Integer, Code[20]]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitTableValuePair(TableValuePair, FieldNo, IsHandled, Rec);
        if IsHandled then
            exit;

        case true of
            FieldNo = Rec.FieldNo("No."):
                TableValuePair.Add(ServDimMgt.ServiceLineTypeToTableID(Rec.Type), Rec."No.");
            FieldNo = Rec.FieldNo("Responsibility Center"):
                TableValuePair.Add(Database::"Responsibility Center", Rec."Responsibility Center");
            FieldNo = Rec.FieldNo("Job No."):
                TableValuePair.Add(Database::Job, Rec."Job No.");
            FieldNo = Rec.FieldNo("Location Code"):
                TableValuePair.Add(Database::Location, Rec."Location Code");
        end;
        OnAfterInitTableValuePair(TableValuePair, FieldNo, Rec);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, ServDimMgt.ServiceLineTypeToTableID(Rec.Type), Rec."No.", FieldNo = Rec.FieldNo("No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, Rec."Job No.", FieldNo = Rec.FieldNo("Job No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Responsibility Center", Rec."Responsibility Center", FieldNo = Rec.FieldNo("Responsibility Center"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code", FieldNo = Rec.FieldNo("Location Code"));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    procedure CheckIfServiceLineMeetsReservedFromStockSetting(QtyToPost: Decimal; ReservedFromStock: Enum "Reservation From Stock") Result: Boolean
    var
        QtyReservedFromStock: Decimal;
    begin
        Result := true;

        if not Rec.IsInventoriableItem() then
            exit(true);

        if ReservedFromStock = ReservedFromStock::" " then
            exit(true);

        QtyReservedFromStock := ServiceLineReserve.GetReservedQtyFromInventory(Rec);

        case ReservedFromStock of
            ReservedFromStock::Full:
                if QtyToPost <> QtyReservedFromStock then
                    Result := false;
            ReservedFromStock::"Full and Partial":
                if QtyReservedFromStock = 0 then
                    Result := false;
            else
                OnCheckIfServiceLineMeetsReservedFromStockSetting(QtyToPost, ReservedFromStock, Result);
        end;

        exit(Result);
    end;

    procedure SetCalledFromServiceItemLine(CallFromServiceItemLine: Boolean)
    begin
        CalledFromServiceItemLine := CallFromServiceItemLine;
    end;

    #region Blocked Item/Item Variant Notifications
    local procedure GetBlockedItemNotificationID(): Guid
    begin
        exit('963A9FD3-11E8-4CAA-BE3A-7F8CEC9EF8EC');
    end;

    local procedure SendBlockedItemNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToSend: Notification;
    begin
        NotificationToSend.Id := GetBlockedItemNotificationID();
        NotificationToSend.Recall();
        NotificationToSend.Message := StrSubstNo(BlockedItemNotificationMsg, "No.");
        NotificationLifecycleMgt.SendNotification(NotificationToSend, RecordId);
    end;

    local procedure GetBlockedItemVariantNotificationID(): Guid
    begin
        exit('1113AAF8-EC5B-4F80-BB38-09A770130E59');
    end;

    local procedure SendBlockedItemVariantNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToSend: Notification;
    begin
        NotificationToSend.Id := GetBlockedItemVariantNotificationID();
        NotificationToSend.Recall();
        NotificationToSend.Message := StrSubstNo(BlockedItemVariantNotificationMsg, Rec."Variant Code", Rec."No.");
        NotificationLifecycleMgt.SendNotification(NotificationToSend, Rec.RecordId());
    end;
    # endregion Blocked Item/Item Variant Notifications

    procedure CopyToItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyToItemJnlLine(ItemJournalLine, Rec, IsHandled);
#if not CLEAN25
        ItemJournalLine.RunOnBeforeCopyItemJnlLineFromServLine(ItemJournalLine, Rec, IsHandled);
#endif
        if not IsHandled then begin
            ItemJournalLine."Item No." := Rec."No.";
            ItemJournalLine."Posting Date" := Rec."Posting Date";
            ItemJournalLine.Description := Rec.Description;
            ItemJournalLine."Shortcut Dimension 1 Code" := Rec."Shortcut Dimension 1 Code";
            ItemJournalLine."Shortcut Dimension 2 Code" := Rec."Shortcut Dimension 2 Code";
            ItemJournalLine."Dimension Set ID" := Rec."Dimension Set ID";
            ItemJournalLine."Location Code" := Rec."Location Code";
            ItemJournalLine."Bin Code" := Rec."Bin Code";
            ItemJournalLine."Variant Code" := Rec."Variant Code";
            ItemJournalLine."Inventory Posting Group" := Rec."Posting Group";
            ItemJournalLine."Gen. Bus. Posting Group" := Rec."Gen. Bus. Posting Group";
            ItemJournalLine."Gen. Prod. Posting Group" := Rec."Gen. Prod. Posting Group";
            ItemJournalLine."Applies-to Entry" := Rec."Appl.-to Item Entry";
            ItemJournalLine."Transaction Type" := Rec."Transaction Type";
            ItemJournalLine."Transport Method" := Rec."Transport Method";
            ItemJournalLine."Entry/Exit Point" := Rec."Exit Point";
            ItemJournalLine.Area := Rec.Area;
            ItemJournalLine."Transaction Specification" := Rec."Transaction Specification";
            ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::Sale;
            ItemJournalLine."Unit of Measure Code" := Rec."Unit of Measure Code";
            ItemJournalLine."Qty. per Unit of Measure" := Rec."Qty. per Unit of Measure";
            ItemJournalLine."Qty. Rounding Precision" := Rec."Qty. Rounding Precision";
            ItemJournalLine."Qty. Rounding Precision (Base)" := Rec."Qty. Rounding Precision (Base)";
            ItemJournalLine."Derived from Blanket Order" := false;
            ItemJournalLine."Item Category Code" := Rec."Item Category Code";
            ItemJournalLine.Nonstock := Rec.Nonstock;
            ItemJournalLine."Return Reason Code" := Rec."Return Reason Code";
            ItemJournalLine."Order Type" := ItemJournalLine."Order Type"::Service;
            ItemJournalLine."Order No." := Rec."Document No.";
            ItemJournalLine."Order Line No." := Rec."Line No.";
            ItemJournalLine."Job No." := Rec."Job No.";
            ItemJournalLine."Job Task No." := Rec."Job Task No.";
            ItemJournalLine."Price Calculation Method" := Rec."Price Calculation Method";
            ItemJournalLine."Invoice-to Source No." := Rec."Bill-to Customer No.";
        end;

        OnAfterCopyToItemJnlLine(ItemJournalLine, Rec);
#if not CLEAN25
        ItemJournalLine.RunOnAfterCopyItemJnlLineFromServLine(ItemJournalLine, Rec);
#endif
    end;

    procedure CopyToResJournalLine(var ResJournalLine: Record "Res. Journal Line")
    begin
        ResJournalLine."Posting Date" := Rec."Posting Date";
        ResJournalLine."Order Type" := ResJournalLine."Order Type"::Service;
        ResJournalLine."Order Line No." := Rec."Line No.";
        ResJournalLine."Resource No." := Rec."No.";
        ResJournalLine.Description := Rec.Description;
        ResJournalLine."Work Type Code" := Rec."Work Type Code";
        ResJournalLine."Shortcut Dimension 1 Code" := Rec."Shortcut Dimension 1 Code";
        ResJournalLine."Shortcut Dimension 2 Code" := Rec."Shortcut Dimension 2 Code";
        ResJournalLine."Dimension Set ID" := Rec."Dimension Set ID";
        ResJournalLine."Unit of Measure Code" := Rec."Unit of Measure Code";
        ResJournalLine."Qty. per Unit of Measure" := Rec."Qty. per Unit of Measure";
        ResJournalLine."Gen. Bus. Posting Group" := Rec."Gen. Bus. Posting Group";
        ResJournalLine."Gen. Prod. Posting Group" := Rec."Gen. Prod. Posting Group";
        ResJournalLine."Source Type" := ResJournalLine."Source Type"::Customer;
        ResJournalLine."Source No." := Rec."Customer No.";
        ResJournalLine."Time Sheet No." := Rec."Time Sheet No.";
        ResJournalLine."Time Sheet Line No." := Rec."Time Sheet Line No.";
        ResJournalLine."Time Sheet Date" := Rec."Time Sheet Date";
        ResJournalLine."Job No." := Rec."Job No.";

        OnAfterCopyToResJournalLine(ResJournalLine, Rec);
    end;

    procedure CheckProdPostingGroups(): Boolean
    var
        ApplicationAreaMgmt: Codeunit System.Environment.Configuration."Application Area Mgmt.";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdPostingGroups(Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(not ApplicationAreaMgmt.IsSalesTaxEnabled());
    end;

    local procedure UpdateItemReference()
    begin
        ServItemReferenceMgt.EnterServiceItemReference(Rec);
    end;

    internal procedure ClearVATPct()
    begin
        "VAT %" := 0;
        OnAfterClearVATPct(Rec);
    end;

    internal procedure ClearVATDifference()
    begin
        "VAT Difference" := 0;
        OnAfterClearVATDifference(Rec);
    end;

    internal procedure CalcVATDifference(var TempVATAmountLineRemainder: record "VAT Amount Line" temporary; var VATAmountLine: Record "VAT Amount Line"; LineAmount: Decimal; var VATDifference: Decimal)
    begin
        VATDifference :=
            TempVATAmountLineRemainder."VAT Difference" +
            VATAmountLine."VAT Difference" * LineAmount / VATAmountLine.CalcLineAmount();
        OnAfterCalcVATDifference(TempVATAmountLineRemainder, VATAmountLine, LineAmount);
    end;

    internal procedure RoundVATDifference(VATDifference: Decimal; Currency: Record Currency)
    begin
        "VAT Difference" := Round(VATDifference, Currency."Amount Rounding Precision");
        OnAfterRoundVATDifference(Rec, Currency);
    end;

    internal procedure GetVATPct() VATPct: Decimal
    begin
        VATPct := "VAT %";
        OnAfterGetVATPct(Rec, VATPct);
    end;

    internal procedure CopyFromVATPostingSetup(var VATPostingSetupFrom: Record "VAT Posting Setup")
    begin
        "VAT %" := VATPostingSetupFrom."VAT %";
        "VAT Calculation Type" := VATPostingSetupFrom."VAT Calculation Type";
        "VAT Identifier" := VATPostingSetupFrom."VAT Identifier";
        "VAT Clause Code" := VATPostingSetupFrom."VAT Clause Code";

        OnAfterCopyFromVATPostingSetup(Rec, VATPostingSetupFrom);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var ServiceLine: Record "Service Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignHeaderValues(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignStdTxtValues(var ServiceLine: Record "Service Line"; StandardText: Record "Standard Text")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignGLAccountValues(var ServiceLine: Record "Service Line"; GLAccount: Record "G/L Account"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignServCostValues(var ServiceLine: Record "Service Line"; ServiceCost: Record "Service Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemValues(var ServiceLine: Record "Service Line"; Item: Record Item; xServiceLine: Record "Service Line"; CallingFieldNo: Integer; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignServItemValues(var ServiceLine: Record "Service Line"; ServiceItem: Record "Service Item"; ServiceItemComp: Record "Service Item Component"; HideReplacementDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignResourceValues(var ServiceLine: Record "Service Line"; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineAmount(var ServiceLine: Record "Service Line"; var LineAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateDiscount(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcInvDiscToInvoice(var ServiceLine: Record "Service Line"; OldInvDiscAmtToInv: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckApplFromItemLedgEntry(var ServiceLine: Record "Service Line"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearFields(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; TempServiceLine: Record "Service Line" temporary; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemTranslation(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ItemTranslation: Record "Item Translation")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSKU(ServiceLine: Record "Service Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetStrMenuDefaultValue(var DefaultValue: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetUnitCost(var ServiceLine: Record "Service Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var ServiceLine: Record "Service Line"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindLinesForReservation(var ServiceLine: Record "Service Line"; ReservationEntry: Record "Reservation Entry"; AvailabilityFilter: Text; Positive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMaxQtyToConsume(var ServiceLine: Record "Service Line"; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMaxQtyToConsumeBase(var ServiceLine: Record "Service Line"; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResourseFindCost(var ServiceLine: Record "Service Line"; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestStatusOpen(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetHideCostWarning(var ServiceLine: Record "Service Line"; var HideCostWarning: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetHideWarrantyWarning(var ServiceLine: Record "Service Line"; var HideWarrantyWarning: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateServiceItemLineNumber(var Rec: Record "Service Line"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitPrice(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATAmounts(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmounts(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATOnLines(var ServHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcVATAmount(VATAmountLine: Record "VAT Amount Line"; NewAmount: Decimal; NewBase: Decimal; var VATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcVATAmountLines(var ServHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping,Consuming)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstanding(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstandingAmount(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToInvoice(var ServiceLine: Record "Service Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToShip(var ServiceLine: Record "Service Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToConsume(var ServiceLine: Record "Service Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculate(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateReverse(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetHideReplacementDialog(var ServiceLine: Record "Service Line"; var HideReplacementDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowNonstock(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyDiscount(ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVATCalculationType(var ServiceLine: Record "Service Line"; VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyToInvoicePositive(var ServiceLine: Record "Service Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyToShipPositive(var ServiceLine: Record "Service Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyToConsumePositive(var ServiceLine: Record "Service Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToShip(var ServiceLine: Record "Service Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromItem(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromServItem(var ServiceLine: Record "Service Line"; ServiceItem: Record "Service Item"; ServItemComponent: Record "Service Item Component"; var IsHandled: Boolean; var HideReplacementDialog: Boolean; ServItemLine: Record "Service Item Line"; var Select: Integer; var ReplaceServItemAction: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var ServiceLine: Record "Service Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultBin(var ServiceLine: Record "Service Line"; CallingFieldNo: Integer; var IsHandled: Boolean; ReplaceServItemAction: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSKU(var ServiceLine: Record "Service Line"; var Result: Boolean; var IsHandled: Boolean; var SKU: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitServHeaderShipToCode(var ServiceLine: Record "Service Line"; var ServHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitHeaderDefaults(var ServiceLine: Record "Service Line"; var ServHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestBinCode(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestQuantityPositive(var ServiceLine: Record "Service Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestQtyFromLineDiscountAmount(var ServiceLine: Record "Service Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestQtyFromLineAmount(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShortcutDimCode(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestStatusOpen(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmounts(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLineDiscPct(var ServiceLine: Record "Service Line"; Currency: Record Currency; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitPrice(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitPriceProcedure(var ServiceLine: Record "Service Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitPriceByField(var ServiceLine: Record "Service Line"; CalledByFieldNo: Integer; CalcCost: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVATAmounts(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNeededByDate(var ServHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateResponsibilityCenter(var Rec: Record "Service Line"; var DimMgt: Codeunit DimensionManagement; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateServiceItemNo(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateServiceItemLineNumber(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantity(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityInvIsBalanced(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityShipIsBalanced(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityConsumeIsBalanced(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityBase(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToConsumeBase(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToInvoiceBase(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToShipBase(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnAfterCalcLineTotals(var VATAmountLine: Record "VAT Amount Line"; ServHeader: Record "Service Header"; ServiceLine: Record "Service Line"; Currency: Record Currency; QtyType: Option General,Invoicing,Shipping; var TotalVATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemAvailableOnBeforeCheckNonStock(var ServiceLine: Record "Service Line"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromResourceOnAfterCheckResource(var ServiceLine: Record "Service Line"; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCopyFromCostOnAfterCalcShouldShowConfirm(var ServiceLine: Record "Service Line"; ServiceCost: Record "Service Cost"; HideCostWarning: Boolean; var ShouldShowConfirm: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitQtyToShipOnBeforeInitQtyToInvoice(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitQtyToInvoiceOnBeforeCalcInvDiscToInvoice(var ServiceLine: Record "Service Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitHeaderDefaultsOnAfterAssignLocationCode(var ServiceLine: Record "Service Line"; ServHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReplaceServItemOnCopyFromReplacementItem(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateContractNoOnBeforeContractDiscountFind(var ServiceLine: Record "Service Line"; var ContractServDisc: Record "Contract/Service Discount"; ServItem: Record "Service Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceItemLineNoOnBeforeValidateContractNo(var ServiceLine: Record "Service Line"; ServItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnAssignItem(var ServiceLine: Record "Service Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterCopyFields(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnAfterCopyFields(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnBeforeValidateQuantity(var ServiceLine: Record "Service Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnAssignItemVariant(var ServiceLine: Record "Service Line"; ItemVariant: Record "Item Variant")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterCalcQuantityBase(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfCanBeModified(ServiceLine: Record "Service Line"; var IsHandled: Boolean; xServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailable(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; CalledByFieldNo: Integer; var IsHandled: Boolean; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemSub(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowNonstock(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReservation(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnAfterServiceLineSetFilter(var ServiceLine2: Record "Service Line"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var ServiceLine: Record "Service Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDimensions(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupServiceItemNoOnAfterServItemSetFilters(var ServiceLine: Record "Service Line"; ServHeader: Record "Service Header"; var ServItem: Record "Service Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReplaceServItemOnAfterAssignVariantCode(var ServiceLine: Record "Service Line"; ServItemReplacement: Page "Service Item Replacement"; SerialNo: Code[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemTrackingOnBeforeCreateEntry(var Rec: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVATProdPostingGroup(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowNonstockOnAfterUpdateFromNonstockItem(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAmountsOnAfterCalcShouldCheckCrLimit(var ServiceLine: Record "Service Line"; IsCustCrLimitChecked: Boolean; CurrentFieldNo: Integer; var ShouldCheckCrLimit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCPGInvRoundAcc(ServiceHeader: Record "Service Header"; var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateApplToItemEntryOnBeforeShowNotOpenItemLedgerEntryMessage(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReturnReasonCodeOnBeforeValidateLocationCode(var ServiceLine: Record "Service Line"; ReturnReason: Record "Return Reason"; var ShouldValidateLocationCode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAmountOnAfterCalculateNormalVAT(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeUpdateLines(var TotalVATAmount: Decimal; Currency: Record Currency; ServiceHeader: Record "Service Header"; var VATAmountLine: Record "VAT Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAmountIncludingVATOnAfterCalculateNormalVAT(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCalcVATAmountLines(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping,Consuming; isShip: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeResetAmounts(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVATOnLines(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; var VATAmountLine: Record "VAT Amount Line" temporary; QtyType: Option General,Invoicing,Shipping; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAmountsOnAfterCalcExpectedLineAmount(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; var ExpectedLineAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsIfPricesInclVATOnAfterNormalVATCalc(var ServiceLine: Record "Service Line"; ServHeader: Record "Service Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsIfPricesExclVATOnAfterNormalVATCalc(var ServiceLine: Record "Service Line"; ServHeader: Record "Service Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountOnAfterClearAmounts(var ServiceLine: Record "Service Line")
    begin
    end;

#if not CLEAN27
    [Obsolete('The event is never raised', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATOnLinesOnAfterCalcVATAmount(var ServiceLine: Record "Service Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; VATAmountLine: Record "VAT Amount Line"; var VATAmount: Decimal)
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitTableValuePair(var TableValuePair: Dictionary of [Integer, Code[20]]; FieldNo: Integer; var IsHandled: Boolean; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitTableValuePair(var TableValuePair: Dictionary of [Integer, Code[20]]; FieldNo: Integer; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouse(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWithWarehouseShipOnAfterVerifyType(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcChargeableQty(ServiceLine: Record "Service Line"; var ChargableQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobNo(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobTaskNo(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateFaultReasonCodeOnBeforeExcludeWarrantyDiscountCheck(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeServiceEntriesError(var ServiceLine: Record "Service Line"; var CheckServiceDocumentType: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupContractNo(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateDiscount(var ServiceLine: Record "Service Line"; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckErrorSelectedSI(var ServiceLine: Record "Service Line"; var ServItemLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIfServiceLineMeetsReservedFromStockSetting(QtyToPost: Decimal; ReservedFromStock: Enum "Reservation From Stock"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemAvailable(var ServiceLine: Record "Service Line"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeDisplayConflictError(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnAfterDisplayConflictError(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnAfterUpdateServiceLedgerEntry(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnDelNonStockFSMBeforeModify(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeTestFields(var ServiceLine: Record "Service Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeCustomerCheck(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeGetUnitCost(var ServiceLine: Record "Service Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToShipOnBeforeQtyToShipCheck(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateWorkTypeCodeOnBeforePlanPriceCalcByField(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnAfterUpdateReservation(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureOnAfterAssignUnitofMeasureValue(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateExcludeWarranty(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; HideWarrantyWarning: Boolean; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateContractNoOnBeforeAssignWarrantyDisc(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromCost(var ServiceLine: Record "Service Line"; HideCostWarning: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromResource(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsOnBeforeCalculateAmountWithNoVAT(var ServiceLine: Record "Service Line"; TotalAmount: Decimal; TotalAmountInclVAT: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLineDiscount(var ServiceLine: Record "Service Line"; LineDisc: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmAdjPriceLineChange(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserve(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; FullAutoReservation: Boolean; var ReserveServiceLine: Codeunit "Service Line-Reserve"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnAfterServiceLineSetFilters(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectMultipleItems(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelectMultipleItems(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddItems(var ServiceLine: Record "Service Line"; SelectionFilter: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPickDiscount(var ServiceLine: Record "Service Line"; var PriceCalculation: Interface "Price Calculation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPickPrice(var ServiceLine: Record "Service Line"; var PriceCalculation: Interface "Price Calculation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyToItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToResJournalLine(var ResJournalLine: Record "Res. Journal Line"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVatBaseDiscountPct(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATAmountOnBeforeInsert(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindVATAmountLineOnAfterSetFilters(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsOnAfterCalculateVATBaseAmount(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; var Currency: Record Currency; TotalAmount: Decimal; TotalVATBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeVATAmountLineModifyInvoicing(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeVATAmountLineModifyShipping(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeVATAmountLineModifyElseCase(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterSetNewVATBaseAmountPriceInclVAT(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; var VATAmountLine: Record "VAT Amount Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; NewAmount: Decimal; var NewVATBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterSetNewVATBaseAmountPriceExclVAT(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; var VATAmountLine: Record "VAT Amount Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; NewAmount: Decimal; var NewVATBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterSetVATBaseAmountGeneral(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line"; var Currency: Record Currency; NewVATBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeTempVATAmountLineRemainderModify(var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; var ServiceLine: Record "Service Line"; NewVATBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnDelete(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdPostingGroups(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearVATPct(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearVATDifference(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcVATDifference(var TempVATAmountLineRemainder: record "VAT Amount Line" temporary; var VATAmountLine: Record "VAT Amount Line"; LineAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundVATDifference(var ServiceLine: Record "Service Line"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATPct(var ServiceLine: Record "Service Line"; var VATPct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromVATPostingSetup(var ServiceLine: Record "Service Line"; var VATPostingSetupFrom: Record "VAT Posting Setup")
    begin
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPrepaymentFromVATPostingSetup(var ServiceLine: Record "Service Line"; var VATPostingSetupFrom: Record "VAT Posting Setup")
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLineAmount(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; Currency: Record Currency; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeUpdateVATAmountLine(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line"; var TotalVATAmount: Decimal; Currency: Record Currency; var RoundingLineInserted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToConsumeOnBeforeQtyToConsumeCheck(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitOutstandingOnAfterInitOutstandingQuantity(var ServiceLine: Record "Service Line")
    begin
    end;
}