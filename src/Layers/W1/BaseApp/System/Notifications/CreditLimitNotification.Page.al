namespace System.Environment.Configuration;

using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Reports;

page 1870 "Credit Limit Notification"
{
    Caption = 'Credit Limit Notification';
    DelayedInsert = false;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            label(Control4)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Heading;
                MultiLine = true;
                ShowCaption = false;
                ToolTip = 'Specifies the main message of the notification.';
            }
            part(CreditLimitDetails; "Credit Limit Details")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Manage")
            {
                Caption = '&Manage';
                action(Customer)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Image = Customer;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    RunPageMode = View;
                    ToolTip = 'View or edit detailed information about the customer.';
                }
            }
            group(Create)
            {
                Caption = 'Create';
                action(NewFinanceChargeMemo)
                {
                    AccessByPermission = TableData "Finance Charge Memo Header" = RIM;
                    ApplicationArea = Suite;
                    Caption = 'Finance Charge Memo';
                    Image = FinChargeMemo;
                    RunObject = Page "Finance Charge Memo";
                    RunPageLink = "Customer No." = field("No.");
                    RunPageMode = Create;
                    ToolTip = 'Create a new finance charge memo.';
                }
            }
            group("Report")
            {
                Caption = 'Report';
                action("Report Customer - Balance to Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer - Balance to Date';
                    Image = "Report";
                    ToolTip = 'View a list with customers'' payment history up until a certain date. You can use the report to extract your total sales income at the close of an accounting period or fiscal year.';

                    trigger OnAction()
                    var
                        CustomerCard: Page "Customer Card";
                    begin
                        CustomerCard.RunReport(REPORT::"Customer - Balance to Date", Rec."No.");
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';

                actionref(NewFinanceChargeMemo_Promoted; NewFinanceChargeMemo)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Report Customer - Balance to Date_Promoted"; "Report Customer - Balance to Date")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Customer_Promoted; Customer)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Create', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
        }
    }

    var
        Heading: Text[250];

    procedure SetHeading(Value: Text[250])
    begin
        Heading := Value;
    end;

    procedure InitializeFromNotificationVar(CreditLimitNotification: Notification)
    var
        Customer: Record Customer;
    begin
        Rec.Get(CreditLimitNotification.GetData(Customer.FieldName("No.")));
        Rec.SetRange("No.", Rec."No.");

        if Rec.GetFilter("Date Filter") = '' then
            Rec.SetFilter("Date Filter", '..%1', WorkDate());

        CurrPage.CreditLimitDetails.PAGE.InitializeFromNotificationVar(CreditLimitNotification);
    end;
}

