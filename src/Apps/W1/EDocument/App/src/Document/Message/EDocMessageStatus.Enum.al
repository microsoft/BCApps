// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// Operational state of an "E-Document Message" row. Distinct from the parent E-Document's
/// user-facing Service Status (which lives on "E-Document Service Status").
/// </summary>
enum 6116 "E-Doc. Message Status"
{
    Extensible = true;

    value(0; "Pending Send") { Caption = 'Pending Send'; }
    value(1; Sent)           { Caption = 'Sent'; }
    value(2; "Send Failed")  { Caption = 'Send Failed'; }
    value(3; Received)       { Caption = 'Received'; }
    value(4; Applied)        { Caption = 'Applied'; }
    value(5; Ignored)        { Caption = 'Ignored'; }
    value(6; "Apply Failed") { Caption = 'Apply Failed'; }
}
