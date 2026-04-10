// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Address;
using System.Telemetry;
using System.Utilities;

codeunit 11001 "VIES ELMA Xml"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        VATReportSetup: Record "VAT Report Setup";
        XMLDoc: XmlDocument;
        ELMANamespace: Text;
        ELANNamespace: Text;
        ZMNamespace: Text;
        ELMANamespacePrefix: Text;
        ELANNamespacePrefix: Text;
        ZMNamespacePrefix: Text;
        BOPUserAccountIDMissingErr: Label 'The BOP User Account ID must be specified in the VAT Report Setup before generating the ELMA XML file.';
        ELMANamespaceTxt: Label 'http://www.itzbund.de/elan', Locked = true;
        ELANNamespaceTxt: Label 'http://www.itzbund.de/elan/elemente', Locked = true;
        ZMNamespaceTxt: Label 'http://www.itzbund.de/ZM/01', Locked = true;
        ELMANamespacePrefixTxt: Label 'n1', Locked = true;
        ELANNamespacePrefixTxt: Label 'elan', Locked = true;
        ZMNamespacePrefixTxt: Label 'zm', Locked = true;

    procedure Create(VATReportHeader: Record "VAT Report Header"; var FileID: Text; var TempBlob: Codeunit "Temp Blob")
    var
        VATReportLine: Record "VAT Report Line";
        Telemetry: Codeunit Telemetry;
        RootElement: XmlElement;
        ELMAHeaderElement: XmlElement;
        ZMSElement: XmlElement;
        UnternehmerElement: XmlElement;
        ZMElement: XmlElement;
        BlobOutStream: OutStream;
        XMLDocText: Text;
    begin
        Telemetry.LogMessage('0000R2T', 'Create VIES ELMA xml started', Verbosity::Normal, DataClassification::SystemMetadata);
        InitializeNamespaces();

        VATReportSetup.Get();
        if VATReportSetup."BOP User Account ID" = '' then
            Error(BOPUserAccountIDMissingErr);

        FileID := CreateUUID();

        XMLDoc := XmlDocument.Create();
        XMLDoc.SetDeclaration(XmlDeclaration.Create('1.0', 'UTF-8', 'yes'));

        // Create root ELMA element with all namespace declarations
        RootElement := CreateELMARoot();
        XMLDoc.Add(RootElement);

        // Add ELMAHeader
        ELMAHeaderElement := CreateELMAHeader(VATReportHeader, FileID);
        RootElement.Add(ELMAHeaderElement);

        // Add zms element
        ZMSElement := CreateZMSElement();
        RootElement.Add(ZMSElement);

        // Add unternehmer (entrepreneur) element
        UnternehmerElement := CreateEntrepreneurElement(VATReportHeader);
        ZMSElement.Add(UnternehmerElement);

        // Add zm element (the actual report)
        ZMElement := CreateVIESReportElement(VATReportHeader);
        UnternehmerElement.Add(ZMElement);

        // Add report lines
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.SetRange("Line Type", VATReportLine."Line Type"::New);
        if VATReportLine.FindSet() then
            repeat
                AddVIESReportLineElement(ZMElement, VATReportLine);
            until VATReportLine.Next() = 0;

        if VATReportSetup."Export Cancellation Lines" then
            VATReportLine.SetFilter("Line Type", '<>%1', VATReportLine."Line Type"::New)
        else
            VATReportLine.SetRange("Line Type", VATReportLine."Line Type"::Correction);

        if VATReportLine.FindSet() then
            repeat
                AddVIESReportLineElement(ZMElement, VATReportLine);
            until VATReportLine.Next() = 0;

        // Write to TempBlob
        TempBlob.CreateOutStream(BlobOutStream, TextEncoding::UTF8);
        XMLDoc.WriteTo(XMLDocText);
        BlobOutStream.WriteText(XMLDocText);

        Telemetry.LogMessage('0000R2U', 'Create VIES ELMA xml completed', Verbosity::Normal, DataClassification::SystemMetadata);
    end;

#if not CLEAN29
    [Obsolete('Use the overload that returns FileID instead.', '29.0')]
    procedure Create(VATReportHeader: Record "VAT Report Header"; var TempBlob: Codeunit "Temp Blob")
    var
        FileID: Text;
    begin
        Create(VATReportHeader, FileID, TempBlob);
    end;
#endif

    local procedure InitializeNamespaces()
    begin
        ELMANamespace := ELMANamespaceTxt;
        ELANNamespace := ELANNamespaceTxt;
        ZMNamespace := ZMNamespaceTxt;

        ELMANamespacePrefix := ELMANamespacePrefixTxt;
        ELANNamespacePrefix := ELANNamespacePrefixTxt;
        ZMNamespacePrefix := ZMNamespacePrefixTxt;
    end;

    local procedure CreateELMARoot(): XmlElement
    var
        RootElement: XmlElement;
    begin
        RootElement := XmlElement.Create('ELMA', ELMANamespace);
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration(ELMANamespacePrefix, ELMANamespace));
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration(ELANNamespacePrefix, ELANNamespace));
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration(ZMNamespacePrefix, ZMNamespace));
        RootElement.Add(XmlAttribute.Create('elmaVersion', '2'));
        RootElement.Add(XmlAttribute.Create('verfVersion', '8.0.0'));
        exit(RootElement);
    end;

    local procedure CreateELMAHeader(VATReportHeader: Record "VAT Report Header"; FileID: Text): XmlElement
    var
        HeaderElement: XmlElement;
        TransportRouteElement: XmlElement;
        IdentificationElement: XmlElement;
        TimestampsElement: XmlElement;
    begin
        HeaderElement := XmlElement.Create('ELMAHeader', ELANNamespace);

        // BenutzerkontoID is mandatory
        HeaderElement.Add(CreateELANElement('BenutzerkontoID', VATReportSetup."BOP User Account ID"));

        TransportRouteElement := XmlElement.Create('Transportweg', ELANNamespace);
        TransportRouteElement.Add(CreateELANElement('Datenart', 'ZMDO'));
        TransportRouteElement.Add(CreateELANElement('Umgebung', GetEnvironment(VATReportHeader."Test Export")));
        HeaderElement.Add(TransportRouteElement);

        IdentificationElement := XmlElement.Create('Identifizierung', ELANNamespace);
        IdentificationElement.Add(CreateELANElement('EingangsID', FileID));
        HeaderElement.Add(IdentificationElement);

        TimestampsElement := XmlElement.Create('Zeitpunkte', ELANNamespace);
        TimestampsElement.Add(CreateELANElement('Erstellung', FormatDateTime(CurrentDateTime())));
        HeaderElement.Add(TimestampsElement);

        exit(HeaderElement);
    end;

    local procedure CreateELANElement(ElementName: Text; ElementValue: Text): XmlElement
    var
        Element: XmlElement;
    begin
        Element := XmlElement.Create(ElementName, ELANNamespace, ElementValue);
        exit(Element);
    end;

    local procedure CreateZMSElement(): XmlElement
    var
        ZMSElement: XmlElement;
    begin
        ZMSElement := XmlElement.Create('zms', ZMNamespace);
        ZMSElement.Add(XmlAttribute.Create('version', '000008'));
        exit(ZMSElement);
    end;

    local procedure CreateEntrepreneurElement(VATReportHeader: Record "VAT Report Header"): XmlElement
    var
        EntrepreneurElement: XmlElement;
        ApprovalNumberElement: XmlElement;
        AddressElement: XmlElement;
    begin
        EntrepreneurElement := XmlElement.Create('unternehmer', ZMNamespace);

        // German VAT ID (must be DE + 9 digits)
        EntrepreneurElement.Add(CreateZMElement('deUStIdNr', FormatDEVATRegNo(VATReportHeader."VAT Registration No.")));

        // Approval number
        ApprovalNumberElement := XmlElement.Create('zulassNr', ZMNamespace);
        ApprovalNumberElement.Add(CreateZMElement('zulnr1', 'L'));
        ApprovalNumberElement.Add(CreateZMElement('zulnr2', '1111111'));
        EntrepreneurElement.Add(ApprovalNumberElement);

        // Address
        AddressElement := CreateAddressElement(VATReportHeader);
        EntrepreneurElement.Add(AddressElement);

        exit(EntrepreneurElement);
    end;

    local procedure CreateAddressElement(VATReportHeader: Record "VAT Report Header"): XmlElement
    var
        AddressElement: XmlElement;
    begin
        AddressElement := XmlElement.Create('anschrift', ZMNamespace);

        AddressElement.Add(CreateZMElement('name', VATReportHeader."Company Name"));
        AddressElement.Add(CreateZMElement('strasse', VATReportHeader."Company Address"));
        if VATReportHeader."Post Code" <> '' then
            AddressElement.Add(CreateZMElement('plz', CopyStr(VATReportHeader."Post Code", 1, 12)));
        AddressElement.Add(CreateZMElement('ort', VATReportHeader.City));

        // ISO-3166 Alpha-2 country/region code
        AddressElement.Add(CreateZMElement('staat', VATReportHeader."ISO Country/Region Code"));

        exit(AddressElement);
    end;

    local procedure CreateVIESReportElement(VATReportHeader: Record "VAT Report Header"): XmlElement
    var
        ZMElement: XmlElement;
        ReportingPeriodElement: XmlElement;
    begin
        ZMElement := XmlElement.Create('zm', ZMNamespace);
        ZMElement.Add(XmlAttribute.Create('meldeart', GetReportType(VATReportHeader)));
        ZMElement.Add(XmlAttribute.Create('uuid', CreateUUID()));

        ReportingPeriodElement := XmlElement.Create('mzr', ZMNamespace);
        ReportingPeriodElement.Add(CreateZMElement('quart', Format(GetPeriodCode(VATReportHeader))));
        ReportingPeriodElement.Add(CreateZMElement('jahr', Format(VATReportHeader."Report Year")));
        ZMElement.Add(ReportingPeriodElement);

        // Notice or revocation (optional, mutually exclusive)
        if VATReportHeader.Notice then
            ZMElement.Add(CreateZMElement('anzeige', 'true'))
        else
            if VATReportHeader.Revocation then
                ZMElement.Add(CreateZMElement('widerruf', 'true'));

        exit(ZMElement);
    end;

    local procedure CreateZMElement(ElementName: Text; ElementValue: Text): XmlElement
    var
        Element: XmlElement;
    begin
        Element := XmlElement.Create(ElementName, ZMNamespace, ElementValue);
        exit(Element);
    end;

    local procedure AddVIESReportLineElement(var ZMElement: XmlElement; VATReportLine: Record "VAT Report Line")
    var
        ZMZeileElement: XmlElement;
        CountryCode: Code[2];
        VATRegNoWithoutCountry: Text[12];
    begin
        // Skip zero base lines except for corrections
        if (VATReportLine.Base = 0) and (VATReportLine."Line Type" <> VATReportLine."Line Type"::Correction) then
            exit;

        ZMZeileElement := XmlElement.Create('zmZeile', ZMNamespace);
        ZMZeileElement.Add(XmlAttribute.Create('uuid', CreateUUID()));

        // Parse VAT Registration No. to get country code and number
        GetVATRegNoParts(VATReportLine, CountryCode, VATRegNoWithoutCountry);

        // Country code
        ZMZeileElement.Add(CreateZMElement('lkz', CountryCode));

        // Foreign VAT ID without country code
        ZMZeileElement.Add(CreateZMElement('auslUStIdNrOhneLKZ', VATRegNoWithoutCountry));

        // Turnover type: L=Lieferung (Goods delivery), S=Sonstige Leistung (Services), D=Dreiecksgeschäft (Triangular trade)
        ZMZeileElement.Add(CreateZMElement('umsatzart', GetTurnoverType(VATReportLine)));

        // Amount (rounded to integer)
        ZMZeileElement.Add(CreateZMElement('betrag', Format(GetAmount(VATReportLine))));

        ZMElement.Add(ZMZeileElement);
    end;

    local procedure GetVATRegNoParts(VATReportLine: Record "VAT Report Line"; var CountryCode: Code[2]; var VATRegNoWithoutCountry: Text[12])
    var
        CountryRegion: Record "Country/Region";
        VATRegNo: Text;
    begin
        VATRegNo := VATReportLine."VAT Registration No.";

        if CountryRegion.Get(VATReportLine."Country/Region Code") then begin
            CountryCode := CopyStr(CountryRegion."EU Country/Region Code", 1, 2);
            // Remove country code prefix if present
            if CopyStr(VATRegNo, 1, StrLen(CountryRegion."EU Country/Region Code")) = CountryRegion."EU Country/Region Code" then
                VATRegNo := CopyStr(VATRegNo, StrLen(CountryRegion."EU Country/Region Code") + 1);
        end else
            CountryCode := CopyStr(VATReportLine."Country/Region Code", 1, 2);

        VATRegNoWithoutCountry := CopyStr(VATRegNo, 1, 12);
    end;

    local procedure GetTurnoverType(VATReportLine: Record "VAT Report Line"): Text[1]
    begin
        if VATReportLine."EU Service" then
            exit('S');  // Sonstige Leistung (Services)

        if VATReportLine."EU 3-Party Trade" then
            exit('D');  // Dreiecksgeschäft (Triangular trade)

        exit('L');      // Lieferung (Goods delivery)
    end;

    local procedure GetAmount(VATReportLine: Record "VAT Report Line"): Integer
    begin
        if VATReportLine."Line Type" = VATReportLine."Line Type"::Cancellation then
            exit(0);

        exit(Round(VATReportLine.Base, 1));
    end;

    local procedure GetReportType(VATReportHeader: Record "VAT Report Header"): Text[2]
    begin
        // 10 = Erstmeldung (first/standard report)
        // 11 = berichtigte Anmeldung (corrective report)
        if VATReportHeader."VAT Report Type" = VATReportHeader."VAT Report Type"::Corrective then
            exit('11');

        exit('10');
    end;

    local procedure GetPeriodCode(VATReportHeader: Record "VAT Report Header"): Integer
    begin
        // According to XSD:
        // 1-4 = Quarters
        // 5 = Annual
        // 11-14 = Bi-monthly (Jan-Feb, Apr-May, Jul-Aug, Oct-Nov)
        // 21-32 = Monthly (Jan=21, Feb=22, ..., Dec=32)
        case VATReportHeader."Report Period Type" of
            VATReportHeader."Report Period Type"::Quarter:
                exit(VATReportHeader."Report Period No.");  // 1-4
            VATReportHeader."Report Period Type"::Month:
                exit(VATReportHeader."Report Period No." + 20);  // 21-32
            VATReportHeader."Report Period Type"::Year:
                exit(5);
            VATReportHeader."Report Period Type"::"Bi-Monthly":
                exit(VATReportHeader."Report Period No." + 10);  // 11-14
        end;
    end;

    local procedure GetEnvironment(TestExport: Boolean): Text
    begin
        if TestExport then
            exit('TEST');
        exit('PRODUKTION');
    end;

    local procedure FormatDEVATRegNo(VATRegNo: Code[20]): Text
    var
        ResultTB: TextBuilder;
        Ch: Char;
    begin
        ResultTB.Append('DE');
        foreach Ch in VATRegNo do
            if (Ch >= '0') and (Ch <= '9') then
                ResultTB.Append(Ch);

        exit(ResultTB.ToText());
    end;

    local procedure CreateUUID(): Text[36]
    begin
        exit(CopyStr(DelChr(LowerCase(Format(CreateGuid())), '=', '{}'), 1, 36));
    end;

    local procedure FormatDateTime(DateTimeValue: DateTime): Text
    begin
        // ISO 8601 format: 2025-01-15T10:30:00
        exit(Format(DateTimeValue, 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'));
    end;

    procedure MakeFileName(VATReportHeader: Record "VAT Report Header"; FileID: Text): Text[250]
    var
        FileNamePatternLbl: Label 'ZMDO.%1.%2.xml', Locked = true;
    begin
        // File name format: ZMDO.<BenutzerkontoID>.<FileID>.xml
        VATReportSetup.Get();
        exit(StrSubstNo(FileNamePatternLbl, VATReportSetup."BOP User Account ID", FileID));
    end;

#if not CLEAN29
    [Obsolete('Use the overload with explicit FileID parameter instead.', '29.0')]
    procedure MakeFileName(VATReportHeader: Record "VAT Report Header"): Text[250]
    begin
        exit(MakeFileName(VATReportHeader, CreateUUID()));
    end;
#endif
}