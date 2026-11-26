// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.AI;

using System.AI.Troubleshooting;
using System.AI.Workspace;

codeunit 132691 "Troubleshooting Session Pages"
{
    Subtype = Test;

    [Test]
    [Scope('OnPrem')]
    procedure ListIsReadOnly()
    var
        Sessions: TestPage "Troubleshooting Sessions";
    begin
        Sessions.OpenEdit();
        if Sessions.Editable then
            Error('Troubleshooting sessions must remain read-only when opened for editing.');
        if Sessions.TroubleshootingId.Editable() or Sessions.Status.Editable() or
           Sessions.FirstSavedAt.Editable() or Sessions.LastSavedAt.Editable() or
           Sessions.Revision.Editable() or Sessions.OwnerUserSecurityId.Editable()
        then
            Error('Troubleshooting session list fields must remain read-only.');
        Sessions.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CardIsReadOnly()
    var
        SessionCard: TestPage "Troubleshooting Session Card";
    begin
        SessionCard.OpenEdit();
        if SessionCard.Editable then
            Error('The troubleshooting session card must remain read-only when opened for editing.');
        if SessionCard.TroubleshootingId.Editable() or SessionCard.Status.Editable() or
           SessionCard.FirstSavedAt.Editable() or SessionCard.LastSavedAt.Editable() or
           SessionCard.Revision.Editable() or SessionCard.OwnerName.Editable() or
           SessionCard.Details.Editable()
        then
            Error('Troubleshooting session card fields must remain read-only.');
        if not SessionCard.Details.Visible() then
            Error('The troubleshooting session card must show the saved report details.');
        SessionCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ListRespectsConversationFilter()
    var
        Sessions: TestPage "Troubleshooting Sessions";
    begin
        Sessions.OpenView();
        Sessions.Filter.SetFilter("Troubleshooting Id", Format(CreateGuid()));
        if Sessions.First() then
            Error('The troubleshooting session list must respect its conversation filter.');
        Sessions.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ListCanToggleActiveStatusFilter()
    var
        Entry: Record "Troubleshooting Session Entry";
        Sessions: TestPage "Troubleshooting Sessions";
        ActiveFilter: Text;
        ConversationFilter: Text;
    begin
        Entry.SetFilter(Status, '%1|%2', Entry.Status::InProgress, Entry.Status::AwaitingUser);
        ActiveFilter := Entry.GetFilter(Status);
        Sessions.OpenView();
        if Sessions.Filter.GetFilter(Status) <> ActiveFilter then
            Error('The troubleshooting session list must open with the active status filter.');

        Sessions.Filter.SetFilter("Troubleshooting Id", Format(CreateGuid()));
        ConversationFilter := Sessions.Filter.GetFilter("Troubleshooting Id");
        Sessions.ShowAllSessions.Invoke();
        if Sessions.Filter.GetFilter(Status) <> '' then
            Error('Show All Sessions must clear the status filter.');
        Sessions.ShowActiveSessions.Invoke();
        if Sessions.Filter.GetFilter(Status) <> ActiveFilter then
            Error('Show Active Sessions must restore the active status filter.');
        if Sessions.Filter.GetFilter("Troubleshooting Id") <> ConversationFilter then
            Error('Switching the status filter must preserve the conversation filter.');
        Sessions.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyCardHasNoDetails()
    var
        SessionCard: TestPage "Troubleshooting Session Card";
    begin
        SessionCard.OpenView();
        SessionCard.Filter.SetFilter("Troubleshooting Id", Format(CreateGuid()));
        if SessionCard.First() then
            Error('The troubleshooting session card must respect its conversation filter.');
        SessionCard.Details.AssertEquals('');
        SessionCard.Close();
    end;
}
