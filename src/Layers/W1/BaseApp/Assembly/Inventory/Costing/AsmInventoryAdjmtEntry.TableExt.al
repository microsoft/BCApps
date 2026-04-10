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
        SetAssemblyDoc(AssemblyHeader, AssemblyHeader."Item No.");
    end;

    procedure SetPostedAsmOrder(PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
        SetAssemblyDoc(PostedAssemblyHeader, PostedAssemblyHeader."Item No.");
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Inventory Adjmt. Entry (Order)", 'I')]
    local procedure SetAssemblyDoc(AssemblyHeader: Record "Assembly Header"; ItemNo: Code[20])
    begin
        Init();
        "Order Type" := "Order Type"::Assembly;
        "Order No." := AssemblyHeader."No.";
        "Item No." := ItemNo;
        "Cost is Adjusted" := false;
        "Is Finished" := true;
        "Indirect Cost %" := AssemblyHeader."Indirect Cost %";
        GetCostsFromItem(1);
        if not Insert() then;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Inventory Adjmt. Entry (Order)", 'I')]
    local procedure SetAssemblyDoc(PostedAssemblyHeader: Record "Posted Assembly Header"; ItemNo: Code[20])
    begin
        Init();
        "Order Type" := "Order Type"::Assembly;
        "Order No." := PostedAssemblyHeader."Order No.";
        "Item No." := ItemNo;
        "Cost is Adjusted" := false;
        "Is Finished" := true;
        "Indirect Cost %" := PostedAssemblyHeader."Indirect Cost %";
        GetCostsFromItem(1);
        if not Insert() then;
    end;
}