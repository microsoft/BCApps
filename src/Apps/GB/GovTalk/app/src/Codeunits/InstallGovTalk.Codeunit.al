// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.GovTalk;

using System.Upgrade;

codeunit 10560 "Install GovTalk"
{
    Access = Internal;
    Subtype = Install;

    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagGovTalk: Codeunit "Upg. Tag GovTalk";

    trigger OnInstallAppPerCompany()
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if CurrentModuleInfo.AppVersion().Major() < 30 then
            exit;

        InstallGovTalk();
    end;

    local procedure InstallGovTalk()
    var
        GovTalkHelperProcedures: Codeunit "GovTalk Helper Procedures";
        CompanyInformationTableId: Integer;
        ECSLVATReportLineTableId: Integer;
        VATReportsConfigurationTableId: Integer;
        GovTalkMessageTableId: Integer;
        GovTalkMessagePartsTableId: Integer;
        GovTalkSetupTableId: Integer;
        NewGovTalkMessageTableId: Integer;
        NewGovTalkMessagePartsTableId: Integer;
        NewGovTalkSetupTableId: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagGovTalk.GetGovTalkUpgradeTag()) then
            exit;

        CompanyInformationTableId := 79;
        ECSLVATReportLineTableId := 362;
        VATReportsConfigurationTableId := 746;
        GovTalkMessageTableId := 10520;
        GovTalkMessagePartsTableId := 10524;
        GovTalkSetupTableId := 10523;
        NewGovTalkMessageTableId := 10504;
        NewGovTalkMessagePartsTableId := 10519;
        NewGovTalkSetupTableId := 10525;

        GovTalkHelperProcedures.TransferFields(CompanyInformationTableId, 10507, 10509); // 10507 - the existing field "Branch Number", 10509 - the new field "Branch Number GB";
        GovTalkHelperProcedures.TransferFields(ECSLVATReportLineTableId, 10500, 10502); // 10500 - the existing field "Line Status", 10502 - the new field "Line Status GB";
        GovTalkHelperProcedures.TransferFields(ECSLVATReportLineTableId, 10501, 10503); // 10501 - the existing field "XML Part Id", 10503 - the new field "XML Part Id GB";
        GovTalkHelperProcedures.TransferFields(VATReportsConfigurationTableId, 10500, 10501); // 10500 - the existing field "Content Max Lines", 10501 - the new field "Content Max Lines GB";
        GovTalkHelperProcedures.TransferRecords(GovTalkMessageTableId, NewGovTalkMessageTableId);
        GovTalkHelperProcedures.TransferRecords(GovTalkMessagePartsTableId, NewGovTalkMessagePartsTableId);
        GovTalkHelperProcedures.TransferRecords(GovTalkSetupTableId, NewGovTalkSetupTableId);
        GovTalkHelperProcedures.UpgradeVATReportHeaderStatus();
        GovTalkHelperProcedures.SetDefaultReportLayouts();

        UpgradeTag.SetUpgradeTag(UpgTagGovTalk.GetGovTalkUpgradeTag());
    end;
}