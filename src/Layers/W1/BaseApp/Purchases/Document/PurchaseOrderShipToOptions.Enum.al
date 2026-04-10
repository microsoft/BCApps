// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

enum 423 "Purchase Order Ship-to Options"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Default (Company Address)") { Caption = 'Default (Company Address)'; }
    value(1; "Location") { Caption = 'Location'; }
    value(2; "Customer Address") { Caption = 'Customer Address'; }
    value(3; "Custom Address") { Caption = 'Custom Address'; }
}
