// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

report 5185 "Log Segment"
{
    Caption = 'Log Segment';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Segment Header"; "Segment Header")
        {
            DataItemTableView = sorting("No.");

            trigger OnAfterGetRecord()
            begin
                OnBeforeLogSegment("Segment Header");
                SegManagement.LogSegment("Segment Header", Send, FollowUp);
            end;

            trigger OnPreDataItem()
            begin
                SetRange("No.", SegmentNo);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Deliver; Send)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Send Attachments';
                        Enabled = DeliverEnable;
                        ToolTip = 'Specifies if you want to deliver the attachments and send them by e-mail or fax, or print them when you choose OK.';
                    }
                    field(FollowUp; FollowUp)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Create Follow-up Segment';
                        ToolTip = 'Specifies if you want to create a new segment that Specifies the same contacts when you choose OK.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            DeliverEnable := true;
        end;

        trigger OnOpenPage()
        var
            SegLine: Record "Segment Line";
        begin
            SegLine.SetRange("Segment No.", SegmentNo);
            SegLine.SetFilter("Correspondence Type", '<>0');
            Send := not SegLine.IsEmpty();
            DeliverEnable := Send;
        end;
    }

    labels
    {
    }

    var
        SegManagement: Codeunit SegManagement;
        SegmentNo: Code[20];
        Send: Boolean;
        FollowUp: Boolean;
        DeliverEnable: Boolean;

    procedure SetSegmentNo(SegmentFilter: Code[20])
    begin
        SegmentNo := SegmentFilter;
    end;

    procedure InitializeRequest(SendFrom: Boolean; FollowUpFrom: Boolean)
    begin
        Send := SendFrom;
        FollowUp := FollowUpFrom;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLogSegment(var SegmentHeader: Record "Segment Header");
    begin
    end;
}

