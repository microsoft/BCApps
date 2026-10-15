// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Email;

table 3308 "PA Known Sender"
{
    Access = Internal;
    Caption = 'Payables Agent Known Sender', Comment = 'Payables Agent is a term, and should not be translated.';
    InherentEntitlements = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; Id; BigInteger)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; Email; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Email';
            ToolTip = 'Specifies the email address of a sender whose emails have been processed by the Payables Agent.';
        }
        field(3; "Sender Policy"; Enum "PA Sender Policy")
        {
            DataClassification = CustomerContent;
            Caption = 'Review policy';
            ToolTip = 'Specifies how an incoming email from this sender is handled. ''Ask'' requests human review. ''Approve'' processes without review (effective when overall email review is ''Manage per sender''). ''Reject'' ignores the email.';
        }
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
        key(Key1; Email)
        {
        }
    }

    trigger OnInsert()
    begin
        LogSenderAdded();
        if Rec."Sender Policy" = Rec."Sender Policy"::Approve then
            LogSenderApproved();
    end;

    trigger OnModify()
    begin
        if (Rec."Sender Policy" = Rec."Sender Policy"::Approve) and (xRec."Sender Policy" <> Rec."Sender Policy"::Approve) then
            LogSenderApproved();
    end;

    /// <summary>
    /// Adds the sender of an email-sourced task to the known-senders list if it is not there yet. The sender is
    /// read from the Email module via the task source's email inbox; tasks with no email source are ignored.
    /// Callers standardize their input into a task source first (see "PA V1V2 Compatibility").
    /// </summary>
    internal procedure InsertIfNew(PayablesAgentTaskSource: Record "Payables Agent Task Source")
    var
        Existing: Record "PA Known Sender";
        Setup: Record "Payables Agent Setup";
        SenderEmail: Text[250];
    begin
        SenderEmail := GetSenderEmail(PayablesAgentTaskSource);
        if SenderEmail = '' then
            exit;
        Existing.SetRange(Email, SenderEmail);
        if not Existing.IsEmpty() then
            exit;
        Rec.Init();
        Rec.Email := SenderEmail;
        Setup.GetSetup();
        if Setup."Email Review Policy" = "PA Email Review Policy"::OnlyIfUntrusted then
            Rec."Sender Policy" := "PA Sender Policy"::Approve
        else
            Rec."Sender Policy" := "PA Sender Policy"::Ask;
        Rec.Insert(true);
    end;

    /// <summary>
    /// Finds the known-sender record matching a task source's sender, if any.
    /// Returns false when the task has no email source, the sender is empty, or it is not in the list.
    /// </summary>
    internal procedure GetForSource(PayablesAgentTaskSource: Record "Payables Agent Task Source"; var KnownSender: Record "PA Known Sender"): Boolean
    var
        SenderEmail: Text[250];
    begin
        SenderEmail := GetSenderEmail(PayablesAgentTaskSource);
        if SenderEmail = '' then
            exit(false);
        KnownSender.SetRange(Email, SenderEmail);
        exit(KnownSender.FindFirst());
    end;

    /// <summary>
    /// The sender email address of a task source, read from the Email module. Blank when there is no email inbox
    /// attached or the inbox row is no longer available.
    /// </summary>
    local procedure GetSenderEmail(PayablesAgentTaskSource: Record "Payables Agent Task Source"): Text[250]
    var
        EmailInbox: Record "Email Inbox";
    begin
        if PayablesAgentTaskSource."Email Inbox Id" = 0 then
            exit('');
        EmailInbox.SetLoadFields("Sender Address");
        if not EmailInbox.Get(PayablesAgentTaskSource."Email Inbox Id") then
            exit('');
        exit(CopyStr(EmailInbox."Sender Address", 1, 250));
    end;

    // Logs every path that adds a known sender, and separately every path that results in a sender
    // marked Approve (which lets its emails be processed without human review).
    local procedure LogSenderAdded()
    begin
        Session.LogSecurityAudit(Rec.TableName(), SecurityOperationResult::Success, StrSubstNo(SenderAddedAuditLbl, Rec.Email), AuditCategory::PolicyManagement);
    end;

    local procedure LogSenderApproved()
    begin
        Session.LogSecurityAudit(Rec.TableName(), SecurityOperationResult::Success, StrSubstNo(SenderApprovedAuditLbl, Rec.Email), AuditCategory::PolicyManagement);
    end;

    var
        SenderAddedAuditLbl: Label 'Added Payables Agent known sender %1.', Locked = true;
        SenderApprovedAuditLbl: Label 'Payables Agent known sender %1 was set to Approve, allowing its emails to be processed without review.', Locked = true;
}
