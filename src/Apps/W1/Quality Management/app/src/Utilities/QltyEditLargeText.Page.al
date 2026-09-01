// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

/// <summary>
/// A simple page meant to be run modal for use with editing large text.
/// </summary>
page 20441 "Qlty. Edit Large Text"
{
    PageType = StandardDialog;
    Caption = 'Edit Large Text';
    ApplicationArea = QualityManagement;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(RawHtml)
            {
                ShowCaption = false;
                Caption = ' ';

                field(HtmlContent; ContentText)
                {
                    Caption = 'HTML';
                    ShowCaption = false;
                    ToolTip = 'Specifies the text to be displayed.';
                    MultiLine = true;
                }
            }
        }
    }

    var
        ContentText: Text;

    internal procedure RunModalWith(var ExistingText: Text) ResultAction: Action
    begin
        ContentText := ExistingText;
        ResultAction := CurrPage.RunModal();
        if ResultAction in [ResultAction::OK, ResultAction::LookupOK, ResultAction::Yes] then
            ExistingText := ContentText;
    end;
}
