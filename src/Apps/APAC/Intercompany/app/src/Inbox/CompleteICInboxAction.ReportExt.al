// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Inbox;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Purchases.Vendor;

reportextension 8557 "Complete IC Inbox Action APAC" extends "Complete IC Inbox Action"
{
    dataset
    {
        modify("IC Inbox Jnl. Line")
        {
            trigger OnBeforeAfterGetRecord()
            begin
                if ("IC Inbox Transaction"."Line Action" =
                    "IC Inbox Transaction"."Line Action"::Accept) and (AccNo <> '') then begin
                    if "IC Inbox Jnl. Line"."Account Type" = "IC Inbox Jnl. Line"."Account Type"::"G/L Account" then
                        if AccType = AccType::"G/L Account" then
                            "IC Inbox Jnl. Line"."Account Type" := "IC Inbox Jnl. Line"."Account Type"::"G/L Account";
                    if AccType = AccType::Vendor then
                        "IC Inbox Jnl. Line"."Account Type" := "IC Inbox Jnl. Line"."Account Type"::Vendor;
                    "IC Inbox Jnl. Line".Validate("Account No.", AccNo);
                    "IC Inbox Jnl. Line".Modify();
                end;
            end;
        }
    }

    requestpage
    {
        layout
        {
            addlast(Options)
            {
                group("BAS GST Settlement")
                {
                    Caption = 'BAS GST Settlement';
                    field(AccType; AccType)
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Settlement Account Type';
                        ToolTip = 'Specifies if the account is a general ledger account or a vendor account.';
                    }
                    field(AccNo; AccNo)
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Settlement Account No.';
                        ToolTip = 'Specifies the general ledger account number or vendor number, based on the type selected in the Settlement Account Type field.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
#pragma warning disable AA0139 // Preserve the existing APAC settlement account length.
                            case AccType of
                                AccType::"G/L Account":
                                    if Page.RunModal(0, GLAcc, GLAcc."No.") = Action::LookupOK then
                                        AccNo := GLAcc."No.";
                                AccType::Vendor:
                                    if Page.RunModal(0, Vendor, Vendor."No.") = Action::LookupOK then
                                        AccNo := Vendor."No.";
                            end;
#pragma warning restore AA0139
                        end;
                    }
                }
            }
        }
    }

    var
        GLAcc: Record "G/L Account";
        Vendor: Record Vendor;
        AccType: Option "G/L Account",Vendor;
        AccNo: Code[10];
}
