// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Registration;

using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

/// <summary>
/// Resolves role-specific legal identifiers from the original document, without backfilling historical snapshots.
/// </summary>
codeunit 7405 "Registration No. Export"
{
    var
        RegistrationNoFeature: Codeunit "Registration No. Feature";
        MissingRegistrationNoErr: Label 'The %1 legal registration snapshot is missing. Profile %2 requires this identifier.', Comment = '%1 = Party role, %2 = Export profile';
        MissingSchemeErr: Label 'The registry scheme for the %1 legal registration number is required by profile %2.', Comment = '%1 = Party role, %2 = Export profile';
        UnsupportedLengthErr: Label 'The %1 legal registration number exceeds the maximum length of %2 characters supported by profile %3.', Comment = '%1 = Party role, %2 = Maximum length, %3 = Export profile';
        InvalidMaximumLengthErr: Label 'The legal registration number length specified for profile %1 must be greater than zero.', Comment = '%1 = Export profile';

    /// <summary>
    /// Replaces only the legal identifier and its scheme when global registration numbers are enabled.
    /// Registry/profile extensions can specify a scheme and mandatory-identifier requirements.
    /// </summary>
    /// <param name="Document">The original document, not a projected Sales/Purchase Header buffer.</param>
    /// <param name="PartyRole">The source party whose legal identity is exported.</param>
    /// <param name="Profile">The external profile or customization identifier.</param>
    /// <param name="Identifier">The unchanged snapshot, or blank when an optional snapshot is unavailable.</param>
    /// <param name="SchemeID">The profile/registry scheme, never a registration-number format mask.</param>
    procedure ApplyLegalIdentity(Document: RecordRef; PartyRole: Enum "Registration No. Party Role"; Profile: Text; var Identifier: Text; var SchemeID: Text)
    var
        RegistrationNo: Text[50];
        CountryCode: Code[10];
        RegistrationRequired: Boolean;
        SchemeRequired: Boolean;
        MaximumLength: Integer;
    begin
        if not RegistrationNoFeature.IsEnabled() then
            exit;

        GetSnapshot(Document, PartyRole, RegistrationNo, CountryCode);
        Clear(SchemeID);
        MaximumLength := MaxStrLen(RegistrationNo);
        OnResolveProfileRequirements(Document, PartyRole, Profile, RegistrationNo, CountryCode, SchemeID, RegistrationRequired, SchemeRequired, MaximumLength);
        if MaximumLength <= 0 then
            Error(InvalidMaximumLengthErr, Profile);
        if (RegistrationNo = '') and RegistrationRequired then
            Error(MissingRegistrationNoErr, PartyRole, Profile);
        if StrLen(RegistrationNo) > MaximumLength then
            Error(UnsupportedLengthErr, PartyRole, MaximumLength, Profile);
        if RegistrationNo = '' then
            Clear(SchemeID)
        else
            if (SchemeID = '') and SchemeRequired then
                Error(MissingSchemeErr, PartyRole, Profile);
        Identifier := RegistrationNo;
    end;

    local procedure GetSnapshot(Document: RecordRef; PartyRole: Enum "Registration No. Party Role"; var RegistrationNo: Text[50]; var CountryCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchaseHeader: Record "Purchase Header";
        RegistrationNoMgt: Codeunit "Registration No. Mgt.";
    begin
        case PartyRole of
            PartyRole::Company:
                case Document.Number of
                    Database::"Sales Header", Database::"Purchase Header":
                        RegistrationNoMgt.GetCompanyRegistrationSnapshot(RegistrationNo, CountryCode);
                    Database::"Sales Invoice Header", Database::"Sales Cr.Memo Header",
                    Database::"Sales Shipment Header", Database::"Return Receipt Header", Database::"Sales Header Archive",
                    Database::"Purch. Inv. Header", Database::"Purch. Cr. Memo Hdr.",
                    Database::"Purch. Rcpt. Header", Database::"Return Shipment Header", Database::"Purchase Header Archive":
                        ReadSnapshotFields(Document, SalesInvoiceHeader.FieldNo("Company Registration No."),
                            SalesInvoiceHeader.FieldNo("Company Reg. Country/Region"), RegistrationNo, CountryCode);
                end;
            PartyRole::"Sales Bill-to":
                case Document.Number of
                    Database::"Sales Header", Database::"Sales Invoice Header", Database::"Sales Cr.Memo Header",
                    Database::"Sales Shipment Header", Database::"Return Receipt Header", Database::"Sales Header Archive":
                        ReadSnapshotFields(Document, SalesHeader.FieldNo("Bill-to Registration No."),
                            SalesHeader.FieldNo("Bill-to Reg. Country/Region"), RegistrationNo, CountryCode);
                end;
            PartyRole::"Purchase Buy-from":
                case Document.Number of
                    Database::"Purchase Header", Database::"Purch. Inv. Header", Database::"Purch. Cr. Memo Hdr.",
                    Database::"Purch. Rcpt. Header", Database::"Return Shipment Header", Database::"Purchase Header Archive":
                        ReadSnapshotFields(Document, PurchaseHeader.FieldNo("Registration No."),
                            PurchaseHeader.FieldNo("Registration Country/Region"), RegistrationNo, CountryCode);
                end;
        end;
    end;

    local procedure ReadSnapshotFields(Document: RecordRef; RegistrationFieldNo: Integer; CountryFieldNo: Integer; var RegistrationNo: Text[50]; var CountryCode: Code[10])
    begin
        RegistrationNo := Document.Field(RegistrationFieldNo).Value;
        CountryCode := Document.Field(CountryFieldNo).Value;
    end;

    /// <summary>
    /// Specifies registry/profile policy without changing the historical identifier or deriving schemes from format masks.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnResolveProfileRequirements(Document: RecordRef; PartyRole: Enum "Registration No. Party Role"; Profile: Text; RegistrationNo: Text[50]; CountryCode: Code[10]; var SchemeID: Text; var RegistrationRequired: Boolean; var SchemeRequired: Boolean; var MaximumLength: Integer)
    begin
    end;
}
