// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
page 1308 "O365 Device Setup"
{
    ApplicationArea = All;
    Caption = 'Get the App';
    PageType = StandardDialog;
    SourceTable = "O365 Device Setup Instructions";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group("Get the app on your smartphone")
            {
                Caption = 'Get the app on your smartphone';
                group("1. INSTALL THE APP")
                {
                    Caption = '1. INSTALL THE APP';
                    InstructionalText = 'To install the app, point your smartphone browser to this URL or scan the QR code';
                    field(SetupURL; SetupURL)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Open in browser';
                        Editable = false;
                        ExtendedDatatype = URL;
                    }
                    field(QR; Rec."QR Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'or QR Code';
                        Editable = false;
                    }
                }
                group("2. IN APP")
                {
                    Caption = '2. IN APP';
                    InstructionalText = 'Enter your user name and password that you created during sign-up for Dynamics 365 Business Central and follow the instructions on the screen.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetupURL := SetupURLTxt;
    end;

    var
        SetupURL: Text[250];
        SetupURLTxt: Label 'aka.ms/BusinessCentralApp', Locked = true;
}

