// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Utilities;

/// <summary>
/// Provides comprehensive dimension validation services for sales and purchase documents.
/// Validates dimension combinations, dimension value posting restrictions, and mandatory dimension requirements.
/// </summary>
/// <remarks>
/// Integrates with DimensionManagement codeunit for validation logic. Supports error collection mode
/// for batch validation scenarios. Provides extensibility through integration events for custom validation.
/// </remarks>
codeunit 481 "Check Dimensions"
{

    trigger OnRun()
    begin
    end;

    var
        ErrorMessageMgt: Codeunit "Error Message Management";
        DimMgt: Codeunit DimensionManagement;

        DimensionIsBlockedErr: Label 'The combination of dimensions used in %1 %2 is blocked', Comment = '%1 = Document Type, %2 = Document No, %3 = Error text';
        LineDimensionBlockedErr: Label 'The combination of dimensions used in %1 %2, line no. %3 is blocked', Comment = '%1 = Document Type, %2 = Document No, %3 = LineNo., %4 = Error text';
        InvalidDimensionsErr: Label 'The dimensions used in %1 %2 are invalid', Comment = '%1 = Document Type, %2 = Document No, %3 = Error text';
        LineInvalidDimensionsErr: Label 'The dimensions used in %1 %2, line no. %3 are invalid', Comment = '%1 = Document Type, %2 = Document No, %3 = LineNo., %4 = Error text';

    /// <summary>
    /// Validates dimension combinations and posting restrictions for purchase documents including header and lines.
    /// Performs comprehensive dimension validation using error collection mode for batch processing.
    /// </summary>
    /// <param name="PurchHeader">Purchase document header to validate dimensions for</param>
    /// <param name="TempPurchLine">Temporary table containing purchase lines to validate</param>
    /// <remarks>
    /// Extensibility: OnBeforeCheckPurchDim event allows custom validation logic.
    /// Validates both header-level and line-level dimension combinations and posting restrictions.
    /// </remarks>
    procedure CheckPurchDim(PurchHeader: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary)
    var
        TempPurchLineLocal: Record "Purchase Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchDim(PurchHeader, TempPurchLine, IsHandled);
        if IsHandled then
            exit;

        DimMgt.SetCollectErrorsMode();
        CheckPurchDimCombHeader(PurchHeader);
        CheckPurchDimValuePostingHeader(PurchHeader);

        TempPurchLineLocal.Copy(TempPurchLine, true);
        CheckPurchDimLines(PurchHeader, TempPurchLineLocal);
    end;

    local procedure CheckPurchDimCombHeader(PurchaseHeader: Record "Purchase Header")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ContextErrorMessage: Text[250];
    begin
        ContextErrorMessage := StrSubstNo(DimensionIsBlockedErr, PurchaseHeader."Document Type", PurchaseHeader."No.");
        ErrorMessageMgt.PushContext(ErrorContextElement, PurchaseHeader.RecordId, 0, ContextErrorMessage);
        if not DimMgt.CheckDimIDComb(PurchaseHeader."Dimension Set ID") then
            ErrorMessageMgt.ThrowError(ContextErrorMessage, DimMgt.GetDimErr());
        ErrorMessageMgt.PopContext(ErrorContextElement);
    end;

    local procedure CheckPurchDimCombLine(PurchaseLine: Record "Purchase Line")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ContextErrorMessage: Text[250];
    begin
        ContextErrorMessage := StrSubstNo(LineDimensionBlockedErr, PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        ErrorMessageMgt.PushContext(ErrorContextElement, PurchaseLine.RecordId, 0, ContextErrorMessage);
        if not DimMgt.CheckDimIDComb(PurchaseLine."Dimension Set ID") then
            ErrorMessageMgt.ThrowError(ContextErrorMessage, DimMgt.GetDimErr());
        ErrorMessageMgt.PopContext(ErrorContextElement);
    end;

    local procedure CheckPurchDimLines(PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary)
    var
        CheckDimensions: Boolean;
    begin
        TempPurchaseLine.Reset();
        TempPurchaseLine.SetFilter(Type, '<>%1', TempPurchaseLine.Type::" ");
        if TempPurchaseLine.FindSet() then
            repeat
                CheckDimensions := (PurchaseHeader.Receive and (TempPurchaseLine."Qty. to Receive" <> 0)) or
                (PurchaseHeader.Invoice and (TempPurchaseLine."Qty. to Invoice" <> 0)) or
                    (PurchaseHeader.Ship and (TempPurchaseLine."Return Qty. to Ship" <> 0));
                if not CheckDimensions then
                    OnCheckPurchDimLinesOnBeforeCheckDim(PurchaseHeader, TempPurchaseLine, CheckDimensions);

                if CheckDimensions then begin
                    CheckPurchDimCombLine(TempPurchaseLine);
                    CheckPurchDimValuePostingLine(TempPurchaseLine);
                    OnCheckPurchDimLinesOnAfterCheckPurchDimValuePostingLine(TempPurchaseLine);
                end
            until TempPurchaseLine.Next() = 0;
    end;

    local procedure CheckPurchDimValuePostingHeader(PurchaseHeader: Record "Purchase Header")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ContextErrorMessage: Text[250];
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        TableIDArr[1] := Database::Vendor;
        NumberArr[1] := PurchaseHeader."Pay-to Vendor No.";
        TableIDArr[2] := Database::"Salesperson/Purchaser";
        NumberArr[2] := PurchaseHeader."Purchaser Code";
        TableIDArr[3] := Database::Campaign;
        NumberArr[3] := PurchaseHeader."Campaign No.";
        TableIDArr[4] := Database::"Responsibility Center";
        NumberArr[4] := PurchaseHeader."Responsibility Center";
        TableIDArr[5] := Database::Location;
        NumberArr[5] := PurchaseHeader."Location Code";
        OnCheckDimValuePostingOnAfterCreateDimTableIDs(PurchaseHeader, TableIDArr, NumberArr);

        DimMgt.SetSourceCode(Database::"Purchase Header", PurchaseHeader);
        ContextErrorMessage := StrSubstNo(InvalidDimensionsErr, PurchaseHeader."Document Type", PurchaseHeader."No.");
        ErrorMessageMgt.PushContext(ErrorContextElement, PurchaseHeader.RecordId, 0, ContextErrorMessage);
        if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, PurchaseHeader."Dimension Set ID") then
            ErrorMessageMgt.ThrowError(ContextErrorMessage, DimMgt.GetDimErr());
        ErrorMessageMgt.PopContext(ErrorContextElement);
    end;

    local procedure CheckPurchDimValuePostingLine(PurchaseLine: Record "Purchase Line")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ContextErrorMessage: Text[250];
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        TableIDArr[1] := DimMgt.PurchLineTypeToTableID(PurchaseLine.Type);
        NumberArr[1] := PurchaseLine."No.";
        TableIDArr[2] := Database::Job;
        NumberArr[2] := PurchaseLine."Job No.";
        TableIDArr[4] := Database::Location;
        NumberArr[4] := PurchaseLine."Location Code";
        OnCheckDimValuePostingOnAfterCreateDimTableIDs(PurchaseLine, TableIDArr, NumberArr);

        DimMgt.SetSourceCode(Database::"Purchase Line", PurchaseLine);
        ContextErrorMessage := StrSubstNo(LineInvalidDimensionsErr, PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        ErrorMessageMgt.PushContext(ErrorContextElement, PurchaseLine.RecordId, 0, ContextErrorMessage);
        if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, PurchaseLine."Dimension Set ID") then
            ErrorMessageMgt.ThrowError(ContextErrorMessage, DimMgt.GetDimErr());
        ErrorMessageMgt.PopContext(ErrorContextElement);
    end;

    /// <summary>
    /// Validates dimension combinations and posting restrictions for purchase prepayment scenarios.
    /// Performs header and prepayment line validation for purchase documents with prepayment percentages.
    /// </summary>
    /// <param name="PurchaseHeader">Purchase document header with prepayment setup to validate</param>
    /// <remarks>
    /// Specifically validates lines with prepayment percentages greater than zero.
    /// Uses error collection mode for comprehensive validation reporting.
    /// </remarks>
    procedure CheckPurchPrepmtDim(PurchaseHeader: Record "Purchase Header")
    begin
        DimMgt.SetCollectErrorsMode();
        CheckPurchDimCombHeader(PurchaseHeader);
        CheckPurchDimValuePostingHeader(PurchaseHeader);

        CheckPurchPrepmtDimLines(PurchaseHeader);
    end;

    local procedure CheckPurchPrepmtDimLines(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        PurchaseLine.SetFilter("Prepayment %", '<>0');
        if PurchaseLine.FindSet() then
            repeat
                CheckPurchDimCombLine(PurchaseLine);
                CheckPurchDimValuePostingLine(PurchaseLine);
            until PurchaseLine.Next() = 0;
    end;

    /// <summary>
    /// Validates dimension combinations and posting restrictions for sales documents including header and lines.
    /// Performs comprehensive dimension validation using error collection mode for batch processing.
    /// </summary>
    /// <param name="SalesHeader">Sales document header to validate dimensions for</param>
    /// <param name="TempSalesLine">Temporary table containing sales lines to validate</param>
    /// <remarks>
    /// Extensibility: OnBeforeCheckSalesDim event allows custom validation logic.
    /// Validates both header-level and line-level dimension combinations and posting restrictions.
    /// </remarks>
    procedure CheckSalesDim(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    var
        TempSalesLineLocal: Record "Sales Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesDim(SalesHeader, TempSalesLine, IsHandled);
        if IsHandled then
            exit;

        DimMgt.SetCollectErrorsMode();
        CheckSalesDimCombHeader(SalesHeader);
        CheckSalesDimValuePostingHeader(SalesHeader);

        TempSalesLineLocal.Copy(TempSalesLine, true);
        CheckSalesDimLines(SalesHeader, TempSalesLineLocal);
    end;

    local procedure CheckSalesDimCombHeader(SalesHeader: Record "Sales Header")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ContextErrorMessage: Text[250];
    begin
        ContextErrorMessage := StrSubstNo(DimensionIsBlockedErr, SalesHeader."Document Type", SalesHeader."No.");
        ErrorMessageMgt.PushContext(ErrorContextElement, SalesHeader.RecordId, 0, ContextErrorMessage);
        if not DimMgt.CheckDimIDComb(SalesHeader."Dimension Set ID") then
            ErrorMessageMgt.ThrowError(ContextErrorMessage, DimMgt.GetDimErr());
        ErrorMessageMgt.PopContext(ErrorContextElement);
    end;

    local procedure CheckSalesDimCombLine(SalesLine: Record "Sales Line")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ContextErrorMessage: Text[250];
    begin
        ContextErrorMessage := StrSubstNo(LineDimensionBlockedErr, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        ErrorMessageMgt.PushContext(ErrorContextElement, SalesLine.RecordId, 0, ContextErrorMessage);
        if not DimMgt.CheckDimIDComb(SalesLine."Dimension Set ID") then
            ErrorMessageMgt.ThrowError(ContextErrorMessage, DimMgt.GetDimErr());
        ErrorMessageMgt.PopContext(ErrorContextElement);
    end;

    local procedure CheckSalesDimLines(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    var
        ShouldCheckDimensions: Boolean;
    begin
        TempSalesLine.Reset();
        TempSalesLine.SetFilter(Type, '<>%1', TempSalesLine.Type::" ");
        if TempSalesLine.FindSet() then
            repeat
                ShouldCheckDimensions := (SalesHeader.Invoice and (TempSalesLine."Qty. to Invoice" <> 0)) or
                                            (SalesHeader.Ship and (TempSalesLine."Qty. to Ship" <> 0)) or
                                            (SalesHeader.Receive and (TempSalesLine."Return Qty. to Receive" <> 0));
                OnCheckSalesDimLinesOnAfterCalcShouldCheckDimensions(SalesHeader, TempSalesLine, ShouldCheckDimensions);
                if ShouldCheckDimensions then begin
                    CheckSalesDimCombLine(TempSalesLine);
                    CheckSalesDimValuePostingLine(TempSalesLine);
                end
            until TempSalesLine.Next() = 0;
    end;

    local procedure CheckSalesDimValuePostingHeader(SalesHeader: Record "Sales Header")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ContextErrorMessage: Text[250];
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        TableIDArr[1] := Database::Customer;
        NumberArr[1] := SalesHeader."Bill-to Customer No.";
        TableIDArr[2] := Database::"Salesperson/Purchaser";
        NumberArr[2] := SalesHeader."Salesperson Code";
        TableIDArr[3] := Database::Campaign;
        NumberArr[3] := SalesHeader."Campaign No.";
        TableIDArr[4] := Database::"Responsibility Center";
        NumberArr[4] := SalesHeader."Responsibility Center";
        TableIDArr[5] := Database::Location;
        NumberArr[5] := SalesHeader."Location Code";
        OnCheckDimValuePostingOnAfterCreateDimTableIDs(SalesHeader, TableIDArr, NumberArr);

        DimMgt.SetSourceCode(Database::"Sales Header", SalesHeader);
        ContextErrorMessage := StrSubstNo(InvalidDimensionsErr, SalesHeader."Document Type", SalesHeader."No.");
        ErrorMessageMgt.PushContext(ErrorContextElement, SalesHeader.RecordId, 0, ContextErrorMessage);
        if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, SalesHeader."Dimension Set ID") then
            ErrorMessageMgt.ThrowError(ContextErrorMessage, DimMgt.GetDimErr());
        ErrorMessageMgt.PopContext(ErrorContextElement);
    end;

    local procedure CheckSalesDimValuePostingLine(SalesLine: Record "Sales Line")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ContextErrorMessage: Text[250];
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        TableIDArr[1] := DimMgt.SalesLineTypeToTableID(SalesLine.Type);
        NumberArr[1] := SalesLine."No.";
        TableIDArr[2] := Database::Job;
        NumberArr[2] := SalesLine."Job No.";
        TableIDArr[3] := Database::Location;
        NumberArr[3] := SalesLine."Location Code";
        DimMgt.SetSourceCode(Database::"Sales Line", SalesLine);
        OnCheckDimValuePostingOnAfterCreateDimTableIDs(SalesLine, TableIDArr, NumberArr);

        ContextErrorMessage := StrSubstNo(LineInvalidDimensionsErr, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        ErrorMessageMgt.PushContext(ErrorContextElement, SalesLine.RecordId, 0, ContextErrorMessage);
        if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, SalesLine."Dimension Set ID") then
            ErrorMessageMgt.ThrowError(ContextErrorMessage, DimMgt.GetDimErr());
        ErrorMessageMgt.PopContext(ErrorContextElement);
    end;

    /// <summary>
    /// Validates dimension combinations and posting restrictions for sales prepayment scenarios.
    /// Performs header and prepayment line validation for sales documents with prepayment percentages.
    /// </summary>
    /// <param name="SalesHeader">Sales document header with prepayment setup to validate</param>
    /// <remarks>
    /// Specifically validates lines with prepayment percentages greater than zero.
    /// Uses error collection mode for comprehensive validation reporting.
    /// </remarks>
    procedure CheckSalesPrepmtDim(SalesHeader: Record "Sales Header")
    begin
        DimMgt.SetCollectErrorsMode();
        CheckSalesDimCombHeader(SalesHeader);
        CheckSalesDimValuePostingHeader(SalesHeader);

        CheckSalesPrepmtDimLines(SalesHeader);
    end;

    local procedure CheckSalesPrepmtDimLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.SetFilter("Prepayment %", '<>0');
        if SalesLine.FindSet() then
            repeat
                CheckSalesDimCombLine(SalesLine);
                CheckSalesDimValuePostingLine(SalesLine);
            until SalesLine.Next() = 0;
    end;

    local procedure ShowDimensionsSetup(RecID: RecordID): Boolean
    var
        Dimension: Record Dimension;
        DimensionCombination: Record "Dimension Combination";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        DimensionValueCombination: Record "Dimension Value Combination";
        DimensionCombinations: Page "Dimension Combinations";
        MyDimValueCombinations: Page "MyDim Value Combinations";
        RecRef: RecordRef;
    begin
        case RecID.TableNo of
            Database::Dimension:
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then
                        RecRef.SetTable(Dimension);
                    PAGE.Run(PAGE::Dimensions, Dimension);
                end;
            Database::"Dimension Combination":
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then
                        RecRef.SetTable(DimensionCombination);
                    DimensionCombinations.SetSelectedRecord(DimensionCombination);
                    DimensionCombinations.Run();
                end;
            Database::"Dimension Value":
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then
                        RecRef.SetTable(DimensionValue);
                    PAGE.Run(PAGE::"Dimension Values", DimensionValue);
                end;
            Database::"Dimension Value Combination":
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then
                        RecRef.SetTable(DimensionValueCombination);
                    MyDimValueCombinations.SetSelectedDimValueComb(DimensionValueCombination);
                    MyDimValueCombinations.Run();
                end;
            Database::"Default Dimension":
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then begin
                        RecRef.SetTable(DefaultDimension);
                        DefaultDimension.SetRange("Table ID", DefaultDimension."Table ID");
                        DefaultDimension.SetRange("No.", DefaultDimension."No.");
                    end;
                    PAGE.Run(PAGE::"Default Dimensions", DefaultDimension);
                end;
            else
                exit(false);
        end;
        exit(true);
    end;

    /// <summary>
    /// Displays dimension-related pages based on the record type and context for dimension troubleshooting.
    /// Opens appropriate dimension pages for sales/purchase documents and their lines to aid in dimension validation errors.
    /// </summary>
    /// <param name="RecID">Record ID of the sales or purchase document/line to show dimensions for</param>
    /// <returns>True if appropriate dimension page was displayed, false if record type not supported</returns>
    /// <remarks>
    /// Extensibility: OnBeforeShowContextDimensions event allows custom dimension page display logic.
    /// Supports Purchase Header, Purchase Line, Sales Header, and Sales Line record types.
    /// </remarks>
    procedure ShowContextDimensions(RecID: RecordID) Result: Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowContextDimensions(RecID, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case RecID.TableNo of
            Database::"Sales Header":
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then
                        RecRef.SetTable(SalesHeader);
                    SalesHeader.ShowDocDim();
                end;
            Database::"Sales Line":
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then
                        RecRef.SetTable(SalesLine);
                    if SalesLine.ShowDimensions() then
                        SalesLine.Modify();
                end;
            Database::"Purchase Header":
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then
                        RecRef.SetTable(PurchaseHeader);
                    PurchaseHeader.ShowDocDim();
                end;
            Database::"Purchase Line":
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then
                        RecRef.SetTable(PurchaseLine);
                    if PurchaseLine.ShowDimensions() then
                        PurchaseLine.Modify();
                end;
            else
                exit(false);
        end;
        exit(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Error Message", 'OnDrillDownSource', '', false, false)]
    local procedure OnErrorMessageDrillDown(ErrorMessage: Record "Error Message"; SourceFieldNo: Integer; var IsHandled: Boolean)
    begin
        if not IsHandled then
            if ErrorMessage."Table Number" in [Database::Dimension, Database::"Dimension Value", Database::"Dimension Combination", Database::"Dimension Value Combination", Database::"Default Dimension"] then
                case SourceFieldNo of
                    ErrorMessage.FieldNo("Context Record ID"):
                        IsHandled := ShowContextDimensions(ErrorMessage."Context Record ID");
                    ErrorMessage.FieldNo("Record ID"):
                        if Format(ErrorMessage."Record ID") = '' then
                            IsHandled := ShowContextDimensions(ErrorMessage."Context Record ID")
                        else
                            IsHandled := ShowDimensionsSetup(ErrorMessage."Record ID");
                end;
    end;

    /// <summary>
    /// Integration event raised before validating purchase document dimensions.
    /// Enables custom validation logic or skipping standard dimension validation.
    /// </summary>
    /// <param name="PurchaseHeader">Purchase document header being validated</param>
    /// <param name="TempPurchaseLine">Temporary purchase lines to validate</param>
    /// <param name="IsHandled">Set to true to skip standard dimension validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchDim(PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before validating sales document dimensions.
    /// Enables custom validation logic or skipping standard dimension validation.
    /// </summary>
    /// <param name="SalesHeader">Sales document header being validated</param>
    /// <param name="TempSalesLine">Temporary sales lines to validate</param>
    /// <param name="IsHandled">Set to true to skip standard dimension validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesDim(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before displaying context-specific dimension pages.
    /// Enables custom dimension page display logic based on record context.
    /// </summary>
    /// <param name="RecID">Record ID of the document or line for dimension display</param>
    /// <param name="Result">Set to indicate whether dimension page was displayed</param>
    /// <param name="IsHandled">Set to true to skip standard dimension page display</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowContextDimensions(RecID: RecordID; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after validating dimension value posting for purchase lines.
    /// Enables custom processing or additional validation after standard dimension checks.
    /// </summary>
    /// <param name="TempPurchLine">Purchase line that was validated for dimension posting</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckPurchDimLinesOnAfterCheckPurchDimValuePostingLine(var TempPurchLine: Record "Purchase Line")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"Error Messages", 'OnOpenRelatedRecord', '', false, false)]
    local procedure OnOpenRelatedRecord(ErrorMessage: Record "Error Message"; var IsHandled: Boolean)
    var
        PageManagement: Codeunit "Page Management";
    begin
        if ErrorMessage."Table Number" in [Database::Dimension .. Database::"Default Dimension"] then begin
            PageManagement.PageRun(ErrorMessage."Context Record ID");
            IsHandled := true;
        end;
    end;

    /// <summary>
    /// Integration event raised after determining whether sales dimensions should be checked.
    /// Enables custom logic to override dimension validation requirements based on document context.
    /// </summary>
    /// <param name="SalesHeader">Sales document header being evaluated</param>
    /// <param name="TempSalesLine">Sales line being evaluated for dimension validation</param>
    /// <param name="ShouldCheckDimensions">Set to control whether dimension validation should proceed</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesDimLinesOnAfterCalcShouldCheckDimensions(SalesHeader: Record "Sales Header"; TempSalesLine: Record "Sales Line" temporary; var ShouldCheckDimensions: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after creating table ID and number arrays for dimension value posting validation.
    /// Enables custom table ID and number array population for extended dimension validation scenarios.
    /// </summary>
    /// <param name="RecordVariant">Record variant containing the source record for dimension validation</param>
    /// <param name="TableIDArr">Array of table IDs used for dimension value posting validation</param>
    /// <param name="NumberArr">Array of record numbers corresponding to the table IDs</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckDimValuePostingOnAfterCreateDimTableIDs(RecordVariant: Variant; var TableIDArr: array[10] of Integer; var NumberArr: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPurchDimLinesOnBeforeCheckDim(PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; var CheckDimensions: Boolean)
    begin
    end;
}

