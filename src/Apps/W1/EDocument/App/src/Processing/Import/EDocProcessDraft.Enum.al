// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument.Processing.Interfaces;

/// <summary>
/// Enum for E-Document Processing
/// </summary>
enum 6107 "E-Doc. Process Draft" implements IProcessStructuredData
{
    Extensible = true;

#if not CLEAN29
    value(0; "Purchase Document")
    {
        Caption = 'Purchase Document';
        Implementation = IProcessStructuredData = "Prepare Purchase E-Doc. Draft";
        ObsoleteState = Pending;
        ObsoleteReason = 'Use "Purchase Invoice" or "Purchase Credit Memo" instead.';
        ObsoleteTag = '29.0';
    }
#endif
    value(1; "Purchase Invoice")
    {
        Caption = 'Purchase Invoice';
        Implementation = IProcessStructuredData = "Prepare Purchase E-Doc. Draft";
    }
    value(2; "Purchase Credit Memo")
    {
        Caption = 'Purchase Credit Memo';
        Implementation = IProcessStructuredData = "EDoc Prepare Cr. Memo Draft";
    }
}
