#pragma warning disable AA0247
codeunit 104171 "Elec. Tax. Decl. Upgrade"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    var
        SchemaVersionTxt: Label '2019v13.0', Locked = true;
        BDDataEndpointTxt: Label 'https://www.nltaxonomie.nl/nt17/bd/20221207/dictionary/bd-data', Locked = true;
        BDTuplesEndpointTxt: Label 'https://www.nltaxonomie.nl/nt17/bd/20221207/dictionary/bd-tuples', Locked = true;
        TaxDeclarationSchemaEndpointTxt: Label 'https://www.nltaxonomie.nl/nt17/bd/20221207/entrypoints/bd-rpt-ob-aangifte-2023.xsd', Locked = true;
        ICPDeclarationSchemaEndpointTxt: Label 'https://www.nltaxonomie.nl/nt17/bd/20221207/entrypoints/bd-rpt-icp-opgaaf-2023.xsd', Locked = true;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        UpgradeElecTaxDeclSetup();
    end;

    local procedure UpgradeElecTaxDeclSetup()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetElecTaxDeclSetupUpgradeTag()) then
            exit;

        if ElecTaxDeclarationSetup.Get() then begin
            ElecTaxDeclarationSetup.Validate("Tax Decl. Schema Version", SchemaVersionTxt);
            ElecTaxDeclarationSetup.Validate("Tax Decl. BD Data Endpoint", BDDataEndpointTxt);
            ElecTaxDeclarationSetup.Validate("Tax Decl. BD Tuples Endpoint", BDTuplesEndpointTxt);
            ElecTaxDeclarationSetup.Validate("Tax Decl. Schema Endpoint", TaxDeclarationSchemaEndpointTxt);
            ElecTaxDeclarationSetup.Validate("ICP Decl. Schema Endpoint", ICPDeclarationSchemaEndpointTxt);
            ElecTaxDeclarationSetup.Modify(true);
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetElecTaxDeclSetupUpgradeTag());
    end;

}

