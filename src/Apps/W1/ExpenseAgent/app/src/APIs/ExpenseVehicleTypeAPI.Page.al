// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7107 "Expense Vehicle Type API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Vehicle Type';
    EntitySetCaption = 'Expense Vehicle Types';
    DelayedInsert = true;
    EntityName = 'expenseVehicleType';
    EntitySetName = 'expenseVehicleTypes';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Vehicle Type";
    AboutText = 'Provides access to the data from the Expense Vehicle Type table';

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
                field(description; Rec.Description)
                {
                    Caption = 'Description';
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
