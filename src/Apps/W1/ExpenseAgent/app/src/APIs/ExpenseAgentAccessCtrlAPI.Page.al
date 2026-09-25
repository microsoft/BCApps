// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6984 "Expense Agent Access Ctrl API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Agent Access Control';
    EntitySetCaption = 'Expense Agent Access Controls';
    EntityName = 'expenseAgentAccessControl';
    EntitySetName = 'expenseAgentAccessControls';
    PageType = API;
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Agent Access Control";
    AboutText = 'Provides read-only access to the Expense Agent Access Control configuration';

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
                field(setupSystemId; Rec."Setup System ID")
                {
                    Caption = 'Setup System ID';
                }
                field(authenticationEmail; Rec."Authentication Email")
                {
                    Caption = 'Authentication Email';
                }
                field(canConfigureAgent; Rec."Can Configure Agent")
                {
                    Caption = 'Can Configure Agent';
                }
                field(canWorkOnBehalf; Rec."Can Work on Behalf")
                {
                    Caption = 'Can Work on Behalf';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.ReadIsolation(IsolationLevel::ReadCommitted);
    end;

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess(true);
    end;
}
