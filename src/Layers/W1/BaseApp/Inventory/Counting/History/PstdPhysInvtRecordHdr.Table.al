// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.History;

using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Counting.Comment;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;

table 5881 "Pstd. Phys. Invt. Record Hdr"
{
    Caption = 'Pstd. Phys. Invt. Record Hdr';
    DrillDownPageID = "Posted Phys. Invt. Rec. List";
    LookupPageID = "Posted Phys. Invt. Rec. List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            TableRelation = "Phys. Invt. Order Header";
        }
        field(2; "Recording No."; Integer)
        {
            Caption = 'Recording No.';
            Editable = false;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Finished';
            OptionMembers = Open,Finished;
        }
        field(30; Comment; Boolean)
        {
            CalcFormula = exist("Phys. Invt. Comment Line" where("Document Type" = const("Posted Recording"),
                                                                  "Order No." = field("Order No."),
                                                                  "Recording No." = field("Recording No.")));
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
        field(40; "Allow Recording Without Order"; Boolean)
        {
            Caption = 'Allow Recording Without Order';
        }
        field(100; "Date Recorded"; Date)
        {
            Caption = 'Date Recorded';
        }
        field(101; "Time Recorded"; Time)
        {
            Caption = 'Time Recorded';
        }
        field(102; "Person Recorded"; Code[20])
        {
            Caption = 'Person Recorded';
            TableRelation = Employee;
            ValidateTableRelation = false;
        }
        field(110; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(111; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
    }

    keys
    {
        key(Key1; "Order No.", "Recording No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        PstdPhysInvtRecordLine: Record "Pstd. Phys. Invt. Record Line";
        PhysInvtCommentLine: Record "Phys. Invt. Comment Line";
    begin
        LockTable();

        PstdPhysInvtRecordLine.Reset();
        PstdPhysInvtRecordLine.SetRange("Order No.", "Order No.");
        PstdPhysInvtRecordLine.SetRange("Recording No.", "Recording No.");
        PstdPhysInvtRecordLine.DeleteAll(true);

        PhysInvtCommentLine.Reset();
        PhysInvtCommentLine.SetRange("Document Type", PhysInvtCommentLine."Document Type"::"Posted Recording");
        PhysInvtCommentLine.SetRange("Order No.", "Order No.");
        PhysInvtCommentLine.SetRange("Recording No.", "Recording No.");
        PhysInvtCommentLine.DeleteAll();
    end;
}

