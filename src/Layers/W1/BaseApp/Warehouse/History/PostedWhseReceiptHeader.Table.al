// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.History;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

table 7318 "Posted Whse. Receipt Header"
{
    Caption = 'Posted Whse. Receipt Header';
    LookupPageID = "Posted Whse. Receipt List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the code of the location where the items were received.';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(3; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            ToolTip = 'Specifies the ID of the user who is responsible for the document.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Warehouse Employee" where("Location Code" = field("Location Code"));
        }
        field(4; "Assignment Date"; Date)
        {
            Caption = 'Assignment Date';
            ToolTip = 'Specifies the date when the user was assigned the activity.';
            Editable = false;
        }
        field(5; "Assignment Time"; Time)
        {
            Caption = 'Assignment Time';
            ToolTip = 'Specifies the time when the user was assigned the activity.';
            Editable = false;
        }
        field(7; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
            TableRelation = "No. Series";
        }
        field(8; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            ToolTip = 'Specifies the code of the zone on this posted receipt header.';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));
        }
        field(9; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            ToolTip = 'Specifies the bin where the items are picked or put away.';
            TableRelation = if ("Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                               "Zone Code" = field("Zone Code"));
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = exist("Warehouse Comment Line" where("Table Name" = const("Posted Whse. Receipt"),
                                                                Type = const(" "),
                                                                "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date of the receipt.';
        }
        field(13; "Vendor Shipment No."; Code[35])
        {
            Caption = 'Vendor Shipment No.';
            ToolTip = 'Specifies the vendor''s shipment number. It is inserted in the corresponding field on the source document during posting.';
        }
        field(14; "Whse. Receipt No."; Code[20])
        {
            Caption = 'Whse. Receipt No.';
            ToolTip = 'Specifies the number of the warehouse receipt that the posted warehouse receipt concerns.';
        }
        field(15; "Document Status"; Option)
        {
            Caption = 'Document Status';
            ToolTip = 'Specifies the status of the posted warehouse receipt.';
            Editable = false;
            OptionCaption = ' ,Partially Put Away,Completely Put Away';
            OptionMembers = " ","Partially Put Away","Completely Put Away";
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
        key(Key3; "Whse. Receipt No.")
        {
        }
        key(Key4; "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Location Code", "Posting Date", "Document Status")
        {
        }
    }

    trigger OnDelete()
    begin
        DeleteRelatedLines();
    end;

    trigger OnInsert()
    var
        WarehouseSetup: Record "Warehouse Setup";
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        WarehouseSetup.Get();
        if "No." = '' then begin
            IsHandled := false;
            OnInsertOnBeforeTestWhseReceiptNos(WarehouseSetup, IsHandled);
            if not IsHandled then
                WarehouseSetup.TestField("Whse. Receipt Nos.");
                "No. Series" := WarehouseSetup."Posted Whse. Receipt Nos.";
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series", "Posting Date");
        end;
    end;

    procedure GetHeaderStatus(SkipLineNo: Integer): Integer
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        PostedWhseReceiptLine.SetRange("No.", "No.");
        if SkipLineNo <> 0 then
            PostedWhseReceiptLine.SetFilter("Line No.", '<>%1', SkipLineNo);

        PostedWhseReceiptLine.SetRange(Status, PostedWhseReceiptLine.Status::"Completely Put Away");
        if not PostedWhseReceiptLine.IsEmpty() then begin
            PostedWhseReceiptLine.SetFilter(Status, '<>%1', PostedWhseReceiptLine.Status::"Completely Put Away");
            if not PostedWhseReceiptLine.IsEmpty() then
                exit(PostedWhseReceiptLine.Status::"Partially Put Away");

            exit(PostedWhseReceiptLine.Status::"Completely Put Away");
        end else begin
            PostedWhseReceiptLine.SetRange(Status, PostedWhseReceiptLine.Status::"Partially Put Away");
            if not PostedWhseReceiptLine.IsEmpty() then
                exit(PostedWhseReceiptLine.Status::"Partially Put Away");
        end;

        exit(PostedWhseReceiptLine.Status::" ");
    end;

    local procedure DeleteRelatedLines()
    var
        Location: Record Location;
        WhsePutAwayRequest: Record "Whse. Put-away Request";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        WarehouseCommentLine: Record "Warehouse Comment Line";
    begin
        if Location.RequirePutaway("Location Code") then
            TestField("Document Status", "Document Status"::"Completely Put Away");

        WhsePutAwayRequest.SetRange("Document Type", WhsePutAwayRequest."Document Type"::Receipt);
        WhsePutAwayRequest.SetRange("Document No.", "No.");
        WhsePutAwayRequest.DeleteAll();

        PostedWhseReceiptLine.SetRange("No.", "No.");
        PostedWhseReceiptLine.DeleteAll();

        WarehouseCommentLine.SetRange("Table Name", WarehouseCommentLine."Table Name"::"Posted Whse. Receipt");
        WarehouseCommentLine.SetRange(Type, WarehouseCommentLine.Type::" ");
        WarehouseCommentLine.SetRange("No.", "No.");
        WarehouseCommentLine.DeleteAll();
    end;

    procedure LookupPostedWhseRcptHeader(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    begin
        Commit();
        if UserId() <> '' then begin
            PostedWhseReceiptHeader.FilterGroup := 2;
            PostedWhseReceiptHeader.SetRange("Location Code");
        end;
        if Page.RunModal(0, PostedWhseReceiptHeader) = Action::LookupOK then;
        if UserId() <> '' then begin
            PostedWhseReceiptHeader.FilterGroup := 2;
            PostedWhseReceiptHeader.SetRange("Location Code", PostedWhseReceiptHeader."Location Code");
            PostedWhseReceiptHeader.FilterGroup := 0;
        end;
    end;

    procedure FindFirstAllowedRec(Which: Text[1024]): Boolean
    var
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        WMSManagement: Codeunit "WMS Management";
    begin
        if Find(Which) then begin
            PostedWhseReceiptHeader := Rec;
            while true do begin
                if WMSManagement.LocationIsAllowedToView("Location Code") then
                    exit(true);

                if Next(1) = 0 then begin
                    Rec := PostedWhseReceiptHeader;
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
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        WMSManagement: Codeunit "WMS Management";
        RealSteps: Integer;
        NextSteps: Integer;
    begin
        RealSteps := 0;
        if Steps <> 0 then begin
            PostedWhseReceiptHeader := Rec;
            repeat
                NextSteps := Next(Steps / Abs(Steps));
                if WMSManagement.LocationIsAllowedToView("Location Code") then begin
                    RealSteps := RealSteps + NextSteps;
                    PostedWhseReceiptHeader := Rec;
                end;
            until (NextSteps = 0) or (RealSteps = Steps);
            Rec := PostedWhseReceiptHeader;
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
    local procedure OnInsertOnBeforeTestWhseReceiptNos(WarehouseSetup: Record "Warehouse Setup"; var IsHandled: Boolean)
    begin
    end;
}
