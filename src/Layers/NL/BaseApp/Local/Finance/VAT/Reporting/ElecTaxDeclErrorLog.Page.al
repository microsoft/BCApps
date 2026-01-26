// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 11415 "Elec. Tax Decl. Error Log"
{
    Caption = 'Elec. Tax Decl. Error Log';
    DataCaptionFields = "Declaration No.";
    Editable = false;
    PageType = List;
    SourceTable = "Elec. Tax Decl. Error Log";

    layout
    {
        area(content)
        {
            repeater(Control1000000)
            {
                ShowCaption = false;
                field("Error Class"; Rec."Error Class")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the error class of the error described in the response message from the tax authority.';
                }
                field("Error Description"; Rec."Error Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the error in the electronic declaration found by the tax authority.';

                    trigger OnDrillDown()
                    begin
                        Message(Rec."Error Description");
                    end;
                }
            }
        }
    }

    actions
    {
    }
}

