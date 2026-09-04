// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using System.Security.AccessControl;
using System.Security.User;
using System.Utilities;

table 6923 "Expense User"
{
    Access = Internal;
    Caption = 'Expense User';
    DataClassification = CustomerContent;
    DataCaptionFields = "No.", "Employee No.", Name;
    LookupPageId = "Expense Users";
    DrillDownPageId = "Expense User";
    ReplicateData = false;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee."No.";

            trigger OnValidate()
            var
                Employee: Record Employee;
            begin
                if Rec."Employee No." <> '' then begin
                    Employee.Get("Employee No.");

                    if Employee."Employee Posting Group" = '' then
                        Error(
                            EmployeePostingGroupMissingErr,
                            Employee.TableCaption(), Employee."No.", Rec.TableCaption(), Employee.FieldCaption("Employee Posting Group"));

                    CheckDuplicateEmployeeNo();

                    if ConfirmOverwriteExpenseUserInformation(Employee) then begin
                        Rec.Validate("Name", Employee.FullName());
                        if Employee."Company E-Mail" = '' then
                            Rec.Validate("E-mail", Employee."E-Mail")
                        else
                            Rec.Validate("E-mail", Employee."Company E-Mail");
                    end;
                    Rec.Validate("Job Title", Employee."Job Title");
                end else begin
                    Rec.Validate("Name", '');
                    Rec.Validate("E-mail", '');
                    Rec.Validate("Job Title", '');
                end;
            end;
        }
        field(3; "Name"; Text[100])
        {
            Caption = 'Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "E-mail"; Text[80])
        {
            Caption = 'E-mail';
            ExtendedDatatype = EMail;
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                if Rec."E-mail" <> '' then
                    CheckDuplicateEmail();

                if Rec."E-mail" <> xRec."E-mail" then begin
                    Rec."User Id For Approvals" := '';

                    if Rec."Can Approve" then
                        UpdateApprovalUserId();
                end;
            end;
        }
        field(5; "Job Title"; Text[30])
        {
            Caption = 'Job Title';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Expense Team Code"; Code[20])
        {
            Caption = 'Expense Team Code';
            TableRelation = "Expense Team"."Code";
        }
        field(10; "Team Manager"; Boolean)
        {
            Caption = 'Team Manager';

            trigger OnValidate()
            begin
                if Rec."Team Manager" then
                    CheckExpenseUserIsAlreadyTeamManager();
            end;
        }
        field(15; "Entra Id"; Guid)
        {
            Caption = 'Entra Id';
            ToolTip = 'Specifies the Entra Id of the agent.';
            DataClassification = SystemMetadata;
        }
        field(20; "Can Approve"; Boolean)
        {
            Caption = 'Can Approve';
            ToolTip = 'Specifies whether the employee can approve expense.';

            trigger OnValidate()
            begin
                if not "Can Approve" then begin
                    if not ConfirmApproverReassignment() then
                        Error('');
                end else
                    UpdateApprovalUserId();
            end;
        }
        field(30; "Is a System User"; Boolean)
        {
            Caption = 'Is a user in Business Central';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = exist(User where("Authentication Email" = field("E-mail")));
        }
        field(40; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            ToolTip = 'Specifies the resource linked to the employee.';
            FieldClass = FlowField;
            CalcFormula = lookup(Employee."Resource No." where("No." = field("Employee No.")));
        }
        field(21; "User Id For Approvals"; Code[50])
        {
            Caption = 'User Id For Approvals';
            ToolTip = 'Specifies the user ID used for approvals.';
            TableRelation = "User Setup"."User ID";
        }
        field(22; "Employee Status"; Enum "Employee Status")
        {
            Caption = 'Employee Status';
            ToolTip = 'Specifies the employment status of the related employee.';
            FieldClass = FlowField;
            CalcFormula = lookup(Employee.Status where("No." = field("Employee No.")));
            Editable = false;
        }
        field(25; "Employee Posting Group"; Code[20])
        {
            Caption = 'Employee Posting Group';
            ToolTip = 'Specifies the employee posting group of the related employee. Expenses cannot be posted without it.';
            FieldClass = FlowField;
            CalcFormula = lookup(Employee."Employee Posting Group" where("No." = field("Employee No.")));
            Editable = false;
        }
        field(23; "Approver No."; Code[20])
        {
            Caption = 'Approver No.';
            ToolTip = 'Specifies the number of the expense user who can approve for this user.';
            FieldClass = FlowField;
            CalcFormula = lookup("Expense Approval Setup"."Approver No." where("Expense User No." = field("No.")));
            Editable = false;
        }
        field(24; "Approver Name"; Text[100])
        {
            Caption = 'Approver';
            ToolTip = 'Specifies the name of the expense user who can approve for this user.';
            FieldClass = FlowField;
            CalcFormula = lookup("Expense User".Name where("No." = field("Approver No.")));
            Editable = false;
        }
        field(53; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
#if not CLEANSCHEMA29
        field(54; "Welcome Email Sent"; Boolean)
        {
            Caption = 'Welcome Email Sent';
            Editable = false;
#if CLEAN29
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Replaced by Welcome Email Status, which also tracks queued and failed sends.';
#pragma warning disable AS0072 // Bug 647877: temporary v30 suppression, restore ObsoleteTag to 30.0
            ObsoleteTag = '29.0';
#pragma warning restore AS0072
        }
#endif
        field(55; "Welcome Email Sent At"; DateTime)
        {
            Caption = 'Welcome Email Sent At';
            Editable = false;
        }
        field(56; "Welcome Email Status"; Option)
        {
            Caption = 'Welcome Email Status';
            Editable = false;
            OptionMembers = None,Queued,"In Outbox",Sent,Failed;
            OptionCaption = 'None,Queued,In Outbox,Sent,Failed', Comment = 'None = not sent, Queued = waiting for the agent to send, In Outbox = handed to the service and waiting to be delivered, Sent = successfully sent, Failed = send failed';
        }
        field(57; "Welcome Correlation Id"; Guid)
        {
            Caption = 'Welcome Correlation Id';
            Editable = false;
            ToolTip = 'Specifies the identifier used to correlate the welcome email with its delivery from the outbox.';
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(WelcomeCorrelationKey; "Welcome Correlation Id")
        {
        }
    }

    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        SkipOverwriteFromEmployee: Boolean;
        ApproverReassignToDefaultQst: Label 'Expense user %1 was an approver for some users. These users will now be assigned the default approver. Continue?', Comment = '%1 = Expense User No.';
        ApproverRemoveQst: Label 'Expense user %1 was an approver for some users. These users will now have no approver. Continue?', Comment = '%1 = Expense User No.';
        CannotRemoveDefaultApproverErr: Label 'You cannot remove approval rights from expense user %1 because this user is the default approver. Change the default approver in %2 first.', Comment = '%1 = Expense User No., %2 = Expense Agent Setup table caption';
        ConfirmOverwriteExpenseUserInformationQst: Label 'Do you want to overwrite the employee Name and E-Mail on Expense User from Employee information of %1?', Comment = '%1 - Employee No.';
        ExistingExpenseTeamManagerErr: Label 'There is already a Team Manager (%1) for Expense Team %2.', Comment = '%1 - Expense User No. %2 -Expense Team Code';
        ExpenseApprovalSetupErr: Label 'You cannot remove approval rights from expense user %1. This expense user is currently configured as an approver in the %2.', Comment = '%1 - Expense User No., %2 - Table Caption';
        DuplicateEmailErr: Label '%1 %2 is already used by another %3. %1 must be unique.', Comment = '%1 = Email Caption, %2 = Email address, %3 = Expense User Table Caption';
        DuplicateEmployeeNoErr: Label '%1 %2 is already linked to another %3. Each employee can only be linked to one %3.', Comment = '%1 = Employee No. Caption, %2 = Employee No., %3 = Expense User Table Caption';
        EmployeePostingGroupMissingErr: Label '%1 %2 cannot be linked to an %3 because %4 is not specified on the %1.', Comment = '%1 = Employee Table Caption, %2 = Employee No., %3 = Expense User Table Caption, %4 = Employee Posting Group Field Caption';
        OnlyBCUserCanApproveErr: Label 'In order to be an expense approver there must be a user in Business Central for email %1 for expense user %2.', Comment = '%1 - Email, %2 - Expense User No.';
        CannotDeleteExpenseUserWithExpenseErr: Label 'You cannot delete Expense User %1 because they have active expense.', Comment = '%1 = Expense User No.';
        CannotDeleteExpenseUserWithExpenseReportErr: Label 'You cannot delete Expense User %1 because they have active expense report.', Comment = '%1 = Expense User No.';
        CannotDeleteExpenseUserWithPostedExpenseReportErr: Label 'You cannot delete Expense User %1 because they have posted expense report.', Comment = '%1 = Expense User No.';
        ResendWelcomeEmailQst: Label 'Some of the selected expense users have already received a welcome email or have one that is still being sent. Do you want to send it to them again as well? Choose No to send only to those who have not received one yet.';
        WelcomeEmailsQueuedMsg: Label '%1 welcome email(s) have been queued. The expense agent will send them shortly.', Comment = '%1 = number of welcome emails queued';
        NoWelcomeEmailsQueuedMsg: Label 'No welcome emails were sent. The selected expense users have already received one or have one that is still being sent.';
        NoExpenseUsersWithEmailErr: Label 'There are no expense users to send welcome email.';
        AgentNotEnabledErr: Label 'Please make sure the Expense Agent is active.';
        CommunicationDisabledErr: Label 'Sending emails to users is turned off. Turn on communication for the Expense Agent before sending welcome emails.';
        NoNoreplyAccountErr: Label 'No account is set for sending emails. Set the send mail account for the Expense Agent before sending welcome emails.';
        CurrentBCUserHasNoAuthEmailErr: Label 'Your Business Central user account is not linked to an authentication email, so it cannot be matched to an Expense User. Ask your administrator to set the Authentication Email on your user record in Business Central.';
        CurrentBCUserNotMatchedToExpenseUserErr: Label 'No Expense User exists for the email %1 used by your Business Central account. Ask your administrator to create an Expense User with this email, or to update the email on the existing Expense User to match.', Comment = '%1 = authentication email of the current Business Central user';

    trigger OnDelete()
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        CheckExpenseUserCanBeDeleted();
        CheckExpenseUserIsDefaultApprover();
        CheckExpenseUserIsApprover();
        if ExpenseApprovalSetup.Get(Rec."No.") then
            ExpenseApprovalSetup.Delete();
    end;

    trigger OnInsert()
    var
        ExpenseUser: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        NoSeries: Codeunit "No. Series";
    begin
        ExpenseAgentSetup.GetRecordOnce();

        if Rec."No." = '' then begin
            ExpenseAgentSetup.TestField("Expense User Nos.");
            if NoSeries.AreRelated(ExpenseAgentSetup."Expense User Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := ExpenseAgentSetup."Expense User Nos.";
            Rec."No." := NoSeries.GetNextNo("No. Series");
            ExpenseUser.ReadIsolation(IsolationLevel::ReadUncommitted);
            ExpenseUser.SetLoadFields("No.");
            while ExpenseUser.Get("No.") do
                Rec."No." := NoSeries.GetNextNo("No. Series");
        end;
        if ExpenseAgentSetup."Default Approver No." <> '' then begin
            ExpenseApprovalSetup.Init();
            ExpenseApprovalSetup."Expense User No." := Rec."No.";
            ExpenseApprovalSetup.Validate("Approver No.", ExpenseAgentSetup."Default Approver No.");
            if ExpenseApprovalSetup.Insert() then; // safeguard agains race conditions
        end;
    end;

    local procedure CheckExpenseUserCanBeDeleted()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
    begin
        Expense.SetRange("Expense User No.", Rec."No.");
        if not Expense.IsEmpty() then
            Error(CannotDeleteExpenseUserWithExpenseErr, Rec."No.");

        ExpenseReportHeader.SetRange("Expense User No.", Rec."No.");
        if not ExpenseReportHeader.IsEmpty() then
            Error(CannotDeleteExpenseUserWithExpenseReportErr, Rec."No.");

        PostedExpenseReportHeader.SetRange("Expense User No.", Rec."No.");
        if not PostedExpenseReportHeader.IsEmpty() then
            Error(CannotDeleteExpenseUserWithPostedExpenseReportErr, Rec."No.");
    end;

    local procedure ConfirmOverwriteExpenseUserInformation(Employee: Record Employee): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if SkipOverwriteFromEmployee then
            exit(false);

        if not GuiAllowed() then
            exit(true);

        if (Rec.Name <> '') or (Rec."E-mail" <> '') then
            if (Rec.Name <> Employee.FullName()) or (Rec."E-mail" <> Employee."Company E-Mail") then
                exit(ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConfirmOverwriteExpenseUserInformationQst, Rec."Employee No."), true));

        exit(true);
    end;

    /// <summary>
    /// Suppresses the overwrite confirmation when validating Employee No. and keeps
    /// existing Name and E-mail values on the Expense User instead of copying from the Employee.
    /// Resets each time the record is read or initialized.
    /// </summary>
    internal procedure SetSkipOverwriteFromEmployee(NewSkipOverwriteFromEmployee: Boolean)
    begin
        SkipOverwriteFromEmployee := NewSkipOverwriteFromEmployee;
    end;

    local procedure CheckExpenseUserIsAlreadyTeamManager()
    var
        ExpenseUser: Record "Expense User";
    begin
        Rec.TestField("Expense Team Code");

        ExpenseUser.SetFilter("No.", '<>%1', Rec."No.");
        ExpenseUser.SetRange("Expense Team Code", Rec."Expense Team Code");
        ExpenseUser.SetRange("Team Manager", true);
        if ExpenseUser.FindFirst() then
            Error(ExistingExpenseTeamManagerErr, ExpenseUser."Employee No.", Rec."Expense Team Code");
    end;

    local procedure CheckExpenseUserIsDefaultApprover()
    begin
        ExpenseAgentSetup.Get();
        if ExpenseAgentSetup."Default Approver No." = Rec."No." then
            Error(CannotRemoveDefaultApproverErr, Rec."No.", ExpenseAgentSetup.TableCaption());
    end;

    local procedure CheckExpenseUserIsApprover()
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        ExpenseApprovalSetup.SetRange("Approver No.", Rec."No.");
        if not ExpenseApprovalSetup.IsEmpty() then
            Error(ExpenseApprovalSetupErr, Rec."No.", ExpenseApprovalSetup.TableCaption());
    end;

    /// <summary>
    /// Reassigns or removes approver references before the user's approval role is removed
    /// (via delete or by clearing "Can Approve"). Errors if the user is the default approver,
    /// otherwise confirms with the user and reassigns to the default approver, or removes the
    /// approver when no default is configured. Must be called outside the write transaction
    /// (e.g. from the page's OnDeleteRecord trigger).
    /// </summary>
    /// <returns>True if the user confirmed and reassignment succeeded, or if there is nothing to reassign. False if the user declined.</returns>
    internal procedure ConfirmApproverReassignment(): Boolean
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        CheckExpenseUserIsDefaultApprover();

        ExpenseApprovalSetup.SetRange("Approver No.", Rec."No.");
        if ExpenseApprovalSetup.IsEmpty() then
            exit(true);

        ExpenseAgentSetup.Get();
        if ExpenseAgentSetup."Default Approver No." <> '' then begin
            if not Confirm(ApproverReassignToDefaultQst, false, Rec."No.") then
                exit(false);
            AssignDefaultApprover();
        end else begin
            if not Confirm(ApproverRemoveQst, false, Rec."No.") then
                exit(false);
            RemoveApprover();
        end;
        exit(true);
    end;

    local procedure AssignDefaultApprover()
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseApprovalSetup.SetRange("Approver No.", Rec."No.");
        ExpenseApprovalSetup.ModifyAll("Approver No.", ExpenseAgentSetup."Default Approver No.");
    end;

    local procedure RemoveApprover()
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        ExpenseApprovalSetup.SetRange("Approver No.", Rec."No.");
        ExpenseApprovalSetup.ModifyAll("Approver No.", '');
    end;

    local procedure CheckDuplicateEmail()
    var
        ExpenseUser: Record "Expense User";
    begin
        if Rec."No." <> '' then
            ExpenseUser.SetFilter("No.", '<>%1', Rec."No.");

        ExpenseUser.SetRange("E-mail", Rec."E-mail");
        if not ExpenseUser.IsEmpty() then
            Error(DuplicateEmailErr, Rec.FieldCaption("E-mail"), Rec."E-mail", Rec.TableCaption());
    end;

    local procedure CheckDuplicateEmployeeNo()
    var
        ExpenseUser: Record "Expense User";
    begin
        if Rec."No." <> '' then
            ExpenseUser.SetFilter("No.", '<>%1', Rec."No.");

        ExpenseUser.SetRange("Employee No.", Rec."Employee No.");
        if not ExpenseUser.IsEmpty() then
            Error(DuplicateEmployeeNoErr, Rec.FieldCaption("Employee No."), Rec."Employee No.", Rec.TableCaption());
    end;

    internal procedure GetExpenseUserNoBySystemId(ExpenseUserSystemId: Guid): Code[20]
    var
        ExpenseUser: Record "Expense User";
    begin
        if IsNullGuid(ExpenseUserSystemId) then
            exit('');

        ExpenseUser.SetLoadFields("No.");
        if ExpenseUser.GetBySystemId(ExpenseUserSystemId) then
            exit(ExpenseUser."No.");

        exit('');
    end;

    internal procedure GetSystemIdByExpenseUserNo(ExpenseUserNo: Code[20]): Guid
    var
        ExpenseUser: Record "Expense User";
    begin
        if ExpenseUserNo = '' then
            exit;

        ExpenseUser.SetLoadFields(SystemId);
        if ExpenseUser.Get(ExpenseUserNo) then
            exit(ExpenseUser.SystemId);

        exit;
    end;

    internal procedure GetExpenseUserNoByCurrentUser(): Code[20]
    var
        ExpenseUser: Record "Expense User";
        User: Record User;
        UserSecurityID: Guid;
    begin
        FindUserSecurityID(UserSecurityID);
        User.Get(UserSecurityID);
        if User."Authentication Email" = '' then
            Error(CurrentBCUserHasNoAuthEmailErr);

        ExpenseUser.SetLoadFields("No.");
        ExpenseUser.SetRange("E-mail", User."Authentication Email");
        if not ExpenseUser.FindFirst() then
            Error(CurrentBCUserNotMatchedToExpenseUserErr, User."Authentication Email");

        exit(ExpenseUser."No.");
    end;

    local procedure FindUserSecurityID(var UserSecurityID: Guid)
    var
        User: Record User;
    begin
        if User.Get(UserSecurityId()) then begin
            UserSecurityID := User."User Security ID";
            exit;
        end;

        User.SetRange("User Name", UserId());
        if User.FindFirst() then begin
            UserSecurityID := User."User Security ID";
            exit;
        end;
    end;

    internal procedure AssistEdit() Result: Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup.TestField("Expense User Nos.");
        if NoSeries.LookupRelatedNoSeries(ExpenseAgentSetup."Expense User Nos.", xRec."No. Series", "No. Series") then begin
            Rec."No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    internal procedure UpdateApprovalUserId()
    var
        ApprovalUserId: Code[50];
    begin
        Rec.TestField("E-mail");

        if Rec."User Id For Approvals" <> '' then
            exit;

        ApprovalUserId := GetUserIdByEmail(Rec."E-mail");
        Rec."User Id For Approvals" := ApprovalUserId;

        if (ApprovalUserId = '') and (Rec."Can Approve") then
            Error(OnlyBCUserCanApproveErr, Rec."E-mail", Rec."No.");
    end;

    local procedure GetUserIdByEmail(Email: Text[100]): Code[50]
    var
        User: Record User;
    begin
        if Email = '' then
            exit('');

        User.SetRange("Authentication Email", Email);
        if User.FindFirst() then
            exit(User."User Name");

        User.SetRange("Authentication Email");
        User.SetRange("Contact Email", Email);
        if User.FindFirst() then
            exit(User."User Name");
    end;

    internal procedure CreateEmployeeFromExpenseUser()
    var
        ImportExpenseUser: Codeunit "Import Expense User";
        EmployeeNo: Code[20];
    begin
        ExpenseAgentSetup.GetRecordOnce();

        ExpenseAgentSetup.TestField("Create Emp. for Expense Users");
        Rec.TestField("Employee No.", '');
        Rec.TestField("Name");
        Rec.TestField("E-mail");

        EmployeeNo := ImportExpenseUser.GetEmployeeNoFromEmail(Rec."E-mail");
        if EmployeeNo = '' then begin
            SetSkipOverwriteFromEmployee(true);
            Rec.Validate("Employee No.", CreateEmployeeFromTemplate());
            SetSkipOverwriteFromEmployee(false);
        end else
            Rec.Validate("Employee No.", EmployeeNo);

        Rec.Modify();
    end;

    local procedure CreateEmployeeFromTemplate(): Code[20]
    var
        EmployeeTempl: Record "Employee Templ.";
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
        TemplateSelected: Boolean;
    begin
        if EmployeeTemplMgt.IsEnabled() then begin
            TemplateSelected := EmployeeTemplMgt.SelectEmployeeTemplateFromContact(EmployeeTempl);
            if not TemplateSelected then
                if EmployeeTemplMgt.TemplatesAreNotEmpty() then
                    Error('');
        end;

        exit(CreateEmployee(EmployeeTempl, TemplateSelected));
    end;

    internal procedure CreateEmployee(EmployeeTempl: Record "Employee Templ."; TemplateSelected: Boolean): Code[20]
    var
        Employee: Record Employee;
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
    begin
        Employee.Init();
        EmployeeTemplMgt.InitEmployeeNo(Employee, EmployeeTempl);
        NameBreakdown(Employee);
        Employee.Validate("Company E-Mail", Rec."E-mail");
        Employee.Validate("Job Title", Rec."Job Title");
        Employee.Validate("Search Name");
        Employee.Insert(true);
        if TemplateSelected then
            EmployeeTemplMgt.ApplyEmployeeTemplate(Employee, EmployeeTempl);

        exit(Employee."No.");
    end;

    local procedure NameBreakdown(var Employee: Record Employee)
    var
        NamePart: array[30] of Text[100];
        TempName: Text[250];
        FirstName250: Text[250];
        i: Integer;
        NoOfParts: Integer;
    begin
        TempName := Rec.Name;
        while StrPos(TempName, ' ') > 0 do begin
            if StrPos(TempName, ' ') > 1 then begin
                i := i + 1;
                NamePart[i] := CopyStr(CopyStr(TempName, 1, StrPos(TempName, ' ') - 1), 1, MaxStrLen(NamePart[i]));
            end;
            TempName := CopyStr(TempName, StrPos(TempName, ' ') + 1, MaxStrLen(TempName));
        end;

        i := i + 1;
        NamePart[i] := CopyStr(TempName, 1, MaxStrLen(NamePart[i]));
        NoOfParts := i;

        Employee."First Name" := '';
        Employee."Middle Name" := '';
        Employee."Last Name" := '';
        for i := 1 to NoOfParts do
            if (i = NoOfParts) and (NoOfParts > 1) then
                Employee.Validate("Last Name", CopyStr(NamePart[i], 1, MaxStrLen(Employee."Last Name")))
            else
                if (i = NoOfParts - 1) and (NoOfParts > 2) then
                    Employee.Validate("Middle Name", CopyStr(NamePart[i], 1, MaxStrLen(Employee."Middle Name")))
                else begin
                    FirstName250 := CopyStr(DelChr(Employee."First Name" + ' ' + NamePart[i], '<', ' '), 1, MaxStrLen(FirstName250));
                    Employee.Validate("First Name", CopyStr(FirstName250, 1, MaxStrLen(Employee."First Name")));
                end;
    end;

    internal procedure SendWelcomeEmail(var ExpenseUser: Record "Expense User")
    var
        AlreadySentExpenseUser: Record "Expense User";
        IncludeAlreadySent: Boolean;
        QueuedCount: Integer;
    begin
        ExpenseAgentSetup.GetRecordOnce();
        if not ExpenseAgentSetup."Enable Agent" then
            Error(AgentNotEnabledErr);
        if not ExpenseAgentSetup."Enable Communication" then
            Error(CommunicationDisabledErr);
        if IsNullGuid(ExpenseAgentSetup."Noreply Email Account ID") then
            Error(NoNoreplyAccountErr);

        ExpenseUser.SetFilter("E-mail", '<>%1', '');
        if ExpenseUser.IsEmpty() then
            Error(NoExpenseUsersWithEmailErr);

        AlreadySentExpenseUser.CopyFilters(ExpenseUser);
        AlreadySentExpenseUser.SetFilter("Welcome Email Status", '%1|%2', AlreadySentExpenseUser."Welcome Email Status"::"In Outbox", AlreadySentExpenseUser."Welcome Email Status"::Sent);
        if not AlreadySentExpenseUser.IsEmpty() then
            IncludeAlreadySent := not GuiAllowed() or Confirm(ResendWelcomeEmailQst, false);

        if not IncludeAlreadySent then
            ExpenseUser.SetFilter("Welcome Email Status", '<>%1&<>%2', ExpenseUser."Welcome Email Status"::"In Outbox", ExpenseUser."Welcome Email Status"::Sent);

        QueuedCount := ExpenseUser.Count();
        if QueuedCount > 0 then
            ExpenseUser.ModifyAll("Welcome Email Status", ExpenseUser."Welcome Email Status"::Queued);

        if GuiAllowed() then
            if QueuedCount = 0 then
                Message(NoWelcomeEmailsQueuedMsg)
            else
                Message(WelcomeEmailsQueuedMsg, QueuedCount);
    end;

    /// <summary>
    /// Records the outcome of a welcome-email hop-1 handoff (BC -> Expense Agent service)
    /// on the current expense user. On success the email is not yet delivered, so the
    /// status becomes In Outbox and the correlation id is stored so the dispatcher can
    /// map the eventual outbox delivery back to this user. The dispatcher calls this
    /// outside the send TryFunction, since a MODIFY inside a TryFunction is not allowed
    /// while running under the scheduled task.
    /// </summary>
    internal procedure SetWelcomeEmailHandoffResult(Success: Boolean; CorrelationId: Guid)
    var
        NullGuid: Guid;
    begin
        if Success then begin
            Rec."Welcome Email Status" := Rec."Welcome Email Status"::"In Outbox";
            Rec."Welcome Correlation Id" := CorrelationId;
        end else begin
            Rec."Welcome Email Status" := Rec."Welcome Email Status"::Failed;
            Rec."Welcome Correlation Id" := NullGuid;
        end;
        Rec.Modify();
    end;

    /// <summary>
    /// Records the final welcome-email delivery result on the current expense user,
    /// based on the outbox row's delivery status (hop-2). Sets the sent timestamp when
    /// delivered.
    /// </summary>
    internal procedure SetWelcomeEmailDelivered(Delivered: Boolean)
    begin
        if Delivered then begin
            Rec."Welcome Email Status" := Rec."Welcome Email Status"::Sent;
            Rec."Welcome Email Sent At" := CurrentDateTime();
        end else
            Rec."Welcome Email Status" := Rec."Welcome Email Status"::Failed;
        Rec.Modify();
    end;

    /// <summary>
    /// Applies an outbox delivery result (hop-2) to any expense user that is waiting
    /// In Outbox for the given correlation id. Called by the dispatcher when an outbox
    /// welcome email reaches a terminal delivery state.
    /// </summary>
    internal procedure ApplyWelcomeDeliveryResult(CorrelationId: Guid; Delivered: Boolean)
    var
        ExpenseUser: Record "Expense User";
    begin
        if IsNullGuid(CorrelationId) then
            exit;

        ExpenseUser.SetRange("Welcome Correlation Id", CorrelationId);
        ExpenseUser.SetRange("Welcome Email Status", ExpenseUser."Welcome Email Status"::"In Outbox");
        if ExpenseUser.FindSet(true) then
            repeat
                ExpenseUser.SetWelcomeEmailDelivered(Delivered);
            until ExpenseUser.Next() = 0;
    end;
}
