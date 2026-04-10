codeunit 134278 "Workflow Single Server Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow Single Server]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";

    local procedure CleanUpTestUsers()
    var
        User: Record "User";
        UserSetup: Record "User Setup";
    begin
        UserSetup.DeleteAll();
        User.DeleteAll();
    end;

    [Test]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure GetDirectApproverForRequestor()
    var
        UserSetup: Record "User Setup";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
        EmailRequestor: Text;
        EmailApprover: Text;
        Result: Text;
        UserName1: Code[50];
        UserName2: Code[50];
    begin
        // Make sure that the test users are cleaned up
        CleanUpTestUsers();

        EmailRequestor := 'user1@microsoft.com';
        EmailApprover := 'user2@microsoft.com';
        UserName1 := 'user1';
        UserName2 := 'user2';

        // [GIVEN] User Setup for "User1" (requestor) and "User2" (approver)
        LibraryDocumentApprovals.CreateUserWithEmail(UserName1, UserId(), EmailRequestor);
        LibraryDocumentApprovals.CreateUserWithEmail(UserName2, '', EmailApprover);
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, UserName1, UserName2);

        // [WHEN] Request the direct approval workflow
        Result := WorkflowWebhookManagement.GetDirectApproverForRequestor(EmailRequestor);

        // Make sure that the test users are cleaned up
        CleanUpTestUsers();

        Assert.AreEqual(EmailApprover, Result, 'Expected approver email was not returned.');
    end;

    [Test]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure GetDirectApproverFailEmptyEmail()
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [When] Request the direct approval workflow without email fails
        asserterror WorkflowWebhookManagement.GetDirectApproverForRequestor('');
    end;

    [Test]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure GetDirectApproverWrongEmailRequestor()
    var
        UserSetup: Record "User Setup";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
        EmailRequestor: Text;
        EmailApprover: Text;
        EmailWrong: Text;
        UserName1: Code[50];
        UserName2: Code[50];
    begin
        // Make sure that the test users are cleaned up
        CleanUpTestUsers();

        EmailRequestor := 'user3@microsoft.com';
        EmailApprover := 'user4@microsoft.com';
        EmailWrong := 'user5@microsoft.com';
        UserName1 := 'user3';
        UserName2 := 'user4';

        // [GIVEN] User Setup for "User1" (requestor) and "User2" (approver)
        LibraryDocumentApprovals.CreateUserWithEmail(UserName1, '', EmailRequestor);
        LibraryDocumentApprovals.CreateUserWithEmail(UserName2, '', '');
        LibraryDocumentApprovals.CreateUserSetupWithEmail(UserSetup, UserName1, UserName2, EmailApprover);

        // [Then] Request the direct approval workflow with wrong email fails
        asserterror WorkflowWebhookManagement.GetDirectApproverForRequestor(EmailWrong);
    end;
}
