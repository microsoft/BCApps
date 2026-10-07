// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides comprehensive direct debit collection functionality for SEPA and other direct debit standards.
/// This namespace implements the complete lifecycle of direct debit processing, from mandate management
/// to collection execution and file generation. The architecture supports multiple payment standards
/// through dedicated export handlers and validation routines.
/// </summary>
/// <remarks>
/// Key architectural components include mandate management for customer authorization,
/// collection orchestration for grouping and processing payments, SEPA-compliant XML generation
/// for standard formats (pain.008.001.02/08 for direct debits, pain.001.001.03/09 for credit transfers),
/// and automated status tracking throughout the process lifecycle.
/// 
/// The namespace integrates with core banking functionality through bank account management,
/// customer data for mandate validation, and general journal processing for posting.
/// Extension points include custom validation rules, specialized export formats,
/// and integration event handling for third-party payment processors.
/// 
/// Dependencies include Microsoft.Bank.BankAccount for account management,
/// Microsoft.Sales.Customer for mandate relationships, Microsoft.Finance.GeneralLedger.Journal
/// for payment processing, and System.IO for file generation and management.
/// </remarks>
namespace Microsoft.Bank.DirectDebit;
