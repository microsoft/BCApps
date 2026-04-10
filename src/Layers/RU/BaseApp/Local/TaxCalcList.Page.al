#pragma warning disable AA0247
page 17310 "Tax Calc. List"
{
    Caption = 'Tax Calc. List';
    CardPageID = "Tax Calc. Setup Card";
    DelayedInsert = true;
    DeleteAllowed = false;
    PageType = List;
    SourceTable = "Tax Calc. Header";

    layout
    {
        area(content)
        {
            repeater(Control100)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax calculation header.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table ID associated with the tax calculation header.';
                    Visible = TableIDVisible;
                }
                field("Storing Method"; Rec."Storing Method")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the storing method associated with the tax calculation header.';
                    Visible = StoringMethodVisible;
                }
                field("Tax Diff. Code"; Rec."Tax Diff. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax differences code associated with the tax calculation header.';
                }
                field("G/L Corr. Analysis View Code"; Rec."G/L Corr. Analysis View Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger corresponding analysis view code.';
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
        area(processing)
        {
            action(Data)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Data';
                Image = AccountingPeriods;
                RunObject = Page "Tax Calc. Accumulation";
                RunPageLink = "Section Code" = field("Section Code"),
                              "No." = field("No.");
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Data_Promoted; Data)
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        StoringMethodVisible := true;
        TableIDVisible := true;
    end;

    trigger OnOpenPage()
    begin
        CurrPage.Editable := not CurrPage.LookupMode;
        TableIDVisible := CurrPage.Editable;
        StoringMethodVisible := CurrPage.Editable;
    end;

    var
        TableIDVisible: Boolean;
        StoringMethodVisible: Boolean;
}

