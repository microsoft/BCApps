// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

using Microsoft.Assembly.Document;
using Microsoft.Warehouse.Tracking;

codeunit 977 "Asm. Whse. Worksheet Line"
{
    [EventSubscriber(ObjectType::Table, Database::"Whse. Worksheet Line", 'OnWhseItemTrackingLinesSetSource', '', false, false)]
    local procedure OnWhseItemTrackingLinesSetSource(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var WhseItemTrackingLines: Page "Whse. Item Tracking Lines"; var IsHandled: Boolean)
    begin
        if WhseWorksheetLine."Whse. Document Type" = WhseWorksheetLine."Whse. Document Type"::Assembly then begin
            WhseItemTrackingLines.SetSource(WhseWorksheetLine, Database::"Assembly Line");
            IsHandled := true;
        end;
    end;
}
