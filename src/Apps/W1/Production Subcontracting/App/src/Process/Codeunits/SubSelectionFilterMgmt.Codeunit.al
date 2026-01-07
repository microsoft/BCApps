// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using System.Text;

codeunit 99001504 "Sub. SelectionFilterMgmt"
{
    var
        SelectionFilterManagement: Codeunit SelectionFilterManagement;

    procedure GetSelectionFilterForWorkCenter(var WorkCenter: Record "Work Center"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(WorkCenter);
        exit(SelectionFilterManagement.GetSelectionFilter(RecRef, WorkCenter.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForStandardTask(var StandardTask: Record "Standard Task"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(StandardTask);
        exit(SelectionFilterManagement.GetSelectionFilter(RecRef, StandardTask.FieldNo(Code)));
    end;
}