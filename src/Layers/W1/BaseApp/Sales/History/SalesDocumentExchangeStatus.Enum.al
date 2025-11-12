// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

enum 711 "Sales Document Exchange Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Not Sent") { Caption = 'Not Sent'; }
    value(1; "Sent to Document Exchange Service") { Caption = 'Sent to Document Exchange Service'; }
    value(2; "Delivered to Recipient") { Caption = 'Delivered to Recipient'; }
    value(3; "Delivery Failed") { Caption = 'Delivery Failed'; }
    value(4; "Pending Connection to Recipient") { Caption = 'Pending Connection to Recipient'; }
}
