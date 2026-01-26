// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.CRM.Contact;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System;
using System.Environment;
using System.IO;
using System.Utilities;
using System.Xml;

codeunit 12182 "Datifattura Export"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    var
        XMLDoc: DotNet XmlDocument;
    begin
        if not Rec.isDatifattura() then
            exit;

        ErrorMessage.SetContext(Rec);
        ErrorMessage.ClearLog();

        CompanyInfo.Get();
        VATReportSetup.Get();

        case Rec."VAT Report Type" of
            Rec."VAT Report Type"::Standard:
                ExportStandardDatifattura(Rec);
            Rec."VAT Report Type"::"Cancellation ":
                begin
                    XMLDoc := XMLDoc.XmlDocument();
                    ExportCancellationDatifattura(Rec, XMLDoc);
                    SaveFileOnClient(XMLDoc, 'IT_%1_DF_%2.xml', Rec."No.");
                end
            else
                ;
        end;
    end;

    var
        CompanyInfo: Record "Company Information";
        VATReportSetup: Record "VAT Report Setup";
        ErrorMessage: Record "Error Message";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        XMLDOMManagement: Codeunit "XML DOM Management";
        DocumentTypes: Option TD01,TD04,TD05,TD07,TD08,TD10,TD11;
        TaxRepresentativeType: Option Customer,Vendor,Contact;
        ServerFilePath: Text;
        SaveXmlAsLbl: Label 'Save xml as...';
        StandardDatifatturaXmlnsXsAttrTxt: Label 'http://www.w3.org/2001/XMLSchema', Locked = true;
        StandardDatifatturaXmlnsDsAttrTxt: Label 'http://www.w3.org/2000/09/xmldsig#', Locked = true;
        StandardDatifatturaXmlnsNs2AttrTxt: Label 'http://ivaservizi.agenziaentrate.gov.it/docs/xsd/fatture/v2.0', Locked = true;
        DatifatturaExportLbl: Label 'DatifatturaExport.zip';

    local procedure SaveFileOnClient(XMLDoc: DotNet XmlDocument; FileFormat: Text; FileNameSuffix: Text)
    var
        FileManagement: Codeunit "File Management";
        SuggestedFileName: Text;
        ServerFilePathAlreadySet: Boolean;
    begin
        if ErrorMessage.HasErrors(false) then
            ErrorMessage.ShowErrorMessages(true);

        OnBeforeSaveFileOnClient(ServerFilePath);
        if ServerFilePath = '' then
            ServerFilePath := FileManagement.ServerTempFileName('xml')
        else
            ServerFilePathAlreadySet := true;

        XMLDoc.Save(ServerFilePath);
        SuggestedFileName := StrSubstNo(FileFormat, GetSubmitterID(), FileNameSuffix);
        if not ServerFilePathAlreadySet then
            TempNameValueBuffer.AddNewEntry(
              CopyStr(ServerFilePath, 1, MaxStrLen(TempNameValueBuffer.Name)),
              CopyStr(SuggestedFileName, 1, MaxStrLen(TempNameValueBuffer.Value)));

        OnAfterSaveFileOnClient(SuggestedFileName);
        ServerFilePath := '';
    end;

    local procedure SaveFileOnWebClient(FileNameCounter: Integer)
    var
        DataCompression: Codeunit "Data Compression";
        FileManagement: Codeunit "File Management";
        ClientTypeMgt: Codeunit "Client Type Management";
        TempBlob: Codeunit "Temp Blob";
        ServerTempFileInStream: InStream;
        ZipInStream: InStream;
        ZipOutStream: OutStream;
        ToFile: Text;
    begin
        if not (ClientTypeMgt.GetCurrentClientType() in [CLIENTTYPE::Web, CLIENTTYPE::Phone, CLIENTTYPE::Tablet, CLIENTTYPE::Desktop]) then
            exit;
        if FileNameCounter = 0 then
            exit;

        TempNameValueBuffer.FindSet();
        if FileNameCounter > 1 then begin
            DataCompression.CreateZipArchive();
            repeat
                FileManagement.BLOBImportFromServerFile(TempBlob, TempNameValueBuffer.Name);
                TempBlob.CreateInStream(ServerTempFileInStream);
                DataCompression.AddEntry(ServerTempFileInStream, TempNameValueBuffer.Value);
            until TempNameValueBuffer.Next() = 0;
            Clear(TempBlob);
            TempBlob.CreateOutStream(ZipOutStream);
            DataCompression.SaveZipArchive(ZipOutStream);
            DataCompression.CloseZipArchive();
            TempBlob.CreateInStream(ZipInStream);
            ToFile := DatifatturaExportLbl;
            DownloadFromStream(ZipInStream, '', '', '', ToFile);
        end else
            Download(TempNameValueBuffer.Name, SaveXmlAsLbl, '',
              FileManagement.GetToFilterText('', TempNameValueBuffer.Value), TempNameValueBuffer.Value);
    end;

    local procedure AddDatiFatturaNode(var XMLDoc: DotNet XmlDocument; var XMLRootNode: DotNet XmlNode)
    begin
        XMLDOMManagement.AddRootElementWithPrefix(XMLDoc, 'DatiFattura', 'ns2', StandardDatifatturaXmlnsNs2AttrTxt, XMLRootNode);
        XMLDOMManagement.AddDeclaration(XMLDoc, '1.0', 'utf-8', '');
        XMLDOMManagement.AddAttribute(XMLRootNode, 'xmlns:xs', StandardDatifatturaXmlnsXsAttrTxt);
        XMLDOMManagement.AddAttribute(XMLRootNode, 'xmlns:ds', StandardDatifatturaXmlnsDsAttrTxt);
        XMLDOMManagement.AddAttribute(XMLRootNode, 'versione', 'DAT20');
    end;

    local procedure ExportStandardDatifattura(VATReportHeader: Record "VAT Report Header")
    var
        VATReportLine: Record "VAT Report Line";
        DotNetXmlDocument: DotNet XmlDocument;
        XMLRootNode: DotNet XmlNode;
        DatiFatturaBodyDTEXmlNode: DotNet XmlNode;
        FileCounter: Integer;
        FileSuffix: Text;
        CessionarioCommittenteDTECount: Integer;
        CessionarioCommittenteDTELoopCouner: Integer;
        CessionarioCommittenteDTELoop: Integer;
        PrevDocumentType: Enum "Gen. Journal Document Type";
        PrevDocumentNo: Code[20];
        PrevBillToPayToNo: Code[20];
    begin
        VATReportLine.SetCurrentKey("Document Type", "Document No.", "Bill-to/Pay-to No.");
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.SetRange("Incl. in Report", true);

        VATReportLine.SetRange(Type, VATReportLine.Type::Sale);
        CessionarioCommittenteDTELoop := VATReportLine.Count div 1000;
        if VATReportLine.Count mod 1000 <> 0 then
            CessionarioCommittenteDTELoop += 1;
        if VATReportLine.FindSet() then
            for CessionarioCommittenteDTELoopCouner := 1 to CessionarioCommittenteDTELoop do begin
                InitDatiFatturaNode(DotNetXmlDocument, XMLRootNode);
                ExportStandardDatifatturaHeader(VATReportHeader, XMLRootNode);
                // DTE xml node
                // CedentePrestatoreDTE node
                ExportCompInfo(XMLRootNode, 'CedentePrestatoreDTE', 'DTE');
                PrevDocumentType := VATReportLine."Document Type"::" ";
                PrevDocumentNo := '';
                PrevBillToPayToNo := '';
                repeat
                    // CessionarioCommittenteDTE node
                    if (VATReportLine."Document Type" <> PrevDocumentType) or (VATReportLine."Document No." <> PrevDocumentNo) or
                       (VATReportLine."Bill-to/Pay-to No." <> PrevBillToPayToNo)
                    then begin
                        PrevDocumentType := VATReportLine."Document Type";
                        PrevDocumentNo := VATReportLine."Document No.";
                        PrevBillToPayToNo := VATReportLine."Bill-to/Pay-to No.";
                        ExportSaleInvoiceCustAndInvInfo(VATReportLine, XMLRootNode, DatiFatturaBodyDTEXmlNode);
                    end;
                    CessionarioCommittenteDTECount += 1;
                    AddInvoiceAmountsData(VATReportLine, DatiFatturaBodyDTEXmlNode);
                until (VATReportLine.Next() = 0) or (CessionarioCommittenteDTECount = 1000);
                CessionarioCommittenteDTECount := 0;
                FileCounter += 1;
                GetFileSuffix(FileCounter, CessionarioCommittenteDTELoopCouner, FileSuffix);
                SaveFileOnClient(DotNetXmlDocument, 'IT%1_DF_%2.xml', 'V000' + FileSuffix);
            end;

        VATReportLine.SetRange(Type, VATReportLine.Type::Purchase);
        CessionarioCommittenteDTELoop := VATReportLine.Count div 1000;
        if VATReportLine.Count mod 1000 <> 0 then
            CessionarioCommittenteDTELoop += 1;
        if VATReportLine.FindSet() then
            for CessionarioCommittenteDTELoopCouner := 1 to CessionarioCommittenteDTELoop do begin
                InitDatiFatturaNode(DotNetXmlDocument, XMLRootNode);
                ExportStandardDatifatturaHeader(VATReportHeader, XMLRootNode);
                // DTE xml node
                // CedentePrestatoreDTE node
                ExportCompInfo(XMLRootNode, 'CessionarioCommittenteDTR', 'DTR');
                PrevDocumentType := VATReportLine."Document Type"::" ";
                PrevDocumentNo := '';
                PrevBillToPayToNo := '';
                repeat
                    // CessionarioCommittenteDTE node
                    if (VATReportLine."Document Type" <> PrevDocumentType) or (VATReportLine."Document No." <> PrevDocumentNo) or
                       (VATReportLine."Bill-to/Pay-to No." <> PrevBillToPayToNo)
                    then begin
                        PrevDocumentType := VATReportLine."Document Type";
                        PrevDocumentNo := VATReportLine."Document No.";
                        PrevBillToPayToNo := VATReportLine."Bill-to/Pay-to No.";
                        ExportPurchInvoiceVendAndInvInfo(VATReportLine, XMLRootNode, DatiFatturaBodyDTEXmlNode);
                    end;
                    CessionarioCommittenteDTECount += 1;
                    AddInvoiceAmountsData(VATReportLine, DatiFatturaBodyDTEXmlNode);
                until (VATReportLine.Next() = 0) or (CessionarioCommittenteDTECount = 1000);
                CessionarioCommittenteDTECount := 0;
                FileCounter += 1;
                GetFileSuffix(FileCounter, CessionarioCommittenteDTELoopCouner, FileSuffix);
                SaveFileOnClient(DotNetXmlDocument, 'IT%1_DF_%2.xml', '0000' + FileSuffix);
            end;

        SaveFileOnWebClient(FileCounter);
    end;

    local procedure ExportStandardDatifatturaHeader(VATReportHeader: Record "VAT Report Header"; var XMLRootNode: DotNet XmlNode)
    var
        SpesometroAppointment: Record "Spesometro Appointment";
        SpesometroVendor: Record Vendor;
        DatiFatturaHdrXmlNode: DotNet XmlNode;
        DichiaranteXmlNode: DotNet XmlNode;
        XmlNode: DotNet XmlNode;
        CodiceFiscale: Text;
        Carica: Text;
    begin
        if not SpesometroAppointment.FindAppointmentByDate(VATReportHeader."Start Date", VATReportHeader."End Date") then
            exit;

        if SpesometroVendor.Get(SpesometroAppointment."Vendor No.") then
            CodiceFiscale := SpesometroVendor."Fiscal Code";

        Carica := SpesometroAppointment."Appointment Code";

        XMLDOMManagement.AddElement(XMLRootNode, 'DatiFatturaHeader', '', '', DatiFatturaHdrXmlNode);

        // 1.1 ProgressivoInvio
        XMLDOMManagement.AddElement(DatiFatturaHdrXmlNode, 'ProgressivoInvio', VATReportHeader."No.", '', DichiaranteXmlNode);

        // 1.2 Dichiarante
        XMLDOMManagement.AddElement(DatiFatturaHdrXmlNode, 'Dichiarante', '', '', DichiaranteXmlNode);
        XMLDOMManagement.AddElement(DichiaranteXmlNode, 'CodiceFiscale', CodiceFiscale, '', XmlNode);
        XMLDOMManagement.AddElement(DichiaranteXmlNode, 'Carica', Carica, '', XmlNode);
    end;

    local procedure ExportCompInfo(var DTEXmlNode: DotNet XmlNode; NodeName: Text; DTENodeName: Text)
    var
        CedentePrestatoreDTEXmlNode: DotNet XmlNode;
        AltriDatiIdentificativiXmlNode: DotNet XmlNode;
        XmlNode: DotNet XmlNode;
    begin
        // DTE node
        XMLDOMManagement.AddElement(DTEXmlNode, DTENodeName, '', '', DTEXmlNode);

        // CedentePrestatoreDTE node
        XMLDOMManagement.AddElement(DTEXmlNode, NodeName, '', '', CedentePrestatoreDTEXmlNode);

        // IdentificativiFiscali node
        ExportCompInfoTaxDtl(CedentePrestatoreDTEXmlNode);

        // AltriDatiIdentificativi node
        XMLDOMManagement.AddElement(CedentePrestatoreDTEXmlNode, 'AltriDatiIdentificativi', '', '', AltriDatiIdentificativiXmlNode);
        XMLDOMManagement.AddElement(AltriDatiIdentificativiXmlNode, 'Denominazione', CompanyInfo.Name, '', XmlNode);
        AddCompAddress(AltriDatiIdentificativiXmlNode);
        if CompanyInfo."Tax Representative No." <> '' then
            AddTaxRepresentativeInfo(AltriDatiIdentificativiXmlNode, CompanyInfo."Tax Representative No.", TaxRepresentativeType::Vendor);
    end;

    local procedure ExportCompInfoTaxDtl(var CedentePrestatoreDTEXmlNode: DotNet XmlNode)
    var
        IdentificativiFiscaliXmlNode: DotNet XmlNode;
        IdFiscaleIVAXmlNode: DotNet XmlNode;
        XmlNode: DotNet XmlNode;
    begin
        XMLDOMManagement.AddElement(CedentePrestatoreDTEXmlNode, 'IdentificativiFiscali', '', '', IdentificativiFiscaliXmlNode);

        // IdFiscaleIVA node
        XMLDOMManagement.AddElement(IdentificativiFiscaliXmlNode, 'IdFiscaleIVA', '', '', IdFiscaleIVAXmlNode);
        XMLDOMManagement.AddElement(IdFiscaleIVAXmlNode, 'IdPaese', 'IT', '', XmlNode);
        XMLDOMManagement.AddElement(IdFiscaleIVAXmlNode, 'IdCodice', CompanyInfo."VAT Registration No.", '', XmlNode);

        // CodiceFiscale node
        XMLDOMManagement.AddElement(IdentificativiFiscaliXmlNode, 'CodiceFiscale', CompanyInfo."Fiscal Code", '', XmlNode);
    end;

    local procedure AddCompAddress(var CompanyXmlNode: DotNet XmlNode)
    var
        AddressXmlNode: DotNet XmlNode;
        XmlNode: DotNet XmlNode;
    begin
        XMLDOMManagement.AddElement(CompanyXmlNode, 'Sede', '', '', AddressXmlNode);

        XMLDOMManagement.AddElement(AddressXmlNode, 'Indirizzo', CompanyInfo.Address, '', XmlNode);
        if CompanyInfo."Post Code" <> '' then
            XMLDOMManagement.AddElement(AddressXmlNode, 'CAP', CompanyInfo."Post Code", '', XmlNode);

        XMLDOMManagement.AddElement(AddressXmlNode, 'Comune', CompanyInfo.City, '', XmlNode);
        if CompanyInfo.County <> '' then
            XMLDOMManagement.AddElement(AddressXmlNode, 'Provincia', CompanyInfo.County, '', XmlNode);
        XMLDOMManagement.AddElement(AddressXmlNode, 'Nazione', CompanyInfo."Country/Region Code", '', XmlNode);
    end;

    local procedure ExportSaleInvoiceCustAndInvInfo(VATReportLine: Record "VAT Report Line"; var DTEXmlNode: DotNet XmlNode; var DatiFatturaBodyDTEXmlNode: DotNet XmlNode)
    var
        CessionarioCommittenteDTEXmlNode: DotNet XmlNode;
        DocumentType: Text;
    begin
        if VATReportLine."Bill-to/Pay-to No." = '' then
            exit;

        // CessionarioCommittenteDTE node
        XMLDOMManagement.AddElement(DTEXmlNode, 'CessionarioCommittenteDTE', '', '', CessionarioCommittenteDTEXmlNode);

        DocumentType := GetDocumentType(VATReportLine);

        // IdentificativiFiscali node
        if (DocumentType <> Format(DocumentTypes::TD07)) and (DocumentType <> Format(DocumentTypes::TD08)) then
            ExportSaleInvoiceCustInfoTaxDtl(VATReportLine, CessionarioCommittenteDTEXmlNode);

        // AltriDatiIdentificativi node
        ExportSaleInvoiceCustInfoCustDtl(VATReportLine, CessionarioCommittenteDTEXmlNode);

        // 2.2.3 DatiFatturaBodyDTE node
        ExportSaleInvoiceData(VATReportLine, CessionarioCommittenteDTEXmlNode, DatiFatturaBodyDTEXmlNode);
    end;

    local procedure ExportSaleInvoiceCustInfoTaxDtl(VATReportLine: Record "VAT Report Line"; var CessionarioCommittenteDTEXmlNode: DotNet XmlNode) Valued: Boolean
    var
        Customer: Record Customer;
        IdentificativiFiscaliXmlNode: DotNet XmlNode;
        IdFiscaleIVAXmlNode: DotNet XmlNode;
        XmlNode: DotNet XmlNode;
    begin
        XMLDOMManagement.AddElement(CessionarioCommittenteDTEXmlNode, 'IdentificativiFiscali', '', '', IdentificativiFiscaliXmlNode);
        Valued := false;

        if not GetCustomerForVATReportLine(Customer, VATReportLine) then
            exit;

        if (Customer."VAT Registration No." = '') and (Customer."Fiscal Code" = '') then
            if Customer."Individual Person" then
                ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("Fiscal Code"), ErrorMessage."Message Type"::Error)
            else
                ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("VAT Registration No."), ErrorMessage."Message Type"::Error);

        // IdFiscaleIVA node
        if Customer."VAT Registration No." <> '' then begin
            XMLDOMManagement.AddElement(IdentificativiFiscaliXmlNode, 'IdFiscaleIVA', '', '', IdFiscaleIVAXmlNode);

            ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
            XMLDOMManagement.AddElement(IdFiscaleIVAXmlNode, 'IdPaese', Customer."Country/Region Code", '', XmlNode);

            XMLDOMManagement.AddElement(IdFiscaleIVAXmlNode, 'IdCodice', Customer."VAT Registration No.", '', XmlNode);
            Valued := true;
        end;

        // CodiceFiscale node
        if Customer."Country/Region Code" = 'IT' then begin
            XMLDOMManagement.AddElement(IdentificativiFiscaliXmlNode, 'CodiceFiscale', Customer."Fiscal Code", '', XmlNode);
            Valued := true;
        end;
    end;

    local procedure ExportSaleInvoiceCustInfoCustDtl(VATReportLine: Record "VAT Report Line"; var CessionarioCommittenteDTEXmlNode: DotNet XmlNode)
    var
        Customer: Record Customer;
        AltriDatiIdentificativiXmlNode: DotNet XmlNode;
        XmlNode: DotNet XmlNode;
    begin
        XMLDOMManagement.AddElement(CessionarioCommittenteDTEXmlNode, 'AltriDatiIdentificativi', '', '', AltriDatiIdentificativiXmlNode);

        if not GetCustomerForVATReportLine(Customer, VATReportLine) then
            exit;

        if not Customer."Individual Person" then
            XMLDOMManagement.AddElement(AltriDatiIdentificativiXmlNode, 'Denominazione', Customer.Name, '', XmlNode)
        else begin
            ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("First Name"), ErrorMessage."Message Type"::Error);
            XMLDOMManagement.AddElement(AltriDatiIdentificativiXmlNode, 'Nome', Customer."First Name", '', XmlNode);

            ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("Last Name"), ErrorMessage."Message Type"::Error);
            XMLDOMManagement.AddElement(AltriDatiIdentificativiXmlNode, 'Cognome', Customer."Last Name", '', XmlNode);
        end;

        AddCustAddress(Customer, AltriDatiIdentificativiXmlNode);

        if Customer."Tax Representative No." <> '' then
            if Customer."Tax Representative Type" = Customer."Tax Representative Type"::Customer then
                AddTaxRepresentativeInfo(AltriDatiIdentificativiXmlNode, Customer."Tax Representative No.", TaxRepresentativeType::Customer)
            else
                AddTaxRepresentativeInfo(AltriDatiIdentificativiXmlNode, Customer."Tax Representative No.", TaxRepresentativeType::Contact);
    end;

    local procedure GetCustomerForVATReportLine(var Customer: Record Customer; VATReportLine: Record "VAT Report Line") CustomerExists: Boolean
    begin
        CustomerExists := Customer.Get(VATReportLine."Bill-to/Pay-to No.");
        OnAfterGetCustomerForVATReportLine(Customer, VATReportLine, CustomerExists);
    end;

    local procedure AddCustAddress(Customer: Record Customer; var AltriDatiIdentificativiXmlNode: DotNet XmlNode)
    var
        AddressXmlNode: DotNet XmlNode;
        XmlNode: DotNet XmlNode;
        IsResident: Boolean;
    begin
        IsResident := Customer.Resident = Customer.Resident::Resident;
        if IsResident then
            XMLDOMManagement.AddElement(AltriDatiIdentificativiXmlNode, 'Sede', '', '', AddressXmlNode)
        else
            XMLDOMManagement.AddElement(AltriDatiIdentificativiXmlNode, 'StabileOrganizzazione', '', '', AddressXmlNode);

        ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo(Address), ErrorMessage."Message Type"::Error);
        XMLDOMManagement.AddElement(AddressXmlNode, 'Indirizzo', Customer.Address, '', XmlNode);

        if (not IsResident) or (Customer."Post Code" <> '') then begin
            ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("Post Code"), ErrorMessage."Message Type"::Error);
            XMLDOMManagement.AddElement(AddressXmlNode, 'CAP', Customer."Post Code", '', XmlNode);
        end;

        ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo(City), ErrorMessage."Message Type"::Error);
        XMLDOMManagement.AddElement(AddressXmlNode, 'Comune', Customer.City, '', XmlNode);

        if Customer.County <> '' then
            XMLDOMManagement.AddElement(AddressXmlNode, 'Provincia', Customer.County, '', XmlNode)
        else
            ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo(County), ErrorMessage."Message Type"::Warning);

        ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
        XMLDOMManagement.AddElement(AddressXmlNode, 'Nazione', Customer."Country/Region Code", '', XmlNode);
    end;

    local procedure ExportSaleInvoiceData(VATReportLine: Record "VAT Report Line"; var CessionarioCommittenteDTEXmlNode: DotNet XmlNode; var DatiFatturaBodyDTEXmlNode: DotNet XmlNode)
    var
        VATEntry: Record "VAT Entry";
        DatiGeneraliXmlNode: DotNet XmlNode;
        XmlNode: DotNet XmlNode;
    begin
        XMLDOMManagement.AddElement(CessionarioCommittenteDTEXmlNode, 'DatiFatturaBodyDTE', '', '', DatiFatturaBodyDTEXmlNode);

        // 2.2.3.1 DatiGenerali node
        XMLDOMManagement.AddElement(DatiFatturaBodyDTEXmlNode, 'DatiGenerali', '', '', DatiGeneraliXmlNode);
        XMLDOMManagement.AddElement(DatiGeneraliXmlNode, 'TipoDocumento', GetDocumentType(VATReportLine), '', XmlNode);
        VATEntry.Get(VATReportLine."VAT Entry No.");
        XMLDOMManagement.AddElement(DatiGeneraliXmlNode, 'Data', FormatDate(VATEntry."Document Date"), '', XmlNode);
        XMLDOMManagement.AddElement(DatiGeneraliXmlNode, 'Numero', GetAlphanumericValue(VATReportLine."Document No."), '', XmlNode);
    end;

    local procedure ExportPurchInvoiceVendAndInvInfo(VATReportLine: Record "VAT Report Line"; var DTRXmlNode: DotNet XmlNode; var DatiFatturaBodyDTEXmlNode: DotNet XmlNode)
    var
        CedentePrestatoreDTRXmlNode: DotNet XmlNode;
    begin
        if VATReportLine."Bill-to/Pay-to No." = '' then
            exit;

        // 3.2 CedentePrestatoreDTR node
        XMLDOMManagement.AddElement(DTRXmlNode, 'CedentePrestatoreDTR', '', '', CedentePrestatoreDTRXmlNode);

        // 3.2.1 IdentificativiFiscali node
        ExportPurchInvoiceVendInfoTaxDtl(VATReportLine, CedentePrestatoreDTRXmlNode);

        // 3.2.2 AltriDatiIdentificativi node
        ExportPurchInvoiceVendInfoVendDtl(VATReportLine, CedentePrestatoreDTRXmlNode);

        // 3.2.3 DatiFatturaBodyDTR node
        ExportPurchInvoiceData(VATReportLine, CedentePrestatoreDTRXmlNode, DatiFatturaBodyDTEXmlNode);
    end;

    local procedure ExportPurchInvoiceVendInfoTaxDtl(VATReportLine: Record "VAT Report Line"; var CedentePrestatoreDTRXmlNode: DotNet XmlNode)
    var
        Vendor: Record Vendor;
        IdentificativiFiscaliXmlNode: DotNet XmlNode;
        IdFiscaleIVAXmlNode: DotNet XmlNode;
        XmlNode: DotNet XmlNode;
        VendorNo: Code[20];
    begin
        XMLDOMManagement.AddElement(CedentePrestatoreDTRXmlNode, 'IdentificativiFiscali', '', '', IdentificativiFiscaliXmlNode);

        VendorNo := GetVendorNoForIdentificativiFiscali(VATReportLine);
        if not GetVendorForVATReportLine(Vendor, VendorNo, VATReportLine) then
            exit;

        // IdFiscaleIVA node
        XMLDOMManagement.AddElement(IdentificativiFiscaliXmlNode, 'IdFiscaleIVA', '', '', IdFiscaleIVAXmlNode);

        ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
        XMLDOMManagement.AddElement(IdFiscaleIVAXmlNode, 'IdPaese', Vendor."Country/Region Code", '', XmlNode);

        if Vendor.GetTaxCode() = '' then
            if Vendor."Individual Person" then
                ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("Fiscal Code"), ErrorMessage."Message Type"::Error)
            else
                ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("VAT Registration No."), ErrorMessage."Message Type"::Error);
        if Vendor."VAT Registration No." <> '' then
            XMLDOMManagement.AddElement(IdFiscaleIVAXmlNode, 'IdCodice', Vendor."VAT Registration No.", '', XmlNode);

        // CodiceFiscale node
        if Vendor."Individual Person" and (Vendor."Country/Region Code" = 'IT') then
            ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("Fiscal Code"), ErrorMessage."Message Type"::Warning);
        if Vendor."Fiscal Code" <> '' then
            XMLDOMManagement.AddElement(IdentificativiFiscaliXmlNode, 'CodiceFiscale', Vendor."Fiscal Code", '', XmlNode);
    end;

    local procedure ExportPurchInvoiceVendInfoVendDtl(VATReportLine: Record "VAT Report Line"; var CedentePrestatoreDTRXmlNode: DotNet XmlNode)
    var
        Vendor: Record Vendor;
        AltriDatiIdentificativiXmlNode: DotNet XmlNode;
        XmlNode: DotNet XmlNode;
    begin
        XMLDOMManagement.AddElement(CedentePrestatoreDTRXmlNode, 'AltriDatiIdentificativi', '', '', AltriDatiIdentificativiXmlNode);

        if not GetVendorForVATReportLine(Vendor, VATReportLine."Bill-to/Pay-to No.", VATReportLine) then
            exit;

        if not Vendor."Individual Person" then
            XMLDOMManagement.AddElement(AltriDatiIdentificativiXmlNode, 'Denominazione', Vendor.Name, '', XmlNode)
        else begin
            ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("First Name"), ErrorMessage."Message Type"::Error);
            XMLDOMManagement.AddElement(AltriDatiIdentificativiXmlNode, 'Nome', Vendor."First Name", '', XmlNode);

            ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("Last Name"), ErrorMessage."Message Type"::Error);
            XMLDOMManagement.AddElement(AltriDatiIdentificativiXmlNode, 'Cognome', Vendor."Last Name", '', XmlNode);
        end;

        AddVendAddress(Vendor, AltriDatiIdentificativiXmlNode);

        if Vendor."Tax Representative No." <> '' then
            if Vendor."Tax Representative Type" = Vendor."Tax Representative Type"::Vendor then
                AddTaxRepresentativeInfo(AltriDatiIdentificativiXmlNode, Vendor."Tax Representative No.", TaxRepresentativeType::Vendor)
            else
                AddTaxRepresentativeInfo(AltriDatiIdentificativiXmlNode, Vendor."Tax Representative No.", TaxRepresentativeType::Contact);
    end;

    local procedure GetVendorForVATReportLine(var Vendor: Record Vendor; VendorNo: Code[20]; VATReportLine: Record "VAT Report Line") VendorExists: Boolean
    begin
        VendorExists := Vendor.Get(VendorNo);
        OnAfterGetVendorForVATReportLine(Vendor, VendorNo, VATReportLine, VendorExists);
    end;

    local procedure AddVendAddress(Vendor: Record Vendor; var AltriDatiIdentificativiXmlNode: DotNet XmlNode)
    var
        AddressXmlNode: DotNet XmlNode;
        XmlNode: DotNet XmlNode;
        IsResident: Boolean;
    begin
        IsResident := Vendor.Resident = Vendor.Resident::Resident;
        if IsResident then
            XMLDOMManagement.AddElement(AltriDatiIdentificativiXmlNode, 'Sede', '', '', AddressXmlNode)
        else
            XMLDOMManagement.AddElement(AltriDatiIdentificativiXmlNode, 'StabileOrganizzazione', '', '', AddressXmlNode);

        XMLDOMManagement.AddElement(AddressXmlNode, 'Indirizzo', Vendor.Address, '', XmlNode);
        if (not IsResident) or (Vendor."Post Code" <> '') then begin
            ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("Post Code"), ErrorMessage."Message Type"::Error);
            if Vendor."Country/Region Code" <> 'IT' then
                XMLDOMManagement.AddElement(AddressXmlNode, 'CAP', '00000', '', XmlNode)
            else
                XMLDOMManagement.AddElement(AddressXmlNode, 'CAP', Vendor."Post Code", '', XmlNode);
        end;

        ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo(City), ErrorMessage."Message Type"::Error);
        XMLDOMManagement.AddElement(AddressXmlNode, 'Comune', Vendor.City, '', XmlNode);

        if Vendor.County <> '' then
            XMLDOMManagement.AddElement(AddressXmlNode, 'Provincia', Vendor.County, '', XmlNode)
        else
            ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo(County), ErrorMessage."Message Type"::Warning);

        ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
        XMLDOMManagement.AddElement(AddressXmlNode, 'Nazione', Vendor."Country/Region Code", '', XmlNode);
    end;

    local procedure ExportPurchInvoiceData(VATReportLine: Record "VAT Report Line"; var CedentePrestatoreDTRXmlNode: DotNet XmlNode; var DatiFatturaBodyDTEXmlNode: DotNet XmlNode)
    var
        VATEntry: Record "VAT Entry";
        DatiGeneraliXmlNode: DotNet XmlNode;
        XmlNode: DotNet XmlNode;
    begin
        XMLDOMManagement.AddElement(CedentePrestatoreDTRXmlNode, 'DatiFatturaBodyDTR', '', '', DatiFatturaBodyDTEXmlNode);

        // 2.2.3.1 DatiGenerali node
        XMLDOMManagement.AddElement(DatiFatturaBodyDTEXmlNode, 'DatiGenerali', '', '', DatiGeneraliXmlNode);
        XMLDOMManagement.AddElement(DatiGeneraliXmlNode, 'TipoDocumento', GetDocumentType(VATReportLine), '', XmlNode);
        VATEntry.Get(VATReportLine."VAT Entry No.");
        XMLDOMManagement.AddElement(DatiGeneraliXmlNode, 'Data', FormatDate(VATEntry."Document Date"), '', XmlNode);
        XMLDOMManagement.AddElement(DatiGeneraliXmlNode, 'Numero', GetAlphanumericValue(VATReportLine."Document No."), '', XmlNode);
        XMLDOMManagement.AddElement(DatiGeneraliXmlNode, 'DataRegistrazione', FormatDate(VATReportLine."Posting Date"), '', XmlNode);
    end;

    local procedure AddInvoiceAmountsData(VATReportLine: Record "VAT Report Line"; var InvoiceXmlNode: DotNet XmlNode)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DatiRiepilogoXmlNode: DotNet XmlNode;
        DatiIVAXmlNode: DotNet XmlNode;
        XmlNode: DotNet XmlNode;
        DocumentType: Text;
        IsHandled: Boolean;
    begin
        // 2.2.3.2 DatiRiepilogo node
        XMLDOMManagement.AddElement(InvoiceXmlNode, 'DatiRiepilogo', '', '', DatiRiepilogoXmlNode);

        DocumentType := GetDocumentType(VATReportLine);

        if (DocumentType = Format(DocumentTypes::TD07)) or (DocumentType = Format(DocumentTypes::TD08)) then
            XMLDOMManagement.AddElement(
              DatiRiepilogoXmlNode, 'ImponibileImporto', FormatAmount(Abs(VATReportLine."Amount Incl. VAT")), '', XmlNode)
        else
            XMLDOMManagement.AddElement(DatiRiepilogoXmlNode, 'ImponibileImporto', FormatAmount(Abs(VATReportLine.Base)), '', XmlNode);

        IsHandled := false;
        OnAddInvoiceAmountsDataOnBeforeGetVATPostingSetup(VATReportLine, XMLDOMManagement, IsHandled);
        if not IsHandled then
            if VATPostingSetup.Get(VATReportLine."VAT Bus. Posting Group", VATReportLine."VAT Prod. Posting Group") then begin
                // DatiIVA
                OnAddInvoiceAmountsDataOnAfterVATPostingSetupGet(VATPostingSetup, VATReportLine);
                XMLDOMManagement.AddElement(DatiRiepilogoXmlNode, 'DatiIVA', '', '', DatiIVAXmlNode);
                XMLDOMManagement.AddElement(DatiIVAXmlNode, 'Imposta', FormatAmount(Abs(VATReportLine.Amount)), '', XmlNode);
                XMLDOMManagement.AddElement(DatiIVAXmlNode, 'Aliquota', FormatAmount(VATPostingSetup."VAT %"), '', XmlNode);

                if (VATReportLine.Amount = 0) or
                (VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT")
                then
                    XMLDOMManagement.AddElement(DatiRiepilogoXmlNode, 'Natura', VATReportLine."VAT Transaction Nature", '', XmlNode);
            end;

        AddEsigibilitaIVATag(DatiRiepilogoXmlNode, XmlNode, VATReportLine);
    end;

    local procedure AddTaxRepresentativeInfo(var CurrentXmlNode: DotNet XmlNode; TaxRepresentativeNo: Code[20]; RepresentativeType: Option)
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Contact: Record Contact;
        RappresentanteFiscaleXmlNode: DotNet XmlNode;
        IdFiscaleIVAXmlNode: DotNet XmlNode;
        XmlNode: DotNet XmlNode;
    begin
        XMLDOMManagement.AddElement(CurrentXmlNode, 'RappresentanteFiscale', '', '', RappresentanteFiscaleXmlNode);
        case RepresentativeType of
            TaxRepresentativeType::Customer:
                begin
                    Customer.Get(TaxRepresentativeNo);

                    XMLDOMManagement.AddElement(RappresentanteFiscaleXmlNode, 'IdFiscaleIVA', '', '', IdFiscaleIVAXmlNode);

                    ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
                    XMLDOMManagement.AddElement(IdFiscaleIVAXmlNode, 'IdPaese', Customer."Country/Region Code", '', XmlNode);

                    ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("VAT Registration No."), ErrorMessage."Message Type"::Error);
                    XMLDOMManagement.AddElement(IdFiscaleIVAXmlNode, 'IdCodice', Customer."VAT Registration No.", '', XmlNode);

                    if not Customer."Individual Person" then
                        XMLDOMManagement.AddElement(RappresentanteFiscaleXmlNode, 'Denominazione', Customer.Name, '', XmlNode)
                    else begin
                        ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("First Name"), ErrorMessage."Message Type"::Error);
                        XMLDOMManagement.AddElement(RappresentanteFiscaleXmlNode, 'Nome', Customer."First Name", '', XmlNode);

                        ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("Last Name"), ErrorMessage."Message Type"::Error);
                        XMLDOMManagement.AddElement(RappresentanteFiscaleXmlNode, 'Cognome', Customer."Last Name", '', XmlNode);
                    end;
                end;
            TaxRepresentativeType::Vendor:
                begin
                    Vendor.Get(TaxRepresentativeNo);

                    XMLDOMManagement.AddElement(RappresentanteFiscaleXmlNode, 'IdFiscaleIVA', '', '', IdFiscaleIVAXmlNode);

                    ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
                    XMLDOMManagement.AddElement(IdFiscaleIVAXmlNode, 'IdPaese', Vendor."Country/Region Code", '', XmlNode);

                    ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("VAT Registration No."), ErrorMessage."Message Type"::Error);
                    XMLDOMManagement.AddElement(IdFiscaleIVAXmlNode, 'IdCodice', Vendor."VAT Registration No.", '', XmlNode);

                    if not Vendor."Individual Person" then
                        XMLDOMManagement.AddElement(RappresentanteFiscaleXmlNode, 'Denominazione', Vendor.Name, '', XmlNode)
                    else begin
                        ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("First Name"), ErrorMessage."Message Type"::Error);
                        XMLDOMManagement.AddElement(RappresentanteFiscaleXmlNode, 'Nome', Vendor."First Name", '', XmlNode);

                        ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("Last Name"), ErrorMessage."Message Type"::Error);
                        XMLDOMManagement.AddElement(RappresentanteFiscaleXmlNode, 'Cognome', Vendor."Last Name", '', XmlNode);
                    end;
                end;
            TaxRepresentativeType::Contact:
                begin
                    Contact.Get(TaxRepresentativeNo);

                    XMLDOMManagement.AddElement(RappresentanteFiscaleXmlNode, 'IdFiscaleIVA', '', '', IdFiscaleIVAXmlNode);

                    ErrorMessage.LogIfEmpty(Contact, Contact.FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
                    XMLDOMManagement.AddElement(IdFiscaleIVAXmlNode, 'IdPaese', Contact."Country/Region Code", '', XmlNode);
                    if Contact.Type = Contact.Type::Company then begin
                        ErrorMessage.LogIfEmpty(Contact, Contact.FieldNo("VAT Registration No."), ErrorMessage."Message Type"::Error);
                        XMLDOMManagement.AddElement(IdFiscaleIVAXmlNode, 'IdCodice', Contact."VAT Registration No.", '', XmlNode);
                    end else begin
                        ErrorMessage.LogIfEmpty(Contact, Contact.FieldNo("First Name"), ErrorMessage."Message Type"::Error);
                        XMLDOMManagement.AddElement(RappresentanteFiscaleXmlNode, 'Nome', Contact."First Name", '', XmlNode);

                        ErrorMessage.LogIfEmpty(Contact, Contact.FieldNo(Surname), ErrorMessage."Message Type"::Error);
                        XMLDOMManagement.AddElement(RappresentanteFiscaleXmlNode, 'Cognome', Contact.Surname, '', XmlNode);
                    end;
                end;
            else
                ;
        end;
    end;

    local procedure InitDatiFatturaNode(var DotNetXmlDocument: DotNet XmlDocument; var XMLRootNode: DotNet XmlNode)
    begin
        Clear(DotNetXmlDocument);
        Clear(XMLRootNode);
        DotNetXmlDocument := DotNetXmlDocument.XmlDocument();
        AddDatiFatturaNode(DotNetXmlDocument, XMLRootNode);
    end;

    local procedure AddEsigibilitaIVATag(var DatiRiepilogoXmlNode: DotNet XmlNode; var XmlNode: DotNet XmlNode; VATReportLine: Record "VAT Report Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TagValue: Text;
    begin
        if (VATReportLine.Base <> 0) and (VATReportLine."Unrealized Base" = 0) then
            TagValue := 'I'
        else
            if (VATReportLine.Base = 0) and (VATReportLine."Unrealized Base" <> 0) then
                TagValue := 'D'
            else
                if (VATReportLine.Base <> 0) and (VATReportLine."Unrealized Base" <> 0) then
                    TagValue := 'S';

        if FindSplitFullVATVATPostingSetup(VATPostingSetup, VATReportLine) then
            if FindSplitFullVATVATEntry(VATReportLine, VATPostingSetup) then
                TagValue := 'S';

        if TagValue <> '' then
            XMLDOMManagement.AddElement(DatiRiepilogoXmlNode, 'EsigibilitaIVA', TagValue, '', XmlNode);
    end;

    local procedure ExportCancellationDatifattura(VATReportHeader: Record "VAT Report Header"; var XMLDoc: DotNet XmlDocument)
    var
        XMLRootNode: DotNet XmlNode;
        ANNXmlNode: DotNet XmlNode;
        XmlNode: DotNet XmlNode;
    begin
        XMLDOMManagement.AddRootElement(XMLDoc, 'DatiFattura', XMLRootNode);
        XMLDOMManagement.AddDeclaration(XMLDoc, '1.0', 'utf-8', '');

        // 1 DatiFatturaHeader
        ExportStandardDatifatturaHeader(VATReportHeader, XMLRootNode);

        // 4 ANN node
        XMLDOMManagement.AddElement(XMLRootNode, 'ANN', '', '', ANNXmlNode);
        // 4.1 IdFile node
        XMLDOMManagement.AddElement(ANNXmlNode, 'IdFile', VATReportHeader."Original Report No.", '', XmlNode);
    end;

    local procedure GetSubmitterID(): Text
    var
        TaxRepresentativeVendor: Record Vendor;
    begin
        if CompanyInfo."Tax Representative No." = '' then
            exit(CompanyInfo."VAT Registration No.");

        if TaxRepresentativeVendor.Get(CompanyInfo."Tax Representative No.") then begin
            if TaxRepresentativeVendor."Individual Person" then
                exit(TaxRepresentativeVendor."Fiscal Code");
            exit(TaxRepresentativeVendor."VAT Registration No.");
        end;

        exit(CompanyInfo."VAT Registration No.");
    end;

    local procedure FindSplitFullVATVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATReportLine: Record "VAT Report Line"): Boolean
    var
        NormalVATEntry: Record "VAT Entry";
    begin
        if (VATReportLine.Base = 0) or (VATReportLine.Amount = 0) then
            exit(false);

        NormalVATEntry.Get(VATReportLine."VAT Entry No.");
        VATPostingSetup.SetRange("Reversed VAT Bus. Post. Group", NormalVATEntry."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("Reversed VAT Prod. Post. Group", NormalVATEntry."VAT Prod. Posting Group");
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Full VAT");
        exit(VATPostingSetup.FindFirst())
    end;

    local procedure FindSplitFullVATVATEntry(VATReportLine: Record "VAT Report Line"; VATPostingSetup: Record "VAT Posting Setup"): Boolean
    var
        VATEntry: Record "VAT Entry";
        NormalVATEntry: Record "VAT Entry";
    begin
        NormalVATEntry.Get(VATReportLine."VAT Entry No.");
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.SetRange("VAT Calculation Type", VATEntry."VAT Calculation Type"::"Full VAT");
        VATEntry.SetRange("Transaction No.", NormalVATEntry."Transaction No.");
        VATEntry.SetRange(Amount, -NormalVATEntry.Amount);
        exit(VATEntry.FindFirst())
    end;

    local procedure FormatDate(InputDate: Date): Text
    begin
        exit(Format(InputDate, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,9>'))
    end;

    local procedure GetAlphanumericValue(Value: Text) AlphanumericValue: Text
    var
        Char: Char;
        i: Integer;
    begin
        for i := 1 to StrLen(Value) do begin
            Char := Value[i];
            if Char in ['0' .. '9', 'A' .. 'Z', 'a' .. 'z'] then
                AlphanumericValue += Format(Value[i]);
        end;
    end;

    local procedure GetDocumentType(VATReportLine: Record "VAT Report Line"): Text
    var
        CountryRegion: Record "Country/Region";
        Intracommunity: Boolean;
    begin
        if VATReportLine."Fattura Document Type" <> '' then
            exit(VATReportLine."Fattura Document Type");
        if VATReportLine."Document Type" = VATReportLine."Document Type"::Invoice then begin
            if (VATReportLine.Type = VATReportLine.Type::Purchase) and CountryRegion.Get(VATReportLine."Country/Region Code") then begin
                Intracommunity := (CountryRegion."EU Country/Region Code" <> '') and
                  (CountryRegion."EU Country/Region Code" <> CompanyInfo.GetCountryRegionCode(''));

                if Intracommunity then begin
                    if SumPurchInvoiceVATEntries(VATReportLine, true) <= SumPurchInvoiceVATEntries(VATReportLine, false) then
                        exit(Format(DocumentTypes::TD10));
                    exit(Format(DocumentTypes::TD11));
                end;
            end;

            exit(Format(DocumentTypes::TD01));
        end;

        if VATReportLine."Document Type" = VATReportLine."Document Type"::"Credit Memo" then
            exit(Format(DocumentTypes::TD04));

        exit('');
    end;

    local procedure GetFileSuffix(FileCounter: Integer; SalesPurchFileCounter: Integer; var FileSuffix: Text)
    begin
        if SalesPurchFileCounter = 1 then
            FileSuffix := Format(FileCounter)
        else
            FileSuffix := Format(FileCounter) + '_00' + Format(SalesPurchFileCounter);
    end;

    local procedure GetVendorNoForIdentificativiFiscali(VATReportLine: Record "VAT Report Line") VendorNo: Code[20]
    var
        VATEntry: Record "VAT Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VATEntry.Get(VATReportLine."VAT Entry No.");
        if VendorLedgerEntry.Get(VATEntry."Related Entry No.") then
            VendorNo := VendorLedgerEntry."Vendor No." // linked foreign vendor for customs authority invoice
        else
            VendorNo := VATReportLine."Bill-to/Pay-to No.";
    end;

    local procedure SumPurchInvoiceVATEntries(VATReportLine: Record "VAT Report Line"; EUServiceFlag: Boolean): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("External Document No.", VATReportLine."Document No.");
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("EU Service", EUServiceFlag);
        VATEntry.SetRange(Type, VATReportLine.Type);
        VATEntry.SetRange("VAT Identifier", VATReportLine."VAT Group Identifier");
        VATEntry.CalcSums(Base);
        exit(VATEntry.Base);
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(FilePath: Text)
    begin
        ServerFilePath := FilePath;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddInvoiceAmountsDataOnBeforeGetVATPostingSetup(VATReportLine: Record "VAT Report Line"; XMLDOMManagement: Codeunit "XML DOM Management"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddInvoiceAmountsDataOnAfterVATPostingSetupGet(var VATPostingSetup: Record "VAT Posting Setup"; var VATReportLine: Record "VAT Report Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCustomerForVATReportLine(var Customer: Record Customer; VATReportLine: Record "VAT Report Line"; var CustomerExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVendorForVATReportLine(var Vendor: Record Vendor; VendorNo: Code[20]; VATReportLine: Record "VAT Report Line"; var VendorExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveFileOnClient(var NewServerFilePath: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSaveFileOnClient(SuggestedFileName: Text)
    begin
    end;
}

