// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.CRM.Contact;
using Microsoft.Purchases.Vendor;

page 1628 "Office No Vendor Dlg"
{
    Caption = 'Create vendor record?';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = Contact;

    layout
    {
        area(content)
        {
            field("STRSUBSTNO(VendDialogLbl,Name)"; StrSubstNo(VendDialogLbl, Rec.Name))
            {
                ApplicationArea = All;
                ShowCaption = false;
            }
            group(Control2)
            {
                ShowCaption = false;
                field(CreateVend; StrSubstNo(CreateVendLbl, Rec.Name))
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies a new vendor for the contact.';

                    trigger OnDrillDown()
                    begin
                        Rec.CreateVendorFromTemplate('');
                        CurrPage.Close();
                    end;
                }
                field(ViewVendList; ViewVendListLbl)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies a list of vendors that are available in your company.';

                    trigger OnDrillDown()
                    var
                        Vendor: Record Vendor;
                    begin
                        Page.Run(Page::"Vendor List", Vendor);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        VendDialogLbl: Label 'Cannot find an existing vendor that matches the contact %1. Do you want to create a new vendor based on this contact?', Comment = '%1 = Contact name';
        CreateVendLbl: Label 'Create a vendor record for %1', Comment = '%1 = Contact name';
        ViewVendListLbl: Label 'View vendor list';
}

