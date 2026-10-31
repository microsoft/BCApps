// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using System.Agents;
using System.Utilities;

// V1 backing representation for a received Payables Agent source; import admission belongs to the intake flow.
codeunit 3332 "PA Draft Based Task Source"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task" = R, tabledata "E-Document" = RM, tabledata "E-Doc. Data Storage" = R;

    var
        LoadedEDocument: Record "E-Document";
        Loaded: Boolean;
        SourceNotFoundErr: Label 'The task source does not exist.';

    internal procedure CreateFromPdf(FileName: Text; PdfInStream: InStream): Boolean
    var
        EDocument: Record "E-Document";
        EDocImport: Codeunit "E-Doc. Import";
        PADraftBasedSetup: Codeunit "PA Draft Based Setup";
    begin
        ClearLoaded();
        EDocImport.CreateFromType(EDocument, PADraftBasedSetup.GetOrCreateAgentEDocumentService(), "E-Doc. File Format"::PDF, FileName, PdfInStream);
        EDocument."Source Details" := CopyStr(FileName, 1, MaxStrLen(EDocument."Source Details"));
        EDocument.Modify();
        exit(Load(EDocument.SystemId));
    end;

    internal procedure Load(SourceId: Guid): Boolean
    begin
        ClearLoaded();
        if IsNullGuid(SourceId) then
            exit(false);
        if not LoadedEDocument.GetBySystemId(SourceId) then
            exit(false);
        Loaded := true;
        exit(true);
    end;

    internal procedure GetId(): Guid
    begin
        RequireLoaded();
        exit(LoadedEDocument.SystemId);
    end;

    internal procedure GetAgentTaskId(): BigInteger
    var
        AgentTask: Record "Agent Task";
    begin
        RequireLoaded();
        AgentTask.SetRange("Company Name", CompanyName());
        AgentTask.SetRange("External ID", GetAgentTaskExternalId());
        if AgentTask.FindFirst() then
            exit(AgentTask.ID);
        exit(0);
    end;

    internal procedure GetAgentTaskExternalId(): Text[2048]
    begin
        RequireLoaded();
        exit(Format(LoadedEDocument."Entry No"));
    end;

    internal procedure GetAgentTaskMessage(): Text
    var
        TaskMessageLbl: Label 'A new electronic document %1 has been received. Your task is to create the purchase document for it in Business Central: a Purchase Invoice, or a Purchase Credit Memo when the draft''s Document Type is Purchase Credit Memo.', Locked = true, Comment = '%1 = e-document entry number';
    begin
        RequireLoaded();
        exit(StrSubstNo(TaskMessageLbl, GetAgentTaskExternalId()));
    end;

    internal procedure GetSourceType(): Enum "PA Source Type"
    begin
        RequireLoaded();
        if LoadedEDocument."Outlook Mail Message Id" <> '' then
            exit("PA Source Type"::Email);
        exit("PA Source Type"::Upload);
    end;

    internal procedure GetFileName(): Text
    var
        Storage: Record "E-Doc. Data Storage";
    begin
        RequireLoaded();
        if Storage.Get(LoadedEDocument."Unstructured Data Entry No.") then
            exit(Storage.Name);
        exit('');
    end;

    internal procedure HasPdf(): Boolean
    var
        Storage: Record "E-Doc. Data Storage";
    begin
        RequireLoaded();
        if Storage.Get(LoadedEDocument."Unstructured Data Entry No.") then
            exit(Storage."File Format" = Enum::"E-Doc. File Format"::PDF);
        exit(false);
    end;

    internal procedure GetEmailFrom(): Text
    begin
        RequireLoaded();
        exit(LoadedEDocument."Source Details");
    end;

    internal procedure GetEmailSubject(): Text
    begin
        RequireLoaded();
        exit(LoadedEDocument."Additional Source Details");
    end;

    internal procedure GetEmailExternalId(): Text
    begin
        RequireLoaded();
        exit(LoadedEDocument."Outlook Mail Message Id");
    end;

    internal procedure GetEmailReceivedAt(): DateTime
    begin
        RequireLoaded();
        exit(LoadedEDocument.SystemCreatedAt);
    end;

    internal procedure GetCreatedAt(): DateTime
    begin
        RequireLoaded();
        exit(LoadedEDocument.SystemCreatedAt);
    end;

    internal procedure GetUpdatedAt(): DateTime
    begin
        RequireLoaded();
        exit(LoadedEDocument.SystemModifiedAt);
    end;

    internal procedure TryGetEmailMessageId(var MessageId: Guid): Boolean
    begin
        RequireLoaded();
        MessageId := LoadedEDocument."Mail Message Id";
        exit(not IsNullGuid(MessageId));
    end;

    internal procedure GetSourcePdf(var TempBlob: Codeunit "Temp Blob"; var FileName: Text): Boolean
    var
        Storage: Record "E-Doc. Data Storage";
    begin
        Clear(TempBlob);
        Clear(FileName);
        RequireLoaded();
        if not Storage.Get(LoadedEDocument."Unstructured Data Entry No.") then
            exit(false);
        TempBlob := Storage.GetTempBlob();
        FileName := Storage.Name;
        exit(true);
    end;

    local procedure RequireLoaded()
    begin
        if not Loaded then
            Error(SourceNotFoundErr);
    end;

    local procedure ClearLoaded()
    begin
        Clear(LoadedEDocument);
        Loaded := false;
    end;
}
