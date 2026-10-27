// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

table 3308 "PA Known Sender"
{
    Extensible = false;
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

    var
        SenderAddedAuditLbl: Label 'Added Payables Agent known sender %1.', Locked = true;
        SenderApprovedAuditLbl: Label 'Payables Agent known sender %1 was set to Approve, allowing its emails to be processed without review.', Locked = true;

    internal procedure InsertIfNew(PATask: Codeunit "Payables Agent Task")
    begin
        InsertSenderIfNew(PATask.GetSenderAddress());
    end;

    internal procedure InsertSourceIfNew(PATaskSource: Codeunit "PA Task Source")
    begin
        InsertSenderIfNew(PATaskSource.GetSenderAddress());
    end;

    local procedure InsertSenderIfNew(SenderEmail: Text[250])
    var
        Existing: Record "PA Known Sender";
        PASetup: Codeunit "PA Setup";
    begin
        if SenderEmail = '' then
            exit;
        Existing.SetRange(Email, SenderEmail);
        if not Existing.IsEmpty() then
            exit;
        Rec.Init();
        Rec.Email := SenderEmail;
        PASetup.GetSetup();
        if PASetup.GetEmailReviewPolicy() = "PA Email Review Policy"::OnlyIfUntrusted then
            Rec."Sender Policy" := "PA Sender Policy"::Approve
        else
            Rec."Sender Policy" := "PA Sender Policy"::Ask;
        Rec.Insert(true);
    end;

    internal procedure GetForTask(PATask: Codeunit "Payables Agent Task"; var KnownSender: Record "PA Known Sender"): Boolean
    begin
        exit(GetForSender(PATask.GetSenderAddress(), KnownSender));
    end;

    internal procedure GetForSource(PATaskSource: Codeunit "PA Task Source"; var KnownSender: Record "PA Known Sender"): Boolean
    begin
        exit(GetForSender(PATaskSource.GetSenderAddress(), KnownSender));
    end;

    local procedure GetForSender(SenderEmail: Text[250]; var KnownSender: Record "PA Known Sender"): Boolean
    begin
        if SenderEmail = '' then
            exit(false);
        KnownSender.SetRange(Email, SenderEmail);
        exit(KnownSender.FindFirst());
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
}
