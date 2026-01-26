// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;
using System.Text;
using System.Utilities;

codeunit 12179 "Export FatturaPA Document"
{
    EventSubscriberInstance = Manual;
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        RecordExportBuffer: Record "Record Export Buffer";
        TempFatturaHeader: Record "Fattura Header" temporary;
        TempFatturaLine: Record "Fattura Line" temporary;
        TempBlob: Codeunit "Temp Blob";
        HeaderRecRef: RecordRef;
        InStr: InStream;
        OutStr: OutStream;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        Session.LogMessage('0000CQ6', ExportFatturaMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FatturaTok);

        HeaderRecRef.Get(Rec.RecordID);
        FatturaDocHelper.InitializeErrorLog(Rec);
        FatturaDocHelper.CollectDocumentInformation(TempFatturaHeader, TempFatturaLine, HeaderRecRef);

        RecordExportBuffer.SetView(Rec.GetView());
        RecordExportBuffer.FindFirst();

        if TempFatturaHeader."Progressive No." <> '' then begin
            if RecordExportBuffer.ID = Rec.ID then
                Rec.ZipFileName := FatturaDocHelper.GetFileName(TempFatturaHeader."Progressive No.") + '.zip'
            else
                Rec.ZipFileName := RecordExportBuffer.ZipFileName;
            Rec.ClientFileName := FatturaDocHelper.GetFileName(TempFatturaHeader."Progressive No.") + '.xml';
        end;
        if not FatturaDocHelper.HasErrors() then
            GenerateXMLFile(TempBlob, TempFatturaLine, TempFatturaHeader, Rec.ClientFileName)
        else
            Session.LogMessage('0000CQ7', DocumentValidationErrMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FatturaTok);

        if TempBlob.HasValue() then begin
            TempBlob.CreateInStream(InStr);
            Rec."File Content".CreateOutStream(OutStr);
            CopyStream(OutStr, InStr);
        end;
        Rec.Modify();

        OnAfterGenerateXmlFile(Rec);

        Session.LogMessage('0000CQ8', ExportFatturaSuccMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FatturaTok);
    end;

    var
        CompanyInformation: Record "Company Information";
        TempXMLBuffer: Record "XML Buffer" temporary;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        YesTok: Label 'SI', Locked = true;
        // fault model labels
        FatturaTok: Label 'FatturaTelemetryCategoryTok', Locked = true;
        ExportFatturaMsg: Label 'Exporting FatturaPA document', Locked = true;
        ExportFatturaSuccMsg: Label 'FatturaPA document successfully exported', Locked = true;
        DocumentValidationErrMsg: Label 'The document did not pass the validation before the export', Locked = true;
        GenerateXMLMsg: Label 'Generating XML file', Locked = true;
        GenerateXMLSuccMsg: Label 'XML file successfully generated', Locked = true;
        HeaderErrMsg: Label 'Cannot create XML header: %1', Locked = true;
        BodyErrMsg: Label 'Cannot create XML body: %1', Locked = true;

    [Scope('OnPrem')]
    procedure GenerateXMLFile(var TempBlob: Codeunit "Temp Blob"; var TempFatturaLine: Record "Fattura Line" temporary; TempFatturaHeader: Record "Fattura Header" temporary; ClientFileName: Text[250])
    var
        ExportFatturaPADocument: Codeunit "Export FatturaPA Document";
    begin
        Session.LogMessage('0000CQ9', GenerateXMLMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FatturaTok);

        CompanyInformation.Get();
        BindSubscription(ExportFatturaPADocument);

        // create file
        if not TryCreateFatturaElettronicaHeader(TempFatturaHeader) then begin
            Session.LogMessage('0000CQA', StrSubstNo(HeaderErrMsg, GetLastErrorText()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FatturaTok);
            Error(GetLastErrorText());
        end;

        if not TryCreateFatturaElettronicaBody(TempFatturaLine, TempFatturaHeader) then begin
            Session.LogMessage('0000CQB', StrSubstNo(BodyErrMsg, GetLastErrorText()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FatturaTok);
            Error(GetLastErrorText());
        end;

        // update Buffer
        TempXMLBuffer.FindFirst();
        TempXMLBuffer.Save(TempBlob);
        OnAfterCreateBlobXML(TempXMLBuffer, TempBlob, ClientFileName);

        Session.LogMessage('0000CQC', GenerateXMLSuccMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FatturaTok);
    end;

    [TryFunction]
    local procedure TryCreateFatturaElettronicaHeader(TempFatturaHeader: Record "Fattura Header" temporary)
    var
        CompanyAsCustomer: Record Customer;
        Customer: Record Customer;
    begin
        CreateXMLDefinition(TempFatturaHeader);
        if TempFatturaHeader."Customer No" = '' then
            GetCustomerAsCurrentCompany(Customer)
        else
            Customer.Get(TempFatturaHeader."Customer No");
        PopulateTransmissionData(TempFatturaHeader, Customer);
        if TempFatturaHeader."Fattura Vendor No." = '' then
            PopulateCompanyInformation(Customer)
        else begin
            GetCustomerAsCurrentCompany(CompanyAsCustomer);
            TempXMLBuffer.AddGroupElement('CedentePrestatore');
            CopyVendorToCustomerBuffer(Customer, TempFatturaHeader."Fattura Vendor No.");
            PopulateCustomerData(Customer);
            TempXMLBuffer.GetParent();
            Customer := CompanyAsCustomer;
        end;

        PopulateTaxRepresentative(TempFatturaHeader);
        PopulateCustomerDataWithHeader(Customer);
    end;

    [TryFunction]
    local procedure TryCreateFatturaElettronicaBody(var TempFatturaLine: Record "Fattura Line" temporary; TempFatturaHeader: Record "Fattura Header" temporary)
    begin
        PopulateDocGeneralData(TempFatturaHeader);
        PopulateDocDiscountData(TempFatturaHeader);
        // fill in General, Order Data
        PopulateOrderData(TempFatturaLine, TempFatturaHeader);

        PopulateApplicationData(TempFatturaHeader);
        // 2.1.8 DatiDDT
        PopulateShipmentData(TempFatturaLine);
        // 2.2 DatiBeniServizi - Goods/Services data
        TempXMLBuffer.GetParent();
        TempXMLBuffer.AddGroupElement('DatiBeniServizi');
        TempFatturaLine.Reset();
        TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::Document);
        OnTryCreateFatturaElettronicaBodyOnAfterTempFatturaLineSetFiltersForDocument(TempFatturaLine, TempFatturaHeader);
        if TempFatturaLine.FindSet() then
            repeat
                PopulateLineData(TempFatturaLine);
            until TempFatturaLine.Next() = 0;
        // fill in LineVATData
        TempFatturaLine.Reset();
        TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::VAT);
        if TempFatturaLine.FindSet() then
            repeat
                PopulateLineVATData(TempFatturaLine);
            until TempFatturaLine.Next() = 0;
        TempXMLBuffer.GetParent();
        PopulatePaymentData(TempFatturaLine, TempFatturaHeader);
        PopulateDocumentAttachments(TempFatturaHeader);
    end;

    local procedure CreateXMLDefinition(TempFatturaHeader: Record "Fattura Header" temporary)
    begin
        TempXMLBuffer.CreateRootElement('p:FatturaElettronica');
        TempXMLBuffer.AddAttribute('versione', TempFatturaHeader."Transmission Type");
        TempXMLBuffer.AddNamespace('ds', 'http://www.w3.org/2000/09/xmldsig#');
        TempXMLBuffer.AddNamespace('p', 'http://ivaservizi.agenziaentrate.gov.it/docs/xsd/fatture/v1.2');
        TempXMLBuffer.AddNamespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance');
    end;

    local procedure IsValidFatturaCharacter(InputChar: Char): Boolean
    var
        IsValid: Boolean;
    begin
        // Fattura expected standard is ISO 8859-1, that is 8-bit character code page
        // Special characters "'&<> are escaped later on xml file saving
        IsValid := InputChar in [1 .. 255];

        OnIsValidFatturaCharacter(InputChar, IsValid);

        exit(IsValid);
    end;

    local procedure GetFatturaValidSubstText(InputChar: Char) Result: Text
    var
        CharCode: Integer;
    begin
        CharCode := InputChar;
        if CharCode = 8364 then
            Result := 'EUR'
        else
            Result := '_';

        OnGetFatturaValidCharacter(InputChar, Result);
    end;

    local procedure GetCustomerAsCurrentCompany(var Customer: Record Customer)
    var
        FatturaSetup: Record "Fattura Setup";
    begin
        Customer.Init();
        Customer."Country/Region Code" := CompanyInformation."Country/Region Code";
        Customer."Fiscal Code" := CompanyInformation."Fiscal Code";
        Customer."VAT Registration No." := CompanyInformation."VAT Registration No.";
        Customer.Name := CompanyInformation.Name;
        Customer.Address := CompanyInformation.Address;
        Customer."Post Code" := CompanyInformation."Post Code";
        Customer.County := CompanyInformation.County;
        Customer.City := CompanyInformation.City;
        FatturaSetup.Get();
        FatturaSetup.TestField("Company PA Code");
        Customer."PA Code" := FatturaSetup."Company PA Code";
    end;

    local procedure GetDenominazioneMaxLength(): Integer
    begin
        exit(80);
    end;

    local procedure CopyVendorToCustomerBuffer(var Customer: Record Customer; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Customer.Init();
        Customer."Country/Region Code" := Vendor."Country/Region Code";
        Customer."Fiscal Code" := Vendor."Fiscal Code";
        Customer."VAT Registration No." := Vendor."VAT Registration No.";
        Customer.Name := Vendor.Name;
        Customer.Address := Vendor.Address;
        Customer."Post Code" := Vendor."Post Code";
        Customer.County := Vendor.County;
        Customer.City := Vendor.City;
    end;

    local procedure FormatAmount(Amount: Decimal): Text[250]
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,9>'))
    end;

    local procedure FormatAmountEightDecimalPlaces(Amount: Decimal): Text[250]
    begin
        exit(Format(Amount, 0, '<Sign><Integer><Decimals,8><Comma,.>'))
    end;

    local procedure FormatQuantity(Amount: Decimal): Text[250]
    begin
        if Amount = 0 then
            exit('');
        exit(FormatNonBlankQuantity(Amount));
    end;

    local procedure FormatNonBlankQuantity(Amount: Decimal): Text[250]
    begin
        exit(Format(Amount, 0, '<Precision,2:5><Standard Format,9>'))
    end;

    local procedure FormatDate(DateToFormat: Date): Text
    begin
        if DateToFormat = 0D then
            exit('');
        exit(Format(DateToFormat, 0, '<Standard Format,9>'));
    end;

    local procedure PopulateTransmissionData(TempFatturaHeader: Record "Fattura Header" temporary; Customer: Record Customer)
    var
        TransmissionIntermediaryVendor: Record Vendor;
    begin
        // Section 1.1 DatiTrasmissione
        if CompanyInformation."Transmission Intermediary No." <> '' then
            if TransmissionIntermediaryVendor.Get(CompanyInformation."Transmission Intermediary No.") then;

        TempXMLBuffer.AddGroupElement('FatturaElettronicaHeader');
        TempXMLBuffer.AddGroupElement('DatiTrasmissione');

        TempXMLBuffer.AddGroupElement('IdTrasmittente');
        if TransmissionIntermediaryVendor."No." = '' then begin
            TempXMLBuffer.AddNonEmptyElement('IdPaese', CompanyInformation."Country/Region Code");
            if CompanyInformation."Fiscal Code" = '' then
                TempXMLBuffer.AddNonEmptyLastElement('IdCodice', CompanyInformation."VAT Registration No.")
            else
                TempXMLBuffer.AddNonEmptyLastElement('IdCodice', CompanyInformation."Fiscal Code");
        end else begin
            TempXMLBuffer.AddNonEmptyElement('IdPaese', TransmissionIntermediaryVendor."Country/Region Code");
            TempXMLBuffer.AddNonEmptyLastElement('IdCodice', TransmissionIntermediaryVendor."Fiscal Code");
        end;

        TempXMLBuffer.AddNonEmptyElement('ProgressivoInvio', TempFatturaHeader."Progressive No.");
        TempXMLBuffer.AddNonEmptyElement('FormatoTrasmissione', TempFatturaHeader."Transmission Type");
        TempXMLBuffer.AddNonEmptyElement('CodiceDestinatario', Customer."PA Code");
        if Customer."PA Code" = '0000000' then
            TempXMLBuffer.AddNonEmptyElement('PECDestinatario', Customer."PEC E-Mail Address");
        TempXMLBuffer.GetParent();
    end;

    local procedure PopulateCompanyInformation(Customer: Record Customer)
    begin
        // 1.2 CedentePrestatore - Seller
        TempXMLBuffer.AddGroupElement('CedentePrestatore');
        TempXMLBuffer.AddGroupElement('DatiAnagrafici');
        TempXMLBuffer.AddGroupElement('IdFiscaleIVA');
        TempXMLBuffer.AddNonEmptyElement('IdPaese', CompanyInformation."Country/Region Code");
        TempXMLBuffer.AddNonEmptyLastElement('IdCodice', CompanyInformation."VAT Registration No.");
        TempXMLBuffer.AddNonEmptyElement('CodiceFiscale', CompanyInformation."Fiscal Code");

        TempXMLBuffer.AddGroupElement('Anagrafica');
        TempXMLBuffer.AddNonEmptyLastElement('Denominazione', CopyStr(CompanyInformation.Name, 1, GetDenominazioneMaxLength()));
        TempXMLBuffer.AddNonEmptyLastElement('RegimeFiscale', 'RF' + CompanyInformation."Company Type");
        // 1.2.2 Sede
        TempXMLBuffer.AddGroupElement('Sede');
        TempXMLBuffer.AddNonEmptyElement('Indirizzo', CopyStr(CompanyInformation.Address, 1, 60));
        TempXMLBuffer.AddNonEmptyElement('CAP', CompanyInformation."Post Code");
        TempXMLBuffer.AddNonEmptyElement('Comune', CompanyInformation.City);
        TempXMLBuffer.AddNonEmptyElement('Provincia', CompanyInformation.County);
        TempXMLBuffer.AddNonEmptyLastElement('Nazione', CompanyInformation."Country/Region Code");
        // 1.2.4 IscrizioneREA
        TempXMLBuffer.AddGroupElement('IscrizioneREA');
        TempXMLBuffer.AddNonEmptyElement('Ufficio', CompanyInformation."Registry Office Province");
        TempXMLBuffer.AddNonEmptyElement('NumeroREA', CompanyInformation."REA No.");
        TempXMLBuffer.AddNonEmptyElement('CapitaleSociale', FormatAmount(CompanyInformation."Paid-In Capital"));
        if CompanyInformation."Shareholder Status" = CompanyInformation."Shareholder Status"::"One Shareholder" then
            TempXMLBuffer.AddNonEmptyElement('SocioUnico', 'SU')
        else
            TempXMLBuffer.AddNonEmptyElement('SocioUnico', 'SM');

        if CompanyInformation."Liquidation Status" = CompanyInformation."Liquidation Status"::"Not in Liquidation" then
            TempXMLBuffer.AddNonEmptyLastElement('StatoLiquidazione', 'LN')
        else
            TempXMLBuffer.AddNonEmptyLastElement('StatoLiquidazione', 'LS');
        // 1.2.5 Contatti
        TempXMLBuffer.AddGroupElement('Contatti');
        TempXMLBuffer.AddNonEmptyElement('Telefono', DelChr(CompanyInformation."Phone No.", '=', '-'));
        TempXMLBuffer.AddNonEmptyElement('Fax', DelChr(CompanyInformation."Fax No.", '=', '-'));
        TempXMLBuffer.AddNonEmptyLastElement('Email', CompanyInformation."E-Mail");
        // 1.2.6. RiferimentoAmministrazione
        TempXMLBuffer.AddNonEmptyLastElement('RiferimentoAmministrazione', Customer."Our Account No.");
    end;

    local procedure PopulateTaxRepresentative(TempFatturaHeader: Record "Fattura Header" temporary)
    var
        TempVendor: Record Vendor temporary;
    begin
        // 1.3. RappresentanteFiscale - TAX REPRESENTATIVE

        if not TempFatturaHeader.GetTaxRepresentative(TempVendor) then
            exit;

        TempXMLBuffer.AddGroupElement('RappresentanteFiscale');
        TempXMLBuffer.AddGroupElement('DatiAnagrafici');
        TempXMLBuffer.AddGroupElement('IdFiscaleIVA');
        TempXMLBuffer.AddNonEmptyElement('IdPaese', TempVendor."Country/Region Code");
        TempXMLBuffer.AddNonEmptyLastElement('IdCodice', TempVendor."VAT Registration No.");

        TempXMLBuffer.AddGroupElement('Anagrafica');
        if TempVendor."Individual Person" then begin
            TempXMLBuffer.AddNonEmptyElement('Nome', TempVendor."First Name");
            TempXMLBuffer.AddNonEmptyLastElement('Cognome', TempVendor."Last Name");
        end else
            TempXMLBuffer.AddNonEmptyLastElement('Denominazione', CopyStr(TempVendor.Name, 1, GetDenominazioneMaxLength()));

        TempXMLBuffer.GetParent();
        TempXMLBuffer.GetParent();
    end;

    local procedure PopulateCustomerDataWithHeader(Customer: Record Customer)
    begin
        // 1.4 CessionarioCommittente
        TempXMLBuffer.AddGroupElement('CessionarioCommittente');
        PopulateCustomerData(Customer);
        TempXMLBuffer.GetParent();
    end;

    local procedure PopulateCustomerData(Customer: Record Customer)
    begin
        // 1.4 CessionarioCommittente
        TempXMLBuffer.AddGroupElement('DatiAnagrafici');
        if (Customer."VAT Registration No." <> '') and (not Customer."Individual Person") then begin
            TempXMLBuffer.AddGroupElement('IdFiscaleIVA');
            TempXMLBuffer.AddNonEmptyElement('IdPaese', Customer."Country/Region Code");
            TempXMLBuffer.AddNonEmptyLastElement('IdCodice', Customer."VAT Registration No.");
        end;
        if CompanyInformation."Country/Region Code" = Customer."Country/Region Code" then
            TempXMLBuffer.AddNonEmptyElement('CodiceFiscale', Customer."Fiscal Code");
        // 1.4.1.3 Anagrafica
        TempXMLBuffer.AddGroupElement('Anagrafica');
        if Customer."Individual Person" then begin
            TempXMLBuffer.AddNonEmptyElement('Nome', Customer."First Name");
            TempXMLBuffer.AddNonEmptyLastElement('Cognome', Customer."Last Name");
        end else
            TempXMLBuffer.AddNonEmptyLastElement('Denominazione', CopyStr(Customer.Name, 1, GetDenominazioneMaxLength()));
        TempXMLBuffer.GetParent();
        // 1.4.2. Sede
        TempXMLBuffer.AddGroupElement('Sede');
        TempXMLBuffer.AddNonEmptyElement('Indirizzo', CopyStr(Customer.Address, 1, 60));
        if Customer."Country/Region Code" <> CompanyInformation."Country/Region Code" then
            TempXMLBuffer.AddNonEmptyElement('CAP', '00000')
        else
            TempXMLBuffer.AddNonEmptyElement('CAP', Customer."Post Code");
        TempXMLBuffer.AddNonEmptyElement('Comune', Customer.City);
        TempXMLBuffer.AddNonEmptyElement('Provincia', Customer.County);
        TempXMLBuffer.AddNonEmptyLastElement('Nazione', Customer."Country/Region Code");
        TempXMLBuffer.GetParent();
    end;

    local procedure PopulateDocGeneralData(TempFatturaHeader: Record "Fattura Header" temporary)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        TempXMLBuffer.AddGroupElement('FatturaElettronicaBody');
        TempXMLBuffer.AddGroupElement('DatiGenerali');
        // 2.1.1   DatiGeneraliDocumento - general details
        TempXMLBuffer.AddGroupElement('DatiGeneraliDocumento');
        TempXMLBuffer.AddNonEmptyElement('TipoDocumento', TempFatturaHeader."Fattura Document Type");
        // 2.1.1.2 Divisa
        GeneralLedgerSetup.Get();
        TempXMLBuffer.AddNonEmptyElement('Divisa', GeneralLedgerSetup."LCY Code");
        // 2.1.1.3  Data
        TempXMLBuffer.AddNonEmptyElement('Data', FormatDate(TempFatturaHeader."Posting Date"));
        // 2.1.1.4   Numero
        TempXMLBuffer.AddNonEmptyElement('Numero', TempFatturaHeader."Document No.");
        // 2.1.1.6   DatiBollo
        if TempFatturaHeader."Fattura Stamp" then begin
            TempXMLBuffer.AddGroupElement('DatiBollo');
            TempXMLBuffer.AddNonEmptyElement('BolloVirtuale', YesTok);
            TempXMLBuffer.AddNonEmptyElement('ImportoBollo', FormatAmount(TempFatturaHeader."Fattura Stamp Amount"));
            TempXMLBuffer.GetParent();
        end;
    end;

    local procedure PopulateDocDiscountData(TempFatturaHeader: Record "Fattura Header" temporary)
    begin
        // 2.1.1.8 - ScontoMaggiorazione - Discount - Extra charge
        if TempFatturaHeader."Total Inv. Discount" <> 0 then begin
            TempXMLBuffer.AddGroupElement('ScontoMaggiorazione');
            TempXMLBuffer.AddNonEmptyElement('Tipo', 'SC');
            TempXMLBuffer.AddNonEmptyLastElement(
              'Importo', FormatAmountEightDecimalPlaces(TempFatturaHeader."Total Inv. Discount"));
        end;
        // 2.1.1.9   ImportoTotaleDocumento
        TempXMLBuffer.AddNonEmptyLastElement('ImportoTotaleDocumento', FormatAmount(TempFatturaHeader."Total Amount"));
    end;

    local procedure PopulateLineData(var TempFatturaLine: Record "Fattura Line" temporary)
    var
        Item: Record Item;
        UoMMaxLength: Integer;
    begin
        UoMMaxLength := 10;
        // 2.2.1 DettaglioLinee
        TempXMLBuffer.AddGroupElement('DettaglioLinee');
        TempXMLBuffer.AddNonEmptyElement('NumeroLinea', Format(TempFatturaLine."Line No."));
        if TempFatturaLine.GetItem(Item) then begin
            TempXMLBuffer.AddGroupElement('CodiceArticolo');
            TempXMLBuffer.AddNonEmptyElement('CodiceTipo', 'GTIN');
            TempXMLBuffer.AddNonEmptyLastElement('CodiceValore', Item.GTIN);
        end;
        TempXMLBuffer.AddNonEmptyElement('Descrizione', TempFatturaLine.Description);
        TempXMLBuffer.AddNonEmptyElement('Quantita', FormatQuantity(TempFatturaLine.Quantity));
        TempXMLBuffer.AddNonEmptyElement('UnitaMisura', CopyStr(TempFatturaLine."Unit of Measure", 1, UoMMaxLength));
        TempXMLBuffer.AddNonEmptyElement('PrezzoUnitario', FormatNonBlankQuantity(TempFatturaLine."Unit Price"));
        if (TempFatturaLine."Discount Percent" <> 0) or (TempFatturaLine."Discount Amount" <> 0) then begin
            TempXMLBuffer.AddGroupElement('ScontoMaggiorazione');
            TempXMLBuffer.AddNonEmptyElement('Tipo', 'SC');
            TempXMLBuffer.AddNonEmptyElement('Percentuale', FormatAmount(TempFatturaLine."Discount Percent"));
            TempFatturaLine."Discount Amount" := (TempFatturaLine."Unit Price" * TempFatturaLine."Discount Percent") / 100;
            TempXMLBuffer.AddNonEmptyElement('Importo', FormatAmountEightDecimalPlaces(TempFatturaLine."Discount Amount"));
            TempXMLBuffer.GetParent();
        end;

        TempXMLBuffer.AddNonEmptyElement('PrezzoTotale', FormatAmount(TempFatturaLine.Amount));
        TempXMLBuffer.AddNonEmptyElement('AliquotaIVA', FormatAmount(TempFatturaLine."VAT %"));
        TempXMLBuffer.AddNonEmptyElement('Natura', TempFatturaLine."VAT Transaction Nature");
        if TempFatturaLine.Type <> '' then
            PopulateAttachedToLinesExtText(TempFatturaLine);
        TempXMLBuffer.GetParent();
    end;

    local procedure PopulateLineVATData(var TempFatturaLine: Record "Fattura Line" temporary)
    begin
        // 2.2.2 DatiRiepilogo - summary data for every VAT rate
        TempXMLBuffer.AddGroupElement('DatiRiepilogo');
        TempXMLBuffer.AddNonEmptyElement('AliquotaIVA', FormatAmount(TempFatturaLine."VAT %"));
        TempXMLBuffer.AddNonEmptyElement('Natura', TempFatturaLine."VAT Transaction Nature");
        TempXMLBuffer.AddNonEmptyElement(
          'ImponibileImporto', FormatAmount(TempFatturaLine."VAT Base"));
        TempXMLBuffer.AddNonEmptyElement('Imposta', FormatAmount(TempFatturaLine."VAT Amount"));
        TempXMLBuffer.AddNonEmptyElement('EsigibilitaIVA', TempFatturaLine.Description);
        TempXMLBuffer.AddNonEmptyElement('RiferimentoNormativo', TempFatturaLine."VAT Nature Description");
        TempXMLBuffer.GetParent();
    end;

    local procedure PopulateOrderData(var TempFatturaLine: Record "Fattura Line" temporary; TempFatturaHeader: Record "Fattura Header" temporary)
    var
        OrderNo: Code[20];
        Finished: Boolean;
        LineInfoExists: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePopulateOrderData(TempFatturaLine, TempFatturaHeader, TempXMLBuffer, IsHandled);
        if IsHandled then
            exit;

        // 2.1.2  DatiOrdineAcquisto

        TempFatturaLine.Reset();
        TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::Order);
        if not TempFatturaLine.FindSet() then
            exit;

        repeat
            TempXMLBuffer.AddGroupElement('DatiOrdineAcquisto');
            OrderNo := TempFatturaLine."Document No.";
            repeat
                if TempFatturaLine."Related Line No." <> 0 then
                    TempXMLBuffer.AddNonEmptyElement('RiferimentoNumeroLinea', Format(TempFatturaLine."Related Line No."));
                if TempFatturaLine."Customer Purchase Order No." <> '' then begin
                    TempXMLBuffer.AddNonEmptyElement('IdDocumento', CopyStr(TempFatturaLine."Customer Purchase Order No.", 1, 20));
                    LineInfoExists := true;
                end;
                if TempFatturaLine."Fattura Project Code" <> '' then begin
                    TempXMLBuffer.AddNonEmptyElement('CodiceCUP', TempFatturaLine."Fattura Project Code");
                    LineInfoExists := true;
                end;
                if TempFatturaLine."Fattura Tender Code" <> '' then begin
                    TempXMLBuffer.AddNonEmptyElement('CodiceCIG', TempFatturaLine."Fattura Tender Code");
                    LineInfoExists := true;
                end;
                Finished := TempFatturaLine.Next() = 0;
            until Finished or (OrderNo <> TempFatturaLine."Document No.");
            if not LineInfoExists then begin
                TempXMLBuffer.AddNonEmptyElement('IdDocumento', CopyStr(TempFatturaHeader."Customer Purchase Order No.", 1, 20));
                TempXMLBuffer.AddNonEmptyElement('CodiceCUP', TempFatturaHeader."Fattura Project Code");
                TempXMLBuffer.AddNonEmptyElement('CodiceCIG', TempFatturaHeader."Fattura Tender Code");
            end;
            TempXMLBuffer.GetParent();
        until Finished;
    end;

    local procedure PopulatePaymentData(var TempFatturaLine: Record "Fattura Line" temporary; TempFatturaHeader: Record "Fattura Header" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePopulatePaymentData(TempFatturaLine, TempFatturaHeader, TempXMLBuffer, IsHandled);
        if IsHandled then
            exit;
        // 2.4. DatiPagamento - Payment Data
        TempFatturaLine.Reset();
        TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::Payment);
        if TempFatturaLine.FindSet() then begin
            TempXMLBuffer.AddGroupElement('DatiPagamento');
            TempXMLBuffer.AddNonEmptyElement('CondizioniPagamento', TempFatturaHeader."Fattura Payment Terms Code");
            repeat
                TempXMLBuffer.AddGroupElement('DettaglioPagamento');
                TempXMLBuffer.AddNonEmptyElement('ModalitaPagamento', TempFatturaHeader."Fattura PA Payment Method");
                TempXMLBuffer.AddNonEmptyElement(
                  'DataScadenzaPagamento', FormatDate(TempFatturaLine."Due Date"));
                TempXMLBuffer.AddNonEmptyElement('ImportoPagamento', FormatAmount(TempFatturaLine.Amount));
                TempXMLBuffer.AddNonEmptyLastElement('IBAN', CompanyInformation.IBAN);
            until TempFatturaLine.Next() = 0;
            TempXMLBuffer.GetParent();
        end;
    end;

    local procedure PopulateShipmentData(var TempFatturaLine: Record "Fattura Line" temporary)
    begin
        TempFatturaLine.Reset();
        TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::Shipment);
        if not TempFatturaLine.FindSet() then
            exit;

        repeat
            TempXMLBuffer.AddGroupElement('DatiDDT');
            TempXMLBuffer.AddNonEmptyElement('NumeroDDT', TempFatturaLine."Document No.");
            TempXMLBuffer.AddNonEmptyElement('DataDDT', FormatDate(TempFatturaLine."Posting Date"));
            if TempFatturaLine."Related Line No." <> 0 then
                TempXMLBuffer.AddNonEmptyElement('RiferimentoNumeroLinea', Format(TempFatturaLine."Line No."));
            TempXMLBuffer.GetParent();
        until TempFatturaLine.Next() = 0;
    end;

    local procedure PopulateExtendedTextData(FatturaLine: Record "Fattura Line")
    var
        ExtendedTextLength: Integer;
        TextToCopy: Text;
        CurrPosition: Integer;
    begin
        ExtendedTextLength := 60;
        TempXMLBuffer.AddGroupElement('AltriDatiGestionali');
        TempXMLBuffer.AddNonEmptyElement('TipoDato', FatturaLine."Ext. Text Source No");
        TempXMLBuffer.AddNonEmptyElement('RiferimentoTesto', CopyStr(FatturaLine.Description, 1, ExtendedTextLength));
        TempXMLBuffer.AddNonEmptyElement('RiferimentoData', FormatDate(FatturaLine."Posting Date"));
        TempXMLBuffer.GetParent();
        if StrLen(FatturaLine.Description) > ExtendedTextLength then begin
            CurrPosition := ExtendedTextLength;
            repeat
                TextToCopy := CopyStr(FatturaLine.Description, CurrPosition + 1, ExtendedTextLength);
                CurrPosition := CurrPosition + StrLen(TextToCopy);
                TempXMLBuffer.AddGroupElement('AltriDatiGestionali');
                TempXMLBuffer.AddNonEmptyElement('TipoDato', FatturaLine."Ext. Text Source No");
                TempXMLBuffer.AddNonEmptyElement('RiferimentoTesto', TextToCopy);
                TempXMLBuffer.AddNonEmptyElement('RiferimentoData', FormatDate(FatturaLine."Posting Date"));
                TempXMLBuffer.GetParent();
            until CurrPosition >= StrLen(FatturaLine.Description);
        end;
    end;

    local procedure PopulateAttachedToLinesExtText(var TempFatturaLine: Record "Fattura Line" temporary)
    var
        TempExtFatturaLine: Record "Fattura Line" temporary;
    begin
        TempExtFatturaLine.Copy(TempFatturaLine, true);
        TempExtFatturaLine.SetRange("Line Type", TempExtFatturaLine."Line Type"::"Extended Text");
        TempExtFatturaLine.SetRange("Related Line No.", TempFatturaLine."Line No.");
        if TempExtFatturaLine.FindSet() then
            repeat
                PopulateExtendedTextData(TempExtFatturaLine);
            until TempExtFatturaLine.Next() = 0;
        TempExtFatturaLine.SetRange("Related Line No.", 0);
        if TempExtFatturaLine.FindFirst() then
            PopulateExtendedTextData(TempExtFatturaLine);
    end;

    local procedure PopulateDocumentAttachments(TempFatturaHeader: Record "Fattura Header" temporary)
    var
        DocumentAttachment: Record "Document Attachment";
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        DocumentAttachment.SetRange("Table ID", TempFatturaHeader.GetTableID());
        DocumentAttachment.SetRange("No.", TempFatturaHeader."Document No.");
        if DocumentAttachment.FindSet() then
            repeat
                if not DocumentAttachment."Document Reference ID".HasValue() then
                    exit;

                TempXMLBuffer.AddGroupElement('Allegati');
                TempXMLBuffer.AddNonEmptyElement('NomeAttachment', DocumentAttachment."File Name");
                TempXMLBuffer.AddNonEmptyElement('FormatoAttachment', DocumentAttachment."File Extension");
                TempXMLBuffer.Get(TempXMLBuffer.AddElement('Attachment', ''));

                TempBlob.CreateOutStream(OutStream);
                DocumentAttachment."Document Reference ID".ExportStream(OutStream);
                TempBlob.CreateInStream(InStream);
                TempXMLBuffer.SetValue(Base64Convert.ToBase64(InStream));

                TempXMLBuffer.GetParent();
                TempXMLBuffer.GetParent();
            until DocumentAttachment.Next() = 0;
    end;

    local procedure PopulateApplicationData(TempFatturaHeader: Record "Fattura Header" temporary)
    var
        AppliedDocNo: Code[35];
    begin
        if TempFatturaHeader."Self-Billing Document" then
            AppliedDocNo := TempFatturaHeader."External Document No."
        else
            AppliedDocNo := TempFatturaHeader."Applied Doc. No.";

        if AppliedDocNo = '' then
            exit;

        TempXMLBuffer.AddGroupElement('DatiFattureCollegate');
        TempXMLBuffer.AddNonEmptyElement('IdDocumento', AppliedDocNo);
        TempXMLBuffer.AddNonEmptyElement('Data', FormatDate(TempFatturaHeader."Applied Posting Date"));
        TempXMLBuffer.AddNonEmptyElement('CodiceCUP', TempFatturaHeader."Appl. Fattura Project Code");
        TempXMLBuffer.AddNonEmptyElement('CodiceCIG', TempFatturaHeader."Appl. Fattura Tender Code");
        TempXMLBuffer.GetParent();
    end;

    local procedure SubstituteInvalidCharacters(var InputValue: Text)
    var
        DotNet_StringBuilder: Codeunit DotNet_StringBuilder;
        Index: Integer;
        Length: Integer;
        InputChar: Char;
        SubstText: Text;
    begin
        if InputValue = '' then
            exit;

        DotNet_StringBuilder.InitStringBuilder('');
        Length := StrLen(InputValue);

        for Index := 1 to Length do begin
            InputChar := InputValue[Index];
            InputChar := NormalizeChar(InputChar);
            SubstText := Format(InputChar);
            if not IsValidFatturaCharacter(InputChar) then
                SubstText := GetFatturaValidSubstText(InputChar);
            DotNet_StringBuilder.Append(SubstText);
        end;

        InputValue := DotNet_StringBuilder.ToString();
    end;

    local procedure NormalizeChar(InputChar: Char): Char
    var
        CharCode: Integer;
    begin
        CharCode := InputChar;
        case CharCode of
            192:
                exit('A');
            224:
                exit('a');
            200:
                exit('E');
            232:
                exit('e');
            201:
                exit('E');
            233:
                exit('e');
            204:
                exit('I');
            236:
                exit('i');
            210:
                exit('O');
            242:
                exit('o');
            211:
                exit('O');
            243:
                exit('o');
            217:
                exit('U');
            249:
                exit('u');
            else
                exit(InputChar);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"XML Buffer", 'OnNormalizeElementValue', '', false, false)]
    local procedure SubstituteInvalidCharactersOnNormalizeElementValue(var ElementValue: Text)
    begin
        SubstituteInvalidCharacters(ElementValue);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateBlobXML(var TempXMLBuffer: Record "XML Buffer" temporary; var TempBlob: Codeunit "Temp Blob"; ClientFileName: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var RecordExportBuffer: Record "Record Export Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePopulatePaymentData(var TempFatturaLine: Record "Fattura Line"; TempFatturaHeader: Record "Fattura Header"; var TempXMLBuffer: record "XML Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePopulateOrderData(var TempFatturaLine: Record "Fattura Line" temporary; TempFatturaHeader: Record "Fattura Header" temporary; var TempXMLBuffer: Record "XML Buffer" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTryCreateFatturaElettronicaBodyOnAfterTempFatturaLineSetFiltersForDocument(var TempFatturaLine: Record "Fattura Line" temporary; TempFatturaHeader: Record "Fattura Header" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsValidFatturaCharacter(InputChar: Char; var IsValid: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFatturaValidCharacter(InputChar: Char; var ReplacementText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGenerateXmlFile(var RecordExportBuffer: Record "Record Export Buffer")
    begin
    end;
}

