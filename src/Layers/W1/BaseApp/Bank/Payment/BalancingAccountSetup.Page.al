// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

/// <summary>
/// Page 980 "Balancing Account Setup" provides a dialog for setting up balance accounts for payment registration.
/// This page allows users to select and configure the default balance account used when registering customer payments.
/// </summary>
/// <remarks>
/// Source table: Payment Registration Setup. Used for configuring payment registration defaults
/// including balance account selection and automation preferences.
/// </remarks>
page 980 "Balancing Account Setup"
{
    Caption = 'Balancing Account Setup';
    DataCaptionExpression = PageCaptionVariable;
    PageType = StandardDialog;
    SourceTable = "Payment Registration Setup";

    layout
    {
        area(content)
        {
            group(Control4)
            {
                InstructionalText = 'Select the balance account that you want to register payments for.';
                ShowCaption = false;
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balancing Account';
                    ToolTip = 'Specifies the account number that is used as the balancing account for payments.';
                }
                field("Use this Account as Def."; Rec."Use this Account as Def.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Use this Account as Default';
                    ToolTip = 'Specifies if the Date Received and the Amount Received fields are automatically filled when you select the Payment Made check box.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Get(UserId);
        PageCaptionVariable := '';
    end;

    var
        PageCaptionVariable: Text[10];
}

