// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

enum 99000802 "Capacity Unit of Measure"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = 'Milliseconds'; }
    value(1; "100/Hour") { Caption = '100/Hour'; }
    value(2; "Minutes") { Caption = 'Minutes'; }
    value(3; "Hours") { Caption = 'Hours'; }
    value(4; "Days") { Caption = 'Days'; }
    value(5; "Seconds") { Caption = 'Seconds'; }
}
