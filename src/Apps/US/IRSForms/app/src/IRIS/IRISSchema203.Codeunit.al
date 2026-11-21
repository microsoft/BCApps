// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Company;
using System.Utilities;

codeunit 10038 "IRIS Schema 2.0.3" implements "IRIS XML Schema"
{
    Access = Internal;

    var
        Generator: Codeunit "Generate Xml File IRIS";
        SupplementalSchemaErr: Label 'Document %1 contains supplemental lines that cannot be reported using IRIS XML schema %2. Select XML schema version 5.0.7 before generating the transmission.', Comment = '%1 - document ID, %2 - schema version';

    procedure GetVersionText(): Text
    begin
        exit('2.0.3');
    end;

    procedure ValidateTransmission(Transmission: Record "Transmission IRIS")
    begin
    end;

    procedure CreateTransmissionXmlContent(var Transmission: Record "Transmission IRIS"; TransmissionType: Enum "Transmission Type IRIS"; CorrectionToZeroMode: Boolean; var UniqueTransmissionId: Text[100]; var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var TempBlob: Codeunit "Temp Blob")
    var
        FormType: Text;
    begin
        Clear(Generator);
        Generator.PrepareTransmission(Transmission, TransmissionType, CorrectionToZeroMode, GetVersionText(),
            Transmission."Period No." in ['2024', '2025'], UniqueTransmissionId, TempDocHeader);
        if TempDocHeader.FindSet() then
            repeat
                ValidateSupplementalDocument(TempDocHeader.ID);
            until TempDocHeader.Next() = 0;

        Generator.AddIRTransmissionManifest(Transmission, UniqueTransmissionId, GetVersionText(), '0');
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
        Generator.AddContactPersonInformationGrp(CompanyInformation);
        Generator.AddSubmissionFormInfo(TempDocHeader, VendorList.Count());
        Generator.AddSubmissionTotals(TempDocHeader, XmlValues);
        Generator.CloseParentXmlNode();
        Generator.SetSubmissionIdOnTempHeaders(TempDocHeader, SubmissionId);

        Generator.AddParentXmlNode('IRSubmission1Detail');
        foreach VendorNo in VendorList do begin
            TempDocHeader.SetRange("Vendor No.", VendorNo);
            if Generator.StartFormDetail(TempDocHeader, RecordId) then begin
                if TransmissionType = TransmissionType::C then
                    Generator.AddPrevSubmittedRecRecipientGrp(TempDocHeader, '');
                Clear(XmlValues);
                Generator.AddRecipientAndFormValues(TempDocHeader, XmlValues);
                Generator.FinishFormDetail(TempDocHeader, RecordId, XmlValues, OccupationCodes);
            end;
        end;
        Generator.CloseParentXmlNode();
        Generator.CloseParentXmlNode();
    end;

    local procedure ValidateSupplementalDocument(DocumentID: Integer)
    var
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        SupplLine.SetRange("Document ID", DocumentID);
        if SupplLine.FindSet() then
            repeat
                if (SupplLine.Amount <> 0) or (SupplLine."Occupation Code 1" <> '') or
                   (SupplLine."Occupation Code 2" <> '')
                then
                    Error(SupplementalSchemaErr, DocumentID, GetVersionText());
            until SupplLine.Next() = 0;
    end;
}
