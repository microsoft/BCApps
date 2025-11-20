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
            TableRelation = "Fault Code".Code where("Fault Area Code" = field("Fault Area Code"),
                                                     "Symptom Code" = field("Symptom Code"));
        }
        field(2; "Symptom Code"; Code[10])
        {
            Caption = 'Symptom Code';
            TableRelation = "Symptom Code";
        }
        field(3; "Fault Area Code"; Code[10])
        {
            Caption = 'Fault Area Code';
            TableRelation = "Fault Area";
        }
        field(4; "Resolution Code"; Code[10])
        {
            Caption = 'Resolution Code';
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
            Editable = false;
        }
        field(6; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(7; "Service Item Group Code"; Code[10])
        {
            Caption = 'Service Item Group Code';
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

