// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

table 7320 "Warehouse Shipment Header"
{
    Caption = 'Warehouse Shipment Header';
    DataCaptionFields = "No.";
    LookupPageID = "Warehouse Shipment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                WarehouseSetup.Get();
                if "No." <> xRec."No." then begin
                    NoSeries.TestManual(WarehouseSetup."Whse. Ship Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            var
                WarehouseShipmentLine: Record "Warehouse Shipment Line";
                WMSManagement: Codeunit "WMS Management";
            begin
                if not WMSManagement.LocationIsAllowed("Location Code") then
                    Error(Text003, "Location Code");

                if "Location Code" <> xRec."Location Code" then begin
                    "Zone Code" := '';
                    "Bin Code" := '';
                    WarehouseShipmentLine.SetRange("No.", "No.");
                    if not WarehouseShipmentLine.IsEmpty() then
                        Error(
                          Text001,
                          FieldCaption("Location Code"));
                end;

                GetLocation("Location Code");
                Location.TestField("Require Shipment");
                if Location."Bin Mandatory" then
                    Validate("Bin Code", Location."Shipment Bin Code");

                if UserId() <> '' then begin
                    FilterGroup := 2;
                    SetRange("Location Code", "Location Code");
                    FilterGroup := 0;
                end;
            end;
        }
        field(3; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Warehouse Employee" where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                if "Assigned User ID" <> '' then begin
                    "Assignment Date" := Today;
                    "Assignment Time" := Time;
                end else begin
                    "Assignment Date" := 0D;
                    "Assignment Time" := 0T;
                end;
            end;
        }
        field(4; "Assignment Date"; Date)
        {
            Caption = 'Assignment Date';
            Editable = false;
        }
        field(5; "Assignment Time"; Time)
        {
            Caption = 'Assignment Time';
            Editable = false;
        }
        field(6; "Sorting Method"; Enum "Warehouse Shipment Sorting Method")
        {
            Caption = 'Sorting Method';

            trigger OnValidate()
            begin
                if "Sorting Method" <> xRec."Sorting Method" then
                    SortWhseDoc();
            end;
        }
        field(7; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = exist("Warehouse Comment Line" where("Table Name" = const("Whse. Shipment"),
                                                                Type = const(" "),
                                                                "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = if ("Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                               "Zone Code" = field("Zone Code"));

            trigger OnValidate()
            var
                Bin: Record Bin;
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
            begin
                if (xRec."Bin Code" <> "Bin Code") or ("Zone Code" = '') then begin
                    TestField(Status, Status::Open);
                    if "Bin Code" <> '' then begin
                        GetLocation("Location Code");
                        WhseIntegrationMgt.CheckBinTypeAndCode(
                            Database::"Warehouse Shipment Header", FieldCaption("Bin Code"), "Location Code", "Bin Code", 0);
                        Bin.Get("Location Code", "Bin Code");
                        "Zone Code" := Bin."Zone Code";
                    end;
                    MessageIfShipmentLinesExist(FieldCaption("Bin Code"));
                end;
            end;
        }
        field(13; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                if "Zone Code" <> xRec."Zone Code" then begin
                    TestField(Status, Status::Open);
                    if "Zone Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Directed Put-away and Pick");
                    end;
                    "Bin Code" := '';
                    MessageIfShipmentLinesExist(FieldCaption("Zone Code"));
                end;
            end;
        }
        field(34; "Document Status"; Enum "Warehouse Shipment Status")
        {
            Caption = 'Document Status';
            Editable = false;

            trigger OnValidate()
            var
                WhsePickRequest: Record "Whse. Pick Request";
            begin
                CalcFields("Completely Picked");
                if "Completely Picked" <> xRec."Completely Picked" then begin
                    WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Shipment);
                    WhsePickRequest.SetRange("Document No.", "No.");
                    if not WhsePickRequest.IsEmpty() then
                        WhsePickRequest.ModifyAll("Completely Picked", "Completely Picked");
                end;
            end;
        }
        field(39; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(41; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                if xRec."Shipping Agent Code" = "Shipping Agent Code" then
                    exit;

                "Shipping Agent Service Code" := '';
            end;
        }
        field(42; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(43; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(45; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';

            trigger OnValidate()
            var
                WarehouseShipmentLine: Record "Warehouse Shipment Line";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShipmentDate(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Shipment Date" <> xRec."Shipment Date" then begin
                    WarehouseShipmentLine.SetRange("No.", "No.");
                    if not WarehouseShipmentLine.IsEmpty() then
                        if ConfirmModification() then
                            WarehouseShipmentLine.ModifyAll("Shipment Date", "Shipment Date");
                end;
            end;
        }
        field(46; "Completely Picked"; Boolean)
        {
            CalcFormula = min("Warehouse Shipment Line"."Completely Picked" where("No." = field("No.")));
            Caption = 'Completely Picked';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(48; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(50; "Create Posted Header"; Boolean)
        {
            Caption = 'Create Posted Header';
        }
        field(61; "Shipping No."; Code[20])
        {
            Caption = 'Shipping No.';
        }
        field(62; "Last Shipping No."; Code[20])
        {
            Caption = 'Last Shipping No.';
            Editable = false;
            TableRelation = "Posted Whse. Shipment Header";
        }
        field(63; "Shipping No. Series"; Code[20])
        {
            Caption = 'Shipping No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            var
                WarehouseShipmentHeader: Record "Warehouse Shipment Header";
            begin
                WarehouseShipmentHeader := Rec;
                WarehouseSetup.Get();
                WarehouseSetup.TestField("Posted Whse. Shipment Nos.");
                if NoSeries.LookupRelatedNoSeries(WarehouseSetup."Posted Whse. Shipment Nos.", WarehouseShipmentHeader."Shipping No. Series") then
                    WarehouseShipmentHeader.Validate(WarehouseShipmentHeader."Shipping No. Series");
                Rec := WarehouseShipmentHeader;
            end;

            trigger OnValidate()
            begin
                if "Shipping No. Series" <> '' then begin
                    WarehouseSetup.Get();
                    WarehouseSetup.TestField("Posted Whse. Shipment Nos.");
                    NoSeries.TestAreRelated(WarehouseSetup."Posted Whse. Shipment Nos.", "Shipping No. Series");
                end;
                TestField("Shipping No.", '');
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Location Code")
        {
        }
        key(Key3; "Shipment Date", "Document Status")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField(Status, Status::Open);
        OnDeleteOnBeforeDeleteWarehouseShipmentLines(Rec, HideValidationDialog);
        DeleteWarehouseShipmentLines();
        DeleteRelatedLines();
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, xRec, WarehouseSetup, Location, IsHandled);
        if IsHandled then
            exit;

        WarehouseSetup.Get();
        if "No." = '' then begin
            WarehouseSetup.TestField("Whse. Ship Nos.");
                "No. Series" := WarehouseSetup."Whse. Ship Nos.";
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series", "Posting Date");
        end;

        if NoSeries.IsAutomatic(WarehouseSetup."Posted Whse. Shipment Nos.") then
            "Shipping No. Series" := WarehouseSetup."Posted Whse. Shipment Nos.";

        GetLocation("Location Code");
        Validate("Bin Code", Location."Shipment Bin Code");
        "Posting Date" := WorkDate();
        "Shipment Date" := WorkDate();

        OnAfterOnInsert(Rec, xRec);
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Location: Record Location;
        WarehouseSetup: Record "Warehouse Setup";
        NoSeries: Codeunit "No. Series";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'You cannot change the %1, because the document has one or more lines.';
        Text003: Label 'You are not allowed to use location code %1.';
        Text006: Label 'You have changed %1 on the %2, but it has not been changed on the existing Warehouse Shipment Lines.\';
#pragma warning restore AA0470
        Text007: Label 'You must update the existing Warehouse Shipment Lines manually.';
#pragma warning disable AA0470
        Text008: Label 'You have modified the %1.\\Do you want to update the lines?';
#pragma warning restore AA0470
        Text009: Label 'The items have been picked. If you delete the warehouse shipment, then the items will remain in the shipping area until you put them away.\Related item tracking information that is defined during the pick will be deleted.\Are you sure that you want to delete the warehouse shipment?';
#pragma warning restore AA0074

    protected var
        HideValidationDialog: Boolean;

    procedure AssistEdit(OldWarehouseShipmentHeader: Record "Warehouse Shipment Header"): Boolean
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        WarehouseSetup.Get();
        WarehouseShipmentHeader := Rec;
        WarehouseSetup.TestField("Whse. Ship Nos.");
        if NoSeries.LookupRelatedNoSeries(WarehouseSetup."Whse. Ship Nos.", OldWarehouseShipmentHeader."No. Series", WarehouseShipmentHeader."No. Series") then begin
            WarehouseShipmentHeader."No." := NoSeries.GetNextNo(WarehouseShipmentHeader."No. Series");
            Rec := WarehouseShipmentHeader;
            exit(true);
        end;

        OnAfterAssistEdit(OldWarehouseShipmentHeader);
    end;

    local procedure ConfirmModification() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmModification(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := Confirm(StrSubstNo(Text008, Rec.FieldCaption("Shipment Date")), false);
    end;

    procedure SortWhseDoc()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SequenceNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSortWhseDoc(Rec, IsHandled);
        if IsHandled then
            exit;

        WarehouseShipmentLine.SetRange("No.", "No.");
        case "Sorting Method" of
            "Sorting Method"::Item:
                WarehouseShipmentLine.SetCurrentKey("No.", "Item No.");
            "Sorting Method"::Document:
                WarehouseShipmentLine.SetCurrentKey("No.", "Source Document", "Source No.");
            "Sorting Method"::"Shelf or Bin":
                begin
                    GetLocation("Location Code");
                    if Location."Bin Mandatory" then
                        WarehouseShipmentLine.SetCurrentKey("No.", "Bin Code")
                    else
                        WarehouseShipmentLine.SetCurrentKey("No.", "Shelf No.");
                end;
            "Sorting Method"::"Due Date":
                WarehouseShipmentLine.SetCurrentKey("No.", "Due Date");
            "Sorting Method"::Destination:
                WarehouseShipmentLine.SetCurrentKey("No.", "Destination Type", "Destination No.");
            else
                OnSortWhseDocCaseElse(Rec, WarehouseShipmentLine);
        end;

        if WarehouseShipmentLine.Find('-') then begin
            SequenceNo := 10000;
            repeat
                WarehouseShipmentLine."Sorting Sequence No." := SequenceNo;
                WarehouseShipmentLine.Modify();
                SequenceNo := SequenceNo + 10000;
            until WarehouseShipmentLine.Next() = 0;
        end;
    end;

#if not CLEAN26
    [Obsolete('Replaced by procedure GetShipmentStatus()', '26.0')]
    procedure GetDocumentStatus(SkipLineNo: Integer): Integer
    begin
        exit(GetShipmentStatus(SkipLineNo).AsInteger());
    end;
#endif

    procedure GetShipmentStatus(SkipLineNo: Integer): Enum "Warehouse Shipment Status"
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("No.", "No.");
        if SkipLineNo <> 0 then
            WarehouseShipmentLine.SetFilter("Line No.", '<>%1', SkipLineNo);
        if not WarehouseShipmentLine.FindFirst() then
            exit(WarehouseShipmentLine.Status::" ");

        OnGetDocumentStatusOnBeforeCheckPartllyShipped(Rec, WarehouseShipmentLine);
        WarehouseShipmentLine.SetRange(Status, WarehouseShipmentLine.Status::"Partially Shipped");
        if not WarehouseShipmentLine.IsEmpty() then
            exit(WarehouseShipmentLine.Status::"Partially Shipped");

        WarehouseShipmentLine.SetRange(Status, WarehouseShipmentLine.Status::"Partially Picked");
        if not WarehouseShipmentLine.IsEmpty() then
            exit(WarehouseShipmentLine.Status::"Partially Picked");

        WarehouseShipmentLine.SetRange(Status, WarehouseShipmentLine.Status::"Completely Picked");
        if not WarehouseShipmentLine.IsEmpty() then begin
            WarehouseShipmentLine.SetFilter(Status, '<%1', WarehouseShipmentLine.Status::"Completely Picked");
            if not WarehouseShipmentLine.IsEmpty() then
                exit(WarehouseShipmentLine.Status::"Partially Picked");

            exit(WarehouseShipmentLine.Status::"Completely Picked");
        end;

        WarehouseShipmentLine.SetRange(Status, WarehouseShipmentLine.Status::"Completely Shipped");
        if not WarehouseShipmentLine.IsEmpty() then begin
            WarehouseShipmentLine.SetFilter(Status, '<%1', WarehouseShipmentLine.Status::"Completely Shipped");
            if not WarehouseShipmentLine.IsEmpty() then
                exit(WarehouseShipmentLine.Status::"Partially Shipped");

            exit(WarehouseShipmentLine.Status::"Completely Shipped");
        end;

        exit(WarehouseShipmentLine.Status::" ");
    end;

    procedure MessageIfShipmentLinesExist(ChangedFieldName: Text[80])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("No.", "No.");
        if not WarehouseShipmentLine.IsEmpty() then
            if not HideValidationDialog then
                Message(
                  StrSubstNo(
                    Text006, ChangedFieldName, TableCaption) + Text007);
    end;

    procedure GetLocation(LocationCode: Code[10]): Record Location
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetLocation(LocationCode, Rec, Location, IsHandled);
        if IsHandled then
            exit(Location);

        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
        exit(Location);
    end;

    procedure LookupLocation(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        LocationForLookup: Record Location;
    begin
        Commit();
        LocationForLookup.FilterGroup := 2;
        LocationForLookup.SetRange(Code);
        if Page.RunModal(Page::"Locations with Warehouse List", LocationForLookup) = Action::LookupOK then
            WarehouseShipmentHeader.Validate("Location Code", LocationForLookup.Code);
        LocationForLookup.FilterGroup := 0;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure DeleteRelatedLines()
    var
        WhsePickRequest: Record "Whse. Pick Request";
        WarehouseCommentLine: Record "Warehouse Comment Line";
    begin
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Shipment);
        WhsePickRequest.SetRange("Document No.", "No.");
        if not WhsePickRequest.IsEmpty() then
            WhsePickRequest.DeleteAll();

        WarehouseCommentLine.SetRange("Table Name", WarehouseCommentLine."Table Name"::"Whse. Shipment");
        WarehouseCommentLine.SetRange(Type, WarehouseCommentLine.Type::" ");
        WarehouseCommentLine.SetRange("No.", "No.");
        if not WarehouseCommentLine.IsEmpty() then
            WarehouseCommentLine.DeleteAll();

        OnAfterDeleteRelatedLines(Rec, xRec);
    end;

    procedure DeleteWarehouseShipmentLines()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        Confirmed: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteWarehouseShipmentLines(Rec, IsHandled);
        if IsHandled then
            exit;

        WarehouseShipmentLine.SetRange("No.", "No.");
        if WarehouseShipmentLine.Find('-') then
            repeat
                if WarehouseShipmentLine."Qty. Shipped" < WarehouseShipmentLine."Qty. Picked" then begin
                    IsHandled := false;
                    OnDeleteWarehouseShipmentLinesOnBeforeConfirm(WarehouseShipmentLine, Confirmed, IsHandled);
                    if not IsHandled then begin
                        if not Confirm(Text009) then
                            Error('');
                        Confirmed := true;
                    end;
                end;
            until (WarehouseShipmentLine.Next() = 0) or Confirmed;

        ItemTrackingManagement.SetDeleteReservationEntries(Confirmed);

        if WarehouseShipmentLine.Find('-') then
            repeat
                if WarehouseShipmentLine."Assemble to Order" then
                    WarehouseShipmentLine.Validate("Qty. to Ship", 0);
                ItemTrackingManagement.DeleteWhseItemTrkgLines(
                    Database::"Warehouse Shipment Line", 0, WarehouseShipmentLine."No.",
                    '', 0, WarehouseShipmentLine."Line No.", WarehouseShipmentLine."Location Code", true);

                OnBeforeWhseShptLineDelete(WarehouseShipmentLine);
                WarehouseShipmentLine.Delete();
            until WarehouseShipmentLine.Next() = 0;
    end;

    procedure FindFirstAllowedRec(Which: Text[1024]): Boolean
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WMSManagement: Codeunit "WMS Management";
    begin
        if Find(Which) then begin
            WarehouseShipmentHeader := Rec;
            while true do begin
                if WMSManagement.LocationIsAllowedToView("Location Code") then
                    exit(true);

                if Next(1) = 0 then begin
                    Rec := WarehouseShipmentHeader;
                    if Find(Which) then
                        while true do begin
                            if WMSManagement.LocationIsAllowedToView("Location Code") then
                                exit(true);

                            if Next(-1) = 0 then
                                exit(false);
                        end;
                end;
            end;
        end;
        exit(false);
    end;

    procedure FindNextAllowedRec(Steps: Integer): Integer
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WMSManagement: Codeunit "WMS Management";
        RealSteps: Integer;
        NextSteps: Integer;
    begin
        RealSteps := 0;
        if Steps <> 0 then begin
            WarehouseShipmentHeader := Rec;
            repeat
                NextSteps := Next(Steps / Abs(Steps));
                if WMSManagement.LocationIsAllowedToView("Location Code") then begin
                    RealSteps := RealSteps + NextSteps;
                    WarehouseShipmentHeader := Rec;
                end;
            until (NextSteps = 0) or (RealSteps = Steps);
            Rec := WarehouseShipmentHeader;
            if not Find() then;
        end;
        exit(RealSteps);
    end;

    procedure ErrorIfUserIsNotWhseEmployee()
    var
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeErrorIfUserIsNotWhseEmployee("Location Code", IsHandled);
        if IsHandled then
            exit;

        WMSManagement.CheckUserIsWhseEmployee();
    end;

    procedure ApplyCustomSortingToWhseShptLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        TempFirstPriorityWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary;
        TempSecondPriorityWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary;
        SequenceNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApplyCustomSortingToWhseShptLines(WarehouseShipmentLine, IsHandled);
        if IsHandled then
            exit;

        if not WarehouseShipmentLine.FindSet() then
            exit;

        repeat
            if MeetsCriteria(WarehouseShipmentLine) then begin
                TempFirstPriorityWarehouseShipmentLine := WarehouseShipmentLine;
                TempFirstPriorityWarehouseShipmentLine.Insert();
            end else begin
                TempSecondPriorityWarehouseShipmentLine := WarehouseShipmentLine;
                TempSecondPriorityWarehouseShipmentLine.Insert();
            end;
        until WarehouseShipmentLine.Next() = 0;

        SequenceNo := 10000;
        if TempFirstPriorityWarehouseShipmentLine.FindSet() then
            repeat
                WarehouseShipmentLine := TempFirstPriorityWarehouseShipmentLine;
                WarehouseShipmentLine.Find();
                WarehouseShipmentLine."Sorting Sequence No." := SequenceNo;
                WarehouseShipmentLine.Modify();
                SequenceNo += 10000;
            until TempFirstPriorityWarehouseShipmentLine.Next() = 0;

        if TempSecondPriorityWarehouseShipmentLine.FindSet() then
            repeat
                WarehouseShipmentLine := TempSecondPriorityWarehouseShipmentLine;
                WarehouseShipmentLine.Find();
                WarehouseShipmentLine."Sorting Sequence No." := SequenceNo;
                WarehouseShipmentLine.Modify();
                SequenceNo += 10000;
            until TempSecondPriorityWarehouseShipmentLine.Next() = 0;
    end;

    local procedure MeetsCriteria(WarehouseShipmentLine: Record "Warehouse Shipment Line") Result: Boolean
    var
        ReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMeetsCriteria(WarehouseShipmentLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ReservationEntry.SetSourceFilter(
          WarehouseShipmentLine."Source Type", WarehouseShipmentLine."Source Subtype", WarehouseShipmentLine."Source No.",
          WarehouseShipmentLine."Source Line No.", true);
        ReservationEntry.SetFilter("Item Tracking", '<>%1', ReservationEntry."Item Tracking"::None);
        Result := not ReservationEntry.IsEmpty();

        exit(Result);
    end;

    procedure ShipmentLinesEditable() IsEditable: Boolean;
    begin
        IsEditable := true;

        OnAfterShipmentLinesEditable(Rec, IsEditable);
    end;

    procedure BinCodeMandatory(): Boolean;
    begin
        exit(GetLocation("Location Code")."Bin Mandatory");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssistEdit(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInsert(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var xWarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShipmentLinesEditable(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsEditable: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmModification(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseShptLineDelete(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeErrorIfUserIsNotWhseEmployee(LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetLocation(LocationCode: Code[10]; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var Location: Record Location; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteWarehouseShipmentLinesOnBeforeConfirm(WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Confirmed: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeDeleteWarehouseShipmentLines(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipmentDate(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; xWarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSortWhseDoc(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSortWhseDocCaseElse(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteWarehouseShipmentLines(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyCustomSortingToWhseShptLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMeetsCriteria(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var xWarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WhseSetup: Record "Warehouse Setup"; var Location: Record Location; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentStatusOnBeforeCheckPartllyShipped(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRelatedLines(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; xWarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;
}
