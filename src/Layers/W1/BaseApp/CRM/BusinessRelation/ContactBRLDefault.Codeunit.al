// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.BusinessRelation;

codeunit 5557 "Contact BRL Default" implements "Contact Business Relation Link"
{
    var
        Msg: Label 'No implementation provided for Contact Relation Link', Locked = true;

    procedure GetTableAndSystemId(No: Code[20]; var TableId: Integer; var SystemId: Guid): Boolean
    begin
        TableId := 0;
        SystemId := CreateGuid();
        Error(Msg);
    end;
}
