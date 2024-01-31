// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// Specifies the possible No. Series implementations.
/// </summary>
enum 397 "No. Series Implementation" implements "No. Series - Single"
{
    Access = Public;
    Extensible = true;

    /// <summary>
    /// Specifies the standard No. Series implementation, which updates the database on every call and uses the table to keep state.
    /// </summary>
    value(0; Normal)
    {
        Caption = 'Normal';
        Implementation = "No. Series - Single" = "No. Series - Stateless Impl.";
    }

    /// <summary>
    /// Specifies the sequence No. Series implementation that does not update the database on every call and uses database sequences to keep state.
    /// </summary>
    value(1; Sequence)
    {
        Caption = 'Sequence';
        Implementation = "No. Series - Single" = "No. Series - Sequence Impl.";
    }
}