// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using System.Environment;
using System.Environment.Configuration;

page 1158 "Cash Account Balances"
{
    Caption = 'Cash Account Balances';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "G/L Account";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the cash account.';
                }
                field(Balance; Rec.Balance)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the balance of the cash account.';

                    trigger OnDrillDown()
                    var
                        Company: Record Company;
                        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
                        HyperLinkUrl: Text[500];
                    begin
                        Company.Get(CompanyName);
                        if Company."Evaluation Company" then
                            HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 20) +
                              '&' + ConfPersonalizationMgt.GetProfileUrlParameterForEvaluationCompany() +
                              StrSubstNo(FilterForBalanceDrillDwnTxt, Rec."No.")

                        else
                            HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 20) + StrSubstNo(FilterForBalanceDrillDwnTxt, Rec."No.");
                        HyperLink(HyperLinkUrl);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange("Account Category", Rec."Account Category"::Assets);
        Rec.SetRange("Account Type", Rec."Account Type"::Posting);
        Rec.SetRange("Account Subcategory Entry No.", 3);
    end;

    var
        FilterForBalanceDrillDwnTxt: Label '&filter=''G/L Entry''.''G/L Account No.'' IS ''%1''', Comment = '%1 - G/L Account record No. which data type of CODE.';
}

