codeunit 143007 "Library - Journals ES"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Journals", OnBeforeModifyGenJnlLineWhenCreate, '', false, false)]
    local procedure SetBillToPayToNoOnBeforeModifyGenJnlLineWhenCreate(var GenJournalLine: Record "Gen. Journal Line")
    begin
        SetBillToPayToNo(GenJournalLine);  // To prevent Bill-to/ Pay-to No. issue in ES.
    end;

    local procedure SetBillToPayToNo(var GenJournalLine: Record "Gen. Journal Line")
    var
        Customer: Record Customer;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        if LibraryLowerPermissions.HasChangedPermissions() then
            LibraryLowerPermissions.AddCustomerEdit();
        LibrarySales.CreateCustomer(Customer);

        // Bill-to Pay-to No. need to be filled in Gen. Journal Lines for Accounts other than Customer and Vendor in ES.
        if GenJournalLine."Bill-to/Pay-to No." = '' then begin
            if (GenJournalLine."Gen. Posting Type" = GenJournalLine."Gen. Posting Type"::Sale) or (GenJournalLine."Bal. Gen. Posting Type" = GenJournalLine."Bal. Gen. Posting Type"::Sale)
              or (GenJournalLine."Account Type" = GenJournalLine."Account Type"::Customer) or (GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::Customer)
            then
                GenJournalLine.Validate("Bill-to/Pay-to No.", Customer."No.");
            if (GenJournalLine."Gen. Posting Type" = GenJournalLine."Gen. Posting Type"::Purchase) or (GenJournalLine."Bal. Gen. Posting Type" = GenJournalLine."Bal. Gen. Posting Type"::Purchase)
              or (GenJournalLine."Account Type" = GenJournalLine."Account Type"::Vendor) or (GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::Vendor)
            then
                GenJournalLine.Validate("Bill-to/Pay-to No.", LibraryPurchase.CreateVendorNo())
            else
                GenJournalLine.Validate("Bill-to/Pay-to No.", Customer."No.");
        end;
    end;
}