codeunit 136505 "Time Sheets Permissions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [HR] [Time Sheet] [Permissions]
    end;

    var
        Assert: Codeunit Assert;
        OpenUserSetupQst: Label 'You aren''t allowed to run this report. If you want, you can give yourself the Time Sheet Admin. rights, and then try again.\\ Do you want to do that now?';
        TimeSheetAdminErr: Label 'Time sheet administrator only is allowed to create time sheets.';
        ConfirmationAnswer: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateTimeSheetsAlreadyTimesheetAdminSuccess()
    var
        UserSetup: Record "User Setup";
        CreateTimeSheets: Report "Create Time Sheets";
    begin
        // [SCENARIO] Time sheet administrator can create time sheets

        UserSetup.Init();
        UserSetup."User ID" := UserId;
        UserSetup."Time Sheet Admin." := true;
        UserSetup.Insert();

        // [WHEN] User tries to run Report Create Time Sheets
        CreateTimeSheets.InitParameters(WorkDate(), 1, '', false, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run();

        // [THEN] No error occurs
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler,UserSetupPageHandlerFillIn')]
    procedure TestCreateTimeSheetsAddSetupSuccess()
    var
        UserSetup: Record "User Setup";
        CreateTimeSheets: Report "Create Time Sheets";
    begin
        // [SCENARIO] User adds time sheet administrator rights and can create time sheets

        UserSetup.DeleteAll();

        ConfirmationAnswer := true;

        // [WHEN] User tries to run Report Create Time Sheets
        CreateTimeSheets.InitParameters(WorkDate(), 1, '', false, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run();

        // [THEN] No error occurs
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestCreateTimeSheetsFailedRejectSetup()
    var
        UserSetup: Record "User Setup";
    begin
        // [SCENARIO] User regects to add Time Sheer admin rights and cannot create time sheet

        UserSetup.DeleteAll();

        ConfirmationAnswer := false;

        // [WHEN] User tries to run Report Create Time Sheets
        asserterror REPORT.Run(REPORT::"Create Time Sheets", false);
        Assert.ExpectedError(TimeSheetAdminErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler,UserSetupPageHandlerLeaveEmpty')]
    procedure TestCreateTimeSheetsFailedNoUserSetupProvided()
    var
        UserSetup: Record "User Setup";
    begin
        // [SCENARIO] User leaves User Setup empty and cannot create time sheet

        UserSetup.DeleteAll();

        ConfirmationAnswer := true;

        // [WHEN] User tries to run Report Create Time Sheets
        asserterror REPORT.Run(REPORT::"Create Time Sheets", false);
        Assert.ExpectedError(TimeSheetAdminErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.AreEqual(Question, OpenUserSetupQst, 'A different dialog was launched');
        Reply := ConfirmationAnswer;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UserSetupPageHandlerFillIn(var UserSetup: TestPage "User Setup")
    begin
        UserSetup."User ID".SetValue(UserId);
        UserSetup."Time Sheet Admin.".SetValue(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UserSetupPageHandlerLeaveEmpty(var UserSetup: TestPage "User Setup")
    begin
    end;
}

