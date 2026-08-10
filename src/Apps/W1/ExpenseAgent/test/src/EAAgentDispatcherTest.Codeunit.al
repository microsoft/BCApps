// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.Email;

codeunit 148314 "EA Agent Dispatcher Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        OneOwnerMustBeDefinedErr: Label 'At least one user must be able to configure the Expense Agent.';

    [Test]
    procedure GetSendEmailAccountReturnsMainAccountWhenNoreplyNotConfigured()
    var
        Setup: Record "Expense Agent Setup";
        MainAccountID: Guid;
    begin
        // [SCENARIO] When no noreply account is configured, sending uses the main email account.

        // [GIVEN] Setup with a main email account and no noreply account
        MainAccountID := CreateGuid();
        InitSetupWithMainAccount(Setup, MainAccountID);

        // [THEN] The main account fields are present and noreply fields are empty
        Assert.AreEqual(MainAccountID, Setup."Email Account ID", 'Main Email Account ID should be set.');
        Assert.IsTrue(IsNullGuid(Setup."Noreply Email Account ID"), 'Noreply Email Account ID should be empty.');
    end;

    [Test]
    procedure GetSendEmailAccountReturnsNoreplyAccountWhenConfigured()
    var
        Setup: Record "Expense Agent Setup";
        MainAccountID: Guid;
        NoreplyAccountID: Guid;
    begin
        // [SCENARIO] When a noreply account is configured, it should be preferred for sending.

        // [GIVEN] Setup with both main and noreply email accounts
        MainAccountID := CreateGuid();
        NoreplyAccountID := CreateGuid();
        InitSetupWithMainAccount(Setup, MainAccountID);
        Setup."Noreply Email Account ID" := NoreplyAccountID;
        Setup."Noreply Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        Setup."Noreply Email Address" := 'noreply@contoso.com';
        Setup.Modify();

        // [THEN] Noreply account is set
        Assert.AreEqual(NoreplyAccountID, Setup."Noreply Email Account ID", 'Noreply Email Account ID should be set.');
        Assert.AreEqual('noreply@contoso.com', Setup."Noreply Email Address", 'Noreply Email Address should be set.');
    end;

    [Test]
    procedure NoreplyFieldsDefaultToEmpty()
    var
        Setup: Record "Expense Agent Setup";
    begin
        // [SCENARIO] New installations have empty noreply fields by default (backward-compatible).

        // [GIVEN] A fresh setup record
        Setup.DeleteAll();
        Setup.Init();
        Setup.Insert();

        // [THEN] Noreply fields are empty
        Assert.IsTrue(IsNullGuid(Setup."Noreply Email Account ID"), 'Noreply Email Account ID should default to empty GUID.');
        Assert.AreEqual('', Setup."Noreply Email Address", 'Noreply Email Address should default to empty.');
    end;

    [Test]
    procedure ClearingNoreplyAccountResetsAllFields()
    var
        Setup: Record "Expense Agent Setup";
        NoreplyAccountID: Guid;
    begin
        // [SCENARIO] Clearing the noreply account resets all three noreply fields.

        // [GIVEN] Setup with a noreply account configured
        NoreplyAccountID := CreateGuid();
        InitSetupWithMainAccount(Setup, CreateGuid());
        Setup."Noreply Email Account ID" := NoreplyAccountID;
        Setup."Noreply Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        Setup."Noreply Email Address" := 'noreply@contoso.com';
        Setup.Modify();

        // [WHEN] The noreply fields are cleared
        Clear(Setup."Noreply Email Account ID");
        Clear(Setup."Noreply Email Connector");
        Setup."Noreply Email Address" := '';
        Setup.Modify();

        // [THEN] All noreply fields are reset
        Setup.Get();
        Assert.IsTrue(IsNullGuid(Setup."Noreply Email Account ID"), 'Noreply Email Account ID should be empty after clearing.');
        Assert.AreEqual('', Setup."Noreply Email Address", 'Noreply Email Address should be empty after clearing.');
    end;

    local procedure InitSetupWithMainAccount(var Setup: Record "Expense Agent Setup"; AccountID: Guid)
    begin
        Setup.DeleteAll();
        Setup.Init();
        Setup."Email Account ID" := AccountID;
        Setup."Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        Setup."Email Address" := 'expenses@contoso.com';
        Setup.Insert();
    end;

    [Test]
    procedure SchedulerTaskFailedStatusAndErrorMessageArePersisted()
    var
        EASchedulerTask: Record "EA Scheduler Task";
        TaskID: BigInteger;
    begin
        // [SCENARIO] EA Scheduler Task supports the new Failed status and stores an error message.

        // [GIVEN] A scheduler task in progress
        EASchedulerTask.DeleteAll();
        Clear(EASchedulerTask);
        EASchedulerTask.Status := EASchedulerTask.Status::"In Progress";
        EASchedulerTask.Insert();
        TaskID := EASchedulerTask.ID;

        // [WHEN] The task is marked as failed with an error message
        EASchedulerTask.Status := EASchedulerTask.Status::Failed;
        EASchedulerTask."Error Message" := 'Expense Agent is not enabled.';
        EASchedulerTask.Modify();

        // [THEN] The Failed status and error message are stored
        Clear(EASchedulerTask);
        EASchedulerTask.Get(TaskID);
        Assert.AreEqual(EASchedulerTask.Status::Failed, EASchedulerTask.Status, 'Status should be Failed.');
        Assert.AreEqual('Expense Agent is not enabled.', EASchedulerTask."Error Message", 'Error Message should be persisted.');
    end;

    [Test]
    procedure ExpenseAgentStatusFlowFieldsLookupSchedulerTask()
    var
        EASchedulerTask: Record "EA Scheduler Task";
        ExpenseAgentStatus: Record "Expense Agent Status";
    begin
        // [SCENARIO] The Expense Agent Status FlowFields read Status and Error Message from the linked scheduler task.

        // [GIVEN] A failed scheduler task
        EASchedulerTask.DeleteAll();
        Clear(EASchedulerTask);
        EASchedulerTask.Status := EASchedulerTask.Status::Failed;
        EASchedulerTask."Error Message" := 'Expense Agent has no email account specified.';
        EASchedulerTask.Insert();

        // [GIVEN] An Expense Agent Status record pointing to that task
        ExpenseAgentStatus.DeleteAll();
        ExpenseAgentStatus.GetOrCreate();
        ExpenseAgentStatus."EA Scheduler Task ID" := EASchedulerTask.ID;
        ExpenseAgentStatus.Modify();

        // [WHEN] The FlowFields are calculated
        ExpenseAgentStatus.CalcFields("Scheduler Task Status", "Scheduler Task Error Message");

        // [THEN] They reflect the linked scheduler task
        Assert.AreEqual(ExpenseAgentStatus."Scheduler Task Status"::Failed, ExpenseAgentStatus."Scheduler Task Status", 'Scheduler Task Status FlowField should reflect linked task.');
        Assert.AreEqual('Expense Agent has no email account specified.', ExpenseAgentStatus."Scheduler Task Error Message", 'Scheduler Task Error Message FlowField should reflect linked task.');
    end;

    [Test]
    procedure GetByUserSecurityIDReturnsTrueWhenUserExists()
    var
        AccessControl: Record "Expense Agent Access Control";
        UserID: Guid;
    begin
        // [SCENARIO] GetByUserSecurityID finds an existing access control row by user.

        // [GIVEN] An access control record for a user
        AccessControl.DeleteAll();
        UserID := CreateGuid();
        InsertAccessControl(AccessControl, UserID, true, true);

        // [WHEN] Looking up by that user security ID
        Clear(AccessControl);

        // [THEN] The record is found
        Assert.IsTrue(AccessControl.GetByUserSecurityID(UserID), 'Expected to find access control row for user.');
        Assert.AreEqual(UserID, AccessControl."User Security ID", 'Returned record should be the requested user.');
    end;

    [Test]
    procedure GetByUserSecurityIDReturnsFalseWhenUserMissing()
    var
        AccessControl: Record "Expense Agent Access Control";
    begin
        // [SCENARIO] GetByUserSecurityID returns false when no row exists for the user.

        // [GIVEN] No access control rows for the queried user
        AccessControl.DeleteAll();

        // [THEN] Lookup returns false
        Assert.IsFalse(AccessControl.GetByUserSecurityID(CreateGuid()), 'Expected lookup to return false when user is not present.');
    end;

    [Test]
    procedure ClearingCanConfigureAgentSucceedsWhenAnotherOwnerExists()
    var
        AccessControl: Record "Expense Agent Access Control";
        SetupSystemID: Guid;
        UserA: Guid;
        UserB: Guid;
    begin
        // [SCENARIO] Clearing Can Configure Agent on one owner is allowed when another owner remains.

        // [GIVEN] Two users with Can Configure Agent set to true
        AccessControl.DeleteAll();
        SetupSystemID := EmptyGuid();
        UserA := CreateGuid();
        UserB := CreateGuid();
        InsertAccessControl(AccessControl, UserA, true, true);
        InsertAccessControl(AccessControl, UserB, true, false);

        // [WHEN] Clearing Can Configure Agent on the first user
        AccessControl.Get(SetupSystemID, UserA);
        AccessControl.Validate("Can Configure Agent", false);
        AccessControl.Modify();

        // [THEN] The value is updated and no error is raised
        AccessControl.Get(SetupSystemID, UserA);
        Assert.IsFalse(AccessControl."Can Configure Agent", 'Can Configure Agent should be cleared.');
    end;

    [Test]
    procedure ClearingCanConfigureAgentFailsWhenLastOwner()
    var
        AccessControl: Record "Expense Agent Access Control";
        UserID: Guid;
    begin
        // [SCENARIO] Clearing 'Can Configure' Agent on the only owner raises an error.

        // [GIVEN] A single user with Can Configure Agent set to true
        AccessControl.DeleteAll();
        UserID := CreateGuid();
        InsertAccessControl(AccessControl, UserID, true, true);

        // [WHEN] Trying to clear Can Configure Agent on the last owner
        AccessControl.Get(EmptyGuid(), UserID);
        asserterror AccessControl.Validate("Can Configure Agent", false);

        // [THEN] The "one owner must be defined" error is raised
        Assert.ExpectedError(OneOwnerMustBeDefinedErr);
    end;

    [Test]
    procedure DeletingOwnerSucceedsWhenAnotherOwnerExists()
    var
        AccessControl: Record "Expense Agent Access Control";
        UserA: Guid;
        UserB: Guid;
    begin
        // [SCENARIO] Deleting an owner is allowed when at least one other owner remains.

        // [GIVEN] Two users with Can Configure Agent
        AccessControl.DeleteAll();
        UserA := CreateGuid();
        UserB := CreateGuid();
        InsertAccessControl(AccessControl, UserA, true, true);
        InsertAccessControl(AccessControl, UserB, true, false);

        // [WHEN] Deleting one of them
        AccessControl.Get(EmptyGuid(), UserA);
        AccessControl.Delete(true);

        // [THEN] The other owner is still present
        Assert.IsTrue(AccessControl.GetByUserSecurityID(UserB), 'Remaining owner should still exist.');
    end;

    [Test]
    procedure DeletingLastOwnerFails()
    var
        AccessControl: Record "Expense Agent Access Control";
        UserID: Guid;
    begin
        // [SCENARIO] Deleting the only owner raises an error.

        // [GIVEN] A single user with Can Configure Agent
        AccessControl.DeleteAll();
        UserID := CreateGuid();
        InsertAccessControl(AccessControl, UserID, true, true);

        // [WHEN] Deleting that user
        AccessControl.Get(EmptyGuid(), UserID);
        asserterror AccessControl.Delete(true);

        // [THEN] The "one owner must be defined" error is raised
        Assert.ExpectedError(OneOwnerMustBeDefinedErr);
    end;

    [Test]
    procedure DeletingNonOwnerDoesNotEnforceOwnerRule()
    var
        AccessControl: Record "Expense Agent Access Control";
        OwnerID: Guid;
        NonOwnerID: Guid;
    begin
        // [SCENARIO] Deleting a non-owner row does not raise the owner rule even when only one owner exists.

        // [GIVEN] One owner and one non-owner
        AccessControl.DeleteAll();
        OwnerID := CreateGuid();
        NonOwnerID := CreateGuid();
        InsertAccessControl(AccessControl, OwnerID, true, true);
        InsertAccessControl(AccessControl, NonOwnerID, false, false);

        // [WHEN] Deleting the non-owner row
        AccessControl.Get(EmptyGuid(), NonOwnerID);
        AccessControl.Delete(true);

        // [THEN] The owner is still present and no error was raised
        Assert.IsTrue(AccessControl.GetByUserSecurityID(OwnerID), 'Owner should remain after deleting a non-owner.');
    end;

    local procedure InsertAccessControl(var AccessControl: Record "Expense Agent Access Control"; UserID: Guid; CanConfigure: Boolean; CanWorkOnBehalf: Boolean)
    begin
        Clear(AccessControl);
        AccessControl."Setup System ID" := EmptyGuid();
        AccessControl."User Security ID" := UserID;
        AccessControl."Can Configure Agent" := CanConfigure;
        AccessControl."Can Work on Behalf" := CanWorkOnBehalf;
        AccessControl.Insert();
    end;

    local procedure EmptyGuid(): Guid
    var
        EmptyId: Guid;
    begin
        Clear(EmptyId);
        exit(EmptyId);
    end;
}
