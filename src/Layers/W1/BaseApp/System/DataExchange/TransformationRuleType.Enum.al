// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;

enum 1237 "Transformation Rule Type" implements "Transformation Rule"
{
    Extensible = true;
    AssignmentCompatibility = true;
    DefaultImplementation = "Transformation Rule" = "Transform. Rule - Custom";

    value(0; "Uppercase")
    {
        Caption = 'Uppercase';
        Implementation = "Transformation Rule" = "Transform. Rule - Basic";
    }
    value(1; "Lowercase")
    {
        Caption = 'Lowercase';
        Implementation = "Transformation Rule" = "Transform. Rule - Basic";
    }
    value(2; "Title Case")
    {
        Caption = 'Title Case';
        Implementation = "Transformation Rule" = "Transform. Rule - Formatting";
    }
    value(3; "Trim")
    {
        Caption = 'Trim';
        Implementation = "Transformation Rule" = "Transform. Rule - Basic";
    }
    value(4; "Substring")
    {
        Caption = 'Substring';
        Implementation = "Transformation Rule" = "Transform. Rule - Substring";
    }
    value(5; "Replace")
    {
        Caption = 'Replace Text';
        Implementation = "Transformation Rule" = "Transform. Rule - Replace";
    }
    value(6; "Regular Expression - Replace")
    {
        Caption = 'Replace by using Regular Expressions';
        Implementation = "Transformation Rule" = "Transform. Rule - Replace";
    }
    value(7; "Remove Non-Alphanumeric Characters")
    {
        Caption = 'Remove Non-Alphanumeric Characters';
        Implementation = "Transformation Rule" = "Transform. Rule - Basic";
    }
    value(8; "Date Formatting")
    {
        Caption = 'Date Formatting';
        Implementation = "Transformation Rule" = "Transform. Rule - Formatting";
    }
    value(9; "Decimal Formatting")
    {
        Caption = 'Decimal Formatting';
        Implementation = "Transformation Rule" = "Transform. Rule - Formatting";
    }
    value(10; "Regular Expression - Match")
    {
        Caption = 'Match by using Regular Expressions';
        Implementation = "Transformation Rule" = "Transform. Rule - Match";
    }
    value(11; "Custom")
    {
        Caption = 'Custom';
        Implementation = "Transformation Rule" = "Transform. Rule - Custom";
    }
    value(12; "Date and Time Formatting")
    {
        Caption = 'Date and Time Formatting';
        Implementation = "Transformation Rule" = "Transform. Rule - Formatting";
    }
    value(13; "Field Lookup")
    {
        Caption = 'Field Lookup';
        Implementation = "Transformation Rule" = "Transform. Rule - Field Lookup";
    }
    value(14; "Round")
    {
        Caption = 'Round';
        Implementation = "Transformation Rule" = "Transform. Rule - Round";
    }
    value(15; "Extract From Date")
    {
        Caption = 'Extract From Date';
        Implementation = "Transformation Rule" = "Transform. Rule - Ex. Fr. Date";
    }
    value(16; "Unixtimestamp")
    {
        Caption = 'Unixtimestamp';
        Implementation = "Transformation Rule" = "Transform. Rule - Basic";
    }
}