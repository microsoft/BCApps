// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Purchases.Vendor;
using System.Telemetry;
using System.Utilities;

/// <summary>
/// Builds shared IRIS transmission XML parts for schema implementations.
/// </summary>
/// <remarks>
/// Use fresh or cleared generator and XML-helper instances for each transmission.
/// Call PrepareTransmission first, build the manifest and submissions, then call FinishTransmission.
/// Keep the same generator and XML-helper instances throughout the operation.
/// </remarks>
codeunit 10033 "Generate Xml File IRIS"
{
    Access = Public;

    var
        Helper: Codeunit "Helper IRIS";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TaxYearGlobal: Text[4];
        SoftwareIdGlobal: Text;
        TCCGlobal: Text;
        SubmissionIdGlobal: Integer;
        RecordIdGlobal: Integer;
        TotalSubmissionCountGlobal: Integer;
        TotalRecordCountGlobal: Integer;
        UsedSubmissionIdsGlobal: Dictionary of [Text, Integer];
        UsedRecordIdsGlobal: Dictionary of [Text, Integer];
        CorrectionToZeroModeGlobal: Boolean;
        TransmissionTypeGlobal: Enum "Transmission Type IRIS";
        TransmRootNodeNameTxt: label 'IRTransmission', Locked = true;
        GetStatusRootNodeNameTxt: Label 'TransStatusOrAckRequest', Locked = true;
        MailingAddressGrpTxt: Label 'MailingAddressGrp', Locked = true;
        Form1099TotalAmtGrpTxt: Label 'Form%1TotalAmtGrp', Comment = '%1 - Form Type Code, ex. 1099INT', Locked = true;
        Form1099DetailTxt: Label 'Form%1Detail', Comment = '%1 - Form Type Code, ex. 1099INT', Locked = true;
        CorrectionToZeroModeErr: Label 'Correction to zero mode can only be used for corrections.', Locked = true;
        CreateAckRequestEventTxt: Label 'CreateAcknowledgementRequest', Locked = true;
        CreateGetStatusRequestEventTxt: Label 'CreateGetStatusRequest', Locked = true;
        NoDocumentsSelectedErr: Label 'No 1099 documents were selected for the transmission of the type %1. Current filters: \%2', Comment = '%1 - transmission type, %2 - filters for IRS 1099 Form Doc. Header';
        EmptySearchIdErr: Label 'Record Id or Unique Transmission ID cannot be empty.';
        LastAcceptedReceiptIdEmtpyErr: Label 'Last accepted receipt ID is missing for the 1099 form document with ID %1. Do not use correction for new documents.', Comment = '%1 - IRS 1099 Form Doc. ID';
        SubmissionIdEmtpyErr: Label 'Submission ID is missing for the 1099 form document with ID %1.', Comment = '%1 - IRS 1099 Form Doc. ID';
        RecordIdEmtpyErr: Label 'Record ID is missing for the 1099 form document with ID %1. \Reopen the document or clear the Needs Correction flag to exclude it from the correction transmission. \If you use two-step correction, release the document before step 2.', Comment = '%1 - IRS 1099 Form Doc. ID';

    /// <summary>
    /// Selects and validates documents, initializes XML and returns a new transmission ID.
    /// </summary>
    /// <remarks>Clear both codeunit instances before calling. Preparation may ask for tax-year mapping confirmation.</remarks>
    /// <param name="XmlHelper">The XML-helper instance to share with the schema implementation.</param>
    /// <param name="TempDocHeader">Cleared and populated with the selected documents.</param>
    procedure PrepareTransmission(var XmlHelper: Codeunit "Helper IRIS"; Transmission: Record "Transmission IRIS"; TransmissionType: Enum "Transmission Type IRIS"; CorrectionToZeroMode: Boolean; VersionText: Text; VerifiedTaxYear: Boolean; var UniqueTransmissionId: Text[100]; var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary)
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ProcessTransmission: Codeunit "Process Transmission IRIS";
        Supplemental: Codeunit "IRS 1099 Supplemental";
        PrevTransmissionStatus: Enum "Transmission Status IRIS";
    begin
        Helper := XmlHelper;
        CorrectionToZeroModeGlobal := CorrectionToZeroMode;
        TaxYearGlobal := Transmission."Period No.";
        SoftwareIdGlobal := Helper.GetSoftwareId(TaxYearGlobal);
        Helper.ConfirmTaxYearMapping(VersionText, TaxYearGlobal, VerifiedTaxYear);
        TCCGlobal := IRSFormsFacade.GetTCC();

        if CorrectionToZeroModeGlobal then
            if TransmissionType <> Enum::"Transmission Type IRIS"::"C" then
                Error(CorrectionToZeroModeErr);

        DocHeader.SetRange("IRIS Transmission Document ID", Transmission."Document ID");
        DocHeader.SetFilter(Status, ProcessTransmission.GetFormDocToSendStatusFilter());
        case TransmissionType of
            Enum::"Transmission Type IRIS"::"R":
                begin
                    PrevTransmissionStatus := Transmission.Status;
                    if PrevTransmissionStatus <> Enum::"Transmission Status IRIS"::Rejected then
                        DocHeader.SetRange("IRIS Submission Status", Enum::"Transmission Status IRIS"::Rejected);    // replace only rejected submissions for partially accepted transmission
                end;
            Enum::"Transmission Type IRIS"::"C":
                DocHeader.SetRange("IRIS Needs Correction", true);
        end;

        if not DocHeader.FindSet() then
            Error(NoDocumentsSelectedErr, TransmissionType, DocHeader.GetFilters());

        TempDocHeader.Reset();
        TempDocHeader.DeleteAll();
        repeat
            Supplemental.ValidateSupplementalLines(DocHeader.ID);
            TempDocHeader := DocHeader;
            TempDocHeader.Insert();
        until DocHeader.Next() = 0;

        UniqueTransmissionId := Helper.CreateUniqueTransmissionIdentifier(TCCGlobal);
        TransmissionTypeGlobal := TransmissionType;
        InitSubmissionAndRecordIds(Transmission."Document ID");

        InitTransmissionDocElement();
    end;

    /// <summary>
    /// Completes the XML and saves submission and record IDs to the actual document headers.
    /// </summary>
    /// <remarks>Call after all submissions are complete. Does not submit to IRS or commit the transaction.</remarks>
    /// <param name="TempBlob">An empty blob that receives the completed XML.</param>
    procedure FinishTransmission(var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var TempBlob: Codeunit "Temp Blob")
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        Helper.UpdateSingleXmlNode('TotalIssuerFormCnt', Format(TotalSubmissionCountGlobal));
        Helper.UpdateSingleXmlNode('TotalRecipientFormCnt', Format(TotalRecordCountGlobal));

        Helper.WriteXMLDocToTempBlob(TempBlob);

        // save SubmissionId and RecordId to use them later for replacements
        TempDocHeader.Reset();
        TempDocHeader.FindSet();
        repeat
            DocHeader.Get(TempDocHeader.ID);
            DocHeader."IRIS Submission ID" := TempDocHeader."IRIS Submission ID";
            DocHeader."IRIS Record ID" := TempDocHeader."IRIS Record ID";
            DocHeader.Modify();
        until TempDocHeader.Next() = 0;

        FeatureTelemetry.LogUptake('0000P83', Helper.GetIRISFeatureName(), Enum::"Feature Uptake Status"::"Used");
    end;

    local procedure InitTransmissionDocElement()
    begin
        Helper.Initialize(TransmRootNodeNameTxt);
    end;

    local procedure InitGetStatusDocElement()
    begin
        Helper.Initialize(GetStatusRootNodeNameTxt);
    end;

    /// <summary>
    /// Adds the transmission manifest using the supplied schema version and prior-year indicator.
    /// </summary>
    procedure AddIRTransmissionManifest(Transmission: Record "Transmission IRIS"; UniqueTransmissionId: Text; VersionText: Text; PriorYearDataIndicator: Text)
    var
        PrevTransmissionStatus: Enum "Transmission Status IRIS";
    begin
        Helper.AddParentXmlNode('IRTransmissionManifest');
        Helper.AppendXmlNode('SchemaVersionNum', VersionText);
        Helper.AppendXmlNode('UniqueTransmissionId', UniqueTransmissionId);
        Helper.AppendXmlNode('TaxYr', TaxYearGlobal);
        Helper.AppendXmlNode('PriorYearDataInd', PriorYearDataIndicator);
        Helper.AppendXmlNode('TransmissionTypeCd', Helper.GetTransmissionTypeName(TransmissionTypeGlobal));
        Helper.AppendXmlNode('TestCd', GetTestFileIndicator());

        // add OriginalReceiptId when the whole transmission is replaced
        PrevTransmissionStatus := Transmission.Status;
        if (TransmissionTypeGlobal = Enum::"Transmission Type IRIS"::"R") and
           (PrevTransmissionStatus = Enum::"Transmission Status IRIS"::Rejected)
        then
            Helper.AppendXmlNode('OriginalReceiptId', Transmission."Original Receipt ID");

        AddTransmitterInfo();

        Helper.AppendXmlNode('VendorCd', 'I');
        Helper.AppendXmlNode('SoftwareId', SoftwareIdGlobal);


        Helper.AppendXmlNode('TotalIssuerFormCnt', 'N');            // updated after all forms are added
        Helper.AppendXmlNode('TotalRecipientFormCnt', 'N');         // updated after all forms are added
        Helper.AppendXmlNode('PaperSubmissionInd', '0');
        Helper.AppendXmlNode('MediaSourceCd', 'M');
        Helper.AppendXmlNode('SubmissionChannelCd', 'A2A');

        Helper.CloseParentXmlNode();
    end;

    local procedure AddTransmitterInfo()
    var
        TIN: Text;
        CompanyName: Text;
        StreetAddress: Text;
        CityName: Text;
        StateCode: Text;
        PostCode: Text;
        ContactName: Text;
        ContactEmail: Text;
        ContactPhone: Text;
    begin
        Helper.AddParentXmlNode('TransmitterGrp');

        GetMicrosoftData(TIN, CompanyName, StreetAddress, CityName, StateCode, PostCode, ContactName, ContactEmail, ContactPhone);
        Helper.AppendXmlNode('TIN', Helper.FormatTIN(TIN));
        Helper.AppendXmlNode('TINSubmittedTypeCd', 'BUSINESS_TIN');
        Helper.AppendXmlNode('TransmitterControlCd', TCCGlobal);
        Helper.AppendXmlNode('ForeignEntityInd', '0');

        AddBusinessName(CompanyName);

        Helper.AddParentXmlNode('CompanyGrp');
        AddBusinessName(CompanyName);
        AddUSAddress(MailingAddressGrpTxt, StreetAddress, CityName, StateCode, PostCode);
        Helper.CloseParentXmlNode();

        Helper.AddParentXmlNode('ContactNameGrp');
        Helper.AppendXmlNode('PersonNm', ContactName);
        Helper.CloseParentXmlNode();
        Helper.AppendXmlNode('ContactEmailAddressTxt', ContactEmail);
        Helper.AppendXmlNode('ContactPhoneNum', ContactPhone);

        Helper.CloseParentXmlNode();
    end;

    /// <summary>
    /// Opens a submission header, adds its issuer and returns its submission ID.
    /// </summary>
    procedure StartSubmissionHeader(var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary) SubmissionId: Text[20]
    var
        Transmission: Record "Transmission IRIS";
        PrevTransmissionStatus: Enum "Transmission Status IRIS";
        OriginalUniqueSubmissionId: Text;
    begin
        SubmissionId := GetNextSubmissionId(TempDocHeader."IRIS Submission ID");
        Helper.AddParentXmlNode('IRSubmission1Header');

        Helper.AppendXmlNode('SubmissionId', SubmissionId);

        Transmission.Get(TempDocHeader."IRIS Transmission Document ID");
        PrevTransmissionStatus := Transmission.Status;
        if (TransmissionTypeGlobal = Enum::"Transmission Type IRIS"::"R") and
           (PrevTransmissionStatus <> Enum::"Transmission Status IRIS"::Rejected)
        then begin
            if TempDocHeader."IRIS Submission ID" = '' then
                Error(SubmissionIdEmtpyErr, TempDocHeader.ID);
            OriginalUniqueSubmissionId := StrSubstNo('%1|%2', TempDocHeader."IRIS Last Receipt ID", TempDocHeader."IRIS Submission ID");
            Helper.AppendXmlNode('OriginalUniqueSubmissionId', OriginalUniqueSubmissionId);
        end;

        Helper.AppendXmlNode('TaxYr', TempDocHeader."Period No.");

        AddIssuerDetails();
    end;

    /// <summary>
    /// Adds the form type and recipient count to the open submission header.
    /// </summary>
    procedure AddSubmissionFormInfo(TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; RecipientFormCount: Integer)
    begin
        Helper.AppendXmlNode('FormTypeCd', GetFormTypeCode(TempDocHeader."Form No."));
        Helper.AppendXmlNode('ParentFormTypeCd', '1096');
        Helper.AppendXmlNode('CFSFElectionInd', '0');
        Helper.AppendXmlNode('TotalReportedRcpntFormCnt', Format(RecipientFormCount));
    end;

    /// <summary>
    /// Sets the submission ID on the filtered temporary document headers.
    /// </summary>
    procedure SaveSubmissionId(var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; SubmissionId: Text[20])
    begin
        // update SubmissionId for temporary IRS 1099 Document records
        if TempDocHeader.FindSet() then
            repeat
                TempDocHeader."IRIS Submission ID" := CopyStr(SubmissionId, 1, MaxStrLen(TempDocHeader."IRIS Submission ID"));
                TempDocHeader.Modify();
            until TempDocHeader.Next() = 0;
    end;

    /// <summary>
    /// Adds ordered financial and supplied supplemental totals for the filtered documents.
    /// </summary>
    /// <param name="FormBoxAmtXmlElemNamesValues">Supplemental XML values on entry; financial totals are added before writing.</param>
    procedure AddSubmissionTotals(var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var FormBoxAmtXmlElemNamesValues: Dictionary of [Text, Text])
    var
        FormType: Enum "Form Type IRIS";
        FormTotalAmounts: Dictionary of [Text, Decimal];
        TotalReportedAmt: Decimal;
        FederalIncomeTaxWithheldAmt: Decimal;
        Form1099TotalAmtGrpTagName: Text;
        AmtXmlElemNames: List of [Text];
        AmtXmlElemName: Text;
        AmtXmlElemValue: Text;
    begin
        if not Evaluate(FormType, TempDocHeader."Form No.") then
            exit;

        Helper.AddParentXmlNode('IRSubmission1FormTotals');

        CalcFormTotalAmounts(TempDocHeader, FormTotalAmounts, TotalReportedAmt, FederalIncomeTaxWithheldAmt);
        GetFormBoxAmtXmlElemNamesAndValues(TempDocHeader, FormTotalAmounts, FormBoxAmtXmlElemNamesValues);
        FormBoxAmtXmlElemNamesValues.Add('TotalReportedAmt', Helper.FormatDecimal(TotalReportedAmt));

        Form1099TotalAmtGrpTagName := GetForm1099TotalAmtGrpTagName(FormType);

        Helper.AddParentXmlNode(Form1099TotalAmtGrpTagName);

        // elements with total amounts must be added in a specific order
        AmtXmlElemNames := Helper.GetTotalAmountsXmlElementsOrder(TempDocHeader."Period No.", FormType);
        foreach AmtXmlElemName in AmtXmlElemNames do
            if FormBoxAmtXmlElemNamesValues.Get(AmtXmlElemName, AmtXmlElemValue) then
                Helper.AppendXmlNode(AmtXmlElemName, AmtXmlElemValue);

        Helper.CloseParentXmlNode();

        Helper.CloseParentXmlNode();
    end;

    local procedure AddIssuerDetails()
    var
        CompanyInformation: Record "Company Information";
        IRSFormsSetup: Record "IRS Forms Setup";
        "Generate Xml File IRIS Events": codeunit "Generate Xml File IRIS Events";
        RecRef: RecordRef;
    begin
        Helper.AddParentXmlNode('IssuerDetail');

        CompanyInformation.Get();
        IRSFormsSetup.Get();
        "Generate Xml File IRIS Events".RunOnAddIssuerDetailsOnAfterGetCompanyInfoAndIRSFormSetup(CompanyInformation, IRSFormsSetup);
        Helper.AppendXmlNode('ForeignEntityInd', GetForeignEntityInd(CompanyInformation."Country/Region Code"));
        Helper.AppendXmlNode('TIN', Helper.FormatTIN(CompanyInformation."Federal ID No."));
        Helper.AppendXmlNode('TINSubmittedTypeCd', 'BUSINESS_TIN');
        Helper.AppendXmlNode('BusinessNameControlTxt', IRSFormsSetup."Business Name Control");

        AddBusinessName(Helper.ConcatenateWithSpace(CompanyInformation.Name, CompanyInformation."Name 2"));

        RecRef.GetTable(CompanyInformation);
        AddAddress(MailingAddressGrpTxt, RecRef);

        Helper.AppendXmlNode('PhoneNum', Helper.FormatPhoneNumber(CompanyInformation."Phone No."));

        Helper.CloseParentXmlNode();
    end;

    /// <summary>
    /// Reads company contact information and applies the contact customization event.
    /// </summary>
    procedure GetContactCompanyInformation(var CompanyInformation: Record "Company Information")
    var
        "Generate Xml File IRIS Events": codeunit "Generate Xml File IRIS Events";
    begin
        CompanyInformation.Get();
        "Generate Xml File IRIS Events".RunOnAddContactPersonInformationGrpOnAfterGetCompanyInformationSetup(CompanyInformation);
    end;

    /// <summary>
    /// Adds contact XML when the formatted contact name is not empty.
    /// </summary>
    /// <remarks>The schema implementation must validate its required contact fields before calling.</remarks>
    procedure AddContactPersonInformationGrp(CompanyInformation: Record "Company Information")
    var
        ContactPerson: Text;
        PhoneNo: Text;
        Email: Text;
    begin
        ContactPerson := Helper.FormatContactPersonName(CompanyInformation."Contact Person");
        PhoneNo := Helper.FormatPhoneNumber(CompanyInformation."Phone No.");
        Email := CompanyInformation."E-Mail";
        if ContactPerson = '' then
            exit;

        Helper.AddParentXmlNode('ContactPersonInformationGrp');

        Helper.AppendXmlNode('ContactPersonNm', ContactPerson);
        Helper.AppendXmlNode('ContactPhoneNum', PhoneNo);
        Helper.AppendXmlNode('ContactEmailAddressTxt', Email);

        Helper.CloseParentXmlNode();
    end;

    /// <summary>
    /// Opens a recipient form detail and returns its record ID.
    /// </summary>
    /// <returns>True if a document with a supported form type and an existing vendor was found.</returns>
    procedure StartFormDetail(var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var RecordId: Text[20]): Boolean
    var
        Vendor: Record Vendor;
        FormType: Enum "Form Type IRIS";
        Form1099DetailTagName: Text;
    begin
        if not TempDocHeader.FindFirst() then
            exit(false);
        if not Evaluate(FormType, TempDocHeader."Form No.") then
            exit(false);
        if not Vendor.Get(TempDocHeader."Vendor No.") then
            exit(false);

        Form1099DetailTagName := GetForm1099DetailTagName(FormType);
        Helper.AddParentXmlNode(Form1099DetailTagName);

        RecordId := GetNextRecordId(TempDocHeader."IRIS Record ID");
        Helper.AppendXmlNode('TaxYr', TempDocHeader."Period No.");
        Helper.AppendXmlNode('RecordId', RecordId);
        Helper.AppendXmlNode('VoidInd', '0');
        Helper.AppendXmlNode('CorrectedInd', GetCorrectedInd(TransmissionTypeGlobal));

        exit(true);
    end;

    /// <summary>
    /// Writes recipient details and adds financial XML values for the filtered documents.
    /// </summary>
    procedure AddRecipientAndFormValues(var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var FormBoxAmtXmlElemNamesValues: Dictionary of [Text, Text])
    var
        Vendor: Record Vendor;
        FormType: Enum "Form Type IRIS";
        TotalAmounts: Dictionary of [Text, Decimal];
    begin
        Vendor.Get(TempDocHeader."Vendor No.");
        Evaluate(FormType, TempDocHeader."Form No.");
        AddRecipientDetails(Vendor);

        Helper.AppendXmlNode('RecipientAccountNum', Helper.GetVendorBankAccountNo(Vendor));

        CalcFormTotalAmounts(TempDocHeader, TotalAmounts);
        GetFormBoxAmtXmlElemNamesAndValues(TempDocHeader, TotalAmounts, FormBoxAmtXmlElemNamesValues);

        case FormType of
            FormType::"DIV":
                AddForm1099DIVDetailsPart(Vendor);
            FormType::"INT":
                AddForm1099INTDetailsPart(Vendor);
            FormType::"MISC":
                AddForm1099MISCDetailsPart(Vendor);
            FormType::"NEC":
                AddForm1099NECDetailsPart();
            else
                Helper.AddOtherForm1099DetailsPart(TempDocHeader);
        end;
    end;

    /// <summary>
    /// Writes ordered values, closes the form detail and saves its ID to the filtered temporary headers.
    /// </summary>
    procedure FinishFormDetail(var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; RecordId: Text[20]; FormBoxAmtXmlElemNamesValues: Dictionary of [Text, Text]; OccupationCodes: List of [Text])
    var
        FormType: Enum "Form Type IRIS";
        AmtXmlElemNames: List of [Text];
        AmtXmlElemName: Text;
        AmtXmlElemValue: Text;
        OccupationCode: Text;
    begin
        Evaluate(FormType, TempDocHeader."Form No.");
        AmtXmlElemNames := Helper.GetDetailAmountsXmlElementsOrder(TempDocHeader."Period No.", FormType);
        foreach AmtXmlElemName in AmtXmlElemNames do
            if AmtXmlElemName = 'TreasuryTippedOccupationCd' then
                foreach OccupationCode in OccupationCodes do
                    Helper.AppendXmlNode(AmtXmlElemName, OccupationCode)
            else
                if FormBoxAmtXmlElemNamesValues.Get(AmtXmlElemName, AmtXmlElemValue) then
                    Helper.AppendXmlNode(AmtXmlElemName, AmtXmlElemValue);

        Helper.CloseParentXmlNode();

        // update RecordId for temporary IRS 1099 Document records
        if TempDocHeader.FindSet() then
            repeat
                TempDocHeader."IRIS Record ID" := CopyStr(RecordId, 1, MaxStrLen(TempDocHeader."IRIS Record ID"));
                TempDocHeader.Modify();
            until TempDocHeader.Next() = 0;
    end;

    local procedure AddForm1099DIVDetailsPart(var Vendor: Record Vendor)
    begin
        Helper.AppendXmlNode('FATCAFilingRequirementInd', Helper.FormatBoolean(Vendor."FATCA Requirement"));
        Helper.AppendXmlNode('SecondTINNoticeInd', '0');
    end;

    local procedure AddForm1099INTDetailsPart(var Vendor: Record Vendor)
    begin
        Helper.AppendXmlNode('SecondTINNoticeInd', '0');
        Helper.AppendXmlNode('FATCAFilingRequirementInd', Helper.FormatBoolean(Vendor."FATCA Requirement"));
    end;

    local procedure AddForm1099MISCDetailsPart(var Vendor: Record Vendor)
    begin
        Helper.AppendXmlNode('SecondTINNoticeInd', '0');
        Helper.AppendXmlNode('FATCAFilingRequirementInd', Helper.FormatBoolean(Vendor."FATCA Requirement"));
    end;

    local procedure AddForm1099NECDetailsPart()
    begin
        Helper.AppendXmlNode('SecondTINNoticeInd', '0');
    end;

    /// <summary>
    /// Adds the accepted receipt, submission and record reference for a correction.
    /// </summary>
    /// <param name="OtherIntakeSystemIndicator">The intake-system indicator, or empty to omit that element.</param>
    procedure AddPrevSubmittedRecRecipientGrp(TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary; OtherIntakeSystemIndicator: Text)
    var
        Transmission: Record "Transmission IRIS";
        PrevAcceptedReceiptId: Text[100];
        UniqueRecordId: Text;
    begin
        Helper.AddParentXmlNode('PrevSubmittedRecRecipientGrp');

        PrevAcceptedReceiptId := TempIRS1099FormDocHeader."IRIS Last Accepted Receipt ID";
        if PrevAcceptedReceiptId = '' then begin
            Transmission.Get(TempIRS1099FormDocHeader."IRIS Transmission Document ID");
            if Transmission.Status in [Enum::"Transmission Status IRIS"::Accepted, Enum::"Transmission Status IRIS"::"Partially Accepted", Enum::"Transmission Status IRIS"::"Accepted with Errors"] then
                PrevAcceptedReceiptId := Transmission."Receipt ID";
        end;

        if PrevAcceptedReceiptId = '' then
            Error(LastAcceptedReceiptIdEmtpyErr, TempIRS1099FormDocHeader.ID);
        if TempIRS1099FormDocHeader."IRIS Submission ID" = '' then
            Error(SubmissionIdEmtpyErr, TempIRS1099FormDocHeader.ID);
        if TempIRS1099FormDocHeader."IRIS Record ID" = '' then
            Error(RecordIdEmtpyErr, TempIRS1099FormDocHeader.ID);

        UniqueRecordId := StrSubstNo('%1|%2|%3', PrevAcceptedReceiptId, TempIRS1099FormDocHeader."IRIS Submission ID", TempIRS1099FormDocHeader."IRIS Record ID");
        Helper.AppendXmlNode('OtherIntakeSystemInd', OtherIntakeSystemIndicator);
        Helper.AppendXmlNode('UniqueRecordId', UniqueRecordId);

        Helper.CloseParentXmlNode();
    end;

    local procedure AddRecipientDetails(var Vendor: Record Vendor)
    var
        RecRef: RecordRef;
    begin
        Helper.AddParentXmlNode('RecipientDetail');

        Helper.AppendXmlNode('TIN', Helper.FormatTIN(Vendor."Federal ID No."));
        Helper.AppendXmlNode('TINSubmittedTypeCd', GetTINSubmittedType(Vendor."Tax Identification Type"));

        case Vendor."Tax Identification Type" of
            "Tax Identification Type"::"Legal Entity":
                AddBusinessName(Helper.ConcatenateWithSpace(Vendor.Name, Vendor."Name 2"));
            "Tax Identification Type"::"Natural Person":
                AddPersonName(Vendor);
        end;

        RecRef.GetTable(Vendor);
        AddAddress(MailingAddressGrpTxt, RecRef);

        Helper.CloseParentXmlNode();
    end;

    local procedure AddBusinessName(BusinessName: Text)
    var
        BusinessNameLine1: Text;
        BusinessNameLine2: Text;
    begin
        Helper.AddParentXmlNode('BusinessName');

        Helper.FormatBusinessName(BusinessName, BusinessNameLine1, BusinessNameLine2);
        Helper.AppendXmlNode('BusinessNameLine1Txt', BusinessNameLine1);
        Helper.AppendXmlNode('BusinessNameLine2Txt', BusinessNameLine2);

        Helper.CloseParentXmlNode();
    end;

    local procedure AddPersonName(var Vendor: Record Vendor)
    var
        Contact: Record Contact;
        FirstName: Text;
        MiddleName: Text;
        LastName: Text;
        FullName: List of [Text];
    begin
        Helper.AddParentXmlNode('PersonName');

        if Vendor."Primary Contact No." <> '' then
            if Contact.Get(Vendor."Primary Contact No.") then begin
                FirstName := Contact."First Name";
                MiddleName := Contact."Middle Name";
                LastName := Contact.Surname;
            end;

        if (FirstName = '') and (LastName = '') then begin
            FullName := Vendor.Name.Split(' ');
            if FullName.Get(1, FirstName) then;
            if FullName.Get(2, LastName) then;
            MiddleName := '';
        end;

        Helper.AppendXmlNode('PersonFirstNm', Helper.FormatPersonName(FirstName));
        Helper.AppendXmlNode('PersonMiddleNm', Helper.FormatPersonName(MiddleName));
        Helper.AppendXmlNode('PersonLastNm', Helper.FormatPersonName(LastName));

        Helper.CloseParentXmlNode();
    end;

    local procedure AddAddress(AddressTagName: Text; RecRef: RecordRef)
    var
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
        CountryRegion: Code[10];
        AddressLine1: Text;
        AddressLine2: Text;
        StreetAddress: Text;
        CityName: Text;
        ProvinceOrStateName: Text;
        FIPSCountryCode: Text;
        PostCode: Text;
    begin
        case RecRef.Number of
            Database::"Company Information":
                begin
                    CountryRegion := RecRef.Field(CompanyInformation.FieldNo("Country/Region Code")).Value;
                    AddressLine1 := RecRef.Field(CompanyInformation.FieldNo("Address")).Value;
                    AddressLine2 := RecRef.Field(CompanyInformation.FieldNo("Address 2")).Value;
                    CityName := RecRef.Field(CompanyInformation.FieldNo("City")).Value;
                    ProvinceOrStateName := RecRef.Field(CompanyInformation.FieldNo(County)).Value;
                    PostCode := RecRef.Field(CompanyInformation.FieldNo("Post Code")).Value;
                end;
            Database::Vendor:
                begin
                    CountryRegion := RecRef.Field(Vendor.FieldNo("Country/Region Code")).Value;
                    AddressLine1 := RecRef.Field(Vendor.FieldNo("Address")).Value;
                    AddressLine2 := RecRef.Field(Vendor.FieldNo("Address 2")).Value;
                    CityName := RecRef.Field(Vendor.FieldNo("City")).Value;
                    ProvinceOrStateName := RecRef.Field(Vendor.FieldNo(County)).Value;
                    PostCode := RecRef.Field(Vendor.FieldNo("Post Code")).Value;
                end;
        end;

        StreetAddress := Helper.ConcatenateWithSpace(AddressLine1, AddressLine2);
        FIPSCountryCode := Helper.ISOToFIPSCountryCode(CountryRegion);

        if Helper.IsForeignCountryRegion(CountryRegion) then
            AddForeignAddress(AddressTagName, StreetAddress, CityName, ProvinceOrStateName, FIPSCountryCode, PostCode)
        else
            AddUSAddress(AddressTagName, StreetAddress, CityName, ProvinceOrStateName, PostCode);
    end;

    local procedure AddUSAddress(AddressTagName: Text; StreetAddress: Text; CityName: Text; StateCode: Text; PostCode: Text)
    var
        AddressLine1: Text;
        AddressLine2: Text;
        FormattedStateCode: Text;
    begin
        Helper.AddParentXmlNode(AddressTagName);
        Helper.AddParentXmlNode(Format(Enum::"Address Type IRIS"::USAddress));

        Helper.FormatStreetAddress(StreetAddress, AddressLine1, AddressLine2);
        Helper.AppendXmlNode('AddressLine1Txt', AddressLine1);
        Helper.AppendXmlNode('AddressLine2Txt', AddressLine2);
        Helper.AppendXmlNode('CityNm', Helper.FormatCityName(CityName, Enum::"Address Type IRIS"::USAddress));
        Helper.MatchStateCode(StateCode, FormattedStateCode);
        Helper.AppendXmlNode('StateAbbreviationCd', FormattedStateCode);
        Helper.AppendXmlNode('ZIPCd', Helper.FormatZipCode(PostCode));

        Helper.CloseParentXmlNode();
        Helper.CloseParentXmlNode();
    end;

    local procedure AddForeignAddress(AddressTagName: Text; StreetAddress: Text; CityName: Text; ProvinceOrStateName: Text; FIPSCountryCode: Text; PostCode: Text)
    var
        AddressLine1: Text;
        AddressLine2: Text;
    begin
        Helper.AddParentXmlNode(AddressTagName);
        Helper.AddParentXmlNode(Format(Enum::"Address Type IRIS"::ForeignAddress));

        Helper.FormatStreetAddress(StreetAddress, AddressLine1, AddressLine2);
        Helper.AppendXmlNode('AddressLine1Txt', AddressLine1);
        Helper.AppendXmlNode('AddressLine2Txt', AddressLine2);
        Helper.AppendXmlNode('CityNm', Helper.FormatCityName(CityName, Enum::"Address Type IRIS"::ForeignAddress));
        Helper.AppendXmlNode('ProvinceOrStateNm', Helper.FormatText(ProvinceOrStateName, 17));
        Helper.AppendXmlNode('CountryCd', FIPSCountryCode);
        Helper.AppendXmlNode('ForeignPostalCd', Helper.FormatText(PostCode, 16));

        Helper.CloseParentXmlNode();
        Helper.CloseParentXmlNode();
    end;

    local procedure GetForeignEntityInd(CountryRegionCode: Code[10]) ForeignEntityInd: Text
    begin
        ForeignEntityInd := Helper.FormatBoolean(false);        // default is US
        if Helper.IsForeignCountryRegion(CountryRegionCode) then
            ForeignEntityInd := Helper.FormatBoolean(true);
    end;

    local procedure GetCorrectedInd(TransmissionTypeIRIS: Enum "Transmission Type IRIS") CorrectedInd: Text
    begin
        CorrectedInd := Helper.FormatBoolean(false);
        if TransmissionTypeIRIS = "Transmission Type IRIS"::"C" then
            CorrectedInd := Helper.FormatBoolean(true);
    end;

    local procedure GetTestFileIndicator(): Text[1]
    begin
        if IRSFormsFacade.TestMode() then
            exit('T');  // T for Test

        exit('P');  // P for Production
    end;

    local procedure GetTINSubmittedType(TaxIdentificationType: Enum "Tax Identification Type") TINTypeCd: Text
    begin
        case TaxIdentificationType of
            "Tax Identification Type"::"Legal Entity":
                TINTypeCd := 'BUSINESS_TIN';
            "Tax Identification Type"::"Natural Person":
                TINTypeCd := 'INDIVIDUAL_TIN';
        end;
    end;

    local procedure FilterIRSFormDocLines(var IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line"; var TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary)
    begin
        IRS1099FormDocLine.Reset();
        IRS1099FormDocLine.SetRange("Period No.", TempIRS1099FormDocHeader."Period No.");
        IRS1099FormDocLine.SetRange("Vendor No.", TempIRS1099FormDocHeader."Vendor No.");
        IRS1099FormDocLine.SetRange("Form No.", TempIRS1099FormDocHeader."Form No.");
        IRS1099FormDocLine.SetRange("Document ID", TempIRS1099FormDocHeader.ID);
        IRS1099FormDocLine.SetRange("Include In 1099", true);
    end;

    /// <summary>
    /// Returns distinct vendor numbers from the filtered temporary document headers.
    /// </summary>
    procedure GetVendorList(var TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary): List of [Text]
    var
        VendorNos: Dictionary of [Text, Text];
    begin
        if TempIRS1099FormDocHeader.FindSet() then
            repeat
                if VendorNos.Add(TempIRS1099FormDocHeader."Vendor No.", '') then;
            until TempIRS1099FormDocHeader.Next() = 0;

        exit(VendorNos.Keys());
    end;

    local procedure CalcFormTotalAmounts(var TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var TotalAmounts: Dictionary of [Text, Decimal])
    var
        DummyTotalReportedAmt: Decimal;
        DummyFederalIncomeTaxWithheldAmt: Decimal;
    begin
        CalcFormTotalAmounts(TempIRS1099FormDocHeader, TotalAmounts, DummyTotalReportedAmt, DummyFederalIncomeTaxWithheldAmt);
    end;

    local procedure CalcFormTotalAmounts(var TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var FormTotalAmounts: Dictionary of [Text, Decimal]; var TotalReportedAmt: Decimal; var FederalIncomeTaxWithheldAmt: Decimal)
    var
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        FederalIncomeTaxWithheldFormBoxes: Dictionary of [Text, Boolean];
        FormBoxNo: Code[20];
        LineAmount: Decimal;
    begin
        // totals must be calculated only for one form type (DIV / INT / MISC / NEC) and one tax year
        Clear(FormTotalAmounts);
        TotalReportedAmt := 0;
        FederalIncomeTaxWithheldAmt := 0;

        if not TempIRS1099FormDocHeader.FindSet() then
            exit;

        // get form boxes related to federal income tax withheld
        FederalIncomeTaxWithheldFormBoxes := Helper.GetFederalIncomeTaxWithheldFormBoxes(TempIRS1099FormDocHeader."Period No.");

        repeat
            FilterIRSFormDocLines(IRS1099FormDocLine, TempIRS1099FormDocHeader);
            if IRS1099FormDocLine.FindSet() then
                repeat
                    FormBoxNo := IRS1099FormDocLine."Form Box No.";
                    LineAmount := IRS1099FormDocLine.Amount;
                    if CorrectionToZeroModeGlobal then
                        LineAmount := 0;
                    if not FormTotalAmounts.ContainsKey(FormBoxNo) then
                        FormTotalAmounts.Add(FormBoxNo, 0);
                    FormTotalAmounts.Set(FormBoxNo, FormTotalAmounts.Get(FormBoxNo) + LineAmount);
                    if FederalIncomeTaxWithheldFormBoxes.ContainsKey(FormBoxNo) then
                        FederalIncomeTaxWithheldAmt += LineAmount
                    else
                        TotalReportedAmt += LineAmount;
                until IRS1099FormDocLine.Next() = 0;
        until TempIRS1099FormDocHeader.Next() = 0;
    end;

    local procedure GetFormBoxAmtXmlElemNamesAndValues(var TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary; FormTotalAmounts: Dictionary of [Text, Decimal]; var XmlElemNamesValues: Dictionary of [Text, Text])
    var
        IRS1099FormBox: Record "IRS 1099 Form Box";
        FormBoxAmtXmlElemNames: Dictionary of [Text, Text];
        FormBoxNo: Text;
        FormBoxAmt: Decimal;
        XmlElemName: Text;
        XmlElemValue: Text;
    begin
        // get xml element names for form boxes ('DIV-01' -> 'DividendIncomeAmt')
        FormBoxAmtXmlElemNames := Helper.GetFormBoxAmountXmlElementNames(TempIRS1099FormDocHeader."Period No.", TempIRS1099FormDocHeader."Form No.");

        foreach FormBoxNo in FormBoxAmtXmlElemNames.Keys() do begin
            FormBoxAmt := 0;
            if FormTotalAmounts.Get(FormBoxNo, FormBoxAmt) then;
            case FormBoxNo of
                'MISC-07', 'NEC-02':          // DirectSaleAboveThresholdInd
                    begin
                        IRS1099FormBox.Get(TempIRS1099FormDocHeader."Period No.", TempIRS1099FormDocHeader."Form No.", FormBoxNo);
                        XmlElemValue := Helper.FormatBoolean(FormBoxAmt >= IRS1099FormBox."Minimum Reportable Amount");
                    end;
                else
                    XmlElemValue := Helper.FormatDecimal(FormBoxAmt);
            end;
            XmlElemName := FormBoxAmtXmlElemNames.Get(FormBoxNo);
            if XmlElemNamesValues.Add(XmlElemName, XmlElemValue) then;
        end;
    end;

    local procedure GetFormTypeCode(FormNo: Code[20]): Text
    begin
        // 1099NEC, 1099MISC, 1099DIV, 1099INT etc.
        exit(StrSubstNo('%1%2', '1099', FormNo));
    end;

    local procedure GetForm1099TotalAmtGrpTagName(FormType: Enum "Form Type IRIS") TagName: Text
    begin
        // Form1099NECTotalAmtGrp etc.
        TagName := StrSubstNo(Form1099TotalAmtGrpTxt, GetFormTypeCode(Format(FormType)));
    end;

    local procedure GetForm1099DetailTagName(FormType: Enum "Form Type IRIS") TagName: Text
    begin
        // Form1099NECDetail etc.
        TagName := StrSubstNo(Form1099DetailTxt, GetFormTypeCode(Format(FormType)));
    end;

    local procedure InitSubmissionAndRecordIds(TransmissionDocumentID: Integer)
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        IRS1099FormDocHeader.SetLoadFields("IRIS Submission ID", "IRIS Record ID");
        IRS1099FormDocHeader.SetRange("IRIS Transmission Document ID", TransmissionDocumentID);
        if IRS1099FormDocHeader.FindSet() then
            repeat
                if IRS1099FormDocHeader."IRIS Submission ID" <> '' then
                    if UsedSubmissionIdsGlobal.Add(IRS1099FormDocHeader."IRIS Submission ID", 0) then;
                if IRS1099FormDocHeader."IRIS Record ID" <> '' then
                    if UsedRecordIdsGlobal.Add(IRS1099FormDocHeader."IRIS Record ID", 0) then;
            until IRS1099FormDocHeader.Next() = 0;

        SubmissionIdGlobal := 1;
        RecordIdGlobal := 1;
    end;

    local procedure GetNextSubmissionId(CurrSubmissionId: Text[20]): Text[20]
    begin
        TotalSubmissionCountGlobal += 1;

        if CurrSubmissionId <> '' then
            exit(CurrSubmissionId);

        while UsedSubmissionIdsGlobal.ContainsKey(Format(SubmissionIdGlobal)) do
            SubmissionIdGlobal += 1;
        if UsedSubmissionIdsGlobal.Add(Format(SubmissionIdGlobal), 0) then;
        exit(Format(SubmissionIdGlobal));
    end;

    local procedure GetNextRecordId(CurrRecordId: Text[20]): Text[20]
    begin
        TotalRecordCountGlobal += 1;

        if CurrRecordId <> '' then
            exit(CurrRecordId);

        while UsedRecordIdsGlobal.ContainsKey(Format(RecordIdGlobal)) do
            RecordIdGlobal += 1;
        if UsedRecordIdsGlobal.Add(Format(RecordIdGlobal), 0) then;
        exit(Format(RecordIdGlobal));
    end;

    local procedure GetMicrosoftData(var TIN: Text; var CompanyName: Text; var StreetAddress: Text; var CityName: Text; var StateCode: Text; var PostCode: Text; var ContactName: Text; var ContactEmail: Text; var ContactPhone: Text)
    begin
        TIN := '91-1144442';
        CompanyName := 'Microsoft';
        StreetAddress := 'One Microsoft Way';
        CityName := 'Redmond';
        StateCode := 'WA';
        PostCode := '98052';

        IRSFormsFacade.GetContactInfo(ContactName, ContactEmail, ContactPhone);
    end;

    /// <summary>
    /// Creates status-request XML for a receipt ID or unique transmission ID.
    /// </summary>
    procedure CreateGetStatusRequest(SearchParamType: Enum "Search Param Type IRIS"; SearchId: Text; var TempBlob: Codeunit "Temp Blob")
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if SearchId = '' then
            Error(EmptySearchIdErr);

        InitGetStatusDocElement();
        Helper.AppendXmlNode('TransmitterControlCd', IRSFormsFacade.GetTCC());
        Helper.AppendXmlNode('SearchTypeCd', 'S');      // S - Status request (status only)
        Helper.AppendXmlNode('SearchParameterTypeCd', Format(SearchParamType));
        Helper.AppendXmlNode('SearchId', SearchId);
        Helper.WriteXMLDocToTempBlob(TempBlob);

        CustomDimensions.Add('SearchTypeCd', 'S');
        CustomDimensions.Add('SearchParameterTypeCd', Format(SearchParamType));
        FeatureTelemetry.LogUsage('0000PAE', Helper.GetIRISFeatureName(), CreateGetStatusRequestEventTxt, CustomDimensions);
    end;

    /// <summary>
    /// Creates acknowledgment-request XML for a receipt ID or unique transmission ID.
    /// </summary>
    procedure CreateAcknowledgementRequest(SearchParamType: Enum "Search Param Type IRIS"; SearchId: Text; var TempBlob: Codeunit "Temp Blob")
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if SearchId = '' then
            Error(EmptySearchIdErr);

        InitGetStatusDocElement();
        Helper.AppendXmlNode('TransmitterControlCd', IRSFormsFacade.GetTCC());
        Helper.AppendXmlNode('SearchTypeCd', 'A');      // A - Acknowledgement request (status and errors)
        Helper.AppendXmlNode('SearchParameterTypeCd', Format(SearchParamType));
        Helper.AppendXmlNode('SearchId', SearchId);
        Helper.WriteXMLDocToTempBlob(TempBlob);

        CustomDimensions.Add('SearchTypeCd', 'A');
        CustomDimensions.Add('SearchParameterTypeCd', Format(SearchParamType));
        FeatureTelemetry.LogUsage('0000PAF', Helper.GetIRISFeatureName(), CreateAckRequestEventTxt);
    end;
}