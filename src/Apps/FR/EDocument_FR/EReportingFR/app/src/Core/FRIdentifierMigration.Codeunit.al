// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Utilities;

codeunit 10973 "FR Identifier Migration"
{
    Access = Internal;
    Permissions = tabledata "Error Message" = rimd;

    procedure GetMigrationTargets(SIREN: Text; SIRET: Text; RegistrationNumber: Text; Address: Text; Scheme: Enum "Electronic Address Scheme"; var NewSIREN: Code[9]; var NewSIRET: Code[14]): Text
    begin
        Clear(NewSIREN);
        Clear(NewSIRET);
        if (SIREN <> '') and not FRLegalIdentifiers.IsSIRENFormatValid(SIREN) then
            exit(InvalidCanonicalSIRENErr);
        if (SIRET <> '') and not FRLegalIdentifiers.IsSIRETFormatValid(SIRET) then
            exit(InvalidCanonicalSIRETErr);
        NewSIREN := CopyStr(SIREN, 1, MaxStrLen(NewSIREN));
        if not MergeSIRET(SIRET, NewSIREN, NewSIRET) then
            exit(ConflictingSourcesErr);
        if FRLegalIdentifiers.IsSIRENFormatValid(RegistrationNumber) then
            if not MergeSIREN(RegistrationNumber, NewSIREN) then
                exit(ConflictingSourcesErr);
        if FRLegalIdentifiers.IsSIRETFormatValid(RegistrationNumber) then
            if not MergeSIRET(RegistrationNumber, NewSIREN, NewSIRET) then
                exit(ConflictingSourcesErr);
        if (Scheme = Scheme::"0009") and (Address <> '') then begin
            if not FRLegalIdentifiers.IsSIRETFormatValid(Address) then
                exit(InvalidRoutingSIRETErr);
            if not MergeSIRET(Address, NewSIREN, NewSIRET) then
                exit(ConflictingSourcesErr);
        end;
    end;

    local procedure MergeSIREN(Candidate: Text; var SIREN: Code[9]): Boolean
    begin
        if (SIREN <> '') and (Candidate <> SIREN) then
            exit(false);
        SIREN := CopyStr(Candidate, 1, MaxStrLen(SIREN));
        exit(true);
    end;

    local procedure MergeSIRET(Candidate: Text; var SIREN: Code[9]; var SIRET: Code[14]): Boolean
    begin
        if Candidate = '' then
            exit(true);
        if (SIRET <> '') and (Candidate <> SIRET) then
            exit(false);
        if not MergeSIREN(CopyStr(Candidate, 1, 9), SIREN) then
            exit(false);
        SIRET := CopyStr(Candidate, 1, MaxStrLen(SIRET));
        exit(true);
    end;

    procedure MigrateCustomer(var Customer: Record Customer): Text
    var
        SIREN: Code[9];
        SIRET: Code[14];
        Scheme: Enum "Electronic Address Scheme";
        Issue: Text;
    begin
        if not FRLegalIdentifiers.IsFrenchParty(Customer."Country/Region Code") then
            exit('');
        Issue := GetMigrationTargets(Customer."SIREN No.", Customer."FR SIRET No.", Customer."Registration Number",
            Customer."FR Electronic Address", Customer."FR Elec. Address Scheme", SIREN, SIRET);
        if Issue <> '' then
            exit(Issue);
        Scheme := Customer."FR Elec. Address Scheme";
        if (Scheme = Scheme::" ") and (SIREN <> '') and
           FRLegalIdentifiers.Is0225FormatValid(Customer."FR Electronic Address") and
           (CopyStr(Customer."FR Electronic Address", 1, 9) = SIREN)
        then
            Scheme := Scheme::"0225";
        if (Customer."SIREN No." = SIREN) and (Customer."FR SIRET No." = SIRET) and (Customer."FR Elec. Address Scheme" = Scheme) then
            exit('');
        Customer."SIREN No." := SIREN;
        Customer."FR SIRET No." := SIRET;
        Customer."FR Elec. Address Scheme" := Scheme;
        // Avoid propagating migrated identifiers to Contact records.
        Customer.Modify(false);
    end;

    procedure MigrateVendor(var Vendor: Record Vendor): Text
    var
        SIREN: Code[9];
        SIRET: Code[14];
        Issue: Text;
    begin
        if not FRLegalIdentifiers.IsFrenchParty(Vendor."Country/Region Code") then
            exit('');
        Issue := GetMigrationTargets(Vendor."SIREN No.", '', Vendor."Registration Number",
            Vendor."FR Electronic Address", Vendor."FR Elec. Address Scheme", SIREN, SIRET);
        if Issue <> '' then
            exit(Issue);
        if Vendor."SIREN No." = SIREN then
            exit('');
        Vendor."SIREN No." := SIREN;
        Vendor.Modify(false);
    end;

    procedure PrepareCustomer(var Customer: Record Customer; var ErrorMessage: Record "Error Message"; ServiceCode: Code[20])
    var
        Issue: Text;
    begin
        if not FRLegalIdentifiers.IsFrenchParty(Customer."Country/Region Code") then
            exit;
        Issue := MigrateCustomer(Customer);
        if Issue = '' then
            if not TryCheckCustomer(Customer, ServiceCode) then
                Issue := GetLastErrorText();
        if Issue <> '' then
            LogIdentityIssue(ErrorMessage, Customer, Issue, Customer."SIREN No.", Customer."FR SIRET No.",
                Customer."Registration Number", Customer."VAT Registration No.", Customer."FR Electronic Address", Customer."FR Elec. Address Scheme");
    end;

    procedure PrepareVendor(var Vendor: Record Vendor; var ErrorMessage: Record "Error Message")
    var
        Issue: Text;
    begin
        if not FRLegalIdentifiers.IsFrenchParty(Vendor."Country/Region Code") then
            exit;
        Issue := MigrateVendor(Vendor);
        if Issue = '' then
            if not TryCheckVendor(Vendor) then
                Issue := GetLastErrorText();
        if Issue <> '' then
            LogIdentityIssue(ErrorMessage, Vendor, Issue, Vendor."SIREN No.", '',
                Vendor."Registration Number", Vendor."VAT Registration No.", Vendor."FR Electronic Address", Vendor."FR Elec. Address Scheme");
    end;

    procedure PrepareCompany(var ErrorMessage: Record "Error Message"; ServiceCode: Code[20])
    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        Vendor: Record Vendor;
        EDocumentService: Record "E-Document Service";
        ServiceParticipant: Record "Service Participant";
    begin
        if CompanyInformation.Get() then begin
            ErrorMessage.SetContext(CompanyInformation);
            if not TryCheckCompany(CompanyInformation, ServiceCode) then
                LogIdentityIssue(ErrorMessage, CompanyInformation, GetLastErrorText(), CompanyInformation."Registration No.",
                    CompanyInformation."SIRET No.", '', CompanyInformation."VAT Registration No.", '', Enum::"Electronic Address Scheme"::" ");
        end else
            ErrorMessage.LogMessage(CompanyInformation, 0, ErrorMessage."Message Type"::Error, MissingCompanyInformationErr);
        if Customer.FindSet() then
            repeat
                PrepareCustomer(Customer, ErrorMessage, ServiceCode);
            until Customer.Next() = 0;
        if Vendor.FindSet() then
            repeat
                PrepareVendor(Vendor, ErrorMessage);
            until Vendor.Next() = 0;
        EDocumentService.SetFilter("Document Format", '%1|%2', EDocumentService."Document Format"::"Peppol BIS 3.0 FR", EDocumentService."Document Format"::"Factur-X FR");
        if ServiceCode <> '' then
            EDocumentService.SetRange(Code, ServiceCode);
        if EDocumentService.FindSet() then
            repeat
                ServiceParticipant.SetRange(Service, EDocumentService.Code);
                if ServiceParticipant.FindSet() then
                    repeat
                        if not TryCheckParticipant(ServiceParticipant) then
                            LogIdentityIssue(ErrorMessage, ServiceParticipant, GetLastErrorText(), '', '', '', '',
                                ServiceParticipant."Participant Identifier", ServiceParticipant."FR Identifier Scheme");
                    until ServiceParticipant.Next() = 0;
            until EDocumentService.Next() = 0;
    end;

    [TryFunction]
    local procedure TryCheckCustomer(Customer: Record Customer; ServiceCode: Code[20])
    var
        Address: Text[250];
        Scheme: Enum "Electronic Address Scheme";
    begin
        FRLegalIdentifiers.GetCustomerEndpoint(Customer, ServiceCode, false, Address, Scheme);
    end;

    [TryFunction]
    local procedure TryCheckVendor(Vendor: Record Vendor)
    var
        SIREN: Text[9];
    begin
        SIREN := FRLegalIdentifiers.GetVendorSIREN(Vendor);
        if SIREN = '' then
            Error(MissingVendorIdentityErr);
        if (Vendor."FR Electronic Address" <> '') or
           not (Vendor."FR Elec. Address Scheme" in [Vendor."FR Elec. Address Scheme"::" ", Vendor."FR Elec. Address Scheme"::EM])
        then
            FRLegalIdentifiers.ValidateEndpoint(Vendor."FR Electronic Address", Vendor."FR Elec. Address Scheme", false, SIREN, Vendor);
    end;

    [TryFunction]
    local procedure TryCheckCompany(CompanyInformation: Record "Company Information"; ServiceCode: Code[20])
    var
        Address: Text[250];
        Scheme: Enum "Electronic Address Scheme";
    begin
        FRLegalIdentifiers.GetCompanyEndpoint(CompanyInformation, ServiceCode, false, Address, Scheme);
    end;

    [TryFunction]
    local procedure TryCheckParticipant(ServiceParticipant: Record "Service Participant")
    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        Vendor: Record Vendor;
        SIREN: Text[9];
        Require0225: Boolean;
    begin
        Require0225 := false;
        SIREN := '';
        case ServiceParticipant."Participant Type" of
            ServiceParticipant."Participant Type"::Customer:
                begin
                    Customer.Get(ServiceParticipant.Participant);
                    Require0225 := FRLegalIdentifiers.IsDomesticB2B(Customer);
                    SIREN := FRLegalIdentifiers.GetCustomerSIREN(Customer, Require0225);
                end;
            ServiceParticipant."Participant Type"::Vendor:
                begin
                    Vendor.Get(ServiceParticipant.Participant);
                    SIREN := FRLegalIdentifiers.GetVendorSIREN(Vendor);
                end;
            ServiceParticipant."Participant Type"::Company:
                begin
                    CompanyInformation.Get();
                    SIREN := FRLegalIdentifiers.GetCompanySIREN(CompanyInformation);
                end;
        end;
        FRLegalIdentifiers.ValidateEndpoint(ServiceParticipant."Participant Identifier", ServiceParticipant."FR Identifier Scheme", Require0225, SIREN, ServiceParticipant);
    end;

    local procedure LogIdentityIssue(var ErrorMessage: Record "Error Message"; Owner: Variant; Issue: Text; SIREN: Text; SIRET: Text; RegistrationNumber: Text; VAT: Text; Address: Text; Scheme: Enum "Electronic Address Scheme")
    var
        SourceValues: Text[250];
    begin
        SourceValues := CopyStr(StrSubstNo(SourceValuesLbl, SIREN, SIRET, RegistrationNumber, VAT), 1, MaxStrLen(SourceValues));
        ErrorMessage.LogDetailedMessage(Owner, 0, ErrorMessage."Message Type"::Error, Issue, SourceValues, '');
        if Address <> '' then
            ErrorMessage.LogDetailedMessage(Owner, 0, ErrorMessage."Message Type"::Information,
                StrSubstNo(RoutingSourceLbl, FRLegalIdentifiers.SchemeCode(Scheme)), CopyStr(Address, 1, 250), '');
        if (SIREN <> '') or (SIRET <> '') then
            exit;
        if FRLegalIdentifiers.IsFrenchVATFormatValid(VAT) then
            ErrorMessage.LogDetailedMessage(Owner, 0, ErrorMessage."Message Type"::Information,
                StrSubstNo(UnconfirmedSIRENLbl, CopyStr(VAT, 5, 9)), CopyStr(VAT, 1, 250), '');
        if (Scheme in [Scheme::" ", Scheme::"0225"]) and FRLegalIdentifiers.Is0225FormatValid(Address) or
           (Scheme = Scheme::"0002") and (FRLegalIdentifiers.IsSIRENFormatValid(Address) or FRLegalIdentifiers.IsSIRETFormatValid(Address))
        then
            ErrorMessage.LogDetailedMessage(Owner, 0, ErrorMessage."Message Type"::Information,
                StrSubstNo(UnconfirmedSIRENLbl, CopyStr(Address, 1, 9)), CopyStr(Address, 1, 250), '');
    end;

    procedure ShowCustomerReadiness(var Customer: Record Customer)
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        TempErrorMessage.SetContext(Customer);
        PrepareCustomer(Customer, TempErrorMessage, '');
        ShowReadiness(TempErrorMessage);
    end;

    procedure ShowVendorReadiness(var Vendor: Record Vendor)
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        TempErrorMessage.SetContext(Vendor);
        PrepareVendor(Vendor, TempErrorMessage);
        ShowReadiness(TempErrorMessage);
    end;

    procedure ShowCompanyReadiness(ServiceCode: Code[20])
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        PrepareCompany(TempErrorMessage, ServiceCode);
        ShowReadiness(TempErrorMessage);
    end;

    local procedure ShowReadiness(var TempErrorMessage: Record "Error Message" temporary)
    var
        ErrorMessages: Page "Error Messages";
    begin
        TempErrorMessage.Reset();
        if TempErrorMessage.IsEmpty() then begin
            Message(ReadyMsg);
            exit;
        end;
        ErrorMessages.SetRecords(TempErrorMessage);
        ErrorMessages.Run();
    end;

    var
        FRLegalIdentifiers: Codeunit "FR Legal Identifiers";
        InvalidCanonicalSIRENErr: Label 'The existing SIREN must contain exactly nine digits. Correct it before migrating identifiers.';
        InvalidCanonicalSIRETErr: Label 'The existing SIRET must contain exactly fourteen digits. Correct it before migrating identifiers.';
        InvalidRoutingSIRETErr: Label 'The electronic address with scheme 0009 is not a fourteen-digit SIRET. No identifiers were migrated.';
        ConflictingSourcesErr: Label 'The existing French identifier sources disagree. No identifiers were migrated. Review the source values and correct the owning card.';
        MissingVendorIdentityErr: Label 'Set the vendor''s dedicated SIREN. Routing prefixes and VAT suffixes require confirmation and are not migrated automatically.';
        MissingCompanyInformationErr: Label 'Set up Company Information before preparing French identifiers.';
        SourceValuesLbl: Label 'SIREN: %1; SIRET: %2; Registration Number: %3; VAT: %4', Comment = '%1 = Dedicated SIREN, %2 = Dedicated SIRET, %3 = Legacy registration number, %4 = VAT registration number';
        UnconfirmedSIRENLbl: Label 'Possible SIREN %1 was not migrated. Confirm the legal identity on the owning card before using this value.', Comment = '%1 = Unconfirmed SIREN candidate from routing or VAT';
        RoutingSourceLbl: Label 'Retained electronic address (scheme %1). See Additional Information for its original value.', Comment = '%1 = Electronic address scheme';
        ReadyMsg: Label 'Preparation completed. No unresolved French identifier settings were found.';
}
