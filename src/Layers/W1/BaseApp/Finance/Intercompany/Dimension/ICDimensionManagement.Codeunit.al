// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.Partner;
using System.Reflection;

codeunit 8408 "IC Dimension Management"
{
    var
        DimensionManagement: Codeunit DimensionManagement;

    /// <summary>
    /// Copies dimension set entries from journal lines to intercompany journal line dimensions.
    /// Converts company-specific dimension codes to intercompany dimension codes during the copy process.
    /// </summary>
    /// <param name="TableID">Source table identifier for the journal line</param>
    /// <param name="TransactionNo">Intercompany transaction number</param>
    /// <param name="PartnerCode">Intercompany partner code</param>
    /// <param name="TransactionSource">Source of the intercompany transaction</param>
    /// <param name="LineNo">Line number within the transaction</param>
    /// <param name="DimSetID">Dimension set ID containing dimensions to copy</param>
    procedure CopyJnlLineDimToICJnlDim(TableID: Integer; TransactionNo: Integer; PartnerCode: Code[20]; TransactionSource: Option; LineNo: Integer; DimSetID: Integer)
    var
        InOutBoxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        DimSetEntry: Record "Dimension Set Entry";
        ICDim: Code[20];
        ICDimValue: Code[20];
    begin
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        if DimSetEntry.FindSet() then
            repeat
                ICDim := ConvertDimtoICDim(DimSetEntry."Dimension Code");
                ICDimValue := ConvertDimValuetoICDimVal(DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                if (ICDim <> '') and (ICDimValue <> '') then begin
                    InOutBoxJnlLineDim.Init();
                    InOutBoxJnlLineDim."Table ID" := TableID;
                    InOutBoxJnlLineDim."IC Partner Code" := PartnerCode;
                    InOutBoxJnlLineDim."Transaction No." := TransactionNo;
                    InOutBoxJnlLineDim."Transaction Source" := TransactionSource;
                    InOutBoxJnlLineDim."Line No." := LineNo;
                    InOutBoxJnlLineDim."Dimension Code" := ICDim;
                    InOutBoxJnlLineDim."Dimension Value Code" := ICDimValue;
                    InOutBoxJnlLineDim.Insert();
                end;
            until DimSetEntry.Next() = 0;
    end;

    /// <summary>
    /// Copies intercompany journal line dimensions from one record set to another.
    /// Creates duplicate dimension entries for intercompany transaction processing.
    /// </summary>
    /// <param name="FromInOutBoxLineDim">Source intercompany journal line dimensions to copy from</param>
    /// <param name="ToInOutBoxlineDim">Target intercompany journal line dimensions to copy to</param>
    procedure CopyICJnlDimToICJnlDim(var FromInOutBoxLineDim: Record "IC Inbox/Outbox Jnl. Line Dim."; var ToInOutBoxlineDim: Record "IC Inbox/Outbox Jnl. Line Dim.")
    begin
        if FromInOutBoxLineDim.FindSet() then
            repeat
                ToInOutBoxlineDim := FromInOutBoxLineDim;
                ToInOutBoxlineDim.Insert();
            until FromInOutBoxLineDim.Next() = 0;
    end;

    /// <summary>
    /// Copies dimension set entries from documents to intercompany document dimensions.
    /// Converts company-specific dimension codes to intercompany dimension codes for cross-company transactions.
    /// </summary>
    /// <param name="TableID">Source table identifier for the document</param>
    /// <param name="TransactionNo">Intercompany transaction number</param>
    /// <param name="PartnerCode">Intercompany partner code</param>
    /// <param name="TransactionSource">Source of the intercompany transaction</param>
    /// <param name="LineNo">Line number within the document</param>
    /// <param name="DimSetEntryID">Dimension set ID containing dimensions to copy</param>
    procedure CopyDocDimtoICDocDim(TableID: Integer; TransactionNo: Integer; PartnerCode: Code[20]; TransactionSource: Option; LineNo: Integer; DimSetEntryID: Integer)
    var
        InOutBoxDocDim: Record "IC Document Dimension";
        DimSetEntry: Record "Dimension Set Entry";
        ICDim: Code[20];
        ICDimValue: Code[20];
    begin
        DimSetEntry.SetRange("Dimension Set ID", DimSetEntryID);
        if DimSetEntry.FindSet() then
            repeat
                ICDim := ConvertDimtoICDim(DimSetEntry."Dimension Code");
                ICDimValue := ConvertDimValuetoICDimVal(DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                if (ICDim <> '') and (ICDimValue <> '') then begin
                    InOutBoxDocDim.Init();
                    InOutBoxDocDim."Table ID" := TableID;
                    InOutBoxDocDim."IC Partner Code" := PartnerCode;
                    InOutBoxDocDim."Transaction No." := TransactionNo;
                    InOutBoxDocDim."Transaction Source" := TransactionSource;
                    InOutBoxDocDim."Line No." := LineNo;
                    InOutBoxDocDim."Dimension Code" := ICDim;
                    InOutBoxDocDim."Dimension Value Code" := ICDimValue;
                    InOutBoxDocDim.Insert();
                end;
            until DimSetEntry.Next() = 0;
    end;

    /// <summary>
    /// Copies intercompany document dimensions from one record set to another with new table and transaction source.
    /// Creates duplicate dimension entries for intercompany document processing across different table contexts.
    /// </summary>
    /// <param name="FromSourceICDocDim">Source intercompany document dimensions to copy from</param>
    /// <param name="ToSourceICDocDim">Target intercompany document dimensions to copy to</param>
    /// <param name="ToTableID">Target table identifier for the copied dimensions</param>
    /// <param name="ToTransactionSource">Target transaction source for the copied dimensions</param>
    procedure CopyICDocDimtoICDocDim(FromSourceICDocDim: Record "IC Document Dimension"; var ToSourceICDocDim: Record "IC Document Dimension"; ToTableID: Integer; ToTransactionSource: Integer)
    begin
        SetICDocDimFilters(FromSourceICDocDim, FromSourceICDocDim."Table ID", FromSourceICDocDim."Transaction No.", FromSourceICDocDim."IC Partner Code", FromSourceICDocDim."Transaction Source", FromSourceICDocDim."Line No.");
        if FromSourceICDocDim.FindSet() then
            repeat
                ToSourceICDocDim := FromSourceICDocDim;
                ToSourceICDocDim."Table ID" := ToTableID;
                ToSourceICDocDim."Transaction Source" := ToTransactionSource;
                ToSourceICDocDim.Insert();
            until FromSourceICDocDim.Next() = 0;
    end;

    /// <summary>
    /// Moves intercompany document dimensions from one record set to another with new table and transaction source.
    /// Transfers dimension entries and deletes the source records during intercompany document processing.
    /// </summary>
    /// <param name="FromSourceICDocDim">Source intercompany document dimensions to move from</param>
    /// <param name="ToSourceICDocDim">Target intercompany document dimensions to move to</param>
    /// <param name="ToTableID">Target table identifier for the moved dimensions</param>
    /// <param name="ToTransactionSource">Target transaction source for the moved dimensions</param>
    procedure MoveICDocDimtoICDocDim(FromSourceICDocDim: Record "IC Document Dimension"; var ToSourceICDocDim: Record "IC Document Dimension"; ToTableID: Integer; ToTransactionSource: Integer)
    begin
        SetICDocDimFilters(FromSourceICDocDim, FromSourceICDocDim."Table ID", FromSourceICDocDim."Transaction No.", FromSourceICDocDim."IC Partner Code", FromSourceICDocDim."Transaction Source", FromSourceICDocDim."Line No.");
        if FromSourceICDocDim.FindSet() then
            repeat
                ToSourceICDocDim := FromSourceICDocDim;
                ToSourceICDocDim."Table ID" := ToTableID;
                ToSourceICDocDim."Transaction Source" := ToTransactionSource;
                ToSourceICDocDim.Insert();
                FromSourceICDocDim.Delete();
            until FromSourceICDocDim.Next() = 0;
    end;

    /// <summary>
    /// Sets filters on intercompany document dimension record to isolate specific dimension entries.
    /// Applies standard filters for table ID, transaction number, partner code, transaction source, and line number.
    /// </summary>
    /// <param name="ICDocDim">Intercompany document dimension record to apply filters to</param>
    /// <param name="TableID">Table identifier to filter by</param>
    /// <param name="TransactionNo">Transaction number to filter by</param>
    /// <param name="PartnerCode">Intercompany partner code to filter by</param>
    /// <param name="TransactionSource">Transaction source to filter by</param>
    /// <param name="LineNo">Line number to filter by</param>
    procedure SetICDocDimFilters(var ICDocDim: Record "IC Document Dimension"; TableID: Integer; TransactionNo: Integer; PartnerCode: Code[20]; TransactionSource: Integer; LineNo: Integer)
    begin
        ICDocDim.Reset();
        ICDocDim.SetRange("Table ID", TableID);
        ICDocDim.SetRange("Transaction No.", TransactionNo);
        ICDocDim.SetRange("IC Partner Code", PartnerCode);
        ICDocDim.SetRange("Transaction Source", TransactionSource);
        ICDocDim.SetRange("Line No.", LineNo);
    end;

    /// <summary>
    /// Deletes intercompany document dimensions that match the specified criteria.
    /// Removes all dimension entries for a specific intercompany document transaction line.
    /// </summary>
    /// <param name="TableID">Table identifier to delete dimensions for</param>
    /// <param name="ICTransactionNo">Intercompany transaction number</param>
    /// <param name="ICPartnerCode">Intercompany partner code</param>
    /// <param name="TransactionSource">Transaction source type</param>
    /// <param name="LineNo">Line number within the transaction</param>
    internal procedure DeleteICDocDim(TableID: Integer; ICTransactionNo: Integer; ICPartnerCode: Code[20]; TransactionSource: Option; LineNo: Integer)
    var
        ICDocDim: Record "IC Document Dimension";
    begin
        SetICDocDimFilters(ICDocDim, TableID, ICTransactionNo, ICPartnerCode, TransactionSource, LineNo);
        if not ICDocDim.IsEmpty() then
            ICDocDim.DeleteAll();
    end;

    /// <summary>
    /// Deletes intercompany journal line dimensions that match the specified criteria.
    /// Removes all dimension entries for a specific intercompany journal line transaction.
    /// </summary>
    /// <param name="TableID">Table identifier to delete dimensions for</param>
    /// <param name="ICTransactionNo">Intercompany transaction number</param>
    /// <param name="ICPartnerCode">Intercompany partner code</param>
    /// <param name="TransactionSource">Transaction source type</param>
    /// <param name="LineNo">Line number within the transaction</param>
    internal procedure DeleteICJnlDim(TableID: Integer; ICTransactionNo: Integer; ICPartnerCode: Code[20]; TransactionSource: Option; LineNo: Integer)
    var
        ICJnlDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
    begin
        ICJnlDim.SetRange("Table ID", TableID);
        ICJnlDim.SetRange("Transaction No.", ICTransactionNo);
        ICJnlDim.SetRange("IC Partner Code", ICPartnerCode);
        ICJnlDim.SetRange("Transaction Source", TransactionSource);
        ICJnlDim.SetRange("Line No.", LineNo);
        if not ICJnlDim.IsEmpty() then
            ICJnlDim.DeleteAll();
    end;

    internal procedure ConvertICDimtoDim(FromICDimCode: Code[20]) DimCode: Code[20]
    var
        ICDim: Record "IC Dimension";
    begin
        if ICDim.Get(FromICDimCode) then
            DimCode := ICDim."Map-to Dimension Code";

        OnAfterConvertICDimtoDim(FromICDimCode, DimCode);
    end;

    internal procedure ConvertICDimValuetoDimValue(FromICDimCode: Code[20]; FromICDimValue: Code[20]) DimValueCode: Code[20]
    var
        ICDimValue: Record "IC Dimension Value";
    begin
        if ICDimValue.Get(FromICDimCode, FromICDimValue) then
            DimValueCode := ICDimValue."Map-to Dimension Value Code";

        OnAfterConvertICDimValuetoDimValue(FromICDimCode, FromICDimValue, DimValueCode);
    end;

    /// <summary>
    /// Converts a company-specific dimension code to its intercompany equivalent.
    /// Uses the dimension's mapping configuration to return the corresponding IC dimension code.
    /// </summary>
    /// <param name="FromDim">Company dimension code to convert</param>
    /// <returns>Mapped intercompany dimension code, or empty if no mapping exists</returns>
    procedure ConvertDimtoICDim(FromDim: Code[20]) ICDimCode: Code[20]
    var
        Dim: Record Dimension;
    begin
        if Dim.Get(FromDim) then
            ICDimCode := Dim."Map-to IC Dimension Code";

        OnAfterConvertDimtoICDim(FromDim, ICDimCode);
    end;

    /// <summary>
    /// Converts a company-specific dimension value to its intercompany equivalent.
    /// Uses the dimension value's mapping configuration to return the corresponding IC dimension value code.
    /// </summary>
    /// <param name="FromDim">Company dimension code containing the value</param>
    /// <param name="FromDimValue">Company dimension value code to convert</param>
    /// <returns>Mapped intercompany dimension value code, or empty if no mapping exists</returns>
    procedure ConvertDimValuetoICDimVal(FromDim: Code[20]; FromDimValue: Code[20]) ICDimValueCode: Code[20]
    var
        DimValue: Record "Dimension Value";
    begin
        OnBeforeConvertDimValuetoICDimVal(DimValue);
        if DimValue.Get(FromDim, FromDimValue) then
            ICDimValueCode := DimValue."Map-to IC Dimension Value Code";

        OnAfterConvertDimValuetoICDimVal(FromDim, FromDimValue, ICDimValueCode);
    end;

    /// <summary>
    /// Validates intercompany dimension value and checks if it exists and is not blocked.
    /// Performs validation and logging for intercompany dimension value usage.
    /// </summary>
    /// <param name="ICDimCode">Intercompany dimension code to validate</param>
    /// <param name="ICDimValCode">Intercompany dimension value code to validate</param>
    /// <returns>True if the intercompany dimension value is valid and not blocked, false otherwise</returns>
    procedure CheckICDimValue(ICDimCode: Code[20]; ICDimValCode: Code[20]): Boolean
    var
        ICDimVal: Record "IC Dimension Value";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        Result := false;
        IsHandled := false;
        OnBeforeCheckICDimValue(ICDimCode, ICDimValCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if (ICDimCode <> '') and (ICDimValCode <> '') then
            if ICDimVal.Get(ICDimCode, ICDimValCode) then begin
                if ICDimVal.Blocked then begin
                    DimensionManagement.LogError(
                      ICDimVal.RecordId, ICDimVal.FieldNo(Blocked),
                      StrSubstNo(DimensionManagement.GetDimValueBlockedErr(), ICDimVal.TableCaption(), ICDimCode, ICDimValCode), '');
                    exit(false);
                end;
                if not CheckICDimValueAllowed(ICDimVal) then begin
                    DimensionManagement.LogError(
                      ICDimVal.RecordId, ICDimVal.FieldNo("Dimension Value Type"),
                      StrSubstNo(
                        DimensionManagement.GetDimValueMustNotBeErr(), ICDimVal.TableCaption(), ICDimCode, ICDimValCode,
                        Format(ICDimVal."Dimension Value Type")),
                      '');
                    exit(false);
                end;
            end else begin
                DimensionManagement.LogError(
                  Database::"IC Dimension Value", 0,
                  StrSubstNo(DimensionManagement.GetDimValueMissingErr(), ICDimVal.TableCaption(), ICDimCode, ICDimValCode), '');
                exit(false);
            end;
        exit(true);
    end;

    local procedure CheckICDimValueAllowed(ICDimVal: Record "IC Dimension Value"): Boolean
    var
        DimValueAllowed: Boolean;
    begin
        DimValueAllowed :=
          ICDimVal."Dimension Value Type" in [ICDimVal."Dimension Value Type"::Standard, ICDimVal."Dimension Value Type"::"Begin-Total"];

        OnCheckICDimValueAllowed(ICDimVal, DimValueAllowed);

        exit(DimValueAllowed);
    end;

    /// <summary>
    /// Validates intercompany dimension and checks if it exists and is not blocked.
    /// Performs validation and logging for intercompany dimension usage.
    /// </summary>
    /// <param name="ICDimCode">Intercompany dimension code to validate</param>
    /// <returns>True if the intercompany dimension is valid and not blocked, false otherwise</returns>
    procedure CheckICDim(ICDimCode: Code[20]): Boolean
    var
        ICDim: Record "IC Dimension";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        Result := false;
        IsHandled := false;
        OnBeforeCheckICDim(ICDimCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ICDim.Get(ICDimCode) then begin
            if ICDim.Blocked then begin
                DimensionManagement.LogError(
                  ICDim.RecordId, ICDim.FieldNo(Blocked), StrSubstNo(DimensionManagement.GetDimIsBlockedErr(), ICDim.TableCaption(), ICDimCode), '');
                exit(false);
            end;
        end else begin
            DimensionManagement.LogError(
              Database::"IC Dimension", 0, StrSubstNo(DimensionManagement.GetDimIsNotFoundErr(), ICDim.TableCaption(), ICDimCode), '');
            exit(false);
        end;
        exit(true);
    end;

    /// <summary>
    /// Creates a dimension set ID from intercompany document dimensions by converting IC dimensions to company dimensions.
    /// Processes all IC document dimension entries and builds a corresponding company dimension set.
    /// </summary>
    /// <param name="ICDocDim">Intercompany document dimensions to convert</param>
    /// <returns>Dimension set ID representing the converted intercompany dimensions</returns>
    procedure CreateDimSetIDFromICDocDim(var ICDocDim: Record Microsoft.Intercompany.Dimension."IC Document Dimension"): Integer
    var
        DimValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        OnBeforeCreateDimSetIDFromICDocDim(DimValue);
        if ICDocDim.Find('-') then
            repeat
                DimValue.Get(
                  ConvertICDimtoDim(ICDocDim."Dimension Code"),
                  ConvertICDimValuetoDimValue(ICDocDim."Dimension Code", ICDocDim."Dimension Value Code"));
                DimensionManagement.CreateDimSetEntryFromDimValue(DimValue, TempDimSetEntry);
            until ICDocDim.Next() = 0;
        exit(DimensionManagement.GetDimensionSetID(TempDimSetEntry));
    end;

    /// <summary>
    /// Creates a dimension set ID from intercompany journal line dimensions by converting IC dimensions to company dimensions.
    /// Processes all IC journal line dimension entries and builds a corresponding company dimension set.
    /// </summary>
    /// <param name="ICInboxOutboxJnlLineDim">Intercompany journal line dimensions to convert</param>
    /// <returns>Dimension set ID representing the converted intercompany journal dimensions</returns>
    procedure CreateDimSetIDFromICJnlLineDim(var ICInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim."): Integer
    var
        DimValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        OnBeforeCreateDimSetIDFromICJnlLineDim(DimValue);
        if ICInboxOutboxJnlLineDim.Find('-') then
            repeat
                DimValue.Get(
                  ConvertICDimtoDim(ICInboxOutboxJnlLineDim."Dimension Code"),
                  ConvertICDimValuetoDimValue(
                    ICInboxOutboxJnlLineDim."Dimension Code", ICInboxOutboxJnlLineDim."Dimension Value Code"));
                DimensionManagement.CreateDimSetEntryFromDimValue(DimValue, TempDimSetEntry);
            until ICInboxOutboxJnlLineDim.Next() = 0;
        exit(DimensionManagement.GetDimensionSetID(TempDimSetEntry));
    end;

    /// <summary>
    /// Retrieves the last dimension error message.
    /// </summary>
    /// <returns>Error message text describing the dimension validation issue</returns>
    procedure GetDimErr() ErrorMessage: Text[250]
    begin
        DimensionManagement.FindLastErrorMessage(ErrorMessage);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvertDimtoICDim(FromDim: Code[20]; var ICDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvertDimValuetoICDimVal(FromDimCode: Code[20]; FromDimValue: Code[20]; var ICDimValueCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvertICDimtoDim(FromICDimCode: Code[20]; var DimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvertICDimValuetoDimValue(FromICDimCode: Code[20]; FromICDimValue: Code[20]; var DimValueCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckICDim(ICDimCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckICDimValue(ICDimCode: Code[20]; ICDimValCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConvertDimValuetoICDimVal(var DimValue: Record "Dimension Value")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDimSetIDFromICJnlLineDim(var DimValue: Record "Dimension Value")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDimSetIDFromICDocDim(var DimValue: Record "Dimension Value")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckICDimValueAllowed(ICDimVal: Record "IC Dimension Value"; var DimValueAllowed: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::DimensionManagement, 'OnAfterTypeToTableID1', '', true, false)]
    local procedure OnAfterTypeToTableID1(Type: Integer; var TableId: Integer)
    begin
        if Type = 6 then // "IC Dimension"
            TableId := Database::"IC Partner";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::DimensionManagement, 'OnAfterDefaultDimObjectNoWithoutGlobalDimsList', '', true, false)]
    local procedure OnAfterDefaultDimObjectNoWithoutGlobalDimsList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    begin
        DimensionManagement.DefaultDimInsertTempObject(TempAllObjWithCaption, Database::"IC Partner");
    end;

    [EventSubscriber(ObjectType::Table, Database::Dimension, 'OnAfterDeleteEvent', '', true, true)]
    local procedure OnAfterDeleteDimension(var Rec: Record Dimension; RunTrigger: Boolean)
    begin
        RemoveICDimensionMappings(Rec.Code);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Dimension Value", 'OnAfterValidateEvent', 'Dimension Code', true, true)]
    local procedure OnAfterValidateDimensionCode(var Rec: Record "Dimension Value"; var xRec: Record "Dimension Value"; CurrFieldNo: Integer)
    var
        Dimension: Record Dimension;
    begin
        if Dimension.Get(Rec."Dimension Code") then begin
            Rec.Validate("Map-to IC Dimension Code", Dimension."Map-to IC Dimension Code");
            Rec."Dimension Id" := Dimension.SystemId;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Dimension Value", 'OnAfterDeleteEvent', '', true, true)]
    local procedure OnAfterDeleteDimensionValue(var Rec: Record "Dimension Value"; RunTrigger: Boolean)
    begin
        RemoveICDimensionValueMappings(Rec.Code);
    end;

    local procedure RemoveICDimensionValueMappings(DimensionValueCode: Code[20])
    var
        ICDimensionValue: Record "IC Dimension Value";
    begin
        ICDimensionValue.SetRange("Map-to Dimension Value Code", DimensionValueCode);
        if not ICDimensionValue.IsEmpty() then
            ICDimensionValue.ModifyAll("Map-to Dimension Value Code", '');
    end;

    local procedure RemoveICDimensionMappings(DimensionCode: Code[20])
    var
        ICDimension: Record "IC Dimension";
        ICDimensionValue: Record "IC Dimension Value";
    begin
        ICDimension.SetRange("Map-to Dimension Code", DimensionCode);
        if not ICDimension.IsEmpty() then begin
            ICDimension.FindSet();
            repeat
                ICDimensionValue.SetRange("Dimension Code", ICDimension.Code);
                if not ICDimensionValue.IsEmpty() then begin
                    ICDimensionValue.FindSet();
                    repeat
                        if ICDimensionValue."Map-to Dimension Code" <> '' then begin
                            ICDimensionValue."Map-to Dimension Code" := '';
                            ICDimensionValue."Map-to Dimension Value Code" := '';
                            ICDimensionValue.Modify();
                        end;
                    until ICDimensionValue.Next() = 0;
                end;
                ICDimension."Map-to Dimension Code" := '';
                ICDimension.Modify();
            until ICDimension.Next() = 0;
        end;
    end;

}