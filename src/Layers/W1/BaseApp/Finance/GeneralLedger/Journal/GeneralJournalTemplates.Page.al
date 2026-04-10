// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.GeneralLedger.Setup;
using System.Reflection;
using System.Utilities;

/// <summary>
/// Administrative page for managing general journal templates that define journal types and configurations.
/// Provides template setup including journal type, recurring options, balancing account defaults, and page assignments.
/// </summary>
/// <remarks>
/// Template management interface for configuring journal template structures and behaviors.
/// Key features: Template type configuration, recurring journal setup, balancing account defaults, page assignment management.
/// Integration: Links to journal batches, provides template-level configuration for all journal operations.
/// Actions: Navigate to batches, configure posting restrictions, manage source codes and reason codes.
/// </remarks>
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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the journal type. The type determines what the window will look like.';
                }
                field(Recurring; Rec.Recurring)
                {
                    ApplicationArea = Suite;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting No. Series"; Rec."Posting No. Series")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Force Doc. Balance"; Rec."Force Doc. Balance")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Copy VAT Setup to Jnl. Lines"; Rec."Copy VAT Setup to Jnl. Lines")
                {
                    ApplicationArea = Basic, Suite;

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
                }
                field("Allow VAT Difference"; Rec."Allow VAT Difference")
                {
                    ApplicationArea = Basic, Suite;

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
                    Visible = IsJournalTemplNameMandatoryVisible;
                }
                field("Allow Posting Date To"; Rec."Allow Posting Date To")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = IsJournalTemplNameMandatoryVisible;
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    Visible = false;
                }
                field("Test Report ID"; Rec."Test Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Test Report Caption"; Rec."Test Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    Visible = false;
                }
                field("Posting Report ID"; Rec."Posting Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Posting Report Caption"; Rec."Posting Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    Visible = false;
                }
                field("Force Posting Report"; Rec."Force Posting Report")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Cust. Receipt Report ID"; Rec."Cust. Receipt Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Cust. Receipt Report Caption"; Rec."Cust. Receipt Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    Visible = false;
                }
                field("Vendor Receipt Report ID"; Rec."Vendor Receipt Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Vendor Receipt Report Caption"; Rec."Vendor Receipt Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    Visible = false;
                }
                field("Copy to Posted Jnl. Lines"; Rec."Copy to Posted Jnl. Lines")
                {
                    ApplicationArea = Suite;

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

