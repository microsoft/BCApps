// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

/// <summary>
/// Identifies whether an E-Document payment occurrence applies or reverses an amount.
/// </summary>
enum 6115 "E-Doc. Payment Occurrence Type"
{
    Access = Public;
    Extensible = false;

    value(0; Applied)
    {
        Caption = 'Applied';
    }
    value(1; Reversed)
    {
        Caption = 'Reversed';
    }
}