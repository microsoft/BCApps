codeunit 139028 "Test Workdate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    Permissions =
        tabledata Company = rm,
        tabledata "Company Information" = rm,
        tabledata "G/L Entry" = ri;

    trigger OnRun()
    begin
        // [FEATURE] [Default WorkDate]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluationCompanyUsesLatestGLEntryPostingDateByDefault()
    var
        CompanyInformation: Record "Company Information";
        LogInManagement: Codeunit LogInManagement;
        LatestPostingDate: Date;
    begin
        // [SCENARIO] An evaluation company uses the latest G/L entry posting date by default.
        SetCompanyWorkDateSettings(CompanyInformation, true, false, CompanyInformation."Evaluation Work Date"::"Latest G/L Entry Posting Date", 0D);
        LatestPostingDate := CreateLatestGLEntry();

        Assert.AreEqual(LatestPostingDate, LogInManagement.GetDefaultWorkDate(), 'The latest G/L entry posting date should be used.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluationCompanyCanUseTodayAsWorkDate()
    var
        CompanyInformation: Record "Company Information";
        LogInManagement: Codeunit LogInManagement;
    begin
        // [SCENARIO] An evaluation company can use today instead of the latest G/L entry posting date.
        SetCompanyWorkDateSettings(CompanyInformation, true, false, CompanyInformation."Evaluation Work Date"::Today, 0D);
        CreateLatestGLEntry();

        Assert.AreEqual(Today, LogInManagement.GetDefaultWorkDate(), 'Today should be used as the work date.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluationCompanyCanUseCustomWorkDate()
    var
        CompanyInformation: Record "Company Information";
        LogInManagement: Codeunit LogInManagement;
        CustomWorkDate: Date;
    begin
        // [SCENARIO] An evaluation company can use a custom work date.
        CustomWorkDate := CalcDate('<-1M>', Today);
        SetCompanyWorkDateSettings(CompanyInformation, true, false, CompanyInformation."Evaluation Work Date"::"Custom Date", CustomWorkDate);
        CreateLatestGLEntry();

        Assert.AreEqual(CustomWorkDate, LogInManagement.GetDefaultWorkDate(), 'The custom date should be used as the work date.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluationCompanyWithBlankCustomWorkDateUsesToday()
    var
        CompanyInformation: Record "Company Information";
        LogInManagement: Codeunit LogInManagement;
    begin
        // [SCENARIO] An evaluation company with an invalid blank custom work date safely uses today.
        SetCompanyWorkDateSettings(CompanyInformation, true, false, CompanyInformation."Evaluation Work Date"::"Custom Date", 0D);

        Assert.AreEqual(Today, LogInManagement.GetDefaultWorkDate(), 'Today should be used when the custom work date is blank.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonEvaluationCompanyIgnoresEvaluationWorkDate()
    var
        CompanyInformation: Record "Company Information";
        LogInManagement: Codeunit LogInManagement;
    begin
        // [SCENARIO] The evaluation-company setting does not affect a regular company.
        SetCompanyWorkDateSettings(CompanyInformation, false, false, CompanyInformation."Evaluation Work Date"::Today, 0D);
        CreateLatestGLEntry();

        Assert.AreEqual(WorkDate(), LogInManagement.GetDefaultWorkDate(), 'The current work date should remain unchanged.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluationCompanyCanApplyWorkDateToAllSessions()
    var
        CompanyInformation: Record "Company Information";
        LogInManagement: Codeunit LogInManagement;
        CustomWorkDate: Date;
        DefaultWorkDate: Date;
        ApplyWorkDateToAllSessions: Boolean;
    begin
        // [SCENARIO] An evaluation company can apply its work date to all session types.
        CustomWorkDate := CalcDate('<-1M>', Today);
        SetCompanyWorkDateSettings(CompanyInformation, true, false, CompanyInformation."Evaluation Work Date"::"Custom Date", CustomWorkDate, true);

        ApplyWorkDateToAllSessions := LogInManagement.GetDefaultWorkDateForAllSessions(ClientType::Background, DefaultWorkDate);

        Assert.AreEqual(CustomWorkDate, DefaultWorkDate, 'The custom work date should be used.');
        Assert.IsTrue(ApplyWorkDateToAllSessions, 'The work date should be applied to all sessions.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluationCompanyAppliesTodayInUserTimeZoneToApiSessions()
    var
        CompanyInformation: Record "Company Information";
        LogInManagement: Codeunit LogInManagement;
        TypeHelper: Codeunit "Type Helper";
        DefaultWorkDate: Date;
        ExpectedWorkDate: Date;
        ApplyWorkDateToAllSessions: Boolean;
    begin
        // [SCENARIO] An API session uses today in the user's time zone when the work date applies to all sessions.
        SetCompanyWorkDateSettings(CompanyInformation, true, false, CompanyInformation."Evaluation Work Date"::Today, 0D, true);
        ExpectedWorkDate := DT2Date(TypeHelper.GetCurrentDateTimeInUserTimeZone());

        ApplyWorkDateToAllSessions := LogInManagement.GetDefaultWorkDateForAllSessions(ClientType::Api, DefaultWorkDate);

        Assert.IsTrue(ApplyWorkDateToAllSessions, 'The work date should be applied to all sessions.');
        Assert.AreEqual(ExpectedWorkDate, DefaultWorkDate, 'The API session should use today in the user''s time zone.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegularCompanyCannotApplyWorkDateToAllSessions()
    var
        CompanyInformation: Record "Company Information";
        LogInManagement: Codeunit LogInManagement;
        DefaultWorkDate: Date;
        ApplyWorkDateToAllSessions: Boolean;
    begin
        // [SCENARIO] A regular company cannot apply the evaluation work date to all session types.
        SetCompanyWorkDateSettings(CompanyInformation, false, false, CompanyInformation."Evaluation Work Date"::Today, 0D, true);

        ApplyWorkDateToAllSessions := LogInManagement.GetDefaultWorkDateForAllSessions(ClientType::Background, DefaultWorkDate);

        Assert.AreEqual(0D, DefaultWorkDate, 'The default work date should not be calculated.');
        Assert.IsFalse(ApplyWorkDateToAllSessions, 'The work date should not be applied to all sessions.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomWorkDateIsRequired()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO] A custom work date cannot be cleared.
        SetCompanyWorkDateSettings(CompanyInformation, true, false, CompanyInformation."Evaluation Work Date"::"Custom Date", Today);

        asserterror CompanyInformation.Validate("Custom Work Date", 0D);
        Assert.ExpectedTestFieldError(CompanyInformation.FieldCaption("Custom Work Date"), '');
    end;

    local procedure SetCompanyWorkDateSettings(var CompanyInformation: Record "Company Information"; IsEvaluationCompany: Boolean; IsDemoCompany: Boolean; EvaluationWorkDate: Option "Latest G/L Entry Posting Date",Today,"Custom Date"; CustomWorkDate: Date)
    begin
        SetCompanyWorkDateSettings(CompanyInformation, IsEvaluationCompany, IsDemoCompany, EvaluationWorkDate, CustomWorkDate, false);
    end;

    local procedure SetCompanyWorkDateSettings(var CompanyInformation: Record "Company Information"; IsEvaluationCompany: Boolean; IsDemoCompany: Boolean; EvaluationWorkDate: Option "Latest G/L Entry Posting Date",Today,"Custom Date"; CustomWorkDate: Date; ApplyWorkDateToAllSessions: Boolean)
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName());
        Company."Evaluation Company" := IsEvaluationCompany;
        Company.Modify();

        CompanyInformation.Get();
        CompanyInformation."Demo Company" := IsDemoCompany;
        CompanyInformation."Evaluation Work Date" := EvaluationWorkDate;
        CompanyInformation."Custom Work Date" := CustomWorkDate;
        CompanyInformation."Apply Work Date to Sessions" := ApplyWorkDateToAllSessions;
        CompanyInformation.Modify();
    end;

    local procedure CreateLatestGLEntry(): Date
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Posting Date");
        if GLEntry.FindLast() then
            GLEntry."Posting Date" := CalcDate('<+1D>', NormalDate(GLEntry."Posting Date"))
        else
            GLEntry."Posting Date" := Today;

        GLEntry."Entry No." := GLEntry.GetLastEntryNo() + 1;
        GLEntry.Insert();
        exit(GLEntry."Posting Date");
    end;
}
