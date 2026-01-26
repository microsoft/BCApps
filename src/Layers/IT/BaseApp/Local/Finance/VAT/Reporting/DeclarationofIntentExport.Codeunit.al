// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using System.Utilities;

codeunit 12134 "Declaration of Intent Export"
{

    trigger OnRun()
    begin
    end;

    var
        CompanyInformation: Record "Company Information";
        TempErrorMessage: Record "Error Message" temporary;
        FlatFileManagement: Codeunit "Flat File Management";
        ConstFormat: Option AN,CB,CB12,CF,CN,PI,DA,DT,DN,D4,D6,NP,NU,NUp,Nx,PC,PR,QU,PN,VP;
        ConstRecordType: Option A,B,C,D,E,G,H,Z;
        FileNameLbl: Label '%1_%2.ivi', Comment = '%1 = Vendor No.,%2 = VAT Exempion. No.';
        NoSigningCompanyOfficialErr: Label 'You need to specify a Signing Company Official.';
        NoAmountToDeclareErr: Label 'You need to specify an amount to declare.';
        VendorMustHaveFiscalCodeOrVatRegNoErr: Label 'Vendor with No. = %1 must have a value in either %2 or %3.', Comment = '%1 = Vendor No., %2 = Fiscal Code, %3 = VAT Reg. No.';
        CompanyMustHaveFiscalCodeOrVatRegNoErr: Label 'Company Information must have a value in either %1 or %2.', Comment = '%1 = Fiscal Code, %2 = VAT Reg. No.';

    [Scope('OnPrem')]
    procedure Export(var VATExemption: Record "VAT Exemption"; DescriptionOfGoods: Text[100]; SigningCompanyOfficialNo: Code[20]; AmountToDeclare: Decimal; CeilingType: Option "Fixed",Mobile; ExportFlags: array[6] of Boolean; SupplementaryReturn: Boolean; TaxAuthorityReceiptsNo: Text[17]; TaxAuthorityDocNo: Text[6]): Boolean
    var
        SigningCompanyOfficials: Record "Company Officials";
    begin
        VATExemption.TestField(Type, VATExemption.Type::Vendor);
        if not SigningCompanyOfficials.Get(SigningCompanyOfficialNo) then
            Error(NoSigningCompanyOfficialErr);
        if AmountToDeclare <= 0 then
            Error(NoAmountToDeclareErr);

        CompanyInformation.Get();

        OnExportBeforeWriteFile(VATExemption, CompanyInformation);

        FlatFileManagement.Initialize();
        FlatFileManagement.StartNewFile();
        CreateRecordA();
        CreateRecordB(VATExemption, DescriptionOfGoods, SigningCompanyOfficials, AmountToDeclare, CeilingType,
          ExportFlags, SupplementaryReturn, TaxAuthorityReceiptsNo, TaxAuthorityDocNo);
        EndFile();

        if not TempErrorMessage.HasErrors(true) then begin
            FlatFileManagement.DownloadFile(StrSubstNo(FileNameLbl, VATExemption."No.", VATExemption.GetVATExemptNo()));
            exit(true);
        end;

        TempErrorMessage.ShowErrorMessages(false);
        exit(false);
    end;

    local procedure CreateRecordA()
    var
        VendorTaxRepresentative: Record Vendor;
        TaxCode: Code[20];
    begin
        FlatFileManagement.StartNewRecord(ConstRecordType::A);

        FlatFileManagement.WritePositionalValue(16, 5, ConstFormat::NU, 'IVI15', false); // A-3
        if VendorTaxRepresentative.Get(CompanyInformation."Tax Representative No.") then begin
            FlatFileManagement.WritePositionalValue(21, 2, ConstFormat::NU, '10', false); // A-4
            TaxCode := VendorTaxRepresentative.GetTaxCode();
            if TaxCode <> '' then
                FlatFileManagement.WritePositionalValue(23, 16, ConstFormat::AN, TaxCode, false) // A-5
            else
                TempErrorMessage.LogMessage(
                  VendorTaxRepresentative, VendorTaxRepresentative.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
                  StrSubstNo(
                    VendorMustHaveFiscalCodeOrVatRegNoErr, VendorTaxRepresentative."No.",
                    VendorTaxRepresentative.FieldCaption("Fiscal Code"),
                    VendorTaxRepresentative.FieldCaption("VAT Registration No.")));
        end else begin
            FlatFileManagement.WritePositionalValue(21, 2, ConstFormat::NU, '01', false); // A-4
            TaxCode := CompanyInformation.GetTaxCode();
            if TaxCode <> '' then
                FlatFileManagement.WritePositionalValue(23, 16, ConstFormat::AN, TaxCode, false) // A-5
            else
                TempErrorMessage.LogMessage(
                  CompanyInformation, CompanyInformation.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
                  StrSubstNo(CompanyMustHaveFiscalCodeOrVatRegNoErr, CompanyInformation.FieldCaption("Fiscal Code"),
                    CompanyInformation.FieldCaption("VAT Registration No.")));
        end;
    end;

    local procedure CreateRecordB(var VATExemption: Record "VAT Exemption"; DescriptionOfGoods: Text[100]; SigningCompanyOfficials: Record "Company Officials"; AmountToDeclare: Decimal; CeilingType: Option "Fixed",Mobile; ExportFlags: array[6] of Boolean; SupplementaryReturn: Boolean; TaxAuthorityReceiptsNo: Text[17]; TaxAuthorityDocNo: Text[6])
    var
        Vendor: Record Vendor;
        TaxPayerVendor: Record Vendor;
        TaxCode: Code[20];
    begin
        Vendor.Get(VATExemption."No.");

        FlatFileManagement.StartNewRecord(ConstRecordType::B);

        TaxCode := CompanyInformation.GetTaxCode();
        if TaxCode <> '' then
            FlatFileManagement.WritePositionalValue(2, 16, ConstFormat::AN, TaxCode, false) // B-2
        else
            TempErrorMessage.LogMessage(
              CompanyInformation, CompanyInformation.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(CompanyMustHaveFiscalCodeOrVatRegNoErr, CompanyInformation.FieldCaption("Fiscal Code"),
                CompanyInformation.FieldCaption("VAT Registration No.")));

        FlatFileManagement.WritePositionalValue(18, 8, ConstFormat::NU, '1', false); // B-3
        FlatFileManagement.WritePositionalValue(74, 16, ConstFormat::AN, '08106710158', false); // B-7

        CreateRecordBSupplementary(SupplementaryReturn, TaxAuthorityReceiptsNo, TaxAuthorityDocNo);
        InitializeTaxPayerVendorFromCompanyInfo(TaxPayerVendor);
        CreateRecordBTaxPayer(TaxPayerVendor);

        // Individual Person
        FlatFileManagement.WritePositionalValue(271, 8, ConstFormat::DT, '00000000', true); // B-17

        CreateRecordBSigningCompanyOfficial(SigningCompanyOfficials);

        // Contact Data
        if CompanyInformation."Phone No." = '' then
            FlatFileManagement.WritePositionalValue(404, 12, ConstFormat::AN, '000000000000', true) // B-28
        else
            FlatFileManagement.WritePositionalValue(
              404, 12, ConstFormat::AN, FlatFileManagement.CleanPhoneNumber(CompanyInformation."Phone No."), true); // B-28
        FlatFileManagement.WritePositionalValue(416, 100, ConstFormat::AN, CompanyInformation."E-Mail", false); // B-29

        CreateRecordBStatement(VATExemption, DescriptionOfGoods, AmountToDeclare, Vendor.IsCustomAuthorityVendor());
        CreateRecordBDeclarationDestination(Vendor);
        CreateRecordBSignature(CeilingType, ExportFlags);
        CreateRecordBIntermediarySection(CompanyInformation."Tax Representative No.");
    end;

    local procedure CreateRecordBSupplementary(SupplementaryReturn: Boolean; TaxAuthorityReceiptsNo: Text[17]; TaxAuthorityDocNo: Text[6])
    begin
        if SupplementaryReturn then begin
            FlatFileManagement.WritePositionalValue(90, 1, ConstFormat::CB, '1', false); // B-8
            FlatFileManagement.WritePositionalValue(91, 17, ConstFormat::NU, TaxAuthorityReceiptsNo, false); // B-9
            FlatFileManagement.WritePositionalValue(108, 6, ConstFormat::NU, TaxAuthorityDocNo, false); // B-10
        end else begin
            FlatFileManagement.WritePositionalValue(90, 1, ConstFormat::CB, '0', false); // B-8
            FlatFileManagement.WritePositionalValue(91, 17, ConstFormat::NU, '00000000000000000', false); // B-9
            FlatFileManagement.WritePositionalValue(108, 6, ConstFormat::NU, '000000', false); // B-10
        end;
    end;

    local procedure CreateRecordBTaxPayer(Vendor: Record Vendor)
    var
        TaxCode: Code[20];
    begin
        if Vendor."Individual Person" then begin
            TempErrorMessage.LogIfEmpty(
              Vendor, Vendor.FieldNo("Last Name"), TempErrorMessage."Message Type"::Error);
            FlatFileManagement.WritePositionalValue(114, 24, ConstFormat::AN, Vendor."Last Name", true); // B-11
            TempErrorMessage.LogIfEmpty(
              Vendor, Vendor.FieldNo("First Name"), TempErrorMessage."Message Type"::Error);
            FlatFileManagement.WritePositionalValue(138, 20, ConstFormat::AN, Vendor."First Name", true); // B-12
        end else begin
            TempErrorMessage.LogIfEmpty(
              Vendor, Vendor.FieldNo(Name), TempErrorMessage."Message Type"::Error);
            FlatFileManagement.WritePositionalValue(158, 60, ConstFormat::AN, Vendor.Name, false); // B-13
        end;

        TaxCode := Vendor.GetTaxCode();
        if TaxCode <> '' then
            FlatFileManagement.WritePositionalValue(218, 11, ConstFormat::PI, TaxCode, false) // B-14
        else
            TempErrorMessage.LogMessage(Vendor, Vendor.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(
                VendorMustHaveFiscalCodeOrVatRegNoErr, Vendor."No.",
                Vendor.FieldCaption("Fiscal Code"),
                Vendor.FieldCaption("VAT Registration No.")));
    end;

    local procedure CreateRecordBSigningCompanyOfficial(SigningCompanyOfficials: Record "Company Officials")
    begin
        TempErrorMessage.LogIfEmpty(
          SigningCompanyOfficials, SigningCompanyOfficials.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(280, 16, ConstFormat::CF, SigningCompanyOfficials."Fiscal Code", false); // B-19
        FlatFileManagement.WritePositionalValue(296, 11, ConstFormat::CN, CompanyInformation.GetTaxCode(), false); // B-20
        TempErrorMessage.LogIfEmpty(
          SigningCompanyOfficials, SigningCompanyOfficials.FieldNo("Appointment Code"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(307, 2, ConstFormat::NU, SigningCompanyOfficials."Appointment Code", false); // B-21
        TempErrorMessage.LogIfEmpty(
          SigningCompanyOfficials, SigningCompanyOfficials.FieldNo("Last Name"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(309, 24, ConstFormat::AN, SigningCompanyOfficials."Last Name", false); // B-22
        TempErrorMessage.LogIfEmpty(
          SigningCompanyOfficials, SigningCompanyOfficials.FieldNo("First Name"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(333, 20, ConstFormat::AN, SigningCompanyOfficials."First Name", false); // B-23
        if SigningCompanyOfficials.Gender = SigningCompanyOfficials.Gender::Male then
            FlatFileManagement.WritePositionalValue(353, 1, ConstFormat::AN, 'M', false) // B-24
        else
            FlatFileManagement.WritePositionalValue(353, 1, ConstFormat::AN, 'F', false); // B-24
        TempErrorMessage.LogIfEmpty(
          SigningCompanyOfficials, SigningCompanyOfficials.FieldNo("Date of Birth"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(
          354, 8, ConstFormat::DT, FlatFileManagement.FormatDate(SigningCompanyOfficials."Date of Birth", ConstFormat::DT), false); // B-25
        TempErrorMessage.LogIfEmpty(
          SigningCompanyOfficials, SigningCompanyOfficials.FieldNo("Birth City"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(362, 40, ConstFormat::AN, SigningCompanyOfficials."Birth City", false); // B-25
        TempErrorMessage.LogIfEmpty(
          SigningCompanyOfficials, SigningCompanyOfficials.FieldNo("Birth County"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(402, 2, ConstFormat::PR, SigningCompanyOfficials."Birth County", false); // B-26
    end;

    local procedure CreateRecordBStatement(var VATExemption: Record "VAT Exemption"; DescriptionOfGoods: Text[100]; AmountToDeclare: Decimal; IsCustomAuthoruty: Boolean)
    begin
        if IsCustomAuthoruty then
            FlatFileManagement.WritePositionalValue(517, 1, ConstFormat::CB, '1', false) // B-31
        else begin
            FlatFileManagement.WritePositionalValue(516, 1, ConstFormat::CB, '1', false); // B-30
            FlatFileManagement.WritePositionalValue(517, 1, ConstFormat::CB, '0', false); // B-31
        end;
        FlatFileManagement.WritePositionalValue(
          518, 4, ConstFormat::NU, Format(Date2DMY(VATExemption."VAT Exempt. Starting Date", 3)), false); // B-32
        FlatFileManagement.WritePositionalValue(522, 16, ConstFormat::VP, '0', false); // B-33
        FlatFileManagement.WritePositionalValue(
          538, 16, ConstFormat::VP, FlatFileManagement.FormatNum(AmountToDeclare, ConstFormat::VP), false);  // B-34
        FlatFileManagement.WritePositionalValue(570, 100, ConstFormat::AN, DescriptionOfGoods, false); // B-36
        TempErrorMessage.LogIfEmpty(
          VATExemption, VATExemption.FieldNo("VAT Exempt. Int. Registry No."), TempErrorMessage."Message Type"::Error);
    end;

    local procedure CreateRecordBDeclarationDestination(var Vendor: Record Vendor)
    var
        TaxCode: Code[20];
    begin
        if Vendor.IsCustomAuthorityVendor() then
            FlatFileManagement.WritePositionalValue(690, 1, ConstFormat::CB, '1', false) // B-40
        else
            FlatFileManagement.WritePositionalValue(690, 1, ConstFormat::CB, '0', false); // B-40
        TaxCode := Vendor.GetTaxCode();
        if TaxCode <> '' then
            FlatFileManagement.WritePositionalValue(691, 16, ConstFormat::CF, TaxCode, false) // B-41
        else
            TempErrorMessage.LogMessage(Vendor, Vendor.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(
                VendorMustHaveFiscalCodeOrVatRegNoErr, Vendor."No.",
                Vendor.FieldCaption("Fiscal Code"),
                Vendor.FieldCaption("VAT Registration No.")));
        FlatFileManagement.WritePositionalValue(707, 11, ConstFormat::PI, Vendor."VAT Registration No.", false); // B-42

        if Vendor."Individual Person" then begin
            TempErrorMessage.LogIfEmpty(
              Vendor, Vendor.FieldNo("Last Name"), TempErrorMessage."Message Type"::Error);
            FlatFileManagement.WritePositionalValue(718, 24, ConstFormat::AN, Vendor."Last Name", true); // B-43
            TempErrorMessage.LogIfEmpty(
              Vendor, Vendor.FieldNo("First Name"), TempErrorMessage."Message Type"::Error);
            FlatFileManagement.WritePositionalValue(742, 20, ConstFormat::AN, Vendor."First Name", true); // B-44
            if Vendor.Gender = Vendor.Gender::Male then
                FlatFileManagement.WritePositionalValue(822, 1, ConstFormat::AN, 'M', false) // B-46
            else
                FlatFileManagement.WritePositionalValue(822, 1, ConstFormat::AN, 'F', false); // B-46
        end else begin
            TempErrorMessage.LogIfEmpty(
              Vendor, Vendor.FieldNo(Name), TempErrorMessage."Message Type"::Error);
            FlatFileManagement.WritePositionalValue(762, 60, ConstFormat::AN, Vendor.Name, false); // B-45
        end;
    end;

    local procedure CreateRecordBSignature(CeilingType: Option "Fixed",Mobile; ExportFlags: array[6] of Boolean)
    begin
        FlatFileManagement.WritePositionalValue(823, 1, ConstFormat::CB, '1', false); // B-47

        if CeilingType = CeilingType::Fixed then
            FlatFileManagement.WritePositionalValue(824, 1, ConstFormat::NU, '1', false) // B-48
        else
            FlatFileManagement.WritePositionalValue(824, 1, ConstFormat::NU, '2', false); // B-48
        FlatFileManagement.WritePositionalValue(825, 1, ConstFormat::CB, BoolToString(ExportFlags[1]), false); // B-49
        FlatFileManagement.WritePositionalValue(826, 1, ConstFormat::CB, BoolToString(ExportFlags[2]), false); // B-50
        FlatFileManagement.WritePositionalValue(827, 1, ConstFormat::CB, BoolToString(ExportFlags[3]), false); // B-51
        FlatFileManagement.WritePositionalValue(828, 1, ConstFormat::CB, BoolToString(ExportFlags[4]), false); // B-52
        FlatFileManagement.WritePositionalValue(829, 1, ConstFormat::CB, BoolToString(ExportFlags[5]), false); // B-53
        FlatFileManagement.WritePositionalValue(830, 1, ConstFormat::CB, BoolToString(ExportFlags[6]), false); // B-54
    end;

    local procedure CreateRecordBIntermediarySection(VendorTaxRepresentativeNo: Code[20])
    var
        VendorTaxRepresentative: Record Vendor;
        TaxCode: Code[20];
    begin
        if VendorTaxRepresentative.Get(VendorTaxRepresentativeNo) then begin
            TaxCode := VendorTaxRepresentative.GetTaxCode();
            if TaxCode <> '' then
                FlatFileManagement.WritePositionalValue(891, 16, ConstFormat::CF, TaxCode, false) // B-57
            else
                TempErrorMessage.LogMessage(
                  VendorTaxRepresentative, VendorTaxRepresentative.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
                  StrSubstNo(
                    VendorMustHaveFiscalCodeOrVatRegNoErr, VendorTaxRepresentative."No.",
                    VendorTaxRepresentative.FieldCaption("Fiscal Code"),
                    VendorTaxRepresentative.FieldCaption("VAT Registration No.")));
            FlatFileManagement.WritePositionalValue(907, 8, ConstFormat::DT, FlatFileManagement.FormatDate(Today, ConstFormat::DT), false); // B-58
            FlatFileManagement.WritePositionalValue(915, 1, ConstFormat::NU, '1', false); // B-59
        end else begin
            FlatFileManagement.WritePositionalValue(907, 8, ConstFormat::DT, '00000000', false); // B-58
            FlatFileManagement.WritePositionalValue(915, 1, ConstFormat::NU, '0', false); // B-59
        end;
    end;

    local procedure CreateRecordZ()
    begin
        FlatFileManagement.StartNewRecord(ConstRecordType::Z);
        FlatFileManagement.WritePositionalValue(
          16, 9, ConstFormat::NU, Format(FlatFileManagement.GetRecordCount(ConstRecordType::B), 0, 1), false);
    end;

    local procedure EndFile()
    begin
        CreateRecordZ();
        FlatFileManagement.EndFile();
    end;

    local procedure BoolToString(Bool: Boolean): Text[1]
    begin
        if Bool then
            exit('1');
        exit('0');
    end;

    [Scope('OnPrem')]
    procedure SetServerFileName(FileName: Text)
    begin
        FlatFileManagement.SetServerFileName(FileName);
    end;

    local procedure InitializeTaxPayerVendorFromCompanyInfo(var Vendor: Record Vendor)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        Vendor.Init();
        Vendor.Name := CompanyInformation.Name;
        Vendor."VAT Registration No." := CompanyInformation."VAT Registration No.";
        Vendor."Individual Person" := false;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExportBeforeWriteFile(var VATExemption: Record "VAT Exemption"; var CompanyInformation: Record "Company Information")
    begin
    end;
}

