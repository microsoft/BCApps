// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Company;
using System.Integration;
using System.Privacy;
using System.Security.Encryption;
using System.Telemetry;
using System.Threading;

table 1270 "OCR Service Setup"
{
    Caption = 'OCR Service Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "User Name"; Text[50])
        {
            Caption = 'User Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Password Key"; Guid)
        {
            Caption = 'Password Key';
        }
        field(4; "Sign-up URL"; Text[250])
        {
            Caption = 'Sign-up URL';
            ExtendedDatatype = URL;
        }
        field(5; "Service URL"; Text[250])
        {
            Caption = 'Service URL';
            ExtendedDatatype = URL;

            trigger OnValidate()
            var
                HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
            begin
                if "Service URL" = '' then
                    exit;
                HttpWebRequestMgt.CheckUrl("Service URL");
                while (StrLen("Service URL") > 8) and ("Service URL"[StrLen("Service URL")] = '/') do
                    "Service URL" := CopyStr("Service URL", 1, StrLen("Service URL") - 1);
            end;
        }
        field(6; "Sign-in URL"; Text[250])
        {
            Caption = 'Sign-in URL';
            ExtendedDatatype = URL;
        }
        field(7; "Authorization Key"; Guid)
        {
            Caption = 'Authorization Key';
        }
        field(8; "Customer Name"; Text[80])
        {
            Caption = 'Customer Name';
            Editable = false;
        }
        field(9; "Customer ID"; Text[50])
        {
            Caption = 'Customer ID';
            Editable = false;
        }
        field(10; "Customer Status"; Text[30])
        {
            Caption = 'Customer Status';
            Editable = false;
        }
        field(11; "Organization ID"; Text[50])
        {
            Caption = 'Organization ID';
            Editable = false;
        }
        field(12; "Default OCR Doc. Template"; Code[20])
        {
            Caption = 'Default OCR Doc. Template';
            TableRelation = "OCR Service Document Template";

            trigger OnLookup()
            var
                OCRServiceDocumentTemplate: Record "OCR Service Document Template";
                OCRServiceMgt: Codeunit "OCR Service Mgt.";
            begin
                if OCRServiceDocumentTemplate.IsEmpty() then begin
                    OCRServiceMgt.SetupConnection(Rec);
                    Commit();
                end;

                if PAGE.RunModal(PAGE::"OCR Service Document Templates", OCRServiceDocumentTemplate) = ACTION::LookupOK then
                    "Default OCR Doc. Template" := OCRServiceDocumentTemplate.Code;
            end;

            trigger OnValidate()
            var
                IncomingDocument: Record "Incoming Document";
            begin
                if xRec."Default OCR Doc. Template" <> '' then
                    exit;
                IncomingDocument.SetRange("OCR Service Doc. Template Code", '');
                IncomingDocument.ModifyAll("OCR Service Doc. Template Code", "Default OCR Doc. Template");
            end;
        }
        field(13; Enabled; Boolean)
        {
            Caption = 'Enabled';

            trigger OnValidate()
            var
                CompanyInformation: Record "Company Information";
                OCRServiceMgt: Codeunit "OCR Service Mgt.";
                CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
                AuditLog: Codeunit "Audit Log";
            begin
                if not xRec."Enabled" and Rec."Enabled" then
                    Rec."Enabled" := CustomerConsentMgt.ConfirmUserConsent();

                if Rec.Enabled then begin
                    AuditLog.LogAuditMessage(StrSubstNo(OCRServiceConsentProvidedLbl, UserSecurityId(), CompanyName()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0);
                    OCRServiceMgt.SetupConnection(Rec);
                    if "Default OCR Doc. Template" = '' then
                        if CompanyInformation.Get() then
                            case CompanyInformation."Country/Region Code" of
                                'US', 'USA':
                                    Validate("Default OCR Doc. Template", 'USA_PO');
                                'CA':
                                    Validate("Default OCR Doc. Template", 'CAN_PO');
                            end;
                    Modify();
                    TestField("Default OCR Doc. Template");
                    ScheduleJobQueueEntries();
                    LogTelemetryWhenServiceEnabled();
                    if Confirm(JobQEntriesCreatedQst) then
                        ShowJobQueueEntry();
                end else begin
                    CancelJobQueueEntries();
                    LogTelemetryWhenServiceDisabled();
                end;
            end;
        }
        field(14; "Master Data Sync Enabled"; Boolean)
        {
            Caption = 'Master Data Sync Enabled';

            trigger OnValidate()
            begin
                if "Master Data Sync Enabled" and Enabled then begin
                    Modify();
                    ScheduleJobQueueSync();
                end else
                    CancelJobQueueSync();
            end;
        }
        field(15; "Master Data Last Sync"; DateTime)
        {
            Caption = 'Master Data Last Sync';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        OCRServiceDocTemplate: Record "OCR Service Document Template";
    begin
        DeletePassword("Password Key");
        DeletePassword("Authorization Key");
        OCRServiceDocTemplate.DeleteAll(true)
    end;

    trigger OnInsert()
    begin
        TestField("Primary Key", '');
        SetURLsToDefault();
        LogTelemetryWhenServiceCreated();
    end;

    trigger OnModify()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
    begin
        FeatureTelemetry.LogUptake('0000IML', OCRServiceMgt.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
    end;

    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        MustBeEnabledErr: Label 'The OCR service is not enabled.\\In the OCR Service Setup window, select the Enabled check box.', Comment = 'OCR = Optical Character Recognition';
        JobQEntriesCreatedQst: Label 'Job queue entries for sending and receiving electronic documents have been created.\\Do you want to open the Job Queue Entries window?';
        OCRServiceCreatedTxt: Label 'The user started setting up OCR service.', Locked = true;
        OCRServiceEnabledTxt: Label 'The user enabled OCR service.', Locked = true;
        OCRServiceDisabledTxt: Label 'The user disabled OCR service.', Locked = true;
        TelemetryCategoryTok: Label 'AL OCR Service', Locked = true;
        OCRServiceConsentProvidedLbl: Label 'OCR Service - consent provided by UserSecurityId %1 for company %2.', Comment = '%1 - User Security ID, %2 - Company name', Locked = true;

#if not CLEAN25
    [Scope('OnPrem')]
    [Obsolete('Replaced by SavePassword(var PasswordKey: Guid; PasswordText: SecretText)', '25.0')]
    [NonDebuggable]
    procedure SavePassword(var PasswordKey: Guid; PasswordText: Text)
    var
        PasswordAsSecretText: SecretText;
    begin
        PasswordAsSecretText := PasswordText;
        SavePassword(PasswordKey, PasswordAsSecretText);
    end;
#endif

    [Scope('OnPrem')]
    procedure SavePassword(var PasswordKey: Guid; PasswordText: SecretText)
    begin
        if IsNullGuid(PasswordKey) then begin
            PasswordKey := CreateGuid();
            Modify();
        end;

        IsolatedStorageManagement.Set(PasswordKey, PasswordText, DATASCOPE::Company);
    end;
#if not CLEAN25

    [NonDebuggable]
    [Scope('OnPrem')]
    [Obsolete('Replaced by GetPasswordAsSecretText', '25.0')]
    procedure GetPassword(PasswordKey: Guid): Text
    begin
        exit(GetPasswordAsSecretText(PasswordKey).Unwrap());
    end;
#endif

    [Scope('OnPrem')]
    procedure GetPasswordAsSecretText(PasswordKey: Guid): SecretText
    var
        Value: SecretText;
    begin
        IsolatedStorageManagement.Get(PasswordKey, DATASCOPE::Company, Value);
        exit(Value);
    end;

    [Scope('OnPrem')]
    local procedure DeletePassword(PasswordKey: Guid)
    begin
        IsolatedStorageManagement.Delete(PasswordKey, DATASCOPE::Company);
    end;

    [Scope('OnPrem')]
    procedure HasPassword(PasswordKey: Guid): Boolean
    var
        Value: SecretText;
    begin
        IsolatedStorageManagement.Get(PasswordKey, DATASCOPE::Company, Value);
        exit(not Value.IsEmpty());
    end;

    procedure SetURLsToDefault()
    var
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
    begin
        OCRServiceMgt.SetURLsToDefaultRSO(Rec);
    end;

    procedure CheckEnabled()
    begin
        if not Enabled then
            Error(MustBeEnabledErr);
    end;

    local procedure ScheduleJobQueueEntries()
    begin
        ScheduleJobQueueReceive();
        ScheduleJobQueueSend();
        ScheduleJobQueueSync();
    end;

    procedure ScheduleJobQueueSend()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DummyRecId: RecordID;
    begin
        CancelJobQueueSend();
        JobQueueEntry.ScheduleRecurrentJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"OCR - Send to Service", DummyRecId);
    end;

    procedure ScheduleJobQueueReceive()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DummyRecId: RecordID;
    begin
        CancelJobQueueReceive();
        JobQueueEntry.ScheduleRecurrentJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"OCR - Receive from Service", DummyRecId);
    end;

    procedure ScheduleJobQueueSync()
    var
        OCRSyncMasterData: Codeunit "OCR - Sync Master Data";
    begin
        OCRSyncMasterData.ScheduleJob();
    end;

    local procedure CancelJobQueueEntries()
    begin
        CancelJobQueueReceive();
        CancelJobQueueSend();
        CancelJobQueueSync();
    end;

    local procedure CancelJobQueueEntry(ObjType: Option; ObjID: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.FindJobQueueEntry(ObjType, ObjID) then
            JobQueueEntry.Cancel();
    end;

    procedure CancelJobQueueSend()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CancelJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"OCR - Send to Service");
    end;

    procedure CancelJobQueueReceive()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CancelJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"OCR - Receive from Service");
    end;

    procedure CancelJobQueueSync()
    var
        OCRSyncMasterData: Codeunit "OCR - Sync Master Data";
    begin
        OCRSyncMasterData.CancelJob();
    end;

    procedure ShowJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetFilter("Object ID to Run", '%1|%2|%3',
          CODEUNIT::"OCR - Send to Service",
          CODEUNIT::"OCR - Receive from Service",
          CODEUNIT::"OCR - Sync Master Data");
        if JobQueueEntry.FindFirst() then
            PAGE.Run(PAGE::"Job Queue Entries", JobQueueEntry);
    end;

    local procedure LogTelemetryWhenServiceEnabled()
    begin
        Session.LogMessage('00008A4', OCRServiceEnabledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        Session.LogMessage('00008A5', "Service URL", Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    local procedure LogTelemetryWhenServiceDisabled()
    begin
        Session.LogMessage('00008A6', OCRServiceDisabledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        Session.LogMessage('00008A7', "Service URL", Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    local procedure LogTelemetryWhenServiceCreated()
    begin
        Session.LogMessage('00008A8', OCRServiceCreatedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;
}

