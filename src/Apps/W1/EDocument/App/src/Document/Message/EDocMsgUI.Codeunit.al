// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// UI helper for the "Send Message" flow. Any page that wants to expose Send Message calls
/// "PromptAndSend(ParentEDocument, TriggerSource)". The helper opens the framework's modal
/// lookup populated with applicable Types, resolves the Service from the parent's service status,
/// and dispatches to "E-Doc. Send Message".
/// </summary>
codeunit 6345 "E-Doc. Msg. UI"
{
    Access = Public;

    /// <summary>
    /// Show the modal applicable-message lookup and send the picked one for this parent.
    /// </summary>
    procedure PromptAndSend(var Parent: Record "E-Document"; TriggerSource: Enum "E-Doc. Msg. Trigger Source")
    var
        Service: Record "E-Document Service";
        Send: Codeunit "E-Doc. Send Message";
        Lookup: Page "E-Document Message Lookup";
        Picked: Enum "E-Document Message Type";
        ServiceCode: Code[20];
    begin
        Lookup.Populate(Parent, Parent.Direction::Outgoing, TriggerSource);
        Lookup.LookupMode(true);
        if Lookup.RunModal() <> Action::LookupOK then
            exit;
        Picked := Lookup.GetSelectedMessageType();

        ServiceCode := GetServiceCodeForParent(Parent);
        if ServiceCode = '' then
            Error(NoServiceConfiguredErr);
        if not Service.Get(ServiceCode) then
            Error(ServiceNotFoundErr, ServiceCode);

        Send.Run(Parent, Service, Picked, TriggerSource);
    end;

    local procedure GetServiceCodeForParent(Parent: Record "E-Document"): Code[20]
    var
        ServiceStatus: Record "E-Document Service Status";
    begin
        ServiceStatus.SetRange("E-Document Entry No", Parent."Entry No");
        if ServiceStatus.FindFirst() then
            exit(ServiceStatus."E-Document Service Code");
        exit('');
    end;

    var
        NoServiceConfiguredErr: Label 'No E-Document Service is configured for this document.';
        ServiceNotFoundErr: Label 'E-Document Service %1 not found.', Comment = '%1 = service code';
}
