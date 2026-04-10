// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides comprehensive VAT calculation functionality for Business Central including amount calculations, tax processing, and reporting date management.
/// Enables accurate VAT processing across sales, purchase, and service transactions with support for multiple VAT types and compliance requirements.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The VAT calculation system is built on a flexible calculation engine where VAT Amount Line serves as the central calculation buffer,
/// VAT Posting Parameters manage posting data transfer, and specialized management codeunits handle reporting dates and non-deductible VAT processing.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>VAT Amount Calculation:</b></term>
/// <description>Calculate VAT amounts from document lines using VAT Amount Line temporary tables with support for multiple VAT types, currency conversion, and rounding</description>
/// </item>
/// <item>
/// <term><b>VAT Posting Process:</b></term>
/// <description>Transfer calculated VAT data through VAT Posting Parameters to posting routines with comprehensive validation and period control</description>
/// </item>
/// <item>
/// <term><b>VAT Reporting Date Management:</b></term>
/// <description>Manage VAT reporting dates with validation against VAT periods, linked entry updates, and compliance with reporting requirements</description>
/// </item>
/// <item>
/// <term><b>Non-Deductible VAT Processing:</b></term>
/// <description>Handle non-deductible VAT calculations and distributions across expense accounts and asset costs with proper accounting integration</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates extensively with General Ledger posting, Sales/Purchase document processing, Service management, and VAT reporting systems.
/// Core dependencies include Currency management for rounding, VAT Setup for configuration, and various document posting frameworks.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include VAT calculation events in VAT Amount Line, reporting date validation events in VAT Reporting Date Management,
/// and non-deductible VAT processing events. Supports custom VAT calculation methods, validation rules, and integration with external tax systems.
/// </para>
/// </remarks>
namespace Microsoft.Finance.VAT.Calculation;
