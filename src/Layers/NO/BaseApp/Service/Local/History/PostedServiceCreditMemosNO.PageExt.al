// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;

pageextension 10617 "Posted Service Credit Memos NO" extends "Posted Service Credit Memos"
{
    actions
    {
        addafter("Co&mments")
        {
            separator(Action1080000)
            {
            }
            action("Create Electronic Credit Memo")
            {
                ApplicationArea = Service;
                Caption = 'Create Electronic Credit Memo';
                Image = CreateDocument;
                ToolTip = 'Create one or more XML documents that you can send to the customer. You can run the batch job for multiple credit memos or you can run it for an individual credit memo. The document number is used as the file name. The files are stored at the location that has been specified in the Sales & Receivables Setup window.';
                Visible = false;

                trigger OnAction()
                var
                    ServiceCrMemoHeader: Record "Service Cr.Memo Header";
                begin
                    ServiceCrMemoHeader := Rec;
                    ServiceCrMemoHeader.SetRecFilter();
                    REPORT.RunModal(REPORT::"Create Elec. Service Cr. Memos", true, false, ServiceCrMemoHeader);
                end;
            }
        }
    }
}