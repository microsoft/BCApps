// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Reports;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Configuration.Result;
#if not CLEAN29
using Microsoft.QualityManagement.Configuration.Template;
#endif
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;
using System.Security.User;

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
        ConditionSuffixLbl: Label 'Condition';
        NameSuffixLbl: Label 'Name';
        SignatureSuffixLbl: Label 'Signature';
        TitleLbl: Label 'Title';
        NameLbl: Label 'Name';
        DefaultQualityInspectorTitleLbl: Label 'Quality Inspector';
        EnteredByNameAndTimestampLbl: Label '%1 %2', Locked = true;

    // --- Report PreSection: company and contact information ---

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

    // --- Inspection header OnAfterGetRecord sequence ---

    internal procedure ResolveSourceItem(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var Item: Record Item)
    begin
        if QltyInspectionHeader."Source Item No." = '' then
            Item.Reset()
        else
            Item.Get(QltyInspectionHeader."Source Item No.");
    end;

#if not CLEAN29
    [Obsolete('Unused by Word layouts. Used only by RDLC layouts, and will be removed with the RDLC layouts.', '29.0')]
    internal procedure ResolveInspectionTemplateCache(TemplateCode: Code[20]; var QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.")
    begin
        if QltyInspectionTemplateHdr.Code = TemplateCode then
            exit;

        Clear(QltyInspectionTemplateHdr);
        if QltyInspectionTemplateHdr.Get(TemplateCode) then;
    end;
#endif

    internal procedure ResolveFinishedByPerson(FinishedByUserId: Code[50]; var FinishedByUserName: Text; var FinishedByTitle: Text; var FinishedByEmail: Text; var FinishedByPhone: Text)
    var
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
        DummyRecordId: RecordId;
    begin
        FinishedByUserName := FinishedByUserId;
        QltyPersonLookup.GetBasicPersonDetails(FinishedByUserId, FinishedByUserName, FinishedByTitle, FinishedByEmail, FinishedByPhone, DummyRecordId);

        if (FinishedByTitle = '') and (FinishedByUserName <> '') then
            FinishedByTitle := DefaultQualityInspectorTitleLbl;

        if (FinishedByTitle = '') and (FinishedByUserId <> '') then begin
            FinishedByTitle := GetSalespersonJobTitleForUser(FinishedByUserId);
            if FinishedByTitle = '' then
                FinishedByTitle := DefaultQualityInspectorTitleLbl;
        end;
    end;

    local procedure GetSalespersonJobTitleForUser(UserId: Code[50]): Text
    var
        UserSetup: Record "User Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        if not UserSetup.Get(UserId) then
            exit('');
        if UserSetup."Salespers./Purch. Code" = '' then
            exit('');
        if not SalespersonPurchaser.Get(UserSetup."Salespers./Purch. Code") then
            exit('');
        exit(SalespersonPurchaser."Job Title");
    end;

    internal procedure BuildItemIdentifierText(ItemNo: Text; VariantCode: Text): Text
    var
        Result: TextBuilder;
        NewLine: Text[1];
    begin
        NewLine[1] := 10; // LF character for Word layout line breaks

        if ItemNo <> '' then
            Result.Append(ItemNo);

        if VariantCode <> '' then begin
            if Result.Length() > 0 then
                Result.Append(NewLine);
            Result.Append(VariantCode);
        end;

        exit(Result.ToText());
    end;

    internal procedure BuildItemTrackingIdentifierText(LotNo: Text; SerialNo: Text; PackageNo: Text): Text
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

    internal procedure BuildReinspectionSequenceInformationText(ReinspectionNo: Integer): Text
    var
        NewLine: Text[1];
    begin
        NewLine[1] := 10;

        if ReinspectionNo <> 0 then
            exit(NewLine + StrSubstNo(ReinspectionSequenceLbl, Format(ReinspectionNo)));

        exit('');
    end;

    internal procedure BuildSignatureAndNameLabels(Title: Text; var SignatureLbl: Text; var NameLabelText: Text)
    begin
        SignatureLbl := Title + ' ' + SignatureSuffixLbl;
        NameLabelText := Title + ' ' + NameSuffixLbl;
    end;

    // --- Inspection line OnAfterGetRecord sequence ---

    internal procedure ClearPromotedResultMatrix(var MatrixSourceRecordId: array[10] of RecordId; var MatrixArrayConditionCellData: array[10] of Text; var MatrixArrayConditionDescriptionCellData: array[10] of Text; var MatrixArrayCaptionSet: array[10] of Text; var MatrixVisibleState: array[10] of Boolean)
    begin
        Clear(MatrixSourceRecordId);
        Clear(MatrixArrayConditionCellData);
        Clear(MatrixArrayConditionDescriptionCellData);
        Clear(MatrixArrayCaptionSet);
        Clear(MatrixVisibleState);
    end;

    internal procedure ResolveModifiedByUser(var QltyInspectionLine: Record "Qlty. Inspection Line"; var PreviousUserId: Text; var ModifiedByUserId: Code[50]; var UserName: Text; var JobTitle: Text; var Email: Text; var Phone: Text)
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
        DummyRecordId: RecordId;
    begin
        ModifiedByUserId := QltyMiscHelpers.GetUserNameByUserSecurityID(QltyInspectionLine.SystemModifiedBy);
        if PreviousUserId <> ModifiedByUserId then
            QltyPersonLookup.GetBasicPersonDetails(ModifiedByUserId, UserName, JobTitle, Email, Phone, DummyRecordId);
        PreviousUserId := ModifiedByUserId;
    end;

    internal procedure ResolveLinePersonDetails(var QltyInspectionLine: Record "Qlty. Inspection Line"; var IsPersonField: Boolean; var PersonName: Text; var PersonTitle: Text; var PersonEmail: Text; var PersonPhone: Text)
    var
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
        DummyRecordId: RecordId;
    begin
        IsPersonField := QltyPersonLookup.GetBasicPersonDetailsFromInspectionLine(QltyInspectionLine, PersonName, PersonTitle, PersonEmail, PersonPhone, DummyRecordId);
    end;

    internal procedure ResolveLineFieldTypeFlags(var QltyInspectionLine: Record "Qlty. Inspection Line"; var FieldIsLabel: Boolean; var FieldIsText: Boolean; var HasEnteredValue: Boolean)
    begin
        FieldIsLabel := QltyInspectionLine."Test Value Type" in [QltyInspectionLine."Test Value Type"::"Value Type Label"];
        FieldIsText := QltyInspectionLine."Test Value Type" in [QltyInspectionLine."Test Value Type"::"Value Type Text"];

        HasEnteredValue := not FieldIsLabel and
            ((QltyInspectionLine."Test Value" <> '') and (QltyInspectionLine.SystemCreatedAt <> QltyInspectionLine.SystemModifiedAt));
    end;

    internal procedure ResolveLineResultAndMatrix(var QltyInspectionLine: Record "Qlty. Inspection Line"; var ResultDescription: Text; var MatrixSourceRecordId: array[10] of RecordId; var MatrixArrayConditionCellData: array[10] of Text; var MatrixArrayConditionDescriptionCellData: array[10] of Text; var MatrixArrayCaptionSet: array[10] of Text; var MatrixVisibleState: array[10] of Boolean)
    var
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
    begin
        ResultDescription := QltyInspectionLine."Result Description";
        if ResultDescription = '' then
            ResultDescription := QltyInspectionLine."Result Code";

        QltyResultConditionMgmt.GetPromotedResultsForInspectionLine(QltyInspectionLine, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);
    end;

    internal procedure ResolveLineLabelFieldDescription(var QltyInspectionLine: Record "Qlty. Inspection Line"; FieldIsLabel: Boolean; var LabelFieldDescription: Text)
    begin
        if FieldIsLabel then
            LabelFieldDescription := QltyInspectionLine.Description
        else
            LabelFieldDescription := '';
    end;

    internal procedure ResolveConditionLabels(QltyInspectionLine: Record "Qlty. Inspection Line"; var ConditionLabelText1: Text; var ConditionLabelText2: Text)
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionResult: Record "Qlty. Inspection Result";
        Caption: array[2] of Text;
        Iterator: Integer;
    begin
        ConditionLabelText1 := '';
        ConditionLabelText2 := '';

        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
        QltyIResultConditConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        QltyIResultConditConf.SetRange("Target Re-inspection No.", QltyInspectionLine."Re-inspection No.");
        QltyIResultConditConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        QltyIResultConditConf.SetRange("Test Code", QltyInspectionLine."Test Code");
        QltyIResultConditConf.SetRange("Result Visibility", QltyIResultConditConf."Result Visibility"::Promoted);
        QltyIResultConditConf.SetCurrentKey("Condition Type", "Result Visibility", Priority, "Target Code", "Target Re-inspection No.", "Target Line No.");
        QltyIResultConditConf.Ascending(false);
        Iterator := 0;
        if QltyIResultConditConf.FindSet() then
            repeat
                if QltyInspectionResult.Get(QltyIResultConditConf."Result Code") then begin
                    Iterator += 1;
                    if Iterator <= 2 then
                        if QltyInspectionResult.Description <> '' then
                            Caption[Iterator] := QltyInspectionResult.Description
                        else
                            Caption[Iterator] := QltyInspectionResult.Code;
                end;
            until (QltyIResultConditConf.Next() = 0) or (Iterator >= 2);

        if Caption[1] <> '' then
            ConditionLabelText1 := Caption[1] + ' ' + ConditionSuffixLbl;

        if Caption[2] <> '' then
            ConditionLabelText2 := Caption[2] + ' ' + ConditionSuffixLbl;
    end;

    internal procedure BuildPersonFieldDetails(Title: Text; Name: Text; Phone: Text; Email: Text): Text
    var
        CombinedText: TextBuilder;
    begin
        if Title <> '' then
            CombinedText.AppendLine(Title);
        if Name <> '' then
            CombinedText.AppendLine(Name);
        if Phone <> '' then
            CombinedText.AppendLine(Phone);
        if Email <> '' then
            CombinedText.AppendLine(Email);
        exit(CombinedText.ToText());
    end;

    internal procedure BuildPersonFieldDetailsLabeled(Title: Text; Name: Text; Phone: Text; Email: Text): Text
    var
        CombinedText: TextBuilder;
    begin
        if Title <> '' then
            CombinedText.AppendLine(TitleLbl + ': ' + Title);
        if Name <> '' then
            CombinedText.AppendLine(NameLbl + ': ' + Name);
        if Phone <> '' then
            CombinedText.AppendLine(Phone);
        if Email <> '' then
            CombinedText.AppendLine(Email);
        exit(CombinedText.ToText());
    end;

    internal procedure BuildEnteredByNameAndTimestamp(UserId: Text; ModifiedAt: DateTime; HasEnteredValue: Boolean): Text
    begin
        if HasEnteredValue then
            exit(StrSubstNo(EnteredByNameAndTimestampLbl, UserId, ModifiedAt));
        exit('');
    end;

    // --- Low-level formatting utilities ---

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
