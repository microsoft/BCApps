// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Setup;

/// <summary>
/// Administration page for managing payment service providers and their configuration.
/// Provides interface for enabling, configuring, and setting up online payment services.
/// </summary>
/// <remarks>
/// Source Table: Payment Service Setup (1060) - Temporary. Displays available payment services like PayPal, Microsoft Pay, WorldPay.
/// Supports creation of new payment service configurations and management of existing ones.
/// </remarks>
page 1060 "Payment Services"
{
    AdditionalSearchTerms = 'paypal,microsoft pay payments,worldpay,online payment';
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Services';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Payment Service Setup";
    SourceTableTemporary = true;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the payment service.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the payment service.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the payment service is enabled.';
                }
                field("Always Include on Documents"; Rec."Always Include on Documents")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the payment service is always available in the Payment Service field on outgoing sales documents.';
                }
                field("Terms of Service"; Rec."Terms of Service")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a link to the Terms of Service page for the payment service.';

                    trigger OnDrillDown()
                    begin
                        Rec.TermsOfServiceDrillDown();
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(NewAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New';
                Image = NewDocument;
                ToolTip = 'Add a payment service (such as PayPal) on the application that lets customers make online payments for sales orders and invoices.';

                trigger OnAction()
                begin
                    if Rec.NewPaymentService() then begin
                        Rec.Reset();
                        Rec.DeleteAll();
                        Rec.OnRegisterPaymentServices(Rec);
                    end;
                end;
            }
            action(Setup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Setup';
                Enabled = SetupEditable;
                Image = Setup;
                ToolTip = 'Change the payment service setup.';

                trigger OnAction()
                begin
                    Rec.OpenSetupCard();
                    Rec.Reset();
                    Rec.DeleteAll();
                    Rec.OnRegisterPaymentServices(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

                actionref(NewAction_Promoted; NewAction)
                {
                }
            }
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Setup_Promoted; Setup)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateSetupEditable();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update();
    end;

    trigger OnOpenPage()
    var
        TempPaymentServiceSetupProviders: Record "Payment Service Setup" temporary;
    begin
        Rec.OnRegisterPaymentServices(Rec);
        Rec.OnRegisterPaymentServiceProviders(TempPaymentServiceSetupProviders);
        if TempPaymentServiceSetupProviders.IsEmpty() then
            Error(NoServicesInstalledErr);
    end;

    var
        NoServicesInstalledErr: Label 'No payment service extension has been installed.';
        SetupEditable: Boolean;

    /// <summary>
    /// Updates the setup editable flag based on whether payment services are available.
    /// Controls the enabled state of setup-related actions and fields.
    /// </summary>
    local procedure UpdateSetupEditable()
    begin
        SetupEditable := not Rec.IsEmpty();
    end;
}

