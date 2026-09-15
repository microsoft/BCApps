#pragma warning disable AA0247
codeunit 104152 "UPG. Data Exchange Definition"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        DataExchDef: Record "Data Exch. Def";
        TempDataExchDefEFTPaymentExport: Record "Data Exch. Def" temporary;
        TempDataExchDefGenericExport: Record "Data Exch. Def" temporary;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        HybridDeployment: Codeunit "Hybrid Deployment";
        DataExchDefType: Enum "Data Exchange Definition Type";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetDataExchDefinitionTypeTag()) then
            exit;

        DataExchDef.SetRange(Type, 5); // EFT Payment Export
        if DataExchDef.FindSet() then
            repeat
                TempDataExchDefEFTPaymentExport := DataExchDef;
                TempDataExchDefEFTPaymentExport.Insert();
            until DataExchDef.Next() = 0;

        DataExchDef.SetRange(Type, 6); // Generic Export
        if DataExchDef.FindSet() then
            repeat
                TempDataExchDefGenericExport := DataExchDef;
                TempDataExchDefGenericExport.Insert();
            until DataExchDef.Next() = 0;

        if TempDataExchDefEFTPaymentExport.FindSet() then
            repeat
                if DataExchDef.get(TempDataExchDefEFTPaymentExport.Code) then begin
                    DataExchDef.Type := DataExchDefType::"EFT Payment Export";
                    DataExchDef.Modify();
                end;
            until TempDataExchDefEFTPaymentExport.Next() = 0;

        if TempDataExchDefGenericExport.FindSet() then
            repeat
                if DataExchDef.get(TempDataExchDefGenericExport.Code) then begin
                    DataExchDef.Type := DataExchDefType::"Generic Export";
                    DataExchDef.Modify();
                end;
            until TempDataExchDefGenericExport.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetDataExchDefinitionTypeTag());
    end;

}

