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

        CombineToCarriageReturnString(CompanyInformationArray, AllCompanyInformation);
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

        CombineToCarriageReturnString(ContactInformationArray, AllContactInformation);
    end;

    internal procedure BuildItemTrackingText(LotNo: Text; SerialNo: Text; PackageNo: Text): Text
    var
        Result: TextBuilder;
    begin
        if LotNo <> '' then
            Result.Append(LotNo);
        if SerialNo <> '' then begin
            if Result.Length() > 0 then
                Result.Append(' ');
            Result.Append(SerialNo);
        end;
        if PackageNo <> '' then begin
            if Result.Length() > 0 then
                Result.Append(' ');
            Result.Append(PackageNo);
        end;

        exit(Result.ToText());
    end;

    internal procedure BuildItemDescriptionText(ItemNo: Text; VariantCode: Text; Description: Text; Description2: Text): Text
    var
        Result: TextBuilder;
    begin
        if ItemNo <> '' then
            Result.Append(ItemNo);
        if VariantCode <> '' then begin
            if Result.Length() > 0 then
                Result.Append(' ');
            Result.Append(VariantCode);
        end;
        if Description <> '' then begin
            if Result.Length() > 0 then
                Result.Append(' ');
            Result.Append(Description);
        end;
        if Description2 <> '' then begin
            if Result.Length() > 0 then
                Result.Append(' ');
            Result.Append(Description2);
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

    local procedure CombineToCarriageReturnString(InTextToCombine: array[8] of Text[100]; var CombinedTextResult: Text)
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
