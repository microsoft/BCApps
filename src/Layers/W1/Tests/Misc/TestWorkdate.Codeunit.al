codeunit 139028 "Test Workdate"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

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
        SetCompanyWorkDateSettings(CompanyInformation, true, false);
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
        SetCompanyWorkDateSettings(CompanyInformation, true, true);
        CreateLatestGLEntry();

        Assert.AreEqual(Today, LogInManagement.GetDefaultWorkDate(), 'Today should be used as the work date.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonEvaluationCompanyIgnoresUseTodayAsWorkDate()
    var
        CompanyInformation: Record "Company Information";
        LogInManagement: Codeunit LogInManagement;
    begin
        // [SCENARIO] The evaluation-company setting does not affect a regular company.
        SetCompanyWorkDateSettings(CompanyInformation, false, true);
        CreateLatestGLEntry();

        Assert.AreEqual(WorkDate(), LogInManagement.GetDefaultWorkDate(), 'The current work date should remain unchanged.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UseTodayAsWorkDateIsVisibleForEvaluationCompany()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationPage: TestPage "Company Information";
    begin
        // [SCENARIO] The work date setting is visible for an evaluation company.
        SetCompanyWorkDateSettings(CompanyInformation, true, false);

        CompanyInformationPage.OpenEdit();

        Assert.IsTrue(CompanyInformationPage."Use Today as a Workdate".Visible(), 'The field should be visible for an evaluation company.');
        CompanyInformationPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UseTodayAsWorkDateIsHiddenForRegularCompany()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationPage: TestPage "Company Information";
    begin
        // [SCENARIO] The work date setting is hidden for a regular company.
        SetCompanyWorkDateSettings(CompanyInformation, false, false);

        CompanyInformationPage.OpenEdit();

        Assert.IsFalse(CompanyInformationPage."Use Today as a Workdate".Visible(), 'The field should be hidden for a regular company.');
        CompanyInformationPage.Close();
    end;

    local procedure SetCompanyWorkDateSettings(var CompanyInformation: Record "Company Information"; IsEvaluationCompany: Boolean; UseTodayAsWorkDate: Boolean)
    begin
        CompanyInformation.Get();
        CompanyInformation."Demo Company" := IsEvaluationCompany;
        CompanyInformation."Use Today as a Workdate" := UseTodayAsWorkDate;
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
