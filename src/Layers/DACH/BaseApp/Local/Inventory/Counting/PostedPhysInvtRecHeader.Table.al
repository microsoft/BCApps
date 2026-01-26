#if not CLEANSCHEMA27 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting;

using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;

table 5005356 "Posted Phys. Invt. Rec. Header"
{
    Caption = 'Posted Phys. Invt. Rec. Header';
    ObsoleteReason = 'Merged to W1';
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(2; "Recording No."; Integer)
        {
            Caption = 'Recording No.';
            Editable = false;
        }
        field(10; Description; Text[50])
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
            CalcFormula = exist("Phys. Inventory Comment Line" where("Document Type" = const("Posted Recording"),
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
        field(40; "Recording without order permit"; Boolean)
        {
            Caption = 'Recording without order permit';
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
}

 
#endif