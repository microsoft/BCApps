// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

using Microsoft.Service.Item;

table 5920 "Fault/Resol. Cod. Relationship"
{
    Caption = 'Fault/Resol. Cod. Relationship';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Fault Code"; Code[10])
        {
            Caption = 'Fault Code';
            ToolTip = 'Specifies the fault code.';
            TableRelation = "Fault Code".Code where("Fault Area Code" = field("Fault Area Code"),
                                                     "Symptom Code" = field("Symptom Code"));
        }
        field(2; "Symptom Code"; Code[10])
        {
            Caption = 'Symptom Code';
            ToolTip = 'Specifies the symptom code.';
            TableRelation = "Symptom Code";
        }
        field(3; "Fault Area Code"; Code[10])
        {
            Caption = 'Fault Area Code';
            ToolTip = 'Specifies the fault area code.';
            TableRelation = "Fault Area";
        }
        field(4; "Resolution Code"; Code[10])
        {
            Caption = 'Resolution Code';
            ToolTip = 'Specifies the resolution code.';
            TableRelation = "Resolution Code";

            trigger OnValidate()
            begin
                if "Resolution Code" <> '' then begin
                    ResolutionCode.Get("Resolution Code");
                    Description := ResolutionCode.Description;
                end else
                    Description := '';
            end;
        }
        field(5; Occurrences; Integer)
        {
            Caption = 'Occurrences';
            ToolTip = 'Specifies the number of times the combination of fault code, symptom code, fault area, and resolution code occurs in the posted service lines.';
            Editable = false;
        }
        field(6; Description; Text[80])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the relationship between the fault code and the resolution code.';
        }
        field(7; "Service Item Group Code"; Code[10])
        {
            Caption = 'Service Item Group Code';
            ToolTip = 'Specifies the code of the service item group linked to the relationship.';
            TableRelation = "Service Item Group";
        }
        field(8; "Created Manually"; Boolean)
        {
            Caption = 'Created Manually';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Fault Code", "Fault Area Code", "Symptom Code", "Resolution Code", "Service Item Group Code")
        {
            Clustered = true;
        }
        key(Key2; "Fault Code", Occurrences)
        {
        }
        key(Key3; "Fault Area Code", Occurrences)
        {
        }
        key(Key4; "Symptom Code", Occurrences)
        {
        }
        key(Key5; "Service Item Group Code", "Fault Code", Occurrences)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "Created Manually" := true;
    end;

    trigger OnModify()
    begin
        "Created Manually" := true;
    end;

    var
        ResolutionCode: Record "Resolution Code";
}

