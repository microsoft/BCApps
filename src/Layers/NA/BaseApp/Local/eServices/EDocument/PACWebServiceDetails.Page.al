// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 10456 "PAC Web Service Details"
{
    Caption = 'PAC Web Service Details';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "PAC Web Service Detail";

    layout
    {
        area(content)
        {
            repeater(Control1020000)
            {
                ShowCaption = false;
                field(Environment; Rec.Environment)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies if the web service is for a test environment or a production environment.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies if the web service is for requesting digital stamps or for canceling signed invoices.';
                }
                field("Method Name"; Rec."Method Name")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the web method that will be used for this request type. Contact your authorized service provider, PAC, for this information.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the web method URL used for this type of request. Contact your authorized service provider, PAC, for this information.';
                }
            }
        }
    }

    actions
    {
    }
}

