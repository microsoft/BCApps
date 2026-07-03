// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;

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
            ToolTip = 'Specifies the email address of a sender whose e-documents have been processed by the Payables Agent.';
        }
        field(3; "Sender Policy"; Enum "PA Sender Policy")
        {
            DataClassification = CustomerContent;
            Caption = 'Review policy';
            ToolTip = 'Specifies how an incoming email from this sender is handled. ''Ask'' requests human review. ''Approve'' processes without review (effective when overall email review is ''Only if untrusted''). ''Reject'' ignores the email.';
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

    internal procedure InsertIfNew(EDocument: Record "E-Document")
    var
        Existing: Record "PA Known Sender";
        Setup: Record "Payables Agent Setup";
        SenderEmail: Text[250];
    begin
        SenderEmail := CopyStr(EDocument."Source Details", 1, MaxStrLen(SenderEmail));
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
        Rec.Insert();
        Session.LogSecurityAudit(Rec.TableName(), SecurityOperationResult::Success, 'Added new known sender.', AuditCategory::PolicyManagement);
    end;

    /// <summary>
    /// Finds the known-sender record matching the e-document's sender, if any.
    /// Returns false when the sender is empty or not in the list.
    /// </summary>
    internal procedure GetForEDocument(EDocument: Record "E-Document"; var KnownSender: Record "PA Known Sender"): Boolean
    var
        SenderEmail: Text[250];
    begin
        SenderEmail := CopyStr(EDocument."Source Details", 1, MaxStrLen(KnownSender.Email));
        if SenderEmail = '' then
            exit(false);
        KnownSender.SetRange(Email, SenderEmail);
        exit(KnownSender.FindFirst());
    end;
}
