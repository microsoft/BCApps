// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Enums;

enum 7118 "Analysis Column Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Formula)
    {
        Caption = 'Formula';
    }
    value(1; "Net Change")
    {
        Caption = 'Net Change';
    }
    value(2; "Balance at Date")
    {
        Caption = 'Balance at Date';
    }
    value(3; "Beginning Balance")
    {
        Caption = 'Beginning Balance';
    }
    value(4; "Year to Date")
    {
        Caption = 'Year to Date';
    }
    value(5; "Rest of Fiscal Year")
    {
        Caption = 'Rest of Fiscal Year';
    }
    value(6; "Entire Fiscal Year")
    {
        Caption = 'Entire Fiscal Year';
    }
}
