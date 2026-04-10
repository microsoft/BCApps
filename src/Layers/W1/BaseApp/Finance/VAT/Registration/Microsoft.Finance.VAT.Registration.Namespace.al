/// <summary>
/// Provides comprehensive VAT registration number validation and management capabilities for Business Central.
/// Includes VIES service integration, format validation, and alternative VAT registration handling for multiple jurisdictions.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The VAT Registration system uses a service-oriented architecture with VIES integration for EU validation,
/// format validation tables for country-specific patterns, and logging infrastructure for audit trails.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>VAT Number Validation:</b></term>
/// <description>Format validation using country-specific patterns, VIES service validation for EU countries, and duplicate checking across entities</description>
/// </item>
/// <item>
/// <term><b>Alternative VAT Registration:</b></term>
/// <description>Multi-country VAT registration support for customers, ship-to address VAT handling, and sales document VAT management</description>
/// </item>
/// <item>
/// <term><b>Validation Logging:</b></term>
/// <description>Comprehensive audit trail creation, validation result tracking, and detailed response management from external services</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with VIES web service for EU VAT validation, Customer/Vendor/Contact entities for VAT registration storage,
/// Sales document processing for alternative VAT scenarios, and Service Connection framework for external service management.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include custom validation logic events, alternative VAT registration strategies through interfaces,
/// VIES service response processing events, and format validation customization. Supports country-specific validation extensions
/// and custom VAT registration workflows through comprehensive event architecture.
/// </para>
/// </remarks>
namespace Microsoft.Finance.VAT.Registration;
