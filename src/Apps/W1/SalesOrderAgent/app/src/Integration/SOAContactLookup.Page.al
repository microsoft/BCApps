// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.CRM.Contact;

page 4412 "SOA Contact Lookup"
{
    ApplicationArea = All;
    Caption = 'Select contact';
    DeleteAllowed = false;
    Editable = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;
    InsertAllowed = false;
    PageType = List;
    SourceTable = Contact;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Contacts)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the contact.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the contact.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company that the contact works for.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the primary email address of the contact.';
                }
                field("E-Mail 2"; Rec."E-Mail 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the alternate email address of the contact.';
                }
            }
        }
    }

    internal procedure SetEmailFilter(EmailAddress: Text)
    var
        SOAFiltersImpl: Codeunit "SOA Filters Impl.";
        EmailFilter: Text;
    begin
        EmailFilter := SOAFiltersImpl.GetSafeFromEmailFilter(EmailAddress);
        Rec.FilterGroup(-1);
        Rec.SetFilter("E-Mail", EmailFilter);
        Rec.SetFilter("E-Mail 2", EmailFilter);
        Rec.FilterGroup(0);
    end;
}