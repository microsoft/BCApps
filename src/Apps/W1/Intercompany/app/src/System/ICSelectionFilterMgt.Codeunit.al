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
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ICPartner);
        exit(GetSelectionFilterForICPartner(RecRef));
    end;

    local procedure GetSelectionFilterForICPartner(var RecRef: RecordRef): Text
    var
        ICPartner: Record "IC Partner";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        exit(SelectionFilterManagement.GetSelectionFilter(RecRef, ICPartner.FieldNo(Code)));
    end;

#if not CLEAN30 and not CLEANSCHEMA30
#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::SelectionFilterManagement, 'OnGetSelectionFilterForICPartner', '', false, false)]
    local procedure OnGetSelectionFilterForICPartner(var ICPartnerRecRef: RecordRef; var SelectionFilter: Text; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;
        SelectionFilter := GetSelectionFilterForICPartner(ICPartnerRecRef);
        IsHandled := true;
    end;
#pragma warning restore AL0432
#endif
}
