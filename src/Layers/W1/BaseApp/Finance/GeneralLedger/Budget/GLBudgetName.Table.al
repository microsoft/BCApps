// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;

/// <summary>
/// Defines budget templates with configurable dimension structures for creating multi-dimensional budget scenarios.
/// Master table that controls budget entry validation rules and dimensional analysis capabilities.
/// </summary>
/// <remarks>
/// Key relationships: G/L Budget Entry (details), Dimension Values (structure).
/// Integration: Budget analysis workflows and Excel import/export dimension validation.
/// Extensibility: OnValidate events for custom dimension validation and budget structure rules.
/// </remarks>
table 95 "G/L Budget Name"
{
    Caption = 'G/L Budget Name';
    LookupPageID = "G/L Budget Names";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the budget name that serves as the primary key and reference for budget entries.
        /// </summary>
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the general ledger budget.';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive text explaining the purpose and scope of the budget for user identification.
        /// </summary>
        field(2; Description; Text[80])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the general ledger budget name.';
        }
        /// <summary>
        /// Indicates whether the budget is blocked from further modifications or new entry creation.
        /// </summary>
        field(3; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
        }
        /// <summary>
        /// First custom dimension code that can be used for budget-specific analysis beyond global dimensions.
        /// </summary>
        field(4; "Budget Dimension 1 Code"; Code[20])
        {
            Caption = 'Budget Dimension 1 Code';
            ToolTip = 'Specifies a code for a budget dimension. You can specify four additional dimensions on each budget that you create.';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if "Budget Dimension 1 Code" <> xRec."Budget Dimension 1 Code" then
                    if Dim.CheckIfDimUsed("Budget Dimension 1 Code", Enum::"Dim Type Checked".FromInteger(9), Name, '', 0) then
                        Error(Text000, Dim.GetCheckDimErr());
            end;
        }
        /// <summary>
        /// Second custom dimension code that can be used for budget-specific analysis beyond global dimensions.
        /// </summary>
        field(5; "Budget Dimension 2 Code"; Code[20])
        {
            Caption = 'Budget Dimension 2 Code';
            ToolTip = 'Specifies a code for a budget dimension. You can specify four additional dimensions on each budget that you create.';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if "Budget Dimension 2 Code" <> xRec."Budget Dimension 2 Code" then
                    if Dim.CheckIfDimUsed("Budget Dimension 2 Code", Enum::"Dim Type Checked".FromInteger(10), Name, '', 0) then
                        Error(Text000, Dim.GetCheckDimErr());
            end;
        }
        /// <summary>
        /// Third custom dimension code that can be used for budget-specific analysis beyond global dimensions.
        /// </summary>
        field(6; "Budget Dimension 3 Code"; Code[20])
        {
            Caption = 'Budget Dimension 3 Code';
            ToolTip = 'Specifies a code for a budget dimension. You can specify four additional dimensions on each budget that you create.';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if "Budget Dimension 3 Code" <> xRec."Budget Dimension 3 Code" then
                    if Dim.CheckIfDimUsed("Budget Dimension 3 Code", Enum::"Dim Type Checked".FromInteger(11), Name, '', 0) then
                        Error(Text000, Dim.GetCheckDimErr());
            end;
        }
        /// <summary>
        /// Fourth custom dimension code that can be used for budget-specific analysis beyond global dimensions.
        /// </summary>
        field(7; "Budget Dimension 4 Code"; Code[20])
        {
            Caption = 'Budget Dimension 4 Code';
            ToolTip = 'Specifies a code for a budget dimension. You can specify four additional dimensions on each budget that you create.';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if "Budget Dimension 4 Code" <> xRec."Budget Dimension 4 Code" then
                    if Dim.CheckIfDimUsed("Budget Dimension 4 Code", Enum::"Dim Type Checked".FromInteger(12), Name, '', 0) then
                        Error(Text000, Dim.GetCheckDimErr());
            end;
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
    begin
        TestField(Blocked, false);

        AnalysisViewBudgetEntry.SetRange("Budget Name", Name);
        AnalysisViewBudgetEntry.DeleteAll();

        GLBudgetEntry.SetCurrentKey("Budget Name");
        GLBudgetEntry.SetRange("Budget Name", Name);
        GLBudgetEntry.DeleteAll();

    end;

    trigger OnModify()
    var
        ShouldUpdateDimensions: Boolean;
    begin
        ShouldUpdateDimensions := ("Budget Dimension 1 Code" <> xRec."Budget Dimension 1 Code") or
           ("Budget Dimension 2 Code" <> xRec."Budget Dimension 2 Code") or
           ("Budget Dimension 3 Code" <> xRec."Budget Dimension 3 Code") or
           ("Budget Dimension 4 Code" <> xRec."Budget Dimension 4 Code");
        OnOnModifyOnAfterCalcShouldUpdateDimensions(Rec, xRec, ShouldUpdateDimensions);
        if ShouldUpdateDimensions then
            UpdateGLBudgetEntryDim();
    end;

    var
        Dim: Record Dimension;
        DimSetEntry: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1\You cannot use the same dimension twice in the same budget.';
#pragma warning restore AA0470
        Text001: Label 'Updating budget entries @1@@@@@@@@@@@@@@@@@@';
#pragma warning restore AA0074

    local procedure UpdateGLBudgetEntryDim()
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        Window: Dialog;
        TotalCount: Integer;
        i: Integer;
        T0: Time;
    begin
        GLBudgetEntry.SetCurrentKey("Budget Name");
        GLBudgetEntry.SetRange("Budget Name", Name);
        GLBudgetEntry.SetFilter("Dimension Set ID", '<>%1', 0);
        TotalCount := Count;
        Window.Open(Text001);
        T0 := Time;
        GLBudgetEntry.LockTable();
        if GLBudgetEntry.FindSet() then
            repeat
                i := i + 1;
                if Time > T0 + 750 then begin
                    Window.Update(1, 10000 * i div TotalCount);
                    T0 := Time;
                end;
                GLBudgetEntry."Budget Dimension 1 Code" := GetDimValCode(GLBudgetEntry."Dimension Set ID", "Budget Dimension 1 Code");
                GLBudgetEntry."Budget Dimension 2 Code" := GetDimValCode(GLBudgetEntry."Dimension Set ID", "Budget Dimension 2 Code");
                GLBudgetEntry."Budget Dimension 3 Code" := GetDimValCode(GLBudgetEntry."Dimension Set ID", "Budget Dimension 3 Code");
                GLBudgetEntry."Budget Dimension 4 Code" := GetDimValCode(GLBudgetEntry."Dimension Set ID", "Budget Dimension 4 Code");
                OnUpdateGLBudgetEntryDimOnBeforeModify(Rec, GLBudgetEntry);
                GLBudgetEntry.Modify();
            until GLBudgetEntry.Next() = 0;
        Window.Close();
    end;

    local procedure GetDimValCode(DimSetID: Integer; DimCode: Code[20]): Code[20]
    begin
        if DimCode = '' then
            exit('');
        if TempDimSetEntry.Get(DimSetID, DimCode) then
            exit(TempDimSetEntry."Dimension Value Code");
        if DimSetEntry.Get(DimSetID, DimCode) then
            TempDimSetEntry := DimSetEntry
        else begin
            TempDimSetEntry.Init();
            TempDimSetEntry."Dimension Set ID" := DimSetID;
            TempDimSetEntry."Dimension Code" := DimCode;
        end;
        TempDimSetEntry.Insert();
        exit(TempDimSetEntry."Dimension Value Code")
    end;

    /// <summary>
    /// Integration event raised during modify to determine if dimensions should be updated.
    /// Allows subscribers to customize the logic for when budget entry dimensions need updating.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnOnModifyOnAfterCalcShouldUpdateDimensions(var GLBudgetName: Record "G/L Budget Name"; xGLBudgetName: Record "G/L Budget Name"; var ShouldUpdateDimensions: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before modifying G/L Budget Entry dimensions during budget name updates.
    /// Allows subscribers to perform additional processing before budget entry dimension changes.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateGLBudgetEntryDimOnBeforeModify(var GLBudgetName: Record "G/L Budget Name"; var GLBudgetEntry: Record "G/L Budget Entry")
    begin
    end;

}

