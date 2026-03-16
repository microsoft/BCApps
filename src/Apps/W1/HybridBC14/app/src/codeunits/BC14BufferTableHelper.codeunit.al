// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

codeunit 50178 "BC14 Buffer Table Helper"
{
    /// <summary>
    /// Opens any buffer table record for editing using the generic BC14 Buffer Record Editor page.
    /// This approach follows the Integration Table Mapping pattern - one page for all tables.
    /// </summary>
    procedure OpenBufferRecord(SourceTableId: Integer; SourceRecordId: RecordId): Boolean
    var
        BC14BufferRecordEditor: Page "BC14 Buffer Record Editor";
    begin
        if SourceTableId = 0 then
            exit(false);

        if Format(SourceRecordId) = '' then
            exit(false);

        BC14BufferRecordEditor.SetSourceRecord(SourceRecordId);
        BC14BufferRecordEditor.RunModal();
        exit(true);
    end;
}
