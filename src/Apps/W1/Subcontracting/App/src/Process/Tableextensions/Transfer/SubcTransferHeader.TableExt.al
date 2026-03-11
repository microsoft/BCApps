// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

tableextension 99001520 "Subc. Transfer Header" extends "Transfer Header"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        modify("Direct Transfer")
        {
            trigger OnAfterValidate()
            begin
                SetDirectTransferPosting();
            end;
        }
        modify("Transfer-to Code")
        {
            trigger OnAfterValidate()
            var
                Location: Record Location;
            begin
                if "Transfer-to Code" = '' then
                    Validate("Direct Transfer Posting", "Direct Transfer Post. Type"::Empty)
                else begin
                    Location.Get("Transfer-to Code");
                    Validate("Direct Transfer Posting", Location."Direct Transfer Posting");
                end;
            end;
        }
        field(99001530; "Subcontr. Purch. Order No."; Code[20])
        {
            Caption = 'Subcontr. Purch. Order No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99001531; "Subcontr. PO Line No."; Integer)
        {
            Caption = 'Subcontr. Purch. Order Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99001535; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            DataClassification = CustomerContent;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(99001536; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
            DataClassification = CustomerContent;
            trigger OnLookup()
            begin
                HandleSubcontractingSourceLookup(Rec);
            end;
        }
        field(99001537; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
            DataClassification = CustomerContent;
        }
        field(99001540; "Source Type"; Enum "Transfer Source Type")
        {
            Caption = 'Source Type';
            DataClassification = CustomerContent;
        }
        field(99001541; "Return Order"; Boolean)
        {
            Caption = 'Return Order';
            DataClassification = CustomerContent;
        }
        field(99001553; "Direct Transfer Posting"; Enum "Direct Transfer Post. Type")
        {
            Caption = 'Direct Transfer Posting';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                ValidateDirectTransferPosting();
            end;
        }
        field(99001554; "Do Not Validate"; Boolean)
        {
            Caption = 'Do not validate';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }
    keys
    {
        key(Key99001500; "Subcontr. Purch. Order No.") { }
        key(Key99001501; "Source ID", "Source Type", "Source Subtype") { }
    }

    local procedure HandleSubcontractingSourceLookup(var TransferHeader: Record "Transfer Header")
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        if TransferHeader."Source Type" = TransferHeader."Source Type"::Subcontracting then
            case TransferHeader."Source Subtype" of
                TransferHeader."Source Subtype"::"1":
                    begin
                        Customer.SetRange("No.", TransferHeader."Source ID");
                        Page.RunModal(0, Customer);
                    end;
                TransferHeader."Source Subtype"::"2":
                    begin
                        Vendor.SetRange("No.", TransferHeader."Source ID");
                        Page.RunModal(0, Vendor);
                    end;
                TransferHeader."Source Subtype"::"3":
                    begin
                        Item.SetRange("No.", TransferHeader."Source ID");
                        Page.RunModal(0, Item);
                    end;
            end;
    end;

    procedure CheckDirectTransferPosting()
    var
        Location: Record Location;
    begin
        TestField("Transfer-to Code");
        Location.Get("Transfer-to Code");
        Location.SetLoadFields("Require Put-away", "Use Cross-Docking", "Require Receive");
        Location.CheckInboundWarehouseHandling();
    end;

    local procedure SetDirectTransferPosting()
    var
        Location: Record Location;
    begin
        if "Direct Transfer" then begin
            TestField("Transfer-to Code");
            if not "Do Not Validate" then begin
                Location.SetLoadFields("Direct Transfer Posting");
                Location.Get("Transfer-to Code");
                Validate("Direct Transfer Posting", Location."Direct Transfer Posting");
            end;
        end;
    end;

    local procedure ValidateDirectTransferPosting()
    begin
        case "Direct Transfer Posting" of
            "Direct Transfer Post. Type"::Empty,
            "Direct Transfer Post. Type"::"Receipt and Shipment":
                // TODO: This causes Quality Management tests to fail. Enable this after the initial checkin and investigate.    
                // if "Direct Transfer" then
                //     Validate("Direct Transfer", false);
                "Do Not Validate" := false; // TODO: Dummy asignment added as part of above todo
            "Direct Transfer Post. Type"::"Direct Transfer":
                if not "Direct Transfer" then begin
                    "Do Not Validate" := true;
                    Validate("Direct Transfer", true);
                    "Do Not Validate" := false;
                end;
        end;
        if "Direct Transfer Posting" <> "Direct Transfer Post. Type"::Empty then
            CheckDirectTransferPosting();
    end;
}
