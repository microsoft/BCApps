#pragma warning disable AA0247
codeunit 14060 "UPG Data Out Of Geo. Apps"
{
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade('') then
            exit;

        AddDataOutOfGeoApps();
    end;

    local procedure AddDataOutOfGeoApps()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetDataOutOfGeoAppTagCh()) then
            exit;

        InsertDataOutOfGeoApp('d09fa965-9a2a-424d-b704-69f3b54ed0ce'); // Paypal
        InsertDataOutOfGeoApp('bae453ed-0fd8-4416-afdc-4b09db6c12c3'); // World Pay
        InsertDataOutOfGeoApp('16319982-4995-4fb1-8fb2-2b1e13773e3b'); // AMC
        InsertDataOutOfGeoApp('e868ad92-21b8-4e08-af2b-8975a8b06e04'); // Image Analysis
        InsertDataOutOfGeoApp('3d5b2137-efeb-4014-8489-41d37f8fd4c3'); // Late Payment Predictor
        InsertDataOutOfGeoApp('c526b3e9-b8ca-4683-81ba-fcd5f6b1472a'); // Sales and Inventory Forecast

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetDataOutOfGeoAppTagCh());
    end;

    local procedure InsertDataOutOfGeoApp(AppID: Guid)
    var
        DataOutOfGeoApp: Codeunit "Data Out Of Geo. App";
    begin
        if not DataOutOfGeoApp.Contains(AppID) then
            DataOutOfGeoApp.Add(AppID);
    end;
}
