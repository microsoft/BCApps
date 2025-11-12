// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using System.Utilities;

table 5741 "Transfer Line"
{
    Caption = 'Transfer Line';
    DrillDownPageID = "Transfer Lines";
    LookupPageID = "Transfer Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item where(Type = const(Inventory),
                                        Blocked = const(false));
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                TempTransferLine: Record "Transfer Line" temporary;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateItemNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Quantity Shipped", 0);
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                "Item No." := GetItemNo();
                TransferLineReserve.VerifyChange(Rec, xRec);
                CalcFields("Reserved Qty. Inbnd. (Base)");
                TestField("Reserved Qty. Inbnd. (Base)", 0);
                WhseValidateSourceLine.TransLineVerifyChange(Rec, xRec);

                TempTransferLine := Rec;
                Init();
                SystemId := TempTransferLine.SystemId;
                "Item No." := TempTransferLine."Item No.";
                OnValidateItemNoOnCopyFromTempTransLine(Rec, TempTransferLine);
                if "Item No." = '' then
                    exit;

                OnValidateItemNoOnAfterInitLine(Rec, TempTransferLine);

                GetTransHeaderExternal();

                OnValidateItemNoOnAfterGetTransHeaderExternal(Rec, TransHeader, TempTransferLine);
                GetItem();
                GetDefaultBin("Transfer-from Code", "Transfer-to Code");

                Item.TestField(Blocked, false);
                Item.TestField(Type, Item.Type::Inventory);

                Description := Item.Description;
                "Description 2" := Item."Description 2";
                Validate("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
                Validate("Inventory Posting Group", Item."Inventory Posting Group");
                Validate(Quantity, xRec.Quantity);
                Validate("Unit of Measure Code", Item."Base Unit of Measure");
                "Item Category Code" := Item."Item Category Code";

                OnAfterAssignItemValues(Rec, Item, TransHeader);

                CreateDimFromDefaultDim();
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(4; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                if Quantity <> 0 then
                    TestField("Item No.");

                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));

                "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));
                OnValidateQuantityOnAfterCalcQuantityBase(Rec, xRec);
                if ((Quantity * "Quantity Shipped") < 0) or
                   (Abs(Quantity) < Abs("Quantity Shipped"))
                then
                    FieldError(Quantity, StrSubstNo(Text002, FieldCaption("Quantity Shipped")));
                if (("Quantity (Base)" * "Qty. Shipped (Base)") < 0) or
                   (Abs("Quantity (Base)") < Abs("Qty. Received (Base)"))
                then
                    FieldError("Quantity (Base)", StrSubstNo(Text002, FieldCaption("Qty. Shipped (Base)")));
                InitQtyInTransit();
                InitOutstandingQty();
                InitQtyToShip();
                InitQtyToReceive();
                CheckItemAvailable(FieldNo(Quantity));

                VerifyReserveTransferLineQuantity();

                UpdateWithWarehouseShipReceive();

                IsHandled := false;
                OnValidateQuantityOnBeforeTransLineVerifyChange(Rec, xRec, IsHandled);
                if not IsHandled then
                    WhseValidateSourceLine.TransLineVerifyChange(Rec, xRec);
            end;
        }
        field(5; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
            end;
        }
        field(6; "Qty. to Ship"; Decimal)
        {
            Caption = 'Qty. to Ship';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyToShip(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                GetLocation("Transfer-from Code");
                if CurrFieldNo <> 0 then begin
                    if Location."Require Shipment" and
                       ("Qty. to Ship" <> 0)
                    then
                        CheckWarehouse(Location, false);
                    WhseValidateSourceLine.TransLineVerifyChange(Rec, xRec);
                end;

                CheckItemCanBeShipped();

                "Qty. to Ship (Base)" := CalcBaseQty("Qty. to Ship", FieldCaption("Qty. to Ship"), FieldCaption("Qty. to Ship (Base)"));
                ValidateQuantityShipIsBalanced();

                if ("In-Transit Code" = '') and ("Quantity Shipped" = "Quantity Received") then
                    Validate("Qty. to Receive", "Qty. to Ship");

                CheckDirectTransferQtyToShip();
            end;
        }
        field(7; "Qty. to Receive"; Decimal)
        {
            Caption = 'Qty. to Receive';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyToReceive(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                GetLocation("Transfer-to Code");
                if CurrFieldNo <> 0 then begin
                    if Location."Require Receive" and
                       ("Qty. to Receive" <> 0)
                    then
                        CheckWarehouse(Location, true);
                    WhseValidateSourceLine.TransLineVerifyChange(Rec, xRec);
                end;

                GetTransferHeaderNoVerification();

                if not TransHeader."Direct Transfer" and ("Direct Transfer" = xRec."Direct Transfer") then
                    if "Qty. to Receive" > "Qty. in Transit" then
                        if "Qty. in Transit" > 0 then
                            Error(
                              Text008,
                              "Qty. in Transit")
                        else
                            Error(Text009);
                "Qty. to Receive (Base)" := CalcBaseQty("Qty. to Receive", FieldCaption("Qty. to Receive"), FieldCaption("Qty. to Receive (Base)"));
                ValidateQuantityReceiveIsBalanced();

            end;
        }
        field(8; "Quantity Shipped"; Decimal)
        {
            Caption = 'Quantity Shipped';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Shipped (Base)" := CalcBaseQty("Quantity Shipped", FieldCaption("Quantity Shipped"), FieldCaption("Qty. Shipped (Base)"));
                InitQtyInTransit();
                InitOutstandingQty();
                InitQtyToShip();
                InitQtyToReceive();
            end;
        }
        field(9; "Quantity Received"; Decimal)
        {
            Caption = 'Quantity Received';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Received (Base)" := CalcBaseQty("Quantity Received", FieldCaption("Quantity Received"), FieldCaption("Qty. Received (Base)"));
                InitQtyInTransit();
                InitOutstandingQty();
                InitQtyToReceive();
            end;
        }
        field(10; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(11; "Shortcut Dimension 1 Code"; Code[20])
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
        field(12; "Shortcut Dimension 2 Code"; Code[20])
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
        field(13; Description; Text[100])
        {
            Caption = 'Description';
            TableRelation = Item where(Type = const(Inventory),
                                        Blocked = const(false));
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                Item: Record Item;
                ReturnValue: Text[50];
                ItemDescriptionIsNo: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDescription(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if (StrLen(Description) <= MaxStrLen(Item."No.")) and ("Item No." <> '') then
                    ItemDescriptionIsNo := Item.Get(Description);

                if ("Item No." <> '') and (not ItemDescriptionIsNo) and (Description <> '') then begin
                    Item.SetFilter(Description, '''@' + ConvertStr(Description, '''', '?') + '''');
                    if not Item.FindFirst() then
                        exit;
                    if Item."No." = "Item No." then
                        exit;
                    if ConfirmManagement.GetResponseOrDefault(
                        StrSubstNo(AnotherItemWithSameDescrQst, Item."No.", Item.Description), true)
                    then
                        Validate("Item No.", Item."No.");
                    exit;
                end;

                if Item.TryGetItemNoOpenCard(ReturnValue, Description, false, true, true) then
                    case ReturnValue of
                        '':
                            Description := xRec.Description;
                        "Item No.":
                            Description := xRec.Description;
                        else begin
                            CurrFieldNo := FieldNo("Item No.");
                            Validate("Item No.", CopyStr(ReturnValue, 1, MaxStrLen(Item."No.")));
                        end;
                    end;

                if "Item No." <> '' then
                    GetItem();
            end;
        }
        field(14; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
            end;
        }
        field(15; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
            end;
        }
        field(16; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantityBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(17; "Outstanding Qty. (Base)"; Decimal)
        {
            Caption = 'Outstanding Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(18; "Qty. to Ship (Base)"; Decimal)
        {
            Caption = 'Qty. to Ship (Base)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyToShipBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Ship", "Qty. to Ship (Base)");
            end;
        }
        field(19; "Qty. Shipped (Base)"; Decimal)
        {
            Caption = 'Qty. Shipped (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(20; "Qty. to Receive (Base)"; Decimal)
        {
            Caption = 'Qty. to Receive (Base)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyToReceiveBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Receive", "Qty. to Receive (Base)");
            end;
        }
        field(21; "Qty. Received (Base)"; Decimal)
        {
            Caption = 'Qty. Received (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(22; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(23; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                UnitOfMeasure: Record "Unit of Measure";
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                TestField("Quantity Shipped", 0);
                TestField("Qty. Shipped (Base)", 0);
                TestField("Quantity Received", 0);
                TestField("Qty. Received (Base)", 0);
                TransferLineReserve.VerifyChange(Rec, xRec);
                WhseValidateSourceLine.TransLineVerifyChange(Rec, xRec);
                if "Unit of Measure Code" = '' then
                    "Unit of Measure" := ''
                else begin
                    if not UnitOfMeasure.Get("Unit of Measure Code") then
                        UnitOfMeasure.Init();
                    "Unit of Measure" := UnitOfMeasure.Description;
                end;
                GetItem();
                Validate("Qty. per Unit of Measure", UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code"));
                "Gross Weight" := Item."Gross Weight" * "Qty. per Unit of Measure";
                "Net Weight" := Item."Net Weight" * "Qty. per Unit of Measure";
                "Unit Volume" := Item."Unit Volume" * "Qty. per Unit of Measure";
                "Units per Parcel" := Round(Item."Units per Parcel" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");
                OnValidateUnitofMeasureCodeOnBeforeValidateQuantity(Rec, Item, xRec);
                Validate(Quantity);
            end;
        }
        field(24; "Outstanding Quantity"; Decimal)
        {
            Caption = 'Outstanding Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(25; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
        }
        field(26; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
        }
        field(27; "Unit Volume"; Decimal)
        {
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
        }
        field(28; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(29; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(30; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."), Blocked = const(false));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                TransferLineReserve.VerifyChange(Rec, xRec);
                WhseValidateSourceLine.TransLineVerifyChange(Rec, xRec);

                OnValidateVariantCodeOnBeforeCheckEmptyVariantCode(Rec, xRec, CurrFieldNo);
                if Rec."Variant Code" = '' then
                    exit;

                GetDefaultBin("Transfer-from Code", "Transfer-to Code");
                ItemVariant.SetLoadFields(Description, "Description 2", Blocked);
                ItemVariant.Get("Item No.", "Variant Code");
                ItemVariant.TestField(Blocked, false);
                Description := ItemVariant.Description;
                "Description 2" := ItemVariant."Description 2";

                CheckItemAvailable(FieldNo("Variant Code"));
            end;
        }
        field(31; "Units per Parcel"; Decimal)
        {
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
        }
        field(32; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(33; "In-Transit Code"; Code[10])
        {
            Caption = 'In-Transit Code';
            Editable = false;
            TableRelation = Location where("Use As In-Transit" = const(true));

            trigger OnValidate()
            begin
                TestField("Quantity Shipped", 0);
            end;
        }
        field(34; "Qty. in Transit"; Decimal)
        {
            Caption = 'Qty. in Transit';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(35; "Qty. in Transit (Base)"; Decimal)
        {
            Caption = 'Qty. in Transit (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(36; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            Editable = false;
            TableRelation = Location;

            trigger OnValidate()
            begin
                TestField("Quantity Shipped", 0);
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                if "Transfer-from Code" <> xRec."Transfer-from Code" then begin
                    "Transfer-from Bin Code" := '';
                    GetDefaultBin("Transfer-from Code", '');
                end;

                OnValidateTransferFromCodeOnBeforeCheckItemAvailable(Rec);
                CheckItemAvailable(FieldNo("Transfer-from Code"));
                TransferLineReserve.VerifyChange(Rec, xRec);
                UpdateWithWarehouseShipReceive();
                WhseValidateSourceLine.TransLineVerifyChange(Rec, xRec);
            end;
        }
        field(37; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            Editable = false;
            TableRelation = Location;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateTransferToCode(Rec, xRec, CurrFieldNo, StatusCheckSuspended, IsHandled);
                if IsHandled then
                    exit;

                TestField("Quantity Shipped", 0);
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                if "Transfer-to Code" <> xRec."Transfer-to Code" then begin
                    "Transfer-To Bin Code" := '';
                    GetDefaultBin('', "Transfer-to Code");
                end;

                OnValidateTransferToCodeOnBeforeVerifyChange(Rec);
                TransferLineReserve.VerifyChange(Rec, xRec);
                UpdateWithWarehouseShipReceive();
                WhseValidateSourceLine.TransLineVerifyChange(Rec, xRec);
            end;
        }
        field(38; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();

                IsHandled := false;
                OnValidateShipmentDateOnBeforeCalcReceiptDate(IsHandled, Rec);
                if not IsHandled then
                    CalcReceiptDate();

                CheckItemAvailable(FieldNo("Shipment Date"));
                DateConflictCheck();
            end;
        }
        field(39; "Receipt Date"; Date)
        {
            Caption = 'Receipt Date';

            trigger OnValidate()
            var
                TransferLine: Record "Transfer Line";
                IsHandled: Boolean;
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();

                IsHandled := false;
                OnValidateReceiptDateOnBeforeCalcShipmentDate(IsHandled, Rec);
                if not IsHandled then
                    CalcShipmentDate();

                CheckItemAvailable(FieldNo("Shipment Date"));
                DateConflictCheck();
                if "Derived From Line No." = 0 then
                    if DerivedLinesExist(TransferLine, "Document No.", "Line No.") then
                        TransferLine.ModifyAll("Receipt Date", "Receipt Date");
            end;
        }
        field(40; "Derived From Line No."; Integer)
        {
            Caption = 'Derived From Line No.';
            TableRelation = "Transfer Line"."Line No." where("Document No." = field("Document No."));
        }
        field(41; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                if "Shipping Agent Code" <> xRec."Shipping Agent Code" then
                    Validate("Shipping Agent Service Code", '');
            end;
        }
        field(42; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                TransferRoute.GetShippingTime(
                  "Transfer-from Code", "Transfer-to Code",
                  "Shipping Agent Code", "Shipping Agent Service Code",
                  "Shipping Time");
                CalcReceiptDate();
                CheckItemAvailable(FieldNo("Shipping Agent Service Code"));
                DateConflictCheck();
            end;
        }
        field(43; "Appl.-to Item Entry"; Integer)
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
                ItemTrackingLines: Page "Item Tracking Lines";
            begin
                if "Appl.-to Item Entry" <> 0 then begin
                    TestField(Quantity);
                    ItemLedgEntry.Get("Appl.-to Item Entry");
                    ItemLedgEntry.TestField(Positive, true);
                    if (ItemLedgEntry."Lot No." <> '') or (ItemLedgEntry."Serial No." <> '') or (ItemLedgEntry."Package No." <> '') then
                        Error(MustUseTrackingErr, ItemTrackingLines.Caption, FieldCaption("Appl.-to Item Entry"));
                    if Abs("Qty. to Ship (Base)") > ItemLedgEntry.Quantity then
                        Error(ShippingMoreUnitsThanReceivedErr, ItemLedgEntry.Quantity, ItemLedgEntry."Document No.");

                    ItemLedgEntry.TestField("Location Code", "Transfer-from Code");
                    if not ItemLedgEntry.Open then
                        Message(LedgEntryWillBeOpenedMsg, "Appl.-to Item Entry");
                end;
            end;
        }
        field(50; "Reserved Quantity Inbnd."; Decimal)
        {
            CalcFormula = sum("Reservation Entry".Quantity where("Source ID" = field("Document No."),
                                                                  "Source Ref. No." = field("Line No."),
                                                                  "Source Type" = const(5741),
                                                                  "Source Subtype" = const("1"),
                                                                  "Source Prod. Order Line" = field("Derived From Line No."),
                                                                  "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity Inbnd.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(51; "Reserved Quantity Outbnd."; Decimal)
        {
            CalcFormula = - sum("Reservation Entry".Quantity where("Source ID" = field("Document No."),
                                                                   "Source Ref. No." = field("Line No."),
                                                                   "Source Type" = const(5741),
                                                                   "Source Subtype" = const("0"),
                                                                   "Source Prod. Order Line" = field("Derived From Line No."),
                                                                   "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity Outbnd.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Reserved Qty. Inbnd. (Base)"; Decimal)
        {
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Source ID" = field("Document No."),
                                                                           "Source Ref. No." = field("Line No."),
                                                                           "Source Type" = const(5741),
                                                                           "Source Subtype" = const("1"),
                                                                           "Source Prod. Order Line" = field("Derived From Line No."),
                                                                           "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. Inbnd. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(53; "Reserved Qty. Outbnd. (Base)"; Decimal)
        {
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Source ID" = field("Document No."),
                                                                            "Source Ref. No." = field("Line No."),
                                                                            "Source Type" = const(5741),
                                                                            "Source Subtype" = const("0"),
                                                                            "Source Prod. Order Line" = field("Derived From Line No."),
                                                                            "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. Outbnd. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(54; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Time';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                CalcReceiptDate();
                DateConflictCheck();
            end;
        }
        field(55; "Reserved Quantity Shipped"; Decimal)
        {
            CalcFormula = sum("Reservation Entry".Quantity where("Source ID" = field("Document No."),
                                                                  "Source Ref. No." = filter(<> 0),
                                                                  "Source Type" = const(5741),
                                                                  "Source Subtype" = const("1"),
                                                                  "Source Prod. Order Line" = field("Line No."),
                                                                  "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity Shipped';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "Reserved Qty. Shipped (Base)"; Decimal)
        {
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Source ID" = field("Document No."),
                                                                           "Source Ref. No." = filter(<> 0),
                                                                           "Source Type" = const(5741),
                                                                           "Source Subtype" = const("1"),
                                                                           "Source Prod. Order Line" = field("Line No."),
                                                                           "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. Shipped (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Direct Transfer"; Boolean)
        {
            Caption = 'Direct Transfer';
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
        field(5704; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        field(5750; "Whse. Inbnd. Otsdg. Qty (Base)"; Decimal)
        {
            BlankZero = true;
            CalcFormula = sum("Warehouse Receipt Line"."Qty. Outstanding (Base)" where("Source Type" = const(5741),
                                                                                        "Source Subtype" = const("1"),
                                                                                        "Source No." = field("Document No."),
                                                                                        "Source Line No." = field("Line No.")));
            Caption = 'Whse. Inbnd. Otsdg. Qty (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5751; "Whse Outbnd. Otsdg. Qty (Base)"; Decimal)
        {
            BlankZero = true;
            CalcFormula = sum("Warehouse Shipment Line"."Qty. Outstanding (Base)" where("Source Type" = const(5741),
                                                                                         "Source Subtype" = const("0"),
                                                                                         "Source No." = field("Document No."),
                                                                                         "Source Line No." = field("Line No.")));
            Caption = 'Whse Outbnd. Otsdg. Qty (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5752; "Completely Shipped"; Boolean)
        {
            Caption = 'Completely Shipped';
            Editable = false;
        }
        field(5753; "Completely Received"; Boolean)
        {
            Caption = 'Completely Received';
            Editable = false;
        }
        field(5793; "Outbound Whse. Handling Time"; DateFormula)
        {
            Caption = 'Outbound Whse. Handling Time';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                CalcReceiptDate();
                DateConflictCheck();
            end;
        }
        field(5794; "Inbound Whse. Handling Time"; DateFormula)
        {
            Caption = 'Inbound Whse. Handling Time';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                CalcReceiptDate();
                DateConflictCheck();
            end;
        }
        field(7300; "Transfer-from Bin Code"; Code[20])
        {
            Caption = 'Transfer-from Bin Code';
            TableRelation = "Bin Content"."Bin Code" where("Location Code" = field("Transfer-from Code"),
                                                            "Item No." = field("Item No."),
                                                            "Variant Code" = field("Variant Code"));

            trigger OnValidate()
            begin
                if "Transfer-from Bin Code" <> xRec."Transfer-from Bin Code" then begin
                    TestField("Transfer-from Code");
                    if "Transfer-from Bin Code" <> '' then begin
                        GetLocation("Transfer-from Code");
                        Location.TestField("Bin Mandatory");
                        Location.TestField("Directed Put-away and Pick", false);
                        GetBin("Transfer-from Code", "Transfer-from Bin Code");
                        TestField("Transfer-from Code", Bin."Location Code");
                        HandleDedicatedBin(true);
                    end;
                end;
            end;
        }
        field(7301; "Transfer-To Bin Code"; Code[20])
        {
            Caption = 'Transfer-To Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Transfer-to Code"));

            trigger OnValidate()
            begin
                if "Transfer-To Bin Code" <> xRec."Transfer-To Bin Code" then begin
                    TestField("Transfer-to Code");
                    if "Transfer-To Bin Code" <> '' then begin
                        GetLocation("Transfer-to Code");
                        Location.TestField("Bin Mandatory");
                        Location.TestField("Directed Put-away and Pick", false);
                        GetBin("Transfer-to Code", "Transfer-To Bin Code");
                        TestField("Transfer-to Code", Bin."Location Code");
                    end;
                end;
            end;
        }
        field(99000755; "Planning Flexibility"; Enum "Reservation Planning Flexibility")
        {
            Caption = 'Planning Flexibility';

            trigger OnValidate()
            begin
                if "Planning Flexibility" <> xRec."Planning Flexibility" then
                    TransferLineReserve.UpdatePlanningFlexibility(Rec);
            end;
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Transfer-to Code", Status, "Derived From Line No.", "Item No.", "Variant Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Receipt Date", "In-Transit Code")
        {
            IncludedFields = "Qty. in Transit (Base)", "Outstanding Qty. (Base)", "Shipment Date";
        }
        key(Key3; "Transfer-from Code", Status, "Derived From Line No.", "Item No.", "Variant Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Shipment Date", "In-Transit Code")
        {
        }
        key(Key4; "Item No.", "Variant Code")
        {
        }
        key(Key5; "Transfer-to Code", "Receipt Date", "Item No.", "Variant Code")
        {
        }
        key(Key6; "Transfer-from Code", "Shipment Date", "Item No.", "Variant Code")
        {
        }
        key(Key7; "Document No.", "Item No.", "Transfer-from Code", "Transfer-from Bin Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Item No.", Description, Quantity, "Unit of Measure", "Transfer-from Code", "Transfer-to Code")
        {
        }
    }

    trigger OnDelete()
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        OnBeforeOnDelete(Rec);
        TestStatusOpen();

        TestField("Quantity Shipped", "Quantity Received");
        TestField("Qty. Shipped (Base)", "Qty. Received (Base)");
        CalcFields("Reserved Qty. Inbnd. (Base)", "Reserved Qty. Outbnd. (Base)");
        TestField("Reserved Qty. Inbnd. (Base)", 0);
        TestField("Reserved Qty. Outbnd. (Base)", 0);

        OnDeleteOnBeforeDeleteRelatedData(Rec);

        TransferLineReserve.DeleteLine(Rec);
        WhseValidateSourceLine.TransLineDelete(Rec);

        ItemChargeAssgntPurch.SetCurrentKey(
          "Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", ItemChargeAssgntPurch."Applies-to Doc. Type"::"Transfer Receipt");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. No.", "Document No.");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.", "Line No.");
        ItemChargeAssgntPurch.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        TransLine2: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, xRec, TransHeader, IsHandled);
        if IsHandled then
            exit;

        TestStatusOpen();

        IsHandled := false;
        OnInsertOnBeforeAssignLineNo(Rec, IsHandled);
        if not IsHandled then begin
            TransLine2.Reset();
            TransLine2.SetFilter("Document No.", TransHeader."No.");
            if TransLine2.FindLast() then
                "Line No." := TransLine2."Line No." + 10000;
        end;
        TransferLineReserve.VerifyQuantity(Rec, xRec);
    end;

    trigger OnModify()
    begin
        if ItemExists(xRec."Item No.") then
            TransferLineReserve.VerifyChange(Rec, xRec);
    end;

    trigger OnRename()
    begin
        Error(Text001, TableCaption);
    end;

    var
        TransferRoute: Record "Transfer Route";
        Item: Record Item;
        TransHeader: Record "Transfer Header";
        Location: Record Location;
        Bin: Record Bin;
        DimMgt: Codeunit DimensionManagement;
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
        CheckDateConflict: Codeunit "Reservation-Check Date Confl.";
        WMSManagement: Codeunit "WMS Management";
        ConfirmManagement: Codeunit "Confirm Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        Reservation: Page Reservation;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You cannot rename a %1.';
        Text002: Label 'must not be less than %1';
        Text003: Label 'Warehouse %1 is required for %2 = %3.';
#pragma warning restore AA0470
        Text004: Label '\The entered information may be disregarded by warehouse operations.';
#pragma warning disable AA0470
        Text005: Label 'You cannot ship more than %1 units.';
#pragma warning restore AA0470
        Text006: Label 'All items have been shipped.';
#pragma warning disable AA0470
        Text008: Label 'You cannot receive more than %1 units.';
#pragma warning restore AA0470
        Text009: Label 'No items are currently in transit.';
        Text011: Label 'Outbound,Inbound';
#pragma warning disable AA0470
        Text012: Label 'You have changed one or more dimensions on the %1, which is already shipped. When you post the line with the changed dimension to General Ledger, amounts on the Inventory Interim account will be out of balance when reported per dimension.\\Do you want to keep the changed dimension?';
#pragma warning restore AA0470
        Text013: Label 'Cancelled.';
#pragma warning restore AA0074
        CannotAutoReserveErr: Label 'Quantity %1 in line %2 cannot be reserved automatically.', Comment = '%1 - quantity, %2 - line number';
        MustUseTrackingErr: Label 'You must use the %1 page to specify the %2, if you use item tracking.', Comment = '%1 = Form Name, %2 = Value to Enter';
        LedgEntryWillBeOpenedMsg: Label 'When posting the Applied to Ledger Entry %1 will be opened first.', Comment = '%1 = Entry No.';
        ShippingMoreUnitsThanReceivedErr: Label 'You cannot ship more than the %1 units that you have received for document no. %2.', Comment = '%1 = Quantity Value, %2 = Document No.';
        AnotherItemWithSameDescrQst: Label 'We found an item with the description "%2" (No. %1).\Did you mean to change the current item to %1?', Comment = '%1=Item no., %2=item description';

    protected var
        StatusCheckSuspended, TrackingBlocked : Boolean;

    /// <summary>
    /// Initializes outstanding quantity and base quantity for the current transfer line.
    /// </summary>
    procedure InitOutstandingQty()
    begin
        "Outstanding Quantity" := Quantity - "Quantity Shipped";
        "Outstanding Qty. (Base)" := "Quantity (Base)" - "Qty. Shipped (Base)";
        "Completely Shipped" := (Quantity <> 0) and ("Outstanding Quantity" = 0);

        OnAfterInitOutstandingQty(Rec, CurrFieldNo);
    end;

    /// <summary>
    /// Initializes quantity to ship fields for the current transfer line.
    /// </summary>
    procedure InitQtyToShip()
    begin
        "Qty. to Ship" := "Outstanding Quantity";
        "Qty. to Ship (Base)" := "Outstanding Qty. (Base)";

        OnAfterInitQtyToShip(Rec, CurrFieldNo);
    end;

    /// <summary>
    /// Initializes quantity to receive based on in transit location for the current transfer line.
    /// </summary>
    procedure InitQtyToReceive()
    begin
        if "In-Transit Code" <> '' then begin
            "Qty. to Receive" := "Qty. in Transit";
            "Qty. to Receive (Base)" := "Qty. in Transit (Base)";
        end;
        if ("In-Transit Code" = '') and ("Quantity Shipped" = "Quantity Received") then begin
            "Qty. to Receive" := "Qty. to Ship";
            "Qty. to Receive (Base)" := "Qty. to Ship (Base)";
        end;

        OnAfterInitQtyToReceive(Rec, CurrFieldNo);
    end;

    /// <summary>
    /// Calculates the quantity in transit based on in transit location for the current transfer line.
    /// Verifies whether the transfer line is completely received by checking if the Quantity is not zero and if it is equal to the "Quantity Received".
    /// </summary>
    procedure InitQtyInTransit()
    begin
        if "In-Transit Code" <> '' then begin
            "Qty. in Transit" := "Quantity Shipped" - "Quantity Received";
            "Qty. in Transit (Base)" := "Qty. Shipped (Base)" - "Qty. Received (Base)";
        end else begin
            "Qty. in Transit" := 0;
            "Qty. in Transit (Base)" := 0;
        end;
        "Completely Received" := (Quantity <> 0) and (Quantity = "Quantity Received");

        OnAfterInitQtyInTransit(Rec, CurrFieldNo);
    end;

    local procedure CalcReceiptDate()
    begin
        TransferRoute.CalcReceiptDate("Shipment Date", "Receipt Date",
            "Shipping Time", "Outbound Whse. Handling Time", "Inbound Whse. Handling Time",
            "Transfer-from Code", "Transfer-to Code", "Shipping Agent Code", "Shipping Agent Service Code");
    end;

    local procedure CalcShipmentDate()
    begin
        TransferRoute.CalcShipmentDate("Shipment Date", "Receipt Date",
            "Shipping Time", "Outbound Whse. Handling Time", "Inbound Whse. Handling Time",
            "Transfer-from Code", "Transfer-to Code", "Shipping Agent Code", "Shipping Agent Service Code");
    end;

    /// <summary>
    /// Resets the posted quantities for the current transfer line.
    /// </summary>
    procedure ResetPostedQty()
    begin
        "Quantity Shipped" := 0;
        "Qty. Shipped (Base)" := 0;
        "Quantity Received" := 0;
        "Qty. Received (Base)" := 0;
        "Qty. in Transit" := 0;
        "Qty. in Transit (Base)" := 0;

        OnAfterResetPostedQty(Rec);
    end;

    /// <summary>
    /// Retrieves the transfer header information and assigns it to the corresponding fields in the current transfer line.
    /// </summary>
    procedure GetTransHeaderExternal()
    begin
        GetTransHeader();
    end;

    local procedure GetTransHeader()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetTransHeader(Rec, TransHeader, IsHandled);
        if IsHandled then
            exit;

        GetTransferHeaderNoVerification();

        CheckTransferHeader(TransHeader);

        "In-Transit Code" := TransHeader."In-Transit Code";
        "Transfer-from Code" := TransHeader."Transfer-from Code";
        "Transfer-to Code" := TransHeader."Transfer-to Code";
        "Shipment Date" := TransHeader."Shipment Date";
        "Receipt Date" := TransHeader."Receipt Date";
        "Shipping Agent Code" := TransHeader."Shipping Agent Code";
        "Shipping Agent Service Code" := TransHeader."Shipping Agent Service Code";
        "Shipping Time" := TransHeader."Shipping Time";
        "Outbound Whse. Handling Time" := TransHeader."Outbound Whse. Handling Time";
        "Inbound Whse. Handling Time" := TransHeader."Inbound Whse. Handling Time";
        Status := TransHeader.Status;
        "Direct Transfer" := TransHeader."Direct Transfer";

        OnAfterGetTransHeader(Rec, TransHeader);
    end;

    local procedure CheckTransferHeader(TransferHeader: Record "Transfer Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTransferHeader(TransferHeader, IsHandled, Rec, xRec);
        if IsHandled then
            exit;

        TransHeader.TestField("Shipment Date");
        TransHeader.TestField("Receipt Date");
        TransHeader.TestField("Transfer-from Code");
        TransHeader.TestField("Transfer-to Code");
        if not TransHeader."Direct Transfer" and ("Direct Transfer" = xRec."Direct Transfer") then
            TransHeader.TestField("In-Transit Code");
    end;

    local procedure GetItem()
    begin
        TestField("Item No.");
        if "Item No." <> Item."No." then
            Item.Get("Item No.");
    end;

    local procedure GetItemNo(): Code[20]
    var
        ReturnValue: Text[50];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItemNo(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit("Item No.");

        Item.TryGetItemNo(ReturnValue, "Item No.", true);
        exit(CopyStr(ReturnValue, 1, MaxStrLen("Item No.")));
    end;

    /// <summary>
    /// Sets the block status for dynamic tracking of the transfer line.
    /// </summary>
    /// <param name="SetBlock">Specifies whether to block dynamic tracking.</param>
    /// <remarks>Global parameter 'TrackingBlocked' is used to prevent date conflict check.</remarks>
    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        TrackingBlocked := SetBlock;
        TransferLineReserve.Block(SetBlock);
    end;

    /// <summary>
    /// Opens a page that shows the dimensions of the current transfer line.
    /// </summary>
    ///<remarks>In case transfer line is partially shipped, confirmation dialog will appear.</remarks>
    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."));
        VerifyItemLineDim();
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec, xRec);
    end;

    /// <summary>
    /// Generates a new dimension set id from provided default dimensions for the current transfer line.
    /// </summary>
    /// <param name="DefaultDimSource">Provided list of default dimensions.</param>
    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup.Transfer,
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", TransHeader."Dimension Set ID", Database::Location);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterCreateDim(Rec, DefaultDimSource, xRec, CurrFieldNo);
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

    local procedure ValidateQuantityReceiveIsBalanced()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQuantityReceiveIsBalanced(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        UOMMgt.ValidateQtyIsBalanced(Quantity, "Quantity (Base)", "Qty. to Receive", "Qty. to Receive (Base)", "Quantity Received", "Qty. Received (Base)");
    end;

    /// <summary>
    /// Triggers validation of shortcut dimension values.
    /// </summary>
    /// <param name="FieldNumber">Indicates the number of a field which is invoked by the method.</param>
    /// <param name="ShortcutDimCode">Specified value of the shortcut dimension.</param>
    ///<remarks>In case transfer line is partially shipped, confirmation dialog will appear.</remarks>
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        VerifyItemLineDim();

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    /// <summary>
    /// Displays a shortcut dimension list for the user to choose from.
    /// </summary>
    /// <param name="FieldNumber">Dimension shortcut ordinal number.</param>
    /// <param name="ShortcutDimCode">Selected shortcut dimension code.</param>
    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        Rec.ValidateShortcutDimCode(FieldNumber, ShortcutDimCode);
    end;

    /// <summary>
    /// Retrieves a shortcut dimension list for the current transfer line.
    /// </summary>
    /// <param name="ShortcutDimCode">Array to hold the dimension information.</param>
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    /// <summary>
    /// Runs an item list page for the user to select multiple items for transfer.
    /// </summary>
    procedure SelectMultipleItems()
    var
        ItemListPage: Page "Item List";
        SelectionFilter: Text;
    begin
        OnBeforeSelectMultipleItems(Rec);

        SelectionFilter := ItemListPage.SelectActiveItemsForTransfer();
        if SelectionFilter <> '' then
            AddItems(SelectionFilter);

        OnAfterSelectMultipleItems(Rec);
    end;

    /// <summary>
    /// Adds items to the transfer line based on the specified selection filter.
    /// </summary>
    /// <param name="SelectionFilter">The filter to apply when selecting items.</param>
    procedure AddItems(SelectionFilter: Text)
    var
        SelectedItem: Record Item;
        TransferLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddItems(Rec, SelectionFilter, IsHandled);
        if IsHandled then
            exit;

        if SelectionFilter = '' then
            exit;

        InitNewLine(TransferLine);
        SelectedItem.SetLoadFields("No.");
        SelectedItem.SetFilter("No.", SelectionFilter);
        if SelectedItem.FindSet() then
            repeat
                AddItem(TransferLine, SelectedItem."No.");
            until SelectedItem.Next() = 0;
    end;

    /// <summary>
    /// Creates a new transfer line and validates item no based on provided 'ItemNo'.
    /// </summary>
    /// <param name="TransferLine">The transfer line record.</param>
    /// <param name="ItemNo">The item number.</param>
    procedure AddItem(var TransferLine: Record "Transfer Line"; ItemNo: Code[20])
    begin
        TransferLine.Init();
        TransferLine."Line No." += 10000;
        TransferLine.Validate("Item No.", ItemNo);
        TransferLine.Insert(true);

        OnAfterAddItem(TransferLine);
    end;

    /// <summary>
    /// Initializes a new transfer line based on the current record.
    /// </summary>
    /// <param name="NewTransferLine">The new transfer line record.</param>
    procedure InitNewLine(var NewTransferLine: Record "Transfer Line")
    var
        TransferLine: Record "Transfer Line";
    begin
        NewTransferLine.Copy(Rec);
        TransferLine.SetLoadFields("Line No.");
        TransferLine.SetRange("Document No.", NewTransferLine."Document No.");
        if TransferLine.FindLast() then
            NewTransferLine."Line No." := TransferLine."Line No."
        else
            NewTransferLine."Line No." := 0;
    end;

    /// <summary>
    /// Checks if an item is available for transfer.
    /// </summary>
    /// <param name="CalledByFieldNo">The field number that triggered the check.</param>
    procedure CheckItemAvailable(CalledByFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemAvailable(Rec, CalledByFieldNo, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if (CurrFieldNo <> 0) and
           (CurrFieldNo = CalledByFieldNo) and
           ("Item No." <> '') and
           ("Outstanding Quantity" > 0)
        then
            if ItemCheckAvail.TransferLineCheck(Rec) then
                ItemCheckAvail.RaiseUpdateInterruptedError();
    end;

    local procedure CheckItemCanBeShipped()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemCanBeShipped(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Qty. to Ship" > "Outstanding Quantity" then
            if "Outstanding Quantity" > 0 then
                Error(
                  Text005,
                  "Outstanding Quantity")
            else
                Error(Text006);
    end;

    /// <summary>
    /// Checks if the entire quantity on the line is shipped in case of direct Transfer.
    /// </summary>
    procedure CheckDirectTransferQtyToShip()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        if "Qty. to Ship" = 0 then
            exit;

        InventorySetup.Get();
        if InventorySetup."Direct Transfer Posting" <> InventorySetup."Direct Transfer Posting"::"Direct Transfer" then
            exit;

        GetTransferHeaderNoVerification();
        if TransHeader."Direct Transfer" then begin
            TestField("Qty. to Ship", Quantity);
            TestField("Qty. to Ship (Base)", "Quantity (Base)");
        end;
    end;

    /// <summary>
    /// Opens the item tracking lines for the specified transfer direction.
    /// </summary>
    /// <param name="Direction">The transfer direction.</param>
    /// <remarks>Transfer direction can be either outbound or inbound.</remarks>
    procedure OpenItemTrackingLines(Direction: Enum "Transfer Direction")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenItemTrackingLines(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Item No.");
        TestField("Quantity (Base)");

        TransferLineReserve.CallItemTracking(Rec, Direction);
    end;

    /// <summary>
    /// Opens the item tracking lines for the specified transfer direction.
    /// </summary>
    /// <param name="Direction">The transfer direction.</param>
    /// <remarks>Transfer direction can be either outbound or inbound.
    /// Item tracking page will be run in direct transfer mode.</remarks>
    procedure OpenItemTrackingLinesWithReclass(Direction: Enum "Transfer Direction")
    begin
        TestField("Item No.");
        TestField("Quantity (Base)");

        TransferLineReserve.CallItemTracking(Rec, Direction, true);
    end;

    /// <summary>
    /// Test whether the status of a transfer document is set to 'Open'.
    /// </summary>
    procedure TestStatusOpen()
    var
        IsHandled: Boolean;
    begin
        if StatusCheckSuspended then
            exit;

        TestField("Document No.");
        if TransHeader."No." <> "Document No." then
            TransHeader.Get("Document No.");

        IsHandled := false;
        OnBeforeTestStatusOpen(Rec, TransHeader, IsHandled);
        if not IsHandled then
            TransHeader.TestField(Status, TransHeader.Status::Open);

        OnAfterTestStatusOpen(Rec, TransHeader);
    end;

    /// <summary>
    /// Sets the status check suspension flag.
    /// </summary>
    /// <param name="Suspend">A boolean value indicating whether to suspend the status check.</param>
    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    /// <summary>
    /// Displays the reservation for the transfer line.
    /// </summary>
    procedure ShowReservation()
    var
        OptionNumber: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowReservation(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Item No.");
        Item.Get("Item No.");
        Item.TestField(Reserve);
        Clear(Reservation);
        OptionNumber := StrMenu(Text011);
        if OptionNumber > 0 then begin
            Reservation.SetReservSource(Rec, Enum::"Transfer Direction".FromInteger(OptionNumber - 1));
            Reservation.RunModal();
        end;

        OnAfterShowReservation(Rec);
    end;

    /// <summary>
    /// Updates "Qty. to Ship" and "Qty. to Receive" fields of current transfer line based on location setup.
    /// </summary>
    procedure UpdateWithWarehouseShipReceive()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateWithWarehouseShipReceive(Rec, IsHandled);
        if IsHandled then
            exit;

        if Location.RequireShipment("Transfer-from Code") then
            Validate("Qty. to Ship", 0)
        else
            Validate("Qty. to Ship", "Outstanding Quantity");

        if Location.RequireReceive("Transfer-to Code") then
            Validate("Qty. to Receive", 0)
        else begin
            if "In-Transit Code" <> '' then
                Validate("Qty. to Receive", "Qty. in Transit");
            if ("In-Transit Code" = '') and ("Quantity Shipped" = "Quantity Received") then
                Validate("Qty. to Receive", "Qty. to Ship");
        end;

        OnAfterUpdateWithWarehouseShipReceive(Rec, CurrFieldNo);
    end;

    /// <summary>
    /// Renames the item number in the transfer line table.
    /// </summary>
    /// <param name="OldNo">The old item number.</param>
    /// <param name="NewNo">The new item number.</param>
    procedure RenameNo(OldNo: Code[20]; NewNo: Code[20])
    begin
        Reset();
        SetRange("Item No.", OldNo);
        if not Rec.IsEmpty() then
            ModifyAll("Item No.", NewNo, true);
    end;

    /// <summary>
    /// Checks warehouse requirements for a transfer line.
    /// It determines whether a dialog should be displayed to the user based on the location setup and receive flag.
    /// In case a dialog needs to be displayed, an appropriate message or error is presented.
    /// </summary>
    /// <param name="Location">The location record for the transfer line.</param>
    /// <param name="Receive">A boolean flag indicating whether the transfer line is for receiving or not.</param>
    procedure CheckWarehouse(Location: Record Location; Receive: Boolean)
    var
        ShowDialog: Option " ",Message,Error;
        DialogText: Text[50];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWarehouse(Rec, Location, Receive, IsHandled);
        if IsHandled then
            exit;

        if Location."Directed Put-away and Pick" then begin
            ShowDialog := ShowDialog::Error;
            if Receive then
                DialogText := Location.GetRequirementText(Location.FieldNo("Require Receive"))
            else
                DialogText := Location.GetRequirementText(Location.FieldNo("Require Shipment"));
        end else begin
            if Receive and (Location."Require Receive" or Location."Require Put-away") then begin
                if WhseValidateSourceLine.WhseLinesExist(
                     DATABASE::"Transfer Line", 1, "Document No.", "Line No.", 0, Quantity)
                then
                    ShowDialog := ShowDialog::Error
                else
                    if Location."Require Receive" then
                        ShowDialog := ShowDialog::Message;
                if Location."Require Receive" then
                    DialogText := Location.GetRequirementText(Location.FieldNo("Require Receive"))
                else
                    DialogText := Location.GetRequirementText(Location.FieldNo("Require Put-away"));
            end;

            if not Receive and (Location."Require Shipment" or Location."Require Pick") then begin
                if WhseValidateSourceLine.WhseLinesExist(
                     DATABASE::"Transfer Line", 0, "Document No.", "Line No.", 0, Quantity)
                then
                    ShowDialog := ShowDialog::Error
                else
                    if Location."Require Shipment" then
                        ShowDialog := ShowDialog::Message;
                if Location."Require Shipment" then
                    DialogText := Location.GetRequirementText(Location.FieldNo("Require Shipment"))
                else
                    DialogText := Location.GetRequirementText(Location.FieldNo("Require Pick"));
            end;
        end;

        OnCheckWarehouseOnBeforeShowDialog(Rec, Location, ShowDialog, DialogText);
        case ShowDialog of
            ShowDialog::Message:
                Message(Text003 + Text004, DialogText, FieldCaption("Line No."), "Line No.");
            ShowDialog::Error:
                Error(Text003, DialogText, FieldCaption("Line No."), "Line No.");
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if BinCode = '' then
            Clear(Bin)
        else
            if (Bin.Code <> BinCode) or (Bin."Location Code" <> LocationCode) then
                Bin.Get(LocationCode, BinCode);
    end;

    local procedure GetDefaultBin(FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultBin(Rec, IsHandled);
        if IsHandled then
            exit;

        if (FromLocationCode <> '') and ("Item No." <> '') then begin
            GetLocation(FromLocationCode);
            if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then begin
                WMSManagement.GetDefaultBin("Item No.", "Variant Code", FromLocationCode, "Transfer-from Bin Code");
                HandleDedicatedBin(false);
            end;
        end;

        if (ToLocationCode <> '') and ("Item No." <> '') then begin
            GetLocation(ToLocationCode);
            if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                WMSManagement.GetDefaultBin("Item No.", "Variant Code", ToLocationCode, "Transfer-To Bin Code");
        end;

        OnAfterGetDefaultBin(Rec, FromLocationCode, ToLocationCode);
    end;

    local procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    begin
        OnBeforeCalcBaseQty(Rec, Qty, FromFieldName, ToFieldName);

        exit(UOMMgt.CalcBaseQty(
            "Item No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    /// <summary>
    /// Calculates remaining quantity and remaining base quantity according to specified direction for the current transfer line.
    /// </summary>
    /// <param name="RemainingQty">The remaining quantity.</param>
    /// <param name="RemainingQtyBase">The remaining base quantity.</param>
    /// <param name="Direction">Direction of the transfer (0 for outbound, 1 for inbound).</param>
    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal; Direction: Integer)
    begin
        case Direction of
            0: // Outbound
                begin
                    CalcFields("Reserved Quantity Outbnd.", "Reserved Qty. Outbnd. (Base)");
                    RemainingQty := "Outstanding Quantity" - Abs("Reserved Quantity Outbnd.");
                    RemainingQtyBase := "Outstanding Qty. (Base)" - Abs("Reserved Qty. Outbnd. (Base)");
                end;
            1: // Inbound
                begin
                    CalcFields("Reserved Quantity Inbnd.", "Reserved Qty. Inbnd. (Base)");
                    RemainingQty := "Outstanding Quantity" - Abs("Reserved Quantity Inbnd.");
                    RemainingQtyBase := "Outstanding Qty. (Base)" - Abs("Reserved Qty. Inbnd. (Base)");
                end;
        end;
    end;

    /// <summary>
    /// Retrieves reservation quantities for the current transfer line.
    /// </summary>
    /// <param name="QtyReserved">The quantity reserved.</param>
    /// <param name="QtyReservedBase">The quantity reserved in base units.</param>
    /// <param name="QtyToReserve">The quantity to be reserved.</param>
    /// <param name="QtyToReserveBase">The quantity to be reserved in base units.</param>
    /// <param name="Direction">Direction of the transfer (0 for outbound, 1 for inbound).</param>
    /// <returns>The quantity per unit of measure.</returns>
    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; Direction: Integer) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReservationQty(Rec, QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, Direction, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Direction = 0 then begin // Outbound
            CalcFields("Reserved Quantity Outbnd.", "Reserved Qty. Outbnd. (Base)");
            QtyReserved := "Reserved Quantity Outbnd.";
            QtyReservedBase := "Reserved Qty. Outbnd. (Base)";
            QtyToReserve := "Outstanding Quantity";
            QtyToReserveBase := "Outstanding Qty. (Base)";
        end else begin // Inbound
            CalcFields("Reserved Quantity Inbnd.", "Reserved Qty. Inbnd. (Base)");
            QtyReserved := "Reserved Quantity Inbnd.";
            QtyReservedBase := "Reserved Qty. Inbnd. (Base)";
            QtyToReserve := "Outstanding Quantity";
            QtyToReserveBase := "Outstanding Qty. (Base)";
        end;
        exit("Qty. per Unit of Measure");
    end;

    /// <summary>
    /// Combines values of "Document No.", "Line No." and "Item No." fields of the current transfer line.
    /// </summary>
    /// <returns>Returns source transfer line information.</returns>
    procedure GetSourceCaption(): Text
    begin
        exit(StrSubstNo('%1 %2 %3', "Document No.", "Line No.", "Item No."));
    end;

    /// <summary>
    /// Sets the reservation entry for the current transfer line based on specified direction.
    /// </summary>
    /// <param name="ReservEntry">The reservation entry record to set.</param>
    /// <param name="Direction">The transfer direction.</param>
    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry"; Direction: Enum "Transfer Direction")
    begin
        ReservEntry.SetSource(
            DATABASE::"Transfer Line", Direction.AsInteger(), "Document No.", "Line No.", '', "Derived From Line No.");
        case Direction of
            Direction::Outbound:
                begin
                    ReservEntry.SetItemData(
                        "Item No.", Description, "Transfer-from Code", "Variant Code", "Qty. per Unit of Measure");
                    ReservEntry."Shipment Date" := "Shipment Date";
                    ReservEntry."Expected Receipt Date" := "Shipment Date";
                end;
            Direction::Inbound:
                begin
                    ReservEntry.SetItemData(
                        "Item No.", Description, "Transfer-to Code", "Variant Code", "Qty. per Unit of Measure");
                    ReservEntry."Shipment Date" := "Receipt Date";
                    ReservEntry."Expected Receipt Date" := "Receipt Date";
                end;
        end;
    end;

    /// <summary>
    /// Sets filters for the specified reservation entry based on the transfer direction.
    /// </summary>
    /// <param name="ReservEntry">The reservation entry record to set the filters for.</param>
    /// <param name="Direction">The transfer direction.</param>
    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry"; Direction: Enum "Transfer Direction")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Transfer Line", Direction.AsInteger(), "Document No.", "Line No.", false);
        ReservEntry.SetSourceFilter('', "Derived From Line No.");

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    /// <summary>
    /// Checks if a reservation entry exists for the transfer line.
    /// </summary>
    /// <returns>
    /// Returns true in case reservation entry exists, otherwise false.
    /// </returns>
    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry, Enum::"Transfer Direction"::Outbound);
        ReservEntry.SetRange("Source Subtype"); // Ignore direction
        exit(not ReservEntry.IsEmpty);
    end;

    /// <summary>
    /// Checks if the current transfer line is inbound.
    /// </summary>
    /// <returns>
    /// Returns true if the quantity (base) is less than 0, indicating an inbound transfer line.
    /// Returns false otherwise.
    /// </returns>
    procedure IsInbound(): Boolean
    begin
        exit("Quantity (Base)" < 0);
    end;

    local procedure HandleDedicatedBin(IssueWarning: Boolean)
    var
        WhseIntegrationMgt: Codeunit "Whse. Integration Management";
    begin
        if not IsInbound() and ("Quantity (Base)" <> 0) then
            WhseIntegrationMgt.CheckIfBinDedicatedOnSrcDoc("Transfer-from Code", "Transfer-from Bin Code", IssueWarning);
    end;

    /// <summary>
    /// Filters the lines with the provided item for planning.
    /// </summary>
    /// <param name="Item">Provided item record.</param>
    /// <param name="IsReceipt">Specifies whether transfer line is a receipt or not.</param>
    /// <param name="IsSupplyForPlanning">Specifies whether it is supply for planning or not.</param>
    procedure FilterLinesWithItemToPlan(var Item: Record Item; IsReceipt: Boolean; IsSupplyForPlanning: Boolean)
    begin
        Reset();
        SetCurrentKey("Item No.");
        SetRange("Item No.", Item."No.");
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        if not IsSupplyForPlanning then
            SetRange("Derived From Line No.", 0);
        if IsReceipt then begin
            SetFilter("Transfer-to Code", Item.GetFilter("Location Filter"));
            SetFilter("Receipt Date", Item.GetFilter("Date Filter"))
        end else begin
            SetFilter("Transfer-from Code", Item.GetFilter("Location Filter"));
            SetFilter("Shipment Date", Item.GetFilter("Date Filter"));
            SetFilter("Outstanding Qty. (Base)", '<>0');
        end;
        SetFilter("Shortcut Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        SetFilter("Shortcut Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));
        OnAfterFilterLinesWithItemToPlan(Item, IsReceipt, IsSupplyForPlanning, Rec);
    end;

    /// <summary>
    /// Finds the lines with the provided item to plan.
    /// </summary>
    /// <param name="Item">Provided item record.</param>
    /// <param name="IsReceipt">Specifies whether the transfer line is a receipt.</param>
    /// <param name="IsSupplyForPlanning">Specifies whether the item is supply for planning.</param>
    /// <returns>True in case the lines with the item to plan are found, otherwise false.</returns>
    procedure FindLinesWithItemToPlan(var Item: Record Item; IsReceipt: Boolean; IsSupplyForPlanning: Boolean): Boolean
    begin
        FilterLinesWithItemToPlan(Item, IsReceipt, IsSupplyForPlanning);
        exit(Find('-'));
    end;

    /// <summary>
    /// Checks if there are any lines with the provided item that need to be planned.
    /// </summary>
    /// <param name="Item">Provided item record.</param>
    /// <param name="IsReceipt">Specifies whether the transfer line is a receipt or not.</param>
    /// <returns>True if there are lines with the item that need to be planned, otherwise false.</returns>
    procedure LinesWithItemToPlanExist(var Item: Record Item; IsReceipt: Boolean): Boolean
    begin
        FilterLinesWithItemToPlan(Item, IsReceipt, false);
        exit(not IsEmpty);
    end;

    /// <summary>
    /// Filters the inbound transfer lines based on provided reservation entry and availability date filter.
    /// </summary>
    /// <param name="ReservationEntry">Provided reservation entry record.</param>
    /// <param name="AvailabilityFilter">The availability date filter.</param>
    /// <param name="Positive">A boolean value indicating whether to filter for positive or negative outstanding quantities.</param>
    procedure FilterInboundLinesForReservation(ReservationEntry: Record "Reservation Entry"; AvailabilityFilter: Text; Positive: Boolean)
    begin
        Reset();
        SetCurrentKey("Transfer-to Code", "Receipt Date", "Item No.", "Variant Code");
        SetRange("Item No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Transfer-to Code", ReservationEntry."Location Code");
        SetFilter("Receipt Date", AvailabilityFilter);
        if Positive then
            SetFilter("Outstanding Qty. (Base)", '>0')
        else
            SetFilter("Outstanding Qty. (Base)", '<0');

        OnAfterFilterInboundLinesForReservation(Rec, ReservationEntry, AvailabilityFilter, Positive);
    end;

    /// <summary>
    /// Filters the outbound transfer lines based on provided reservation entry and availability date filter.
    /// </summary>
    /// <param name="ReservationEntry">Provided reservation entry record.</param>
    /// <param name="AvailabilityFilter">The availability date filter.</param>
    /// <param name="Positive">A boolean value indicating whether to filter for positive or negative outstanding quantities.</param>
    procedure FilterOutboundLinesForReservation(ReservationEntry: Record "Reservation Entry"; AvailabilityFilter: Text; Positive: Boolean)
    begin
        Reset();
        SetCurrentKey("Transfer-from Code", "Shipment Date", "Item No.", "Variant Code");
        SetRange("Item No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Transfer-from Code", ReservationEntry."Location Code");
        SetFilter("Shipment Date", AvailabilityFilter);
        if Positive then
            SetFilter("Outstanding Qty. (Base)", '<0')
        else
            SetFilter("Outstanding Qty. (Base)", '>0');

        OnAfterFilterOutboundLinesForReservation(Rec, ReservationEntry, AvailabilityFilter, Positive);
    end;

    /// <summary>
    /// Verifies if the item line dimensions have been changed and confirms the change if necessary.
    /// </summary>
    procedure VerifyItemLineDim()
    begin
        if IsShippedDimChanged() then
            ConfirmShippedDimChange();
    end;

    /// <summary>
    /// Automatically creates reservations for the item quantity of provided transfer lines.
    /// </summary>
    /// <param name="TransLine">Provided transfer line records.</param>
    procedure ReserveFromInventory(var TransLine: Record "Transfer Line")
    var
        ReservMgt: Codeunit "Reservation Management";
        SourceRecRef: RecordRef;
        AutoReserved: Boolean;
    begin
        TransLine.SetAutoCalcFields("Reserved Quantity Outbnd.", "Reserved Qty. Outbnd. (Base)");
        if TransLine.FindSet() then
            repeat
                SourceRecRef.GetTable(TransLine);
                ReservMgt.SetReservSource(SourceRecRef);
                TransLine.TestField("Shipment Date");
                ReservMgt.AutoReserveToShip(
                  AutoReserved, '', TransLine."Shipment Date",
                  TransLine."Qty. to Ship" - TransLine."Reserved Quantity Outbnd.",
                  TransLine."Qty. to Ship (Base)" - TransLine."Reserved Qty. Outbnd. (Base)");
                if not AutoReserved then
                    Error(CannotAutoReserveErr, TransLine."Qty. to Ship (Base)", TransLine."Line No.");
            until TransLine.Next() = 0;
    end;

    /// <summary>
    /// Determines if the dimensions of already shipped transfer line have been changed.
    /// </summary>
    /// <returns>True if the dimensions are changed, otherwise false.</returns>
    procedure IsShippedDimChanged() Result: Boolean
    begin
        Result := ("Dimension Set ID" <> xRec."Dimension Set ID") and (("Quantity Shipped" <> 0) or ("Qty. Shipped (Base)" <> 0));

        OnAfterIsShippedDimChanged(Rec, Result);
    end;

    /// <summary>
    /// Confirms the change of dimensions for an already shipped transfer line.
    /// </summary>
    /// <returns>Returns true if the change is confirmed, otherwise false.</returns>
    procedure ConfirmShippedDimChange(): Boolean
    begin
        if not Confirm(Text012, false, TableCaption) then
            Error(Text013);

        exit(true);
    end;

    local procedure SelectItemEntry(CurrentFieldNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TransferLine2: Record "Transfer Line";
    begin
        SetItemLedgerEntryFilters(ItemLedgEntry);

        if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then begin
            TransferLine2 := Rec;
            TransferLine2.Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No.");
            CheckItemAvailable(CurrentFieldNo);
            Rec := TransferLine2;
        end;
    end;

    local procedure GetTransferHeaderNoVerification()
    begin
        TestField("Document No.");
        GetTransferHeader();
    end;

    /// <summary>
    /// Retrieves the transfer header record based on document number of the current transfer line.
    /// </summary>
    procedure GetTransferHeader(): Record "Transfer Header"
    begin
        if "Document No." <> TransHeader."No." then
            TransHeader.Get("Document No.");

        exit(TransHeader);
    end;

    /// <summary>
    /// Checks for date conflicts in the transfer line in case global parameter 'TrackingBlocked' is set to false.
    /// </summary>
    procedure DateConflictCheck()
    begin
        if not TrackingBlocked then
            CheckDateConflict.TransferLineCheck(Rec);
    end;

    local procedure ItemExists(ItemNo: Code[20]): Boolean
    var
        IEItem: Record Item;
    begin
        exit(IEItem.Get(ItemNo));
    end;

    local procedure DerivedLinesExist(var TransferLine: Record "Transfer Line"; DocumentNo: Code[20]; DerivedFromLineNo: Integer): Boolean
    begin
        TransferLine.SetRange("Document No.", DocumentNo);
        TransferLine.SetRange("Derived From Line No.", DerivedFromLineNo);
        exit(not TransferLine.IsEmpty);
    end;

    /// <summary>
    /// Returns the Row ID for the specified transfer direction.
    /// </summary>
    /// <param name="Direction">Provided transfer direction.</param>
    /// <returns>The Row ID as a text value.</returns>
    procedure RowID1(Direction: Enum "Transfer Direction"): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(ItemTrackingMgt.ComposeRowID(DATABASE::"Transfer Line", Direction.AsInteger(), "Document No.", '', "Derived From Line No.", "Line No."));
    end;

    local procedure VerifyReserveTransferLineQuantity()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyReserveTransferLineQuantity(Rec, IsHandled);
        if IsHandled then
            exit;

        TransferLineReserve.VerifyQuantity(Rec, xRec);
    end;

    local procedure SetItemLedgerEntryFilters(var ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ItemLedgEntry.SetRange("Item No.", "Item No.");
        if "Transfer-from Code" <> '' then
            ItemLedgEntry.SetRange("Location Code", "Transfer-from Code");
        ItemLedgEntry.SetRange("Variant Code", "Variant Code");
        ItemLedgEntry.SetRange(Positive, true);
        ItemLedgEntry.SetRange(Open, true);

        OnAfterSetItemLedgerEntryFilters(ItemLedgEntry, Rec);
    end;

    /// <summary>
    /// Creates a dimension based on default dimension source.
    /// </summary>
    procedure CreateDimFromDefaultDim()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Item, Rec."Item No.");

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, CurrFieldNo);
    end;

    /// <summary>
    /// Checks if qunatity on the current transfer line meets the reserved from stock setting.
    /// </summary>
    /// <param name="QtyToPost">The quantity to post from current transfer line.</param>
    /// <param name="ReservedFromStock">The reservation from stock option.</param>
    /// <returns>True if the transfer line meets the reserved from stock setting, otherwise false.</returns>
    /// <remarks>Reserve from stock options are: None, Partial, Full and Partial, Full.</remarks>
    procedure CheckIfTransferLineMeetsReservedFromStockSetting(QtyToPost: Decimal; ReservedFromStock: Enum "Reservation From Stock") Result: Boolean
    var
        QtyReservedFromStock: Decimal;
    begin
        Result := true;

        if ReservedFromStock = ReservedFromStock::" " then
            exit(true);

        QtyReservedFromStock := TransferLineReserve.GetReservedQtyFromInventory(Rec);

        case ReservedFromStock of
            ReservedFromStock::Full:
                if QtyToPost <> QtyReservedFromStock then
                    Result := false;
            ReservedFromStock::"Full and Partial":
                if QtyReservedFromStock = 0 then
                    Result := false;
            else
                OnCheckIfTransferLineMeetsReservedFromStockSetting(QtyToPost, ReservedFromStock, Result);
        end;

        exit(Result);
    end;

    /// <summary>
    /// Displays reservation entries for the current transfer line.
    /// </summary>
    /// <param name="Modal">Specifies whether the page reservation entries should be run in a modal mode or not.</param>
    /// <param name="Direction">Specifies the direction of the transfer.</param>
    procedure ShowReservationEntries(Modal: Boolean; Direction: Enum "Transfer Direction")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        TestField("Item No.");
        ReservationEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservationEntry, Direction);
        if Modal then
            PAGE.RunModal(PAGE::"Reservation Entries", ReservationEntry)
        else
            PAGE.Run(PAGE::"Reservation Entries", ReservationEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var TransferLine: Record "Transfer Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var TransferLine: Record "Transfer Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; xTransferLine: Record "Transfer Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemValues(var TransferLine: Record "Transfer Line"; Item: Record Item; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var Item: Record Item; IsReceipt: Boolean; IsSupplyForPlanning: Boolean; var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterInboundLinesForReservation(var TransferLine: Record "Transfer Line"; ReservationEntry: Record "Reservation Entry"; AvailabilityFilter: Text; Positive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterOutboundLinesForReservation(var TransferLine: Record "Transfer Line"; ReservationEntry: Record "Reservation Entry"; AvailabilityFilter: Text; Positive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDefaultBin(var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetTransHeader(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstandingQty(var TransferLine: Record "Transfer Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyInTransit(var TransferLine: Record "Transfer Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToReceive(var TransferLine: Record "Transfer Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToShip(var TransferLine: Record "Transfer Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetPostedQty(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowReservation(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestStatusOpen(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWithWarehouseShipReceive(var TransferLine: Record "Transfer Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var TransferLine: Record "Transfer Line"; var xTransferLine: Record "Transfer Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailable(var TransferLine: Record "Transfer Line"; CalledByFieldNo: Integer; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemCanBeShipped(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransferHeader(TransferHeader: Record "Transfer Header"; var IsHandled: Boolean; TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouse(TransferLine: Record "Transfer Line"; Location: Record Location; Receive: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemNo(var TransLine: Record "Transfer Line"; xTransLine: Record "Transfer Line"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReservationQty(var TransferLine: Record "Transfer Line"; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; Direction: Integer; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTransHeader(var TransferLine: Record "Transfer Line"; var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var TransferLine: Record "Transfer Line"; var xTransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenItemTrackingLines(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestStatusOpen(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWithWarehouseShipReceive(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDescription(var TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var TransferLine: Record "Transfer Line"; var xTransferLine: Record "Transfer Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityReceiveIsBalanced(var TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityShipIsBalanced(var TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityBase(var TransferLine: Record "Transfer Line"; var xTransferLine: Record "Transfer Line"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToShipBase(var TransferLine: Record "Transfer Line"; var xTransferLine: Record "Transfer Line"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToReceiveBase(var TransferLine: Record "Transfer Line"; var xTransferLine: Record "Transfer Line"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyReserveTransferLineQuantity(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeDeleteRelatedData(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterInitLine(var TransferLine: Record "Transfer Line"; TempTransferLine: Record "Transfer Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterGetTransHeaderExternal(var TransferLine: Record "Transfer Line"; var TransHeader: Record "Transfer Header"; TempTransferLine: Record "Transfer Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnCopyFromTempTransLine(var TransferLine: Record "Transfer Line"; TempTransferLine: Record "Transfer Line" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateReceiptDateOnBeforeCalcShipmentDate(var IsHandled: Boolean; var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateShipmentDateOnBeforeCalcReceiptDate(var IsHandled: Boolean; var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeTransLineVerifyChange(var TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterCalcQuantityBase(var TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitofMeasureCodeOnBeforeValidateQuantity(var TransferLine: Record "Transfer Line"; Item: Record Item; xTransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemLedgerEntryFilters(var ItemLedgEntry: Record "Item Ledger Entry"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultBin(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWarehouseOnBeforeShowDialog(TransferLine: Record "Transfer Line"; Location: Record Location; var ShowDialog: Option " ",Message,Error; var DialogText: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeAssignLineNo(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsShippedDimChanged(var TransferLine: Record "Transfer Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReservation(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTransferFromCodeOnBeforeCheckItemAvailable(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTransferToCodeOnBeforeVerifyChange(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnBeforeCheckEmptyVariantCode(var TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectMultipleItems(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelectMultipleItems(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddItems(var TransferLine: Record "Transfer Line"; SelectionFilter: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddItem(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBaseQty(var TransferLine: Record "Transfer Line"; var Qty: Decimal; FromFieldName: Text; ToFieldName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIfTransferLineMeetsReservedFromStockSetting(QtyToPost: Decimal; ReservedFromStock: Enum "Reservation From Stock"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTransferToCode(var TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line"; CurrFieldNo: Integer; StatusCheckSuspended: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToShip(var TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToReceive(var TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateItemNo(var TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;
}
