#if not CLEANSCHEMA30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

enum 6185 "EDoc Vendor Matching Scope"
{
    Access = Internal;
    Extensible = false;
#pragma warning disable AS0072 // this change is backported to 27.x
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';
    ObsoleteReason = 'Replaced with experiment-based matching.';
#pragma warning restore AS0072

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