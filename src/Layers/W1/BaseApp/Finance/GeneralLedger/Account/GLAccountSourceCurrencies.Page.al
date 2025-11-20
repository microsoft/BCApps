// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;

page 589 "G/L Account Source Currencies"
{
    Caption = 'Source Currencies';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "G/L Account Source Currency";
    AboutTitle = 'About G/L entry source currencies';
    AboutText = 'General ledger entries contains Amount in LCY and Source Currency Amount in source currency of original operations.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the default dimension.';
                }
                field("Value Posting"; Rec."Source Curr. Balance at Date")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies how default dimensions and their values must be used.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(UpdateCurrencies)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Currencies';
                    Ellipsis = true;
                    Image = ApplyTemplate;
                    ToolTip = 'Update page with currencies used in general ledger entries posted to this account.';

                    trigger OnAction()
                    var
                        GLAccountSourceCurrency: Record "G/L Account Source Currency";
                    begin
                        GLAccountSourceCurrency.BuildCurrencyList();
                        CurrPage.Update();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Category6)
            {
                Caption = 'Source Currencies', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(UpdateCurrencies_Promoted; UpdateCurrencies)
                {
                }
            }
        }
    }
}
