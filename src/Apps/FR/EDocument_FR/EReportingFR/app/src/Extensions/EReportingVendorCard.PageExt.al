// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Purchases.Vendor;

pageextension 10973 "E-Reporting Vendor Card" extends "Vendor Card"
{
    layout
    {
        addafter("VAT Registration No.")
        {
            field("FR E-Reporting Trans. Type"; Rec."FR E-Reporting Trans. Type")
            {
                ApplicationArea = Basic, Suite;
            }
            field("FR Electronic Address"; Rec."FR Electronic Address")
            {
                ApplicationArea = Basic, Suite;
            }
            field("FR Elec. Address Scheme"; Rec."FR Elec. Address Scheme")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action(PrepareFrenchIdentifiers)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Prepare French Identifiers';
                ToolTip = 'Fill a blank SIREN from agreeing existing French identifiers and show settings that require correction. The registration number and electronic address are preserved.';
                Image = CheckRulesSyntax;

                trigger OnAction()
                var
                    FRIdentifierMigration: Codeunit "FR Identifier Migration";
                begin
                    CurrPage.SaveRecord();
                    FRIdentifierMigration.ShowVendorReadiness(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
