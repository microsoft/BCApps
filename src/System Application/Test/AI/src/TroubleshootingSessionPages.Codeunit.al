// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.AI;

using System.AI.Troubleshooting;
using System.AI.Workspace;

codeunit 132691 "Troubleshooting Session Pages"
{
    // [FEATURE] Troubleshooting sessions
    Subtype = Test;

    [Test]
    [Scope('OnPrem')]
    procedure ListIsReadOnly()
    var
        Sessions: TestPage "Troubleshooting Sessions";
    begin
        // [SCENARIO] The list cannot be edited, even in edit mode.
        // [WHEN] A user opens the list in edit mode.
        Sessions.OpenEdit();
        // [THEN] The list and its report fields remain read-only.
        if Sessions.Editable then
            Error('Troubleshooting sessions must remain read-only when opened for editing.');
        if Sessions.TroubleshootingId.Editable() or Sessions.Status.Editable() or
           Sessions.FirstSavedAt.Editable() or Sessions.LastSavedAt.Editable() or
           Sessions.Revision.Editable() or Sessions.OwnerName.Editable()
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
        // [SCENARIO] The card shows details without allowing edits.
        // [WHEN] A user opens the card in edit mode.
        SessionCard.OpenEdit();
        // [THEN] The card and its fields remain read-only and the details are visible.
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
        // [SCENARIO] The list respects a conversation filter.
        // [GIVEN] An open troubleshooting session list.
        Sessions.OpenView();
        // [WHEN] A user filters to a conversation that does not exist.
        Sessions.Filter.SetFilter("Troubleshooting Id", Format(CreateGuid()));
        // [THEN] No session is displayed.
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
        // [SCENARIO] The list opens on active sessions and can toggle the status filter.
        // [GIVEN] The expected filter for active sessions.
        Entry.SetFilter(Status, '%1|%2', Entry.Status::InProgress, Entry.Status::AwaitingUser);
        ActiveFilter := Entry.GetFilter(Status);
        // [WHEN] A user opens the list.
        Sessions.OpenView();
        // [THEN] Only active statuses are selected.
        if Sessions.Filter.GetFilter(Status) <> ActiveFilter then
            Error('The troubleshooting session list must open with the active status filter.');

        Sessions.Filter.SetFilter("Troubleshooting Id", Format(CreateGuid()));
        ConversationFilter := Sessions.Filter.GetFilter("Troubleshooting Id");
        // [WHEN] A user switches between all and active sessions.
        Sessions.ShowAllSessions.Invoke();
        if Sessions.Filter.GetFilter(Status) <> '' then
            Error('Show All Sessions must clear the status filter.');
        Sessions.ShowActiveSessions.Invoke();
        // [THEN] The active status filter is restored and the conversation filter is unchanged.
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
        // [SCENARIO] The card has no details when there is no matching report.
        // [GIVEN] An open troubleshooting session card.
        SessionCard.OpenView();
        // [WHEN] A user filters to a conversation that does not exist.
        SessionCard.Filter.SetFilter("Troubleshooting Id", Format(CreateGuid()));
        // [THEN] The card shows no session or details.
        if SessionCard.First() then
            Error('The troubleshooting session card must respect its conversation filter.');
        SessionCard.Details.AssertEquals('');
        SessionCard.Close();
    end;
}
