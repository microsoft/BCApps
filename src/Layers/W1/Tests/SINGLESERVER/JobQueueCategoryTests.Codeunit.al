codeunit 139019 "Job Queue Category Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Job Queue] [Category]
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [HandlerFunctions('JobQueueCategoryHandler')]
    [Scope('OnPrem')]
    procedure VerifyJobQueueCategoryLookupIsValidPage()
    var
        NewJobQueueCategory: Record "Job Queue Category";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        SalesReceivablesSetupPage: TestPage "Sales & Receivables Setup";
    begin
        // Setup
        LibraryLowerPermissions.SetO365Full();
        NewJobQueueCategory.Code := LibraryUtility.GenerateRandomCode(NewJobQueueCategory.FieldNo(Code), DATABASE::"Job Queue Category");
        NewJobQueueCategory.Description :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(NewJobQueueCategory.Description)),
            1, MaxStrLen(NewJobQueueCategory.Description));
        NewJobQueueCategory.Insert(true);

        // Start Page
        SalesReceivablesSetupPage.OpenEdit();

        // Execution
        LibraryVariableStorage.Enqueue(NewJobQueueCategory.Code);
        SalesReceivablesSetupPage."Job Queue Category Code".Lookup();

        // Coming back from the handler
        SalesReceivablesSetupPage."Job Queue Category Code".AssertEquals(NewJobQueueCategory.Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobQueueCategoryHandler(var JobQueueCategoryList: TestPage "Job Queue Category List")
    begin
        // Select the new value that was just created
        JobQueueCategoryList.GotoKey(LibraryVariableStorage.DequeueText());
        JobQueueCategoryList.OK().Invoke();
    end;
}

