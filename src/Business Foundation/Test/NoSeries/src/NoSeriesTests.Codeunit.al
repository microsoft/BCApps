// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Test.Foundation.NoSeries;

using System.TestLibraries.Utilities;
using System.TestLibraries.Security.AccessControl;
using Microsoft.TestLibraries.Foundation.NoSeries;
using Microsoft.Foundation.NoSeries;

codeunit 134530 "No. Series Tests"
{
    Subtype = Test;

    var
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        LibraryNoSeries: Codeunit "Library - No. Series";
        CannotAssignNewErr: Label 'You cannot assign new numbers from the number series %1.', Comment = '%1=No. Series Code';

    #region sequence
    [Test]
    procedure TestGetNextNoDefaultRunOut_Sequence()
    var
        NoSeries: Codeunit "No. Series";
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
            LibraryAssert.AreEqual(Format(i), NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeries.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNo_Sequence()
    var
        NoSeries: Codeunit "No. Series";
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
        LibraryAssert.AreEqual('1', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('8', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeries.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoWithLastNoUsed_Sequence()
    var
        NoSeries: Codeunit "No. Series";
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
        LibraryAssert.AreEqual('5', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('7', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('9', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeries.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoDefaultOverFlow_Sequence()
    var
        NoSeries: Codeunit "No. Series";
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
            LibraryAssert.AreEqual('A' + Format(i), NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        for i := 1 to 5 do
            LibraryAssert.AreEqual('B' + Format(i), NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeries.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoAdvancedOverFlow_Sequence()
    var
        NoSeries: Codeunit "No. Series";
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
        LibraryAssert.AreEqual('A01', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('A08', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('B01', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('B08', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeries.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoOverflowOutsideDate_Sequence()
    var
        NoSeries: Codeunit "No. Series";
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
            LibraryAssert.AreEqual('A' + Format(i), NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number for WorkDate without throwing errors
        // [THEN] No number is returned
        LibraryAssert.AreEqual('', NoSeries.GetNextNo(NoSeriesCode, WorkDate(), true), 'A number was returned when it should not have been');

        // [WHEN] We get the next number for WorkDate + 1
        // [THEN] We get the numbers from the second line
        for i := 1 to 5 do
            LibraryAssert.AreEqual('B' + Format(i), NoSeries.GetNextNo(NoSeriesCode, TomorrowsWorkDate), 'Number was not as expected');

        // [WHEN] We get the next number for WorkDate
        // [THEN] No other numbers are available
        asserterror NoSeries.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoWithLine_Sequence()
    var
        NoSeriesLineA: Record "No. Series Line";
        NoSeriesLineB: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
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
            LibraryAssert.AreEqual('B' + Format(i), NoSeries.GetNextNo(NoSeriesLineB, WorkDate()), 'Number was not as expected');
            LibraryAssert.AreEqual('A' + Format(i), NoSeries.GetNextNo(NoSeriesLineA, WorkDate()), 'Number was not as expected');
        end;

        // [WHEN] We get the next number for either line without throwing errors
        // [THEN] No number is returned
        LibraryAssert.AreEqual('', NoSeries.GetNextNo(NoSeriesLineA, WorkDate(), true), 'A number was returned when it should not have been');
        LibraryAssert.AreEqual('', NoSeries.GetNextNo(NoSeriesLineB, WorkDate(), true), 'A number was returned when it should not have been');
    end;

    [Test]
    procedure TestPeekNextNoDefaultRunOut_Sequence()
    var
        NoSeries: Codeunit "No. Series";
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
        LibraryAssert.AreEqual('A01TEST', NoSeries.PeekNextNo(NoSeriesCode), 'Initial number was not as expected');
        LibraryAssert.AreEqual('A01TEST', NoSeries.PeekNextNo(NoSeriesCode), 'Follow up call to PeekNextNo was not as expected');

        // [WHEN] We peek and get the next number 10 times
        // [THEN] The two match up
        for i := 1 to 10 do
            LibraryAssert.AreEqual(NoSeries.PeekNextNo(NoSeriesCode), NoSeries.GetNextNo(NoSeriesCode), 'GetNextNo and PeekNextNo are not aligned');

        // [WHEN] We peek the next number after the series has run out
        // [THEN] An error is thrown
        asserterror NoSeries.PeekNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;
    #endregion

    #region normal
    [Test]
    procedure TestGetNextNoDefaultRunOut()
    var
        NoSeries: Codeunit "No. Series";
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
            LibraryAssert.AreEqual(Format(i), NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeries.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNo()
    var
        NoSeries: Codeunit "No. Series";
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
        LibraryAssert.AreEqual('1', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('8', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeries.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoWithLastNoUsed()
    var
        NoSeries: Codeunit "No. Series";
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
        LibraryAssert.AreEqual('5', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('7', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('9', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeries.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoDefaultOverFlow()
    var
        NoSeries: Codeunit "No. Series";
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
            LibraryAssert.AreEqual('A' + Format(i), NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        for i := 1 to 5 do
            LibraryAssert.AreEqual('B' + Format(i), NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeries.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoAdvancedOverFlow()
    var
        NoSeries: Codeunit "No. Series";
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
        LibraryAssert.AreEqual('A01', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('A08', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('B01', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('B08', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] An error is thrown
        asserterror NoSeries.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoOverflowOutsideDate()
    var
        NoSeries: Codeunit "No. Series";
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
            LibraryAssert.AreEqual('A' + Format(i), NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');

        // [WHEN] We get the next number for WorkDate without throwing errors
        // [THEN] No number is returned
        LibraryAssert.AreEqual('', NoSeries.GetNextNo(NoSeriesCode, WorkDate(), true), 'A number was returned when it should not have been');

        // [WHEN] We get the next number for WorkDate + 1
        // [THEN] We get the numbers from the second line
        for i := 1 to 5 do
            LibraryAssert.AreEqual('B' + Format(i), NoSeries.GetNextNo(NoSeriesCode, TomorrowsWorkDate), 'Number was not as expected');

        // [WHEN] We get the next number for WorkDate
        // [THEN] No other numbers are available
        asserterror NoSeries.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoWithLine()
    var
        NoSeriesLineA: Record "No. Series Line";
        NoSeriesLineB: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
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
            LibraryAssert.AreEqual('B' + Format(i), NoSeries.GetNextNo(NoSeriesLineB, WorkDate()), 'Number was not as expected');
            LibraryAssert.AreEqual('A' + Format(i), NoSeries.GetNextNo(NoSeriesLineA, WorkDate()), 'Number was not as expected');
        end;

        // [WHEN] We get the next number for either line without throwing errors
        // [THEN] No number is returned
        LibraryAssert.AreEqual('', NoSeries.GetNextNo(NoSeriesLineA, WorkDate(), true), 'A number was returned when it should not have been');
        LibraryAssert.AreEqual('', NoSeries.GetNextNo(NoSeriesLineB, WorkDate(), true), 'A number was returned when it should not have been');
    end;

    [Test]
    procedure TestPeekNextNoDefaultRunOut()
    var
        NoSeries: Codeunit "No. Series";
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
        LibraryAssert.AreEqual('A01TEST', NoSeries.PeekNextNo(NoSeriesCode), 'Initial number was not as expected');
        LibraryAssert.AreEqual('A01TEST', NoSeries.PeekNextNo(NoSeriesCode), 'Follow up call to PeekNextNo was not as expected');

        // [WHEN] We peek and get the next number 10 times
        // [THEN] The two match up
        for i := 1 to 10 do
            LibraryAssert.AreEqual(NoSeries.PeekNextNo(NoSeriesCode), NoSeries.GetNextNo(NoSeriesCode), 'GetNextNo and PeekNextNo are not aligned');

        // [WHEN] We peek the next number after the series has run out
        // [THEN] An error is thrown
        asserterror NoSeries.PeekNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;


    [Test]
    procedure TestGetNextNoWithIncompleteLine()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
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
        LibraryAssert.AreEqual(StartingNo, NoSeries.GetNextNo(NoSeriesCode), 'not the first number');
        LibraryAssert.AreEqual(IncStr(StartingNo), NoSeries.GetNextNo(NoSeriesCode), 'not the second number');
    end;
    #endregion

    #region GetLastNoUsed
    [Test]
    procedure TestGetLastNoUsedCodeRunOut_Sequence()
    var
        NoSeries: Codeunit "No. Series";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        Initialize();
        PermissionsMock.Set('No. Series - Admin');

        // [GIVEN] A No. Series with 10 numbers
        NoSeriesCode := CopyStr(UpperCase(Any.AlphabeticText(MaxStrLen(NoSeriesCode))), 1, MaxStrLen(NoSeriesCode));
        LibraryNoSeries.CreateNoSeries(NoSeriesCode);
        LibraryNoSeries.CreateSequenceNoSeriesLine(NoSeriesCode, 1, 'A1', 'A9');

        // [WHEN] GetLastNoUsed is called on a new series, an empty string is returned
        PermissionsMock.SetExactPermissionSet('No. Series Test');
        LibraryAssert.AreEqual('', NoSeries.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed expected to return empty string for new No. Series');

        // [WHEN] We get the first 10 numbers from the No. Series
        // [THEN] The numbers match with 1, 2, 3, 4, 5, 6, 7, 8 and GetLastNoUsed reflects that
        for i := 1 to 8 do begin
            LibraryAssert.AreEqual('A' + Format(i), NoSeries.GetNextNo(NoSeriesCode), 'GetNextNo Number was not as expected');
            LibraryAssert.AreEqual('A' + Format(i), NoSeries.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed Number was not as expected');
        end;

        // [WHEN] We get the last number in the series, GetLastNoUsed will be empty.
        LibraryAssert.AreEqual('A9', NoSeries.GetNextNo(NoSeriesCode), 'GetNextNo Number was not as expected');
        LibraryAssert.AreEqual('', NoSeries.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] No number is returned
        LibraryAssert.AreEqual('', NoSeries.GetNextNo(NoSeriesCode, WorkDate(), true), 'A number was returned even though the sequence has run out');

        // [THEN] GetLastNoUsed returns blank, however new batch references will return A9 until save since the Line is not yet closed but the sequence is updated in the database.
        LibraryAssert.AreEqual('', NoSeries.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed Number was not as expected');
    end;

    [Test]
    procedure TestGetLastNoUsedRecordRunOut_Sequence()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        PermissionsMock: Codeunit "Permissions Mock";
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
        LibraryAssert.AreEqual('', NoSeries.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed expected to return empty string for new No. Series');

        // [WHEN] We get the first 10 numbers from the No. Series
        // [THEN] The numbers match with 1, 2, 3, 4, 5, 6, 7, 8 and GetLastNoUsed reflects that
        for i := 1 to 8 do begin
            LibraryAssert.AreEqual('A' + Format(i), NoSeries.GetNextNo(NoSeriesCode), 'GetNextNo Number was not as expected');
            LibraryAssert.AreEqual('A' + Format(i), NoSeries.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed Number was not as expected');
        end;

        // [WHEN] We get the last number in the series, GetLastNoUsed will be empty.
        LibraryAssert.AreEqual('A9', NoSeries.GetNextNo(NoSeriesCode), 'GetNextNo Number was not as expected');
        LibraryAssert.AreEqual('A9', NoSeries.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed Number was not as expected before getting invalid number');

        // [WHEN] We get the next number from the No. Series
        // [THEN] No number is returned
        LibraryAssert.AreEqual('', NoSeries.GetNextNo(NoSeriesCode, WorkDate(), true), 'A number was returned even though the sequence has run out');

        // [THEN] GetLastNoUsed returns blank, however new batch references will return A9 until save since the Line is not yet closed but the sequence is updated in the database.
        LibraryAssert.AreEqual('A9', NoSeries.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed Number was not as expected after getting invalid number');
    end;

    [Test]
    procedure TestGetLastNoUsedCodeRunOut()
    var
        NoSeries: Codeunit "No. Series";
        PermissionsMock: Codeunit "Permissions Mock";
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
        LibraryAssert.AreEqual('', NoSeries.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed expected to return empty string for new No. Series');

        // [WHEN] We get the first 10 numbers from the No. Series
        // [THEN] The numbers match with 1, 2, 3, 4, 5, 6, 7, 8 and GetLastNoUsed reflects that
        for i := 1 to 8 do begin
            LibraryAssert.AreEqual('A' + Format(i), NoSeries.GetNextNo(NoSeriesCode), 'GetNextNo Number was not as expected');
            LibraryAssert.AreEqual('A' + Format(i), NoSeries.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed Number was not as expected');
        end;

        // [WHEN] We get the last number in the series, GetLastNoUsed will be empty.
        LibraryAssert.AreEqual('A9', NoSeries.GetNextNo(NoSeriesCode), 'GetNextNo Number was not as expected');
        LibraryAssert.AreEqual('', NoSeries.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed Number was not as expected');

        // [WHEN] We get the next number from the No. Series
        // [THEN] No number is returned
        LibraryAssert.AreEqual('', NoSeries.GetNextNo(NoSeriesCode, WorkDate(), true), 'A number was returned even though the sequence has run out');

        // [THEN] GetLastNoUsed returns blank
        LibraryAssert.AreEqual('', NoSeries.GetLastNoUsed(NoSeriesCode), 'GetLastNoUsed Number was not as expected');
    end;

    [Test]
    procedure TestGetLastNoUsedRecordRunOut()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        PermissionsMock: Codeunit "Permissions Mock";
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
        LibraryAssert.AreEqual('', NoSeries.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed expected to return empty string for new No. Series');
        PermissionsMock.ClearAssignments();

        // [WHEN] We get the first 10 numbers from the No. Series
        // [THEN] The numbers match with 1, 2, 3, 4, 5, 6, 7, 8 and GetLastNoUsed reflects that
        for i := 1 to 8 do begin
            LibraryAssert.AreEqual('A' + Format(i), NoSeries.GetNextNo(NoSeriesCode), 'GetNextNo Number was not as expected');
            NoSeriesLine.Find();
            LibraryAssert.AreEqual('A' + Format(i), NoSeries.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed Number was not as expected');
        end;

        // [WHEN] We get the last number in the series, GetLastNoUsed will be empty.
        LibraryAssert.AreEqual('A9', NoSeries.GetNextNo(NoSeriesCode), 'GetNextNo Number was not as expected');
        NoSeriesLine.Find();
        LibraryAssert.AreEqual('A9', NoSeries.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed Number was not as expected before getting invalid number');

        // [WHEN] We get the next number from the No. Series
        // [THEN] No number is returned
        LibraryAssert.AreEqual('', NoSeries.GetNextNo(NoSeriesCode, WorkDate(), true), 'A number was returned even though the sequence has run out');

        // [THEN] GetLastNoUsed returns blank, however new batch references will return A9 until save since the Line is not yet closed but the sequence is updated in the database.
        NoSeriesLine.Find();
        LibraryAssert.AreEqual('A9', NoSeries.GetLastNoUsed(NoSeriesLine), 'GetLastNoUsed Number was not as expected after getting invalid number');
    end;
    #endregion

    local procedure Initialize()
    begin
        Any.SetDefaultSeed();
    end;
}