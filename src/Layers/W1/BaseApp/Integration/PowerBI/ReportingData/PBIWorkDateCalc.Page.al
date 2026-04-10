// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using System.Environment;
using System.Utilities;

page 6313 "PBI WorkDate Calc."
{
    Caption = 'PBI WorkDate Calc.';
    PageType = List;
    SourceTable = "Integer";
    SourceTableView = where(Number = const(1));

    layout
    {
        area(content)
        {
            repeater(Control3)
            {
                ShowCaption = false;
                field(WorkDateNAV; WorkDateNAV)
                {
                    ApplicationArea = All;
                    Caption = 'Work Date';
                    ToolTip = 'Specifies the date that is set as the work date. This is either today or another date.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        LogInManagement: Codeunit LogInManagement;
    begin
        WorkDateNAV := LogInManagement.GetDefaultWorkDate();
    end;

    var
        WorkDateNAV: Date;
}

