// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Setup;

enum 306 "Report Selection Usage Sales"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Quote") { Caption = 'Quote'; }
    value(1; "Blanket Order") { Caption = 'Blanket Order'; }
    value(2; "Order") { Caption = 'Order'; }
    value(3; "Invoice") { Caption = 'Invoice'; }
    value(4; "Work Order") { Caption = 'Work Order'; }
    value(5; "Return Order") { Caption = 'Return Order'; }
    value(6; "Credit Memo") { Caption = 'Credit Memo'; }
    value(7; "Shipment") { Caption = 'Shipment'; }
    value(8; "Return Receipt") { Caption = 'Return Receipt'; }
    value(9; "Sales Document - Test") { Caption = 'Sales Document - Test'; }
    value(10; "Prepayment Document - Test") { Caption = 'Prepayment Document - Test'; }
    value(11; "Archived Quote") { Caption = 'Archived Quote'; }
    value(12; "Archived Order") { Caption = 'Archived Order'; }
    value(13; "Archived Return Order") { Caption = 'Archived Return Order'; }
    value(14; "Pick Instruction") { Caption = 'Pick Instruction'; }
    value(15; "Customer Statement") { Caption = 'Customer Statement'; }
    value(16; "Draft Invoice") { Caption = 'Draft Invoice'; }
    value(17; "Pro Forma Invoice") { Caption = 'Pro Forma Invoice'; }
    value(18; "Archived Blanket Order") { Caption = 'Archived Blanket Order'; }
    value(19; "Sales Order Picking List") { Caption = 'Sales Order Picking List'; }
}
