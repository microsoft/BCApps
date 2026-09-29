// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using System.Privacy;
using System.Security.Encryption;
using System.Threading;
using System.Utilities;

table 31125 "EET Service Setup CZL"
{
    Caption = 'EET Service Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = CustomerContent;
            AllowInCustomizations = Never;
        }
        field(2; "Service URL"; Text[250])
        {
            Caption = 'Service URL';
            ExtendedDatatype = URL;
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the source address of the service.';

            trigger OnValidate()
            var
                EETServiceMgtCZL: Codeunit "EET Service Management CZL";
                Confirmed: Boolean;
                ProductionEnvironmentQst: Label 'There are still unprocessed EET Entries.\Entering the URL of the production environment, these entries will be registered in a production environment!\\ Do you want to continue?';
                NonproductionEnvironmentQst: Label 'There are still unprocessed EET Entries.\Entering the URL of the non-production environment, these entries will be registered in a non-production environment!\\ Do you want to continue?';
            begin
                Confirmed := true;
                if "Service URL" <> xRec."Service URL" then
                    if AreEETEntriesToSending() then
                        case "Service URL" of
                            EETServiceMgtCZL.GetWebServiceURLTxt():
                                Confirmed := ConfirmManagement.GetResponse(ProductionEnvironmentQst, false);
                            EETServiceMgtCZL.GetWebServicePlayGroundURLTxt():
                                Confirmed := ConfirmManagement.GetResponse(NonproductionEnvironmentQst, false);
                        end;
                if not Confirmed then
                    "Service URL" := xRec."Service URL";
            end;
        }
        field(10; "Sales Regime"; Enum "EET Sales Regime CZL")
        {
            Caption = 'Sales Regime';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the settings for the simplified scheme sales.';
            // TODO: implement upgrade
        }
        field(11; "Limit Response Time"; Integer)
        {
            Caption = 'Limit Response Time';
            DataClassification = CustomerContent;
            InitValue = 2000;
            MinValue = 2000;
            ToolTip = 'Specifies the response time limit, after which goes into offline mode.';
        }
        field(12; "Appointing VAT Reg. No."; Text[20])
        {
            Caption = 'Appointing VAT Reg. No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the responsible person who collects revenues.';
        }
        field(15; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies if the service is enabled.';

            trigger OnValidate()
            var
                CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
                JobQEntryCreatedQst: Label 'Job queue entry for sending electronic sales records has been created.\\Do you want to open the Job Queue Entries window?';
            begin
                if Enabled then begin
                    if not CustomerConsentMgt.ConfirmUserConsent() then begin
                        Enabled := false;
                        exit;
                    end;
                    ScheduleJobQueueEntry();
                    if ConfirmManagement.GetResponse(JobQEntryCreatedQst, false) then
                        ShowJobQueueEntry();
                end else
                    CancelJobQueueEntry();
            end;
        }
        field(17; "Certificate Code"; Code[10])
        {
            Caption = 'Certificate Code';
            TableRelation = "Certificate Code CZL";
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the certificate needed to register sales.';
        }
        field(30; Representation; Enum "EET Representation CZL")
        {
            Caption = 'Representation';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the registrating unit reports sales directly or indirectly.';
        }
        field(35; Authorization; Boolean)
        {
            Caption = 'Authorization';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the taxpayer is authorized to report sales on behalf of another taxpayer.';
        }
        field(36; "Multiple Taxpayer Auth."; Boolean)
        {
            Caption = 'Multiple Taxpayer Authorization';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the transaction is recorded on behalf of multiple taxpayers.';
        }
        field(40; "Authorized Taxpayer ID"; Code[20])
        {
            Caption = 'Authorized Taxpayer ID';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the registered identification number of the taxpayer authorized to report sales.';
        }
        field(41; "Authorizing Taxpayer ID"; Code[20])
        {
            Caption = 'Authorizing Taxpayer ID';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the registered identification number of the taxpayer authorizing another taxpayer to report sales.';
            // TODO: implement upgrade and fill value from Appointing VAT Reg. No. field
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        TestField("Primary Key", '');
        SetURLToDefault(false);
    end;

    var
        ConfirmManagement: Codeunit "Confirm Management";

    procedure SetURLToDefault(ShowDialog: Boolean)
    var
        EETServiceManagementCZL: Codeunit "EET Service Management CZL";
        Selection: Integer;
        URLOptionsQst: Label '&Production environment URL,&Non-production environment URL';
    begin
        TestField(Enabled, false);
        if not ShowDialog then begin
            EETServiceManagementCZL.SetURLToDefault(Rec);
            exit;
        end;

        Selection := 2;
        if GuiAllowed() then
            Selection := StrMenu(URLOptionsQst, Selection);
        case Selection of
            1:
                Validate("Service URL", EETServiceManagementCZL.GetWebServiceURLTxt());
            2:
                Validate("Service URL", EETServiceManagementCZL.GetWebServicePlayGroundURLTxt());
            else
                exit;
        end;
    end;

    local procedure ScheduleJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DummyRecId: RecordId;
    begin
        JobQueueEntry.ScheduleRecurrentJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          Codeunit::"EET Send Entries To Serv. CZL", DummyRecId);
    end;

    local procedure CancelJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"EET Send Entries To Serv. CZL") then
            JobQueueEntry.Cancel();
    end;

    procedure ShowJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"EET Send Entries To Serv. CZL");
        if JobQueueEntry.FindFirst() then
            Page.Run(Page::"Job Queue Entries", JobQueueEntry);
    end;

    local procedure AreEETEntriesToSending(): Boolean
    var
        EETEntryCZL: Record "EET Entry CZL";
    begin
        EETEntryCZL.SetFilterToSending();
        exit(not EETEntryCZL.IsEmpty());
    end;
}

