// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

page 246 "VAT Reg. No. Srv. Templates"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    SourceTable = "VAT Reg. No. Srv. Template";
    Caption = 'VAT Reg. No. Validation Templates';

    layout
    {
        area(Content)
        {
            repeater(TemplateList)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Validate Name"; Rec."Validate Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Validate Street"; Rec."Validate Street")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Validate City"; Rec."Validate City")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Validate Post Code"; Rec."Validate Post Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Ignore Details"; Rec."Ignore Details")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        VATRegNoSrvConfig.Get();
        Rec.CheckInitDefaultTemplate(VATRegNoSrvConfig);
    end;
}
