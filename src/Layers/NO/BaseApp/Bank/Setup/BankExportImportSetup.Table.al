// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Setup;

using Microsoft.Bank.PositivePay;
using System.IO;
using System.Reflection;

/// <summary>
/// Configures import/export settings for electronic banking file formats.
/// Defines processing rules for bank statement imports, payment exports, and positive pay files.
/// </summary>
/// <remarks>
/// Integrates with Data Exchange Framework and supports multiple file formats (XML, CSV, fixed-width).
/// Extensible through custom codeunits and XMLports for specialized banking formats.
/// </remarks>
table 1200 "Bank Export/Import Setup"
{
    Caption = 'Bank Export/Import Setup';
    DataCaptionFields = "Code", Name;
    DrillDownPageID = "Bank Export/Import Setup";
    LookupPageID = "Bank Export/Import Setup";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the bank export/import configuration.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name for the bank export/import setup configuration.
        /// </summary>
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        /// <summary>
        /// Processing direction for the configuration (Export, Import, or Export-Positive Pay).
        /// Determines available processing options and validation rules.
        /// </summary>
        field(3; Direction; Option)
        {
            Caption = 'Direction';
            OptionCaption = 'Export,Import,Export-Positive Pay';
            OptionMembers = Export,Import,"Export-Positive Pay";

            trigger OnValidate()
            begin
                if Direction = Direction::"Export-Positive Pay" then
                    "Processing Codeunit ID" := CODEUNIT::"Exp. Launcher Pos. Pay"
                else
                    if "Processing Codeunit ID" = CODEUNIT::"Exp. Launcher Pos. Pay" then
                        "Processing Codeunit ID" := 0;
            end;
        }
        /// <summary>
        /// Codeunit ID that handles the processing logic for this configuration.
        /// Must be a valid codeunit that implements the required processing interface.
        /// </summary>
        field(4; "Processing Codeunit ID"; Integer)
        {
            Caption = 'Processing Codeunit ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));
        }
        /// <summary>
        /// Display name of the processing codeunit.
        /// FlowField that retrieves the codeunit caption from system metadata.
        /// </summary>
        field(5; "Processing Codeunit Name"; Text[249])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Processing Codeunit ID")));
            Caption = 'Processing Codeunit Name';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// XMLport ID that handles the data transformation for this configuration.
        /// Used for file format conversion and data mapping.
        /// </summary>
        field(6; "Processing XMLport ID"; Integer)
        {
            Caption = 'Processing XMLport ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(XMLport));
        }
        /// <summary>
        /// Display name of the processing XMLport.
        /// FlowField that retrieves the XMLport caption from system metadata.
        /// </summary>
        field(7; "Processing XMLport Name"; Text[249])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(XMLport),
                                                                           "Object ID" = field("Processing XMLport ID")));
            Caption = 'Processing XMLport Name';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Data Exchange Definition code that defines the file format structure.
        /// Links to specific exchange definitions based on the direction setting.
        /// </summary>
        field(8; "Data Exch. Def. Code"; Code[20])
        {
            Caption = 'Data Exch. Def. Code';
            TableRelation = if (Direction = const(Import)) "Data Exch. Def".Code where(Type = const("Bank Statement Import"))
            else
            if (Direction = const(Export)) "Data Exch. Def".Code where(Type = const("Payment Export"))
            else
            if (Direction = const("Export-Positive Pay")) "Data Exch. Def".Code where(Type = const("Positive Pay Export"));
        }
        /// <summary>
        /// Display name of the data exchange definition.
        /// FlowField that shows the human-readable name of the selected exchange definition.
        /// </summary>
        field(9; "Data Exch. Def. Name"; Text[100])
        {
            CalcFormula = lookup("Data Exch. Def".Name where(Code = field("Data Exch. Def. Code")));
            Caption = 'Data Exch. Def. Name';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Controls whether non-Latin characters are preserved during export/import processing.
        /// When enabled, special characters are maintained in their original form.
        /// </summary>
        field(10; "Preserve Non-Latin Characters"; Boolean)
        {
            Caption = 'Preserve Non-Latin Characters';
            InitValue = true;
        }
        /// <summary>
        /// Codeunit ID for additional export validation and processing.
        /// Used for custom validation logic during export operations.
        /// </summary>
        field(11; "Check Export Codeunit"; Integer)
        {
            Caption = 'Check Export Codeunit';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));
        }
        /// <summary>
        /// Display name of the check export codeunit.
        /// FlowField that shows the caption of the validation codeunit.
        /// </summary>
        field(12; "Check Export Codeunit Name"; Text[249])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Check Export Codeunit")));
            Caption = 'Check Export Codeunit Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10601; "Reg.Reporting Thresh.Amt (LCY)"; Decimal)
        {
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
    }
}
