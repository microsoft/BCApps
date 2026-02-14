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
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;

report 20405 "Qlty. General Purpose Inspect."
{
    ApplicationArea = QualityManagement;
    UsageCategory = ReportsAndAnalysis;
    Caption = 'Quality Management - General Purpose Inspection Report';
    ToolTip = 'A printable general purpose inspection report.';
    DefaultRenderingLayout = QltyGeneralPurposeInspectionDefault;
    Extensible = true;

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
            column(QltyInspection_Director_Title; DirectorTitle) { }
            column(QltyInspection_Director_Name; DirectorName) { }
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

            column(CompanyInformation_Row1; ArrayCompanyInformation[1]) { }
            column(CompanyInformation_Row2; ArrayCompanyInformation[2]) { }
            column(CompanyInformation_Row3; ArrayCompanyInformation[3]) { }
            column(CompanyInformation_Row4; ArrayCompanyInformation[4]) { }
            column(CompanyInformation_Row5; ArrayCompanyInformation[5]) { }
            column(CompanyInformation_Row6; ArrayCompanyInformation[6]) { }
            column(CompanyInformation_Row7; ArrayCompanyInformation[7]) { }
            column(CompanyInformation_Row8; ArrayCompanyInformation[8]) { }
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

                column(Test_Value; CurrentInspectionLine.GetLargeText()) { }
                column(Test_Result; "Result Code") { }
                column(Test_ResultDescription; ResultDescription) { }
                column(Field_LineCommentary; CurrentInspectionLine.GetMeasurementNote()) { }
                column(PromptedResultCaption_1; MatrixArrayCaptionSet[1])
                {
                }
                column(PromptedResultConditionDescription_1; MatrixArrayConditionDescriptionCellData[1])
                {
                }
                column(PromptedResultVisible_1; MatrixVisibleState[1])
                {
                }
                column(PromptedResultCaption_2; MatrixArrayCaptionSet[2])
                {
                }
                column(PromptedResultConditionDescription_2; MatrixArrayConditionDescriptionCellData[2])
                {
                }
                column(PromptedResultVisible_2; MatrixVisibleState[2])
                {
                }
                column(PromptedResultCaption_3; MatrixArrayCaptionSet[3])
                {
                }
                column(PromptedResultConditionDescription_3; MatrixArrayConditionDescriptionCellData[3])
                {
                }
                column(PromptedResultVisible_3; MatrixVisibleState[3])
                {
                }
                column(PromptedResultCaption_4; MatrixArrayCaptionSet[4])
                {
                }
                column(PromptedResultConditionDescription_4; MatrixArrayConditionDescriptionCellData[4])
                {
                }
                column(PromptedResultVisible_4; MatrixVisibleState[4])
                {
                }
                column(PromptedResultCaption_5; MatrixArrayCaptionSet[5])
                {
                }
                column(PromptedResultConditionDescription_5; MatrixArrayConditionDescriptionCellData[5])
                {
                }
                column(PromptedResultVisible_5; MatrixVisibleState[5])
                {
                }
                column(PromptedResultCaption_6; MatrixArrayCaptionSet[6])
                {
                }
                column(PromptedResultConditionDescription_6; MatrixArrayConditionDescriptionCellData[6])
                {
                }
                column(PromptedResultVisible_6; MatrixVisibleState[6])
                {
                }
                column(PromptedResultCaption_7; MatrixArrayCaptionSet[7])
                {
                }
                column(PromptedResultConditionDescription_7; MatrixArrayConditionDescriptionCellData[7])
                {
                }
                column(PromptedResultVisible_7; MatrixVisibleState[7])
                {
                }
                column(PromptedResultCaption_8; MatrixArrayCaptionSet[8])
                {
                }
                column(PromptedResultConditionDescription_8; MatrixArrayConditionDescriptionCellData[8])
                {
                }
                column(PromptedResultVisible_8; MatrixVisibleState[8])
                {
                }
                column(PromptedResultCaption_9; MatrixArrayCaptionSet[9])
                {
                }
                column(PromptedResultConditionDescription_9; MatrixArrayConditionDescriptionCellData[9])
                {
                }
                column(PromptedResultVisible_9; MatrixVisibleState[9])
                {
                }
                column(PromptedResultCaption_10; MatrixArrayCaptionSet[10])
                {
                }
                column(PromptedResultConditionDescription_10; MatrixArrayConditionDescriptionCellData[10])
                {
                }
                column(PromptedResultVisible_10; MatrixVisibleState[10])
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
                    QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
                    DummyRecordId: RecordId;
                    CombinedText: TextBuilder;
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

                    if IsPersonField then begin
                        Clear(CombinedText);
                        CarriageReturnPersonFieldDetails := '';
                        if OptionalTitleIfPerson <> '' then
                            CombinedText.AppendLine(OptionalTitleIfPerson);
                        if OptionalNameIfPerson <> '' then
                            CombinedText.AppendLine(OptionalNameIfPerson);
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
                FormatAddress.Company(ArrayCompanyInformation, CompanyInformation);

                DirectorTitle := DefaultDirectorTitleLbl;
                DirectorName := '';

                QltyManagementSetup.Get();
                if QltyManagementSetup."Certificate Contact No." <> '' then
                    if Contact.Get(QltyManagementSetup."Certificate Contact No.") then begin
                        DirectorName := Contact.Name;
                        DirectorTitle := Contact."Job Title";
                        FormatAddress.ContactAddr(ContactInformationArray, Contact);
                    end;

                CombineToCarriageReturnString(ArrayCompanyInformation, AllCompanyInformation);
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
                QltyPersonLookup.GetBasicPersonDetails(CurrentInspection."Finished By User ID", FinishedByUserName, FinishedByTitle, FinishedByEmail, FinishedByPhone, DummyRecordId);
                if (FinishedByTitle = '') and (FinishedByUserName <> '') then
                    FinishedByTitle := DefaultQualityInspectorTitleLbl;
            end;
        }
    }

    rendering
    {
        layout(QltyGeneralPurposeInspectionDefault)
        {
            Type = RDLC;
            Caption = 'Default Layout';
            Summary = 'The default general purpose quality inspection report.';
            LayoutFile = './src/Reports/QltyGeneralPurposeInspectionDefault.rdl';
        }
        layout(QltyGeneralPurposeInspectionAlternate)
        {
            Type = RDLC;
            Caption = 'Alternate Layout';
            Summary = 'An alternate general purpose quality inspection report.';
            LayoutFile = './src/Reports/QltyGeneralPurposeInspectionAlternate.rdl';
        }
        layout(QualityManagement_GeneralPurposeInspection_Default)
        {
            Type = Word;
            Caption = 'Word Layout';
            Summary = 'Word layout for general purpose quality inspection report.';
            LayoutFile = './src/Reports/QltyGeneralPurposeInspection.docx';
        }
    }

    var
        Item: Record Item;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
        MatrixSourceRecordId: array[10] of RecordId;
        ArrayCompanyInformation: array[8] of Text[100];
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
        DirectorTitle: Text;
        DirectorName: Text;
        LabelFieldDescription: Text;
        CarriageReturnPersonFieldDetails: Text;
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
