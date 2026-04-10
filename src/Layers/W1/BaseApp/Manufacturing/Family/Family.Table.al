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
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            NotBlank = true;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description for a product family.';

            trigger OnValidate()
            begin
                "Search Name" := Description;
            end;
        }
        field(11; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies an additional description of the product family if there is not enough space in the Description field.';
        }
        field(12; "Search Name"; Code[100])
        {
            Caption = 'Search Name';
            ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
        }
        field(13; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies that the family is blocked. This field is for information only and does not affect the posting in transactions.';
        }
        field(14; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            ToolTip = 'Specifies when the standard data of this production family was last modified.';
            Editable = false;
        }
        field(20; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            ToolTip = 'Specifies the number of the routing which is used for the production of the family.';
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

