// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.CRM.Contact;
using Microsoft.Sales.Customer;

page 1627 "Office No Customer Dlg"
{
    Caption = 'Create customer record?';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = Contact;

    layout
    {
        area(content)
        {
            field("STRSUBSTNO(CustDialogLbl,Name)"; StrSubstNo(CustDialogLbl, Rec.Name))
            {
                ApplicationArea = All;
                ShowCaption = false;
            }
            group(Control2)
            {
                ShowCaption = false;
                field(CreateCust; StrSubstNo(CreateCustLbl, Rec.Name))
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies a new customer for the contact.';

                    trigger OnDrillDown()
                    begin
                        Rec.CreateCustomerFromTemplate(Rec.ChooseNewCustomerTemplate());
                        CurrPage.Close();
                    end;
                }
                field(ViewCustList; ViewCustListLbl)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies a list of customers that are available in your company.';

                    trigger OnDrillDown()
                    var
                        Customer: Record Customer;
                    begin
                        PAGE.Run(PAGE::"Customer List", Customer);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        CustDialogLbl: Label 'Cannot find an existing customer that matches the contact %1. Do you want to create a new customer based on this contact?', Comment = '%1 = Contact name';
        CreateCustLbl: Label 'Create a customer record for %1', Comment = '%1 = Contact name';
        ViewCustListLbl: Label 'View customer list';
}

