// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;

query 2 "Customer Interaction Stats."
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    AboutTitle = 'Customer Interaction Statistics';
    AboutText = 'This query returns statistics about customer interactions';

    elements
    {
        dataitem(Customer; Customer)
        {
            column(CustomerNo; "No.")
            {
                Caption = 'Customer No.';
            }
            dataitem(ContactBusRelation; "Contact Business Relation")
            {
                DataItemLink = "No." = Customer."No.";
                DataItemTableFilter = "Link To Table" = const(Customer);
                dataitem(Contact; Contact)
                {
                    DataItemLink = "No." = ContactBusRelation."Contact No.";
                    dataitem(Contacts; Contact)
                    {
                        DataItemLink = "Company No." = Contact."Company No.";
                        SqlJoinType = LeftOuterJoin;
                        dataitem(InteractionLogEntry; "Interaction Log Entry")
                        {
                            DataItemLink = "Contact No." = Contacts."No.";

                            filter(InteractionDate; "Date")
                            {
                            }
                            column(MaxEntryNo; "Entry No.")
                            {
                                method = Max;
                                Caption = 'Last Entry No.';
                            }
                            dataitem(InteractionGroup; "Interaction Group")
                            {
                                DataItemLink = Code = InteractionLogEntry."Interaction Group Code";
                                SqlJoinType = LeftOuterJoin;

                                column(GroupCode; Code)
                                {
                                    Caption = 'Interaction Group Code';
                                }
                                column(Description; Description)
                                {
                                    Caption = 'Interaction Group Description';
                                }
                                column(InteractionCount)
                                {
                                    method = Count;
                                    Caption = 'Count of Interactions';
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}