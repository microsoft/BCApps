// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

report 84 "Update Analysis Views"
{
    ApplicationArea = Dimensions;
    Caption = 'Update Analysis Views';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Analysis View"; "Analysis View")
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code";

            trigger OnAfterGetRecord()
            begin
                if RecreateAnalysisViews then
                    "Analysis View".AnalysisViewReset();

                if not Blocked then
                    UpdateAnalysisView.Update("Analysis View", 2, true)
                else
                    BlockedOccured := true;
            end;

            trigger OnPostDataItem()
            begin
                if BlockedOccured then
                    Message(Text000)
                else
                    Message(Text001);
            end;

            trigger OnPreDataItem()
            begin
                LockTable();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(RecreateAnalysisViewsField; RecreateAnalysisViews)
                    {
                        Caption = 'Reset Analysis Views';
                        ToolTip = 'This option recreates analysis views, which can take some time to complete. Use this option only when entries are missing or if a dimension was corrected.';
                        ApplicationArea = Basic, Suite;

                        trigger OnValidate()
                        begin
                            if RecreateAnalysisViews then
                                Message(RecreateAnalysisViewMsg);
                        end;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        UpdateAnalysisView: Codeunit "Update Analysis View";
#pragma warning disable AA0074
        Text000: Label 'One or more of the selected Analysis Views is Blocked, and could not be updated.';
#pragma warning restore AA0074
        BlockedOccured: Boolean;
        RecreateAnalysisViews: Boolean;
#pragma warning disable AA0074
        Text001: Label 'All selected Analysis Views were updated successfully.';
#pragma warning restore AA0074
        RecreateAnalysisViewMsg: Label 'Recreating entries can take time to complete. We recommend that you schedule the update to happen outside business hours.';
}

