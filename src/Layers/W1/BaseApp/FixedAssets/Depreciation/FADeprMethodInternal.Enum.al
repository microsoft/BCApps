// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

enum 5611 "FA Depr. Method Internal"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Straight-Line") { Caption = 'Straight-Line'; }
    value(1; "Declining-Balance 1") { Caption = 'Declining-Balance 1'; }
    value(2; "Declining-Balance 2") { Caption = 'Declining-Balance 2'; }
    value(3; "DB1/SL") { Caption = 'DB1/SL'; }
    value(4; "DB2/SL") { Caption = 'DB2/SL'; }
    value(5; "User-Defined") { Caption = 'User-Defined'; }
    value(6; "Manual") { Caption = 'Manual'; }
    value(7; "Below Zero") { Caption = 'Below Zero'; }
    // Use with local enum FA Depr. Method CC, where CC is country/region code
    value(100; "Country Specific") { Caption = 'Country Specific'; }
}
