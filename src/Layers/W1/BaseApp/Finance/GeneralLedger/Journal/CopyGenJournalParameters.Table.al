// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Stores parameters for copying general journal lines between batches with optional data replacement and transformation options.
/// Supports batch-to-batch copying with configurable field updates including posting dates, document numbers, and reference information.
/// </summary>
/// <remarks>
/// Temporary parameter storage for journal copying operations. Enables bulk journal line replication with customizable field transformations.
/// Key features: Template and batch selection, posting date replacement, document number updating, reference field modifications.
/// Integration: Used by copy journal management functions and journal copying user interfaces for parameter passing.
/// </remarks>
table 183 "Copy Gen. Journal Parameters"
{
    Caption = 'Copy Gen. Jnl. Line Parameters';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Primary key field for parameter record identification.
        /// </summary>
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        /// <summary>
        /// Source journal template name for copying journal lines.
        /// </summary>
        field(2; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            ToolTip = 'Specifies journal template is used to copy posted journal lines.';
            TableRelation = "Gen. Journal Template";
        }
        /// <summary>
        /// Source journal batch name containing lines to be copied.
        /// </summary>
        field(3; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            ToolTip = 'Specifies journal batch is used to copy posted journal lines.';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        /// <summary>
        /// Optional replacement posting date to apply to all copied journal lines.
        /// </summary>
        field(4; "Replace Posting Date"; Date)
        {
            Caption = 'Replace Posting Date';
            ToolTip = 'Specifies if the posting date will be validated with the value of current field while copy posted journal lines. If you leave this field blank original Posting Date will be used in Target Journal.';
        }
        /// <summary>
        /// Optional replacement document number to apply to copied journal lines.
        /// </summary>
        field(5; "Replace Document No."; Code[20])
        {
            Caption = 'Replace Document No.';
            ToolTip = 'Specifies if the document number will be replaced with the value of current field while copy posted journal lines. If you leave this field blank original Document No. will be used in Target Journal.';
        }
        /// <summary>
        /// Indicates whether to reverse the sign of amounts in copied journal lines.
        /// </summary>
        field(6; "Reverse Sign"; Boolean)
        {
            Caption = 'Reverse Sign';
            ToolTip = 'Specifies if the amount will be replaced with the opposite value while copy posted journal lines. If you leave this field disabled original amount will be used in Target Journal.';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
