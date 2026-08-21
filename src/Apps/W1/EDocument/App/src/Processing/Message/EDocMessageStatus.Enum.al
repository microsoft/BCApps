// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

/// <summary>
/// Operational status of an E-Document message record.
/// </summary>
enum 6429 "E-Doc. Message Status"
{
    Extensible = true;

    value(0; Created)
    {
        Caption = 'Created';
    }
    value(1; Sent)
    {
        Caption = 'Sent';
    }
    value(2; Queued)
    {
        Caption = 'Queued';
    }
    value(3; Error)
    {
        Caption = 'Error';
    }
    value(4; Received)
    {
        Caption = 'Received';
    }
    value(5; "Pending Response")
    {
        Caption = 'Pending response';
    }
    value(6; "Response Error")
    {
        Caption = 'Response error';
    }
}
