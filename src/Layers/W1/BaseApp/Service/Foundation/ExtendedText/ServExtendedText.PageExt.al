// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.ExtendedText;

pageextension 6468 "Serv. Extended Text" extends "Extended Text"
{
    layout
    {
        addafter(Purchases)
        {
            group(Service)
            {
                Caption = 'Service';
                field("Service Quote"; Rec."Service Quote")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the extended text for an item, account or other factor will be available on service lines in service orders.';
                }
                field("Service Order"; Rec."Service Order")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the extended text for an item, account or other factor will be available on service lines in service orders.';
                }
                field("Service Invoice"; Rec."Service Invoice")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the extended text for an item, account or other factor will be available on service lines in service orders.';
                }
                field("Service Credit Memo"; Rec."Service Credit Memo")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the extended text for an item, account or other factor will be available on service lines in service orders.';
                }
            }
        }
    }
}
