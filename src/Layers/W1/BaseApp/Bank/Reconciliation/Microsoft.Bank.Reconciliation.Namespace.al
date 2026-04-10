// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// This namespace contains functionality for bank account reconciliation and payment application processes.
/// It provides comprehensive tools for matching bank statement lines with bank account ledger entries,
/// applying payments to customer and vendor invoices, and managing bank reconciliation workflows.
/// The namespace supports automatic and manual matching algorithms, payment discount handling,
/// and multi-currency reconciliation scenarios.
/// </summary>
/// <remarks>
/// Key features include:
/// - Bank statement import and processing
/// - Automatic matching of bank transactions with ledger entries
/// - Payment application with discount and tolerance support
/// - Text-to-account mapping for recurring transactions
/// - Multi-currency reconciliation capabilities
/// - Integration events for customizing matching and application logic
/// - Comprehensive audit trail and reporting
/// 
/// The namespace is designed to handle complex reconciliation scenarios including:
/// - One-to-one, one-to-many, and many-to-one transaction matching
/// - Payment discounts and payment tolerance
/// - Cross-currency applications
/// - Bank charges and fees handling
/// - Reversals and corrections
/// </remarks>
namespace Microsoft.Bank.Reconciliation;
