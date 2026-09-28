// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Finance.SpendRequest;
using Microsoft.Foundation.AuditCodes;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Utilities;
using System.Agents;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Utilities;

codeunit 6908 "Expense Event Subscriber"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata User = r;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", OnAfterInitialization, '', false, false)]
    local procedure ValidateExpenseAgentLoginNotAllowed()
    var
        AgentSession: Codeunit "Agent Session";
        AgentMetadataProvider: Enum "Agent Metadata Provider";
        ExpenseUserLoginNotAllowedErr: Label 'Expense agent user is not allowed to login.';
    begin
        // Agent login must fail for Expense Agent user
        if AgentSession.IsAgentSession(AgentMetadataProvider) then
            if AgentMetadataProvider = Enum::"Agent Metadata Provider"::"Expense Agent" then
                Error(ExpenseUserLoginNotAllowedErr);
    end;

    var
        CannotDeleteEmployeeWithPostedExpenseReportErr: Label 'You cannot delete Employee %1 because they have posted expense report.', Comment = '%1 = Employee No.';
        CannotDeleteEmployeeWithExpenseReportErr: Label 'You cannot delete Employee %1 because they have active expense report.', Comment = '%1 = Employee No.';
        CannotDeleteEmployeeWithExpenseErr: Label 'You cannot delete Employee %1 because they have active expense.', Comment = '%1 = Employee No.';
        EmailChangeWarningQst: Label 'Employee %1 has existing expenses. Changing the email address may make these expenses inaccessible to them in the expense app. Do you want to continue?', Comment = '%1 = Employee No.';
        PolicyNotAcknowledgedErr: Label 'You must acknowledge the travel policy before releasing the %1.', Comment = '%1 = document type description';
        NoTravelersErr: Label 'You must add at least one traveler before releasing the %1.', Comment = '%1 = document type description';
        DestinationRequiredErr: Label '%1 is required for international travel.', Comment = '%1 = Field Caption';
        FieldRequiredBeforeReleaseErr: Label 'You must specify %1 before releasing the %2.', Comment = '%1 = Field Caption, %2 = document type description';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Instruction Mgt.", OnShowPostedDocumentOnBeforePageRun, '', false, false)]
    local procedure OnShowPostedDocumentOnBeforePageRun(CalledFromPageId: Integer; RecVariant: Variant; var PageId: Integer)
    var
        RecRef: RecordRef;
    begin
        if not RecVariant.IsRecord then
            exit;

        RecRef.GetTable(RecVariant);

        if RecRef.Number <> Database::"Posted Expense Report Header" then
            exit;

        PageId := Page::"Posted Expense Report"
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", OnBeforeCheckDocType, '', false, false)]
    local procedure OnBeforeCheckDocType(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
        if IsSourceExpense(GenJournalLine."Source Code") then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnBeforeGetEmployeePayablesAccount, '', false, false)]
    local procedure OnBeforeGetEmployeePayablesAccount(GenJournalLine: Record "Gen. Journal Line"; EmployeePostingGroup: Record "Employee Posting Group"; var PayablesAccount: Code[20]; var IsHandled: Boolean)
    begin
        if IsSourceExpense(GenJournalLine."Source Code") then
            EmployeePostingGroup.GetExpenseReportPayablesAccount();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnAfterGetEmployeePayablesAccount, '', false, false)]
    local procedure OnAfterGetEmployeePayablesAccount(GenJournalLine: Record "Gen. Journal Line"; EmployeePostingGroup: Record "Employee Posting Group"; var PayablesAccount: Code[20])
    begin
        if IsSourceExpense(GenJournalLine."Source Code") then
            PayablesAccount := EmployeePostingGroup.GetExpenseReportPayablesAccount();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Transfer Line", OnAfterFromJnlLineToLedgEntry, '', false, false)]
    local procedure OnAfterFromJnlLineToLedgEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
        JobLedgerEntry."Expense Report No." := JobJournalLine."Expense Report No.";
        JobLedgerEntry."Expense Report Line No." := JobJournalLine."Expense Report Line No.";
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Expense User", 'RM', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Table, Database::Employee, OnAfterValidateEvent, "First Name", false, false)]
    local procedure OnAfterValidateFirstNameEvent(var Rec: Record Employee)
    begin
        UpdateEmployeeDetailInExpenseUser(Rec, Rec.FieldNo("First Name"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Expense User", 'RM', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Table, Database::Employee, OnAfterValidateEvent, "Middle Name", false, false)]
    local procedure OnAfterValidateMiddleNameEvent(var Rec: Record Employee)
    begin
        UpdateEmployeeDetailInExpenseUser(Rec, Rec.FieldNo("Middle Name"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Expense User", 'RM', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Table, Database::Employee, OnAfterValidateEvent, "Last Name", false, false)]
    local procedure OnAfterValidateLastNameEvent(var Rec: Record Employee)
    begin
        UpdateEmployeeDetailInExpenseUser(Rec, Rec.FieldNo("Last Name"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Expense User", 'R', InherentPermissionsScope::Permissions)]
    [InherentPermissions(PermissionObjectType::TableData, Database::Expense, 'R', InherentPermissionsScope::Permissions)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Expense Report Header", 'R', InherentPermissionsScope::Permissions)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Posted Expense Report Header", 'R', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Table, Database::Employee, OnBeforeDeleteEvent, '', false, false)]
    local procedure OnBeforeDeleteEmployeeEvent(var Rec: Record Employee; RunTrigger: Boolean)
    var
        ExpenseUser: Record "Expense User";
    begin
        if not RunTrigger then
            exit;

        ExpenseUser.SetRange("Employee No.", Rec."No.");
        if ExpenseUser.FindFirst() then
            CheckEmployeeCanBeDeleted(ExpenseUser."No.", Rec."No.");
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Expense User", 'RD', InherentPermissionsScope::Permissions)]
    [InherentPermissions(PermissionObjectType::TableData, Database::Expense, 'R', InherentPermissionsScope::Permissions)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Expense Report Header", 'R', InherentPermissionsScope::Permissions)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Posted Expense Report Header", 'R', InherentPermissionsScope::Permissions)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Expense Agent Setup", 'R', InherentPermissionsScope::Permissions)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Expense Approval Setup", 'RD', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Table, Database::Employee, OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteEmployeeEvent(var Rec: Record Employee; RunTrigger: Boolean)
    var
        ExpenseUser: Record "Expense User";
    begin
        if not RunTrigger then
            exit;

        ExpenseUser.SetRange("Employee No.", Rec."No.");
        if ExpenseUser.FindFirst() then
            ExpenseUser.Delete(true);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Expense User", 'RM', InherentPermissionsScope::Permissions)]
    [InherentPermissions(PermissionObjectType::TableData, Database::Expense, 'R', InherentPermissionsScope::Permissions)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Expense Report Header", 'R', InherentPermissionsScope::Permissions)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Posted Expense Report Header", 'R', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Table, Database::Employee, OnAfterValidateEvent, "Company E-Mail", false, false)]
    local procedure OnAfterValidateCompanyEmailEvent(var Rec: Record Employee)
    begin
        CheckEmployeeEmailCanBeChangedInExpenseUser(Rec);

        UpdateEmployeeDetailInExpenseUser(Rec, Rec.FieldNo("Company E-Mail"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Expense User", 'RM', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Table, Database::Employee, OnAfterValidateEvent, "Job Title", false, false)]
    local procedure OnAfterValidateJobTitleEvent(var Rec: Record Employee)
    begin
        UpdateEmployeeDetailInExpenseUser(Rec, Rec.FieldNo("Job Title"));
    end;

    [EventSubscriber(ObjectType::Table, Database::Expense, OnAfterInsertEvent, '', false, false)]
    local procedure OnAfterInsertExpenseEvent(var Rec: Record Expense)
    begin
        Rec.ApplyRule();
        Rec.Modify();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reversal Entry", OnBeforeCheckGLEntry, '', false, false)]
    local procedure OnBeforeCheckGLEntryReversalEntryEvent(GLEntry: Record "G/L Entry"; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        if IsSourceExpense(GLEntry."Source Code") then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Spend Request", OnBeforeRelease, '', false, false)]
    local procedure OnBeforeReleaseSpendRequest(var SpendRequest: Record "Spend Request")
    begin
        CheckSpendRequestBeforeRelease(SpendRequest);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Spend Request", OnAfterRelease, '', false, false)]
    local procedure OnAfterReleaseSpendRequest(var SpendRequest: Record "Spend Request")
    begin
        AutoApproveSpendRequestWhenAgentDisabled(SpendRequest);
    end;

    internal procedure IsSourceExpense(SourceCode: Code[10]): Boolean
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.SetLoadFields(Expense);
        SourceCodeSetup.Get();

        exit(SourceCode = SourceCodeSetup.Expense);
    end;

    local procedure UpdateEmployeeDetailInExpenseUser(var Employee: Record Employee; FieldNo: Integer)
    var
        ExpenseUser: Record "Expense User";
    begin
        if Employee."No." = '' then
            exit;

        ExpenseUser.SetRange("Employee No.", Employee."No.");
        if ExpenseUser.FindFirst() then begin

            case FieldNo of
                Employee.FieldNo("First Name"),
                Employee.FieldNo("Middle Name"),
                Employee.FieldNo("Last Name"):
                    ExpenseUser.Validate(Name, Employee.FullName());
                Employee.FieldNo("Company E-Mail"):
                    ExpenseUser.Validate("E-mail", Employee."Company E-Mail");
                Employee.FieldNo("Job Title"):
                    ExpenseUser.Validate("Job Title", Employee."Job Title");
            end;

            ExpenseUser.Modify();
        end;
    end;

    local procedure CheckEmployeeEmailCanBeChangedInExpenseUser(Employee: Record Employee)
    var
        ExpenseUser: Record "Expense User";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        ExpenseUser.SetLoadFields("Employee No.", "E-mail");
        ExpenseUser.SetRange("Employee No.", Employee."No.");
        if ExpenseUser.FindFirst() then
            if Employee."Company E-Mail" <> ExpenseUser."E-mail" then
                if EmployeeExpenseUserHasExpenses(ExpenseUser."No.") then
                    if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(EmailChangeWarningQst, Employee."No."), false) then
                        Error('');

    end;

    local procedure EmployeeExpenseUserHasExpenses(ExpenseUserNo: Code[20]): Boolean
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
    begin
        Expense.SetRange("Expense User No.", ExpenseUserNo);
        if not Expense.IsEmpty() then
            exit(true);

        ExpenseReportHeader.SetRange("Expense User No.", ExpenseUserNo);
        if not ExpenseReportHeader.IsEmpty() then
            exit(true);

        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUserNo);
        exit(not PostedExpenseReportHeader.IsEmpty());
    end;

    local procedure CheckEmployeeCanBeDeleted(ExpenseUserNo: Code[20]; EmployeeNo: Code[20])
    var
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportHeader: Record "Expense Report Header";
        Expense: Record Expense;
    begin
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUserNo);
        if not PostedExpenseReportHeader.IsEmpty() then
            Error(CannotDeleteEmployeeWithPostedExpenseReportErr, EmployeeNo);

        ExpenseReportHeader.SetRange("Expense User No.", ExpenseUserNo);
        if not ExpenseReportHeader.IsEmpty() then
            Error(CannotDeleteEmployeeWithExpenseReportErr, EmployeeNo);

        Expense.SetRange("Expense User No.", ExpenseUserNo);
        if not Expense.IsEmpty() then
            Error(CannotDeleteEmployeeWithExpenseErr, EmployeeNo);
    end;

    local procedure CheckSpendRequestBeforeRelease(SpendRequest: Record "Spend Request")
    var
        Traveler: Record Traveler;
    begin
        if SpendRequest."Document Type" <> SpendRequest."Document Type"::"Travel Request" then
            exit;

        if SpendRequest.Status = SpendRequest.Status::Released then
            exit;

        if SpendRequest."Requested For" = '' then
            Error(FieldRequiredBeforeReleaseErr, SpendRequest.FieldCaption("Requested For"), SpendRequest.GetDocumentTypeDescription());
        if SpendRequest."Expected Start Date" = 0D then
            Error(FieldRequiredBeforeReleaseErr, SpendRequest.FieldCaption("Expected Start Date"), SpendRequest.GetDocumentTypeDescription());
        if SpendRequest."Expected End Date" = 0D then
            Error(FieldRequiredBeforeReleaseErr, SpendRequest.FieldCaption("Expected End Date"), SpendRequest.GetDocumentTypeDescription());

        if not SpendRequest."Travel Policy Acknowledgment" then
            Error(PolicyNotAcknowledgedErr, SpendRequest.GetDocumentTypeDescription());

        if SpendRequest."International Travel" and (SpendRequest."Dest. Country/Region Code" = '') then
            Error(DestinationRequiredErr, SpendRequest.FieldCaption("Dest. Country/Region Code"));

        Traveler.SetRange("Spend Request No.", SpendRequest."No.");
        if Traveler.IsEmpty() then
            Error(NoTravelersErr, SpendRequest.GetDocumentTypeDescription());
    end;

    local procedure AutoApproveSpendRequestWhenAgentDisabled(var SpendRequest: Record "Spend Request")
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        TravelRequestApproval: Codeunit "Travel Request Approval";
    begin
        if SpendRequest."Document Type" <> SpendRequest."Document Type"::"Travel Request" then
            exit;

        if SpendRequest.Status <> SpendRequest.Status::Released then
            exit;

        // Without the agent there is no approver, so a Releaseted request is approved right away.
        ExpenseAgentSetup.GetRecordOnce();
        if ExpenseAgentSetup."Enable Agent" then
            exit;

        TravelRequestApproval.ApproveAutomatically(SpendRequest);
    end;
}