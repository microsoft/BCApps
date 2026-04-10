codeunit 134324 "Workflow User Group Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [User Group]
    end;

    var
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure DeletingWorkflowUserGroupDeletesItsMembers()
    var
        UserSetup1: Record "User Setup";
        UserSetup2: Record "User Setup";
        UserSetup3: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowUserGroupMember: Record "Workflow User Group Member";
    begin
        // [SCENARIO] Deleting Workflow User Group deletes its members.
        // [GIVEN] A Workflow User Group with members.
        // [WHEN] The Workflow User Group is deleted.
        // [THEN] The Workflow User Group Members gets deleted as well;

        // Setup
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup1);
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup2);
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup3);

        CreateWorkflowUserGroup(WorkflowUserGroup);
        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, UserSetup1."User ID", 1);
        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, UserSetup2."User ID", 2);
        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, UserSetup3."User ID", 3);

        // Excercise
        WorkflowUserGroup.Delete(true);

        // Verification
        asserterror WorkflowUserGroupMember.Get(WorkflowUserGroup.Code, UserSetup1."User ID");
        Assert.ExpectedErrorCannotFind(Database::"Workflow User Group Member");
        asserterror WorkflowUserGroupMember.Get(WorkflowUserGroup.Code, UserSetup2."User ID");
        Assert.ExpectedErrorCannotFind(Database::"Workflow User Group Member");
        asserterror WorkflowUserGroupMember.Get(WorkflowUserGroup.Code, UserSetup3."User ID");
        Assert.ExpectedErrorCannotFind(Database::"Workflow User Group Member");
    end;

    local procedure CreateWorkflowUserGroup(var WorkflowUserGroup: Record "Workflow User Group")
    begin
        WorkflowUserGroup.Code := LibraryUtility.GenerateRandomCode(WorkflowUserGroup.FieldNo(Code), DATABASE::"Workflow User Group");
        WorkflowUserGroup.Description := CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50);
        WorkflowUserGroup.Insert(true);
    end;
}

