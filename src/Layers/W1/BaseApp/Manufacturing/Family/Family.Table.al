// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Family;

using Microsoft.Manufacturing.Routing;

table 99000773 Family
{
    Caption = 'Family';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Family List";
    LookupPageID = "Family List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                "Search Name" := Description;
            end;
        }
        field(11; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(12; "Search Name"; Code[100])
        {
            Caption = 'Search Name';
        }
        field(13; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies that the family is blocked. This field is for information only and does not affect the posting in transactions.';
        }
        field(14; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(20; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            TableRelation = "Routing Header";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Name")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        FamilyLine: Record "Family Line";
    begin
        FamilyLine.SetRange("Family No.", "No.");
        FamilyLine.DeleteAll();
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;
}

