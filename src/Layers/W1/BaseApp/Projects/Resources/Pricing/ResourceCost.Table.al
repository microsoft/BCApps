// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Pricing;

using Microsoft.Projects.Resources.Resource;
using Microsoft.Utilities;

table 202 "Resource Cost"
{
    Caption = 'Resource Cost';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type.';
            OptionCaption = 'Resource,Group(Resource),All';
            OptionMembers = Resource,"Group(Resource)",All;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code.';
            TableRelation = if (Type = const(Resource)) Resource
            else
            if (Type = const("Group(Resource)")) "Resource Group";

            trigger OnValidate()
            begin
                if (Code <> '') and (Type = Type::All) then
                    FieldError(Code, StrSubstNo(Text000, FieldCaption(Type), Format(Type)));
            end;
        }
        field(3; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            ToolTip = 'Specifies the code for the type of work. You can also assign a unit price to a work type.';
            TableRelation = "Work Type";
        }
        field(4; "Cost Type"; Option)
        {
            Caption = 'Cost Type';
            ToolTip = 'Specifies the type of cost.';
            OptionCaption = 'Fixed,% Extra,LCY Extra';
            OptionMembers = "Fixed","% Extra","LCY Extra";

            trigger OnValidate()
            begin
                if "Work Type Code" = '' then
                    TestField("Cost Type", "Cost Type"::Fixed);
            end;
        }
        field(5; "Direct Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Direct Unit Cost';
            ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
        }
        field(6; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Cost';
            ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
        }
    }

    keys
    {
        key(Key1; Type, "Code", "Work Type Code")
        {
            Clustered = true;
        }
        key(Key2; "Cost Type", "Code", "Work Type Code")
        {
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'cannot be specified when %1 is %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
}
