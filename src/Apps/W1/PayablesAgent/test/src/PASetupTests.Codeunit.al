// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;
using System.Email;

// PA-owned mailbox proposal behavior; framework activation/task/page behavior is tested by runtime validation.
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
        PATestFixtures.LoadConfiguration(PASetupUpdateParameters, false);
        PATestFixtures.SetEmailMonitoring(PASetupUpdateParameters, true, RegisterMailbox(), "PA Email Review Policy"::Always);
        Assert.IsTrue(PADemoGuide.IsEmailConfiguredForDemoEmail(PASetupUpdateParameters), 'Email should be configured when monitoring is on and a mailbox is set');
    end;

    [Test]
    procedure IsEmailConfiguredForDemoEmailReturnsFalseWhenMonitoringDisabled()
    var
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
        PADemoGuide: Codeunit "PA Demo Guide";
    begin
        PATestFixtures.LoadConfiguration(PASetupUpdateParameters, false);
        PATestFixtures.SetEmailMonitoring(PASetupUpdateParameters, false, RegisterMailbox(), "PA Email Review Policy"::Always);
        Assert.IsFalse(PADemoGuide.IsEmailConfiguredForDemoEmail(PASetupUpdateParameters), 'Email should not be configured when monitoring is disabled');
    end;

    [Test]
    procedure IsEmailConfiguredForDemoEmailReturnsFalseWhenNoAccount()
    var
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
        PADemoGuide: Codeunit "PA Demo Guide";
        NullGuid: Guid;
    begin
        PATestFixtures.LoadConfiguration(PASetupUpdateParameters, false);
        PATestFixtures.SetEmailMonitoring(PASetupUpdateParameters, true, NullGuid, "PA Email Review Policy"::Always);
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
