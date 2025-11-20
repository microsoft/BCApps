// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

#pragma warning disable AL0659
enum 5602 "FA Journal Line FA Posting Type"
#pragma warning restore AL0659
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
    value(6; Disposal)
    {
        Caption = 'Disposal';
    }
    value(7; Maintenance)
    {
        Caption = 'Maintenance';
    }
    value(8; "Salvage Value")
    {
        Caption = 'Salvage Value';
    }
}
