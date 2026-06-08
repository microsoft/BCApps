// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Telemetry;

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
            column(QltyInspectionTemplate_Description; QltyInspectionTemplateHdr.Description) { } // CLEAN
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
            column(ReinspectionSequenceInformation; QltyReportMgmt.BuildReinspectionSequenceInformationText(CurrentInspection."Re-inspection No.")) { }
            column(ItemIdentifier; QltyReportMgmt.BuildItemIdentifierText(CurrentInspection."Source Item No.", CurrentInspection."Source Variant Code")) { }
            column(ItemDescription; Item.Description) { }
            column(ItemTrackingIdentifier; ItemTrackingText) { }

            // Pre-calculated label columns for Word Layout
            column(CompanyLogo; CompanyInformation.Picture) { }
            column(HomePageLabel; HomePageLabelText) { }
            column(HomePageValue; HomePageValueText) { }
            column(EmailLabel; EmailLabelText) { }
            column(EmailValue; EmailValueText) { }
            column(PhoneNoLabel; PhoneNoLabelText) { }
            column(PhoneNoValue; PhoneNoValueText) { }
            column(FinishedBySignatureLabel; FinishedBySignatureLbl) { }
            column(FinishedByNameLabel; FinishedByNameLbl) { }
            column(ApproverSignatureLabel; ApproverSignatureLbl) { }
            column(ApproverNameLabel; ApproverNameLbl) { }

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
                begin
                    QltyReportMgmt.ClearPromotedResultMatrix(MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);
                    QltyReportMgmt.ResolveModifiedByUser(CurrentInspectionLine, InspectionLinePreviousModifiedByUserId, InspectionLineModifiedByUserId, InspectionLineModifiedByUserName, InspectionLineModifiedByJobTitle, InspectionLineModifiedByEmail, InspectionLineModifiedByPhone);
                    QltyReportMgmt.ResolveLinePersonDetails(CurrentInspectionLine, IsPersonField, OptionalNameIfPerson, OptionalTitleIfPerson, OptionalEmailIfPerson, OptionalPhoneIfPerson);
                    QltyReportMgmt.ResolveLineFieldTypeFlags(CurrentInspectionLine, FieldIsLabel, FieldIsText, HasEnteredValue);
                    QltyReportMgmt.ResolveLineResultAndMatrix(CurrentInspectionLine, ResultDescription, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);
                    QltyReportMgmt.ResolveLineLabelFieldDescription(CurrentInspectionLine, FieldIsLabel, LabelFieldDescription);

                    EnteredByNameAndTimestamp := QltyReportMgmt.BuildEnteredByNameAndTimestamp(InspectionLinePreviousModifiedByUserId, CurrentInspectionLine.SystemModifiedAt, HasEnteredValue);

                    // Resolve pre-calculated condition label columns for Word Layout
                    QltyReportMgmt.ResolveConditionLabels(CurrentInspectionLine, ConditionLabelText1, ConditionLabelText2);

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
                        CarriageReturnPersonFieldDetails := QltyReportMgmt.BuildPersonFieldDetails(OptionalTitleIfPerson, OptionalNameIfPerson, OptionalPhoneIfPerson, OptionalEmailIfPerson);
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
            begin
                QltyReportMgmt.ResolveCompanyInformation(CompanyInformation, CompanyInformationArray, AllCompanyInformation, HomePageValueText, HomePageLbl, HomePageLabelText, EmailValueText, EmailLbl, EmailLabelText, PhoneNoValueText, PhoneNoLbl, PhoneNoLabelText);

                QltyReportMgmt.ResolveCertificateContactInformation(DefaultApproverTitleLbl, ApproverTitle, ApproverName, ContactInformationArray, AllContactInformation);
            end;

            trigger OnAfterGetRecord()
            begin
                QltyReportMgmt.ResolveSourceItem(CurrentInspection, Item);
                QltyReportMgmt.ResolveInspectionTemplateCache(CurrentInspection."Template Code", QltyInspectionTemplateHdr);
                QltyReportMgmt.ResolveFinishedByPerson(CurrentInspection."Finished By User ID", FinishedByUserName, FinishedByTitle, FinishedByEmail, FinishedByPhone);

                ItemTrackingText := QltyReportMgmt.BuildItemTrackingIdentifierText(CurrentInspection."Source Lot No.", CurrentInspection."Source Serial No.", CurrentInspection."Source Package No.");

                QltyReportMgmt.BuildSignatureAndNameLabels(FinishedByTitle, FinishedBySignatureLbl, FinishedByNameLbl);
                QltyReportMgmt.BuildSignatureAndNameLabels(ApproverTitle, ApproverSignatureLbl, ApproverNameLbl);
            end;
        }
    }

    rendering
    {
        layout(QltyInspection_GeneralPurposeInspection_Default)
        {
            Type = Word;
            Caption = 'General Purpose Inspection Report (Word)';
            Summary = 'Built in layout for General Purpose Inspection report.';
            LayoutFile = './src/Reports/QltyGeneralPurposeInspection.docx';
        }
        layout(QltyGeneralPurposeInspectionDefault)
        {
            Type = RDLC;
            Caption = 'General Purpose Inspection Report (RDLC)';
            Summary = 'Built in layout for General Purpose Inspection report.';
            LayoutFile = './src/Reports/QltyGeneralPurposeInspectionAlternate.rdl';
        }
    }

    labels
    {
        PageLabel = 'Page';
        ReportTitleLabel = 'Quality Inspection Report';
        ItemLabel = 'Item';
        ItemDescriptionLabel = 'Item Description';
        ItemTrackingLabel = 'Item Tracking';
        FinishedByLabel = 'Finished by';
        FinishedOnLabel = 'Finished on';
        TestLabel = 'Test';
        TestValueLabel = 'Test Value';
        ResultLabel = 'Result';
        InspectionLabel = 'Inspection';
        InspectionDescriptionLabel = 'Inspection Description';
        StatusLabel = 'Status';
        DateLabel = 'Date';
        LastModifiedByLabel = 'Last modified by';
    }

    trigger OnPreReport()
    var
        QltyMgmtFeatureTelemetry: Codeunit "Qlty. Mgmt. Feature Telemetry";
    begin
        QltyMgmtFeatureTelemetry.LogFeatureUsage(ObjectType::Report, Report::"Qlty. General Purpose Inspect.", 'Print report General Purpose Inspection');
    end;

    var
        Item: Record Item;
        CompanyInformation: Record "Company Information";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyReportMgmt: Codeunit "Qlty. Report Mgmt.";
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
        ItemTrackingText: Text;
        FinishedBySignatureLbl: Text;
        FinishedByNameLbl: Text;
        ApproverSignatureLbl: Text;
        ApproverNameLbl: Text;
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
        HomePageLbl: Label 'Home Page';
        EmailLbl: Label 'E-Mail';
        PhoneNoLbl: Label 'Phone No.';
        DefaultApproverTitleLbl: Label 'Approver';
}
