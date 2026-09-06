// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using System.Utilities;

codeunit 11333 GenJnlCheckLineNL
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", 'OnAfterCheckGenJnlLine', '', false, false)]
    local procedure OnAfterCheckGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var ErrorMessageMgt: Codeunit "Error Message Management")
    begin
        GenJournalLine.TestField(Description, ErrorInfo.Create());
    end;
}
