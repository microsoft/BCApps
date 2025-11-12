// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Recording;

using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Counting.Comment;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;
using System.Security.AccessControl;

table 5877 "Phys. Invt. Record Header"
{
    Caption = 'Phys. Invt. Record Header';
    DataCaptionFields = "Order No.", "Recording No.", Description;
    DrillDownPageID = "Phys. Inventory Recording List";
    LookupPageID = "Phys. Inventory Recording List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            TableRelation = "Phys. Invt. Order Header";

            trigger OnValidate()
            begin
                if (xRec."Order No." <> '') and ("Order No." <> xRec."Order No.") then
                    Error(CannotChangeErr, FieldCaption("Order No."));
            end;
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
            CalcFormula = exist("Phys. Invt. Comment Line" where("Document Type" = const(Recording),
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
        field(103; "Recorded by User ID"; Code[50])
        {
            Caption = 'Created by User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
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

            trigger OnValidate()
            begin
                if "Bin Code" <> '' then begin
                    TestField("Location Code");
                    Location.Get("Location Code");
                    Location.TestField("Bin Mandatory", true);
                    Location.TestField("Directed Put-away and Pick", false);
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Order No.", "Recording No.")
        {
            Clustered = true;
        }
        key(Key2; Status)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Order No.", "Recording No.", Description)
        {
        }
    }

    trigger OnDelete()
    begin
        TestField(Status, Status::Open);

        PhysInvtRecordLine.Reset();
        PhysInvtRecordLine.SetRange("Order No.", "Order No.");
        PhysInvtRecordLine.SetRange("Recording No.", "Recording No.");
        PhysInvtRecordLine.DeleteAll(true);

        PhysInvtCommentLine.Reset();
        PhysInvtCommentLine.SetRange("Document Type", PhysInvtCommentLine."Document Type"::Recording);
        PhysInvtCommentLine.SetRange("Order No.", "Order No.");
        PhysInvtCommentLine.SetRange("Recording No.", "Recording No.");
        PhysInvtCommentLine.DeleteAll();
    end;

    trigger OnInsert()
    begin
        TestField("Order No.");
        PhysInvtOrderHeader.Get("Order No.");
        PhysInvtOrderHeader.TestField(Status, PhysInvtOrderHeader.Status::Open);

        if "Recording No." = 0 then begin
            LockTable();
            PhysInvtRecordHeader.Reset();
            PhysInvtRecordHeader.SetRange("Order No.", "Order No.");
            if PhysInvtRecordHeader.FindLast() then
                "Recording No." := PhysInvtRecordHeader."Recording No." + 1
            else
                "Recording No." := 1;
        end;

        "Recorded by User ID" := CopyStr(UserId(), 1, 50);
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
        CannotRenameErr: Label 'You cannot rename a %1.', Comment = '%1 = Table caption';
        CannotChangeErr: Label 'You cannot change the %1.', Comment = '%1 = Field caption';
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtCommentLine: Record "Phys. Invt. Comment Line";
        Location: Record Location;
}

