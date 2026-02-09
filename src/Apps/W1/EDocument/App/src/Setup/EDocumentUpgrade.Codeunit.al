// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

#if not CLEAN28
using Microsoft.Sales.History;
#endif
using System.Upgrade;

codeunit 6168 "E-Document Upgrade"
{
    Access = Internal;
    Subtype = Upgrade;
    InherentPermissions = X;
    InherentEntitlements = X;

    trigger OnUpgradePerCompany()
    begin
        UpgradeLogURLMaxLength();
#if not CLEAN28
        UpgradeQRCodeFields();
#endif
    end;

    local procedure UpgradeLogURLMaxLength()
    var
        EDocumentIntegrationLog: Record "E-Document Integration Log";
        UpgradeTag: Codeunit "Upgrade Tag";
        EDocumentIntegrationLogDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(GetUpgradeLogURLMaxLengthUpgradeTag()) then
            exit;

        EDocumentIntegrationLogDataTransfer.SetTables(Database::"E-Document Integration Log", Database::"E-Document Integration Log");
        EDocumentIntegrationLogDataTransfer.AddFieldValue(EDocumentIntegrationLog.FieldNo(URL), EDocumentIntegrationLog.FieldNo("Request URL"));
        EDocumentIntegrationLogDataTransfer.UpdateAuditFields(false);
        EDocumentIntegrationLogDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(GetUpgradeLogURLMaxLengthUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetUpgradeLogURLMaxLengthUpgradeTag());
#if not CLEAN28
        PerCompanyUpgradeTags.Add(GetQRCodeFieldsUpgradeTag());
#endif
    end;

    internal procedure GetUpgradeLogURLMaxLengthUpgradeTag(): Code[250]
    begin
        exit('MS-540448-LogURLMaxLength-20240813');
    end;

#if not CLEAN28
    local procedure UpgradeQRCodeFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetQRCodeFieldsUpgradeTag()) then
            exit;

        MigrateSalesCrMemoQRCodeFields();

        UpgradeTag.SetUpgradeTag(GetQRCodeFieldsUpgradeTag());
    end;

    local procedure MigrateSalesCrMemoQRCodeFields()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoDataTransfer: DataTransfer;
    begin
        // Use DataTransfer to copy data by field ID (works even after field is deleted from code)
        // Field 6167 (old "QR Code Image") -> Field 6165 (new "QR Code Image")
        // Field 6168 (old "QR Code Base64") -> Field 6166 (new "QR Code Base64")
        SalesCrMemoDataTransfer.SetTables(Database::"Sales Cr.Memo Header", Database::"Sales Cr.Memo Header");
        SalesCrMemoDataTransfer.AddFieldValue(6167, SalesCrMemoHeader.FieldNo("QR Code Image"));
        SalesCrMemoDataTransfer.AddFieldValue(6168, SalesCrMemoHeader.FieldNo("QR Code Base64"));
        SalesCrMemoDataTransfer.UpdateAuditFields(false);
        SalesCrMemoDataTransfer.CopyFields();
    end;

    local procedure GetQRCodeFieldsUpgradeTag(): Code[250]
    begin
        exit('MS-EDOC-QRCodeFieldsUpgrade-20260209');
    end;
#endif

}