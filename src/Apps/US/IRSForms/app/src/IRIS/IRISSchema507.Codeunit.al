// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Company;
using System.Utilities;

codeunit 10053 "IRIS Schema 5.0.7" implements "IRIS XML Schema"
{
    Access = Internal;

    var
        Helper: Codeunit "Helper IRIS";
        Generator: Codeunit "Generate Xml File IRIS";
        TaxYear: Text[4];
        CorrectionToZeroModeGlobal: Boolean;
        EmptyFieldErr: Label 'must be set.';
        TooManyOccupationCodesErr: Label 'Documents %1 contain more than two different Treasury tipped occupation codes for the same recipient. Review the occupation codes in Supplemental Lines before generating the transmission.', Comment = '%1 - contributing document IDs';
        SupplementalTotalErr: Label 'For documents %3, the total %2 for supplemental XML element %1 must be between zero and %4, the maximum amount allowed by the IRIS XML schema.', Comment = '%1 - XML element, %2 - aggregate amount, %3 - selected document IDs, %4 - maximum amount';

    procedure GetVersionText(): Text
    begin
        exit('5.0.7');
    end;

    procedure ValidateTransmission(Transmission: Record "Transmission IRIS")
    var
        CompanyInformation: Record "Company Information";
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        if Transmission."Period No." <> '2026' then
            exit;
        CompanyInformation.Get();
        if CompanyInformation."E-Mail" = '' then
            ErrorMessageMgt.LogFieldError(CompanyInformation, CompanyInformation.FieldNo("E-Mail"), EmptyFieldErr);
    end;

    procedure CreateTransmissionXmlContent(var Transmission: Record "Transmission IRIS"; TransmissionType: Enum "Transmission Type IRIS"; CorrectionToZeroMode: Boolean; var UniqueTransmissionId: Text[100]; var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var TempBlob: Codeunit "Temp Blob")
    var
        FormType: Text;
        PriorYearDataIndicator: Text;
    begin
        Clear(Generator);
        TaxYear := Transmission."Period No.";
        CorrectionToZeroModeGlobal := CorrectionToZeroMode;
        Generator.PrepareTransmission(Transmission, TransmissionType, CorrectionToZeroMode, GetVersionText(),
            TaxYear in ['2025', '2026'], UniqueTransmissionId, TempDocHeader);
        PriorYearDataIndicator := '0';
        if TaxYear < '2026' then
            PriorYearDataIndicator := '1';
        Generator.AddIRTransmissionManifest(Transmission, UniqueTransmissionId, GetVersionText(), PriorYearDataIndicator);
        foreach FormType in "Form Type IRIS".Names() do begin
            TempDocHeader.Reset();
            TempDocHeader.SetRange("Form No.", FormType);
            if not TempDocHeader.IsEmpty() then
                AddSubmission(TempDocHeader, TransmissionType);
        end;
        Generator.FinishTransmission(TempDocHeader, TempBlob);
    end;

    local procedure AddSubmission(var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; TransmissionType: Enum "Transmission Type IRIS")
    var
        CompanyInformation: Record "Company Information";
        XmlValues: Dictionary of [Text, Text];
        OccupationCodes: List of [Text];
        VendorList: List of [Text];
        VendorNo: Text;
        SubmissionId: Text[20];
        RecordId: Text[20];
    begin
        Generator.AddParentXmlNode('IRSubmission1Grp');
        VendorList := Generator.GetVendorList(TempDocHeader);
        SubmissionId := Generator.StartSubmissionHeader(TempDocHeader);
        Generator.GetContactCompanyInformation(CompanyInformation);
        if TaxYear = '2026' then begin
            CompanyInformation.TestField("Contact Person");
            CompanyInformation.TestField("Phone No.");
            CompanyInformation.TestField("E-Mail");
        end;
        Generator.AddContactPersonInformationGrp(CompanyInformation);
        Generator.AddSubmissionFormInfo(TempDocHeader, VendorList.Count());
        AddSupplementalTotals(TempDocHeader, XmlValues);
        Generator.AddSubmissionTotals(TempDocHeader, XmlValues);
        Generator.CloseParentXmlNode();
        Generator.SetSubmissionIdOnTempHeaders(TempDocHeader, SubmissionId);

        Generator.AddParentXmlNode('IRSubmission1Detail');
        foreach VendorNo in VendorList do begin
            TempDocHeader.SetRange("Vendor No.", VendorNo);
            if Generator.StartFormDetail(TempDocHeader, RecordId) then begin
                if TransmissionType = TransmissionType::C then
                    Generator.AddPrevSubmittedRecRecipientGrp(TempDocHeader, '0');
                Clear(XmlValues);
                AddSupplementalValues(TempDocHeader, XmlValues, OccupationCodes);
                Generator.AddRecipientAndFormValues(TempDocHeader, XmlValues);
                Generator.FinishFormDetail(TempDocHeader, RecordId, XmlValues, OccupationCodes);
            end;
        end;
        Generator.CloseParentXmlNode();
        Generator.CloseParentXmlNode();
    end;

    local procedure AddSupplementalTotals(var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var XmlValues: Dictionary of [Text, Text])
    var
        TempRecipientDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        Amounts: Dictionary of [Text, Decimal];
        RecipientAmounts: Dictionary of [Text, Decimal];
        OccupationCodes: List of [Text];
        VendorList: List of [Text];
        VendorNo: Text;
        ElementName: Text;
        SelectedDocuments: Text;
        RecipientDocuments: Text;
    begin
        TempRecipientDocHeader.Copy(TempDocHeader, true);
        VendorList := Generator.GetVendorList(TempRecipientDocHeader);
        foreach VendorNo in VendorList do begin
            TempRecipientDocHeader.SetRange("Vendor No.", VendorNo);
            CalcSupplementalRecipientAmounts(TempRecipientDocHeader, RecipientAmounts, OccupationCodes, RecipientDocuments);
            if SelectedDocuments <> '' then
                SelectedDocuments += ', ';
            SelectedDocuments += RecipientDocuments;
            foreach ElementName in RecipientAmounts.Keys() do begin
                if not Amounts.ContainsKey(ElementName) then
                    Amounts.Add(ElementName, 0);
                AddSupplementalAmount(Amounts, ElementName, RecipientAmounts.Get(ElementName), SelectedDocuments);
            end;
        end;
        foreach ElementName in Amounts.Keys() do
            XmlValues.Add(ElementName, Helper.FormatDecimal(Amounts.Get(ElementName)));
    end;

    local procedure AddSupplementalValues(var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var XmlValues: Dictionary of [Text, Text]; var OccupationCodes: List of [Text])
    var
        Amounts: Dictionary of [Text, Decimal];
        SelectedDocuments: Text;
        ElementName: Text;
    begin
        CalcSupplementalRecipientAmounts(TempDocHeader, Amounts, OccupationCodes, SelectedDocuments);
        foreach ElementName in Amounts.Keys() do
            XmlValues.Add(ElementName, Helper.FormatDecimal(Amounts.Get(ElementName)));
    end;

    local procedure CalcSupplementalRecipientAmounts(var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var Amounts: Dictionary of [Text, Decimal]; var OccupationCodes: List of [Text]; var SelectedDocuments: Text)
    var
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        Supplemental: Codeunit "IRS 1099 Supplemental";
        ParentBoxNo: Code[20];
        ElementName: Text[100];
        ValueType: Enum "IRS 1099 Supplemental Type";
        CodeDocuments: Text;
        Amount: Decimal;
    begin
        Clear(Amounts);
        Clear(OccupationCodes);
        Clear(SelectedDocuments);
        if (TaxYear < '2026') or not (TempDocHeader."Form No." in ['MISC', 'NEC']) then
            exit;
        Amounts.Add('CashTipsAmt', 0);
        Amounts.Add('OvertimeCompensationAmt', 0);
        if TempDocHeader.FindSet() then
            repeat
                if SelectedDocuments <> '' then
                    SelectedDocuments += ', ';
                SelectedDocuments += Format(TempDocHeader.ID);
                SupplLine.SetRange("Document ID", TempDocHeader.ID);
                if SupplLine.FindSet() then
                    repeat
                        if Supplemental.GetMapping(TaxYear, TempDocHeader."Form No.", SupplLine."Supplemental Box No.", ParentBoxNo, ElementName, ValueType) then
                            if Supplemental.IsReportable(SupplLine) then
                                case ValueType of
                                    ValueType::Amount:
                                        if not CorrectionToZeroModeGlobal then
                                            AddSupplementalAmount(Amounts, ElementName, SupplLine.Amount, SelectedDocuments);
                                    ValueType::"Occupation Codes":
                                        if not CorrectionToZeroModeGlobal then begin
                                            if CodeDocuments <> '' then
                                                CodeDocuments += ', ';
                                            CodeDocuments += Format(TempDocHeader.ID);
                                            AddOccupationCode(OccupationCodes, SupplLine."Occupation Code 1");
                                            AddOccupationCode(OccupationCodes, SupplLine."Occupation Code 2");
                                        end;
                                end;
                    until SupplLine.Next() = 0;
            until TempDocHeader.Next() = 0;
        foreach ElementName in Amounts.Keys() do begin
            Amount := Supplemental.RoundAmount(Amounts.Get(ElementName));
            Amounts.Set(ElementName, Amount);
        end;
        if Amounts.Get('CashTipsAmt') = 0 then
            Clear(OccupationCodes)
        else
            if OccupationCodes.Count() > 2 then
                Error(TooManyOccupationCodesErr, CodeDocuments);
    end;

    local procedure AddSupplementalAmount(var Amounts: Dictionary of [Text, Decimal]; ElementName: Text; Amount: Decimal; SelectedDocuments: Text)
    begin
        if (Amount < 0) or (Amount > 999999999999999.99) or
           (Amounts.Get(ElementName) > 999999999999999.99 - Amount)
        then
            Error(SupplementalTotalErr, ElementName,
                Format(Amounts.Get(ElementName)) + ' + ' + Format(Amount),
                SelectedDocuments, 999999999999999.99);
        Amounts.Set(ElementName, Amounts.Get(ElementName) + Amount);
    end;

    local procedure AddOccupationCode(var OccupationCodes: List of [Text]; OccupationCode: Text)
    begin
        if (OccupationCode <> '') and not OccupationCodes.Contains(OccupationCode) then
            OccupationCodes.Add(OccupationCode);
    end;
}
