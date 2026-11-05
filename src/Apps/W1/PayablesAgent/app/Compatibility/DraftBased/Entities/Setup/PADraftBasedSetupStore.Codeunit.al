// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.EServices.EDocumentConnector.Microsoft365;
using System.Email;

// Owns the editable legacy mailbox proposal and its persisted monitoring configuration, without UI or commits.
codeunit 3338 "PA Draft Based Setup Store"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Outlook Setup" = RIM;

    var
        OutlookSetup: Record "Outlook Setup";
        OutlookSetupExists: Boolean;
        PayablesAgentEDocServiceTok: Label 'AGENT', Locked = true;

    internal procedure LoadStored()
    begin
        Clear(OutlookSetup);
        OutlookSetupExists := OutlookSetup.FindFirst();
    end;

    internal procedure ResetProposal()
    begin
        Clear(OutlookSetup);
        OutlookSetupExists := true;
    end;

    internal procedure HasMailboxProposal(): Boolean
    begin
        exit(OutlookSetupExists);
    end;

    internal procedure SetMailboxSelection(AccountId: Guid; FolderName: Text[2048]; FolderId: Text[2048])
    begin
        OutlookSetup."Email Account ID" := AccountId;
        OutlookSetup."Email Folder" := FolderName;
        OutlookSetup."Email Folder Id" := FolderId;
        OutlookSetupExists := true;
    end;

    internal procedure GetEmailAccountId(): Guid
    begin
        exit(OutlookSetup."Email Account ID");
    end;

    internal procedure GetEmailFolder(): Text[2048]
    begin
        exit(OutlookSetup."Email Folder");
    end;

    internal procedure GetEmailFolderId(): Text[2048]
    begin
        exit(OutlookSetup."Email Folder Id");
    end;

    internal procedure GetEmailMonitoringConsent(): Boolean
    begin
        exit(OutlookSetup."Consent Received");
    end;

    internal procedure SetEmailMonitoringConsent(Value: Boolean)
    begin
        OutlookSetup."Consent Received" := Value;
    end;

    internal procedure GetLastSyncAt(): DateTime
    begin
        exit(OutlookSetup."Last Sync At");
    end;

    internal procedure GetOrCreateService() EDocumentService: Record "E-Document Service"
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        if not EDocumentService.Get(PayablesAgentEDocServiceTok) then begin
            EDocumentService.Code := PayablesAgentEDocServiceTok;
            EDocumentService.Insert(true);
        end;
        EDocServiceSupportedType.InsertDefaultIfMissing(EDocumentService.Code, "E-Document Type"::"Purchase Invoice", "E-Doc. Supp. Type Direction"::Incoming);
        EDocServiceSupportedType.InsertDefaultIfMissing(EDocumentService.Code, "E-Document Type"::"Purchase Credit Memo", "E-Doc. Supp. Type Direction"::Incoming);
    end;

    internal procedure AllowCreditMemos()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        if EDocumentService.Get(PayablesAgentEDocServiceTok) then
            EDocServiceSupportedType.InsertDefaultIfMissing(EDocumentService.Code, "E-Document Type"::"Purchase Credit Memo", "E-Doc. Supp. Type Direction"::Incoming);
    end;

    internal procedure Synchronize(Enabling: Boolean; Monitoring: Boolean; AccountId: Guid; FolderName: Text[2048]; FolderId: Text[2048]; Consent: Boolean)
    var
        StoredOutlookSetup: Record "Outlook Setup";
        OutlookSetupExistedPreviously: Boolean;
        EmailAccountChanged: Boolean;
    begin
        OutlookSetupExistedPreviously := StoredOutlookSetup.FindFirst();
        EmailAccountChanged := StoredOutlookSetup."Email Account ID" <> AccountId;
        StoredOutlookSetup."Email Account ID" := AccountId;
        StoredOutlookSetup."Email Connector" := "Email Connector"::"Microsoft 365";
        StoredOutlookSetup."Email Folder" := FolderName;
        StoredOutlookSetup."Email Folder Id" := FolderId;
        StoredOutlookSetup."Consent Received" := Consent;
        if EmailAccountChanged then
            StoredOutlookSetup."Last Sync At" := 0DT;
        if OutlookSetupExistedPreviously then
            StoredOutlookSetup.Modify()
        else
            StoredOutlookSetup.Insert();

        OutlookSetup := StoredOutlookSetup;
        OutlookSetupExists := true;
        SynchronizeService(Enabling, EmailAccountChanged, Monitoring);
    end;

    internal procedure DisableMonitoring()
    var
        EDocumentService: Record "E-Document Service";
    begin
        if EDocumentService.Get(PayablesAgentEDocServiceTok) then begin
            EDocumentService.Validate("Auto Import", false);
            EDocumentService.Modify();
        end;
    end;

    local procedure SynchronizeService(Enabling: Boolean; ReactivateAutoImport: Boolean; Monitoring: Boolean)
    var
        EDocumentService: Record "E-Document Service";
        StoredOutlookSetup: Record "Outlook Setup";
        SupportedType: Record "E-Doc. Service Supported Type";
    begin
        if not Enabling then begin
            DisableMonitoring();
            exit;
        end;
        if not EDocumentService.Get(PayablesAgentEDocServiceTok) then begin
            EDocumentService.Code := PayablesAgentEDocServiceTok;
            EDocumentService.Insert(true);
        end;
        SupportedType.InsertDefaultIfMissing(EDocumentService.Code, "E-Document Type"::"Purchase Invoice", "E-Doc. Supp. Type Direction"::Incoming);
        SupportedType.InsertDefaultIfMissing(EDocumentService.Code, "E-Document Type"::"Purchase Credit Memo", "E-Doc. Supp. Type Direction"::Incoming);
        EDocumentService.Validate("Automatic Import Processing", "E-Doc. Automatic Processing"::No);
        EDocumentService.Validate("Import Process", "E-Document Import Process"::"Version 2.0");
        Clear(EDocumentService."Import Start Time");
        EDocumentService."Import Minutes between runs" := 1;
        EDocumentService."Verify Purch. Total Amounts" := true;
        EDocumentService.Modify();
        if ReactivateAutoImport then
            EDocumentService.Validate("Auto Import", false);
        if Monitoring then begin
            EDocumentService.Validate("Service Integration V2", "Service Integration"::Outlook);
            EDocumentService.Validate("Auto Import", true);
            StoredOutlookSetup.FindFirst();
            StoredOutlookSetup.Validate(Enabled, true);
            StoredOutlookSetup.Modify();
        end else
            EDocumentService.Validate("Auto Import", false);
        EDocumentService.Modify();
    end;
}
