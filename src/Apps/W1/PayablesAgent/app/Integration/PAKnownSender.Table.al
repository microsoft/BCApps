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
        Rec.Insert();
        Session.LogSecurityAudit(Rec.TableName(), SecurityOperationResult::Success, 'Added new known sender.', AuditCategory::PolicyManagement);
    end;
}
