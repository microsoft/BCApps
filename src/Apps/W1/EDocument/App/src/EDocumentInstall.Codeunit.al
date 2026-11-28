// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.IO;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
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
    var
        EDocumentBackgroundJobs: Codeunit "E-Document Background Jobs";
    begin
        InsertDataExch();
        InsertDataExchV2();
        AddIncomingLegalIdentityMappings();
        EDocumentBackgroundJobs.EnsurePaymentOccurrenceDispatcher();
        HandleSupportedTypeDirectionUpgrade();
    end;

    local procedure HandleSupportedTypeDirectionUpgrade()
    var
        EDocumentUpgrade: Codeunit "E-Document Upgrade";
        UpgradeTag: Codeunit "Upgrade Tag";
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if CurrentModuleInfo.DataVersion() = Version.Create(0, 0, 0, 0) then begin
            if not UpgradeTag.HasUpgradeTag(EDocumentUpgrade.GetUpgradeSupportedTypeDirectionTag()) then
                UpgradeTag.SetUpgradeTag(EDocumentUpgrade.GetUpgradeSupportedTypeDirectionTag());
        end else
            EDocumentUpgrade.UpgradeSupportedTypeDirection();
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

    internal procedure AddIncomingLegalIdentityMappings()
    begin
        AddIncomingLegalIdentityMappings('EDOCPEPPOLINVIMP', 'PEPPOLINVHEADER', false);
        AddIncomingLegalIdentityMappings('EDOCPEPPOLCRMEMOIMP', 'PEPPOLCRMEMOHEADER', false);
        AddIncomingLegalIdentityMappings('EDOCPEPINVPURCHDRAFT', 'PEPPOLINVHEADER', true);
        AddIncomingLegalIdentityMappings('EDOCPEPCMPURCHDRAFT', 'PEPPOLCRMEMOHEADER', true);
    end;

    local procedure AddIncomingLegalIdentityMappings(DefinitionCode: Code[20]; LineCode: Code[20]; PurchaseDraft: Boolean)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        EDocument: Record "E-Document";
        Header: Record "E-Document Purchase Header";
        SupplierPath: Text;
        CustomerPath: Text;
    begin
        if not DataExchLineDef.Get(DefinitionCode, LineCode) then
            exit;
        if not (DataExchLineDef."Data Line Tag" in ['/Invoice', '/CreditNote']) then
            exit;
        if not DataExchMapping.Get(DefinitionCode, LineCode, Database::"Intermediate Data Import") then
            exit;
        if not DataExchMapping."Use as Intermediate Table" then
            exit;
        SupplierPath := DataExchLineDef."Data Line Tag" + '/cac:AccountingSupplierParty/cac:Party';
        CustomerPath := DataExchLineDef."Data Line Tag" + '/cac:AccountingCustomerParty/cac:Party';
        if PurchaseDraft then begin
            AddIncomingColumn(DataExchLineDef, 'InboundSupplierRegistrationNo', SupplierPath + '/cac:PartyLegalEntity/cbc:CompanyID', Database::"E-Document Purchase Header", Header.FieldNo("Vendor Registration No."));
            AddIncomingColumn(DataExchLineDef, 'InboundSupplierRegCountry', SupplierPath + '/cac:PostalAddress/cac:Country/cbc:IdentificationCode', Database::"E-Document Purchase Header", Header.FieldNo("Vendor Reg. Country/Region"));
            AddIncomingColumn(DataExchLineDef, 'InboundSupplierRegScheme', SupplierPath + '/cac:PartyLegalEntity/cbc:CompanyID/@schemeID', Database::"E-Document Purchase Header", Header.FieldNo("Vendor Reg. Scheme"));
            AddIncomingColumn(DataExchLineDef, 'InboundCustomerRegistrationNo', CustomerPath + '/cac:PartyLegalEntity/cbc:CompanyID', Database::"E-Document Purchase Header", Header.FieldNo("Customer Registration No."));
            AddIncomingColumn(DataExchLineDef, 'InboundCustomerRegCountry', CustomerPath + '/cac:PostalAddress/cac:Country/cbc:IdentificationCode', Database::"E-Document Purchase Header", Header.FieldNo("Customer Reg. Country/Region"));
            AddIncomingColumn(DataExchLineDef, 'InboundCustomerRegScheme', CustomerPath + '/cac:PartyLegalEntity/cbc:CompanyID/@schemeID', Database::"E-Document Purchase Header", Header.FieldNo("Customer Reg. Scheme"));
        end else begin
            AddIncomingColumn(DataExchLineDef, 'InboundSupplierRegistrationNo', SupplierPath + '/cac:PartyLegalEntity/cbc:CompanyID', Database::"E-Document", EDocument.FieldNo("Supplier Registration No."));
            AddIncomingColumn(DataExchLineDef, 'InboundSupplierRegCountry', SupplierPath + '/cac:PostalAddress/cac:Country/cbc:IdentificationCode', Database::"E-Document", EDocument.FieldNo("Supplier Reg. Country/Region"));
            AddIncomingColumn(DataExchLineDef, 'InboundSupplierRegScheme', SupplierPath + '/cac:PartyLegalEntity/cbc:CompanyID/@schemeID', Database::"E-Document", EDocument.FieldNo("Supplier Reg. Scheme"));
            AddIncomingColumn(DataExchLineDef, 'InboundCustomerRegistrationNo', CustomerPath + '/cac:PartyLegalEntity/cbc:CompanyID', Database::"E-Document", EDocument.FieldNo("Receiving Registration Number"));
            AddIncomingColumn(DataExchLineDef, 'InboundCustomerRegCountry', CustomerPath + '/cac:PostalAddress/cac:Country/cbc:IdentificationCode', Database::"E-Document", EDocument.FieldNo("Receiving Reg. Country/Region"));
            AddIncomingColumn(DataExchLineDef, 'InboundCustomerRegScheme', CustomerPath + '/cac:PartyLegalEntity/cbc:CompanyID/@schemeID', Database::"E-Document", EDocument.FieldNo("Receiving Reg. Scheme"));
        end;
        AddIncomingColumn(DataExchLineDef, 'InboundSupplierVATID', SupplierPath + '/cac:PartyTaxScheme[cac:TaxScheme/cbc:ID="VAT"]/cbc:CompanyID', 0, 0);
        AddIncomingColumn(DataExchLineDef, 'InboundCustomerVATID', CustomerPath + '/cac:PartyTaxScheme[cac:TaxScheme/cbc:ID="VAT"]/cbc:CompanyID', 0, 0);
        AddIncomingColumn(DataExchLineDef, 'InboundSupplierEndpointID', SupplierPath + '/cbc:EndpointID', 0, 0);
        AddIncomingColumn(DataExchLineDef, 'InboundSupplierEndpointScheme', SupplierPath + '/cbc:EndpointID/@schemeID', 0, 0);
    end;

    local procedure AddIncomingColumn(var DataExchLineDef: Record "Data Exch. Line Def"; ColumnName: Text[250]; ColumnPath: Text; TargetTable: Integer; TargetField: Integer)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        ColumnNo: Integer;
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.SetRange(Name, ColumnName);
        if DataExchColumnDef.FindFirst() then
            exit;

        DataExchColumnDef.SetRange(Name);
        if DataExchColumnDef.FindLast() then
            ColumnNo := DataExchColumnDef."Column No.";
        ColumnNo += 1;
        DataExchColumnDef.Init();
        DataExchColumnDef."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
        DataExchColumnDef."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchColumnDef."Column No." := ColumnNo;
        DataExchColumnDef.Name := ColumnName;
        DataExchColumnDef.Path := CopyStr(ColumnPath, 1, MaxStrLen(DataExchColumnDef.Path));
        DataExchColumnDef.Insert(true);
        if TargetTable <> 0 then begin
            DataExchFieldMapping.Init();
            DataExchFieldMapping."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
            DataExchFieldMapping."Data Exch. Line Def Code" := DataExchLineDef.Code;
            DataExchFieldMapping."Table ID" := Database::"Intermediate Data Import";
            DataExchFieldMapping."Column No." := ColumnNo;
            DataExchFieldMapping."Target Table ID" := TargetTable;
            DataExchFieldMapping."Target Field ID" := TargetField;
            DataExchFieldMapping.Optional := true;
            DataExchFieldMapping.Insert(true);
        end;
        if DataExchLineDef."Column Count" < ColumnNo then begin
            DataExchLineDef."Column Count" := ColumnNo;
            DataExchLineDef.Modify(true);
        end;
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
        case ResourceName of
            InvoiceImportResourceTok:
                AddIncomingLegalIdentityMappings('EDOCPEPPOLINVIMP', 'PEPPOLINVHEADER', false);
            CrMemoImportResourceTok:
                AddIncomingLegalIdentityMappings('EDOCPEPPOLCRMEMOIMP', 'PEPPOLCRMEMOHEADER', false);
            InvoiceImportV2ResourceTok:
                AddIncomingLegalIdentityMappings('EDOCPEPINVPURCHDRAFT', 'PEPPOLINVHEADER', true);
            CrMemoImportV2ResourceTok:
                AddIncomingLegalIdentityMappings('EDOCPEPCMPURCHDRAFT', 'PEPPOLCRMEMOHEADER', true);
        end;
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
