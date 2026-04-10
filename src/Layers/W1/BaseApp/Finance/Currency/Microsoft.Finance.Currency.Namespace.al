// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides comprehensive currency management functionality for multi-currency business operations.
/// Enables currency setup, exchange rate management, automated rate updates, and currency revaluation
/// to ensure accurate financial reporting and compliance with international accounting standards.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The currency system is built on a master-detail pattern where Currency table (4) serves as the master record
/// defining currency properties, while Currency Exchange Rate table manages historical rates. Exchange rate
/// adjustment processing uses buffer tables for calculation optimization and ledger tables for audit trails.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Currency Setup:</b></term>
/// <description>Configure currency definitions, rounding rules, G/L account mappings, and exchange rate relationships</description>
/// </item>
/// <item>
/// <term><b>Exchange Rate Management:</b></term>
/// <description>Maintain current and historical exchange rates manually or through automated service updates</description>
/// </item>
/// <item>
/// <term><b>Revaluation Processing:</b></term>
/// <description>Perform comprehensive exchange rate adjustments across customer, vendor, bank, and G/L accounts to reflect current rates</description>
/// </item>
/// <item>
/// <term><b>Service Integration:</b></term>
/// <description>Connect to external currency exchange rate services for automated daily rate updates and synchronization</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with General Ledger for posting adjustment entries, Data Exchange Framework for automated rate imports,
/// Job Queue for scheduled updates, and all transaction modules (Sales, Purchase, Banking) for currency calculations.
/// Customer Consent Management ensures compliance with data privacy regulations for external service connections.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include exchange rate adjustment calculation events, currency setup validation hooks,
/// and service integration customization events. Supports custom calculation methods through OnBeforeCalculate events,
/// custom rate providers through service setup events, and adjustment posting customization through integration events.
/// </para>
/// <para>
/// <b>Dependencies:</b><br/>
/// <i>Required:</i> <c>Microsoft.Finance.GeneralLedger</c>, <c>Microsoft.Foundation.Period</c>, <c>Microsoft.Foundation.NoSeries</c><br/>
/// <i>Optional:</i> <c>Microsoft.Sales</c>, <c>Microsoft.Purchases</c>, <c>Microsoft.Bank</c>, <c>System.Integration</c>, <c>System.Threading</c>
/// </para>
/// </remarks>
namespace Microsoft.Finance.Currency;
