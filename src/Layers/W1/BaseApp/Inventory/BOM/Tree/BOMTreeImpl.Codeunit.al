// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM.Tree;

codeunit 3683 "BOM Tree Impl."
{
    Access = Internal;

    var
        AllNodes: Codeunit "BOM Tree Node Dictionary";

    procedure AddRelation(Parent: Codeunit "BOM Node"; Child: Codeunit "BOM Node")
    var
        ParentTreeNode: Codeunit "BOM Tree Node";
        ChildTreeNode: Codeunit "BOM Tree Node";
        ParentKey: Text;
        ChildKey: Text;
    begin
        ParentKey := Parent.GetKey();
        if not AllNodes.TryGet(ParentKey, ParentTreeNode) then begin
            ParentTreeNode.Create(Parent);
            AllNodes.Add(ParentTreeNode);
        end;

        ChildKey := Child.GetKey();
        if not AllNodes.TryGet(ChildKey, ChildTreeNode) then begin
            ChildTreeNode.Create(Child);
            AllNodes.Add(ChildTreeNode);
        end;

        ParentTreeNode.AddChild(ChildTreeNode);
    end;

    procedure TraverseDown()
    var
        Node: Codeunit "BOM Tree Node";
    begin
        while AllNodes.MoveNext() do begin
            AllNodes.GetCurrent(Node);
            if Node.GetIsRootNode() then
                Node.TraverseDown();
        end;
        AllNodes.ResetEnumerator();
    end;

    procedure TraverseDown(NodeContent: Codeunit "BOM Node")
    var
        Node: Codeunit "BOM Tree Node";
    begin
        AllNodes.Get(NodeContent.GetKey(), Node);
        Node.TraverseDown();
    end;

    procedure ChildHasKey(ParentKey: Text; ChildKey: Text): Boolean
    var
        ParentNode: Codeunit "BOM Tree Node";
    begin
        if not AllNodes.TryGet(ParentKey, ParentNode) then
            exit(false);

        exit(ParentNode.IsChild(ChildKey));
    end;
}