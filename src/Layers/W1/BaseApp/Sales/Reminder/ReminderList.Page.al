// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Reports;
using System.Text;

page 436 "Reminder List"
{
    ApplicationArea = Suite;
    Caption = 'Reminders';
    CardPageID = Reminder;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    AboutTitle = 'About Reminders';
    AboutText = 'Create and manage reminders for customers with overdue payments, including customizing reminder texts, adding finance charges, and issuing reminders by print or email to support timely collections.';
    SourceTable = "Reminder Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                Editable = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer you want to post a reminder for.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer the reminder is for.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the reminder.';
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the outstanding amount that is due for the relevant customer ledger entry.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city name of the customer the reminder is for.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Reminder")
            {
                Caption = '&Reminder';
                Image = Reminder;
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Reminder Comment Sheet";
                    RunPageLink = Type = const(Reminder),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("C&ustomer")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ustomer';
                    Image = Customer;
                    RunObject = Page "Customer List";
                    RunPageLink = "No." = field("Customer No.");
                    ToolTip = 'Open the card of the customer that the reminder or finance charge applies to. ';
                }
                separator(Action8)
                {
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Reminder Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action(ReminderTerm)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reminder Terms';
                    Image = ReminderTerms;
                    RunObject = Page "Reminder Terms List";
                    RunPageMode = View;
                    Tooltip = 'Open the list of Reminder Terms.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CreateReminders)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Reminders';
                    Ellipsis = true;
                    Image = CreateReminders;
                    ToolTip = 'Create reminders for one or more customers with overdue payments.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Create Reminders");
                    end;
                }
                action(SuggestReminderLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Reminder Lines';
                    Ellipsis = true;
                    Image = SuggestReminderLines;
                    ToolTip = 'Create reminder lines in existing reminders for any overdue payments based on information in the Reminder window.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(ReminderHeader);
                        REPORT.RunModal(REPORT::"Suggest Reminder Lines", true, false, ReminderHeader);
                    end;
                }
                action(UpdateReminderText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Reminder Text';
                    Ellipsis = true;
                    Image = RefreshText;
                    ToolTip = 'Replace the beginning and ending text that has been defined for the related reminder level with those from a different level.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(ReminderHeader);
                        REPORT.RunModal(REPORT::"Update Reminder Text", true, false, ReminderHeader);
                    end;
                }
            }
            group("&Issuing")
            {
                Caption = '&Issuing';
                Image = Add;
                action(TestReport)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(ReminderHeader);
                        ReminderHeader.PrintRecords();
                    end;
                }
                action(Issue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Issue';
                    Ellipsis = true;
                    Image = ReleaseDoc;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post the specified reminder entries according to your specifications in the Reminder Terms window. This specification determines whether interest and/or additional fees are posted to the customer''s account and the general ledger.';

                    trigger OnAction()
                    var
                        IsHandled: Boolean;
                    begin
                        CurrPage.SetSelectionFilter(ReminderHeader);
                        IsHandled := false;
                        OnIssueOnBeforeIssueRemindersRunModal(ReminderHeader, IsHandled);
                        if not IsHandled then
                            REPORT.RunModal(REPORT::"Issue Reminders", true, true, ReminderHeader);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(reporting)
        {
#if not CLEAN26
            action("Reminder Nos.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'The action will be obsoleted.';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report Reminder;
                ToolTip = 'The action will be obsoleted.';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'The related report doesn''t exist anymore';
#pragma warning disable AS0074
                ObsoleteTag = '26.0';
#pragma warning restore AS0074
            }
#endif
            action("Reminder Test")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reminder Test';
                Image = "Report";
                ToolTip = 'Preview the reminder text before you issue the reminder and send it to the customer.';

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(ReminderHeader);
                    REPORT.RunModal(REPORT::"Reminder - Test", true, true, ReminderHeader);
                end;
            }
            action("Customer - Balance to Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - Balance to Date';
                Image = "Report";
                RunObject = Report "Customer - Balance to Date";
                ToolTip = 'View a list with customers'' payment history up until a certain date. You can use the report to extract your total sales income at the close of an accounting period or fiscal year.';
            }
            action("Customer - Detail Trial Bal.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - Detail Trial Bal.';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Customer - Detail Trial Bal.";
                ToolTip = 'View the balance for customers with balances on a specified date. The report can be used at the close of an accounting period, for example, or for an audit.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CreateReminders_Promoted; CreateReminders)
                {
                }
                actionref(Issue_Promoted; Issue)
                {
                }
                actionref(SuggestReminderLines_Promoted; SuggestReminderLines)
                {
                }
                actionref(UpdateReminderText_Promoted; UpdateReminderText)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Reminder', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                separator(Navigate_Separator)
                {
                }
                actionref("C&ustomer_Promoted"; "C&ustomer")
                {
                }
                actionref(ReminderTerm_Promoted; ReminderTerm)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Reminder Test_Promoted"; "Reminder Test")
                {
                }
                actionref("Customer - Balance to Date_Promoted"; "Customer - Balance to Date")
                {
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        exit(Rec.ConfirmDeletion());
    end;

    var
        ReminderHeader: Record "Reminder Header";

    procedure GetSelectionFilter(): Text
    var
        ReminderHeader: Record "Reminder Header";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(ReminderHeader);
        exit(SelectionFilterManagement.GetSelectionFilterForIssueReminder(ReminderHeader));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIssueOnBeforeIssueRemindersRunModal(var ReminderHeader: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;
}

