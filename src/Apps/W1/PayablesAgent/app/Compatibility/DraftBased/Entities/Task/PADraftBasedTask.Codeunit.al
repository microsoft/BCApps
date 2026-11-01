// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;

// Source resolves the backing identity; this adapter retains the task's loaded outcome snapshot.
codeunit 3337 "PA Draft Based Task"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "E-Document" = RM;

    var
        LoadedEDocument: Record "E-Document";
        AgentEDocumentServiceTok: Label 'AGENT', Locked = true;

    internal procedure LoadResolvedSource(SourceId: Guid)
    begin
        Clear(LoadedEDocument);
        LoadedEDocument.GetBySystemId(SourceId);
    end;

    internal procedure GetOutcome(): RecordId
    begin
        exit(LoadedEDocument."Document Record ID");
    end;

    internal procedure IsBackingRecord(Candidate: RecordId): Boolean
    begin
        exit(Candidate = LoadedEDocument.RecordId());
    end;

    internal procedure GetState(): Enum "PA Task State"
    begin
        // Keep the loaded document, but calculate its processing FlowField just as the task did.
        LoadedEDocument.CalcFields("Import Processing Status");
        case LoadedEDocument."Import Processing Status" of
            "Import E-Doc. Proc. Status"::"Draft Ready":
                exit("PA Task State"::"Needs Attention");
            "Import E-Doc. Proc. Status"::"Ready for draft":
                exit("PA Task State"::"Ready For Review");
            "Import E-Doc. Proc. Status"::Processed:
                exit("PA Task State"::Processed);
        end;
        exit("PA Task State"::"Pending Processing");
    end;

    // Set-level posting bridge only: no per-task registration, attachment, title update or commit.
    internal procedure ReplaceOutcomeReferences(PreviousOutcome: RecordId; PostedOutcome: RecordId)
    var
        EDocument: Record "E-Document";
    begin
        EDocument.SetRange("Document Record ID", PreviousOutcome);
        if EDocument.FindSet(true) then
            repeat
                if EDocument.GetEDocumentService().Code = AgentEDocumentServiceTok then begin
                    EDocument."Document Record ID" := PostedOutcome;
                    EDocument.Modify();
                end;
            until EDocument.Next() = 0;
    end;
}
