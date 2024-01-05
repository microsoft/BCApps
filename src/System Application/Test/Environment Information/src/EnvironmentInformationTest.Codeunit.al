// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Environment;

using System.Environment;
using System.TestLibraries.Environment;
using System.TestLibraries.Utilities;

codeunit 135091 "Environment Information Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        EnvironmentInformation: Codeunit "Environment Information";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";

    [Test]
    [Scope('OnPrem')]
    procedure TestCanStartSessionWithTestIsolationEnabled()
    begin
        // [Scenario] When running the tests with the test isolation enabled (the default), CanStartSession returns false.
        // [Given] The test codeunit is executed by a test runner with enabled test isolation
        // [Then] CanStartSession returns false
        Assert.IsFalse(EnvironmentInformation.CanStartSession(), 'CanStartSession() should return false if test isolation is enabled.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsSandboxIsTrueWhenTestabilitySandboxIsSet()
    begin
        // [Scenario] Set the testability to true. IsSandBox returns correct values.

        // [Given] Set the testability sandbox to True
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);

        // [When] Poll for IsSandbox
        // [Then] Should return true
        Assert.IsTrue(EnvironmentInformation.IsSandbox(), 'Environment Information should have returned the setup of a sandbox environment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsSandboxIsFalseWhenTestabilitySandboxIsNotSet()
    begin
        // [Scenario] Set the testability to false. IsSandBox returns correct values.

        // [Given] Set the testability sandbox to false
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);

        // [When] Poll for IsSandbox
        // [Then] Should return false
        Assert.IsFalse(EnvironmentInformation.IsSandbox(), 'Environment Information should have returned the setup of a non-sandbox environment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsSaaSIsTrueWhenTestabilitySaaSIsSet()
    begin
        // [SCENARIO] Set the testability to true. IsSaaS returns correct values.

        // [Given] Set the testability SaaS to true
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [When] Poll for IsSaaS
        // [Then] Should return true
        Assert.IsTrue(EnvironmentInformation.IsSaaS(), 'Environment Information should have returned the setup of a SaaS environment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsSaaSIsFalseWhenTestabilitySaaSIsNotSet()
    begin
        // [SCENARIO] Set the testability to false. IsSaaS returns correct values.

        // [Given] Set the testability SaaS to false
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [When] Poll for IsSaaS
        // [Then] Should return false
        Assert.IsFalse(EnvironmentInformation.IsSaaS(), 'Environment Information should have returned the setup of a non-SaaS environment');
    end;

    [Test]
    procedure TestIsSaaSInfrastructureIsTrueWhenTestabilitySaaSInfrastructureIsSetTrue()
    begin
        // [SCENARIO] Set the testability to true. IsSaaSInfrastructure returns correct values.
        If BindSubscription(EnvironmentInfoTestLibrary) then;

        // [Given] Set the testability SaaS to true
        EnvironmentInfoTestLibrary.SetIsSaaSInfrastructure(true);

        // [When] Poll for IsSaaSInfrastructure
        // [Then] Should return true
        Assert.IsTrue(EnvironmentInformation.IsSaaSInfrastructure(), 'Environment Information should have returned the setup of a SaaS infrastructure');
        If UnbindSubscription(EnvironmentInfoTestLibrary) then;
    end;

    [Test]
    procedure TestVersionInstalledIsTrueWhenTestabilityVersionInstalledIsSet()
    begin
        // [SCENARIO] Set the testability to true. VersionInstalled returns correct values.
        If BindSubscription(EnvironmentInfoTestLibrary) then;

        // [Given] Set the testability VersionInstalled to 23
        EnvironmentInfoTestLibrary.SetVersionInstalled(23);

        // [When] Poll for VersionInstalled
        // [Then] Should return the correct version installed
        Assert.AreEqual(23, EnvironmentInformation.VersionInstalled('35de2eee-c479-459e-b70b-2f244708415a'), 'Environment Information should have returned the correct version installed');
        If UnbindSubscription(EnvironmentInfoTestLibrary) then;
    end;

    [Test]
    procedure TestIsSaaSIsTrueWhenTestabilityIsSaaSIsSet()
    begin
        // [SCENARIO] Set the testability to true. IsSaaS returns correct values.
        If BindSubscription(EnvironmentInfoTestLibrary) then;

        // [Given] Set the testability SaaS to true
        EnvironmentInfoTestLibrary.SetIsSaaS(true);

        // [When] Poll for IsSaaS
        // [Then] Should return true
        Assert.IsTrue(EnvironmentInformation.IsSaaS(), 'Environment Information should have returned the setup of a SaaS environment');
        If UnbindSubscription(EnvironmentInfoTestLibrary) then;
    end;

    [Test]
    procedure TestEnvironmentNameIsTrueWhenTestabilityEnvironmentNameIsSet()
    begin
        // [SCENARIO] Set the testability to true. EnvironmentName returns correct values.
        If BindSubscription(EnvironmentInfoTestLibrary) then;

        // [Given] Set the testability EnvironmentName to '123'
        EnvironmentInfoTestLibrary.SetEnvironmentName('123');

        // [When] Poll for EnvironmentName
        // [Then] Should return the correct environment name
        Assert.AreEqual('123', EnvironmentInformation.GetEnvironmentName(), 'Environment Information should have returned the correct environment name');
        If UnbindSubscription(EnvironmentInfoTestLibrary) then;
    end;

    [Test]
    procedure TestIsProductionIsTrueWhenTestabilityIsProductionIsSet()
    begin
        // [SCENARIO] Set the testability to true. IsProduction returns correct values.
        If BindSubscription(EnvironmentInfoTestLibrary) then;

        // [Given] Set the testability IsProduction to true
        EnvironmentInfoTestLibrary.SetIsProduction(true);

        // [When] Poll for IsProduction
        // [Then] Should return true
        Assert.IsTrue(EnvironmentInformation.IsProduction(), 'Environment Information should have returned the setup of a production environment');
        If UnbindSubscription(EnvironmentInfoTestLibrary) then;
    end;

    [Test]
    procedure TestApplicationFamilyIsTrueWhenTestabilityApplicationFamilyIsSet()
    begin
        // [SCENARIO] Set the testability to true. ApplicationFamily returns correct values.
        If BindSubscription(EnvironmentInfoTestLibrary) then;

        // [Given] Set the testability ApplicationFamily to 1234
        EnvironmentInfoTestLibrary.SetApplicationFamily('1234');

        // [When] Poll for ApplicationFamily
        // [Then] Should return the correct application family
        Assert.AreEqual('1234', EnvironmentInformation.GetApplicationFamily(), 'Environment Information should have returned the correct application family');
        If UnbindSubscription(EnvironmentInfoTestLibrary) then;
    end;
}

