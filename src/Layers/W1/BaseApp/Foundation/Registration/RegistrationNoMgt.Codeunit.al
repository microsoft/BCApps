// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Registration;

using Microsoft.Bank.Payment;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;
using System.Text;

codeunit 7402 "Registration No. Mgt."
{
    var
        RegistrationNoFeature: Codeunit "Registration No. Feature";
        InvalidFormatErr: Label 'The registration number format must not end with an unescaped backslash.';
        FormatMismatchErr: Label 'Registration number %1 does not match an accepted format for country/region %2. Accepted formats: %3.', Comment = '%1 = Registration number, %2 = Country/region code, %3 = Accepted formats';
        DuplicateNotificationMsg: Label 'Registration number %1 is also used by %2 other organization(s) in country/region %3. Review the possible duplicates before continuing.', Comment = '%1 = Registration number, %2 = Number of other organizations, %3 = Country/region code';
        ShowDuplicatesLbl: Label 'Show possible duplicates';
        CompanyRegistrationNoTooLongErr: Label 'The company registration number exceeds the maximum document snapshot length of %1 characters.', Comment = '%1 = Maximum registration number length';
        PaymentExportLengthErr: Label 'The legal registration number exceeds the maximum length of %1 characters for %2.', Comment = '%1 = Maximum length, %2 = Payment export field caption';
        PaymentExportCharactersErr: Label 'The legal registration number cannot be exported unchanged in %1. Use a payment format that supports the original identifier.', Comment = '%1 = Payment export field caption';

    procedure GetRegistrationNo(RegistrationNo: Text[50]; CountryCode: Code[10]; SourceRecordId: RecordId) ResolvedRegistrationNo: Text[50]
    begin
        ResolvedRegistrationNo := RegistrationNo;
        if not RegistrationNoFeature.IsEnabled() then
            exit;
        OnResolveRegistrationNo(RegistrationNo, CountryCode, SourceRecordId, ResolvedRegistrationNo);
    end;

    procedure GetCompanyRegistrationSnapshot(var RegistrationNo: Text[50]; var CountryCode: Code[10])
    var
        CompanyInformation: Record "Company Information";
        CompanyRegistrationNo: Text;
    begin
        CompanyInformation.Get();
        CompanyRegistrationNo := CompanyInformation.GetRegistrationNumber();
        if StrLen(CompanyRegistrationNo) > MaxStrLen(RegistrationNo) then
            Error(CompanyRegistrationNoTooLongErr, MaxStrLen(RegistrationNo));
        RegistrationNo := CopyStr(CompanyRegistrationNo, 1, MaxStrLen(RegistrationNo));
        CountryCode := CompanyInformation."Country/Region Code";
    end;

    procedure ValidateRegistrationNo(RegistrationNo: Text[50]; CountryCode: Code[10]; SourceRecordId: RecordId)
    begin
        if not RegistrationNoFeature.IsEnabled() then
            exit;
        ValidateMigrationRegistrationNo(RegistrationNo, CountryCode, SourceRecordId);
    end;

    /// <summary>
    /// Validates a known legal payment field before buffer conversion or fixed-width mapping can narrow its value.
    /// </summary>
    procedure ValidatePaymentExportField(PaymentExportData: Record "Payment Export Data"; RegistrationNo: Text; ExportFieldNo: Integer; CodeField: Boolean; PreserveNonLatinCharacters: Boolean)
    var
        DataExch: Record "Data Exch.";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
        PaymentRecord: RecordRef;
        ExportField: FieldRef;
    begin
        if not RegistrationNoFeature.IsEnabled() then
            exit;
        PaymentRecord.GetTable(PaymentExportData);
        ExportField := PaymentRecord.Field(ExportFieldNo);
        ValidatePaymentExportValue(RegistrationNo, ExportField.Length, PreserveNonLatinCharacters, CodeField, ExportField.Caption);
        if PaymentExportData."Data Exch Entry No." = 0 then
            exit;

        DataExch.Get(PaymentExportData."Data Exch Entry No.");
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", PaymentExportData."Data Exch. Line Def Code");
        DataExchFieldMapping.SetRange("Table ID", Database::"Payment Export Data");
        DataExchFieldMapping.SetRange("Field ID", ExportFieldNo);
        DataExchFieldMapping.SetRange("Use Default Value", false);
        if DataExchFieldMapping.FindSet() then
            repeat
                DataExchColumnDef.Get(DataExchFieldMapping."Data Exch. Def Code", DataExchFieldMapping."Data Exch. Line Def Code", DataExchFieldMapping."Column No.");
                if DataExchColumnDef.Length > 0 then
                    if StrLen(RegistrationNo) > DataExchColumnDef.Length then
                        Error(PaymentExportLengthErr, DataExchColumnDef.Length, ExportField.Caption);
            until DataExchFieldMapping.Next() = 0;
    end;

    /// <summary>
    /// Rejects loss of legal identity through payment field narrowing, Code normalization or EPC character conversion.
    /// Call only for fields that the payment adapter populates with a legal registration number.
    /// </summary>
    local procedure ValidatePaymentExportValue(RegistrationNo: Text; MaximumLength: Integer; PreserveNonLatinCharacters: Boolean; CodeField: Boolean; ExportFieldCaption: Text)
    var
        StringConversionManagement: Codeunit StringConversionManagement;
        CodeValue: Code[50];
        ExportValue: Text;
        Index: Integer;
    begin
        if StrLen(RegistrationNo) > MaximumLength then
            Error(PaymentExportLengthErr, MaximumLength, ExportFieldCaption);

        ExportValue := RegistrationNo;
        if CodeField then begin
            if StrLen(RegistrationNo) > MaxStrLen(CodeValue) then
                Error(PaymentExportLengthErr, MaxStrLen(CodeValue), ExportFieldCaption);
            CodeValue := CopyStr(RegistrationNo, 1, MaxStrLen(CodeValue));
            ExportValue := CodeValue;
        end;
        if not PreserveNonLatinCharacters then
            ExportValue := StringConversionManagement.WindowsToASCII(ExportValue);
        if StrLen(RegistrationNo) <> StrLen(ExportValue) then
            Error(PaymentExportCharactersErr, ExportFieldCaption);
        for Index := 1 to StrLen(RegistrationNo) do
            if (RegistrationNo[Index] < 32) or (RegistrationNo[Index] in [127 .. 159]) or
               (RegistrationNo[Index] <> ExportValue[Index])
            then
                Error(PaymentExportCharactersErr, ExportFieldCaption);
    end;

    procedure ValidateMigrationRegistrationNo(RegistrationNo: Text[50]; CountryCode: Code[10]; SourceRecordId: RecordId)
    var
        IsHandled: Boolean;
    begin
        OnBeforeValidateRegistrationNo(RegistrationNo, CountryCode, SourceRecordId, IsHandled);
        if not IsHandled then
            TestFormats(RegistrationNo, CountryCode);
        OnAfterValidateRegistrationNo(RegistrationNo, CountryCode, SourceRecordId);
    end;

    local procedure TestFormats(RegistrationNo: Text[50]; CountryCode: Code[10])
    var
        RegistrationNoFormat: Record "Registration No. Format";
        AcceptedFormats: Text;
    begin
        if (RegistrationNo = '') or (CountryCode = '') then
            exit;

        RegistrationNoFormat.SetRange("Country/Region Code", CountryCode);
        if not RegistrationNoFormat.FindSet() then
            exit;

        repeat
            if MatchesFormat(RegistrationNo, RegistrationNoFormat.Format) then
                exit;
            if AcceptedFormats <> '' then
                AcceptedFormats += ', ';
            AcceptedFormats += RegistrationNoFormat.Format;
        until RegistrationNoFormat.Next() = 0;

        Error(FormatMismatchErr, RegistrationNo, CountryCode, AcceptedFormats);
    end;

    procedure ValidateFormat(RegistrationFormat: Text[50])
    var
        Index: Integer;
    begin
        Index := 1;
        while Index <= StrLen(RegistrationFormat) do begin
            if RegistrationFormat[Index] = '\' then begin
                Index += 1;
                if Index > StrLen(RegistrationFormat) then
                    Error(InvalidFormatErr);
            end;
            Index += 1;
        end;
    end;

    procedure MatchesFormat(RegistrationNo: Text[50]; RegistrationFormat: Text[50]): Boolean
    var
        FormatIndex: Integer;
        ValueIndex: Integer;
        FormatCharacter: Char;
        ValueCharacter: Char;
    begin
        ValidateFormat(RegistrationFormat);
        FormatIndex := 1;
        ValueIndex := 1;
        while FormatIndex <= StrLen(RegistrationFormat) do begin
            if ValueIndex > StrLen(RegistrationNo) then
                exit(false);
            FormatCharacter := RegistrationFormat[FormatIndex];
            ValueCharacter := RegistrationNo[ValueIndex];
            if FormatCharacter = '\' then begin
                FormatIndex += 1;
                if ValueCharacter <> RegistrationFormat[FormatIndex] then
                    exit(false);
            end else
                case FormatCharacter of
                    '#':
                        if (ValueCharacter < '0') or (ValueCharacter > '9') then
                            exit(false);
                    '@':
                        if ((ValueCharacter < 'A') or (ValueCharacter > 'Z')) and
                           ((ValueCharacter < 'a') or (ValueCharacter > 'z')) then
                            exit(false);
                    else
                        if (FormatCharacter <> '?') and (ValueCharacter <> FormatCharacter) then
                            exit(false);
                end;
            FormatIndex += 1;
            ValueIndex += 1;
        end;
        exit(ValueIndex > StrLen(RegistrationNo));
    end;

    procedure FindDuplicates(RegistrationNo: Text[50]; CountryCode: Code[10]; SourceRecordId: RecordId; var Duplicates: List of [RecordId])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        CompanyInformation: Record "Company Information";
        ContactNos: List of [Code[20]];
        SourceContactNo: Code[20];
        IsHandled: Boolean;
    begin
        Clear(Duplicates);
        if (RegistrationNo = '') or (CountryCode = '') then
            exit;

        OnBeforeFindDuplicates(RegistrationNo, CountryCode, SourceRecordId, Duplicates, IsHandled);
        if IsHandled then
            exit;

        SourceContactNo := GetContactNo(SourceRecordId);
        if SourceContactNo <> '' then
            ContactNos.Add(SourceContactNo);

        if Customer.ReadPermission() then begin
            Customer.SetRange("Country/Region Code", CountryCode);
            Customer.SetRange("Registration Number", RegistrationNo);
            if Customer.FindSet() then
                repeat
                    AddDuplicate(Customer.RecordId, SourceRecordId, ContactNos, Duplicates);
                until Customer.Next() = 0;
        end;
        if Vendor.ReadPermission() then begin
            Vendor.SetRange("Country/Region Code", CountryCode);
            Vendor.SetRange("Registration Number", RegistrationNo);
            if Vendor.FindSet() then
                repeat
                    AddDuplicate(Vendor.RecordId, SourceRecordId, ContactNos, Duplicates);
                until Vendor.Next() = 0;
        end;
        if Contact.ReadPermission() then begin
            Contact.SetRange("Country/Region Code", CountryCode);
            Contact.SetRange("Registration Number", RegistrationNo);
            if Contact.FindSet() then
                repeat
                    AddDuplicate(Contact.RecordId, SourceRecordId, ContactNos, Duplicates);
                until Contact.Next() = 0;
        end;
        if CompanyInformation.ReadPermission() then begin
            CompanyInformation.SetRange("Country/Region Code", CountryCode);
            CompanyInformation.SetRange("Registration No.", RegistrationNo);
            if CompanyInformation.FindSet() then
                repeat
                    AddDuplicate(CompanyInformation.RecordId, SourceRecordId, ContactNos, Duplicates);
                until CompanyInformation.Next() = 0;
        end;

        OnAfterFindDuplicates(RegistrationNo, CountryCode, SourceRecordId, Duplicates);
    end;

    local procedure AddDuplicate(CandidateRecordId: RecordId; SourceRecordId: RecordId; var ContactNos: List of [Code[20]]; var Duplicates: List of [RecordId])
    var
        ContactNo: Code[20];
    begin
        if CandidateRecordId = SourceRecordId then
            exit;
        ContactNo := GetContactNo(CandidateRecordId);
        if ContactNo <> '' then begin
            if ContactNos.Contains(ContactNo) then
                exit;
            ContactNos.Add(ContactNo);
        end;
        Duplicates.Add(CandidateRecordId);
    end;

    local procedure GetContactNo(SourceRecordId: RecordId): Code[20]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        SourceRecordRef: RecordRef;
    begin
        if SourceRecordId.TableNo = 0 then
            exit('');
        SourceRecordRef := SourceRecordId.GetRecord();
        case SourceRecordId.TableNo of
            Database::Contact:
                begin
                    SourceRecordRef.SetTable(Contact);
                    exit(Contact."No.");
                end;
            Database::Customer:
                if ContactBusinessRelation.ReadPermission() then begin
                    SourceRecordRef.SetTable(Customer);
                    exit(ContactBusinessRelation.GetContactNo(ContactBusinessRelation."Link to Table"::Customer, Customer."No."));
                end;
            Database::Vendor:
                if ContactBusinessRelation.ReadPermission() then begin
                    SourceRecordRef.SetTable(Vendor);
                    exit(ContactBusinessRelation.GetContactNo(ContactBusinessRelation."Link to Table"::Vendor, Vendor."No."));
                end;
        end;
        exit('');
    end;

    procedure NotifyDuplicates(RegistrationNo: Text[50]; CountryCode: Code[10]; SourceRecordId: RecordId)
    var
        DuplicateNotification: Notification;
        Duplicates: List of [RecordId];
        SourceRecordRef: RecordRef;
    begin
        if not RegistrationNoFeature.IsEnabled() or not GuiAllowed() then
            exit;

        DuplicateNotification.Id := '8be2391e-f4e7-4e31-bd99-e028c43b3f09';
        DuplicateNotification.Scope := NotificationScope::LocalScope;
        DuplicateNotification.Recall();
        FindDuplicates(RegistrationNo, CountryCode, SourceRecordId, Duplicates);
        if Duplicates.Count() = 0 then
            exit;
        SourceRecordRef := SourceRecordId.GetRecord();
        DuplicateNotification.Message := StrSubstNo(DuplicateNotificationMsg, RegistrationNo, Duplicates.Count(), CountryCode);
        DuplicateNotification.SetData('RegistrationNo', RegistrationNo);
        DuplicateNotification.SetData('CountryCode', CountryCode);
        DuplicateNotification.SetData('SourceTableNo', Format(SourceRecordId.TableNo));
        DuplicateNotification.SetData('SourcePosition', SourceRecordRef.GetPosition(false));
        DuplicateNotification.AddAction(ShowDuplicatesLbl, Codeunit::"Registration No. Mgt.", 'ShowDuplicates');
        DuplicateNotification.Send();
    end;

    procedure ShowDuplicates(DuplicateNotification: Notification)
    var
        TempDuplicate: Record "Registration No. Duplicate" temporary;
        Duplicates: List of [RecordId];
        CandidateRecordId: RecordId;
        SourceRecordRef: RecordRef;
        CandidateRecordRef: RecordRef;
        RegistrationNo: Text[50];
        CountryCode: Code[10];
        SourceTableNo: Integer;
    begin
        RegistrationNo := DuplicateNotification.GetData('RegistrationNo');
        CountryCode := DuplicateNotification.GetData('CountryCode');
        Evaluate(SourceTableNo, DuplicateNotification.GetData('SourceTableNo'));
        SourceRecordRef.Open(SourceTableNo);
        SourceRecordRef.SetPosition(DuplicateNotification.GetData('SourcePosition'));
        FindDuplicates(RegistrationNo, CountryCode, SourceRecordRef.RecordId, Duplicates);
        foreach CandidateRecordId in Duplicates do begin
            CandidateRecordRef := CandidateRecordId.GetRecord();
            if CandidateRecordRef.Find() then begin
                TempDuplicate.Init();
                TempDuplicate."Record ID" := CandidateRecordId;
                TempDuplicate."Record Type" := CopyStr(CandidateRecordRef.Caption, 1, MaxStrLen(TempDuplicate."Record Type"));
                TempDuplicate."No." := CandidateRecordRef.Field(1).Value;
                TempDuplicate.Name := CandidateRecordRef.Field(2).Value;
                TempDuplicate.Insert();
            end;
        end;
        Page.Run(Page::"Registration No. Duplicates", TempDuplicate);
    end;

    procedure GetCompanyRegistrationForReport(CompanyRegistrationSnapshot: Text[50]; CompanyInformation: Record "Company Information"): Text
    begin
        if RegistrationNoFeature.IsEnabled() then
            exit(CompanyRegistrationSnapshot);
        exit(CompanyInformation.GetRegistrationNumber());
    end;

    procedure GetDocumentRegistrationForReport(RegistrationSnapshot: Text[50]; LegacyRegistrationNo: Text[50]): Text[50]
    begin
        if RegistrationNoFeature.IsEnabled() then
            exit(RegistrationSnapshot);
        exit(LegacyRegistrationNo);
    end;

    procedure FormatRegistrationNo(RegistrationNo: Text[50]; CountryCode: Code[10]; SourceRecordId: RecordId) FormattedRegistrationNo: Text[50]
    begin
        FormattedRegistrationNo := RegistrationNo;
        if not RegistrationNoFeature.IsEnabled() then
            exit;
        OnFormatRegistrationNo(RegistrationNo, CountryCode, SourceRecordId, FormattedRegistrationNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResolveRegistrationNo(RegistrationNo: Text[50]; CountryCode: Code[10]; SourceRecordId: RecordId; var ResolvedRegistrationNo: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateRegistrationNo(RegistrationNo: Text[50]; CountryCode: Code[10]; SourceRecordId: RecordId; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateRegistrationNo(RegistrationNo: Text[50]; CountryCode: Code[10]; SourceRecordId: RecordId)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindDuplicates(RegistrationNo: Text[50]; CountryCode: Code[10]; SourceRecordId: RecordId; var Duplicates: List of [RecordId]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindDuplicates(RegistrationNo: Text[50]; CountryCode: Code[10]; SourceRecordId: RecordId; var Duplicates: List of [RecordId])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFormatRegistrationNo(RegistrationNo: Text[50]; CountryCode: Code[10]; SourceRecordId: RecordId; var FormattedRegistrationNo: Text[50])
    begin
    end;
}
