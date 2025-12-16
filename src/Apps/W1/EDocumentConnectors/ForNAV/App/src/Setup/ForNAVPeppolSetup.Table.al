// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.eServices.EDocument;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using System.Automation;
using System.EMail;
using System.Environment;
using System.Globalization;
table 6414 "ForNAV Peppol Setup"
{
    DataClassification = CustomerContent;
    Caption = 'ForNAV Peppol Setup';

    fields
    {
        field(1; PK; Guid)
        {
            Caption = 'PK';
            DataClassification = SystemMetadata;
            Access = Internal;
        }

        field(2; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the company.';
            NotBlank = true;
            Editable = false;
            DataClassification = CustomerContent;
            Access = Internal;
        }
        field(7; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
            Editable = false;
            DataClassification = CustomerContent;
            Access = Internal;
        }
        field(8; TermsAccepted; Boolean)
        {
            Caption = 'Terms accepted';
            DataClassification = EndUserPseudonymousIdentifiers;
            Access = Internal;
        }
        field(9; Authorized; Boolean)
        {
            Caption = 'Authenticated';
            ToolTip = 'Specifies if the Oauth setup has been tested.';
            DataClassification = EndUserPseudonymousIdentifiers;
            Access = Internal;
        }
        field(10; "Client Id"; Text[100])
        {
            Caption = 'Client Id';
            ToolTip = 'Specifies the Oauth Client Id. You can get this from your ForNAV partner.';
            DataClassification = EndUserPseudonymousIdentifiers;
            Access = Internal;

            trigger OnValidate()
            var
                PeppolOauth: Codeunit "ForNAV Peppol Oauth";
            begin
                if not IsTemporary() then
                    PeppolOauth.ValidateClientID("Client Id");
            end;
        }
        field(17; "Oauth Setup Request Sent"; Date)
        {
            Caption = 'Oauth Setup Request Sent';
            DataClassification = SystemMetadata;
            Access = Internal;
        }
        field(34; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;
            NotBlank = true;
            Editable = false;
            DataClassification = CustomerContent;
            Access = Internal;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
#pragma warning disable AA0139
                MailManagement.ValidateEmailAddressField("E-Mail");
#pragma warning restore AA0139
            end;
        }
        field(35; "Home Page"; Text[255])
        {
            Caption = 'Home Page';
            ToolTip = 'Specifies the home page of the company.';
            ExtendedDatatype = URL;
            NotBlank = true;
            Editable = false;
            DataClassification = CustomerContent;
            Access = Internal;
        }
        field(36; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            ToolTip = 'Specifies the country/region code of the company.';
            TableRelation = "Country/Region";
            NotBlank = true;
            Editable = false;
            DataClassification = CustomerContent;
            Access = Internal;
        }

        field(50; "Add contact information"; Boolean)
        {
            Caption = 'Add contact information to business card';
            DataClassification = CustomerContent;
            Access = Internal;
        }

        field(51; "Contact Person"; Text[50])
        {
            Caption = 'Contact Person';
            NotBlank = true;
            Editable = false;
            DataClassification = CustomerContent;
            Access = Internal;
        }
        field(80; "E-Document Service"; Code[20])
        {
            Caption = 'E-Document Service';
            ToolTip = 'Specifies the E-Document Service to use for the company.';
            TableRelation = "E-Document Service" where("Service Integration V2" = const(FORNAV));
            DataClassification = CustomerContent;
            Access = Internal;
        }
        field(81; "Document Sending Profile"; Code[20])
        {
            Caption = 'Document Sending Profile';
            ToolTip = 'Specifies the Document Sending Profile to use for the company.';
            TableRelation = "Document Sending Profile" where("Electronic Document" = const("Extended E-Document Service Flow"));
            DataClassification = CustomerContent;
            Access = Internal;
        }
        field(102; Status; Option)
        {
            OptionMembers = "Not published","Published","Published in another company or installation",Offline,Unlicensed,"Published by another AP","Waiting for approval","Published by ForNAV using another AAD tenant";
            OptionCaption = 'Not Published,Published,Published in another company or installation,Offline,Unlicensed,Published by another access point,Waiting for approval by ForNAV,Published by ForNAV using another AAD tenant';
            DataClassification = CustomerContent;
            Access = Internal;
        }
        field(103; "Demo Company"; Boolean)
        {
            Caption = 'Demo Company';
            DataClassification = SystemMetadata;
            Access = Internal;
        }
        field(999; Test; Boolean)
        {
            Caption = 'Test';
            ToolTip = 'Specifies if the setup is for testing purposes.';
            DataClassification = CustomerContent;
            Access = Internal;
        }
        field(1000; "Identification Code"; Code[10])
        {
            Caption = 'Identification Code';
            ToolTip = 'Specifies the Identification Code.';
            DataClassification = CustomerContent;
            NotBlank = true;
            Editable = false;
            Access = Internal;
        }
        field(1001; "Identification Value"; Text[50])
        {
            Caption = 'Identification Value';
            ToolTip = 'Specifies the Identification Value.';
            DataClassification = CustomerContent;
            NotBlank = true;
            Editable = false;
            Access = Internal;
        }

        field(1003; Address; Text[500])
        {
            Caption = 'Address';
            ToolTip = 'Specifies the address of the company.';
            DataClassification = CustomerContent;
            NotBlank = true;
            Editable = false;
            Access = Internal;
        }

        field(1004; "Language"; Text[2])
        {
            Caption = 'Language';
            ToolTip = 'Specifies the two letter ISO 639-1 language code';
            DataClassification = CustomerContent;
            NotBlank = true;
            Editable = false;
            Access = Internal;
            trigger OnValidate()
            begin
                Language := Language.ToLower();
            end;
        }
        field(1100; PublishMsg; Blob)
        {
            Caption = 'Address';
            DataClassification = CustomerContent;
            Access = Internal;
        }

        field(1101; SetupNotification; Blob)
        {
            Caption = 'Address';
            DataClassification = CustomerContent;
            Access = Internal;
        }
        field(1102; SetupNotificationUrl; Text[50])
        {
            Caption = 'SetupNotificationUrl';
            DataClassification = CustomerContent;
            Access = Internal;
        }
    }

    keys
    {
        key(PK; PK)
        {
            Clustered = true;
        }
    }

    var
        CannotGetSetupErr: Label 'Cannot get setup from Peppol API. Contact your ForNAV partner.';

    internal procedure SetValues(ValuesObject: JsonObject)
    var
        ValueText: BigText;
        ValueKey: Text;
        ValueToken: JsonToken;
        OutStr: OutStream;
    begin
        foreach ValueKey in ValuesObject.Keys do begin
            ValuesObject.Get(ValueKey, ValueToken);
            Clear(ValueText);
            ValueText.AddText(ValueToken.AsValue().AsText());
            case ValueKey of
                'publishmsg':
                    begin
                        PublishMsg.CreateOutStream(OutStr, TextEncoding::UTF8);
                        ValueText.Write(OutStr);
                    end;
                'setupnotification':
                    begin
                        SetupNotification.CreateOutStream(OutStr, TextEncoding::UTF8);
                        ValueText.Write(OutStr);
                    end;
                'setupnotificationurl':
                    SetupNotificationUrl := CopyStr(ValueToken.AsValue().AsText(), 1, MaxStrLen((SetupNotificationUrl)));
            end;
        end;
    end;

    internal procedure GetSetupNotification(): Text;
    var
        ValueText: BigText;
        InStr: InStream;
    begin
        if SetupNotification.HasValue then begin
            Rec.CalcFields(SetupNotification);
            SetupNotification.CreateInStream(InStr, TextEncoding::UTF8);
            ValueText.Read(InStr);
        end;
        exit(Format(ValueText));
    end;

    internal procedure GetPublishMsg(): Text;
    var
        ValueText: BigText;
        InStr: InStream;
    begin
        if PublishMsg.HasValue then begin
            Rec.CalcFields(PublishMsg);
            PublishMsg.CreateInStream(InStr, TextEncoding::UTF8);
            ValueText.Read(InStr);
        end;
        exit(Format(ValueText));
    end;

    internal procedure SetupOauth()
    var
        Setup: Codeunit "ForNAV Peppol Setup";
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
        EnvironmentInformation: Codeunit "Environment Information";
        IsSaaS: Boolean;
    begin
        Setup.ClearAccessToken();
        if PeppolOauth.GetClientID() <> '' then
            if PeppolOauth.TestOAuth() then begin
                Authorized := true;
                Modify();
                exit;
            end;

        ResetForSetup();
        PeppolOauth.SetSetupKey();
        IsSaaS := EnvironmentInformation.IsSaaS();

        Commit();

        if not PeppolOauth.SendSetupRequest(IsSaas) then
            Error(CannotGetSetupErr);

        SelectLatestVersion();
        FindFirst();
        "Oauth Setup Request Sent" := Today();
        Modify();

        if IsSaaS then
            ValidateConnection();
    end;

    internal procedure ProcessStoredOauthRequest(PassCode: SecretText)
    var
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
    begin
        if not PeppolOauth.GetSetupFile(PassCode, "Identification Value") then
            Error(CannotGetSetupErr);

        ValidateConnection();
    end;

    internal procedure RotateClientSecret()
    var
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
    begin
        if PeppolOauth.GetSecretValidFrom() > CreateDateTime(CalcDate('<-1w>', Today), Time) then
            exit;

        PeppolOauth.GetNewSecurityKey();
        ValidateConnection();
    end;

    local procedure ValidateConnection()
    var
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
    begin
        if PeppolOauth.TestOAuth() then begin
            Authorized := true;
            PeppolOauth.ResetSetupKey();
        end else
            Authorized := false;

        Modify();
    end;

    internal procedure ResetForSetup()
    var
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
    begin
        PeppolOauth.ResetForSetup();
        Clear("Oauth Setup Request Sent");
        Authorized := false;
        Modify();
    end;

    internal procedure UpdateFromCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        WindowsLanguage: Record "Windows Language";
        Country: Record "Country/Region";
        Addr: Text;
    begin
        CompanyInformation.Get();
        if CompanyInformation."Use GLN in Electronic Document" then begin
            "Identification Code" := '0088';
            "Identification Value" := CompanyInformation.GLN;
        end else begin
            if Country.Get(CompanyInformation.GetCompanyCountryRegionCode()) then;
            "Identification Code" := Country."VAT Scheme";
            "Identification Value" := CompanyInformation."VAT Registration No.";
        end;

        "Identification Value" := CompanyInformation."VAT Registration No.";

        Name := CompanyInformation.Name;
        "Phone No." := CompanyInformation."Phone No.";
        "E-mail" := CompanyInformation."E-Mail";
#pragma warning disable AL0432
        "Home Page" := CopyStr(CompanyInformation."Home Page", 1, MaxStrLen("Home Page"));
#pragma warning restore AL0432
        "Country/Region Code" := CompanyInformation."Country/Region Code";
        "Contact Person" := CompanyInformation."Contact Person";

        Addr := CompanyInformation.Address;
        if CompanyInformation."Address 2" <> '' then
            Addr += ', ' + CompanyInformation."Address 2";
        if CompanyInformation.County <> '' then
            Addr += ', ' + CompanyInformation.County;
        Addr += ', ' + CompanyInformation."Post Code" + ' ' + CompanyInformation.City;
        Address := CopyStr(Addr, 1, MaxStrLen(Address));
        WindowsLanguage.Get(System.WindowsLanguage);
        Rec.Language := WindowsLanguage."Language Tag".Substring(1, 2);
    end;

    internal procedure InitSetup()
    var
        CompanyInformation: Record "Company Information";
    begin
        if not FindFirst() then begin
            Rec.PK := CreateGuid();
            Rec."E-Document Service" := GetForNAVCode();
            Rec."Document Sending Profile" := GetForNAVCode();
            SetupDocumentSendingProfile();
            UpdateFromCompanyInformation();
            CompanyInformation.Get();
            Rec."Demo Company" := CompanyInformation."Demo Company";
            Rec.Test := Rec."Demo Company";
            Rec.Insert();
        end;
    end;

    local procedure SetupDocumentSendingProfile()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        if EDocumentService.Get("E-Document Service") then
            exit;

        EDocumentService.Code := "E-Document Service";
        EDocumentService.Description := 'ForNAV Service';
        EDocumentService."Service Integration V2" := EDocumentService.ForNAVServiceIntegration();
        EDocumentService."Document Format" := "E-Document Format"::"PEPPOL BIS 3.0";
        EDocumentService."Use Batch Processing" := false;
        EDocumentService.Insert();

        EDocServiceSupportedType.SetRange(EDocServiceSupportedType."E-Document Service Code", EDocumentService.Code);
        EDocServiceSupportedType.DeleteAll();
        EDocServiceSupportedType."E-Document Service Code" := EDocumentService.Code;
        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Sales Invoice";
        EDocServiceSupportedType.Insert();
        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Sales Credit Memo";
        EDocServiceSupportedType.Insert();

        if DocumentSendingProfile.Get("Document Sending Profile") then
            exit;

        DocumentSendingProfile.Code := "Document Sending Profile";
        DocumentSendingProfile.Description := 'ForNAV eDocument';
        DocumentSendingProfile."Electronic Format" := 'PEPPOL BIS3';
        DocumentSendingProfile."Electronic Document" := "Doc. Sending Profile Elec.Doc."::"Extended E-Document Service Flow";
        DocumentSendingProfile."Electronic Service Flow" := GetForNAVCode();
        DocumentSendingProfile.Insert();

        if Workflow.Get(GetForNAVCode()) then
            Workflow.Delete();

        Workflow.Code := GetForNAVCode();
        Workflow.Description := 'ForNAV eDocument workflow';
        Workflow.Category := 'EDOC';
        Workflow.Enabled := true;
        Workflow.Insert();

        WorkflowStep.SetRange("Workflow Code", GetForNAVCode());
        WorkflowStep.DeleteAll();
        WorkflowStep.Init();
        WorkflowStep."Sequence No." := 1;
        WorkflowStep."Workflow Code" := GetForNAVCode();
        WorkflowStep.Type := WorkflowStep.Type::"Event";
        WorkflowStep."Function Name" := 'EDOCCREATEDEVENT';
        WorkflowStep."Entry Point" := true;
        WorkflowStep.Insert();

        WorkflowStep."Previous Workflow Step ID" := WorkflowStep.ID;
        WorkflowStep.ID += 1;
        WorkflowStep."Sequence No." := 0;
        WorkflowStep."Workflow Code" := GetForNAVCode();
        WorkflowStep.Type := WorkflowStep.Type::"Response";
        WorkflowStep."Function Name" := 'EDOCSENDEDOCRESPONSE';
        WorkflowStep."Entry Point" := false;

        WorkflowStepArgument.SetRange("Response Function Name", 'EDOCSENDEDOCRESPONSE');
        WorkflowStepArgument.SetRange("E-Document Service", GetForNAVCode());
        WorkflowStepArgument.DeleteAll();

        WorkflowStepArgument.Init();
        WorkflowStepArgument."Table No." := Database::"E-Document";
        WorkflowStepArgument."Response Function Name" := 'EDOCSENDEDOCRESPONSE';
        WorkflowStepArgument."E-Document Service" := GetForNAVCode();
        WorkflowStepArgument.ID := CreateGuid();
        WorkflowStepArgument.Insert();

        WorkflowStep.Argument := WorkflowStepArgument.ID;
        WorkflowStep.Insert();
    end;

    internal procedure PeppolId(): Text
    begin
        exit(Rec."Identification Code" + ':' + Rec."Identification Value");
    end;

    internal procedure IsTest(): Boolean
    begin
        exit(Test);
    end;

    internal procedure CreateBusinessEntity() BusinessEntityObject: JsonObject;
    begin
        BusinessEntityObject.Add('ParticipantIdentifier', PeppolId());
        BusinessEntityObject.Add('Name', Name);
        BusinessEntityObject.Add('CountryCode', "Country/Region Code");
        BusinessEntityObject.Add('GeographicalInformation', Address);
    end;

    procedure IsAuthorized(): Boolean
    begin
        exit(Rec.Authorized);
    end;

    internal procedure ID(): Text
    begin
        exit(Format(Rec.PK).TrimStart('{').TrimEnd('}'));
    end;

    internal procedure GetEDocumentService(var EDocumentService: Record "E-Document Service"): Boolean
    begin
        if not FindFirst() then
            exit(false);

        TestField("E-Document Service");
        exit(EDocumentService.Get("E-Document Service") and (EDocumentService.ForNAVIsServiceIntegration()));
    end;

    internal procedure GetEDocumentService() EDocumentService: Record "E-Document Service"
    begin
        if not FindFirst() then
            exit;

        TestField("E-Document Service");
        EDocumentService.Get("E-Document Service");
        exit(EDocumentService);
    end;

    internal procedure GetDocumentSendingProfile(): Code[20]
    begin
        FindFirst();

        TestField("Document Sending Profile");
        exit("Document Sending Profile");
    end;

    internal procedure GetForNAVCode() Result: Code[10]
    var
        ForNAVLbl: Label 'FORNAVEDOC', Locked = true;
    begin
        Result := CopyStr(ForNAVLbl, 1, MaxStrLen(Result));
    end;
}