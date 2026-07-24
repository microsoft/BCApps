// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Wizard;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Document;
using System.Reflection;

codeunit 99001022 "Prod. Def. Source Initializer"
{
    var
        UnknownSourceTypeErr: Label 'No initialization handler found for source type: %1.', Comment = '%1 = source type description';

    /// <summary>
    /// Dispatches initialization of the temporary production definition data based on the type of the source record.
    /// Built-in handling is provided for Item, Stockkeeping Unit, and Sales Line. For other source types (such as Purchase Line in the
    /// Subcontracting app), subscribe to OnInitializeFromSource and set IsHandled to true.
    /// </summary>
    /// <param name="TempData">The temporary data codeunit to initialize.</param>
    /// <param name="Source">The source record variant. Supported built-in types: Item, Stockkeeping Unit, Sales Line.</param>
    internal procedure InitializeFromSource(var TempData: Codeunit "Prod. Definition Temp Data"; Source: Variant)
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        SalesLine: Record "Sales Line";
        DataTypeManagement: Codeunit "Data Type Management";
        SourceRecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitializeFromSource(TempData, Source, IsHandled);
        if IsHandled then
            exit;

        if not DataTypeManagement.GetRecordRef(Source, SourceRecRef) then begin
            OnInitializeFromSource(TempData, Source, IsHandled);
            if not IsHandled then
                RaiseUnknownSourceTypeError(Source);
            exit;
        end;

        case SourceRecRef.Number of
            Database::Item:
                begin
                    SourceRecRef.SetTable(Item);
                    TempData.InitializeFromItem(Item);
                end;
            Database::"Sales Line":
                begin
                    SourceRecRef.SetTable(SalesLine);
                    TempData.InitializeFromSalesLine(SalesLine);
                end;
            Database::"Stockkeeping Unit":
                begin
                    SourceRecRef.SetTable(SKU);
                    TempData.InitializeFromSKU(SKU);
                end;
            else begin
                OnInitializeFromSource(TempData, Source, IsHandled);
                if not IsHandled then
                    RaiseUnknownSourceTypeError(Source);
            end;
        end;
    end;

    local procedure RaiseUnknownSourceTypeError(Source: Variant)
    var
        UnknownSourceTypeErrorInfo: ErrorInfo;
    begin
        UnknownSourceTypeErrorInfo.DataClassification := DataClassification::SystemMetadata;
        UnknownSourceTypeErrorInfo.ErrorType := ErrorType::Internal;
        UnknownSourceTypeErrorInfo.Verbosity := Verbosity::Error;
        UnknownSourceTypeErrorInfo.Message := StrSubstNo(UnknownSourceTypeErr, Format(Source));
        Error(UnknownSourceTypeErrorInfo);
    end;

    /// <summary>
    /// Raised before built-in dispatch. Set IsHandled to true to skip default Item/SalesLine handling
    /// and to prevent OnInitializeFromSource from firing as the fallback.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitializeFromSource(var TempData: Codeunit "Prod. Definition Temp Data"; Source: Variant; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised when the source type is not handled natively (i.e. not Item, Stockkeeping Unit, or Sales Line).
    /// Subscribe here to support additional source types such as Purchase Line.
    /// Set IsHandled to true once the initialization is complete.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnInitializeFromSource(var TempData: Codeunit "Prod. Definition Temp Data"; Source: Variant; var IsHandled: Boolean)
    begin
    end;
}