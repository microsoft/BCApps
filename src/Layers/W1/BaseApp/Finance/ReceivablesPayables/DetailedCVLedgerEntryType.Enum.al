// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

/// <summary>
/// Defines entry types for detailed customer and vendor ledger entries tracking transaction components.
/// Categorizes different aspects of customer/vendor transactions including applications, adjustments, and tolerances.
/// </summary>
/// <remarks>
/// Used by detailed ledger entry systems to classify transaction elements and their impact.
/// Supports currency adjustments, payment processing, VAT handling, and application tracking.
/// Critical for audit trails and detailed transaction analysis in receivables/payables modules.
/// </remarks>
enum 379 "Detailed CV Ledger Entry Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Empty entry type for unclassified or default transactions.
    /// </summary>
    value(0; "") { Caption = ''; }
    /// <summary>
    /// Initial posting entry representing the original transaction amount.
    /// </summary>
    value(1; "Initial Entry") { Caption = 'Initial Entry'; }
    /// <summary>
    /// Application entry created when payments are applied to invoices.
    /// </summary>
    value(2; "Application") { Caption = 'Application'; }
    /// <summary>
    /// Unrealized currency exchange loss adjustment entry.
    /// </summary>
    value(3; "Unrealized Loss") { Caption = 'Unrealized Loss'; }
    /// <summary>
    /// Unrealized currency exchange gain adjustment entry.
    /// </summary>
    value(4; "Unrealized Gain") { Caption = 'Unrealized Gain'; }
    /// <summary>
    /// Realized currency exchange loss when transactions are settled.
    /// </summary>
    value(5; "Realized Loss") { Caption = 'Realized Loss'; }
    /// <summary>
    /// Realized currency exchange gain when transactions are settled.
    /// </summary>
    value(6; "Realized Gain") { Caption = 'Realized Gain'; }
    /// <summary>
    /// Payment discount amount taken by customer or granted to vendor.
    /// </summary>
    value(7; "Payment Discount") { Caption = 'Payment Discount'; }
    /// <summary>
    /// Payment discount amount excluding VAT for tax calculation purposes.
    /// </summary>
    value(8; "Payment Discount (VAT Excl.)") { Caption = 'Payment Discount (VAT Excl.)'; }
    /// <summary>
    /// VAT adjustment entry related to payment discount processing.
    /// </summary>
    value(9; "Payment Discount (VAT Adjustment)") { Caption = 'Payment Discount (VAT Adjustment)'; }
    /// <summary>
    /// Rounding adjustment created during application of payments to invoices.
    /// </summary>
    value(10; "Appln. Rounding") { Caption = 'Appln. Rounding'; }
    /// <summary>
    /// Correction entry to adjust remaining amounts on ledger entries.
    /// </summary>
    value(11; "Correction of Remaining Amount") { Caption = 'Correction of Remaining Amount'; }
    /// <summary>
    /// Payment tolerance amount accepted within configured tolerance limits.
    /// </summary>
    value(12; "Payment Tolerance") { Caption = 'Payment Tolerance'; }
    /// <summary>
    /// Payment discount tolerance amount for late payment discount acceptance.
    /// </summary>
    value(13; "Payment Discount Tolerance") { Caption = 'Payment Discount Tolerance'; }
    /// <summary>
    /// Payment tolerance amount excluding VAT for proper tax handling.
    /// </summary>
    value(14; "Payment Tolerance (VAT Excl.)") { Caption = 'Payment Tolerance (VAT Excl.)'; }
    /// <summary>
    /// VAT adjustment entry related to payment tolerance processing.
    /// </summary>
    value(15; "Payment Tolerance (VAT Adjustment)") { Caption = 'Payment Tolerance (VAT Adjustment)'; }
    /// <summary>
    /// Payment discount tolerance amount excluding VAT for tax calculations.
    /// </summary>
    value(16; "Payment Discount Tolerance (VAT Excl.)") { Caption = 'Payment Discount Tolerance (VAT Excl.)'; }
    /// <summary>
    /// VAT adjustment entry for payment discount tolerance processing.
    /// </summary>
    value(17; "Payment Discount Tolerance (VAT Adjustment)") { Caption = 'Payment Discount Tolerance (VAT Adjustment)'; }
}
