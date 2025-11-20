// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using System.Reflection;

table 5099 "Saved Segment Criteria Line"
{
    Caption = 'Saved Segment Criteria Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Segment Criteria Code"; Code[10])
        {
            Caption = 'Segment Criteria Code';
            TableRelation = "Saved Segment Criteria";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Action,Filter';
            OptionMembers = "Action","Filter";
        }
        field(4; "Action"; Enum "Segment Criteria Line Action")
        {
            Caption = 'Action';
        }
        field(5; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(6; "Table View"; Text[2048])
        {
            Caption = 'Table View';
        }
#if not CLEANSCHEMA25
        field(7; View; Text[250])
        {
            Caption = 'View';
            ObsoleteReason = 'Replaced by field "Table View": Text[2048]';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(8; "Allow Existing Contacts"; Boolean)
        {
            Caption = 'Allow Existing Contacts';
        }
        field(9; "Expand Contact"; Boolean)
        {
            Caption = 'Expand Contact';
        }
        field(10; "Allow Company with Persons"; Boolean)
        {
            Caption = 'Allow Company with Persons';
        }
        field(11; "Ignore Exclusion"; Boolean)
        {
            Caption = 'Ignore Exclusion';
        }
        field(12; "Entire Companies"; Boolean)
        {
            Caption = 'Entire Companies';
        }
        field(13; "Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table No.")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "No. of Filters"; Integer)
        {
            Caption = 'No. of Filters';
        }
    }

    keys
    {
        key(Key1; "Segment Criteria Code", "Line No.", "Action")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure ActionTable(): Text[250]
    begin
        case Type of
            Type::Action:
                exit(Format(Action));
            Type::Filter:
                begin
                    CalcFields("Table Caption");
                    exit("Table Caption");
                end;
        end;
    end;
}

