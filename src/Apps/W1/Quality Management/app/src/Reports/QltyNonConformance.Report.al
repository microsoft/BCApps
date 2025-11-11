// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Reports;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;

report 20403 "Qlty. Non-Conformance"
{
    ApplicationArea = QualityManagement;
    UsageCategory = ReportsAndAnalysis;
    Caption = 'Quality Management - Non-Conformance Report';
    DefaultRenderingLayout = QltyNonConformanceDefault;
    Extensible = true;
    AdditionalSearchTerms = 'NCR,CAR,Printable Certificate,Non Conformance';

    dataset
    {
        dataitem(CurrentTest; "Qlty. Inspection Test Header")
        {
            RequestFilterFields = "Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Document No.", "No.", "Retest No.", "Template Code";
            column(QITemplate_Description; QltyInspectionTemplateHdr.Description) { }
            column(QITest_Description; Description) { }
            column(QITest_Status; Status) { }
            column(QITest_Grade_Code; "Grade Code") { }
            column(QITest_Grade_Description; "Grade Description") { }
            column(QITest_No; CurrentTest."No.") { }
            column(QITest_RetestNo; CurrentTest."Retest No.") { }
            column(QITest_Finished_By_User_ID; "Finished By User ID") { }
            column(QITest_Finished_By_UserName; FinishedByUserName) { }
            column(QITest_Finished_By_Title; FinishedByUserName) { }
            column(QITest_Finished_By_Email; FinishedByEmail) { }
            column(QITest_Finished_By_Phone; FinishedByPhone) { }
            column(QITest_Director_Title; DirectorTitle) { }
            column(QITest_Director_Name; DirectorName) { }
            column(QITest_Finished_Date; "Finished Date") { }
            column(QITest_Source_Item_No_; "Source Item No.") { }
            column(QITest_Source_Item_Description; Item.Description) { }
            column(QITest_Source_Item_Description2; Item."Description 2") { }
            column(QITest_Source_Variant_Code; "Source Variant Code") { }
            column(QITest_Source_Lot_No_; "Source Lot No.") { }
            column(QITest_Source_Serial_No_; "Source Serial No.") { }
            column(QITest_Source_Package_No_; "Source Package No.") { }
            column(QITest_Source_Document_No_; "Source Document No.") { }
            column(QITest_Source_Task_No_; "Source Task No.") { }
            column(QITest_Source_Custom_1; "Source Custom 1") { }
            column(QITest_Source_Custom_2; "Source Custom 2") { }
            column(QITest_Source_Custom_3; "Source Custom 3") { }
            column(QITest_Source_Custom_4; "Source Custom 4") { }
            column(QITest_Source_Custom_5; "Source Custom 5") { }
            column(QITest_Source_Custom_6; "Source Custom 6") { }
            column(QITest_Source_Custom_7; "Source Custom 7") { }
            column(QITest_Source_Custom_8; "Source Custom 8") { }
            column(QITest_Source_Custom_9; "Source Custom 9") { }
            column(QITest_Source_Custom_10; "Source Custom 10") { }

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

            dataitem(CurrentTestLine; "Qlty. Inspection Test Line")
            {
                DataItemLink = "Test No." = field("No."), "Retest No." = field("Retest No.");
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
                column(Field_ModifiedDateTime; CurrentTestLine.SystemModifiedAt) { }
                column(Field_ModifiedByUserID; TestLineModifiedByUserId) { }
                column(Field_ModifiedByUserName; TestLineModifiedByUserName) { }
                column(Field_ModifiedByUserJobTitle; TestLineModifiedByJobTitle) { }
                column(Field_ModifiedByUserEmail; TestLineModifiedByEmail) { }
                column(Field_ModifiedByUserPhone; TestLineModifiedByPhone) { }
                column(Field_EnteredByNameAndTimestamp; EnteredByNameAndTimestamp) { }

                column(Test_Value; CurrentTestLine.GetLargeText()) { }
                column(Test_Grade; CurrentTestLine."Grade Code") { }
                column(Test_GradeDescription; GradeDescription) { }
                column(Field_LineCommentary; CurrentTestLine.GetMeasurementNote()) { }
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
                column(CarriageReturnPersonFieldDetails; CarriageReturnPersonFieldDetails)
                {
                }

                trigger OnAfterGetRecord()
                var
                    QltyGradeConditionMgmt: Codeunit "Qlty. Grade Condition Mgmt.";
                    DummyRecordId: RecordId;
                    CombinedText: TextBuilder;
                begin
                    Clear(MatrixSourceRecordId);
                    Clear(MatrixArrayConditionCellData);
                    Clear(MatrixArrayConditionDescriptionCellData);
                    Clear(MatrixArrayCaptionSet);
                    Clear(MatrixVisibleState);
                    GradeDescription := '';

                    TestLineModifiedByUserId := QltyMiscHelpers.GetUserNameByUserSecurityID(CurrentTestLine.SystemModifiedBy);
                    if TestLinePreviousModifiedByUserId <> TestLineModifiedByUserId then
                        QltyMiscHelpers.GetBasicPersonDetails(TestLineModifiedByUserId, TestLineModifiedByUserName, TestLineModifiedByJobTitle, TestLineModifiedByEmail, TestLineModifiedByPhone, DummyRecordId);
                    TestLinePreviousModifiedByUserId := TestLineModifiedByUserId;

                    IsPersonField := QltyMiscHelpers.GetBasicPersonDetailsFromTestLine(CurrentTestLine, OptionalNameIfPerson, OptionalTitleIfPerson, OptionalEmailIfPerson, OptionalPhoneIfPerson, DummyRecordId);

                    FieldIsLabel := CurrentTestLine."Field Type" in [CurrentTestLine."Field Type"::"Field Type Label"];
                    FieldIsText := CurrentTestLine."Field Type" in [CurrentTestLine."Field Type"::"Field Type Text"];

                    HasEnteredValue := not FieldIsLabel and
                        ((CurrentTestLine."Test Value" <> '') and (CurrentTestLine.SystemCreatedAt <> CurrentTestLine.SystemModifiedAt));

                    if HasEnteredValue then
                        EnteredByNameAndTimestamp := StrSubstNo(EnteredByNameAndTimestampLbl, TestLinePreviousModifiedByUserId, CurrentTestLine.SystemModifiedAt)
                    else
                        Clear(EnteredByNameAndTimestamp);

                    GradeDescription := CurrentTestLine."Grade Description";
                    if GradeDescription = '' then
                        GradeDescription := CurrentTestLine."Grade Code";
                    QltyGradeConditionMgmt.GetPromotedGradesForTestLine(CurrentTestLine, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);

                    if FieldIsLabel then
                        LabelFieldDescription := CurrentTestLine.Description
                    else
                        LabelFieldDescription := '';

                    if IsPersonField then begin
                        Clear(CombinedText);
                        CarriageReturnPersonFieldDetails := '';
                        if OptionalTitleIfPerson <> '' then
                            CombinedText.AppendLine(TitleLbl + ': ' + OptionalTitleIfPerson);
                        if OptionalNameIfPerson <> '' then
                            CombinedText.AppendLine(NameLbl + ': ' + OptionalNameIfPerson);
                        if OptionalEmailIfPerson <> '' then
                            CombinedText.AppendLine(OptionalEmailIfPerson);
                        if OptionalPhoneIfPerson <> '' then
                            CombinedText.AppendLine(OptionalPhoneIfPerson);
                        CarriageReturnPersonFieldDetails := CombinedText.ToText();
                    end else
                        CarriageReturnPersonFieldDetails := '';
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
                if QltyManagementSetup."CoA Contact No." <> '' then
                    if Contact.Get(QltyManagementSetup."CoA Contact No.") then begin
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
                if CurrentTest."Source Item No." = '' then
                    Item.Reset()
                else
                    Item.Get(CurrentTest."Source Item No.");

                if QltyInspectionTemplateHdr.Code <> CurrentTest."Template Code" then begin
                    Clear(QltyInspectionTemplateHdr);
                    if QltyInspectionTemplateHdr.Get(CurrentTest."Template Code") then;
                end;

                FinishedByUserName := CurrentTest."Finished By User ID";

                QltyMiscHelpers.GetBasicPersonDetails(CurrentTest."Finished By User ID", FinishedByUserName, FinishedByTitle, FinishedByEmail, FinishedByPhone, DummyRecordId);
                if (FinishedByTitle = '') and (FinishedByUserName <> '') then
                    FinishedByTitle := DefaultQualityInspectorTitleLbl;
            end;
        }
    }

    rendering
    {
        layout(QltyNonConformanceDefault)
        {
            Type = RDLC;
            Caption = 'Default Layout';
            Summary = 'The default layout for the non-conformance Report.';
            LayoutFile = './src/Reports/QltyNonConformanceDefault.rdl';
        }
        layout(QltyNonConformanceAlternate)
        {
            Type = RDLC;
            Caption = 'Alternate Layout';
            Summary = 'An alternate layout for the non-conformance Report.';
            LayoutFile = './src/Reports/QltyNonConformanceAlternate.rdl';
        }
        layout(QualityManagement_NonConformance_Default)
        {
            Type = Word;
            Caption = 'Word Layout';
            Summary = 'Word layout for the non-conformance Report.';
            LayoutFile = './src/Reports/QltyNonConformance.docx';
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
        EnteredByNameAndTimestamp: Text;
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
        CarriageReturnPersonFieldDetails: Text;
        TitleLbl: Label 'Title';
        NameLbl: Label 'Name';
        DefaultDirectorTitleLbl: Label 'Director';
        DefaultQualityInspectorTitleLbl: Label 'Quality Inspection';
        EnteredByNameAndTimestampLbl: Label '%1 %2', Locked = true;

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
