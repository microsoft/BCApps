// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

enum 454 "Approval Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Quote") { Caption = 'Quote'; }
    value(1; "Order") { Caption = 'Order'; }
    value(2; "Invoice") { Caption = 'Invoice'; }
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    value(4; "Blanket Order") { Caption = 'Blanket Order'; }
    value(5; "Return Order") { Caption = 'Return Order'; }
    value(6; " ") { Caption = ' '; }
    value(7; "Payment") { Caption = 'Payment'; }
}
