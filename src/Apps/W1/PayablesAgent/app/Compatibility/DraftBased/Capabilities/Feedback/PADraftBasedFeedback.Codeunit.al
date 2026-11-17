// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

// The draft page's feedback context discriminator is a legacy UI protocol, not a shared task identity.
codeunit 3346 "PA Draft Based Feedback"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure IsDraftPageFeedbackContext(Context: Dictionary of [Text, Text]): Boolean
    begin
        if not (Context.ContainsKey('FormName') and Context.ContainsKey('Copilot.Feedback.Target')) then
            exit(false);
        exit(Context.Get('FormName') = 'E-Document Purchase Draft');
    end;
}
