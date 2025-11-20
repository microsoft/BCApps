// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

/// <summary>
/// Displays a list of positive pay entries showing upload history and summary information for bank accounts.
/// This page provides users with an overview of all positive pay file uploads and their status.
/// </summary>
/// <remarks>
/// The Positive Pay Entries page allows users to view the history of positive pay file uploads for bank accounts.
/// Users can see upload dates, times, confirmation numbers, and summary statistics including check counts and amounts.
/// The page provides navigation to detailed check information and supports re-exporting positive pay files if needed.
/// All fields are read-only as this page serves as a historical record of uploads rather than data entry.
/// </remarks>
page 1231 "Positive Pay Entries"
{
    Caption = 'Positive Pay Entries';
    DelayedInsert = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Positive Pay Entry";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account number. If you select Balance at Date, the balance as of the last day in the relevant time interval is displayed.';
                }
                field("Upload Date"; DT2Date(Rec."Upload Date-Time"))
                {
                    ApplicationArea = Suite;
                    Caption = 'Upload Date';
                    Editable = false;
                    ToolTip = 'Specifies the date when the Positive Pay file was uploaded.';
                }
                field("Upload Time"; DT2Time(Rec."Upload Date-Time"))
                {
                    ApplicationArea = Suite;
                    Caption = 'Upload Time';
                    Editable = false;
                    ToolTip = 'Specifies the time when the Positive Pay file was uploaded.';
                }
                field("Last Upload Date"; Rec."Last Upload Date")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the last date that you exported a Positive Pay file.';
                }
                field("Last Upload Time"; Rec."Last Upload Time")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the last time that you exported a Positive Pay file.';
                }
                field("Number of Uploads"; Rec."Number of Uploads")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies how many times the related Positive Pay file was uploaded.';
                }
                field("Number of Checks"; Rec."Number of Checks")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies how many checks were processed with the Positive Pay entry.';
                }
                field("Number of Voids"; Rec."Number of Voids")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies how many of the related checks were voided.';
                }
                field("Check Amount"; Rec."Check Amount")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount on the check.';
                }
                field("Void Amount"; Rec."Void Amount")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount in the Positive Pay file that is related to voided checks.';
                }
                field("Confirmation Number"; Rec."Confirmation Number")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the confirmation number that you receive when the file upload to the bank is successful.';
                }
                field("Upload Date-Time"; Rec."Upload Date-Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when the Positive Pay file was uploaded.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Bank Acc.")
            {
                Caption = '&Bank Acc.';
                Image = Bank;
                action(PositivePayEntryDetails)
                {
                    ApplicationArea = Suite;
                    Caption = 'Positive Pay Entry Details';
                    Image = CheckLedger;
                    RunObject = Page "Positive Pay Entry Details";
                    RunPageLink = "Bank Account No." = field(filter("Bank Account No.")),
                                  "Upload Date-Time" = field("Upload Date-Time");
                    ToolTip = 'Specifies the positive pay entries. If you select Net Change, the net change in the balance is displayed for the relevant time interval.';
                }
                action(ReexportPositivePay)
                {
                    ApplicationArea = Suite;
                    Caption = 'Reexport Positive Pay to File';
                    Image = ExportElectronicDocument;
                    ToolTip = 'Export the Positive Pay file again.';

                    trigger OnAction()
                    begin
                        Rec.Reexport();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ReexportPositivePay_Promoted; ReexportPositivePay)
                {
                }
            }
        }
    }
}

