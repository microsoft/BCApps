// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.SourceConfiguration;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using System.Reflection;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Manufacturing.Routing;
using Microsoft.QualityManagement.Document;
codeunit 20427 "Qlty. Traversal - Mfg."
{
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        QltyTraversal: Codeunit "Qlty. Traversal";

    /// <summary>
    /// Searches for a related Routing Header record by sequentially checking supplied record variants.
    /// Uses early-exit pattern for improved readability and performance.
    /// 
    /// Search sequence:
    /// 1. Check Optional1Variant for Routing → exit immediately if found
    /// 2. Check Optional2Variant for Routing → exit immediately if found
    /// 3. Check Optional3Variant for Routing → exit immediately if found
    /// 4. Check Optional4Variant for Routing → exit immediately if found
    /// 5. Check Optional5Variant for Routing → exit immediately if found
    /// 6. Find parent of Optional1Variant and check parent → return result
    /// 
    /// Common usage: Finding Routing from Production Order Line, Item, or Routing Line
    /// </summary>
    /// <param name="RoutingHeader">Output parameter that will contain the found Routing Header record with all fields populated</param>
    /// <param name="Optional1Variant">First variant to search (typically primary record like Production Order Line)</param>
    /// <param name="Optional2Variant">Second variant to search (typically parent or related Item)</param>
    /// <param name="Optional3Variant">Third variant to search (optional)</param>
    /// <param name="Optional4Variant">Fourth variant to search (optional)</param>
    /// <param name="Optional5Variant">Fifth variant to search (optional)</param>
    /// <returns>True if a Routing was found in any variant or parent; False otherwise</returns>
    procedure FindRelatedRouting(var RoutingHeader: Record "Routing Header"; Optional1Variant: Variant; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        ParentRecordRef: RecordRef;
    begin
        case true of
            FindRelatedRoutingIn(RoutingHeader, Optional1Variant),
            FindRelatedRoutingIn(RoutingHeader, Optional2Variant),
            FindRelatedRoutingIn(RoutingHeader, Optional3Variant),
            FindRelatedRoutingIn(RoutingHeader, Optional4Variant),
            FindRelatedRoutingIn(RoutingHeader, Optional5Variant):
                exit(true);
        end;

        // Try to find parent record and search in it
        if not QltyTraversal.FindSingleParentRecordWithVariant(Optional1Variant, ParentRecordRef) then
            exit(false);

        exit(FindRelatedRoutingIn(RoutingHeader, ParentRecordRef));
    end;

    /// <summary>
    /// Searches for a related Routing Header within a specific record variant using field relationships.
    /// Handles direct Routing Header records and indirect lookups through field mappings.
    /// 
    /// Lookup strategy:
    /// 1. If CurrentVariant is a Routing Header record → return it directly
    /// 2. Call FindRelatedRecordByFieldRelation to search for Routing No. field mappings
    /// 3. If a routing number is found, attempt Routing Header.Get() with that number
    /// 
    /// Common scenarios:
    /// - Production Order with "Routing No." → Routing lookup
    /// - Item with "Routing No." → Routing lookup
    /// - Routing Line with "Routing No." → Routing Header lookup
    /// </summary>
    /// <param name="RoutingHeader">Output: The found Routing Header record with all fields populated</param>
    /// <param name="CurrentVariant">The record variant to search (Record, RecordRef, or RecordId)</param>
    /// <returns>True if a Routing Header was found and loaded into RoutingHeader; False otherwise</returns>
    procedure FindRelatedRoutingIn(var RoutingHeader: Record "Routing Header"; CurrentVariant: Variant): Boolean
    var
        RecordRef: RecordRef;
        RoutingNo: Text;
    begin
        if not QltyMiscHelpers.GetRecordRefFromVariant(CurrentVariant, RecordRef) then
            exit(false);

        // Try direct record match first
        if RecordRef.Number() = Database::"Routing Header" then begin
            RecordRef.SetTable(RoutingHeader);
            exit(RoutingHeader.Get(RoutingHeader."No."));
        end;

        // Search through field relationships
        if QltyTraversal.FindRelatedRecordByFieldRelation(RecordRef, Database::"Routing Header", MaxStrLen(RoutingHeader."No."), RoutingNo) then
            exit(RoutingHeader.Get(RoutingNo));

        exit(false);
    end;

    /// <summary>
    /// Searches for a related Production BOM Header record by sequentially checking supplied record variants.
    /// Uses early-exit pattern for improved readability and performance.
    /// 
    /// Search sequence:
    /// 1. Check Optional1Variant for BOM → exit immediately if found
    /// 2. Check Optional2Variant for BOM → exit immediately if found
    /// 3. Check Optional3Variant for BOM → exit immediately if found
    /// 4. Check Optional4Variant for BOM → exit immediately if found
    /// 5. Check Optional5Variant for BOM → exit immediately if found
    /// 6. Find parent of Optional1Variant and check parent → return result
    /// 
    /// Common usage: Finding Production BOM from Production Order Line, Item, or BOM Line
    /// </summary>
    /// <param name="ProductionBOMHeader">Output parameter that will contain the found Production BOM Header record with all fields populated</param>
    /// <param name="Optional1Variant">First variant to search (typically primary record like Production Order Line)</param>
    /// <param name="Optional2Variant">Second variant to search (typically parent or related Item)</param>
    /// <param name="Optional3Variant">Third variant to search (optional)</param>
    /// <param name="Optional4Variant">Fourth variant to search (optional)</param>
    /// <param name="Optional5Variant">Fifth variant to search (optional)</param>
    /// <returns>True if a Production BOM was found in any variant or parent; False otherwise</returns>
    procedure FindRelatedBillOfMaterial(var ProductionBOMHeader: Record "Production BOM Header"; Optional1Variant: Variant; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        ParentRecordRef: RecordRef;
    begin
        case true of
            FindRelatedBillOfMaterialIn(ProductionBOMHeader, Optional1Variant),
            FindRelatedBillOfMaterialIn(ProductionBOMHeader, Optional2Variant),
            FindRelatedBillOfMaterialIn(ProductionBOMHeader, Optional3Variant),
            FindRelatedBillOfMaterialIn(ProductionBOMHeader, Optional4Variant),
            FindRelatedBillOfMaterialIn(ProductionBOMHeader, Optional5Variant):
                exit(true);
        end;

        // Try to find parent record and search in it
        if not QltyTraversal.FindSingleParentRecordWithVariant(Optional1Variant, ParentRecordRef) then
            exit(false);

        exit(FindRelatedBillOfMaterialIn(ProductionBOMHeader, ParentRecordRef));
    end;

    /// <summary>
    /// Searches for a related Production BOM Header within a specific record variant using field relationships.
    /// Handles direct BOM Header records and indirect lookups through both field mappings and table relations.
    /// 
    /// Lookup strategy (more complex than other FindRelated* procedures):
    /// 1. If CurrentVariant is a Production BOM Header → return it directly
    /// 2. Find all fields in the source table that relate to Production BOM Header
    /// 3. For each related field:
    ///    a. Check if there's an enabled Quality Inspection Source Field Configuration
    ///    b. If configured, read the field value and attempt Production BOM Header.Get()
    ///    c. If not configured but field has table relation, try direct field value lookup
    /// 4. Return first successfully found Production BOM Header
    /// 
    /// Common scenarios:
    /// - Production Order with "Production BOM No." → BOM lookup
    /// - Item with "Production BOM No." → BOM lookup
    /// - Production BOM Line with parent BOM No. → BOM Header lookup
    /// </summary>
    /// <param name="ProductionBOMHeader">Output: The found Production BOM Header record with all fields populated</param>
    /// <param name="CurrentVariant">The record variant to search (Record, RecordRef, or RecordId)</param>
    /// <returns>True if a Production BOM Header was found and loaded into ProductionBOMHeader; False otherwise</returns>
    procedure FindRelatedBillOfMaterialIn(var ProductionBOMHeader: Record "Production BOM Header"; CurrentVariant: Variant): Boolean
    var
        CurrentField: Record Field;
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        QltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        RecordRef: RecordRef;
        FromFieldReference: FieldRef;
        PossibleBillOfMaterialNo: Text;
    begin
        if not QltyMiscHelpers.GetRecordRefFromVariant(CurrentVariant, RecordRef) then
            exit(false);

        // Try direct record match first
        if RecordRef.Number() = Database::"Production BOM Header" then begin
            RecordRef.SetTable(ProductionBOMHeader);
            exit(ProductionBOMHeader.Get(ProductionBOMHeader."No."));
        end;

        // Search through field relationships
        CurrentField.SetRange(TableNo, RecordRef.Number());
        CurrentField.SetRange(RelationTableNo, Database::"Production BOM Header");
        if CurrentField.FindSet() then
            repeat
                QltyInspectSrcFldConf.SetRange("From Table No.", RecordRef.Number());
                QltyInspectSrcFldConf.SetRange("To Type", QltyInspectSrcFldConf."To Type"::Test);
                QltyInspectSrcFldConf.SetRange("To Table No.", Database::"Qlty. Inspection Test Header");
                QltyInspectSrcFldConf.SetRange("From Field No.", CurrentField."No.");
                if QltyInspectSrcFldConf.FindSet() then
                    repeat
                        if QltyInspectSourceConfig.Code <> QltyInspectSrcFldConf.Code then
                            if QltyInspectSourceConfig.Get(QltyInspectSrcFldConf.Code) then;

                        if QltyInspectSourceConfig.Enabled then
                            if QltyInspectSrcFldConf."From Field No." <> 0 then begin
                                FromFieldReference := RecordRef.Field(QltyInspectSrcFldConf."From Field No.");
                                if FromFieldReference.Class() = FieldClass::FlowField then
                                    FromFieldReference.CalcField();

                                PossibleBillOfMaterialNo := Format(FromFieldReference.Value());
                                if PossibleBillOfMaterialNo <> '' then
                                    if ProductionBOMHeader.Get(CopyStr(PossibleBillOfMaterialNo, 1, MaxStrLen(ProductionBOMHeader."No."))) then
                                        exit(true);
                            end;

                    until QltyInspectSrcFldConf.Next() = 0
                else begin
                    FromFieldReference := RecordRef.Field(CurrentField."No.");
                    if FromFieldReference.Class() = FieldClass::FlowField then
                        FromFieldReference.CalcField();

                    PossibleBillOfMaterialNo := Format(FromFieldReference.Value());
                    if PossibleBillOfMaterialNo <> '' then
                        if ProductionBOMHeader.Get(CopyStr(PossibleBillOfMaterialNo, 1, MaxStrLen(ProductionBOMHeader."No."))) then
                            exit(true);
                end;
            until CurrentField.Next() = 0;

        exit(false);
    end;

    /// <summary>
    /// Searches for a related Production Order Routing Line by sequentially checking supplied record variants.
    /// Uses an exact table number match strategy through the GetIfAnExactMatch helper procedure.
    /// 
    /// Unlike other FindRelated* procedures that search through field mappings, this procedure
    /// looks for an exact Production Order Routing Line record in the provided variants.
    /// 
    /// Search sequence (through GetIfAnExactMatch):
    /// 1. Check Optional1Variant for exact table match → exit if found
    /// 2. Check Optional2Variant for exact table match → exit if found
    /// 3. Check Optional3Variant for exact table match → exit if found
    /// 4. Check Optional4Variant for exact table match → exit if found
    /// 5. Check Optional5Variant for exact table match → exit if found
    /// 6. Find parent of Optional1Variant and check parent → return result
    /// 
    /// Common usage: Finding routing line from Production Order, Manufacturing process records
    /// </summary>
    /// <param name="ProdOrderRoutingLine">Output: The found Production Order Routing Line record</param>
    /// <param name="Optional1Variant">First variant to check (typically Production Order or related record)</param>
    /// <param name="Optional2Variant">Second variant to check (optional)</param>
    /// <param name="Optional3Variant">Third variant to check (optional)</param>
    /// <param name="Optional4Variant">Fourth variant to check (optional)</param>
    /// <param name="Optional5Variant">Fifth variant to check (optional)</param>
    /// <returns>True if a Production Order Routing Line was found in any variant or parent; False otherwise</returns>
    procedure FindRelatedProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; Optional1Variant: Variant; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        RecordRefToProdOrderRoutingLine: RecordRef;
    begin
        RecordRefToProdOrderRoutingLine.GetTable(ProdOrderRoutingLine);
        if GetIfAnExactMatch(RecordRefToProdOrderRoutingLine, Optional1Variant, Optional2Variant, Optional3Variant, Optional4Variant, Optional5Variant) then begin
            RecordRefToProdOrderRoutingLine.SetTable(ProdOrderRoutingLine);
            exit(true);
        end;
    end;

    /// <summary>
    /// Searches for an exact record match by sequentially checking supplied record variants.
    /// Uses early-exit pattern for improved readability and performance.
    /// 
    /// This is a helper procedure that looks for a record matching the exact table number specified
    /// in FoundRecordRef. The FoundRecordRef parameter must be initialized with the target
    /// table number before calling this procedure.
    /// 
    /// Unlike the FindRelated* procedures which search for specific entity types, this procedure
    /// performs a generic table-number-based match, useful for finding specific record types like
    /// Prod. Order Routing Line that don't fit the standard relationship patterns.
    /// 
    /// Search sequence:
    /// 1. Check Optional1Variant for exact table match → exit immediately if found
    /// 2. Check Optional2Variant for exact table match → exit immediately if found
    /// 3. Check Optional3Variant for exact table match → exit immediately if found
    /// 4. Check Optional4Variant for exact table match → exit immediately if found
    /// 5. Check Optional5Variant for exact table match → exit immediately if found
    /// 6. Find parent of Optional1Variant and check parent → return result
    /// 
    /// Usage: Primarily used by FindRelatedProdOrderRoutingLine to locate routing line records
    /// </summary>
    /// <param name="FoundRecordRef">Input/Output: Must contain the target table number on input; contains the found record on output</param>
    /// <param name="Optional1Variant">First variant to check for exact table match</param>
    /// <param name="Optional2Variant">Second variant to check for exact table match</param>
    /// <param name="Optional3Variant">Third variant to check for exact table match</param>
    /// <param name="Optional4Variant">Fourth variant to check for exact table match</param>
    /// <param name="Optional5Variant">Fifth variant to check for exact table match</param>
    /// <returns>True if an exact table match was found in any variant or parent; False otherwise</returns>
    local procedure GetIfAnExactMatch(var FoundRecordRef: RecordRef; Optional1Variant: Variant; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        ParentRecordRef: RecordRef;
    begin
        case true of
            GetIfAnExactMatch(FoundRecordRef, Optional1Variant),
            GetIfAnExactMatch(FoundRecordRef, Optional2Variant),
            GetIfAnExactMatch(FoundRecordRef, Optional3Variant),
            GetIfAnExactMatch(FoundRecordRef, Optional4Variant),
            GetIfAnExactMatch(FoundRecordRef, Optional5Variant):
                exit(true);
        end;

        // Try to find parent record and search in it
        if not QltyTraversal.FindSingleParentRecordWithVariant(Optional1Variant, ParentRecordRef) then
            exit(false);

        exit(GetIfAnExactMatch(FoundRecordRef, ParentRecordRef));
    end;

    /// <summary>
    /// Checks if a specific record variant exactly matches the target table number specified in FoundRecordRef.
    /// This is the single-variant implementation called by the multi-variant overload.
    /// 
    /// Comparison logic:
    /// 1. Convert CurrentVariant to RecordRef
    /// 2. Check if RecordRef table number matches FoundRecordRef table number
    /// 3. If match found, copy RecordRef to FoundRecordRef and set record filter
    /// 4. Attempt to find the record with the filter applied
    /// 
    /// Note: FoundRecordRef must be initialized with the target table number before calling.
    /// This procedure is used internally by GetIfAnExactMatch(5-variant overload) and FindRelatedProdOrderRoutingLine.
    /// </summary>
    /// <param name="FoundRecordRef">Input: Target table number; Output: Found record if match successful</param>
    /// <param name="CurrentVariant">The record variant to check (Record, RecordRef, or RecordId)</param>
    /// <returns>True if CurrentVariant's table number matches FoundRecordRef's table number and record exists; False otherwise</returns>
    local procedure GetIfAnExactMatch(var FoundRecordRef: RecordRef; CurrentVariant: Variant): Boolean
    var
        RecordRef: RecordRef;
    begin
        if not QltyMiscHelpers.GetRecordRefFromVariant(CurrentVariant, RecordRef) then
            exit(false);

        if RecordRef.Number() = FoundRecordRef.Number() then begin
            FoundRecordRef := RecordRef;
            FoundRecordRef.SetRecFilter();
            exit(FoundRecordRef.FindFirst());
        end;
    end;

}