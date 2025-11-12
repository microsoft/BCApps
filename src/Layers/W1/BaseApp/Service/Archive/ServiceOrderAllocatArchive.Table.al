// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Item;
using Microsoft.Service.Document;

table 6014 "Service Order Allocat. Archive"
{
    Caption = 'Service Order Allocation Archive';
    DrillDownPageID = "Service Order Allocat. Archive";
    LookupPageID = "Service Order Allocat. Archive";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Nonactive,Active,Finished,Canceled,Reallocation Needed';
            OptionMembers = Nonactive,Active,Finished,Canceled,"Reallocation Needed";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Allocation Date"; Date)
        {
            Caption = 'Allocation Date';
        }
        field(5; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource;
        }
        field(6; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            TableRelation = "Resource Group";
        }
        field(7; "Service Item Line No."; Integer)
        {
            Caption = 'Service Item Line No.';
            TableRelation = "Service Item Line Archive"."Line No." where("Document Type" = field("Document Type"),
                                                                         "Document No." = field("Document No."),
                                                                         "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                         "Version No." = field("Version No."));
        }
        field(8; "Allocated Hours"; Decimal)
        {
            Caption = 'Allocated Hours';
            DecimalPlaces = 0 : 5;
        }
        field(9; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
        }
        field(10; "Finishing Time"; Time)
        {
            Caption = 'Finishing Time';
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(13; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            TableRelation = "Service Item"."No.";
        }
        field(14; Posted; Boolean)
        {
            Caption = 'Posted';
        }
        field(16; "Service Item Serial No."; Code[50])
        {
            Caption = 'Service Item Serial No.';
        }
        field(18; "Service Started"; Boolean)
        {
            Caption = 'Service Started';
        }
        field(19; "Document Type"; Enum "Service Document Type")
        {
            Caption = 'Document Type';
        }
        field(5047; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        field(5048; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Doc. No. Occurrence", "Version No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Document No.", "Doc. No. Occurrence", "Version No.", "Allocation Date", "Resource No.", Status, "Resource Group No.")
        {
            SumIndexFields = "Allocated Hours";
        }
    }
}