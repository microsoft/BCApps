#pragma warning disable AA0247
page 12414 "VAT Purchase Ledger Subform"
{
    Caption = 'VAT Purchase Ledger';
    InsertAllowed = false;
    PageType = ListPart;
    Permissions = TableData "VAT Ledger Line" = rm;
    SourceTable = "VAT Ledger Line";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the line.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Real. VAT Entry Date"; Rec."Real. VAT Entry Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry date of the realized VAT associated with this VAT ledger line.';
                }
                field("Payment Date"; Rec."Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment date associated with this VAT ledger line.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("C/V No."; Rec."C/V No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer or vendor number associated with this VAT ledger line.';
                }
                field("C/V Name"; Rec."C/V Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer or vendor name associated with this VAT ledger line.';
                }
                field("C/V VAT Reg. No."; Rec."C/V VAT Reg. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer or vendor VAT registration number associated with this VAT ledger line.';
                }
                field("Reg. Reason Code"; Rec."Reg. Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the regular reason code associated with this VAT ledger line.';
                }
                field("C/V Posting Group"; Rec."C/V Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer or vendor posting group associated with this VAT ledger line. VAT ledgers are used to store details about VAT in transactions that involve goods and services in Russia or goods imported into Russia.';
                }
                field("VAT Product Posting Group"; Rec."VAT Product Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT product posting group associated with this VAT ledger line.';
                }
                field("VAT Business Posting Group"; Rec."VAT Business Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount, including VAT, of this VAT ledger line.';
                }
                field(Base20; Rec.Base20)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base VAT amount for a 20 percent VAT rate.';
                }
                field(Amount20; Rec.Amount20)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax amount for a 20 percent VAT rate.';
                }
                field(Base18; Rec.Base18)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base VAT amount for an 18 percent VAT rate.';
                }
                field(Amount18; Rec.Amount18)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax amount for an 18 percent VAT rate.';
                }
                field(Base10; Rec.Base10)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base VAT amount for a 10 percent VAT rate.';
                }
                field(Amount10; Rec.Amount10)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax amount for a 10 percent VAT rate.';
                }
                field(Base0; Rec.Base0)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base VAT amount for a zero percent VAT rate.';
                }
                field("Base VAT Exempt"; Rec."Base VAT Exempt")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base VAT exempt amount of this VAT ledger line.';
                }
                field("Receipt Date"; Rec."Receipt Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the receipt date of this VAT ledger line.';
                }
                field("CD No."; Rec."CD No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customs declaration number.';
                }
                field("Country/Region of Origin Code"; Rec."Country/Region of Origin Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the country/region where the item was produced or processed.';
                }
                field(Prepayment; Rec.Prepayment)
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies if the related payment is a prepayment.';
                }
                field("Amt. Diff. VAT"; Rec."Amt. Diff. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this VAT ledger line has an amount difference.';
                }
                field("No. of Sales Ledger Lines"; Rec."No. of Sales Ledger Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of sales ledger lines that are associated with the VAT ledger.';
                }
                field("No. of VAT Purch. Entries"; Rec."No. of VAT Purch. Entries")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of VAT purchase entries of this VAT ledger line.';
                }
                field("Additional Sheet"; Rec."Additional Sheet")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this VAT ledger line has an additional sheet.';
                }
                field("Corr. VAT Entry Posting Date"; Rec."Corr. VAT Entry Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the corrected VAT entry.';
                }
                field("VAT Entry Type"; Rec."VAT Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT entry code according to Russian legislation. Some types of documents, such as corrective or revision invoices, must have multiple VAT entry type codes.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field("Tariff No."; Rec."Tariff No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item tariff number that is associated with this VAT ledger line.';
                }
            }
        }
    }

    actions
    {
    }

    var
        Navigate: Page Navigate;

    [Scope('OnPrem')]
    procedure NavigateDocument()
    begin
        Navigate.SetDoc(Rec."Document Date", Rec."Origin. Document No.");
        Navigate.Run();
    end;
}

