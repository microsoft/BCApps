// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7082 "Expense Capabilities API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Capability';
    EntitySetCaption = 'Expense Capabilities';
    EntityName = 'expenseCapability';
    EntitySetName = 'expenseCapabilities';
    PageType = API;
    SourceTable = "Expense Capabilities Buffer";
    SourceTableTemporary = true;
    DataAccessIntent = ReadOnly;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ODataKeyFields = "Capability Name";
    AboutText = 'Expense feature capabilities supported by this BC environment.';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(capabilityName; Rec."Capability Name")
                {
                    Caption = 'Capability Name';
                }
                field(isEnabled; Rec."Is Enabled")
                {
                    Caption = 'Is Enabled';
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

    trigger OnOpenPage()
    var
        Provider: Codeunit "Expense Capabilities Provider";
    begin
        Provider.Populate(Rec);
    end;
}
