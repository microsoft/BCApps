// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

table 99000802 "Routing Tool"
{
    Caption = 'Routing Tool';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            NotBlank = true;
            TableRelation = "Routing Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(20; "Version Code"; Code[20])
        {
            Caption = 'Version Code';
            TableRelation = "Routing Version"."Version Code" where("Routing No." = field("Routing No."));
        }
        field(21; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            NotBlank = true;
            TableRelation = "Routing Line"."Operation No." where("Routing No." = field("Routing No."),
                                                                  "Version Code" = field("Version Code"));
        }
    }

    keys
    {
        key(Key1; "Routing No.", "Version Code", "Operation No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure Caption(): Text
    var
        RtngHeader: Record "Routing Header";
    begin
        if GetFilters = '' then
            exit('');

        if "Routing No." = '' then
            exit('');

        RtngHeader.Get("Routing No.");

        exit(
          StrSubstNo('%1 %2 %3',
            "Routing No.", RtngHeader.Description, "Operation No."));
    end;
}

