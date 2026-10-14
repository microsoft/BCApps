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
    /// <summary>
    /// Prints the configured general-purpose inspection report or the default report when none is configured.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection header to print.</param>
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

    /// <summary>
    /// Prints the configured non-conformance report or the default report when none is configured.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection header to print.</param>
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

    /// <summary>
    /// Prints the configured certificate of analysis report or the default report when none is configured.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection header to print.</param>
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

    /// <summary>
    /// Loads company information and prepares its address, contact values, labels, and combined display text.
    /// </summary>
    /// <param name="CompanyInformation">The company information record to load.</param>
    /// <param name="CompanyInformationArray">The formatted company address lines.</param>
    /// <param name="AllCompanyInformation">The combined nonblank company address lines.</param>
    /// <param name="HomePageValueText">The company home page value.</param>
    /// <param name="HomePageLbl">The label to use for a nonblank home page.</param>
    /// <param name="HomePageLabelText">The resolved home page label, or blank when the value is blank.</param>
    /// <param name="EmailValueText">The company email value.</param>
    /// <param name="EmailLbl">The label to use for a nonblank email address.</param>
    /// <param name="EmailLabelText">The resolved email label, or blank when the value is blank.</param>
    /// <param name="PhoneNoValueText">The company phone number value.</param>
    /// <param name="PhoneNoLbl">The label to use for a nonblank phone number.</param>
    /// <param name="PhoneNoLabelText">The resolved phone number label, or blank when the value is blank.</param>
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

    /// <summary>
    /// Resolves the configured certificate contact and prepares formatted contact text.
    /// </summary>
    /// <param name="DefaultTitle">The title to use when the contact has no job title.</param>
    /// <param name="ContactTitle">The resolved contact title.</param>
    /// <param name="ContactName">The resolved contact name.</param>
    /// <param name="ContactInformationArray">The formatted contact address lines.</param>
    /// <param name="AllContactInformation">The combined nonblank contact address lines.</param>
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

    /// <summary>
    /// Loads the source item for an inspection or clears the item record when no source item is specified.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection whose source item to resolve.</param>
    /// <param name="Item">The resolved item record.</param>
    internal procedure ResolveSourceItem(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var Item: Record Item)
    begin
        if QltyInspectionHeader."Source Item No." = '' then
            Item.Reset()
        else
            Item.Get(QltyInspectionHeader."Source Item No.");
    end;

#if not CLEAN29
    /// <summary>
    /// Refreshes the cached inspection template when its code differs from the requested code.
    /// </summary>
    /// <param name="TemplateCode">The template code to cache.</param>
    /// <param name="QltyInspectionTemplateHdr">The cached inspection template header.</param>
    [Obsolete('Unused by Word layouts. Used only by RDLC layouts, and will be removed with the RDLC layouts.', '29.0')]
    internal procedure ResolveInspectionTemplateCache(TemplateCode: Code[20]; var QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.")
    begin
        if QltyInspectionTemplateHdr.Code = TemplateCode then
            exit;

        Clear(QltyInspectionTemplateHdr);
        if QltyInspectionTemplateHdr.Get(TemplateCode) then;
    end;
#endif

    /// <summary>
    /// Resolves the name and contact details of the user who finished an inspection.
    /// </summary>
    /// <param name="FinishedByUserId">The user ID to resolve.</param>
    /// <param name="FinishedByUserName">The resolved user name.</param>
    /// <param name="FinishedByTitle">The resolved title, with a quality inspector fallback.</param>
    /// <param name="FinishedByEmail">The resolved email address.</param>
    /// <param name="FinishedByPhone">The resolved phone number.</param>
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

    /// <summary>
    /// Gets the job title of the salesperson or purchaser assigned to a user.
    /// </summary>
    /// <param name="UserId">The user ID to look up.</param>
    /// <returns>The assigned salesperson or purchaser job title, or blank when unavailable.</returns>
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

    /// <summary>
    /// Combines an item number and variant code on separate lines, omitting blank values.
    /// </summary>
    /// <param name="ItemNo">The item number.</param>
    /// <param name="VariantCode">The variant code.</param>
    /// <returns>The nonblank identifiers separated by a line feed.</returns>
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

    /// <summary>
    /// Combines lot, serial, and package numbers on separate lines, omitting blank values.
    /// </summary>
    /// <param name="LotNo">The lot number.</param>
    /// <param name="SerialNo">The serial number.</param>
    /// <param name="PackageNo">The package number.</param>
    /// <returns>The nonblank tracking identifiers separated by line feeds.</returns>
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

    /// <summary>
    /// Builds the labeled reinspection sequence text when the sequence number is nonzero.
    /// </summary>
    /// <param name="ReinspectionNo">The reinspection sequence number.</param>
    /// <returns>A line feed followed by the labeled sequence number, or blank for zero.</returns>
    internal procedure BuildReinspectionSequenceInformationText(ReinspectionNo: Integer): Text
    var
        NewLine: Text[1];
    begin
        NewLine[1] := 10;

        if ReinspectionNo <> 0 then
            exit(NewLine + StrSubstNo(ReinspectionSequenceLbl, Format(ReinspectionNo)));

        exit('');
    end;

    /// <summary>
    /// Builds signature and name labels from a title.
    /// </summary>
    /// <param name="Title">The title that prefixes both labels.</param>
    /// <param name="SignatureLbl">The resulting signature label.</param>
    /// <param name="NameLabelText">The resulting name label.</param>
    internal procedure BuildSignatureAndNameLabels(Title: Text; var SignatureLbl: Text; var NameLabelText: Text)
    begin
        SignatureLbl := Title + ' ' + SignatureSuffixLbl;
        NameLabelText := Title + ' ' + NameSuffixLbl;
    end;

    // --- Inspection line OnAfterGetRecord sequence ---

    /// <summary>
    /// Clears all promoted-result matrix values and visibility flags.
    /// </summary>
    /// <param name="MatrixSourceRecordId">The matrix source record IDs to clear.</param>
    /// <param name="MatrixArrayConditionCellData">The matrix condition values to clear.</param>
    /// <param name="MatrixArrayConditionDescriptionCellData">The matrix condition descriptions to clear.</param>
    /// <param name="MatrixArrayCaptionSet">The matrix captions to clear.</param>
    /// <param name="MatrixVisibleState">The matrix visibility flags to clear.</param>
    internal procedure ClearPromotedResultMatrix(var MatrixSourceRecordId: array[10] of RecordId; var MatrixArrayConditionCellData: array[10] of Text; var MatrixArrayConditionDescriptionCellData: array[10] of Text; var MatrixArrayCaptionSet: array[10] of Text; var MatrixVisibleState: array[10] of Boolean)
    begin
        Clear(MatrixSourceRecordId);
        Clear(MatrixArrayConditionCellData);
        Clear(MatrixArrayConditionDescriptionCellData);
        Clear(MatrixArrayCaptionSet);
        Clear(MatrixVisibleState);
    end;

    /// <summary>
    /// Resolves the modifying user and refreshes person details when the user changes.
    /// </summary>
    /// <param name="QltyInspectionLine">The inspection line whose modifying user to resolve.</param>
    /// <param name="PreviousUserId">The previously resolved user ID, updated to the current value.</param>
    /// <param name="ModifiedByUserId">The resolved modifying user ID.</param>
    /// <param name="UserName">The resolved user name.</param>
    /// <param name="JobTitle">The resolved job title.</param>
    /// <param name="Email">The resolved email address.</param>
    /// <param name="Phone">The resolved phone number.</param>
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

    /// <summary>
    /// Resolves person details from an inspection line and indicates whether the line contains a person value.
    /// </summary>
    /// <param name="QltyInspectionLine">The inspection line to inspect.</param>
    /// <param name="IsPersonField">Indicates whether the line contains a resolvable person value.</param>
    /// <param name="PersonName">The resolved person name.</param>
    /// <param name="PersonTitle">The resolved person title.</param>
    /// <param name="PersonEmail">The resolved person email address.</param>
    /// <param name="PersonPhone">The resolved person phone number.</param>
    internal procedure ResolveLinePersonDetails(var QltyInspectionLine: Record "Qlty. Inspection Line"; var IsPersonField: Boolean; var PersonName: Text; var PersonTitle: Text; var PersonEmail: Text; var PersonPhone: Text)
    var
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
        DummyRecordId: RecordId;
    begin
        IsPersonField := QltyPersonLookup.GetBasicPersonDetailsFromInspectionLine(QltyInspectionLine, PersonName, PersonTitle, PersonEmail, PersonPhone, DummyRecordId);
    end;

    /// <summary>
    /// Resolves label, text, and entered-value flags for an inspection line.
    /// </summary>
    /// <param name="QltyInspectionLine">The inspection line to evaluate.</param>
    /// <param name="FieldIsLabel">Indicates whether the test value type is label.</param>
    /// <param name="FieldIsText">Indicates whether the test value type is text.</param>
    /// <param name="HasEnteredValue">Indicates whether a nonlabel value was entered after creation.</param>
    internal procedure ResolveLineFieldTypeFlags(var QltyInspectionLine: Record "Qlty. Inspection Line"; var FieldIsLabel: Boolean; var FieldIsText: Boolean; var HasEnteredValue: Boolean)
    begin
        FieldIsLabel := QltyInspectionLine."Test Value Type" in [QltyInspectionLine."Test Value Type"::"Value Type Label"];
        FieldIsText := QltyInspectionLine."Test Value Type" in [QltyInspectionLine."Test Value Type"::"Value Type Text"];

        HasEnteredValue := not FieldIsLabel and
            ((QltyInspectionLine."Test Value" <> '') and (QltyInspectionLine.SystemCreatedAt <> QltyInspectionLine.SystemModifiedAt));
    end;

    /// <summary>
    /// Resolves the inspection-line result description and its promoted-result matrix.
    /// </summary>
    /// <param name="QltyInspectionLine">The inspection line whose results to resolve.</param>
    /// <param name="ResultDescription">The result description, falling back to the result code.</param>
    /// <param name="MatrixSourceRecordId">The promoted-result source record IDs.</param>
    /// <param name="MatrixArrayConditionCellData">The promoted-result condition values.</param>
    /// <param name="MatrixArrayConditionDescriptionCellData">The promoted-result condition descriptions.</param>
    /// <param name="MatrixArrayCaptionSet">The promoted-result captions.</param>
    /// <param name="MatrixVisibleState">The promoted-result visibility flags.</param>
    internal procedure ResolveLineResultAndMatrix(var QltyInspectionLine: Record "Qlty. Inspection Line"; var ResultDescription: Text; var MatrixSourceRecordId: array[10] of RecordId; var MatrixArrayConditionCellData: array[10] of Text; var MatrixArrayConditionDescriptionCellData: array[10] of Text; var MatrixArrayCaptionSet: array[10] of Text; var MatrixVisibleState: array[10] of Boolean)
    var
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
    begin
        ResultDescription := QltyInspectionLine."Result Description";
        if ResultDescription = '' then
            ResultDescription := QltyInspectionLine."Result Code";

        QltyResultConditionMgmt.GetPromotedResultsForInspectionLine(QltyInspectionLine, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);
    end;

    /// <summary>
    /// Resolves the description displayed for a label-type inspection line.
    /// </summary>
    /// <param name="QltyInspectionLine">The inspection line containing the description.</param>
    /// <param name="FieldIsLabel">Indicates whether the line is a label field.</param>
    /// <param name="LabelFieldDescription">The line description for a label field, or blank otherwise.</param>
    internal procedure ResolveLineLabelFieldDescription(var QltyInspectionLine: Record "Qlty. Inspection Line"; FieldIsLabel: Boolean; var LabelFieldDescription: Text)
    begin
        if FieldIsLabel then
            LabelFieldDescription := QltyInspectionLine.Description
        else
            LabelFieldDescription := '';
    end;

    /// <summary>
    /// Resolves labels for the two highest-priority promoted result conditions on an inspection line.
    /// </summary>
    /// <param name="QltyInspectionLine">The inspection line whose promoted conditions to resolve.</param>
    /// <param name="ConditionLabelText1">The first promoted condition label.</param>
    /// <param name="ConditionLabelText2">The second promoted condition label.</param>
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

    /// <summary>
    /// Combines nonblank person details into separate lines.
    /// </summary>
    /// <param name="Title">The person's title.</param>
    /// <param name="Name">The person's name.</param>
    /// <param name="Phone">The person's phone number.</param>
    /// <param name="Email">The person's email address.</param>
    /// <returns>The nonblank person details on separate lines.</returns>
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

    /// <summary>
    /// Combines nonblank person details into separate lines with labels for title and name.
    /// </summary>
    /// <param name="Title">The person's title.</param>
    /// <param name="Name">The person's name.</param>
    /// <param name="Phone">The person's phone number.</param>
    /// <param name="Email">The person's email address.</param>
    /// <returns>The nonblank person details on separate lines.</returns>
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

    /// <summary>
    /// Builds the entered-by user and timestamp text when the line has an entered value.
    /// </summary>
    /// <param name="UserId">The user ID to display.</param>
    /// <param name="ModifiedAt">The modification timestamp to display.</param>
    /// <param name="HasEnteredValue">Indicates whether an entered value exists.</param>
    /// <returns>The formatted user and timestamp, or blank when no value was entered.</returns>
    internal procedure BuildEnteredByNameAndTimestamp(UserId: Text; ModifiedAt: DateTime; HasEnteredValue: Boolean): Text
    begin
        if HasEnteredValue then
            exit(StrSubstNo(EnteredByNameAndTimestampLbl, UserId, ModifiedAt));
        exit('');
    end;

    // --- Low-level formatting utilities ---

    /// <summary>
    /// Sets an output label only when its associated value is nonblank.
    /// </summary>
    /// <param name="Value">The value whose presence controls the label.</param>
    /// <param name="LabelText">The label to use for a nonblank value.</param>
    /// <param name="OutputLabelText">The resolved label or blank text.</param>
    local procedure HideLabelIfBlankValue(Value: Text; LabelText: Text; var OutputLabelText: Text)
    begin
        if Value <> '' then
            OutputLabelText := LabelText
        else
            OutputLabelText := '';
    end;

    /// <summary>
    /// Combines nonblank array elements into separate lines.
    /// </summary>
    /// <param name="InTextToCombine">The text elements to combine.</param>
    /// <param name="CombinedTextResult">The combined nonblank elements.</param>
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
