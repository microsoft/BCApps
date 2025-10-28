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
    PageType = Card;
    Caption = 'Quality Edit Large Text';
    UsageCategory = None;
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    Extensible = true;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            group(SettingsForRawHtml)
            {
                ShowCaption = false;
                Caption = ' ';

                field(HtmlContent; ContentText)
                {
                    Caption = 'HTML';
                    ShowCaption = false;
                    ToolTip = 'Change the text.';
                    MultiLine = true;
                }
            }
        }
    }

    var
        ContentText: Text;

    procedure RunModalWith(var ExistingText: Text) ResultAction: Action
    begin
        ContentText := ExistingText;
        ResultAction := CurrPage.RunModal();
        if ResultAction in [ResultAction::OK, ResultAction::LookupOK, ResultAction::Yes] then
            ExistingText := ContentText;
    end;
}
