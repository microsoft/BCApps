#pragma warning disable AA0247
codeunit 9997 "Upgrade Tag Def - Country"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(Get1099DIV2018UpgradeTag());
        PerCompanyUpgradeTags.Add(GetCFDIPurposeRelationFieldsDocUpdateTag());
        PerCompanyUpgradeTags.Add(GetLastUpdateInvoiceEntryNoUpgradeTagUS());
        PerCompanyUpgradeTags.Add(GetGenJnlLineEFTExportSequenceNoUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSalesTaxDiffPositiveFieldUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCFDIEnableOptionUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCompanyInformationRFCNumberUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPACWebServiceDetailsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSCTPermissionNoUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSATAddressUpgradeTag());
        PerCompanyUpgradeTags.Add(GetDataExchDefinitionTypeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure RegisterPerDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetSATPaymentCatalogsSwapTag());
    end;

    procedure Get1099DIV2018UpgradeTag(): Code[250]
    begin
        exit('283821-1099DIV2018Changes-20181018');
    end;

    procedure GetSATPaymentCatalogsSwapTag(): Code[250]
    begin
        exit('MS-304691-SATPaymentCatalogsSwap-20190520');
    end;

    procedure GetCFDIPurposeRelationFieldsDocUpdateTag(): Code[250]
    begin
        exit('MS-304691-CFDIPurposeRelationFieldsDocUpdate-20190520');
    end;

    procedure GetLastUpdateInvoiceEntryNoUpgradeTagUS(): Code[250]
    begin
        exit('MS-310795-LastUpdateInvoiceEntryNo-20190611');
    end;

    procedure GetDataExchDefinitionTypeTag(): Code[250]
    begin
        exit('MS-297272-DataExchDefinitionType-20191030');
    end;

    procedure GetGenJnlLineEFTExportSequenceNoUpgradeTag(): Code[250];
    begin
        exit('MS-360400-EFTUpdatePart2-20200615');
    end;

    procedure GetSalesTaxDiffPositiveFieldUpgradeTag(): Code[250]
    begin
        exit('MS-377669-SalesTaxDiffNegAndPosLines-20201228');
    end;

    procedure GetCFDIEnableOptionUpgradeTag(): Code[250]
    begin
        exit('MS-407179-CFDIEnableOption-20200806');
    end;

    procedure GetCompanyInformationRFCNumberUpgradeTag(): Code[250]
    begin
        exit('MS-459664-CompanyInformation-RFCNumber-20230105');
    end;

    procedure GetPACWebServiceDetailsUpgradeTag(): Code[250]
    begin
        exit('MS-462312-PACWebServiceDetails-20230202');
    end;

    procedure GetSCTPermissionNoUpgradeTag(): Code[250]
    begin
        exit('MS-479044-SCTPermissionNo-20230809');
    end;

    procedure GetSATAddressUpgradeTag(): Code[250]
    begin
        exit('MS-477864-SATAddress-20230814');
    end;
}

