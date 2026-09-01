// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
page 1307 "O365 Getting Started Device"
{
    Caption = 'Getting Started';
    PageType = NavigatePage;
    SourceTable = "O365 Getting Started";

    layout
    {
        area(content)
        {
            group(Control4)
            {
                ShowCaption = false;
                Visible = FirstPageVisible;
                field(Image1; ImagPageDataMediaResources."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Image';
                    Editable = false;
                    ShowCaption = false;
                }
                group(Page1Group)
                {
                    Caption = 'Be productive on the go';
                    field(BodyText1; BodyText)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'BodyText1';
                        Editable = false;
                        MultiLine = true;
                        ShowCaption = false;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(GetStarted)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Go!';
                Image = Start;
                InFooterBar = true;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        Rec.SetRange("User ID", UserId);
    end;

    trigger OnOpenPage()
    begin
        CurrentPageID := 1;
        FirstPageVisible := true;

        LoadRecords();

        if not Rec.AlreadyShown() then begin
            Rec.MarkAsShown();
            Rec."Tour Completed" := true;
            Rec.Modify();
        end;
    end;

    var
        ImageO365GettingStartedPageData: Record "O365 Getting Started Page Data";
        ImagPageDataMediaResources: Record "Media Resources";
        FirstPageVisible: Boolean;
        BodyText: Text;
        CurrentPageID: Integer;
        GetDevice1Txt: Label 'Welcome! Work with business data right here on your device.', Comment = '%1=PRODUCTNAME.MARKETING';

    local procedure LoadRecords()
    begin
        ImageO365GettingStartedPageData.GetPageImage(ImageO365GettingStartedPageData, CurrentPageID, PAGE::"O365 Getting Started Device");
        if ImagPageDataMediaResources.Get(ImageO365GettingStartedPageData."Media Resources Ref") then;

        BodyText := StrSubstNo(GetDevice1Txt, PRODUCTNAME.Marketing());
    end;
}
