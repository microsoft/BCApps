#pragma warning disable AA0247
page 35601 "Responsible Employees"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Responsible Employees';
    CardPageID = "Resp. Employee Card";
    Editable = false;
    PageType = List;
    SourceTable = Vendor;
    SourceTableView = sorting("Vendor Type", "No.")
                      where("Vendor Type" = const("Resp. Employee"));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related record.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1901138007; "Vendor Details FactBox")
            {
                SubPageLink = "No." = field("No.");
                Visible = false;
            }
            part(Control1904651607; "Vendor Statistics FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                Visible = true;
            }
            part(Control1903435607; "Vendor Hist. Buy-from FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                Visible = true;
            }
            part(Control1906949207; "Vendor Hist. Pay-to FactBox")
            {
                SubPageLink = "No." = field("No.");
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = true;
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
            group(Employee)
            {
                Caption = 'Employee';
                Image = Employee;
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = VendorLedger;
                    RunObject = Page "Vendor Ledger Entries";
                    RunPageLink = "Vendor No." = field("No.");
                    RunPageView = sorting("Vendor No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const(Vendor),
                                  "No." = field("No.");
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = const(23),
                                      "No." = field("No.");
                        ShortCutKey = 'Shift+Ctrl+D';
                    }
                    action("Dimensions-&Multiple")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;

                        trigger OnAction()
                        var
                            Vend: Record Vendor;
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(Vend);
                            DefaultDimMultiple.SetMultiRecord(Vend, Rec.FieldNo("No."));
                            DefaultDimMultiple.RunModal();
                        end;
                    }
                }
                action("Bank Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Accounts';
                    Image = BankAccount;
                    RunObject = Page "Vendor Bank Account List";
                    RunPageLink = "Vendor No." = field("No.");
                }
                action("Order &Addresses")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Order &Addresses';
                    Image = Addresses;
                    RunObject = Page "Order Address List";
                    RunPageLink = "Vendor No." = field("No.");
                }
                action("C&ontact")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ontact';
                    Image = ContactPerson;

                    trigger OnAction()
                    begin
                        Rec.ShowContact();
                    end;
                }
                separator(Action1210018)
                {
                }
                action(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Vendor Statistics";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Entry Statistics")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entry Statistics';
                    Image = EntryStatistics;
                    RunObject = Page "Vendor Entry Statistics";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                }
                action(Purchases)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchases';
                    Image = Purchase;
                    RunObject = Page "Vendor Purchases";
                    RunPageLink = "No." = field("No."),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                }
                separator(Action1210023)
                {
                }
                separator(Action1210025)
                {
                }
            }
            group("&Adv. Statements")
            {
                Caption = '&Adv. Statements';
                action("Unposted Advance Statements")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unposted Advance Statements';
                    Image = Documents;
                    RunObject = Page "Purchase Advance Reports";
                    RunPageLink = "Buy-from Vendor No." = field("No.");
                }
                action("Posted Advance Statements")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Advance Statements';
                    Image = RegisteredDocs;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    RunObject = Page "Posted Advance Statement";
                    RunPageLink = "Buy-from Vendor No." = field("No.");
                }
            }
            action("Vendor G/L Turnover")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor G/L Turnover';
                Image = GL;
                RunObject = Page "Vendor G/L Turnover";
                RunPageLink = "No." = field("No.");
                RunPageMode = Create;
                ToolTip = 'Analyze vendors'' turnover and account balances.';
            }
        }
        area(creation)
        {
            action("Purchase Credit Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Credit Memo';
                Image = CreditMemo;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = New;
                RunObject = Page "Purchase Credit Memo";
                RunPageLink = "Buy-from Vendor No." = field("No.");
                RunPageMode = Create;
                ToolTip = 'Create a purchase credit memo for the vendor.';
            }
            action("Letter of Attorney")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Letter of Attorney';
                Image = Documents;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = New;
                RunObject = Page "Purchase Credit Memo";
                RunPageLink = "Buy-from Vendor No." = field("No.");
                RunPageMode = Create;
                ToolTip = 'View the document that authorizes the involved individual or organization to act on the behalf of another to perform the process in question.';
            }
        }
        area(processing)
        {
            action("Payment Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Journal';
                Image = PaymentJournal;
                RunObject = Page "Payment Journal";
            }
            action("Purchase Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Journal';
                Image = Journals;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Purchase Journal";
            }
        }
        area(reporting)
        {
#if not CLEAN28
            action("Vendor - List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor - List';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Vendor - List";
                ToolTip = 'View various kinds of basic information for vendors, such as vendor posting group, discount and payment information, priority level and the vendor''s default currency, and the vendor''s current balance (in LCY). The report can be used, for example, to maintain the information in the Vendor table.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report is obsolete and will be removed in a future release.';
                ObsoleteTag = '28.0';
            }
#endif
            action("Vendor Register")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Register';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Vendor Register";
            }
            action("Vendor - Labels")
            {
                ApplicationArea = Suite;
                Caption = 'Vendor - Labels';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Vendor - Labels";
                ToolTip = 'View mailing labels with the vendors'' names and addresses.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Payment Journal_Promoted"; "Payment Journal")
                {
                }
                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Unposted Advance Statements_Promoted"; "Unposted Advance Statements")
                {
                }
                actionref("Vendor G/L Turnover_Promoted"; "Vendor G/L Turnover")
                {
                }
            }
        }
    }
}

