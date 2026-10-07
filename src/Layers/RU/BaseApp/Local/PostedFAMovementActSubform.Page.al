#pragma warning disable AA0247
page 12481 "Posted FA Movement Act Subform"
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
                field(Status; Rec.Status)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the status of the fixed asset.';
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
                field(Canceled; Rec.Canceled)
                {
                    ApplicationArea = FixedAssets;
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

                    trigger OnAction()
                    begin
                        Rec.ShowComments();
                    end;
                }
            }
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action("FA Posted Movement FA-2")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Posted Movement FA-2';

                    trigger OnAction()
                    var
                        PostedFADocHeader: Record "Posted FA Doc. Header";
                        PostedFADocLine: Record "Posted FA Doc. Line";
                        FAPostedMovementActRep: Report "FA Posted Movement FA-2";
                    begin
                        SetFilters(PostedFADocHeader, PostedFADocLine);
                        FAPostedMovementActRep.SetTableView(PostedFADocHeader);
                        FAPostedMovementActRep.SetTableView(PostedFADocLine);
                        FAPostedMovementActRep.Run();
                    end;
                }
                action("FA Posted Movement FA-3")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Posted Movement FA-3';

                    trigger OnAction()
                    var
                        PostedFADocHeader: Record "Posted FA Doc. Header";
                        PostedFADocLine: Record "Posted FA Doc. Line";
                        FAPostedMovementActRep: Report "FA Posted Movement FA-3";
                    begin
                        SetFilters(PostedFADocHeader, PostedFADocLine);
                        FAPostedMovementActRep.SetTableView(PostedFADocHeader);
                        FAPostedMovementActRep.SetTableView(PostedFADocLine);
                        FAPostedMovementActRep.Run();
                    end;
                }
                action("Posted FA Movement FA-15")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Posted FA Movement FA-15';
                    ToolTip = 'Open the list of posted fixed asset movements.';

                    trigger OnAction()
                    var
                        PostedFADocHeader: Record "Posted FA Doc. Header";
                        PostedFADocLine: Record "Posted FA Doc. Line";
                        FAPostedMovementActRep: Report "Posted FA Movement FA-15";
                    begin
                        SetFilters(PostedFADocHeader, PostedFADocLine);
                        FAPostedMovementActRep.SetTableView(PostedFADocHeader);
                        FAPostedMovementActRep.SetTableView(PostedFADocLine);
                        FAPostedMovementActRep.Run();
                    end;
                }
            }
        }
    }

    local procedure SetFilters(var PostedFADocHeader: Record "Posted FA Doc. Header"; var PostedFADocLine: Record "Posted FA Doc. Line")
    begin
        PostedFADocHeader.Get(Rec."Document Type", Rec."Document No.");
        PostedFADocHeader.SetRecFilter();
        PostedFADocLine := Rec;
        PostedFADocLine.SetRecFilter();
    end;

    [Scope('OnPrem')]
    procedure CancelMovement()
    var
        PstdFADocLine: Record "Posted FA Doc. Line";
    begin
        CurrPage.SetSelectionFilter(PstdFADocLine);
        Rec.CancelFALocationMovement(PstdFADocLine);
    end;
}

