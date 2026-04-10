// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Table Dimension (ID 348).
/// This table stores the master data for dimensions, which are used to analyze transactions and provide additional insight into business data.
/// Dimensions allow for multi-dimensional analysis of financial data and can be used in analysis views, budgets, and reporting.
/// </summary>
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Intercompany.Dimension;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.Globalization;

/// <summary>
/// Table Dimension (ID 348).
/// Stores the master data for dimensions used for financial analysis.
/// Dimensions provide a way to analyze business transactions across different business criteria.
/// </summary>
table 348 Dimension
{
    Caption = 'Dimension';
    DataCaptionFields = "Code", Name;
    DrillDownPageID = "Dimension List";
    LookupPageID = "Dimension List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// The unique code that identifies the dimension.
        /// This field cannot be blank and cannot use reserved system names.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code for the dimension.';
            NotBlank = true;

            trigger OnValidate()
            var
                GLAcc: Record "G/L Account";
                BusUnit: Record "Business Unit";
                Item: Record Item;
                Location: Record Location;
            begin
                if (UpperCase(Code) = UpperCase(GLAcc.TableCaption())) or
                   (UpperCase(Code) = UpperCase(BusUnit.TableCaption())) or
                   (UpperCase(Code) = UpperCase(Item.TableCaption())) or
                   (UpperCase(Code) = UpperCase(Location.TableCaption())) or
                   (UpperCase(Code) = UpperCase(Text006))
                then
                    Error(Text007, FieldCaption(Code), GLAcc.TableCaption(), BusUnit.TableCaption(), Item.TableCaption(), Location.TableCaption());

                UpdateText(Code, '', Name);
                UpdateText(Code, Text008, "Code Caption");
                UpdateText(Code, Text009, "Filter Caption");
            end;
        }
        /// <summary>
        /// The descriptive name of the dimension that appears in the user interface.
        /// This name should clearly describe what the dimension represents.
        /// </summary>
        field(2; Name; Text[30])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the dimension code you enter in the Code field.';
        }
        /// <summary>
        /// The caption used for dimension code fields in forms and reports.
        /// If not specified, defaults to the dimension code with proper formatting.
        /// </summary>
        field(3; "Code Caption"; Text[80])
        {
            Caption = 'Code Caption';
            ToolTip = 'Specifies the caption of the dimension. This is displayed as the name of dimension fields.';
        }
        /// <summary>
        /// The caption used for dimension filter fields in forms and reports.
        /// If not specified, defaults to "Filter" appended to the dimension code.
        /// </summary>
        field(4; "Filter Caption"; Text[80])
        {
            Caption = 'Filter Caption';
            ToolTip = 'Specifies the caption of the dimension code when used as a filter. This is displayed as the name of dimension filter fields.';
        }
        /// <summary>
        /// Extended description of the dimension providing additional context about its purpose and usage.
        /// </summary>
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the dimension code.';
        }
        /// <summary>
        /// Indicates whether the dimension is blocked from being used in new transactions.
        /// Blocked dimensions cannot be selected in new documents but existing data remains unchanged.
        /// </summary>
        field(6; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
        }
        /// <summary>
        /// The consolidation code used when consolidating financial data across business units.
        /// Links this dimension to corresponding dimensions in subsidiary companies.
        /// </summary>
        field(7; "Consolidation Code"; Code[20])
        {
            AccessByPermission = TableData "Business Unit" = R;
            Caption = 'Consolidation Code';
            ToolTip = 'Specifies the code that is used for consolidation.';
        }
        /// <summary>
        /// Maps this dimension to an intercompany dimension for transactions between related companies.
        /// When set, all dimension values are automatically mapped to the corresponding IC dimension.
        /// </summary>
        field(8; "Map-to IC Dimension Code"; Code[20])
        {
            Caption = 'Map-to IC Dimension Code';
            ToolTip = 'Specifies which intercompany dimension corresponds to the dimension on the line.';
            TableRelation = "IC Dimension";

            trigger OnValidate()
            var
                DimensionValue: Record "Dimension Value";
            begin
                if "Map-to IC Dimension Code" <> xRec."Map-to IC Dimension Code" then begin
                    DimensionValue.SetRange("Dimension Code", Code);
                    DimensionValue.ModifyAll("Map-to IC Dimension Code", "Map-to IC Dimension Code");
                    DimensionValue.ModifyAll("Map-to IC Dimension Value Code", '');
                end;
            end;
        }
        /// <summary>
        /// System field that tracks when the dimension record was last modified.
        /// Used for synchronization and audit purposes.
        /// </summary>
        field(8001; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name, Blocked)
        {
        }
        fieldgroup(Brick; "Code", Name)
        {
        }
    }

    /// <summary>
    /// Validates whether a dimension can be deleted by checking for usage in posted entries, budgets, and setup.
    /// Prevents deletion of dimensions that are actively used in the system.
    /// </summary>
    trigger OnDelete()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        DimVal.SetRange("Dimension Code", xRec.Code);
        if CheckIfDimUsed(xRec.Code, Enum::"Dim Type Checked".FromInteger(0), '', '', 0) then begin
            if DimVal.FindSet() then
                repeat
                    if DimVal.CheckIfDimValueUsed() then
                        Error(Text000, GetCheckDimErr());
                until DimVal.Next() = 0;
            Error(Text001, GetCheckDimErr());
        end;
        if DimVal.FindSet() then
            repeat
                if DimVal.CheckIfDimValueUsed() then
                    Error(Text002);
            until DimVal.Next() = 0;

        DeleteRelatedRecords(Code);

        GLSetup.Get();
        case Code of
            GLSetup."Shortcut Dimension 3 Code":
                begin
                    GLSetup."Shortcut Dimension 3 Code" := '';
                    GLSetup.Modify();
                end;
            GLSetup."Shortcut Dimension 4 Code":
                begin
                    GLSetup."Shortcut Dimension 4 Code" := '';
                    GLSetup.Modify();
                end;
            GLSetup."Shortcut Dimension 5 Code":
                begin
                    GLSetup."Shortcut Dimension 5 Code" := '';
                    GLSetup.Modify();
                end;
            GLSetup."Shortcut Dimension 6 Code":
                begin
                    GLSetup."Shortcut Dimension 6 Code" := '';
                    GLSetup.Modify();
                end;
            GLSetup."Shortcut Dimension 7 Code":
                begin
                    GLSetup."Shortcut Dimension 7 Code" := '';
                    GLSetup.Modify();
                end;
            GLSetup."Shortcut Dimension 8 Code":
                begin
                    GLSetup."Shortcut Dimension 8 Code" := '';
                    GLSetup.Modify();
                end;
        end;

        RemoveICDimensionMappings();
    end;

    /// <summary>
    /// Sets the last modified date time when a new dimension is created.
    /// </summary>
    trigger OnInsert()
    begin
        SetLastModifiedDateTime();
    end;

    /// <summary>
    /// Updates the last modified date time when dimension data is changed.
    /// </summary>
    trigger OnModify()
    begin
        SetLastModifiedDateTime();
    end;

    /// <summary>
    /// Handles dimension code changes by updating related dimension value per account records.
    /// Also updates the last modified date time.
    /// </summary>
    trigger OnRename()
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        DimValuePerAccount.RenameDimension(xRec.Code, Code);
        SetLastModifiedDateTime();
    end;

    var
        DefaultDim: Record "Default Dimension";
        DimVal: Record "Dimension Value";
        DimComb: Record "Dimension Combination";
        SelectedDim: Record "Selected Dimension";
        AnalysisSelectedDim: Record "Analysis Selected Dimension";
        DimTrans: Record "Dimension Translation";
        UsedAsGlobalDim: Boolean;
        UsedAsShortcutDim: Boolean;
        UsedAsBudgetDim: Boolean;
        UsedAsAnalysisViewDim: Boolean;
        UsedAsItemBudgetDim: Boolean;
        UsedAsItemAnalysisViewDim: Boolean;
        CheckDimErr: Text;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1\This dimension is also used in posted or budget entries.\You cannot delete it.';
        Text001: Label '%1\You cannot delete it.';
#pragma warning restore AA0470
        Text002: Label 'You cannot delete this dimension value, because it has been used in one or more documents or budget entries.';
        Text006: Label 'Period';
#pragma warning disable AA0470
        Text007: Label '%1 can not be %2, %3, %4, %5 or Period. These names are used internally by the system.';
#pragma warning restore AA0470
        Text008: Label 'Code';
        Text009: Label 'Filter';
        Text010: Label 'This dimension is used in the following setup: ';
        Text011: Label 'General Ledger Setup, ';
        Text012: Label 'G/L Budget Names, ';
        Text013: Label 'Analysis View Card, ';
        Text014: Label 'Item Budget Names, ';
        Text015: Label 'Item Analysis View Card, ';
#pragma warning restore AA0074

    local procedure UpdateText("Code": Code[20]; AddText: Text[30]; var Text: Text[80])
    begin
        if Text = '' then begin
            Text := LowerCase(Code);
            Text[1] := Code[1];
            if AddText <> '' then
                Text := StrSubstNo('%1 %2', Text, AddText);
        end;
    end;

    local procedure DeleteRelatedRecords(DimensionCode: Code[20])
    begin
        OnBeforeDeleteRelatedRecords(DimensionCode);

        DefaultDim.SetRange("Dimension Code", DimensionCode);
        DefaultDim.DeleteAll(true);

        DimVal.SetRange("Dimension Code", DimensionCode);
        DimVal.DeleteAll(true);

        DimComb.SetRange("Dimension 1 Code", DimensionCode);
        DimComb.DeleteAll();

        DimComb.Reset();
        DimComb.SetRange("Dimension 2 Code", DimensionCode);
        DimComb.DeleteAll();

        SelectedDim.SetRange("Dimension Code", DimensionCode);
        SelectedDim.DeleteAll();

        AnalysisSelectedDim.SetRange("Dimension Code", DimensionCode);
        AnalysisSelectedDim.DeleteAll();

        DimTrans.SetRange(Code, DimensionCode);
        DimTrans.DeleteAll();

        OnAfterDeleteRelatedRecords(DimensionCode);
    end;

    /// <summary>
    /// Checks if a dimension is being used in various system setups, posted entries, or budgets.
    /// This comprehensive check prevents deletion of dimensions that would cause data integrity issues.
    /// </summary>
    /// <param name="DimChecked">The dimension code to check for usage.</param>
    /// <param name="DimTypeChecked">The specific dimension type context to check (Global, Shortcut, Budget, etc.).</param>
    /// <param name="BudgetNameChecked">The budget name to check if budget-specific validation is needed.</param>
    /// <param name="AnalysisViewChecked">The analysis view to check if analysis-specific validation is needed.</param>
    /// <param name="AnalysisAreaChecked">The analysis area (Sales/Purchase) for item-related checks.</param>
    /// <returns>True if the dimension is used and cannot be deleted; false otherwise.</returns>
    procedure CheckIfDimUsed(DimChecked: Code[20]; DimTypeChecked: Enum "Dim Type Checked"; BudgetNameChecked: Code[10]; AnalysisViewChecked: Code[10]; AnalysisAreaChecked: Integer): Boolean
    var
        GLSetup: Record "General Ledger Setup";
        GLBudgetName: Record "G/L Budget Name";
        AnalysisView: Record "Analysis View";
        ItemBudgetName: Record "Item Budget Name";
        ItemAnalysisView: Record "Item Analysis View";
        CustomDimErr: Text;
        CheckAllDim: Boolean;
        CheckGlobalDim: Boolean;
        CheckShortcutDim: Boolean;
        CheckBudgetDim: Boolean;
        CheckAnalysisViewDim: Boolean;
        CheckItemBudgetDim: Boolean;
        CheckItemAnalysisViewDim: Boolean;
        UsedAsCustomDim: Boolean;
    begin
        if DimChecked = '' then
            exit;

        OnBeforeCheckIfDimUsed(DimChecked, DimTypeChecked, UsedAsCustomDim, CustomDimErr, AnalysisViewChecked, AnalysisAreaChecked);

        CheckAllDim := DimTypeChecked in [DimTypeChecked::" "];
        CheckGlobalDim := DimTypeChecked in [DimTypeChecked::Global1, DimTypeChecked::Global2];
        CheckShortcutDim := DimTypeChecked in [DimTypeChecked::Shortcut3, DimTypeChecked::Shortcut4, DimTypeChecked::Shortcut5,
                                               DimTypeChecked::Shortcut6, DimTypeChecked::Shortcut7, DimTypeChecked::Shortcut8];
        CheckBudgetDim := DimTypeChecked in [DimTypeChecked::Budget1, DimTypeChecked::Budget2, DimTypeChecked::Budget3,
                                             DimTypeChecked::Budget4];
        CheckAnalysisViewDim := DimTypeChecked in [DimTypeChecked::Analysis1, DimTypeChecked::Analysis2, DimTypeChecked::Analysis3,
                                                   DimTypeChecked::Analysis4];
        CheckItemBudgetDim :=
          DimTypeChecked in [DimTypeChecked::ItemBudget1, DimTypeChecked::ItemBudget2, DimTypeChecked::ItemBudget3];
        CheckItemAnalysisViewDim :=
          DimTypeChecked in [DimTypeChecked::ItemAnalysis1, DimTypeChecked::ItemAnalysis2, DimTypeChecked::ItemAnalysis3];

        UsedAsGlobalDim := false;
        UsedAsShortcutDim := false;
        UsedAsBudgetDim := false;
        UsedAsAnalysisViewDim := false;
        UsedAsItemBudgetDim := false;
        UsedAsItemAnalysisViewDim := false;

        if CheckAllDim or CheckGlobalDim or CheckShortcutDim or CheckBudgetDim or CheckItemBudgetDim then begin
            GLSetup.Get();
            if (DimTypeChecked <> DimTypeChecked::Global1) and
               (DimChecked = GLSetup."Global Dimension 1 Code")
            then
                UsedAsGlobalDim := true;
            if (DimTypeChecked <> DimTypeChecked::Global2) and
               (DimChecked = GLSetup."Global Dimension 2 Code")
            then
                UsedAsGlobalDim := true;
        end;

        if CheckGlobalDim or CheckShortcutDim then begin
            if (DimTypeChecked <> DimTypeChecked::Shortcut3) and
               (DimChecked = GLSetup."Shortcut Dimension 3 Code")
            then
                UsedAsShortcutDim := true;
            if (DimTypeChecked <> DimTypeChecked::Shortcut4) and
               (DimChecked = GLSetup."Shortcut Dimension 4 Code")
            then
                UsedAsShortcutDim := true;
            if (DimTypeChecked <> DimTypeChecked::Shortcut5) and
               (DimChecked = GLSetup."Shortcut Dimension 5 Code")
            then
                UsedAsShortcutDim := true;
            if (DimTypeChecked <> DimTypeChecked::Shortcut6) and
               (DimChecked = GLSetup."Shortcut Dimension 6 Code")
            then
                UsedAsShortcutDim := true;
            if (DimTypeChecked <> DimTypeChecked::Shortcut7) and
               (DimChecked = GLSetup."Shortcut Dimension 7 Code")
            then
                UsedAsShortcutDim := true;
            if (DimTypeChecked <> DimTypeChecked::Shortcut8) and
               (DimChecked = GLSetup."Shortcut Dimension 8 Code")
            then
                UsedAsShortcutDim := true;
        end;

        if CheckAllDim or CheckGlobalDim or CheckBudgetDim then begin
            if BudgetNameChecked <> '' then
                GLBudgetName.SetRange(Name, BudgetNameChecked);
            if GLBudgetName.FindSet() then
                repeat
                    if (DimTypeChecked <> DimTypeChecked::Budget1) and
                       (DimChecked = GLBudgetName."Budget Dimension 1 Code")
                    then
                        UsedAsBudgetDim := true;
                    if (DimTypeChecked <> DimTypeChecked::Budget2) and
                       (DimChecked = GLBudgetName."Budget Dimension 2 Code")
                    then
                        UsedAsBudgetDim := true;
                    if (DimTypeChecked <> DimTypeChecked::Budget3) and
                       (DimChecked = GLBudgetName."Budget Dimension 3 Code")
                    then
                        UsedAsBudgetDim := true;
                    if (DimTypeChecked <> DimTypeChecked::Budget4) and
                       (DimChecked = GLBudgetName."Budget Dimension 4 Code")
                    then
                        UsedAsBudgetDim := true;
                until GLBudgetName.Next() = 0;
        end;

        if CheckAllDim or CheckGlobalDim or CheckItemBudgetDim then begin
            if BudgetNameChecked <> '' then begin
                ItemBudgetName.SetRange("Analysis Area", AnalysisAreaChecked);
                ItemBudgetName.SetRange(Name, BudgetNameChecked);
            end;
            if ItemBudgetName.FindSet() then
                repeat
                    if (DimTypeChecked <> DimTypeChecked::ItemBudget1) and
                       (DimChecked = ItemBudgetName."Budget Dimension 1 Code")
                    then
                        UsedAsItemBudgetDim := true;
                    if (DimTypeChecked <> DimTypeChecked::ItemBudget2) and
                       (DimChecked = ItemBudgetName."Budget Dimension 2 Code")
                    then
                        UsedAsItemBudgetDim := true;
                    if (DimTypeChecked <> DimTypeChecked::ItemBudget3) and
                       (DimChecked = ItemBudgetName."Budget Dimension 3 Code")
                    then
                        UsedAsItemBudgetDim := true;
                until ItemBudgetName.Next() = 0;
        end;

        CheckIfDimUsedAsAnalysisViewDim(AnalysisView, DimChecked, DimTypeChecked, CheckAllDim, CheckAnalysisViewDim, AnalysisViewChecked);

        if CheckAllDim or CheckItemAnalysisViewDim then begin
            if AnalysisViewChecked <> '' then begin
                ItemAnalysisView.SetRange("Analysis Area", AnalysisAreaChecked);
                ItemAnalysisView.SetRange(Code, AnalysisViewChecked);
            end;
            if ItemAnalysisView.FindSet() then
                repeat
                    if (DimTypeChecked <> DimTypeChecked::ItemAnalysis1) and
                       (DimChecked = ItemAnalysisView."Dimension 1 Code")
                    then
                        UsedAsItemAnalysisViewDim := true;
                    if (DimTypeChecked <> DimTypeChecked::ItemAnalysis2) and
                       (DimChecked = ItemAnalysisView."Dimension 2 Code")
                    then
                        UsedAsItemAnalysisViewDim := true;
                    if (DimTypeChecked <> DimTypeChecked::ItemAnalysis3) and
                       (DimChecked = ItemAnalysisView."Dimension 3 Code")
                    then
                        UsedAsItemAnalysisViewDim := true;
                until ItemAnalysisView.Next() = 0;
        end;

        if UsedAsGlobalDim or
           UsedAsShortcutDim or
           UsedAsBudgetDim or
           UsedAsAnalysisViewDim or
           UsedAsItemBudgetDim or
           UsedAsItemAnalysisViewDim or
           UsedAsCustomDim
        then begin
            MakeCheckDimErr(CustomDimErr);
            exit(true);
        end;
        exit(false);
    end;

    /// <summary>
    /// Checks if a dimension is used in analysis views and updates the usage flags accordingly.
    /// This is a helper procedure for the main CheckIfDimUsed function.
    /// </summary>
    local procedure CheckIfDimUsedAsAnalysisViewDim(AnalysisView: Record "Analysis View"; DimChecked: Code[20]; DimTypeChecked: Enum "Dim Type Checked"; CheckAllDim: Boolean; CheckAnalysisViewDim: Boolean; AnalysisViewChecked: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfDimUsedAsAnalysisViewDim(AnalysisView, DimChecked, DimTypeChecked, CheckAllDim, CheckAnalysisViewDim, AnalysisViewChecked, UsedAsAnalysisViewDim, IsHandled);
        if IsHandled then
            exit;

        if CheckAllDim or CheckAnalysisViewDim then begin
            if AnalysisViewChecked <> '' then
                AnalysisView.SetRange(Code, AnalysisViewChecked);
            if AnalysisView.FindSet() then
                repeat
                    if (DimTypeChecked <> DimTypeChecked::Analysis1) and
                       (DimChecked = AnalysisView."Dimension 1 Code")
                    then
                        UsedAsAnalysisViewDim := true;
                    if (DimTypeChecked <> DimTypeChecked::Analysis2) and
                       (DimChecked = AnalysisView."Dimension 2 Code")
                    then
                        UsedAsAnalysisViewDim := true;
                    if (DimTypeChecked <> DimTypeChecked::Analysis3) and
                       (DimChecked = AnalysisView."Dimension 3 Code")
                    then
                        UsedAsAnalysisViewDim := true;
                    if (DimTypeChecked <> DimTypeChecked::Analysis4) and
                       (DimChecked = AnalysisView."Dimension 4 Code")
                    then
                        UsedAsAnalysisViewDim := true;
                until AnalysisView.Next() = 0;
        end;
    end;

    local procedure MakeCheckDimErr(CustomDimErr: Text)
    begin
        CheckDimErr := Text010;
        if UsedAsGlobalDim or UsedAsShortcutDim then
            CheckDimErr := CheckDimErr + Text011;
        if UsedAsBudgetDim then
            CheckDimErr := CheckDimErr + Text012;
        if UsedAsAnalysisViewDim then
            CheckDimErr := CheckDimErr + Text013;
        if UsedAsItemBudgetDim then
            CheckDimErr := CheckDimErr + Text014;
        if UsedAsItemAnalysisViewDim then
            CheckDimErr := CheckDimErr + Text015;
        if CustomDimErr <> '' then
            CheckDimErr := CheckDimErr + CustomDimErr;
        CheckDimErr := CopyStr(CheckDimErr, 1, StrLen(CheckDimErr) - 2) + '.';
    end;

    /// <summary>
    /// Returns the formatted error message indicating where the dimension is being used.
    /// Used in conjunction with CheckIfDimUsed to provide detailed error information.
    /// </summary>
    /// <returns>The formatted error message detailing dimension usage.</returns>
    procedure GetCheckDimErr(): Text[250]
    begin
        exit(CheckDimErr);
    end;

    /// <summary>
    /// Retrieves the multilanguage name for the dimension in the specified language.
    /// Falls back to the default name if no translation exists.
    /// </summary>
    /// <param name="LanguageID">The language ID for the requested translation.</param>
    /// <returns>The dimension name in the specified language.</returns>
    procedure GetMLName(LanguageID: Integer): Text[30]
    begin
        GetDimTrans(LanguageID);
        exit(DimTrans.Name);
    end;

    /// <summary>
    /// Retrieves the multilanguage code caption for the dimension in the specified language.
    /// Falls back to the default code caption if no translation exists.
    /// </summary>
    /// <param name="LanguageID">The language ID for the requested translation.</param>
    /// <returns>The dimension code caption in the specified language.</returns>
    procedure GetMLCodeCaption(LanguageID: Integer): Text[80]
    begin
        GetDimTrans(LanguageID);
        exit(DimTrans."Code Caption");
    end;

    /// <summary>
    /// Retrieves the multilanguage filter caption for the dimension in the specified language.
    /// Falls back to the default filter caption if no translation exists.
    /// </summary>
    /// <param name="LanguageID">The language ID for the requested translation.</param>
    /// <returns>The dimension filter caption in the specified language.</returns>
    procedure GetMLFilterCaption(LanguageID: Integer): Text[80]
    begin
        GetDimTrans(LanguageID);
        exit(DimTrans."Filter Caption");
    end;

    /// <summary>
    /// Sets the multilanguage name for the dimension in the specified language.
    /// Updates either the main record or creates/updates a translation record.
    /// </summary>
    /// <param name="NewMLName">The new name to set for the dimension.</param>
    /// <param name="LanguageID">The language ID for the translation.</param>
    procedure SetMLName(NewMLName: Text[30]; LanguageID: Integer)
    begin
        if IsApplicationLanguage(LanguageID) then begin
            if Name <> NewMLName then begin
                Name := NewMLName;
                Modify();
            end;
        end else begin
            InsertDimTrans(LanguageID);
            if DimTrans.Name <> NewMLName then begin
                DimTrans.Name := NewMLName;
                DimTrans.Modify();
            end;
        end;
    end;

    /// <summary>
    /// Sets the multilanguage code caption for the dimension in the specified language.
    /// Updates either the main record or creates/updates a translation record.
    /// </summary>
    /// <param name="NewMLCodeCaption">The new code caption to set for the dimension.</param>
    /// <param name="LanguageID">The language ID for the translation.</param>
    procedure SetMLCodeCaption(NewMLCodeCaption: Text[80]; LanguageID: Integer)
    begin
        if IsApplicationLanguage(LanguageID) then begin
            if "Code Caption" <> NewMLCodeCaption then begin
                "Code Caption" := NewMLCodeCaption;
                Modify();
            end;
        end else begin
            InsertDimTrans(LanguageID);
            if DimTrans."Code Caption" <> NewMLCodeCaption then begin
                DimTrans."Code Caption" := NewMLCodeCaption;
                DimTrans.Modify();
            end;
        end;
    end;

    /// <summary>
    /// Sets the multilanguage filter caption for the dimension in the specified language.
    /// Updates either the main record or creates/updates a translation record.
    /// </summary>
    /// <param name="NewMLFilterCaption">The new filter caption to set for the dimension.</param>
    /// <param name="LanguageID">The language ID for the translation.</param>
    procedure SetMLFilterCaption(NewMLFilterCaption: Text[80]; LanguageID: Integer)
    begin
        if IsApplicationLanguage(LanguageID) then begin
            if "Filter Caption" <> NewMLFilterCaption then begin
                "Filter Caption" := NewMLFilterCaption;
                Modify();
            end;
        end else begin
            InsertDimTrans(LanguageID);
            if DimTrans."Filter Caption" <> NewMLFilterCaption then begin
                DimTrans."Filter Caption" := NewMLFilterCaption;
                DimTrans.Modify();
            end;
        end;
    end;

    /// <summary>
    /// Sets the multilanguage description for the dimension in the specified language.
    /// Currently only creates the translation record structure without storing the description value.
    /// </summary>
    /// <param name="NewMLDescription">The new description to set for the dimension.</param>
    /// <param name="LanguageID">The language ID for the translation.</param>
    procedure SetMLDescription(NewMLDescription: Text[100]; LanguageID: Integer)
    begin
        if IsApplicationLanguage(LanguageID) then begin
            if Description <> NewMLDescription then begin
                Description := NewMLDescription;
                Modify();
            end;
        end else
            InsertDimTrans(LanguageID);
    end;

    local procedure GetDimTrans(LanguageID: Integer)
    begin
        if (DimTrans.Code <> Code) or (DimTrans."Language ID" <> LanguageID) then
            if not DimTrans.Get(Code, LanguageID) then begin
                DimTrans.Init();
                DimTrans.Code := Code;
                DimTrans."Language ID" := LanguageID;
                DimTrans.Name := Name;
                DimTrans."Code Caption" := "Code Caption";
                DimTrans."Filter Caption" := "Filter Caption";
            end;
    end;

    local procedure InsertDimTrans(LanguageID: Integer)
    begin
        if not DimTrans.Get(Code, LanguageID) then begin
            DimTrans.Init();
            DimTrans.Code := Code;
            DimTrans."Language ID" := LanguageID;
            DimTrans.Insert();
        end;
    end;

    local procedure IsApplicationLanguage(LanguageID: Integer): Boolean
    var
        Language: Codeunit Language;
    begin
        exit(LanguageID = Language.GetDefaultApplicationLanguageId());
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    local procedure RemoveICDimensionMappings()
    var
        ICDimension: Record "IC Dimension";
        ICDimensionValue: Record "IC Dimension Value";
    begin
        ICDimension.SetRange("Map-to Dimension Code", Rec."Code");
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

    /// <summary>
    /// Integration event raised after deleting records related to a dimension being deleted.
    /// Enables cleanup of custom dimension-related data when a dimension is removed.
    /// </summary>
    /// <param name="DimensionCode">Code of the dimension that was deleted</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRelatedRecords(DimensionCode: Code[20])
    begin
    end;

    /// <summary>
    /// Integration event raised before deleting records related to a dimension being deleted.
    /// Enables validation or preparation before dimension-related data cleanup occurs.
    /// </summary>
    /// <param name="DimensionCode">Code of the dimension being deleted</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRelatedRecords(DimensionCode: Code[20])
    begin
    end;

    /// <summary>
    /// Integration event raised before checking if a dimension is used in custom scenarios.
    /// Enables custom validation of dimension usage beyond standard Business Central checks.
    /// </summary>
    /// <param name="DimChecked">Dimension code being checked for usage</param>
    /// <param name="DimTypeChecked">Type of dimension being checked (Global, Shortcut, Budget, Analysis, etc.)</param>
    /// <param name="UsedAsCustomDim">Set to true if dimension is used in custom scenarios</param>
    /// <param name="CustomDimErr">Error message to display if dimension is used</param>
    /// <param name="AnalysisViewChecked">Analysis view code being checked</param>
    /// <param name="AnalysisAreaChecked">Analysis area being checked</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfDimUsed(DimChecked: Code[20]; DimTypeChecked: Enum "Dim Type Checked"; var UsedAsCustomDim: Boolean; var CustomDimErr: Text; AnalysisViewChecked: Code[10]; AnalysisAreaChecked: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised before checking if a dimension is used as an analysis view dimension.
    /// Enables custom logic for determining dimension usage in analysis views and related scenarios.
    /// </summary>
    /// <param name="AnalysisView">Analysis view record being checked</param>
    /// <param name="DimChecked">Dimension code being checked</param>
    /// <param name="DimTypeChecked">Type of dimension being checked</param>
    /// <param name="CheckAllDim">Whether to check all dimensions</param>
    /// <param name="CheckAnalysisViewDim">Whether to check analysis view dimensions</param>
    /// <param name="AnalysisViewChecked">Analysis view code being checked</param>
    /// <param name="UsedAsAnalysisViewDim">Set to true if dimension is used as analysis view dimension</param>
    /// <param name="IsHandled">Set to true to skip standard analysis view dimension checking</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfDimUsedAsAnalysisViewDim(AnalysisView: Record "Analysis View"; DimChecked: Code[20]; DimTypeChecked: Enum "Dim Type Checked"; CheckAllDim: Boolean; CheckAnalysisViewDim: Boolean; AnalysisViewChecked: Code[10]; var UsedAsAnalysisViewDim: Boolean; var IsHandled: Boolean)
    begin
    end;
}
