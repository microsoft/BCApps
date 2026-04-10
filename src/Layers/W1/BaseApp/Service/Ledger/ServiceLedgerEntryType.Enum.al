// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Ledger;

enum 5907 "Service Ledger Entry Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { }
    value(1; "Resource") { Caption = 'Resource'; }
    value(2; "Item") { Caption = 'Item'; }
    value(3; "Service Cost") { Caption = 'Service Cost'; }
    value(4; "Service Contract") { Caption = 'Service Contract'; }
    value(5; "G/L Account") { Caption = 'G/L Account'; }
}
