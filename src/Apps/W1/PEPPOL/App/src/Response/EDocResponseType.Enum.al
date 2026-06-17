// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.Response;

/// <summary>
/// Human-readable response type carried by an E-Document message (e.g. a PEPPOL Order Response).
/// UNCL4343 OrderResponseCode: AB = Acknowledged, AC = Accepted, RE = Rejected.
/// Extend this enum in a format-specific app to declare additional response types.
/// </summary>
enum 50005 "E-Doc. Response Type"
{
    Extensible = true;

    value(50100; Acknowledged)
    {
        Caption = 'Acknowledged';
    }
    value(50101; Accepted)
    {
        Caption = 'Accepted';
    }
    value(50102; Rejected)
    {
        Caption = 'Rejected';
    }
}
