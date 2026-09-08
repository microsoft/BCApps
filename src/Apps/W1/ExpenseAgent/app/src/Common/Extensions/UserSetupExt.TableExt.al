// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Location;
using System.Security.User;

tableextension 6903 "User Setup Ext" extends "User Setup"
{
    fields
    {
#if not CLEAN30
        field(6900; "Unlimited Expense Approval"; Boolean)
        {
            Caption = 'Unlimited Expense Approval';
            DataClassification = CustomerContent;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the approval settings on Expense User.';
            ObsoleteTag = '30.0';
        }
        field(6901; "Expense Amount Approval Limit"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Expense Amount Approval Limit';
            DataClassification = CustomerContent;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the Approval Limit field on Expense User.';
            ObsoleteTag = '30.0';
        }
        field(6902; "Interim Approver ID"; Code[50])
        {
            Caption = 'Interim Approver ID';
            TableRelation = "User Setup";
            DataClassification = EndUserIdentifiableInformation;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the interim approver settings on Expense Report.';
            ObsoleteTag = '30.0';
        }
#endif
        field(6903; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee."No.";
            DataClassification = CustomerContent;
        }
        field(6904; "Expenses Resp. Ctr. Filter"; Code[10])
        {
            Caption = 'Expenses Responsibility Center Filter';
            TableRelation = "Responsibility Center".Code;
            DataClassification = CustomerContent;
        }
    }
}