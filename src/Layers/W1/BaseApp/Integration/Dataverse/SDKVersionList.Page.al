// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using System.Utilities;

page 5332 "SDK Version List"
{
    Caption = 'SDK Version List';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = TempStack;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("SDK version"; Rec.StackOrder)
                {
                    ApplicationArea = Suite;
                    Caption = 'SDK Version';
                    ToolTip = 'Specifies the version of the Microsoft Dynamics 365 (CRM) software development kit that is used for the connection.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationManagement.InitializeProxyVersionList(Rec);
    end;
}

