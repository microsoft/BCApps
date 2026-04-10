// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.ExtendedText;

enum 279 "Extended Text Table Name"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Standard Text") { Caption = 'Standard Text'; }
    value(1; "G/L Account") { Caption = 'G/L Account'; }
    value(2; Item) { Caption = 'Item'; }
    value(3; Resource) { Caption = 'Resource'; }
    value(4; "VAT Clause") { Caption = 'VAT Clause'; }
}
