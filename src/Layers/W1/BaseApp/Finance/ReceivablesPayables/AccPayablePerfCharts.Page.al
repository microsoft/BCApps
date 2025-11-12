// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

page 9074 "Acc. Payable Perf. Charts"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payable Perfomance Charts';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Acc. Payable Performance Chart";
    UsageCategory = None;

    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Chart Name"; Rec."Chart Name")
                {
                    Caption = 'Chart Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the chart.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ToolTip = 'Specifies that the chart is enabled.';
                }
            }
        }
    }

    var
        DisabledChartSelectedErr: Label 'The chart that you selected is disabled and cannot be opened on the role center. Enable the selected chart or select another chart.';

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if (CloseAction = Action::LookupOK) and not Rec.Enabled then
            Dialog.Error(DisabledChartSelectedErr);
    end;
}
