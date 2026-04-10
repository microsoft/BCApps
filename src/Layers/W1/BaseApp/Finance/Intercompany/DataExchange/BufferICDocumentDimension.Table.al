// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

/// <summary>
/// Temporary buffer table for staging intercompany document dimension data during API-based data exchange.
/// Facilitates dimension validation and transformation before posting to target partner systems.
/// </summary>
table 604 "Buffer IC Document Dimension"
{
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        /// <summary>
        /// Table identifier indicating which intercompany document table these dimensions belong to.
        /// </summary>
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
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
        /// Dimension code identifying the dimension type for this document dimension entry.
        /// </summary>
        field(6; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
        }
        /// <summary>
        /// Dimension value code specifying the actual dimension value for this document dimension entry.
        /// </summary>
        field(7; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            NotBlank = true;
        }
        /// <summary>
        /// Unique identifier for the intercompany data exchange operation.
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
