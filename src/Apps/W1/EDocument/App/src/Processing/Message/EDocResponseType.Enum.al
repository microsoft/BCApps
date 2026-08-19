// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

/// <summary>
/// Human-readable response type carried by an E-Document message (e.g. a PEPPOL Order Response).
/// UNCL4343 OrderResponseCode: AB = Acknowledged, AC = Accepted, RE = Rejected.
/// Extend this enum in a format-specific app to declare additional response types.
/// </summary>
enum 6427 "E-Doc. Response Type"
{
    Extensible = true;

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; Acknowledged)
    {
        Caption = 'Acknowledged';
    }
    value(2; Accepted)
    {
        Caption = 'Accepted';
    }
    value(3; Rejected)
    {
        Caption = 'Rejected';
    }
}
