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
        Assert.IsTrue(EnvironmentInformation.IsSandbox(), 'Testability should have dictacted a sandbox environment');
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
        Assert.IsFalse(EnvironmentInformation.IsSandbox(), 'Testability should have dictacted a non-sandbox environment');
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
        Assert.IsTrue(EnvironmentInformation.IsSaaS(), 'Testability should have dictacted a SaaS environment');
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
        Assert.IsFalse(EnvironmentInformation.IsSaaS(), 'Testability should have dictacted a non- SaaS environment');
    end;


    [Test]
    procedure TestIsSaaSInfrastructureIsTrueWhenTestabilitySaaSInfrastructureIsSetTrue()
    begin
        // [SCENARIO] Set the testability to true. IsSaaSInfrastructure returns correct values.

        // [Given] Set the testability SaaS to true
        EnvironmentInfoTestLibrary.SetIsSaaSInfrastructure(true);

        // [When] Poll for IsSaaSInfrastructure
        // [Then] Should return true
        Assert.IsTrue(EnvironmentInformation.IsSaaSInfrastructure(), 'Testability should have dictacted a SaaS environment');
    end;


    [Test]
    procedure TestVersionInstalledIsTrueWhenTestabilityVersionInstalledIsSet()
    begin
        // [SCENARIO] Set the testability to true. VersionInstalled returns correct values.

        // [Given] Set the testability VersionInstalled to 23
        EnvironmentInfoTestLibrary.SetVersionInstalled(23.0);

        // [When] Poll for VersionInstalled
        // [Then] Should return true
        Assert.IsTrue(EnvironmentInformation.VersionInstalled('123') = 23.0, 'Testability should have dictacted a SaaS environment');
    end;

    [Test]
    procedure TestIsSaaSIsTrueWhenTestabilityIsSaaSIsSet()
    begin
        // [SCENARIO] Set the testability to true. IsSaaS returns correct values.

        // [Given] Set the testability SaaS to true
        EnvironmentInfoTestLibrary.SetIsSaaS(true);

        // [When] Poll for IsSaaS
        // [Then] Should return true
        Assert.IsTrue(EnvironmentInformation.IsSaaS(), 'Testability should have dictacted a SaaS environment');
    end;

    [Test]
    procedure TestEnvironmentNameIsTrueWhenTestabilityEnvironmentNameIsSet()
    begin
        // [SCENARIO] Set the testability to true. EnvironmentName returns correct values.

        // [Given] Set the testability EnvironmentName to '123'
        EnvironmentInfoTestLibrary.SetEnvironmentName('123');

        // [When] Poll for EnvironmentName
        // [Then] Should return true
        Assert.IsTrue(EnvironmentInformation.EnvironmentName() = '123', 'Testability should have dictacted a SaaS environment');
    end;

    [Test]
    procedure TestIsProductionIsTrueWhenTestabilityIsProductionIsSet()
    begin
        // [SCENARIO] Set the testability to true. IsProduction returns correct values.

        // [Given] Set the testability IsProduction to true
        EnvironmentInfoTestLibrary.SetIsProduction(true);

        // [When] Poll for IsProduction
        // [Then] Should return true
        Assert.IsTrue(EnvironmentInformation.IsProduction(), 'Testability should have dictacted a SaaS environment');
    end;

    [Test]
    procedure TestApplicationFamilyIsTrueWhenTestabilityApplicationFamilyIsSet()
    begin
        // [SCENARIO] Set the testability to true. ApplicationFamily returns correct values.

        // [Given] Set the testability ApplicationFamily to 1234
        EnvironmentInfoTestLibrary.SetApplicationFamily('1234');

        // [When] Poll for ApplicationFamily
        // [Then] Should return true
        Assert.IsTrue(EnvironmentInformation.ApplicationFamily() = '1234', 'Testability should have dictacted a SaaS environment');
    end;
}

