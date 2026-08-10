// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AdvancePayments;

using Microsoft.Sales.Customer;

tableextension 31045 "Customer CZZ" extends Customer
{
    procedure GetSalesAdvancesCountCZZ(): Integer
    var
        SalesAdvLetterHeaderCZZ: Record "Sales Adv. Letter Header CZZ";
    begin
        SalesAdvLetterHeaderCZZ.SetRange("Bill-to Customer No.", "No.");
        SalesAdvLetterHeaderCZZ.SetFilter(Status, '%1|%2', SalesAdvLetterHeaderCZZ.Status::"To Pay", SalesAdvLetterHeaderCZZ.Status::"To Use");
        exit(SalesAdvLetterHeaderCZZ.Count());
    end;

    /// <summary>
    /// Checks if the customer is blocked for the specified advance letter and raises an error if blocked.
    /// </summary>
    /// <param name="Transaction">Indicates whether this is a posting transaction.</param>
    procedure CheckBlockedCustOnAdvanceLettersCZZ(Transaction: Boolean)
    begin
        if "Privacy Blocked" then
            CustPrivacyBlockedErrorMessage(Rec, Transaction);

        if Blocked <> Blocked::" " then
            CustBlockedErrorMessage(Rec, Transaction);
    end;
}
