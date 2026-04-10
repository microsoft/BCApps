// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM.Tree;

codeunit 3684 "BOM Tree Node"
{
    Access = Internal;

    var
        ChildNodes: Codeunit "BOM Tree Node Dictionary";
        NodeContent: Codeunit "BOM Node";
        IsRootNode: Boolean;
        RecursiveLoopFoundErr: Label 'A recursive loop was found in the following chain of nodes: %1.', Comment = '%1 = List of text keys that are part of the ancestry';
        KeyListElementTxt: Label '%1, ', Locked = true, Comment = '%1 = the key of the node';

    procedure Create(NewNodeContent: Codeunit "BOM Node")
    begin
        NodeContent := NewNodeContent;
        IsRootNode := true; // by default during creation. Reset when adding this as a child.
    end;

    procedure AddChild(Child: Codeunit "BOM Tree Node")
    begin
        ChildNodes.Add(Child);
        Child.SetNotRootNode();
    end;

    procedure TraverseDown(ParentNodeContent: Codeunit "BOM Node"; LineageKeys: List of [Text])
    var
        CurrentKey: Text;
        KeyList: Text;
        LineageKey: Text;
    begin
        NodeContent.TraversedDown(ParentNodeContent);

        CurrentKey := GetKey();
        if LineageKeys.Contains(CurrentKey) then begin
            foreach LineageKey in LineageKeys do
                KeyList += StrSubstNo(KeyListElementTxt, LineageKey);
            KeyList += CurrentKey;
            Error(RecursiveLoopFoundErr, KeyList);
        end;
        LineageKeys.Add(CurrentKey);
        TraverseChildren(LineageKeys);
        LineageKeys.RemoveAt(LineageKeys.Count());
    end;

    procedure TraverseDown()
    var
        LineageKeys: List of [Text];
    begin
        NodeContent.TraversedDown();

        LineageKeys.Add(GetKey());
        TraverseChildren(LineageKeys);
        LineageKeys.RemoveAt(LineageKeys.Count());
    end;

    local procedure TraverseChildren(LineageKeys: List of [Text])
    var
        Child: Codeunit "BOM Tree Node";
    begin
        ChildNodes.ResetEnumerator();
        while ChildNodes.MoveNext() do begin
            ChildNodes.GetCurrent(Child);
            Child.TraverseDown(NodeContent, LineageKeys);
        end;
    end;

    procedure GetKey(): Text
    begin
        exit(NodeContent.GetKey());
    end;

    procedure GetIsRootNode(): Boolean
    begin
        exit(IsRootNode);
    end;

    procedure SetNotRootNode()
    begin
        IsRootNode := false;
    end;

    procedure IsChild(ChildKey: Text): Boolean
    var
        Child: Codeunit "BOM Tree Node";
    begin
        while ChildNodes.MoveNext() do begin
            ChildNodes.GetCurrent(Child);
            if Child.GetKey() = ChildKey then
                exit(true);
        end;
        ChildNodes.ResetEnumerator();
    end;
}