// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.Sales.Customer;

/// <summary>
/// The interface provides methods to handle the alternative customer VAT registration in the ship-to address.
/// </summary>
interface "Ship-To Alt. Cust. VAT Reg."
{
    Access = Public;

    /// <summary>
    /// Handles the relation to the alternative customer VAT registration when the country/region code is changed in the ship-to address.
    /// </summary>
    /// <param name="ShipToAddress">The current ship-to address record</param>
    procedure HandleCountryChangeInShipToAddress(ShipToAddress: Record "Ship-to Address")
}