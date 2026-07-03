// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Extension that adds the Cartera template type for Spanish legal requirements.
/// </summary>
enumextension 7000100 "CRT Gen. Jnl. Template Type" extends "Gen. Journal Template Type"
{
    /// <summary>
    /// Cartera template type for Spanish bill collections and cash management.
    /// </summary>
    value(12; Cartera)
    {
        Caption = 'Cartera';
    }
}
