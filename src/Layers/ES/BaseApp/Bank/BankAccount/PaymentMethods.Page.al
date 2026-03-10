// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

/// <summary>
/// List interface for managing payment methods and their configurations.
/// Provides setup for payment processing options including balancing accounts and direct debit settings.
/// </summary>
/// <remarks>
/// Source Table: Payment Method (289). Administrative page for payment method configuration.
/// Features: Balancing account setup, direct debit configuration, translation management.
/// </remarks>
page 427 "Payment Methods"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Methods';
    PageType = List;
    AboutTitle = 'About Payment Methods';
    AboutText = 'Define and manage payment methods such as bank, cash, check, or direct debit for customers and vendors, specifying default options and related payment terms for use in sales and purchase transactions.';
    SourceTable = "Payment Method";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Invoices to Cartera"; Rec."Invoices to Cartera")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a check mark in this field to send the invoices to Portfolio for this specific payment method.';
                }
                field("Create Bills"; Rec."Create Bills")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a check mark so that this payment method creates bills.';
                }
                field("Bill Type"; Rec."Bill Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document that originated from this specific payment method.';
                }
                field("Collection Agent"; Rec."Collection Agent")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the collection agent to which you will deliver the document that originated from this specific payment method.';
                }
                field("Submit for Acceptance"; Rec."Submit for Acceptance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a check mark in this field if the bill must be sent to the customer for acceptance first.';
                }
                field("Direct Debit"; Rec."Direct Debit")
                {
                    ApplicationArea = Suite;
                }
                field("Direct Debit Pmt. Terms Code"; Rec."Direct Debit Pmt. Terms Code")
                {
                    ApplicationArea = Suite;
                }
                field("Pmt. Export Line Definition"; Rec."Pmt. Export Line Definition")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("SII Payment Method Code"; Rec."SII Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the sii:Medio node in the SII XML file.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("T&ranslation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'T&ranslation';
                Image = Translation;
                RunObject = Page "Payment Method Translations";
                RunPageLink = "Payment Method Code" = field(Code);
                ToolTip = 'View or edit descriptions for each payment method in different languages.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("T&ranslation_Promoted"; "T&ranslation")
                {
                }
            }
        }
    }
}

