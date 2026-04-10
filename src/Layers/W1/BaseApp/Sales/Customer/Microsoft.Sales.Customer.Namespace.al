// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides customer master data management, statistics, credit limits, and customer-related operations.
/// </summary>
/// <remarks>
/// <para><b>Key Capabilities:</b></para>
/// <list type="bullet">
///   <item>Customer master data including addresses and bank accounts</item>
///   <item>Credit limit management and validation</item>
///   <item>Customer statistics and analytics</item>
///   <item>Customer templates for quick setup</item>
///   <item>Customer posting group configuration</item>
///   <item>Statement generation and reporting</item>
/// </list>
/// <para><b>Core Subsystems:</b></para>
/// <list type="bullet">
///   <item><c>Customer</c> - Main customer master table</item>
///   <item><c>Customer Posting Group</c> - G/L account mapping configuration</item>
///   <item><c>Ship-to Address</c> - Multiple delivery addresses</item>
///   <item><c>Customer Bank Account</c> - Payment information</item>
/// </list>
/// <para><b>Entry Points:</b> Use <c>Customer Card</c> for individual customer management,
/// <c>Customer List</c> for browsing customers, <c>Customer Mgt.</c> codeunit for business logic.</para>
/// </remarks>
namespace Microsoft.Sales.Customer;
