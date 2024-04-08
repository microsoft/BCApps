// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Excel;

using System;

/// <summary>
/// This codeunit provides an interface to running Edit in Excel for a specific page.
/// </summary>

#if not CLEAN25
#pragma warning disable AL0432
codeunit 1492 "Edit in Excel Fld Filter Impl." implements "Edit in Excel Field Filter", "Edit in Excel Field Filter v2"
#pragma warning restore AL0432
#else
codeunit 1492 "Edit in Excel Fld Filter Impl." implements "Edit in Excel Field Filter v2"
#endif
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        EditInExcelFieldFilter: Codeunit "Edit in Excel Fld Filter Impl.";
        FilterCollectionNode: DotNet FilterCollectionNode;
        ODataFieldName: Text;
        EdmType: Text;

    internal procedure Initialize(NewODataFieldName: Text; NewEdmType: Text; NewFilterCollectionNode: DotNet FilterCollectionNode; NewEditInExcelFieldFilter: Codeunit "Edit in Excel Fld Filter Impl.")
    begin
        FilterCollectionNode := NewFilterCollectionNode;
        EditInExcelFieldFilter := NewEditInExcelFieldFilter;
        ODataFieldName := NewODataFieldName;
        EdmType := NewEdmType;
    end;

#if not CLEAN25
#pragma warning disable AL0432
    [Obsolete('Use AddFilterValueV2 instead, returns interface "Edit in Excel Field Filter" instead which supports getting filter collection type', '25.0')]
    procedure AddFilterValue(EditInExcelFilterType: Enum "Edit in Excel Filter Type"; FilterValue: Text): Interface "Edit in Excel Field Filter"
#pragma warning restore AL0432
    begin
        AddFieldFilterValue(EditInExcelFilterType, FilterValue);
        exit(EditInExcelFieldFilter); // Reference back to self to allow builder pattern
    end;
#endif

    procedure AddFilterValueV2(EditInExcelFilterType: Enum "Edit in Excel Filter Type"; FilterValue: Text): Interface "Edit in Excel Field Filter V2"
    begin
        AddFieldFilterValue(EditInExcelFilterType, FilterValue);
        exit(EditInExcelFieldFilter); // Reference back to self to allow builder pattern
    end;

    procedure Get(Index: Integer; var EditinExcelFilterType: Enum "Edit in Excel Filter Type"; var FilterValue: Text)
    var
        ExcelFilterNodeType: Enum "Excel Filter Node Type";
        FilterBinaryNode: DotNet FilterBinaryNode;
    begin
        FilterBinaryNode := FilterCollectionNode.Collection.Item(Index);
        ExcelFilterNodeType := "Excel Filter Node Type".FromInteger("Excel Filter Node Type".Ordinals().Get("Excel Filter Node Type".Names().IndexOf(FilterBinaryNode.Operator)));
        EditinExcelFilterType := "Edit in Excel Filter Type".FromInteger(ExcelFilterNodeType.AsInteger());
        FilterValue := FilterBinaryNode.Right;
    end;

    procedure Remove(Index: Integer)
    begin
        FilterCollectionNode.Collection.RemoveAt(Index);
    end;

    procedure GetCollectionType(): Enum "Edit in Excel Filter Collection Type"
    var
        TempString: DotNet String;
    begin
        TempString := FilterCollectionNode.Operator();
        if TempString = 'or' then
            exit("Edit in Excel Filter Collection Type"::"or");
        exit("Edit in Excel Filter Collection Type"::"and")
    end;

    procedure Count(): Integer
    begin
        exit(FilterCollectionNode.Collection.Count());
    end;

    local procedure AddFieldFilterValue(EditInExcelFilterType: Enum "Edit in Excel Filter Type"; FilterValue: Text)
    var
        ExcelFilterNodeType: Enum "Excel Filter Node Type";
        FilterBinaryNode: DotNet FilterBinaryNode;
        FilterLeftOperand: DotNet FilterLeftOperand;
    begin
        FilterLeftOperand := FilterLeftOperand.FilterLeftOperand();
        FilterLeftOperand.Field := ODataFieldName;
        FilterLeftOperand.Type := EdmType;

        ExcelFilterNodeType := "Excel Filter Node Type".FromInteger(EditInExcelFilterType.AsInteger()); // Convert from readable "Less Than" to OData "lt"
        FilterBinaryNode := FilterBinaryNode.FilterBinaryNode();
        FilterBinaryNode.Left := FilterLeftOperand;
        FilterBinaryNode.Operator := Format(ExcelFilterNodeType);
        FilterBinaryNode.Right := FilterValue;

        FilterCollectionNode.Collection.Add(FilterBinaryNode);
    end;
}