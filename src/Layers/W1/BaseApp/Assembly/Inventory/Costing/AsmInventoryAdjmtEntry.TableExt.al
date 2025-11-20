// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;


tableextension 990 "Asm. Inventory Adjmt. Entry" extends "Inventory Adjmt. Entry (Order)"
{
    procedure SetAsmOrder(AssemblyHeader: Record "Assembly Header")
    begin
        SetAssemblyDoc(AssemblyHeader."No.", AssemblyHeader."Item No.");
    end;

    procedure SetPostedAsmOrder(PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
        SetAssemblyDoc(PostedAssemblyHeader."Order No.", PostedAssemblyHeader."Item No.");
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Inventory Adjmt. Entry (Order)", 'I')]
    local procedure SetAssemblyDoc(OrderNo: Code[20]; ItemNo: Code[20])
    begin
        Init();
        "Order Type" := "Order Type"::Assembly;
        "Order No." := OrderNo;
        "Item No." := ItemNo;
        "Cost is Adjusted" := false;
        "Is Finished" := true;
        GetCostsFromItem(1);
        if not Insert() then;
    end;
}