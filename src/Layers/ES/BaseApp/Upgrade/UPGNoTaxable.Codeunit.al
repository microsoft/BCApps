#pragma warning disable AA0247
codeunit 104102 "Upg No Taxable"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        UpdateNoTaxableEntries();
        UpdateNoTaxableEntriesWithVATDate();
        UpgradeCustVendWarning349WithVATDate();
        UpgradeCustLedgerEntriesWithVATDAte();
        UpgradeVendLedgerEntriesWithVATDAte();
    end;

    local procedure UpdateNoTaxableEntries()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateNoTaxableEntriesTag()) then
            exit;

        CODEUNIT.RUN(CODEUNIT::"No Taxable - Generate Entries");

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateNoTaxableEntriesTag());
    end;


    local procedure UpdateNoTaxableEntriesWithVATDate()
    var
        NoTaxableEntry: Record "No Taxable Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        DataTransfer: DataTransfer;
        BlankDate: Date;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateNoTaxableEntriesVATDateTag()) then
            exit;

        NoTaxableEntry.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not NoTaxableEntry.IsEmpty() then
            exit;

        DataTransfer.SetTables(Database::"No Taxable Entry", Database::"No Taxable Entry");
        DataTransfer.AddFieldValue(NoTaxableEntry.FieldNo("Posting Date"), NoTaxableEntry.FieldNo("VAT Reporting Date"));
        DataTransfer.UpdateAuditFields(false);
        DataTransfer.CopyFields();
        Clear(DataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateNoTaxableEntriesVATDateTag());
    end;

    local procedure UpgradeCustVendWarning349WithVATDate()
    var
        CustVendWarning349: Record "Customer/Vendor Warning 349";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        DataTransfer: DataTransfer;
        BlankDate: Date;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateCustVendWarning349VATDateTag()) then
            exit;

        CustVendWarning349.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not CustVendWarning349.IsEmpty() then
            exit;

        DataTransfer.SetTables(Database::"Customer/Vendor Warning 349", Database::"Customer/Vendor Warning 349");
        DataTransfer.AddFieldValue(CustVendWarning349.FieldNo("Posting Date"), CustVendWarning349.FieldNo("VAT Reporting Date"));
        DataTransfer.UpdateAuditFields(false);
        DataTransfer.CopyFields();
        Clear(DataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateCustVendWarning349VATDateTag());
    end;

    local procedure UpgradeCustLedgerEntriesWithVATDAte()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        DataTransfer: DataTransfer;
        BlankDate: Date;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateCustLedgerEntryVATDateTag()) then
            exit;

        CustLedgerEntry.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        DetailedCustLedgEntry.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not CustLedgerEntry.IsEmpty() or not DetailedCustLedgEntry.IsEmpty() then
            exit;

        DataTransfer.SetTables(Database::"Cust. Ledger Entry", Database::"Cust. Ledger Entry");
        DataTransfer.AddFieldValue(CustLedgerEntry.FieldNo("Posting Date"), CustLedgerEntry.FieldNo("VAT Reporting Date"));
        DataTransfer.UpdateAuditFields(false);
        DataTransfer.CopyFields();
        Clear(DataTransfer);

        DataTransfer.SetTables(Database::"Detailed Cust. Ledg. Entry", Database::"Detailed Cust. Ledg. Entry");
        DataTransfer.AddFieldValue(DetailedCustLedgEntry.FieldNo("Posting Date"), DetailedCustLedgEntry.FieldNo("VAT Reporting Date"));
        DataTransfer.UpdateAuditFields(false);
        DataTransfer.CopyFields();
        Clear(DataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateCustLedgerEntryVATDateTag());
    end;

    local procedure UpgradeVendLedgerEntriesWithVATDAte()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        DataTransfer: DataTransfer;
        BlankDate: Date;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateVendLedgerEntryVATDateTag()) then
            exit;

        VendLedgerEntry.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        DetailedVendorLedgEntry.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not VendLedgerEntry.IsEmpty() or not DetailedVendorLedgEntry.IsEmpty() then
            exit;

        DataTransfer.SetTables(Database::"Vendor Ledger Entry", Database::"Vendor Ledger Entry");
        DataTransfer.AddFieldValue(VendLedgerEntry.FieldNo("Posting Date"), VendLedgerEntry.FieldNo("VAT Reporting Date"));
        DataTransfer.UpdateAuditFields(false);
        DataTransfer.CopyFields();
        Clear(DataTransfer);

        DataTransfer.SetTables(Database::"Detailed Vendor Ledg. Entry", Database::"Detailed Vendor Ledg. Entry");
        DataTransfer.AddFieldValue(DetailedVendorLedgEntry.FieldNo("Posting Date"), DetailedVendorLedgEntry.FieldNo("VAT Reporting Date"));
        DataTransfer.UpdateAuditFields(false);
        DataTransfer.CopyFields();
        Clear(DataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateVendLedgerEntryVATDateTag());
    end;

}
