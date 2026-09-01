// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 10455 "PAC Web Services"
{
    ApplicationArea = Basic, Suite;
    Caption = 'PAC Web Services';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "PAC Web Service";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1020000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the unique code for the authorized service provider, PAC.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the name of the authorized service provider, PAC.';
                }
                field(Certificate; Rec.Certificate)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the certificate from the authorized service provider, PAC.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&PAC Web Service")
            {
                Caption = '&PAC Web Service';
                action("&Details")
                {
                    ApplicationArea = BasicMX;
                    Caption = '&Details';
                    Image = View;
                    RunObject = Page "PAC Web Service Details";
                    RunPageLink = "PAC Code" = field(Code);
                    ToolTip = 'View technical information about the web services that are used by an authorized service provider, PAC.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Details_Promoted"; "&Details")
                {
                }
            }
        }
    }
}

