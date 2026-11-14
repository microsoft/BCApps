// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;

interface "Gen. Jnl. Balance Check Provider"
{
    procedure Initialize(GenJournalLine: Record "Gen. Journal Line")

    procedure CollectGLEntry(GLEntry: Record "G/L Entry")

    procedure IsTransactionConsistent(): Boolean
}
