// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Registration;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

page 7403 "Registration No. Duplicates"
{
    Caption = 'Possible Registration No. Duplicates';
    PageType = List;
    SourceTable = "Registration No. Duplicate";
    Editable = false;
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            repeater(Duplicates)
            {
                field("Record Type"; Rec."Record Type")
                {
                    ToolTip = 'Specifies the type of record with a matching registration number.';
                }
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the number of the record with a matching registration number.';
                }
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the name of the organization.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(OpenCard)
            {
                Caption = 'Open Card';
                Image = EditLines;
                ToolTip = 'Open the card for the selected possible duplicate.';

                trigger OnAction()
                var
                    Customer: Record Customer;
                    Vendor: Record Vendor;
                    Contact: Record Contact;
                    CompanyInformation: Record "Company Information";
                begin
                    case Rec."Record ID".TableNo of
                        Database::Customer:
                            begin
                                Customer.Get(Rec."No.");
                                Page.Run(Page::"Customer Card", Customer);
                            end;
                        Database::Vendor:
                            begin
                                Vendor.Get(Rec."No.");
                                Page.Run(Page::"Vendor Card", Vendor);
                            end;
                        Database::Contact:
                            begin
                                Contact.Get(Rec."No.");
                                Page.Run(Page::"Contact Card", Contact);
                            end;
                        Database::"Company Information":
                            begin
                                CompanyInformation.Get();
                                Page.Run(Page::"Company Information", CompanyInformation);
                            end;
                    end;
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        RegistrationNoFeature: Codeunit "Registration No. Feature";
    begin
        RegistrationNoFeature.CheckEnabled();
    end;
}
