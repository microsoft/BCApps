codeunit 131352 "Library - Document Approvals"
{
    Permissions = TableData "Approval Entry" = imd;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryWorkflow: Codeunit "Library - Workflow";

    [Scope('OnPrem')]
    procedure CreateApprovalEntryBasic(var ApprovalEntry: Record "Approval Entry"; TableId: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20]; StatusOption: Enum "Approval Status"; LimitType: Enum "Workflow Approval Limit Type"; RecID: RecordID; ApprovalType: Enum "Workflow Approval Type"; DueDate: Date; AmountDec: Decimal)
    begin
        ApprovalEntry.Init();
        ApprovalEntry."Table ID" := TableId;
        ApprovalEntry."Document Type" := DocumentType;
        ApprovalEntry."Document No." := DocumentNo;
        ApprovalEntry."Sequence No." := LibraryRandom.RandIntInRange(10000, 100000);
        ApprovalEntry.Status := StatusOption;
        ApprovalEntry."Limit Type" := LimitType;
        ApprovalEntry."Record ID to Approve" := RecID;
        ApprovalEntry."Approval Type" := ApprovalType;
        ApprovalEntry."Due Date" := DueDate;
        ApprovalEntry.Amount := AmountDec;
        ApprovalEntry."Approver ID" := UserId();
        ApprovalEntry.Insert();
    end;

    procedure CreateMockupUserSetup(var UserSetup: Record "User Setup")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        User: Record User;
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        UserSetup."Salespers./Purch. Code" := SalespersonPurchaser.Code;
        UserSetup."User ID" :=
          CopyStr(LibraryUtility.GenerateRandomCode(User.FieldNo("User Name"), DATABASE::User),
            1, LibraryUtility.GetFieldLength(DATABASE::User, User.FieldNo("User Name")));
        UserSetup."Approver ID" := '';
        UserSetup."Unlimited Sales Approval" := true;
        UserSetup."Unlimited Purchase Approval" := true;
        UserSetup."Unlimited Request Approval" := true;
        UserSetup."Sales Amount Approval Limit" := 0;
        UserSetup."Purchase Amount Approval Limit" := 0;
        UserSetup."Request Amount Approval Limit" := 0;
        UserSetup."E-Mail" := 'someone@example.com';
        UserSetup.Insert();
    end;

    procedure CreateUser(UserName: Code[50]; WindowsUserName: Text[208])
    var
        User: Record User;
        UsersCreateSuperUser: Codeunit "Users - Create Super User";
    begin
        User.Init();
        User.Validate("User Security ID", CreateGuid());
        User.Validate("User Name", UserName);
        User.Validate("User Name", WindowsUserName);
        User.Validate("Windows Security ID", SID(WindowsUserName));
        UsersCreateSuperUser.AddUserAsSuper(User);
        User.Insert(true);
    end;

    procedure CreateUserWithEmail(UserName: Code[50]; WindowsUserName: Text[208]; Email: Text)
    var
        User: Record User;
        UsersCreateSuperUser: Codeunit "Users - Create Super User";
    begin
        User.Init();
        User.Validate("User Security ID", CreateGuid());
        User.Validate("User Name", UserName);
        if WindowsUserName <> '' then
            User.Validate("Windows Security ID", SID(WindowsUserName));
        User.Validate("Authentication Email", Email);
        UsersCreateSuperUser.AddUserAsSuper(User);
        User.Insert(true);
    end;

    procedure CreateNonWindowsUser(UserName: Code[50])
    var
        User: Record User;
        UsersCreateSuperUser: Codeunit "Users - Create Super User";
    begin
        User.Init();
        User.Validate("User Security ID", CreateGuid());
        User.Validate("User Name", UserName);
        UsersCreateSuperUser.AddUserAsSuper(User);
        User.Insert(true);
    end;

    procedure CreateUserSetup(var UserSetup: Record "User Setup"; UserID: Code[50]; ApproverID: Code[50])
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        UserSetup.Validate("Salespers./Purch. Code", SalespersonPurchaser.Code);
        UserSetup."User ID" := UserID;
        UserSetup."Approver ID" := ApproverID;
        UserSetup.Insert(true);
    end;

    procedure CreateUserSetupWithEmail(var UserSetup: Record "User Setup"; UserID: Code[50]; ApproverID: Code[50]; Email: Text)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        UserSetup.Validate("Salespers./Purch. Code", SalespersonPurchaser.Code);
        UserSetup."User ID" := UserID;
        UserSetup."Approver ID" := ApproverID;
        UserSetup."E-Mail" := Email;
        UserSetup.Insert(true);
    end;

    procedure DeleteUserSetup(var UserSetup: Record "User Setup"; WindowsUserName: Text[208])
    var
        User: Record User;
    begin
        GetUser(User, WindowsUserName);
        UserSetup.SetRange("User ID", User."User Name");
        UserSetup.DeleteAll();
    end;

    procedure GetUser(var User: Record User; WindowsUserName: Text[208]): Boolean
    begin
        User.SetRange("Windows Security ID", Sid(WindowsUserName));
        exit(User.FindFirst())
    end;

    procedure GetNonWindowsUser(var User: Record User; UserName: Text[208]): Boolean
    begin
        User.SetRange("User Name", UserName);
        exit(User.FindSet());
    end;

    procedure GetUserSetup(var UserSetup: Record "User Setup"; WindowsUserName: Text[208]): Boolean
    var
        User: Record User;
    begin
        if GetUser(User, WindowsUserName) then
            UserSetup.SetRange("User ID", User."User Name")
        else
            UserSetup.SetRange("User ID", WindowsUserName);
        exit(UserSetup.FindFirst())
    end;

    procedure UpdateApprovalLimits(var UserSetup: Record "User Setup"; UnlimitedSalesApproval: Boolean; UnlimitedPurchaseApproval: Boolean; UnlimitedRequestApproval: Boolean; SalesAmountApprovalLimit: Integer; PurchaseAmountApprovalLimit: Integer; RequestAmountApprovalLimit: Integer)
    begin
        UserSetup.Validate("Unlimited Sales Approval", UnlimitedSalesApproval);
        UserSetup.Validate("Unlimited Purchase Approval", UnlimitedPurchaseApproval);
        UserSetup.Validate("Unlimited Request Approval", UnlimitedRequestApproval);

        UserSetup.Validate("Sales Amount Approval Limit", SalesAmountApprovalLimit);
        UserSetup.Validate("Purchase Amount Approval Limit", PurchaseAmountApprovalLimit);
        UserSetup.Validate("Request Amount Approval Limit", RequestAmountApprovalLimit);

        UserSetup.Modify(true);
    end;

    procedure UserExists(WindowsUserName: Text[208]): Boolean
    var
        User: Record User;
    begin
        User.SetRange("Windows Security ID", Sid(WindowsUserName));
        exit(not User.IsEmpty);
    end;

    procedure UserSetupExists(WindowsUserName: Text[208]): Boolean
    var
        User: Record User;
        UserSetup: Record "User Setup";
    begin
        GetUser(User, WindowsUserName);
        UserSetup.SetRange("User ID", User."User Name");
        exit(not UserSetup.IsEmpty);
    end;

    procedure SetupUserWithApprover(var CurrentUserSetup: Record "User Setup")
    var
        ApproverUserSetup: Record "User Setup";
    begin
        CreateMockupUserSetup(ApproverUserSetup);
        CreateOrFindUserSetup(CurrentUserSetup, UserId);
        SetApprover(CurrentUserSetup, ApproverUserSetup);
    end;

    procedure SetupUsersForApprovals(var IntermediateApproverUserSetup: Record "User Setup")
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        CreateOrFindUserSetup(CurrentUserSetup, UserId);
        CreateMockupUserSetup(IntermediateApproverUserSetup);
        CreateMockupUserSetup(FinalApproverUserSetup);

        SetApprover(CurrentUserSetup, IntermediateApproverUserSetup);
        SetApprover(IntermediateApproverUserSetup, FinalApproverUserSetup);
        SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);
    end;

    procedure SetupUsersForApprovalsWithLimits(var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup")
    begin
        SetupUsersForApprovals(IntermediateApproverUserSetup);

        CurrentUserSetup.Get(UserId);
        SetSalesAmountApprovalLimits(CurrentUserSetup, LibraryRandom.RandIntInRange(1, 100));
        SetLimitedSalesApprovalLimits(CurrentUserSetup);
        SetPurchaseAmountApprovalLimits(CurrentUserSetup, LibraryRandom.RandIntInRange(1, 100));
        SetLimitedPurchaseApprovalLimits(CurrentUserSetup);

        SetSalesAmountApprovalLimits(IntermediateApproverUserSetup, LibraryRandom.RandIntInRange(101, 1000));
        SetLimitedSalesApprovalLimits(IntermediateApproverUserSetup);
        SetPurchaseAmountApprovalLimits(IntermediateApproverUserSetup, LibraryRandom.RandIntInRange(101, 1000));
        SetLimitedPurchaseApprovalLimits(IntermediateApproverUserSetup);

        FinalApproverUserSetup.Get(IntermediateApproverUserSetup."Approver ID");
        SetUnlimitedSalesApprovalLimits(FinalApproverUserSetup);
        SetUnlimitedPurchaseApprovalLimits(FinalApproverUserSetup);
    end;

    procedure CreateOrFindUserSetup(var UserSetup: Record "User Setup"; UserName: Text[208])
    begin
        if not GetUserSetup(UserSetup, CopyStr(UserName, 1, 50)) then
            CreateUserSetup(UserSetup, CopyStr(UserName, 1, 50), '');
    end;

    procedure CreateUserSetupsAndGroupOfApproversForWorkflow(Workflow: Record Workflow; var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup")
    var
        WorkflowUserGroup: Record "Workflow User Group";
    begin
        CreateOrFindUserSetup(CurrentUserSetup, UserId);
        CreateMockupUserSetup(IntermediateApproverUserSetup);
        CreateMockupUserSetup(FinalApproverUserSetup);
        CreateWorkflowUserGroup(WorkflowUserGroup);

        CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, CurrentUserSetup."User ID", 1);
        CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, IntermediateApproverUserSetup."User ID", 2);
        CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, FinalApproverUserSetup."User ID", 3);

        LibraryWorkflow.SetWorkflowGroupApprover(Workflow.Code, WorkflowUserGroup.Code);
    end;

    procedure CreateWorkflowUserGroupMember(WorkflowUserGroupCode: Code[20]; UserID: Code[50]; SeqNo: Integer)
    var
        WorkflowUserGroupMember: Record "Workflow User Group Member";
    begin
        WorkflowUserGroupMember."Workflow User Group Code" := WorkflowUserGroupCode;
        WorkflowUserGroupMember."User Name" := UserID;
        WorkflowUserGroupMember."Sequence No." := SeqNo;
        WorkflowUserGroupMember.Insert(true);
    end;

    procedure CreateWorkflowUserGroup(var WorkflowUserGroup: Record "Workflow User Group")
    begin
        WorkflowUserGroup.Code := LibraryUtility.GenerateRandomCode(WorkflowUserGroup.FieldNo(Code), DATABASE::"Workflow User Group");
        WorkflowUserGroup.Description := CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50);
        WorkflowUserGroup.Insert(true);
    end;

    procedure SetWorkflowApproverType(Workflow: Record Workflow; ApproverType: Enum "Workflow Approver Type")
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreateApprovalRequestsCode());
        WorkflowStep.FindFirst();

        WorkflowStepArgument.Get(WorkflowStep.Argument);
        WorkflowStepArgument."Approver Type" := ApproverType;
        WorkflowStepArgument.Modify(true);
    end;

    procedure SetApprover(var UserSetup: Record "User Setup"; ApproverUserSetup: Record "User Setup")
    begin
        UserSetup."Approver ID" := ApproverUserSetup."User ID";
        UserSetup.Modify(true);
    end;

    procedure SetSubstitute(var UserSetup: Record "User Setup"; var SubstituteUserSetup: Record "User Setup")
    begin
        UserSetup.Substitute := SubstituteUserSetup."User ID";
        UserSetup.Modify(true);
    end;

    procedure SetAdministrator(var UserSetup: Record "User Setup")
    begin
        UserSetup."Approval Administrator" := true;
        UserSetup.Modify(true);
    end;

    local procedure SetSalesAmountApprovalLimits(var UserSetup: Record "User Setup"; SalesApprovalLimit: Integer)
    begin
        UserSetup."Sales Amount Approval Limit" := SalesApprovalLimit;
        UserSetup.Modify(true);
    end;

    local procedure SetUnlimitedSalesApprovalLimits(var UserSetup: Record "User Setup")
    begin
        UserSetup."Unlimited Sales Approval" := true;
        UserSetup.Modify(true);
    end;

    local procedure SetLimitedSalesApprovalLimits(var UserSetup: Record "User Setup")
    begin
        UserSetup."Unlimited Sales Approval" := false;
        UserSetup.Modify(true);
    end;

    local procedure SetPurchaseAmountApprovalLimits(var UserSetup: Record "User Setup"; PurchaseApprovalLimit: Integer)
    begin
        UserSetup."Purchase Amount Approval Limit" := PurchaseApprovalLimit;
        UserSetup.Modify(true);
    end;

    local procedure SetUnlimitedPurchaseApprovalLimits(var UserSetup: Record "User Setup")
    begin
        UserSetup."Unlimited Purchase Approval" := true;
        UserSetup.Modify(true);
    end;

    local procedure SetLimitedPurchaseApprovalLimits(var UserSetup: Record "User Setup")
    begin
        UserSetup."Unlimited Purchase Approval" := false;
        UserSetup.Modify(true);
    end;

    procedure GetApprovalEntries(var ApprovalEntry: Record "Approval Entry"; RecordID: RecordID)
    begin
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.FindSet();
    end;

    procedure GetPostedApprovalEntries(var PostedApprovalEntry: Record "Posted Approval Entry"; RecordID: RecordID)
    begin
        PostedApprovalEntry.SetRange("Posted Record ID", RecordID);
        PostedApprovalEntry.FindSet();
    end;

    procedure GetPostedApprovalComments(var PostedApprovalCommentLine: Record "Posted Approval Comment Line"; RecordID: RecordID)
    begin
        PostedApprovalCommentLine.SetRange("Posted Record ID", RecordID);
        PostedApprovalCommentLine.FindSet();
    end;

    procedure UpdateApprovalEntryWithCurrUser(RecordID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
    begin
        GetApprovalEntries(ApprovalEntry, RecordID);
        UserSetup.Get(UserId);
        ApprovalEntry.ModifyAll("Sender ID", UserSetup."Approver ID", true);
        ApprovalEntry.ModifyAll("Approver ID", UserSetup."User ID", true);
    end;
}
