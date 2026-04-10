// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;
using Microsoft.Intercompany.Partner;
using System.Reflection;

/// <summary>
/// Stores dimension data for intercompany documents to enable dimension tracking across company transactions.
/// Links dimension values to specific intercompany transactions and document lines.
/// </summary>
table 442 "IC Document Dimension"
{
    Caption = 'IC Document Dimension';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Table identifier indicating which intercompany document table these dimensions belong to.
        /// </summary>
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        /// <summary>
        /// Transaction number linking these dimensions to the parent intercompany transaction.
        /// </summary>
        field(2; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        /// <summary>
        /// Code identifying the intercompany partner associated with these document dimensions.
        /// </summary>
        field(3; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Source of the transaction indicating whether rejected by current company or created by current company.
        /// </summary>
        field(4; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            OptionCaption = 'Rejected by Current Company,Created by Current Company';
            OptionMembers = "Rejected by Current Company","Created by Current Company";
        }
        /// <summary>
        /// Line number identifying the specific document line these dimensions are associated with.
        /// </summary>
        field(5; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Intercompany dimension code for this document dimension entry.
        /// </summary>
        field(6; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
            TableRelation = "IC Dimension";

            trigger OnValidate()
            begin
                if not DimMgt.CheckICDim("Dimension Code") then
                    Error(DimMgt.GetDimErr());
                "Dimension Value Code" := '';
            end;
        }
        /// <summary>
        /// Intercompany dimension value code specifying the actual dimension value for this document dimension entry.
        /// </summary>
        field(7; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            NotBlank = true;
            TableRelation = "IC Dimension Value".Code where("Dimension Code" = field("Dimension Code"));

            trigger OnValidate()
            begin
                if not DimMgt.CheckICDimValue("Dimension Code", "Dimension Value Code") then
                    Error(DimMgt.GetDimErr());
            end;
        }
    }

    keys
    {
        key(Key1; "Table ID", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.", "Dimension Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        DimMgt: Codeunit DimensionManagement;

    /// <summary>
    /// Opens the IC Document Dimensions page to view dimensions for a specific intercompany transaction.
    /// </summary>
    /// <param name="TableID">Table identifier for the document type</param>
    /// <param name="TransactionNo">Transaction number for filtering</param>
    /// <param name="PartnerCode">Intercompany partner code for filtering</param>
    /// <param name="TransactionSource">Transaction source for filtering</param>
    /// <param name="LineNo">Line number for filtering</param>
    procedure ShowDimensions(TableID: Integer; TransactionNo: Integer; PartnerCode: Code[20]; TransactionSource: Option; LineNo: Integer)
    var
        ICDocDimensions: Page "IC Document Dimensions";
    begin
        SetRange("Table ID", TableID);
        SetRange("Transaction No.", TransactionNo);
        SetRange("IC Partner Code", PartnerCode);
        SetRange("Transaction Source", TransactionSource);
        SetRange("Line No.", LineNo);
        Clear(ICDocDimensions);
        ICDocDimensions.SetTableView(Rec);
        ICDocDimensions.RunModal();
    end;
}

