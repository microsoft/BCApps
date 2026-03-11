#if not CLEANSCHEMA30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

enum 6177 "EDoc Line Matching Scope"
{
    Access = Internal;
    Extensible = false;
#pragma warning disable AS0072 // this change is backported to 27.x
    ObsoleteTag = '27.0';
    ObsoleteReason = 'Replaced with experiment-based matching.';
    ObsoleteState = Pending;
#pragma warning restore AS0072

    value(0; "Same Product Description")
    {
        Caption = 'Same product description';
    }
    value(1; "Similar Product Descriptions")
    {
        Caption = 'Similar product descriptions';
    }
}
#endif