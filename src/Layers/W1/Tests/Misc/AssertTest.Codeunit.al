codeunit 132536 "Assert Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Test Framework] [Assert]
    end;

    var
        Assert: Codeunit Assert;
        IsTrueFailedMsg: Label 'Assert.IsTrue failed. %1';
        IsFalseFailedMsg: Label 'Assert.IsFalse failed. %1';
        AreEqualFailedMsg: Label 'Assert.AreEqual failed. Expected:<%1> (%2). Actual:<%3> (%4). %5.', Locked = true;
        AreNotEqualFailedMsg: Label 'Assert.AreNotEqual failed. Expected any value except:<%1> (%2). Actual:<%3> (%4). %5.', Locked = true;
        AreNearlyEqualFailedMsg: Label 'Assert.AreNearlyEqual failed. Expected a difference no greater than <%1> between expected value <%2> and actual value <%3>. %4';
        AreNotNearlyEqualFailedMsg: Label 'Assert.AreNotNearlyEqual failed. Expected a difference greater than <%1> between expected value <%2> and actual value <%3>. %4';
        FailFailedMsg: Label 'Assert.Fail failed. %1';
        TableIsEmptyErr: Label 'Assert.TableIsEmpty failed. Table <%1> with filter <%2> must not contain records.', Locked = true;
        TableIsNotEmptyErr: Label 'Assert.TableIsNotEmpty failed. Table <%1> with filter <%2> must contain records.', Locked = true;
        ErrorHasNotBeenThrownErr: Label 'The error has not been thrown.';
        RecordCountErr: Label 'Assert.RecordCount failed.', Comment = 'Do not translate';
        TextEndsWithErr: Label 'Assert.TextEndsWith failed. The text <%1> must end with <%2>';
        TextEndSubstringIsBlankErr: Label 'Substring must not be blank.';

    [Test]
    [Scope('OnPrem')]
    procedure IsTrueTest()
    begin
        Assert.IsTrue(true, '');

        asserterror Assert.IsTrue(false, '');
        Assert.AreEqual(StrSubstNo(IsTrueFailedMsg, ''), GetLastErrorText, 'Unexpected error message for Assert.IsTrue')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsFalseTest()
    begin
        Assert.IsFalse(false, '');

        asserterror Assert.IsFalse(true, '');
        Assert.AreEqual(StrSubstNo(IsFalseFailedMsg, ''), GetLastErrorText, 'Unexpected error message for Assert.IsFalse')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AreEqualTest()
    begin
        Assert.AreEqual(true, true, 'Comparing booleans');
        Assert.AreEqual(2, 2, 'Comparing integers');
        Assert.AreEqual(2.0, 2.0, 'Comparing decimals');
        Assert.AreEqual('A', 'A', 'Comparing chars');
        Assert.AreEqual('ABC', 'ABC', 'Comparing texts');
        Assert.AreEqual(101000T, 101000T, 'Comparing times');
        Assert.AreEqual(DMY2Date(10, 10, 2010), DMY2Date(10, 10, 2010), 'Comparing dates');
        Assert.AreEqual(1, 1.0, 'Comparing integer with decimal');

        asserterror Assert.AreEqual(DMY2Date(1, 1, 2001), 2.0, '');
        Assert.AreEqual(StrSubstNo(AreEqualFailedMsg, DMY2Date(1, 1, 2001), 'Date', 2.0, 'Decimal', ''),
          GetLastErrorText, 'Unexpected error message for Assert.AreEqual');

        asserterror Assert.AreEqual(1.1, 1, '');
        Assert.AreEqual(StrSubstNo(AreEqualFailedMsg, 1.1, 'Decimal', 1, 'Integer', ''),
          GetLastErrorText, 'Unexpected error message for Assert.AreEqual');

        asserterror Assert.AreEqual(1, '1', '');
        Assert.AreEqual(StrSubstNo(AreEqualFailedMsg, 1, 'Integer', 1, 'Text', ''),
          GetLastErrorText, 'Unexpected error message for Assert.AreEqual');

        asserterror Assert.AreEqual(Assert, Assert, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AreNotEqualTest()
    begin
        Assert.AreNotEqual(true, false, 'Comparing booleans');
        Assert.AreNotEqual(2, 3, 'Comparing integers');
        Assert.AreNotEqual(2.1, 2.0, 'Comparing decimals');
        Assert.AreNotEqual('A', 'B', 'Comparing chars');
        Assert.AreNotEqual('ABC', 'ABCD', 'Comparing texts');
        Assert.AreNotEqual(101000T, 101100T, 'Comparing times');
        Assert.AreNotEqual(DMY2Date(10, 10, 2010), DMY2Date(10, 10, 2011), 'Comparing dates');
        Assert.AreNotEqual(1, 1.1, 'Comparing integer with decimal');

        asserterror Assert.AreNotEqual(DMY2Date(1, 1, 2001), DMY2Date(1, 1, 2001), '');
        Assert.AreEqual(
          StrSubstNo(AreNotEqualFailedMsg, DMY2Date(1, 1, 2001), 'Date', DMY2Date(1, 1, 2001), 'Date', ''),
          GetLastErrorText, 'Unexpected error message for Assert.AreEqual')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AreNearlyEqualTest()
    begin
        Assert.AreNearlyEqual(98, 100, 2, '');
        Assert.AreNearlyEqual(100, 98.1, 2, '');
        Assert.AreNearlyEqual(98, 99.9, -2, '');

        asserterror Assert.AreNearlyEqual(98, -100, 2, '');
        Assert.AreEqual(StrSubstNo(AreNearlyEqualFailedMsg, 2, 98, -100, ''),
          GetLastErrorText, 'Unexpected error message for Assert.AreNearlyEqual')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AreNotNearlyEqualTest()
    begin
        Assert.AreNotNearlyEqual(98, 100.01, 2, '');
        asserterror Assert.AreNotNearlyEqual(98, 100, 2, '');
        Assert.AreEqual(StrSubstNo(AreNotNearlyEqualFailedMsg, 2, 98, 100, ''),
          GetLastErrorText, 'Unexpected error message for Assert.AreNotNearlyEqual')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FailTest()
    begin
        asserterror Assert.Fail('');
        Assert.AreEqual(StrSubstNo(FailFailedMsg, ''), GetLastErrorText, 'Unexpected error message for Assert.Fail')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableIsEmptyTest()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.DeleteAll();
        Assert.TableIsEmpty(DATABASE::"Name/Value Buffer");

        InsertNameValueBuffer(NameValueBuffer, 1);
        asserterror Assert.TableIsEmpty(DATABASE::"Name/Value Buffer");
        Assert.AreEqual(
          StrSubstNo(TableIsEmptyErr, NameValueBuffer.TableCaption(), ''),
          GetLastErrorText,
          'Unexpected error message for Assert.TableIsEmpty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableIsNotEmptyTest()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        InsertNameValueBuffer(NameValueBuffer, 1);
        Assert.TableIsNotEmpty(DATABASE::"Name/Value Buffer");

        NameValueBuffer.DeleteAll();
        asserterror Assert.TableIsNotEmpty(DATABASE::"Name/Value Buffer");
        Assert.AreEqual(
          StrSubstNo(TableIsNotEmptyErr, NameValueBuffer.TableCaption(), ''),
          GetLastErrorText,
          'Unexpected error message for Assert.TableIsNotEmpty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecordIsEmptyTest()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.DeleteAll();
        Assert.RecordIsEmpty(NameValueBuffer);

        InsertNameValueBuffer(NameValueBuffer, 1);
        asserterror Assert.RecordIsEmpty(NameValueBuffer);
        Assert.AreEqual(
          StrSubstNo(TableIsEmptyErr, NameValueBuffer.TableCaption(), NameValueBuffer.GetFilters),
          GetLastErrorText,
          'Unexpected error message for Assert.TableIsEmpty');

        InsertNameValueBuffer(NameValueBuffer, 1);
        NameValueBuffer.SetRange(ID, 2);
        Assert.RecordIsEmpty(NameValueBuffer);

        NameValueBuffer.SetRange(ID, 1);
        asserterror Assert.RecordIsEmpty(NameValueBuffer);
        Assert.AreEqual(
          StrSubstNo(TableIsEmptyErr, NameValueBuffer.TableCaption(), NameValueBuffer.GetFilters),
          GetLastErrorText,
          'Unexpected error message for Assert.TableIsEmpty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecordIsNotEmptyTest()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        InsertNameValueBuffer(NameValueBuffer, 1);
        Assert.RecordIsNotEmpty(NameValueBuffer);

        NameValueBuffer.DeleteAll();
        asserterror Assert.RecordIsNotEmpty(NameValueBuffer);
        Assert.AreEqual(
          StrSubstNo(TableIsNotEmptyErr, NameValueBuffer.TableCaption(), NameValueBuffer.GetFilters),
          GetLastErrorText,
          'Unexpected error message for Assert.TableIsNotEmpty');

        InsertNameValueBuffer(NameValueBuffer, 1);
        NameValueBuffer.SetRange(ID, 1);
        Assert.RecordIsNotEmpty(NameValueBuffer);

        NameValueBuffer.SetRange(ID, 2);
        asserterror Assert.RecordIsNotEmpty(NameValueBuffer);
        Assert.AreEqual(
          StrSubstNo(TableIsNotEmptyErr, NameValueBuffer.TableCaption(), NameValueBuffer.GetFilters),
          GetLastErrorText,
          'Unexpected error message for Assert.TableIsNotEmpty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TempRecordIsEmptyTest()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
    begin
        TempNameValueBuffer.DeleteAll();
        Assert.RecordIsEmpty(TempNameValueBuffer);

        InsertNameValueBuffer(TempNameValueBuffer, 1);
        asserterror Assert.RecordIsEmpty(TempNameValueBuffer);
        Assert.AreEqual(
          StrSubstNo(TableIsEmptyErr, TempNameValueBuffer.TableCaption(), TempNameValueBuffer.GetFilters),
          GetLastErrorText,
          'Unexpected error message for Assert.TableIsEmpty');

        TempNameValueBuffer.SetRange(ID, 2);
        Assert.RecordIsEmpty(TempNameValueBuffer);

        TempNameValueBuffer.SetRange(ID, 1);
        asserterror Assert.RecordIsEmpty(TempNameValueBuffer);
        Assert.AreEqual(
          StrSubstNo(TableIsEmptyErr, TempNameValueBuffer.TableCaption(), TempNameValueBuffer.GetFilters),
          GetLastErrorText,
          'Unexpected error message for Assert.TableIsEmpty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TempRecordIsNotEmptyTest()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
    begin
        InsertNameValueBuffer(TempNameValueBuffer, 1);
        Assert.RecordIsNotEmpty(TempNameValueBuffer);

        TempNameValueBuffer.DeleteAll();
        asserterror Assert.RecordIsNotEmpty(TempNameValueBuffer);
        Assert.AreEqual(
          StrSubstNo(TableIsNotEmptyErr, TempNameValueBuffer.TableCaption(), TempNameValueBuffer.GetFilters),
          GetLastErrorText,
          'Unexpected error message for Assert.TableIsNotEmpty');

        InsertNameValueBuffer(TempNameValueBuffer, 1);
        TempNameValueBuffer.SetRange(ID, 1);
        Assert.RecordIsNotEmpty(TempNameValueBuffer);

        TempNameValueBuffer.SetRange(ID, 2);
        asserterror Assert.RecordIsNotEmpty(TempNameValueBuffer);
        Assert.AreEqual(
          StrSubstNo(TableIsNotEmptyErr, TempNameValueBuffer.TableCaption(), TempNameValueBuffer.GetFilters),
          GetLastErrorText,
          'Unexpected error message for Assert.TableIsNotEmpty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyExpectedError()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 170359] There isn't error if checkin empty error text

        // [GIVEN] Some code is throwing empty error

        // [WHEN] Invoke ERROR('')
        asserterror Error('');

        // [THEN] Assert.ExpectedError function correctly compared empty error with expected empty value
        Assert.ExpectedError('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorHasNotBeenThrown()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 170359] Throw error if error has not been thrown

        // [GIVEN] Some code without error

        // [WHEN] Invoke Assert.ExpectedError('')
        asserterror Assert.ExpectedError('');

        // [THEN] Assert.ExpectedError function returned 'The error has not been thrown.'
        Assert.ExpectedError(ErrorHasNotBeenThrownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TextEndsWithTest()
    var
        OriginalText: Text;
        Substring: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217135] Check if text ends with given substring

        // [GIVEN] Some text with given substring in the end
        OriginalText := 'OriginalText';
        Substring := 'Text';

        // [WHEN] Invoke Assert.TextEndsWith
        Assert.TextEndsWith(OriginalText, Substring);

        // [THEN] Assert.TextEndsWith throws no error
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TextEndsWithTestError()
    var
        OriginalText: Text;
        Substring: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217135] Check if text does not end with given substring

        // [GIVEN] Some text without given substring in the end
        OriginalText := 'OriginalText';
        Substring := 'Substring';

        // [WHEN] Invoke Assert.TextEndsWith
        asserterror Assert.TextEndsWith(OriginalText, Substring);

        // [THEN] Assert.TextEndsWith throws error
        Assert.ExpectedError(StrSubstNo(TextEndsWithErr, OriginalText, Substring));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TextEndsWithTestEmptySubstring()
    var
        OriginalText: Text;
        Substring: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217135] Check if text ends with empty substring

        // [GIVEN] Some text and substring
        OriginalText := 'OriginalText';
        Substring := '';

        // [WHEN] Invoke Assert.TextEndsWith
        asserterror Assert.TextEndsWith(OriginalText, Substring);

        // [THEN] Assert.TextEndsWith throws error
        Assert.ExpectedError(TextEndSubstringIsBlankErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TextEndsWithTestEmptyOriginalText()
    var
        OriginalText: Text;
        Substring: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217135] Check if empty text ends with substring

        // [GIVEN] Empty text with empty substring
        OriginalText := '';
        Substring := 'Substring';

        // [WHEN] Invoke Assert.TextEndsWith
        asserterror Assert.TextEndsWith(OriginalText, Substring);

        // [THEN] Assert.TextEndsWith throws error
        Assert.ExpectedError(StrSubstNo(TextEndsWithErr, OriginalText, Substring));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RecordCountNoFilter()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.DeleteAll();
        InsertNameValueBuffer(NameValueBuffer, 1);
        InsertNameValueBuffer(NameValueBuffer, 2);

        Assert.RecordCount(NameValueBuffer, 2);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RecordCountWithFilter()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.DeleteAll();
        InsertNameValueBuffer(NameValueBuffer, 1);
        InsertNameValueBuffer(NameValueBuffer, 2);

        NameValueBuffer.SetRange(ID, 1);

        Assert.RecordCount(NameValueBuffer, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RecordCountZeroWithIncorrectFilter()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.DeleteAll();
        InsertNameValueBuffer(NameValueBuffer, 1);
        InsertNameValueBuffer(NameValueBuffer, 2);

        NameValueBuffer.SetRange(ID, 3);

        Assert.RecordCount(NameValueBuffer, 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RecordCountFailedNoFilter()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.DeleteAll();
        InsertNameValueBuffer(NameValueBuffer, 1);
        InsertNameValueBuffer(NameValueBuffer, 2);

        asserterror Assert.RecordCount(NameValueBuffer, 1);

        Assert.ExpectedError(RecordCountErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RecordCountFailedWithFilter()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.DeleteAll();
        InsertNameValueBuffer(NameValueBuffer, 1);
        InsertNameValueBuffer(NameValueBuffer, 2);

        NameValueBuffer.SetRange(ID, 3);

        asserterror Assert.RecordCount(NameValueBuffer, 1);

        Assert.ExpectedError(RecordCountErr);
    end;

    [TransactionModel(TransactionModel::AutoRollback)]
    local procedure InsertNameValueBuffer(var NameValueBuffer: Record "Name/Value Buffer"; NewID: Integer)
    begin
        NameValueBuffer.Init();
        NameValueBuffer.ID := NewID;
        NameValueBuffer.Insert();
    end;
}

