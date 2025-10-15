// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

#pragma warning disable AL0432
enum 6185 "EDoc Vendor Matching Scope"
{
    Access = Internal;
    Extensible = false;
    ObsoleteState = Pending;
    ObsoleteTag = '27.1';
    ObsoleteReason = 'Replaced with experiment-based matching.';

    value(0; "Same Vendor")
    {
        Caption = 'Same vendor';
    }
    value(2; "Any Vendor")
    {
        Caption = 'Any vendor';
    }
}
#pragma warning restore AL0432