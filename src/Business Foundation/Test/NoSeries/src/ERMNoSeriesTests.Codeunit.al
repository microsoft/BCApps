// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Test.Foundation.NoSeries;

using System.TestLibraries.Utilities;
using System.TestLibraries.Security.AccessControl;
using Microsoft.Foundation.NoSeries;

codeunit 134370 "ERM No. Series Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [No. Series]
    end;

    var
        LibraryAssert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        StartingNumberTxt: Label 'ABC00010D';
        SecondNumberTxt: Label 'ABC00020D';
        EndingNumberTxt: Label 'ABC00090D';
        NoSeriesCodeForUseInModalPageHandler: Code[20];

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestStartingNoNoGaps()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 1, false, NoSeriesLine);
        LibraryAssert.AreEqual('', NoSeries.GetLastNoUsed(NoSeriesLine."Series Code"), 'lastUsedNo function before taking a number');
        LibraryAssert.AreEqual(0D, NoSeriesLine."Last Date Used", 'Last Date used should be 0D');

        // test
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, true), 'No gaps diff');
        LibraryAssert.AreEqual(IncStr(StartingNumberTxt), NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, true), 'No gaps diff');

        NoSeriesLine.Get(NoSeriesLine."Series Code", NoSeriesLine."Line No.");
        LibraryAssert.AreEqual(IncStr(StartingNumberTxt), NoSeriesLine."Last No. Used", 'last no. used field');
        LibraryAssert.AreEqual(IncStr(StartingNumberTxt), NoSeries.GetLastNoUsed(NoSeriesLine."Series Code"), 'lastUsedNo function');
        LibraryAssert.AreEqual(Today(), NoSeriesLine."Last Date Used", 'Last Date used should be WorkDate');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestStartingNoWithGaps()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 1, true, NoSeriesLine);
        LibraryAssert.AreEqual('', NoSeries.GetLastNoUsed(NoSeriesLine."Series Code"), 'lastUsedNo function before taking a number');
        LibraryAssert.AreEqual(ToBigInt(10), NoSeriesLine."Starting Sequence No.", 'Starting Sequence No. is wrong');
        LibraryAssert.AreEqual(ToBigInt(9), NumberSequence.Current(NoSeriesLine."Sequence Name"), 'Current value wrong');
        LibraryAssert.AreEqual(0D, NoSeriesLine."Last Date Used", 'Last Date used should be 0D');

        // test
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, true), 'With gaps diff');
        LibraryAssert.AreEqual(ToBigInt(10), NumberSequence.Current(NoSeriesLine."Sequence Name"), 'Current value wrong');
        LibraryAssert.AreEqual(IncStr(StartingNumberTxt), NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, true), 'With gaps diff');
        LibraryAssert.AreEqual(ToBigInt(11), NumberSequence.Current(NoSeriesLine."Sequence Name"), 'Current value wrong');

        NoSeriesLine.Get(NoSeriesLine."Series Code", NoSeriesLine."Line No.");
        LibraryAssert.AreEqual('', NoSeriesLine."Last No. Used", 'last no. used field');
        LibraryAssert.AreEqual(IncStr(StartingNumberTxt), NoSeries.GetLastNoUsed(NoSeriesLine."Series Code"), 'lastUsedNo function');
        LibraryAssert.AreEqual(Today(), NoSeriesLine."Last Date Used", 'Last Date used should be WorkDate');
    end;

#if not CLEAN24
#pragma warning disable AL0432
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestChangingToAllowGaps()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 10, false, NoSeriesLine);
        LibraryAssert.AreEqual('', NoSeries.GetLastNoUsed(NoSeriesLine."Series Code"), 'lastUsedNo function before taking a number');
        LibraryAssert.AreEqual(ToBigInt(0), NoSeriesLine."Starting Sequence No.", 'Starting Sequence No. is wrong');

        // test - enable Allow gaps
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, true), 'With gaps diff');
        NoSeriesLine.Find();
        NoSeriesLine.Validate("Allow Gaps in Nos.", true);
        NoSeriesLine.Modify();
        LibraryAssert.AreEqual(ToBigInt(10), NoSeriesLine."Starting Sequence No.", 'Starting Sequence No. is wrong after conversion');
        LibraryAssert.AreEqual('', NoSeriesLine."Last No. Used", 'last no. used field');
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeries.GetLastNoUsed(NoSeriesLine), 'lastUsedNo function after conversion');
        LibraryAssert.AreEqual(SecondNumberTxt, NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, true), 'GetNextNo after conversion');
        LibraryAssert.AreEqual(SecondNumberTxt, NoSeries.GetLastNoUsed(NoSeriesLine), 'lastUsedNo after taking new no. after conversion');
        // Change back to not allow gaps
        NoSeriesLine.Find();
        NoSeriesLine.Validate("Allow Gaps in Nos.", false);
        NoSeriesLine.Modify();
        LibraryAssert.AreEqual(SecondNumberTxt, NoSeriesLine."Last No. Used", 'last no. used field after reset');
        LibraryAssert.AreEqual(SecondNumberTxt, NoSeries.GetLastNoUsed(NoSeriesLine), 'lastUsedNo  after reset');
    end;
#pragma warning restore AL0432
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestChangingToSequence()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 10, false, NoSeriesLine);
        LibraryAssert.AreEqual('', NoSeries.GetLastNoUsed(NoSeriesLine."Series Code"), 'lastUsedNo function before taking a number');
        LibraryAssert.AreEqual(ToBigInt(0), NoSeriesLine."Starting Sequence No.", 'Starting Sequence No. is wrong');

        // test - enable Allow gaps
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, true), 'With gaps diff');
        NoSeriesLine.Find();
        NoSeriesLine.Validate(Implementation, Enum::"No. Series Implementation"::Sequence);
        NoSeriesLine.Modify();
        LibraryAssert.AreEqual(ToBigInt(10), NoSeriesLine."Starting Sequence No.", 'Starting Sequence No. is wrong after conversion');
        LibraryAssert.AreEqual('', NoSeriesLine."Last No. Used", 'last no. used field');
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeries.GetLastNoUsed(NoSeriesLine), 'lastUsedNo function after conversion');
        LibraryAssert.AreEqual(SecondNumberTxt, NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, true), 'GetNextNo after conversion');
        LibraryAssert.AreEqual(SecondNumberTxt, NoSeries.GetLastNoUsed(NoSeriesLine), 'lastUsedNo after taking new no. after conversion');
        // Change back to not allow gaps
        NoSeriesLine.Find();
        NoSeriesLine.Validate(Implementation, Enum::"No. Series Implementation"::Normal);
        NoSeriesLine.Modify();
        LibraryAssert.AreEqual(SecondNumberTxt, NoSeriesLine."Last No. Used", 'last no. used field after reset');
        LibraryAssert.AreEqual(SecondNumberTxt, NoSeries.GetLastNoUsed(NoSeriesLine), 'lastUsedNo  after reset');
    end;

#if not CLEAN24
#pragma warning disable AL0432
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestChangingToAllowGapsDateOrder()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 10, false, NoSeriesLine);
        NoSeries.Get('TEST');
        NoSeries."Date Order" := true;
        NoSeries.Modify();

        // test - enable Allow gaps should be allowed
        NoSeriesLine.Validate("Allow Gaps in Nos.", true);
    end;
#pragma warning restore AL0432
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestChangingToSequenceDateOrder()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 10, false, NoSeriesLine);
        NoSeries.Get('TEST');
        NoSeries."Date Order" := true;
        NoSeries.Modify();

        // test - enable sequence should be allowed
        NoSeriesLine.Validate(Implementation, Enum::"No. Series Implementation"::Sequence);
    end;

#if not CLEAN24
#pragma warning disable AL0432
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestChangingStartNoAfterUsingNoSeries()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        FormattedNo: Code[20];
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 10, false, NoSeriesLine);
        NoSeriesLine."Starting No." := 'A000001';
        NoSeriesLine."Last No. Used" := 'A900001';
        NoSeriesLine.Validate("Allow Gaps in Nos.", true);
        NoSeriesLine.Modify();

        // test - getting formatted number still works
        FormattedNo := NoSeries.GetLastNoUsed(NoSeriesLine."Series Code");
        LibraryAssert.AreEqual('A900001', FormattedNo, 'Init did not work...');
        NoSeriesLine."Starting No." := 'A';
        NoSeriesLine.Modify();
        FormattedNo := NoSeries.GetLastNoUsed(NoSeriesLine."Series Code");
        LibraryAssert.AreEqual('A900001', FormattedNo, 'Default did not work');
    end;
#pragma warning restore AL0432
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestChangingStartNoAfterUsingSequenceNoSeries()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        FormattedNo: Code[20];
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 10, false, NoSeriesLine);
        NoSeriesLine."Starting No." := 'A000001';
        NoSeriesLine."Last No. Used" := 'A900001';
        NoSeriesLine.Validate(Implementation, Enum::"No. Series Implementation"::Sequence);
        NoSeriesLine.Modify();

        // test - getting formatted number still works
        FormattedNo := NoSeries.GetLastNoUsed(NoSeriesLine."Series Code");
        LibraryAssert.AreEqual('A900001', FormattedNo, 'Init did not work...');
        NoSeriesLine."Starting No." := 'A';
        NoSeriesLine.Modify();
        FormattedNo := NoSeries.GetLastNoUsed(NoSeriesLine."Series Code");
        LibraryAssert.AreEqual('A900001', FormattedNo, 'Default did not work');
    end;

#if not CLEAN24
#pragma warning disable AL0432
    [Obsolete('"Allow Gaps in Nos." is obsolete. Use the Implementation field instead.', '24.0')]
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestChangingStartNoAfterUsingNoSeriesTooLong()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        FormattedNo: Code[20];
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 10, false, NoSeriesLine);
        NoSeriesLine."Starting No." := 'ABC00000000000000001';
        NoSeriesLine."Ending No." := 'ABC10000000000000900';
        NoSeriesLine."Last No. Used" := 'ABC10000000000000001';
        NoSeriesLine.Validate("Allow Gaps in Nos.", true);
        NoSeriesLine.Modify();

        // test - getting formatted number still works
        FormattedNo := NoSeries.GetLastNoUsed(NoSeriesLine."Series Code");
        LibraryAssert.AreEqual('ABC10000000000000001', FormattedNo, 'Init did not work...');
        NoSeriesLine."Starting No." := 'ABCD';
        NoSeriesLine.Modify();
        FormattedNo := NoSeries.GetLastNoUsed(NoSeriesLine."Series Code"); // will become too long, so we truncate the prefix
        LibraryAssert.AreEqual('A10000000000000001', FormattedNo, 'Default did not work');
    end;
#pragma warning restore AL0432
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestChangingStartNoAfterUsingNoSeriesTooLongWithSequence()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        FormattedNo: Code[20];
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 10, false, NoSeriesLine);
        NoSeriesLine."Starting No." := 'ABC00000000000000001';
        NoSeriesLine."Ending No." := 'ABC10000000000000900';
        NoSeriesLine."Last No. Used" := 'ABC10000000000000001';
        NoSeriesLine.Validate(Implementation, Enum::"No. Series Implementation"::Sequence);
        NoSeriesLine.Modify();

        // test - getting formatted number still works
        FormattedNo := NoSeries.GetLastNoUsed(NoSeriesLine."Series Code");
        LibraryAssert.AreEqual('ABC10000000000000001', FormattedNo, 'Init did not work...');
        NoSeriesLine."Starting No." := 'ABCD';
        NoSeriesLine.Modify();
        FormattedNo := NoSeries.GetLastNoUsed(NoSeriesLine."Series Code"); // will become too long, so we truncate the prefix
        LibraryAssert.AreEqual('A10000000000000001', FormattedNo, 'Default did not work');
    end;

#if not CLEAN24
#pragma warning disable AL0432
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheLastNoUsedDidNotChangeAfterEnabledAllowGapsInNos()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesLines: TestPage "No. Series Lines";
        LastNoUsed: Code[20];
    begin
        // [SCENARIO 365394] The "Last No. Used" should not changed after enabled and disabled "Allow Gaps in Nos." for No Series, which included only digits
        Initialize();

        // [GIVEN] Created No Series with "Allow Gaps in Nos." = true and "Last No. Used"
        CreateNewNumberSeries('TEST', 10, false, NoSeriesLine);
        NoSeriesLine."Starting No." := '1000001';
        LastNoUsed := '1000023';
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine.Validate("Allow Gaps in Nos.", true);

        // [GIVEN] Change "Allow Gaps in Nos." to false
        NoSeriesLine.Validate("Allow Gaps in Nos.", false);

        // [GIVEN] Change "Allow Gaps in Nos." to true
        NoSeriesLine.Validate("Allow Gaps in Nos.", true);
        NoSeriesLine.Modify();

        // [WHEN] Open page 457 "No. Series Lines"
        NoSeriesLines.OpenEdit();
        NoSeriesLines.Filter.SetFilter("Series Code", NoSeriesLine."Series Code");
        NoSeriesLines.Filter.SetFilter("Line No.", Format(NoSeriesLine."Line No."));
        NoSeriesLines.First();

        // [THEN] "Last No. Used" did not change
        NoSeriesLines."Last No. Used".AssertEquals(LastNoUsed);
    end;
#pragma warning restore AL0432
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheLastNoUsedDidNotChangeAfterUsingSequenceImplementationInNos()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesLines: TestPage "No. Series Lines";
        LastNoUsed: Code[20];
    begin
        // [SCENARIO 365394] The "Last No. Used" should not changed after enabled and disabled "Allow Gaps in Nos." for No Series, which included only digits
        Initialize();

        // [GIVEN] Created No Series with Implementation = Sequence and "Last No. Used"
        CreateNewNumberSeries('TEST', 10, false, NoSeriesLine);
        NoSeriesLine."Starting No." := '1000001';
        LastNoUsed := '1000023';
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine.Validate(Implementation, Enum::"No. Series Implementation"::Sequence);

        // [GIVEN] Change Implementation to Normal
        NoSeriesLine.Validate(Implementation, Enum::"No. Series Implementation"::Normal);

        // [GIVEN] Change Implementation to Sequence
        NoSeriesLine.Validate(Implementation, Enum::"No. Series Implementation"::Sequence);
        NoSeriesLine.Modify();

        // [WHEN] Open page 457 "No. Series Lines"
        NoSeriesLines.OpenEdit();
        NoSeriesLines.Filter.SetFilter("Series Code", NoSeriesLine."Series Code");
        NoSeriesLines.Filter.SetFilter("Line No.", Format(NoSeriesLine."Line No."));
        NoSeriesLines.First();

        // [THEN] "Last No. Used" did not change
        NoSeriesLines."Last No. Used".AssertEquals(LastNoUsed);
    end;

#if not CLEAN24
#pragma warning disable AL0432
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestInsertFromExternalWithGaps()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 1, false, NoSeriesLine);
        // Simulate that NoSeriesLine was inserted programmatically without triggering creation of Sequence
        NoSeriesLine."Allow Gaps in Nos." := true;
        NoSeriesLine.Implementation := Enum::"No. Series Implementation"::Sequence;
        NoSeriesLine."Sequence Name" := Format(CreateGuid());
        NoSeriesLine."Sequence Name" := CopyStr(CopyStr(NoSeriesLine."Sequence Name", 2, StrLen(NoSeriesLine."Sequence Name") - 2), 1, MaxStrLen(NoSeriesLine."Sequence Name"));
        NoSeriesLine.Modify();

        LibraryAssert.AreEqual('', NoSeries.GetLastNoUsed(NoSeriesLine."Series Code"), 'lastUsedNo function before taking a number');

        // test
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, true), 'Gaps diff');
        LibraryAssert.AreEqual(IncStr(StartingNumberTxt), NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, true), 'Gaps diff');
    end;
#pragma warning restore AL0432
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestInsertFromExternalWithSequence()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 1, false, NoSeriesLine);
        // Simulate that NoSeriesLine was inserted programmatically without triggering creation of Sequence
        NoSeriesLine.Implementation := Enum::"No. Series Implementation"::Sequence;
        NoSeriesLine."Sequence Name" := Format(CreateGuid());
        NoSeriesLine."Sequence Name" := CopyStr(CopyStr(NoSeriesLine."Sequence Name", 2, StrLen(NoSeriesLine."Sequence Name") - 2), 1, MaxStrLen(NoSeriesLine."Sequence Name"));
        NoSeriesLine.Modify();

        LibraryAssert.AreEqual('', NoSeries.GetLastNoUsed(NoSeriesLine."Series Code"), 'lastUsedNo function before taking a number');

        // test
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, true), 'Gaps diff');
        LibraryAssert.AreEqual(IncStr(StartingNumberTxt), NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, true), 'Gaps diff');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestModifyNoGetNextWithoutGaps()
    begin
        ModifyNoGetNext(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestModifyNoGetNextWithGaps()
    begin
        ModifyNoGetNext(true);
    end;

    local procedure ModifyNoGetNext(AllowGaps: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 1, AllowGaps, NoSeriesLine);

        // test
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, false), 'Gaps diff - first');
        LibraryAssert.AreEqual(IncStr(StartingNumberTxt), NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, false), 'Gaps diff - second');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestSaveNoSeriesWithOutGaps()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
    begin
        Initialize();
        CreateNewNumberSeriesWithAllowGaps('TEST', 1, NoSeriesLine);

        // test
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeriesBatch.GetNextNo(NoSeriesLine."Series Code", Today), 'Gaps diff');
        LibraryAssert.AreEqual(IncStr(StartingNumberTxt), NoSeriesBatch.GetNextNo(NoSeriesLine."Series Code", Today), 'Gaps diff');
        NoSeriesBatch.SaveState();
        Clear(NoSeriesBatch);
        NoSeriesLine.Get(NoSeriesLine."Series Code", NoSeriesLine."Line No.");
        LibraryAssert.AreEqual(IncStr(StartingNumberTxt), NoSeriesBatch.GetLastNoUsed(NoSeriesLine), 'No. series not updated correctly');
        LibraryAssert.AreEqual(IncStr(IncStr(StartingNumberTxt)), NoSeriesBatch.GetNextNo(NoSeriesLine."Series Code", Today), 'GetNext after Save');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestSaveNoSeriesWithGaps()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
    begin
        Initialize();
        CreateNewNumberSeriesWithoutAllowGaps('TEST', 1, NoSeriesLine);

        // test
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeriesBatch.GetNextNo(NoSeriesLine."Series Code", Today), 'Gaps diff');
        LibraryAssert.AreEqual(IncStr(StartingNumberTxt), NoSeriesBatch.GetNextNo(NoSeriesLine."Series Code", Today), 'Gaps diff');
        NoSeriesBatch.SaveState();
        Clear(NoSeriesBatch);
        NoSeriesLine.Get(NoSeriesLine."Series Code", NoSeriesLine."Line No.");
        LibraryAssert.AreEqual(IncStr(StartingNumberTxt), NoSeriesLine."Last No. Used", 'No. series not updated correctly');
        LibraryAssert.AreEqual(IncStr(IncStr(StartingNumberTxt)), NoSeriesBatch.GetNextNo(NoSeriesLine."Series Code", Today), 'GetNext after Save');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestCurrentAndNextDifferWithOutGaps()
    begin
        CurrentAndNextDiffer(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestCurrentAndNextDifferWithGaps()
    begin
        CurrentAndNextDiffer(true);
    end;

    local procedure CurrentAndNextDiffer(AllowGaps: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 1, AllowGaps, NoSeriesLine);

        // test
        LibraryAssert.AreEqual('', NoSeries.GetLastNoUsed(NoSeriesLine), 'Wrong last no.');
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, false), 'Wrong first no.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoSeriesWithoutNoSeriesLineFailsValidation()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesPage: TestPage "No. Series";
    begin
        // Create no. series without no. series line
        Initialize();
        CreateNewNumberSeries('TEST', 1, true, NoSeriesLine);
        NoSeriesLine.Delete();

        // Invoke TestNoSeries action
        NoSeriesPage.OpenEdit();
        NoSeriesPage.GoToKey('TEST');
        asserterror NoSeriesPage.TestNoSeriesSingle.Invoke();

        // Error is thrown
        LibraryAssert.ExpectedError('You cannot assign new numbers from the number series TEST');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoSeriesWithNoSeriesLineOnLaterStartingDateFailsValidation()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesPage: TestPage "No. Series";
    begin
        // Create no. series without no. series line
        Initialize();
        CreateNewNumberSeries('TEST', 1, true, NoSeriesLine);
        NoSeriesLine.Validate("Starting Date", CalcDate('<+1M>', WorkDate()));
        NoSeriesLine.Modify(true);

        // Invoke TestNoSeries action
        NoSeriesPage.OpenEdit();
        NoSeriesPage.GoToKey('TEST');
        asserterror NoSeriesPage.TestNoSeriesSingle.Invoke();

        // Error is thrown
        LibraryAssert.ExpectedError('You cannot assign new numbers from the number series TEST on ');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('TestSeriesSuccessMessageHandler')]
    procedure NoSeriesThatCanGenerateNextNoSucceedsValidation()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesPage: TestPage "No. Series";
    begin
        // Create no. series without no. series line
        Initialize();
        CreateNewNumberSeries('TEST', 1, true, NoSeriesLine);

        // Invoke TestNoSeries action succeeds
        NoSeriesPage.OpenEdit();
        NoSeriesPage.GoToKey('TEST');
        NoSeriesPage.TestNoSeriesSingle.Invoke();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('TestSeriesSuccessMessageHandler')]
    procedure NoSeriesValidationDoesNotChangeTheNextNoGenerated()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesPage: TestPage "No. Series";
    begin
        // Create no. series without no. series line
        Initialize();
        CreateNewNumberSeries('TEST', 1, true, NoSeriesLine); // todo: test fails when using sequence. Not sure how it passed before

        // Invoke TestNoSeries action succeeds
        NoSeriesPage.OpenEdit();
        NoSeriesPage.GoToKey('TEST');
        NoSeriesPage.TestNoSeriesSingle.Invoke();

        // Ensure invoking TestNoSeries action does not modify the series
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeries.GetNextNo('TEST', WorkDate(), true), 'DoGetNextNo does not get the first no in the no series');

        // Invoke TestNoSeries action again
        NoSeriesPage.TestNoSeriesSingle.Invoke();

        // Ensure invoking TestNoSeries action does not modify the series
        LibraryAssert.AreEqual(IncStr(StartingNumberTxt), NoSeries.GetNextNo('TEST', WorkDate(), true), 'DoGetNextNo does the get the second no in the no series');
    end;

#if not CLEAN24
#pragma warning disable AL0432
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheLastNoUsedCanBeUpdatedWhenAllowGapsInNosYes()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesLines: TestPage "No. Series Lines";
        LastNoUsed: Code[20];
        NewLastNoUsed: Code[20];
    begin
        // [SCENARIO 428940] The "Last No. Used" can be updated when "Allow Gaps in Nos." = Yes
        Initialize();

        // [GIVEN] Created No Series with "Allow Gaps in Nos." = true and "Last No. Used" = '1000023'
        CreateNewNumberSeries('TEST', 10, false, NoSeriesLine);
        NoSeriesLine."Starting No." := '1000001';
        LastNoUsed := '1000023';
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine.Validate("Allow Gaps in Nos.", true);
        NoSeriesLine.Modify();

        // [GIVEN] Open page 457 "No. Series Lines"
        NoSeriesLines.OpenEdit();
        NoSeriesLines.Filter.SetFilter("Series Code", NoSeriesLine."Series Code");
        NoSeriesLines.Filter.SetFilter("Line No.", Format(NoSeriesLine."Line No."));
        NoSeriesLines.First();

        // [GIVEN] "Last No. Used" is changed to '1000025'
        NewLastNoUsed := '1000025';
        NoSeriesLines."Last No. Used".SetValue(NewLastNoUsed);
        // [WHEN] Move focus to new line and return it back
        NoSeriesLines.New();
        NoSeriesLines.First();
        // [THEN] "Last No. Used" = '1000025' in the page
        NoSeriesLines."Last No. Used".AssertEquals(NewLastNoUsed);
        NoSeriesLines.OK().Invoke();

        // [THEN] "Last No. Used" is empty in the table
        NoSeriesLine.Find();
        NoSeriesLine.TestField("Last No. Used", '');
    end;
#pragma warning restore AL0432
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheLastNoUsedCanBeUpdatedWhenImplementationSequenceIsUsed()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesLines: TestPage "No. Series Lines";
        LastNoUsed: Code[20];
        NewLastNoUsed: Code[20];
    begin
        // [SCENARIO 428940] The "Last No. Used" can be updated when Implementation = Sequence
        Initialize();

        // [GIVEN] Created No Series with Implementation = Sequence and "Last No. Used" = '1000023'
        CreateNewNumberSeries('TEST', 10, false, NoSeriesLine);
        NoSeriesLine."Starting No." := '1000001';
        LastNoUsed := '1000023';
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine.Validate(Implementation, Enum::"No. Series Implementation"::Sequence);
        NoSeriesLine.Modify();

        // [GIVEN] Open page 457 "No. Series Lines"
        NoSeriesLines.OpenEdit();
        NoSeriesLines.Filter.SetFilter("Series Code", NoSeriesLine."Series Code");
        NoSeriesLines.Filter.SetFilter("Line No.", Format(NoSeriesLine."Line No."));
        NoSeriesLines.First();

        // [GIVEN] "Last No. Used" is changed to '1000025'
        NewLastNoUsed := '1000025';
        NoSeriesLines."Last No. Used".SetValue(NewLastNoUsed);
        // [WHEN] Move focus to new line and return it back
        NoSeriesLines.New();
        NoSeriesLines.First();
        // [THEN] "Last No. Used" = '1000025' in the page
        NoSeriesLines."Last No. Used".AssertEquals(NewLastNoUsed);
        NoSeriesLines.OK().Invoke();

        // [THEN] "Last No. Used" is empty in the table
        NoSeriesLine.Find();
        NoSeriesLine.TestField("Last No. Used", '');
    end;

    local procedure CreateNewNumberSeriesWithAllowGaps(NewName: Code[20]; IncrementBy: Integer; var NoSeriesLine: Record "No. Series Line")
    begin
        CreateNewNumberSeries(NewName, IncrementBy, true, NoSeriesLine);
    end;

    local procedure CreateNewNumberSeriesWithoutAllowGaps(NewName: Code[20]; IncrementBy: Integer; var NoSeriesLine: Record "No. Series Line")
    begin
        CreateNewNumberSeries(NewName, IncrementBy, false, NoSeriesLine);
    end;

#IF NOT clean24
    local procedure CreateNewNumberSeries(NewName: Code[20]; IncrementBy: Integer; AllowGaps: Boolean; var NoSeriesLine: Record "No. Series Line")
    begin
        if AllowGaps then
            CreateNewNumberSeries(NewName, IncrementBy, Enum::"No. Series Implementation"::Sequence, NoSeriesLine)
        else
            CreateNewNumberSeries(NewName, IncrementBy, Enum::"No. Series Implementation"::Normal, NoSeriesLine);
    end;
#endif

    local procedure CreateNewNumberSeries(NewName: Code[20]; IncrementBy: Integer; Implementation: Enum "No. Series Implementation"; var NoSeriesLine: Record "No. Series Line")
    begin
        CreateNewNumberSeries(NewName);
        CreateNewNumberSeriesLine(NewName, IncrementBy, Implementation, NoSeriesLine);
    end;

    local procedure CreateNewNumberSeries(NewName: Code[20]);
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Code := NewName;
        NoSeries.Description := NewName;
        NoSeries."Default Nos." := true;
        NoSeries.Insert();
    end;

    local procedure CreateNewNumberSeriesLine(NewName: Code[20]; IncrementBy: Integer; Implementation: Enum "No. Series Implementation"; var NoSeriesLine: Record "No. Series Line");
    begin
        NoSeriesLine."Series Code" := NewName;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine.Validate("Starting No.", StartingNumberTxt);
        NoSeriesLine.Validate("Ending No.", EndingNumberTxt);
        NoSeriesLine."Increment-by No." := IncrementBy;
        NoSeriesLine.Insert(true);
        NoSeriesLine.Validate(Implementation, Implementation);
        NoSeriesLine.Modify(true);
    end;

    local procedure CreateNoSeriesRelation(MainSeriesCode: Code[20]; RelatedSeriesCode: Code[20]);
    var
        NoSeriesRelation: Record "No. Series Relationship";
    begin
        NoSeriesRelation.Code := MainSeriesCode;
        NoSeriesRelation."Series Code" := RelatedSeriesCode;
        NoSeriesRelation.Insert();
    end;

#if not CLEAN24
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageNoSeriesChangeAllowGapsTrueOne()
    begin
        PageNoSeriesChangeAllowGaps(true, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageNoSeriesChangeAllowGapsFalseOne()
    begin
        PageNoSeriesChangeAllowGaps(false, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageNoSeriesChangeAllowGapsTrueMultiple()
    begin
        PageNoSeriesChangeAllowGaps(true, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageNoSeriesChangeAllowGapsFalseMultiple()
    begin
        PageNoSeriesChangeAllowGaps(false, 1);
    end;
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageNoSeriesChangeImplementationTrueOne()
    begin
        PageNoSeriesChangeImplementation(Enum::"No. Series Implementation"::Sequence, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageNoSeriesChangeImplementationFalseOne()
    begin
        PageNoSeriesChangeImplementation(Enum::"No. Series Implementation"::Normal, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageNoSeriesChangeImplementationTrueMultiple()
    begin
        PageNoSeriesChangeImplementation(Enum::"No. Series Implementation"::Sequence, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageNoSeriesChangeImplementationFalseMultiple()
    begin
        PageNoSeriesChangeImplementation(Enum::"No. Series Implementation"::Normal, 1);
    end;

#if not CLEAN24
#pragma warning disable AL0432
    local procedure PageNoSeriesChangeAllowGaps(NewAllowGaps: Boolean; NoOfLines: Integer)
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesList: TestPage "No. Series";
        i: Integer;
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 1, not NewAllowGaps, NoSeriesLine);
        for i := 2 to NoOfLines do begin
            NoSeriesLine."Line No." += 10000;
            NoSeriesLine."Starting Date" := WorkDate() + i;
            NoSeriesLine.Insert();
        end;
        NoSeries.Get('TEST');

        // Set Allow Gaps from No. Series list page.
        NoSeriesList.OpenEdit();
        NoSeriesList.GoToRecord(NoSeries);
        NoSeriesList.AllowGapsCtrl.SetValue(NewAllowGaps);

        // validate
        NoSeriesLine.SetRange("Series Code", NoSeriesLine."Series Code");
        if NoSeriesLine.FindSet() then
            repeat
                if NoOfLines = 1 then
                    LibraryAssert.AreEqual(NewAllowGaps, NoSeriesLine."Allow Gaps in Nos.", 'First No. Series Line not updated.')
                else
                    if NoSeriesLine."Starting Date" < WorkDate() then
                        LibraryAssert.AreEqual(not NewAllowGaps, NoSeriesLine."Allow Gaps in Nos.", 'No. Series Line updated when it should not.')
                    else
                        LibraryAssert.AreEqual(NewAllowGaps, NoSeriesLine."Allow Gaps in Nos.", 'No. Series Line not updated.');
            until NoSeriesLine.Next() = 0;
    end;
#pragma warning restore AL0432
#endif

    local procedure PageNoSeriesChangeImplementation(Implementation: Enum "No. Series Implementation"; NoOfLines: Integer)
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesList: TestPage "No. Series";
        i: Integer;
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 1, Implementation, NoSeriesLine);
        for i := 2 to NoOfLines do begin
            NoSeriesLine."Line No." += 10000;
            NoSeriesLine."Starting Date" := WorkDate() + i;
            NoSeriesLine.Insert();
        end;
        NoSeries.Get('TEST');

        // Set Allow Gaps from No. Series list page.
        NoSeriesList.OpenEdit();
        NoSeriesList.GoToRecord(NoSeries);
        NoSeriesList.Implementation.SetValue(Implementation);

        // validate
        NoSeriesLine.SetRange("Series Code", NoSeriesLine."Series Code");
        if NoSeriesLine.FindSet() then
            repeat
                if NoOfLines = 1 then
                    LibraryAssert.AreEqual(Implementation, NoSeriesLine.Implementation, 'First No. Series Line not updated.')
                else
                    if NoSeriesLine."Starting Date" < WorkDate() then
                        LibraryAssert.AreNotEqual(Implementation, NoSeriesLine.Implementation, 'No. Series Line updated when it should not.')
                    else
                        LibraryAssert.AreEqual(Implementation, NoSeriesLine.Implementation, 'No. Series Line not updated.');
            until NoSeriesLine.Next() = 0;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChangeIncrementWithGaps()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 1, true, NoSeriesLine);

        // test
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, true), 'With gaps diff');
        LibraryAssert.AreEqual(ToBigInt(10), NumberSequence.Current(NoSeriesLine."Sequence Name"), 'Current value wrong');
        NoSeriesLine.Get(NoSeriesLine."Series Code", NoSeriesLine."Line No.");
        NoSeriesLine.Validate("Increment-by No.", 2);
        NoSeriesLine.Modify();
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeries.GetLastNoUsed(NoSeriesLine), 'Last Used No. changed after changing increment');
        LibraryAssert.AreEqual(IncStr(IncStr(StartingNumberTxt)), NoSeries.GetNextNo(NoSeriesLine."Series Code", Today, true), 'With gaps diff after change of increment');
        NoSeriesLine.Get(NoSeriesLine."Series Code", NoSeriesLine."Line No.");
        LibraryAssert.AreEqual(ToBigInt(12), NumberSequence.Current(NoSeriesLine."Sequence Name"), 'Current value wrong after first use after change of increment');
    end;

    [Test]
    procedure SettingDefaultNosFalseWhenManualNosIsFalseForcesManualNosToTrue()
    var
        NoSeries: Record "No. Series";
    begin
        // [GIVEN] NoSeries where Default Nos is TRUE and Manual Nos is FALSE
        Initialize();
        NoSeries.Get(CreateNonVisibleNoSeries(false));
        NoSeries.Validate("Default Nos.", true);
        NoSeries.Validate("Manual Nos.", false);

        // [WHEN] When Default Nos is et to FALSE
        NoSeries.Validate("Default Nos.", false);

        // [THEN] Manual Nos is forced to be true because both Manual Nos and Default Nos being FALSE is not a valid scenario
        NoSeries.TestField("Manual Nos.", true);
    end;

    [Test]
    procedure SettingManualNosFalseWhenDefaultNosIsFalseForcesDefaultNosToTrue()
    var
        NoSeries: Record "No. Series";
    begin
        // [GIVEN] NoSeries where Manual Nos is TRUE and Default Nos is FALSE
        Initialize();
        NoSeries.Get(CreateNonVisibleNoSeries(false));
        NoSeries.Validate("Manual Nos.", true);
        NoSeries.Validate("Default Nos.", false);

        // [WHEN] When Manual Nos is et to FALSE
        NoSeries.Validate("Manual Nos.", false);

        // [THEN] Default Nos is forced to be true because both Manual Nos and Default Nos being FALSE is not a valid scenario
        NoSeries.TestField("Default Nos.", true);
    end;

    [Test]
    procedure NoSeriesPage_FieldsValues_WithGoodLines()
    var
        NoSeriesRec: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
    begin
        Initialize();

        NoSeriesCode := CreateNonVisibleNoSeries(false);
        NoSeries.GetNoSeriesLine(NoSeriesLine, NoSeriesCode, 0D, true);
        NoSeriesLine.FindFirst();
        NoSeriesRec.Get(NoSeriesCode);

        ValidateFieldsOnNoSeriesPage(NoSeriesRec, NoSeriesLine);
    end;

    [Test]
    procedure NoSeriesPage_FieldsValues_WithoutGoodLines()
    var
        NoSeriesRec: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
    begin
        Initialize();

        NoSeriesCode := CreateNonVisibleNoSeries(false);
        NoSeries.GetNoSeriesLine(NoSeriesLine, NoSeriesCode, 0D, true);
        NoSeriesLine.DeleteAll();
        NoSeriesLine.Reset();
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.FindFirst();

        NoSeriesRec.Get(NoSeriesCode);

        ValidateFieldsOnNoSeriesPage(NoSeriesRec, NoSeriesLine);
    end;

    [Test]
    procedure NoSeriesPage_FieldsValues_WithoutLines()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesCode: Code[20];
    begin
        Initialize();

        NoSeriesCode := CreateNonVisibleNoSeries(false);

        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.DeleteAll();
        if NoSeriesLine.FindFirst() then;

        NoSeries.Get(NoSeriesCode);

        ValidateFieldsOnNoSeriesPage(NoSeries, NoSeriesLine);
    end;

    [Test]
    [HandlerFunctions('NoSeriesLinesPageHandler')]
    procedure NoSeriesPage_DrillDown()
    var
        NoSeries: Record "No. Series";
        NoSeriesPage: TestPage "No. Series";
    begin
        Initialize();

        NoSeriesCodeForUseInModalPageHandler := CreateNonVisibleNoSeries(false);

        NoSeries.Get(NoSeriesCodeForUseInModalPageHandler);
        NoSeriesPage.OpenView();
        NoSeriesPage.GoToRecord(NoSeries);
        NoSeriesPage.StartNo.Drilldown();
        NoSeriesPage.Close();
    end;

    [Test]
    [HandlerFunctions('NoSeriesLookupHandler')]
    procedure TestLookupNoSeries()
    var
        NoSeries: Codeunit "No. Series";
        SelectedNoSeriesCode: Code[20];
    begin
        // init
        Initialize();

        // setup
        CreateNewNumberSeries('TEST');
        CreateNewNumberSeries('TESTRELATED1');
        CreateNewNumberSeries('TESTRELATED2');
        CreateNewNumberSeries('TESTUNRELATED1');
        CreateNewNumberSeries('TESTUNREALTED2');
        CreateNoSeriesRelation('TEST', 'TESTRELATED1');
        CreateNoSeriesRelation('TEST', 'TESTRELATED2');
        LibraryVariableStorage.Enqueue('TEST');

        // exexute
        NoSeries.LookupRelatedNoSeries('TEST', SelectedNoSeriesCode);

        // verify
        LibraryAssert.IsTrue(NoSeries.AreRelated('TEST', 'TESTRELATED2'), 'Related No Series not found');
    end;

    [ModalPageHandler]
    procedure NoSeriesLookupHandler(var NoSeriesTestPage: TestPage "No. Series")
    var
        NoSeries: Codeunit "No. Series";
        NosSeriesCode: Code[20];
    begin
        NosSeriesCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(NosSeriesCode));
        LibraryAssert.IsTrue(NoSeriesTestPage.First(), 'No records found');
        LibraryAssert.IsTrue(NoSeries.AreRelated(NosSeriesCode, CopyStr(NoSeriesTestPage.Code.Value, 1, MaxStrLen(NosSeriesCode))), 'The No. Series must be related');
        LibraryAssert.IsTrue(NoSeriesTestPage.NEXT(), 'Too few records found');
        LibraryAssert.IsTrue(NoSeries.AreRelated(NosSeriesCode, CopyStr(NoSeriesTestPage.Code.Value, 1, MaxStrLen(NosSeriesCode))), 'The No. Series must be related');
        LibraryAssert.IsTrue(NoSeriesTestPage.NEXT(), 'Too few records found');
        LibraryAssert.IsTrue(NoSeries.AreRelated(NosSeriesCode, CopyStr(NoSeriesTestPage.Code.Value, 1, MaxStrLen(NosSeriesCode))), 'The No. Series must be related');
        LibraryAssert.IsFalse(NoSeriesTestPage.NEXT(), 'Too many records found');
        NoSeriesTestPage.OK().Invoke();
    end;


    local procedure DeleteNumberSeries(NameToDelete: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NameToDelete);
        NoSeriesLine.DeleteAll(true);
        if NoSeries.Get(NameToDelete) then
            NoSeries.Delete(true);
    end;

    local procedure ToBigInt(IntValue: Integer): BigInteger
    begin
        exit(IntValue);
    end;

    local procedure CreateNonVisibleNoSeries(SingleLine: Boolean): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Init();
        NoSeries.Code := CopyStr(CreateGuid(), 1, 10);    // todo: use the last instead of the first characters
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := false;
        if not NoSeries.Insert() then;

        if SingleLine then
            CreateNonVisibleNoSeriesLine(NoSeries.Code, 0)
        else begin
            CreateNonVisibleNoSeriesLine(NoSeries.Code, 0);
            CreateNonVisibleNoSeriesLine(NoSeries.Code, 1);
            CreateNonVisibleNoSeriesLine(NoSeries.Code, 2);
        end;

        exit(NoSeries.Code);
    end;

    local procedure CreateNonVisibleNoSeriesLine(NoSeriesCode: Code[20]; Type: Option Good,Future,Ended)
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        if NoSeriesLine.FindLast() then
            NoSeriesLine."Line No." += 1;

        NoSeriesLine."Series Code" := NoSeriesCode;
        NoSeriesLine."Increment-by No." := 1;
        NoSeriesLine."Starting No." := CopyStr(NoSeriesCode, 1, 10) + '0000000001';

        case Type of
            Type::Good:
                begin
                    NoSeriesLine."Ending No." := CopyStr(NoSeriesCode, 1, 10) + '9999999999';
                    NoSeriesLine."Starting Date" := WorkDate() - 1;
                end;
            Type::Future:
                begin
                    NoSeriesLine."Ending No." := CopyStr(NoSeriesCode, 1, 10) + '8888888888';
                    NoSeriesLine."Starting Date" := WorkDate() + 1;
                end;
            Type::Ended:
                begin
                    NoSeriesLine."Ending No." := CopyStr(NoSeriesCode, 1, 10) + '7777777777';
                    NoSeriesLine.Validate("Last No. Used", NoSeriesLine."Ending No.");
                    NoSeriesLine."Starting Date" := WorkDate() - 1;
                end;
        end;

        NoSeriesLine.Insert();
    end;

    [ModalPageHandler]
    procedure NoSeriesLinesPageHandler(var NoSeriesLinesPage: TestPage "No. Series Lines")
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NoSeriesCodeForUseInModalPageHandler);
        NoSeriesLine.Find('-');

        repeat
            LibraryAssert.IsTrue(NoSeriesLinesPage.GotoRecord(NoSeriesLine), 'Cannot find record in set.');
        until NoSeriesLine.Next() = 0;

        NoSeriesLinesPage.OK().Invoke();
    end;

    local procedure ValidateFieldsOnNoSeriesPage(var NoSeries: Record "No. Series"; var NoSeriesLine: Record "No. Series Line")
    var
        NoSeriesPage: TestPage "No. Series";
    begin
        NoSeriesPage.OpenView();
        NoSeriesPage.GotoRecord(NoSeries);

        LibraryAssert.AreEqual(NoSeriesLine."Starting No.", NoSeriesPage.StartNo.Value, 'Wrong "Starting No."');
        LibraryAssert.AreEqual(NoSeriesLine."Ending No.", NoSeriesPage.EndNo.Value, 'Wrong "Ending No."');

        NoSeriesPage.OK().Invoke();
    end;

    local procedure Initialize()
    begin
        PermissionsMock.Set('No. Series - Admin');
        DeleteNumberSeries('TEST');
    end;

    [MessageHandler]
    procedure TestSeriesSuccessMessageHandler(Message: Text[1024])
    begin
        LibraryAssert.IsTrue(Message.StartsWith('The test was successful.'), 'The test series was not successful, message: ' + Message);
    end;
}
