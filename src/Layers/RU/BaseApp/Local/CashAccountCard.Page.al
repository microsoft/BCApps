#pragma warning disable AA0247
page 12426 "Cash Account Card"
{
    Caption = 'Cash Account Card';
    PageType = Card;
    PopulateAllFields = true;
    SourceTable = "Bank Account";
    SourceTableView = where("Account Type" = const("Cash Account"));

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

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the related record.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional part of the address.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Code/Abbr./City';
                }
                field("Abbr. City"; Rec."Abbr. City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city abbreviation associated with the bank account.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the address.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number.';
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cashier';
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field(Control22; Rec.Balance)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                }
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account''s current balance in LCY.';
                }
                field("Min. Balance"; Rec."Min. Balance")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Our Contact Code"; Rec."Our Contact Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the record was last modified.';
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Phone No.2"; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the telephone number.';
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fax number.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the web site.';
                }
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code for the record.';
                }
                field("Debit Cash Order No. Series"; Rec."Debit Cash Order No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series of the debit cash order associated with the bank account.';
                }
                field("Credit Cash Order No. Series"; Rec."Credit Cash Order No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series of the credit cash order associated with the bank account.';
                }
                field("Last Cash Report Page No."; Rec."Last Cash Report Page No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the last case report page number associated with the bank account.';
                }
                field("Bank Acc. Posting Group"; Rec."Bank Acc. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies a code for the bank account posting group for the bank account.';
                }
                field("VAT % for Document"; Rec."VAT % for Document")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT percentage for VAT calculation in bank payment documents.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Cash Acc.")
            {
                Caption = '&Cash Acc.';
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Bank Account Statistics";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const("Bank Account"),
                                  "No." = field("No.");
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(270),
                                  "No." = field("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department.';
                }
                action(Balance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    Image = Balance;
                    RunObject = Page "Bank Account Balance";
                    RunPageLink = "No." = field("No."),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = BankAccountLedger;
                    RunObject = Page "Bank Account Ledger Entries";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Chec&k Ledger Entries")
                {
                    Caption = 'Chec&k Ledger Entries';
                    Image = CheckLedger;
                    RunObject = Page "Check Ledger Entries";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.");
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
            }
        }
        area(reporting)
        {
            action(List)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'List';
                Image = "Report";
                RunObject = Report "Bank Account - List";
                ToolTip = 'Open the list of cash accounts.';
            }
            action("Bank Account Register")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account Register';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Bank Account Register";
            }
            action("Detail Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Detail Trial Balance';
                Image = "Report";
                RunObject = Report "Bank Acc. - Detail Trial Bal.";
            }
            action("Receivables-Payables")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Receivables-Payables';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Receivables-Payables";
                ToolTip = 'View a summary of the receivables and payables for the account, including customer and vendor balance due amounts.';
            }
            action("Check Details")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Check Details';
                Image = "Report";
                RunObject = Report "Bank Account - Check Details";
            }
            action("Bank Account G/L Turnover")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account G/L Turnover';
                Image = "Report";
                RunObject = Report "Bank Account G/L Turnover";
            }
            action("Bank Account Card")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account Card';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Bank Account Card";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
                {
                }
                actionref("Chec&k Ledger Entries_Promoted"; "Chec&k Ledger Entries")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref(List_Promoted; List)
                {
                }
                actionref("Detail Trial Balance_Promoted"; "Detail Trial Balance")
                {
                }
                actionref("Check Details_Promoted"; "Check Details")
                {
                }
                actionref("Bank Account G/L Turnover_Promoted"; "Bank Account G/L Turnover")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Category 5';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ObjTransl: Record "Object Translation";
    begin
        ObjTransl.TranslateObject(
          ObjTransl."Object Type"::Report, Rec."Check Report ID");
    end;
}

