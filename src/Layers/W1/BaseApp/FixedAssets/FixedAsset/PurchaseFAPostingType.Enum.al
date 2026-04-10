// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Posting;

enum 5607 "Purchase FA Posting Type"
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
    value(2; Maintenance)
    {
        Caption = 'Maintenance';
    }
    value(4; Appreciation)
    {
        Caption = 'Appreciation';
    }
}
