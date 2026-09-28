codeunit 139326 "Create Company Tests"
{
    // Company-Initialize must run in a freshly created, committed company from a separate session,
    // the same way it runs in production. That is why test isolation is disabled here.
    // Isolation-disabled tests only run in the UnitTest stage (runner 130451), so this app must not be in a legacy bucket.
    Subtype = Test;
    TestType = UnitTest;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Company-Initialize] [Company Creation]
    end;

    var
        Assert: Codeunit Assert;
        CompanyNamePrefixTxt: Label 'CCTEST-', Locked = true;
        StartSessionFailedErr: Label 'Could not start a session in company %1.', Comment = '%1 = company name';
        SessionTimeoutErr: Label 'Company-Initialize did not finish in company %1 within the timeout.', Comment = '%1 = company name';
        NoResultErr: Label 'Company-Initialize did not report a result in company %1. The session may have been terminated by an unhandled error.', Comment = '%1 = company name';
        CompanyInitializeFailedErr: Label 'Company-Initialize failed in new company %1: %2', Comment = '%1 = company name, %2 = error text';
        SetupRecordMissingErr: Label '%1 was not initialized in new company %2.', Comment = '%1 = table caption, %2 = company name';

    [Test]
    [Scope('OnPrem')]
    procedure CompanyInitializeSucceedsInNewCompany()
    begin
        // [SCENARIO 629656] Company-Initialize (Codeunit 2) runs without errors in a newly created company (on-premises)
        VerifyCompanyInitializeInNewCompany(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyInitializeSucceedsInNewCompanyAsSaaS()
    begin
        // [SCENARIO 629656] Company-Initialize (Codeunit 2) runs without errors in a newly created company (SaaS)
        // Country-specific OnCompanyInitialize subscribers can fail only in SaaS. Bug 629494 is an example: NO URL validation.
        VerifyCompanyInitializeInNewCompany(true);
    end;

    local procedure VerifyCompanyInitializeInNewCompany(RunAsSaaS: Boolean)
    var
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        CreateCompanyTestInit: Codeunit "Create Company Test Init";
        NewCompanyName: Text[30];
        Result: Text;
        MissingSetupTableCaption: Text;
        HasResult: Boolean;
    begin
        Initialize();

        // [GIVEN] A new, empty company
        NewCompanyName := GenerateCompanyName();
        AssistedCompanySetup.CreateNewCompany(NewCompanyName);

        // [WHEN] Company-Initialize runs in the new company, in its own session
        CreateCompanyTestInit.SetRunAsSaaS(NewCompanyName, RunAsSaaS);
        Commit();
        RunCompanyInitializeInCompany(NewCompanyName);
        HasResult := CreateCompanyTestInit.TryGetResult(NewCompanyName, Result);
        MissingSetupTableCaption := FindMissingCoreSetupTable(NewCompanyName);
        DeleteCompany(NewCompanyName);

        // [THEN] Company-Initialize completes without errors
        Assert.IsTrue(HasResult, StrSubstNo(NoResultErr, NewCompanyName));
        Assert.IsTrue(Result = CreateCompanyTestInit.GetSuccessValue(), StrSubstNo(CompanyInitializeFailedErr, NewCompanyName, Result));

        // [THEN] Core setup tables are initialized in the new company
        Assert.AreEqual('', MissingSetupTableCaption, StrSubstNo(SetupRecordMissingErr, MissingSetupTableCaption, NewCompanyName));
    end;

    local procedure Initialize()
    var
        Company: Record Company;
    begin
        // Remove companies left behind by previous, interrupted runs
        Company.SetFilter(Name, CompanyNamePrefixTxt + '*');
        if Company.FindSet() then
            repeat
                DeleteCompany(Company.Name);
            until Company.Next() = 0;
    end;

    local procedure RunCompanyInitializeInCompany(NewCompanyName: Text[30])
    var
        ActiveSession: Record "Active Session";
        InitSessionId: Integer;
        StartTime: DateTime;
        TimeoutMs: Integer;
    begin
        Assert.IsTrue(
            StartSession(InitSessionId, Codeunit::"Create Company Test Init", NewCompanyName),
            StrSubstNo(StartSessionFailedErr, NewCompanyName));

        TimeoutMs := 10 * 60 * 1000;
        StartTime := CurrentDateTime();
        while ActiveSession.Get(ServiceInstanceId(), InitSessionId) do begin
            if CurrentDateTime() - StartTime > TimeoutMs then begin
                StopSession(InitSessionId);
                Error(SessionTimeoutErr, NewCompanyName);
            end;
            Sleep(500);
        end;
    end;

    local procedure FindMissingCoreSetupTable(NewCompanyName: Text[30]): Text
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        InventorySetup: Record "Inventory Setup";
        SourceCodeSetup: Record "Source Code Setup";
        CompanyInformation: Record "Company Information";
    begin
        GeneralLedgerSetup.ChangeCompany(NewCompanyName);
        if GeneralLedgerSetup.IsEmpty() then
            exit(GeneralLedgerSetup.TableCaption());

        SalesReceivablesSetup.ChangeCompany(NewCompanyName);
        if SalesReceivablesSetup.IsEmpty() then
            exit(SalesReceivablesSetup.TableCaption());

        PurchasesPayablesSetup.ChangeCompany(NewCompanyName);
        if PurchasesPayablesSetup.IsEmpty() then
            exit(PurchasesPayablesSetup.TableCaption());

        InventorySetup.ChangeCompany(NewCompanyName);
        if InventorySetup.IsEmpty() then
            exit(InventorySetup.TableCaption());

        SourceCodeSetup.ChangeCompany(NewCompanyName);
        if SourceCodeSetup.IsEmpty() then
            exit(SourceCodeSetup.TableCaption());

        CompanyInformation.ChangeCompany(NewCompanyName);
        if CompanyInformation.IsEmpty() then
            exit(CompanyInformation.TableCaption());
    end;

    local procedure GenerateCompanyName(): Text[30]
    begin
        exit(CopyStr(CompanyNamePrefixTxt + CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 16), 1, 30));
    end;

    local procedure DeleteCompany(CompanyNameToDelete: Text[30])
    var
        Company: Record Company;
        CreateCompanyTestInit: Codeunit "Create Company Test Init";
    begin
        CreateCompanyTestInit.ClearState(CompanyNameToDelete);
        if Company.Get(CompanyNameToDelete) then
            Company.Delete(true);
        Commit();
    end;
}
