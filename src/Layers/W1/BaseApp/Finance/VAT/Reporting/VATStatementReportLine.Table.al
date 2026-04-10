// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Contains VAT statement lines generated for specific VAT reports with calculated amounts and descriptions.
/// Stores the results of VAT statement calculations as report lines for submission and display purposes.
/// </summary>
table 742 "VAT Statement Report Line"
{
    Caption = 'VAT Statement Report Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// VAT report number that this statement line belongs to.
        /// </summary>
        field(1; "VAT Report No."; Code[20])
        {
            Caption = 'VAT Report No.';
            Editable = false;
            TableRelation = "VAT Report Header"."No.";
        }
        /// <summary>
        /// VAT report configuration code defining the report type and processing rules.
        /// </summary>
        field(2; "VAT Report Config. Code"; Enum "VAT Report Configuration")
        {
            Caption = 'VAT Report Config. Code';
            Editable = true;
            TableRelation = "VAT Reports Configuration"."VAT Report Type";
        }
        /// <summary>
        /// Sequential line number for ordering statement lines within the VAT report.
        /// </summary>
        field(3; "Line No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Line No.';
            Editable = false;
        }
        /// <summary>
        /// Row number displayed on VAT reports for line identification and reference.
        /// </summary>
        field(4; "Row No."; Code[10])
        {
            Caption = 'Row No.';
            ToolTip = 'Specifies a number that identifies the line.';
        }
        /// <summary>
        /// Description text for the VAT statement line explaining its purpose.
        /// </summary>
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the VAT report statement.';
        }
        /// <summary>
        /// Box number or field identifier used for electronic VAT return mapping.
        /// </summary>
        field(6; "Box No."; Text[30])
        {
            Caption = 'Box No.';
            ToolTip = 'Specifies the number on the box that the VAT statement applies to.';
        }
        /// <summary>
        /// Base amount calculated for this VAT statement line from underlying transactions.
        /// </summary>
        field(7; Base; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Base';
            ToolTip = 'Specifies the amount that the VAT amount in the amount is calculated from.';
            Editable = false;
        }
        /// <summary>
        /// VAT amount calculated for this statement line based on applicable rates and base amounts.
        /// </summary>
        field(8; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            ToolTip = 'Specifies the amount of the entry in the report statement.';
            Editable = false;
        }
        /// <summary>
        /// Additional notes or comments related to this VAT statement line.
        /// </summary>
        field(9; Note; Text[250])
        {
            Caption = 'Note';
            ToolTip = 'Specifies any text that you want to add to the specific line.';
        }
    }

    keys
    {
        key(Key1; "VAT Report No.", "VAT Report Config. Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportHeader.Get("VAT Report Config. Code", "VAT Report No.");

        if (VATReportHeader.Status = VATReportHeader.Status::Released) and
           (not VATReportSetup."Modify Submitted Reports")
        then
            Error(MissingSetupErr, VATReportSetup.TableCaption());
    end;

    var
        VATReportHeader: Record "VAT Report Header";
        MissingSetupErr: Label 'This is not allowed because of the setup in the %1 window.', Comment = '%1 = Setup table';
}
