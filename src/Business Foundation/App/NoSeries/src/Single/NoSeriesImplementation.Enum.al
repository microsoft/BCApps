// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

enum 397 "No. Series Implementation" implements "No. Series - Single"
{
    Access = Public;
    Extensible = true;

    value(0; Normal)
    {
        Caption = 'Normal';
        Implementation = "No. Series - Single" = "No. Series - Stateless Impl.";
    }
    value(1; Sequence)
    {
        Caption = 'Sequence';
        Implementation = "No. Series - Single" = "No. Series - Sequence Impl.";
    }
}