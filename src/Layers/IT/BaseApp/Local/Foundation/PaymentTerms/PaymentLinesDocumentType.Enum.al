// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

enum 12170 "Payment Lines Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Quote") { Caption = 'Quote'; }
    value(1; "Order") { Caption = 'Order'; }
    value(2; "Invoice") { Caption = 'Invoice'; }
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    value(4; "Payment Terms") { Caption = 'Payment Terms'; }
    value(5; "General Journal") { Caption = 'General Journal'; }
    value(6; "Sales Journal") { Caption = 'Sales Journal'; }
    value(7; "Purchase Journal") { Caption = 'Purchase Journal'; }
    value(8; "Blanket Order") { Caption = 'Blanket Order'; }
}
