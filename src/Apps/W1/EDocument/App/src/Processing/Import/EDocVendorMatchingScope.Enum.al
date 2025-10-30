#if not CLEANSCHEMA31
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

enum 6185 "EDoc Vendor Matching Scope"
{
    Access = Internal;
    Extensible = false;
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';
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
#endif
