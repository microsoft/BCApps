// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.Sales.Customer;

/// <summary>
/// The interface provides methods to check the consistency of the alternative customer VAT registration and dependant entities.
/// </summary>
interface "Alt. Cust. VAT Reg. Consist."
{
    Access = Public;

    /// <summary>
    /// Checks that the current state of the alternative customer VAT registration is correct
    /// </summary>
    /// <param name="AltCustVATReg">The current alternative customer VAT registration record</param>
    procedure CheckAltCustVATRegConsistent(AltCustVATReg: Record "Alt. Cust. VAT Reg.")

    /// <summary>
    /// Checks that the current state of the customer is consistent with the alternative customer VAT registration
    /// </summary>
    /// <param name="Customer"></param>
    procedure CheckCustomerConsistency(Customer: Record Customer)
}