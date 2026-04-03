// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

table 681 "Payment Period Line"
{
    Caption = 'Payment Period Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Period Header Code"; Code[20])
        {
            TableRelation = "Payment Period Header".Code;
            ToolTip = 'Specifies the code of the payment period header this line belongs to.';
        }
        field(2; "Line No."; Integer)
        {
            ToolTip = 'Specifies the line number.';
        }
        field(3; "Days From"; Integer)
        {
            MinValue = 0;
            ToolTip = 'Specifies the lowest number of Actual Payment Days for the payment to be included in this period.';

            trigger OnValidate()
            begin
                CheckDatePeriodConsistency();
                UpdateDescription();
            end;
        }
        field(4; "Days To"; Integer)
        {
            MinValue = 0;
            ToolTip = 'Specifies the highest number of Actual Payment Days for the payment to be included in this period. 0 means no upper limit.';

            trigger OnValidate()
            begin
                CheckDatePeriodConsistency();
                UpdateDescription();
            end;
        }
        field(5; Description; Text[250])
        {
            ToolTip = 'Specifies the description of the payment period.';
        }
    }

    keys
    {
        key(Key1; "Period Header Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Days From")
        {
        }
    }

    var
        DaysFromLessThanDaysToErr: Label 'Days From must not be less than Days To.';
        DescriptionTemplateTxt: Label '%1 to %2 days.', Comment = '%1,%2 - number of days';
        DescriptionTemplateEndlessTxt: Label 'More than %1 days.', Comment = '%1 - number of days';

    local procedure CheckDatePeriodConsistency()
    begin
        if ("Days To" <> 0) and ("Days From" > "Days To") then
            Error(DaysFromLessThanDaysToErr);
    end;

    procedure UpdateDescription()
    begin
        if "Days To" > 0 then
            Description := CopyStr(StrSubstNo(DescriptionTemplateTxt, "Days From", "Days To"), 1, MaxStrLen(Description))
        else
            Description := CopyStr(StrSubstNo(DescriptionTemplateEndlessTxt, "Days From"), 1, MaxStrLen(Description));
    end;
}
