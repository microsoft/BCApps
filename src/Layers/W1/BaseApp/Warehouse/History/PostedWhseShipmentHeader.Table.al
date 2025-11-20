// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.History;

using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

table 7322 "Posted Whse. Shipment Header"
{
    Caption = 'Posted Whse. Shipment Header';
    LookupPageID = "Posted Whse. Shipment List";
    Permissions = TableData "Posted Whse. Shipment Line" = rd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(3; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Warehouse Employee" where("Location Code" = field("Location Code"));
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
        field(7; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = exist("Warehouse Comment Line" where("Table Name" = const("Posted Whse. Shipment"),
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
        }
        field(13; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));
        }
        field(39; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(40; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(41; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
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
        field(45; "Whse. Shipment No."; Code[20])
        {
            Caption = 'Whse. Shipment No.';
        }
        field(48; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
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
        key(Key3; "Whse. Shipment No.")
        {
        }
        key(Key4; "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Location Code", "Posting Date")
        {
        }
    }

    trigger OnDelete()
    var
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        WhseCommentLine: Record "Warehouse Comment Line";
    begin
        PostedWhseShptLine.SetRange("No.", "No.");
        PostedWhseShptLine.DeleteAll();

        WhseCommentLine.SetRange("Table Name", WhseCommentLine."Table Name"::"Posted Whse. Shipment");
        WhseCommentLine.SetRange(Type, WhseCommentLine.Type::" ");
        WhseCommentLine.SetRange("No.", "No.");
        WhseCommentLine.DeleteAll();
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        WhseSetup.Get();
        if "No." = '' then begin
            IsHandled := false;
            OnInsertOnBeforeTestWhseShipmentNos(WhseSetup, IsHandled);
            if not IsHandled then
                WhseSetup.TestField("Posted Whse. Shipment Nos.");
                "No. Series" := WhseSetup."Posted Whse. Shipment Nos.";
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series", "Posting Date");
        end;
    end;

    var
        WhseSetup: Record "Warehouse Setup";

    procedure LookupPostedWhseShptHeader(var PostedWhseShptHeader: Record "Posted Whse. Shipment Header")
    begin
        Commit();
        if UserId <> '' then begin
            PostedWhseShptHeader.FilterGroup := 2;
            PostedWhseShptHeader.SetRange("Location Code");
        end;
        if PAGE.RunModal(0, PostedWhseShptHeader) = ACTION::LookupOK then;
        if UserId <> '' then begin
            PostedWhseShptHeader.FilterGroup := 2;
            PostedWhseShptHeader.SetRange("Location Code", PostedWhseShptHeader."Location Code");
            PostedWhseShptHeader.FilterGroup := 0;
        end;
    end;

    procedure FindFirstAllowedRec(Which: Text[1024]): Boolean
    var
        PostedWhseShptHeader: Record "Posted Whse. Shipment Header";
        WMSManagement: Codeunit "WMS Management";
    begin
        if Find(Which) then begin
            PostedWhseShptHeader := Rec;
            while true do begin
                if WMSManagement.LocationIsAllowedToView("Location Code") then
                    exit(true);

                if Next(1) = 0 then begin
                    Rec := PostedWhseShptHeader;
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
        PostedWhseShptHeader: Record "Posted Whse. Shipment Header";
        WMSManagement: Codeunit "WMS Management";
        RealSteps: Integer;
        NextSteps: Integer;
    begin
        RealSteps := 0;
        if Steps <> 0 then begin
            PostedWhseShptHeader := Rec;
            repeat
                NextSteps := Next(Steps / Abs(Steps));
                if WMSManagement.LocationIsAllowedToView("Location Code") then begin
                    RealSteps := RealSteps + NextSteps;
                    PostedWhseShptHeader := Rec;
                end;
            until (NextSteps = 0) or (RealSteps = Steps);
            Rec := PostedWhseShptHeader;
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeErrorIfUserIsNotWhseEmployee(LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeTestWhseShipmentNos(WarehouseSetup: Record "Warehouse Setup"; var IsHandled: Boolean)
    begin
    end;
}
