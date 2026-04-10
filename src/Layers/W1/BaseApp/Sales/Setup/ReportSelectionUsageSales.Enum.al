// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Setup;

/// <summary>
/// Defines the usage categories for sales report selections, covering all sales document types from quotes to archived orders and customer statements.
/// </summary>
enum 306 "Report Selection Usage Sales"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies the report selection usage for sales quote documents.
    /// </summary>
    value(0; "Quote") { Caption = 'Quote'; }
    /// <summary>
    /// Specifies the report selection usage for blanket sales order documents.
    /// </summary>
    value(1; "Blanket Order") { Caption = 'Blanket Order'; }
    /// <summary>
    /// Specifies the report selection usage for sales order documents.
    /// </summary>
    value(2; "Order") { Caption = 'Order'; }
    /// <summary>
    /// Specifies the report selection usage for sales invoice documents.
    /// </summary>
    value(3; "Invoice") { Caption = 'Invoice'; }
    /// <summary>
    /// Specifies the report selection usage for work order documents.
    /// </summary>
    value(4; "Work Order") { Caption = 'Work Order'; }
    /// <summary>
    /// Specifies the report selection usage for sales return order documents.
    /// </summary>
    value(5; "Return Order") { Caption = 'Return Order'; }
    /// <summary>
    /// Specifies the report selection usage for sales credit memo documents.
    /// </summary>
    value(6; "Credit Memo") { Caption = 'Credit Memo'; }
    /// <summary>
    /// Specifies the report selection usage for sales shipment documents.
    /// </summary>
    value(7; "Shipment") { Caption = 'Shipment'; }
    /// <summary>
    /// Specifies the report selection usage for sales return receipt documents.
    /// </summary>
    value(8; "Return Receipt") { Caption = 'Return Receipt'; }
    /// <summary>
    /// Specifies the report selection usage for sales document test reports.
    /// </summary>
    value(9; "Sales Document - Test") { Caption = 'Sales Document - Test'; }
    /// <summary>
    /// Specifies the report selection usage for prepayment document test reports.
    /// </summary>
    value(10; "Prepayment Document - Test") { Caption = 'Prepayment Document - Test'; }
    /// <summary>
    /// Specifies the report selection usage for archived sales quote documents.
    /// </summary>
    value(11; "Archived Quote") { Caption = 'Archived Quote'; }
    /// <summary>
    /// Specifies the report selection usage for archived sales order documents.
    /// </summary>
    value(12; "Archived Order") { Caption = 'Archived Order'; }
    /// <summary>
    /// Specifies the report selection usage for archived sales return order documents.
    /// </summary>
    value(13; "Archived Return Order") { Caption = 'Archived Return Order'; }
    /// <summary>
    /// Specifies the report selection usage for pick instruction documents.
    /// </summary>
    value(14; "Pick Instruction") { Caption = 'Pick Instruction'; }
    /// <summary>
    /// Specifies the report selection usage for customer statement documents.
    /// </summary>
    value(15; "Customer Statement") { Caption = 'Customer Statement'; }
    /// <summary>
    /// Specifies the report selection usage for draft sales invoice documents.
    /// </summary>
    value(16; "Draft Invoice") { Caption = 'Draft Invoice'; }
    /// <summary>
    /// Specifies the report selection usage for pro forma invoice documents.
    /// </summary>
    value(17; "Pro Forma Invoice") { Caption = 'Pro Forma Invoice'; }
    /// <summary>
    /// Specifies the report selection usage for archived blanket sales order documents.
    /// </summary>
    value(18; "Archived Blanket Order") { Caption = 'Archived Blanket Order'; }
}
