// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Reports;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;

report 20401 "Qlty. Certificate of Analysis"
{
    ApplicationArea = QualityManagement;
    UsageCategory = ReportsAndAnalysis;
    Caption = 'Quality Management - Certificate of Analysis';
    DefaultRenderingLayout = QltyCertificateOfAnalysisDefault;
    Extensible = true;
    AdditionalSearchTerms = 'COA,Cert of Analysis,Test Report,Inspection Report,Quality Test Report,Printable Tests,Printable Certificate';

    dataset
    {
        dataitem(CurrentInspection; "Qlty. Inspection Header")
        {
            RequestFilterFields = "Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Document No.", "No.", "Reinspection No.", "Template Code";
            column(QltyInspectionTemplate_Description; QltyInspectionTemplateHdr.Description) { }
            column(QltyInspection_Description; Description) { }
            column(QltyInspection_Status; Status) { }
            column(QltyInspection_Grade_Code; "Grade Code") { }
            column(QltyInspection_Grade_Description; "Grade Description") { }
            column(QltyInspection_No; CurrentInspection."No.") { }
            column(QltyInspection_ReinspectionNo; CurrentInspection."Reinspection No.") { }
            column(QltyInspection_Finished_By_User_ID; "Finished By User ID") { }
            column(QltyInspection_Finished_By_UserName; FinishedByUserName) { }
            column(QltyInspection_Finished_By_Title; FinishedByUserName) { }
            column(QltyInspection_Finished_By_Email; FinishedByEmail) { }
            column(QltyInspection_Finished_By_Phone; FinishedByPhone) { }
            column(QltyInspection_Director_Title; DirectorTitle) { }
            column(QltyInspection_Director_Name; DirectorName) { }
            column(QltyInspection_Finished_Date; "Finished Date") { }
            column(QltyInspection_Source_Item_No_; "Source Item No.") { }
            column(QltyInspection_Source_Item_Description; Item.Description) { }
            column(QltyInspection_Source_Item_Description2; Item."Description 2") { }
            column(QltyInspection_Source_Variant_Code; "Source Variant Code") { }
            column(QltyInspection_Source_Lot_No_; "Source Lot No.") { }
            column(QltyInspection_Source_Serial_No_; "Source Serial No.") { }
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

            dataitem(CurrentInspectionLine; "Qlty. Inspection Line")
            {
                DataItemLink = "Inspection No." = field("No."), "Reinspection No." = field("Reinspection No.");
                RequestFilterFields = "Field Code";
                CalcFields = "Grade Description";

                column(Field_Code; "Field Code") { }
                column(Field_Description; Description) { }
                column(Numeric_Value; "Numeric Value") { }
                column(Field_Type; "Field Type") { }
                column(Field_IsLabel; FieldIsLabel) { }
                column(Field_HasEnteredValue; HasEnteredValue) { }
                column(Field_IsText; FieldIsText) { }
                column(Field_IsPersonField; IsPersonField) { }
                column(Field_IfPersonName; OptionalNameIfPerson) { }
                column(Field_IfPersonTitle; OptionalTitleIfPerson) { }
                column(Field_IfPersonEmail; OptionalEmailIfPerson) { }
                column(Field_IfPersonPhone; OptionalPhoneIfPerson) { }
                column(Field_ModifiedDateTime; CurrentInspectionLine.SystemModifiedAt) { }
                column(Field_ModifiedByUserID; TestLineModifiedByUserId) { }
                column(Field_ModifiedByUserName; TestLineModifiedByUserName) { }
                column(Field_ModifiedByUserJobTitle; TestLineModifiedByJobTitle) { }
                column(Field_ModifiedByUserEmail; TestLineModifiedByEmail) { }
                column(Field_ModifiedByUserPhone; TestLineModifiedByPhone) { }
                column(Test_Value; CurrentInspectionLine.GetLargeText()) { }
                column(Test_Grade; "Grade Code") { }
                column(Test_GradeDescription; GradeDescription) { }
                column(Field_LineCommentary; CurrentInspectionLine.GetMeasurementNote()) { }
                column(PromptedGradeCaption_1; MatrixArrayCaptionSet[1])
                {
                }
                column(PromptedGradeConditionDescription_1; MatrixArrayConditionDescriptionCellData[1])
                {
                }
                column(PromptedGradeVisible_1; MatrixVisibleState[1])
                {
                }
                column(PromptedGradeCaption_2; MatrixArrayCaptionSet[2])
                {
                }
                column(PromptedGradeConditionDescription_2; MatrixArrayConditionDescriptionCellData[2])
                {
                }
                column(PromptedGradeVisible_2; MatrixVisibleState[2])
                {
                }
                column(PromptedGradeCaption_3; MatrixArrayCaptionSet[3])
                {
                }
                column(PromptedGradeConditionDescription_3; MatrixArrayConditionDescriptionCellData[3])
                {
                }
                column(PromptedGradeVisible_3; MatrixVisibleState[3])
                {
                }
                column(PromptedGradeCaption_4; MatrixArrayCaptionSet[4])
                {
                }
                column(PromptedGradeConditionDescription_4; MatrixArrayConditionDescriptionCellData[4])
                {
                }
                column(PromptedGradeVisible_4; MatrixVisibleState[4])
                {
                }
                column(PromptedGradeCaption_5; MatrixArrayCaptionSet[5])
                {
                }
                column(PromptedGradeConditionDescription_5; MatrixArrayConditionDescriptionCellData[5])
                {
                }
                column(PromptedGradeVisible_5; MatrixVisibleState[5])
                {
                }
                column(PromptedGradeCaption_6; MatrixArrayCaptionSet[6])
                {
                }
                column(PromptedGradeConditionDescription_6; MatrixArrayConditionDescriptionCellData[6])
                {
                }
                column(PromptedGradeVisible_6; MatrixVisibleState[6])
                {
                }
                column(PromptedGradeCaption_7; MatrixArrayCaptionSet[7])
                {
                }
                column(PromptedGradeConditionDescription_7; MatrixArrayConditionDescriptionCellData[7])
                {
                }
                column(PromptedGradeVisible_7; MatrixVisibleState[7])
                {
                }
                column(PromptedGradeCaption_8; MatrixArrayCaptionSet[8])
                {
                }
                column(PromptedGradeConditionDescription_8; MatrixArrayConditionDescriptionCellData[8])
                {
                }
                column(PromptedGradeVisible_8; MatrixVisibleState[8])
                {
                }
                column(PromptedGradeCaption_9; MatrixArrayCaptionSet[9])
                {
                }
                column(PromptedGradeConditionDescription_9; MatrixArrayConditionDescriptionCellData[9])
                {
                }
                column(PromptedGradeVisible_9; MatrixVisibleState[9])
                {
                }
                column(PromptedGradeCaption_10; MatrixArrayCaptionSet[10])
                {
                }
                column(PromptedGradeConditionDescription_10; MatrixArrayConditionDescriptionCellData[10])
                {
                }
                column(PromptedGradeVisible_10; MatrixVisibleState[10])
                {
                }
                column(LabelField_Description; LabelFieldDescription)
                {
                }

                trigger OnAfterGetRecord()
                var
                    QltyGradeConditionMgmt: Codeunit "Qlty. Grade Condition Mgmt.";
                    DummyRecordId: RecordId;
                begin
                    Clear(MatrixSourceRecordId);
                    Clear(MatrixArrayConditionCellData);
                    Clear(MatrixArrayConditionDescriptionCellData);
                    Clear(MatrixArrayCaptionSet);
                    Clear(MatrixVisibleState);
                    GradeDescription := '';

                    TestLineModifiedByUserId := QltyMiscHelpers.GetUserNameByUserSecurityID(CurrentInspectionLine.SystemModifiedBy);
                    if TestLinePreviousModifiedByUserId <> TestLineModifiedByUserId then
                        QltyMiscHelpers.GetBasicPersonDetails(TestLineModifiedByUserId, TestLineModifiedByUserName, TestLineModifiedByJobTitle, TestLineModifiedByEmail, TestLineModifiedByPhone, DummyRecordId);
                    TestLinePreviousModifiedByUserId := TestLineModifiedByUserId;

                    IsPersonField := QltyMiscHelpers.GetBasicPersonDetailsFromTestLine(CurrentInspectionLine, OptionalNameIfPerson, OptionalTitleIfPerson, OptionalEmailIfPerson, OptionalPhoneIfPerson, DummyRecordId);

                    FieldIsLabel := CurrentInspectionLine."Field Type" in [CurrentInspectionLine."Field Type"::"Field Type Label"];
                    FieldIsText := CurrentInspectionLine."Field Type" in [CurrentInspectionLine."Field Type"::"Field Type Text"];

                    HasEnteredValue := not FieldIsLabel and
                        ((CurrentInspectionLine."Test Value" <> '') and (CurrentInspectionLine.SystemCreatedAt <> CurrentInspectionLine.SystemModifiedAt));

                    GradeDescription := CurrentInspectionLine."Grade Description";
                    if GradeDescription = '' then
                        GradeDescription := CurrentInspectionLine."Grade Code";
                    QltyGradeConditionMgmt.GetPromotedGradesForTestLine(CurrentInspectionLine, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);

                    if FieldIsLabel then
                        LabelFieldDescription := CurrentInspectionLine.Description
                    else
                        LabelFieldDescription := '';
                end;
            }

            trigger OnPreDataItem()
            var
                QltyManagementSetup: Record "Qlty. Management Setup";
                CompanyInformation: Record "Company Information";
                Contact: Record Contact;
                FormatAddress: Codeunit "Format Address";
            begin
                CompanyInformation.Get();
                FormatAddress.Company(CompanyInformationArray, CompanyInformation);

                DirectorTitle := DefaultDirectorTitleLbl;
                DirectorName := '';

                QltyManagementSetup.Get();
                if QltyManagementSetup."Certificate Contact No." <> '' then
                    if Contact.Get(QltyManagementSetup."Certificate Contact No.") then begin
                        DirectorName := Contact.Name;
                        DirectorTitle := Contact."Job Title";
                        FormatAddress.ContactAddr(ContactInformationArray, Contact);
                    end;

                CombineToCarriageReturnString(CompanyInformationArray, AllCompanyInformation);
                CombineToCarriageReturnString(ContactInformationArray, AllContactInformation);
            end;

            trigger OnAfterGetRecord()
            var
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
                QltyMiscHelpers.GetBasicPersonDetails(CurrentInspection."Finished By User ID", FinishedByUserName, FinishedByTitle, FinishedByEmail, FinishedByPhone, DummyRecordId);
                if (FinishedByTitle = '') and (FinishedByUserName <> '') then
                    FinishedByTitle := DefaultQualityInspectorTitleLbl;
            end;
        }
    }

    rendering
    {
        layout(QltyCertificateOfAnalysisDefault)
        {
            Type = RDLC;
            Caption = 'Default Layout';
            Summary = 'The default certificate of analysis report.';
            LayoutFile = './src/Reports/QltyCertificateOfAnalysisDefault.rdl';
        }
        layout(QltyCertificateOfAnalysisAlternate)
        {
            Type = RDLC;
            Caption = 'Alternate Layout';
            Summary = 'Alternate certificate of analysis report.';
            LayoutFile = './src/Reports/QltyCertificateOfAnalysisAlternate.rdl';
        }
        layout(QualityManagement_CertificateOfAnalysis_Default)
        {
            Type = Word;
            Caption = 'Word Layout';
            Summary = 'Word layout for certificate of analysis report.';
            LayoutFile = './src/Reports/QltyCertificateOfAnalysis.docx';
        }
    }

    var
        Item: Record Item;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        MatrixSourceRecordId: array[10] of RecordId;
        CompanyInformationArray: array[8] of Text[100];
        ContactInformationArray: array[8] of Text[100];
        GradeDescription: Text;
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
        TestLineModifiedByUserId: Code[50];
        TestLinePreviousModifiedByUserId: Text;
        TestLineModifiedByUserName: Text;
        TestLineModifiedByJobTitle: Text;
        TestLineModifiedByPhone: Text;
        TestLineModifiedByEmail: Text;
        OptionalNameIfPerson: Text;
        OptionalTitleIfPerson: Text;
        OptionalEmailIfPerson: Text;
        OptionalPhoneIfPerson: Text;
        FinishedByUserName: Text;
        FinishedByTitle: Text;
        FinishedByEmail: Text;
        FinishedByPhone: Text;
        DirectorTitle: Text;
        DirectorName: Text;
        LabelFieldDescription: Text;
        DefaultDirectorTitleLbl: Label 'Director';
        DefaultQualityInspectorTitleLbl: Label 'Quality Inspection';

    local procedure CombineToCarriageReturnString(var InTextToCombine: array[8] of Text[100]; var CombinedTextResult: Text)
    var
        IndexOfTextToCombine: Integer;
        CombinedText: TextBuilder;
    begin
        CombinedTextResult := '';
        for IndexOfTextToCombine := 1 to arraylen(InTextToCombine) do
            if InTextToCombine[IndexOfTextToCombine] <> '' then
                CombinedText.AppendLine(InTextToCombine[IndexOfTextToCombine]);
        CombinedTextResult := CombinedText.ToText();
    end;
}
