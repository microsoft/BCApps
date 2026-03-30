// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// Specifies whether an e-document is outgoing (sent to a recipient) or incoming (received from a sender).
/// </summary>
enum 6102 "E-Document Direction"
{
    value(0; "Outgoing") { Caption = 'Outgoing'; }
    value(1; "Incoming") { Caption = 'Incoming'; }
}
