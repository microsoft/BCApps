codeunit 139028 "Test Workdate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    Permissions =
        tabledata Company = rm,
        tabledata "Company Information" = rm,
        tabledata "G/L Entry" = rimd;

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
    procedure EvaluationCompanyCanUseSpecificWorkDate()
    var
        CompanyInformation: Record "Company Information";
        LogInManagement: Codeunit LogInManagement;
        SpecificWorkDate: Date;
    begin
        // [SCENARIO] An evaluation company can use a specific work date.
        SpecificWorkDate := CalcDate('<-1M>', Today);
        SetCompanyWorkDateSettings(CompanyInformation, true, false, CompanyInformation."Evaluation Work Date"::"Specific Date", SpecificWorkDate);
        CreateLatestGLEntry();

        Assert.AreEqual(SpecificWorkDate, LogInManagement.GetDefaultWorkDate(), 'The specific date should be used as the work date.');
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
    procedure EvaluationWorkDateIsVisibleForEvaluationCompany()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationPage: TestPage "Company Information";
    begin
        // [SCENARIO] The work date setting is visible for an evaluation company.
        SetCompanyWorkDateSettings(CompanyInformation, true, false, CompanyInformation."Evaluation Work Date"::"Latest G/L Entry Posting Date", 0D);

        CompanyInformationPage.OpenEdit();

        Assert.IsTrue(CompanyInformationPage."Evaluation Work Date".Visible(), 'The field should be visible for an evaluation company.');
        CompanyInformationPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluationWorkDateIsHiddenForRegularCompany()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationPage: TestPage "Company Information";
    begin
        // [SCENARIO] The work date setting is hidden for a regular company.
        SetCompanyWorkDateSettings(CompanyInformation, false, false, CompanyInformation."Evaluation Work Date"::"Latest G/L Entry Posting Date", 0D);

        CompanyInformationPage.OpenEdit();

        Assert.IsFalse(CompanyInformationPage."Evaluation Work Date".Visible(), 'The field should be hidden for a regular company.');
        CompanyInformationPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluationWorkDateIsVisibleForDemoCompany()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationPage: TestPage "Company Information";
    begin
        // [SCENARIO] The work date setting remains visible for a legacy demo company.
        SetCompanyWorkDateSettings(CompanyInformation, false, true, CompanyInformation."Evaluation Work Date"::"Latest G/L Entry Posting Date", 0D);

        CompanyInformationPage.OpenEdit();

        Assert.IsTrue(CompanyInformationPage."Evaluation Work Date".Visible(), 'The field should be visible for a demo company.');
        CompanyInformationPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecificWorkDateVisibilityChangesWithSelection()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationPage: TestPage "Company Information";
    begin
        // [SCENARIO] The specific date is shown only when Specific Date is selected.
        SetCompanyWorkDateSettings(CompanyInformation, true, false, CompanyInformation."Evaluation Work Date"::Today, 0D);

        CompanyInformationPage.OpenEdit();
        Assert.IsFalse(CompanyInformationPage."Specific Work Date".Visible(), 'The specific date should initially be hidden.');

        CompanyInformationPage."Evaluation Work Date".SetValue(CompanyInformation."Evaluation Work Date"::"Specific Date");

        Assert.IsTrue(CompanyInformationPage."Specific Work Date".Visible(), 'The specific date should be visible for the Specific Date option.');
        CompanyInformationPage."Specific Work Date".SetValue(Today);
        CompanyInformationPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecificWorkDateIsRequired()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationPage: TestPage "Company Information";
    begin
        // [SCENARIO] A specific work date must be entered when Specific Date is selected.
        SetCompanyWorkDateSettings(CompanyInformation, true, false, CompanyInformation."Evaluation Work Date"::"Specific Date", 0D);

        CompanyInformationPage.OpenEdit();
        asserterror CompanyInformationPage.Close();

        Assert.ExpectedTestFieldError(CompanyInformation.FieldCaption("Specific Work Date"), '');
        CompanyInformationPage."Specific Work Date".SetValue(Today);
        CompanyInformationPage.Close();
    end;

    local procedure SetCompanyWorkDateSettings(var CompanyInformation: Record "Company Information"; IsEvaluationCompany: Boolean; IsDemoCompany: Boolean; EvaluationWorkDate: Option "Latest G/L Entry Posting Date",Today,"Specific Date"; SpecificWorkDate: Date)
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName());
        Company."Evaluation Company" := IsEvaluationCompany;
        Company.Modify();

        CompanyInformation.Get();
        CompanyInformation."Demo Company" := IsDemoCompany;
        CompanyInformation."Evaluation Work Date" := EvaluationWorkDate;
        CompanyInformation."Specific Work Date" := SpecificWorkDate;
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
