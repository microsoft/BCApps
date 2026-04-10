// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;
using System.Reflection;
using System.Security.AccessControl;

/// <summary>
/// Maintains audit log of VAT registration number validations performed through external services.
/// Stores validation results, account details, and response data for compliance and reconciliation tracking.
/// </summary>
table 249 "VAT Registration Log"
{
    Caption = 'VAT Registration Log';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the VAT registration validation log entry.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        /// <summary>
        /// VAT registration number that was submitted for validation.
        /// </summary>
        field(2; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            NotBlank = true;
            ToolTip = 'Specifies the VAT registration number that you entered in the VAT Registration No. field on a customer, vendor, or contact card.';
        }
        /// <summary>
        /// Type of account (Customer, Vendor, Contact, Company Information) being validated.
        /// </summary>
        field(3; "Account Type"; Enum "VAT Registration Log Account Type")
        {
            Caption = 'Account Type';
            ToolTip = 'Specifies the account type of the customer or vendor whose VAT registration number is verified.';
        }
        /// <summary>
        /// Account number of the customer, vendor, or contact being validated.
        /// </summary>
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor;
            ToolTip = 'Specifies the account number of the customer or vendor whose VAT registration number is verified.';
        }
        /// <summary>
        /// Country or region code for the VAT registration being validated.
        /// </summary>
        field(5; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            NotBlank = true;
            TableRelation = "Country/Region".Code;
            ToolTip = 'Specifies the country/region of the address.';
        }
        /// <summary>
        /// User ID of the person who initiated the VAT registration validation.
        /// </summary>
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
        }
        /// <summary>
        /// Validation status indicating whether the VAT number is verified, valid, or invalid.
        /// </summary>
        field(10; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Not Verified,Valid,Invalid';
            OptionMembers = "Not Verified",Valid,Invalid;
            ToolTip = 'Specifies the status of the verification action.';
        }
        /// <summary>
        /// Company or entity name returned by the VAT registration validation service.
        /// </summary>
        field(11; "Verified Name"; Text[150])
        {
            Caption = 'Verified Name';
            ToolTip = 'Specifies the name of the customer, vendor, or contact whose VAT registration number was verified.';
        }
        /// <summary>
        /// Full address returned by the VAT registration validation service.
        /// </summary>
        field(12; "Verified Address"; Text[150])
        {
            Caption = 'Verified Address';
            ToolTip = 'Specifies the address of the customer, vendor, or contact whose VAT registration number was verified.';
        }
        /// <summary>
        /// Date and time when the VAT registration validation was performed.
        /// </summary>
        field(13; "Verified Date"; DateTime)
        {
            Caption = 'Verified Date';
            ToolTip = 'Specifies when the VAT registration number was verified.';
        }
        /// <summary>
        /// Unique request identifier returned by the VAT registration validation service.
        /// </summary>
        field(14; "Request Identifier"; Text[200])
        {
            Caption = 'Request Identifier';
            ToolTip = 'Specifies the request identifier of the VAT registration number validation service.';
        }
        /// <summary>
        /// Street address component returned by the VAT registration validation service.
        /// </summary>
        field(15; "Verified Street"; Text[50])
        {
            Caption = 'Verified Street';
            ToolTip = 'Specifies the street of the customer, vendor, or contact whose VAT registration number was verified. ';
        }
        /// <summary>
        /// Postal code component returned by the VAT registration validation service.
        /// </summary>
        field(16; "Verified Postcode"; Text[20])
        {
            Caption = 'Verified Postcode';
            ToolTip = 'Specifies the postcode of the customer, vendor, or contact whose VAT registration number was verified. ';
        }
        /// <summary>
        /// City component returned by the VAT registration validation service.
        /// </summary>
        field(17; "Verified City"; Text[30])
        {
            Caption = 'Verified City';
            ToolTip = 'Specifies the city of the customer, vendor, or contact whose VAT registration number was verified. ';
        }
        /// <summary>
        /// Overall status of detailed field-by-field validation results.
        /// </summary>
        field(18; "Details Status"; Enum "VAT Reg. Log Details Status")
        {
            Caption = 'Details Status';
            ToolTip = 'Specifies the status of the details validation.';
        }
        /// <summary>
        /// VAT registration service template used for this validation request.
        /// </summary>
        field(19; "Template"; Code[20])
        {
            Caption = 'Template';
            TableRelation = "VAT Reg. No. Srv. Template";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Country/Region Code", "VAT Registration No.", Status)
        {
        }
    }

    var
        VATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template";
        AccountName: Text;
        AccountStreet: Text;
        AccountCity: Text;
        AccountPostCode: Text;
        ResponseName: Text;
        ResponseAddress: Text;
        ResponseStreet: Text;
        ResponsePostCode: Text;
        ResponseCity: Text;
        NameMatch: Boolean;
        StreetMatch: Boolean;
        CityMatch: Boolean;
        PostCodeMatch: Boolean;
        CustomerUpdatedMsg: Label 'The customer has been updated.';
        VendorUpdatedMsg: Label 'The vendor has been updated.';
        ContactUpdatedMsg: Label 'The contact has been updated.';
        CompInfoUpdatedMsg: Label 'The company information has been updated.';

    /// <summary>
    /// Retrieves the country/region code for VAT validation, using EU country code when available.
    /// </summary>
    /// <returns>Country/region code or EU country code for validation purposes</returns>
    procedure GetCountryCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        if "Country/Region Code" = '' then begin
            if not CompanyInformation.Get() then
                exit('');
            exit(CompanyInformation."Country/Region Code");
        end;
        CountryRegion.Get("Country/Region Code");
        if CountryRegion."EU Country/Region Code" = '' then
            exit("Country/Region Code");
        exit(CountryRegion."EU Country/Region Code");
    end;

    /// <summary>
    /// Normalizes and retrieves the VAT registration number by removing country prefix and non-alphanumeric characters.
    /// </summary>
    /// <returns>Cleaned VAT registration number without country code prefix</returns>
    procedure GetVATRegNo(): Code[20]
    var
        VatRegNo: Code[20];
    begin
        VatRegNo := UpperCase("VAT Registration No.");
        VatRegNo := DelChr(VatRegNo, '=', DelChr(VatRegNo, '=', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'));
        if StrPos(VatRegNo, UpperCase(GetCountryCode())) = 1 then
            VatRegNo := DelStr(VatRegNo, 1, StrLen(GetCountryCode()));
        exit(VatRegNo);
    end;

    /// <summary>
    /// Initializes a new VAT registration log entry with specified account details and validation parameters.
    /// </summary>
    /// <param name="VATRegistrationLog">VAT registration log record to initialize</param>
    /// <param name="CountryCode">Country/region code for the validation</param>
    /// <param name="AcountType">Account type (Customer, Vendor, Contact, Company Information)</param>
    /// <param name="AccountNo">Account number being validated</param>
    /// <param name="VATRegNo">VAT registration number to validate</param>
    procedure InitVATRegLog(var VATRegistrationLog: Record "VAT Registration Log"; CountryCode: Code[10]; AcountType: Option; AccountNo: Code[20]; VATRegNo: Text[20])
    begin
        VATRegistrationLog.Init();
        VATRegistrationLog."Account Type" := "VAT Registration Log Account Type".FromInteger(AcountType);
        VATRegistrationLog."Account No." := AccountNo;
        VATRegistrationLog."Country/Region Code" := CountryCode;
        VATRegistrationLog."VAT Registration No." := VATRegNo;
        OnAfterInitVATRegLog(VATRegistrationLog, CountryCode, AcountType, AccountNo, VATRegNo);
    end;

    /// <summary>
    /// Opens the VAT registration details modification interface and applies accepted changes to the source record.
    /// Handles updates for Customer, Vendor, and Contact records with appropriate integration updates.
    /// </summary>
    procedure OpenModifyDetails()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        CustContUpdate: Codeunit "CustCont-Update";
        VendContUpdate: Codeunit "VendCont-Update";
        UpdateCustVendBank: Codeunit "CustVendBank-Update";
        RecordRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenModifyDetails(Rec, IsHandled);
        if IsHandled then
            exit;

        GetAccountRecordRef(RecordRef);
        if OpenDetailsForRecRef(RecordRef) then begin
            RecordRef.Modify();
            case RecordRef.Number of
                Database::Customer:
                    begin
                        RecordRef.SetTable(Customer);
                        CustContUpdate.OnModify(Customer);
                    end;
                Database::Vendor:
                    begin
                        RecordRef.SetTable(Vendor);
                        VendContUpdate.OnModify(Vendor);
                    end;
                Database::Contact:
                    begin
                        RecordRef.SetTable(Contact);
                        UpdateCustVendBank.Run(Contact);
                    end;
            end;
        end;
    end;

    /// <summary>
    /// Opens VAT registration log details page for the specified record and applies accepted validation changes.
    /// </summary>
    /// <param name="RecordRef">Record reference to the account being validated</param>
    /// <returns>True if changes were applied to the record, false otherwise</returns>
    procedure OpenDetailsForRecRef(var RecordRef: RecordRef): Boolean
    var
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        if GuiAllowed() and ("Details Status" <> "Details Status"::"Not Verified") then begin
            VATRegistrationLogDetails.SetRange("Log Entry No.", "Entry No.");
            Page.RunModal(Page::"VAT Registration Log Details", VATRegistrationLogDetails);
            exit(ApplyDetailsChanges(RecordRef));
        end;
    end;

    local procedure ApplyDetailsChanges(var RecordRef: RecordRef) Result: Boolean
    var
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
        Customer: Record Customer;
    begin
        VATRegistrationLogDetails.SetRange("Log Entry No.", "Entry No.");
        VATRegistrationLogDetails.SetRange(Status, VATRegistrationLogDetails.Status::Accepted);
        Result := VATRegistrationLogDetails.FindSet();
        if Result then begin
            repeat
                case VATRegistrationLogDetails."Field Name" of
                    VATRegistrationLogDetails."Field Name"::Name:
                        ValidateField(RecordRef, Customer.FieldName(Name), VATRegistrationLogDetails.Response);
                    VATRegistrationLogDetails."Field Name"::Address:
                        ValidateField(RecordRef, Customer.FieldName(Address), VATRegistrationLogDetails.Response);
                    VATRegistrationLogDetails."Field Name"::Street:
                        ValidateField(RecordRef, Customer.FieldName(Address), VATRegistrationLogDetails.Response);
                    VATRegistrationLogDetails."Field Name"::City:
                        ValidateField(RecordRef, Customer.FieldName(City), VATRegistrationLogDetails.Response);
                    VATRegistrationLogDetails."Field Name"::"Post Code":
                        ValidateField(RecordRef, Customer.FieldName("Post Code"), VATRegistrationLogDetails.Response);
                end;
            until VATRegistrationLogDetails.Next() = 0;
            VATRegistrationLogDetails.ModifyAll(Status, VATRegistrationLogDetails.Status::Applied);
            ShowDetailsUpdatedMessage(RecordRef.Number());
        end;
    end;

    local procedure ShowDetailsUpdatedMessage(TableID: Integer);
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDetailsUpdatedMessage(TableID, IsHandled);
        if IsHandled then
            exit;

        if GuiAllowed() then
            case TableID of
                Database::Customer:
                    Message(CustomerUpdatedMsg);
                Database::Vendor:
                    Message(VendorUpdatedMsg);
                Database::Contact:
                    Message(ContactUpdatedMsg);
                Database::"Company Information":
                    Message(CompInfoUpdatedMsg);
            end;
    end;

    local procedure ValidateField(var RecordRef: RecordRef; FieldName: Text; Value: Text)
    var
        ConfigValidateManagement: Codeunit "Config. Validate Management";
        DataTypeManagement: Codeunit "Data Type Management";
        FieldRef: FieldRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateField(RecordRef, FieldName, Value, IsHandled);
        if IsHandled then
            exit;

        if DataTypeManagement.FindFieldByName(RecordRef, FieldRef, FieldName) then
            ConfigValidateManagement.EvaluateValueWithValidate(FieldRef, CopyStr(Value, 1, FieldRef.Length()), false);
    end;

    /// <summary>
    /// Retrieves the record reference for the account associated with this VAT registration log entry.
    /// </summary>
    /// <param name="RecordRef">Record reference to be populated with the account record</param>
    /// <returns>True if the account record was successfully retrieved, false otherwise</returns>
    procedure GetAccountRecordRef(var RecordRef: RecordRef) Result: Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        CompanyInformation: Record "Company Information";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetAccountRecordRef(Rec, RecordRef, IsHandled, Result);
        if IsHandled then
            exit(Result);

        Clear(RecordRef);
        case "Account Type" of
            "Account Type"::Customer:
                if Customer.Get("Account No.") then
                    RecordRef.GetTable(Customer);
            "Account Type"::Vendor:
                if Vendor.Get("Account No.") then
                    RecordRef.GetTable(Vendor);
            "Account Type"::Contact:
                if Contact.Get("Account No.") then
                    RecordRef.GetTable(Contact);
            "Account Type"::"Company Information":
                if CompanyInformation.Get() then
                    RecordRef.GetTable(CompanyInformation);
        end;

        exit(RecordRef.Number <> 0);
    end;

    /// <summary>
    /// Sets account details from the current system record for comparison during validation.
    /// </summary>
    /// <param name="Name">Account name from the system record</param>
    /// <param name="Street">Street address from the system record</param>
    /// <param name="City">City from the system record</param>
    /// <param name="PostCode">Postal code from the system record</param>
    procedure SetAccountDetails(Name: Text; Street: Text; City: Text; PostCode: Text)
    begin
        AccountName := Name;
        AccountStreet := Street;
        AccountCity := City;
        AccountPostCode := PostCode;
    end;

    /// <summary>
    /// Sets response details received from the VAT registration validation service for comparison and storage.
    /// </summary>
    /// <param name="Name">Company/entity name returned by the validation service</param>
    /// <param name="Address">Full address returned by the validation service</param>
    /// <param name="Street">Street address component returned by the validation service</param>
    /// <param name="City">City component returned by the validation service</param>
    /// <param name="PostCode">Postal code component returned by the validation service</param>
    procedure SetResponseDetails(Name: Text; Address: Text; Street: Text; City: Text; PostCode: Text)
    begin
        ResponseName := Name;
        ResponseAddress := Address;
        ResponseStreet := Street;
        ResponseCity := City;
        ResponsePostCode := PostCode;

        "Verified Name" := CopyStr(ResponseName, 1, MaxStrLen("Verified Name"));
        "Verified Address" := CopyStr(ResponseAddress, 1, MaxStrLen("Verified Address"));
        "Verified Street" := CopyStr(ResponseStreet, 1, MaxStrLen("Verified Street"));
        "Verified City" := CopyStr(ResponseCity, 1, MaxStrLen("Verified City"));
        "Verified Postcode" := CopyStr(ResponsePostCode, 1, MaxStrLen("Verified Postcode"));
    end;

    /// <summary>
    /// Sets the match results for individual field comparisons between system values and validation service responses.
    /// </summary>
    /// <param name="Name">True if company name matches between system and service response</param>
    /// <param name="Street">True if street address matches between system and service response</param>
    /// <param name="City">True if city matches between system and service response</param>
    /// <param name="PostCode">True if postal code matches between system and service response</param>
    procedure SetResponseMatchDetails(Name: Boolean; Street: Boolean; City: Boolean; PostCode: Boolean)
    begin
        NameMatch := Name;
        StreetMatch := Street;
        CityMatch := City;
        PostCodeMatch := PostCode;
    end;

    /// <summary>
    /// Creates detailed log entries for field-by-field validation results and calculates overall validation status.
    /// </summary>
    /// <returns>True if detailed logging was successful, false otherwise</returns>
    procedure LogDetails(): Boolean
    var
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
        TotalCount: Integer;
        ValidCount: Integer;
    begin
        CheckGetTemplate(VATRegNoSrvTemplate);

        LogDetail(
          TotalCount, ValidCount, VATRegistrationLogDetails."Field Name"::Name, VATRegNoSrvTemplate."Validate Name",
          NameMatch, AccountName, ResponseName);
        LogDetail(
          TotalCount, ValidCount, VATRegistrationLogDetails."Field Name"::Address, false, false, AccountStreet, ResponseAddress);
        LogDetail(
          TotalCount, ValidCount, VATRegistrationLogDetails."Field Name"::Street, VATRegNoSrvTemplate."Validate Street",
          StreetMatch, AccountStreet, ResponseStreet);
        LogDetail(
          TotalCount, ValidCount, VATRegistrationLogDetails."Field Name"::City, VATRegNoSrvTemplate."Validate City",
          CityMatch, AccountCity, ResponseCity);
        LogDetail(
          TotalCount, ValidCount, VATRegistrationLogDetails."Field Name"::"Post Code", VATRegNoSrvTemplate."Validate Post Code",
          PostCodeMatch, AccountPostCode, ResponsePostCode);

        if TotalCount > 0 then
            if VATRegNoSrvTemplate."Ignore Details" then
                "Details Status" := "Details Status"::Ignored
            else
                if TotalCount = ValidCount then
                    "Details Status" := "Details Status"::Valid
                else
                    if ValidCount > 0 then
                        "Details Status" := "Details Status"::"Partially Valid"
                    else
                        "Details Status" := "Details Status"::"Not Valid";

        exit(TotalCount > 0);
    end;

    local procedure LogDetail(var TotalCount: Integer; var ValidCount: Integer; FieldName: Enum "VAT Reg. Log Details Field"; IsRequested: Boolean; IsMatched: Boolean; CurrentValue: Text; ResponseValue: Text)
    var
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        if not IsRequested and (ResponseValue = '') then
            exit;

        InitVATRegistrationLogDetailsFromRec(VATRegistrationLogDetails, FieldName, CurrentValue);

        if IsRequested then begin
            VATRegistrationLogDetails.Requested := VATRegistrationLogDetails."Current Value";
            if CurrentValue <> ResponseValue then
                VATRegistrationLogDetails.Response := CopyStr(ResponseValue, 1, MaxStrLen(VATRegistrationLogDetails.Response));
        end else
            if ResponseValue <> '' then
                VATRegistrationLogDetails.Response := CopyStr(ResponseValue, 1, MaxStrLen(VATRegistrationLogDetails.Response));

        if IsMatched or
           (VATRegistrationLogDetails."Current Value" = VATRegistrationLogDetails.Response) and
           (VATRegistrationLogDetails.Response <> '')
        then
            VATRegistrationLogDetails.Status := VATRegistrationLogDetails.Status::Valid;
        VATRegistrationLogDetails.Insert();

        TotalCount += 1;
        if VATRegistrationLogDetails.Status = VATRegistrationLogDetails.Status::Valid then
            ValidCount += 1;
    end;

    local procedure InitVATRegistrationLogDetailsFromRec(var VATRegistrationLogDetails: Record "VAT Registration Log Details"; FieldName: Enum "VAT Reg. Log Details Field"; CurrentValue: Text)
    begin
        VATRegistrationLogDetails.Init();
        VATRegistrationLogDetails."Log Entry No." := "Entry No.";
        VATRegistrationLogDetails."Account Type" := "Account Type";
        VATRegistrationLogDetails."Account No." := "Account No.";
        VATRegistrationLogDetails.Status := VATRegistrationLogDetails.Status::"Not Valid";
        VATRegistrationLogDetails."Field Name" := FieldName;
        VATRegistrationLogDetails."Current Value" := CopyStr(CurrentValue, 1, MaxStrLen(VATRegistrationLogDetails.Requested));
    end;

    /// <summary>
    /// Retrieves the appropriate VAT registration service template for validation operations.
    /// </summary>
    /// <param name="VATRegNoSrvTemplateLcl">VAT registration service template record to populate</param>
    procedure CheckGetTemplate(var VATRegNoSrvTemplateLcl: Record "VAT Reg. No. Srv. Template")
    begin
        if Template = '' then
            Template := VATRegNoSrvTemplate.FindTemplate(Rec);
        VATRegNoSrvTemplateLcl := VATRegNoSrvTemplate;
    end;

    /// <summary>
    /// Integration event raised before validating a field value during detail updates.
    /// </summary>
    /// <param name="RecordRef">Record reference being updated</param>
    /// <param name="FieldName">Name of the field being validated</param>
    /// <param name="Value">Value being set on the field</param>
    /// <param name="IsHandled">Set to true to skip standard field validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateField(var RecordRef: RecordRef; FieldName: Text; var Value: Text; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before showing the details updated message to allow custom messaging.
    /// </summary>
    /// <param name="TableId">Table ID of the record that was updated</param>
    /// <param name="IsHandled">Set to true to skip standard message display</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDetailsUpdatedMessage(TableId: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before opening the modify details interface to allow custom handling.
    /// </summary>
    /// <param name="VATRegistrationLog">VAT registration log record being processed</param>
    /// <param name="IsHandled">Set to true to skip standard details modification process</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenModifyDetails(var VATRegistrationLog: Record "VAT Registration Log"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after initializing a VAT registration log entry to allow custom field population.
    /// </summary>
    /// <param name="VATRegistrationLog">VAT registration log record that was initialized</param>
    /// <param name="CountryCode">Country/region code used for initialization</param>
    /// <param name="AcountType">Account type used for initialization</param>
    /// <param name="AccountNo">Account number used for initialization</param>
    /// <param name="VATRegNo">VAT registration number used for initialization</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitVATRegLog(var VATRegistrationLog: Record "VAT Registration Log"; CountryCode: Code[10]; AcountType: Option; AccountNo: Code[20]; VATRegNo: Text[20])
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving the account record reference to allow custom record retrieval logic.
    /// </summary>
    /// <param name="VATRegistrationLog">VAT registration log record being processed</param>
    /// <param name="RecordRef">Record reference to be populated with the account record</param>
    /// <param name="IsHandled">Set to true to skip standard record retrieval</param>
    /// <param name="Result">Set to true if custom record retrieval was successful</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAccountRecordRef(var VATRegistrationLog: Record "VAT Registration Log"; var RecordRef: RecordRef; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;
}

