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

    /// <summary>
    /// Gets the document identification (CustomizationID/ProfileID) for the PEPPOL remittance advice header.
    /// No PEPPOL BIS profile exists for remittance advice yet, so the default implementation returns both empty
    /// (the elements are omitted); a localization can supply its own values by overriding this method.
    /// </summary>
    /// <param name="CustomizationID">Returns the CustomizationID; empty to omit the element.</param>
    /// <param name="ProfileID">Returns the ProfileID; empty to omit the element.</param>
    procedure GetDocumentIdentification(var CustomizationID: Text; var ProfileID: Text)
}
