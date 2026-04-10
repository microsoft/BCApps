// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

/// <summary>
/// Stores individual tax jurisdiction assignments within tax areas.
/// Defines the calculation sequence and jurisdiction relationships for multi-tier tax scenarios.
/// </summary>
table 319 "Tax Area Line"
{
    Caption = 'Tax Area Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Tax area code that contains this jurisdiction line.
        /// </summary>
        field(1; "Tax Area"; Code[20])
        {
            Caption = 'Tax Area';
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Unique identifier for the tax jurisdiction within this area.
        /// </summary>
        field(2; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            ToolTip = 'Specifies a tax jurisdiction code.';
            NotBlank = true;
            TableRelation = "Tax Jurisdiction";
        }
        /// <summary>
        /// Descriptive name of the tax jurisdiction retrieved from Tax Jurisdiction table.
        /// </summary>
        field(3; "Jurisdiction Description"; Text[100])
        {
            CalcFormula = lookup("Tax Jurisdiction".Description where(Code = field("Tax Jurisdiction Code")));
            Caption = 'Jurisdiction Description';
            ToolTip = 'Specifies the description from the tax jurisdiction table when you enter the tax jurisdiction code.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Sequence order for tax calculation when multiple jurisdictions apply.
        /// Lower numbers are calculated first for tax-on-tax scenarios.
        /// </summary>
        field(4; "Calculation Order"; Integer)
        {
            Caption = 'Calculation Order';
            ToolTip = 'Specifies an integer to determine the sequence the program must use when tax is calculated.';
        }
    }

    keys
    {
        key(Key1; "Tax Area", "Tax Jurisdiction Code")
        {
            Clustered = true;
        }
        key(Key2; "Tax Jurisdiction Code")
        {
        }
        key(Key3; "Tax Area", "Calculation Order")
        {
        }
    }

    fieldgroups
    {
    }
}

