// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Reports;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;
using System.Security.User;

report 20405 "Qlty. General Purpose Inspect."
{
    Caption = 'Quality Inspection - General Purpose Inspection Report';
    ToolTip = 'A printable general purpose inspection report.';
    AccessByPermission = tabledata "Qlty. Inspection Header" = R;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = QualityManagement;
    DefaultRenderingLayout = QltyInspection_GeneralPurposeInspection_Default;
    Extensible = true;
    WordMergeDataItem = CurrentInspection;

    dataset
    {
        dataitem(CurrentInspection; "Qlty. Inspection Header")
        {
            RequestFilterFields = "Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Package No.", "Source Document No.", "No.", "Re-inspection No.", "Template Code";
            column(QltyInspectionTemplate_Description; QltyInspectionTemplateHdr.Description) { }
            column(QltyInspection_Description; Description) { }
            column(QltyInspection_Status; Status) { }
            column(QltyInspection_Result_Code; "Result Code") { }
            column(QltyInspection_Result_Description; "Result Description") { }
            column(QltyInspection_No; CurrentInspection."No.") { }
            column(QltyInspection_ReinspectionNo; CurrentInspection."Re-inspection No.") { }
            column(QltyInspection_Finished_By_User_ID; "Finished By User ID") { }
            column(QltyInspection_Finished_By_UserName; FinishedByUserName) { }
            column(QltyInspection_Finished_By_Title; FinishedByUserName) { }
            column(QltyInspection_Finished_By_Email; FinishedByEmail) { }
            column(QltyInspection_Finished_By_Phone; FinishedByPhone) { }
            column(QltyInspection_Approver_Title; ApproverTitle) { }
            column(QltyInspection_Approver_Name; ApproverName) { }
            column(QltyInspection_Finished_Date; "Finished Date") { }
            column(QltyInspection_Source_Item_No_; "Source Item No.") { }
            column(QltyInspection_Source_Item_Description; Item.Description) { }
            column(QltyInspection_Source_Item_Description2; Item."Description 2") { }
            column(QltyInspection_Source_Variant_Code; "Source Variant Code") { }
            column(QltyInspection_Source_Lot_No_; "Source Lot No.") { }
            column(QltyInspection_Source_Serial_No_; "Source Serial No.") { }
            column(QltyInspection_Source_Package_No_; "Source Package No.") { }
            column(QltyInspection_Source_Document_No_; "Source Document No.") { }
            column(QltyInspection_Source_Task_No_; "Source Task No.") { }
            column(QltyInspection_Source_Custom_1; "Source Custom 1") { }
            column(QltyInspection_Source_Custom_2; "Source Custom 2") { }
            column(QltyInspection_Source_Custom_3; "Source Custom 3") { }
            column(QltyInspection_Source_Custom_4; "Source Custom 4") { }
            column(QltyInspection_Source_Custom_5; "Source Custom 5") { }
            column(QltyInspection_Source_Custom_6; "Source Custom 6") { }
            column(QltyInspection_Source_Custom_7; "Source Custom 7") { }
            column(QltyInspection_Source_Custom_8; "Source Custom 8") { }
            column(QltyInspection_Source_Custom_9; "Source Custom 9") { }
            column(QltyInspection_Source_Custom_10; "Source Custom 10") { }

            column(CompanyInformation_Row1; CompanyInformationArray[1]) { }
            column(CompanyInformation_Row2; CompanyInformationArray[2]) { }
            column(CompanyInformation_Row3; CompanyInformationArray[3]) { }
            column(CompanyInformation_Row4; CompanyInformationArray[4]) { }
            column(CompanyInformation_Row5; CompanyInformationArray[5]) { }
            column(CompanyInformation_Row6; CompanyInformationArray[6]) { }
            column(CompanyInformation_Row7; CompanyInformationArray[7]) { }
            column(CompanyInformation_Row8; CompanyInformationArray[8]) { }
            column(CompanyInformation_All; AllCompanyInformation) { }

            column(COAContact_Row1; ContactInformationArray[1]) { }
            column(COAContact_Row2; ContactInformationArray[2]) { }
            column(COAContact_Row3; ContactInformationArray[3]) { }
            column(COAContact_Row4; ContactInformationArray[4]) { }
            column(COAContact_Row5; ContactInformationArray[5]) { }
            column(COAContact_Row6; ContactInformationArray[6]) { }
            column(COAContact_Row7; ContactInformationArray[7]) { }
            column(COAContact_Row8; ContactInformationArray[8]) { }
            column(COAContact_All; AllContactInformation) { }

            // Pre-calculated columns for Word Layout
            column(ProductDescription; ProductDescriptionText) { }
            column(ItemTrackingDescription; ItemTrackingText) { }
            column(ReinspectionDescription; SequenceText) { }

            // Pre-calculated label columns for Word Layout
            column(FinishedBySignatureLabel; FinishedBySignatureLbl) { }
            column(FinishedByNameLabel; FinishedByNameLbl) { }
            column(ApproverSignatureLabel; ApproverSignatureLbl) { }
            column(ApproverNameLabel; ApproverNameLbl) { }
            column(FinishedDateOnly; FinishedDateOnly) { }
            column(HomePageLabel; HomePageLabelText) { }
            column(HomePageValue; HomePageValueText) { }
            column(EmailLabel; EmailLabelText) { }
            column(EmailValue; EmailValueText) { }
            column(PhoneNoLabel; PhoneNoLabelText) { }
            column(PhoneNoValue; PhoneNoValueText) { }
            column(CompanyLogo; DummyCompanyInfo.Picture) { }

            dataitem(CurrentInspectionLine; "Qlty. Inspection Line")
            {
                DataItemLink = "Inspection No." = field("No."), "Re-inspection No." = field("Re-inspection No.");
                RequestFilterFields = "Test Code";
                CalcFields = "Result Description";

                column(Field_Code; "Test Code") { }
                column(Field_Description; Description) { }
                column(Numeric_Value; "Derived Numeric Value") { }
                column(Field_Type; "Test Value Type") { }
                column(Field_IsLabel; FieldIsLabel) { }
                column(Field_HasEnteredValue; HasEnteredValue) { }
                column(Field_IsText; FieldIsText) { }
                column(Field_IsPersonField; IsPersonField) { }
                column(Field_IfPersonName; OptionalNameIfPerson) { }
                column(Field_IfPersonTitle; OptionalTitleIfPerson) { }
                column(Field_IfPersonEmail; OptionalEmailIfPerson) { }
                column(Field_IfPersonPhone; OptionalPhoneIfPerson) { }
                column(Field_ModifiedDateTime; CurrentInspectionLine.SystemModifiedAt) { }
                column(Field_ModifiedByUserID; InspectionLineModifiedByUserId) { }
                column(Field_ModifiedByUserName; InspectionLineModifiedByUserName) { }
                column(Field_ModifiedByUserJobTitle; InspectionLineModifiedByJobTitle) { }
                column(Field_ModifiedByUserEmail; InspectionLineModifiedByEmail) { }
                column(Field_ModifiedByUserPhone; InspectionLineModifiedByPhone) { }
                column(Field_EnteredByNameAndTimestamp; EnteredByNameAndTimestamp) { }

                column(Test_Value; TestValueText) { }
                column(Test_Result; "Result Code") { }
                column(Test_ResultDescription; ResultDescription) { }
                column(Field_LineCommentary; LineCommentaryText) { }
                column(PromptedResultCaption_1; MatrixArrayCaptionSet[1]) { }
                column(PromptedResultConditionDescription_1; MatrixArrayConditionDescriptionCellData[1]) { }
                column(PromptedResultVisible_1; MatrixVisibleState[1]) { }
                column(PromptedResultCaption_2; MatrixArrayCaptionSet[2]) { }
                column(PromptedResultConditionDescription_2; MatrixArrayConditionDescriptionCellData[2]) { }
                column(PromptedResultVisible_2; MatrixVisibleState[2]) { }
                column(PromptedResultCaption_3; MatrixArrayCaptionSet[3]) { }
                column(PromptedResultConditionDescription_3; MatrixArrayConditionDescriptionCellData[3]) { }
                column(PromptedResultVisible_3; MatrixVisibleState[3]) { }
                column(PromptedResultCaption_4; MatrixArrayCaptionSet[4]) { }
                column(PromptedResultConditionDescription_4; MatrixArrayConditionDescriptionCellData[4]) { }
                column(PromptedResultVisible_4; MatrixVisibleState[4]) { }
                column(PromptedResultCaption_5; MatrixArrayCaptionSet[5]) { }
                column(PromptedResultConditionDescription_5; MatrixArrayConditionDescriptionCellData[5]) { }
                column(PromptedResultVisible_5; MatrixVisibleState[5]) { }
                column(PromptedResultCaption_6; MatrixArrayCaptionSet[6]) { }
                column(PromptedResultConditionDescription_6; MatrixArrayConditionDescriptionCellData[6]) { }
                column(PromptedResultVisible_6; MatrixVisibleState[6]) { }
                column(PromptedResultCaption_7; MatrixArrayCaptionSet[7]) { }
                column(PromptedResultConditionDescription_7; MatrixArrayConditionDescriptionCellData[7]) { }
                column(PromptedResultVisible_7; MatrixVisibleState[7]) { }
                column(PromptedResultCaption_8; MatrixArrayCaptionSet[8]) { }
                column(PromptedResultConditionDescription_8; MatrixArrayConditionDescriptionCellData[8]) { }
                column(PromptedResultVisible_8; MatrixVisibleState[8]) { }
                column(PromptedResultCaption_9; MatrixArrayCaptionSet[9]) { }
                column(PromptedResultConditionDescription_9; MatrixArrayConditionDescriptionCellData[9]) { }
                column(PromptedResultVisible_9; MatrixVisibleState[9]) { }
                column(PromptedResultCaption_10; MatrixArrayCaptionSet[10]) { }
                column(PromptedResultConditionDescription_10; MatrixArrayConditionDescriptionCellData[10]) { }
                column(PromptedResultVisible_10; MatrixVisibleState[10]) { }
                column(LabelField_Description; LabelFieldDescription) { }
                column(CarriageReturnPersonFieldDetails; CarriageReturnPersonFieldDetails) { }

                // Pre-calculated columns for Word Layout - conditionally empty for row hiding
                column(WordDescription; WordDescription) { }
                column(WordTestValue; WordTestValue) { }
                column(WordModifiedDateTime; WordModifiedDateTime) { }
                column(WordModifiedByUserName; WordModifiedByUserName) { }
                column(IfPersonDescription; IfPersonDescription) { }
                column(IfPersonModifiedByUserEmail; IfPersonModifiedByUserEmail) { }
                column(IfPersonModifiedDateTime; IfPersonModifiedDateTime) { }
                // Pre-calculated condition label columns for Word Layout
                column(ConditionLabel_1; ConditionLabelText1) { }
                column(ConditionLabel_2; ConditionLabelText2) { }

                trigger OnAfterGetRecord()
                var
                    QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
                    QltyInspectionResult: Record "Qlty. Inspection Result";
                    QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
                    DummyRecordId: RecordId;
                    CombinedText: TextBuilder;
                    Caption: array[2] of Text;
                    Iterator: Integer;
                begin
                    Clear(MatrixSourceRecordId);
                    Clear(MatrixArrayConditionCellData);
                    Clear(MatrixArrayConditionDescriptionCellData);
                    Clear(MatrixArrayCaptionSet);
                    Clear(MatrixVisibleState);
                    ResultDescription := '';

                    InspectionLineModifiedByUserId := QltyMiscHelpers.GetUserNameByUserSecurityID(CurrentInspectionLine.SystemModifiedBy);
                    if InspectionLinePreviousModifiedByUserId <> InspectionLineModifiedByUserId then
                        QltyPersonLookup.GetBasicPersonDetails(InspectionLineModifiedByUserId, InspectionLineModifiedByUserName, InspectionLineModifiedByJobTitle, InspectionLineModifiedByEmail, InspectionLineModifiedByPhone, DummyRecordId);
                    InspectionLinePreviousModifiedByUserId := InspectionLineModifiedByUserId;

                    IsPersonField := QltyPersonLookup.GetBasicPersonDetailsFromInspectionLine(CurrentInspectionLine, OptionalNameIfPerson, OptionalTitleIfPerson, OptionalEmailIfPerson, OptionalPhoneIfPerson, DummyRecordId);

                    FieldIsLabel := CurrentInspectionLine."Test Value Type" in [CurrentInspectionLine."Test Value Type"::"Value Type Label"];
                    FieldIsText := CurrentInspectionLine."Test Value Type" in [CurrentInspectionLine."Test Value Type"::"Value Type Text"];

                    HasEnteredValue := not FieldIsLabel and
                        ((CurrentInspectionLine."Test Value" <> '') and (CurrentInspectionLine.SystemCreatedAt <> CurrentInspectionLine.SystemModifiedAt));

                    if HasEnteredValue then
                        EnteredByNameAndTimestamp := StrSubstNo(EnteredByNameAndTimestampLbl, InspectionLinePreviousModifiedByUserId, CurrentInspectionLine.SystemModifiedAt)
                    else
                        Clear(EnteredByNameAndTimestamp);

                    ResultDescription := CurrentInspectionLine."Result Description";
                    if ResultDescription = '' then
                        ResultDescription := CurrentInspectionLine."Result Code";
                    QltyResultConditionMgmt.GetPromotedResultsForInspectionLine(CurrentInspectionLine, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);

                    if FieldIsLabel then
                        LabelFieldDescription := CurrentInspectionLine.Description
                    else
                        LabelFieldDescription := '';

                    // Resolve pre-calculated condition label columns for Word Layout
                    Clear(Caption);
                    QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
                    QltyIResultConditConf.SetRange("Target Code", CurrentInspectionLine."Inspection No.");
                    QltyIResultConditConf.SetRange("Target Re-inspection No.", CurrentInspectionLine."Re-inspection No.");
                    QltyIResultConditConf.SetRange("Target Line No.", CurrentInspectionLine."Line No.");
                    QltyIResultConditConf.SetRange("Test Code", CurrentInspectionLine."Test Code");
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
                        ConditionLabelText1 := Caption[1] + ' ' + ConditionSuffixLbl
                    else
                        ConditionLabelText1 := '';

                    if Caption[2] <> '' then
                        ConditionLabelText2 := Caption[2] + ' ' + ConditionSuffixLbl
                    else
                        ConditionLabelText2 := '';

                    // Pre-calculated columns for Word Layout row hiding
                    // WordDescription: populated for normal and person fields, empty for labels
                    if not FieldIsLabel then begin
                        WordDescription := CurrentInspectionLine.Description;
                        WordModifiedDateTime := Format(CurrentInspectionLine.SystemModifiedAt);
                        WordModifiedByUserName := InspectionLineModifiedByUserName;
                    end else begin
                        WordDescription := '';
                        WordModifiedDateTime := '';
                        WordModifiedByUserName := '';
                    end;

                    // Person row: only populated when IsPersonField
                    if IsPersonField then begin
                        IfPersonDescription := CurrentInspectionLine.Description;
                        if HasEnteredValue then begin
                            IfPersonModifiedByUserEmail := InspectionLineModifiedByEmail;
                            IfPersonModifiedDateTime := Format(CurrentInspectionLine.SystemModifiedAt);
                        end else begin
                            IfPersonModifiedByUserEmail := '';
                            IfPersonModifiedDateTime := '';
                        end;
                    end else begin
                        IfPersonDescription := '';
                        IfPersonModifiedByUserEmail := '';
                        IfPersonModifiedDateTime := '';
                    end;

                    // WordTestValue: unified test value for Word layout - person details or normal value
                    if IsPersonField then begin
                        Clear(CombinedText);
                        CarriageReturnPersonFieldDetails := '';
                        if OptionalTitleIfPerson <> '' then
                            CombinedText.AppendLine(OptionalTitleIfPerson);
                        if OptionalNameIfPerson <> '' then
                            CombinedText.AppendLine(OptionalNameIfPerson);
                        if OptionalPhoneIfPerson <> '' then
                            CombinedText.AppendLine(OptionalPhoneIfPerson);
                        if OptionalEmailIfPerson <> '' then
                            CombinedText.AppendLine(OptionalEmailIfPerson);
                        CarriageReturnPersonFieldDetails := CombinedText.ToText();
                        TestValueText := CarriageReturnPersonFieldDetails;
                        WordTestValue := CarriageReturnPersonFieldDetails;
                    end else
                        if not FieldIsLabel then begin
                            CarriageReturnPersonFieldDetails := '';
                            TestValueText := CurrentInspectionLine.GetLargeText();
                            WordTestValue := TestValueText;
                        end else begin
                            CarriageReturnPersonFieldDetails := '';
                            TestValueText := CurrentInspectionLine.GetLargeText();
                            WordTestValue := '';
                        end;

                    // Pre-calculate LineCommentary ensuring truly empty string for HideTableRowIfEmpty
                    LineCommentaryText := CurrentInspectionLine.GetMeasurementNote();
                    if DelChr(LineCommentaryText, '=', ' ' + Format(10) + Format(13)) = '' then
                        LineCommentaryText := '';
                end;
            }

            trigger OnPreDataItem()
            var
                QltyManagementSetup: Record "Qlty. Management Setup";
                Contact: Record Contact;
                FormatAddress: Codeunit "Format Address";
            begin
                CompanyInformation.SetAutoCalcFields(Picture);
                CompanyInformation.Get();
                CompanyInformation.CalcFields(Picture);
                FormatAddress.Company(CompanyInformationArray, CompanyInformation);

                DummyCompanyInfo.Picture := CompanyInformation.Picture;

                // Resolve Company Information fields for Word Layout
                HomePageValueText := CompanyInformation."Home Page";
                EmailValueText := CompanyInformation."E-Mail";
                PhoneNoValueText := CompanyInformation."Phone No.";
                if HomePageValueText <> '' then
                    HomePageLabelText := HomePageLbl
                else
                    HomePageLabelText := '';
                if EmailValueText <> '' then
                    EmailLabelText := EmailLbl
                else
                    EmailLabelText := '';
                if PhoneNoValueText <> '' then
                    PhoneNoLabelText := PhoneNoLbl
                else
                    PhoneNoLabelText := '';

                ApproverTitle := DefaultApproverTitleLbl;
                ApproverName := '';

                QltyManagementSetup.Get();
                if QltyManagementSetup."Certificate Contact No." <> '' then
                    if Contact.Get(QltyManagementSetup."Certificate Contact No.") then begin
                        ApproverName := Contact.Name;
                        if Contact."Job Title" <> '' then
                            ApproverTitle := Contact."Job Title";
                        FormatAddress.ContactAddr(ContactInformationArray, Contact);
                    end;

                CombineToCarriageReturnString(CompanyInformationArray, AllCompanyInformation);
                CombineToCarriageReturnString(ContactInformationArray, AllContactInformation);
            end;

            trigger OnAfterGetRecord()
            var
                UserSetup: Record "User Setup";
                SalespersonPurchaser: Record "Salesperson/Purchaser";
                DummyRecordId: RecordId;
            begin
                if CurrentInspection."Source Item No." = '' then
                    Item.Reset()
                else
                    Item.Get(CurrentInspection."Source Item No.");

                if QltyInspectionTemplateHdr.Code <> CurrentInspection."Template Code" then begin
                    Clear(QltyInspectionTemplateHdr);
                    if QltyInspectionTemplateHdr.Get(CurrentInspection."Template Code") then;
                end;

                FinishedByUserName := CurrentInspection."Finished By User ID";
                QltyPersonLookup.GetBasicPersonDetails(CurrentInspection."Finished By User ID", FinishedByUserName, FinishedByTitle, FinishedByEmail, FinishedByPhone, DummyRecordId);
                if (FinishedByTitle = '') and (FinishedByUserName <> '') then
                    FinishedByTitle := DefaultQualityInspectorTitleLbl;

                // Pre-calculated columns for Word Layout
                // Resolve Product Text
                ProductDescriptionText := CurrentInspection."Source Item No.";
                if CurrentInspection."Source Variant Code" <> '' then
                    ProductDescriptionText += ' ' + CurrentInspection."Source Variant Code";
                if Item.Description <> '' then
                    ProductDescriptionText += ' ' + Item.Description;
                if Item."Description 2" <> '' then
                    ProductDescriptionText += ' ' + Item."Description 2";

                // Resolve Item Tracking
                ItemTrackingText := CurrentInspection."Source Lot No.";
                if CurrentInspection."Source Serial No." <> '' then begin
                    if ItemTrackingText <> '' then
                        ItemTrackingText += ' ';
                    ItemTrackingText += CurrentInspection."Source Serial No.";
                end;

                if CurrentInspection."Source Package No." <> '' then begin
                    if ItemTrackingText <> '' then
                        ItemTrackingText += ' ';
                    ItemTrackingText += CurrentInspection."Source Package No.";
                end;

                // Resolve job title for Finished By user via Salesperson/Purchaser
                FinishedByTitle := '';
                if CurrentInspection."Finished By User ID" <> '' then begin
                    if UserSetup.Get(CurrentInspection."Finished By User ID") then
                        if UserSetup."Salespers./Purch. Code" <> '' then
                            if SalespersonPurchaser.Get(UserSetup."Salespers./Purch. Code") then
                                FinishedByTitle := SalespersonPurchaser."Job Title";

                    if FinishedByTitle = '' then
                        FinishedByTitle := DefaultQualityInspectorTitleLbl;
                end;

                FinishedDateOnly := DT2Date(CurrentInspection."Finished Date");

                // Resolve Sequence
                SequenceText := SequenceLbl;
                SequenceText += ' ' + Format(CurrentInspection."Re-inspection No.");
                SequenceText += ' (' + Format(CurrentInspection.Status);
                SequenceText += ', ' + ResultLbl + ' ' + CurrentInspection."Result Description" + ')';

                // Resolve Finished By Signature Label
                FinishedBySignatureLbl := FinishedByTitle + ' ' + SignatureSuffixLbl;
                // Resolve Finished By Name
                FinishedByNameLbl := FinishedByTitle + ' ' + NameSuffixLbl;
                // Resolve Approver Signature Label
                ApproverSignatureLbl := ApproverTitle + ' ' + SignatureSuffixLbl;
                // Resolve Approver Name Label
                ApproverNameLbl := ApproverTitle + ' ' + NameSuffixLbl;
            end;
        }
    }

    rendering
    {
        layout(QltyInspection_GeneralPurposeInspection_Default)
        {
            Type = Word;
            Caption = 'Word Layout';
            Summary = 'Word layout for general purpose quality inspection report.';
            LayoutFile = './src/Reports/QltyGeneralPurposeInspection.docx';
        }
        layout(QltyGeneralPurposeInspectionDefault)
        {
            Type = RDLC;
            Caption = 'Default Layout';
            Summary = 'The default general purpose quality inspection report.';
            LayoutFile = './src/Reports/QltyGeneralPurposeInspectionAlternate.rdl';
        }
    }

    labels
    {
        TestDocumentNoLabel = 'Test Document No.';
        //MetricLabel = 'Metric';
        //MeasurementLabel = 'Measurement';
        ProductLabel = 'Product';
        ItemTrackingLabel = 'Item Tracking';
        DateLabel = 'Date';
        CompletedByLabel = 'Completed by';
        CompletedDateLabel = 'Completed on';
        ReportTitleLabel = 'General Purpose Inspection Report';
        ResultLabel = 'Result';
        //ConditionLabel = 'Condition';
        InspectionLabel = 'Inspection';
        FieldLabel = 'Field';
        LastModifiedByLabel = 'Last modified by';
    }

    var
        Item: Record Item;
        DummyCompanyInfo: Record "Company Information";
        CompanyInformation: Record "Company Information";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
        MatrixSourceRecordId: array[10] of RecordId;
        CompanyInformationArray: array[8] of Text[100];
        ContactInformationArray: array[8] of Text[100];
        ResultDescription: Text;
        MatrixArrayConditionCellData: array[10] of Text;
        MatrixArrayConditionDescriptionCellData: array[10] of Text;
        MatrixArrayCaptionSet: array[10] of Text;
        MatrixVisibleState: array[10] of Boolean;
        AllContactInformation: Text;
        AllCompanyInformation: Text;
        FieldIsLabel: Boolean;
        FieldIsText: Boolean;
        HasEnteredValue: Boolean;
        IsPersonField: Boolean;
        InspectionLineModifiedByUserId: Code[50];
        InspectionLinePreviousModifiedByUserId: Text;
        InspectionLineModifiedByUserName: Text;
        EnteredByNameAndTimestamp: Text;
        InspectionLineModifiedByJobTitle: Text;
        InspectionLineModifiedByPhone: Text;
        InspectionLineModifiedByEmail: Text;
        OptionalNameIfPerson: Text;
        OptionalTitleIfPerson: Text;
        OptionalEmailIfPerson: Text;
        OptionalPhoneIfPerson: Text;
        FinishedByUserName: Text;
        FinishedByTitle: Text;
        FinishedByEmail: Text;
        FinishedByPhone: Text;
        ApproverTitle: Text;
        ApproverName: Text;
        LabelFieldDescription: Text;
        CarriageReturnPersonFieldDetails: Text;
        ProductDescriptionText: Text;
        ItemTrackingText: Text;
        FinishedBySignatureLbl: Text;
        FinishedByNameLbl: Text;
        ApproverSignatureLbl: Text;
        ApproverNameLbl: Text;
        SequenceText: Text;
        FinishedDateOnly: Date;
        HomePageLabelText: Text;
        HomePageValueText: Text;
        EmailLabelText: Text;
        EmailValueText: Text;
        PhoneNoLabelText: Text;
        PhoneNoValueText: Text;
        ConditionLabelText1: Text;
        ConditionLabelText2: Text;
        WordDescription: Text;
        WordTestValue: Text;
        WordModifiedDateTime: Text;
        WordModifiedByUserName: Text;
        IfPersonDescription: Text;
        IfPersonModifiedByUserEmail: Text;
        IfPersonModifiedDateTime: Text;
        LineCommentaryText: Text;
        TestValueText: Text;
        NameSuffixLbl: Label 'Name';
        SignatureSuffixLbl: Label 'Signature';
        SequenceLbl: Label 'Sequence';
        ResultLbl: Label 'Result';
        HomePageLbl: Label 'Home Page';
        EmailLbl: Label 'E-Mail';
        PhoneNoLbl: Label 'Phone No.';
        ConditionSuffixLbl: Label 'Condition';
        DefaultApproverTitleLbl: Label 'Approver';
        DefaultQualityInspectorTitleLbl: Label 'Inspector';
        EnteredByNameAndTimestampLbl: Label '%1 %2', Locked = true;

    local procedure CombineToCarriageReturnString(var InTextToCombine: array[8] of Text[100]; var CombinedTextResult: Text)
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
}
