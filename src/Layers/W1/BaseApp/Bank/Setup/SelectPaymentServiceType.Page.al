// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Setup;

/// <summary>
/// Dialog page for selecting payment service provider types during setup.
/// Provides read-only list of available payment service providers for configuration.
/// </summary>
/// <remarks>
/// Source Table: Payment Service Setup (1060) - Temporary. Used during payment service creation workflow.
/// Displays registered payment service providers for user selection during setup process.
/// </remarks>
page 1062 "Select Payment Service Type"
{
    Caption = 'Select Payment Service Type';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Payment Service Setup";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control4)
            {
                Editable = false;
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the payment service type.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the payment service.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.OnRegisterPaymentServiceProviders(Rec);
    end;
}

