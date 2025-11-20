// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Partner;

enum 107 "IC Partner Reference Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "G/L Account") { Caption = 'G/L Account'; }
    value(2; "Item") { Caption = 'Item'; }
    value(5; "Charge (Item)") { Caption = 'Charge (Item)'; }
    value(6; "Cross Reference") { Caption = 'Cross Reference'; }
    value(7; "Common Item No.") { Caption = 'Common Item No.'; }
    value(8; "Vendor Item No.") { Caption = 'Vendor Item No.'; }
}
