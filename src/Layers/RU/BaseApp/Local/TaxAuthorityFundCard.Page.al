#pragma warning disable AA0247
page 12429 "Tax Authority/Fund Card"
{
    Caption = 'Tax Authority/Fund Card';
    PageType = Card;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = Vendor;
    SourceTableView = sorting("Vendor Type")
                      where("Vendor Type" = const("Tax Authority"));

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
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the VAT registration number.';
                }
                field("KPP Code"; Rec."KPP Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the company registration code associated with the vendor.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the related record.';
                }
                field("Name 2"; Rec."Name 2")
                {
                    ApplicationArea = Basic, Suite;
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
                    ToolTip = 'Specifies the postal code.';
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
                    ToolTip = 'Specifies the name of the contact person.';
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account''s current balance in LCY.';

                    trigger OnDrillDown()
                    var
                        VendLedgEntry: Record "Vendor Ledger Entry";
                        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                    begin
                        DtldVendLedgEntry.SetFilter("Vendor No.", Rec."No.");
                        Rec.CopyFilter("Global Dimension 1 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 1");
                        Rec.CopyFilter("Global Dimension 2 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 2");
                        Rec.CopyFilter("Currency Filter", DtldVendLedgEntry."Currency Code");
                        VendLedgEntry.DrillDownOnEntries(DtldVendLedgEntry);
                    end;
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
                    ToolTip = 'Specifies the contact email address at the tax authority.';
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the web site.';
                }
            }
            group(Settlement)
            {
                Caption = 'Settlement';
                field("Our Account No."; Rec."Our Account No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Control Tax Organ"; Rec."Control Tax Organ")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the control tax organization associated with the vendor.';
                }
                field("Tax Authority Code"; Rec."Tax Authority Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax authority code associated with the vendor.';
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Vendor Posting Group"; Rec."Vendor Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the vendor''s market type to link business transactions made for the vendor with the appropriate account in the general ledger.';
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
            group("Tax &Auth./Fund")
            {
                Caption = 'Tax &Auth./Fund';
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = LedgerEntries;
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
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(23),
                                  "No." = field("No.");
                    ShortCutKey = 'Shift+Ctrl+D';
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
                    ToolTip = 'View a list of alternate order addresses for the tax authority.';
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
                separator(Action1210062)
                {
                }
                action(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Vendor Statistics";
                    RunPageLink = "No." = field("No."),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
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
            }
        }
    }
}

