// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

table 4593 "SOA KPI"
{
    DataClassification = CustomerContent;
    Access = Internal;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Caption = 'Sales Order Agent';
#if not CLEAN29
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by table SOA KPI Summary for multi-agent KPI tracking.';
    ObsoleteTag = '29.0';
#else
    ObsoleteState = Removed;
    ObsoleteReason = 'Replaced by table SOA KPI Summary for multi-agent KPI tracking.';
    ObsoleteTag = '29.0';
#endif

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Received Emails"; Integer)
        {
            Caption = 'Received emails';
            ToolTip = 'Specifies the total number of emails that the agent has received.';
        }
        field(3; "Total Emails"; Integer)
        {
            Caption = 'Total emails';
            ToolTip = 'Specifies the total number of emails that the agent has received or created.';
        }
        field(4; "Total Quotes Created"; Integer)
        {
            Caption = 'Quotes created';
            ToolTip = 'Specifies the total number of quotes that the agent has created. Both active and inactive quotes are included.';
        }
        field(5; "Total Orders Created"; Integer)
        {
            Caption = 'Orders created';
            ToolTip = 'Specifies the total number of orders that the agent has created. Both active and inactive orders are included.';
        }
        field(6; "Total Amount Orders"; Decimal)
        {
            Caption = 'Amount inc. Tax of orders';
            ToolTip = 'Specifies the total amount including tax of all orders that the agent has created. Both active and inactive orders are included.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(20; "Last Updated DateTime"; DateTime)
        {
            Caption = 'Updated at';
            ToolTip = 'Specifies the date and time when the KPI was last updated.';
        }
        field(5000; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            ToolTip = 'Specifies the security identifier (SID) of the agent for whom the KPIs are tracked.';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }
}
