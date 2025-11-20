// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Counting.Comment;
using Microsoft.Inventory.Counting.History;
using Microsoft.Inventory.Counting.Recording;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Sales.History;
using Microsoft.Warehouse.Structure;

table 5875 "Phys. Invt. Order Header"
{
    Caption = 'Phys. Invt. Order Header';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Physical Inventory Orders";
    LookupPageID = "Physical Inventory Orders";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    InvtSetup.Get();
                    NoSeries.TestManual(GetNoSeriesCode());
                    "No. Series" := '';
                end;
            end;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; Status; Enum "Phys. Invt. Order Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(20; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                if "Posting Date" <> xRec."Posting Date" then begin
                    PhysInvtOrderLine.Reset();
                    PhysInvtOrderLine.SetRange("Document No.", "No.");
                    PhysInvtOrderLine.SetFilter("Item No.", '<>%1', '');
                    if PhysInvtOrderLine.Find('-') then begin
                        TestField("Posting Date");
                        if not Confirm(
                             StrSubstNo(
                               ConfirmChangeQst,
                               PhysInvtOrderLine.FieldCaption("Qty. Expected (Base)"),
                               FieldCaption("Posting Date")),
                             false)
                        then begin
                            "Posting Date" := xRec."Posting Date";
                            exit;
                        end;
                        PhysInvtOrderLine.LockTable();
                        PhysInvtOrderLine.Reset();
                        PhysInvtOrderLine.SetRange("Document No.", "No.");
                        if PhysInvtOrderLine.Find('-') then
                            repeat
                                if PhysInvtOrderLine."Item No." <> '' then begin
                                    PhysInvtOrderLine.ResetQtyExpected();
                                    PhysInvtOrderLine.Modify();
                                end;
                            until PhysInvtOrderLine.Next() = 0;
                        Modify();
                    end;
                end;
            end;
        }
        field(30; Comment; Boolean)
        {
            CalcFormula = exist("Phys. Invt. Comment Line" where("Document Type" = const(Order),
                                                                  "Order No." = field("No."),
                                                                  "Recording No." = const(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Person Responsible"; Code[20])
        {
            Caption = 'Person Responsible';
            TableRelation = Employee;
            ValidateTableRelation = false;
        }
        field(40; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(41; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(50; "Shortcut Dimension 1 Code"; Code[20])
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
        field(51; "Shortcut Dimension 2 Code"; Code[20])
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
        field(60; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                PhysInvtOrderHeader := Rec;
                InvtSetup.Get();
                TestNoSeries();
                if NoSeries.LookupRelatedNoSeries(GetPostingNoSeriesCode(), PhysInvtOrderHeader."Posting No. Series", PhysInvtOrderHeader."Posting No. Series") then
                    PhysInvtOrderHeader.Validate("Posting No. Series");
                Rec := PhysInvtOrderHeader;
            end;

            trigger OnValidate()
            begin
                if "Posting No. Series" <> '' then begin
                    InvtSetup.Get();
                    TestNoSeries();
                    NoSeries.TestAreRelated(GetPostingNoSeriesCode(), "Posting No. Series");
                end;
                TestField("Posting No.", '');
            end;
        }
        field(61; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(64; "Posting No."; Code[20])
        {
            Caption = 'Posting No.';
        }
        field(65; "Last Posting No."; Code[20])
        {
            Caption = 'Last Posting No.';
            Editable = false;
            TableRelation = "Sales Invoice Header";
        }
        field(71; "No. Finished Recordings"; Integer)
        {
            CalcFormula = count("Phys. Invt. Record Header" where("Order No." = field("No."),
                                                                   Status = const(Finished)));
            Caption = 'No. Finished Recordings';
            Editable = false;
            FieldClass = FlowField;
        }
        field(110; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(Rec.FieldNo("Location Code"));
            end;
        }
        field(111; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBinCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Bin Code" <> '' then begin
                    TestField("Location Code");
                    Location.Get("Location Code");
                    Location.TestField("Bin Mandatory", true);
                    Location.TestField("Directed Put-away and Pick", false);
                end;
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDocDim();
            end;

            trigger OnValidate()
            begin
                DimManagement.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; Status)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description)
        {
        }
    }

    trigger OnDelete()
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtCommentLine: Record "Phys. Invt. Comment Line";
    begin
        TestField(Status, Status::Open);

        TestField("No. Finished Recordings", 0);

        PhysInvtOrderLine.Reset();
        PhysInvtOrderLine.SetRange("Document No.", "No.");
        PhysInvtOrderLine.DeleteAll(true);

        PhysInvtCommentLine.Reset();
        PhysInvtCommentLine.SetRange("Document Type", PhysInvtCommentLine."Document Type"::Order);
        PhysInvtCommentLine.SetRange("Order No.", "No.");
        PhysInvtCommentLine.SetRange("Recording No.", 0);
        PhysInvtCommentLine.DeleteAll();

        PhysInvtRecordHeader.Reset();
        PhysInvtRecordHeader.SetRange("Order No.", "No.");
        PhysInvtRecordHeader.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
    begin
        InvtSetup.Get();
        InitInsert();

        if PstdPhysInvtOrderHdr.Get("No.") then
            Error(AlreadyExistsErr, "No.");

        InitRecord();
    end;

    trigger OnModify()
    begin
        TestField(Status, Status::Open);
    end;

    trigger OnRename()
    begin
        Error(CannotRenameErr, TableCaption);
    end;

    var
        AlreadyExistsErr: Label 'Posted Invt. Count Order %1 already exists.', Comment = '%1 = Order No.';
        CannotRenameErr: Label 'You cannot rename a %1.', Comment = '%1 = table caption';
        ConfirmChangeQst: Label '%1 will be reset in all order lines. Do you want to change %2?', Comment = '%1 = field caption, %2 = Posting Date';
        InvtSetup: Record "Inventory Setup";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        Location: Record Location;
        NoSeries: Codeunit "No. Series";
        DimManagement: Codeunit DimensionManagement;
        UpdateDimQst: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        MoreThanOneLineErr: Label 'There are more than one order lines in Order %1 for Item No. %2, Variant Code %3, Location Code %4, Bin Code %5.', Comment = '%1 Order No. %2 Item No. %3 Variant Code %4 Location Code %5 Bin Code';
        NoLineErr: Label 'There are no order line in Order %1 for Item No. %2, Variant Code %3, Location Code %4, Bin Code %5.', Comment = '%1 Order No. %2 Item No. %3 Variant Code %4 Location Code %5 Bin Code';

    local procedure InitInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnInitInsertOnBeforeInitSeries(xRec, IsHandled);
        if not IsHandled then
            if "No." = '' then begin
                TestNoSeries();
                if NoSeries.AreRelated(GetNoSeriesCode(), xRec."No. Series") then
                    "No. Series" := xRec."No. Series"
                else
                    "No. Series" := GetNoSeriesCode();
                "No." := NoSeries.GetNextNo("No. Series", "Order Date");
            end;

        OnInitInsertOnBeforeInitRecord(xRec);
        InitRecord();
    end;

    procedure InitRecord()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitRecord(Rec, xRec, IsHandled);
        if not IsHandled then begin
            if ("No. Series" <> '') and
               (InvtSetup."Phys. Invt. Order Nos." = InvtSetup."Posted Phys. Invt. Order Nos.")
            then
                "Posting No. Series" := "No. Series"
            else
                if NoSeries.IsAutomatic(InvtSetup."Posted Phys. Invt. Order Nos.") then
                    "Posting No. Series" := InvtSetup."Posted Phys. Invt. Order Nos.";

            if "Posting Date" = 0D then
                Validate("Posting Date", WorkDate());
        end;

        OnAfterInitRecord(Rec);
    end;

    procedure AssistEdit(OldPhysInvtOrderHeader: Record "Phys. Invt. Order Header"): Boolean
    begin
        PhysInvtOrderHeader := Rec;
        InvtSetup.Get();
        TestNoSeries();
        if NoSeries.LookupRelatedNoSeries(GetNoSeriesCode(), OldPhysInvtOrderHeader."No. Series", PhysInvtOrderHeader."No. Series") then begin
            PhysInvtOrderHeader."No." := NoSeries.GetNextNo(PhysInvtOrderHeader."No. Series");
            Rec := PhysInvtOrderHeader;
            exit(true);
        end;
    end;

    local procedure TestNoSeries()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestNoSeries(Rec, IsHandled);
        if not IsHandled then begin
            InvtSetup.TestField("Phys. Invt. Order Nos.");
            InvtSetup.TestField("Posted Phys. Invt. Order Nos.");
        end;

        OnAfterTestNoSeries(Rec);
    end;

    local procedure GetNoSeriesCode(): Code[20]
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
    begin
        InvtSetup.Get();
        IsHandled := false;
        OnBeforeGetNoSeriesCode(Rec, InvtSetup, NoSeriesCode, IsHandled);
        if IsHandled then
            exit(NoSeriesCode);

        NoSeriesCode := InvtSetup."Phys. Invt. Order Nos.";
        OnAfterGetNoSeriesCode(Rec, NoSeriesCode);
        exit(NoSeriesCode);
    end;

    local procedure GetPostingNoSeriesCode(): Code[10]
    begin
        exit(InvtSetup."Posted Phys. Invt. Order Nos.");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        OldDimSetID := "Dimension Set ID";
        DimManagement.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if "No." <> '' then
            Modify();

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if PhysInvtOrderLinesExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure GetSamePhysInvtOrderLine(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; var ErrorText: Text[250]; var PhysInvtOrderLine2: Record "Phys. Invt. Order Line"): Integer
    var
        PhysInvtOrderLineArgs: Record "Phys. Invt. Order Line";
    begin
        PhysInvtOrderLineArgs."Item No." := ItemNo;
        PhysInvtOrderLineArgs."Variant Code" := VariantCode;
        PhysInvtOrderLineArgs."Location Code" := LocationCode;
        PhysInvtOrderLineArgs."Bin Code" := BinCode;
        exit(GetSamePhysInvtOrderLine(PhysInvtOrderLineArgs, ErrorText, PhysInvtOrderLine2));
    end;

    procedure GetSamePhysInvtOrderLine(PhysInvtOrderLineArgs: Record "Phys. Invt. Order Line"; var ErrorText: Text[250]; var PhysInvtOrderLine2: Record "Phys. Invt. Order Line"): Integer
    var
        NoOfOrderLines: Integer;
    begin
        Clear(PhysInvtOrderLine2);

        PhysInvtOrderLine2.Reset();
        PhysInvtOrderLine2.SetCurrentKey(
          "Document No.", "Item No.", "Variant Code", "Location Code", "Bin Code");
        PhysInvtOrderLine2.SetRange("Document No.", "No.");
        PhysInvtOrderLine2.SetRange("Item No.", PhysInvtOrderLineArgs."Item No.");
        PhysInvtOrderLine2.SetRange("Variant Code", PhysInvtOrderLineArgs."Variant Code");
        PhysInvtOrderLine2.SetRange("Location Code", PhysInvtOrderLineArgs."Location Code");
        PhysInvtOrderLine2.SetRange("Bin Code", PhysInvtOrderLineArgs."Bin Code");
        OnGetSamePhysInvtOrderLineOnAfterSetFilters(PhysInvtOrderLine2, Rec, PhysInvtOrderLineArgs);
        NoOfOrderLines := PhysInvtOrderLine2.Count();

        case NoOfOrderLines of
            0:
                ErrorText :=
                    StrSubstNo(
                        NoLineErr, "No.", PhysInvtOrderLineArgs."Item No.", PhysInvtOrderLineArgs."Variant Code",
                        PhysInvtOrderLineArgs."Location Code", PhysInvtOrderLineArgs."Bin Code");
            1:
                ErrorText := '';
            else
                ErrorText :=
                    StrSubstNo(
                        MoreThanOneLineErr, "No.", PhysInvtOrderLineArgs."Item No.", PhysInvtOrderLineArgs."Variant Code",
                            PhysInvtOrderLineArgs."Location Code", PhysInvtOrderLineArgs."Bin Code");
        end;
        OnAfterSetErrorText(NoOfOrderLines, "No.", PhysInvtOrderLineArgs, ErrorText);

        if NoOfOrderLines > 0 then
            PhysInvtOrderLine2.Find('-');

        exit(NoOfOrderLines);
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
        DimManagement.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code", FieldNo = Rec.FieldNo("Location Code"));
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        OldDimSetID: Integer;
    begin
        SourceCodeSetup.Get();
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimManagement.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup."Phys. Invt. Orders", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        if (OldDimSetID <> "Dimension Set ID") and (OldDimSetID <> 0) then
            DimManagement.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if PhysInvtOrderLinesExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimManagement.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if OldDimSetID <> "Dimension Set ID" then begin
            OnShowDocDimOnBeforeModify(Rec, xRec);
            Modify();
            if PhysInvtOrderLinesExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure PhysInvtOrderLinesExist(): Boolean
    begin
        PhysInvtOrderLine.Reset();
        PhysInvtOrderLine.SetRange("Document No.", "No.");
        exit(PhysInvtOrderLine.FindFirst());
    end;

    procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        NewDimSetID: Integer;
    begin
        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not Confirm(UpdateDimQst) then
            exit;

        PhysInvtOrderLine.Reset();
        PhysInvtOrderLine.SetRange("Document No.", "No.");
        PhysInvtOrderLine.LockTable();
        if PhysInvtOrderLine.FindSet() then
            repeat
                NewDimSetID := DimManagement.GetDeltaDimSetID(PhysInvtOrderLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if PhysInvtOrderLine."Dimension Set ID" <> NewDimSetID then begin
                    PhysInvtOrderLine."Dimension Set ID" := NewDimSetID;
                    DimManagement.UpdateGlobalDimFromDimSetID(
                      PhysInvtOrderLine."Dimension Set ID", PhysInvtOrderLine."Shortcut Dimension 1 Code",
                      PhysInvtOrderLine."Shortcut Dimension 2 Code");
                    OnUpdateAllLineDimOnBeforePhysInvtOrderLineModify(PhysInvtOrderLine, Rec, xRec);
                    PhysInvtOrderLine.Modify();
                end;
            until PhysInvtOrderLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoSeriesCode(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var NoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestNoSeries(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeriesCode(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; InventorySetup: Record "Inventory Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRecord(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; xPhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoSeries(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var xPhysInvtOrderHeader: Record "Phys. Invt. Order Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var xPhysInvtOrderHeader: Record "Phys. Invt. Order Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBinCode(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSamePhysInvtOrderLineOnAfterSetFilters(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; PhysInvtOrderLineArgs: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInitInsertOnBeforeInitSeries(var xPhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInitInsertOnBeforeInitRecord(var xPhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetErrorText(NoOfOrderLines: Integer; OrderNo: Code[20]; PhysInvtOrderLineArgs: Record "Phys. Invt. Order Line"; var ErrorText: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDocDimOnBeforeModify(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; xPhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforePhysInvtOrderLineModify(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; xPhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
    end;
}

