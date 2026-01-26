// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using System.Utilities;

codeunit 12132 "Withholding Tax Export"
{

    trigger OnRun()
    begin
    end;

    var
        CompanyInformation: Record "Company Information";
        SigningCompanyOfficials: Record "Company Officials";
        TempErrorMessage: Record "Error Message" temporary;
        FlatFileManagement: Codeunit "Flat File Management";
        ConstFormat: Option AN,CB,CB12,CF,CN,PI,DA,DT,DN,D4,D6,NP,NU,NUp,Nx,PC,PR,QU,PN,VP;
        ConstRecordType: Option A,B,C,D,E,G,H,Z;
        FileNameLbl: Label 'WithholdingTaxes%1.dcm', Comment = '%1 = Year';
        NothingToReportMsg: Label 'There were no Withholding Tax entries for the year %1.', Comment = '%1 = Year';
        NoSigningCompanyOfficialErr: Label 'You need to specify a Signing Company Official.';
        VendorMustHaveFiscalCodeOrVatRegNoErr: Label 'Vendor with No. = %1 must have a value in either %2 or %3.', Comment = '%1 = Vendor No., %2 = Fiscal Code, %3 = VAT Reg. No.';
        CompanyMustHaveFiscalCodeOrVatRegNoErr: Label 'Company Information must have a value in either %1 or %2.', Comment = '%1 = Fiscal Code, %2 = VAT Reg. No.';
        ReportPreparedBy: Option Company,"Tax Representative";
        CommunicationNumber: Integer;
        ReplaceFieldValueToMaxAllowedQst: Label 'The witholding tax amount (field AU001019): %1, is greater than the maximum allowed value taxable base (field AU001018): %2. \\Do you want to replace the witholding tax amount with the maximum allowed?', Comment = '%1=witholding tax amount, a decimal value, %2=taxable base, a decimal value.';
        BaseExcludedAmountTotalErr: Label 'Base - Excluded Amount total on lines for Withholding Tax Entry No. = %1 must be equal to Base - Excluded Amount on the Withholding Tax card for that entry (%2).', Comment = '%1=Entry number,%2=Amount.';
        ReportingYear: Integer;
        ExceptionalEvent: Code[10];
        RecordDCount: Integer;
        CURTxt: Label 'CUR%1', Locked = true, Comment = '%1 - year';

    [Scope('OnPrem')]
    procedure Export(Year: Integer; SigningCompanyOfficialNo: Code[20]; PreparedBy: Option Company,"Tax Representative"; NrOfCommunication: Integer; ExceptionalEventCode: Code[10])
    var
        TempWithholdingTax: Record "Withholding Tax" temporary;
        TempWithholdingTaxPrevYears: Record "Withholding Tax" temporary;
        TempContributions: Record Contributions temporary;
    begin
        CompanyInformation.Get();
        ReportPreparedBy := PreparedBy;
        CommunicationNumber := NrOfCommunication;
        ReportingYear := Year;
        ExceptionalEvent := ExceptionalEventCode;

        if not SigningCompanyOfficials.Get(SigningCompanyOfficialNo) then
            Error(NoSigningCompanyOfficialErr);

        CalculateWithholdingTaxPerVendor(TempWithholdingTax, TempContributions, Year, Year);

        if TempWithholdingTax.IsEmpty() then begin
            Message(NothingToReportMsg, Year);
            exit;
        end;

        CalculateWithholdingTaxPerVendor(TempWithholdingTaxPrevYears, TempContributions, 0, Year - 1);

        FlatFileManagement.Initialize();
        FlatFileManagement.SetEstimatedNumberOfRecords(TempWithholdingTax.Count);

        RecordDCount := TempWithholdingTax.Count();
        StartNewFileWithHeader(); // Creates record A and B
        CreateFileBody(TempWithholdingTax, TempWithholdingTaxPrevYears, TempContributions, Year); // Creates record D and H

        EndFile();

        if not TempErrorMessage.HasErrors(true) then
            FlatFileManagement.DownloadFile(StrSubstNo(FileNameLbl, Year));
        TempErrorMessage.ShowErrorMessages(false);
    end;

    [Scope('OnPrem')]
    procedure SetServerFileName(FileName: Text)
    begin
        FlatFileManagement.SetServerFileName(FileName);
    end;

    local procedure CalculateWithholdingTaxPerVendor(var TempWithholdingTax: Record "Withholding Tax" temporary; var TempContributions: Record Contributions temporary; ReportingYearStart: Integer; ReportingYearEnd: Integer)
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        WithholdingTax.SetCurrentKey("Vendor No.", Reason, "Non-Taxable Income Type");
        WithholdingTax.SetRange(Year, ReportingYearStart, ReportingYearEnd);
        OnCalculateWithholdingTaxPerVendorOnAfterWithholdingTaxSetFilter(WithholdingTax);
        if WithholdingTax.FindSet() then begin
            repeat
                if not LinesExistForEntryNo(WithholdingTax."Entry No.") then begin
                    if (WithholdingTax."Non Taxable Amount By Treaty" <> 0) and (WithholdingTax."Non-Taxable Income Type" = WithholdingTax."Non-Taxable Income Type"::" ") then
                        TempErrorMessage.LogIfEmpty(WithholdingTax, WithholdingTax.FieldNo("Non-Taxable Income Type"), TempErrorMessage."Message Type"::Error);

                    if WithholdingTax."Base - Excluded Amount" <> 0 then
                        TempErrorMessage.LogMessage(WithholdingTax, WithholdingTax.FieldNo("Base - Excluded Amount"), TempErrorMessage."Message Type"::Error, StrSubstNo(BaseExcludedAmountTotalErr, WithholdingTax."Entry No.", WithholdingTax."Base - Excluded Amount"));

                    if ReportingYearStart <> 0 then
                        TempErrorMessage.LogIfEmpty(WithholdingTax, WithholdingTax.FieldNo(Reason), TempErrorMessage."Message Type"::Error);
                    if (WithholdingTax."Vendor No." <> TempWithholdingTax."Vendor No.") or
                       (WithholdingTax.Reason <> TempWithholdingTax.Reason) or
                       ((WithholdingTax."Non-Taxable Income Type" <> TempWithholdingTax."Non-Taxable Income Type") and (TempWithholdingTax."Non-Taxable Income Type" <> TempWithholdingTax."Non-Taxable Income Type"::" "))
                    then begin
                        if TempWithholdingTax."Entry No." <> 0 then
                            TempWithholdingTax.Insert();
                        InitTempWithholdingTax(TempWithholdingTax, WithholdingTax);
                    end;
                    if WithholdingTax."Related Date" <> 0D then
                        TempWithholdingTax."Related Date" := WithholdingTax."Related Date";
                    if WithholdingTax."Non-Taxable Income Type" <> WithholdingTax."Non-Taxable Income Type"::" " then
                        TempWithholdingTax."Non-Taxable Income Type" := WithholdingTax."Non-Taxable Income Type";
                    TempWithholdingTax."Total Amount" += WithholdingTax."Total Amount";
                    TempWithholdingTax."Non Taxable Amount By Treaty" += WithholdingTax."Non Taxable Amount By Treaty";
                    TempWithholdingTax."Base - Excluded Amount" += WithholdingTax."Base - Excluded Amount";
                    TempWithholdingTax."Non Taxable Amount" += WithholdingTax."Non Taxable Amount";
                    TempWithholdingTax."Taxable Base" += WithholdingTax."Taxable Base";
                    TempWithholdingTax."Withholding Tax Amount" += WithholdingTax."Withholding Tax Amount";
                    CalculateContributions(WithholdingTax, TempWithholdingTax."Entry No.", TempContributions);
                end;
            until WithholdingTax.Next() = 0;
            if TempWithholdingTax."Entry No." <> 0 then
                TempWithholdingTax.Insert();
        end;

        AddWithholdingTaxWithSeparateLines(TempWithholdingTax, TempContributions, ReportingYearStart, ReportingYearEnd);
    end;

    local procedure AddWithholdingTaxWithSeparateLines(var TempWithholdingTax: Record "Withholding Tax" temporary; var TempContributions: Record Contributions temporary; ReportingYearStart: Integer; ReportingYearEnd: Integer)
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxLine: Record "Withholding Tax Line";
        TempWithholdingTaxByLine: Record "Withholding Tax" temporary;
        IsFirstLine: Boolean;
        EntryNo: Integer;
        IsBlankNoTaxIncomeType: Boolean;
    begin
        WithholdingTax.SetCurrentKey("Vendor No.", Reason);
        WithholdingTax.SetRange(Year, ReportingYearStart, ReportingYearEnd);
        WithholdingTax.SetRange("Non-Taxable Income Type", WithholdingTax."Non-Taxable Income Type"::" ");
        if WithholdingTax.FindSet() then
            repeat
                if LinesExistForEntryNo(WithholdingTax."Entry No.") then begin
                    if WithholdingTaxLine.GetAmountForEntryNo(WithholdingTax."Entry No.") <> WithholdingTax."Base - Excluded Amount" then
                        TempErrorMessage.LogMessage(WithholdingTax, WithholdingTax.FieldNo("Base - Excluded Amount"),
                          TempErrorMessage."Message Type"::Error, StrSubstNo(BaseExcludedAmountTotalErr, WithholdingTax."Entry No.", WithholdingTax."Base - Excluded Amount"));
                    WithholdingTaxLine.SetRange("Withholding Tax Entry No.", WithholdingTax."Entry No.");
                    WithholdingTaxLine.FindSet();
                    IsFirstLine := true;
                    repeat
                        CopyTaxToTempRespectingLine(TempWithholdingTaxByLine, IsFirstLine, WithholdingTax, WithholdingTaxLine);
                    until WithholdingTaxLine.Next() = 0;
                end;
            until WithholdingTax.Next() = 0;
        TempWithholdingTaxByLine.SetCurrentKey("Vendor No.", Reason, "Non-Taxable Income Type");
        if not TempWithholdingTaxByLine.FindSet() then
            exit;

        TempWithholdingTax.Reset();
        if TempWithholdingTax.FindLast() then
            EntryNo := TempWithholdingTax."Entry No.";
        repeat
            IsBlankNoTaxIncomeType := TempWithholdingTax."Non-Taxable Income Type" = TempWithholdingTax."Non-Taxable Income Type"::" ";

            TempWithholdingTax.SetRange("Vendor No.", TempWithholdingTaxByLine."Vendor No.");
            TempWithholdingTax.SetRange(Reason, TempWithholdingTaxByLine.Reason);
            TempWithholdingTax.SetRange("Non-Taxable Income Type", TempWithholdingTaxByLine."Non-Taxable Income Type");
            if (not TempWithholdingTax.FindFirst()) or IsBlankNoTaxIncomeType then begin
                TempWithholdingTax.Init();
                EntryNo += 1;
                TempWithholdingTax."Entry No." := EntryNo;
                TempWithholdingTax."Vendor No." := TempWithholdingTaxByLine."Vendor No.";
                TempWithholdingTax.Reason := TempWithholdingTaxByLine.Reason;
                TempWithholdingTax.Year := TempWithholdingTaxByLine.Year;
                TempWithholdingTax."Non-Taxable Income Type" := TempWithholdingTaxByLine."Non-Taxable Income Type";
                TempWithholdingTax.Insert();
            end;
            if TempWithholdingTaxByLine."Related Date" <> 0D then
                TempWithholdingTax."Related Date" := TempWithholdingTaxByLine."Related Date";
            if TempWithholdingTaxByLine."Non-Taxable Income Type" <> TempWithholdingTaxByLine."Non-Taxable Income Type"::" " then
                TempWithholdingTax."Non-Taxable Income Type" := TempWithholdingTaxByLine."Non-Taxable Income Type";
            TempWithholdingTax."Total Amount" += TempWithholdingTaxByLine."Total Amount";
            TempWithholdingTax."Non Taxable Amount By Treaty" += TempWithholdingTaxByLine."Non Taxable Amount By Treaty";
            TempWithholdingTax."Base - Excluded Amount" += TempWithholdingTaxByLine."Base - Excluded Amount";
            TempWithholdingTax."Non Taxable Amount" += TempWithholdingTaxByLine."Non Taxable Amount";
            TempWithholdingTax."Taxable Base" += TempWithholdingTaxByLine."Taxable Base";
            TempWithholdingTax."Withholding Tax Amount" += TempWithholdingTaxByLine."Withholding Tax Amount";
            TempWithholdingTax.Modify();
            CalculateContributions(WithholdingTax, TempWithholdingTax."Entry No.", TempContributions);
        until TempWithholdingTaxByLine.Next() = 0;
        TempWithholdingTax.Reset();
    end;

    local procedure CalculateContributions(var WithholdingTax: Record "Withholding Tax"; EntryNo: Integer; var TempContributions: Record Contributions temporary)
    var
        Contributions: Record Contributions;
    begin
        Contributions.SetRange("External Document No.", WithholdingTax."External Document No.");
        if not TempContributions.Get(EntryNo) then begin
            TempContributions.Init();
            TempContributions."Entry No." := EntryNo;
            TempContributions.Insert();
        end;

        if Contributions.FindSet() then
            repeat
                TempContributions."Company Amount" += Contributions."Company Amount";
                TempContributions."Free-Lance Amount" += Contributions."Free-Lance Amount";
            until Contributions.Next() = 0;
        TempContributions.Modify();
    end;

    local procedure CreateFileBody(var TempWithholdingTax: Record "Withholding Tax" temporary; var TempWithholdingTaxPrevYears: Record "Withholding Tax" temporary; var TempContributions: Record Contributions temporary; Year: Integer)
    var
        TempWithholdingTaxToExport: Record "Withholding Tax" temporary;
        EntryNumber: Integer;
        VendorEntryNumber: Integer;
        LastVendorNo: Code[20];
        LastReason: Enum "Withholding Tax Reason";
    begin
        EntryNumber := 0;
        VendorEntryNumber := 0;
        TempWithholdingTax.SetCurrentKey("Vendor No.", Reason, "Non-Taxable Income Type");
        if TempWithholdingTax.FindSet() then
            repeat
                TempContributions.Get(TempWithholdingTax."Entry No.");
                FindWithholdingTaxEntry(TempWithholdingTaxPrevYears, TempWithholdingTax."Vendor No.", TempWithholdingTax.Reason);
                EntryNumber += 1;
                if TempWithholdingTax."Vendor No." = LastVendorNo then
                    VendorEntryNumber += 1
                else
                    VendorEntryNumber := 1;
                if (TempWithholdingTax."Vendor No." <> LastVendorNo) or (TempWithholdingTax.Reason <> LastReason) then begin
                    TempWithholdingTax.SetRange("Vendor No.", TempWithholdingTax."Vendor No.");
                    TempWithholdingTax.SetRange(Reason, TempWithholdingTax.Reason);
                    CreateRecordD(TempWithholdingTax, EntryNumber);
                    LastVendorNo := TempWithholdingTax."Vendor No.";
                    LastReason := TempWithholdingTax.Reason;
                    TempWithholdingTax.CalcSums("Total Amount", "Taxable Base", "Withholding Tax Amount");
                    TempWithholdingTaxToExport := TempWithholdingTax;
                    TempWithholdingTax.SetRange("Vendor No.");
                    TempWithholdingTax.SetRange(Reason);
                end else begin
                    TempWithholdingTaxToExport := TempWithholdingTax;
                    TempWithholdingTaxToExport."Total Amount" := 0;
                    TempWithholdingTaxToExport."Taxable Base" := 0;
                    TempWithholdingTaxToExport."Withholding Tax Amount" := 0;
                    TempWithholdingTaxToExport.Reason := TempWithholdingTaxToExport.Reason::" ";
                end;
                CreateRecordH(TempWithholdingTaxToExport, TempWithholdingTaxPrevYears, TempContributions, Year, EntryNumber, VendorEntryNumber);
            until TempWithholdingTax.Next() = 0;
    end;

    local procedure CreateRecordA()
    var
        VendorTaxRepresentative: Record Vendor;
        TaxCode: Code[20];
    begin
        StartNewRecord(ConstRecordType::A);

        FlatFileManagement.WritePositionalValue(16, 5, ConstFormat::NU, StrSubstNo(CURTxt, ReportingYear mod 100 + 1), false); // A-3

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

    local procedure CreateRecordB()
    var
        VendorTaxRepresentative: Record Vendor;
        VATReportSetup: Record "VAT Report Setup";
        TaxCode: Code[20];
    begin
        StartNewRecord(ConstRecordType::B);

        TaxCode := CompanyInformation.GetTaxCode();
        if TaxCode <> '' then
            FlatFileManagement.WritePositionalValue(2, 16, ConstFormat::AN, TaxCode, false) // B-2
        else
            TempErrorMessage.LogMessage(
              CompanyInformation, CompanyInformation.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(CompanyMustHaveFiscalCodeOrVatRegNoErr, CompanyInformation.FieldCaption("Fiscal Code"),
                CompanyInformation.FieldCaption("VAT Registration No.")));

        FlatFileManagement.WritePositionalValue(18, 8, ConstFormat::NU, '1', false); // B-3
        FlatFileManagement.WritePositionalValue(74, 16, ConstFormat::AN, '08106710158', false); // B-8
        FlatFileManagement.WritePositionalValue(91, 1, ConstFormat::CB, '0', false); // B-10
        FlatFileManagement.WritePositionalValue(92, 1, ConstFormat::CB, '0', false); // B-11

        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(Name), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(137, 60, ConstFormat::AN, CompanyInformation.Name, false); // B-14
        FlatFileManagement.WritePositionalValue(197, 100, ConstFormat::AN, CompanyInformation."E-Mail", false); // B-15
        if CompanyInformation."Phone No." = '' then
            FlatFileManagement.WritePositionalValue(297, 12, ConstFormat::AN, '000000000000', true) // B-16
        else
            FlatFileManagement.WritePositionalValue(
              297, 12, ConstFormat::AN, FlatFileManagement.CleanPhoneNumber(CompanyInformation."Phone No."), true); // B-16
        FlatFileManagement.WritePositionalValue(309, 2, ConstFormat::NP, ExceptionalEvent, false); // B-17

        TempErrorMessage.LogIfEmpty(
          SigningCompanyOfficials, SigningCompanyOfficials.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(311, 16, ConstFormat::CF, SigningCompanyOfficials."Fiscal Code", false); // B-18
        TempErrorMessage.LogIfEmpty(
          SigningCompanyOfficials, SigningCompanyOfficials.FieldNo("Appointment Code"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(327, 2, ConstFormat::NU, SigningCompanyOfficials."Appointment Code", false); // B-19
        TempErrorMessage.LogIfEmpty(
          SigningCompanyOfficials, SigningCompanyOfficials.FieldNo("Last Name"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(329, 24, ConstFormat::AN, SigningCompanyOfficials."Last Name", false); // B-20
        TempErrorMessage.LogIfEmpty(
          SigningCompanyOfficials, SigningCompanyOfficials.FieldNo("First Name"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(353, 20, ConstFormat::AN, SigningCompanyOfficials."First Name", false); // B-21

        if TaxCode <> '' then
            FlatFileManagement.WritePositionalValue(373, 11, ConstFormat::CN, TaxCode, false); // B-22

        FlatFileManagement.WritePositionalValue(384, 18, ConstFormat::AN, '000000000000000000', false); // B-23
        if CommunicationNumber <> 0 then
            FlatFileManagement.WritePositionalValue(402, 8, ConstFormat::NU, Format(CommunicationNumber), false) // B-24
        else
            FlatFileManagement.WritePositionalValue(402, 8, ConstFormat::NU, Format(RecordDCount), false); // B-24
        FlatFileManagement.WritePositionalValue(410, 1, ConstFormat::CB, '0', false); // B-25
        FlatFileManagement.WritePositionalValue(411, 1, ConstFormat::CB, '1', false); // B-26

        if VendorTaxRepresentative.Get(CompanyInformation."Tax Representative No.") then begin
            TaxCode := VendorTaxRepresentative.GetTaxCode();
            if TaxCode <> '' then
                FlatFileManagement.WritePositionalValue(412, 16, ConstFormat::CF, TaxCode, false) // B-27
            else
                TempErrorMessage.LogMessage(
                  VendorTaxRepresentative, VendorTaxRepresentative.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
                  StrSubstNo(
                    VendorMustHaveFiscalCodeOrVatRegNoErr, VendorTaxRepresentative."No.",
                    VendorTaxRepresentative.FieldCaption("Fiscal Code"),
                    VendorTaxRepresentative.FieldCaption("VAT Registration No.")));

            if ReportPreparedBy = ReportPreparedBy::Company then
                FlatFileManagement.WritePositionalValue(428, 1, ConstFormat::NU, '1', false) // B-28
            else
                FlatFileManagement.WritePositionalValue(428, 1, ConstFormat::NU, '2', false); // B-28 // Prepared by Tax Representative
            VATReportSetup.Get();
            TempErrorMessage.LogIfEmpty(VATReportSetup, VATReportSetup.FieldNo("Intermediary Date"), TempErrorMessage."Message Type"::Error);
            FlatFileManagement.WritePositionalValue(
              429, 8, ConstFormat::DT, FlatFileManagement.FormatDate(VATReportSetup."Intermediary Date", ConstFormat::DT), false); // B-29
            FlatFileManagement.WritePositionalValue(437, 1, ConstFormat::CB, '1', false); // B-30
        end else begin
            FlatFileManagement.WritePositionalValue(428, 1, ConstFormat::NU, '0', false); // B-28
            FlatFileManagement.WritePositionalValue(429, 8, ConstFormat::NU, '00000000', false); // B-29
            FlatFileManagement.WritePositionalValue(437, 1, ConstFormat::CB, '0', false); // B-30
        end;
        FlatFileManagement.WritePositionalValue(527, 1, ConstFormat::CB, '0', false); // B-37
    end;

    local procedure CreateRecordD(var TempWithholdingTax: Record "Withholding Tax" temporary; EntryNumber: Integer)
    var
        VendorWithholdingTax: Record Vendor;
        GeneralLedgerSetup: Record "General Ledger Setup";
        VendorCountryRegion: Record "Country/Region";
        CompanyTaxCode: Code[20];
        VendorTaxCode: Code[20];
        VendorCountryCode: Code[10];
    begin
        VendorWithholdingTax.Get(TempWithholdingTax."Vendor No.");

        StartNewRecord(ConstRecordType::D);

        CompanyTaxCode := CompanyInformation.GetTaxCode();
        if CompanyTaxCode <> '' then
            FlatFileManagement.WritePositionalValue(2, 16, ConstFormat::AN, CompanyTaxCode, false) // D-2
        else
            TempErrorMessage.LogMessage(
              CompanyInformation, CompanyInformation.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(CompanyMustHaveFiscalCodeOrVatRegNoErr, CompanyInformation.FieldCaption("Fiscal Code"),
                CompanyInformation.FieldCaption("VAT Registration No.")));

        WritePositionalValueAmount(18, 8, ConstFormat::NU, FlatFileManagement.GetFileCount(), false); // D-3

        VendorTaxCode := VendorWithholdingTax.GetTaxCode();
        if VendorTaxCode <> '' then
            FlatFileManagement.WritePositionalValue(26, 16, ConstFormat::AN, VendorTaxCode, false) // D-4
        else
            TempErrorMessage.LogMessage(
              VendorWithholdingTax, VendorWithholdingTax.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(
                VendorMustHaveFiscalCodeOrVatRegNoErr, VendorWithholdingTax."No.", VendorWithholdingTax.FieldCaption("Fiscal Code"),
                VendorWithholdingTax.FieldCaption("VAT Registration No.")));

        WritePositionalValueAmount(42, 5, ConstFormat::NU, EntryNumber, false); // D-5
        FlatFileManagement.WritePositionalValue(47, 17, ConstFormat::NU, '', false); // D-6
        FlatFileManagement.WritePositionalValue(64, 6, ConstFormat::NU, '', false); // D-7
        FlatFileManagement.WritePositionalValue(84, 1, ConstFormat::AN, '', false); // D-9
        if TempWithholdingTax.Count = 1 then
            FlatFileManagement.WritePositionalValue(89, 1, ConstFormat::CB, '0', false) // D-11
        else
            FlatFileManagement.WritePositionalValue(89, 1, ConstFormat::CB, '1', false); // D-11

        if CompanyTaxCode <> '' then
            FlatFileManagement.WriteBlockValue('DA001001', ConstFormat::CF, CompanyTaxCode)
        else
            TempErrorMessage.LogMessage(
              CompanyInformation, CompanyInformation.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(CompanyMustHaveFiscalCodeOrVatRegNoErr, CompanyInformation.FieldCaption("Fiscal Code"),
                CompanyInformation.FieldCaption("VAT Registration No.")));

        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(Name), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WriteBlockValue('DA001002', ConstFormat::AN, CompanyInformation.Name);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(City), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WriteBlockValue('DA001004', ConstFormat::AN, CompanyInformation.City);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(County), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WriteBlockValue('DA001005', ConstFormat::PR, CompanyInformation.County);
        FlatFileManagement.WriteBlockValue('DA001006', ConstFormat::AN, CompanyInformation."Post Code");
        FlatFileManagement.WriteBlockValue('DA001007', ConstFormat::AN, CompanyInformation.Address);
        FlatFileManagement.WriteBlockValue(
          'DA001008', ConstFormat::AN, FlatFileManagement.CleanPhoneNumber(CompanyInformation."Phone No."));
        FlatFileManagement.WriteBlockValue('DA001009', ConstFormat::AN, CompanyInformation."E-Mail");
        GeneralLedgerSetup.GetRecordOnce();
        if GeneralLedgerSetup."Use Activity Code" then begin
            TempErrorMessage.LogIfEmpty(
              CompanyInformation, CompanyInformation.FieldNo("Activity Code"), TempErrorMessage."Message Type"::Error);
            FlatFileManagement.WriteBlockValue('DA001010', ConstFormat::AN, CompanyInformation."Activity Code");
        end;
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("Office Code"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WriteBlockValue('DA001011', ConstFormat::AN, CompanyInformation."Office Code");

        if VendorWithholdingTax."Fiscal Code" <> '' then
            FlatFileManagement.WriteBlockValue('DA002001', ConstFormat::CF, VendorWithholdingTax."Fiscal Code")
        else
            if VendorWithholdingTax."VAT Registration No." <> '' then
                FlatFileManagement.WriteBlockValue('DA002001', ConstFormat::CF, VendorWithholdingTax."VAT Registration No.")
            else
                TempErrorMessage.LogMessage(
                  VendorWithholdingTax, VendorWithholdingTax.FieldNo("Contribution Fiscal Code"), TempErrorMessage."Message Type"::Error,
                  StrSubstNo(
                    VendorMustHaveFiscalCodeOrVatRegNoErr, VendorWithholdingTax."No.",
                    VendorWithholdingTax.FieldCaption("Contribution Fiscal Code"),
                    VendorWithholdingTax.FieldCaption("VAT Registration No.")));

        if VendorWithholdingTax."Individual Person" then begin
            TempErrorMessage.LogIfEmpty(
              VendorWithholdingTax, VendorWithholdingTax.FieldNo("Last Name"), TempErrorMessage."Message Type"::Warning);
            FlatFileManagement.WriteBlockValue('DA002002', ConstFormat::AN, VendorWithholdingTax."Last Name");
        end else begin
            TempErrorMessage.LogIfEmpty(
              VendorWithholdingTax, VendorWithholdingTax.FieldNo(Name), TempErrorMessage."Message Type"::Warning);
            FlatFileManagement.WriteBlockValue('DA002002', ConstFormat::AN, VendorWithholdingTax.Name);
        end;
        if VendorWithholdingTax."Individual Person" then
            TempErrorMessage.LogIfEmpty(
              VendorWithholdingTax, VendorWithholdingTax.FieldNo("First Name"), TempErrorMessage."Message Type"::Warning);
        FlatFileManagement.WriteBlockValue('DA002003', ConstFormat::AN, VendorWithholdingTax."First Name");
        if VendorWithholdingTax."Individual Person" then
            if VendorWithholdingTax.Gender = VendorWithholdingTax.Gender::Male then
                FlatFileManagement.WriteBlockValue('DA002004', ConstFormat::AN, 'M')
            else
                FlatFileManagement.WriteBlockValue('DA002004', ConstFormat::AN, 'F');
        FlatFileManagement.WriteBlockValue(
          'DA002005', ConstFormat::DT, FlatFileManagement.FormatDate(VendorWithholdingTax."Date of Birth", ConstFormat::DT));
        FlatFileManagement.WriteBlockValue('DA002006', ConstFormat::AN, VendorWithholdingTax."Birth City");
        FlatFileManagement.WriteBlockValue('DA002007', ConstFormat::PN, VendorWithholdingTax."Birth County");
        if VendorWithholdingTax."Special Category" <> VendorWithholdingTax."Special Category"::" " then
            FlatFileManagement.WriteBlockValue('DA002008', ConstFormat::AN, Format(VendorWithholdingTax."Special Category"));
        FlatFileManagement.WriteBlockValue('DA002010', ConstFormat::NU, '0');

        VendorCountryCode := CompanyInformation.GetCountryRegionCode(VendorWithholdingTax."Country/Region Code");
        if VendorCountryCode <> 'IT' then begin
            VendorCountryRegion.Get(VendorCountryCode);
            VendorCountryRegion.TestField("ISO Numeric Code");
            FlatFileManagement.WriteBlockValue('DA002011', ConstFormat::AN, VendorCountryRegion."ISO Numeric Code");
        end;

        FlatFileManagement.WriteBlockValue('DA002030', ConstFormat::AN, '');

        FlatFileManagement.WriteBlockValue('DA003001', ConstFormat::DT, FlatFileManagement.FormatDate(Today, ConstFormat::DT));
        FlatFileManagement.WriteBlockValue('DA003002', ConstFormat::CB, '1');
    end;

    local procedure CreateRecordH(var TempWithholdingTax: Record "Withholding Tax" temporary; var TempWithholdingTaxPrevYears: Record "Withholding Tax" temporary; var TempContributions: Record Contributions temporary; Year: Integer; EntryNumber: Integer; VendorEntryNumber: Integer)
    var
        VendorWithholdingTax: Record Vendor;
        TaxCode: Code[20];
    begin
        VendorWithholdingTax.Get(TempWithholdingTax."Vendor No.");
        StartNewRecord(ConstRecordType::H);

        TaxCode := CompanyInformation.GetTaxCode();
        if TaxCode <> '' then
            FlatFileManagement.WritePositionalValue(2, 16, ConstFormat::AN, TaxCode, false) // H-2
        else
            TempErrorMessage.LogMessage(
              CompanyInformation, CompanyInformation.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(CompanyMustHaveFiscalCodeOrVatRegNoErr, CompanyInformation.FieldCaption("Fiscal Code"),
                CompanyInformation.FieldCaption("VAT Registration No.")));

        WritePositionalValueAmount(18, 8, ConstFormat::NU, EntryNumber, false); // H-3

        TaxCode := VendorWithholdingTax.GetTaxCode();
        if TaxCode <> '' then
            FlatFileManagement.WritePositionalValue(26, 16, ConstFormat::AN, TaxCode, false) // H-4
        else
            TempErrorMessage.LogMessage(
              VendorWithholdingTax, VendorWithholdingTax.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(
                VendorMustHaveFiscalCodeOrVatRegNoErr, VendorWithholdingTax."No.", VendorWithholdingTax.FieldCaption("Fiscal Code"),
                VendorWithholdingTax.FieldCaption("VAT Registration No.")));

        WritePositionalValueAmount(42, 5, ConstFormat::NU, VendorEntryNumber, false); // H-5
        FlatFileManagement.WritePositionalValue(47, 17, ConstFormat::NU, '', false); // H-6
        FlatFileManagement.WritePositionalValue(64, 6, ConstFormat::NU, '', false); // H-7
        FlatFileManagement.WritePositionalValue(89, 1, ConstFormat::NU, '', false); // H-11

        if TempWithholdingTax.Reason <> TempWithholdingTax.Reason::" " then
            FlatFileManagement.WriteBlockValue('AU001001', ConstFormat::AN, Format(TempWithholdingTax.Reason));
        if TempWithholdingTax.Reason in [TempWithholdingTax.Reason::G, TempWithholdingTax.Reason::H, TempWithholdingTax.Reason::I] then
            FlatFileManagement.WriteBlockValue('AU001002', ConstFormat::DA, Format(TempWithholdingTax.Year - 1));
        if TempWithholdingTax."Total Amount" <> 0 then
            WriteBlockValueAmount('AU001004', ConstFormat::VP, TempWithholdingTax."Total Amount");
        if VendorWithholdingTax.Resident <> VendorWithholdingTax.Resident::"Non-Resident" then
            WriteBlockValueAmount('AU001005', ConstFormat::VP, TempWithholdingTax."Non Taxable Amount By Treaty");
        if (TempWithholdingTax."Non Taxable Amount By Treaty" + TempWithholdingTax."Base - Excluded Amount" <> 0) and
            (TempWithholdingTax."Non-Taxable Income Type" <> TempWithholdingTax."Non-Taxable Income Type"::" ")
        then
            FlatFileManagement.WriteBlockValue('AU001006', ConstFormat::NP, Format(TempWithholdingTax.GetNonTaxableIncomeTypeNumber()));
        WriteBlockValueAmount('AU001007', ConstFormat::VP,
          TempWithholdingTax."Non Taxable Amount" + TempWithholdingTax."Base - Excluded Amount");
        if TempWithholdingTax."Taxable Base" = 0 then
            FlatFileManagement.WriteBlankValue(ConstFormat::VP)
        else
            WriteBlockValueAmount('AU001008', ConstFormat::VP, TempWithholdingTax."Taxable Base");
        if TempWithholdingTax."Withholding Tax Amount" = 0 then
            FlatFileManagement.WriteBlankValue(ConstFormat::VP)
        else
            WriteBlockValueAmount('AU001009', ConstFormat::VP, TempWithholdingTax."Withholding Tax Amount");
        WriteBlockValueAmount('AU001010', ConstFormat::VP, 0);

        WriteBlocksAU001018AndAU001019(TempWithholdingTaxPrevYears, Year);

        WriteBlockValueAmount('AU001020', ConstFormat::VP, TempContributions."Company Amount");
        WriteBlockValueAmount('AU001021', ConstFormat::VP, TempContributions."Free-Lance Amount");
    end;

    local procedure CreateRecordZ()
    var
        Index: Integer;
        Pos: Integer;
        Len: Integer;
    begin
        StartNewRecord(ConstRecordType::Z);
        Pos := 16;
        Len := 9;
        for Index := ConstRecordType::B to ConstRecordType::H do
            if Index in [ConstRecordType::B, ConstRecordType::C, ConstRecordType::D, ConstRecordType::G, ConstRecordType::H] then begin
                FlatFileManagement.WritePositionalValue(Pos, Len, ConstFormat::NU, Format(FlatFileManagement.GetRecordCount(Index), 0, 1), false);
                Pos += Len;
            end;
        FlatFileManagement.WritePositionalValue(Pos, Len, ConstFormat::NU, Format(0, 0, 1), false);
    end;

    local procedure EndFile()
    begin
        CreateRecordZ();
        FlatFileManagement.EndFile();
    end;

    local procedure FindWithholdingTaxEntry(var TempWithholdingTax: Record "Withholding Tax" temporary; VendorNo: Code[20]; Reason: Enum "Withholding Tax Reason")
    begin
        TempWithholdingTax.SetRange("Vendor No.", VendorNo);
        TempWithholdingTax.SetRange(Reason, Reason);
        if not TempWithholdingTax.FindFirst() then
            Clear(TempWithholdingTax);
    end;

    local procedure InitTempWithholdingTax(var TempWithholdingTax: Record "Withholding Tax" temporary; WithholdingTax: Record "Withholding Tax")
    begin
        TempWithholdingTax.Init();
        TempWithholdingTax."Entry No." := WithholdingTax."Entry No.";
        TempWithholdingTax."Vendor No." := WithholdingTax."Vendor No.";
        TempWithholdingTax.Reason := WithholdingTax.Reason;
        TempWithholdingTax.Year := WithholdingTax.Year;
        TempWithholdingTax."Non-Taxable Income Type" := WithholdingTax."Non-Taxable Income Type";
    end;

    local procedure StartNewRecord(Type: Option A,B,C,D,E,G,H,Z)
    begin
        if FlatFileManagement.RecordsPerFileExceeded(Type) then begin
            EndFile();
            StartNewFileWithHeader();
        end;
        FlatFileManagement.StartNewRecord(Type);
    end;

    local procedure StartNewFileWithHeader()
    begin
        FlatFileManagement.StartNewFile();
        CreateRecordA();
        CreateRecordB();
    end;

    local procedure WriteBlockValueAmount("Code": Code[8]; ValueFormat: Option; DecimalValue: Decimal)
    var
        TextValue: Text;
    begin
        if DecimalValue = 0 then
            exit;

        TextValue := FlatFileManagement.FormatNum(DecimalValue, ValueFormat);
        FlatFileManagement.WriteBlockValue(Code, ValueFormat, TextValue);
    end;

    local procedure WritePositionalValueAmount(Position: Integer; Length: Integer; ValueFormat: Option; DecimalValue: Decimal; Truncate: Boolean)
    var
        TextValue: Text;
    begin
        TextValue := FlatFileManagement.FormatNum(DecimalValue, ValueFormat);
        FlatFileManagement.WritePositionalValue(Position, Length, ValueFormat, TextValue, Truncate);
    end;

    [Scope('OnPrem')]
    procedure WriteBlocksAU001018AndAU001019(TempWithholdingTaxPrevYears: Record "Withholding Tax" temporary; Year: Integer)
    begin
        if TempWithholdingTaxPrevYears."Related Date" = 0D then
            exit;

        if Date2DMY(TempWithholdingTaxPrevYears."Related Date", 3) <> Year then
            exit;

        WriteBlockValueAmount('AU001018', ConstFormat::VP, TempWithholdingTaxPrevYears."Taxable Base");
        // There's a tolerance of max 2 on the max witholding tax amount
        if TempWithholdingTaxPrevYears."Withholding Tax Amount" > TempWithholdingTaxPrevYears."Taxable Base" + 1 then
            if Confirm(ReplaceFieldValueToMaxAllowedQst, true,
                 TempWithholdingTaxPrevYears."Taxable Base",
                 TempWithholdingTaxPrevYears."Withholding Tax Amount")
            then
                WriteBlockValueAmount('AU001019', ConstFormat::VP, TempWithholdingTaxPrevYears."Taxable Base")
            else
                WriteBlockValueAmount('AU001019', ConstFormat::VP, TempWithholdingTaxPrevYears."Withholding Tax Amount");
    end;

    local procedure LinesExistForEntryNo(EntryNo: Integer): Boolean
    var
        WithholdingTaxLine: Record "Withholding Tax Line";
    begin
        WithholdingTaxLine.SetRange("Withholding Tax Entry No.", EntryNo);
        exit(not WithholdingTaxLine.IsEmpty());
    end;

    local procedure CopyTaxToTempRespectingLine(var TempWithholdingTax: Record "Withholding Tax" temporary; var IsFirstLine: Boolean; WithholdingTax: Record "Withholding Tax"; WithholdingTaxLine: Record "Withholding Tax Line")
    var
        EntryNo: Integer;
    begin
        if TempWithholdingTax.FindLast() then;
        EntryNo := TempWithholdingTax."Entry No." + 1;
        TempWithholdingTax.Init();
        TempWithholdingTax."Entry No." := EntryNo;
        TempWithholdingTax."Vendor No." := WithholdingTax."Vendor No.";
        TempWithholdingTax.Reason := WithholdingTax.Reason;
        TempWithholdingTax.Year := WithholdingTax.Year;
        TempWithholdingTax."Related Date" := WithholdingTax."Related Date";
        if IsFirstLine then begin
            TempWithholdingTax."Total Amount" := WithholdingTax."Total Amount";
            TempWithholdingTax."Non Taxable Amount By Treaty" := WithholdingTax."Non Taxable Amount By Treaty";
            TempWithholdingTax."Non Taxable Amount" := WithholdingTax."Non Taxable Amount";
            TempWithholdingTax."Taxable Base" := WithholdingTax."Taxable Base";
            TempWithholdingTax."Withholding Tax Amount" := WithholdingTax."Withholding Tax Amount";
            IsFirstLine := false;
        end;
        TempWithholdingTax."Non-Taxable Income Type" := WithholdingTaxLine."Non-Taxable Income Type";
        TempWithholdingTax."Base - Excluded Amount" := WithholdingTaxLine."Base - Excluded Amount";
        TempWithholdingTax.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateWithholdingTaxPerVendorOnAfterWithholdingTaxSetFilter(var WithholdingTax: record "Withholding Tax")
    begin
    end;
}
