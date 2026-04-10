// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Posting;

enum 5604 "Reversal Entry FA Posting Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; "Acquisition Cost")
    {
        Caption = 'Acquisition Cost';
    }
    value(2; Depreciation)
    {
        Caption = 'Depreciation';
    }
    value(3; "Write-Down")
    {
        Caption = 'Write-Down';
    }
    value(4; Appreciation)
    {
        Caption = 'Appreciation';
    }
    value(5; "Custom 1")
    {
        Caption = 'Custom 1';
    }
    value(6; "Custom 2")
    {
        Caption = 'Custom 2';
    }
    value(7; "Proceeds on Disposal")
    {
        Caption = 'Proceeds on Disposal';
    }
    value(8; "Salvage Value")
    {
        Caption = 'Salvage Value';
    }
    value(9; "Gain/Loss")
    {
        Caption = 'Gain/Loss';
    }
    value(10; "Book Value on Disposal")
    {
        Caption = 'Book Value on Disposal';
    }
}
