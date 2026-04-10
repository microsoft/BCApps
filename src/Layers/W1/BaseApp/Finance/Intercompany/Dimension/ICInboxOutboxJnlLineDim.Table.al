// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;
using Microsoft.Intercompany.Partner;

/// <summary>
/// Stores dimension data for intercompany journal lines in both inbox and outbox transactions.
/// Enables dimension tracking for intercompany general journal entries.
/// </summary>
table 423 "IC Inbox/Outbox Jnl. Line Dim."
{
    Caption = 'IC Inbox/Outbox Jnl. Line Dim.';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Table identifier indicating whether this is an inbox or outbox journal line dimension.
        /// </summary>
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        /// <summary>
        /// Code identifying the intercompany partner associated with this journal line dimension.
        /// </summary>
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Transaction number linking this dimension to the parent intercompany journal transaction.
        /// </summary>
        field(3; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        /// <summary>
        /// Line number identifying the specific journal line this dimension is associated with.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Intercompany dimension code for this journal line dimension entry.
        /// </summary>
        field(5; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            TableRelation = "IC Dimension";

            trigger OnValidate()
            begin
                if not DimMgt.CheckICDim("Dimension Code") then
                    Error(DimMgt.GetDimErr());
                "Dimension Value Code" := '';
            end;
        }
        /// <summary>
        /// Intercompany dimension value code specifying the actual dimension value for this journal line dimension entry.
        /// </summary>
        field(6; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            TableRelation = "IC Dimension Value".Code where("Dimension Code" = field("Dimension Code"));

            trigger OnValidate()
            begin
                if not DimMgt.CheckICDimValue("Dimension Code", "Dimension Value Code") then
                    Error(DimMgt.GetDimErr());
            end;
        }
        /// <summary>
        /// Source of the transaction indicating whether rejected or created by the partner.
        /// </summary>
        field(7; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            OptionCaption = 'Rejected,Created';
            OptionMembers = Rejected,Created;
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
}

