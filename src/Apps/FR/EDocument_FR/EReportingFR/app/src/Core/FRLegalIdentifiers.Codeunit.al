// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.IO.Peppol;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.EMail;
using System.IO;
using System.Utilities;

codeunit 10971 "FR Legal Identifiers"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    procedure IsSIRENFormatValid(Value: Text): Boolean
    begin
        exit((StrLen(Value) = 9) and (DelChr(Value, '=', '0123456789') = ''));
    end;

    procedure IsSIRETFormatValid(Value: Text): Boolean
    begin
        exit((StrLen(Value) = 14) and (DelChr(Value, '=', '0123456789') = ''));
    end;

    procedure ValidatePair(SIREN: Text; SIRET: Text; Owner: Variant)
    begin
        if (SIREN <> '') and not IsSIRENFormatValid(SIREN) then
            RaiseSetupError(InvalidSIRENErr, Owner);
        if (SIRET <> '') and not IsSIRETFormatValid(SIRET) then
            RaiseSetupError(InvalidSIRETErr, Owner);
        if (SIREN <> '') and (SIRET <> '') then
            if CopyStr(SIRET, 1, 9) <> SIREN then
                RaiseSetupError(ConflictingIdentifiersErr, Owner);
    end;

    procedure ResolveSIREN(SIREN: Text; SIRET: Text; Required: Boolean; Owner: Variant): Text[9]
    begin
        ValidatePair(SIREN, SIRET, Owner);
        if SIREN <> '' then
            exit(CopyStr(SIREN, 1, 9));
        if SIRET <> '' then
            exit(CopyStr(SIRET, 1, 9));
        if Required then
            RaiseSetupError(RequiredSIRENErr, Owner);
    end;

    procedure GetCompanySIREN(CompanyInformation: Record "Company Information"): Text[9]
    begin
        exit(ResolveSIREN(CompanyInformation."Registration No.", CompanyInformation."SIRET No.", true, CompanyInformation));
    end;

    procedure GetCustomerSIREN(Customer: Record Customer; Required: Boolean): Text[9]
    var
        SIREN: Text[9];
    begin
        SIREN := ResolveSIREN(Customer."SIREN No.", Customer."FR SIRET No.", Required, Customer);
        if IsFrenchParty(Customer."Country/Region Code") then
            CheckLegacyConflict(SIREN, Customer."FR SIRET No.", Customer."Registration Number", Customer);
        exit(SIREN);
    end;

    procedure GetVendorSIREN(Vendor: Record Vendor): Text[9]
    var
        SIREN: Text[9];
        SIRET: Text[14];
    begin
        SIRET := GetVendorSIRET(Vendor);
        SIREN := ResolveSIREN(Vendor."SIREN No.", SIRET, false, Vendor);
        if IsFrenchParty(Vendor."Country/Region Code") then
            CheckLegacyConflict(SIREN, SIRET, Vendor."Registration Number", Vendor);
        exit(SIREN);
    end;

    procedure GetVendorSIRET(Vendor: Record Vendor): Text[14]
    begin
        if IsFrenchParty(Vendor."Country/Region Code") and IsSIRETFormatValid(Vendor."Registration Number") then
            exit(CopyStr(Vendor."Registration Number", 1, 14));
    end;

    local procedure CheckLegacyConflict(SIREN: Text; SIRET: Text; RegistrationNumber: Text; Owner: Variant)
    begin
        if IsSIRENFormatValid(RegistrationNumber) or IsSIRETFormatValid(RegistrationNumber) then begin
            if SIREN <> CopyStr(RegistrationNumber, 1, 9) then
                RaiseSetupError(LegacyIdentifiersErr, Owner);
            if IsSIRETFormatValid(RegistrationNumber) and (SIRET <> '') then
                if SIRET <> RegistrationNumber then
                    RaiseSetupError(LegacyIdentifiersErr, Owner);
        end;
    end;

    procedure IsFrenchParty(CountryCode: Code[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
    begin
        if CountryCode = '' then
            if CompanyInformation.Get() then
                CountryCode := CompanyInformation."Country/Region Code";
        if CountryRegion.Get(CountryCode) then
            exit(CountryRegion."ISO Code" = 'FR');
        exit(CountryCode = 'FR');
    end;

    procedure IsDomesticB2B(Customer: Record Customer) Result: Boolean
    begin
        Result := IsFrenchParty(Customer."Country/Region Code") and
            (Customer."FR E-Reporting Trans. Type" = Customer."FR E-Reporting Trans. Type"::" ");
        OnAfterIsDomesticB2B(Customer, Result);
    end;

    procedure Is0225FormatValid(Address: Text): Boolean
    begin
        if (StrLen(Address) < 9) or (StrLen(Address) > 125) then
            exit(false);
        if not IsSIRENFormatValid(CopyStr(Address, 1, 9)) then
            exit(false);
        if StrLen(Address) = 9 then
            exit(true);
        exit((StrLen(Address) > 10) and (CopyStr(Address, 10, 1) = '_') and
            (DelChr(CopyStr(Address, 11), '=', 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.') = ''));
    end;

    procedure ValidateEndpoint(Address: Text; Scheme: Enum "Electronic Address Scheme"; Require0225: Boolean; SIREN: Text; Owner: Variant)
    var
        MailManagement: Codeunit "Mail Management";
        Valid: Boolean;
        Handled: Boolean;
    begin
        if (Address = '') or (StrLen(Address) > 125) then
            RaiseSetupError(EndpointLengthErr, Owner);
        case Scheme of
            Scheme::"0002":
                Valid := IsSIRENFormatValid(Address) or IsSIRETFormatValid(Address);
            Scheme::"0009":
                Valid := IsSIRETFormatValid(Address);
            Scheme::"0225":
                Valid := Is0225FormatValid(Address);
            Scheme::"9957":
                Valid := IsFrenchVATFormatValid(Address);
            Scheme::EM:
                Valid := MailManagement.CheckValidEmailAddress(Address);
            Scheme::" ":
                RaiseSetupError(EndpointSchemeRequiredErr, Owner);
            else begin
                OnValidateAdditionalEndpoint(Address, Scheme, Valid, Handled);
                if not Handled then
                    RaiseSetupError(UnsupportedEndpointSchemeErr, Owner);
            end;
        end;
        if not Valid then
            RaiseSetupError(InvalidEndpointErr, Owner);
        if Require0225 then
            if (Scheme <> Scheme::"0225") or not IsSIRENFormatValid(SIREN) or
               (CopyStr(Address, 1, 9) <> SIREN)
            then
                RaiseSetupError(ReceivingEndpointErr, Owner);
    end;

    procedure IsFrenchVATFormatValid(Address: Text): Boolean
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        if StrLen(Address) <> 13 then
            exit(false);
        if DelChr(CopyStr(Address, 3, 2), '=', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789') <> '' then
            exit(false);
        exit(VATRegistrationNoFormat.Compare(CopyStr(Address, 1, 20), 'FR??#########'));
    end;

    procedure GetCustomerEndpoint(Customer: Record Customer; ServiceCode: Code[20]; SelfBilling: Boolean; var Address: Text[250]; var Scheme: Enum "Electronic Address Scheme")
    var
        ServiceParticipant: Record "Service Participant";
        EDocHelpers: Codeunit "EDoc. Helpers";
        SIREN: Text[9];
        Require0225: Boolean;
    begin
        SIREN := GetCustomerSIREN(Customer, IsDomesticB2B(Customer));
        Require0225 := IsDomesticB2B(Customer) and not SelfBilling;
        if EDocHelpers.HasServiceParticipantAddress(ServiceCode, Enum::"E-Document Source Type"::Customer, Customer."No.", ServiceParticipant) then begin
            ValidateEndpoint(ServiceParticipant."Participant Identifier", ServiceParticipant."FR Identifier Scheme", Require0225, SIREN, ServiceParticipant);
            Address := ServiceParticipant."Participant Identifier";
            Scheme := ServiceParticipant."FR Identifier Scheme";
            exit;
        end;

        Clear(Address);
        Scheme := Scheme::" ";
        if Customer."FR Electronic Address" <> '' then begin
            Address := Customer."FR Electronic Address";
            Scheme := Customer."FR Elec. Address Scheme";
        end else begin
            // EM was the original default; without an address it does not define an explicit route.
            if not (Customer."FR Elec. Address Scheme" in [Customer."FR Elec. Address Scheme"::" ", Customer."FR Elec. Address Scheme"::EM]) then
                RaiseSetupError(InvalidEndpointErr, Customer);
            if SIREN <> '' then begin
                Address := SIREN;
                Scheme := Scheme::"0225";
            end;
        end;
        if not EDocHelpers.GetBuyerElectronicAddress(Customer, Address) then
            RaiseSetupError(InvalidEndpointErr, Customer);
        ValidateEndpoint(Address, Scheme, Require0225, SIREN, Customer);
    end;

    procedure GetCompanyEndpoint(CompanyInformation: Record "Company Information"; ServiceCode: Code[20]; Require0225: Boolean; var Address: Text[250]; var Scheme: Enum "Electronic Address Scheme")
    var
        ServiceParticipant: Record "Service Participant";
        EDocHelpers: Codeunit "EDoc. Helpers";
        SIREN: Text[9];
    begin
        SIREN := GetCompanySIREN(CompanyInformation);
        if EDocHelpers.HasServiceParticipantAddress(ServiceCode, Enum::"E-Document Source Type"::Company, '', ServiceParticipant) then begin
            ValidateEndpoint(ServiceParticipant."Participant Identifier", ServiceParticipant."FR Identifier Scheme", Require0225, SIREN, ServiceParticipant);
            Address := ServiceParticipant."Participant Identifier";
            Scheme := ServiceParticipant."FR Identifier Scheme";
            exit;
        end;
        if Require0225 then begin
            Address := SIREN;
            Scheme := Scheme::"0225";
        end else
            if CompanyInformation."SIRET No." <> '' then begin
                Address := CompanyInformation."SIRET No.";
                Scheme := Scheme::"0009";
            end else begin
                Address := SIREN;
                Scheme := Scheme::"0002";
            end;
        ValidateEndpoint(Address, Scheme, Require0225, SIREN, CompanyInformation);
    end;

    procedure SchemeCode(Scheme: Enum "Electronic Address Scheme"): Text
    begin
        exit(Scheme.Names.Get(Scheme.Ordinals.IndexOf(Scheme.AsInteger())));
    end;

    procedure ReadUBLIdentifiers(Document: XmlDocument; Namespaces: XmlNamespaceManager; PartyPath: Text; var SIREN: Text; var SIRET: Text)
    begin
        SIREN := ReadQualifiedIdentifier(Document, Namespaces, PartyPath + '/cac:PartyLegalEntity/cbc:CompanyID[@schemeID="0002"]');
        SIRET := ReadQualifiedIdentifier(Document, Namespaces, PartyPath + '/cac:PartyIdentification/cbc:ID[@schemeID="0009"]');
        ValidateIncomingIdentifiers(SIREN, SIRET);
    end;

    procedure ReadCIIIdentifiers(Document: XmlDocument; Namespaces: XmlNamespaceManager; PartyPath: Text; var SIREN: Text; var SIRET: Text)
    begin
        SIREN := ReadQualifiedIdentifier(Document, Namespaces, PartyPath + '/ram:SpecifiedLegalOrganization/ram:ID[@schemeID="0002"]');
        SIRET := ReadQualifiedIdentifier(Document, Namespaces, PartyPath + '/ram:GlobalID[@schemeID="0009"]');
        ValidateIncomingIdentifiers(SIREN, SIRET);
    end;

    local procedure ReadQualifiedIdentifier(Document: XmlDocument; Namespaces: XmlNamespaceManager; Path: Text): Text
    var
        Nodes: XmlNodeList;
        Node: XmlNode;
    begin
        Document.SelectNodes(Path, Namespaces, Nodes);
        if Nodes.Count > 1 then
            Error(DuplicateIdentifierErr);
        if Nodes.Count = 0 then
            exit('');
        Nodes.Get(1, Node);
        if Node.AsXmlElement().InnerText() = '' then
            Error(EmptyIdentifierErr);
        exit(Node.AsXmlElement().InnerText());
    end;

    procedure ValidateIncomingIdentifiers(SIREN: Text; SIRET: Text)
    begin
        if (SIREN <> '') and not IsSIRENFormatValid(SIREN) then
            Error(InvalidSIRENErr);
        if SIRET <> '' then begin
            if not IsSIRETFormatValid(SIRET) then
                Error(InvalidSIRETErr);
            if SIREN = '' then
                Error(IncomingSIRENRequiredErr);
            if CopyStr(SIRET, 1, 9) <> SIREN then
                Error(ConflictingIdentifiersErr);
        end;
    end;

    procedure ValidateGLN(GLN: Text): Text[13]
    begin
        if GLN <> '' then
            if (StrLen(GLN) <> 13) or (DelChr(GLN, '=', '0123456789') <> '') then
                Error(InvalidGLNErr);
        exit(CopyStr(GLN, 1, 13));
    end;

    procedure FindVendor(SIREN: Text; SIRET: Text; VAT: Text; GLN: Text; VendorName: Text; VendorAddress: Text; ServiceCode: Code[20]; ParticipantID: Text) VendorNo: Code[20]
    var
        Vendor: Record Vendor;
        TempCandidates: Record Vendor temporary;
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        VendorSIREN: Text[9];
        VendorSIRET: Text[14];
    begin
        ValidateIncomingIdentifiers(SIREN, SIRET);
        ValidateGLN(GLN);
        if (StrLen(VAT) > MaxStrLen(Vendor."VAT Registration No.")) or (StrLen(GLN) > MaxStrLen(Vendor.GLN)) then
            Error(MatchingIdentifierTooLongErr);
        if SIRET <> '' then begin
            Vendor.SetCurrentKey("Registration Number");
            Vendor.SetRange("Registration Number", SIRET);
            AddVendorCandidates(Vendor, TempCandidates, true, true);
            SelectCandidate(TempCandidates, VendorNo);
            TempCandidates.Reset();
            TempCandidates.DeleteAll();
        end;
        if SIREN <> '' then begin
            Vendor.Reset();
            Vendor.SetCurrentKey("SIREN No.");
            Vendor.SetRange("SIREN No.", SIREN);
            AddVendorCandidates(Vendor, TempCandidates, VendorNo = '', false);
            Vendor.SetCurrentKey("Registration Number");
            Vendor.SetRange("SIREN No.", '');
            Vendor.SetFilter("Registration Number", '%1*', SIREN);
            AddVendorCandidates(Vendor, TempCandidates, VendorNo = '', true);
            SelectCandidate(TempCandidates, VendorNo);
        end;
        if VAT <> '' then begin
            Vendor.Reset();
            Vendor.SetRange("VAT Registration No.", VAT);
            SelectCandidate(Vendor, VendorNo);
        end;
        if GLN <> '' then begin
            Vendor.Reset();
            Vendor.SetRange(GLN, GLN);
            SelectCandidate(Vendor, VendorNo);
        end;
        if ParticipantID <> '' then begin
            TempCandidates.Reset();
            TempCandidates.DeleteAll();
            AddParticipantCandidates(ServiceCode, ParticipantID, TempCandidates);
            SelectCandidate(TempCandidates, VendorNo);
        end;
        if (VendorNo = '') and (VendorName <> '') then
            VendorNo := EDocumentImportHelper.FindVendorByNameAndAddressWithNotification(VendorName, VendorAddress, 0, true);
        if VendorNo = '' then
            exit('');

        Vendor.Get(VendorNo);
        VendorSIREN := GetVendorSIREN(Vendor);
        if (SIREN <> '') and (VendorSIREN <> '') and (SIREN <> VendorSIREN) then
            RaiseSetupError(ConflictingMatchErr, Vendor);
        VendorSIRET := GetVendorSIRET(Vendor);
        if (SIRET <> '') and (VendorSIRET <> '') and (SIRET <> VendorSIRET) then
            RaiseSetupError(ConflictingMatchErr, Vendor);
    end;

    local procedure AddVendorCandidates(var Vendor: Record Vendor; var TempCandidates: Record Vendor temporary; ValidateIdentity: Boolean; RequireLegacySIRET: Boolean)
    begin
        if Vendor.FindSet() then
            repeat
                if not RequireLegacySIRET or (GetVendorSIRET(Vendor) <> '') then begin
                    if ValidateIdentity then
                        GetVendorSIREN(Vendor);
                    if not TempCandidates.Get(Vendor."No.") then begin
                        TempCandidates := Vendor;
                        TempCandidates.Insert();
                    end;
                end;
            until Vendor.Next() = 0;
    end;

    local procedure AddParticipantCandidates(ServiceCode: Code[20]; ParticipantID: Text; var TempCandidates: Record Vendor temporary)
    var
        ServiceParticipant: Record "Service Participant";
        Vendor: Record Vendor;
    begin
        ServiceParticipant.SetRange("Participant Type", ServiceParticipant."Participant Type"::Vendor);
        ServiceParticipant.SetRange("Participant Identifier", ParticipantID);
        ServiceParticipant.SetRange(Service, ServiceCode);
        if ServiceParticipant.IsEmpty() then
            ServiceParticipant.SetRange(Service);
        if ServiceParticipant.FindSet() then
            repeat
                Vendor.Get(ServiceParticipant.Participant);
                if not TempCandidates.Get(Vendor."No.") then begin
                    TempCandidates := Vendor;
                    TempCandidates.Insert();
                end;
            until ServiceParticipant.Next() = 0;
    end;

    local procedure SelectCandidate(var Candidates: Record Vendor; var VendorNo: Code[20])
    begin
        if Candidates.IsEmpty() then
            exit;
        if VendorNo <> '' then begin
            Candidates.SetRange("No.", VendorNo);
            if Candidates.IsEmpty() then
                Error(ConflictingMatchErr);
            Candidates.SetRange("No.");
            exit;
        end;
        Candidates.FindSet();
        VendorNo := Candidates."No.";
        if Candidates.Next() <> 0 then
            Error(AmbiguousVendorErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EDoc Import PEPPOL BIS 3.0", OnBeforeParseAccountingSupplierParty, '', false, false)]
    local procedure ReadLegacyPeppolSupplier(var EDocument: Record "E-Document"; var TempXMLBuffer: Record "XML Buffer" temporary; RootPath: Text; var IsHandled: Boolean)
    var
        EDocumentService: Record "E-Document Service";
        Vendor: Record Vendor;
        TempCopy: Record "XML Buffer" temporary;
        EDocHelpers: Codeunit "EDoc. Helpers";
        EDocumentHelper: Codeunit "E-Document Helper";
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        SourceBlob: Codeunit "Temp Blob";
        Document: XmlDocument;
        Namespaces: XmlNamespaceManager;
        SourceStream: InStream;
        SIREN: Text;
        SIRET: Text;
        PartyPath: Text;
        VAT: Text;
        GLN: Text;
        VendorName: Text;
        VendorAddress: Text;
        ParticipantID: Text;
        VendorNo: Code[20];
    begin
        if IsHandled then
            exit;
        TempCopy.Copy(TempXMLBuffer, true);
        if not TempCopy.Save(SourceBlob) then
            Error(InvalidIncomingDocumentErr);
        SourceBlob.CreateInStream(SourceStream, TextEncoding::UTF8);
        XmlDocument.ReadFrom(SourceStream, Document);
        Namespaces.NameTable(Document.NameTable());
        Namespaces.AddNamespace('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        Namespaces.AddNamespace('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
        PartyPath := '/*/cac:AccountingSupplierParty/cac:Party';
        ReadUBLIdentifiers(Document, Namespaces, PartyPath, SIREN, SIRET);
        VAT := EDocHelpers.GetNodeValue(Document, Namespaces, PartyPath + '/cac:PartyTaxScheme[cac:TaxScheme/cbc:ID="VAT"]/cbc:CompanyID');
        GLN := EDocHelpers.GetNodeValue(Document, Namespaces, PartyPath + '/cbc:EndpointID[@schemeID="0088"]');
        VendorName := EDocHelpers.GetNodeValue(Document, Namespaces, PartyPath + '/cac:PartyName/cbc:Name');
        VendorAddress := EDocHelpers.GetNodeValue(Document, Namespaces, PartyPath + '/cac:PostalAddress/cbc:StreetName');
        ParticipantID := EDocHelpers.GetNodeValue(Document, Namespaces, PartyPath + '/cbc:EndpointID');
        if ParticipantID <> '' then
            ParticipantID := EDocHelpers.GetNodeValue(Document, Namespaces, PartyPath + '/cbc:EndpointID/@schemeID') + ':' + ParticipantID;
        EDocumentHelper.GetEdocumentService(EDocument, EDocumentService);
        VendorNo := FindVendor(SIREN, SIRET, VAT, GLN, VendorName, VendorAddress, EDocumentService.Code, ParticipantID);
        EDocument."Bill-to/Pay-to Name" := CopyStr(VendorName, 1, MaxStrLen(EDocument."Bill-to/Pay-to Name"));
        Vendor := EDocumentImportHelper.GetVendor(EDocument, VendorNo);
        EDocument."Bill-to/Pay-to No." := Vendor."No.";
        if Vendor."No." <> '' then
            EDocument."Bill-to/Pay-to Name" := Vendor.Name;
        IsHandled := true;
    end;

    procedure RaiseSetupError(Message: Text; Owner: Variant)
    var
        OwnerRef: RecordRef;
        SetupError: ErrorInfo;
    begin
        OwnerRef.GetTable(Owner);
        SetupError.Message(Message);
        SetupError.DataClassification := DataClassification::CustomerContent;
        SetupError.RecordId(OwnerRef.RecordId);
        case OwnerRef.Number of
            Database::Customer:
                SetupError.PageNo(Page::"Customer Card");
            Database::Vendor:
                SetupError.PageNo(Page::"Vendor Card");
            Database::"Company Information":
                SetupError.PageNo(Page::"Company Information");
            Database::"Service Participant":
                SetupError.PageNo(Page::"Service Participants");
        end;
        if SetupError.PageNo() <> 0 then
            SetupError.AddNavigationAction(ShowRecordLbl);
        Error(SetupError);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsDomesticB2B(Customer: Record Customer; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAdditionalEndpoint(Address: Text; Scheme: Enum "Electronic Address Scheme"; var Valid: Boolean; var Handled: Boolean)
    begin
    end;

    var
        InvalidSIRENErr: Label 'SIREN must contain exactly nine digits.';
        InvalidSIRETErr: Label 'SIRET must contain exactly fourteen digits.';
        ConflictingIdentifiersErr: Label 'The first nine digits of SIRET must match SIREN.';
        RequiredSIRENErr: Label 'Specify a SIREN or a valid SIRET for this party before creating the French electronic invoice.';
        LegacyIdentifiersErr: Label 'Review the dedicated SIREN and SIRET fields and the legacy Registration Number. The French legal identifiers are missing or conflicting.';
        EndpointLengthErr: Label 'The electronic address must contain between 1 and 125 characters.';
        EndpointSchemeRequiredErr: Label 'Specify a scheme for the electronic address.';
        UnsupportedEndpointSchemeErr: Label 'The electronic address scheme is not supported for this French invoice.';
        InvalidEndpointErr: Label 'Specify an electronic address and scheme with a valid scheme-specific format.';
        ReceivingEndpointErr: Label 'The receiving address for French domestic B2B e-invoicing must use scheme 0225 and begin with the receiving party''s SIREN.';
        DuplicateIdentifierErr: Label 'The incoming document contains more than one legal identifier with the same scheme.';
        EmptyIdentifierErr: Label 'A qualified legal identifier in the incoming document is empty.';
        IncomingSIRENRequiredErr: Label 'The incoming document must supply a legal SIREN with scheme 0002 when it supplies a SIRET with scheme 0009.';
        MatchingIdentifierTooLongErr: Label 'An incoming VAT or GLN identifier exceeds the supported length. Correct it before matching a vendor.';
        ConflictingMatchErr: Label 'The incoming identifiers refer to different vendor identities or establishments. Review the vendor and incoming document.';
        AmbiguousVendorErr: Label 'More than one vendor matches the incoming identifier. Select a vendor manually.';
        InvalidIncomingDocumentErr: Label 'The incoming document could not be read for French supplier identification.';
        InvalidGLNErr: Label 'A GLN with scheme 0088 must contain exactly thirteen digits.';
        ShowRecordLbl: Label 'Show record';
}
