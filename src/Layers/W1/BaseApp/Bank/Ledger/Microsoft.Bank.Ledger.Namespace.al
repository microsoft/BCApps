// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides comprehensive bank account ledger entry management for transaction tracking and reconciliation.
/// This namespace implements the complete bank account transaction lifecycle from entry creation
/// through application processing and historical analysis. The architecture supports detailed
/// transaction tracking with running balance calculations and audit trail maintenance.
/// </summary>
/// <remarks>
/// Key architectural components include bank account ledger entry storage for transaction records,
/// application processing for matching and reconciling entries, running balance calculations
/// for real-time account position tracking, and comprehensive querying capabilities for reporting.
/// 
/// The namespace integrates with core banking functionality through bank account management,
/// general ledger integration for financial consistency, and date compression utilities
/// for historical data maintenance. Extension points include custom application logic,
/// specialized balance calculations, and integration event handling for third-party systems.
/// 
/// Dependencies include Microsoft.Bank.BankAccount for account relationships,
/// Microsoft.Finance.GeneralLedger for posting integration, and Microsoft.Foundation.AuditCodes
/// for transaction classification and tracking purposes.
/// </remarks>
namespace Microsoft.Bank.Ledger;
