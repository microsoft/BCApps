// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

enum 393 "No. Series Cop. Search Method" implements "No. Series Cop. Field Search"
{
    Access = Internal;
    Extensible = false;

    value(1; Keyword)
    {
        Caption = 'Keyword';
        Implementation = "No. Series Cop. Field Search" = "No. Series Keyword Search";
    }
    value(2; Semantic)
    {
        Caption = 'Semantic';
        Implementation = "No. Series Cop. Field Search" = "No. Series Semantic Search";
    }
}
