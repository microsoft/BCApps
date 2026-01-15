// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Routing;

pageextension 99001500 "Subc. Standard Tasks" extends "Standard Tasks"
{
    procedure GetCurrSelectionFilter(): Text
    var
        StandardTask: Record "Standard Task";
        SubSelectionFilterMgmt: Codeunit "Subc. SelectionFilterMgmt";
    begin
        CurrPage.SetSelectionFilter(StandardTask);
        exit(SubSelectionFilterMgmt.GetSelectionFilterForStandardTask(StandardTask));
    end;
}