#pragma warning disable AA0247
page 35605 "FA Movement Acts"
{
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Movements';
    CardPageID = "FA Movement Act";
    Editable = false;
    PageType = List;
    SourceTable = "FA Document Header";
    SourceTableView = sorting("Document Type", "No.")
                      where("Document Type" = const(Movement));
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
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Posting Description"; Rec."Posting Description")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("FA Posting Date"; Rec."FA Posting Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the posting date of the related fixed asset transaction, such as a depreciation.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
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
            group("&Act")
            {
                Caption = '&Act';
                action("Co&mments")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "FA Comments";
                    RunPageLink = "Document Type" = const(Movement),
                                  "Document No." = field("No."),
                                  "Document Line No." = const(0);
                }
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                    end;
                }
                action("Employee Si&gnatures")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Employee Si&gnatures';
                    Image = Signature;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    RunObject = Page "Document Signatures";
                    RunPageLink = "Table ID" = const(12470),
                                  "Document Type" = field("Document Type"),
                                  "Document No." = field("No.");
                }
            }
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = Post;
                    RunObject = Codeunit "FA Document-Post (Yes/No)";
                    ShortCutKey = 'F9';
                    ToolTip = 'Record the related transaction in your books.';
                }
                action(Preview)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Preview';
                    ToolTip = 'Preview the full content of the document.';

                    trigger OnAction()
                    var
                        FADocumentPostYesNo: Codeunit "FA Document-Post (Yes/No)";
                    begin
                        FADocumentPostYesNo.Preview(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("P&ost_Promoted"; "P&ost")
                {
                }
            }
        }
    }
}

