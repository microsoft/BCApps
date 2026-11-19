// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7131 "Mileage Rate Setup API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Mileage Rate Setup';
    EntitySetCaption = 'Mileage Rate Setups';
    DelayedInsert = true;
    EntityName = 'mileageRateSetup';
    EntitySetName = 'mileageRateSetups';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Mileage Rate Setup";
    AboutText = 'Provides access to the data from the Mileage Rate Setup table';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(code; Rec."Code")
                {
                    Caption = 'Code';
                }
                field(vehicleType; Rec."Vehicle Type")
                {
                    Caption = 'Vehicle Type';
                }
                field(startingDate; Rec."Starting Date")
                {
                    Caption = 'Starting Date';
                }
                field(endingDate; Rec."Ending Date")
                {
                    Caption = 'Ending Date';
                }
                field(rate; Rec.Rate)
                {
                    Caption = 'Rate';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;
}
