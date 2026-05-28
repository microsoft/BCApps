// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// What caused an E-Document Message to be generated or to flow inbound. Used as an axis on
/// "IEDocumentMessageType.IsApplicableFor" — auto-fired messages (BC Event) never appear in
/// the user "Send Message" modal; user-only messages never auto-fire on a BC event.
/// </summary>
enum 6117 "E-Doc. Msg. Trigger Source"
{
    Extensible = true;

    value(0; "User Action - E-Doc Page") { Caption = 'User Action - E-Doc Page'; }
    value(1; "User Action - BC Doc Page") { Caption = 'User Action - BC Document Page'; }
    value(2; "BC Event") { Caption = 'BC Event'; }                       // posting, application, release, reversal
    value(3; "External Inbound") { Caption = 'External Inbound'; }
    value(4; "Workflow Internal") { Caption = 'Workflow Internal'; }
}
