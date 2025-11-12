// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Contract;
using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;
using Microsoft.Service.Item;

codeunit 5955 "Serv. Dimension Management"
{

    // Codeunit DimensionManagement

    [EventSubscriber(ObjectType::Codeunit, Codeunit::DimensionManagement, 'OnAfterSetSourceCode', '', false, false)]
    local procedure DimensionManagementOnAfterSetSourceCodeWithVar(var SourceCodeSetup: Record "Source Code Setup"; var SourceCode: Code[10]; TableID: Integer)
    begin
        if TableID in [Database::"Service Header",
                        Database::"Service Item Line",
                        Database::"Service Line",
                        Database::"Service Contract Header",
                        Database::"Standard Service Line"]
        then
            SourceCode := SourceCodeSetup."Service Management";
    end;

    procedure ServiceLineTypeToTableID(LineType: Enum "Service Line Type") TableId: Integer
    begin
        case LineType of
            LineType::" ":
                exit(0);
            LineType::Item:
                exit(Database::Item);
            LineType::Resource:
                exit(Database::Resource);
            LineType::Cost:
                exit(Database::"Service Cost");
            LineType::"G/L Account":
                exit(Database::"G/L Account");
        end;

        OnAfterServiceLineTypeToTableID(LineType, TableId);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceLineTypeToTableID(LineType: Enum "Service Line Type"; var TableId: Integer)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::DimensionManagement, 'OnAfterDefaultDimObjectNoWithoutGlobalDimsList', '', false, false)]
    local procedure DimensionManagementOnAfterDefaultDimObjectNoWithoutGlobalDimsList(var TempAllObjWithCaption: Record System.Reflection.AllObjWithCaption temporary; sender: Codeunit DimensionManagement)
    begin
        sender.DefaultDimInsertTempObject(TempAllObjWithCaption, Database::"Service Order Type");
        sender.DefaultDimInsertTempObject(TempAllObjWithCaption, Database::"Service Item Group");
        sender.DefaultDimInsertTempObject(TempAllObjWithCaption, Database::"Service Item");
        sender.DefaultDimInsertTempObject(TempAllObjWithCaption, Database::"Service Contract Template");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Default Dimension Priority", 'OnAfterGetDefaultDimTableList', '', false, false)]
    local procedure OnAfterGetDefaultDimTableList(var TempAllObjWithCaption: Record System.Reflection.AllObjWithCaption temporary)
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.InsertObject(TempAllObjWithCaption, Database::"Service Contract Header");
    end;
}
