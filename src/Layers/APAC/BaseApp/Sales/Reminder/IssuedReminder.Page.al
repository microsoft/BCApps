// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.CRM.Contact;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Customer;

using Microsoft.Sales.Receivables;

page 438 "Issued Reminder"
{
    Caption = 'Issued Reminder';
    DeleteAllowed = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    SourceTable = "Issued Reminder Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer number the reminder is for.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer the reminder is for.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the customer the reminder is for.';
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional address information.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city name of the customer the reminder is for.';
                }
                field(County; Rec.County)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the county of the customer.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country or region of the customer.';
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
                    ToolTip = 'Specifies the posting date that the reminder was issued on.';
                }
                field("VAT Reporting Date"; Rec."VAT Reporting Date")
                {
                    ApplicationArea = VAT;
                    Visible = VATDateEnabled;
                    ToolTip = 'Specifies the VAT date for the reminder.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Pre-Assigned No."; Rec."Pre-Assigned No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the reminder from which the issued reminder was created.';
                }
                field("Reminder Level"; Rec."Reminder Level")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reminder''s level.';
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
                field(Canceled; Rec.Canceled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the issued reminder has been canceled.';
                }
            }
            part(ReminderLines; "Issued Reminder Lines")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "Reminder No." = field("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                Editable = false;
                field("Reminder Terms Code"; Rec."Reminder Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reminder terms code for the reminder.';
                }
                field("Fin. Charge Terms Code"; Rec."Fin. Charge Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the involved finance charges in case of late payment.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when payment of the amount on the reminder is due.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the issued reminder.';

                    trigger OnAssistEdit()
                    begin
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
            part(Control3; "Customer Ledger Entry FactBox")
            {
                ApplicationArea = Basic, Suite;
                Provider = ReminderLines;
                SubPageLink = "Entry No." = field("Entry No.");
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
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
                    ToolTip = 'View all issued reminders that exist.';

                    trigger OnAction()
                    begin
                        IssuedReminderHeader.Copy(Rec);
                        if PAGE.RunModal(0, IssuedReminderHeader) = ACTION::LookupOK then
                            Rec := IssuedReminderHeader;
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Reminder Comment Sheet";
                    RunPageLink = Type = const("Issued Reminder"),
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
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                separator(Action6)
                {
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Issued Reminder Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    IsHandled: Boolean;
                begin
                    IssuedReminderHeader := Rec;
                    IsHandled := false;
                    OnBeforePrintRecords(Rec, IssuedReminderHeader, IsHandled);
                    if IsHandled then
                        exit;
                    CurrPage.SetSelectionFilter(IssuedReminderHeader);
                    IssuedReminderHeader.PrintRecords(true, false, false);
                end;
            }
            action("Send by &Email")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Send by &Email';
                Image = Email;
                ToolTip = 'Prepare to send the document by email. The Send Email window opens prefilled for the customer where you can add or change information before you send the email.';

                trigger OnAction()
                var
                    IsHandled: Boolean;
                begin
                    IssuedReminderHeader := Rec;
                    IsHandled := false;
                    OnBeforeSendRecords(Rec, IssuedReminderHeader, IsHandled);
                    if IsHandled then
                        exit;
                    CurrPage.SetSelectionFilter(IssuedReminderHeader);
                    IssuedReminderHeader.PrintRecords(false, true, false);
                end;
            }
            action(MarkAsSent)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Mark as Sent';
                Image = SendConfirmation;
                ToolTip = 'Mark the reminder as sent.';

                trigger OnAction()
                var
                    SendReminder: Codeunit "Send Reminder";
                begin
                    SendReminder.UpdateReminderSentFromUI(Rec);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
            action(Cancel)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cancel';
                Ellipsis = true;
                Image = Cancel;
                ToolTip = 'Cancel the issued reminder.';

                trigger OnAction()
                begin
                    IssuedReminderHeader := Rec;
                    IssuedReminderHeader.SetRecFilter();
                    Rec.RunCancelIssuedReminder(IssuedReminderHeader);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("Send by &Email_Promoted"; "Send by &Email")
                {
                }
                actionref(MarkAsSent_Promoted; MarkAsSent)
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref(Cancel_Promoted; Cancel)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Category5)
            {
                Caption = 'Reminder', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("C&ustomer_Promoted"; "C&ustomer")
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 5.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnOpenPage()
    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
    begin
        VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
    end;

    trigger OnAfterGetRecord()
    var
        Customer: Record Customer;
    begin
        Customer.GetPrimaryContact(Rec."Customer No.", PrimaryContact);
    end;

    var
        PrimaryContact: Record Contact;
        IssuedReminderHeader: Record "Issued Reminder Header";
        CurrExchRate: Record "Currency Exchange Rate";
        ChangeExchangeRate: Page "Change Exchange Rate";
        VATDateEnabled: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(IssuedReminderHeaderRec: Record "Issued Reminder Header"; var IssuedReminderHeaderToPrint: Record "Issued Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendRecords(IssuedReminderHeaderRec: Record "Issued Reminder Header"; var IssuedReminderHeaderToSend: Record "Issued Reminder Header"; var IsHandled: Boolean)
    begin
    end;
}

