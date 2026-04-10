// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

/// <summary>
/// Temporary buffer table for staging intercompany journal line dimension data during API-based data exchange.
/// Stores dimension-specific information associated with journal lines for cross-company dimension validation and mapping.
/// </summary>
table 611 "Buffer IC InOut Jnl. Line Dim."
{
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        /// <summary>
        /// Table identifier for the source journal line table in the intercompany transaction.
        /// </summary>
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        /// <summary>
        /// Intercompany partner code identifying the originating company for this dimension data.
        /// </summary>
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
        }
        /// <summary>
        /// Unique transaction number assigned by the intercompany system for tracking purposes.
        /// </summary>
        field(3; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        /// <summary>
        /// Journal line number that this dimension data is associated with.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Dimension code defining the type of dimension (Department, Project, etc.).
        /// </summary>
        field(5; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
        }
        /// <summary>
        /// Specific dimension value assigned to the journal line for this dimension code.
        /// </summary>
        field(6; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
        }
        /// <summary>
        /// Source of the intercompany transaction (Created by Current Company, Rejected by IC Partner, etc.).
        /// </summary>
        field(7; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            OptionCaption = 'Rejected,Created';
            OptionMembers = Rejected,Created;
        }
        /// <summary>
        /// Unique operation identifier for tracking API-based data exchange processes and error resolution.
        /// </summary>
        field(8100; "Operation ID"; Guid)
        {
            Editable = false;
            Caption = 'Operation ID';
        }
    }

    keys
    {
        key(Key1; "Table ID", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.", "Dimension Code")
        {
            Clustered = true;
        }
    }
}
