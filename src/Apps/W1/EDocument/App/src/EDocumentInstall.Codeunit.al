// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.IO;

#if not CLEAN29
using Microsoft.eServices.EDocument.OrderMatch.Copilot;
#endif
using System.IO;
using System.Reflection;
using System.Upgrade;
using System.Utilities;

codeunit 6161 "E-Document Install"
{
    Access = Internal;
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        InsertDataExch();
        InsertDataExchV2();
    end;

#if not CLEAN29
    trigger OnInstallAppPerDatabase()
    var
        EDocAIMatching: Codeunit "E-Doc. PO Copilot Matching";
    begin
        EDocAIMatching.RegisterAICapability();
    end;
#endif

    internal procedure InsertDataExch()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetEDOCDataExchUpdateTag()) then
            exit;

        ImportInvoiceXML();
        ImportCreditMemoXML();

        ImportSalesInvoiceXML();
        ImportSalesCreditMemoXML();

        ImportServiceInvoiceXML();
        ImportServiceCreditMemoXML();

        if not UpgradeTag.HasUpgradeTag(GetEDOCDataExchUpdateTag()) then
            UpgradeTag.SetUpgradeTag(GetEDOCDataExchUpdateTag());
    end;

    internal procedure InsertDataExchV2()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetEDOCDataExchV2UpdateTag()) then
            exit;

        ImportInvoiceV2XML();
        ImportCreditMemoV2XML();

        UpgradeTag.SetUpgradeTag(GetEDOCDataExchV2UpdateTag());
    end;

    internal procedure ImportServiceInvoiceXML()
    var
        DataExchDef: Record "Data Exch. Def";
        Field: Record Field;
        ResourceName: Text;
    begin
        if DataExchDef.Get('EDOCPEPPOLSRVINVEXP') then
            DataExchDef.Delete(true);

        // Fix issue in NO localisation where Field 100 does not exists:
        ResourceName := ServiceInvoiceExportResourceTok;
        Field.SetRange(TableNo, 5992); // Serv. Inv. Header
        Field.SetRange("No.", 100); // W1 field (External Doc. No.)
        if Field.IsEmpty() then
            ResourceName := ServiceInvoiceExportNOResourceTok;

        ImportDataExchDefinition(ResourceName);
    end;

    internal procedure ImportServiceCreditMemoXML()
    var
        DataExchDef: Record "Data Exch. Def";
        Field: Record Field;
        ResourceName: Text;
    begin
        if DataExchDef.Get('EDOCPEPPOLSRVCRMEXP') then
            DataExchDef.Delete(true);

        // Fix issue in NO localisation where Field 100 does not exists:
        ResourceName := ServiceCrMemoExportResourceTok;
        Field.SetRange(TableNo, 5992); // Serv. Inv. Header
        Field.SetRange("No.", 100); // W1 field (External Doc. No.)
        if Field.IsEmpty() then
            ResourceName := ServiceCrMemoExportNOResourceTok;

        ImportDataExchDefinition(ResourceName);
    end;

    internal procedure ImportSalesInvoiceXML()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        if DataExchDef.Get('EDOCPEPPOLSALINVEXP') then
            DataExchDef.Delete(true);

        ImportDataExchDefinition(SalesInvoiceExportResourceTok);
    end;

    internal procedure ImportSalesCreditMemoXML()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        if DataExchDef.Get('EDOCPEPPOLSALCRMEXP') then
            DataExchDef.Delete(true);

        ImportDataExchDefinition(SalesCrMemoExportResourceTok);
    end;

    internal procedure ImportCreditMemoXML()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        if DataExchDef.Get('EDOCPEPPOLCRMEMOIMP') then
            DataExchDef.Delete(true);

        ImportDataExchDefinition(CrMemoImportResourceTok);
    end;

    internal procedure ImportInvoiceXML()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        if DataExchDef.Get('EDOCPEPPOLINVIMP') then
            DataExchDef.Delete(true);

        ImportDataExchDefinition(InvoiceImportResourceTok);
    end;

    internal procedure ImportInvoiceV2XML()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        if DataExchDef.Get('EDOCPEPINVIMPV2') then
            DataExchDef.Delete(true);
        if DataExchDef.Get('EDOCPEPINVPURCHDRAFT') then
            DataExchDef.Delete(true);

        ImportDataExchDefinition(InvoiceImportV2ResourceTok);
    end;

    internal procedure ImportCreditMemoV2XML()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        if DataExchDef.Get('EDOCPEPCRMEMOIMPV2') then
            DataExchDef.Delete(true);
        if DataExchDef.Get('EDOCPEPCMPURCHDRAFT') then
            DataExchDef.Delete(true);

        ImportDataExchDefinition(CrMemoImportV2ResourceTok);
    end;

    local procedure ImportDataExchDefinition(ResourceName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        XMLOutStream: OutStream;
        XMLInStream: InStream;
        ResInStream: InStream;
    begin
        NavApp.GetResource(ResourceName, ResInStream);
        TempBlob.CreateOutStream(XMLOutStream);
        CopyStream(XMLOutStream, ResInStream);
        TempBlob.CreateInStream(XMLInStream);
        Xmlport.Import(Xmlport::"Imp / Exp Data Exch Def & Map", XMLInStream);
        Clear(TempBlob);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetEDOCDataExchUpdateTag());
        PerCompanyUpgradeTags.Add(GetEDOCDataExchV2UpdateTag());
    end;

    local procedure GetEDOCDataExchUpdateTag(): Code[250]
    begin
        exit('MS-365688-EDOCDataExchPEPPOL-20231113');
    end;

    local procedure GetEDOCDataExchV2UpdateTag(): Code[250]
    begin
        exit('MS-EDOCDataExchPEPPOLV2-20260414');
    end;

    var
        InvoiceImportResourceTok: Label 'DataExchange/eDocPEPPOLInvoiceImport.xml', Locked = true;
        CrMemoImportResourceTok: Label 'DataExchange/eDocPEPPOLCrMemoImport.xml', Locked = true;
        InvoiceImportV2ResourceTok: Label 'DataExchange/eDocPEPPOLInvoiceImportV2.xml', Locked = true;
        CrMemoImportV2ResourceTok: Label 'DataExchange/eDocPEPPOLCrMemoImportV2.xml', Locked = true;
        SalesInvoiceExportResourceTok: Label 'DataExchange/eDocPEPPOLSalesInvoiceExport.xml', Locked = true;
        SalesCrMemoExportResourceTok: Label 'DataExchange/eDocPEPPOLSalesCrMemoExport.xml', Locked = true;
        ServiceInvoiceExportResourceTok: Label 'DataExchange/eDocPEPPOLServiceInvoiceExport.xml', Locked = true;
        ServiceInvoiceExportNOResourceTok: Label 'DataExchange/eDocPEPPOLServiceInvoiceExportNO.xml', Locked = true;
        ServiceCrMemoExportResourceTok: Label 'DataExchange/eDocPEPPOLServiceCrMemoExport.xml', Locked = true;
        ServiceCrMemoExportNOResourceTok: Label 'DataExchange/eDocPEPPOLServiceCrMemoExportNO.xml', Locked = true;

}
