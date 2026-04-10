// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using System.Globalization;

/// <summary>
/// Stores allowed dimension values per specific account configuration.
/// Manages dimension value permissions and validation for individual accounts across different table types.
/// </summary>
/// <remarks>
/// Used to control which dimension values are permitted for specific accounts in various master data tables.
/// Supports dimension value validation during posting and data entry operations.
/// Integrates with default dimension management for account-specific dimension value restrictions.
/// </remarks>
table 356 "Dim. Value per Account"
{
    DataClassification = SystemMetadata;

    fields
    {
        /// <summary>
        /// Table identifier specifying which master data table the account belongs to.
        /// </summary>
        field(1; "Table ID"; Integer)
        {
        }
        /// <summary>
        /// Account number or identifier within the specified table.
        /// </summary>
        field(2; "No."; Code[20])
        {
        }
        /// <summary>
        /// Dimension code for which value permissions are being managed.
        /// </summary>
        field(3; "Dimension Code"; Code[20])
        {
        }
        /// <summary>
        /// Specific dimension value code that is allowed or restricted for this account.
        /// </summary>
        field(4; "Dimension Value Code"; Code[20])
        {
            ToolTip = 'Specifies the code for the dimension value.';
        }
        /// <summary>
        /// Display name of the dimension value for user interface presentation.
        /// </summary>
        field(6; "Dimension Value Name"; Text[50])
        {
            CalcFormula = lookup("Dimension Value".Name where("Dimension Code" = field("Dimension Code"),
                                                               Code = field("Dimension Value Code")));
            Caption = 'Dimension Value Name';
            ToolTip = 'Specifies a descriptive name for the dimension value.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Type classification of the dimension value indicating its role in hierarchical structures.
        /// </summary>
        field(7; "Dimension Value Type"; Option)
        {
            Caption = 'Dimension Value Type';
            OptionCaption = 'Standard,Heading,Total,Begin-Total,End-Total';
            OptionMembers = Standard,Heading,Total,"Begin-Total","End-Total";
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Value"."Dimension Value Type" where("Dimension Code" = field("Dimension Code"),
                                                               Code = field("Dimension Value Code")));
        }
        /// <summary>
        /// Indentation level for hierarchical display of dimension values in user interfaces.
        /// </summary>
        field(8; Indentation; Integer)
        {
            Caption = 'Indentation';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Value".Indentation where("Dimension Code" = field("Dimension Code"),
                                                               Code = field("Dimension Value Code")));
        }
        /// <summary>
        /// Indicates whether this dimension value is allowed for the specified account.
        /// </summary>
        field(10; Allowed; Boolean)
        {
            ToolTip = 'Specifies whether the related record can be posted in transactions.';
            InitValue = true;

            trigger OnValidate()
            var
                DefaultDimension: Record "Default Dimension";
            begin
                if not Allowed then
                    if DefaultDimension.Get("Table ID", "No.", "Dimension Code") then
                        DefaultDimension.CheckDisallowedDimensionValue(Rec);
            end;
        }
    }

    keys
    {
        key(PK; "Table ID", "No.", "Dimension Code", "Dimension Value Code")
        {
            Clustered = true;
        }
    }

    var
        CaptionLbl: Label '%1 - %2 %3', Comment = '%1 = dimension code and %2- table name, %3 - account number', Locked = true;

    /// <summary>
    /// Generates a formatted caption string combining dimension code, table name, and account number.
    /// Provides user-friendly display text for dimension value per account records.
    /// </summary>
    /// <returns>Formatted caption text with dimension code, table caption, and account number</returns>
    /// <remarks>
    /// Uses table translation for localized table names and follows standard caption formatting patterns.
    /// Useful for display purposes in user interfaces and reports.
    /// </remarks>
    procedure GetCaption(): Text[250]
    begin
        exit(StrSubstNo(CaptionLbl, "Dimension Code", GetTableCaption(), "No."));
    end;

    /// <summary>
    /// Retrieves the localized caption for the table specified by Table ID.
    /// Provides translated table name based on current user language settings.
    /// </summary>
    /// <returns>Localized table caption text</returns>
    /// <remarks>
    /// Uses Object Translation functionality to provide language-specific table names.
    /// Supports multilingual environments with proper table name localization.
    /// </remarks>
    procedure GetTableCaption(): Text[250]
    var
        ObjTransl: Record "Object Translation";
    begin
        exit(ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, "Table ID"));
    end;

    /// <summary>
    /// Renames dimension value per account records when account numbers change.
    /// Updates all related dimension value permissions for the specified account and dimension.
    /// </summary>
    /// <param name="TableId">Table identifier containing the account</param>
    /// <param name="OldNo">Original account number to be renamed</param>
    /// <param name="NewNo">New account number after renaming</param>
    /// <param name="DimensionCode">Dimension code for which permissions are being updated</param>
    /// <remarks>
    /// Maintains data integrity during account renaming operations by updating all related dimension value permissions.
    /// Ensures dimension value restrictions follow the account through renaming processes.
    /// </remarks>
    procedure RenameNo(TableId: Integer; OldNo: Code[20]; NewNo: Code[20]; DimensionCode: Code[20])
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        DimValuePerAccount.SetRange("Table ID", TableId);
        DimValuePerAccount.SetRange("No.", OldNo);
        DimValuePerAccount.SetRange("Dimension Code", DimensionCode);
        if DimValuePerAccount.FindSet() then
            repeat
                RenameDimValuePerAccount(DimValuePerAccount, DimValuePerAccount."Table ID", NewNo, DimValuePerAccount."Dimension Code", DimValuePerAccount."Dimension Value Code");
            until DimValuePerAccount.Next() = 0;
    end;

    /// <summary>
    /// Renames dimension value per account records when dimension codes change.
    /// Updates all related dimension value permissions for the specified dimension across all accounts.
    /// </summary>
    /// <param name="OldDimensionCode">Original dimension code to be renamed</param>
    /// <param name="NewDimensionCode">New dimension code after renaming</param>
    /// <remarks>
    /// Maintains data integrity during dimension renaming operations by updating all related dimension value permissions.
    /// Ensures dimension value restrictions follow the dimension through renaming processes across all accounts.
    /// </remarks>
    procedure RenameDimension(OldDimensionCode: Code[20]; NewDimensionCode: Code[20])
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        DimValuePerAccount.SetRange("Dimension Code", OldDimensionCode);
        if DimValuePerAccount.FindSet() then
            repeat
                RenameDimValuePerAccount(DimValuePerAccount, DimValuePerAccount."Table ID", DimValuePerAccount."No.", NewDimensionCode, DimValuePerAccount."Dimension Value Code");
            until DimValuePerAccount.Next() = 0;
    end;

    /// <summary>
    /// Renames dimension value per account records when dimension value codes change.
    /// Updates all related dimension value permissions for the specified dimension value across all accounts.
    /// </summary>
    /// <param name="DimensionCode">Dimension code containing the value to be renamed</param>
    /// <param name="OldDimensionValueCode">Original dimension value code to be renamed</param>
    /// <param name="NewDimensionValueCode">New dimension value code after renaming</param>
    /// <remarks>
    /// Maintains data integrity during dimension value renaming operations by updating all related permissions.
    /// Ensures dimension value restrictions follow the dimension value through renaming processes across all accounts.
    /// </remarks>
    procedure RenameDimensionValue(DimensionCode: Code[20]; OldDimensionValueCode: Code[20]; NewDimensionValueCode: Code[20])
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        DimValuePerAccount.SetRange("Dimension Code", DimensionCode);
        DimValuePerAccount.SetRange("Dimension Value Code", OldDimensionValueCode);
        if DimValuePerAccount.FindSet() then
            repeat
                RenameDimValuePerAccount(DimValuePerAccount, DimValuePerAccount."Table ID", DimValuePerAccount."No.", DimValuePerAccount."Dimension Code", NewDimensionValueCode);
            until DimValuePerAccount.Next() = 0;
    end;

    local procedure RenameDimValuePerAccount(DimValuePerAccount: Record "Dim. Value per Account"; TableId: Integer; No: Code[20]; DimensionCode: Code[20]; DimensionValueCode: code[20])
    var
        DimValuePerAccountToRename: Record "Dim. Value per Account";
    begin
        DimValuePerAccountToRename := DimValuePerAccount;
        DimValuePerAccountToRename.Rename(TableId, No, DimensionCode, DimensionValueCode);
    end;
}
