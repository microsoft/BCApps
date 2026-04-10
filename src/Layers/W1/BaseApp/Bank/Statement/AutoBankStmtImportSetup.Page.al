// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using Microsoft.Bank.BankAccount;

/// <summary>
/// Configures automatic bank statement import settings for bank accounts.
/// Provides setup interface for scheduling and automating bank statement processing.
/// </summary>
/// <remarks>
/// Source Table: Bank Account (270). Dialog page for configuring automatic import parameters.
/// Allows configuration of import frequency, file locations, and processing options.
/// Integrates with job queue system for scheduled bank statement import operations.
/// </remarks>
page 1269 "Auto. Bank Stmt. Import Setup"
{
    Caption = 'Automatic Bank Statement Import Setup';
    PageType = StandardDialog;
    SourceTable = "Bank Account";

    layout
    {
        area(content)
        {
            field("Transaction Import Timespan"; Rec."Transaction Import Timespan")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Number of Days Included';

                trigger OnValidate()
                begin
                    if not (Rec."Transaction Import Timespan" in [0 .. 9999]) then begin
                        Rec."Transaction Import Timespan" := xRec."Transaction Import Timespan";
                        Message(TransactionImportTimespanMustBePositiveMsg);
                    end;
                end;
            }
            field("Automatic Stmt. Import Enabled"; Rec."Automatic Stmt. Import Enabled")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Enabled';
            }
        }
    }

    actions
    {
    }

    var
        TransactionImportTimespanMustBePositiveMsg: Label 'The value in the Number of Days Included field must be a positive number not greater than 9999.';
}

