// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

enum 39 "Purchase Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "G/L Account") { Caption = 'G/L Account'; }
    value(2; "Item") { Caption = 'Item'; }
    value(3; "Resource") { Caption = 'Resource'; }
    value(4; "Fixed Asset") { Caption = 'Fixed Asset'; }
    value(5; "Charge (Item)") { Caption = 'Charge (Item)'; }
    value(10; "Allocation Account") { Caption = 'Allocation Account'; }
}
