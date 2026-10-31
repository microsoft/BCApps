// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEANSCHEMA30
namespace Microsoft.Intercompany.Dimension;

using System.Reflection;

/// <summary>
/// Stores dimension data for intercompany documents to enable dimension tracking across company transactions.
/// Links dimension values to specific intercompany transactions and document lines.
/// </summary>
table 442 "IC Document Dimension"
{
    Caption = 'IC Document Dimension';
    DataClassification = CustomerContent;
    ObsoleteReason = 'Moved to the Intercompany app.';
    ObsoleteState = Moved;
    ObsoleteTag = '30.0';
    MovedTo = '74676280-1b87-43cc-8ca2-3b2b17a5b81d';

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
        }
        /// <summary>
        /// Intercompany dimension value code specifying the actual dimension value for this document dimension entry.
        /// </summary>
        field(7; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            NotBlank = true;
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
}
#endif
