// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Team;

table 5084 "Team Salesperson"
{
    Caption = 'Team Salesperson';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Team Code"; Code[10])
        {
            Caption = 'Team Code';
            NotBlank = true;
            TableRelation = Team;
        }
        field(2; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            NotBlank = true;
            TableRelation = "Salesperson/Purchaser";
        }
        field(3; "Team Name"; Text[50])
        {
            CalcFormula = lookup(Team.Name where(Code = field("Team Code")));
            Caption = 'Team Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Salesperson Name"; Text[50])
        {
            CalcFormula = lookup("Salesperson/Purchaser".Name where(Code = field("Salesperson Code")));
            Caption = 'Salesperson Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Team Code", "Salesperson Code")
        {
            Clustered = true;
        }
        key(Key2; "Salesperson Code")
        {
        }
    }

    fieldgroups
    {
    }
}

