// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Finance.Registration;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Receivables;

pageextension 11704 "Customer Card CZL" extends "Customer Card"
{
    layout
    {
        modify("Registration Number")
        {
            trigger OnDrillDown()
            var
                RegistrationLogMgtCZL: Codeunit "Registration Log Mgt. CZL";
            begin
                CurrPage.SaveRecord();
                RegistrationLogMgtCZL.AssistEditCustomerRegNo(Rec);
                CurrPage.Update(false);
            end;
        }
        addafter("VAT Registration No.")
        {
            field("Tax Registration No. CZL"; Rec."Tax Registration No. CZL")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the secondary VAT registration number for the customer.';
                Importance = Additional;
            }
        }
        addlast(Invoicing)
        {
            field("Last Unrel. Check Date CZL"; Rec."Last Unreliab. Check Date CZL")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the date of the last check of unreliability.';
            }
            field("Unreliable Payer Status CZL"; Rec."Unreliable Payer Status CZL")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the Customer is VAT Unreliable Payer.';
            }
            field("Disable Unreliab. Check CZL"; Rec."Disable Unreliab. Check CZL")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies that the check of VAT Unreliable Payer is disabled.';
            }
        }
    }
    actions
    {
        addlast("&Customer")
        {
            action(UnreliabilityStatusCZL)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Unreliability Status';
                Image = CustomerRating;
                ToolTip = 'View the VAT payer unreliable entries.';

                trigger OnAction()
                begin
                    Rec.ShowUnreliableEntriesCZL();
                end;
            }
        }
        addlast("F&unctions")
        {
            action(UnreliableVATPaymentCheckCZL)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Unreliable VAT Payment Check';
                Image = ElectronicPayment;
                ToolTip = 'Checks unreliability of the VAT payer.';

                trigger OnAction()
                var
                    UnreliablePayerMgtCZL: Codeunit "Unreliable Payer Mgt. CZL";
                begin
                    if not UnreliablePayerMgtCZL.IsUnreliablePayerServiceEnabled() then
                        UnreliablePayerMgtCZL.CreateUnrelPayerServiceNotSetNotification();

                    Rec.ImportUnrPayerStatusCZL();
                end;
            }
        }
        addafter(BackgroundStatement)
        {
            action("Balance Reconciliation CZL")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance Reconciliation';
                Image = Balance;
                ToolTip = 'Open the report for customer''s balance reconciliation.';

                trigger OnAction()
                begin
                    RunReport(Report::"Cust.- Bal. Reconciliation CZL", Rec."No.");
                end;
            }
        }
        addlast(Category_Report)
        {
            actionref("Balance Reconciliation CZL_Promoted"; "Balance Reconciliation CZL")
            {
            }
        }
    }
}
