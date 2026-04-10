// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Enums;

enum 7131 "Analysis Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Customer") { Caption = 'Customer'; }
    value(2; "Vendor") { Caption = 'Vendor'; }
    value(3; "Item") { Caption = 'Item'; }
}
