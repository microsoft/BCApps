// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

interface "PEPPOL Format Provider"
{
    /// <summary>
    /// Gets the unit of measure code for pieces in UN/ECE Rec 20 list.
    /// </summary>
    /// <returns>The unit of measure code for pieces.</returns>
    procedure GetUoMforPieceINUNECERec20ListID(): Code[10]

    /// <summary>
    /// Gets the VAT scheme identifier for a specific country/region.
    /// </summary>
    /// <param name="CountryRegionCode">The country/region code to get the VAT scheme for.</param>
    /// <returns>The VAT scheme identifier for the country/region.</returns>
    procedure GetVATScheme(CountryRegionCode: Code[10]): Text

    /// <summary>
    /// Gets the PEPPOL telemetry token for tracking purposes.
    /// </summary>
    /// <returns>The PEPPOL telemetry token.</returns>
    procedure GetPeppolTelemetryTok(): Text
}