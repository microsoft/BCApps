// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;
using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.EServices.EDocumentConnector.Microsoft365;
using System.Agents;
using System.Email;
using System.TestLibraries.Utilities;

codeunit 133723 "PA EDoc Unit Test Glue"
{
    Access = Internal;

    #region Setup

    internal procedure SetMonitoredEmailAccount(AccountId: Guid; Connector: Enum "Email Connector")
    var
        OutlookSetup: Record "Outlook Setup";
    begin
        if not OutlookSetup.Get() then begin
            OutlookSetup.Init();
            OutlookSetup.Insert();
        end;
        OutlookSetup."Email Account ID" := AccountId;
        OutlookSetup."Email Connector" := Connector;
        OutlookSetup.Modify();
    end;

    internal procedure SetMonitoredEmailAccount(var PASetupConfiguration: Codeunit "PA Setup Configuration"; AccountId: Guid)
    var
        TempDummyOutlookSetup: Record "Outlook Setup" temporary;
    begin
        TempDummyOutlookSetup."Email Account ID" := AccountId;
        PASetupConfiguration.SetOutlookSetup(TempDummyOutlookSetup);
    end;

    internal procedure AssertAgentIntakeMonitorsMailbox(PASetup: Record "Payables Agent Setup")
    var
        EDocumentService: Record "E-Document Service";
        OutlookSetup: Record "Outlook Setup";
    begin
        EDocumentService.Get(PASetup."E-Document Service Code");
        // The E-Document Service is configured for auto-import with the correct configuration
        OutlookSetup.FindFirst();
        Assert.AreEqual(true, OutlookSetup.Enabled, 'The Outlook Setup should be enabled');
        Assert.AreEqual(true, EDocumentService."Auto Import", 'The agent''s E-Document Service should be configured for auto-import');
        Assert.AreEqual("E-Document Import Process"::"Version 2.0", EDocumentService."Import Process", 'Import process should be v2');
        Assert.AreEqual("E-Doc. Automatic Processing"::No, EDocumentService."Automatic Import Processing", 'The E-Document Service should not auto process');
    end;

    internal procedure DeleteEmailMonitoringSetup()
    var
        OutlookSetup: Record "Outlook Setup";
    begin
        OutlookSetup.DeleteAll();
    end;

    internal procedure DeleteAgentIntake()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        DeleteEmailMonitoringSetup();
        EDocumentService.DeleteAll();
        EDocServiceSupportedType.DeleteAll();
    end;

    #endregion

    #region Task intake

    internal procedure CreateAgentTaskForInvoice(PASetup: Record "Payables Agent Setup"; Agent: Record Agent) ExpectedExternalId: Text
    var
        EDocument: Record "E-Document";
        PayablesAgent: Codeunit "Payables Agent";
    begin
        EDocument.Service := PASetup."E-Document Service Code";
        EDocument."Source Details" := 'Test Source Details';
        EDocument.Insert();
        PayablesAgent.BuildAgentTask(EDocument, Agent);
        exit(Format(EDocument."Entry No"));
    end;

    internal procedure RecordKnownSender(SenderEmail: Text)
    var
        PAKnownSender: Record "PA Known Sender";
        EDocument: Record "E-Document";
    begin
        EDocument.Init();
        EDocument."Source Details" := CopyStr(SenderEmail, 1, MaxStrLen(EDocument."Source Details"));
        PAKnownSender.InsertIfNew(EDocument);
    end;

    #endregion

    var
        Assert: Codeunit Assert;
}
