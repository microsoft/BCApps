// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

enum 5944 "Service Item Log Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Quote") { Caption = 'Quote'; }
    value(2; "Order") { Caption = 'Order'; }
    value(3; "Contract") { Caption = 'Contract'; }
}
