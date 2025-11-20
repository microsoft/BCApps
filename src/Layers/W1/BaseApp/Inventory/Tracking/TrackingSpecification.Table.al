// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;

table 336 "Tracking Specification"
{
    Caption = 'Tracking Specification';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(4; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if ("Quantity (Base)" * "Quantity Handled (Base)" < 0) or
                   (Abs("Quantity (Base)") < Abs("Quantity Handled (Base)"))
                then
                    FieldError("Quantity (Base)", StrSubstNo(Text002, FieldCaption("Quantity Handled (Base)")));

                "Quantity (Base)" := UOMMgt.RoundAndValidateQty("Quantity (Base)", "Qty. Rounding Precision (Base)", FieldCaption("Quantity (Base)"));

                IsHandled := false;
                OnValidateQuantityBaseOnBeforeCheckItemTrackingChange(Rec, CurrFieldNo, IsHandled);
                if not IsHandled then
                    WMSManagement.CheckItemTrackingChange(Rec, xRec);

                InitQtyToShip();
                CheckSerialNoQty();

                ClearApplyToEntryIfQuantityToInvoiceIsNotSufficient();
            end;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(10; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(11; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(12; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(13; "Source Batch Name"; Code[10])
        {
            Caption = 'Source Batch Name';
        }
        field(14; "Source Prod. Order Line"; Integer)
        {
            Caption = 'Source Prod. Order Line';
        }
        field(15; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
        }
        field(16; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(17; "Transfer Item Entry No."; Integer)
        {
            Caption = 'Transfer Item Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(24; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnValidate()
            begin
                if "Serial No." <> xRec."Serial No." then begin
                    TestField("Quantity Handled (Base)", 0);
                    TestField("Appl.-from Item Entry", 0);
                    if IsReclass() then
                        "New Serial No." := "Serial No.";
                    WMSManagement.CheckItemTrackingChange(Rec, xRec);
                    CheckSerialNoQty();
                    InitExpirationDate();
                end;
            end;
        }
        field(28; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(29; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(31; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(38; "Appl.-to Item Entry"; Integer)
        {
            Caption = 'Appl.-to Item Entry';

            trigger OnLookup()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Entry No.");
                ItemLedgEntry.SetRange("Item No.", "Item No.");
                ItemLedgEntry.SetRange(Positive, true);
                ItemLedgEntry.SetRange("Location Code", "Location Code");
                ItemLedgEntry.SetRange("Variant Code", "Variant Code");
                ItemLedgEntry.SetTrackingFilterFromSpec(Rec);
                ItemLedgEntry.SetRange(Open, true);
                if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then
                    Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No.");
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                if "Appl.-to Item Entry" = 0 then
                    exit;

                if not TrackingExists() then
                    TestTrackingFieldsAreBlank();

                ItemLedgEntry.Get("Appl.-to Item Entry");

                TestApplyToItemLedgEntryNo(ItemLedgEntry);

                if Abs("Quantity (Base)" - "Quantity Handled (Base)") > Abs(ItemLedgEntry."Remaining Quantity") then
                    Error(
                      RemainingQtyErr,
                      ItemLedgEntry.FieldCaption("Remaining Quantity"), ItemLedgEntry."Entry No.");
            end;
        }
        field(40; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(41; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';

            trigger OnValidate()
            var
                ItemTrackingMgt: Codeunit "Item Tracking Management";
                IsHandled: Boolean;
            begin
                WMSManagement.CheckItemTrackingChange(Rec, xRec);

                IsHandled := false;
                OnValidateExpirationDateOnBeforeResetExpirationDate(Rec, xRec, IsHandled);
                if not IsHandled then
                    if "Buffer Status2" = "Buffer Status2"::"ExpDate blocked" then begin
                        "Expiration Date" := xRec."Expiration Date";
                        Message(Text004);
                    end;

                if "Expiration Date" <> xRec."Expiration Date" then
                    ItemTrackingMgt.UpdateExpirationDateForLot(Rec);
            end;
        }
        field(50; "Qty. to Handle (Base)"; Decimal)
        {
            Caption = 'Qty. to Handle (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
            begin
                if ("Qty. to Handle (Base)" * "Quantity (Base)" < 0) or
                   (Abs("Qty. to Handle (Base)") > Abs("Quantity (Base)")
                    - "Quantity Handled (Base)")
                then
                    Error(Text001, "Quantity (Base)" - "Quantity Handled (Base)");

                OnValidateQtyToHandleOnBeforeInitQtyToInvoice(Rec, xRec, CurrFieldNo);

                "Qty. to Handle (Base)" := UOMMgt.RoundAndValidateQty("Qty. to Handle (Base)", "Qty. Rounding Precision (Base)", FieldCaption("Qty. to Handle (Base)"));

                InitQtyToInvoice();
                "Qty. to Handle" := CalcQty("Qty. to Handle (Base)");
                CheckSerialNoQty();
            end;
        }
        field(51; "Qty. to Invoice (Base)"; Decimal)
        {
            Caption = 'Qty. to Invoice (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if ("Qty. to Invoice (Base)" * "Quantity (Base)" < 0) or
                   (Abs("Qty. to Invoice (Base)") > Abs("Qty. to Handle (Base)"
                      + "Quantity Handled (Base)" - "Quantity Invoiced (Base)"))
                then
                    Error(
                      Text000,
                      "Qty. to Handle (Base)" + "Quantity Handled (Base)" - "Quantity Invoiced (Base)");

                "Qty. to Invoice (Base)" := UOMMgt.RoundAndValidateQty("Qty. to Invoice (Base)", "Qty. Rounding Precision (Base)", FieldCaption("Qty. to Invoice (Base)"));

                "Qty. to Invoice" := CalcQty("Qty. to Invoice (Base)");
                CheckSerialNoQty();
            end;
        }
        field(52; "Quantity Handled (Base)"; Decimal)
        {
            Caption = 'Quantity Handled (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(53; "Quantity Invoiced (Base)"; Decimal)
        {
            Caption = 'Quantity Invoiced (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(60; "Qty. to Handle"; Decimal)
        {
            Caption = 'Qty. to Handle';
            DecimalPlaces = 0 : 5;
        }
        field(61; "Qty. to Invoice"; Decimal)
        {
            Caption = 'Qty. to Invoice';
            DecimalPlaces = 0 : 5;
        }
        field(70; "Buffer Status"; Option)
        {
            Caption = 'Buffer Status';
            Editable = false;
            OptionCaption = ' ,MODIFY,INSERT';
            OptionMembers = " ",MODIFY,INSERT;
        }
        field(71; "Buffer Status2"; Option)
        {
            Caption = 'Buffer Status2';
            Editable = false;
            OptionCaption = ',ExpDate blocked';
            OptionMembers = ,"ExpDate blocked";
        }
        field(72; "Buffer Value1"; Decimal)
        {
            Caption = 'Buffer Value1';
            Editable = false;
        }
        field(73; "Buffer Value2"; Decimal)
        {
            Caption = 'Buffer Value2';
            Editable = false;
        }
        field(74; "Buffer Value3"; Decimal)
        {
            Caption = 'Buffer Value3';
            Editable = false;
        }
        field(75; "Buffer Value4"; Decimal)
        {
            Caption = 'Buffer Value4';
            Editable = false;
        }
        field(76; "Buffer Value5"; Decimal)
        {
            Caption = 'Buffer Value5';
            Editable = false;
        }
        field(80; "New Serial No."; Code[50])
        {
            Caption = 'New Serial No.';

            trigger OnValidate()
            begin
                WMSManagement.CheckItemTrackingChange(Rec, xRec);
                CheckSerialNoQty();
            end;
        }
        field(81; "New Lot No."; Code[50])
        {
            Caption = 'New Lot No.';

            trigger OnValidate()
            begin
                WMSManagement.CheckItemTrackingChange(Rec, xRec);
            end;
        }
        field(900; "Prohibit Cancellation"; Boolean)
        {
            Caption = 'Prohibit Cancellation';
        }
        field(5400; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';

            trigger OnValidate()
            begin
                if "Lot No." <> xRec."Lot No." then begin
                    TestField("Quantity Handled (Base)", 0);
                    TestField("Appl.-from Item Entry", 0);
                    if IsReclass() then
                        "New Lot No." := "Lot No.";
                    WMSManagement.CheckItemTrackingChange(Rec, xRec);
                    InitExpirationDate();
                end;
            end;
        }
        field(5401; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(5402; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(5811; "Appl.-from Item Entry"; Integer)
        {
            Caption = 'Appl.-from Item Entry';
            MinValue = 0;

            trigger OnLookup()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                ItemLedgEntry.SetCurrentKey("Item No.", Positive, "Location Code", "Variant Code");
                ItemLedgEntry.SetRange("Item No.", "Item No.");
                ItemLedgEntry.SetRange(Positive, false);
                if "Location Code" <> '' then
                    ItemLedgEntry.SetRange("Location Code", "Location Code");
                ItemLedgEntry.SetRange("Variant Code", "Variant Code");
                ItemLedgEntry.SetTrackingFilterFromSpec(Rec);
                ItemLedgEntry.SetFilter("Shipped Qty. Not Returned", '<0');
                OnAfterLookupApplFromItemEntrySetFilters(ItemLedgEntry, Rec);
                if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then
                    Validate("Appl.-from Item Entry", ItemLedgEntry."Entry No.");
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                if "Appl.-from Item Entry" = 0 then
                    exit;

                CheckApplyFromItemEntrySourceType();

                if not TrackingExists() then
                    TestTrackingFieldsAreBlank();

                ItemLedgEntry.Get("Appl.-from Item Entry");
                ItemLedgEntry.TestField("Item No.", "Item No.");
                ItemLedgEntry.TestField(Positive, false);
                if ItemLedgEntry."Shipped Qty. Not Returned" + Abs("Qty. to Handle (Base)") > 0 then
                    ItemLedgEntry.FieldError("Shipped Qty. Not Returned");
                ItemLedgEntry.TestField("Variant Code", "Variant Code");
                ItemLedgEntry.TestTrackingEqualToTrackingSpec(Rec);

                OnAfterValidateApplFromItemEntry(Rec, ItemLedgEntry, IsReclass());
            end;
        }
        field(5817; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(6505; "New Expiration Date"; Date)
        {
            Caption = 'New Expiration Date';

            trigger OnValidate()
            begin
                WMSManagement.CheckItemTrackingChange(Rec, xRec);
            end;
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';

            trigger OnValidate()
            begin
                if "Package No." <> xRec."Package No." then begin
                    CheckPackageNo("Package No.");
                    TestField("Quantity Handled (Base)", 0);
                    if IsReclass() then
                        "New Package No." := "Package No.";
                    WMSManagement.CheckItemTrackingChange(Rec, xRec);
                    InitExpirationDate();
                end;
            end;
        }
        field(6516; "New Package No."; Code[50])
        {
            Caption = 'New Package No.';
            CaptionClass = '6,2';

            trigger OnValidate()
            begin
                if "New Package No." <> xRec."New Package No." then begin
                    CheckPackageNo("New Package No.");
                    TestField("Quantity Handled (Base)", 0);
                    WMSManagement.CheckItemTrackingChange(Rec, xRec);
                end;
            end;
        }
        field(7300; "Quantity actual Handled (Base)"; Decimal)
        {
            Caption = 'Quantity actual Handled (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Source ID", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.")
        {
            IncludedFields = "Qty. to Handle (Base)", "Qty. to Invoice (Base)", "Quantity Handled (Base)", "Quantity Invoiced (Base)";
        }
#pragma warning disable AS0009
        key(Key3; "Lot No.", "Serial No.", "Package No.")
#pragma warning restore AS0009
        {
        }
#pragma warning disable AS0009
        key(Key4; "New Lot No.", "New Serial No.", "New Package No.")
#pragma warning restore AS0009
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Lot No.", "Serial No.", "Quantity (Base)", "Package No.", "Expiration Date")
        {

        }
    }

    trigger OnDelete()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        TestField("Quantity Handled (Base)", 0);
        TestField("Quantity Invoiced (Base)", 0);
    end;

    var
        CachedItem: Record Item;
        CachedItemTrackingCode: Record "Item Tracking Code";
        WMSManagement: Codeunit "WMS Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        SkipSerialNoQtyValidation: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot invoice more than %1 units.';
        Text001: Label 'You cannot handle more than %1 units.';
        Text002: Label 'must not be less than %1';
        Text003: Label '%1 must be -1, 0 or 1 when %2 is stated.';
#pragma warning restore AA0470
        Text004: Label 'Expiration date has been established by existing entries and cannot be changed.';
#pragma warning restore AA0074
#pragma warning disable AA0470
        RemainingQtyErr: Label 'The %1 in item ledger entry %2 is too low to cover quantity available to handle.';
#pragma warning restore AA0470
        WrongQtyForItemErr: Label '%1 in the item tracking assigned to the document line for item %2 is currently %3. It must be %4.\\Check the assignment for serial number %5, lot number %6, package number %7.', Comment = '%1 - Qty. to Handle or Qty. to Invoice, %2 - Item No., %3 - actual value, %4 - expected value, %5 - Serial No., %6 - Lot No., %7 - Package No.';

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure InitQtyToShip()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitQtyToShip(Rec, IsHandled);
        if IsHandled then
            exit;

        "Qty. to Handle (Base)" := "Quantity (Base)" - "Quantity Handled (Base)";
        "Qty. to Handle" := CalcQty("Qty. to Handle (Base)");

        InitQtyToInvoice();

        OnAfterInitQtyToShip(Rec);
    end;

    procedure InitQtyToInvoice()
    begin
        OnBeforeInitQtyToInvoice(Rec);

        "Qty. to Invoice (Base)" := "Quantity Handled (Base)" + "Qty. to Handle (Base)" - "Quantity Invoiced (Base)";
        "Qty. to Invoice" := CalcQty("Qty. to Invoice (Base)");

        OnAfterInitQtyToInvoice(Rec);
    end;

#if not CLEAN25
    [Obsolete('Procedure moved to codeunit Assembly Header-Reserve', '25.0')]
    procedure InitFromAsmHeader(var AsmHeader: Record Microsoft.Assembly.Document."Assembly Header")
    var
        AssemblyHeaderReserve: Codeunit Microsoft.Assembly.Document."Assembly Header-Reserve";
    begin
        AssemblyHeaderReserve.InitFromAsmHeader(Rec, AsmHeader);
    end;
#endif

#if not CLEAN25
    [Obsolete('Procedure moved to codeunit Assembly Line-Reserve', '25.0')]
    procedure InitFromAsmLine(var AsmLine: Record Microsoft.Assembly.Document."Assembly Line")
    var
        AssemblyLineReserve: Codeunit Microsoft.Assembly.Document."Assembly Line-Reserve";
    begin
        AssemblyLineReserve.InitFromAsmLine(Rec, AsmLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Procedure moved to codeunit Item Jnl. Line-Reserve', '25.0')]
    procedure InitFromItemJnlLine(ItemJnlLine: Record "Item Journal Line")
    var
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
    begin
        ItemJnlLineReserve.InitFromItemJnlLine(Rec, ItemJnlLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Procedure moved to codeunit Invt. Doc. Line-Reserve', '25.0')]
    procedure InitFromInvtDocLine(var InvtDocLine: Record Microsoft.Inventory.Document."Invt. Document Line")
    var
        InvtDocLineReserve: Codeunit Microsoft.Inventory.Document."Invt. Doc. Line-Reserve";
    begin
        InvtDocLineReserve.InitFromInvtDocLine(Rec, InvtDocLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Procedure moved to codeunit Job Jnl. Line-Reserve', '25.0')]
    procedure InitFromJobJnlLine(var JobJnlLine: Record Microsoft.Projects.Project.Journal."Job Journal Line")
    var
        JobJnlLineReserve: Codeunit Microsoft.Projects.Project.Journal."Job Jnl. Line-Reserve";
    begin
        JobJnlLineReserve.InitFromJobJnlLine(Rec, JobJnlLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Procedure moved to codeunit Job Planning Line-Reserve', '25.0')]
    procedure InitFromJobPlanningLine(var JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line")
    var
        JobPlanningLineReserve: Codeunit Microsoft.Projects.Project.Planning."Job Planning Line-Reserve";
    begin
        JobPlanningLineReserve.InitFromJobPlanningLine(Rec, JobPlanningLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Procedure moved to codeunit Purch. Line-Reserve', '25.0')]
    procedure InitFromPurchLine(PurchLine: Record "Purchase Line")
    var
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
    begin
        PurchLineReserve.InitFromPurchLine(Rec, PurchLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Procedure moved to codeunit Prod. Order Line-Reserve', '25.0')]
    procedure InitFromProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    var
        ProdOrderLineReserve: Codeunit Microsoft.Manufacturing.Document."Prod. Order Line-Reserve";
    begin
        ProdOrderLineReserve.InitFromProdOrderLine(Rec, ProdOrderLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Procedure moved to codeunit Prod. Order Comp.-Reserve', '25.0')]
    procedure InitFromProdOrderComp(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    var
        ProdOrderCompReserve: Codeunit Microsoft.Manufacturing.Document."Prod. Order Comp.-Reserve";
    begin
        ProdOrderCompReserve.InitFromProdOrderComp(Rec, ProdOrderComp);
    end;
#endif

#if not CLEAN25
    [Obsolete('Procedure moved to codeunit Plng. Component-Reserve', '25.0')]
    procedure InitFromProdPlanningComp(var PlanningComponent: Record Microsoft.Inventory.Planning."Planning Component")
    var
        PlngComponentReserve: Codeunit Microsoft.Inventory.Planning."Plng. Component-Reserve";
    begin
        PlngComponentReserve.InitFromProdPlanningComp(Rec, PlanningComponent);
    end;
#endif

#if not CLEAN25
    [Obsolete('Procedure moved to codeunit Req. Line-Reserve', '25.0')]
    procedure InitFromReqLine(ReqLine: Record Microsoft.Inventory.Requisition."Requisition Line")
    var
        ReqLineReserve: Codeunit Microsoft.Inventory.Requisition."Req. Line-Reserve";
    begin
        ReqLineReserve.InitFromReqLine(Rec, ReqLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Procedure moved to codeunit Sales Line-Reserve', '25.0')]
    procedure InitFromSalesLine(SalesLine: Record "Sales Line")
    var
        SalesLineReserve: Codeunit "Sales Line-Reserve";
    begin
        SalesLineReserve.InitFromSalesLine(Rec, SalesLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Procedure moved to codeunit Service Line-Reserve', '25.0')]
    procedure InitFromServLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; Consume: Boolean)
    var
        ServiceLineReserve: Codeunit Microsoft.Service.Document."Service Line-Reserve";
    begin
        ServiceLineReserve.InitFromServLine(Rec, ServiceLine, Consume);
    end;
#endif

#if not CLEAN25
    [Obsolete('Procedure moved to codeunit Transfer Line-Reserve', '25.0')]
    procedure InitFromTransLine(var TransLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var AvalabilityDate: Date; Direction: Enum Microsoft.Foundation.Enums."Transfer Direction")
    var
        TransferLineReserve: Codeunit Microsoft.Inventory.Transfer."Transfer Line-Reserve";
    begin
        TransferLineReserve.InitFromTransLine(Rec, TransLine, AvalabilityDate, Direction);
    end;
#endif

    local procedure CheckApplyFromItemEntrySourceType()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckApplyFromItemEntrySourceType(Rec, IsHandled);
        if IsHandled then
            exit;

        IsHandled := false;
        OnValidateApplFromItemEntryOnSourceTypeCaseElse(Rec, IsHandled);
        if not IsHandled then
            FieldError("Source Subtype");
    end;

    local procedure CheckSerialNoQty()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSerialNoQty(Rec, IsHandled);
        if IsHandled then
            exit;

        if SkipSerialNoQtyValidation then
            exit;

        if ("Serial No." = '') and ("New Serial No." = '') then
            exit;
        if not ("Quantity (Base)" in [-1, 0, 1]) then
            Error(Text003, FieldCaption("Quantity (Base)"), FieldCaption("Serial No."));
        if not ("Qty. to Handle (Base)" in [-1, 0, 1]) then
            Error(Text003, FieldCaption("Qty. to Handle (Base)"), FieldCaption("Serial No."));
        if not ("Qty. to Invoice (Base)" in [-1, 0, 1]) then
            Error(Text003, FieldCaption("Qty. to Invoice (Base)"), FieldCaption("Serial No."));

        OnAfterCheckSerialNoQty(Rec);
    end;

    procedure CalcQty(BaseQty: Decimal): Decimal
    begin
        if "Qty. per Unit of Measure" = 0 then
            "Qty. per Unit of Measure" := 1;
        exit(Round(BaseQty / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
    end;

    procedure CopySpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
        Reset();
        if TempTrackingSpecification.FindSet() then begin
            repeat
                Rec := TempTrackingSpecification;
                if Insert() then;
            until TempTrackingSpecification.Next() = 0;
            TempTrackingSpecification.DeleteAll();
        end;
    end;

    procedure HasSameTracking(TrackingSpecification: Record "Tracking Specification") IsSameTracking: Boolean;
    begin
        IsSameTracking :=
            ("Serial No." = TrackingSpecification."Serial No.") and
            ("Lot No." = TrackingSpecification."Lot No.");

        OnAfterHasSameTracking(Rec, TrackingSpecification, IsSameTracking);
    end;

    procedure InsertSpecification()
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        Reset();
        if FindSet() then begin
            repeat
                TrackingSpecification := Rec;
                TrackingSpecification."Buffer Status" := 0;
                TrackingSpecification.InitQtyToShip();
                TrackingSpecification.Correction := false;
                TrackingSpecification."Quantity actual Handled (Base)" := 0;
                OnBeforeUpdateTrackingSpecification(Rec, TrackingSpecification);
                if "Buffer Status" = "Buffer Status"::MODIFY then
                    TrackingSpecification.Modify()
                else
                    TrackingSpecification.Insert();
            until Next() = 0;
            DeleteAll();
        end;
    end;

    procedure InitTrackingSpecification(FromType: Integer; FromSubtype: Integer; FromID: Code[20]; FromBatchName: Code[10]; FromProdOrderLine: Integer; FromRefNo: Integer; FromVariantCode: Code[10]; FromLocationCode: Code[10]; FromQtyPerUOM: Decimal)
    begin
        SetSource(FromType, FromSubtype, FromID, FromRefNo, FromBatchName, FromProdOrderLine);
        "Variant Code" := FromVariantCode;
        "Location Code" := FromLocationCode;
        "Qty. per Unit of Measure" := FromQtyPerUOM;
    end;

    procedure InitExpirationDate()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ExpDate: Date;
        EntriesExist: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitExpirationDate(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if HasSameTracking(xRec) then
            exit;

        "Expiration Date" := 0D;
        ItemTrackingMgt.CopyExpirationDateForLot(Rec);

        GetItemTrackingCode("Item No.", ItemTrackingCode);
        if not ItemTrackingCode."Use Expiration Dates" then
            "Buffer Status2" := "Buffer Status2"::"ExpDate blocked"
        else begin
            ExpDate := ItemTrackingMgt.ExistingExpirationDate(Rec, false, EntriesExist);
            if EntriesExist then begin
                "Expiration Date" := ExpDate;
                "Buffer Status2" := "Buffer Status2"::"ExpDate blocked";
            end else
                "Buffer Status2" := 0;
        end;

        if IsReclass() then begin
            "New Expiration Date" := "Expiration Date";
            ItemTrackingSetup.CopyTrackingFromNewTrackingSpec(Rec);
            "Warranty Date" := ItemTrackingMgt.ExistingWarrantyDate("Item No.", "Variant Code", ItemTrackingSetup, EntriesExist);
        end;

        OnAfterInitExpirationDate(Rec);
    end;

    procedure IsReclass() Reclass: Boolean
    begin
        Reclass := ("Source Type" = Database::"Item Journal Line") and ("Source Subtype" = 4);

        OnAfterIsReclass(Rec, Reclass);
    end;

    local procedure TestApplyToItemLedgEntryNo(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemJnlLine: Record "Item Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestApplyToItemLedgEntry(Rec, ItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        ItemLedgEntry.TestField("Item No.", "Item No.");
        ItemLedgEntry.TestField(Positive, true);
        ItemLedgEntry.TestField("Variant Code", "Variant Code");
        ItemLedgEntry.TestTrackingEqualToTrackingSpec(Rec);
        if "Source Type" = Database::"Item Journal Line" then begin
            ItemJnlLine.SetRange("Journal Template Name", "Source ID");
            ItemJnlLine.SetRange("Journal Batch Name", "Source Batch Name");
            ItemJnlLine.SetRange("Line No.", "Source Ref. No.");
            ItemJnlLine.SetRange("Entry Type", "Source Subtype");
            if ItemJnlLine.FindFirst() then
                if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Output then begin
                    ItemLedgEntry.TestField("Order Type", ItemJnlLine."Order Type"::Production);
                    ItemLedgEntry.TestField("Order No.", ItemJnlLine."Order No.");
                    ItemLedgEntry.TestField("Order Line No.", ItemJnlLine."Order Line No.");
                    ItemLedgEntry.TestField("Entry Type", ItemJnlLine."Entry Type");
                end;
        end;
    end;

    procedure TestFieldError(FieldCaptionText: Text[80]; CurrFieldValue: Decimal; CompareValue: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestFieldError(FieldCaptionText, CurrFieldValue, CompareValue, IsHandled);
        if IsHandled then
            exit;

        if CurrFieldValue = CompareValue then
            exit;

        Error(
          WrongQtyForItemErr,
          FieldCaptionText, "Item No.", Abs(CurrFieldValue), Abs(CompareValue), "Serial No.", "Lot No.", "Package No.");
    end;

    procedure SetItemData(ItemNo: Code[20]; ItemDescription: Text[100]; LocationCode: Code[10]; VariantCode: Code[10]; BinCode: Code[20]; QtyPerUoM: Decimal)
    begin
        "Item No." := ItemNo;
        Description := ItemDescription;
        "Location Code" := LocationCode;
        "Variant Code" := VariantCode;
        "Bin Code" := BinCode;
        "Qty. per Unit of Measure" := QtyPerUoM;
    end;

    procedure SetItemData(ItemNo: Code[20]; ItemDescription: Text[100]; LocationCode: Code[10]; VariantCode: Code[10]; BinCode: Code[20]; QtyPerUoM: Decimal; QtyRoundingPrecision: Decimal)
    begin
        SetItemData(ItemNo, ItemDescription, LocationCode, VariantCode, BinCode, QtyPerUoM);
        "Qty. Rounding Precision (Base)" := QtyRoundingPrecision;
    end;

    procedure SetQuantities(QtyBase: Decimal; QtyToHandle: Decimal; QtyToHandleBase: Decimal; QtyToInvoice: Decimal; QtyToInvoiceBase: Decimal; QtyHandledBase: Decimal; QtyInvoicedBase: Decimal)
    begin
        "Quantity (Base)" := QtyBase;
        "Qty. to Handle" := QtyToHandle;
        "Qty. to Handle (Base)" := QtyToHandleBase;
        "Qty. to Invoice" := QtyToInvoice;
        "Qty. to Invoice (Base)" := QtyToInvoiceBase;
        "Quantity Handled (Base)" := QtyHandledBase;
        "Quantity Invoiced (Base)" := QtyInvoicedBase;
    end;

    procedure ClearSourceFilter()
    begin
        SetRange("Source Type");
        SetRange("Source Subtype");
        SetRange("Source ID");
        SetRange("Source Ref. No.");
        SetRange("Source Batch Name");
        SetRange("Source Prod. Order Line");
    end;

    procedure SetSource(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        "Source Type" := SourceType;
        "Source Subtype" := SourceSubtype;
        "Source ID" := SourceID;
        "Source Ref. No." := SourceRefNo;
        "Source Batch Name" := SourceBatchName;
        "Source Prod. Order Line" := SourceProdOrderLine;
    end;

    procedure SetSourceFromPurchLine(PurchLine: Record "Purchase Line")
    begin
        "Source Type" := Database::"Purchase Line";
        "Source Subtype" := PurchLine."Document Type".AsInteger();
        "Source ID" := PurchLine."Document No.";
        "Source Batch Name" := '';
        "Source Prod. Order Line" := 0;
        "Source Ref. No." := PurchLine."Line No.";

        OnAfterSetSourceFromPurchLine(Rec, PurchLine);
    end;

    procedure SetSourceFromSalesLine(SalesLine: Record "Sales Line")
    begin
        "Source Type" := Database::"Sales Line";
        "Source Subtype" := SalesLine."Document Type".AsInteger();
        "Source ID" := SalesLine."Document No.";
        "Source Batch Name" := '';
        "Source Prod. Order Line" := 0;
        "Source Ref. No." := SalesLine."Line No.";

        OnAfterSetSourceFromSalesLine(Rec, SalesLine);
    end;

    procedure SetSourceFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        "Source Type" := ReservEntry."Source Type";
        "Source Subtype" := ReservEntry."Source Subtype";
        "Source ID" := ReservEntry."Source ID";
        "Source Batch Name" := ReservEntry."Source Batch Name";
        "Source Prod. Order Line" := ReservEntry."Source Prod. Order Line";
        "Source Ref. No." := ReservEntry."Source Ref. No.";
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceKey: Boolean)
    begin
        if SourceKey then
            SetCurrentKey(
              "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.");
        SetRange("Source Type", SourceType);
        if SourceSubtype >= 0 then
            SetRange("Source Subtype", SourceSubtype);
        SetRange("Source ID", SourceID);
        if SourceRefNo >= 0 then
            SetRange("Source Ref. No.", SourceRefNo);

        OnAfterSetSourceFilter(Rec, SourceType, SourceSubtype, SourceID, SourceRefNo, SourceKey);
    end;

    procedure SetSourceFilter(SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        SetRange("Source Batch Name", SourceBatchName);
        SetRange("Source Prod. Order Line", SourceProdOrderLine);
    end;

    procedure ClearTracking()
    begin
        "Serial No." := '';
        "Lot No." := '';
        "Warranty Date" := 0D;
        "Expiration Date" := 0D;

        OnAfterClearTracking(Rec);
    end;

    procedure ClearTrackingFilter()
    begin
        SetRange("Serial No.");
        SetRange("Lot No.");

        OnAfterClearTrackingFilter(Rec);
    end;

    procedure SetTrackingBlank()
    begin
        "Serial No." := '';
        "Lot No." := '';
        "Warranty Date" := 0D;
        "Expiration Date" := 0D;

        OnAfterSetTrackingBlank(Rec);
    end;

    procedure CopyTrackingFromTrackingSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";

        OnAfterCopyTrackingFromTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure CopyNewTrackingFromTrackingSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "New Serial No." := TrackingSpecification."Serial No.";
        "New Lot No." := TrackingSpecification."Lot No.";

        OnAfterCopyNewTrackingFromTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure CopyNewTrackingFromNewTrackingSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "New Serial No." := TrackingSpecification."New Serial No.";
        "New Lot No." := TrackingSpecification."New Lot No.";

        OnAfterCopyNewTrackingFromNewTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure CopyTrackingFromEntrySummary(EntrySummary: Record "Entry Summary")
    begin
        "Serial No." := EntrySummary."Serial No.";
        "Lot No." := EntrySummary."Lot No.";

        OnAfterCopyTrackingFromEntrySummary(Rec, EntrySummary);
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgerEntry."Serial No.";
        "Lot No." := ItemLedgerEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgerEntry);
    end;

    procedure CopyTrackingFromItemTrackingSetup(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        "Serial No." := ItemTrackingSetup."Serial No.";
        "Lot No." := ItemTrackingSetup."Lot No.";

        OnAfterCopyTrackingFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    procedure CopyTrackingFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        "Serial No." := ReservEntry."Serial No.";
        "Lot No." := ReservEntry."Lot No.";

        OnAfterCopyTrackingFromReservEntry(Rec, ReservEntry);
    end;

    procedure CopyTrackingFromWhseActivityLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        "Serial No." := WhseActivityLine."Serial No.";
        "Lot No." := WhseActivityLine."Lot No.";

        OnAfterCopyTrackingFromWhseActivityLine(Rec, WhseActivityLine);
    end;

    procedure CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        "Serial No." := WhseItemTrackingLine."Serial No.";
        "Lot No." := WhseItemTrackingLine."Lot No.";

        OnAfterCopyTrackingFromWhseItemTrackingLine(Rec, WhseItemTrackingLine);
    end;

    procedure SetTrackingFilterBlank()
    begin
        SetRange("Serial No.", '');
        SetRange("Lot No.", '');

        OnAfterSetTrackingFilterBlank(Rec);
    end;

    procedure SetTrackingFilterFromEntrySummary(EntrySummary: Record "Entry Summary")
    begin
        SetRange("Serial No.", EntrySummary."Serial No.");
        SetRange("Lot No.", EntrySummary."Lot No.");

        OnAfterSetTrackingFilterFromEntrySummary(Rec, EntrySummary);
    end;

    procedure SetTrackingFilterFromItemJnlLine(ItemJnlLine: Record "Item Journal Line")
    begin
        SetRange("Serial No.", ItemJnlLine."Serial No.");
        SetRange("Lot No.", ItemJnlLine."Lot No.");

        OnAfterSetTrackingFilterFromItemJnlLine(Rec, ItemJnlLine);
    end;

    procedure SetTrackingFilterFromItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        SetRange("Serial No.", ItemLedgEntry."Serial No.");
        SetRange("Lot No.", ItemLedgEntry."Lot No.");

        OnAfterSetTrackingFilterFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    procedure SetTrackingFilterFromItemTrackingSetup(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        SetRange("Serial No.", ItemTrackingSetup."Serial No.");
        SetRange("Lot No.", ItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        SetRange("Serial No.", ReservEntry."Serial No.");
        SetRange("Lot No.", ReservEntry."Lot No.");

        OnAfterSetTrackingFilterFromReservEntry(Rec, ReservEntry);
    end;

    procedure SetNewTrackingFilterFromNewReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        SetRange("New Serial No.", ReservEntry."New Serial No.");
        SetRange("New Lot No.", ReservEntry."New Lot No.");

        OnAfterSetNewTrackingFilterFromNewReservEntry(Rec, ReservEntry);
    end;

    procedure SetNewTrackingFilterFromNewTrackingSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        SetRange("New Serial No.", TrackingSpecification."New Serial No.");
        SetRange("New Lot No.", TrackingSpecification."New Lot No.");

        OnAfterSetNewTrackingFilterFromNewTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure SetTrackingFilterFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        SetRange("Serial No.", TrackingSpecification."Serial No.");
        SetRange("Lot No.", TrackingSpecification."Lot No.");

        OnAfterSetTrackingFilterFromTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure SetNonSerialTrackingFilterFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        SetRange("Lot No.", TrackingSpecification."Lot No.");

        OnAfterSetNonSerialTrackingFilterFromSpec(Rec, TrackingSpecification);
    end;

    procedure SetTrackingFilterFromWhseActivityLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        SetRange("Serial No.", WhseActivityLine."Serial No.");
        SetRange("Lot No.", WhseActivityLine."Lot No.");

        OnAfterSetTrackingFilterFromWhseActivityLine(Rec, WhseActivityLine);
    end;

    procedure SetTrackingKey()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetTrackingKey(Rec, IsHandled);
        if not IsHandled then
            SetCurrentKey("Lot No.", "Serial No.", "Package No.");
    end;

    procedure SetSkipSerialNoQtyValidation(NewSkipSerialNoQtyValidation: Boolean)
    begin
        SkipSerialNoQtyValidation := NewSkipSerialNoQtyValidation;
    end;

    procedure CheckItemTrackingQuantity(TableNo: Integer; DocumentType: Option; DocumentNo: Code[20]; LineNo: Integer; QtyToHandleBase: Decimal; QtyToInvoiceBase: Decimal; Handle: Boolean; Invoice: Boolean)
    begin
        CheckItemTrackingQuantity(TableNo, DocumentType, DocumentNo, LineNo, -1, QtyToHandleBase, QtyToInvoiceBase, Handle, Invoice);
    end;

    procedure CheckItemTrackingQuantity(TableNo: Integer; DocumentType: Option; DocumentNo: Code[20]; LineNo: Integer; ProdOrderLineNo: Integer; QtyToHandleBase: Decimal; QtyToInvoiceBase: Decimal; Handle: Boolean; Invoice: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemTrackingQuantity(
            Rec, TableNo, DocumentType, DocumentNo, LineNo, ProdOrderLineNo,
            QtyToHandleBase, QtyToInvoiceBase, Handle, Invoice, IsHandled);
        if IsHandled then
            exit;

        if QtyToHandleBase = 0 then
            Handle := false;
        if QtyToInvoiceBase = 0 then
            Invoice := false;
        if not (Handle or Invoice) then
            exit;

        ReservationEntry.SetSourceFilter(TableNo, DocumentType, DocumentNo, LineNo, true);
        if ProdOrderLineNo >= 0 then
            ReservationEntry.SetSourceFilter('', ProdOrderLineNo);
        ReservationEntry.SetFilter("Item Tracking", '%1|%2|%3|%4',
            ReservationEntry."Item Tracking"::"Lot and Serial No.",
            ReservationEntry."Item Tracking"::"Serial No.",
            ReservationEntry."Item Tracking"::"Serial and Package No.",
            ReservationEntry."Item Tracking"::"Lot and Serial and Package No.");
        CheckItemTrackingByType(ReservationEntry, QtyToHandleBase, QtyToInvoiceBase, false, Handle, Invoice);
        ReservationEntry.SetFilter("Item Tracking", '%1|%2|%3',
            ReservationEntry."Item Tracking"::"Lot No.",
            ReservationEntry."Item Tracking"::"Package No.",
            ReservationEntry."Item Tracking"::"Lot and Package No.");
        CheckItemTrackingByType(ReservationEntry, QtyToHandleBase, QtyToInvoiceBase, true, Handle, Invoice);

        OnAfterCheckItemTrackingQuantity(Rec, ReservationEntry, TableNo, DocumentType, DocumentNo, LineNo);
    end;

    procedure CheckItemTrackingByType(var ReservationEntry: Record "Reservation Entry"; QtyToHandleBase: Decimal; QtyToInvoiceBase: Decimal; OnlyLot: Boolean; Handle: Boolean; Invoice: Boolean)
    var
        TrackingSpecification: Record "Tracking Specification";
        HandleQtyBase: Decimal;
        InvoiceQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemTrackingByType(
            ReservationEntry, QtyToHandleBase, QtyToInvoiceBase, OnlyLot, Handle, Invoice, IsHandled);
        if IsHandled then
            exit;

        if OnlyLot then
            // OnlyLot = Non-serial number tracking scenarios
            if CheckNonSerialTrackingIsUndefinedOrSingleSet(ReservationEntry, Handle, Invoice) then
                exit;

        if Handle then begin
            ReservationEntry.SetFilter("Qty. to Handle (Base)", '<>%1', 0);
            ReservationEntry.CalcSums("Qty. to Handle (Base)");
            HandleQtyBase := ReservationEntry."Qty. to Handle (Base)";

            if Abs(HandleQtyBase) > Abs(QtyToHandleBase) then begin
                ReservationEntry.FindLast();
                TrackingSpecification.TransferFields(ReservationEntry);
                TrackingSpecification.TestFieldError(FieldCaption("Qty. to Handle (Base)"), HandleQtyBase, QtyToHandleBase);
            end;
            ReservationEntry.SetRange("Qty. to Handle (Base)");
        end;

        if Invoice then begin
            ReservationEntry.SetFilter("Qty. to Invoice (Base)", '<>%1', 0);
            if ReservationEntry.FindSet() then
                repeat
                    InvoiceQtyBase += ReservationEntry."Qty. to Invoice (Base)";
                until ReservationEntry.Next() = 0;
            if Abs(InvoiceQtyBase) > Abs(QtyToInvoiceBase) then begin
                ReservationEntry.FindLast();
                TrackingSpecification.TransferFields(ReservationEntry);
                TrackingSpecification.TestFieldError(FieldCaption("Qty. to Invoice (Base)"), InvoiceQtyBase, QtyToInvoiceBase);
            end;
            ReservationEntry.SetRange("Qty. to Invoice (Base)");
        end;
    end;

    local procedure CheckNonSerialTrackingIsUndefinedOrSingleSet(var ReservationEntry: Record "Reservation Entry"; Handle: Boolean; Invoice: Boolean): Boolean
    var
        TempReservationEntryToHandleFirstFound: Record "Reservation Entry" temporary;
        TempReservationEntryToInvoiceFirstFound: Record "Reservation Entry" temporary;
        TrackingToHandleInMultipleSets: Boolean;
        TrackingToInvoiceInMultipleSets: Boolean;
    begin
        if not ReservationEntry.FindSet() then
            exit(true);

        repeat
            if Handle and (ReservationEntry."Qty. to Handle (Base)" <> 0) then begin
                CheckNonSerialTrackingInMultipleSets(ReservationEntry."Qty. to Handle (Base)", ReservationEntry, TempReservationEntryToHandleFirstFound, TrackingToHandleInMultipleSets);
                if TrackingToHandleInMultipleSets then
                    exit(false);
            end;
            if Invoice and (ReservationEntry."Qty. to Invoice (Base)" <> 0) then begin
                CheckNonSerialTrackingInMultipleSets(ReservationEntry."Qty. to Invoice (Base)", ReservationEntry, TempReservationEntryToInvoiceFirstFound, TrackingToInvoiceInMultipleSets);
                if TrackingToInvoiceInMultipleSets then
                    exit(false);
            end;
        until ReservationEntry.Next() = 0;
        exit(true);
    end;

    local procedure CheckNonSerialTrackingInMultipleSets(ReservationEntryQty: Decimal; var ReservationEntry: Record "Reservation Entry"; var TempReservationEntryFirstFound: Record "Reservation Entry" temporary; var TrackingInMultipleSets: Boolean)
    begin
        if ReservationEntryQty = 0 then
            exit;

        if (TempReservationEntryFirstFound."Lot No." = '') and (TempReservationEntryFirstFound."Package No." = '') then begin
            TempReservationEntryFirstFound."Lot No." := ReservationEntry."Lot No.";
            TempReservationEntryFirstFound."Package No." := ReservationEntry."Package No.";
            TrackingInMultipleSets := false;
        end else
            if (ReservationEntry."Lot No." <> TempReservationEntryFirstFound."Lot No.") or (ReservationEntry."Package No." <> TempReservationEntryFirstFound."Package No.") then
                TrackingInMultipleSets := true;
    end;

    local procedure QuantityToInvoiceIsSufficient(): Boolean
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        case "Source Type" of
            Database::"Sales Line":
                if SalesLine.Get("Source Subtype", "Source ID", "Source Ref. No.") then
                    exit("Quantity (Base)" <= SalesLine."Qty. to Invoice (Base)");
            Database::"Purchase Line":
                if PurchaseLine.Get("Source Subtype", "Source ID", "Source Ref. No.") then
                    exit("Quantity (Base)" <= PurchaseLine."Qty. to Invoice (Base)");
        end;

        exit(false);
    end;

    local procedure ClearApplyToEntryIfQuantityToInvoiceIsNotSufficient()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearApplyToEntryIfQuantityToInvoiceIsNotSufficient(Rec, IsHandled);
        if IsHandled then
            exit;

        if not QuantityToInvoiceIsSufficient() then
            Validate("Appl.-to Item Entry", 0);
    end;

    procedure TestTrackingFieldsAreBlank();
    begin
        TestField("Serial No.", '');
        TestField("Lot No.", '');

        OnAfterTestTrackingFieldsAreBlank(Rec);
    end;

    procedure TrackingExists() IsTrackingExist: Boolean
    begin
        IsTrackingExist := ("Serial No." <> '') or ("Lot No." <> '');

        OnAfterTrackingExist(Rec, IsTrackingExist);
    end;

    procedure NewTrackingExists() IsTrackingExist: Boolean
    begin
        IsTrackingExist := ("New Serial No." <> '') or ("New Lot No." <> '');

        OnAfterNewTrackingExist(Rec, IsTrackingExist);
    end;

    procedure NonSerialTrackingExists() IsTrackingExists: Boolean
    begin
        IsTrackingExists := "Lot No." <> '';

        OnAfterNonSerialTrackingExists(Rec, IsTrackingExists);
    end;

    local procedure GetItemTrackingCode(ItemNo: Code[20]; var ItemTrackingCode: Record "Item Tracking Code")
    begin
        if CachedItem."No." <> ItemNo then begin
            // searching for a new item, clear the cached item
            Clear(CachedItem);

            // get the item from the database
            if CachedItem.Get(ItemNo) then begin
                if CachedItem."Item Tracking Code" <> CachedItemTrackingCode.Code then
                    Clear(CachedItemTrackingCode); // item tracking code changed, clear the cached tracking code

                if CachedItem."Item Tracking Code" <> '' then
                    // item tracking code changed to something not empty, so get the new item tracking code from the database
                    CachedItemTrackingCode.Get(CachedItem."Item Tracking Code");
            end else
                Clear(CachedItemTrackingCode); // can't find the item, so clear the cached tracking code as well
        end;

        ItemTrackingCode := CachedItemTrackingCode;
    end;

    procedure GetSourceShipmentDate() ShipmentDate: Date
    begin
        OnGetSourceShipmentDate(Rec, ShipmentDate);
    end;

    local procedure CheckPackageNo(PackageNo: Code[50])
    begin
        OnCheckPackageNo(Rec, PackageNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTracking(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTrackingFilter(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromReservEntry(var TrackingSpecification: Record "Tracking Specification"; ReservEntry: Record "Reservation Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseActivityLine(var TrackingSpecification: Record "Tracking Specification"; WhseActivityLine: Record "Warehouse Activity Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseItemTrackingLine(var TrackingSpecification: Record "Tracking Specification"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterInitFromAsmHeader(var TrackingSpecification: Record "Tracking Specification"; AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
        OnAfterInitFromAsmHeader(TrackingSpecification, AssemblyHeader);
    end;

    [Obsolete('Replaced same event in codeunit AssemblyHeaderReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromAsmHeader(var TrackingSpecification: Record "Tracking Specification"; AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterInitFromAsmLine(var TrackingSpecification: Record "Tracking Specification"; AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
        OnAfterInitFromAsmLine(TrackingSpecification, AssemblyLine);
    end;

    [Obsolete('Replaced same event in codeunit AssemblyLineReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromAsmLine(var TrackingSpecification: Record "Tracking Specification"; AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterInitFromItemJnlLine(var TrackingSpecification: Record "Tracking Specification"; ItemJournalLine: Record "Item Journal Line")
    begin
        OnAfterInitFromItemJnlLine(TrackingSpecification, ItemJournalLine);
    end;

    [Obsolete('Replaced same event in codeunit ItemJnlLineReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromItemJnlLine(var TrackingSpecification: Record "Tracking Specification"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterInitFromJobJnlLine(var TrackingSpecification: Record "Tracking Specification"; JobJournalLine: Record Microsoft.Projects.Project.Journal."Job Journal Line")
    begin
        OnAfterInitFromJobJnlLine(TrackingSpecification, JobJournalLine);
    end;

    [Obsolete('Replaced same event in codeunit JobJnlLineReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromJobJnlLine(var TrackingSpecification: Record "Tracking Specification"; JobJournalLine: Record Microsoft.Projects.Project.Journal."Job Journal Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterInitFromJobPlanningLine(var TrackingSpecification: Record "Tracking Specification"; JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line")
    begin
        OnAfterInitFromJobPlanningLine(TrackingSpecification, JobPlanningLine);
    end;

    [Obsolete('Replaced same event in codeunit JobPlanningLineReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromJobPlanningLine(var TrackingSpecification: Record "Tracking Specification"; JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterInitFromPurchLine(var TrackingSpecification: Record "Tracking Specification"; PurchaseLine: Record "Purchase Line")
    begin
        OnAfterInitFromPurchLine(TrackingSpecification, PurchaseLine);
    end;

    [Obsolete('Replaced same event in codeunit PurchLineReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromPurchLine(var TrackingSpecification: Record "Tracking Specification"; PurchaseLine: Record "Purchase Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterInitFromProdOrderLine(var TrackingSpecification: Record "Tracking Specification"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
        OnAfterInitFromProdOrderLine(TrackingSpecification, ProdOrderLine);
    end;

    [Obsolete('Replaced same event in codeunit ProdOrderLineReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromProdOrderLine(var TrackingSpecification: Record "Tracking Specification"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterInitFromProdOrderComp(var TrackingSpecification: Record "Tracking Specification"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnAfterInitFromProdOrderComp(TrackingSpecification, ProdOrderComponent);
    end;

    [Obsolete('Replaced same event in codeunit ProdOrderCompReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromProdOrderComp(var TrackingSpecification: Record "Tracking Specification"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterInitFromProdPlanningComp(var TrackingSpecification: Record "Tracking Specification"; PlanningComponent: Record Microsoft.Inventory.Planning."Planning Component")
    begin
        OnAfterInitFromProdPlanningComp(TrackingSpecification, PlanningComponent);
    end;

    [Obsolete('Replaced same event in codeunit PlngComponentReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromProdPlanningComp(var TrackingSpecification: Record "Tracking Specification"; PlanningComponent: Record Microsoft.Inventory.Planning."Planning Component")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterInitFromReqLine(var TrackingSpecification: Record "Tracking Specification"; RequisitionLine: Record Microsoft.Inventory.Requisition."Requisition Line")
    begin
        OnAfterInitFromReqLine(TrackingSpecification, RequisitionLine);
    end;

    [Obsolete('Replaced same event in codeunit ReqLineReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromReqLine(var TrackingSpecification: Record "Tracking Specification"; RequisitionLine: Record Microsoft.Inventory.Requisition."Requisition Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterInitFromSalesLine(var TrackingSpecification: Record "Tracking Specification"; SalesLine: Record "Sales Line")
    begin
        OnAfterInitFromSalesLine(TrackingSpecification, SalesLine);
    end;

    [Obsolete('Event moved to codeunit Sales Line-Reserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromSalesLine(var TrackingSpecification: Record "Tracking Specification"; SalesLine: Record "Sales Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterInitFromServLine(var TrackingSpecification: Record "Tracking Specification"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
        OnAfterInitFromServLine(TrackingSpecification, ServiceLine);
    end;

    [Obsolete('Event moved to codeunit Service Line-Reserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromServLine(var TrackingSpecification: Record "Tracking Specification"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterInitFromTransLine(var TrackingSpecification: Record "Tracking Specification"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; Direction: Enum Microsoft.Foundation.Enums."Transfer Direction")
    begin
        OnAfterInitFromTransLine(TrackingSpecification, TransferLine, Direction);
    end;

    [Obsolete('Event moved to codeunit Transfer Line-Reserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromTransLine(var TrackingSpecification: Record "Tracking Specification"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; Direction: Enum Microsoft.Foundation.Enums."Transfer Direction")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToInvoice(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToShip(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitExpirationDate(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromEntrySummary(var TrackingSpecification: Record "Tracking Specification"; EntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var TrackingSpecification: Record "Tracking Specification"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemTrackingSetup(var TrackingSpecification: Record "Tracking Specification"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyNewTrackingFromTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyNewTrackingFromNewTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingBlank(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterBlank(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromEntrySummary(var TrackingSpecification: Record "Tracking Specification"; EntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemJnlLine(var TrackingSpecification: Record "Tracking Specification"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetup(var TrackingSpecification: Record "Tracking Specification"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemLedgEntry(var TrackingSpecification: Record "Tracking Specification"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromReservEntry(var TrackingSpecification: Record "Tracking Specification"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetNewTrackingFilterFromNewReservEntry(var TrackingSpecification: Record "Tracking Specification"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetNewTrackingFilterFromNewTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetNonSerialTrackingFilterFromSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilter(var TrackingSpecification: Record "Tracking Specification"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceKey: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseActivityLine(var TrackingSpecification: Record "Tracking Specification"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupApplFromItemEntrySetFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestTrackingFieldsAreBlank(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingExist(var TrackingSpecification: Record "Tracking Specification"; var IsTrackingExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNewTrackingExist(var TrackingSpecification: Record "Tracking Specification"; var IsTrackingExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNonSerialTrackingExists(var TrackingSpecification: Record "Tracking Specification"; var IsTrackingExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasSameTracking(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification"; var IsSameTracking: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateApplFromItemEntry(var TrackingSpecification: Record "Tracking Specification"; ItemLedgerEntry: Record "Item Ledger Entry"; IsReclassification: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSerialNoQty(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearApplyToEntryIfQuantityToInvoiceIsNotSufficient(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToInvoice(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToShip(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestApplyToItemLedgEntry(var TrackingSpecification: Record "Tracking Specification"; ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestFieldError(FieldCaptionText: Text[80]; CurrFieldValue: Decimal; CompareValue: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPackageNo(TrackingSpecification: Record "Tracking Specification"; PackageNo: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTrackingSpecification(var TrackingSpecification: Record "Tracking Specification"; var FromTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToHandleOnBeforeInitQtyToInvoice(var TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateApplFromItemEntryOnSourceTypeCaseElse(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTrackingQuantity(var TrackingSpecification: Record "Tracking Specification"; TableNo: Integer; DocumentType: Option; DocumentNo: Code[20]; LineNo: Integer; ProdOrderLineNo: Integer; var QtyToHandleBase: Decimal; var QtyToInvoiceBase: Decimal; var Handle: Boolean; var Invoice: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTrackingByType(var ReservationEntry: Record "Reservation Entry"; var QtyToHandleBase: Decimal; var QtyToInvoiceBase: Decimal; var OnlyLot: Boolean; var Handle: Boolean; var Invoice: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFromPurchLine(var TrackingSpecification: Record "Tracking Specification"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFromSalesLine(var TrackingSpecification: Record "Tracking Specification"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitExpirationDate(var TrackingSpecification: Record "Tracking Specification"; xRec: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetTrackingKey(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsReclass(TrackingSpecification: Record "Tracking Specification"; var Reclass: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemTrackingQuantity(var TrackingSpecification: Record "Tracking Specification"; var ReservationEntry: Record "Reservation Entry"; TableNo: Integer; DocumentType: Option; DocumentNo: Code[20]; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSerialNoQty(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityBaseOnBeforeCheckItemTrackingChange(var TrackingSpecification: Record "Tracking Specification"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateExpirationDateOnBeforeResetExpirationDate(var TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckApplyFromItemEntrySourceType(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceShipmentDate(var TrackingSpecification: Record "Tracking Specification"; var ShipmentDate: Date);
    begin
    end;
}

