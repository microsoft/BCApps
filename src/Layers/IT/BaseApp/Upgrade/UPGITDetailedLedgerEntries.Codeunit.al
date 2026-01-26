#pragma warning disable AA0247
codeunit 104151 "UPG.IT Detailed Ledger Entries"
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

        UpgradeDetailedVendorLedgerEntries();
        UpgradeDetailedCustomerLedgerEntries();
    end;

    procedure UpgradeDetailedVendorLedgerEntries();
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTags: Codeunit "Upgrade Tag Def - Country";
        VendorLedgerEntryDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTags.GetFixRemainingAmountVLEUpgradeTag()) then
            exit;

        VendorLedgerEntryDataTransfer.SetTables(Database::"Vendor Ledger Entry", Database::"Detailed Vendor Ledg. Entry");
        VendorLedgerEntryDataTransfer.AddJoin(VendorLedgerEntry.FieldNo("Entry No."), DetailedVendorLedgEntry.FieldNo("Vendor Ledger Entry No."));
        VendorLedgerEntryDataTransfer.AddFieldValue(VendorLedgerEntry.FieldNo("Document No."), DetailedVendorLedgEntry.FieldNo("Original Document No."));
        VendorLedgerEntryDataTransfer.AddFieldValue(VendorLedgerEntry.FieldNo("Document Type"), DetailedVendorLedgEntry.FieldNo("Original Document Type"));
        VendorLedgerEntryDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTags.GetFixRemainingAmountVLEUpgradeTag());
    end;

    procedure UpgradeDetailedCustomerLedgerEntries();
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTags: Codeunit "Upgrade Tag Def - Country";
        CustLedgerEntryDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTags.GetFixRemainingAmountCLEUpgradeTag()) then
            exit;

        CustLedgerEntryDataTransfer.SetTables(Database::"Cust. Ledger Entry", Database::"Detailed Cust. Ledg. Entry");
        CustLedgerEntryDataTransfer.AddJoin(CustLedgerEntry.FieldNo("Entry No."), DetailedCustLedgEntry.FieldNo("Cust. Ledger Entry No."));
        CustLedgerEntryDataTransfer.AddFieldValue(CustLedgerEntry.FieldNo("Document No."), DetailedCustLedgEntry.FieldNo("Original Document No."));
        CustLedgerEntryDataTransfer.AddFieldValue(CustLedgerEntry.FieldNo("Document Type"), DetailedCustLedgEntry.FieldNo("Original Document Type"));
        CustLedgerEntryDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTags.GetFixRemainingAmountCLEUpgradeTag());
    end;
}

