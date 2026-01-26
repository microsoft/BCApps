// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Privacy;
using System.Security.Encryption;
using System.Telemetry;

table 10751 "SII Setup"
{
    Caption = 'SII VAT Setup';
    LookupPageID = "SII Setup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';

            trigger OnValidate()
            var
                CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
                IsHandled: Boolean;
                SIISetupConsentProvidedLbl: Label 'SII Setup - consent provided by UserSecurityId %1.', Locked = true;
            begin
                IsHandled := false;
                OnBeforeValidateEnabled(Rec, IsHandled);
                if IsHandled then
                    exit;

                if Enabled and ("Certificate Code" = '') then
                    Error(CannotEnableWithoutCertificateErr);
                if Enabled then
                    Enabled := CustomerConsentMgt.ConfirmUserConsent();
                if Enabled then
                    Session.LogAuditMessage(StrSubstNo(SIISetupConsentProvidedLbl, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0);
            end;
        }
        field(5; InvoicesIssuedEndpointUrl; Text[250])
        {
            Caption = 'InvoicesIssuedEndpointUrl';
            InitValue = 'https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/fe/SiiFactFEV1SOAP';
            NotBlank = true;
        }
        field(6; InvoicesReceivedEndpointUrl; Text[250])
        {
            Caption = 'InvoicesReceivedEndpointUrl';
            InitValue = 'https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/fr/SiiFactFRV1SOAP';
            NotBlank = true;
        }
        field(7; PaymentsIssuedEndpointUrl; Text[250])
        {
            Caption = 'PaymentsIssuedEndpointUrl';
            InitValue = 'https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/fr/SiiFactPAGV1SOAP';
            NotBlank = true;
        }
        field(8; PaymentsReceivedEndpointUrl; Text[250])
        {
            Caption = 'PaymentsReceivedEndpointUrl';
            InitValue = 'https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/fe/SiiFactCOBV1SOAP';
            NotBlank = true;
        }
#if not CLEANSCHEMA25
        field(9; IntracommunityEndpointUrl; Text[250])
        {
            Caption = 'IntracommunityEndpointUrl';
            InitValue = 'https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/oi/SiiFactOIV1SOAP';
            NotBlank = true;
            ObsoleteReason = 'Intracommunity feature was removed in scope of 222210';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(10; "Enable Batch Submissions"; Boolean)
        {
            Caption = 'Enable Batch Submissions';
        }
        field(11; "Job Batch Submission Threshold"; Integer)
        {
            Caption = 'Job Batch Submission Threshold';
            MinValue = 0;
        }
        field(12; "Show Advanced Actions"; Boolean)
        {
            Caption = 'Show Advanced Actions';
        }
        field(13; CollectionInCashEndpointUrl; Text[250])
        {
            Caption = 'CollectionInCashEndpointUrl';
            InitValue = 'https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/pm/SiiFactCMV1SOAP';
            NotBlank = true;
        }
        field(20; "Invoice Amount Threshold"; Decimal)
        {
            Caption = 'Invoice Amount Threshold';
            InitValue = 100000000;
            MinValue = 0;
        }
        field(21; "Do Not Export Negative Lines"; Boolean)
        {
            Caption = 'Do Not Export Negative Lines';
        }
        field(22; "Do Not Schedule JQ Entry"; Boolean)
        {
            Caption = 'Do Not Schedule Job Queue Entry';

            trigger OnValidate()
            begin
                FeatureTelemetry.LogUsage('0000MY1', SIIFeatureNameTok, StrSubstNo(DoNotScheduleJobQueueEntryEnabledTxt, Rec."Do Not Schedule JQ Entry"));
            end;
        }
        field(30; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(31; "Auto Missing Entries Check"; Option)
        {
            Caption = 'Auto Missing Entries Check';
            InitValue = Daily;
            OptionCaption = 'Never,Daily,Weekly';
            OptionMembers = Never,Daily,Weekly;

            trigger OnValidate()
            var
                SIIJobManagement: Codeunit "SII Job Management";
            begin
                if "Auto Missing Entries Check" = xRec."Auto Missing Entries Check" then
                    exit;

                SIIJobManagement.RestartJobQueueEntryForMissingEntryCheck("Auto Missing Entries Check");
            end;
        }
        field(32; "Include ImporteTotal"; Boolean)
        {
            Caption = 'Include ImporteTotal';
        }
        field(40; "SuministroInformacion Schema"; Text[2048])
        {
            InitValue = 'https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/ssii/fact/ws/SuministroInformacion.xsd';
        }
        field(41; "SuministroLR Schema"; Text[2048])
        {
            InitValue = 'https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/ssii/fact/ws/SuministroLR.xsd';
        }
        field(42; "Certificate Code"; Code[20])
        {
            TableRelation = "Isolated Certificate";
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                Validate(Enabled, "Certificate Code" <> '');
            end;
        }
        field(43; "Operation Date"; Enum "SII Operation Date Type")
        {
            Caption = 'Operation Date';
        }
        field(44; "New Automatic Sending Exp."; Boolean)
        {
            Caption = 'New Automatic Sending Experience';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                FeatureTelemetry.LogUsage('0000M84', SIIFeatureNameTok, StrSubstNo(NewAutomaticSendingExperienceEnabledTxt, Rec."New Automatic Sending Exp."));
            end;
        }
        field(45; "Tax Period"; Enum "SII Tax Period")
        {
            Caption = 'Tax Period';
            Tooltip = 'Specifies the type of the tax period for the SII. It will affect the value in the Periodo xml node.';
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

    trigger OnInsert()
    begin
        "Starting Date" := WorkDate();
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CannotEnableWithoutCertificateErr: Label 'The setup cannot be enabled without a valid certificate.';
        SiiTxt: Label 'https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/ssii/fact/ws/SuministroInformacion.xsd', Locked = true;
        SiiLRTxt: Label 'https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/ssii/fact/ws/SuministroLR.xsd', Locked = true;
        SIIFeatureNameTok: Label 'SII', Locked = true;
        NewAutomaticSendingExperienceEnabledTxt: Label 'New Automatic Sending Experience: %1', Locked = true, Comment = '%1 = either true or false';
        DoNotScheduleJobQueueEntryEnabledTxt: Label 'Do Not Schedule Job Queue Entry: %1', Locked = true, Comment = '%1 = either true or false';

    procedure IsEnabled(): Boolean
    begin
        if not Get() then
            exit(false);
        exit(Enabled);
    end;

    procedure SetDefaults()
    begin
        if ("SuministroInformacion Schema" <> '') and ("SuministroLR Schema" <> '') then
            exit;
        "SuministroInformacion Schema" := SiiTxt;
        "SuministroLR Schema" := SiiLRTxt;
        Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateEnabled(var SIISetup: Record "SII Setup"; var IsHandled: Boolean)
    begin
    end;
}