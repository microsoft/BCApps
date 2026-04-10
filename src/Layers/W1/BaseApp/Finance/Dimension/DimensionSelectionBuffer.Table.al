// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Temporary buffer table for dimension selection operations in analysis views and reporting scenarios.
/// Manages dimension selection state, filters, and level settings for analysis view configuration and dimension-based reporting.
/// </summary>
/// <remarks>
/// Used in analysis view setup, dimension selection pages, and reporting scenarios requiring dynamic dimension filtering.
/// Supports multiple selection types including multiple selection, change selection, and level-based selection.
/// Integrates with analysis views, G/L accounts, and cash flow accounts for comprehensive dimension management.
/// </remarks>
table 368 "Dimension Selection Buffer"
{
    Caption = 'Dimension Selection Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Code identifying the dimension or special analysis element being selected.
        /// </summary>
        field(1; "Code"; Text[30])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code for the dimension.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Descriptive name of the dimension or analysis element for user interface display.
        /// </summary>
        field(2; Description; Text[30])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the dimension.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether this dimension is selected for inclusion in analysis or reporting.
        /// </summary>
        field(3; Selected; Boolean)
        {
            Caption = 'Selected';
            ToolTip = 'Specifies that this dimension will be included.';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                "New Dimension Value Code" := '';
                "Dimension Value Filter" := '';
                Level := Level::" ";
            end;
        }
        /// <summary>
        /// New dimension value code for dimension change operations and value substitutions.
        /// </summary>
        field(4; "New Dimension Value Code"; Code[20])
        {
            Caption = 'New Dimension Value Code';
            ToolTip = 'Specifies the new dimension value to that you are changing to.';
            DataClassification = SystemMetadata;
            TableRelation = if (Code = const('G/L Account')) "G/L Account"."No."
            else
            if (Code = const('Business Unit')) "Business Unit".Code
            else
            "Dimension Value".Code where("Dimension Code" = field(Code), Blocked = const(false));

            trigger OnValidate()
            begin
                Selected := true;
            end;
        }
        /// <summary>
        /// Filter expression for dimension values used in analysis and reporting operations.
        /// </summary>
        field(5; "Dimension Value Filter"; Code[250])
        {
            Caption = 'Dimension Value Filter';
            ToolTip = 'Specifies the dimension value that the analysis view is based on.';
            DataClassification = SystemMetadata;
            TableRelation = if ("Filter Lookup Table No." = const(15)) "G/L Account"."No."
            else
            if ("Filter Lookup Table No." = const(220)) "Business Unit".Code
            else
            if ("Filter Lookup Table No." = const(841)) "Cash Flow Account"."No."
            else
            if ("Filter Lookup Table No." = const(840)) "Cash Flow Forecast"."No."
            else
            "Dimension Value".Code where("Dimension Code" = field(Code), Blocked = const(false));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if (Level = Level::" ") and ("Dimension Value Filter" = '') then
                    Selected := false
                else
                    Selected := true;
            end;
        }
        /// <summary>
        /// Analysis level classification for hierarchical dimension analysis and level-based filtering.
        /// </summary>
        field(6; Level; Option)
        {
            Caption = 'Level';
            ToolTip = 'Specifies the level for the selected dimension.';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Level 1,Level 2,Level 3,Level 4';
            OptionMembers = " ","Level 1","Level 2","Level 3","Level 4";

            trigger OnValidate()
            begin
                if (Level = Level::" ") and ("Dimension Value Filter" = '') then
                    Selected := false
                else
                    Selected := true;
            end;
        }
        /// <summary>
        /// Table number for filter lookup operations, determining the source table for dimension value filtering.
        /// </summary>
        field(7; "Filter Lookup Table No."; Integer)
        {
            Caption = 'Filter Lookup Table No.';
            DataClassification = SystemMetadata;
            Editable = false;
            InitValue = 349;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Level, "Code")
        {
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Another user has modified the selected dimensions for the %1 field after you retrieved it from the database.\';
        Text002: Label 'Enter your changes again in the Dimension Selection window by clicking the AssistButton on the %1 field. ';
#pragma warning restore AA0470
#pragma warning restore AA0074

    /// <summary>
    /// Opens dimension selection page for multiple dimension selection and updates the selected dimension text.
    /// Allows users to select multiple dimensions for analysis views and reporting scenarios.
    /// </summary>
    /// <param name="ObjectType">Type of object for which dimensions are being selected</param>
    /// <param name="ObjectID">ID of the object for which dimensions are being selected</param>
    /// <param name="SelectedDimText">Text containing the selected dimension codes, updated after selection</param>
    /// <remarks>
    /// Extensibility: OnBeforeInsertDimSelBufForDimSelectionMultiple event allows custom dimension buffer setup.
    /// Used in analysis view configuration and reporting scenarios requiring multiple dimension selection.
    /// </remarks>
    procedure SetDimSelectionMultiple(ObjectType: Integer; ObjectID: Integer; var SelectedDimText: Text[250])
    var
        Dim: Record Dimension;
        TempDimSelectionBuf: Record "Dimension Selection Buffer" temporary;
        DimSelectionMultiple: Page "Dimension Selection-Multiple";
    begin
        Clear(DimSelectionMultiple);
        if Dim.Find('-') then
            repeat
                InsertDimSelBufForDimSelectionMultiple(DimSelectionMultiple, Dim, ObjectType, ObjectID)
            until Dim.Next() = 0;

        if DimSelectionMultiple.RunModal() = ACTION::OK then begin
            DimSelectionMultiple.GetDimSelBuf(TempDimSelectionBuf);
            SetDimSelection(ObjectType, ObjectID, '', SelectedDimText, TempDimSelectionBuf);
        end;
    end;

    local procedure InsertDimSelBufForDimSelectionMultiple(var DimSelectionMultiple: Page "Dimension Selection-Multiple"; Dimension: Record Dimension; ObjectType: Integer; ObjectID: Integer)
    var
        SelectedDim: Record "Selected Dimension";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertDimSelBufForDimSelectionMultiple(DimSelectionMultiple, Dimension, ObjectType, ObjectID, IsHandled);
        if IsHandled then
            exit;

        DimSelectionMultiple.InsertDimSelBuf(SelectedDim.Get(UserId, ObjectType, ObjectID, '', Dimension.Code), Dimension.Code, Dimension.GetMLName(GlobalLanguage));
    end;

    /// <summary>
    /// Opens a dimension selection page allowing users to change dimension selections for a specific object.
    /// Updates the selected dimensions text based on user choices and commits changes to the selected dimensions table.
    /// </summary>
    /// <param name="ObjectType">Type of object for which dimensions are being selected</param>
    /// <param name="ObjectID">ID of the object for which dimensions are being selected</param>
    /// <param name="SelectedDimText">Text representation of currently selected dimensions, updated with new selections</param>
    /// <remarks>
    /// Uses modal page interaction to present available dimensions and capture user selections.
    /// Integrates with Selected Dimension table for persistence and provides extensibility through integration events.
    /// </remarks>
    procedure SetDimSelectionChange(ObjectType: Integer; ObjectID: Integer; var SelectedDimText: Text[250])
    var
        Dim: Record Dimension;
        TempDimSelectionBuf: Record "Dimension Selection Buffer" temporary;
        DimSelectionChange: Page "Dimension Selection-Change";
    begin
        Clear(DimSelectionChange);
        if Dim.Find('-') then
            repeat
                InsertDimSelBufForDimSelectionChange(DimSelectionChange, Dim, ObjectType, ObjectID);
            until Dim.Next() = 0;

        if DimSelectionChange.RunModal() = ACTION::OK then begin
            DimSelectionChange.GetDimSelBuf(TempDimSelectionBuf);
            SetDimSelection(ObjectType, ObjectID, '', SelectedDimText, TempDimSelectionBuf);
        end;

        OnAfterSetDimSelectionChange(Rec, TempDimSelectionBuf);
    end;

    local procedure InsertDimSelBufForDimSelectionChange(var DimSelectionChange: Page "Dimension Selection-Change"; Dimension: Record Dimension; ObjectType: Integer; ObjectID: Integer)
    var
        SelectedDim: Record "Selected Dimension";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertDimSelBufForDimSelectionChange(DimSelectionChange, Dimension, ObjectType, ObjectID, IsHandled);
        if IsHandled then
            exit;

        DimSelectionChange.InsertDimSelBuf(
          SelectedDim.Get(UserId, ObjectType, ObjectID, '', Dimension.Code),
          Dimension.Code, Dimension.GetMLName(GlobalLanguage),
          SelectedDim."New Dimension Value Code",
          SelectedDim."Dimension Value Filter");
    end;

    /// <summary>
    /// Compares current dimension selection text with stored dimension selections to ensure data consistency.
    /// Validates that the provided dimension text matches the dimensions stored in the Selected Dimension table.
    /// </summary>
    /// <param name="ObjectType">Type of object for which dimensions are being compared</param>
    /// <param name="ObjectID">ID of the object for which dimensions are being compared</param>
    /// <param name="AnalysisViewCode">Analysis view code for context-specific dimension validation</param>
    /// <param name="SelectedDimText">Current dimension text to be validated</param>
    /// <param name="DimTextFieldName">Name of the field containing dimension text for error messages</param>
    /// <remarks>
    /// Throws error if dimension text does not match stored selections, ensuring data integrity across dimension operations.
    /// Supports analysis view specific validation and provides extensibility through integration events.
    /// </remarks>
    procedure CompareDimText(ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]; SelectedDimText: Text[250]; DimTextFieldName: Text[100])
    var
        SelectedDim: Record "Selected Dimension";
        SelectedDimTextFromDb: Text[250];
    begin
        SelectedDimTextFromDb := '';
        SelectedDim.SetCurrentKey(
          "User ID", "Object Type", "Object ID", "Analysis View Code", Level, "Dimension Code");
        SetDefaultRangeOnSelectedDimTable(SelectedDim, ObjectType, ObjectID, AnalysisViewCode);
        OnCompareDimTextOnBeforeSelectedDimFind(SelectedDim, ObjectType, ObjectID);
        if SelectedDim.Find('-') then
            repeat
                AddDimCodeToText(SelectedDim."Dimension Code", SelectedDimTextFromDb);
            until SelectedDim.Next() = 0;
        if SelectedDimTextFromDb <> SelectedDimText then
            Error(
              Text000 +
              Text002,
              DimTextFieldName);
    end;

    local procedure AddDimCodeToText(DimCode: Code[30]; var Text: Text[250])
    begin
        if Text = '' then
            Text := DimCode
        else
            if (StrLen(Text) + StrLen(DimCode)) <= (MaxStrLen(Text) - 4) then
                Text := StrSubstNo('%1;%2', Text, DimCode)
            else
                if CopyStr(Text, StrLen(Text) - 2, 3) <> '...' then
                    Text := StrSubstNo('%1;...', Text)
    end;

    /// <summary>
    /// Updates dimension selections for a specific object based on user choices from the dimension selection buffer.
    /// Replaces existing selections with new ones and updates the dimension text representation.
    /// </summary>
    /// <param name="ObjectType">Type of object for which dimensions are being set</param>
    /// <param name="ObjectID">ID of the object for which dimensions are being set</param>
    /// <param name="AnalysisViewCode">Analysis view code for context-specific dimension management</param>
    /// <param name="SelectedDimText">Text representation of selected dimensions, updated to reflect new selections</param>
    /// <param name="DimSelectionBuf">Buffer containing dimension selections to be applied</param>
    /// <remarks>
    /// Clears existing selections and creates new Selected Dimension records based on buffer contents.
    /// Provides extensibility through integration events for validation and custom processing.
    /// </remarks>
    procedure SetDimSelection(ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]; var SelectedDimText: Text[250]; var DimSelectionBuf: Record "Dimension Selection Buffer")
    var
        SelectedDim: Record "Selected Dimension";
    begin
        SetDefaultRangeOnSelectedDimTable(SelectedDim, ObjectType, ObjectID, AnalysisViewCode);
        OnSetDimSelectionOnAfterSetDefaultRangeOnSelectedDimTable(SelectedDim, ObjectType, ObjectID);
        SelectedDim.DeleteAll();
        SelectedDimText := '';
        DimSelectionBuf.SetCurrentKey(Level, Code);
        DimSelectionBuf.SetRange(Selected, true);
        if DimSelectionBuf.Find('-') then begin
            repeat
                SelectedDim."User ID" := CopyStr(UserId(), 1, MaxStrLen(SelectedDim."User ID"));
                SelectedDim."Object Type" := ObjectType;
                SelectedDim."Object ID" := ObjectID;
                SelectedDim."Analysis View Code" := AnalysisViewCode;
                SelectedDim."Dimension Code" := DimSelectionBuf.Code;
                SelectedDim."New Dimension Value Code" := DimSelectionBuf."New Dimension Value Code";
                SelectedDim."Dimension Value Filter" := DimSelectionBuf."Dimension Value Filter";
                SelectedDim.Level := DimSelectionBuf.Level;
                OnSetDimSelectionOnBeforeSelectedDimInsert(SelectedDim, ObjectType, ObjectID);
                SelectedDim.Insert();
            until DimSelectionBuf.Next() = 0;
            SelectedDimText := GetDimSelectionText(ObjectType, ObjectID, AnalysisViewCode);
        end;
    end;

    /// <summary>
    /// Sets dimension selection level for G/L Account based analysis with manual dimension selection.
    /// Provides G/L Account specific dimension management without automatic dimension assignment.
    /// </summary>
    /// <param name="ObjectType">Type of object for which dimensions are being set</param>
    /// <param name="ObjectID">ID of the object for which dimensions are being set</param>
    /// <param name="AnalysisViewCode">Analysis view code for G/L Account dimension analysis</param>
    /// <param name="SelectedDimText">Text representation of selected dimensions, updated with new selections</param>
    /// <remarks>
    /// Specialized for G/L Account analysis scenarios with manual dimension control.
    /// Delegates to SetDimSelectionLevelWithAutoSet with G/L Account context and AutoSet disabled.
    /// </remarks>
    procedure SetDimSelectionLevelGLAcc(ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]; var SelectedDimText: Text[250])
    var
        GLAcc: Record "G/L Account";
    begin
        SetDimSelectionLevelWithAutoSet(ObjectType, ObjectID, AnalysisViewCode, SelectedDimText, GLAcc.TableCaption(), false);
    end;

    /// <summary>
    /// Sets dimension selection level for G/L Account based analysis with automatic dimension assignment.
    /// Provides G/L Account specific dimension management with automatic dimension selection based on analysis view configuration.
    /// </summary>
    /// <param name="ObjectType">Type of object for which dimensions are being set</param>
    /// <param name="ObjectID">ID of the object for which dimensions are being set</param>
    /// <param name="AnalysisViewCode">Analysis view code for G/L Account dimension analysis</param>
    /// <param name="SelectedDimText">Text representation of selected dimensions, updated with automatic selections</param>
    /// <remarks>
    /// Specialized for G/L Account analysis scenarios with automatic dimension assignment.
    /// Delegates to SetDimSelectionLevelWithAutoSet with G/L Account context and AutoSet enabled.
    /// </remarks>
    procedure SetDimSelectionLevelGLAccAutoSet(ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]; var SelectedDimText: Text[250])
    var
        GLAcc: Record "G/L Account";
    begin
        SetDimSelectionLevelWithAutoSet(ObjectType, ObjectID, AnalysisViewCode, SelectedDimText, GLAcc.TableCaption(), true);
    end;

    /// <summary>
    /// Sets dimension selection level for Cash Flow Account based analysis with manual dimension selection.
    /// Provides Cash Flow Account specific dimension management without automatic dimension assignment.
    /// </summary>
    /// <param name="ObjectType">Type of object for which dimensions are being set</param>
    /// <param name="ObjectID">ID of the object for which dimensions are being set</param>
    /// <param name="AnalysisViewCode">Analysis view code for Cash Flow Account dimension analysis</param>
    /// <param name="SelectedDimText">Text representation of selected dimensions, updated with new selections</param>
    /// <remarks>
    /// Specialized for Cash Flow Account analysis scenarios with manual dimension control.
    /// Delegates to SetDimSelectionLevelWithAutoSet with Cash Flow Account context and AutoSet disabled.
    /// </remarks>
    procedure SetDimSelectionLevelCFAcc(ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]; var SelectedDimText: Text[250])
    var
        CFAcc: Record "Cash Flow Account";
    begin
        SetDimSelectionLevelWithAutoSet(ObjectType, ObjectID, AnalysisViewCode, SelectedDimText, CFAcc.TableCaption(), false);
    end;

    local procedure SetDimSelectionLevelWithAutoSet(ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]; var SelectedDimText: Text[250]; AccTableCaption: Text[30]; AutoSet: Boolean)
    var
        SelectedDim: Record "Selected Dimension";
        AnalysisView: Record "Analysis View";
        Dim: Record Dimension;
        TempDimSelectionBuf: Record "Dimension Selection Buffer" temporary;
        DimSelectionLevel: Page "Dimension Selection-Level";
        SelectedDimLevel: Option;
        GetSelectedDim: Boolean;
        Finished: Boolean;
    begin
        Clear(DimSelectionLevel);
        if AnalysisView.Get(AnalysisViewCode) then begin
            if Dim.Get(AnalysisView."Dimension 1 Code") then begin
                GetSelectedDim := SelectedDim.Get(UserId, ObjectType, ObjectID, AnalysisViewCode, Dim.Code);
                if AutoSet and not GetSelectedDim then begin
                    SelectedDimLevel := SelectedDim.Level::"Level 2";
                    GetSelectedDim := true;
                end else
                    SelectedDimLevel := SelectedDim.Level;

                DimSelectionLevel.InsertDimSelBuf(
                  GetSelectedDim,
                  Dim.Code, Dim.GetMLName(GlobalLanguage),
                  SelectedDim."Dimension Value Filter", SelectedDimLevel);
            end;

            if Dim.Get(AnalysisView."Dimension 2 Code") then
                DimSelectionLevel.InsertDimSelBuf(
                  SelectedDim.Get(UserId, ObjectType, ObjectID, AnalysisViewCode, Dim.Code),
                  Dim.Code, Dim.GetMLName(GlobalLanguage),
                  SelectedDim."Dimension Value Filter", SelectedDim.Level);

            if Dim.Get(AnalysisView."Dimension 3 Code") then
                DimSelectionLevel.InsertDimSelBuf(
                  SelectedDim.Get(UserId, ObjectType, ObjectID, AnalysisViewCode, Dim.Code),
                  Dim.Code, Dim.GetMLName(GlobalLanguage),
                  SelectedDim."Dimension Value Filter", SelectedDim.Level);

            if Dim.Get(AnalysisView."Dimension 4 Code") then
                DimSelectionLevel.InsertDimSelBuf(
                  SelectedDim.Get(UserId, ObjectType, ObjectID, AnalysisViewCode, Dim.Code),
                  Dim.Code, Dim.GetMLName(GlobalLanguage),
                  SelectedDim."Dimension Value Filter", SelectedDim.Level);

            GetSelectedDim := SelectedDim.Get(UserId, ObjectType, ObjectID, AnalysisViewCode, AccTableCaption);
            if AutoSet and not GetSelectedDim then
                SelectedDimLevel := SelectedDim.Level::"Level 1"
            else
                SelectedDimLevel := SelectedDim.Level;

            DimSelectionLevel.InsertDimSelBuf(
              GetSelectedDim,
              AccTableCaption, AccTableCaption,
              SelectedDim."Dimension Value Filter", SelectedDimLevel);
        end;

        if not AutoSet then
            Finished := DimSelectionLevel.RunModal() = ACTION::OK
        else
            Finished := true;

        if Finished then begin
            DimSelectionLevel.GetDimSelBuf(TempDimSelectionBuf);
            SetDimSelection(ObjectType, ObjectID, AnalysisViewCode, SelectedDimText, TempDimSelectionBuf);
        end;
    end;

    /// <summary>
    /// Retrieves the text representation of currently selected dimensions for a specific object and analysis view.
    /// Builds dimension code list from Selected Dimension table records.
    /// </summary>
    /// <param name="ObjectType">Type of object for which dimension text is being retrieved</param>
    /// <param name="ObjectID">ID of the object for which dimension text is being retrieved</param>
    /// <param name="AnalysisViewCode">Analysis view code for context-specific dimension retrieval</param>
    /// <returns>Semicolon-separated text representation of selected dimension codes</returns>
    /// <remarks>
    /// Constructs dimension text by concatenating dimension codes from Selected Dimension records.
    /// Used for display purposes and dimension selection validation across analysis operations.
    /// </remarks>
    procedure GetDimSelectionText(ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]): Text[250]
    var
        SelectedDim: Record "Selected Dimension";
        SelectedDimText: Text[250];
    begin
        SetDefaultRangeOnSelectedDimTable(SelectedDim, ObjectType, ObjectID, AnalysisViewCode);
        SelectedDim.SetCurrentKey("User ID", "Object Type", "Object ID", "Analysis View Code", Level, "Dimension Code");
        if SelectedDim.Find('-') then
            repeat
                AddDimCodeToText(SelectedDim."Dimension Code", SelectedDimText);
            until SelectedDim.Next() = 0;
        exit(SelectedDimText);
    end;

    local procedure SetDefaultRangeOnSelectedDimTable(var SelectedDim: Record "Selected Dimension"; ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10])
    begin
        SelectedDim.SetRange("User ID", UserId);
        SelectedDim.SetRange("Object Type", ObjectType);
        SelectedDim.SetRange("Object ID", ObjectID);
        SelectedDim.SetRange("Analysis View Code", AnalysisViewCode);
    end;

    /// <summary>
    /// Integration event raised after completing dimension selection change operations.
    /// Provides extensibility for custom processing after dimension selection modifications.
    /// </summary>
    /// <param name="DimensionSelectionBuffer">Current dimension selection buffer record context</param>
    /// <param name="TheDimSelectionBuf">Temporary dimension selection buffer with updated selections</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDimSelectionChange(var DimensionSelectionBuffer: Record "Dimension Selection Buffer"; var TheDimSelectionBuf: Record "Dimension Selection Buffer" temporary)
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting dimension selection buffer records for dimension selection change operations.
    /// Allows custom validation and preprocessing before dimension buffer creation.
    /// </summary>
    /// <param name="DimSelectionChange">Dimension Selection-Change page instance</param>
    /// <param name="Dimension">Dimension record being processed</param>
    /// <param name="ObjectType">Type of object for dimension selection</param>
    /// <param name="ObjectID">ID of object for dimension selection</param>
    /// <param name="IsHandled">Set to true to skip standard processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDimSelBufForDimSelectionChange(var DimSelectionChange: Page "Dimension Selection-Change"; Dimension: Record Dimension; ObjectType: Integer; ObjectID: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting dimension selection buffer records for multiple dimension selection operations.
    /// Allows custom validation and preprocessing before dimension buffer creation in multiple selection scenarios.
    /// </summary>
    /// <param name="DimSelectionMultiple">Dimension Selection-Multiple page instance</param>
    /// <param name="Dimension">Dimension record being processed</param>
    /// <param name="ObjectType">Type of object for dimension selection</param>
    /// <param name="ObjectID">ID of object for dimension selection</param>
    /// <param name="IsHandled">Set to true to skip standard processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDimSelBufForDimSelectionMultiple(var DimSelectionMultiple: Page "Dimension Selection-Multiple"; Dimension: Record Dimension; ObjectType: Integer; ObjectID: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised in CompareDimText before searching Selected Dimension records.
    /// Enables custom filtering and validation before dimension text comparison operations.
    /// </summary>
    /// <param name="SelectedDimension">Selected Dimension record with applied filters</param>
    /// <param name="ObjectType">Type of object for dimension comparison</param>
    /// <param name="ObjectID">ID of object for dimension comparison</param>
    [IntegrationEvent(false, false)]
    local procedure OnCompareDimTextOnBeforeSelectedDimFind(var SelectedDimension: Record "Selected Dimension"; ObjectType: Integer; ObjectID: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised after setting default range on Selected Dimension table during SetDimSelection operations.
    /// Allows additional filtering and validation before dimension selection processing.
    /// </summary>
    /// <param name="SelectedDimension">Selected Dimension record with default range applied</param>
    /// <param name="ObjectType">Type of object for dimension selection</param>
    /// <param name="ObjectID">ID of object for dimension selection</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetDimSelectionOnAfterSetDefaultRangeOnSelectedDimTable(var SelectedDimension: Record "Selected Dimension"; ObjectType: Integer; ObjectID: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting Selected Dimension records during SetDimSelection operations.
    /// Enables custom validation and modification of dimension selection data before persistence.
    /// </summary>
    /// <param name="SelectedDimension">Selected Dimension record to be inserted</param>
    /// <param name="ObjectType">Type of object for dimension selection</param>
    /// <param name="ObjectID">ID of object for dimension selection</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetDimSelectionOnBeforeSelectedDimInsert(var SelectedDimension: Record "Selected Dimension"; ObjectType: Integer; ObjectID: Integer)
    begin
    end;
}

