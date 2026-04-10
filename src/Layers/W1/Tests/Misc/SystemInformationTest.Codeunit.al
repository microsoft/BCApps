codeunit 132910 "System Information Test"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [System information]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        ErrorOccurredErr: Label 'Error occurred.', Locked = true;
        ErrorTwoOccurredErr: Label 'Error 2 occurred';

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldsVisibilityWhenErrorOccurs()
    var
        SystemInformationTestPage: TestPage "Latest Error";
    begin
        // [FEATURE] [Error]
        // [SCENARIO] When error occurs some error fields are visible

        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] An error occurred
        asserterror Error(ErrorOccurredErr);

        // [WHEN] The page is opened
        SystemInformationTestPage.OpenView();

        // [THEN] Error fields are visible
        Assert.IsTrue(SystemInformationTestPage.ErrorCallStack.Visible(), 'Expected Error Callstack to be visible');
        Assert.IsTrue(SystemInformationTestPage.ErrorText.Visible(), 'Expected Error Text to be visible');
        Assert.IsTrue(SystemInformationTestPage.ErrorCode.Visible(), 'Expected Error Code to be visible');

        SystemInformationTestPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorTextWhenErrorOccurs()
    var
        SystemInformationTestPage: TestPage "Latest Error";
    begin
        // [FEATURE] [Error]
        // [SCENARIO] When error occurs the error text field contains the error text

        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] An error occurred
        asserterror Error(ErrorOccurredErr);

        // [WHEN] The page is opened
        SystemInformationTestPage.OpenView();

        // [THEN] Error text field contains the error text
        Assert.AreEqual(ErrorOccurredErr, SystemInformationTestPage.ErrorText.Value, 'Invalid error text.');

        SystemInformationTestPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TesErrorTextWhenMultipleErrorsOccur()
    var
        SystemInformationTestPage: TestPage "Latest Error";
    begin
        // [FEATURE] [Error]
        // [SCENARIO] When multiple errors occur the error text field contains the latest error text

        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] Multiple errors occurred
        asserterror Error(ErrorOccurredErr);
        asserterror Error(ErrorTwoOccurredErr);

        // [WHEN] The page is opened
        SystemInformationTestPage.OpenView();

        // [THEN]  Error text field contains the latest error text
        Assert.AreEqual(ErrorTwoOccurredErr, SystemInformationTestPage.ErrorText.Value, 'Invalid error text.');

        SystemInformationTestPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGroupVisibilityWhenNoError()
    var
        SystemInformationTestPage: TestPage "Latest Error";
    begin
        // [FEATURE] [Error]
        // [SCENARIO] When no error occurs mo error fields are visible
        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] No error occurred
        ClearLastError();

        // [WHEN] The page is opened
        SystemInformationTestPage.OpenView();

        // [THEN] No error fields are visible
        Assert.IsFalse(SystemInformationTestPage.ErrorCallStack.Visible(), 'Expected Error Callstack to not be visible');
        Assert.IsFalse(SystemInformationTestPage.ErrorText.Visible(), 'Expected Error Text to not be visible');
        Assert.IsFalse(SystemInformationTestPage.ErrorCode.Visible(), 'Expected Error Code to not be visible');

        SystemInformationTestPage.Close();
    end;
}

