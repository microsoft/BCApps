// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM.Tree;

/// <summary>
/// Helps create and traverse data as nodes in a tree. The structure supports disjoint trees as well as multiple parents for a child node.
/// </summary>
codeunit 3682 "BOM Tree"
{
    Access = Public;

    var
        TreeImpl: Codeunit "BOM Tree Impl.";

    /// <summary>
    /// Adds a relation between two nodes connected in a parent- child relationship.
    /// </summary>
    /// <param name="Parent">The node that represents the parent part of the relationship.</param>
    /// <param name="Child">The node that represents the child part of the relationship.</param>
    procedure AddRelation(Parent: Codeunit "BOM Node"; Child: Codeunit "BOM Node")
    begin
        TreeImpl.AddRelation(Parent, Child);
    end;

    /// <summary>
    /// Traverses the nodes starting from the root node and traverses down to the children and so on. Note that there can be many root nodes, in which case, the traversal starts from each of them.
    /// </summary>
    procedure TraverseDown()
    begin
        TreeImpl.TraverseDown();
    end;

    /// <summary>
    /// Traverses the nodes starting from the given node and traverses down to the children and so on. 
    /// </summary>
    /// <param name="Node">The node from which the traversal should start.</param>
    procedure TraverseDown(Node: Codeunit "BOM Node")
    begin
        TreeImpl.TraverseDown(Node);
    end;

    /// <summary>
    /// Finds if a node with the given key is a child of another node with the given parent key.
    /// <param name="ParentKey">The key of the parent node.</param>
    /// <param name="ChildKey">The key of the child node.</param>
    /// <returns>True if there was a child found with the key, false otherwise.</returns>
    /// <remarks>This will return false if the node with the parent key was not found.</remarks>
    /// </summary>
    procedure ChildHasKey(ParentKey: Text; ChildKey: Text): Boolean
    begin
        exit(TreeImpl.ChildHasKey(ParentKey, ChildKey));
    end;
}