// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Structure;

table 7325 "Whse. Pick Request"
{
    Caption = 'Whse. Pick Request';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Warehouse Pick Request Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Document Subtype"; Option)
        {
            Caption = 'Document Subtype';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            NotBlank = true;
            TableRelation = if ("Document Type" = const(Shipment)) "Warehouse Shipment Header"."No."
            else
            if ("Document Type" = const("Internal Pick")) "Whse. Internal Pick Header"."No."
            else
            if ("Document Type" = const(Job)) Job."No." where(Status = const(Open));

            trigger OnLookup()
            begin
                LookupDocumentNo();
            end;
        }
        field(4; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(5; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));
        }
        field(6; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = if ("Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                               "Zone Code" = field("Zone Code"));
        }
        field(7; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(8; "Completely Picked"; Boolean)
        {
            Caption = 'Completely Picked';
        }
        field(9; "Shipment Method Code"; Code[10])
        {
            CalcFormula = lookup("Warehouse Shipment Header"."Shipment Method Code" where("No." = field("Document No.")));
            Caption = 'Shipment Method Code';
            Editable = false;
            FieldClass = FlowField;
            TableRelation = "Shipment Method";
        }
        field(10; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            CalcFormula = lookup("Warehouse Shipment Header"."Shipping Agent Code" where("No." = field("Document No.")));
            Caption = 'Shipping Agent Code';
            Editable = false;
            FieldClass = FlowField;
            TableRelation = "Shipping Agent";
        }
        field(11; "Shipping Agent Service Code"; Code[10])
        {
            CalcFormula = lookup("Warehouse Shipment Header"."Shipping Agent Service Code" where("No." = field("Document No.")));
            Caption = 'Shipping Agent Service Code';
            Editable = false;
            FieldClass = FlowField;
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document Subtype", "Document No.", "Location Code")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Document Type", Status) { }
    }

    fieldgroups
    {
    }

    local procedure LookupDocumentNo()
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        JobHeader: Record Job;
        WhseShptList: Page "Warehouse Shipment List";
        WhseInternalPickList: Page "Whse. Internal Pick List";
        JobList: Page "Job List";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupDocumentNo(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Document Type" of
            "Document Type"::Shipment:
                begin
                    if WhseShptHeader.Get("Document No.") then
                        WhseShptList.SetRecord(WhseShptHeader);
                    WhseShptList.RunModal();
                    Clear(WhseShptList);
                end;
            "Document Type"::"Internal Pick":
                begin
                    if WhseInternalPickHeader.Get("Document No.") then
                        WhseInternalPickList.SetRecord(WhseInternalPickHeader);
                    WhseInternalPickList.RunModal();
                    Clear(WhseInternalPickList);
                end;
            "Document Type"::Job:
                begin
                    if JobHeader.Get("Document No.") then
                        JobList.SetRecord(JobHeader);
                    JobList.RunModal();
                    Clear(JobList);
                end;
            else
                OnLookupDocumentNo(Rec);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDocumentNo(var WhsePickRequest: Record "Whse. Pick Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupDocumentNo(var WhsePickRequest: Record "Whse. Pick Request")
    begin
    end;
}

