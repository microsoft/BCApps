// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

table 958 "Time Sheet Posting Entry"
{
    Caption = 'Time Sheet Posting Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        field(2; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            ToolTip = 'Specifies the number of a time sheet.';
            TableRelation = "Time Sheet Header";
        }
        field(3; "Time Sheet Line No."; Integer)
        {
            Caption = 'Time Sheet Line No.';
            ToolTip = 'Specifies the number of a time sheet line.';
        }
        field(4; "Time Sheet Date"; Date)
        {
            Caption = 'Time Sheet Date';
            ToolTip = 'Specifies the date for which time usage information was entered in a time sheet.';
        }
        field(5; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the number of hours that have been posted for that date in the time sheet.';
            Editable = false;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number that was generated or created for the time sheet during posting.';
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date of the posted document.';
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description that is contained in the details about the time sheet line.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Time Sheet No.", "Time Sheet Line No.", "Time Sheet Date")
        {
            SumIndexFields = Quantity;
        }
    }

    fieldgroups
    {
    }
}

