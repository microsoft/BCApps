// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Vendor;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Integration.Manufacturing.Routing;
using Microsoft.Sales.Customer;
using Microsoft.Warehouse.Structure;
using System.IO;
using System.Reflection;
using System.Utilities;

/// <summary>
/// This codeunit contains helper methods to assist with filtering.
/// </summary>
codeunit 20403 "Qlty. Filter Helpers"
{
    EventSubscriberInstance = Manual;

    var
        SearchingForSpecificItemForItemAttributeManagementEventBinding: Code[20];
        ItemAttributeFilterSimulatorTok: Label '"%1"=Filter(%2)', Locked = true, Comment = '%1=the attribute, %2=the attribute value';
        FilterTok: Label 'Filter', Locked = true;

    internal procedure BuildFilter(TableNo: Integer; IncludeWhereText: Boolean; var Value: Text) Result: Boolean
    var
        AllObjWithCaption: Record AllObjWithCaption;
        FilterPageBuilderToCreateFilters: FilterPageBuilder;
        Filter: Text;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::TableData);
        AllObjWithCaption.SetRange("Object ID", TableNo);
        if AllObjWithCaption.FindFirst() then
            Filter := AllObjWithCaption."Object Caption"
        else
            Filter := FilterTok;

        FilterPageBuilderToCreateFilters.AddTable(Filter, TableNo);
        if Value <> '' then
            FilterPageBuilderToCreateFilters.SetView(Filter, Value);

        if FilterPageBuilderToCreateFilters.RunModal() then begin
            Value := FilterPageBuilderToCreateFilters.GetView(Filter);
            if Value <> '' then
                Value := CleanUpWhereClause(Value);

            Result := true;
        end;
    end;

    /// <summary>
    /// Opens a table lookup dialog filtered by specified object IDs.
    /// Allows users to select from available tables matching the filter criteria.
    /// 
    /// Behavior:
    /// - Filters to Table objects only (no pages, codeunits, etc.)
    /// - Applies ObjectIdFilter to restrict available tables
    /// - Opens Objects page in lookup mode
    /// - Updates ObjectID parameter with selected table if user confirms
    /// 
    /// Common usage: Template configuration, field mapping setup, filter builders.
    /// </summary>
    /// <param name="ObjectID">Input/Output: Current table ID; updated with selected table ID</param>
    /// <param name="ObjectIdFilter">Filter expression to limit table choices (e.g., "50000..99999" for custom tables)</param>
    internal procedure RunModalLookupTable(var ObjectID: Integer; ObjectIdFilter: Text)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        Objects: Page Objects;
    begin
        AllObjWithCaption.FilterGroup(2);
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetFilter("Object ID", ObjectIdFilter);
        AllObjWithCaption.FilterGroup(0);
        Objects.SetTableView(AllObjWithCaption);
        Objects.LookupMode := true;
        if Objects.RunModal() = Action::LookupOK then begin
            Objects.GetRecord(AllObjWithCaption);
            ObjectID := AllObjWithCaption."Object ID";
        end;
    end;

    /// <summary>
    /// Opens a table lookup dialog and returns the selected table name as text.
    /// Converts between text table reference and numeric table ID internally.
    /// 
    /// Input handling:
    /// - If TableReference is empty → shows all tables
    /// - If TableReference contains text/number → attempts to identify and pre-select that table
    /// 
    /// Output:
    /// - Updates TableReference with the Object Name (not caption) of selected table
    /// - If user cancels or no table found, TableReference remains unchanged
    /// 
    /// Common usage: User-friendly table selection where table name is stored as text rather than ID.
    /// </summary>
    /// <param name="TableReference">Input/Output: Table name or ID as text; updated with selected table's Object Name</param>
    internal procedure RunModalLookupTableFromText(var TableReference: Text)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ConfigValidateManagement: Codeunit "Config. Validate Management";
        TableNumber: Integer;
    begin
        if TableReference <> '' then
            TableNumber := IdentifyTableIDFromText(TableReference);

        ConfigValidateManagement.LookupTable(TableNumber);
        if TableNumber <> 0 then begin
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
            AllObjWithCaption.SetRange("Object ID", TableNumber);
            AllObjWithCaption.FindFirst();
            TableReference := AllObjWithCaption."Object Name";
        end;
    end;

    /// <summary>
    /// Opens a field lookup dialog for a specified table and returns the selected field name as text.
    /// Handles table identification automatically if table reference is unclear.
    /// 
    /// Workflow:
    /// 1. If TableReference is blank → prompts user to select a table first
    /// 2. Identifies table ID from TableReference (name or number)
    /// 3. Opens field lookup for that table
    /// 4. Updates FieldReference with selected field number as text
    /// 
    /// Note: Returns field number as text (not field name) for consistent referencing.
    /// If user cancels at any step, both parameters remain unchanged.
    /// 
    /// Common usage: Template configuration where both table and field need to be selected dynamically.
    /// </summary>
    /// <param name="TableReference">Input/Output: Table name or ID; prompts for table if blank</param>
    /// <param name="FieldReference">Output: Selected field number as text (e.g., "10" for field 10)</param>
    internal procedure RunModalLookupFieldFromText(var TableReference: Text; var FieldReference: Text)
    var
        CurrentTable: Integer;
        CurrentField: Integer;
    begin
        CurrentTable := IdentifyTableIDFromText(TableReference);
        if CurrentTable = 0 then
            RunModalLookupTableFromText(TableReference);

        if CurrentTable = 0 then
            exit;

        CurrentField := RunModalLookupAnyField(CurrentTable, 0, '');
        if CurrentField <> 0 then begin
            FieldReference := Format(CurrentField, 0, 9);
            CurrentField := IdentifyFieldIDFromText(CurrentTable, FieldReference);
        end;
    end;

    /// <summary>
    /// Resolves a text representation of a table to its numeric table ID.
    /// Handles both numeric IDs and table names/captions with intelligent fallback logic.
    /// 
    /// Resolution logic:
    /// 1. If CurrentTable is numeric → returns that number directly
    /// 2. If CurrentTable is text → searches by Object Name first
    /// 3. If not found by name → searches by Object Caption
    /// 4. If still not found → returns 0 (no error thrown)
    /// 
    /// On successful resolution:
    /// - CurrentTable parameter is updated to the canonical Object Name
    /// - Return value contains the table ID
    /// 
    /// Common usage: Converting user-friendly table references to IDs for RecordRef operations.
    /// </summary>
    /// <param name="CurrentTable">Input/Output: Table reference as text; updated to Object Name if found</param>
    /// <returns>The table ID if found; 0 if table cannot be identified</returns>
    internal procedure IdentifyTableIDFromText(var CurrentTable: Text) ResultTableID: Integer
    var
        TablesAllObjWithCaption: Record AllObjWithCaption;
    begin
        if CurrentTable = '' then
            exit;

        TablesAllObjWithCaption.SetRange("Object Type", TablesAllObjWithCaption."Object Type"::Table);
        if not Evaluate(ResultTableID, CurrentTable) then begin
            TablesAllObjWithCaption.SetRange("Object Caption");
            TablesAllObjWithCaption.SetRange("Object Name", CopyStr(CurrentTable, 1, MaxStrLen(TablesAllObjWithCaption."Object Name")));
            if TablesAllObjWithCaption.FindFirst() then begin
                ResultTableID := TablesAllObjWithCaption."Object ID";
                CurrentTable := TablesAllObjWithCaption."Object Name";
            end else begin
                TablesAllObjWithCaption.SetRange("Object Caption");
                TablesAllObjWithCaption.SetFilter("Object Name", StrSubstNo('@%1', CopyStr(CurrentTable, 1, MaxStrLen(TablesAllObjWithCaption."Object Name"))));
                if TablesAllObjWithCaption.FindFirst() then begin
                    ResultTableID := TablesAllObjWithCaption."Object ID";
                    CurrentTable := TablesAllObjWithCaption."Object Name";
                end else begin
                    TablesAllObjWithCaption.SetRange("Object Name");
                    TablesAllObjWithCaption.SetRange("Object Caption", CopyStr(CurrentTable, 1, MaxStrLen(TablesAllObjWithCaption."Object Caption")));
                    if TablesAllObjWithCaption.FindFirst() then begin
                        ResultTableID := TablesAllObjWithCaption."Object ID";
                        CurrentTable := TablesAllObjWithCaption."Object Name";
                    end else begin
                        TablesAllObjWithCaption.SetRange("Object Name");
                        TablesAllObjWithCaption.SetFilter("Object Caption", StrSubstNo('@%1', CopyStr(CurrentTable, 1, MaxStrLen(TablesAllObjWithCaption."Object Name"))));
                        if TablesAllObjWithCaption.FindFirst() then begin
                            ResultTableID := TablesAllObjWithCaption."Object ID";
                            CurrentTable := TablesAllObjWithCaption."Object Name";
                        end;
                    end;
                end;
            end;
        end;
        if ResultTableID = 0 then begin
            TablesAllObjWithCaption.SetRange("Object Caption");
            TablesAllObjWithCaption.SetFilter("Object Name", StrSubstNo('@*%1*', CopyStr(CurrentTable, 1, MaxStrLen(TablesAllObjWithCaption."Object Name"))));
            if TablesAllObjWithCaption.Count() = 1 then begin
                TablesAllObjWithCaption.FindFirst();
                ResultTableID := TablesAllObjWithCaption."Object ID";
                CurrentTable := TablesAllObjWithCaption."Object Name";
            end else begin
                TablesAllObjWithCaption.SetRange("Object Name");
                TablesAllObjWithCaption.SetFilter("Object Caption", StrSubstNo('@*%1*', CopyStr(CurrentTable, 1, MaxStrLen(TablesAllObjWithCaption."Object Name"))));
                if TablesAllObjWithCaption.Count() = 1 then begin
                    TablesAllObjWithCaption.FindFirst();
                    ResultTableID := TablesAllObjWithCaption."Object ID";
                    CurrentTable := TablesAllObjWithCaption."Object Name";
                end;
            end;
        end;
    end;

    /// <summary>
    /// Will return an field number of the field.
    /// If it's a number it presumes the text is just a number and the field id.
    /// If it's text then it will search first for field name, then afterwards field caption.
    /// If neither can be found 0 will be returned, no error will be thrown.
    /// </summary>
    /// <param name="CurrentTable">The table.</param>
    /// <param name="NumberOrNameOfField">Will be the field name as an output if found. If unfound will be left unaltered.</param>
    /// <returns></returns>
    internal procedure IdentifyFieldIDFromText(CurrentTable: Integer; var NumberOrNameOfField: Text) ResultFieldNo: Integer
    var
        ToFindField: Record Field;
    begin
        if (CurrentTable = 0) or (NumberOrNameOfField = '') then
            exit;

        ToFindField.SetRange(TableNo, CurrentTable);
        if Evaluate(ResultFieldNo, NumberOrNameOfField) then begin
            ToFindField.SetRange("No.", ResultFieldNo);
            if ToFindField.FindFirst() then begin
                ResultFieldNo := ToFindField."No.";
                NumberOrNameOfField := ToFindField.FieldName;
            end;
        end;
        if ResultFieldNo = 0 then begin
            ToFindField.SetRange("Field Caption");
            ToFindField.SetRange(FieldName, CopyStr(NumberOrNameOfField, 1, MaxStrLen(ToFindField.FieldName)));
            if ToFindField.FindFirst() then begin
                ResultFieldNo := ToFindField."No.";
                NumberOrNameOfField := ToFindField.FieldName;
            end else begin
                ToFindField.SetRange("Field Caption");
                ToFindField.SetFilter(FieldName, StrSubstNo('@%1', CopyStr(NumberOrNameOfField, 1, MaxStrLen(ToFindField.FieldName))));
                if ToFindField.FindFirst() then begin
                    ToFindField.SetRange(FieldName);
                    ToFindField.SetRange("Field Caption", CopyStr(NumberOrNameOfField, 1, MaxStrLen(ToFindField."Field Caption")));
                    if ToFindField.FindFirst() then begin
                        ResultFieldNo := ToFindField."No.";
                        NumberOrNameOfField := ToFindField.FieldName;
                    end else begin
                        ToFindField.SetRange(FieldName);
                        ToFindField.SetFilter("Field Caption", StrSubstNo('@%1', CopyStr(NumberOrNameOfField, 1, MaxStrLen(ToFindField.FieldName))));
                        if ToFindField.Count() = 1 then begin
                            ToFindField.FindFirst();
                            ResultFieldNo := ToFindField."No.";
                            NumberOrNameOfField := ToFindField.FieldName;
                        end;
                    end;
                end;
            end;
        end;
        if ResultFieldNo = 0 then begin
            ToFindField.SetRange("Field Caption");
            ToFindField.SetFilter(FieldName, StrSubstNo('@*%1*', CopyStr(NumberOrNameOfField, 1, MaxStrLen(ToFindField.FieldName))));
            if ToFindField.Count() = 1 then begin
                ToFindField.FindFirst();
                ResultFieldNo := ToFindField."No.";
                NumberOrNameOfField := ToFindField.FieldName;
            end else begin
                ToFindField.SetRange(FieldName);
                ToFindField.SetFilter("Field Caption", StrSubstNo('@*%1*', CopyStr(NumberOrNameOfField, 1, MaxStrLen(ToFindField.FieldName))));
                if ToFindField.Count() = 1 then begin
                    ToFindField.FindFirst();
                    ResultFieldNo := ToFindField."No.";
                    NumberOrNameOfField := ToFindField.FieldName;
                end;
            end;
        end;
    end;

    /// <summary>
    /// This function exists to get expression evaluator and other expressions to work.
    ///
    /// Input:   FieldA=3,FieldB=4,FieldC=cow
    /// Output:  Where( FieldA=const(3), FieldB=const(4), FieldC=const(5) )
    /// 
    ///  **** Bad data is ignored intentionally *** 
    /// </summary>
    /// <param name="RecordRef"></param>
    /// <param name="ExpressionConditionalFilterSyntax"></param>
    /// <returns></returns>
    internal procedure SetFiltersByExpressionSyntax(var RecordRef: RecordRef; ExpressionConditionalFilterSyntax: Text)
    var
        FieldRefToSetRangeFilter: FieldRef;
        OfFields: List of [Text];
        FieldExpression: Text;
        KeyValue: List of [Text];
        FieldNo: Integer;
        HopefullyAField: Text;
    begin
        OfFields := ExpressionConditionalFilterSyntax.Split(',');
        foreach FieldExpression in OfFields do begin
            KeyValue := FieldExpression.Split('=');
            if KeyValue.Count() = 2 then begin
                HopefullyAField := KeyValue.Get(1);
                FieldNo := IdentifyFieldIDFromText(RecordRef.Number(), HopefullyAField);
                if FieldNo > 0 then begin
                    FieldRefToSetRangeFilter := RecordRef.Field(FieldNo);
                    FieldRefToSetRangeFilter.SetRange(KeyValue.Get(2));
                end;
            end;
        end;
    end;

    /// <summary>
    /// Look up any field.
    /// </summary>
    /// <param name="TableNo"></param>
    /// <param name="OptionalTypeFilter">Use -1 to indicate 'any' type.</param>
    /// <returns>-1 if no field selected. </returns>
    internal procedure RunModalLookupAnyField(TableNo: Integer; OptionalTypeFilter: Integer; OptionalNameFilter: Text): Integer
    var
        CurrentField: Record Field;
        FieldSelection: Codeunit "Field Selection";
    begin
        if TableNo = 0 then
            exit;

        CurrentField.SetRange(TableNo, TableNo);
        if OptionalTypeFilter >= 0 then
            if OptionalTypeFilter in [CurrentField.Type::Integer, CurrentField.Type::Option] then
                CurrentField.SetFilter(Type, '%1|%2', CurrentField.Type::Integer, CurrentField.Type::Option)
            else
                if OptionalTypeFilter in [CurrentField.Type::Code, CurrentField.Type::Text] then
                    CurrentField.SetFilter(Type, '%1|%2', CurrentField.Type::Code, CurrentField.Type::Text)
                else
                    CurrentField.SetRange(Type, OptionalTypeFilter);

        if OptionalNameFilter <> '' then
            CurrentField.SetFilter(FieldName, OptionalNameFilter);

        CurrentField.SetFilter(Class, '%1|%2', CurrentField.Class::Normal, CurrentField.Class::FlowField);

        if FieldSelection.Open(CurrentField) then
            exit(CurrentField."No.")
        else
            exit(-1);
    end;

    /// <summary>
    /// Starts the assist edit dialog for choosing a zone.
    /// </summary>
    /// <param name="LocationFilter"></param>
    /// <param name="ToZoneCodeFilter"></param>
    /// <returns></returns>
    internal procedure AssistEditZone(LocationFilter: Code[20]; var ToZoneCodeFilter: Code[20]): Boolean
    var
        Zone: Record "Zone";
        ZoneList: Page "Zone List";
    begin
        ZoneList.LookupMode(true);
        if LocationFilter <> '' then
            Zone.SetFilter("Location Code", LocationFilter);

        if ToZoneCodeFilter <> '' then begin
            Zone.SetFilter(Code, ToZoneCodeFilter);
            if Zone.FindSet() then
                ZoneList.SetRecord(Zone);

            Zone.SetRange(Code);
        end;

        ZoneList.SetTableView(Zone);

        if ZoneList.RunModal() in [Action::LookupOK, Action::OK] then begin
            ZoneList.GetRecord(Zone);
            ToZoneCodeFilter := Zone.Code;
            exit(true);
        end;
    end;

    internal procedure AssistEditBin(LocationFilter: Code[20]; ToZoneFilter: Code[20]; var ToBinCodeFilter: Code[20]): Boolean
    var
        Bin: Record "Bin";
        BinList: Page "Bin List";
    begin
        BinList.LookupMode(true);

        if LocationFilter <> '' then
            Bin.SetFilter("Location Code", LocationFilter);
        if ToZoneFilter <> '' then
            Bin.SetFilter("Zone Code", ToZoneFilter);
        if ToBinCodeFilter <> '' then begin
            Bin.SetFilter(Code, ToBinCodeFilter);
            if Bin.FindSet() then
                BinList.SetRecord(Bin);
            Bin.SetRange(Code);
        end;

        BinList.SetTableView(Bin);
        if BinList.RunModal() in [Action::LookupOK, Action::OK] then begin
            BinList.GetRecord(Bin);
            ToBinCodeFilter := Bin.Code;
            exit(true);
        end;
    end;

    internal procedure AssistEditItemNo(var ItemNoFilter: Code[20]): Boolean
    var
        Item: Record "Item";
        ItemList: Page "Item List";
    begin
        ItemList.LookupMode(true);
        if ItemNoFilter <> '' then begin
            Item.SetFilter("No.", ItemNoFilter);
            if Item.FindSet() then
                ItemList.SetRecord(Item);
        end;
        Item.SetRange("No.");

        if ItemList.RunModal() in [Action::LookupOK, Action::OK] then begin
            ItemList.GetRecord(Item);
            ItemNoFilter := Item."No.";
            exit(true);
        end;
    end;

    /// <summary>
    /// Starts the assist edit dialog for choosing an item category.
    /// </summary>
    /// <param name="ItemCategoryCodeFilter"></param>
    /// <returns></returns>
    internal procedure AssistEditItemCategory(var ItemCategoryCodeFilter: Code[20]): Boolean
    var
        ItemCategory: Record "Item Category";
        ItemCategories: Page "Item Categories";
    begin
        ItemCategories.LookupMode(true);
        if ItemCategoryCodeFilter <> '' then begin
            ItemCategory.SetFilter(Code, ItemCategoryCodeFilter);
            if ItemCategory.FindSet() then
                ItemCategories.SetRecord(ItemCategory);
        end;
        ItemCategory.SetRange(Code);

        if ItemCategories.RunModal() in [Action::LookupOK, Action::OK] then begin
            ItemCategories.GetRecord(ItemCategory);
            ItemCategoryCodeFilter := ItemCategory.Code;
            exit(true)
        end;
    end;

    internal procedure AssistEditInventoryPostingGroup(var InventoryPostingGroupCode: Code[20]): Boolean
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
        InventoryPostingGroups: Page "Inventory Posting Groups";
    begin
        InventoryPostingGroups.LookupMode(true);
        if InventoryPostingGroupCode <> '' then begin
            InventoryPostingGroup.SetFilter(Code, InventoryPostingGroupCode);
            if InventoryPostingGroup.FindSet() then
                InventoryPostingGroups.SetRecord(InventoryPostingGroup);
        end;
        InventoryPostingGroup.SetRange(Code);

        if InventoryPostingGroups.RunModal() in [Action::LookupOK, Action::OK] then begin
            InventoryPostingGroups.GetRecord(InventoryPostingGroup);
            InventoryPostingGroupCode := InventoryPostingGroup.Code;
            exit(true);
        end;
    end;

    /// <summary>
    /// Starts the assist edit dialog for choosing a vendor.
    /// </summary>
    /// <param name="VendorNoFilter"></param>
    /// <returns></returns>
    internal procedure AssistEditVendor(var VendorNoFilter: Code[20]): Boolean
    var
        Vendor: Record Vendor;
        VendorList: Page "Vendor List";
    begin
        VendorList.LookupMode(true);
        if VendorNoFilter <> '' then begin
            Vendor.SetFilter("No.", VendorNoFilter);
            if Vendor.FindSet() then
                VendorList.SetRecord(Vendor);
        end;
        Vendor.SetRange("No.");

        if VendorList.RunModal() in [Action::LookupOK, Action::OK] then begin
            VendorList.GetRecord(Vendor);
            VendorNoFilter := Vendor."No.";
            exit(true);
        end;
    end;

    /// <summary>
    /// Starts the assist edit dialog for choosing a customer.
    /// </summary>
    /// <param name="CustomerNoFilter"></param>
    /// <returns></returns>
    internal procedure AssistEditCustomer(var CustomerNoFilter: Code[20]): Boolean
    var
        Customer: Record Customer;
        CustomerList: Page "Customer List";
    begin
        CustomerList.LookupMode(true);
        if CustomerNoFilter <> '' then begin
            Customer.SetFilter("No.", CustomerNoFilter);
            if Customer.FindSet() then
                CustomerList.SetRecord(Customer);
        end;
        Customer.SetRange("No.");

        if CustomerList.RunModal() in [Action::LookupOK, Action::OK] then begin
            CustomerList.GetRecord(Customer);
            CustomerNoFilter := Customer."No.";
            exit(true);
        end;
    end;

    /// <summary>
    /// Starts the assist edit dialog for choosing a machine.
    /// </summary>
    /// <param name="MachineNoFilter"></param>
    /// <returns></returns>
    internal procedure AssistEditMachine(var MachineNoFilter: Code[20]): Boolean
    var
        MachineCenter: Record "Machine Center";
        MachineCenterList: Page "Machine Center List";
    begin
        MachineCenterList.LookupMode(true);
        if MachineNoFilter <> '' then begin
            MachineCenter.SetFilter("No.", MachineNoFilter);
            if MachineCenter.FindSet() then
                MachineCenterList.SetRecord(MachineCenter);
        end;
        MachineCenter.SetRange("No.");

        if MachineCenterList.RunModal() in [Action::LookupOK, Action::OK] then begin
            MachineCenterList.GetRecord(MachineCenter);
            MachineNoFilter := MachineCenter."No.";
            exit(true);
        end;
    end;

    /// <summary>
    /// Starts the assist edit dialog for choosing a routing.
    /// </summary>
    /// <param name="RoutingNoFilter"></param>
    /// <returns></returns>
    internal procedure AssistEditRouting(var RoutingNoFilter: Code[20]): Boolean
    var
        RoutingHeader: Record "Routing Header";
        RoutingList: Page "Routing List";
    begin
        RoutingList.LookupMode(true);
        if RoutingNoFilter <> '' then begin
            RoutingHeader.SetFilter("No.", RoutingNoFilter);
            if RoutingHeader.FindSet() then
                RoutingList.SetRecord(RoutingHeader);
        end;
        RoutingHeader.SetRange("No.");

        if RoutingList.RunModal() in [Action::LookupOK, Action::OK] then begin
            RoutingList.GetRecord(RoutingHeader);
            RoutingNoFilter := RoutingHeader."No.";
            exit(true);
        end;
    end;

    internal procedure AssistEditRoutingOperation(InRoutingNoFilter: Code[20]; var OperationNoFilter: Code[20]): Boolean
    var
        RoutingLine: Record "Routing Line";
        QltyRoutingLineLookup: Page "Qlty. Routing Line Lookup";

    begin
        QltyRoutingLineLookup.LookupMode(true);

        if InRoutingNoFilter <> '' then
            RoutingLine.SetFilter("Routing No.", InRoutingNoFilter);

        if OperationNoFilter <> '' then begin
            RoutingLine.SetFilter("Operation No.", OperationNoFilter);
            if RoutingLine.FindSet() then
                QltyRoutingLineLookup.SetRecord(RoutingLine);
            RoutingLine.SetRange("Operation No.");
        end;

        QltyRoutingLineLookup.SetTableView(RoutingLine);

        if QltyRoutingLineLookup.RunModal() in [Action::LookupOK, Action::OK] then begin
            QltyRoutingLineLookup.GetRecord(RoutingLine);
            OperationNoFilter := RoutingLine."Operation No.";
            exit(true);
        end;
    end;

    internal procedure AssistEditWorkCenter(var RoutingNoFilter: Code[20]): Boolean
    var
        WorkCenter: Record "Work Center";
        WorkCenterList: Page "Work Center List";
    begin
        WorkCenterList.LookupMode(true);
        if RoutingNoFilter <> '' then begin
            WorkCenter.SetFilter("No.", RoutingNoFilter);
            if WorkCenter.FindSet() then
                WorkCenterList.SetRecord(WorkCenter);
        end;
        WorkCenter.SetRange("No.");

        if WorkCenterList.RunModal() in [Action::LookupOK, Action::OK] then begin
            WorkCenterList.GetRecord(WorkCenter);
            RoutingNoFilter := WorkCenter."No.";
            exit(true);
        end;
    end;

    internal procedure AssistEditPurchasingCode(var PurchasingCode: Code[20]): Boolean
    var
        Purchasing: Record Purchasing;
        ListPurchasingCodes: Page "Purchasing Codes";
    begin
        ListPurchasingCodes.LookupMode(true);
        if PurchasingCode <> '' then begin
            Purchasing.SetFilter(Code, PurchasingCode);
            if Purchasing.FindSet() then
                ListPurchasingCodes.SetRecord(Purchasing);
        end;
        Purchasing.SetRange(Code);

        if ListPurchasingCodes.RunModal() in [Action::LookupOK, Action::OK] then begin
            ListPurchasingCodes.GetRecord(Purchasing);
            PurchasingCode := Purchasing.Code;
            exit(true);
        end;
    end;

    internal procedure AssistEditReturnReasonCode(var ReturnReasonCode: Code[20]): Boolean
    var
        ReturnReason: Record "Return Reason";
        ReturnReasons: Page "Return Reasons";
    begin
        ReturnReasons.LookupMode(true);
        if ReturnReasonCode <> '' then begin
            ReturnReason.SetFilter(Code, ReturnReasonCode);
            if ReturnReason.FindSet() then
                ReturnReasons.SetRecord(ReturnReason);
        end;
        ReturnReason.SetRange(Code);

        if ReturnReasons.RunModal() in [Action::LookupOK, Action::OK] then begin
            ReturnReasons.GetRecord(ReturnReason);
            ReturnReasonCode := ReturnReason.Code;
            exit(true);
        end;
    end;

    internal procedure AssistEditQltyInspectionTemplate(var QltyInspectionTemplateCode: Code[20]): Boolean
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateList: Page "Qlty. Inspection Template List";
    begin
        QltyInspectionTemplateList.LookupMode(true);
        if QltyInspectionTemplateCode <> '' then begin
            QltyInspectionTemplateHdr.SetFilter(Code, QltyInspectionTemplateCode);
            if QltyInspectionTemplateHdr.FindSet() then
                QltyInspectionTemplateList.SetRecord(QltyInspectionTemplateHdr);
        end;
        QltyInspectionTemplateHdr.SetRange(Code);

        if QltyInspectionTemplateList.RunModal() in [Action::LookupOK, Action::OK] then begin
            QltyInspectionTemplateList.GetRecord(QltyInspectionTemplateHdr);
            QltyInspectionTemplateCode := QltyInspectionTemplateHdr.Code;
            exit(true);
        end;
    end;

    internal procedure AssistEditLocation(var LocationCodeFilter: Code[20]): Boolean
    var
        Location: Record Location;
        LocationList: Page "Location List";
    begin
        LocationList.LookupMode(true);
        if LocationCodeFilter <> '' then begin
            Location.SetFilter(Code, LocationCodeFilter);
            if Location.FindSet() then
                LocationList.SetRecord(Location);
        end;

        Location.SetRange(Code);

        if LocationList.RunModal() in [Action::LookupOK, Action::OK] then begin
            LocationCodeFilter := CopyStr(LocationList.GetSelectionFilter(), 1, MaxStrLen(LocationCodeFilter));
            exit(true);
        end;
    end;

    internal procedure AssistEditUnitOfMeasure(var UnitOfMeasureCode: Code[10]): Boolean
    var
        UnitOfMeasure: Record "Unit of Measure";
        UnitsOfMeasure: Page "Units of Measure";
    begin
        UnitsOfMeasure.LookupMode(true);
        if UnitOfMeasureCode <> '' then begin
            UnitOfMeasure.SetFilter(Code, UnitOfMeasureCode);
            if UnitOfMeasure.FindSet() then
                UnitsOfMeasure.SetRecord(UnitOfMeasure);
        end;

        UnitOfMeasure.SetRange(Code);

        if UnitsOfMeasure.RunModal() in [Action::LookupOK, Action::OK] then begin
            UnitsOfMeasure.GetRecord(UnitOfMeasure);
            UnitOfMeasureCode := UnitOfMeasure.Code;
            exit(true);
        end;
    end;

    internal procedure CleanUpWhereClause2048(Input: Text) ResultText: Text[2048]
    begin
        ResultText := CopyStr(CleanUpWhereClause(Input), 1, MaxStrLen(ResultText));
    end;

    internal procedure CleanUpWhereClause(Input: Text) ResultText: Text
    var
        FindWhere: Integer;
    begin
        Clear(FindWhere);
        ResultText := Input;
        if ResultText <> '' then begin
            FindWhere := StrPos(ResultText, 'WHERE');
            if FindWhere >= 1 then
                ResultText := CopyStr(ResultText, FindWhere)
            else
                ResultText := '';
        end;
    end;

    /// <summary>
    /// De-serializes an existing attribute filter text into an attribute filter buffer.
    /// </summary>
    /// <param name="AttributeFilter">A=Filter(B),C=Filter(D),E=Filter(F)</param>
    /// <param name="TempFilterItemAttributesBuffer"></param>
    internal procedure DeserializeFilterIntoItemAttributesBuffer(AttributeFilter: Text; var TempFilterItemAttributesBuffer: Record "Filter Item Attributes Buffer" temporary)
    var
        TempRegexMatches: Record Matches temporary;
        TempRegexGroups: Record Groups temporary;
        Regex: Codeunit Regex;
        Filters: List of [Text];
        Filter: Text;
    begin
        Filters := AttributeFilter.Split(',');
        foreach Filter in Filters do begin
            Regex.Match(Filter, '""?([A-Za-z0-9 ]+)""?=Filter\(([^()]+)\)', TempRegexMatches);
            if TempRegexMatches.Count() = 1 then begin
                Regex.Groups(TempRegexMatches, TempRegexGroups);
                if TempRegexGroups.Count() = 3 then begin
                    TempRegexGroups.Next();
                    TempFilterItemAttributesBuffer.Attribute := CopyStr(TempRegexGroups.ReadValue(), 1, MaxStrLen(TempFilterItemAttributesBuffer.Attribute));
                    TempRegexGroups.Next();
                    TempFilterItemAttributesBuffer.Value := CopyStr(TempRegexGroups.ReadValue(), 1, MaxStrLen(TempFilterItemAttributesBuffer.Value));
                    TempFilterItemAttributesBuffer.Insert();
                end
            end
        end;
    end;

    /// <summary>
    /// v18 and newer only. Given an item attributes buffer, serializes it into a 'pretend' filter
    /// similar to BC's filtering mechanism. A=Filter(B),C=Filter(D),E=Filter(F)
    /// </summary>
    /// <param name="TempFilterItemAttributesBuffer"></param>
    /// <returns>A=Filter(B),C=Filter(D),E=Filter(F)</returns>
    internal procedure SerializeItemAttributesBufferIntoText(var TempFilterItemAttributesBuffer: Record "Filter Item Attributes Buffer" temporary) Result: Text
    begin
        TempFilterItemAttributesBuffer.Reset();
        if TempFilterItemAttributesBuffer.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += StrSubstNo(ItemAttributeFilterSimulatorTok, TempFilterItemAttributesBuffer.Attribute, TempFilterItemAttributesBuffer.Value);
            until TempFilterItemAttributesBuffer.Next() = 0;
    end;

    internal procedure BuildItemAttributeFilter2048(var ItemAttributeFilter: Text[2048])
    var
        FullItemAttributeFilter: Text;
    begin
        FullItemAttributeFilter := ItemAttributeFilter;
        BuildItemAttributeFilter(FullItemAttributeFilter);
        ItemAttributeFilter := CopyStr(FullItemAttributeFilter, 1, MaxStrLen(ItemAttributeFilter));
    end;

    internal procedure BuildItemAttributeFilter(var ItemAttributeFilter: Text)
    var
        TempFilterItemAttributesBuffer: Record "Filter Item Attributes Buffer" temporary;
        CloseAction: Action;
        FilterPageID: Integer;
    begin
        FilterPageID := Page::"Filter Items by Attribute";
        if CurrentClientType() = ClientType::Phone then
            FilterPageID := Page::"Filter Items by Att. Phone";

        DeserializeFilterIntoItemAttributesBuffer(ItemAttributeFilter, TempFilterItemAttributesBuffer);

        CloseAction := Page.RunModal(FilterPageID, TempFilterItemAttributesBuffer);
        if (CurrentClientType() <> ClientType::Phone) and (CloseAction <> Action::LookupOK) then
            exit;

        ItemAttributeFilter := SerializeItemAttributesBufferIntoText(TempFilterItemAttributesBuffer);
    end;

    /// <summary>
    /// Not intended to be used outside of the Quality Management application.
    /// Intended to be used with BindSubscription for the OnFindItemsByAttributesOnBeforeFilterItemAttributesBufferLoop hook.
    /// </summary>
    /// <param name="ItemNo"></param>
    internal procedure SetItemFilterForItemAttributeFilterSearching(ItemNo: Code[20])
    begin
        SearchingForSpecificItemForItemAttributeManagementEventBinding := ItemNo;
    end;

    /// <summary>
    /// Returns a true or false if the supplied field has a filter and it's set to the value.
    /// </summary>
    /// <param name="TableNo"></param>
    /// <param name="Filter"></param>
    /// <param name="FieldNo"></param>
    /// <param name="ExpectedVariant"></param>
    /// <returns></returns>
    internal procedure GetIsFilterSetToValue(TableNo: Integer; Filter: Text; FieldNo: Integer; ExpectedVariant: Variant): Boolean;
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        FilterOfSpecificField: Text;
        FormattedExpectedValueToCompare: Text;
    begin
        RecordRef.Open(TableNo, true);
        RecordRef.SetView(Filter);
        FieldRef := RecordRef.Field(FieldNo);
        FilterOfSpecificField := FieldRef.GetFilter();
        FormattedExpectedValueToCompare := Format(ExpectedVariant);
        exit(FilterOfSpecificField.StartsWith(FormattedExpectedValueToCompare) or
           FilterOfSpecificField.Contains('|' + FormattedExpectedValueToCompare) or
           FilterOfSpecificField.Contains('..' + FormattedExpectedValueToCompare));
    end;

    #region Event Subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Attribute Management", 'OnFindItemsByAttributesOnBeforeFilterItemAttributesBufferLoop', '', true, true)]
    local procedure HandleOnFindItemsByAttributesOnBeforeFilterItemAttributesBufferLoop(var FilterItemAttributesBuffer: Record "Filter Item Attributes Buffer"; var TempFilteredItem: Record Item temporary; var ItemAttributeValueMapping: Record "Item Attribute Value Mapping")
    begin
        if SearchingForSpecificItemForItemAttributeManagementEventBinding = '' then
            exit;

        ItemAttributeValueMapping.SetRange("No.", SearchingForSpecificItemForItemAttributeManagementEventBinding);
    end;

    #endregion Event Subscribers
}
