// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;

page 6933 "Expense Management Role Center"
{
    Caption = 'Expense Management';
    PageType = RoleCenter;

    actions
    {
        area(Sections)
        {
            group("Expense Management")
            {
                Caption = 'Expense Management';

                group(Expenses)
                {
                    Caption = 'Expenses';

                    action("Expenses List")
                    {
                        Caption = 'Expenses';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page Expenses;
                        ToolTip = 'View and manage expenses.';
                    }
                    action("Expense Reports")
                    {
                        Caption = 'Expense Reports';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Expense Reports";
                        ToolTip = 'View and manage expense reports.';
                    }
                    action("Posted Expense Reports")
                    {
                        Caption = 'Posted Expense Reports';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Posted Expense Reports";
                        ToolTip = 'View posted expense reports.';
                    }
                }
                group(Users)
                {
                    Caption = 'Users';

                    action("Expense Users")
                    {
                        Caption = 'Expense Users';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Expense Users";
                        ToolTip = 'View and manage expense users.';
                    }
                    action("Expense Teams")
                    {
                        Caption = 'Expense Teams';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Expense Teams";
                        ToolTip = 'View and manage expense teams.';
                    }
                    action("Employees")
                    {
                        Caption = 'Employees';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Employee List";
                        ToolTip = 'View and manage employees.';
                    }
                }
                group(Entries)
                {
                    Caption = 'Entries';

                    action("Expense Ledger Entries")
                    {
                        Caption = 'Expense Ledger Entries';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Expense Ledger Entries";
                        ToolTip = 'View expense ledger entries.';
                    }
                    action("Employee Ledger Entries")
                    {
                        Caption = 'Employee Ledger Entries';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Employee Ledger Entries";
                        ToolTip = 'View employee ledger entries.';
                    }
                }
                group(Reports)
                {
                    Caption = 'Reports';

                    action("Expense Report Cover Page")
                    {
                        Caption = 'Expense Report Cover Page';
                        ApplicationArea = Basic, Suite;
                        RunObject = Report "Expense Report Cover Page";
                        ToolTip = 'Run expense report cover page report.';
                    }
                    action("Expense Report Details")
                    {
                        Caption = 'Expense Report Details';
                        ApplicationArea = Basic, Suite;
                        RunObject = Report "Expense Report Details";
                        ToolTip = 'Run expense report details.';
                    }
                    action("Expense Report Summary Page")
                    {
                        Caption = 'Expense Report Summary Page';
                        ApplicationArea = Basic, Suite;
                        RunObject = Report "Expense Report Summary Page";
                        ToolTip = 'Run expense report Summary page.';
                    }
                }
                group(Setup)
                {
                    Caption = 'Setup';

                    action("Expense Agent Setup")
                    {
                        Caption = 'Expense Agent Setup';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Expense Agent Setup";
                        ToolTip = 'Configure expense agent settings.';
                    }
                    action("Expense Categories")
                    {
                        Caption = 'Expense Categories';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Expense Categories";
                        ToolTip = 'Setup expense categories.';
                    }
                    action("Expense Subcategories")
                    {
                        Caption = 'Expense Subcategories';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Expense Subcategories";
                        ToolTip = 'Setup expense subcategories.';
                    }
                    action("Expense Locations")
                    {
                        Caption = 'Expense Locations';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Expense Locations";
                        ToolTip = 'Setup expense locations.';
                    }
                    action("Expense Groups")
                    {
                        Caption = 'Expense Groups';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Expense Groups";
                        ToolTip = 'Setup expense groups.';
                    }
                    action("Expense Payment Methods")
                    {
                        Caption = 'Expense Payment Methods';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Expense Payment Methods";
                        ToolTip = 'Setup expense payment methods.';
                    }
                    action("Expense Management Rules")
                    {
                        Caption = 'Expense Management Rules';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Expense Management Rules";
                        ToolTip = 'Setup expense management rules.';
                    }
                    action("Expense Approvals Setup")
                    {
                        Caption = 'Expense Approvals Setup';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Expense Approval Setup";
                        ToolTip = 'Setup expense approvals.';
                    }
                    action("Expense Posting Groups")
                    {
                        Caption = 'Expense Posting Groups';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Expense Posting Groups";
                        ToolTip = 'Setup expense posting groups.';
                    }
                    action("Employee Posting Groups")
                    {
                        Caption = 'Employee Posting Groups';
                        ApplicationArea = Basic, Suite;
                        RunObject = Page "Employee Posting Groups";
                        ToolTip = 'Setup employee posting groups.';
                    }
                }
            }
        }
    }
}