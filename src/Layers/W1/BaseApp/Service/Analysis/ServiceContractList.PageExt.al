// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Analysis;

using Microsoft.Service.Contract;

pageextension 5900 ServiceContractList extends "Service Contract List"
{
    actions
    {
        addfirst(Reporting)
        {
            action(ServicesAnalysis)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Analyze Services';
                Image = ServiceAgreement;
                RunObject = Query "Service Analysis";
                ToolTip = 'Analyze (group, summarize, pivot) your Service Ledger Entries with related Service master data such as Service Contract, Customer, Item, G/L Account, and Job.';
            }
        }

        addfirst(Category_Report)
        {
            actionref(ServicesAnalysis_Promoted; ServicesAnalysis)
            {
            }
        }
    }
}