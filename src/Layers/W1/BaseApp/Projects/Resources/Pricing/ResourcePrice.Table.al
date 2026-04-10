// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Pricing;

using Microsoft.Finance.Currency;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Utilities;

table 201 "Resource Price"
{
    Caption = 'Resource Price';
    DrillDownPageID = "Resource Prices";
    LookupPageID = "Resource Prices";
    DataClassification = CustomerContent;

    fields
    {
        field(2; Type; Option)
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type.';
            OptionCaption = 'Resource,Group(Resource),All';
            OptionMembers = Resource,"Group(Resource)",All;
        }
        field(3; "Code"; Code[20])
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
        field(4; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
            TableRelation = "Work Type";
        }
        field(5; "Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
            ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
        }
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code of the alternate sales price on this line.';
            TableRelation = Currency;
        }
    }

    keys
    {
        key(Key1; Type, "Code", "Work Type Code", "Currency Code")
        {
            Clustered = true;
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
