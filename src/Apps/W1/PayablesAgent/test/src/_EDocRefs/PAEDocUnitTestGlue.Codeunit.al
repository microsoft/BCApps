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

/// <summary>
/// The only place of the Payables Agent unit tests that references E-Document Core or the E-Document Microsoft 365
/// connector (E-Documents, E-Document Services, Outlook Setup). Every other test object goes through the procedures
/// of this codeunit, which are named after what the test needs, not after how the e-document based Payables Agent
/// implements it.
/// </summary>
codeunit 133723 "PA EDoc Unit Test Glue"
{
    Access = Internal;

    #region Setup

    /// <summary>
    /// Sets the email account the agent monitors, directly on the stored setup.
    /// </summary>
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

    /// <summary>
    /// Sets the email account the agent monitors on a setup configuration that is about to be applied.
    /// </summary>
    internal procedure SetMonitoredEmailAccount(var PASetupConfiguration: Codeunit "PA Setup Configuration"; AccountId: Guid)
    var
        TempDummyOutlookSetup: Record "Outlook Setup" temporary;
    begin
        TempDummyOutlookSetup."Email Account ID" := AccountId;
        PASetupConfiguration.SetOutlookSetup(TempDummyOutlookSetup);
    end;

    /// <summary>
    /// Asserts that the intake the agent receives invoices through is configured to monitor the mailbox.
    /// </summary>
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

    /// <summary>
    /// Deletes the stored email monitoring setup.
    /// </summary>
    internal procedure DeleteEmailMonitoringSetup()
    var
        OutlookSetup: Record "Outlook Setup";
    begin
        OutlookSetup.DeleteAll();
    end;

    /// <summary>
    /// Deletes the intake the agent receives invoices through, including the email monitoring setup.
    /// </summary>
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

    /// <summary>
    /// Creates a task for an invoice and hands it to the agent through the intake path that requests review.
    /// </summary>
    /// <returns>The external id the agent task message is expected to carry.</returns>
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

    /// <summary>
    /// Runs the agent-side known-sender recording path for a task whose sender is the given email.
    /// </summary>
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
