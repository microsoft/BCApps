// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

/// <summary>
/// Dialog page for viewing the full message text of a message event.
/// </summary>
page 6804 "Avl Full Message Dialog"
{
    ApplicationArea = All;
    Caption = 'Full Message';
    InherentEntitlements = X;
    InherentPermissions = X;
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            group(MessageGroup)
            {
                ShowCaption = false;

                field(FullMessageText; FullMessageText)
                {
                    ApplicationArea = All;
                    Caption = 'Message';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the full message text from Avalara.';
                }
            }
        }
    }

    procedure SetMessage(MessageText: Text)
    begin
        FullMessageText := MessageText;
    end;

    var
        FullMessageText: Text;
}
