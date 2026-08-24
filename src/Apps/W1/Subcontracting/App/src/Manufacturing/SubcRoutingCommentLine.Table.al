// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Routing;

table 20573 "Subc. Routing Comment Line"
{
    Caption = 'Subcontracting Routing Comment Line';
    DrillDownPageID = "Subc. Routing Comments";
    LookupPageID = "Subc. Routing Comments";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            Editable = false;
            NotBlank = true;
            TableRelation = "Routing Header";
            ToolTip = 'Specifies the routing number for the subcontracting comment.';
        }
        field(2; "Version Code"; Code[20])
        {
            Caption = 'Version Code';
            Editable = false;
            TableRelation = "Routing Version"."Version Code" where("Routing No." = field("Routing No."));
            ToolTip = 'Specifies the version code for the subcontracting comment.';
        }
        field(3; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            Editable = false;
            NotBlank = true;
            TableRelation = "Routing Line"."Operation No." where("Routing No." = field("Routing No."),
                                                                  "Version Code" = field("Version Code"));
            ToolTip = 'Specifies the operation number for the subcontracting comment.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
            ToolTip = 'Specifies the line number of the subcontracting comment.';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the subcontracting comment.';
        }
        field(6; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies the description 2 of the subcontracting comment.';
        }
    }

    keys
    {
        key(PK; "Routing No.", "Version Code", "Operation No.", "Line No.")
        {
            Clustered = true;
        }
    }
}