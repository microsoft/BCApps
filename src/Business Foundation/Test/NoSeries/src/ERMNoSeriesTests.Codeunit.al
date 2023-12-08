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
        StartingNumberTxt: Label 'ABC00010D';
        SecondNumberTxt: Label 'ABC00020D';
        EndingNumberTxt: Label 'ABC00090D';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
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
        LibraryAssert.AreEqual(Today(), NoSeriesLine."Last Date Used", 'Last Date used should be workdate');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
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
        LibraryAssert.AreEqual(Today(), NoSeriesLine."Last Date Used", 'Last Date used should be workdate');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
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

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
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

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
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

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestChangingStartNoAfterUsingNoSeriesTooLong()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        FormattedNo: Code[20];
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 10, false, NoSeriesLine);
        NoSeriesLine."Starting No." := 'ABC00000000000000001';
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

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
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

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestInsertFromExternalWithGaps()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 1, false, NoSeriesLine);
        // Simulate that NoSeriesLine was inserted programmatically without triggering creation of Sequence
        NoSeriesLine."Allow Gaps in Nos." := true;
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
    [Scope('OnPrem')]
    procedure TestModifyNoGetNextWithoutGaps()
    begin
        ModifyNoGetNext(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
    procedure TestCurrentAndNextDifferWithOutGaps()
    begin
        CurrentAndNextDiffer(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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

    local procedure CreateNewNumberSeries(NewName: Code[20]; IncrementBy: Integer; AllowGaps: Boolean; var NoSeriesLine: Record "No. Series Line")
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Code := NewName;
        NoSeries.Description := NewName;
        NoSeries."Default Nos." := true;
        NoSeries.Insert();

        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine.Validate("Starting No.", StartingNumberTxt);
        NoSeriesLine.Validate("Ending No.", EndingNumberTxt);
        NoSeriesLine."Increment-by No." := IncrementBy;
        NoSeriesLine.Insert(true);
        NoSeriesLine.Validate("Allow Gaps in Nos.", AllowGaps);
        NoSeriesLine.Modify(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PageNoSeriesChangeAllowGapsTrueOne()
    begin
        PageNoSeriesChangeAllowGaps(true, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PageNoSeriesChangeAllowGapsFalseOne()
    begin
        PageNoSeriesChangeAllowGaps(false, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PageNoSeriesChangeAllowGapsTrueMultiple()
    begin
        PageNoSeriesChangeAllowGaps(true, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PageNoSeriesChangeAllowGapsFalseMultiple()
    begin
        PageNoSeriesChangeAllowGaps(false, 1);
    end;

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

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
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

    local procedure Initialize()
    begin
        PermissionsMock.Set('No. Series - Admin');
        DeleteNumberSeries('TEST');
    end;
}
