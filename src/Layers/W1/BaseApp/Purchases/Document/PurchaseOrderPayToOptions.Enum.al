// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

enum 424 "Purchase Order Pay-to Options"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Default (Vendor)") { Caption = 'Default (Vendor)'; }
    value(1; "Another Vendor") { Caption = 'Another Vendor'; }
    value(2; "Custom Address") { Caption = 'Custom Address'; }
}
