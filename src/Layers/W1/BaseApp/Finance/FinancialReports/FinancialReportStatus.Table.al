// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

table 8395 "Financial Report Status"
{
    Caption = 'Financial Report Status';
    DataClassification = CustomerContent;
    DrillDownPageId = "Financial Report Status";
    LookupPageId = "Financial Report Status";

    fields
    {
        field(1; Code; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the unique code of the status.';
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the status name.';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the status description.';
        }
        field(4; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies if the status is considered a blocked status. Financial reports with a blocked status are hidden from users without permission edit permission on Financial Report Status.';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}