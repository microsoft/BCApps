// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;

pageextension 10977 "E-Reporting E-Doc. Service" extends "E-Document Service"
{
    layout
    {
        addlast(ExportProcessing)
        {
            group(FrenchLifecycle)
            {
                Caption = 'French Invoice Lifecycle';
                Visible = (Rec."Document Format" = Rec."Document Format"::"Peppol BIS 3.0 FR") or (Rec."Document Format" = Rec."Document Format"::"Factur-X FR");

                field("FR Sender Platform ID"; Rec."FR Sender Platform ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("FR Sender Platform Scheme"; Rec."FR Sender Platform Scheme")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("FR Sender Platform Name"; Rec."FR Sender Platform Name")
                {
                    ApplicationArea = Basic, Suite;
                }

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
                ToolTip = 'Fill blank identifiers for French customers and vendors from agreeing existing values, then check company identifiers and routing for this service. Conflicting values are preserved and reported.';
                Image = CheckRulesSyntax;
                Visible = (Rec."Document Format" = Rec."Document Format"::"Peppol BIS 3.0 FR") or (Rec."Document Format" = Rec."Document Format"::"Factur-X FR");

                trigger OnAction()
                var
                    FRIdentifierMigration: Codeunit "FR Identifier Migration";
                begin
                    CurrPage.SaveRecord();
                    FRIdentifierMigration.ShowCompanyReadiness(Rec.Code);
                end;
            }
        }
    }
}