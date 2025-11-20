// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.GeneralLedger.Setup;
using System.Reflection;
using System.Utilities;

page 101 "General Journal Templates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'General Journal Templates';
    PageType = List;
    SourceTable = "Gen. Journal Template";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal template you are creating.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a brief description of the journal template you are creating.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the journal type. The type determines what the window will look like.';
                }
                field(Recurring; Rec.Recurring)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the journal template will be a recurring journal.';
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Posting No. Series"; Rec."Posting No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign document numbers to ledger entries that are posted from journals using this template.';
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Force Doc. Balance"; Rec."Force Doc. Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether transactions that are posted in the general journal must balance by document number and document type, in addition to balancing by date.';
                }
                field("Copy VAT Setup to Jnl. Lines"; Rec."Copy VAT Setup to Jnl. Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the program to calculate VAT for accounts and balancing accounts on the journal line of the selected journal template.';

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if Rec."Copy VAT Setup to Jnl. Lines" <> xRec."Copy VAT Setup to Jnl. Lines" then
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(Text001, Rec.FieldCaption("Copy VAT Setup to Jnl. Lines")), true)
                            then
                                Error(Text002);
                    end;
                }
                field("Increment Batch Name"; Rec."Increment Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if batch names using this template are automatically incremented. Example: The posting following BATCH001 is automatically named BATCH002.';
                }
                field("Allow VAT Difference"; Rec."Allow VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to allow the manual adjustment of VAT amounts in journals.';

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if Rec."Allow VAT Difference" <> xRec."Allow VAT Difference" then
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(Text001, Rec.FieldCaption("Allow VAT Difference")), true)
                            then
                                Error(Text002);
                    end;
                }
                field("Allow Posting Date From"; Rec."Allow Posting Date From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date when posting to the journal template is allowed.';
                    Visible = IsJournalTemplNameMandatoryVisible;
                }
                field("Allow Posting Date To"; Rec."Allow Posting Date To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date when posting to the journal template is allowed.';
                    Visible = IsJournalTemplNameMandatoryVisible;
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Test Report ID"; Rec."Test Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the test report that is printed when you click Test Report.';
                    Visible = false;
                }
                field("Test Report Caption"; Rec."Test Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the test report that is printed when you print a journal under this journal template.';
                    Visible = false;
                }
                field("Posting Report ID"; Rec."Posting Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the posting report that is printed when you choose Post and Print.';
                    Visible = false;
                }
                field("Posting Report Caption"; Rec."Posting Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the report that is printed when you print the journal.';
                    Visible = false;
                }
                field("Force Posting Report"; Rec."Force Posting Report")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether a report is printed automatically when you post.';
                    Visible = false;
                }
                field("Cust. Receipt Report ID"; Rec."Cust. Receipt Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies how to print customer receipts when you post.';
                    Visible = false;
                }
                field("Cust. Receipt Report Caption"; Rec."Cust. Receipt Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies how to print customer receipts when you post.';
                    Visible = false;
                }
                field("Vendor Receipt Report ID"; Rec."Vendor Receipt Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies how to print vendor receipts when you post.';
                    Visible = false;
                }
                field("Vendor Receipt Report Caption"; Rec."Vendor Receipt Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies how to print vendor receipts when you post.';
                    Visible = false;
                }
                field("Copy to Posted Jnl. Lines"; Rec."Copy to Posted Jnl. Lines")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the journal lines to be copied to posted journal lines of the selected journal template.';

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if Rec."Copy to Posted Jnl. Lines" <> xRec."Copy to Posted Jnl. Lines" then
                            if not ConfirmManagement.GetResponseOrDefault(EnableCopyToPostedQst, true) then
                                Error(Text002);
                    end;
                }
                field("Unlink Inc. Doc On Posting"; Rec."Unlink Inc. Doc On Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the the incoming document will be unlinked from the journal when it is posted.';
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
        area(navigation)
        {
            group("Te&mplate")
            {
                Caption = 'Te&mplate';
                Image = Template;
                action(Batches)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Batches';
                    Image = Description;
                    RunObject = Page "General Journal Batches";
                    RunPageLink = "Journal Template Name" = field(Name);
                    ToolTip = 'View or edit multiple journals for a specific template. You can use batches when you need multiple journals of a certain type.';
                    Scope = Repeater;
                }
            }
        }
        area(Promoted)
        {
            actionref("Batches_Promoted"; Batches)
            {

            }
        }
    }

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        IsJournalTemplNameMandatoryVisible: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Do you want to update the %1 field on all general journal batches?';
#pragma warning restore AA0470
        Text002: Label 'Canceled.';
#pragma warning restore AA0074
        EnableCopyToPostedQst: Label 'Do you want to enable copying of journal lines to posted general journal on journal batches that belong to selected general journal template?';

    trigger OnOpenPage()
    begin
        GeneralLedgerSetup.Get();
        IsJournalTemplNameMandatoryVisible := GeneralLedgerSetup."Journal Templ. Name Mandatory";
    end;
}

