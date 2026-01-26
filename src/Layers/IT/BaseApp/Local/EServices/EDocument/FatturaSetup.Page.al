// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

page 12204 "Fattura Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Fattura Setup';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Fattura Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Self-Billing VAT Bus. Group"; Rec."Self-Billing VAT Bus. Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT business posting group that is used for VAT entries related to self-billing documents.';
                }
                field("Company PA Code"; Rec."Company PA Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code to be reported in the CodiceDestinetario XML node for self-billing documents.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

