// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Enums;

enum 5444 "Quantity Calculation Formula"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Length") { Caption = 'Length'; }
    value(2; "Length * Width") { Caption = 'Length * Width'; }
    value(3; "Length * Width * Depth") { Caption = 'Length * Width * Depth'; }
    value(4; "Weight") { Caption = 'Weight'; }
    value(5; "Fixed Quantity") { Caption = 'Fixed Quantity'; }
}
