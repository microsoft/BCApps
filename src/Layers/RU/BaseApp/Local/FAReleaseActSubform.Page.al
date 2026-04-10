#pragma warning disable AA0247
page 12475 "FA Release Act Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "FA Document Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("FA No."; Rec."FA No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the related fixed asset. ';
                }
                field("New FA No."; Rec."New FA No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a new fixed assets number.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a description of the fixed asset.';
                }
                field("Depreciation Book Code"; Rec."Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code for the depreciation book to which the line will be posted if you have selected Fixed Asset in the Type field for this line.';
                }
                field("New Depreciation Book Code"; Rec."New Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies an alternative depreciation book code that is used to post depreciation for the fixed asset entry.';
                }
                field("FA Location Code"; Rec."FA Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the location, such as a building, where the fixed asset is located.';
                    Visible = FALocationCodeVisible;
                }
                field("FA Employee No."; Rec."FA Employee No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the employee number of the person who maintains possession of the fixed asset.';
                    Visible = FAEmployeeNoVisible;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the quantity of the fixed asset movement or write-off line.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action(Comments)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Comments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';

                    trigger OnAction()
                    begin
                        Rec.ShowComments();
                    end;
                }
                action("&Print")
                {
                    ApplicationArea = FixedAssets;
                    Caption = '&Print';
                    Image = Print;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        FADocHeader: Record "FA Document Header";
                        FADocLine: Record "FA Document Line";
                        FAReleaseActRep: Report "FA Release Act FA-1";
                    begin
                        FADocHeader.Get(Rec."Document Type", Rec."Document No.");
                        FADocHeader.SetRecFilter();
                        FADocLine := Rec;
                        FADocLine.SetRecFilter();
                        FAReleaseActRep.SetTableView(FADocHeader);
                        FAReleaseActRep.SetTableView(FADocLine);
                        FAReleaseActRep.Run();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FALocationCodeVisible := FASetup."FA Location Mandatory";
        FAEmployeeNoVisible := FASetup."Employee No. Mandatory";
    end;

    var
        FALocationCodeVisible: Boolean;
        FAEmployeeNoVisible: Boolean;

    [Scope('OnPrem')]
    procedure UpdateForm(SetSaveRecord: Boolean)
    begin
        CurrPage.Update(SetSaveRecord);
    end;
}

