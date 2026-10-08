// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

enum 1670 "Option Lookup Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Sales") { Caption = 'Sales'; }
    value(1; "Purchases") { Caption = 'Purchases'; }
    value(2; "Permissions") { Caption = 'Permissions'; }
}
