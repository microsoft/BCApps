// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Stores parameters for net customer/vendor balance processing operations.
/// Temporary table used to configure posting date, document numbering, and journal settings.
/// </summary>
/// <remarks>
/// Used by Net Customer/Vendor Balances report to capture user input parameters.
/// Validates document number format and provides initialization defaults.
/// Integrates with General Journal for template and batch selection.
/// </remarks>
table 109 "Net Balances Parameters"
{
    Caption = 'Net Balances Parameters';
    Tabletype = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the parameter record.
        /// </summary>
        field(1; ID; Code[20])
        {
            Caption = 'ID';
        }
        /// <summary>
        /// Date to be used for posting the netted balance entries.
        /// </summary>
        field(2; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        /// <summary>
        /// Starting document number for generated journal entries, incremented for each vendor.
        /// </summary>
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            trigger OnValidate()
            begin
                if "Document No." <> '' then
                    if IncStr("Document No.") = '' then
                        error(DocNoMustContainNumberErr);
            end;
        }
        /// <summary>
        /// Description text for the netted balance journal entries.
        /// </summary>
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Hold code to prevent modification of related customer and vendor ledger entries.
        /// </summary>
        field(5; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        /// <summary>
        /// Order preference for applying entries when multiple documents exist.
        /// </summary>
        field(6; "Order of Suggestion"; Enum "Net Cust/Vend Balances Order")
        {
            Caption = 'Order of Suggestion';
        }
        /// <summary>
        /// General journal template name for posting the netted entries.
        /// </summary>
        field(7; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";
        }
        /// <summary>
        /// General journal batch name within the specified template.
        /// </summary>
        field(8; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
    }

    keys
    {
        key(PK; ID) { }
    }

    var
        DocNoMustContainNumberErr: Label 'Document No. must contain a number.';
        DescriptionMsg: Label 'Net customer/vendor balances %1 %2', Comment = '%1 %2';
        PostingDateErr: Label 'Please enter the Posting Date.';
        DocumentNoErr: Label 'Please enter the Document No.';

    /// <summary>
    /// Initializes default values for posting date and description.
    /// Sets posting date to work date and creates standard description text.
    /// </summary>
    procedure Initialize()
    begin
        if "Posting Date" = 0D then
            "Posting Date" := WorkDate();
        Description := CopyStr(DescriptionMsg, 1, MaxStrLen(Description));
    end;

    /// <summary>
    /// Validates required fields before processing net balances operation.
    /// Ensures posting date and document number are specified.
    /// </summary>
    procedure Verify()
    begin
        if "Posting Date" = 0D then
            error(PostingDateErr);

        if "Document No." = '' then
            error(DocumentNoErr);
    end;

}
