// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Assembly.Posting;
using Microsoft.Foundation.BatchProcessing;
using System.Environment;

report 900 "Batch Post Assembly Orders"
{
    Caption = 'Batch Post Assembly Orders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Assembly Header"; "Assembly Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));
            RequestFilterFields = "No.";

            trigger OnPreDataItem()
            var
                BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
                RecRef: RecordRef;
            begin
                if ReplacePostingDate and (PostingDateReq = 0D) then
                    Error(Text000);

                BatchProcessingMgt.SetProcessingCodeunit(CODEUNIT::"Assembly-Post");
                BatchProcessingMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Replace Posting Date", ReplacePostingDate);
                BatchProcessingMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Posting Date", PostingDateReq);

                RecRef.GetTable("Assembly Header");
                BatchProcessingMgt.BatchProcess(RecRef);
                RecRef.SetTable("Assembly Header");

                CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that you want to use as the document date or the posting date when you post. ';
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the posting date of the orders with the date that is entered in the Posting Date field.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            ClientTypeManagement: Codeunit "Client Type Management";
        begin
            if ClientTypeManagement.GetCurrentClientType() <> ClientType::Background then
                ReplacePostingDate := false;
        end;
    }

    labels
    {
    }

    var
#pragma warning disable AA0074
        Text000: Label 'Enter the posting date.';
#pragma warning restore AA0074
        PostingDateReq: Date;
        ReplacePostingDate: Boolean;

    procedure InitializeRequest(NewPostingDateReq: Date; NewReplacePostingDate: Boolean)
    begin
        PostingDateReq := NewPostingDateReq;
        ReplacePostingDate := NewReplacePostingDate;
    end;
}

