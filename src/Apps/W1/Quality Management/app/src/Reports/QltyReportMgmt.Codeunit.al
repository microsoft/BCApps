// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Reports;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;

codeunit 20440 "Qlty. Report Mgmt."
{
    internal procedure PrintGeneralPurposeInspection(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"Quality Management - General Purpose Inspection");
        if ReportSelections.IsEmpty() then
            Report.Run(Report::"Qlty. General Purpose Inspect.", true, true, QltyInspectionHeader)
        else
            ReportSelections.PrintReport(ReportSelections.Usage::"Quality Management - General Purpose Inspection", QltyInspectionHeader);
    end;

    internal procedure PrintNonConformance(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"Quality Management - Non-Conformance");
        if ReportSelections.IsEmpty() then
            Report.Run(Report::"Qlty. Non-Conformance", true, true, QltyInspectionHeader)
        else
            ReportSelections.PrintReport(ReportSelections.Usage::"Quality Management - Non-Conformance", QltyInspectionHeader);
    end;

    internal procedure PrintCertificateOfAnalysis(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"Quality Management - Certificate of Analysis");
        if ReportSelections.IsEmpty() then
            Report.Run(Report::"Qlty. Certificate of Analysis", true, true, QltyInspectionHeader)
        else
            ReportSelections.PrintReport(ReportSelections.Usage::"Quality Management - Certificate of Analysis", QltyInspectionHeader);
    end;

    #region Helper methods
    var
        ReinspectionSequenceLbl: Label 'Re-inspection: %1', Comment = '%1 = the sequence number of the re-inspection';
        StatusLbl: Label 'Status: %1', Comment = '%1 = the status of the inspection';
        ResultLbl: Label 'Result: %1', Comment = '%1 = the result of the inspection';

    internal procedure ResolveCompanyInformation(var CompanyInformation: Record "Company Information"; var CompanyInformationArray: array[8] of Text[100]; var AllCompanyInformation: Text; var HomePageValueText: Text; HomePageLbl: Text; var HomePageLabelText: Text; var EmailValueText: Text; EmailLbl: Text; var EmailLabelText: Text; var PhoneNoValueText: Text; PhoneNoLbl: Text; var PhoneNoLabelText: Text)
    var
        FormatAddress: Codeunit "Format Address";
    begin
        CompanyInformation.SetAutoCalcFields(Picture);
        CompanyInformation.Get();
        FormatAddress.Company(CompanyInformationArray, CompanyInformation);

        HomePageValueText := CompanyInformation."Home Page";
        HideLabelIfBlankValue(HomePageValueText, HomePageLbl, HomePageLabelText);

        EmailValueText := CompanyInformation."E-Mail";
        HideLabelIfBlankValue(EmailValueText, EmailLbl, EmailLabelText);

        PhoneNoValueText := CompanyInformation."Phone No.";
        HideLabelIfBlankValue(PhoneNoValueText, PhoneNoLbl, PhoneNoLabelText);

        BuildMultilineText(CompanyInformationArray, AllCompanyInformation);
    end;

    internal procedure ResolveCertificateContactInformation(DefaultTitle: Text; var ContactTitle: Text; var ContactName: Text; var ContactInformationArray: array[8] of Text[100]; var AllContactInformation: Text)
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Contact: Record Contact;
        FormatAddress: Codeunit "Format Address";
    begin
        ContactTitle := DefaultTitle;
        ContactName := '';

        QltyManagementSetup.Get();
        if QltyManagementSetup."Certificate Contact No." <> '' then
            if Contact.Get(QltyManagementSetup."Certificate Contact No.") then begin
                ContactName := Contact.Name;
                if Contact."Job Title" <> '' then
                    ContactTitle := Contact."Job Title";
                FormatAddress.ContactAddr(ContactInformationArray, Contact);
            end;

        BuildMultilineText(ContactInformationArray, AllContactInformation);
    end;

    internal procedure BuildItemTrackingText(LotNo: Text; SerialNo: Text; PackageNo: Text): Text
    var
        Result: TextBuilder;
        NewLine: Text[1];
    begin
        NewLine[1] := 10; // LF character for Word layout line breaks

        if LotNo <> '' then
            Result.Append(LotNo);

        if SerialNo <> '' then begin
            if Result.Length() > 0 then
                Result.Append(NewLine);
            Result.Append(SerialNo);
        end;

        if PackageNo <> '' then begin
            if Result.Length() > 0 then
                Result.Append(NewLine);
            Result.Append(PackageNo);
        end;

        exit(Result.ToText());
    end;

    internal procedure BuildItemDescriptionText(ItemNo: Text; VariantCode: Text; Description: Text): Text
    var
        Result: TextBuilder;
        NewLine: Text[1];
    begin
        NewLine[1] := 10; // LF character for Word layout line breaks

        if ItemNo <> '' then
            Result.Append(ItemNo);

        if VariantCode <> '' then begin
            if Result.Length() > 0 then
                Result.Append(' ');
            Result.Append(VariantCode);
        end;

        if Description <> '' then begin
            if Result.Length() > 0 then
                Result.Append(NewLine);
            Result.Append(Description);
        end;

        exit(Result.ToText());
    end;

    internal procedure BuildReinspectionSequenceInformationText(ReinspectionNo: Integer): Text
    var
        NewLine: Text[1];
    begin
        NewLine[1] := 10;

        if ReinspectionNo <> 0 then
            exit(NewLine + StrSubstNo(ReinspectionSequenceLbl, Format(ReinspectionNo)));

        exit('');
    end;

    internal procedure BuildInspectionInformationText(Status: Text; ResultDescription: Text): Text
    var
        Result: TextBuilder;
        NewLine: Text[1];
    begin
        NewLine[1] := 10;

        Result.Append(StrSubstNo(StatusLbl, Status));

        if ResultDescription <> '' then begin
            Result.Append(NewLine);
            Result.Append(StrSubstNo(ResultLbl, ResultDescription));
        end;

        exit(Result.ToText());
    end;

    local procedure HideLabelIfBlankValue(Value: Text; LabelText: Text; var OutputLabelText: Text)
    begin
        if Value <> '' then
            OutputLabelText := LabelText
        else
            OutputLabelText := '';
    end;

    local procedure BuildMultilineText(InTextToCombine: array[8] of Text[100]; var CombinedTextResult: Text)
    var
        IndexOfTextToCombine: Integer;
        CombinedText: TextBuilder;
    begin
        CombinedTextResult := '';

        for IndexOfTextToCombine := 1 to ArrayLen(InTextToCombine) do
            if InTextToCombine[IndexOfTextToCombine] <> '' then
                CombinedText.AppendLine(InTextToCombine[IndexOfTextToCombine]);

        CombinedTextResult := CombinedText.ToText();
    end;
    #endregion Helper methods
}
