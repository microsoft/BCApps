// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AdvancePayments;

using Microsoft.Purchases.Vendor;

tableextension 31046 "Vendor CZZ" extends Vendor
{
    procedure GetPurchaseAdvancesCountCZZ(): Integer
    var
        PurchAdvLetterHeaderCZZ: Record "Purch. Adv. Letter Header CZZ";
    begin
        PurchAdvLetterHeaderCZZ.SetRange("Pay-to Vendor No.", "No.");
        PurchAdvLetterHeaderCZZ.SetFilter(Status, '%1|%2', PurchAdvLetterHeaderCZZ.Status::"To Pay", PurchAdvLetterHeaderCZZ.Status::"To Use");
        exit(PurchAdvLetterHeaderCZZ.Count());
    end;


    /// <summary>
    /// Checks if the vendor is blocked for the specified advance letter and raises an error if blocked.
    /// </summary>
    /// <param name="Transaction">Indicates whether this is a posting transaction.</param>
    procedure CheckBlockedVendOnAdvanceLettersCZZ(Transaction: Boolean)
    begin
        if "Privacy Blocked" then
            VendPrivacyBlockedErrorMessage(Rec, Transaction);

        if Blocked <> Blocked::" " then
            VendBlockedErrorMessage(Rec, Transaction);
    end;
}
