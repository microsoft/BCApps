// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Test.Foundation.NoSeries;

using System.TestLibraries.Utilities;
using System.TestLibraries.Security.AccessControl;
using Microsoft.TestLibraries.Foundation.NoSeries;
using Microsoft.Foundation.NoSeries;

codeunit 134531 "No. Series Batch Tests"
{
    Subtype = Test;

    var
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        LibraryNoSeries: Codeunit "Library - No. Series";
        CannotAssignNewErr: Label 'You cannot assign new numbers from the number series %1', Comment = '%1=No. Series Code';

    #region sequence
    [Test]
    procedure TestGetNextNoDefaultRunOut_Sequence()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with 10 numbers
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, '1', '10');

        // [WHEN] We get the first 10 numbers from the No. Series
        // [THEN] The numbers match with 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        for i := 1 to 10 do
            LibraryAssert.AreEqual(Format(i), NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeriesBatch.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNo_Sequence()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with a line going from 1-10, jumping 7 numbers at a time
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 7, '1', '10');

        // [WHEN] We get the first two numbers from the No. Series
        // [THEN] The numbers match with 1, 8
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        LibraryAssert.AreEqual('1', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('8', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeriesBatch.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoWithLastNoUsed_Sequence()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with a line going from 1-10, jumping 2 numbers at a time, with last used number 3
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 2, '1', '10', '3', 0D);

        // [WHEN] We get the first three new numbers from the No. Series
        // [THEN] The numbers match with 5, 7, 9
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        LibraryAssert.AreEqual('5', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('7', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('9', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeriesBatch.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoDefaultOverFlow_Sequence()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with two lines going from 1-5
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, 'A1', 'A5');
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, 'B1', 'B5');

        // [WHEN] We get the first 10 numbers from the No. Series
        // [THEN] The numbers match with A1, A2, A3, A4, A5, B1, B2, B3, B4, B5 (automatically switches from the first to the second series)
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        for i := 1 to 5 do
            LibraryAssert.AreEqual('A' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');
        for i := 1 to 5 do
            LibraryAssert.AreEqual('B' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeriesBatch.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoAdvancedOverFlow_Sequence()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with two lines going from 1-10, jumping 7 numbers at a time
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 7, 'A1', 'A10');
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 7, 'B1', 'B10');

        // [WHEN] We get the first 4 numbers from the No. Series
        // [THEN] The numbers match with A1, A8, B1, B8
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        LibraryAssert.AreEqual('A01', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('A08', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('B01', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('B08', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeriesBatch.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoOverflowOutsideDate_Sequence()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
        TomorrowsWorkDate: Date;
        i: Integer;
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with two lines, one only valid from WorkDate + 1
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, 'A1', 'A5');
        TomorrowsWorkDate := CalcDate('<+1D>', WorkDate());
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, 'B1', 'B5', TomorrowsWorkDate);

        // [WHEN] We get the next number 5 times for WorkDate
        // [THEN] We get the numbers from the first line
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        for i := 1 to 5 do
            LibraryAssert.AreEqual('A' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number for WorkDate without throwing errors
        // [THEN] No number is returned
        LibraryAssert.AreEqual('', NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate(), true), 'A number was returned when it should not have been');

        // [WHEN] We get the next number for WorkDate + 1
        // [THEN] We get the numbers from the second line
        for i := 1 to 5 do
            LibraryAssert.AreEqual('B' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesCode, TomorrowsWorkDate), 'Number was not as expected');

        // [WHEN] We get the next number for WorkDate
        // [THEN] No other numbers are available
        asserterror NoSeriesBatch.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoWithLine_Sequence()
    var
        NoSeriesLineA: Record "No. Series Line";
        NoSeriesLineB: Record "No. Series Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with two lines going from 1-5
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, 'A1', 'A5');
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, 'B1', 'B5');

        NoSeriesLineA.SetRange("Series Code", NoSeriesCode);
        NoSeriesLineA.FindFirst();
        NoSeriesLineB.SetRange("Series Code", NoSeriesCode);
        NoSeriesLineB.FindLast();

        // [WHEN] We request numbers from each line
        // [THEN] We get the numbers for the specific line
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        for i := 1 to 5 do begin
            LibraryAssert.AreEqual('B' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesLineB, WorkDate()), 'Number was not as expected');
            LibraryAssert.AreEqual('A' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesLineA, WorkDate()), 'Number was not as expected');
        end;

        // [WHEN] We get the next number for either line without throwing errors
        // [THEN] No number is returned
        LibraryAssert.AreEqual('', NoSeriesBatch.GetNextNo(NoSeriesLineA, WorkDate(), true), 'A number was returned when it should not have been');
        LibraryAssert.AreEqual('', NoSeriesBatch.GetNextNo(NoSeriesLineB, WorkDate(), true), 'A number was returned when it should not have been');
    end;

    [Test]
    procedure TestPeekNextNoDefaultRunOut_Sequence()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with 10 numbers
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, 'A1Test', 'A10Test');

        // [WHEN] We peek the next number
        // [THEN] We get the first number
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        LibraryAssert.AreEqual('A01TEST', NoSeriesBatch.PeekNextNo(NoSeriesCode), 'Initial number was not as expected');
        LibraryAssert.AreEqual('A01TEST', NoSeriesBatch.PeekNextNo(NoSeriesCode), 'Follow up call to PeekNextNo was not as expected');

        // [WHEN] We peek and get the next number 10 times
        // [THEN] The two match up
        for i := 1 to 10 do
            LibraryAssert.AreEqual(NoSeriesBatch.PeekNextNo(NoSeriesCode), NoSeriesBatch.GetNextNo(NoSeriesCode), 'GetNextNo and PeekNextNo are not aligned');

        // [WHEN] We peek the next number after the series has run out
        // [THEN] An error is thrown
        asserterror NoSeriesBatch.PeekNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;
    #endregion

    #region normal
    [Test]
    procedure TestGetNextNoDefaultRunOut()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with 10 numbers
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateNormalNoSeriesLine(NoSeriesCode, 1, '1', '10');

        // [WHEN] We get the first 10 numbers from the No. Series
        // [THEN] The numbers match with 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        for i := 1 to 10 do
            LibraryAssert.AreEqual(Format(i), NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeriesBatch.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNo()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with a line going from 1-10, jumping 7 numbers at a time
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateNormalNoSeriesLine(NoSeriesCode, 7, '1', '10');

        // [WHEN] We get the first two numbers from the No. Series
        // [THEN] The numbers match with 1, 8
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        LibraryAssert.AreEqual('1', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('8', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeriesBatch.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoWithLastNoUsed()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with a line going from 1-10, jumping 2 numbers at a time, with last used number 3
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateNormalNoSeriesLine(NoSeriesCode, 2, '1', '10', '3', 0D);

        // [WHEN] We get the first three new numbers from the No. Series
        // [THEN] The numbers match with 5, 7, 9
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        LibraryAssert.AreEqual('5', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('7', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('9', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeriesBatch.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoDefaultOverFlow()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with two lines going from 1-5
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateNormalNoSeriesLine(NoSeriesCode, 1, 'A1', 'A5');
        LibraryNoSeries.CreateNormalNoSeriesLine(NoSeriesCode, 1, 'B1', 'B5');

        // [WHEN] We get the first 10 numbers from the No. Series
        // [THEN] The numbers match with A1, A2, A3, A4, A5, B1, B2, B3, B4, B5 (automatically switches from the first to the second series)
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        for i := 1 to 5 do
            LibraryAssert.AreEqual('A' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');
        for i := 1 to 5 do
            LibraryAssert.AreEqual('B' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeriesBatch.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoAdvancedOverFlow()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with two lines going from 1-10, jumping 7 numbers at a time
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateNormalNoSeriesLine(NoSeriesCode, 7, 'A1', 'A10');
        LibraryNoSeries.CreateNormalNoSeriesLine(NoSeriesCode, 7, 'B1', 'B10');

        // [WHEN] We get the first 4 numbers from the No. Series
        // [THEN] The numbers match with A1, A8, B1, B8
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        LibraryAssert.AreEqual('A01', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('A08', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('B01', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('B08', NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeriesBatch.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoOverflowOutsideDate()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
        TomorrowsWorkDate: Date;
        i: Integer;
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with two lines, one only valid from WorkDate + 1
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateNormalNoSeriesLine(NoSeriesCode, 1, 'A1', 'A5');
        TomorrowsWorkDate := CalcDate('<+1D>', WorkDate());
        LibraryNoSeries.CreateNormalNoSeriesLine(NoSeriesCode, 1, 'B1', 'B5', TomorrowsWorkDate);

        // [WHEN] We get the next number 5 times for WorkDate
        // [THEN] We get the numbers from the first line
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        for i := 1 to 5 do
            LibraryAssert.AreEqual('A' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number for WorkDate without throwing errors
        // [THEN] No number is returned
        LibraryAssert.AreEqual('', NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate(), true), 'A number was returned when it should not have been');

        // [WHEN] We get the next number for WorkDate + 1
        // [THEN] We get the numbers from the second line
        for i := 1 to 5 do
            LibraryAssert.AreEqual('B' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesCode, TomorrowsWorkDate), 'Number was not as expected');

        // [WHEN] We get the next number for WorkDate
        // [THEN] No other numbers are available
        asserterror NoSeriesBatch.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoWithLine()
    var
        NoSeriesLineA: Record "No. Series Line";
        NoSeriesLineB: Record "No. Series Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with two lines going from 1-5
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateNormalNoSeriesLine(NoSeriesCode, 1, 'A1', 'A5');
        LibraryNoSeries.CreateNormalNoSeriesLine(NoSeriesCode, 1, 'B1', 'B5');

        NoSeriesLineA.SetRange("Series Code", NoSeriesCode);
        NoSeriesLineA.FindFirst();
        NoSeriesLineB.SetRange("Series Code", NoSeriesCode);
        NoSeriesLineB.FindLast();

        // [WHEN] We request numbers from each line
        // [THEN] We get the numbers for the specific line
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        for i := 1 to 5 do begin
            LibraryAssert.AreEqual('B' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesLineB, WorkDate()), 'Number was not as expected');
            LibraryAssert.AreEqual('A' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesLineA, WorkDate()), 'Number was not as expected');
        end;

        // [WHEN] We get the next number for either line without throwing errors
        // [THEN] No number is returned
        LibraryAssert.AreEqual('', NoSeriesBatch.GetNextNo(NoSeriesLineA, WorkDate(), true), 'A number was returned when it should not have been');
        LibraryAssert.AreEqual('', NoSeriesBatch.GetNextNo(NoSeriesLineB, WorkDate(), true), 'A number was returned when it should not have been');
    end;

    [Test]
    procedure TestPeekNextNoDefaultRunOut()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with 10 numbers
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateNormalNoSeriesLine(NoSeriesCode, 1, 'A1Test', 'A10Test');

        // [WHEN] We peek the next number
        // [THEN] We get the first number
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        LibraryAssert.AreEqual('A01TEST', NoSeriesBatch.PeekNextNo(NoSeriesCode), 'Initial number was not as expected');
        LibraryAssert.AreEqual('A01TEST', NoSeriesBatch.PeekNextNo(NoSeriesCode), 'Follow up call to PeekNextNo was not as expected');

        // [WHEN] We peek and get the next number 10 times
        // [THEN] The two match up
        for i := 1 to 10 do
            LibraryAssert.AreEqual(NoSeriesBatch.PeekNextNo(NoSeriesCode), NoSeriesBatch.GetNextNo(NoSeriesCode), 'GetNextNo and PeekNextNo are not aligned');

        // [WHEN] We peek the next number after the series has run out
        // [THEN] An error is thrown
        asserterror NoSeriesBatch.PeekNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;


    [Test]
    procedure TestGetNextNoWithIncompleteLine()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
        StartingNo: Code[20];
        StartingNoLbl: Label 'SCI0000001';
    begin
        // init
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // setup
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        StartingNo := StartingNoLbl;

        NoSeriesLine.Validate("Series Code", NoSeriesCode);
        NoSeriesLine.Validate("Line No.", 10000);
        NoSeriesLine.Validate("Starting No.", StartingNo);
        NoSeriesLine.Validate("Last No. Used", '');
        NoSeriesLine.Validate("Last Date Used", 0D);
        NoSeriesLine.Insert();

        // exercise
        // verify
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        LibraryAssert.AreEqual(StartingNo, NoSeriesBatch.GetNextNo(NoSeriesCode), 'not the first number');
        LibraryAssert.AreEqual(IncStr(StartingNo), NoSeriesBatch.GetNextNo(NoSeriesCode), 'not the second number');
    end;
    #endregion

    #region Simulation
    [Test]
    procedure TestSimulateGetNextNoSequenceDatabaseNotUpdated()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesBatch2: Codeunit "No. Series - Batch";
        NoSeriesBatch3: Codeunit "No. Series - Batch";
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        // Scenario: Make sure the database sequence is not updated when calling batch simulation
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with 10 numbers
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, 'A1', 'A9');
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, 'B1', 'B9');

        // [WHEN] We get the first 10 numbers from the No. Series
        // [THEN] The numbers match with 1, 2, 3, 4, 5
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        for i := 0 to 4 do
            LibraryAssert.AreEqual('A' + Format(i + 1), NoSeriesBatch.SimulateGetNextNo(NoSeriesCode, WorkDate(), 'A' + Format((i))), 'Number was not as expected');

        // [WHEN] We get the next number using the same batch instance, the simulation does not continue
        // [THEN] The numbers A7, A8, A9 are returned
        for i := 1 to 9 do
            LibraryAssert.AreEqual('A' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate()), 'Getting Next No. should continue the simulation');

        // [WHEN] Getting the next number and it overflows to the second line, simulation does not run
        // [THEN] The number B1, B2, B3 are returned
        LibraryAssert.AreEqual('B1', NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate()), 'Getting Next No. should continue the simulation');
        LibraryAssert.AreEqual('B2', NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate()), 'Getting Next No. should continue the simulation');
        LibraryAssert.AreEqual('B3', NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate()), 'Getting Next No. should continue the simulation');

        // [WHEN] We get the next number from the No. Series using a different batch
        // [THEN] The numbers start again from A1
        LibraryAssert.AreEqual('A1', NoSeriesBatch2.GetNextNo(NoSeriesCode, WorkDate()), 'No numbers from the sequence should have been used');
        LibraryAssert.AreEqual('A2', NoSeriesBatch2.GetNextNo(NoSeriesCode, WorkDate()), 'No numbers from the sequence should have been used');
        LibraryAssert.AreEqual('A3', NoSeriesBatch2.GetNextNo(NoSeriesCode, WorkDate()), 'No numbers from the sequence should have been used');

        // [WHEN] We save the original batch
        NoSeriesBatch.SaveState();
        // [THEN] The numbers from another batch will continue from line 2
        LibraryAssert.AreEqual('B4', NoSeriesBatch3.GetNextNo(NoSeriesCode, WorkDate()), 'No numbers from the sequence should have been used');
        LibraryAssert.AreEqual('B5', NoSeriesBatch3.GetNextNo(NoSeriesCode, WorkDate()), 'No numbers from the sequence should have been used');
        LibraryAssert.AreEqual('B6', NoSeriesBatch3.GetNextNo(NoSeriesCode, WorkDate()), 'No numbers from the sequence should have been used');
    end;

    [Test]
    procedure TestSimulateGetNextNoNormalDatabaseNotUpdated()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesBatch2: Codeunit "No. Series - Batch";
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        // Scenario: Make sure the database sequence is not updated when calling batch simulation
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with 10 numbers
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateNormalNoSeriesLine(NoSeriesCode, 1, 'A1', 'A9');
        LibraryNoSeries.CreateNormalNoSeriesLine(NoSeriesCode, 1, 'B1', 'B9');

        // [WHEN] We get the first 10 numbers from the No. Series
        // [THEN] The numbers match with 1, 2, 3, 4, 5
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        for i := 0 to 4 do
            LibraryAssert.AreEqual('A' + Format(i + 1), NoSeriesBatch.SimulateGetNextNo(NoSeriesCode, WorkDate(), 'A' + Format((i))), 'Number was not as expected');

        // [WHEN] We get the next number using the same batch, simulation does not continue
        // [THEN] The numbers A1, A2, A3 are returned
        LibraryAssert.AreEqual('A1', NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate()), 'Getting Next No. should not continue the simulation');
        LibraryAssert.AreEqual('A2', NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate()), 'Getting Next No. should not continue the simulation');
        LibraryAssert.AreEqual('A3', NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate()), 'Getting Next No. should not continue the simulation');

        // [WHEN] We get the next number from the No. Series using a different batch
        // [THEN] The numbers should start from A1 again since we were only simulating before (and could not save the state)
        LibraryAssert.AreEqual('A1', NoSeriesBatch2.GetNextNo(NoSeriesCode, WorkDate()), 'No numbers from the sequence should have been used');
        LibraryAssert.AreEqual('A2', NoSeriesBatch2.GetNextNo(NoSeriesCode, WorkDate()), 'No numbers from the sequence should have been used');
        LibraryAssert.AreEqual('A3', NoSeriesBatch2.GetNextNo(NoSeriesCode, WorkDate()), 'No numbers from the sequence should have been used');
    end;
    #endregion


    #region GetLastNoUsed
    [Test]
    procedure TestGetLastNoUsedCodeRunOut_Sequence()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesBatch2: Codeunit "No. Series - Batch";
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with 9 numbers
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, 'A1', 'A9');

        // [WHEN] GetLastNoUsed is called on a new series, an empty string is returned
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        LibraryAssert.AreEqual('', NoSeriesBatch.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed expected to return empty string for new No. Series');

        // [WHEN] We get the first 8 numbers from the No. Series
        // [THEN] The numbers match with 1, 2, 3, 4, 5, 6, 7, 8 and GetLastNoUsed reflects that
        for i := 1 to 8 do begin
            LibraryAssert.AreEqual('A' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesCode), 'GetNextNo Number was not as expected');
            LibraryAssert.AreEqual('A' + Format(i), NoSeriesBatch.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed Number was not as expected');
        end;

        // [WHEN] We get the last number in the series, GetLastNoUsed will be empty.
        LibraryAssert.AreEqual('A9', NoSeriesBatch.GetNextNo(NoSeriesCode), 'GetNextNo Number was not as expected');
        LibraryAssert.AreEqual('', NoSeriesBatch.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] No number is returned
        LibraryAssert.AreEqual('', NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate(), true), 'A number was returned even though the sequence has run out');

        // [THEN] GetLastNoUsed returns blank, and new batch references will return '' as well, even though no save was done. This is due to the sequence being exhausted.
        LibraryAssert.AreEqual('', NoSeriesBatch.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed Number was not as expected');
        LibraryAssert.AreEqual('', NoSeriesBatch2.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed Number was not as expected');

        // [GIVEN] The No. Series is saved
        NoSeriesBatch.SaveState();

        // [THEN] The last No. Used for a new batch is blank
        Clear(NoSeriesBatch2);
        LibraryAssert.AreEqual('', NoSeriesBatch2.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed Number was not as expected in batch2');
    end;

    [Test]
    procedure TestGetLastNoUsedRecordRunOut_Sequence()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesBatch2: Codeunit "No. Series - Batch";
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with 10 numbers
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, 'A1', 'A9');
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.FindFirst();

        // [WHEN] GetLastNoUsed is called on a new series, an empty string is returned
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        LibraryAssert.AreEqual('', NoSeriesBatch.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed expected to return empty string for new No. Series');

        // [WHEN] We get the first 10 numbers from the No. Series
        // [THEN] The numbers match with 1, 2, 3, 4, 5, 6, 7, 8 and GetLastNoUsed reflects that
        for i := 1 to 8 do begin
            LibraryAssert.AreEqual('A' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesCode), 'GetNextNo Number was not as expected');
            LibraryAssert.AreEqual('A' + Format(i), NoSeriesBatch.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed Number was not as expected');
        end;

        // [WHEN] We get the last number in the series, GetLastNoUsed will be empty.
        LibraryAssert.AreEqual('A9', NoSeriesBatch.GetNextNo(NoSeriesCode), 'GetNextNo Number was not as expected');
        LibraryAssert.AreEqual('A9', NoSeriesBatch.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed Number was not as expected before getting invalid number');

        // [WHEN] We get the next number from the No. Series
        // [THEN] No number is returned
        LibraryAssert.AreEqual('', NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate(), true), 'A number was returned even though the sequence has run out');

        // [THEN] GetLastNoUsed returns A9, however new batch references will return blank since no number has been saved.
        LibraryAssert.AreEqual('A9', NoSeriesBatch.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed Number was not as expected after getting invalid number');
        LibraryAssert.AreEqual('', NoSeriesBatch2.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed Number was not as expected');

        // [GIVEN] The No. Series is saved
        NoSeriesBatch.SaveState();

        // [THEN] The last No. Used for a new batch is blank
        PermissionsMock.ClearAssignments();
        Clear(NoSeriesBatch2);
        NoSeriesLine.FindFirst();
        LibraryAssert.AreEqual('A9', NoSeriesBatch2.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed Number was not as expected in batch2');

        // Still getting Last No. through code returns a blank code since the No. Series is closed
        Clear(NoSeriesBatch2);
        LibraryAssert.AreEqual('', NoSeriesBatch2.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed with code Number was not as expected');
    end;

    [Test]
    procedure TestGetLastNoUsedCodeRunOut()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesBatch2: Codeunit "No. Series - Batch";
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with 10 numbers
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateNormalNoSeriesLine(NoSeriesCode, 1, 'A1', 'A9');

        // [WHEN] GetLastNoUsed is called on a new series, an empty string is returned
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        LibraryAssert.AreEqual('', NoSeriesBatch.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed expected to return empty string for new No. Series');

        // [WHEN] We get the first 10 numbers from the No. Series
        // [THEN] The numbers match with 1, 2, 3, 4, 5, 6, 7, 8 and GetLastNoUsed reflects that
        for i := 1 to 8 do begin
            LibraryAssert.AreEqual('A' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesCode), 'GetNextNo Number was not as expected');
            LibraryAssert.AreEqual('A' + Format(i), NoSeriesBatch.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed Number was not as expected');
        end;

        // [WHEN] We get the last number in the series, GetLastNoUsed will be empty.
        LibraryAssert.AreEqual('A9', NoSeriesBatch.GetNextNo(NoSeriesCode), 'GetNextNo Number was not as expected');
        LibraryAssert.AreEqual('', NoSeriesBatch.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] No number is returned
        LibraryAssert.AreEqual('', NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate(), true), 'A number was returned even though the sequence has run out');

        // [THEN] GetLastNoUsed returns blank
        LibraryAssert.AreEqual('', NoSeriesBatch.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed Number was not as expected');
        LibraryAssert.AreEqual('', NoSeriesBatch2.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed Number was not as expected in batch2');

        // [GIVEN] The No. Series is saved
        NoSeriesBatch.SaveState();

        // [THEN] The last No. Used for a new batch is blank
        Clear(NoSeriesBatch2);
        LibraryAssert.AreEqual('', NoSeriesBatch2.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed Number was not as expected');
    end;

    [Test]
    procedure TestGetLastNoUsedRecordRunOut()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesBatch2: Codeunit "No. Series - Batch";
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with 10 numbers
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateNormalNoSeriesLine(NoSeriesCode, 1, 'A1', 'A9');
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.FindFirst();

        // [WHEN] GetLastNoUsed is called on a new series, an empty string is returned
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        LibraryAssert.AreEqual('', NoSeriesBatch.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed expected to return empty string for new No. Series');

        // [WHEN] We get the first 10 numbers from the No. Series
        // [THEN] The numbers match with 1, 2, 3, 4, 5, 6, 7, 8 and GetLastNoUsed reflects that
        for i := 1 to 8 do begin
            LibraryAssert.AreEqual('A' + Format(i), NoSeriesBatch.GetNextNo(NoSeriesCode), 'GetNextNo Number was not as expected');
            LibraryAssert.AreEqual('A' + Format(i), NoSeriesBatch.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed Number was not as expected');
        end;

        // [WHEN] We get the last number in the series, GetLastNoUsed will be empty.
        LibraryAssert.AreEqual('A9', NoSeriesBatch.GetNextNo(NoSeriesCode), 'GetNextNo Number was not as expected');
        LibraryAssert.AreEqual('A9', NoSeriesBatch.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed Number was not as expected before getting invalid number');

        // [WHEN] We get the next number from the No. Series
        // [THEN] No number is returned
        LibraryAssert.AreEqual('', NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate(), true), 'A number was returned even though the sequence has run out');

        // [THEN] GetLastNoUsed returns blank, however new batch references will return A9 until save since the Line is not yet closed but the sequence is updated in the database.
        LibraryAssert.AreEqual('A9', NoSeriesBatch.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed Number was not as expected after getting invalid number');
        LibraryAssert.AreEqual('', NoSeriesBatch2.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed should be empty since no state has been saved');

        // [GIVEN] The No. Series is saved
        NoSeriesBatch.SaveState();

        // [THEN] The last No. Used for a new batch is blank
        PermissionsMock.ClearAssignments();
        Clear(NoSeriesBatch2);
        NoSeriesLine.FindFirst();
        LibraryAssert.AreEqual('A9', NoSeriesBatch2.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed Number was not as expected in batch2');

        // Still getting Last No. through code returns a blank code since the No. Series is closed
        Clear(NoSeriesBatch2);
        LibraryAssert.AreEqual('', NoSeriesBatch2.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed with code Number was not as expected');
    end;
    #endregion

    [Test]
    procedure TestSequenceTempCurrentSequenceNoField()
    var
        NoSeriesLine: Record "No. Series Line";
        TempNoSeriesLine: Record "No. Series Line" temporary;
        NoSeriesBatch: Codeunit "No. Series - Batch";
        NoSeriesBatch2: Codeunit "No. Series - Batch";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
    begin
        // [Scenario] Make sure the Temp Current Sequence No. field cannot be abused and is always set to 0 upon database modify
        // Note: These scenarios are not supported, this is simply to make sure the Temp Current Sequence No. field works as expected behind the scenes.

        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with 10 numbers
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, '1', '9');
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.FindFirst();
        TempNoSeriesLine := NoSeriesLine;
        TempNoSeriesLine.Insert();

        // [GIVEN] A No. Series Line and Temporary No. Series Line with Current Sequence No. set to 5
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        LibraryNoSeries.SetTempCurrentSequenceNo(NoSeriesLine, 5);
        TempNoSeriesLine := NoSeriesLine;

        // [WHEN] Fetching the Last No. Used, both implementations return blank (batch will fetch the correct line from the database which does not contain the Temp Current Sequence No.)
        LibraryAssert.AreEqual('', NoSeriesBatch.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed returned wrong value');
        LibraryAssert.AreEqual('', NoSeriesBatch2.GetLastNoUsed(TempNoSeriesLine), 'GetLastNoUsed with temporary record returned wrong value');

        // [WHEN] We peek the next number from both No. Series, they both return 1 since no number has been used
        LibraryAssert.AreEqual('1', NoSeriesBatch.PeekNextNo(NoSeriesLine, WorkDate()), 'PeekNextNo returned wrong value');
        LibraryAssert.AreEqual('1', NoSeriesBatch2.PeekNextNo(TempNoSeriesLine, WorkDate()), 'PeekNextNo with temporary record returned wrong value');

        // [WHEN] We get the next number from both No. Series, they both return 1
        LibraryAssert.AreEqual('1', NoSeriesBatch.GetNextNo(NoSeriesLine, WorkDate()), 'GetNextNo returned wrong value');
        LibraryAssert.AreEqual('1', NoSeriesBatch2.GetNextNo(TempNoSeriesLine, WorkDate()), 'GetNextNo with temporary record returned wrong value');

        // [THEN] Getting the next number, they again both return 7
        LibraryAssert.AreEqual('2', NoSeriesBatch.GetNextNo(NoSeriesLine, WorkDate()), 'GetNextNo returned wrong value');
        LibraryAssert.AreEqual('2', NoSeriesBatch2.GetNextNo(TempNoSeriesLine, WorkDate()), 'GetNextNo with temporary record returned wrong value');
    end;

    [Test]
    procedure TestDailyNoSeriesBeforeFirstStartDateError()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        NoSeriesCode: Code[20];
    begin
        // [SCENARIO] When setting up a No. Series Line with a new start date each day, ensure that the correct number is returned for each day
        Initialize();

        // [GIVEN] A No Series with 3 lines starting on 3 different days 
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        CreateDailyNoSeriesLines(NoSeriesCode);

        // [WHEN] We get the next number for a day before the first starting date
        asserterror NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate() - 1);
        // [THEN] an error is returned
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestDailyNoSeries()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        NoSeriesCode: Code[20];
        NextNo: Code[20];
    begin
        // [SCENARIO] When setting up a No. Series Line with a new start date each day, ensure that the correct number is returned for each day
        Initialize();

        // [GIVEN] A No Series with 3 lines starting on 3 different days 
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        CreateDailyNoSeriesLines(NoSeriesCode);

        // [WHEN] We get the next number for the first starting date
        NextNo := NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate());
        // [THEN] the correct number is returned
        LibraryAssert.AreEqual(StrSubstNo('%1-001', WorkDate()), NextNo, 'Number was not as expected');

        // [WHEN] We get the next number for the second starting date
        NextNo := NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate() + 1);
        // [THEN] the correct number is returned
        LibraryAssert.AreEqual(StrSubstNo('%1-001', WorkDate() + 1), NextNo, 'Number was not as expected');

        // [WHEN] We get the next number for the first starting date
        NextNo := NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate());
        // [THEN] the correct number is returned
        LibraryAssert.AreEqual(StrSubstNo('%1-002', WorkDate()), NextNo, 'Number was not as expected');

        // [WHEN] We get the next number for the second starting date
        NextNo := NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate() + 1);
        // [THEN] the correct number is returned
        LibraryAssert.AreEqual(StrSubstNo('%1-002', WorkDate() + 1), NextNo, 'Number was not as expected');

        // [WHEN] We get the next number for the third starting date
        NextNo := NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate() + 2);
        // [THEN] the correct number is returned
        LibraryAssert.AreEqual(StrSubstNo('%1-001', WorkDate() + 2), NextNo, 'Number was not as expected');

        // [WHEN] We get the next number for the third starting date
        NextNo := NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate() + 2);
        // [THEN] the correct number is returned
        LibraryAssert.AreEqual(StrSubstNo('%1-002', WorkDate() + 2), NextNo, 'Number was not as expected');

        // [WHEN] We get the next number for the second starting date
        NextNo := NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate() + 1);
        // [THEN] the correct number is returned
        LibraryAssert.AreEqual(StrSubstNo('%1-003', WorkDate() + 1), NextNo, 'Number was not as expected');
    end;

    [Test]
    procedure TestDailyNoSeriesWithDifferentOrder()
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        NoSeriesCode: Code[20];
        NextNo: Code[20];
    begin
        // [Bug 537964] No Series Line should be picked in the order of Starting Date, instead of line number
        // [SCENARIO] When setting up a No. Series Line with a new start date each day in a different order(i.e., the line number doesn't match the order of start date), ensure that the correct number is returned for each day

        Initialize();

        // [GIVEN] A No Series with 3 lines starting on 3 different days 
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        CreateDailyNoSeriesLinesDisOrder(NoSeriesCode);

        // [WHEN] We get the next number for the first starting date
        NextNo := NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate());
        // [THEN] the correct number is returned
        LibraryAssert.AreEqual(StrSubstNo('%1-001', WorkDate()), NextNo, 'Number was not as expected');

        // [WHEN] We get the next number for the second starting date
        NextNo := NoSeriesBatch.GetNextNo(NoSeriesCode, WorkDate() + 1);
        // [THEN] the correct number is returned
        LibraryAssert.AreEqual(StrSubstNo('%1-001', WorkDate() + 1), NextNo, 'Number was not as expected');
    end;

#if not CLEAN24
#pragma warning disable AL0432
    [Test]
    procedure TestLegacyDailyNoSeries()
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
        NoSeriesCode: Code[20];
        NextNo: Code[20];
    begin
        // [SCENARIO] When setting up a No. Series Line with a new start date each day, ensure that the correct number is returned for each day
        Initialize();

        // [GIVEN] A No Series with 3 lines starting on 3 different days 
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        CreateDailyNoSeriesLines(NoSeriesCode);

        // [WHEN] We get the next number for the first starting date
        NextNo := NoSeriesManagement.GetNextNo(NoSeriesCode, WorkDate(), true);
        // [THEN] the correct number is returned
        LibraryAssert.AreEqual(StrSubstNo('%1-001', WorkDate()), NextNo, 'Number was not as expected');

        // [WHEN] We get the next number for the second starting date
        NextNo := NoSeriesManagement.GetNextNo(NoSeriesCode, WorkDate() + 1, true);
        // [THEN] the correct number is returned
        LibraryAssert.AreEqual(StrSubstNo('%1-001', WorkDate() + 1), NextNo, 'Number was not as expected');

        // [WHEN] We get the next number for the first starting date
        NextNo := NoSeriesManagement.GetNextNo(NoSeriesCode, WorkDate(), true);
        // [THEN] the correct number is returned
        LibraryAssert.AreEqual(StrSubstNo('%1-002', WorkDate()), NextNo, 'Number was not as expected');

        // [WHEN] We get the next number for the second starting date
        NextNo := NoSeriesManagement.GetNextNo(NoSeriesCode, WorkDate() + 1, true);
        // [THEN] the correct number is returned
        LibraryAssert.AreEqual(StrSubstNo('%1-002', WorkDate() + 1), NextNo, 'Number was not as expected');

        // [WHEN] We get the next number for the third starting date
        NextNo := NoSeriesManagement.GetNextNo(NoSeriesCode, WorkDate() + 2, true);
        // [THEN] the correct number is returned
        LibraryAssert.AreEqual(StrSubstNo('%1-001', WorkDate() + 2), NextNo, 'Number was not as expected');

        // [WHEN] We get the next number for the third starting date
        NextNo := NoSeriesManagement.GetNextNo(NoSeriesCode, WorkDate() + 2, true);
        // [THEN] the correct number is returned
        LibraryAssert.AreEqual(StrSubstNo('%1-002', WorkDate() + 2), NextNo, 'Number was not as expected');

        // [WHEN] We get the next number for the second starting date
        NextNo := NoSeriesManagement.GetNextNo(NoSeriesCode, WorkDate() + 1, true);
        // [THEN] the correct number is returned
        LibraryAssert.AreEqual(StrSubstNo('%1-003', WorkDate() + 1), NextNo, 'Number was not as expected');
    end;
#pragma warning restore AL0432
#endif

    local procedure CreateDailyNoSeriesLines(NoSeriesCode: Code[20])
    begin
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, StrSubstNo('%1-001', WorkDate()), '', WorkDate());
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, StrSubstNo('%1-001', WorkDate() + 1), '', WorkDate() + 1);
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, StrSubstNo('%1-001', WorkDate() + 2), '', WorkDate() + 2);
    end;

    local procedure CreateDailyNoSeriesLinesDisOrder(NoSeriesCode: Code[20])
    begin
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, StrSubstNo('%1-001', WorkDate() + 2), '', WorkDate() + 2);
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, StrSubstNo('%1-001', WorkDate() + 1), '', WorkDate() + 1);
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, StrSubstNo('%1-001', WorkDate()), '', WorkDate());
    end;

    local procedure Initialize()
    begin
        Any.SetDefaultSeed();
    end;
}