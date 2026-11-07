#pragma warning disable AA0247
page 35630 "Bank Accounts"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Accounts';
    CardPageID = "Bank Account Card";
    Editable = false;
    PageType = List;
    SourceTable = "Bank Account";
    SourceTableView = where("Account Type" = const("Bank Account"));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
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
                field("Post Code"; Rec."Post Code")
                {
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ToolTip = 'Specifies the country/region of the address.';
                    Visible = false;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number.';
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ToolTip = 'Specifies the fax number.';
                    Visible = false;
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                    Visible = false;
                }
                field("SWIFT Code"; Rec."SWIFT Code")
                {
                    Visible = false;
                }
                field(IBAN; Rec.IBAN)
                {
                    Visible = false;
                }
                field("Our Contact Code"; Rec."Our Contact Code")
                {
                    Visible = false;
                }
                field("Bank Acc. Posting Group"; Rec."Bank Acc. Posting Group")
                {
                    ToolTip = 'Specifies a code for the bank account posting group for the bank account.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ToolTip = 'Specifies the currency code for the record.';
                    Visible = false;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                    Visible = false;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1905532107; "Dimensions FactBox")
            {
                SubPageLink = "Table ID" = const(270),
                              "No." = field("No.");
                Visible = false;
            }
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
            group("&Bank Acc.")
            {
                Caption = '&Bank Acc.';
                Image = Bank;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';

                    trigger OnAction()
                    var
                        BankAcc: Record "Bank Account";
                    begin
                        BankAcc.Copy(Rec);
                        if Rec."Account Type" = Rec."Account Type"::"Bank Account" then
                            PAGE.Run(PAGE::"Bank Account Card", BankAcc)
                        else
                            PAGE.Run(PAGE::"Cash Account Card", BankAcc);
                    end;
                }
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
                        RunPageLink = "Table ID" = const(270),
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
                            BankAcc: Record "Bank Account";
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(BankAcc);
                            DefaultDimMultiple.SetMultiRecord(BankAcc, Rec.FieldNo("No."));
                            DefaultDimMultiple.RunModal();
                        end;
                    }
                }
                action(Balance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    Image = Balance;
                    RunObject = Page "Bank Account Balance";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                }
                action("St&atements")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'St&atements';
                    Image = BankAccountStatement;
                    RunObject = Page "Bank Account Statement List";
                    RunPageLink = "Bank Account No." = field("No.");
                    ToolTip = 'View posted bank statements and reconciliations.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = BankAccountLedger;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
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
            action("Detail Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Detail Trial Balance';
                Image = "Report";
                RunObject = Report "Bank Acc. - Detail Trial Bal.";
            }
            action("Check Details")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Check Details';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Bank Account - Check Details";
            }
            action("Trial Balance by Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Trial Balance by Period';
                Image = "Report";
                RunObject = Report "Trial Balance by Period";
                ToolTip = 'View a detailed trial balance for selected checks within a selected period.';
            }
#if not CLEAN28
            action("Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Trial Balance';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Trial Balance";
                ToolTip = 'View a detailed trial balance for the selected bank account.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report is obsolete and will be removed in a future release.';
                ObsoleteTag = '28.0';
            }
#endif
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref(Balance_Promoted; Balance)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Detail Trial Balance_Promoted"; "Detail Trial Balance")
                {
                }
                actionref("Trial Balance by Period_Promoted"; "Trial Balance by Period")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Check Report Name");
    end;
}

