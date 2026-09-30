#pragma warning disable AA0247
codeunit 104100 "Upg Local Functionality"
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

        UpdateVendorRegistrationNo();
    end;

    procedure UpdateVendorRegistrationNo()
    var
        Vendor: Record Vendor;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        VendorDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetVendorRegistrationNoTag()) then
            exit;

        VendorDataTransfer.SetTables(Database::Vendor, Database::Vendor);
        VendorDataTransfer.AddFieldValue(Vendor.FieldNo("Registration No."), Vendor.FieldNo("Registration Number"));
        VendorDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetVendorRegistrationNoTag());
    end;
}
