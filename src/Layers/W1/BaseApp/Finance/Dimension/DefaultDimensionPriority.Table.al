// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Foundation.AuditCodes;
using System.Reflection;

/// <summary>
/// Defines priority order for default dimensions when multiple master data tables have conflicting default dimension values.
/// Controls which table's default dimensions take precedence during dimension inheritance in posting scenarios.
/// </summary>
/// <remarks>
/// Used when documents inherit dimensions from multiple sources (customer, item, location, etc.).
/// Higher priority tables override lower priority tables when dimension conflicts occur.
/// Essential for consistent dimension assignment in complex posting scenarios with multiple dimension sources.
/// </remarks>
table 354 "Default Dimension Priority"
{
    Caption = 'Default Dimension Priority';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Source code identifying the posting context where this priority applies.
        /// </summary>
        field(1; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        /// <summary>
        /// Identifier of the master data table for which priority is being defined.
        /// </summary>
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            ToolTip = 'Specifies the table ID for the account type, if you want to prioritize an account type.';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnLookup()
            var
                TempAllObjWithCaption: Record AllObjWithCaption temporary;
            begin
                GetDefaultDimTableList(TempAllObjWithCaption);
                if PAGE.RunModal(PAGE::Objects, TempAllObjWithCaption) = ACTION::LookupOK then begin
                    "Table ID" := TempAllObjWithCaption."Object ID";
                    Validate("Table ID");
                end;
            end;

            trigger OnValidate()
            var
                TempAllObjWithCaption: Record AllObjWithCaption temporary;
            begin
                CalcFields("Table Caption");
                GetDefaultDimTableList(TempAllObjWithCaption);
                if not TempAllObjWithCaption.Get(TempAllObjWithCaption."Object Type"::Table, "Table ID") then
                    FieldError("Table ID");
            end;
        }
        /// <summary>
        /// Display name of the table for user interface presentation.
        /// </summary>
        field(3; "Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table ID")));
            Caption = 'Table Caption';
            ToolTip = 'Specifies the table name for the account type you wish to prioritize.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Priority level determining precedence in dimension conflict resolution. Higher values take precedence.
        /// </summary>
        field(4; Priority; Integer)
        {
            Caption = 'Priority';
            ToolTip = 'Specifies the priority of an account type, with the highest priority being 1.';
            MinValue = 1;
        }
    }

    keys
    {
        key(Key1; "Source Code", "Table ID")
        {
            Clustered = true;
        }
        key(Key2; "Source Code", Priority)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if Priority = 0 then
            Priority := xRec.Priority + 1;
    end;

    var
        DimensionManagement: Codeunit DimensionManagement;

    /// <summary>
    /// Retrieves a list of all tables that support default dimensions.
    /// Populates temporary buffer with table objects that can have default dimension configurations.
    /// </summary>
    /// <param name="TempAllObjWithCaption">Temporary buffer to populate with default dimension-enabled tables</param>
    /// <remarks>
    /// Extensibility: OnAfterGetDefaultDimTableList event allows customization of the table list.
    /// </remarks>
    local procedure GetDefaultDimTableList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    begin
        DimensionManagement.DefaultDimObjectNoList(TempAllObjWithCaption);

        OnAfterGetDefaultDimTableList(TempAllObjWithCaption);
    end;

    /// <summary>
    /// Initializes default dimension priorities for all source codes with predefined table priority orders.
    /// Sets up standard dimension priority configurations for common posting scenarios.
    /// </summary>
    /// <remarks>
    /// Extensibility: OnBeforeInitializeDefaultDimPriorities event allows custom priority configuration.
    /// Creates standard priority settings for sales, purchase, and other common posting source codes.
    /// </remarks>
    procedure InitializeDefaultDimPrioritiesForSourceCode()
    var
        SourceCodeSetup: Record "Source Code Setup";
        IsHandled: Boolean;
    begin
        OnBeforeInitializeDefaultDimPriorities(Rec, IsHandled);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();
        case Rec."Source Code" of
            SourceCodeSetup.Sales:
                begin
                    InsertDefaultDimensionPriority(SourceCodeSetup.Sales, 18, 1);
                    InsertDefaultDimensionPriority(SourceCodeSetup.Sales, 27, 2);
                end;
            SourceCodeSetup."Sales Journal":
                begin
                    InsertDefaultDimensionPriority(SourceCodeSetup."Sales Journal", 18, 1);
                    InsertDefaultDimensionPriority(SourceCodeSetup."Sales Journal", 27, 2);
                end;
            SourceCodeSetup.Purchases:
                begin
                    InsertDefaultDimensionPriority(SourceCodeSetup.Purchases, 23, 1);
                    InsertDefaultDimensionPriority(SourceCodeSetup.Purchases, 27, 2);
                end;
            SourceCodeSetup."Purchase Journal":
                begin
                    InsertDefaultDimensionPriority(SourceCodeSetup."Purchase Journal", 23, 1);
                    InsertDefaultDimensionPriority(SourceCodeSetup."Purchase Journal", 27, 2);
                end;
        end;
    end;

    /// <summary>
    /// Creates a new default dimension priority entry if it doesn't already exist.
    /// Inserts priority configuration for specific source code and table combination.
    /// </summary>
    /// <param name="SourceCode">Source code for which to set priority</param>
    /// <param name="TableID">Table identifier for the priority setting</param>
    /// <param name="Priority">Priority level (lower numbers indicate higher priority)</param>
    local procedure InsertDefaultDimensionPriority(SourceCode: Code[20]; TableID: Integer; Priority: Integer)
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        if DefaultDimensionPriority.Get(SourceCode, TableID) then
            exit;

        DefaultDimensionPriority.Init();
        DefaultDimensionPriority.Validate("Source Code", SourceCode);
        DefaultDimensionPriority.Validate("Table ID", TableID);
        DefaultDimensionPriority.Validate(Priority, Priority);
        DefaultDimensionPriority.Insert(true);
    end;

    /// <summary>
    /// Integration event raised before initializing default dimension priorities.
    /// Enables custom priority configuration or skipping standard initialization logic.
    /// </summary>
    /// <param name="DefaultDimPriority">Default dimension priority record being processed</param>
    /// <param name="IsHandled">Set to true to skip standard initialization</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitializeDefaultDimPriorities(var DefaultDimPriority: Record "Default Dimension Priority"; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Integration event raised after building the list of tables that support default dimensions.
    /// Enables addition of custom tables to the default dimension table list.
    /// </summary>
    /// <param name="TempAllObjWithCaption">Temporary table containing available default dimension tables</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDefaultDimTableList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    begin
    end;
}

