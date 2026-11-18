// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;
using System.Email;

codeunit 133723 "PA Setup Tests"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    Access = Internal;

    var
        PATestFixtures: Codeunit "PA Test Fixtures";
        Assert: Codeunit Assert;

    [Test]
    procedure IsEmailConfiguredForDemoEmailReturnsTrueWhenConfigured()
    var
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
        PADemoGuide: Codeunit "PA Demo Guide";
    begin
        // [SCENARIO] Email is configured for the demo email when monitoring is on and a mailbox is selected.
        // [GIVEN] A setup proposal with monitoring on and a registered mailbox.
        PATestFixtures.LoadConfiguration(PASetupUpdateParameters, false);
        PATestFixtures.SetEmailMonitoring(PASetupUpdateParameters, true, RegisterMailbox(), "PA Email Review Policy"::Always);

        // [WHEN] The demo guide checks the email configuration.
        // [THEN] Email is reported as configured.
        Assert.IsTrue(PADemoGuide.IsEmailConfiguredForDemoEmail(PASetupUpdateParameters), 'Email should be configured when monitoring is on and a mailbox is set');
    end;

    [Test]
    procedure IsEmailConfiguredForDemoEmailReturnsFalseWhenMonitoringDisabled()
    var
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
        PADemoGuide: Codeunit "PA Demo Guide";
    begin
        // [SCENARIO] Email is not configured for the demo email when monitoring is off.
        // [GIVEN] A setup proposal with a registered mailbox but monitoring off.
        PATestFixtures.LoadConfiguration(PASetupUpdateParameters, false);
        PATestFixtures.SetEmailMonitoring(PASetupUpdateParameters, false, RegisterMailbox(), "PA Email Review Policy"::Always);

        // [WHEN] The demo guide checks the email configuration.
        // [THEN] Email is reported as not configured.
        Assert.IsFalse(PADemoGuide.IsEmailConfiguredForDemoEmail(PASetupUpdateParameters), 'Email should not be configured when monitoring is disabled');
    end;

    [Test]
    procedure IsEmailConfiguredForDemoEmailReturnsFalseWhenNoAccount()
    var
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
        PADemoGuide: Codeunit "PA Demo Guide";
        NullGuid: Guid;
    begin
        // [SCENARIO] Email is not configured for the demo email when no mailbox is selected.
        // [GIVEN] A setup proposal with monitoring on but no mailbox.
        PATestFixtures.LoadConfiguration(PASetupUpdateParameters, false);
        PATestFixtures.SetEmailMonitoring(PASetupUpdateParameters, true, NullGuid, "PA Email Review Policy"::Always);

        // [WHEN] The demo guide checks the email configuration.
        // [THEN] Email is reported as not configured.
        Assert.IsFalse(PADemoGuide.IsEmailConfiguredForDemoEmail(PASetupUpdateParameters), 'Email should not be configured when no mailbox is set');
    end;

    local procedure RegisterMailbox(): Guid
    var
        EmailOutlookAccount: Record "Email - Outlook Account";
    begin
        EmailOutlookAccount.Id := CreateGuid();
        EmailOutlookAccount.Name := 'Payables';
        EmailOutlookAccount."Email Address" := LowerCase(DelChr(Format(EmailOutlookAccount.Id), '=', '{}-')) + '@contoso.com';
        EmailOutlookAccount."Outlook API Email Connector" := "Email Connector"::"Microsoft 365";
        EmailOutlookAccount.Insert();
        exit(EmailOutlookAccount.Id);
    end;
}
