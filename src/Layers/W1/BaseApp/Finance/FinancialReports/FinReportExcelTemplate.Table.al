// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Stores Excel template layouts for financial report export formatting.
/// Enables custom Excel output layouts for financial reports with reusable templates.
/// </summary>
table 764 "Fin. Report Excel Template"
{
    Caption = 'Financial Report Excel Layout';
    DataClassification = CustomerContent;
    LookupPageId = "Fin. Report Excel Templates";

    fields
    {
        /// <summary>
        /// Financial report name linked to Excel template for export formatting.
        /// </summary>
        field(1; "Financial Report Name"; Code[10])
        {
            Caption = 'Financial Report Name';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "Financial Report";
            ToolTip = 'Specifies the name of the financial report.';
        }
        /// <summary>
        /// Unique code identifying the Excel template within financial report.
        /// </summary>
        field(2; Code; Code[50])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            NotBlank = true;
            ToolTip = 'Specifies the code of the layout.';
        }
        /// <summary>
        /// Description of Excel template layout for user identification and selection.
        /// </summary>
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies a description of the Excel Layout to help users understand what the layout does.';

        }
        /// <summary>
        /// Excel template file stored as BLOB for financial report export formatting.
        /// </summary>
        field(4; Template; Blob)
        {
            Caption = 'Layout';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the Excel layout file.';
        }
        /// <summary>
        /// File name for Excel export output when using this template layout.
        /// </summary>
        field(5; "File Name"; Text[250])
        {
            Caption = 'File Name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the file name of the layout when exported. If not specified the financial report name will be used instead.';
        }
    }

    keys
    {
        key(PK; "Financial Report Name", Code)
        {
            Clustered = true;
        }
    }
}