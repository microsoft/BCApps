// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

#pragma warning disable AL0659
enum 5603 "Gen. Journal Line FA Posting Type"
#pragma warning restore AL0659
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
    value(7; Disposal)
    {
        Caption = 'Disposal';
    }
    value(8; Maintenance)
    {
        Caption = 'Maintenance';
    }
}
