// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Utilities;
using System.Security.AccessControl;

/// <summary>
/// Stores individual budget entries with multi-dimensional analysis capabilities for financial planning and forecasting.
/// Primary transaction table for budget data with full dimension support and Analysis View integration.
/// </summary>
/// <remarks>
/// Key relationships: G/L Budget Name (header), G/L Account (master data), Dimension Values (analysis).
/// Integration: Analysis View Budget Entry for performance reporting and G/L Account budgeting workflows.
/// Extensibility: OnValidate triggers for custom business rules and dimension validation hooks.
/// </remarks>
table 96 "G/L Budget Entry"
{
    Caption = 'G/L Budget Entry';
    DrillDownPageID = "G/L Budget Entries";
    LookupPageID = "G/L Budget Entries";
    Permissions = TableData "Analysis View Budget Entry" = rd;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the budget entry record within the G/L Budget Entry table.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Reference to the budget name that groups related budget entries and defines dimension structure.
        /// </summary>
        field(2; "Budget Name"; Code[10])
        {
            Caption = 'Budget Name';
            TableRelation = "G/L Budget Name";
        }
        /// <summary>
        /// G/L Account for which the budget amount is defined, linking to the chart of accounts structure.
        /// </summary>
        field(3; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                if (xRec."G/L Account No." <> '') and (xRec."G/L Account No." <> "G/L Account No.") then
                    VerifyNoRelatedAnalysisViewBudgetEntries(xRec);
            end;
        }
        /// <summary>
        /// Budget period date that determines when the budget amount applies for period-based analysis.
        /// </summary>
        field(4; Date; Date)
        {
            Caption = 'Date';
            ClosingDates = true;

            trigger OnValidate()
            begin
                if (xRec.Date <> 0D) and (xRec.Date <> Date) then
                    VerifyNoRelatedAnalysisViewBudgetEntries(xRec);
            end;
        }
        /// <summary>
        /// First global dimension code for company-wide analysis and reporting requirements.
        /// </summary>
        field(5; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));

            trigger OnValidate()
            begin
                if "Global Dimension 1 Code" = xRec."Global Dimension 1 Code" then
                    exit;
                GetGLSetup();
                ValidateDimValue(GLSetup."Global Dimension 1 Code", "Global Dimension 1 Code");
                UpdateDimensionSetId(GLSetup."Global Dimension 1 Code", "Global Dimension 1 Code");
            end;
        }
        /// <summary>
        /// Second global dimension code for company-wide analysis and reporting requirements.
        /// </summary>
        field(6; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));

            trigger OnValidate()
            begin
                if "Global Dimension 2 Code" = xRec."Global Dimension 2 Code" then
                    exit;
                GetGLSetup();
                ValidateDimValue(GLSetup."Global Dimension 2 Code", "Global Dimension 2 Code");
                UpdateDimensionSetId(GLSetup."Global Dimension 2 Code", "Global Dimension 2 Code");
            end;
        }
        /// <summary>
        /// Budget amount in local currency for the specified G/L account and dimension combination.
        /// </summary>
        field(7; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                if (xRec.Amount <> 0) and (xRec.Amount <> Amount) then
                    VerifyNoRelatedAnalysisViewBudgetEntries(xRec);
            end;
        }
        /// <summary>
        /// Descriptive text providing additional context or explanation for the budget entry.
        /// </summary>
        field(9; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Business unit code for consolidation and multi-company budget analysis scenarios.
        /// </summary>
        field(10; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        /// <summary>
        /// User identifier who created or last modified the budget entry for audit trail purposes.
        /// </summary>
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// First budget-specific dimension code as configured in the associated G/L Budget Name.
        /// </summary>
        field(12; "Budget Dimension 1 Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(1);
            Caption = 'Budget Dimension 1 Code';

            trigger OnLookup()
            begin
                "Budget Dimension 1 Code" := OnLookupDimCode(2, "Budget Dimension 1 Code");
                ValidateDimValue(GLBudgetName."Budget Dimension 1 Code", "Budget Dimension 1 Code");
                UpdateDimensionSetId(GLBudgetName."Budget Dimension 1 Code", "Budget Dimension 1 Code");
            end;

            trigger OnValidate()
            begin
                if "Budget Dimension 1 Code" = xRec."Budget Dimension 1 Code" then
                    exit;
                if GLBudgetName.Name <> "Budget Name" then
                    GLBudgetName.Get("Budget Name");
                ValidateDimValue(GLBudgetName."Budget Dimension 1 Code", "Budget Dimension 1 Code");
                UpdateDimensionSetId(GLBudgetName."Budget Dimension 1 Code", "Budget Dimension 1 Code");
            end;
        }
        /// <summary>
        /// Second budget-specific dimension code as configured in the associated G/L Budget Name.
        /// </summary>
        field(13; "Budget Dimension 2 Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(2);
            Caption = 'Budget Dimension 2 Code';

            trigger OnLookup()
            begin
                "Budget Dimension 2 Code" := OnLookupDimCode(3, "Budget Dimension 2 Code");
                ValidateDimValue(GLBudgetName."Budget Dimension 2 Code", "Budget Dimension 2 Code");
                UpdateDimensionSetId(GLBudgetName."Budget Dimension 2 Code", "Budget Dimension 2 Code");
            end;

            trigger OnValidate()
            begin
                if "Budget Dimension 2 Code" = xRec."Budget Dimension 2 Code" then
                    exit;
                if GLBudgetName.Name <> "Budget Name" then
                    GLBudgetName.Get("Budget Name");
                ValidateDimValue(GLBudgetName."Budget Dimension 2 Code", "Budget Dimension 2 Code");
                UpdateDimensionSetId(GLBudgetName."Budget Dimension 2 Code", "Budget Dimension 2 Code");
            end;
        }
        /// <summary>
        /// Third budget-specific dimension code as configured in the associated G/L Budget Name.
        /// </summary>
        field(14; "Budget Dimension 3 Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(3);
            Caption = 'Budget Dimension 3 Code';

            trigger OnLookup()
            begin
                "Budget Dimension 3 Code" := OnLookupDimCode(4, "Budget Dimension 3 Code");
                ValidateDimValue(GLBudgetName."Budget Dimension 3 Code", "Budget Dimension 3 Code");
                UpdateDimensionSetId(GLBudgetName."Budget Dimension 3 Code", "Budget Dimension 3 Code");
            end;

            trigger OnValidate()
            begin
                if "Budget Dimension 3 Code" = xRec."Budget Dimension 3 Code" then
                    exit;
                if GLBudgetName.Name <> "Budget Name" then
                    GLBudgetName.Get("Budget Name");
                ValidateDimValue(GLBudgetName."Budget Dimension 3 Code", "Budget Dimension 3 Code");
                UpdateDimensionSetId(GLBudgetName."Budget Dimension 3 Code", "Budget Dimension 3 Code");
            end;
        }
        /// <summary>
        /// Fourth budget-specific dimension code as configured in the associated G/L Budget Name.
        /// </summary>
        field(15; "Budget Dimension 4 Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(4);
            Caption = 'Budget Dimension 4 Code';

            trigger OnLookup()
            begin
                "Budget Dimension 4 Code" := OnLookupDimCode(5, "Budget Dimension 4 Code");
                ValidateDimValue(GLBudgetName."Budget Dimension 4 Code", "Budget Dimension 4 Code");
                UpdateDimensionSetId(GLBudgetName."Budget Dimension 4 Code", "Budget Dimension 4 Code");
            end;

            trigger OnValidate()
            begin
                if "Budget Dimension 4 Code" = xRec."Budget Dimension 4 Code" then
                    exit;
                if GLBudgetName.Name <> "Budget Name" then
                    GLBudgetName.Get("Budget Name");
                ValidateDimValue(GLBudgetName."Budget Dimension 4 Code", "Budget Dimension 4 Code");
                UpdateDimensionSetId(GLBudgetName."Budget Dimension 4 Code", "Budget Dimension 4 Code");
            end;
        }
        /// <summary>
        /// Date when the budget entry was last modified for tracking changes and version control.
        /// </summary>
        field(16; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        /// <summary>
        /// Dimension Set ID that combines all dimension values into a single reference for optimized querying.
        /// </summary>
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            begin
                if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                    Error(DimMgt.GetDimCombErr());
            end;
        }
        field(10720; "Old G/L Account No."; Code[20])
        {
            Caption = 'Old G/L Account No.';
        }
        field(10721; Updated; Boolean)
        {
            Caption = 'Updated';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Budget Name", "G/L Account No.", Date)
        {
            SumIndexFields = Amount;
        }
        key(Key3; "Budget Name", "G/L Account No.", "Business Unit Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Budget Dimension 1 Code", "Budget Dimension 2 Code", "Budget Dimension 3 Code", "Budget Dimension 4 Code", Date)
        {
            SumIndexFields = Amount;
        }
        key(Key4; "Budget Name", "G/L Account No.", Description, Date)
        {
        }
        key(Key5; "Budget Name", "Old G/L Account No.", Date)
        {
            SumIndexFields = Amount;
        }
        key(Key6; "Budget Name", "Old G/L Account No.", "Business Unit Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Budget Dimension 1 Code", "Budget Dimension 2 Code", "Budget Dimension 3 Code", "Budget Dimension 4 Code", Date)
        {
            SumIndexFields = Amount;
        }
        key(Key7; "G/L Account No.", Date, "Budget Name", "Dimension Set ID")
        {
            SumIndexFields = Amount;
        }
        key(Key8; "Last Date Modified", "Budget Name")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckIfBlocked();
        DeleteAnalysisViewBudgetEntries();
    end;

    trigger OnInsert()
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        CheckIfBlocked();
        TestField(Date);
        TestField("G/L Account No.");
        TestField("Budget Name");
        LockTable();
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Last Date Modified" := Today;
        if "Entry No." = 0 then
            "Entry No." := GetLastEntryNo() + 1;

        GetGLSetup();
        DimMgt.GetDimensionSet(TempDimSetEntry, "Dimension Set ID");
        UpdateDimSet(TempDimSetEntry, GLSetup."Global Dimension 1 Code", "Global Dimension 1 Code");
        UpdateDimSet(TempDimSetEntry, GLSetup."Global Dimension 2 Code", "Global Dimension 2 Code");
        UpdateDimSet(TempDimSetEntry, GLBudgetName."Budget Dimension 1 Code", "Budget Dimension 1 Code");
        UpdateDimSet(TempDimSetEntry, GLBudgetName."Budget Dimension 2 Code", "Budget Dimension 2 Code");
        UpdateDimSet(TempDimSetEntry, GLBudgetName."Budget Dimension 3 Code", "Budget Dimension 3 Code");
        UpdateDimSet(TempDimSetEntry, GLBudgetName."Budget Dimension 4 Code", "Budget Dimension 4 Code");
        OnInsertOnAfterUpdateDimSets(TempDimSetEntry, Rec);
        Validate("Dimension Set ID", DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    trigger OnModify()
    begin
        CheckIfBlocked();
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Last Date Modified" := Today;
    end;

    var
        GLBudgetName: Record "G/L Budget Name";
        GLSetup: Record "General Ledger Setup";
        DimVal: Record "Dimension Value";
        DimMgt: Codeunit DimensionManagement;
        GLSetupRetrieved: Boolean;

#pragma warning disable AA0074
        Text001: Label '1,5,,Budget Dimension 1 Code';
        Text002: Label '1,5,,Budget Dimension 2 Code';
        Text003: Label '1,5,,Budget Dimension 3 Code';
        Text004: Label '1,5,,Budget Dimension 4 Code';
#pragma warning restore AA0074
        AnalysisViewBudgetEntryExistsErr: Label 'You cannot change the amount on this G/L budget entry because one or more related analysis view budget entries exist.\\You must make the change on the related entry in the G/L Budget window.';

    /// <summary>
    /// Retrieves the highest entry number in the G/L Budget Entry table for generating new unique identifiers.
    /// </summary>
    /// <returns>The last used entry number in the table.</returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"G/L Budget Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    /// <summary>
    /// Validates that the associated budget name is not blocked before allowing entry modifications.
    /// </summary>
    procedure CheckIfBlocked()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfBlocked(Rec, xRec, GLBudgetName, IsHandled);
        if IsHandled then
            exit;

        if "Budget Name" = GLBudgetName.Name then
            exit;
        if GLBudgetName.Name <> "Budget Name" then
            GLBudgetName.Get("Budget Name");
        GLBudgetName.TestField(Blocked, false);
    end;

    local procedure ValidateDimValue(DimCode: Code[20]; DimValueCode: Code[20])
    begin
        if not DimMgt.CheckDimValue(DimCode, DimValueCode) then
            Error(DimMgt.GetDimErr());
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRetrieved then begin
            GLSetup.Get();
            GLSetupRetrieved := true;
        end;
    end;

    local procedure OnLookupDimCode(DimOption: Option "Global Dimension 1","Global Dimension 2","Budget Dimension 1","Budget Dimension 2","Budget Dimension 3","Budget Dimension 4"; DefaultValue: Code[20]): Code[20]
    var
        DimValue: Record "Dimension Value";
        DimValueList: Page "Dimension Value List";
    begin
        if DimOption in [DimOption::"Global Dimension 1", DimOption::"Global Dimension 2"] then
            GetGLSetup()
        else
            if GLBudgetName.Name <> "Budget Name" then
                GLBudgetName.Get("Budget Name");
        case DimOption of
            DimOption::"Global Dimension 1":
                DimValue."Dimension Code" := GLSetup."Global Dimension 1 Code";
            DimOption::"Global Dimension 2":
                DimValue."Dimension Code" := GLSetup."Global Dimension 2 Code";
            DimOption::"Budget Dimension 1":
                DimValue."Dimension Code" := GLBudgetName."Budget Dimension 1 Code";
            DimOption::"Budget Dimension 2":
                DimValue."Dimension Code" := GLBudgetName."Budget Dimension 2 Code";
            DimOption::"Budget Dimension 3":
                DimValue."Dimension Code" := GLBudgetName."Budget Dimension 3 Code";
            DimOption::"Budget Dimension 4":
                DimValue."Dimension Code" := GLBudgetName."Budget Dimension 4 Code";
        end;
        DimValue.SetRange("Dimension Code", DimValue."Dimension Code");
        if DimValue.Get(DimValue."Dimension Code", DefaultValue) then;
        DimValueList.SetTableView(DimValue);
        DimValueList.SetRecord(DimValue);
        DimValueList.LookupMode := true;
        if DimValueList.RunModal() = ACTION::LookupOK then begin
            DimValueList.GetRecord(DimValue);
            exit(DimValue.Code);
        end;
        exit(DefaultValue);
    end;

    /// <summary>
    /// Generates dynamic captions for budget dimension fields based on the dimension configuration in the budget name.
    /// </summary>
    /// <param name="BudgetDimType">The budget dimension type number (1-4) for caption generation.</param>
    /// <returns>Formatted caption text for the specified budget dimension field.</returns>
    procedure GetCaptionClass(BudgetDimType: Integer): Text[250]
    begin
        if GetFilter("Budget Name") <> '' then begin
            GLBudgetName.SetFilter(Name, GetFilter("Budget Name"));
            if not GLBudgetName.FindFirst() then
                Clear(GLBudgetName);
        end;
        case BudgetDimType of
            1:
                begin
                    if GLBudgetName."Budget Dimension 1 Code" <> '' then
                        exit('1,5,' + GLBudgetName."Budget Dimension 1 Code");

                    exit(Text001);
                end;
            2:
                begin
                    if GLBudgetName."Budget Dimension 2 Code" <> '' then
                        exit('1,5,' + GLBudgetName."Budget Dimension 2 Code");

                    exit(Text002);
                end;
            3:
                begin
                    if GLBudgetName."Budget Dimension 3 Code" <> '' then
                        exit('1,5,' + GLBudgetName."Budget Dimension 3 Code");

                    exit(Text003);
                end;
            4:
                begin
                    if GLBudgetName."Budget Dimension 4 Code" <> '' then
                        exit('1,5,' + GLBudgetName."Budget Dimension 4 Code");

                    exit(Text004);
                end;
        end;
    end;

    /// <summary>
    /// Opens the dimension management page for viewing and editing the entry's dimension set values.
    /// </summary>
    procedure ShowDimensions()
    var
        DimSetEntry: Record "Dimension Set Entry";
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', "Budget Name", "G/L Account No.", "Entry No."));

        if OldDimSetID = "Dimension Set ID" then
            exit;

        GetGLSetup();
        GLBudgetName.Get("Budget Name");

        "Global Dimension 1 Code" := '';
        "Global Dimension 2 Code" := '';
        "Budget Dimension 1 Code" := '';
        "Budget Dimension 2 Code" := '';
        "Budget Dimension 3 Code" := '';
        "Budget Dimension 4 Code" := '';

        if DimSetEntry.Get("Dimension Set ID", GLSetup."Global Dimension 1 Code") then
            "Global Dimension 1 Code" := DimSetEntry."Dimension Value Code";
        if DimSetEntry.Get("Dimension Set ID", GLSetup."Global Dimension 2 Code") then
            "Global Dimension 2 Code" := DimSetEntry."Dimension Value Code";
        if DimSetEntry.Get("Dimension Set ID", GLBudgetName."Budget Dimension 1 Code") then
            "Budget Dimension 1 Code" := DimSetEntry."Dimension Value Code";
        if DimSetEntry.Get("Dimension Set ID", GLBudgetName."Budget Dimension 2 Code") then
            "Budget Dimension 2 Code" := DimSetEntry."Dimension Value Code";
        if DimSetEntry.Get("Dimension Set ID", GLBudgetName."Budget Dimension 3 Code") then
            "Budget Dimension 3 Code" := DimSetEntry."Dimension Value Code";
        if DimSetEntry.Get("Dimension Set ID", GLBudgetName."Budget Dimension 4 Code") then
            "Budget Dimension 4 Code" := DimSetEntry."Dimension Value Code";

        OnAfterShowDimensions(Rec);
    end;

    /// <summary>
    /// Updates a temporary dimension set entry record with the specified dimension code and value.
    /// Used for building dimension sets during budget entry processing and validation.
    /// </summary>
    /// <param name="TempDimSetEntry">Temporary dimension set entry record to update.</param>
    /// <param name="DimCode">Dimension code to set in the entry.</param>
    /// <param name="DimValueCode">Dimension value code to set in the entry.</param>
    procedure UpdateDimSet(var TempDimSetEntry: Record "Dimension Set Entry" temporary; DimCode: Code[20]; DimValueCode: Code[20])
    begin
        if DimCode = '' then
            exit;
        if TempDimSetEntry.Get("Dimension Set ID", DimCode) then
            TempDimSetEntry.Delete();
        if DimValueCode = '' then
            DimVal.Init()
        else
            DimVal.Get(DimCode, DimValueCode);
        TempDimSetEntry.Init();
        TempDimSetEntry."Dimension Set ID" := "Dimension Set ID";
        TempDimSetEntry."Dimension Code" := DimCode;
        TempDimSetEntry."Dimension Value Code" := DimValueCode;
        TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
        TempDimSetEntry.Insert();
        OnAfterUpdateDimSet(Rec, TempDimSetEntry, DimCode, DimValueCode);
    end;

    local procedure UpdateDimensionSetId(DimCode: Code[20]; DimValueCode: Code[20])
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        DimMgt.GetDimensionSet(TempDimSetEntry, "Dimension Set ID");
        UpdateDimSet(TempDimSetEntry, DimCode, DimValueCode);
        OnAfterUpdateDimensionSetId(TempDimSetEntry, Rec, xRec);
        "Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
    end;

    local procedure DeleteAnalysisViewBudgetEntries()
    var
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
    begin
        AnalysisViewBudgetEntry.SetRange("Budget Name", "Budget Name");
        AnalysisViewBudgetEntry.SetRange("Entry No.", "Entry No.");
        AnalysisViewBudgetEntry.DeleteAll();
    end;

    local procedure VerifyNoRelatedAnalysisViewBudgetEntries(GLBudgetEntry: Record "G/L Budget Entry")
    var
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyNoRelatedAnalysisViewBudgetEntries(Rec, xRec, IsHandled);
        if IsHandled then
            exit;
        AnalysisViewBudgetEntry.SetRange("Budget Name", GLBudgetEntry."Budget Name");
        AnalysisViewBudgetEntry.SetRange("G/L Account No.", GLBudgetEntry."G/L Account No.");
        AnalysisViewBudgetEntry.SetRange("Posting Date", GLBudgetEntry.Date);
        AnalysisViewBudgetEntry.SetRange("Business Unit Code", GLBudgetEntry."Business Unit Code");
        if not AnalysisViewBudgetEntry.IsEmpty() then
            Error(AnalysisViewBudgetEntryExistsErr);
    end;

    /// <summary>
    /// Integration event raised after showing dimensions for a budget entry.
    /// Allows subscribers to perform additional processing after dimension dialog is displayed.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var GLBudgetEntry: Record "G/L Budget Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after updating dimension set entries for a budget entry.
    /// Allows subscribers to perform additional dimension processing or validation.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDimSet(GLBudgetEntry: Record "G/L Budget Entry"; var TempDimensionSetEntry: Record "Dimension Set Entry" temporary; DimCode: Code[20]; DimValueCode: Code[20])
    begin
    end;

    /// <summary>
    /// Integration event raised after updating the dimension set ID for a budget entry.
    /// Allows subscribers to perform additional processing after dimension set ID changes.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDimensionSetId(var TempDimensionSetEntry: Record "Dimension Set Entry" temporary; var GLBudgetEntry: Record "G/L Budget Entry"; xGLBudgetEntry: Record "G/L Budget Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before checking if a budget name is blocked.
    /// Allows subscribers to implement custom blocking logic or skip the standard check.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfBlocked(var GLBudgetEntry: Record "G/L Budget Entry"; xGLBudgetEntry: Record "G/L Budget Entry"; GLBudgetName: Record "G/L Budget Name"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised during insert after updating dimension sets.
    /// Allows subscribers to perform additional processing after dimension sets are updated during budget entry insertion.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnInsertOnAfterUpdateDimSets(var TempDimensionSetEntry: Record "Dimension Set Entry" temporary; var GLBudgetEntry: Record "G/L Budget Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before verifying no related Analysis View Budget Entries exist.
    /// Allows subscribers to implement custom verification logic or skip the standard verification.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyNoRelatedAnalysisViewBudgetEntries(var GLBudgetEntry: Record "G/L Budget Entry"; xGLBudgetEntry: Record "G/L Budget Entry"; var IsHandled: Boolean)
    begin
    end;
}
