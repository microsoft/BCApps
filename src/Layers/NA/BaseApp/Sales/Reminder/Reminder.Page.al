// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Outlook;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reports;
using Microsoft.Utilities;
using System.Telemetry;

/// <summary>
/// Displays the document card for creating and editing reminder documents before issuing.
/// </summary>
page 434 Reminder
{
    Caption = 'Reminder';
    PageType = Document;
    SourceTable = "Reminder Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the customer you want to post a reminder for.';

                    trigger OnValidate()
                    begin
                        ContactCustomer.GetPrimaryContact(Rec."Customer No.", PrimaryContact);
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the customer the reminder is for.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    QuickEntry = false;
                    ToolTip = 'Specifies the address of the customer the reminder is for.';
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    QuickEntry = false;
                    ToolTip = 'Specifies additional address information.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    QuickEntry = false;
                    ToolTip = 'Specifies the city name of the customer the reminder is for.';
                }
                field(County; Rec.County)
                {
                    Caption = 'State / ZIP Code';
                    ToolTip = 'Specifies the customer''s state and postal code on the reminder.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    QuickEntry = false;
                    ToolTip = 'Specifies the postal code.';
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the person you regularly contact when you communicate with the customer the reminder is for.';
                }
                field(ContactPhoneNo; PrimaryContact."Phone No.")
                {
                    Caption = 'Phone No.';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Additional;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the telephone number of the customer contact person the reminder is for.';
                }
                field(ContactMobilePhoneNo; PrimaryContact."Mobile Phone No.")
                {
                    Caption = 'Mobile Phone No.';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Additional;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the mobile telephone number of the customer contact person the reminder is for.';
                }
                field(ContactEmail; PrimaryContact."E-Mail")
                {
                    Caption = 'Email';
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the email address of the customer contact person the reminder is for.';
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the customer''s reference. The content will be printed on the related document.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the reminder should be issued.';
                }
                field("VAT Reporting Date"; Rec."VAT Reporting Date")
                {
                    ApplicationArea = VAT;
                    Editable = VATDateEnabled;
                    Visible = VATDateEnabled;
                    ToolTip = 'Specifies the date used to include entries on VAT reports in a VAT period. This is either the date that the document was created or posted, depending on your setting on the General Ledger Setup page.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Reminder Level"; Rec."Reminder Level")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the reminder''s level.';
                }
                field("Use Header Level"; Rec."Use Header Level")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the condition of the level for the Reminder Level field is applied to all suggested reminder lines.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
            }
            part(ReminderLines; "Reminder Lines")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Reminder No." = field("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Reminder Terms Code"; Rec."Reminder Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies how reminders about late payments are handled for this customer.';
                }
                field("Fin. Charge Terms Code"; Rec."Fin. Charge Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the involved finance charges in case of late payment.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies when payment of the amount on the reminder is due.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code of the reminder.';

                    trigger OnAssistEdit()
                    begin
                        Rec.TestField("Posting Date");
                        ChangeExchangeRate.SetParameter(
                          Rec."Currency Code",
                          CurrExchRate.ExchangeRate(Rec."Posting Date", Rec."Currency Code"),
                          Rec."Posting Date");
                        ChangeExchangeRate.Editable(false);
                        if ChangeExchangeRate.RunModal() = ACTION::OK then;
                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Company Bank Account Code"; Rec."Company Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the bank account to use for bank information when the document is printed.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
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
            part(Control9; "Customer Ledger Entry FactBox")
            {
                ApplicationArea = Basic, Suite;
                Provider = ReminderLines;
                SubPageLink = "Entry No." = field("Entry No.");
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
                action(List)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View all reminders that exist.';

                    trigger OnAction()
                    begin
                        ReminderHeader.Copy(Rec);
                        if PAGE.RunModal(0, ReminderHeader) = ACTION::LookupOK then
                            Rec := ReminderHeader;
                    end;
                }
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
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = field("Customer No.");
                    ToolTip = 'Open the card of the customer that the reminder or finance charge applies to. ';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Enabled = Rec."No." <> '';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                        CurrPage.SaveRecord();
                    end;
                }
                separator(Action32)
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
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
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
                    Visible = not IsOfficeAddin;

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
                    begin
                        CurrPage.SetSelectionFilter(ReminderHeader);
                        REPORT.RunModal(REPORT::"Issue Reminders", true, true, ReminderHeader);
                    end;
                }
            }
        }
        area(reporting)
        {
            group(Customer)
            {
                Caption = 'Customer';
                Image = "Report";
                action("Customer - Order Summary")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer - Order Summary';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Customer - Order Summary";
                    ToolTip = 'View the order detail (the quantity not yet shipped) for each customer in three periods of 30 days each, starting from a selected date. There are also columns with orders to be shipped before and after the three periods and a column with the total order detail for each customer. The report can be used to analyze a company''s expected sales volume.';
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
                    Visible = false;
                }
                action("Customer Account Detail")
                {
                    Caption = 'Customer Account Detail';
                    Image = "Report";
                    RunObject = Report "Customer Account Detail";
                    ToolTip = 'View the detailed account activity for each customer for any period of time. The report lists all activity with running account balances, or only open items or only closed items with totals of either. The report can also show the application of payments to invoices.';
                }
                action("Report Statement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statement';
                    Image = "Report";
                    RunObject = Report "Customer Statement";
                    ToolTip = 'View a list of a customer''s transactions for a selected period, for example, to send to the customer at the close of an accounting period. You can choose to have all overdue balances displayed regardless of the period specified, or you can choose to include an aging band.';
                }
                action("Aged Accounts Receivable")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Aged Accounts Receivable';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Aged Accounts Receivable NA";
                    ToolTip = 'View an overview of when customer payments are due or overdue, divided into four periods. You must specify the date you want aging calculated from and the length of the period that each column will contain data for.';
                }
                action("Customer - Payment Receipt")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer - Payment Receipt';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Customer - Payment Receipt";
                    ToolTip = 'View a document showing which customer ledger entries that a payment has been applied to. This report can be used as a payment receipt that you send to the customer.';
                }
                action("Open Customer Entries")
                {
                    Caption = 'Open Customer Entries';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Open Customer Entries";
                    ToolTip = 'View open customer entries. This report lists the open entries for each customer, and shows the age (days overdue) and remaining amount due in the transaction currency for each open entry.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Issue_Promoted; Issue)
                {
                }
                actionref(SuggestReminderLines_Promoted; SuggestReminderLines)
                {
                }
                actionref(UpdateReminderText_Promoted; UpdateReminderText)
                {
                }
                actionref("C&ustomer_Promoted"; "C&ustomer")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Reminder', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
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

                actionref("Report Statement_Promoted"; "Report Statement")
                {
                }
                actionref("Customer Account Detail_Promoted"; "Customer Account Detail")
                {
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord();
        exit(Rec.ConfirmDeletion());
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if (not DocNoVisible) and (Rec."No." = '') then begin
            Rec.SetCustomerFromFilter();
            if Rec."Customer No." <> '' then
                Rec.SetReminderNo();
        end;
    end;

    trigger OnOpenPage()
    var
        OfficeMgt: Codeunit "Office Management";
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        SetDocNoVisible();
        IsOfficeAddin := OfficeMgt.IsAvailable();
        VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
        FeatureTelemetry.LogUptake('0000LB3', 'Reminder', Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUptake('0000LB4', 'Reminder', Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000LB5', 'Reminder', 'Reminder page open.');
    end;

    trigger OnAfterGetRecord()
    begin
        ContactCustomer.GetPrimaryContact(Rec."Customer No.", PrimaryContact);
    end;

    var
        ContactCustomer: Record Customer;
        PrimaryContact: Record Contact;
        ReminderHeader: Record "Reminder Header";
        CurrExchRate: Record "Currency Exchange Rate";
        ChangeExchangeRate: Page "Change Exchange Rate";
        DocNoVisible: Boolean;
        IsOfficeAddin: Boolean;
        VATDateEnabled: Boolean;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo;
    begin
        DocNoVisible := DocumentNoVisibility.SalesDocumentNoIsVisible(DocType::Reminder, Rec."No.");
    end;
}
