// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

enum 5902 "Service Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { }
    value(1; "Item") { Caption = 'Item'; }
    value(2; "Resource") { Caption = 'Resource'; }
    value(3; "Cost") { Caption = 'Cost'; }
    value(4; "G/L Account") { Caption = 'G/L Account'; }
}
