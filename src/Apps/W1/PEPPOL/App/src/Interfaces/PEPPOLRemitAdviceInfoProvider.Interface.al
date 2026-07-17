// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Purchases.Vendor;

interface "PEPPOL Remit. Advice Info Provider"
{
    /// <summary>
    /// Gets payee (vendor) party information for the PEPPOL remittance advice.
    /// </summary>
    /// <param name="Vendor">The vendor being paid.</param>
    /// <param name="PayeeEndpointID">Returns the payee endpoint ID.</param>
    /// <param name="PayeeSchemeID">Returns the payee endpoint scheme ID.</param>
    /// <param name="PayeePartyName">Returns the payee party name.</param>
    procedure GetPayeePartyInfo(Vendor: Record Vendor; var PayeeEndpointID: Text; var PayeeSchemeID: Text; var PayeePartyName: Text)

    /// <summary>
    /// Gets payment means information for the PEPPOL remittance advice from the buffer's header row.
    /// </summary>
    /// <param name="RemitAdviceBuffer">The remittance advice buffer header row ("Line No." = 0).</param>
    /// <param name="PaymentMeansCode">Returns the UNCL4461 payment means code; empty to omit the PaymentMeans element.</param>
    /// <param name="PayeeFinancialAccountID">Returns the payee financial account ID (IBAN or bank account no.); empty to omit.</param>
    procedure GetPaymentMeansInfo(RemitAdviceBuffer: Record "Remit. Advice Buffer" temporary; var PaymentMeansCode: Text; var PayeeFinancialAccountID: Text)
}
