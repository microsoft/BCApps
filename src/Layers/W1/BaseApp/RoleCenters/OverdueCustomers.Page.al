// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.CRM.BusinessRelation;
using Microsoft.Sales.Reminder;
using Microsoft.CRM.Contact;
using System.EMail;
using Microsoft.CRM.Interaction;

page 1321 "Overdue Customers"
{
    PageType = ListPart;
    SourceTable = Customer;
    SourceTableTemporary = true;
    Caption = 'Customers with overdue balance';
    DeleteAllowed = false;
    InsertAllowed = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(OverdueCustomers)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Customer Name';
                    ToolTip = 'Specifies the name of the customer.';
                }
                field(ContactField; Rec.Contact)
                {
                    ApplicationArea = All;
                    Caption = 'Contact';
                    ToolTip = 'Specifies the contact person at the customer''s company.';
                }
                field("Balance Due (LCY)"; Rec."Balance Due (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Balance Due (LCY)';
                    ToolTip = 'Specifies the balance due for this customer in local currency.';
                    trigger OnDrillDown()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                        CustomerLedgerEntries: Page "Customer Ledger Entries";
                    begin
                        CustLedgerEntry.SetRange("Customer No.", Rec."No.");
                        CustLedgerEntry.SetRange(Open, true);
                        CustomerLedgerEntries.SetTableView(CustLedgerEntry);
                        CustomerLedgerEntries.Run();
                    end;
                }
                field(DueDate; DueDate)
                {
                    ApplicationArea = All;
                    Caption = 'Earliest Due Date';
                    ToolTip = 'Specifies the earliest due date for this customer''s invoices.';
                }
                field("Issued Reminder Level"; IssuedReminderLevel)
                {
                    ApplicationArea = All;
                    Caption = 'Issued Reminder Level';
                    ToolTip = 'Specifies the highest reminder level issued for this customer.';
                    trigger OnDrillDown()
                    var
                        IssuedReminderHeader: Record "Issued Reminder Header";
                        IssuedReminders: Page "Issued Reminder List";
                    begin
                        if IssuedReminderLevel = 0 then begin
                            if Confirm('No issued reminders for this customer. Do you wish to create a reminder?') then
                                CreateReminder(Rec."No.");
                            exit;
                        end;
                        IssuedReminderHeader.SetRange("Customer No.", Rec."No.");
                        IssuedReminders.SetTableView(IssuedReminderHeader);
                        IssuedReminders.Run();
                    end;
                }

            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenContacts)
            {
                ApplicationArea = All;
                Caption = 'Open Contacts';
                Image = ContactPerson;
                ToolTip = 'Opens the contact list for this customer.';
                RunObject = page "Contact List";
                RunPageLink = "Company Name" = field(Name),
                            "Contact Business Relation" = const(Customer);
                Scope = Repeater;
            }
            action(SendAnEmail)
            {
                ApplicationArea = All;
                Caption = 'Send an Email';
                Image = Email;
                ToolTip = 'Sends an email to the main contact';
                Scope = Repeater;

                trigger OnAction()
                var
                    TempEmailItem: Record "Email Item" temporary;
                    Contact: Record Contact;
                    EmailScenario: Enum "Email Scenario";
                begin
                    GetContact(Rec, Contact);
                    TempEmailItem.AddSourceDocument(Database::Contact, Contact.SystemId);
                    TempEmailItem."Send to" := Contact."E-Mail";
                    TempEmailItem.Send(false, EmailScenario::Default);
                end;
            }
            action(MakePhoneCall)
            {
                ApplicationArea = All;
                Caption = 'Make Phone Call';
                Image = Calls;
                Scope = Repeater;
                ToolTip = 'Calls the main contact.';

                trigger OnAction()
                var
                    Contact: Record Contact;
                    TAPIManagement: Codeunit TAPIManagement;
                begin
                    GetContact(Rec, Contact);
                    TAPIManagement.DialContCustVendBank(Database::Contact, Contact."No.", Contact.GetDefaultPhoneNo(), '');
                end;
            }
            action(CreateAReminder)
            {
                ApplicationArea = All;
                Caption = 'Create a Reminder';
                Image = Reminder;
                ToolTip = 'Creates a reminder for this customer.';
                Scope = Repeater;

                trigger OnAction()
                begin
                    CreateReminder(Rec."No.");
                end;
            }
        }
    }


    var
        IssuedReminderLevel: Integer;
        DueDate: Date;
        NoContactConfiguredForCustomerErr: Label 'No contact configured for this customer.';

    trigger OnOpenPage()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        MaxCustomersShown, NCustomersShown : Integer;
    begin
        MaxCustomersShown := 20;
        NCustomersShown := 0;
        CustLedgerEntry.SetRange("Due Date", 0D, WorkDate());
        CustLedgerEntry.SetRange(Open, true);
        if not CustLedgerEntry.FindSet() then
            exit;
        repeat
            Customer.SetRange("Date Filter", 0D, WorkDate());
            if Customer.Get(CustLedgerEntry."Customer No.") then
                if not Rec.Get(CustLedgerEntry."Customer No.") then begin
                    Customer.CalcFields("Balance Due (LCY)");
                    Rec.Copy(Customer);
                    Rec.Insert();
                    NCustomersShown += 1;
                end;
        until (CustLedgerEntry.Next() = 0) or (NCustomersShown >= MaxCustomersShown);
    end;

    trigger OnAfterGetRecord()
    begin
        IssuedReminderLevel := GetIssuedReminderLevel(Rec);
        DueDate := GetDueDate(Rec);
    end;

    local procedure GetContact(Customer: Record Customer; var Contact: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        if Customer."Primary Contact No." <> '' then
            Contact.SetRange("No.", Customer."Primary Contact No.")
        else
            if ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, Customer."No.") then
                Contact.SetRange("Company No.", ContactBusinessRelation."Contact No.");
        if not Contact.FindFirst() then
            Error(NoContactConfiguredForCustomerErr);
    end;

    local procedure CreateReminder(CustomerNo: Code[20])
    var
        CreateReminders: Report "Create Reminders";
    begin
        CreateReminders.SetCustomer(CustomerNo);
        CreateReminders.SetOpenReminderListAfter(true);
        CreateReminders.Run();
    end;

    local procedure GetDueDate(Customer: Record Customer): Date
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.SetRange("Due Date", 0D, WorkDate());
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetCurrentKey("Due Date");
        CustLedgerEntry.SetAscending("Due Date", true);
        if not CustLedgerEntry.FindFirst() then
            exit(0D);
        exit(CustLedgerEntry."Due Date");
    end;

    local procedure GetIssuedReminderLevel(Customer: Record Customer) ReminderLevel: Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLine: Record "Issued Reminder Line";
        DueDocumentNos: List of [Code[20]];
        DueDocumentNo: Code[20];
    begin
        IssuedReminderHeader.SetRange("Customer No.", Customer."No.");
        if not IssuedReminderHeader.FindSet() then
            exit(0);

        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.SetRange("Due Date", 0D, WorkDate());
        CustLedgerEntry.SetRange(Open, true);
        if not CustLedgerEntry.FindSet() then
            exit(0);

        repeat
            if not DueDocumentNos.Contains(CustLedgerEntry."Document No.") then
                DueDocumentNos.Add(CustLedgerEntry."Document No.");
        until CustLedgerEntry.Next() = 0;

        repeat
            foreach DueDocumentNo in DueDocumentNos do begin
                IssuedReminderLine.SetRange("Reminder No.", IssuedReminderHeader."No.");
                IssuedReminderLine.SetRange("Document No.", DueDocumentNo);
                if not IssuedReminderLine.IsEmpty() then
                    if ReminderLevel < IssuedReminderHeader."Reminder Level" then
                        ReminderLevel := IssuedReminderHeader."Reminder Level";
            end;
        until IssuedReminderHeader.Next() = 0;
    end;
}
