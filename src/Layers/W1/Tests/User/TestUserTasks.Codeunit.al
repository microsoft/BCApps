codeunit 134769 "Test User Tasks"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [User Tasks]
        Init();
    end;

    var
        User1: Record User;
        User2: Record User;
        UserTaskGroup1: Record "User Task Group";
        UserTaskGroupMember: Record "User Task Group Member";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure TestUserCard()
    var
        UserTaskCard: TestPage "User Task Card";
        BaseDate: DateTime;
    begin
        // [SCENARIO] Test the User Task Card page.

        // [GIVEN] The User Tasks Card page.
        // [WHEN] The Page opens.
        // [THEN] Various fields are defaulted.
        BaseDate := CreateDateTime(20121212D, 000000T);
        UserTaskCard.Trap();
        UserTaskCard.OpenNew();
        UserTaskCard.Title.Value('Task 1');
        Assert.AreEqual(0DT, UserTaskCard."Start DateTime".AsDateTime(), 'Start DateTime should be 0DT');
        Assert.AreNearlyEqual(CurrentDateTime - BaseDate, UserTaskCard."Created DateTime".AsDateTime() - BaseDate,
          60000, 'Unexpected Created DateTime');
        Assert.AreEqual('', UserTaskCard.MultiLineTextControl.Value, 'Unexpected value in the Task Description');

        // [WHEN] The Percent Completed field is updated to be less that 100
        // [THEN] Various fields are defaulted.
        UserTaskCard."Percent Complete".Value('5');

        Assert.AreNearlyEqual(CurrentDateTime - BaseDate, UserTaskCard."Start DateTime".AsDateTime() - BaseDate,
          60000, 'Unexpected Start DateTime');

        // [WHEN] The Percent Completed field is updated to be = 100
        // [THEN] Various fields are defaulted.
        UserTaskCard."Percent Complete".Value('100');
        Assert.AreNearlyEqual(CurrentDateTime - BaseDate, UserTaskCard."Completed DateTime".AsDateTime() - BaseDate,
          60000, 'Unexpected Completed DateTime');

        // [WHEN] The Percent Completed field is updated to be less that 100
        // [THEN] Various fields are defaulted.
        UserTaskCard."Percent Complete".Value('15');
        Assert.AreEqual(0DT, UserTaskCard."Completed DateTime".AsDateTime(), 'Unexpected Completed DateTime');

        // [WHEN] The Percent Completed field is updated to be 0
        // [THEN] Various fields are defaulted.
        UserTaskCard."Percent Complete".Value('0');
        Assert.AreEqual(0DT, UserTaskCard."Completed DateTime".AsDateTime(), 'Unexpected Completed DateTime');
        Assert.AreEqual(0DT, UserTaskCard."Start DateTime".AsDateTime(), 'Unexpected Start Date Time');

        // [WHEN] The Completed Date field is updated.
        // [THEN] Various fields are defaulted.
        UserTaskCard."Completed DateTime".Value(Format(CurrentDateTime));
        Assert.AreEqual(100, UserTaskCard."Percent Complete".AsInteger(), 'Unexpected Percent Complete');

        // [WHEN] The user creates a hyper link using the object selection controls.

        // [WHEN] The user tries to creates a hyper link using page of type card.
        // [THEN] An error message is raised, handler below.
        UserTaskCard."Object Type".Value('Page');
        asserterror UserTaskCard."Object ID".Value('21');

        UserTaskCard.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('RequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestUserPurge()
    var
        UserTask: Record "User Task";
    begin
        // [SCENARIO] Test the User Task purge.

        // [GIVEN] Several Task records with different creators.
        UserTask.DeleteAll();
        UserTask.Init();
        UserTask."Created By" := User1."User Security ID";
        UserTask."Assigned To" := User2."User Security ID";
        UserTask.Insert();

        Clear(UserTask);
        UserTask.Init();
        UserTask."Created By" := User2."User Security ID";
        UserTask."Assigned To" := User1."User Security ID";
        UserTask.Insert();

        // [WHEN] The task purge is asked to delete tasks for User1
        // [THEN] Those records are deleted, tasks created by User2 remain.

        Assert.AreEqual(2, UserTask.Count, 'Unexpected record count prior to purge');
        Commit();

        REPORT.Run(REPORT::"User Task Utility");

        Assert.AreEqual(1, UserTask.Count, 'Unexpected record count prior to purge');
        Assert.IsTrue(UserTask.FindFirst(), 'Expected record to be found');
        Assert.AreEqual(User2."User Security ID", UserTask."Created By", 'Expected Task for User2 not found');
    end;

    [Test]
    procedure TestUserCompleteTask()
    var
        UserTask: Record "User Task";
        UserTaskMgt: Codeunit "User Task Management";
    begin
        // [SCENARIO] Test the User Task purge.

        // [GIVEN] Several Task records with different creators.
        UserTask.DeleteAll();
        UserTask.Init();
        UserTask."Created By" := UserSecurityId();
        UserTask."Assigned To" := UserSecurityId();
        UserTask.Insert();

        Clear(UserTask);
        UserTask.Init();
        UserTask."Created By" := UserSecurityId();
        UserTask."Assigned To" := UserSecurityId();
        UserTask.Insert();

        Clear(UserTask);
        UserTask.Init();
        UserTask."Created By" := User2."User Security ID";
        UserTask."Assigned To" := User2."User Security ID";
        UserTask.Insert();
        Clear(UserTask);

        UserTaskMgt.SetFiltersToShowMyUserTasks(UserTask, 0); // 0 - DueDateFilterOptions::NONE:
        UserTask.FilterGroup(2);
        UserTaskMgt.CompleteTasks(UserTask);

        Clear(UserTask);
        UserTask.SetRange("Percent Complete", 100);
        Assert.RecordCount(UserTask, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WinEncodingInDescriptionBLOB()
    var
        UserTask: Record "User Task";
        UserTask2: Record "User Task";
    begin
        // FEATURE] [UT]
        // [SCENARIO 253612] Task Description field in User Task table must be set accordingly to its encoding
        UserTask.Init();
        UserTask.SetDescription('Vytvorení úcetního období pro rok 2018');
        UserTask.Insert();

        UserTask2.Get(UserTask.ID);
        Assert.AreEqual('Vytvorení úcetního období pro rok 2018', UserTask2.GetDescription(), 'Unexpected value in the Task Description');
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestRenameUser()
    var
        User: Record User;
        FieldRec: Record "Field";
        Company: Record Company;
        TableInformation: Record "Table Information";
        TempTablesAlreadyInserted: Record Integer temporary;
        RecRef: RecordRef;
        FldRef: FieldRef;
        UserCodeunit: Codeunit User;
    begin
        // [GIVEN] Create data for tables with fields having relation with User table
        Company.FindFirst();
        FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);
        FieldRec.SetRange(RelationTableNo, DATABASE::User);
        FieldRec.SetRange(RelationFieldNo, User.FieldNo("User Name"));
        FieldRec.SetFilter(Type, '%1|%2', FieldRec.Type::Code, FieldRec.Type::Text);
        if FieldRec.FindSet() then
            repeat
                TableInformation.SetFilter("Company Name", '%1|%2', '', Company.Name);
                TableInformation.SetRange("Table No.", FieldRec.TableNo);
                if TableInformation.FindFirst() then begin
                    RecRef.Open(FieldRec.TableNo, false, Company.Name);
                    if TempTablesAlreadyInserted.Get(FieldRec.TableNo) then begin
                        RecRef.FindFirst();
                        FldRef := RecRef.Field(FieldRec."No.");
                        FldRef.Value('OLD');
                        RecRef.Modify();
                    end else begin
                        RecRef.DeleteAll();
                        RecRef.Init();
                        FldRef := RecRef.Field(FieldRec."No.");
                        FldRef.Value('OLD');
                        RecRef.Insert();
                        TempTablesAlreadyInserted.Init();
                        TempTablesAlreadyInserted.Number := FieldRec.TableNo;
                        TempTablesAlreadyInserted.Insert();
                    end;
                    RecRef.Close();
                end;
            until FieldRec.Next() = 0;

        // [WHEN] RenameUser is invoked
        UserCodeunit.RenameUser('OLD', 'NEW');

        // [THEN] The data in the table fields has been updated
        if FieldRec.FindSet() then
            repeat
                TableInformation.SetFilter("Company Name", '%1|%2', '', Company.Name);
                TableInformation.SetRange("Table No.", FieldRec.TableNo);
                if TableInformation.FindFirst() then begin
                    RecRef.Open(FieldRec.TableNo, false, Company.Name);
                    FldRef := RecRef.Field(FieldRec."No.");
                    FldRef.SetRange('NEW');
                    Assert.AreEqual(1, RecRef.Count(), StrSubstNo('Records with new username should exist in %1.', TableInformation."Table Name"));
                    RecRef.Close();
                end;
            until FieldRec.Next() = 0;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestWindowsSecurityIdNotEditableOnSaaS()
    begin
        VerifyWindowsSecurityIdEditability(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestWindowsSecurityIdEditableOnPrem()
    begin
        VerifyWindowsSecurityIdEditability(false);
    end;

    [Scope('OnPrem')]
    procedure Init()
    var
        UserTask: Record "User Task";
        LibraryPermissions: Codeunit "Library - Permissions";
    begin
        UserTask.DeleteAll();

        LibraryPermissions.CreateUser(User1, '', false);
        LibraryPermissions.CreateUser(User2, '', false);

        // Create user task groups
        CreateUserTaskGroup(UserTaskGroup1);
        AddUserToUserTaskGroupByCode(User1."User Security ID", 'GroupA');
    end;

    [Test]
    [HandlerFunctions('CustomerListPageHandler')]
    [Scope('OnPrem')]
    procedure EnsurePageLinkedToTaskCanBeOpened()
    var
        UserTaskCard: TestPage "User Task Card";
    begin
        // [SCENARIO] Ensure linked page to user task card page can be opened by an action on the page.

        // [GIVEN] A task user card page with a valid page type associated with it.
        UserTaskCard.Trap();
        UserTaskCard.OpenNew();
        UserTaskCard."Object Type".Value('page');
        UserTaskCard."Object ID".Value('22');

        // [WHEN] An action on the user card page is clicked to open up linked page to task
        // [THEN] Linked page opens up handled by CustomerListPageHandler
        UserTaskCard."Go To Task Item".Invoke();

        UserTaskCard.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerListPageHandler(var CustomerList: Page "Customer List")
    begin
        // Handles customer list page opening from user task card.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandler(var UserTaskPurge: TestRequestPage "User Task Utility")
    begin
        UserTaskPurge."User Task".SetFilter("Created By", User1."User Security ID");
        UserTaskPurge.OK().Invoke();
    end;

    [Scope('OnPrem')]
    procedure CreateUserTaskGroup(var UserTaskGroup: Record "User Task Group")
    begin
        UserTaskGroup.Init();
        UserTaskGroup.Code := LibraryUtility.GenerateGUID();
        UserTaskGroup.Description := LibraryUtility.GenerateGUID();
        UserTaskGroup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure AddUserToUserTaskGroupByCode(UserSecID: Guid; GroupCode: Code[20])
    begin
        if UserTaskGroupMember.Get(GroupCode, UserSecID) then
            exit;
        UserTaskGroupMember.Init();
        UserTaskGroupMember."User Task Group Code" := GroupCode;
        UserTaskGroupMember."User Security ID" := UserSecID;
        UserTaskGroupMember.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure VerifyWindowsSecurityIdEditability(IsSaaSInfrastructure: Boolean)
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        User: Record User;
        LibraryPermissions: Codeunit "Library - Permissions";
    begin
        // [SCENARIO] User Windows Security ID editability based on environment
        LibraryPermissions.CreateUser(User, '', false);
        User.FindFirst();

        // [GIVEN] A given system setup (SaaS or OnPrem)
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(IsSaaSInfrastructure);

        // [GIVEN] User tries to modify SID
        User."Windows Security ID" := 'SomeSID';

        // [THEN] Modification throws error when in SaaS environment or succeeds when in OnPrem environment
        if IsSaaSInfrastructure then
            asserterror User.Modify()
        else
            Assert.IsTrue(User.Modify(), 'Modifying the Windows user''s Windows Security ID should be possible in OnPrem environment');
    end;
}
