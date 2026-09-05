// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

/// <summary>
/// Operational status of an E-Document payment occurrence.
/// </summary>
enum 6539 "E-Doc. Payment Occ. Status"
{
    Access = Public;
    Extensible = false;

    value(0; Pending)
    {
        Caption = 'Pending';
    }
    value(1; Processed)
    {
        Caption = 'Processed';
    }
    value(2; Error)
    {
        Caption = 'Error';
    }
    value(3; Processing)
    {
        Caption = 'Processing';
    }
}