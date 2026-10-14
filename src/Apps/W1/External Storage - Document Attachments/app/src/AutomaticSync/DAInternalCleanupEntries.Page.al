// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExternalStorage.DocumentAttachments;

using Microsoft.Foundation.Attachment;

page 8752 "DA Internal Cleanup Entries"
{
    PageType = List;
    SourceTable = "DA Internal Cleanup Entry";
    Caption = 'Internal Attachment Cleanup Requests';
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    Extensible = false;
    Permissions = tabledata "DA Internal Cleanup Entry" = r;

    layout
    {
        area(Content)
        {
            repeater(Requests)
            {
                field("Attachment System ID"; Rec."Attachment System ID") { ToolTip = 'Identifies the attachment owning this request.'; }
                field(Status; Rec.Status) { ToolTip = 'Shows the current cleanup state.'; }
                field(Origin; Rec.Origin) { ToolTip = 'Shows which operation requested cleanup. Copy does not authorize cleanup.'; }
                field("External File Path"; Rec."External File Path") { ToolTip = 'Shows the exact stored path bound to upload provenance.'; }
                field("Requested At"; Rec."Requested At") { ToolTip = 'Shows when cleanup was requested.'; }
                field("Attempt Count"; Rec."Attempt Count") { ToolTip = 'Shows the number of attempts in this request.'; }
                field("Next Attempt At"; Rec."Next Attempt At") { ToolTip = 'Shows the earliest time for a retry.'; }
                field("Last Verified At"; Rec."Last Verified At") { ToolTip = 'Shows diagnostic evidence of past readback, not permanent authorization for cleanup.'; }
                field(Outcome; Rec.Outcome) { ToolTip = 'Shows the latest cleanup outcome.'; }
                field("Last Error"; Rec."Last Error") { ToolTip = 'Shows why internal content was retained. Configuration changes are never silently rebound.'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RetryCleanup)
            {
                Caption = 'Retry Requested Cleanup';
                Image = Refresh;
                ToolTip = 'Recheck a previous request without releasing internal references. Internal cleanup remains blocked and reclaims no database storage; this does not adopt a different destination or legacy binding.';
                Enabled = (Rec.Origin <> Rec.Origin::Copy) and ((Rec.Status = Rec.Status::Blocked) or (Rec.Status = Rec.Status::"Retry Due"));

                trigger OnAction()
                var
                    Entries: Record "DA Internal Cleanup Entry";
                    DocumentAttachment: Record "Document Attachment";
                    CleanupManagement: Codeunit "DA Internal Cleanup Mgt.";
                    BlockedCount: Integer;
                begin
                    if not Confirm(RetryQst, false) then
                        exit;
                    BlockedCount := 0;
                    CurrPage.SetSelectionFilter(Entries);
                    if Entries.FindSet() then
                        repeat
                            if (Entries.Origin <> Entries.Origin::Copy) and (Entries.Status in [Entries.Status::Blocked, Entries.Status::"Retry Due"]) then
                                if DocumentAttachment.GetBySystemId(Entries."Attachment System ID") then
                                    if not CleanupManagement.RequestCleanup(DocumentAttachment, Entries.Origin) then
                                        BlockedCount += 1;
                            Commit();
                        until Entries.Next() = 0;
                    Message(RequestsBlockedMsg, BlockedCount, CleanupManagement.GetInternalReleaseBlockedReason());
                end;
            }
            action(CancelCleanup)
            {
                Caption = 'Cancel Cleanup Request';
                Image = Cancel;
                ToolTip = 'Cancel selected cleanup requests without deleting internal content or external files.';
                Enabled = (Rec.Status = Rec.Status::Pending) or (Rec.Status = Rec.Status::"In Progress") or (Rec.Status = Rec.Status::"Retry Due") or (Rec.Status = Rec.Status::Blocked);

                trigger OnAction()
                var
                    Entries: Record "DA Internal Cleanup Entry";
                    CleanupManagement: Codeunit "DA Internal Cleanup Mgt.";
                begin
                    if not Confirm(CancelQst, false) then
                        exit;
                    CurrPage.SetSelectionFilter(Entries);
                    if Entries.FindSet() then
                        repeat
                            if Entries.Status in [Entries.Status::Pending, Entries.Status::"In Progress", Entries.Status::"Retry Due", Entries.Status::Blocked] then
                                CleanupManagement.CancelCleanup(Entries."Attachment System ID");
                        until Entries.Next() = 0;
                end;
            }
        }
    }

    var
        RetryQst: Label 'Recheck the selected requests? Internal cleanup remains blocked. Internal references and content will be retained, with no database storage reclamation.';
        CancelQst: Label 'Cancel the selected cleanup requests and retain internal content?';
        RequestsBlockedMsg: Label '%1 cleanup request(s) blocked. %2', Comment = '%1 = Blocked requests, %2 = Reason explaining retained content and no storage reclamation';
}
