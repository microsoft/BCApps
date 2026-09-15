// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

enum 5606 "FA Posting Group Account Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Acquisition Cost")
    {
        Caption = 'Acquisition Cost';
    }
    value(1; Depreciation)
    {
        Caption = 'Depreciation';
    }
    value(2; "Write-Down")
    {
        Caption = 'Write-Down';
    }
    value(3; Appreciation)
    {
        Caption = 'Appreciation';
    }
    value(4; "Custom 1")
    {
        Caption = 'Custom 1';
    }
    value(5; "Custom 2")
    {
        Caption = 'Custom 2';
    }
    value(6; "Proceeds on Disposal")
    {
        Caption = 'Proceeds on Disposal';
    }
    value(7; "Maintenance")
    {
        Caption = 'Maintenance';
    }
    value(8; "Gain")
    {
        Caption = 'Gain/Loss';
    }
    value(9; "Loss")
    {
        Caption = 'Gain/Loss';
    }
    value(10; "Book Value Gain")
    {
        Caption = 'Book Value Gain';
    }
    value(11; "Book Value Loss")
    {
        Caption = 'Book Value Loss';
    }
}
