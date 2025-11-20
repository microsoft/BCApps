// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using System.Environment.Configuration;
using System.Media;
using System.Utilities;

page 3731 "Product Video Topics"
{
    Caption = 'Setup Guide Topics';
    PageType = ListPart;
    SourceTableTemporary = true;
    SourceTable = Integer;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Name; TopicName)
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    var
                        Video: Codeunit Video;
                    begin
                        Video.Show("Video Category".FromInteger(Rec.Number));
                    end;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Show Assisted Setup")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Show Assisted Setup';
                Tooltip = 'Get assistance with set-up.';

                trigger OnAction()
                begin
                    Page.RunModal(Page::"Assisted Setup");
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        i: Integer;
    begin
        foreach i in "Video Category".Ordinals() do
            // skip showing uncategoried videos- as this page should focus on meaningful topics for new users 
            if Format("Video Category".FromInteger(i)) <> Format("Video Category"::Uncategorized) then begin
                Rec.Init();
                Rec.Number := i;
                Rec.Insert();
            end;
    end;

    trigger OnAfterGetRecord()
    var
        VideoCategory: Enum "Video Category";
    begin
        VideoCategory := "Video Category".FromInteger(Rec.Number);
        TopicName := Format(VideoCategory);
    end;

    var
        TopicName: Text;
}
