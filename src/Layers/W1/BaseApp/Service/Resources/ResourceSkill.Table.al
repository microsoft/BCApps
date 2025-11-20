// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Resources;

using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Item;
using Microsoft.Service.Setup;

table 5956 "Resource Skill"
{
    Caption = 'Resource Skill';
    LookupPageID = "Resource Skills";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Enum "Resource Skill Type")
        {
            Caption = 'Type';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = if (Type = const(Resource)) Resource."No."
            else
            if (Type = const("Service Item Group")) "Service Item Group".Code
            else
            if (Type = const(Item)) Item."No."
            else
            if (Type = const("Service Item")) "Service Item"."No.";
        }
        field(3; "Skill Code"; Code[10])
        {
            Caption = 'Skill Code';
            NotBlank = true;
            TableRelation = "Skill Code";

            trigger OnValidate()
            var
                ResSkill: Record "Resource Skill";
                ResSkillMgt: Codeunit "Resource Skill Mgt.";
            begin
                if ("Skill Code" <> xRec."Skill Code") and
                   (xRec."Skill Code" <> '') and
                   (not ResSkill.Get(Type, "No.", "Skill Code"))
                then
                    if not ResSkillMgt.ChangeResSkill(Rec, xRec."Skill Code") then
                        Error('');
            end;
        }
        field(4; "Assigned From"; Enum "Resource Skill Assigned From")
        {
            Caption = 'Assigned From';
        }
        field(5; "Source Type"; Enum "Resource Skill Source Type")
        {
            Caption = 'Source Type';
        }
        field(6; "Source Code"; Code[20])
        {
            Caption = 'Source Code';
        }
    }

    keys
    {
        key(Key1; Type, "No.", "Skill Code")
        {
            Clustered = true;
        }
        key(Key2; "Skill Code", Type, "No.")
        {
        }
        key(Key3; "Assigned From")
        {
        }
        key(Key4; "Source Type", "Source Code")
        {
        }
        key(Key5; "Assigned From", "Source Type", "Source Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        ResSkillMgt: Codeunit "Resource Skill Mgt.";
    begin
        ResSkillMgt.AddResSkill(Rec);
    end;
}

