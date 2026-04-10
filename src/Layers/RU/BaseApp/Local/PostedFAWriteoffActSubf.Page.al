#pragma warning disable AA0247
page 12473 "Posted FA Writeoff Act Subf"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DataCaptionFields = "Document No.";
    DelayedInsert = true;
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
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the quantity of the fixed asset movement or the write-off line.';
                    Visible = false;
                }
                field("Value %"; Rec."Value %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'This field is used internally.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the amount of the fixed asset document line transaction.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
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
            }
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action("FA Posted Write-off Act FA-4")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Posted Write-off Act FA-4';
                    ToolTip = 'View the full or partial write-off of fixed assets that are vehicles. After you post an FA Write-off Act, you can use this report to print the posted document.';

                    trigger OnAction()
                    var
                        PostedFADocHeader: Record "Posted FA Doc. Header";
                        PostedFADocLine: Record "Posted FA Doc. Line";
                        FAPostedWriteoffActRep: Report "FA Posted Writeoff Act FA-4";
                    begin
                        SetFilters(PostedFADocHeader, PostedFADocLine);
                        FAPostedWriteoffActRep.SetTableView(PostedFADocHeader);
                        FAPostedWriteoffActRep.SetTableView(PostedFADocLine);
                        FAPostedWriteoffActRep.Run();
                    end;
                }
                action("FA Posted Writeoff Act FA-4a")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Posted Writeoff Act FA-4a';
                    ToolTip = 'View the full or partial write-off of fixed assets that are vehicles. After you post an FA Write-off Act, you can use this report to print the posted document.';

                    trigger OnAction()
                    var
                        PostedFADocHeader: Record "Posted FA Doc. Header";
                        PostedFADocLine: Record "Posted FA Doc. Line";
                        FAPostedWriteoffActRep: Report "Posted FA Writeoff Act FA-4a";
                    begin
                        SetFilters(PostedFADocHeader, PostedFADocLine);
                        FAPostedWriteoffActRep.SetTableView(PostedFADocHeader);
                        FAPostedWriteoffActRep.SetTableView(PostedFADocLine);
                        FAPostedWriteoffActRep.Run();
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
}

