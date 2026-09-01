// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

codeunit 405 "Update Item Analysis View Bck."
{
    Permissions = TableData "Item Analysis View" = r;
    InherentPermissions = X;

    trigger OnRun()
    var
        ItemAnalysisView: Record "Item Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
    begin
        ItemAnalysisView.SetRange(Blocked, false);
        ItemAnalysisView.SetRange("Update on Posting", true);
        if ItemAnalysisView.IsEmpty() then
            exit;
        UpdateItemAnalysisView.UpdateAll(ItemAnalysisView, 0, true);
    end;
}
