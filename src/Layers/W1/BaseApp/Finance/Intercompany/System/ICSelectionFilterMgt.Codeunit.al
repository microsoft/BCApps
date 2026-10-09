// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Text;

using Microsoft.Intercompany.Partner;

/// <summary>
/// Extends SelectionFilterManagement with Intercompany-specific selection filter helpers.
/// </summary>
codeunit 8498 "IC Selection Filter Mgt."
{
    /// <summary>
    /// Returns a selection filter string for the given IC Partner record set.
    /// </summary>
    procedure GetSelectionFilterForICPartner(var ICPartner: Record "IC Partner"): Text
    var
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ICPartner);
        exit(SelectionFilterManagement.GetSelectionFilter(RecRef, ICPartner.FieldNo(Code)));
    end;
}
