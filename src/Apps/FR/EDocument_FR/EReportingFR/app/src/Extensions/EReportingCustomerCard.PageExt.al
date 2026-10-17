// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Sales.Customer;

pageextension 10972 "E-Reporting Customer Card" extends "Customer Card"
{
    layout
    {
        addafter("SIREN No.")
        {
            field("FR SIRET No."; Rec."FR SIRET No.")
            {
                ApplicationArea = Basic, Suite;
            }

        }
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
                ToolTip = 'Fill blank French identifiers from agreeing existing values and show settings that require correction. Existing identifiers and electronic addresses are preserved.';
                Image = CheckRulesSyntax;

                trigger OnAction()
                var
                    FRIdentifierMigration: Codeunit "FR Identifier Migration";
                begin
                    CurrPage.SaveRecord();
                    FRIdentifierMigration.ShowCustomerReadiness(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
