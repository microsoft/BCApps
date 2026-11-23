// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 139203 "Library Random Lifecycle Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit "Library Assert";

    [Test]
    procedure RandomIsInitializedBeforeFirstUse()
    var
        ActualFirst: Integer;
        ActualValue: Integer;
        ExpectedFirst: Integer;
        ExpectedValue: Integer;
    begin
        ActualFirst := Random(100000);
        ActualValue := LibraryRandom.RandInt(100000);
        LibraryRandom.SetSeed(1);
        ExpectedFirst := Random(100000);
        ExpectedValue := LibraryRandom.RandInt(100000);

        Assert.AreEqual(ExpectedFirst, ActualFirst, 'Native procedures must start with the default sequence.');
        Assert.AreEqual(ExpectedValue, ActualValue, 'First library use must not rewind the shared random sequence.');
        LibraryRandom.SetSeed(8721);
    end;

    [Test]
    procedure PreviousSeedDoesNotLeak()
    var
        ActualValue: Integer;
        ExpectedValue: Integer;
    begin
        ActualValue := LibraryRandom.RandInt(100000);
        LibraryRandom.SetSeed(1);
        ExpectedValue := LibraryRandom.RandInt(100000);

        Assert.AreEqual(ExpectedValue, ActualValue, 'A previous procedure seed must not leak into this procedure.');
    end;

    [Test]
    procedure ExplicitBodySeedIsPreserved()
    var
        ExpectedFirst: Integer;
        ExpectedSecond: Integer;
    begin
        Randomize(37);
        ExpectedFirst := Random(100000);
        ExpectedSecond := Random(100000);
        LibraryRandom.SetSeed(37);

        Assert.AreEqual(ExpectedFirst, LibraryRandom.RandInt(100000), 'The body must be able to override the automatic seed.');
        Assert.AreEqual(ExpectedSecond, LibraryRandom.RandInt(100000), 'No automatic reset may interrupt the body sequence.');
    end;

    [TestDataSource(Codeunit::"Library Random Test Cases", 'Default')]
    procedure EachCaseStartsWithDefaultSeed(Context: Interface System.Test.ITestContext)
    var
        CaseValues: Codeunit "Library Random Test Cases";
        ExpectedFirst: Integer;
        ExpectedSecond: Integer;
    begin
        Randomize(1);
        ExpectedFirst := Random(100000);
        ExpectedSecond := Random(100000);

        Assert.AreEqual(ExpectedFirst, CaseValues.FirstValue(), 'Every case must reset before GetTestCase, including the first.');
        Assert.AreEqual(ExpectedSecond, CaseValues.SecondValue(), 'First library use in the provider must not reset again.');
        LibraryRandom.SetSeed(8721);
    end;

    [TestDataSource(Codeunit::"Library Random Test Cases", 'Explicit')]
    procedure ExplicitProviderSeedIsPreserved(Context: Interface System.Test.ITestContext)
    var
        CaseValues: Codeunit "Library Random Test Cases";
        ExpectedFirst: Integer;
        ExpectedSecond: Integer;
        ActualNext: Integer;
    begin
        ActualNext := LibraryRandom.RandInt(100000);
        Randomize(91);
        ExpectedFirst := Random(100000);
        ExpectedSecond := Random(100000);

        Assert.AreEqual(ExpectedFirst, CaseValues.FirstValue(), 'The provider must be able to choose its own seed.');
        Assert.AreEqual(ExpectedSecond, ActualNext, 'No reset may occur between GetTestCase and the test body.');
    end;
}
