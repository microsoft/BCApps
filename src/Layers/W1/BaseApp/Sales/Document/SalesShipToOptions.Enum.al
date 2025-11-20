// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

enum 422 "Sales Ship-to Options"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Default (Sell-to Address)") { Caption = 'Default (Sell-to Address)'; }
    value(1; "Alternate Shipping Address") { Caption = 'Alternate Shipping Address'; }
    value(2; "Custom Address") { Caption = 'Custom Address'; }
}
