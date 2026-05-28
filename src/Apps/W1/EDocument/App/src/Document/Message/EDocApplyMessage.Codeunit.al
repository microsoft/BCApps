// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// The shared post-event step for E-Document Messages. Called once inbound (after the Reader
/// parsed the payload and the framework resolved the parent) and once outbound (after the
/// Writer generated and the connector sent). Locks the parent, runs Type.ApplyMessage with an
/// Apply Context, then executes the declared intent uniformly: Service Status update via
/// "E-Document Processing", log entries via "E-Document Log", workflow event firing, and
/// message internal status.
///
/// Type / Reader / Writer never see locking, log writes, Service Status updates, or events.
/// </summary>
codeunit 6344 "E-Doc. Apply Message"
{
    Access = Public;

    procedure Run(var Msg: Record "E-Document Message"; var Parent: Record "E-Document"; var Service: Record "E-Document Service")
    var
        Log: Codeunit "E-Document Log";
        Context: Codeunit "E-Doc. Msg. Apply Context";
        Type: Interface IEDocumentMessageType;
    begin
        Parent.LockTable();
        if not Parent.Find() then
            exit;

        Type := Msg."Message Type";
        Clear(Context);
        Type.ApplyMessage(Msg, Context);

        // Document log records the *parent's* state changes, not message-internal events.
        // Type.AddLogNote(...) notes are deliberately not routed to EDocumentLog — they would
        // require a free-text field or a placeholder Service Status, both of which muddy audit.
        // Implementers wanting telemetry can use Session.LogMessage directly.

        if Context.IsIgnored() then begin
            MarkRow(Msg, Msg.Status::Ignored, Context.GetIgnoredReason());
            exit;
        end;

        if Context.HasError() then begin
            UpdateStatus(Parent, Service, Context.GetErrorStatus());
            Log.InsertLog(Parent, Service, Context.GetErrorStatus());
            MarkRow(Msg, Msg.Status::"Apply Failed", Context.GetErrorText());
            exit;
        end;

        if Context.HasNewParentStatus() then begin
            UpdateStatus(Parent, Service, Context.GetNewParentStatus());
            Log.InsertLog(Parent, Service, Context.GetNewParentStatus());
        end;

        if Msg.Direction = Msg.Direction::Incoming then begin
            Msg.Status := Msg.Status::Applied;
            Msg.Modify();
        end;

        OnAfterApply(Msg, Parent);
    end;

    local procedure UpdateStatus(var Parent: Record "E-Document"; var Service: Record "E-Document Service"; NewStatus: Enum "E-Document Service Status")
    var
        ServiceStatus: Record "E-Document Service Status";
        Processing: Codeunit "E-Document Processing";
    begin
        if ServiceStatus.Get(Parent."Entry No", Service.Code) then
            Processing.ModifyServiceStatus(Parent, Service, NewStatus)
        else
            Processing.InsertServiceStatus(Parent, Service, NewStatus);
    end;

    local procedure MarkRow(var Msg: Record "E-Document Message"; NewStatus: Enum "E-Doc. Message Status"; ErrorText: Text)
    begin
        Msg.Status := NewStatus;
        Msg."Last Error" := CopyStr(ErrorText, 1, MaxStrLen(Msg."Last Error"));
        Msg.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApply(Msg: Record "E-Document Message"; Parent: Record "E-Document")
    begin
    end;
}
