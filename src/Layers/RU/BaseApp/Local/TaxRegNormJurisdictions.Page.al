#pragma warning disable AA0247
page 17246 "Tax Reg. Norm Jurisdictions"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tax Register Norm Jurisdictions';
    PageType = List;
    SourceTable = "Tax Register Norm Jurisdiction";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the norm jurisdiction code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the norm jurisdiction code.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Jurisdiction")
            {
                Caption = '&Jurisdiction';
                Image = ViewDetails;
                action(Groups)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Groups';
                    Image = Group;
                    RunObject = Page "Tax Register Norm Groups";
                    RunPageLink = "Norm Jurisdiction Code" = field(Code);
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Export Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Export Settings';
                    Ellipsis = true;
                    Image = ExportFile;
                    ToolTip = 'Export an XML file that contains information about the tax register norm jurisdiction.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(NormJurisdiction);
                    end;
                }
                action("&Import Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Import Settings';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Import an XML file that contains settings for norm jurisdictions.';

                    trigger OnAction()
                    begin
                        Rec.PromptImportSettings();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Groups_Promoted; Groups)
                {
                }
            }
        }
    }

    var
        NormJurisdiction: Record "Tax Register Norm Jurisdiction";
}

