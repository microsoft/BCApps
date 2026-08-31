// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Routing;

table 20572 "Subc. Standard Task Comment"
{
    Caption = 'Subcontracting Standard Task Comment';
    DrillDownPageID = "Subc. Standard Task Comments";
    LookupPageID = "Subc. Standard Task Comments";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Standard Task Code"; Code[10])
        {
            Caption = 'Standard Task Code';
            Editable = false;
            NotBlank = true;
            TableRelation = "Standard Task";
            ToolTip = 'Specifies the standard task code for the subcontracting comment.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
            ToolTip = 'Specifies the line number of the subcontracting comment.';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the subcontracting comment.';
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies the description 2 of the subcontracting comment.';
        }
    }

    keys
    {
        key(PK; "Standard Task Code", "Line No.")
        {
            Clustered = true;
        }
    }
}