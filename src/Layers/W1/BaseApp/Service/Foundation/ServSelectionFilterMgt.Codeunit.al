// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Text;

using Microsoft.Service.Document;
using Microsoft.Service.Item;

codeunit 6465 "Serv. Selection Filter Mgt."
{
    var
        SelectionFilterMgt: Codeunit SelectionFilterManagement;

    procedure GetSelectionFilterForServiceItem(var ServiceItem: Record "Service Item"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ServiceItem);
        exit(SelectionFilterMgt.GetSelectionFilter(RecRef, ServiceItem.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForServiceHeader(var ServiceHeader: Record "Service Header"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ServiceHeader);
        exit(SelectionFilterMgt.GetSelectionFilter(RecRef, ServiceHeader.FieldNo("No.")));
    end;
}
