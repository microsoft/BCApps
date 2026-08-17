#pragma warning disable AA0247
page 12477 "Posted FA Release Act Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DataCaptionFields = "Document No.";
    DelayedInsert = true;
    Editable = false;
    PageType = ListPart;
    PopulateAllFields = true;
    SaveValues = true;
    SourceTable = "Posted FA Doc. Line";

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
                field("FA Location Code"; Rec."FA Location Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the location, such as a building, where the fixed asset is located.';
                }
                field("FA Employee No."; Rec."FA Employee No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the employee number of the person who maintains possession of the fixed asset.';
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
                        PostedFADocHeader: Record "Posted FA Doc. Header";
                        PostedFADocLine: Record "Posted FA Doc. Line";
                        FAPostedReleaseActRep: Report "FA Posted Release Act FA-1";
                    begin
                        PostedFADocHeader.Get(Rec."Document Type", Rec."Document No.");
                        PostedFADocHeader.SetRecFilter();
                        PostedFADocLine := Rec;
                        PostedFADocLine.SetRecFilter();
                        FAPostedReleaseActRep.SetTableView(PostedFADocHeader);
                        FAPostedReleaseActRep.SetTableView(PostedFADocLine);
                        FAPostedReleaseActRep.Run();
                    end;
                }
            }
        }
    }
}

